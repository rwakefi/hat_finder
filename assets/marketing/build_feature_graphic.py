#!/usr/bin/env python3
"""Compose Play Store feature graphic from real Moon Ridge hat photos."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
ASSETS = Path(__file__).resolve().parent
CURSOR_ASSETS = Path.home() / ".cursor/projects/Users-richardwakefield-hat-finder/assets"

W, H = 1024, 500

CREAM = (250, 248, 245)
ESPRESSO = (45, 41, 38)
TEAL = (85, 156, 153)
MUTED = (74, 69, 65)
GOLD = (212, 168, 67)

HATS = [
    # (filename, x, y, target_height, z-order draw index)
    ("F471C386-A432-404E-B2A8-6FA593F8A1CC_1_105_c-0b364e2f-2de6-4d8e-8a00-0832fd024c74.png", 40, 55, 390),
    ("C663497A-815A-443C-8413-F914BCE1706C_1_105_c-2c8433ce-f8fc-4a1b-af4f-e520e7dfff09.png", 300, 10, 460),
    ("4710EB84-090F-4315-AE65-A2ADB1744F29_1_105_c-d7e99fe9-2750-4632-a187-2925909dcb3e.png", 500, 40, 400),
]

LOGO = ROOT / "assets/images/moon_ridge_logo.png"
OUT = ASSETS / "hat-finder-feature-graphic-real-1024x500.png"


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Georgia Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Georgia.ttf",
        "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def gradient_bg() -> Image.Image:
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        # Warm cream left → slightly deeper cream/espresso tint right
        r = int(CREAM[0] * (1 - t * 0.12) + ESPRESSO[0] * t * 0.12)
        g = int(CREAM[1] * (1 - t * 0.12) + ESPRESSO[1] * t * 0.12)
        b = int(CREAM[2] * (1 - t * 0.12) + ESPRESSO[2] * t * 0.12)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    return img


def soft_mask(size: tuple[int, int], radius: float = 0.08) -> Image.Image:
    w, h = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    inset = int(min(w, h) * radius)
    draw.rounded_rectangle((inset, inset, w - inset, h - inset), radius=inset, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=10))
    return mask


def fit_height(img: Image.Image, height: int) -> Image.Image:
    ratio = height / img.height
    width = int(img.width * ratio)
    return img.resize((width, height), Image.Resampling.LANCZOS)


def paste_hat(canvas: Image.Image, path: Path, x: int, y: int, height: int) -> None:
    hat = Image.open(path).convert("RGBA")
    hat = fit_height(hat, height)
    mask = soft_mask(hat.size)
    hat.putalpha(mask)
    # subtle drop shadow
    shadow = Image.new("RGBA", hat.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (8, 12, hat.width - 8, hat.height - 4),
        radius=24,
        fill=(45, 41, 38, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=14))
    canvas.alpha_composite(shadow, (x + 6, y + 10))
    canvas.alpha_composite(hat, (x, y))


def draw_text_panel(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    text_x = 620
    # Teal accent rule
    draw.rectangle((text_x, 118, text_x + 48, 122), fill=TEAL)

    title_font = load_font(44, bold=True)
    sub_font = load_font(19)
    brand_font = load_font(14)

    draw.text((text_x, 58), "FIND YOUR", font=title_font, fill=ESPRESSO)
    draw.text((text_x, 108), "PERFECT HAT", font=title_font, fill=ESPRESSO)

    sub = "Guided fit by hat type,\nstyle, crown & brim"
    draw.multiline_text((text_x, 148), sub, font=sub_font, fill=MUTED, spacing=6)

    # Logo
    if LOGO.exists():
        logo = Image.open(LOGO).convert("RGBA")
        logo_h = 72
        logo_w = int(logo.width * (logo_h / logo.height))
        logo = logo.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
        # tint logo espresso for cream bg
        r, g, b, a = logo.split()
        tinted = Image.merge("RGBA", (r, g, b, a))
        canvas.alpha_composite(tinted, (text_x, H - logo_h - 36))

    draw.text((text_x, H - 28), "Moon Ridge Hats & Heritage", font=brand_font, fill=GOLD)


def main() -> None:
    base = gradient_bg().convert("RGBA")
    # Soft panel behind text
    panel = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    panel_draw = ImageDraw.Draw(panel)
    panel_draw.rectangle((580, 0, W, H), fill=(*CREAM, 210))
    base = Image.alpha_composite(base, panel)

    for name, x, y, height in HATS:
        path = CURSOR_ASSETS / name
        if not path.exists():
            raise FileNotFoundError(path)
        paste_hat(base, path, x, y, height)

    draw_text_panel(base)
    final = base.convert("RGB")
    final.save(OUT, quality=95)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
