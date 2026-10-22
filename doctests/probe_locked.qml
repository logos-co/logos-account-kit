// The locked banner, driven with the signer manager's wallets(): hidden with none locked, named
// for one, counted for several, and Unlock asks for exactly the locked ones. Run with
// doctests/run_view_probe.sh.
import QtQuick
import QtQuick.Layouts
import "../qml" as Kit

Item {
    id: probe
    width: 700
    height: 400

    property int failures: 0
    property var asked: []

    function check(label, got, want) {
        var ok = JSON.stringify(got) === JSON.stringify(want)
        if (!ok) probe.failures++
        console.log((ok ? "  PASS  " : "  FAIL  ") + label + "   got=" + JSON.stringify(got)
                    + (ok ? "" : "  want=" + JSON.stringify(want)))
    }
    function find(o, name) {
        if (!o) return null
        if (o.objectName === name) return o
        var kids = [].concat(o.data !== undefined ? Array.prototype.slice.call(o.data) : [],
                             o.contentItem ? [o.contentItem] : [])
        for (var i = 0; i < kids.length; ++i) {
            var hit = find(kids[i], name)
            if (hit) return hit
        }
        return null
    }

    ColumnLayout {
        width: probe.width
        Kit.LockedBanner {
            id: banner
            namePrefix: "btc"
            Layout.fillWidth: true
            onUnlock: function (seeds) { probe.asked = seeds }
        }
    }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            console.log("")
            console.log("the locked banner")
            check("hidden with nothing locked", banner.shown, false)
            banner.wallets = [{ seed: "s_1", name: "Main phrase", locked: true }, { seed: "s_2", name: "Card", locked: false }]
            check("one locked: shown", banner.shown, true)
            check("...by name", banner.title, "Wallet “Main phrase” is locked")
            check("...its object name", banner.objectName, "btcLockedBanner")
            banner.wallets = [{ seed: "s_1", name: "Main phrase", locked: true }, { seed: "s_3", name: "", locked: true },
                              { seed: "s_2", name: "Card", locked: false }]
            check("several: counted", banner.title, "2 wallets are locked")
            var button = probe.find(banner, "btcUnlockButton")
            check("an Unlock button", button !== null, true)
            if (button) button.clicked()
            check("...asking for the locked ones only", probe.asked, ["s_1", "s_3"])
            banner.wallets = [{ seed: "s_2", name: "Card", locked: false }]
            check("hidden once they unlock", banner.shown, false)
            console.log("")
            console.log(probe.failures ? "RESULT: FAILURES" : "RESULT: ALL PASS")
            Qt.exit(probe.failures ? 1 : 0)
        }
    }
}
