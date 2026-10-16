// The kit's components, loaded with the roster entries in entries.json and driven: an EVM
// account four signers hold, an imported key, and two Bitcoin accounts. Run with
// doctests/run_view_probe.sh.
import QtQuick
import QtQuick.Layouts
import "../qml" as Kit

Item {
    id: probe
    width: 700
    height: 900

    property int failures: 0
    property var pickedKeys: []

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
    function prop(root, name, key) {
        var o = find(root, name)
        return o ? o[key] : "<absent>"
    }

    readonly property var e: {
        var x = new XMLHttpRequest()
        x.open("GET", Qt.resolvedUrl("entries.json"), false)
        x.send()
        return JSON.parse(x.responseText)
    }
    readonly property var all: [e.savings, e.imported, e.segwit, e.taproot]

    ColumnLayout {
        width: probe.width
        Kit.AccountIdentity { id: evm; objectName: "evm"; namePrefix: "evm"; Layout.fillWidth: true; entry: probe.e.savings }
        Kit.AccountIdentity { id: btc; objectName: "btc"; namePrefix: "btc"; Layout.fillWidth: true; entry: probe.e.segwit }
        Kit.AccountIdentity { id: tap; objectName: "tap"; namePrefix: "tap"; Layout.fillWidth: true; entry: probe.e.taproot }
        Kit.AccountIdentity { id: key; objectName: "key"; namePrefix: "key"; Layout.fillWidth: true; entry: probe.e.imported }
        Kit.AccountIdentity { id: none; objectName: "none"; namePrefix: "none"; Layout.fillWidth: true; entry: null }
        Kit.AccountPicker {
            id: picker
            objectName: "picker"
            Layout.fillWidth: true
            entries: probe.all
            canPick: function (entry) { return entry.key !== probe.e.imported.key }
            onPicked: function (entry) { probe.pickedKeys = probe.pickedKeys.concat([entry.key]) }
        }
    }

    function assertAnEvmAccountLeadsWithItsNameAndAddress() {
        console.log("")
        console.log("an EVM account: its name and address, its wallet, and every signer holding it")
        check("name", prop(evm, "evmName", "text"), "Savings")
        check("address", prop(evm, "evmAddress", "text"), "0x9858…da94")
        check("...shown", prop(evm, "evmAddress", "visible"), true)
        check("no script type", prop(evm, "evmType", "visible"), false)
        check("wallet", prop(evm, "evmWallet", "text"), "Wallet “Main phrase” · 73c5da0a · account 0")
        check("first chip: the keystore, ready", prop(evm, "evmChip_0", "text"), "● This device (Keystore)")
        check("then the Shell, connected", prop(evm, "evmChip_1", "text"), "● Keycard Shell · USB")
        check("then QR, with no dot", prop(evm, "evmChip_2", "text"), "QR wallet")
        check("last the card, not connected", prop(evm, "evmChip_3", "text"), "○ Keycard · reader")
        check("no copy button unless asked", prop(evm, "evmCopy", "visible"), false)
    }

    function assertABitcoinAccountLeadsWithItsNameTypeAndNumber() {
        console.log("")
        console.log("a Bitcoin account: its name, script type and number; no address")
        check("name", prop(btc, "btcName", "text"), "Savings")
        check("type", prop(btc, "btcType", "text"), "Native SegWit")
        check("...shown", prop(btc, "btcType", "visible"), true)
        check("number", prop(btc, "btcAccount", "text"), "account 0")
        check("no address", prop(btc, "btcAddress", "visible"), false)
        check("wallet", prop(btc, "btcWallet", "text"), "Wallet “Main phrase” · 73c5da0a")
        console.log("...unnamed, it is Bitcoin #<account>, and the number isn't said twice")
        check("name", prop(tap, "tapName", "text"), "Bitcoin #1")
        check("no separate number", prop(tap, "tapAccount", "visible"), false)
        check("a QR wallet's chip", prop(tap, "tapChip_0", "text"), "QR wallet")
    }

    function assertAnImportedKeyHasNoWallet() {
        console.log("")
        console.log("an imported key: its address alone, and no wallet")
        check("no name", prop(key, "keyName", "visible"), false)
        check("address", prop(key, "keyAddress", "text"), "0xf39F…2266")
        check("wallet line", prop(key, "keyWallet", "text"), "Imported key · no wallet")
        console.log("...and nothing selected says so")
        check("placeholder", prop(none, "noneName", "text"), "Select an account")
        check("no wallet line", prop(none, "noneWallet", "visible"), false)
        check("no chips", prop(none, "noneSigners", "visible"), false)
    }

    function assertThePickerFollowsTheApp() {
        console.log("")
        console.log("the picker: the app names the account, by key or by any holder's id")
        picker.currentKey = probe.e.segwit.key
        check("by key", picker.currentIndex, 2)
        check("...shown", prop(picker, "pickerSelectedName", "text"), "Savings")
        check("...as Bitcoin", prop(picker, "pickerSelectedType", "visible"), true)
        picker.currentKey = "keycard-73c5da0a-84-1-0"
        check("by a holder's id", picker.currentIndex, 2)
        console.log("a click says which, and the picker holds the app's choice until the app moves it")
        picker.activated(0)
        check("picked", probe.pickedKeys, [probe.e.savings.key])
        check("still the app's choice", picker.currentIndex, 2)
        picker.currentKey = probe.e.savings.key
        check("the app moved it", picker.currentIndex, 0)
        check("...shown", prop(picker, "pickerSelectedAddress", "text"), "0x9858…da94")
        console.log("a new roster, the selected account renamed in it, keeps the selection")
        picker.currentKey = probe.e.segwit.key
        var renamed = JSON.parse(JSON.stringify(probe.e.segwit))
        renamed.label = "Cold"
        picker.entries = [probe.e.savings, probe.e.imported, renamed, probe.e.taproot]
        check("still selected", picker.currentIndex, 2)
        check("...under its new name", prop(picker, "pickerSelectedName", "text"), "Cold")
        picker.entries = probe.all
        picker.popup.open()
    }

    // The popup's rows exist only once it has opened.
    function assertRowsTheAppWontTakeAreDisabled() {
        console.log("rows the app won't take are offered but disabled")
        var row = function (i) { return picker.popupListView.itemAtIndex(i) }
        check("four rows, one per account", picker.popupListView.count, 4)
        check("the imported key's row", row(1) ? row(1).enabled : "<no row>", false)
        check("another row", row(2) ? row(2).enabled : "<no row>", true)
        check("...showing its account", row(2) ? prop(row(2), "pickerRow_2Name", "text") : "<no row>", "Savings")
        check("no copy button unless asked", row(0) ? prop(row(0), "pickerRow_0Copy", "visible") : "<no row>", false)
        picker.copyable = true
        check("...and one on an EVM row when asked", row(0) ? prop(row(0), "pickerRow_0Copy", "visible") : "<no row>", true)
        check("...never on a Bitcoin row", row(2) ? prop(row(2), "pickerRow_2Copy", "visible") : "<no row>", false)
        picker.popup.close()
    }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            probe.assertAnEvmAccountLeadsWithItsNameAndAddress()
            probe.assertABitcoinAccountLeadsWithItsNameTypeAndNumber()
            probe.assertAnImportedKeyHasNoWallet()
            probe.assertThePickerFollowsTheApp()
            rows.start()
        }
    }
    Timer {
        id: rows
        interval: 300
        onTriggered: {
            probe.assertRowsTheAppWontTakeAreDisabled()
            console.log("")
            console.log(probe.failures ? "RESULT: FAILURES" : "RESULT: ALL PASS")
            Qt.exit(probe.failures ? 1 : 0)
        }
    }
}
