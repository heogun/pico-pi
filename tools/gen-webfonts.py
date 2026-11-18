#!/usr/bin/env python3
"""Build the web UI fonts (www/fonts/*.woff2) from Noto Sans (SIL OFL 1.1).

The console serves its own fonts so the pages look the same everywhere,
including the Wi-Fi setup hotspot (no internet, so no web fonts from a CDN).
To keep downloads small for a Pi Zero, each font is subset:

  pico8os-latin.woff2  Noto Sans: Latin, Latin-1, Latin Extended-A/B, Cyrillic,
                      punctuation (whole ranges, so Wi-Fi/cart names render)
  pico8os-kr/sc/jp     Noto Sans KR / SC / JP: only the CJK characters used in
                      the pages (i18n.js, *.html) + all kana for JP

Characters the subsets lack fall back to the browser's system fonts.
Weights are limited to 400-700 (variable wght axis).

usage: gen-webfonts.py FONT_DIR WWW_DIR   (needs fontTools + brotli)
"""
import glob
import io
import os
import shutil
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

LATIN_RANGES = [(0x20, 0x7E), (0xA0, 0x24F), (0x400, 0x45F), (0x2000, 0x206F),
                (0x20AC, 0x20AC), (0x2190, 0x2193), (0x2212, 0x2212), (0xFFFD, 0xFFFD)]
KANA = [(0x3000, 0x30FF), (0xFF01, 0xFF60)]


def page_chars(www):
    text = ""
    for f in glob.glob(os.path.join(www, "*.html")) + [os.path.join(www, "i18n.js")]:
        with open(f, encoding="utf-8") as src:
            text += src.read()
    return set(text)


def build(src, dst, unicodes, axes):
    font = TTFont(src)
    if "fvar" in font:
        font = instancer.instantiateVariableFont(font, axes)
        # Reload: subsetting an in-memory instanced font trips over lazily
        # loaded variation data in fontTools.
        buf = io.BytesIO()
        font.save(buf)
        buf.seek(0)
        font = TTFont(buf)
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    sub = subset.Subsetter(options=opts)
    sub.populate(unicodes=sorted(unicodes))
    sub.subset(font)
    font.flavor = "woff2"
    font.save(dst)
    return os.path.getsize(dst)


def main(font_dir, www):
    out = os.path.join(www, "fonts")
    os.makedirs(out, exist_ok=True)
    chars = page_chars(www)
    cjk = {ord(c) for c in chars if ord(c) >= 0x2E80}
    latin = {u for a, b in LATIN_RANGES for u in range(a, b + 1)}
    latin |= {ord(c) for c in chars if ord(c) < 0x2E80}
    kana = {u for a, b in KANA for u in range(a, b + 1)}
    wght = {"wght": (400, 700)}
    jobs = [
        ("NotoSans.ttf", "pico8os-latin.woff2", latin, {"wdth": 100, **wght}),
        ("NotoSansKR.ttf", "pico8os-kr.woff2", cjk, wght),
        ("NotoSansSC.ttf", "pico8os-sc.woff2", cjk, wght),
        ("NotoSansJP.ttf", "pico8os-jp.woff2", cjk | kana, wght),
    ]
    for src, dst, uni, axes in jobs:
        size = build(os.path.join(font_dir, src), os.path.join(out, dst), uni, axes)
        print(f"{dst}: {size // 1024} KB")
    shutil.copy(os.path.join(font_dir, "OFL.txt"), os.path.join(out, "OFL.txt"))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(*sys.argv[1:])
