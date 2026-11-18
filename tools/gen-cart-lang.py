#!/usr/bin/env python3
"""Generate the PICO8-OS settings-cart language data carts (lang_<code>.p8).

PICO-8's built-in font only has ASCII and kana, so each language gets a data
cart whose sprite memory holds:

  0x0000-0x07ff  a PICO-8 custom font (copied to 0x5600 by the cart): ASCII
                 plus every non-ASCII character the language's texts use,
                 remapped to free codes (16-31, 128-255)
  0x0800-...     "key=value\\n" lines in that remapped encoding, NUL-terminated

Glyphs come from Fusion Pixel Font 8px monospaced (SIL OFL 1.1):
https://github.com/TakWolf/fusion-pixel-font
Cyrillic (which Fusion lacks) comes from tools/i18n/cyrillic-8px.txt.

usage: gen-cart-lang.py FONT_DIR STRINGS_JSON OUT_DIR
"""
import json
import os
import shutil
import sys

ASCENT = 7
VARIANT = {"ko": "ko", "zh": "zh_hans", "ja": "ja"}   # others: latin
NATIVE = {"ko": "ko", "zh": "zh_hans", "ja": "ja"}    # for language names
FULL_CODES = list(range(128, 256))                    # full-width glyphs
HALF_CODES = list(range(16, 32))                      # half-width first here
SCREEN_W = 128
MAX_LABEL_W = {"title": 124, "i_hint1": 126, "i_hint2": 126, "back": 118, "confirm": 126}


def load_bdf(path):
    glyphs, cur = {}, None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if line.startswith("ENCODING"):
                cur = {"enc": int(line.split()[1])}
            elif cur is None:
                continue
            elif line.startswith("DWIDTH"):
                cur["dw"] = int(line.split()[1])
            elif line.startswith("BBX"):
                cur["bbx"] = list(map(int, line.split()[1:]))
            elif line.startswith("BITMAP"):
                cur["bm"] = []
            elif line.startswith("ENDCHAR"):
                glyphs[cur["enc"]] = cur
                cur = None
            elif "bm" in cur:
                cur["bm"].append(int(line.strip(), 16))
    return glyphs


def load_custom(path, latin):
    """Hand-drawn glyphs: header line + 8 art rows, or 'X=Y' Latin alias."""
    glyphs = {}
    lines = [l.rstrip("\n") for l in open(path, encoding="utf-8")]
    i = 0
    while i < len(lines):
        l = lines[i]
        if not l.strip() or l.startswith("#"):
            i += 1
            continue
        if "=" in l:
            ch, alias = l.split("=", 1)
            glyphs[ch] = latin[ord(alias)]
            i += 1
            continue
        art = lines[i + 1:i + 9]
        if len(art) != 8 or any(set(a) - set(".#") for a in art):
            raise SystemExit(f"{path}: bad glyph block for {l!r}")
        w = max(len(a) for a in art)
        rows = [sum(1 << x for x, c in enumerate(a) if c == "#") for a in art]
        glyphs[l] = {"rows": rows, "dw": w + 1}
        i += 9
    return glyphs


def glyph_rows(g):
    """8 bytes, one per row, bit 0 = leftmost pixel (PICO-8 custom font)."""
    if "rows" in g:
        return list(g["rows"])
    w, h, xo, yo = g["bbx"]
    rows = [0] * 8
    top = ASCENT - (yo + h)
    for r, bits in enumerate(g["bm"]):
        y = top + r
        if not 0 <= y < 8:
            continue
        nbytes = (w + 7) // 8
        for px in range(w):
            if (bits >> (nbytes * 8 - 1 - px)) & 1 and 0 <= xo + px < 8:
                rows[y] |= 1 << (xo + px)
    return rows


def gfx_lines(mem):
    out = []
    for y in range(128):
        row = mem[y * 64:(y + 1) * 64]
        out.append("".join("%x%x" % (b & 15, b >> 4) for b in row))
    while out and set(out[-1]) == {"0"}:
        out.pop()
    return out


def main(font_dir, strings_json, out_dir):
    data = json.load(open(strings_json, encoding="utf-8"))
    fonts = {}

    def font(v):
        if v not in fonts:
            fonts[v] = load_bdf(os.path.join(font_dir, f"fusion-pixel-8px-monospaced-{v}.bdf"))
        return fonts[v]

    custom = load_custom(os.path.join(os.path.dirname(os.path.abspath(strings_json)), "cyrillic-8px.txt"),
                         font("latin"))

    def find(ch, prefer):
        for v in (prefer, "latin", "ko", "ja", "zh_hans"):
            g = font(v).get(ord(ch))
            if g:
                return g
        if ch in custom:
            return custom[ch]
        raise SystemExit(f"no glyph for {ch!r} (U+{ord(ch):04X})")

    os.makedirs(out_dir, exist_ok=True)
    report = []
    for lang in data["languages"]:
        variant = VARIANT.get(lang, "latin")
        texts = {k: v[lang] for k, v in data["strings"].items()}
        texts.update({f"n_{c}": n for c, n in data["names"].items()})
        texts["lang"] = lang

        # characters -> glyphs (language names use their own script's variant)
        glyph_of = {}
        for k, s in texts.items():
            prefer = NATIVE.get(k[2:], variant) if k.startswith("n_") else variant
            for ch in s:
                if ch not in glyph_of:
                    glyph_of[ch] = find(ch, prefer)
        for c in range(32, 127):
            glyph_of.setdefault(chr(c), find(chr(c), variant))

        extra = sorted(ch for ch in glyph_of if ord(ch) > 126)
        adv = {ch: min(8, max(4, glyph_of[ch]["dw"])) for ch in glyph_of}
        # codes >= 128 draw 8 px wide (adjustable -4..0); 16-31 draw 4 (+0..3)
        full = [ch for ch in extra if adv[ch] > 7]
        half = [ch for ch in extra if adv[ch] <= 7]
        code = {chr(c): c for c in range(32, 127)}
        code["\n"] = 10
        free_full, free_half = list(FULL_CODES), list(HALF_CODES)
        for ch in full:
            if not free_full:
                raise SystemExit(f"{lang}: too many full-width characters ({len(full)})")
            code[ch] = free_full.pop(0)
        for ch in half:
            pool = free_half if free_half else free_full
            if not pool:
                raise SystemExit(f"{lang}: out of glyph slots")
            code[ch] = pool.pop(0)

        # custom font block (2 KB)
        fnt = bytearray(2048)
        fnt[0], fnt[1], fnt[2] = 4, 8, 8       # width <128, width >=128, height
        fnt[5] = 0x1                            # apply per-char size adjustments
        for ch, c in code.items():
            if ch == "\n":
                continue
            g = glyph_of[ch]
            fnt[c * 8:c * 8 + 8] = bytes(glyph_rows(g))
            want = adv[ch]
            base = 4 if c < 128 else 8
            adj = want - base                   # -4..3 -> nibble 4..7, 0..3
            if adj:
                nib = adj & 0x7
                i = c - 16
                fnt[8 + i // 2] |= nib << (4 * (i % 2))

        def width(s):
            return sum(adv[ch] for ch in s)

        for k, s in texts.items():
            limit = MAX_LABEL_W.get(k, 100)
            if width(s) > limit:
                raise SystemExit(f"{lang}: '{k}' is {width(s)} px wide (max {limit}): {s}")

        blob = "".join(f"{k}={v}\n" for k, v in texts.items())
        enc = bytes(code[ch] for ch in blob) + b"\0"
        if len(enc) > 0x2000 - 0x800:
            raise SystemExit(f"{lang}: strings too long ({len(enc)} bytes)")
        mem = bytearray(0x2000)
        mem[0:0x800] = fnt
        mem[0x800:0x800 + len(enc)] = enc

        path = os.path.join(out_dir, f"lang_{lang}.p8")
        with open(path, "w") as f:
            f.write("pico-8 cartridge // http://www.pico-8.com\nversion 41\n__gfx__\n")
            f.write("\n".join(gfx_lines(mem)) + "\n")
        report.append(f"{lang}: {len(extra)} extra glyphs, {len(enc)} bytes of text")

    shutil.copy(os.path.join(font_dir, "OFL.txt"), os.path.join(out_dir, "FONT-LICENSE-OFL.txt"))
    print("\n".join(report))


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
