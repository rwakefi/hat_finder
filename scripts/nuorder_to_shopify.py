#!/usr/bin/env python3
"""Convert a NuOrder/Pendleton wholesale product export CSV into a Shopify
product-import CSV (Products -> Import in the Shopify admin).

Rows are grouped by ``Style Number``: each style becomes one product and each
color row becomes a "Color" variant carrying its own SKU, barcode (UPC),
price, and image. Extra media URLs are appended as additional product images.

Usage:
    python3 scripts/nuorder_to_shopify.py INPUT.csv [OUTPUT.csv] [--status draft|active]
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import OrderedDict, defaultdict

# Standard Shopify product-import columns (order matters for readability only).
SHOPIFY_COLUMNS = [
    "Handle",
    "Title",
    "Body (HTML)",
    "Vendor",
    "Type",
    "Tags",
    "Published",
    "Option1 Name",
    "Option1 Value",
    "Variant SKU",
    "Variant Inventory Tracker",
    "Variant Inventory Qty",
    "Variant Inventory Policy",
    "Variant Fulfillment Service",
    "Variant Price",
    "Variant Requires Shipping",
    "Variant Taxable",
    "Variant Barcode",
    "Image Src",
    "Image Position",
    "Image Alt Text",
    "Variant Image",
    "Status",
]


def slugify(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-")


def clean(value) -> str:
    if value is None:
        return ""
    if isinstance(value, float) and value.is_integer():
        value = int(value)
    return str(value).strip()


def title_case(value: str) -> str:
    return " ".join(w.capitalize() for w in clean(value).split())


def media_urls(row: dict) -> list[str]:
    urls = []
    for i in range(1, 11):  # NuOrder exports vary (3, 5, ... media columns)
        url = clean(row.get(f"Media URL {i}"))
        if url:
            urls.append(url)
    return urls


def build_tags(row: dict) -> str:
    parts = [
        clean(row.get("Division")),
        clean(row.get("Department")),
        clean(row.get("Category")),
        clean(row.get("Subcategory")),
        clean(row.get("Season")),
    ]
    seen = OrderedDict()
    for p in parts:
        if p:
            seen[title_case(p)] = None
    return ", ".join(seen.keys())


def convert(input_path: str, output_path: str, status: str) -> int:
    with open(input_path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        rows = list(reader)

    # Group color rows under their style number, preserving file order.
    groups: "OrderedDict[str, list[dict]]" = OrderedDict()
    for row in rows:
        style = clean(row.get("Style Number"))
        if not style:
            continue
        groups.setdefault(style, []).append(row)

    used_handles: dict[str, int] = defaultdict(int)
    out_rows: list[dict] = []

    for style, variant_rows in groups.items():
        first_row = variant_rows[0]
        title = title_case(first_row.get("Name")) or style

        base_handle = slugify(f"{title}-{style}") or slugify(style)
        used_handles[base_handle] += 1
        handle = base_handle if used_handles[base_handle] == 1 else f"{base_handle}-{used_handles[base_handle]}"

        body = clean(first_row.get("Fabric Description")) or clean(first_row.get("Description"))
        product_type = title_case(first_row.get("Subcategory")) or title_case(first_row.get("Category"))
        tags = build_tags(first_row)

        # De-duplicate the full image set across all variants, keep order.
        all_images: "OrderedDict[str, None]" = OrderedDict()
        for vr in variant_rows:
            for url in media_urls(vr):
                all_images.setdefault(url, None)
        image_list = list(all_images.keys())

        for idx, vr in enumerate(variant_rows):
            color = title_case(vr.get("Color"))
            variant_image = media_urls(vr)[0] if media_urls(vr) else ""

            out = {col: "" for col in SHOPIFY_COLUMNS}
            out["Handle"] = handle
            out["Option1 Name"] = "Color"
            out["Option1 Value"] = color
            out["Variant SKU"] = clean(vr.get("brand_id")) or f"{style}-{clean(vr.get('Color Code'))}"
            out["Variant Inventory Tracker"] = "shopify"
            out["Variant Inventory Qty"] = "0"
            out["Variant Inventory Policy"] = "deny"
            out["Variant Fulfillment Service"] = "manual"
            out["Variant Price"] = clean(vr.get("Retail Price 1 USD"))
            out["Variant Requires Shipping"] = "TRUE"
            out["Variant Taxable"] = "TRUE"
            out["Variant Barcode"] = clean(vr.get("UPC 1"))
            out["Variant Image"] = variant_image

            if idx == 0:
                out["Title"] = title
                out["Body (HTML)"] = body
                out["Vendor"] = "Pendleton"
                out["Type"] = product_type
                out["Tags"] = tags
                out["Published"] = "TRUE" if status == "active" else "FALSE"
                out["Status"] = status
                if image_list:
                    out["Image Src"] = image_list[0]
                    out["Image Position"] = "1"
                    out["Image Alt Text"] = f"{title} - {color}"
            out_rows.append(out)

        # Remaining product images as standalone image rows.
        for pos, url in enumerate(image_list[1:], start=2):
            img_row = {col: "" for col in SHOPIFY_COLUMNS}
            img_row["Handle"] = handle
            img_row["Image Src"] = url
            img_row["Image Position"] = str(pos)
            out_rows.append(img_row)

    with open(output_path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=SHOPIFY_COLUMNS)
        writer.writeheader()
        writer.writerows(out_rows)

    print(f"Products: {len(groups)}")
    print(f"Output rows (variants + image rows): {len(out_rows)}")
    print(f"Wrote: {output_path}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="NuOrder export CSV path")
    parser.add_argument("output", nargs="?", help="Output Shopify CSV path")
    parser.add_argument(
        "--status",
        choices=["draft", "active"],
        default="draft",
        help="Product status on import (default: draft, so nothing goes live until you review).",
    )
    args = parser.parse_args()

    output = args.output or re.sub(r"\.csv$", "", args.input) + "_shopify.csv"
    return convert(args.input, output, args.status)


if __name__ == "__main__":
    sys.exit(main())
