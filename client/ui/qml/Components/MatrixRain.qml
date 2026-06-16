import QtQuick

// ─── Matrix-rain фон (Fresh VPN) — порт 1:1 из дизайн-хэндоффа (ui.jsx MatrixRain) ───
// Trail-free: каждая колонка держит «голову» + призраков с быстрым затуханием,
// каждый кадр canvas полностью очищается — без длинных хвостов.
// Нейтральные символы (точки/линии/блоки), БЕЗ "01"/"VPN", чтобы не выглядело как «вас взламывают».
// Лёгкий: один Canvas + Timer 22fps, рисует только когда видим (батарея/перф).
Canvas {
    id: matrix

    // Параметры = канон дизайна
    property color glyphColor: "#A8D63A"
    property real density: 0.7
    property real speedFactor: 1.0
    property real baseOpacity: 0.18

    readonly property int fontSize: 11      // меньше шрифт → больше колонок
    readonly property int colStep: 11       // расстояние между колонками по X
    readonly property string glyphs: "·∙•∘░▒│┊"
    readonly property int trail: 5
    readonly property var trailAlphas: [1.0, 0.62, 0.38, 0.22, 0.11, 0.04]

    property var cols: []
    property bool ready: false

    antialiasing: false

    function pickChar() {
        return glyphs.charAt(Math.floor(Math.random() * glyphs.length))
    }

    function rebuild() {
        if (width <= 0 || height <= 0)
            return
        var colCount = Math.max(1, Math.floor(width / colStep))
        var arr = []
        for (var i = 0; i < colCount; i++) {
            var hist = []
            for (var h = 0; h < trail + 1; h++)
                hist.push(pickChar())
            arr.push({
                "x": i * colStep,
                "y": -Math.random() * height,
                "v": (0.4 + Math.random() * 1.1) * speedFactor,
                "on": Math.random() < density,
                "wait": Math.floor(Math.random() * 60),
                "lastLine": null,
                "history": hist
            })
        }
        cols = arr
        ready = true
    }

    onWidthChanged: rebuild()
    onHeightChanged: rebuild()
    Component.onCompleted: rebuild()

    onPaint: {
        if (!ready)
            return
        var ctx = getContext("2d")
        if (!ctx)
            return
        ctx.clearRect(0, 0, width, height)
        ctx.font = fontSize + "px 'JetBrains Mono', monospace"
        ctx.textBaseline = "top"
        ctx.fillStyle = glyphColor

        for (var c = 0; c < cols.length; c++) {
            var col = cols[c]
            if (!col.on) {
                col.wait--
                if (col.wait <= 0) {
                    col.on = true
                    col.y = -fontSize
                }
                continue
            }
            col.y += col.v * fontSize

            // символ меняется только при пересечении целой строки →
            // скорость смены символа = скорости падения, не fps
            var line = Math.floor(col.y / fontSize)
            if (line !== col.lastLine) {
                col.history.unshift(pickChar())
                col.history.length = trail + 1
                col.lastLine = line
            }

            for (var i = 0; i <= trail; i++) {
                var yi = col.y - i * fontSize
                if (yi < -fontSize || yi > height + fontSize)
                    continue
                ctx.globalAlpha = baseOpacity * trailAlphas[i]
                ctx.fillText(col.history[i], col.x, yi)
            }

            if (col.y > height + fontSize * (trail + 2)) {
                col.on = Math.random() < density
                col.y = -fontSize
                col.wait = Math.floor(Math.random() * 25)
            }
        }
        ctx.globalAlpha = 1
    }

    // 22 fps — рисуем только пока элемент виден (страница активна / окно на экране)
    Timer {
        interval: Math.round(1000 / 22)
        running: matrix.visible
        repeat: true
        onTriggered: matrix.requestPaint()
    }
}
