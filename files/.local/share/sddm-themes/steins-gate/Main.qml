// Steins;Gate × Tokyo Night — SDDM greeter theme (Qt 6)
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#16161e"

    // Everything is sized relative to a 1080p screen
    readonly property real s: height / 1080

    readonly property color bg:      "#1a1b26"
    readonly property color bgHl:    "#292e42"
    readonly property color fg:      "#c0caf5"
    readonly property color fgDim:   "#a9b1d6"
    readonly property color comment: "#565f89"
    readonly property color blue:    config.accent || "#7aa2f7"
    readonly property color magenta: "#bb9af7"
    readonly property color red:     "#f7768e"
    readonly property color nixie:   config.nixie || "#ff9e64"

    readonly property string monoFont: "JetBrainsMono Nerd Font"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string userName: userModel.lastUser

    // ---- Background: the divergence meter wallpaper, blurred and dimmed ----
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background || "background.png"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: wallpaper
        source: wallpaper
        blurEnabled: true
        blurMax: 64
        blur: 0.6
        brightness: -0.12
    }

    ListView {
        model: userModel
        visible: false
        width: 1; height: 1
        delegate: Item {
            // No remembered user yet (first boot): default to the first account
            Component.onCompleted: if (root.userName === "" && index === 0) root.userName = name
        }
    }

    // ---- Clock + date ----
    Column {
        id: clockColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: loginColumn.top
        anchors.bottomMargin: 70 * s
        spacing: 6 * s

        Item {
            width: clock.implicitWidth
            height: clock.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                id: clock
                font.family: "Noto Sans"
                font.weight: Font.Light
                font.pixelSize: 150 * s
                color: root.nixie
                text: Qt.formatTime(new Date(), "HH:mm")
                visible: false
            }
            MultiEffect {
                anchors.fill: clock
                source: clock
                shadowEnabled: true
                shadowColor: root.nixie
                shadowBlur: 1.0
                shadowOpacity: 0.75
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                autoPaddingEnabled: true
            }
        }

        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.monoFont
            font.pixelSize: 24 * s
            color: root.fg
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                clock.text = Qt.formatTime(new Date(), "HH:mm")
                dateText.text = Qt.formatDate(new Date(), "dddd, d MMMM")
            }
        }
    }

    // ---- Login ----
    Column {
        id: loginColumn
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 110 * s
        spacing: 16 * s
        width: 420 * s

        // User: shown as a label; editable field only if SDDM has no last user
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.userName !== ""
            font.family: root.monoFont
            font.pixelSize: 20 * s
            color: root.blue
            text: "  " + root.userName
        }

        TextField {
            id: userField
            visible: root.userName === ""
            width: parent.width
            height: 56 * s
            font.family: root.monoFont
            font.pixelSize: 18 * s
            color: root.fg
            placeholderText: "username"
            placeholderTextColor: root.comment
            horizontalAlignment: TextInput.AlignHCenter
            onTextChanged: root.userName = text
            background: Rectangle {
                radius: 16 * s
                color: Qt.rgba(0.10, 0.11, 0.15, 0.8)
                border.width: 2 * s
                border.color: userField.activeFocus ? root.blue : root.bgHl
            }
        }

        TextField {
            id: password
            width: parent.width
            height: 60 * s
            focus: true
            echoMode: TextInput.Password
            passwordCharacter: "●"
            font.family: root.monoFont
            font.pixelSize: 20 * s
            font.letterSpacing: 4 * s
            color: root.fg
            horizontalAlignment: TextInput.AlignHCenter
            onAccepted: root.doLogin()
            Keys.onEscapePressed: text = ""

            background: Rectangle {
                id: pwBox
                radius: 18 * s
                color: Qt.rgba(0.10, 0.11, 0.15, 0.8)
                border.width: 2 * s
                border.color: errorText.visible ? root.red
                             : (password.activeFocus ? root.blue : root.bgHl)
                Behavior on border.color { ColorAnimation { duration: 180 } }
            }

            // Own placeholder: the Basic style hides it on a focused, centred field
            Text {
                anchors.centerIn: parent
                visible: password.text.length === 0
                font.family: root.monoFont
                font.italic: true
                font.pixelSize: 18 * s
                color: root.comment
                text: "El Psy Kongroo…"
            }

            SequentialAnimation {
                id: shake
                loops: 1
                NumberAnimation { target: password; property: "x"; to: -12 * s; duration: 50 }
                NumberAnimation { target: password; property: "x"; to:  12 * s; duration: 50 }
                NumberAnimation { target: password; property: "x"; to:  -8 * s; duration: 50 }
                NumberAnimation { target: password; property: "x"; to:   8 * s; duration: 50 }
                NumberAnimation { target: password; property: "x"; to:   0;     duration: 50 }
            }
        }

        Text {
            id: errorText
            anchors.horizontalCenter: parent.horizontalCenter
            visible: false
            font.family: root.monoFont
            font.pixelSize: 15 * s
            color: root.red
            text: "Access denied — the worldline did not converge"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: keyboard.capsLock
            font.family: root.monoFont
            font.pixelSize: 14 * s
            color: root.nixie
            text: "  Caps Lock is on"
        }
    }

    function doLogin() {
        errorText.visible = false
        sddm.login(root.userName, password.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            errorText.visible = true
            shake.start()
            password.forceActiveFocus()
        }
    }

    // ---- Session picker (bottom-left) ----
    ListView {
        id: sessionList
        model: sessionModel
        currentIndex: root.sessionIndex
        visible: false
        width: 1; height: 1
        delegate: Item {
            property string sessionName: name
            // No remembered session yet: default to plain Hyprland (uwsm is not installed)
            Component.onCompleted: if (sessionModel.lastIndex < 0 && name === "Hyprland") root.sessionIndex = index
        }
    }

    Text {
        id: sessionButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 40 * s
        font.family: root.monoFont
        font.pixelSize: 16 * s
        color: sessionMouse.containsMouse ? root.blue : root.fgDim
        text: "  " + (sessionList.currentItem ? sessionList.currentItem.sessionName : "session") + "  "
        MouseArea {
            id: sessionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
        }
    }

    // ---- Power (bottom-right) ----
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 40 * s
        spacing: 28 * s

        Repeater {
            model: [
                { icon: "", tip: "Suspend",  color: "#7dcfff", can: sddm.canSuspend,  act: function() { sddm.suspend() } },
                { icon: "", tip: "Reboot",   color: "#ff9e64", can: sddm.canReboot,   act: function() { sddm.reboot() } },
                { icon: "", tip: "Shutdown", color: "#f7768e", can: sddm.canPowerOff, act: function() { sddm.powerOff() } }
            ]
            delegate: Text {
                required property var modelData
                visible: modelData.can
                font.family: root.monoFont
                font.pixelSize: 22 * s
                color: powerMouse.containsMouse ? modelData.color : root.fgDim
                text: modelData.icon
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    anchors.margins: -8 * s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.act()
                }
            }
        }
    }

    // ---- Footer ----
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44 * s
        font.family: root.monoFont
        font.pixelSize: 13 * s
        font.letterSpacing: 4 * s
        color: root.comment
        text: "WORLDLINE DIVERGENCE  ·  1.048596"
    }

    Component.onCompleted: password.forceActiveFocus()
}
