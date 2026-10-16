#!/usr/bin/env node
// qml/roster.js as a table: the same text the components import.
//
// Run: node doctests/roster_table.mjs

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const src = readFileSync(join(here, "..", "qml", "roster.js"), "utf8");
const names = [...src.matchAll(/^function\s+(\w+)\s*\(/gm)].map((m) => m[1]);
const R = new Function(`${src}\nreturn { ${names.join(", ")} };`)();
const E = JSON.parse(readFileSync(join(here, "entries.json"), "utf8"));

let failed = 0;
function check(label, got, want) {
    const ok = JSON.stringify(got) === JSON.stringify(want);
    if (!ok) failed++;
    console.log(`  ${ok ? "PASS" : "FAIL"}  ${label}   got=${JSON.stringify(got)}${ok ? "" : `  want=${JSON.stringify(want)}`}`);
}

console.log("\nan EVM account leads with its name and address");
check("named", R.title(E.savings), "Savings 0x9858…da94");
check("unnamed: the address alone", R.title(E.imported), "0xf39F…2266");
check("no name to show for an unnamed one", R.name(E.imported), "");

console.log("\na Bitcoin account leads with its name, script type and number");
check("named", R.title(E.segwit), "Savings · Native SegWit · account 0");
check("unnamed: Bitcoin #<account>", R.title(E.taproot), "Bitcoin #1 · Taproot");
check("its number", R.accountNumber(E.taproot), 1);
check("an EVM address's index", R.accountNumber(E.savings), 0);
check("no path, no number", R.accountNumber(E.imported), -1);

console.log("\nthe wallet line: its name, master fingerprint, and an EVM address's index");
check("EVM, derived", R.walletLine(E.savings), "Wallet “Main phrase” · 73c5da0a · account 0");
check("Bitcoin", R.walletLine(E.segwit), "Wallet “Main phrase” · 73c5da0a");
check("unnamed wallet", R.walletLine(E.taproot), "Wallet · 73c5da0a");
check("an imported key", R.walletLine(E.imported), "Imported key · no wallet");
check("a wallet the app can't name", R.walletLine({ family: "evm", wallet: {}, path: "m/44'/60'/0'/0/2" }), "Wallet · account 2");

console.log("\nsigners, by what they are, never by module");
const [keystore, shell, qr, reader] = E.savings.holders;
check("the keystore", R.holderName(keystore), "This device (Keystore)");
check("the Shell", R.holderName(shell), "Keycard Shell · USB");
check("a QR wallet", R.holderName(qr), "QR wallet");
check("a card in a reader", R.holderName(reader), "Keycard · reader");
check("ready", R.holderState(keystore), "ready");
check("QR is never 'connected'", R.holderState(qr), "");
check("not connected", R.holderState(reader), "not connected");
check("chips: filled, filled, none, hollow", E.savings.holders.map(R.chip),
      ["● This device (Keystore)", "● Keycard Shell · USB", "QR wallet", "○ Keycard · reader"]);
check("summary", R.summary(E.imported), "0xf39F…2266 — Imported key · no wallet — This device (Keystore)");

console.log("\nchoosing what an app lists, and finding an account again");
const all = [E.savings, E.imported, E.segwit, E.taproot];
check("EVM only", R.select(all, ["evm"]).map((e) => e.key), [E.savings.key, E.imported.key]);
check("Bitcoin on test", R.select(all, ["bitcoin", "bitcoin_taproot"], "test").length, 2);
check("Bitcoin on main", R.select(all, ["bitcoin", "bitcoin_taproot"], "main").length, 0);
check("by key", R.indexOf(all, E.segwit.key), 2);
check("by any holder's id", R.indexOf(all, "keycard-73c5da0a-84-1-0"), 2);
check("an EVM id without case", R.indexOf(all, "0x9858EFFD232B4033E47D90003D41EC34ECAEDA94"), 0);
check("unknown", R.indexOf(all, "g_nope"), -1);

console.log("\nthe id a Bitcoin account opens under");
check("a holder's that already has a wallet", R.homeId(E.segwit, ["keycard-73c5da0a-84-1-0"]), "keycard-73c5da0a-84-1-0");
check("else the first holder's", R.homeId(E.segwit, []), "g_segwit");

console.log(failed ? `\nRESULT: ${failed} FAILED` : "\nRESULT: ALL PASS");
process.exit(failed ? 1 : 0);
