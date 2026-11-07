"""Dalbit 맥 스타일 창 장식(Aurorae) 생성기: DalbitMac(다크) / DalbitMacLight(라이트).

실행: python tools/gen-mac-decorations.py  (저장소 루트에서)

구조 (Aurorae = SVG를 9조각으로 잘라 창 둘레에 늘려 붙이는 방식)
- decoration.svg: 그림자 + 둥근 제목 표시줄. 조각 크기가 곧 자르는 기준이므로
  왼쪽·오른쪽·아래 조각은 창 안쪽으로 OVER 만큼 겹쳐 그림 (그 부분은 창 내용에 가려짐).
  이렇게 해야 위 모서리의 둥근 부분이 늘어나지 않고 그대로 유지됨.
- close/minimize/maximize/restore.svg: 동그란 버튼. 마우스를 올리면 ×, −, + 기호.
- 버튼 위치·순서는 테마가 아니라 kwinrc(ButtonsOnLeft/Right)로 정함 → dalbit-theme
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "system_files" / "usr" / "share" / "aurorae" / "themes"

PAD = 22      # 그림자 폭
RADIUS = 10   # 제목 표시줄 위 모서리 둥글기
TITLE = 36    # 제목 표시줄 높이
OVER = 12     # 창 안쪽으로 겹쳐 그리는 폭 (창 내용에 가려짐)
STRETCH = 8   # 늘어나는 조각의 기본 길이
BTN_W = 22    # 버튼 칸 너비 (동그라미 지름 13 + 여백)
DOT_R = 6.5

THEMES = {
    "DalbitMac": {
        "name": "Dalbit Mac", "name_ko": "달빛 맥",
        "title": "#1A1C20", "title_inactive": "#1E2024", "window": "#1E2024",
        "outline": ("#FFFFFF", 0.07), "outline_inactive": ("#FFFFFF", 0.05),
        "shadow": 0.50, "shadow_inactive": 0.32,
        "text": (236, 238, 242), "text_inactive": (149, 155, 166),
        "close": "#E5707A", "minimize": "#D9C28A", "maximize": "#7CCB9C",
        "off": "#454951", "glyph": "#000000", "glyph_op": 0.55, "ring": 0.18,
    },
    "DalbitMacLight": {
        "name": "Dalbit Mac Light", "name_ko": "달빛 맥 라이트",
        "title": "#E6E9ED", "title_inactive": "#EEF0F3", "window": "#EEF0F3",
        "outline": ("#000000", 0.14), "outline_inactive": ("#000000", 0.10),
        "shadow": 0.22, "shadow_inactive": 0.12,
        "text": (30, 33, 39), "text_inactive": (107, 113, 124),
        "close": "#E0606C", "minimize": "#D8AE48", "maximize": "#5DB884",
        "off": "#C9CDD4", "glyph": "#000000", "glyph_op": 0.5, "ring": 0.12,
    },
}


def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n<defs>\n{defs}</defs>\n{body}</svg>\n')


def gradients(sp, op):
    """그림자 그라데이션: 창 가장자리(진함) → 바깥(투명). 바깥쪽으로 빠르게 옅어지도록 3단계.
    sp = 상태 접두어(a-: 활성, i-: 비활성)."""
    def stops(start=0.0):
        k = 1 - start
        return (f'<stop offset="{start:.3f}" stop-color="#000" stop-opacity="{op:.3f}"/>'
                f'<stop offset="{start + 0.35 * k:.3f}" stop-color="#000" stop-opacity="{op * 0.45:.3f}"/>'
                '<stop offset="1" stop-color="#000" stop-opacity="0"/>')
    out = []
    # 직선 그림자: 각 방향 창 쪽 → 바깥쪽
    for k, (x1, y1, x2, y2) in {"t": (0, 1, 0, 0), "b": (0, 0, 0, 1), "l": (1, 0, 0, 0)}.items():
        out.append(f'<linearGradient id="{sp}sh-{k}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{stops()}</linearGradient>\n')
    # 위 모서리: 중심 = 둥근 모서리의 중심, 반지름 RADIUS까지는 진하게
    c = PAD + RADIUS
    out.append(f'<radialGradient id="{sp}sh-ct" gradientUnits="userSpaceOnUse" cx="{c}" cy="{c}" r="{c}">'
               f'{stops(RADIUS / c)}</radialGradient>\n')
    # 아래 모서리: 중심 = 창의 각진 꼭짓점
    out.append(f'<radialGradient id="{sp}sh-cb" gradientUnits="userSpaceOnUse" cx="{PAD}" cy="{OVER}" r="{PAD}">'
               f'{stops()}</radialGradient>\n')
    return "".join(out)


def decoration(t):
    """decoration.svg: 활성/비활성 9조각 + 최대화용 가운데 조각.
    각 조각의 내용은 반드시 자기 크기 안에만 그림 (조각 크기 = 자르는 기준)."""
    side = PAD + OVER          # 왼쪽·오른쪽 조각 너비, 아래 조각 높이
    top = PAD + TITLE          # 위 조각 높이
    cw = STRETCH
    r = RADIUS
    c = PAD + r
    X = [0, side + 10, side + 10 + cw + 10]
    Yoff = [0, top + 10, top + 10 + cw + 10]
    block_h = Yoff[2] + side + 20
    defs, body = [], []

    def piece(prefix, sp, y0, title_col, outline, shadow_op):
        defs.append(gradients(sp, shadow_op))
        oc, oo = outline
        Y = [y0 + v for v in Yoff]

        def el(name, x, y, w, h, inner):
            body.append(f'<g id="{prefix}-{name}" transform="translate({x} {y})">'
                        f'<rect width="{w}" height="{h}" fill="#000" fill-opacity="0"/>{inner}</g>\n')

        # 위-왼쪽: 모서리 그림자 + 둥근 제목 표시줄 시작
        tl = (f'<rect width="{c}" height="{c}" fill="url(#{sp}sh-ct)"/>'
              f'<rect x="{c}" width="{side - c}" height="{PAD}" fill="url(#{sp}sh-t)"/>'
              f'<rect y="{c}" width="{PAD}" height="{top - c}" fill="url(#{sp}sh-l)"/>'
              f'<path d="M{PAD} {top} V{c} A{r} {r} 0 0 1 {c} {PAD} H{side} V{top} Z" fill="{title_col}"/>'
              f'<path d="M{PAD + 0.5} {top} V{c} A{r - 0.5} {r - 0.5} 0 0 1 {c} {PAD + 0.5} H{side}" '
              f'fill="none" stroke="{oc}" stroke-opacity="{oo}"/>')
        el("topleft", X[0], Y[0], side, top, tl)
        tp = (f'<rect width="{cw}" height="{PAD}" fill="url(#{sp}sh-t)"/>'
              f'<rect y="{PAD}" width="{cw}" height="{TITLE}" fill="{title_col}"/>'
              f'<rect y="{PAD}" width="{cw}" height="1" fill="{oc}" fill-opacity="{oo}"/>')
        el("top", X[1], Y[0], cw, top, tp)
        el("topright", X[2], Y[0], side, top, f'<g transform="translate({side} 0) scale(-1 1)">{tl}</g>')
        # 왼쪽 / 오른쪽: 그림자 + (창 내용에 가려지는) 창 바탕
        lf = (f'<rect width="{PAD}" height="{cw}" fill="url(#{sp}sh-l)"/>'
              f'<rect x="{PAD}" width="{OVER}" height="{cw}" fill="{t["window"]}"/>'
              f'<rect x="{PAD}" width="1" height="{cw}" fill="{oc}" fill-opacity="{oo}"/>')
        el("left", X[0], Y[1], side, cw, lf)
        el("center", X[1], Y[1], cw, cw, f'<rect width="{cw}" height="{cw}" fill="{t["window"]}"/>')
        el("right", X[2], Y[1], side, cw, f'<g transform="translate({side} 0) scale(-1 1)">{lf}</g>')
        # 아래: 창 내용이 각져 있으므로 아래 모서리는 각지게
        bl = (f'<rect width="{PAD}" height="{OVER}" fill="url(#{sp}sh-l)"/>'
              f'<rect y="{OVER}" width="{PAD}" height="{PAD}" fill="url(#{sp}sh-cb)"/>'
              f'<rect x="{PAD}" width="{OVER}" height="{OVER}" fill="{t["window"]}"/>'
              f'<rect x="{PAD}" y="{OVER}" width="{OVER}" height="{PAD}" fill="url(#{sp}sh-b)"/>'
              f'<path d="M{PAD + 0.5} 0 V{OVER - 0.5} H{side}" fill="none" stroke="{oc}" stroke-opacity="{oo}"/>')
        el("bottomleft", X[0], Y[2], side, side, bl)
        bt = (f'<rect width="{cw}" height="{OVER}" fill="{t["window"]}"/>'
              f'<rect y="{OVER}" width="{cw}" height="{PAD}" fill="url(#{sp}sh-b)"/>'
              f'<rect y="{OVER - 1}" width="{cw}" height="1" fill="{oc}" fill-opacity="{oo}"/>')
        el("bottom", X[1], Y[2], cw, side, bt)
        el("bottomright", X[2], Y[2], side, side, f'<g transform="translate({side} 0) scale(-1 1)">{bl}</g>')

    piece("decoration", "a-", 0, t["title"], t["outline"], t["shadow"])
    piece("decoration-inactive", "i-", block_h, t["title_inactive"], t["outline_inactive"], t["shadow_inactive"])
    # 최대화: 그림자·둥근 모서리 없이 제목 표시줄만 (가운데 조각만 사용됨)
    y = block_h * 2
    for name, col in (("decoration-maximized-center", t["title"]),
                      ("decoration-maximized-inactive-center", t["title_inactive"])):
        body.append(f'<rect id="{name}" x="0" y="{y}" width="{cw}" height="{cw}" fill="{col}"/>\n')
        y += cw + 10
    return svg(X[2] + side, y + 10, "".join(body), "".join(defs))


GLYPHS = {
    "close": lambda cx, cy: f'M{cx-2.4} {cy-2.4}L{cx+2.4} {cy+2.4}M{cx+2.4} {cy-2.4}L{cx-2.4} {cy+2.4}',
    "minimize": lambda cx, cy: f'M{cx-2.9} {cy}H{cx+2.9}',
    "maximize": lambda cx, cy: f'M{cx-2.9} {cy}H{cx+2.9}M{cx} {cy-2.9}V{cy+2.9}',
    # 이전 크기로: 안쪽을 향한 두 화살촉
    "restore": lambda cx, cy: (f'M{cx-0.6} {cy-3}V{cy-0.6}H{cx-3}M{cx+0.6} {cy+3}V{cy+0.6}H{cx+3}'),
}


def button(t, kind):
    color = t["close" if kind == "close" else "minimize" if kind == "minimize" else "maximize"]
    w, h = BTN_W, TITLE
    cx, cy = w / 2, h / 2
    states = [
        # (요소 이름, 원 색, 불투명도, 기호, 원 밝기 조절)
        ("active", color, 1.0, False, None),
        ("hover", color, 1.0, True, None),
        ("pressed", color, 1.0, True, ("#000000", 0.22)),
        ("inactive", t["off"], 1.0, False, None),
        ("hover-inactive", color, 1.0, True, None),
        ("pressed-inactive", color, 1.0, True, ("#000000", 0.22)),
        ("deactivated", t["off"], 0.55, False, None),
        ("deactivated-inactive", t["off"], 0.4, False, None),
    ]
    body = []
    for i, (name, col, op, glyph, tint) in enumerate(states):
        x = i * (w + 4)
        g = [f'<rect width="{w}" height="{h}" fill="#000" fill-opacity="0"/>',
             f'<circle cx="{cx}" cy="{cy}" r="{DOT_R}" fill="{col}" fill-opacity="{op}"/>',
             f'<circle cx="{cx}" cy="{cy}" r="{DOT_R - 0.4}" fill="none" stroke="#000" '
             f'stroke-opacity="{t["ring"] * op:.3f}" stroke-width="0.8"/>']
        if tint:
            g.append(f'<circle cx="{cx}" cy="{cy}" r="{DOT_R}" fill="{tint[0]}" fill-opacity="{tint[1]}"/>')
        if glyph:
            g.append(f'<path d="{GLYPHS[kind](cx, cy)}" fill="none" stroke="{t["glyph"]}" '
                     f'stroke-opacity="{t["glyph_op"]}" stroke-width="1.3" stroke-linecap="round"/>')
        body.append(f'<g id="{name}-center" transform="translate({x} 0)">{"".join(g)}</g>\n')
    return svg(len(states) * (w + 4), h, "".join(body))


def rc(t):
    c = lambda rgb: ",".join(str(v) for v in rgb) + ",255"
    return f"""[General]
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=120
ActiveTextColor={c(t['text'])}
InactiveTextColor={c(t['text_inactive'])}
UseTextShadow=false
Shadow=true
LeftButtons=
RightButtons=IAX

[Layout]
BorderLeft=0
BorderRight=0
BorderBottom=0
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=10
TitleEdgeRight=10
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=10
TitleEdgeRightMaximized=10
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={TITLE}
ButtonWidth={BTN_W}
ButtonHeight={TITLE}
ButtonSpacing=0
ButtonMarginTop=0
ExplicitButtonSpacer=10
PaddingTop={PAD}
PaddingBottom={PAD}
PaddingLeft={PAD}
PaddingRight={PAD}
"""


for theme_id, t in THEMES.items():
    d = OUT / theme_id
    d.mkdir(parents=True, exist_ok=True)
    (d / "decoration.svg").write_text(decoration(t))
    for kind in ("close", "minimize", "maximize", "restore"):
        (d / f"{kind}.svg").write_text(button(t, kind))
    (d / f"{theme_id}rc").write_text(rc(t))
    (d / "metadata.desktop").write_text(
        "[Desktop Entry]\n"
        f"Name={t['name']}\nName[ko]={t['name_ko']}\n"
        "Comment=Dalbit OS window decoration with round buttons\n"
        "Comment[ko]=동그란 버튼의 Dalbit 창 장식\n"
        "X-KDE-PluginInfo-Author=SEJIN0523\n"
        f"X-KDE-PluginInfo-Name={theme_id}\n"
        "X-KDE-PluginInfo-Version=1.0\n"
        "X-KDE-PluginInfo-License=GPL-2.0-or-later\n"
        "X-KDE-PluginInfo-Website=https://github.com/SEJIN0523/dalbit-os\n"
    )
    (d / "metadata.json").write_text(json.dumps({
        "KPlugin": {
            "Authors": [{"Name": "SEJIN0523"}],
            "Description": "Dalbit OS window decoration with round buttons",
            "Description[ko]": "동그란 버튼의 Dalbit 창 장식",
            "Id": theme_id,
            "License": "GPL-2.0-or-later",
            "Name": t["name"],
            "Name[ko]": t["name_ko"],
            "Version": "1.0",
            "Website": "https://github.com/SEJIN0523/dalbit-os",
        },
        "KPackageStructure": "KWin/Aurorae",
    }, ensure_ascii=False, indent=4) + "\n")
    print("생성:", d.relative_to(ROOT))
