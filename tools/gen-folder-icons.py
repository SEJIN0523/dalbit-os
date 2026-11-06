"""Dalbit 폴더 아이콘(F1 플랫) 생성기.

KDE(Qt SVG)에서 그대로 보이도록 <use>, CSS 변수, 마스크 없이 단순한 경로만 사용한다.
실행: python tools/gen-folder-icons.py  (저장소 루트에서)
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

THEMES = {
    "dalbit-dark": {
        "name": "Dalbit Dark",
        "inherits": "breeze-dark,breeze,hicolor",
        "back": "#8797BB",
        "front": "#A9B8D8",
        "glyph": "#111317",
        "glyph_opacity": "0.6",
    },
    "dalbit-light": {
        "name": "Dalbit Light",
        "inherits": "breeze,hicolor",
        "back": "#7088BD",
        "front": "#8EA2CF",
        "glyph": "#FFFFFF",
        "glyph_opacity": "0.92",
    },
}

BACK = "M6 14a4 4 0 0 1 4-4h14l5 5h25a4 4 0 0 1 4 4v29a4 4 0 0 1-4 4H10a4 4 0 0 1-4-4z"
FRONT = "M6 22a3 3 0 0 1 3-3h46a3 3 0 0 1 3 3v25a4 4 0 0 1-4 4H10a4 4 0 0 1-4-4z"

# 폴더 앞면(y 19~51) 가운데에 얇은 선 한 가지 굵기로 그리는 기호
GLYPHS = {
    "": "",
    "doc": '<path d="M25 30h14M25 35h14M25 40h9"/>',
    "down": '<path d="M32 27.5v11M27 33.5l5 5 5-5M25 43h14"/>',
    "pic": '<circle cx="37.5" cy="29.5" r="1.8"/><path d="M24 42l6-6.5 4.5 4.5 3-3 4.5 5"/>',
    "music": '<path d="M35 39V28l5 2"/><circle cx="31.5" cy="39.5" r="3.2"/>',
    "video": '<path d="M28.5 29.5v11l9.5-5.5z"/>',
    "home": '<path d="M24.5 36l7.5-6.5 7.5 6.5M27.5 34v8h9v-8"/>',
    "desktop": '<path d="M24.5 28.5h15v10h-15zM29 43h6M32 38.5V43"/>',
    "templates": '<path d="M25.5 28.5h13v14h-13zM25.5 33h13M30 33v9.5"/>',
    "share": '<circle cx="27" cy="35" r="2.4"/><circle cx="37" cy="29.5" r="2.4"/><circle cx="37" cy="40.5" r="2.4"/><path d="M29.1 33.8l5.8-3.1M29.1 36.2l5.8 3.1"/>',
}

# 아이콘 이름(freedesktop / Breeze) → 기호
ICONS = {
    "folder": "",
    "folder-open": "",
    "inode-directory": "",
    "folder-documents": "doc",
    "folder-download": "down",
    "folder-downloads": "down",
    "folder-pictures": "pic",
    "folder-images": "pic",
    "folder-music": "music",
    "folder-sound": "music",
    "folder-videos": "video",
    "folder-video": "video",
    "user-home": "home",
    "folder-home": "home",
    "user-desktop": "desktop",
    "folder-desktop": "desktop",
    "folder-templates": "templates",
    "folder-publicshare": "share",
}


def svg(theme: dict, glyph: str) -> str:
    g = GLYPHS[glyph]
    glyph_group = (
        f'\n  <g fill="none" stroke="{theme["glyph"]}" stroke-opacity="{theme["glyph_opacity"]}" '
        f'stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">{g}</g>'
        if g else ""
    )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">\n'
        f'  <path fill="{theme["back"]}" d="{BACK}"/>\n'
        f'  <path fill="{theme["front"]}" d="{FRONT}"/>'
        f"{glyph_group}\n</svg>\n"
    )


for theme_id, theme in THEMES.items():
    base = ROOT / "system_files" / "usr" / "share" / "icons" / theme_id
    out = base / "places" / "scalable"
    out.mkdir(parents=True, exist_ok=True)
    for name, glyph in ICONS.items():
        (out / f"{name}.svg").write_text(svg(theme, glyph), encoding="utf-8")
    (base / "index.theme").write_text(
        "[Icon Theme]\n"
        f"Name={theme['name']}\n"
        "Comment=Dalbit OS folder icons (F1 flat)\n"
        f"Inherits={theme['inherits']}\n"
        "Directories=places/scalable\n\n"
        "[places/scalable]\n"
        "Size=64\nMinSize=16\nMaxSize=512\nType=Scalable\nContext=Places\n",
        encoding="utf-8",
    )
    print(f"{theme_id}: {len(ICONS)} icons")
