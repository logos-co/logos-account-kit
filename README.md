# logos-account-kit

The QML pieces every wallet app on Logos uses to show and pick an account, so the Ethereum,
Uniswap and Bitcoin apps and the keys app show one account the same way. An account can be held
by several signers (the keystore, a Keycard in a reader, a Keycard Shell over USB, a QR wallet),
and the kit lists it once, with every signer that holds it.

| Component | What it is |
|---|---|
| `AccountPicker` | The account selector: one row per account, never one per signer. |
| `AccountIdentity` | One account in three lines: the account, the wallet it comes from, its signers. |
| `SignerChips` | The signers holding an account, in the signer manager's order. |
| `WalletCard` | One wallet as the Signer, Keycard and Keys apps show it: its name and Wallet ID (the master fingerprint), the app's lines and strips, one `AccountDetails` row per account, and the app's own actions. |
| `AccountDetails` | One account on a card: name and number, script type, derivation path, and its address (a Bitcoin account's first receiving one), with the app's actions for that account. |
| `LockedBanner` | The wallets still locked in the Signer app, from the signer manager's `wallets()`, with an Unlock that hands the app their seeds for `wallets.unlock`. |
| `PhraseGrid` | A recovery phrase typed one word to a numbered field, shown as typed so it can be checked against the paper. A phrase pasted into a field spreads over the rest; `text` reads the words back, and setting it fills the grid. `counts` narrows the lengths offered (Zcash: `[24]`, which also hides the chooser); `readOnly` shows a phrase to be written down, numbered as it will be typed back. |

Every component takes the signer manager's `roster()` entries as they are: `{ key, family,
chain, address, path, label, labels, wallet: { fingerprint, name }, holders: [...] }`.

## How an account reads

```
Savings  0x9858…da94                          an EVM account: its name and address
Wallet “Main phrase” · 73c5da0a · account 0   the wallet: its name, master fingerprint, index
● This device (Keystore)  ● Keycard Shell · USB  QR wallet  ○ Keycard · reader

Savings  [Native SegWit]  account 0           a Bitcoin account: name, script type, number
Wallet “Main phrase” · 73c5da0a
```

- An unnamed EVM account is its address; an unnamed Bitcoin account is `Bitcoin #<account>`.
- An imported key reads "Imported key · no wallet".
- A filled dot marks a signer that can sign now and a hollow one a device that isn't connected.
  A QR wallet needs no connection, so it gets no dot.
- The xpub and the path never show here. They belong on an account's details.

`roster.js` holds those rules, and also:
- `select`: the entries an app lists, by family and Bitcoin chain;
- `find` and `indexOf`: an entry again, by roster key or by any holder's own id;
- `homeId`: the id a Bitcoin account opens under;
- `lockedWallets` and `lockedTitle`: the wallets still locked, and how the banner names them.
  A locked wallet's accounts aren't in `roster()` at all until the person unlocks it.

## How a wallet card reads

```
Main phrase                                              Unlocked   [Add accounts…]
Wallet ID 73c5da0a  master fingerprint
Held by Keystore · Unlocks with its keystore password.            the app's lines
┌ Recovery phrase kept here, encrypted               [Show or forget…] ┐  a strip
Savings  account 0                                  [Rename…] [Remove…]
Derivation path m/44'/60'/0'/0/0
Address 0x9858…da94 ⧉
Savings  account 0  [Native SegWit] [Test networks] [Rename…] [Remove…]
Derivation path m/84'/1'/0'
First receiving address (testnet/signet, 0/0) tb1q6r…pvkl ⧉
[Lock]                                        [Rename…] [Change password…]
```

- Rows go Ethereum, Bitcoin, then Bitcoin's test networks; SegWit before Taproot; then by number.
- An unnamed account is "Ethereum" or "Bitcoin", with its number beside it.
- A Bitcoin row needs `firstAddress` on its entry. The signer manager's roster gives it to the
  Signer app; the Keycard and Keys apps derive it. Without one the row says the entry's
  `addressNote`, else "Unavailable".
- A locked wallet shows neither its Wallet ID nor its accounts.
- Items declared inside the card, as an inline editor, go above the bottom actions.
- Actions are labels, or `{ id, label, enabled, tip }`; `accountActions` may be a function of
  the entry. The card hands them back as `action(id)`, `stripAction(index, id)` and
  `accountAction(id, entry)`.

## Using it in an app

The kit is vendored, not imported from the host: the builder stages only an app's own view
directory. `vendor.sh` copies the kit into the app's view directory (`src/qml`, else `qml`) as
`accountkit/`. It writes a `qmldir` whose module is named after the app, and records the kit
commit in `accountkit/VERSION`. It sits beside `logos-evm-tx-kit`'s `kit/`.

```bash
../logos-account-kit/scripts/vendor.sh .          # from the app's repo, at a kit checkout
```

```qml
import "accountkit" as Accounts
import "accountkit/roster.js" as Roster

Accounts.AccountPicker {
    entries: Roster.select(roster, ["evm"])
    currentKey: selectedAddress            // a roster key, or any holder's id
    onPicked: function (entry) { select(entry.address) }
}
```

An app's CI proves its copy is the kit at the pinned commit: check out the kit at
`accountkit/VERSION` and run `scripts/check.sh <app repo>`.

## Testing

```bash
node doctests/roster_table.mjs      # roster.js, the same text the components import
./doctests/run_view_probe.sh        # every component, loaded offscreen and driven
```

Both read `doctests/entries.json`. The probes need a Qt Quick runtime and the design system
(`LOGOS_DESIGN_SYSTEM_QML`), and skip with a message without them.
