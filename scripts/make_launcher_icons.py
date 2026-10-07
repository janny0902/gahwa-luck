"""스토어 아이콘(512 PNG)으로 안드로이드 런처 아이콘을 만든다.

사용: python scripts/make_launcher_icons.py <512 png>
"""
import sys
from pathlib import Path

from PIL import Image

BG = (249, 234, 211)
RES = Path(__file__).resolve().parent.parent / "app" / "android" / "app" / "src" / "main" / "res"
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
# 적응형 아이콘은 108dp 중 가운데 약 72dp만 보인다.
FOREGROUND_RATIO = 66 / 108


def main(src: str) -> None:
    image = Image.open(src).convert("RGB")
    # 원본 가장자리의 옅은 둥근 테두리를 잘라 낸다.
    margin = round(image.width * 0.045)
    image = image.crop((margin, margin, image.width - margin, image.height - margin))

    for density, size in LEGACY.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        image.resize((size, size), Image.Resampling.LANCZOS).save(folder / "ic_launcher.png")

    for density, size in ADAPTIVE.items():
        canvas = Image.new("RGB", (size, size), BG)
        inner = round(size * FOREGROUND_RATIO)
        art = image.resize((inner, inner), Image.Resampling.LANCZOS)
        offset = (size - inner) // 2
        canvas.paste(art, (offset, offset))
        canvas.save(RES / f"mipmap-{density}" / "ic_launcher_foreground.png")


if __name__ == "__main__":
    main(sys.argv[1])
