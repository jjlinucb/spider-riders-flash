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

A handful of small binary patches on top of the original recovered SWFs, all
applied via JPEXS FFDec (`-export script` → hand-edit the `.as` → `-importScript`;
only the one changed script per SWF is reimported, not the full tree — see git
history for the exact diffs). Each patched SWF has an `*.orig.swf` sibling with
the pre-patch bytes, kept as a rollback point. Plus one JS-only feature (2x
speed) with no SWF patch involved at all.

- **Mission select**: a "choose a mission" screen in `index.html` before Ruffle
  boots, passed through as a `startMission` FlashVar. See the comment block at the
  top of `index.html` for the exact patch location
  (`SpiderRider_2_edited.swf`, `frame_10/DoAction.as`).
- **Auto-battle**: a floating toggle button (top-right, same always-visible/
  works-anytime pattern as 2x speed below — flipping it mid-game rebuilds the
  player and carries progress forward on the latest autosave, for the same
  reason 2x speed does: no live JS↔SWF channel to just flip the value on a
  running instance), passed as an `autoBattle` FlashVar. `SpiderRider_2_edited.swf`
  normalizes it to a boolean on `root` (same `frame_10` patch site as mission
  select). `battleSystem_2.swf`'s `SetMode()`
  (`decompiled/battleSystem/scripts/DefineSprite_3152/frame_1/DoAction_5.as`)
  checks it at the two points a human would otherwise click a button —
  `MODE_NEXT_TURN` (rolls dice) and `MODE_CARD` (assigns dice to cards, then
  attacks) — gated on `CurrentPlayer == TURN_PLAYER` so the existing opponent
  AI is untouched. `MODE_CARD` now also calls a new `AutoAssignDice()`
  (added just before `SetMode()` in that same file) before attacking: for
  each rolled green/yellow/blue die still in `Dices`, it finds a matching
  inactive card among `DeckPlayerInHandUI.Socket01..07` — green activates
  Weapon(100s)/Protection(200s)/Item(300s, except 302)/Fusion(600s) cards,
  yellow activates Boost(500s) cards, blue activates BattleAction(400s)
  cards plus item 302 — using the exact same CardID-range rule the human
  drag-and-drop path (`Release()`, same file) checks, then calls
  `Activate()` directly (no `startDrag`/hitTest needed, since nothing async
  has to happen — that's only required for the opponent AI's own version of
  this, `AIDispatchYellowDice()` etc. in `DoAction_8.as`, which this patch
  doesn't touch). Red and white dice were already fully automatic before
  this patch (resolved by the game itself, before `MODE_CARD` is even
  reached) and are untouched.
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
- **2x speed**: a "2x Speed" button fixed in the top-right corner, visible on
  the mission-select screen and over the running game alike, so it works on
  every screen (walking around a mission, menus, battle). Unlike the other
  three features, this isn't an AS patch at all — it just passes
  `frameRate: 60` in Ruffle's `load()` config (the SWF's native rate, verified
  by parsing the header, is 30), and Ruffle runs a single movie clock shared
  by every loaded SWF (missions, `battleSystem_2.swf`, etc. all execute under
  one player instance), so overriding the rate at load time speeds up all of
  them together with zero decompile/reimport risk.

  The catch: Ruffle only lets you pick a frame rate when *building* a player
  instance (it's a construction-time call in the wasm bindings, not a method
  on an instance already running), so there's no live "change speed" knob —
  toggling mid-game tears the current player down and rebuilds it at the new
  rate. `index.html` carries the game forward across that rebuild using
  whatever the existing save system (see below) last autosaved, so it isn't a
  hard reset, but it isn't a seamless in-place speed change either: it can
  rewind up to the ~5s autosave interval, and it can't restore an in-progress
  battle or exact map position (autosave only tracks victory points/mission/
  gils/name/cards) — the mission itself restarts at its entry point. Toggling
  before ever starting a game (still on the mission-select screen) just
  remembers the choice for the next Start Game click, no rebuild needed.

- **Mission-appropriate gearing**: jumping straight into a later mission via
  mission-select used to leave you at the hardcoded blank-slate defaults
  (rank 0: dice 3 / defense 4 / life 10, no cards, no spider) against
  opponents balanced for a player who'd actually played through — e.g.
  mission 14's monster is Dice 16 / Defense 20 / Life 25 per
  `LookUpMonster()`'s `TableEncounterMonster` (`battleSystem/scripts/
  DefineSprite_3152/frame_1/DoAction_5.as`), an easy wipe. `frame_10/
  DoAction.as` now has `gearUpForMission(missionNbr)`, called once at boot
  whenever `playerStats.mission > 1`: it floors `victory` at
  `min(65000, (missionNbr-1)*4500)` (never lowers it — this also applies on
  top of a real save, so it only tops up an underleveled continue, never
  downgrades one), re-derives `dice`/`defense`/`life`/`rank` from that via the
  game's own `getRankValue2()`/`setUpgrade()` (the same functions
  `applySaveString()` already calls), grants the default spider
  (`{dice:3,defense:3,action:3}`, matching the game's own mission-6 unlock
  data) if `missionNbr >= 6` and none is already set, and adds a fixed set of
  card IDs gated by mission thresholds (2/3/5/8/11/14) — spanning weapon
  (100s), shield (200s), and boost (500s) cards from `cardData` — skipping
  any id already owned. All of this is additive/non-destructive by
  construction; it can only raise a player's power, never lower it.

  This only covers combat stats/cards, not appearance — the visible
  on-map/on-avatar look (`typeBody`/`typeLegs`/`typeArmor`/`typeManacle`,
  plus the spider's own `sprHead`/`sprBody`/`sprLegs` cosmetics) is a
  completely separate system in the original game, normally set by
  `initPlayer()` (only ever called from the online registration screen,
  which never fires here — `callScriptEnable` is hardcoded false) or by a
  login-server reply (also dead here). Live gameplay's actual "you're now a
  Spider Rider" trigger turned out to be a specific mission-5 pickup event
  (`decompiled/scr5/script/scripts/frame_12/PlaceObject2_598_124/...as`),
  not a mission-number threshold — it's the only place in the whole
  decompiled tree that ever sets `root.sprAccess = true`. Since none of
  this ran at all in the offline rebuild's actual boot path (frame_10),
  every character always rendered whatever a freshly-instantiated clip's
  default frame happens to be, regardless of mission or spider status.
  `frame_10/DoAction.as` now sets sane baseline cosmetics
  (`tempSex`/`typeSex`/`typeHair`/`typeEyes`/`typeSkin`/`typeBody`/
  `typeLegs`, matching `initPlayer()`'s own defaults) on every boot,
  computes `typeManacle` from `playerStats.mission` (`<=3` → 1, else → 2 —
  the same formula the dead login-handler used), and scales `typeArmor`
  with mission progress instead of leaving it flat at the `initPlayer()`
  default (which read as "no armor visible" on the map — the actual
  original-report bug this was chasing): the armor clip
  (`decompiled/character/.../DefineSprite_387`) has 28 frames, so
  `typeArmor = min(28, max(1, ceil(mission/15*28)))` gives a visibly
  higher-tier armor look as missions progress, same philosophy as
  `typeManacle`. `gearUpForMission()` now also sets `sprAccess = true` plus the same
  spider-cosmetic defaults (`sprSex`/`sprName`/`sprHead`/`sprBody`/
  `sprLegs`) the mission-5 event itself sets, gated on the same
  `missionNbr >= 6 && !playerStats.spider` check as the spider stat grant
  (so, like everything else here, it only fills in what's missing and
  never overwrites a real save's actual cosmetic state — though the save
  system doesn't capture cosmetics either way, so this runs fresh every
  boot regardless of save/blank-state path).

- **Mission 14 healer softlock fix**: reported as "I give the healer 4
  flowers, talk to her son, and she disappears forever with no potion." The
  quest's flag chain (`purpleFlowers`→`trigger3`→`trigger4`→`text22`→
  `balsam`→`trigger5`, all in `decompiled/scr14/`) turned out to be intact in
  the original game — after `trigger4` is set, the healer and her son
  *relocate* to a different screen (`frame_39`, reached via 8 easy-to-miss
  transit tiles on the son's home screen, `frame_10` lines 31-38) where the
  potion (`"balsam"`) is actually pickable. So this isn't necessarily a dead
  end in the original logic, but it's fragile: the screen-to-screen
  transition itself hands off through an `upPanel`/`downPanel` close-animation
  callback (`moveCharTween()`, `frame_2/DoAction.as` ~line 469) that, if it
  ever stalls under Ruffle, silently strands the player with no error and no
  way back — plus the transit tiles have no visual cue, so even a working
  transition is easy to miss entirely. Rather than chase whether Ruffle's
  playback is the culprit (unverifiable in the sandbox this was built in —
  see below), the fix removes the dependency outright: `scr14_2.swf`'s
  frame_11 son-conversation handler (`PlaceObject2_1304_431`) now grants the
  potion (`game.balsam=1; game.text22=2; game.addObject("balsam");
  game.trigger5=1`) directly, guarded on `game.balsam == 0`, the moment
  `trigger3` flips to `trigger4` — the same moment the original game commits
  to relocating the healer. No screen transition or tile-finding required
  anymore; the original frame_39 pickup path is left in place but is now a
  no-op for players who do make it there (its own `placeObject` for `balsam`
  is already guarded on `game.balsam == 0`, so nothing double-grants).
  `scr14_2.orig.swf` is the pre-fix backup.

  Two follow-on bugs surfaced once the actual live playthrough started:
  first, the son's own walkZone (`frame_11/PlaceObject2_1304_431`)
  unconditionally called `game.unregisterWalkZone(this)` regardless of
  which internal branch fired — so approaching him even once before
  finishing all 4 flowers (`trigger3` not yet `1`, only the `trigger2`
  reminder-line branch firing) permanently disabled him for that visit,
  and since nothing else could ever set `trigger3` back, the quest
  couldn't progress even after the flowers were later delivered. Moved
  that unregister call inside the `trigger3==1` branch so it only fires
  once the interaction actually completes. Second: mission 14's own
  rockfield/pickaxe delivery (`frame_116/PlaceObject2_1344_435`, a
  completely unrelated quest) had a stray `game.trigger4 = 0;` with no
  purpose for its own logic — its only effect was resetting the SAME flag
  the flower/son quest uses, which (in the unpatched game) permanently
  softlocks `frame_39`'s healer-dialogue registration if the pickaxe
  quest finishes before the player has talked to her there even once.
  Deleted that line outright — nothing in the pickaxe/rockfield chain
  reads `trigger4`, so it served no purpose beyond corrupting the other
  quest's state.

  A full trace of mission 14's actual quest structure turned up something
  bigger: the flower→son→potion chain isn't a side quest at all — it's
  the *entire* main path through the mission (`trigger1` through
  `trigger8`, ending at `frame_214`'s `root.gotoAndStop("level15")`).
  Checklist, in order: talk to **lument** (`frame_172`) → pick up all 4
  `purpleFlowerN` items (`frame_4`/`frame_144`/`frame_151`/`frame_158`,
  no prerequisite — free from mission start) → deliver them to the
  healer's drop zone at tile (31,31) in `frame_53` → talk to the **son**
  (`frame_11`, now potion-granting per the fix above) → talk to
  **womanA** at `frame_39` at least once (belt-and-suspenders — not
  strictly required after the direct-grant fix, but do it anyway; skip
  straight to the rockfield/pickaxe side quest first and you're relying
  entirely on the `trigger4` fix above) → carry the balsam to the
  `frame_207` drop zone (tile 37,35) → fight **krail** (type 317,
  `frame_193`) → fight **aquine** (type 602, `frame_207`) → talk to the
  final NPC at `frame_214` to finish. The necklace→gold→pickaxe→rockfield
  chain (`frame_95`→`frame_88`→`frame_46`→`frame_116`) and the
  `frame_200` "chompede" bounty fight are optional bonus content, read
  by nothing in the required chain — the "gold" item some players expect
  never even spawns until the necklace has been separately delivered
  (`frame_88`'s placement condition is `neckless==2 && gold==0`), which
  explains reports of "there's nothing to pay the pickaxe seller with" on
  a fresh mission-select start — it's not eaten by anything else, it's
  just gated behind a quest most players haven't started yet.

- **Mission 15 card pickup fix**: reported as "couldn't pick up this
  card" (a card-back icon standing next to an NPC, unresponsive to
  walking up to it). Root cause: the pickup clip for card 103
  (`frame_32/PlaceObject2_1089_135`) checks `game.card6==1` exactly once,
  in its own `onClipEvent(load)` — but `card6` only becomes `1` via a
  sibling puzzle object in the *same* frame (dropping a "ring" item on a
  nearby zone, `frame_32/PlaceObject2_1072_133`), which fires *after* the
  card clip's one-shot load check already ran and found `card6` still
  `0`. Leaving and re-entering the room re-triggers everything and would
  fix the registration side (the clip reloads with `card6` already `1`),
  but `frame_32/DoAction.as`'s own re-placement condition was
  `if(game.card6==0){placeObject(...,"cardField",1);}` — which stops
  being true the moment the ring puzzle sets `card6=1`, so the card
  graphic then never reappears either. Net effect: visible-but-dead on
  the first visit, invisible-but-functional on every visit after — never
  both at once. Fixed by widening that one condition to
  `game.card6 < 2` (i.e. keep showing the card until it's actually
  picked up, which sets `card6=2`), so leaving and re-entering the room
  now shows it *and* lets you grab it. `scr15_2.orig.swf` is the pre-fix
  backup.

- **Bonus missions (camps 1-3) added to mission-select**: the mission
  dropdown now has 3 extra entries, "Bonus Mission 1/2/3", for the game's
  three "camp" modules (`camp1_2.swf`/`camp2_2.swf`/`camp3_2.swf` — Guild/
  mentor hub content). These were originally gated behind two locks: a
  real-world *date* lock (`DefineSprite_1157/frame_2/DoAction.as`, comparing
  against `<bonusDate>14-5-2007,31-12-2009,31-12-2009</bonusDate>` from
  `sprSettings01_EN.xml`) that's simply moot by now — the check only
  disables the button while the date hasn't passed yet, and all three
  passed over a decade ago — and a promotional *webcode* lock (typing a
  code, checked against a plain string from `sprSettings01_EN.xml`'s
  `<webcodes>` node, real server validation never wired up even in the
  original: `changewebcode()`'s reply handler has no success case for it).
  Picking a bonus mission passes a `startCamp` FlashVar; `frame_10/DoAction.as`
  stashes it on `root.startCamp` and calls a new `grantAllCards()` (all 61
  card IDs in the game — the same set `LookUpCard()`'s six tables resolve,
  cross-checked against the base `cardData` catalog — pushed via the same
  non-destructive `hasCard()`-guarded pattern as `gearUpForMission()`, so a
  real save's cards are only ever added to, never replaced). `frame_54`'s
  dispatcher gets a new branch, checked before the regular mission jump:
  sets `so.data["camp"+startCamp] = true` (the same bypass a valid webcode
  would have produced) and does `gotoAndPlay("camp"+startCamp)` — the same
  frame label the button flow itself uses, so this rides the exact same
  boot sequence the shipped mission-select patch already proved out, rather
  than trying to jump there early and risk skipping the shell's preloader/
  login frames.

**None of the above has been confirmed with a live playthrough** — the
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
