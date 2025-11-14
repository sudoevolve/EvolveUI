import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import MusicLibrary 1.0
import QtQuick.Dialogs

Item {
    id: root
    width: 300
    height: 480

    property var theme
    property var model: null
    property var playerRef: null
    property int currentIndex: playerRef && typeof playerRef.currentIndex === "number" ? playerRef.currentIndex : -1
    property var metaCache: ({})
    MusicLibrary { id: musicLib }
    ListModel { id: fileModel }
    property var prefetchQueue: []
    property bool singleFolderMode: false
    property bool initialPrefetchDone: false
    property var removedSources: []
    Timer {
        id: sequentialPrefetchTimer
        interval: 280
        repeat: true
        running: false
        onTriggered: {
            if (prefetchQueue.length === 0) { running = false; return }
            var next = prefetchQueue.shift()
            if (next) musicLib.prefetchMetadata([next])
        }
    }
    function schedulePrefetch(srcs) {
        if (!srcs || srcs.length === 0) return
        for (var i = 0; i < srcs.length; i++) prefetchQueue.push(srcs[i])
        initialPrefetchDone = true
        if (!sequentialPrefetchTimer.running) sequentialPrefetchTimer.start()
    }
    function scheduleVisiblePrefetch() {
        var rowH = 56
        var start = Math.max(0, Math.floor(listView.contentY / rowH) - 2)
        var vis = Math.ceil(listView.height / rowH) + 4
        var end = Math.min(fileModel.count - 1, start + vis)
        var batch = []
        for (var i = start; i <= end; i++) {
            var it = fileModel.get(i)
            if (it && (!it.artist || it.artist.length === 0)) batch.push(it.source)
        }
        schedulePrefetch(batch)
    }
    function toLocalPath(s) {
        if (!s) return ""
        var t = s
        if (t && typeof t.toString === 'function') t = t.toString()
        if (typeof t === 'string' && t.indexOf('file:') === 0) {
            var u = t.replace(/^file:[\/\\]*/, "")
            return decodeURIComponent(u)
        }
        return t
    }
    function appendUniqueSources(srcs) {
        for (var i = 0; i < srcs.length; i++) {
            var s = toLocalPath(srcs[i])
            var exists = false
            for (var j = 0; j < fileModel.count; j++) { if (fileModel.get(j).source === s) { exists = true; break } }
            if (!exists) {
                var m = musicLib.getMetadata(s)
                var t = (m && m.title && m.title.length > 0) ? m.title : baseName(s)
                var a = (m && m.artist) ? m.artist : ""
                fileModel.append({ source: s, title: t, artist: a })
            }
        }
    }
    function setFiles(files) {
        fileModel.clear()
        for (var i = 0; i < files.length; i++) {
            var s2 = files[i]
            if (removedSources.indexOf(s2) >= 0) continue
            var m2 = musicLib.getMetadata(s2)
            var t2 = (m2 && m2.title && m2.title.length > 0) ? m2.title : baseName(s2)
            var a2 = (m2 && m2.artist) ? m2.artist : ""
            fileModel.append({ source: s2, title: t2, artist: a2 })
        }
        schedulePrefetch(files)
    }

    function removeItem(idx) {
        if (idx < 0 || idx >= fileModel.count) return
        var it = fileModel.get(idx)
        var src = it && it.source ? it.source : ""
        if (removedSources.indexOf(src) < 0) removedSources.push(src)
        fileModel.remove(idx)
        if (playerRef && playerRef.playlistModelRef && typeof playerRef.playlistModelRef.get === "function") {
            var pm = playerRef.playlistModelRef
            var found = -1
            for (var i2 = 0; i2 < pm.count; i2++) { var pit = pm.get(i2); if (pit && pit.source === src) { found = i2; break } }
            if (found >= 0 && typeof pm.remove === "function") {
                pm.remove(found)
                if (typeof playerRef.currentIndex === "number") {
                    if (found === playerRef.currentIndex) {
                        if (pm.count > 0 && typeof playerRef.playAt === "function") {
                            var nextIdx = Math.min(found, pm.count - 1)
                            playerRef.playAt(nextIdx)
                        } else {
                            playerRef.currentIndex = -1
                            if (playerRef && typeof playerRef.stopPlayback === "function") playerRef.stopPlayback()
                        }
                    } else if (found < playerRef.currentIndex) {
                        playerRef.currentIndex = playerRef.currentIndex - 1
                    }
                }
            }
        }
    }

    function baseName(p) {
        if (!p || typeof p !== "string") return "未知"
        var seg = p.split(/[\\/]/).pop()
        var dot = seg.lastIndexOf(".")
        return dot > 0 ? seg.substring(0, dot) : seg
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Text {
            id: titleText
            text: "播放列表"
            font.pixelSize: 18
            font.bold: true
            color: theme ? theme.textColor : "#ffffff"
        }

        ListView {
            id: listView
            width: root.width
            height: Math.max(0, root.height - titleText.height - spacing)
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            reuseItems: true
            cacheBuffer: height * 1.5
            clip: false
            model: fileModel
            currentIndex: playerRef ? playerRef.currentIndex : currentIndex
            property int scalePulse: 0
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 320
            highlightRangeMode: ListView.NoHighlightRange
            highlight: Item {
                id: playlistHighlight
                width: listView.width
                height: listView.currentItem ? listView.currentItem.height : 40
                opacity: 0.9
                transformOrigin: Item.Center
                scale: 1.0
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: theme ? Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.16) : Qt.rgba(0,196,179,0.16)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                SequentialAnimation {
                    id: highlightScaleAnim
                    running: false
                    NumberAnimation { target: playlistHighlight; property: "scale"; to: 1.08; duration: 140; easing.type: Easing.OutBack }
                    NumberAnimation { target: playlistHighlight; property: "scale"; to: 1.0; duration: 220; easing.type: Easing.InQuad }
                }
                Connections {
                    target: listView
                    function onScalePulseChanged() { highlightScaleAnim.restart() }
                }
            }

            onCurrentIndexChanged: {
                if (listView.highlightItem) listView.highlightItem.opacity = 0.9
                listView.scalePulse++
            }

            Behavior on contentY { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            onContentYChanged: scheduleVisiblePrefetch()

            delegate: Item { id: rowItem
                width: listView.width
                height: 56
                readonly property bool isActive: (playerRef && typeof playerRef.currentIndex === "number") ? (index === playerRef.currentIndex) : (index === currentIndex)
                readonly property var itemObj: (index >= 0 && index < fileModel.count) ? fileModel.get(index) : ({})
                readonly property string itemSource: itemObj && itemObj.source ? itemObj.source : ""
                property bool hovered: false
                opacity: 1.0
                transform: Translate { id: slideTransform; x: 0 }
                onItemSourceChanged: {
                    opacity = 1.0
                    slideTransform.x = 0
                    hovered = false
                }
                SequentialAnimation {
                    id: deleteAnim
                    running: false
                    ParallelAnimation {
                        NumberAnimation { target: slideTransform; property: "x"; to: listView.width; duration: 220; easing.type: Easing.OutCubic }
                        NumberAnimation { target: rowItem; property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.OutQuad }
                    }
                    ScriptAction { script: { root.removeItem(index) } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: isActive ? "\uf04b" : (index + 1)
                        font.family: "Font Awesome 6 Free"
                        font.pixelSize: 14
                        color: isActive ? (theme ? theme.focusColor : "#00C4B3") : (theme ? Qt.darker(theme.textColor, 1.2) : "#dddddd")
                        verticalAlignment: Text.AlignVCenter
                    }

                    Column {
                        id: infoBlock
                        spacing: 2
                        width: parent.width - 80
                        
                        // 懒加载元数据，仅在可视区域内加载
                        property bool inView: (infoBlock.y + infoBlock.height) > listView.contentY && infoBlock.y < (listView.contentY + listView.height)
                        Text {
                            id: titleLabel
                            text: (itemObj && itemObj.title && itemObj.title.length > 0) ? itemObj.title : baseName(itemSource)
                            font.pixelSize: 14
                            font.bold: isActive
                            color: theme ? theme.textColor : "#ffffff"
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            width: parent.width
                        }

                        Text {
                            id: artistLabel
                            text: (itemObj && itemObj.artist && itemObj.artist.length > 0) ? itemObj.artist : "未知艺术家"
                            font.pixelSize: 12
                            color: theme ? Qt.darker(theme.textColor, 1.2) : "#dddddd"
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            width: parent.width
                        }
                    }
                }

                Item {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    opacity: (rowArea.containsMouse || deleteArea.containsMouse) ? 1.0 : 0.0
                    z: 2
                    property real scaleVal: 0.92
                    scale: scaleVal
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Rectangle { anchors.fill: parent; radius: width/2; color: theme ? theme.focusColor : "#00C4B3" }
                    Text {
                        anchors.centerIn: parent
                        text: "\uf1f8"
                        font.family: "Font Awesome 6 Free"
                        font.pixelSize: 16
                        color: theme ? theme.textColor : "#ffffff"
                    }
                    MouseArea {
                        id: deleteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.scaleVal = 1.05
                        onExited: parent.scaleVal = 0.92
                        onPressed: function(mouse) { mouse.accepted = true }
                        onClicked: function(mouse) { mouse.accepted = true; deleteAnim.restart() }
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: hovered = true
                    onExited: hovered = false
                    onClicked: {
                        if (typeof deleteArea !== 'undefined' && deleteArea.containsMouse) return
                        var fp = itemSource
                        var used = false
                        if (playerRef && playerRef.playlistModelRef && typeof playerRef.playlistModelRef.get === "function" && typeof playerRef.playAt === "function") {
                            var pm = playerRef.playlistModelRef
                            var found = -1
                            for (var i2 = 0; i2 < pm.count; i2++) { var it = pm.get(i2); if (it && it.source === fp) { found = i2; break } }
                            if (found >= 0) { playerRef.playAt(found); used = true }
                        }
                        if (!used && playerRef && typeof playerRef.playSourcePath === "function") playerRef.playSourcePath(fp)
                        currentIndex = index
                    }
                }
            }
        }
        // 空列表占位
        Item {
            width: root.width
            height: 80
            visible: fileModel.count === 0
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(240, root.width - 40)
                height: 36
                radius: 10
                color: theme ? Qt.rgba(theme.secondaryColor.r, theme.secondaryColor.g, theme.secondaryColor.b, 0.9) : "#2b2b2b"
                Text { anchors.centerIn: parent; text: "未找到音乐文件"; font.pixelSize: 14; color: theme ? theme.textColor : "#ffffff" }
            }
        }
        Connections {
            target: musicLib
            function onMetadataReady(src, meta) {
                for (var i = 0; i < fileModel.count; i++) {
                    var it = fileModel.get(i)
                    if (it && it.source === src) {
                        fileModel.set(i, {
                            source: it.source,
                            title: (meta && meta.title) ? meta.title : it.title,
                            artist: (meta && meta.artist) ? meta.artist : it.artist
                        })
                        break
                    }
                }
            }
        }
    }
    Component.onCompleted: {
        fileModel.clear()
        var srcs = []
        if (model && model.count && model.count > 0) {
            for (var i = 0; i < model.count; i++) {
                var s = model.get(i).source
                fileModel.append({ source: s, title: baseName(s), artist: "" })
                srcs.push(s)
            }
        } else {
            var files2 = musicLib.scanAllAvailableMusic(true)
            for (var k = 0; k < files2.length; k++) {
                var ss = files2[k]
                fileModel.append({ source: ss, title: baseName(ss), artist: "" })
                srcs.push(ss)
            }
            musicLib.startWatching()
        }
        schedulePrefetch(srcs)
        scheduleVisiblePrefetch()
    }

    FileDialog {
        id: importFilesDialog
        title: "选择音乐文件"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["音频文件 (*.mp3 *.m4a *.flac *.wav *.ogg *.aac *.wma)"]
        onAccepted: {
            var arr = []
            for (var i = 0; i < importFilesDialog.selectedFiles.length; i++) arr.push(toLocalPath(importFilesDialog.selectedFiles[i]))
            appendUniqueSources(arr)
            schedulePrefetch(arr)
            if (playerRef && typeof playerRef.addSources === 'function') playerRef.addSources(arr)
        }
    }
    FolderDialog {
        id: importFolderDialog
        title: "选择音乐文件夹"
        onAccepted: {
            var url = "" + (importFolderDialog.selectedFolder || importFolderDialog.folder || "")
            var list = musicLib.scanOnlyDirectory(url)
            console.log("选择文件夹 URL:", url, "文件数:", list.length)
            removedSources = []
            fileModel.clear()
            appendUniqueSources(list)
            musicLib.prefetchMetadata(list)
            scheduleVisiblePrefetch()
            if (playerRef && typeof playerRef.resetSources === 'function') playerRef.resetSources(list)
            singleFolderMode = true
        }
    }

    Item {
        id: addPanel
        visible: false
        opacity: 0.0
        scale: 0.92
        z: 1000
        width: 160
        height: 88
        x: fabImport.x - width - 8
        y: fabImport.y - (height - fabImport.height) / 2
        transformOrigin: Item.Center
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: theme ? theme.secondaryColor : "#2b2b2b"
            border.color: theme ? Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.35) : Qt.rgba(0,196,179,0.35)
            border.width: 2
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Rectangle {
                width: parent.width
                height: 32
                radius: 8
                color: "transparent"
                border.color: "transparent"
                Text { anchors.centerIn: parent; text: "导入文件"; font.pixelSize: 14; color: theme ? theme.textColor : "#ffffff" }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = (theme ? Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.16) : Qt.rgba(0,196,179,0.16))
                    onExited: parent.color = "transparent"
                    onClicked: {
                        addPanel.visible = false; addPanel.opacity = 0.0; addPanel.scale = 0.92
                        importFilesDialog.open()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 32
                radius: 8
                color: "transparent"
                border.color: "transparent"
                Text { anchors.centerIn: parent; text: "选择文件夹"; font.pixelSize: 14; color: theme ? theme.textColor : "#ffffff" }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = (theme ? Qt.rgba(theme.focusColor.r, theme.focusColor.g, theme.focusColor.b, 0.16) : Qt.rgba(0,196,179,0.16))
                    onExited: parent.color = "transparent"
                    onClicked: {
                        addPanel.visible = false; addPanel.opacity = 0.0; addPanel.scale = 0.92
                        importFolderDialog.open()
                    }
                }
            }
        }
    }

    Item {
        id: fabImport
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 12
        anchors.bottomMargin: -54
        width: 44
        height: 44
        z: 999
        property bool hovered: false
        property bool pressed: false
        scale: pressed ? 0.95 : (hovered ? 1.06 : 1.0)
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: theme ? theme.focusColor : "#00C4B3"
        }
        Text {
            anchors.centerIn: parent
            text: "+"
            font.pixelSize: 20
            color: theme ? theme.textColor : "#ffffff"
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: fabImport.hovered = true
            onExited: fabImport.hovered = false
            onPressed: fabImport.pressed = true
            onReleased: {
                fabImport.pressed = false
                addPanel.visible = !addPanel.visible
                addPanel.opacity = addPanel.visible ? 1.0 : 0.0
                addPanel.scale = addPanel.visible ? 1.0 : 0.92
            }
            onCanceled: fabImport.pressed = false
        }
    }
    Connections {
        target: musicLib
        function onMusicFilesChanged(newFiles) {
            if (!singleFolderMode) setFiles(newFiles)
        }
    }
}
