import QtQuick 6.2
import QtQuick.Controls 6.2
import QtQuick.Layouts 1.15
import QtQuick.Effects

Rectangle {
    id: chordCircle
    width: 500
    height: 500

    property string selectedKey: ""
    property string selectedScale: "Major" // Default scale type

    signal keySelected(string key, string scale)

    // Exposed properties for keys
    property var majorKeys: [
        "C", "G", "D", "A", "E", "B",
        "F♯/G♭", "C♯/D♭", "G♯/A♭",
        "D♯/E♭", "A♯/B♭", "F"
    ]

    property var minorKeys: [
        "Am", "Em", "Bm", "F♯m", "C♯m", "G♯m",
        "D♯m/E♭m", "A♯m/B♭m", "Fm", "Cm", "Gm", "Dm"
    ]

    // Background with blur effect
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: "transparent"
    }

    // Main Circle representing Major Keys
    Canvas {
        id: majorCircle
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: width

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            // Circle background
            ctx.beginPath()
            ctx.arc(width/2, height/2, width/2, 0, 2 * Math.PI)
            ctx.fillStyle = "rgba(255, 255, 255, 0.1)"
            ctx.fill()

            // Draw chord segments
            var segmentAngle = (2 * Math.PI) / chordCircle.majorKeys.length
            for (var i = 0; i < chordCircle.majorKeys.length; i++) {
                ctx.beginPath()
                ctx.moveTo(width/2, height/2)
                ctx.arc(
                    width/2,
                    height/2,
                    width/2 * 0.9,
                    i * segmentAngle,
                    (i + 1) * segmentAngle
                )
                ctx.closePath()

                // Color gradient for segments
                var gradient = ctx.createRadialGradient(
                    width/2, height/2, 0,
                    width/2, height/2, width/2
                )
                gradient.addColorStop(0, `hsla(${i * 30}, 70%, 55%, 0.6)`)
                gradient.addColorStop(1, `hsla(${i * 30}, 70%, 35%, 0.5)`)

                ctx.fillStyle = gradient
                ctx.fill()

                // Draw key labels without rotation
                ctx.save()
                var angle = i * segmentAngle + segmentAngle / 2
                var x = width / 2 + Math.cos(angle) * width / 2.7
                var y = height / 2 + Math.sin(angle) * height / 2.7
                ctx.fillStyle = "white"
                ctx.font = "bold 12px 'Inter'"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(chordCircle.majorKeys[i], x, y)
                ctx.restore()
            }
        }
    }

    // Inner Circle representing Minor Keys
    Canvas {
        id: minorCircle
        anchors.centerIn: parent
        width: parent.width * 0.5
        height: width

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            // Inner circle background
            ctx.beginPath()
            ctx.arc(width/2, height/2, width/2, 0, 2 * Math.PI)
            ctx.fillStyle = "rgba(0, 0, 0, 0.4)"
            ctx.fill()

            // Draw minor key segments
            var segmentAngle = (2 * Math.PI) / chordCircle.minorKeys.length
            for (var i = 0; i < chordCircle.minorKeys.length; i++) {
                ctx.beginPath()
                ctx.moveTo(width/2, height/2)
                ctx.arc(
                    width/2,
                    height/2,
                    width/2 * 0.9,
                    i * segmentAngle,
                    (i + 1) * segmentAngle
                )
                ctx.closePath()

                // Color gradient for minor key segments
                var gradient = ctx.createRadialGradient(
                    width/2, height/2, 0,
                    width/2, height/2, width/2
                )
                gradient.addColorStop(0, `hsla(${i * 30 + 180}, 50%, 45%, 0.6)`)
                gradient.addColorStop(1, `hsla(${i * 30 + 180}, 50%, 25%, 0.5)`)

                ctx.fillStyle = gradient
                ctx.fill()

                // Draw minor key labels without rotation
                ctx.save()
                var angle = i * segmentAngle + segmentAngle / 2
                var x = width / 2 + Math.cos(angle) * width / 3
                var y = height / 2 + Math.sin(angle) * height / 3
                ctx.fillStyle = "white"
                ctx.font = "9px 'Inter'"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(chordCircle.minorKeys[i], x, y)
                ctx.restore()
            }
        }
    }

    // Interactive hover/select behavior
    MouseArea {
        anchors.fill: parent

        onClicked: (mouse) => {
            var distanceFromCenter = Math.sqrt(
                Math.pow(mouse.x - width/2, 2) +
                Math.pow(mouse.y - height/2, 2)
            )

            if (distanceFromCenter <= majorCircle.width/2) {
                var angle = Math.atan2(
                    mouse.y - height/2,
                    mouse.x - width/2
                )
                if (angle < 0) angle += 2 * Math.PI

                var segmentIndex = Math.floor(
                    angle / ((2 * Math.PI) / chordCircle.majorKeys.length)
                )

                console.log("Selected Major Key: " + chordCircle.majorKeys[segmentIndex])
            }

            if (distanceFromCenter <= minorCircle.width/2) {
                var angle = Math.atan2(
                    mouse.y - height/2,
                    mouse.x - width/2
                )
                if (angle < 0) angle += 2 * Math.PI

                var segmentIndex = Math.floor(
                    angle / ((2 * Math.PI) / chordCircle.minorKeys.length)
                )

                console.log("Selected Minor Key: " + chordCircle.minorKeys[segmentIndex])
            }
        }
    }
}
