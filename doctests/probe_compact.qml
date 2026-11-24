// The compact account picker: one line for the account picked, a row per account in the list,
// and below them the wallets still locked, grouped by the app that unlocks them, each with its
// own Unlock. Run with doctests/run_view_probe.sh.
import QtQuick
import QtQuick.Layouts
import "../qml" as Kit

Item {
    id: probe
    width: 700
    height: 600

    property int failures: 0
    property var picked: []
    property var asked: []
    property var e: ({})

    function check(label, got, want) {
        var ok = JSON.stringify(got) === JSON.stringify(want)
        if (!ok) probe.failures++
        console.log((ok ? "  PASS  " : "  FAIL  ") + label + "   got=" + JSON.stringify(got)
                    + (ok ? "" : "  want=" + JSON.stringify(want)))
    }
    function find(o, name) {
        if (!o) return null
        if (o.objectName === name && o.visible !== false) return o
        var kids = [].concat(o.data !== undefined ? Array.prototype.slice.call(o.data) : [],
                             o.contentItem ? [o.contentItem] : [],
                             o.children !== undefined ? Array.prototype.slice.call(o.children) : [])
        for (var i = 0; i < kids.length; ++i) {
            var hit = find(kids[i], name)
            if (hit) return hit
        }
        return null
    }
    function entries() {
        var x = new XMLHttpRequest()
        x.open("GET", Qt.resolvedUrl("entries.json"), false)
        x.send()
        return JSON.parse(x.responseText)
    }

    ColumnLayout {
        width: probe.width
        Kit.CompactAccountPicker {
            id: picker
            objectName: "picker"
            Layout.preferredWidth: 320
            onPicked: function (entry) { probe.picked = probe.picked.concat([entry.key]) }
            onUnlock: function (seeds) { probe.asked = seeds }
        }
    }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            probe.e = probe.entries()
            console.log("")
            console.log("the compact picker: one line for the account picked")
            check("nothing yet: the placeholder", picker.displayText, "Select an account")
            picker.entries = [probe.e.savings, probe.e.segwit]
            picker.currentKey = probe.e.segwit.key
            check("the account picked, by its key", picker.currentIndex, 1)
            check("one line high", picker.implicitHeight, 44)
            picker.activated(0)
            check("picking a row hands back its entry", probe.picked, [probe.e.savings.key])

            console.log("")
            console.log("the wallets still locked, below the accounts, by the app that unlocks them")
            picker.lockedWallets = [{ seed: "a", name: "Main", locked: true, kinds: ["keystore"] },
                                    { seed: "b", name: "Card", locked: true, kinds: ["keycard_shell", "keycard"] },
                                    { seed: "c", name: "Spare", locked: true, kinds: ["keystore"] }]
            picker.popup.open()
            Qt.callLater(function () {
                check("Keystore: counted", find(picker.popupListView, "pickerLockedTitle_Keystore") !== null
                      ? find(picker.popupListView, "pickerLockedTitle_Keystore").text : null, "2 Keystore wallets are locked")
                check("Keycard: a Shell is a Keycard", find(picker.popupListView, "pickerLockedTitle_Keycard") !== null
                      ? find(picker.popupListView, "pickerLockedTitle_Keycard").text : null, "1 Keycard wallet is locked")
                var unlock = find(picker.popupListView, "pickerFooterUnlock_Keystore")
                check("an Unlock per app", unlock !== null, true)
                if (unlock) unlock.clicked()
                check("...asks for that app's wallets only", probe.asked, ["a", "c"])
                console.log("")
                console.log(probe.failures ? "RESULT: FAILURES" : "RESULT: ALL PASS")
                Qt.exit(probe.failures ? 1 : 0)
            })
        }
    }
}
