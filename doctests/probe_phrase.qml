// The phrase grid, typed into as a person would: a word to a field, shown as typed; a phrase pasted
// into one field spreads over the rest; `text` reads the words back and setting it fills the grid.
// Run with doctests/run_view_probe.sh.
import QtQuick
import QtQuick.Layouts
import "../qml" as Kit

Item {
    id: probe
    width: 700
    height: 600

    property int failures: 0

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
    // What typing does: the field's text, then its edit.
    function type(i, value) {
        var f = probe.find(phrase, "words_" + i)
        if (!f) { check("a field " + i, "none", "one"); return }
        f.textInput.text = value
        f.textInput.textEdited()
    }

    readonly property string twelve: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

    ColumnLayout {
        width: probe.width
        Kit.PhraseGrid { id: phrase; objectName: "words"; Layout.fillWidth: true }
    }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            console.log("")
            console.log("the phrase grid")
            check("12 numbered fields to start", probe.find(phrase, "words_11") !== null && probe.find(phrase, "words_12") === null, true)
            check("...shown as typed, not hidden", probe.find(phrase, "words_0").echoMode, 0)

            probe.type(0, "Aspect")
            probe.type(1, "asset")
            check("each word in its field, lowercase", phrase.text, "aspect asset")
            check("not complete yet", phrase.complete, false)

            probe.type(2, "abandon ")
            check("a space after a word keeps the word", phrase.words[2], "abandon")

            probe.type(0, probe.twelve)
            check("a pasted phrase spreads over the fields", phrase.text, probe.twelve)
            check("...field 12 holds the last word", probe.find(phrase, "words_11").text, "about")
            check("...and it is complete", phrase.complete, true)

            phrase.text = Array(24).fill("zoo").join(" ")
            check("setting 24 words grows the grid", phrase.count, 24)
            check("...and fills it", probe.find(phrase, "words_23").text, "zoo")

            phrase.clear()
            check("clear empties it", phrase.text, "")
            check("...field by field", probe.find(phrase, "words_0").text, "")

            phrase.count = 12
            probe.type(5, "word1 word2 word3")
            check("a paste from field 6 fills 6 to 8", phrase.words.slice(4, 9), ["", "word1", "word2", "word3", ""])
            console.log("")
            console.log(probe.failures ? "RESULT: FAILURES" : "RESULT: ALL PASS")
            Qt.exit(probe.failures ? 1 : 0)
        }
    }
}
