"""Dalbit 한글 입력기(fcitx5) 후보 창 테마 생성기: dalbit-dark / dalbit-light.

실행: python tools/gen-fcitx5-themes.py  (저장소 루트에서)
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "system_files" / "usr" / "share" / "fcitx5" / "themes"

THEMES = {
    "dalbit-dark": {
        "name": "Dalbit Dark",
        "bg": "#1E2024", "border": "#30343B", "fg": "#ECEEF2", "mute": "#959BA6",
        "accent": "#A9B8D8", "accent_fg": "#111317", "sep": "#30343B",
    },
    "dalbit-light": {
        "name": "Dalbit Light",
        "bg": "#FFFFFF", "border": "#D3D7DE", "fg": "#1E2127", "mute": "#6B717C",
        "accent": "#5F77AE", "accent_fg": "#FFFFFF", "sep": "#E2E5EA",
    },
}


def margin(section: str, l: int, r: int, t: int, b: int) -> str:
    return f"[{section}]\nLeft={l}\nRight={r}\nTop={t}\nBottom={b}\n\n"


for theme_id, t in THEMES.items():
    text = (
        "[Metadata]\n"
        f"Name={t['name']}\nVersion=1\nAuthor=Dalbit OS\n"
        f"Description=Dalbit OS {t['name']} candidate window\nScaleWithDPI=True\n\n"
        "[InputPanel]\n"
        f"NormalColor={t['fg']}\nHighlightCandidateColor={t['accent_fg']}\n"
        f"HighlightColor={t['accent']}\nHighlightBackgroundColor={t['accent']}\n"
        "Spacing=4\nEnableBlur=False\n\n"
        + margin("InputPanel/TextMargin", 7, 7, 5, 5)
        + margin("InputPanel/ContentMargin", 4, 4, 4, 4)
        + "[InputPanel/Background]\n"
        f"Color={t['bg']}\nBorderColor={t['border']}\nBorderWidth=1\n\n"
        + margin("InputPanel/Background/Margin", 4, 4, 4, 4)
        + "[InputPanel/Highlight]\n"
        f"Color={t['accent']}\n\n"
        + margin("InputPanel/Highlight/Margin", 7, 7, 5, 5)
        + "[Menu]\n"
        f"NormalColor={t['fg']}\nHighlightCandidateColor={t['accent_fg']}\nSpacing=2\n\n"
        + "[Menu/Background]\n"
        f"Color={t['bg']}\nBorderColor={t['border']}\nBorderWidth=1\n\n"
        + margin("Menu/Background/Margin", 4, 4, 4, 4)
        + margin("Menu/ContentMargin", 4, 4, 4, 4)
        + "[Menu/Highlight]\n"
        f"Color={t['accent']}\n\n"
        + margin("Menu/Highlight/Margin", 6, 6, 4, 4)
        + "[Menu/Separator]\n"
        f"Color={t['sep']}\n\n"
        + margin("Menu/TextMargin", 8, 8, 5, 5)
    )
    d = OUT / theme_id
    d.mkdir(parents=True, exist_ok=True)
    (d / "theme.conf").write_text(text, encoding="utf-8", newline="\n")
    print(f"{theme_id}/theme.conf written")
