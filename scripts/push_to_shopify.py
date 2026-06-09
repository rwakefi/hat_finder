#!/usr/bin/env python3
"""Create products in Shopify from a NuOrder/Pendleton export CSV via the
Admin REST API.

Each ``Style Number`` becomes one product; each color row becomes a "Color"
variant carrying its SKU, barcode (UPC) and retail price. Variant images and
the remaining media URLs are attached as product images.

Products are created with status=draft by default and the script skips any
product whose title already exists for the vendor (so re-running is safe).

Env / args:
    SHOPIFY_TOKEN   Admin API access token (shpat_...)  [required]
    --shop          store subdomain (default: raftermhatco)
    --status        draft|active (default: draft)
    --dry-run       print what would be created, make no changes
    input           NuOrder export CSV path
"""
from __future__ import annotations

import argparse
import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import OrderedDict

try:
    import certifi

    _SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except Exception:  # pragma: no cover - fall back to system defaults
    _SSL_CONTEXT = ssl.create_default_context()

from nuorder_to_shopify import build_tags, clean, media_urls, slugify, title_case

API_VERSION = "2024-01"
VENDOR = "Pendleton"
THROTTLE_SECONDS = 0.6  # stay under REST 2 req/s leak rate


class Api:
    def __init__(self, shop: str, token: str):
        self.base = f"https://{shop}.myshopify.com/admin/api/{API_VERSION}"
        self.token = token

    def _request(self, method: str, path: str, body: dict | None = None) -> tuple[int, dict]:
        url = f"{self.base}{path}"
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("X-Shopify-Access-Token", self.token)
        req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, context=_SSL_CONTEXT) as resp:
                payload = resp.read().decode()
                time.sleep(THROTTLE_SECONDS)
                return resp.status, (json.loads(payload) if payload else {})
        except urllib.error.HTTPError as e:
            payload = e.read().decode()
            time.sleep(THROTTLE_SECONDS)
            try:
                return e.code, json.loads(payload)
            except Exception:
                return e.code, {"errors": payload}

    def get(self, path: str) -> tuple[int, dict]:
        return self._request("GET", path)

    def post(self, path: str, body: dict) -> tuple[int, dict]:
        return self._request("POST", path, body)


def _read_rows(input_path: str) -> list[dict]:
    """Read a NuOrder export from .csv or .xlsx into a list of dict rows."""
    if input_path.lower().endswith((".xlsx", ".xlsm")):
        import openpyxl

        wb = openpyxl.load_workbook(input_path, read_only=True, data_only=True)
        ws = wb.active
        rows = list(ws.iter_rows(values_only=True))
        if not rows:
            return []
        header = [str(h).strip() if h is not None else "" for h in rows[0]]
        out = []
        for r in rows[1:]:
            if not r or r[0] in (None, ""):
                continue
            out.append({header[i]: (r[i] if i < len(r) else None) for i in range(len(header))})
        return out

    import csv

    with open(input_path, newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def parse_groups(input_path: str) -> "OrderedDict[str, list[dict]]":
    groups: "OrderedDict[str, list[dict]]" = OrderedDict()
    for row in _read_rows(input_path):
        style = clean(row.get("Style Number"))
        if style:
            groups.setdefault(style, []).append(row)
    return groups


def existing_titles(api: Api) -> set[str]:
    """Titles already present for the vendor, to avoid duplicate creation."""
    titles: set[str] = set()
    status, data = api.get(
        f"/products.json?vendor={urllib.parse.quote(VENDOR)}&limit=250&fields=title"
    )
    if status == 200:
        for p in data.get("products", []):
            titles.add(clean(p.get("title")).lower())
    return titles


# NuOrder placeholder "sizes" that mean one-size / not a real size run.
_NON_SIZES = {"", "1-sz", "1sz", "unit", "unsz", "os", "o/s", "one size", "onesize"}

# Normalize apparel size labels to the store's convention (S/M/L/XL/2XL/3XL).
_SIZE_NORMALIZE = {
    "sm": "S", "s": "S",
    "md": "M", "m": "M", "med": "M",
    "lg": "L", "l": "L",
    "xl": "XL", "x-large": "XL",
    "xxl": "2XL", "2xl": "2XL",
    "xxxl": "3XL", "3xl": "3XL",
}


def _normalize_size(raw: str) -> str:
    s = clean(raw)
    return _SIZE_NORMALIZE.get(s.lower(), s)


def _is_real_size(raw: str) -> bool:
    return clean(raw).lower() not in _NON_SIZES


def build_product_payload(
    style: str,
    variant_rows: list[dict],
    status: str,
    ballcap_styles: set[str],
) -> tuple[dict, list[str], dict[str, list[int]]]:
    first = variant_rows[0]
    title = title_case(first.get("Name")) or style
    body = clean(first.get("Fabric Description")) or clean(first.get("Description"))
    product_type = title_case(first.get("Subcategory")) or title_case(first.get("Category"))
    tags = build_tags(first)

    # Does this style have a real size run (apparel) or is it one-size (color only)?
    has_sizes = any(_is_real_size(vr.get("Size 1")) for vr in variant_rows)

    variants = []
    # url -> list of variant indices that use it as their main image
    main_image_for: "OrderedDict[str, list[int]]" = OrderedDict()
    all_images: "OrderedDict[str, None]" = OrderedDict()
    # Each color's hero image is its first media URL; shared by all its sizes.
    color_main_url: "OrderedDict[str, str]" = OrderedDict()

    for idx, vr in enumerate(variant_rows):
        color = title_case(vr.get("Color"))
        sku = clean(vr.get("brand_id")) or f"{style}-{clean(vr.get('Color Code'))}"
        variant = {
            "option1": color,
            "sku": sku,
            "price": clean(vr.get("Retail Price 1 USD")),
            "barcode": clean(vr.get("UPC 1")),
            "inventory_management": "shopify",
            "inventory_policy": "deny",
        }
        if has_sizes:
            variant["option2"] = _normalize_size(vr.get("Size 1"))
        variants.append(variant)

        urls = media_urls(vr)
        if urls and color not in color_main_url:
            color_main_url[color] = urls[0]
        for u in urls:
            all_images.setdefault(u, None)

    # Map hero image -> all variant indices of that color (so every size gets it).
    for idx, v in enumerate(variants):
        hero = color_main_url.get(v["option1"])
        if hero:
            main_image_for.setdefault(hero, []).append(idx)

    options = [{"name": "Color"}]
    if has_sizes:
        options.append({"name": "Size"})

    product = {
        "title": title,
        "body_html": body,
        "vendor": VENDOR,
        "product_type": product_type,
        "tags": tags,
        "status": status,
        "options": options,
        "variants": variants,
    }
    if style in ballcap_styles:
        # Makes the product eligible for the Hat Finder app catalog filter.
        product["metafields"] = [
            {
                "namespace": "custom",
                "key": "felt_straw_or_ballcap",
                "type": "list.single_line_text_field",
                "value": json.dumps(["Ballcap"]),
            }
        ]
    return product, list(all_images.keys()), main_image_for


def existing_barcodes(api: Api) -> set[str]:
    """All variant barcodes already in the store (paginated)."""
    codes: set[str] = set()
    since = 0
    while True:
        status, data = api.get(f"/products.json?limit=250&since_id={since}&fields=id,variants")
        if status != 200:
            break
        batch = data.get("products", [])
        if not batch:
            break
        for p in batch:
            for v in p.get("variants", []):
                bc = clean(v.get("barcode"))
                if bc:
                    codes.add(bc)
        since = batch[-1]["id"]
        if len(batch) < 250:
            break
    return codes


def push(
    input_path: str,
    shop: str,
    token: str,
    status: str,
    dry_run: bool,
    ballcap_styles: set[str],
    exclude_styles: set[str],
    skip_existing_barcodes: bool,
) -> int:
    api = Api(shop, token)
    groups = parse_groups(input_path)

    skip_titles = set() if dry_run else existing_titles(api)
    known_barcodes = existing_barcodes(api) if (skip_existing_barcodes and not dry_run) else set()

    created, skipped, failed = 0, 0, 0
    for style, variant_rows in groups.items():
        if style in exclude_styles:
            print(f"SKIP (excluded): [{style}]")
            skipped += 1
            continue

        if skip_existing_barcodes and known_barcodes:
            kept = [r for r in variant_rows if clean(r.get("UPC 1")) not in known_barcodes]
            dropped = len(variant_rows) - len(kept)
            if dropped:
                print(f"  ~ {style}: skipping {dropped} variant(s) whose UPC already exists")
            if not kept:
                print(f"SKIP (all variants exist): [{style}]")
                skipped += 1
                continue
            variant_rows = kept

        product, image_urls, main_image_for = build_product_payload(
            style, variant_rows, status, ballcap_styles
        )
        title = product["title"]
        hat_tag = " [Ballcap]" if style in ballcap_styles else ""

        if title.lower() in skip_titles:
            print(f"SKIP (exists): {title} [{style}]")
            skipped += 1
            continue

        if dry_run:
            print(f"WOULD CREATE: {title} [{style}]{hat_tag} — {len(product['variants'])} variants, {len(image_urls)} images")
            continue

        code, resp = api.post("/products.json", {"product": product})
        if code not in (200, 201) or "product" not in resp:
            print(f"FAIL create {title} [{style}] (http {code}): {resp.get('errors', resp)}")
            failed += 1
            continue

        created_product = resp["product"]
        pid = created_product["id"]
        created_variants = created_product.get("variants", [])
        print(f"CREATED: {title} [{style}]{hat_tag} id={pid} ({len(created_variants)} variants)")
        created += 1

        # Attach images. Variant main images carry variant_ids so they map.
        for pos, url in enumerate(image_urls, start=1):
            image_body: dict = {"src": url, "position": pos}
            variant_idxs = main_image_for.get(url)
            if variant_idxs:
                vids = [created_variants[i]["id"] for i in variant_idxs if i < len(created_variants)]
                if vids:
                    image_body["variant_ids"] = vids
            icode, iresp = api.post(f"/products/{pid}/images.json", {"image": image_body})
            if icode not in (200, 201):
                print(f"  ! image failed (http {icode}) pos {pos}: {iresp.get('errors', iresp)}")

    print("\n--- summary ---")
    print(f"created: {created}  skipped: {skipped}  failed: {failed}  total styles: {len(groups)}")
    return 0 if failed == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="NuOrder export CSV path")
    parser.add_argument("--shop", default="raftermhatco", help="store subdomain")
    parser.add_argument("--status", choices=["draft", "active"], default="draft")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--ballcap-styles",
        default="",
        help="Comma-separated Style Numbers to tag custom.felt_straw_or_ballcap=Ballcap (Hat Finder eligible).",
    )
    parser.add_argument(
        "--exclude-styles",
        default="",
        help="Comma-separated Style Numbers to skip entirely.",
    )
    parser.add_argument(
        "--skip-existing-barcodes",
        action="store_true",
        help="Skip any variant whose UPC barcode already exists in the store.",
    )
    args = parser.parse_args()

    token = os.environ.get("SHOPIFY_TOKEN", "")
    if not token and not args.dry_run:
        print("ERROR: set SHOPIFY_TOKEN env var (shpat_...)", file=sys.stderr)
        return 2

    ballcap_styles = {s.strip() for s in args.ballcap_styles.split(",") if s.strip()}
    exclude_styles = {s.strip() for s in args.exclude_styles.split(",") if s.strip()}
    return push(
        args.input,
        args.shop,
        token,
        args.status,
        args.dry_run,
        ballcap_styles,
        exclude_styles,
        args.skip_existing_barcodes,
    )


if __name__ == "__main__":
    sys.exit(main())
