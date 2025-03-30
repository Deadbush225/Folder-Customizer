import QtQuick 2.0

Rectangle {
    width: 400
    height: 300

    Text {
        id: header
        text: "Component Version Information"
        font.pixelSize: 18
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        margin: 10
    }

    ListView {
        id: versionList
        anchors.fill: parent
        anchors.topMargin: 50
        model: componentVersions

        delegate: Item {
            width: parent.width
            height: 30

            Row {
                spacing: 10
                Text {
                    text: versionData.name
                    font.pixelSize: 14
                }
                Text {
                    text: versionData.version
                    font.pixelSize: 14
                }
            }
        }
    }

    ListModel {
        id: componentVersions
        // Placeholder data; you’ll populate this dynamically
        ListElement { name: "Component A"; version: "1.0.0" }
        ListElement { name: "Component B"; version: "2.1.3" }
    }
}
