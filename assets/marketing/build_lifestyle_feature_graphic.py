#!/usr/bin/env python3
"""Blend a real lifestyle hat photo into the preferred feature graphic layout."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance

ROOT = Path(__file__).resolve().parents[2]
MARKETING = Path(__file__).resolve().parent
CURSOR_ASSETS = Path.home() / ".cursor/projects/Users-richardwakefield-hat-finder/assets"

W, H = 1024, 500
SPLIT = 548
BLEND_START = SPLIT - 110
BLEND_END = SPLIT + 35

BASE = MARKETING / "hat-finder-feature-graphic-template-1024x500.png"
PHOTO = CURSOR_ASSETS / (
    "4710EB84-090F-4315-AE65-A2ADB1744F29_1_105_c-d4b851d8-5fb4-4099-b807-c481923b0ca6.png"
)
OUT = MARKETING / "hat-finder-feature-graphic-1024x500.png"
OUT_ALT = MARKETING / "hat-finder-feature-graphic-lifestyle-1024x500.png"


def crop_hat_focus(photo: Image.Image) -> Image.Image:
    pw, ph = photo.size
    return photo.crop(
        (
            int(pw * 0.06),
            int(ph * 0.02),
            int(pw * 0.94),
            int(ph * 0.78),
        )
    )


def cover_left_panel(photo: Image.Image, bleed: int = 90) -> Image.Image:
    target_w = SPLIT + bleed
    ratio = max(H / photo.height, target_w / photo.width)
    scaled = photo.resize(
        (int(photo.width * ratio), int(photo.height * ratio)),
        Image.Resampling.LANCZOS,
    )
    left = max(0, (scaled.width - target_w) // 2 - 20)
    top = max(0, (scaled.height - H) // 2 - 30)
    return scaled.crop((left, top, left + target_w, top + H))


def blend_mask() -> Image.Image:
    mask = Image.new("L", (W, H), 0)
    draw = ImageDraw.Draw(mask)
    span = BLEND_END - BLEND_START
    for x in range(W):
        if x <= BLEND_START:
            alpha = 255
        elif x >= BLEND_END:
            alpha = 0
        else:
            alpha = int(255 * (1 - (x - BLEND_START) / span))
        draw.line([(x, 0), (x, H)], fill=alpha)
    return mask


def warm_tint(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    overlay = Image.new("RGBA", img.size, (255, 248, 238, 38))
    return Image.alpha_composite(rgba, overlay)


def main() -> None:
    base = Image.open(BASE).convert("RGBA")
    photo = Image.open(PHOTO).convert("RGB")
    photo = crop_hat_focus(photo)
    photo = ImageEnhance.Contrast(photo).enhance(1.06)
    photo = ImageEnhance.Color(photo).enhance(0.92)
    panel = cover_left_panel(photo)

    photo_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    photo_layer.paste(panel.convert("RGBA"), (0, 0))
    photo_layer = warm_tint(photo_layer.convert("RGB")).convert("RGBA")

    mask = blend_mask()
    merged = Image.composite(photo_layer, base, mask)

    # Soft vignette on far left for polish
    vignette = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vdraw = ImageDraw.Draw(vignette)
    for x in range(140):
        alpha = int(55 * (1 - x / 140))
        vdraw.line([(x, 0), (x, H)], fill=(45, 35, 28, alpha))
    merged = Image.alpha_composite(merged, vignette)

    final = merged.convert("RGB")
    final.save(OUT, quality=95)
    final.save(OUT_ALT, quality=95)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
