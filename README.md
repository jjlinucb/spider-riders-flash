# Spider Riders: Battle for Arachna — Flash/Ruffle build

The original 2007 Flash browser game, recovered and running fully client-side via
[Ruffle](https://ruffle.rs) (an open-source Flash Player emulator) — no backend
server required.

**Live version:** https://jjlinucb.itch.io/spiderriders

## Why this works with no server

The game's login/save system is gated behind a flag (`callScriptEnable`) that is
hardcoded to `false` and never set `true` anywhere in the shell's code
(`decompiled/SpiderRider/script/scripts/frame_2/DoAction.as`, `frame_10/DoAction.as`).
Every server-dependent call — login, save, card/gil/guild updates — silently no-ops,
and the game falls back to a hardcoded default character. The battle system
(`decompiled/battleSystem/`) has zero network calls anywhere and runs entirely on
local hardcoded tables, so combat works identically offline.

Practically: any username/password logs you in, and all 15 single-player missions,
the card battle system, and the minigames are fully playable.

## Features added on top of the original

Two small binary patches on top of the original recovered SWFs, both applied via
JPEXS FFDec (`-export script` → hand-edit the `.as` → `-importScript`; only the
one changed script per SWF is reimported, not the full tree — see git history for
the exact diffs). Each patched SWF has an `*.orig.swf` sibling with the pre-patch
bytes, kept as a rollback point.

- **Mission select**: a "choose a mission" screen in `index.html` before Ruffle
  boots, passed through as a `startMission` FlashVar. See the comment block at the
  top of `index.html` for the exact patch location
  (`SpiderRider_2_edited.swf`, `frame_10/DoAction.as`).
- **Auto-battle**: a checkbox next to the mission dropdown, passed as an
  `autoBattle` FlashVar. `SpiderRider_2_edited.swf` normalizes it to a boolean on
  `root` (same `frame_10` patch site as mission select). `battleSystem_2.swf`'s
  `SetMode()` (`decompiled/battleSystem/scripts/DefineSprite_3152/frame_1/DoAction_5.as`)
  checks it at the two points a human would otherwise click a button —
  `MODE_NEXT_TURN` (rolls dice) and `MODE_CARD` (attacks) — gated on
  `CurrentPlayer == TURN_PLAYER` so the existing opponent AI is untouched. It
  doesn't drag dice onto cards first, so no card bonuses are applied — it's meant
  for fast playtesting, not optimal play.
- **Save/load**: this SWF version has no `FileReference` and no
  `ExternalInterface` (nothing calls `addCallback`), so there's no JS↔SWF
  channel except the one-way `getURL("javascript:...")` bridge `googleAnalytic()`
  already used (note: not *through* `googleAnalytic()` itself — it silently no-ops
  whenever `GAMEDEBUG` is a non-empty string, which it always is here, so the new
  code calls `getURL` directly). `frame_10/DoAction.as` adds:
  - `autoSaveTick()`, on a 5s `setInterval`: snapshots victory points, mission,
    gils, name, and card inventory (deliberately *not* avatar/spider
    customization — restoring `undefined` customization fields as `0` into
    rendering code this patch never traced felt like the wrong tradeoff for a
    feature this scoped) into a compact `|`-delimited string
    (`buildSaveString()`/`applySaveString()`), writes it to the existing `so`
    SharedObject (`so.data.saveGame` — the same local object the camp1/2/3
    webcodes already use) so it survives a refresh, and reports it to the page
    via `getURL` so the page's "Download current save" button has something to
    offer.
  - A boot-time check, ahead of the original hardcoded blank-stats fallback:
    an `importedSave` FlashVar wins first, then `so.data.saveGame`, and only
    *then* the original blank defaults — existing saves and brand-new players
    both see unchanged behavior otherwise.
  - `index.html` reads a picked save file client-side (there's no JS→SWF
    channel to inject it into a *running* game) and holds it until Start Game
    is clicked, at which point it rides in as the `importedSave` FlashVar above.

**Neither of the above has been confirmed with a live playthrough** — the
sandbox this was built in can't get Ruffle's AVM1 loop to actually run: `document.visibilityState`
is stuck `"hidden"` (a similar issue to one hit earlier in this project on the Phaser
side, but Ruffle exposes no `headlessStep`-style manual-tick escape hatch to work
around it, and neither `suspend()`/`resume()` nor `backgroundExecutionMode: "worker"`
freed it up). This blocks *all* AVM1 execution in that sandbox, old code and new
alike, not just these two patches specifically — even the pre-existing autosave-free
build would look identically stuck there. What *was* verified without needing the
loop to run: both patches export/reimport byte-clean, the SWF loads to 100% in
Ruffle with no console errors under several configs, and FlashVars/config
(`autoBattle`, `importedSave`) carry the right values all the way into Ruffle's
`loadedConfig` — plus, since it's plain JS unaffected by the AVM1 stall, the save
file picker's own validate/accept/reject logic in `index.html` was exercised
directly and works. But nobody has watched dice roll on their own, or watched a
save file actually round-trip through a real playthrough, yet. Worth a real-browser
check before relying on either.

## Running locally

Browsers block WASM/fetch on `file://`, so this needs a static server, not just
double-clicking `index.html`:

```bash
cd flash-source
python3 -m http.server 8000
# open http://localhost:8000/index.html
```

## Layout

- `index.html` — entry point, loads Ruffle from the local `ruffle-vendor/` (no CDN)
  and boots `SpiderRider_2_edited.swf`.
- `ruffle-vendor/` — vendored Ruffle self-hosted release (stable, not nightly).
- `*_2.swf` — the game's modules: `SpiderRider_2_edited.swf` (main shell),
  `scr1_2.swf`–`scr15_2.swf` (missions 1–15), `battleSystem_2.swf`, `world_2.swf`,
  `character_2.swf`, `miniGame1_2.swf`–`miniGame6_2.swf`, plus multiplayer/chat
  modules (`battleMulti_2.swf`, `chatModule_2.swf`, `friends_2.swf`) that are present
  but not exercised by the single-player flow above.
- `sprSettings01_EN.xml` — server config/localization data loaded at boot. Already
  points `scriptLink` at a dead local address rather than the original production
  server.
- `decompiled/` — full ActionScript 2 decompilation (via JPEXS FFDec) of every
  module above, for reference when tracking down game logic.
- `game.html`, `swfobject.js`, `urchin.js` — the original 2007-era embed files,
  recovered from a Wayback Machine capture. Not used by `index.html`; kept for
  historical reference.

## Known issues

- **Victory Pts / rank corruption**: the Victory Pts counter can end up showing a
  huge garbled number instead of `0`. A per-frame watcher
  (`decompiled/SpiderRider/script/scripts/DefineSprite_1960/frame_1/DoAction.as`)
  recomputes rank from that value via `getRankValue2()`
  (`decompiled/SpiderRider/script/scripts/frame_2/DoAction.as`), whose top tier
  is just "≥ 58000" with no upper bound — so the bad value immediately maxes out
  attack/defense/health stats. Root cause of *why* Victory Pts gets corrupted in
  the first place hasn't been traced yet.
- **Audio**: not verified either way — nobody's confirmed whether music/sound
  effects actually play through Ruffle yet.

## Contributing

This is fan preservation/tinkering, not the original developers' code. If you want
to fix one of the issues above (or anything else), the `decompiled/` tree is the
place to start reading — file paths above point at the relevant scripts.
