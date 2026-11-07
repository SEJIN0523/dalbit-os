/*
 * 오늘의 달 모양 (북반구 기준: 차오르는 달은 오른쪽이 밝음) + 로고의 네 갈래 별
 * phase: 0 = 삭, 0.25 = 상현, 0.5 = 보름, 0.75 = 하현
 */
import QtQuick

Canvas {
    id: canvas

    property real phase: 0
    property color color: "white"
    property bool showStar: true

    onPhaseChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const s = Math.min(width, height)
        // 별이 들어갈 자리를 오른쪽 위에 남김
        const r = showStar ? s * 0.40 : s * 0.48
        const cx = showStar ? s * 0.44 : width / 2
        const cy = showStar ? s * 0.56 : height / 2

        // 어두운 부분: 은은하게 원 전체
        ctx.globalAlpha = 0.16
        ctx.fillStyle = canvas.color
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.fill()

        // 밝은 부분: 바깥 테두리 반원 + 명암 경계(타원 반쪽)
        ctx.globalAlpha = 1
        const waxing = phase < 0.5
        const k = Math.cos(2 * Math.PI * phase)
        const n = 32
        ctx.beginPath()
        for (let i = 0; i <= n; i++) {
            const a = -Math.PI / 2 + Math.PI * i / n
            const x = Math.cos(a) * r
            const px = cx + (waxing ? x : -x), py = cy + Math.sin(a) * r
            if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
        }
        for (let i = 0; i <= n; i++) {
            const a = Math.PI / 2 - Math.PI * i / n
            const x = Math.cos(a) * r * k
            ctx.lineTo(cx + (waxing ? x : -x), cy + Math.sin(a) * r)
        }
        ctx.closePath()
        ctx.fill()

        if (!showStar) return
        // 네 갈래 별 (로고와 같은 모양)
        const sx = s * 0.86, sy = s * 0.16, sr = s * 0.15, t = sr * 0.11
        ctx.beginPath()
        ctx.moveTo(sx, sy - sr)
        ctx.bezierCurveTo(sx + t, sy - t, sx + t, sy - t, sx + sr, sy)
        ctx.bezierCurveTo(sx + t, sy + t, sx + t, sy + t, sx, sy + sr)
        ctx.bezierCurveTo(sx - t, sy + t, sx - t, sy + t, sx - sr, sy)
        ctx.bezierCurveTo(sx - t, sy - t, sx - t, sy - t, sx, sy - sr)
        ctx.closePath()
        ctx.fill()
    }
}
