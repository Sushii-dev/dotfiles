import QtQuick
import org.kde.kirigami as Kirigami

/*
 * Visualizer — matugen-themed audio spectrum (Reddit-post style).
 *
 * `levels` = bar magnitudes 0..100 from the cava statefile. A few bold rounded
 * accent bars react to audio. NO canned idle animation: when silent the bars
 * ease down to a small flat restLevel (an EQ at rest); they only jump on real
 * audio. This is a true visualizer, not a looping shimmer.
 */
Item {
    id: vis

    property var levels: []
    property int barHint: 6
    property real restLevel: 12          // resting bar magnitude 0..100 (flat, calm)
    property color baseColor: Kirigami.Theme.highlightColor
    property bool active: true

    property var _disp: []

    Timer {
        interval: 16
        repeat: true
        running: vis.visible && vis.active
        onTriggered: {
            var src = vis.levels;
            var n = (src && src.length > 0) ? src.length : vis.barHint;
            if (vis._disp.length !== n) {
                var seed = [];
                for (var s = 0; s < n; ++s) seed.push(vis.restLevel);
                vis._disp = seed;
            }
            var d = vis._disp;
            var changed = false;
            for (var i = 0; i < n; ++i) {
                var target = (src && src.length === n) ? Math.max(src[i], vis.restLevel) : vis.restLevel;
                var k = target > d[i] ? 0.5 : 0.16;   // snappy rise, smooth fall
                var nv = d[i] + (target - d[i]) * k;
                if (Math.abs(nv - d[i]) > 0.05) changed = true;
                d[i] = nv;
            }
            vis._disp = d;
            if (changed) canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            var d = vis._disp;
            var n = d ? d.length : 0;
            if (n === 0 || width <= 0 || height <= 0) return;

            var slot = width / n;
            var bw = Math.max(3, slot * 0.66);    // bold bars
            var radius = bw * 0.5;

            for (var i = 0; i < n; ++i) {
                var mag = Math.max(0, Math.min(100, d[i])) / 100;
                var h = Math.max(bw, mag * height);   // never thinner than a rounded dot's diameter
                var x = i * slot + (slot - bw) / 2;
                var y = height - h;
                var r = Math.min(radius, h / 2);

                var grad = ctx.createLinearGradient(0, y, 0, height);
                grad.addColorStop(0, vis.baseColor);
                grad.addColorStop(1, Qt.rgba(vis.baseColor.r, vis.baseColor.g, vis.baseColor.b, 0.6));
                ctx.fillStyle = grad;

                ctx.beginPath();
                ctx.moveTo(x, height);
                ctx.lineTo(x, y + r);
                ctx.quadraticCurveTo(x, y, x + r, y);
                ctx.lineTo(x + bw - r, y);
                ctx.quadraticCurveTo(x + bw, y, x + bw, y + r);
                ctx.lineTo(x + bw, height);
                ctx.closePath();
                ctx.fill();
            }
        }
    }
}
