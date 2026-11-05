// The wallet card, driven with entries.json: its Wallet ID, lines and strips, rows in a fixed
// order with their path and address, and every action handed back with its id and entry. Run
// with doctests/run_view_probe.sh.
import QtQuick
import QtQuick.Layouts
import "../qml" as Kit

Item {
    id: probe
    width: 900
    height: 1200

    property int failures: 0
    property var heard: []

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
    function prop(name, key) {
        var o = find(card, name)
        return o ? o[key] : "<absent>"
    }
    function shown(name) {
        var o = find(card, name)
        return o ? o.visible : "<absent>"
    }
    function click(name) {
        var o = find(card, name)
        if (o) o.clicked()
        return o !== null
    }

    readonly property var e: {
        var x = new XMLHttpRequest()
        x.open("GET", Qt.resolvedUrl("entries.json"), false)
        x.send()
        return JSON.parse(x.responseText)
    }

    ColumnLayout {
        width: probe.width
        Kit.WalletCard {
            id: card
            namePrefix: "w"
            Layout.fillWidth: true
            title: "Main phrase"
            fingerprint: "73c5da0a"
            stateText: "Unlocked"
            lines: ["Held by Keystore · Unlocks with its keystore password."]
            strips: [{ id: "kept", text: "Recovery phrase kept here, encrypted", actions: [{ id: "phrase", label: "Show or forget…" }] },
                     { text: "You trusted this card although Keycard did not certify it.", warn: true, actions: ["Stop trusting"] }]
            actions: [{ id: "add", label: "Add accounts…" }]
            accounts: [probe.e.taproot, probe.e.segwit, probe.e.savings]
            accountActions: function (entry) {
                return [{ id: "rename", label: "Rename…" }, { id: "remove", label: "Remove…" }]
                       .concat(entry.family === "evm" ? [{ id: "export", label: "Export…", enabled: false, tip: "Unlock first" }] : [])
            }
            leftActions: [{ id: "lock", label: "Lock" }]
            rightActions: [{ id: "rename-wallet", label: "Rename…" }, { id: "password", label: "Change password…" }]
            onAction: function (id) { probe.heard = probe.heard.concat(["wallet:" + id]) }
            onStripAction: function (i, id) { probe.heard = probe.heard.concat(["strip" + i + ":" + id]) }
            onAccountAction: function (id, entry) { probe.heard = probe.heard.concat([id + ":" + entry.key]) }
            Text { objectName: "appEditor"; text: "the app's own" }
        }
    }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            console.log("")
            console.log("the wallet: its name, Wallet ID, state and lines")
            check("title", prop("wTitle", "text"), "Main phrase")
            check("Wallet ID: the master fingerprint", prop("wWalletId", "text"), "73c5da0a")
            check("state", prop("wState", "text"), "Unlocked")
            check("a line", prop("wLine_0", "text"), "Held by Keystore · Unlocks with its keystore password.")
            check("strips, by id or else by place, a warning among them", [prop("wStrip_kept_Text", "text"), prop("wStrip_1_Text", "text")],
                  ["Recovery phrase kept here, encrypted", "You trusted this card although Keycard did not certify it."])

            console.log("")
            console.log("rows: Ethereum, then Bitcoin's test networks, each with its path and address")
            check("first row: the EVM account", prop("wAccount_0_Name", "text"), "Savings")
            check("...its index", prop("wAccount_0_Id", "text"), "account 0")
            check("...its path", prop("wAccount_0_Path", "text"), "m/44'/60'/0'/0/0")
            check("...its address", [prop("wAccount_0_AddressLabel", "text"), prop("wAccount_0_Address", "text")],
                  ["Address", "0x9858…da94"])
            check("...with no script badge", find(card, "wAccount_0_Badge_0"), null)
            check("second: SegWit before Taproot", prop("wAccount_1_Path", "text"), "m/84'/1'/0'")
            check("...its badges", [prop("wAccount_1_Badge_0", "text"), prop("wAccount_1_Badge_1", "text")],
                  ["Native SegWit", "Test networks"])
            check("...its first receiving address", [prop("wAccount_1_AddressLabel", "text"), prop("wAccount_1_Address", "text")],
                  ["First receiving address (testnet/signet, 0/0)", "tb1q6r…pvkl"])
            check("...copied whole", prop("wAccount_1_Copy", "value"), "tb1q6rz28mcfaxtmd6v789l9rrlrusdprr9pqcpvkl")
            check("third: unnamed Taproot", [prop("wAccount_2_Name", "text"), prop("wAccount_2_Id", "text")], ["Bitcoin", "account 1"])
            check("...no address yet, and nothing to copy", [prop("wAccount_2_Address", "text"), shown("wAccount_2_Copy")],
                  ["Unavailable", false])

            console.log("")
            console.log("actions: each app's own, handed back with what they are for")
            check("a row action for EVM only", [find(card, "wAccount_0_Action_export") !== null, find(card, "wAccount_1_Action_export")],
                  [true, null])
            check("...disabled", prop("wAccount_0_Action_export", "enabled"), false)
            click("wAccount_1_Action_rename")
            click("wAccount_0_Action_remove")
            click("wAction_add")
            click("wStrip_kept_Action_phrase")
            click("wStrip_1_Action_Stoptrusting")
            click("wAction_lock")
            click("wAction_password")
            check("heard in order", probe.heard,
                  ["rename:" + probe.e.segwit.key, "remove:" + probe.e.savings.key, "wallet:add", "strip0:phrase",
                   "strip1:Stop trusting", "wallet:lock", "wallet:password"])

            check("the app's own items go in the card", find(card, "appEditor") !== null && find(card, "appEditor").parent.objectName, "wContent")

            console.log("")
            console.log("locked, then empty")
            card.locked = true
            check("locked: its text", [shown("wLocked"), prop("wLocked", "text")],
                  [true, "Locked · its ID and accounts show once you unlock it in the Signer app."])
            check("...no Wallet ID", shown("wWalletId"), false)
            check("...no rows", shown("wAccount_0"), false)
            check("...and not called empty", shown("wEmpty"), false)
            card.locked = false
            card.accounts = []
            check("empty", [shown("wEmpty"), prop("wEmpty", "text")], [true, "No accounts yet."])

            console.log("")
            console.log(probe.failures ? "RESULT: FAILURES" : "RESULT: ALL PASS")
            Qt.exit(probe.failures ? 1 : 0)
        }
    }
}
