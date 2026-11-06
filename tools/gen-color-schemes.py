"""Dalbit 색 구성표(.colors) 생성기: Dusk(다크) / Mist(라이트).

실행: python tools/gen-color-schemes.py  (저장소 루트에서)
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "system_files" / "usr" / "share" / "color-schemes"

SCHEMES = {
    "DalbitDark": {
        "name": "Dalbit Dark", "name_ko": "달빛 다크",
        "window": ((30, 32, 36), (36, 39, 44)),
        "view": ((25, 27, 31), (29, 31, 36)),
        "button": ((42, 45, 51), (36, 39, 44)),
        "header": ((26, 28, 32), (30, 32, 36)),
        "header_inactive": ((30, 32, 36), (26, 28, 32)),
        "tooltip": ((42, 45, 51), (36, 39, 44)),
        "complementary": ((15, 17, 20), (21, 23, 27)),
        "fg": (236, 238, 242), "fg_inactive": (149, 155, 166),
        "accent": (169, 184, 216), "accent_alt": (143, 158, 192),
        "sel_fg": (17, 19, 23), "sel_fg_inactive": (42, 45, 51),
        "link": (185, 199, 230), "visited": (199, 185, 230),
        "negative": (229, 112, 122), "neutral": (217, 194, 138), "positive": (124, 203, 156),
        "comp_fg": (236, 238, 242), "comp_fg_inactive": (149, 155, 166),
        "disabled_color": (30, 32, 36),
    },
    "DalbitLight": {
        "name": "Dalbit Light", "name_ko": "달빛 라이트",
        "window": ((238, 240, 243), (230, 233, 237)),
        "view": ((255, 255, 255), (246, 247, 249)),
        "button": ((226, 229, 234), (217, 221, 227)),
        "header": ((230, 233, 237), (238, 240, 243)),
        "header_inactive": ((238, 240, 243), (230, 233, 237)),
        "tooltip": ((247, 248, 250), (238, 240, 243)),
        "complementary": ((30, 32, 36), (26, 28, 32)),
        "fg": (30, 33, 39), "fg_inactive": (107, 113, 124),
        "accent": (95, 119, 174), "accent_alt": (120, 141, 190),
        "sel_fg": (255, 255, 255), "sel_fg_inactive": (226, 229, 234),
        "link": (74, 99, 160), "visited": (122, 91, 168),
        "negative": (194, 65, 78), "neutral": (168, 122, 18), "positive": (46, 138, 87),
        "comp_fg": (236, 238, 242), "comp_fg_inactive": (149, 155, 166),
        "disabled_color": (238, 240, 243),
    },
}


def c(rgb):
    return ",".join(str(v) for v in rgb)


def group(s, bg, fg, fg_inactive):
    a = s["accent"]
    return (
        f"BackgroundAlternate={c(bg[1])}\nBackgroundNormal={c(bg[0])}\n"
        f"DecorationFocus={c(a)}\nDecorationHover={c(a)}\n"
        f"ForegroundActive={c(a)}\nForegroundInactive={c(fg_inactive)}\n"
        f"ForegroundLink={c(s['link'])}\nForegroundNegative={c(s['negative'])}\n"
        f"ForegroundNeutral={c(s['neutral'])}\nForegroundNormal={c(fg)}\n"
        f"ForegroundPositive={c(s['positive'])}\nForegroundVisited={c(s['visited'])}\n"
    )


for scheme_id, s in SCHEMES.items():
    fg, fgi = s["fg"], s["fg_inactive"]
    a, sf = s["accent"], s["sel_fg"]
    text = (
        "[ColorEffects:Disabled]\n"
        f"Color={c(s['disabled_color'])}\nColorAmount=0\nColorEffect=0\nContrastAmount=0.65\n"
        "ContrastEffect=1\nIntensityAmount=0.1\nIntensityEffect=2\n\n"
        "[ColorEffects:Inactive]\nChangeSelectionColor=true\n"
        f"Color={c(s['complementary'][0])}\nColorAmount=0.025\nColorEffect=2\nContrastAmount=0.1\n"
        "ContrastEffect=2\nEnable=false\nIntensityAmount=0\nIntensityEffect=0\n\n"
        "[Colors:Button]\n" + group(s, s["button"], fg, fgi) + "\n"
        "[Colors:Complementary]\n" + group(s, s["complementary"], s["comp_fg"], s["comp_fg_inactive"]) + "\n"
        "[Colors:Header]\n" + group(s, s["header"], fg, fgi) + "\n"
        "[Colors:Header][Inactive]\n" + group(s, s["header_inactive"], fg, fgi) + "\n"
        "[Colors:Selection]\n"
        f"BackgroundAlternate={c(s['accent_alt'])}\nBackgroundNormal={c(a)}\n"
        f"DecorationFocus={c(a)}\nDecorationHover={c(a)}\n"
        f"ForegroundActive={c(sf)}\nForegroundInactive={c(s['sel_fg_inactive'])}\n"
        f"ForegroundLink={c(sf)}\nForegroundNegative={c(sf)}\nForegroundNeutral={c(sf)}\n"
        f"ForegroundNormal={c(sf)}\nForegroundPositive={c(sf)}\nForegroundVisited={c(sf)}\n\n"
        "[Colors:Tooltip]\n" + group(s, s["tooltip"], fg, fgi) + "\n"
        "[Colors:View]\n" + group(s, s["view"], fg, fgi) + "\n"
        "[Colors:Window]\n" + group(s, s["window"], fg, fgi) + "\n"
        "[General]\n"
        f"ColorScheme={scheme_id}\nName={s['name']}\nName[ko]={s['name_ko']}\nshadeSortColumn=true\n\n"
        "[KDE]\ncontrast=4\n\n"
        "[WM]\n"
        f"activeBackground={c(s['header'][0])}\nactiveBlend={c(fg)}\nactiveForeground={c(fg)}\n"
        f"inactiveBackground={c(s['header_inactive'][0])}\ninactiveBlend={c(fgi)}\ninactiveForeground={c(fgi)}\n"
    )
    (OUT / f"{scheme_id}.colors").write_text(text, encoding="utf-8")
    print(f"{scheme_id}.colors written")
