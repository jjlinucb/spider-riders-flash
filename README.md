# Spider Riders: Battle for Arachna — Flash/Ruffle build

The original 2007 Flash browser game, recovered and running fully client-side via
[Ruffle](https://ruffle.rs) (an open-source Flash Player emulator) — no backend
server required.

**Live version:** https://flash-source.vercel.app

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
  (`SpiderRider_2_edited.swf`, `frame_10/DoAction.as`). As of this patch, picking
  *any* mission (1-15, not just gear-gated ones) also calls the existing
  `grantAllCards()` — previously only bonus camps and the Buguese fight got the
  full 61-card pool; `gearUpForMission()`'s own curated per-mission-threshold
  card list only ever covered a subset. One line added inside the existing
  `if(startMission != undefined)` block; `grantAllCards()`'s `hasCard()` guard
  means calling it twice (once here, once more if a camp/Buguese flag is also
  set) is harmless.
- **Deck A/B/C tiering by gold value**: every card a player is granted (via
  `grantAllCards()`, `gearUpForMission()`'s curated list, or any of the four
  boss fights' gearing) used to hardcode `deck:7` — "always active regardless
  of which of decks A/B/C is selected" (the meaning of `deck` values 1-7 was
  reverse-engineered from `battleSystem/scripts/DefineSprite_3152/frame_1/DoAction_6.as:124-135`:
  `1`=A only, `2`=B only, `3`=C only, `4`=A+B, `5`=A+C, `6`=B+C, `7`=all
  three). A new `deckForCard(cardId)` in `frame_10/DoAction.as` (right after
  `hasCard()`) looks the card's real shop price up via the existing
  `findCardObj()`, strips the trailing `g`, and buckets it: deck **C** always
  gets everything; deck **B** gets `500g`–`1999g`; deck **A** gets `1500g`
  and up with no ceiling (so `1500g`–`1999g` cards sit in both A and B; cards
  at `2000g`+ are A-only, not B — a deliberate closed range, not a floor).
  Cards with no shop price (`N/Ag` — reward-only cards) count as `0` and land
  in C only. Both `deck:7` call sites were changed to
  `deck:deckForCard(id)`. Only affects newly-granted cards going forward —
  same `hasCard()`-guarded non-destructive pattern as everything else, so a
  card a save already has keeps whatever `deck` value it was first granted
  with.

  **Bug found and fixed right after shipping the above**: a real playtest
  screenshot showed an almost-empty hand in an actual battle (0-1 of the ~21
  cards that should qualify for deck A). Root cause: `cardData` (the array
  `deckForCard()`/`findCardObj()` need to look up a card's cost) was declared
  at the very *end* of `frame_10/DoAction.as`, but `grantAllCards()`/
  `gearUpForMission()` get called earlier in that same frame's boot logic
  (`index.html` always sends a `startMission` FlashVar — even for boss
  fights, where it silently falls back to `"1"` since `parseInt("buguese")`
  is `NaN`). So on every mission-select or boss-fight launch, cards were
  first granted while `cardData` was still `undefined` — `findCardObj()`
  found nothing, `deckForCard()` fell through its `undefined`-cost branch,
  and *every* card landed on `deck:3` (C-only). The `hasCard()` guard then
  meant nothing ever got corrected on a later call. Fixed by moving the
  `cardData = [...]` literal to right after the function definitions, before
  any boot logic can call the functions that depend on it — same file, no
  new code, pure reordering (verified as a pure move: sorted line sets of
  the before/after file are identical).
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

- **Shield Master fix**: reported as "this doesn't work" (screenshot from a
  bonus mission) for the sibling **Rider Master** card. Investigating the
  whole "Master" card family (`battleSystem_2.swf`,
  `DefineSprite_3152/frame_1/DoAction_3.as`'s `TableCardBattleAction`, plus
  the two stat-panel clips `PlaceObject2_2941_394` (player) and
  `PlaceObject2_2966_441` (opponent) that consume the one-shot flags) against
  the actual localized card text in `sprSettings01_EN.xml` found the "fix all
  5" framing from earlier in this session was too broad: **Weapon Master**,
  **Boost Blaze**, and **Light of the Oracle** describe converting dice
  *already rolled this turn* — the existing one-shot-at-play-time code
  matches that description exactly and needed no change. Only two cards
  describe a forward-looking, card-type-triggered aura ("**All** weapon
  Equipment card give you +2 damage" / "**Shield** Equipment card give you +2
  defense"), and only **Shield Master** was actually broken in code: the
  opponent-side clip cleared the wrong flag (`riderMasterEq` instead of
  `shldMasterEq` — a copy-paste bug) and added its bonus to `DiceRed` (an
  *attack* pool) instead of defense; the player-side clip's Shield Master
  block did nothing at all (dead code, no bonus applied). Rider Master
  itself was already working as coded — `DiceRed += WeaponInGame() * 2` is
  correct — though it only counts weapon cards already in play at the moment
  Rider Master resolves, not ones added afterward, which can make it feel
  like nothing happened if few/no other weapons are out yet; that's the
  original one-shot design, not a bug, and was left alone. Fixed both clips'
  Shield Master block to clear `shldMasterEq` and apply
  `ShieldInGame() * 2` to `DefendMalusPlayer`/`DefendMalusOpponent`
  (subtracting from the existing malus pool — confirmed as a legitimate
  defense-bonus channel by cross-referencing the "Shadow" debuff card, which
  already nudges the same variable the other direction).
  `battleSystem_2.orig.swf` is the pre-session backup (predates this and
  every other `battleSystem_2.swf` patch this session).

- **Boss fights (Buguese, Magma, Stag, Prince Lumens)**: four new
  mission-select entries, "*Name* (Boss Fight)" (`index.html`'s dropdown →
  a `BOSS_FIGHTS` map of value → `{label, flashVar}`, each riding its own
  `startX` FlashVar into the shell, same pattern as the bonus missions).
  All four were previously only reachable through the game's dead
  multiplayer world hub (`decompiled/world/`) — none of them have a
  single-player story mission. `frame_10/DoAction.as` gets a new shared
  `startBossFight(bossType, bossCard)` helper (added alongside
  `grantAllCards()`/`gearUpForMission()`): gears the player
  (`gearUpForMission(15)` + `grantAllCards()`, so this doesn't wipe out a
  fresh character), sets `root.inWorld = true` (the stat tables in
  `DoAction_3.as` branch on `inWorld` — for Buguese/Stag specifically it's
  `inWorld||inCamp` — `true` consistently selects the harder/tankier
  world-hub variant over the milder single-player fallback, where one
  exists), builds `ennemyStats` with the given `type`/`card`, and calls
  `root.battleSystem.initBattle(...)` directly with the same
  `setInterval` readiness-poll and `CallbackEndBattle` win/lose handling
  Buguese's original patch used. `frame_54`'s dispatcher gets one `else if`
  branch per boss, each just clearing its flag and calling
  `startBossFight(type, card)` — no new SWF frames inserted anywhere for
  any of the four. Per-boss specifics:
  - **Buguese** (id `605`, `TableEncounterMantisSqad[5]`): Dice 18/Defence
    20/Life 45/400 victory points, `bugueseDeck` — same as before, now
    routed through the shared helper.
  - **Magma** (id `502`, `TableEncounterSpiderRider[2]`,
    `DoAction_3.as:79-92`): Dice 16/Defence 10/Life 20/150 victory points
    (both branches are identical for Magma — no hard/mild split), real
    `magmaDeck` from `decompiled/world/script/scripts/frame_2/DoAction.as:1176`.
    Notably a much lower-tier fight than Buguese; that's the real data, left
    as-is rather than inflated.
  - **Stag** (id `604`, `TableEncounterMantisSqad[4]`,
    `DoAction_3.as:94-109`): Dice 16/Defence 15/Life 40/270 victory points
    (harder `inWorld||inCamp` branch), real `stagDeck` from
    `decompiled/world/script/scripts/frame_2/DoAction.as:1177`.
  - **Prince Lumens** (id `503`, `TableEncounterSpiderRider[3]`,
    `DoAction_3.as:79-92`): Dice 15/Defence 15/Life 30/140 victory points
    (harder `inWorld` branch). Unlike the other three, Lumens has **no**
    real NPC object or card deck anywhere in the decompiled tree — confirmed
    genuinely cut/unfinished content, not a lookup miss. Since he's
    otherwise the weakest of the four on raw stats, he was given an
    invented 22-card deck (`106,106,110,204,205,208,208,301,300,508,508,
    508,508,509,509,510,510,511,511,507,506,504` — two Elite Plate Armor,
    two Arachna Power, leaning into the same high-cost weapon/shield/boost
    mix Magma and Buguese's real decks favor) so he plays as a comparably
    tough boss instead of a pushover, rather than leaving him without a
    deck at all.

**Shield Master and the original Buguese fight were confirmed with an actual
live playthrough** — see the verification note below. **Everything since —
mission-select's `grantAllCards()` addition, all three new boss fights
(Magma/Stag/Lumens) plus the `startBossFight()` refactor, and the deck A/B/C
gold-tier system — was not.** Same clean-diff verification as everything
else each time, and `startBossFight()`/`deckForCard()` both reuse mechanisms
already proven live-working elsewhere in the same build — but repeated
attempts to click through a normal mission-select or boss-fight launch have
stalled on Ruffle's own preloader animation before even reaching the login
screen every time since, with no console errors. See below — this looks like
the pre-existing AVM1 flakiness resurfacing, not a regression, but it's
genuinely unconfirmed by an actual playthrough.

**Everything else has not been confirmed with a live playthrough.**
Earlier attempts this session assumed the sandbox couldn't get Ruffle's AVM1
loop to run at all (`document.visibilityState` stuck `"hidden"` under whatever
setup was tried then). The Shield Master / Buguese verification turned out to
be the first time this session actually got past the login screen — served
over `http(s)`, not `file://` (browsers block WASM/fetch on `file://`
regardless), and clicking through with *any* non-blank username/password (see
"Why this works with no server" above — `callScriptEnable` is permanently
`false`, so login always no-ops and succeeds). Once past that, AVM1 ran
completely normally that time: dice actually rolled, damage actually applied
to the HUD, new cards actually got drawn into the deck, and the Buguese fight
rendered with correct art, the correct harder stat branch, and a geared-up
player, all matching what the code predicted. But it isn't reliably
reproducible on demand — the very next attempt (mission-select, above)
stalled before even reaching login, across multiple fresh tabs and waits over
10s. So the earlier "AVM1 won't run here" belief looks like real, still-
unresolved intermittent flakiness in this sandbox (possibly tied to
`requestAnimationFrame` throttling on a backgrounded/non-visible tab), not
something reliably worth depending on — worth retrying against the *other*
patches in this list, but don't be surprised if it stalls, and don't treat one
success as proof the sandbox issue is gone.

- **Boss-fight cosmetic armor fix**: a real playtest screenshot of the
  Buguese fight showed the hero in plain civilian clothes despite being
  fully geared for combat. Root cause: `typeArmor`/`typeManacle` (the
  costume-tier variables the battle screen's `mainChar` clip reads via
  `mainChar.typeBody = 4 + root.typeArmor` in
  `battleSystem/scripts/frame_1/DoAction.as`'s `initBattle()`) are computed
  in `frame_10/DoAction.as` from `playerStats.mission` *before* any boss
  fight logic runs — and `playerStats.mission` is stuck at `1` for every
  boss fight, for the same `parseInt("buguese")==NaN` fallback reason as
  the card-loading bug above. `startBossFight()`'s own `gearUpForMission(15)`
  call only buffs stats/cards/rank; it never touched the cosmetic variables.
  Fixed by having `startBossFight()` also set `root.typeArmor`/
  `root.typeManacle` to the same mission-15 tier it already gears everything
  else to.
- **`GAMEDEBUG` was backwards**: `index.html` passed the *string* `"false"`
  as the FlashVar, intending to disable debug mode — but AS2 treats any
  non-empty string as truthy, so every bare `if(GAMEDEBUG)`/`if(!GAMEDEBUG)`
  check in the SWF (`SpiderRider/script/scripts/frame_1/DoAction.as` and
  others) was actually running as if debug mode were *on* the whole time:
  world-map debug overlay clips forced visible, analytics pings always
  suppressed, and the game always connecting to the dev multiplayer room
  server instead of prod. Fixed in `index.html` alone — passing `""`
  (empty string) instead of `"false"` is falsy in AS2 while still
  registering as "set" (so it still skips the SWF's own separate
  "default to true if unset" fallback). No SWF patch needed. Note: a
  battle-screen debug stat panel (event/state/mission/gils/xp fields) and
  some "HIGHLIGHT"/"SHADER"-labeled art seen in the same screenshots could
  not be tied to `GAMEDEBUG` or any other flag from the script-only
  decompile — genuinely unconfirmed whether this fix also resolves those;
  needs a fresh screenshot to check.
- **Player always goes first**: `battleSystem/scripts/DefineSprite_3152/frame_1/DoAction_9.as`'s
  `InitAfterDraw()` decided turn order by `Opponent.ID` — under 200 always
  gave the player first turn, under 300 always gave the opponent first
  turn, and *everything else* (300+, which includes every real story-mission
  monster and all four new boss fights) was a 50/50 `Math.random()` coin
  flip. Changed that branch to unconditionally set `CurrentPlayer =
  TURN_PLAYER`, so the player now always acts first in every battle that
  previously randomized it. Verified via a normalized diff (stripping
  FFDec's arbitrary `_locN_` renumbering, which changes on every
  recompile even in completely untouched functions elsewhere in the same
  file) down to exactly the one intended line plus one unrelated, provably
  equivalent cosmetic rewrite (`x = x + 1` re-rendered as `x += 1`) — cross-
  checked against raw P-code to confirm no logic was dropped, consistent
  with this project's established "don't trust the plain decompile alone"
  practice.
- **The armor fix above got silently reverted, then re-fixed.** A follow-up
  playtest screenshot showed the hero back in civilian clothes with *no*
  further code changes in between — a real regression, not flakiness. Two
  agent investigations later: the first traced the actual DisplayList and
  found the battle module's costume-selector clips (`DefineSprite_1571`,
  `_1927`, and ~30-odd siblings, one pair per combat pose: idle/attack/hurt/
  win/etc.) are *not* one-shot — the pose controller
  (`DefineSprite_3152/frame_1/DoAction_9.as`) calls
  `AnimPlayer.Avatar.gotoAndStop(state)` on every single turn action, and
  since each pose is a non-"move" `PlaceObject2` placement, Flash fully
  reconstructs it (and re-runs its `gotoAndStop(mainChar.typeBody)` one-liner)
  every time. So the armor mechanism was never structurally broken — it just
  needed `root.typeArmor` to actually hold the right value when a pose
  rendered. Direct re-export of the *live* SWF (not a cached decompile)
  confirmed why it didn't: `startBossFight()` no longer contained the
  `root.typeArmor = 28` / `root.typeManacle` lines from the original fix.
  They were lost when the **card-order fix** (above) reimported a whole
  rebuilt `frame_10/DoAction.as` — that edit was built by slicing an export
  that predated the armor fix, so re-importing it silently reverted armor
  while keeping the card fix. **Lesson for this project**: when two patches
  touch the *same* decompiled file in the same session, each one needs a
  fresh export of the *currently-live* SWF immediately before editing —
  never reuse an earlier round's intermediate export, even from minutes
  earlier. Re-applied the two lines against a freshly-exported current copy,
  verified via isolated diff (`142a143,144`, nothing else in the 808-file
  export changed), redeployed, MD5-confirmed.
- **"Clear autosave & start fresh" button** (`index.html`): added to rule out
  a stale-save explanation for the card-hand bug — `SharedObject.getLocal
  ("spiderSo")` (`frame_1/DoAction.as:14`) persists across every server-side
  fix, and `hasCard()` never revisits a card a save already owns. The button
  clears any `localStorage` key containing `"spiderSo"` (Ruffle's web
  backend has no documented fixed key-naming scheme, so it matches on the
  literal SharedObject name rather than guessing Ruffle's prefix format) and
  reports how many keys it cleared. Pure JS, no SWF patch.
- **In-game boss/bonus-mission menu**: previously the only way to reach the 4
  boss fights or 3 bonus missions was the pre-boot HTML dropdown. Investigated
  whether an in-game "world map" screen exists to attach new hotspots to — it
  doesn't; single-player has no walkable hub, just mission-select → a
  background preload chain (guild/chat/multiplayer-hub preload, unrelated to
  the player) → straight into whatever was picked. So instead of inventing a
  fake screen, added a runtime-drawn overlay (`createEmptyMovieClip` +
  drawing API + dynamic `TextField`s, no new `DefineButton2`/`PlaceObject2`
  tags) inside the existing in-game character/options window
  (`root.charWindow`, opened by the same HUD button players already use).
  Lists all 4 bosses and 3 bonus missions, each calling the exact same
  `startBossFight(bossType, bossCard)` / camp-trigger code the dropdown uses
  (args copied verbatim from `frame_54/DoAction.as`'s dispatch table, so
  behavior is identical either way). `frame_10/PlaceObject2_1865_201/
  CLIPACTIONRECORD onClipEvent(load).as` — isolated diff, only this file
  changed.
- **`playerStats.gils` was `NaN` in every save.** Fresh saves never
  initialized it; the first gold reward anywhere (`addGils()`,
  `frame_2/DoAction.as:412`) computed `Number(undefined) + Number(amount)` =
  `NaN`, permanently baked into the save from that point on (`Array.join`
  renders `undefined` as `""`, but `NaN.toString()` is literally `"NaN"` —
  that's what showed up in a downloaded save). Fixed by adding
  `playerStats.gils = 0;` to the fresh-save init block in `frame_10/
  DoAction.as`. One-line isolated diff.
- **Default player name changed from `""` to `"Hunter"`** (`frame_10/
  DoAction.as`) — cosmetic, requested directly. `Name` only ever gets a real
  value through the character-creation flow, which the mission-select
  shortcut skips entirely, so it was always blank for any session started
  that way.
- **Mission-1 tutorial popup misfiring for boss fights and bonus missions.**
  `index.html` always sends a `startMission` FlashVar (falling back to `"1"`
  for boss/camp picks via `parseInt(NaN)||1`), and neither `startBossFight()`
  nor the camp dispatch branch (`frame_54/DoAction.as`) ever updated
  `playerStats.mission` away from that stuck default — so on a fresh save,
  `playerStats.mission` stayed `1` forever for any shortcut-started session.
  The battle module's tutorial gate (`battleSystem/frame_1/DoAction.as`'s
  `initBattle()`) fires `showTutorial=true` specifically when
  `playerStats.mission==1` — hence the first-battle-only "To throw the dice,
  click..." popup reappearing every time. (It's masked for boss fights
  specifically because `startBossFight()` also sets `root.inWorld=true`,
  which independently short-circuits the same gate — bonus missions never
  set that flag, so they were the ones actually showing the popup.) Fixed by
  setting `root.playerStats.mission = 15` in both `startBossFight()` and the
  camp dispatch branch — two one-line additions, isolated diff confirmed
  across both files.
- **Card-hand size: corrected a wrong assumption from earlier this session.**
  Previously assumed the battle hand should show ~21 cards (everything
  costing 1500g+). That's wrong — the game caps hand size at
  `min(deckPool.length, 7)` by design (`battleSystem/DefineSprite_3152/
  frame_1/DoAction_9.as`), drawing randomly without replacement from the
  eligible pool, same as any normal card game.
- **Root cause of the near-empty `Player.CardDeck` found and fixed:
  `deckActive` defaulted to the most restrictive tier.** Live testing (a
  boss fight, then independently a real mission-3 battle) showed 0-1 cards
  in hand, with the occasional card (e.g. the 3000g "Lightning bolt")
  flickering in then out — captured on video and confirmed frame-by-frame.
  The "Deck A/B/C tiering by gold value" feature above (added earlier the
  same day, before this fix) is working exactly as designed — the actual bug
  was one line above it, `root.deckActive = "A";` (`frame_10/DoAction.as`,
  part of the original boot sequence, unconditional on every load), which
  selects deck **A** — the *narrowest* tier (1500g and up only) — as the
  default. `battleSystem/DefineSprite_3152/frame_1/DoAction_6.as:124-135`
  intersects `deckActive` against each card's `deckForCard()` bucket to
  build `Player.CardDeck`; with `deckActive=="A"`, only cards costing
  2000g+ or 1500g-1999g ever qualify — exactly matching "Lightning bolt
  (3000g) flickered in" while everything else stayed empty, since most
  granted cards are starter-tier (200g-1000g). Confirmed via `git log` that
  this default predates the tiering feature and was never touched by it —
  before that feature existed every card hardcoded `deck:7` (all three
  tiers at once), so the restrictive default was harmless until the tiering
  feature made it matter. Fixed by changing the default to deck **C** (the
  catch-all tier — every `deckForCard()` bucket intersects it), restoring
  "every owned card is drawable" as the out-of-the-box behavior while
  keeping the A/B tabs (`activeDeck` clip, present on every mission/camp
  screen) working for anyone who deliberately wants to filter down to
  pricier cards. One-line isolated diff, `frame_10/DoAction.as`.
- **Music starts muted by default.** `index.html` sets `player.volume = 0`
  right after the Ruffle player element is created. The in-game speaker icon
  (top right of the stage) still toggles it back on — this only changes
  what a fresh page load starts with. Pure JS, no SWF patch.
- **Instant boss fight: skip the entire preload chain from the pre-boot
  dropdown.** Picking a boss from the HTML dropdown used to still walk
  through the full guild/chat/multiplayer/`world_2.swf` preload sequence
  before `startBossFight()` ever ran. Added, at the end of the existing
  `if(!callScriptEnable){...}` boot block in `frame_10/DoAction.as`: if any
  `root.start<Boss>` flag is set, jump straight to `gotoAndStop(54)` (the
  dispatch frame `startBossFight()` lives on) and kick off
  `battleSystem.loadMovie(...)` immediately, bypassing every intervening
  frame's own load-time setup. Relies on `gotoAndStop()`'s AS2 semantics —
  jumping forward synthesizes the intervening frames' DisplayList (so
  everything still gets placed) without executing their DoAction scripts —
  and on `startBossFight()`'s own `setInterval` readiness-poll for
  `battleSystem.initBattle`, which already exists to absorb exactly this
  kind of load-time gap. Confirmed working live (Prince Lumens loaded and
  was playable straight from the dropdown, no preload wait).
- **Register and Save Avatar: "please wait" dialog that never closes.**
  `subscribeUser()` and `updatePlayer()` (`SpiderRider/.../frame_2/DoAction.as`)
  both unconditionally pushed a `callObj`, called `processCall()` (a no-op —
  its entire body is gated on `callScriptEnable`, hardcoded `false` and never
  set `true` anywhere), and then unconditionally called
  `criticMsgWindow.drawWindow(...)` with no guard. Since `loadMc.onData =
  handleReply` is only ever assigned inside that same dead
  `if(callScriptEnable)` branch in `processCall()`, `handleReply()` — the only
  thing that ever calls `criticMsgWindow.closeWindow()` — can never fire, so
  the dialog opens and never closes. `tryLogin()`, right next to both of
  these in the same file, already had the correct pattern: check
  `callScriptEnable` first, short-circuit when false. `updatePlayer()` is
  reachable from a "Save Avatar" button (`DefineButton2_1877`) plus ~19
  mission/menu-frame `onClipEvent(load)` handlers; `subscribeUser()` from the
  three Register-screen buttons/clips. Fixed both to match `tryLogin()`'s
  shape: the whole network/dialog portion moved inside
  `if(callScriptEnable){...}`. `subscribeUser()`'s `else` closes the register
  sub-window directly (`loginWindow.registerWindow.closeWindow()` — the same
  call the real server-success path already used, confirmed by reading the
  `"subscribeuser"` case in `handleReply()`). `updatePlayer()`'s `else` does
  nothing: `updateAllCards()` (the one part of the function with no network
  dependency) still runs unconditionally before the `if`, and the real
  server-success path for `updatePlayer()`'s call (`"newplayer"`) turned out
  to just fall through to `handleReply()`'s `default: processCall();` — no
  state change beyond closing a dialog that, offline, was never opened.
  Verified via a clean isolated diff: re-exporting the whole 808-file script
  tree after reimport shows only `frame_2/DoAction.as` changed, and within
  it, only these two functions. (Reimporting this file also required
  stripping a pre-existing decompiler artifact unrelated to this fix — a
  `loop16:` switch label plus its unreachable `break loop16;`, dead code
  after an unconditional `continue;` in `xmlLoaded()` — FFDec's script
  importer rejects the file otherwise; confirmed cosmetic-only, since
  re-exporting after reimport does not reintroduce it and no other line
  changed.) **Not confirmed with a live playthrough** — this session's
  Ruffle instance stalled on the preloader animation before reaching the
  login screen in two separate fresh tabs (`document.visibilityState` stuck
  `"hidden"`), the same pre-existing sandbox flakiness noted elsewhere in
  this file, not something this fix could have caused. The fix logic itself
  is static — a straight `if/else` gate on a flag that is always `false` —
  so live confirmation would only be re-proving the mechanism already
  verified by the clean diff, but it's still genuinely unconfirmed by an
  actual playthrough.
- **Dice roll: game stalls right after rolling, cards can't be dragged.**
  Reported directly from a live playthrough: cards dealt into the hand fine,
  clicking "Throw the dice" rolled correctly, then the game just sat there —
  dice couldn't be dragged onto cards. Root cause,
  `battleSystem/scripts/DefineSprite_3152/frame_1/DoAction_9.as`:
  `CumulateRedDice()` moves red dice to the attack-total display one at a
  time via a chained `setInterval`/`onEnterFrame` handoff, but had no
  fallback for "no red dice left" — its `for(var _loc1_ in Dices)` loop just
  did nothing when it matched nothing, so the interval it was called from
  kept firing forever and `CumulateBlueDice()` (the function that sets
  `MODE_CARD`) was never reached. Dice can only be dragged onto cards when
  `CurrentMode == MODE_CARD` (checked in the dice's own `on(press)` handler,
  `DefineButton2_2638`), so this one missing branch explains both symptoms:
  any roll with zero or now-fully-processed red dice soft-locks the turn.
  Fixed by tracking whether a red die was found each pass; if not, clear the
  interval and call `CumulateBlueDice()` directly. Also fixed a second,
  related bug in the same file: `RemoveWhiteDice()` called
  `Dices[_loc1_].splice(_loc1_,1)` — `.splice()` on a single dice
  *MovieClip*, not on the `Dices` array — so white dice were flagged removed
  visually but never actually left the tracked array (compare
  `CumulateRedDice()`'s own correct `Dices.splice(_loc1_,1)` a few lines
  down). Rewrote it as a reverse-indexed loop splicing the array directly,
  avoiding the original's implicit assumption that a forward `for...in`
  tolerates live mutation. Verified via isolated diff: only this file
  changed, only these two functions. **Not confirmed with a live
  playthrough on my end** — this session's Ruffle instance stopped
  responding to synthetic clicks entirely (the same sandbox
  `document.visibilityState` quirk, confirmed this time by a click that
  produced zero pixel change), so this needs a real playthrough to close
  the loop.
- **Boss fights redirect into Mission 1 instead of starting the battle.**
  With the charWindow-reopening race above already fixed, boss fights
  (Buguese/Magma/Stag/Prince Lumens, instant-launch path) still didn't
  work: confirmed via live trace that `startBossFight()` runs and calls
  `battleSystem.initBattle(...)` correctly, but the screen then shows
  "MISSION 1 / READY" instead of the battle. Root cause: the instant-launch
  path's `gotoAndStop(54)` — per this project's own confirmed AS2 semantics
  — synthesizes every intervening frame's DisplayList, including frame 48's
  `emptyClip` (the normal, non-boss world-hub preload placeholder). Frame
  48's `onClipEvent(load)` unconditionally calls
  `loadWindow.setLoader(this, fct, ...)`, hijacking the shared `loadWindow`
  spinner's target away from `battleSystem` (which `frame_10` had correctly
  registered moments earlier) — the same class of bug as the charWindow
  race, a second caller nobody had accounted for. Because the hijacked
  `emptyClip` never actually has a real `loadMovie()` call run against it
  during the skip-jump, `loadWindow`'s progress poll reads it as instantly
  "fully loaded" and fires the hijacked callback, which does
  `root.nextFrame()` — landing on the frame labeled `"level1"` and loading
  Mission 1's map instead. Fixed the same way as the charWindow race: the
  existing `bossReadyPoll` watchdog in `startBossFight()`
  (`frame_10/DoAction.as`) now also re-pins `root.loadWindow.target` back
  to `root.battleSystem` (and `loadFct` back to a no-op) on every 100ms
  tick, for the same ~3s window — faster than any hijacker's near-instant
  completion can act on a stolen registration. Verified via isolated diff:
  7 lines added, one function, nothing else touched. **Bug reproduction
  confirmed live** (trace log + screenshot showing the Mission 1 splash);
  **the fix itself could not be re-confirmed live** — same sandbox
  rendering-stall as above, hit on every retry across fresh tabs for the
  rest of the session.
- **Boss fights now force `deckActive = "A"`.** Requested directly: boss
  fights should draw only from the priciest card tier. `deckActive`
  filters `Player.CardDeck` by cost bracket at battle-init
  (`battleSystem/scripts/DefineSprite_3152/frame_1/DoAction_6.as`, matched
  against each card's `deckForCard()` bucket from `frame_10/DoAction.as`):
  `"A"` only admits 1500g+ cards (bucket 5 or 7), `"B"` admits 500g+ minus
  the top tier (6 or 7), the global default `"C"` admits everything (3, 5,
  6, or 7 — see the near-empty-hand fix above for why that's the sane
  global default). Checked before wiring this up: unlike a fresh mission
  start, `startBossFight()` already calls `grantAllCards()`, which grants
  the full ~60-card catalog including 20+ cards at 1500g+ — so restricting
  to deck A here doesn't reintroduce the near-empty-hand bug fixed above,
  it just narrows a large, already-owned pool down to the expensive end of
  it. Added `root.deckActive = "A";` at the top of `startBossFight()`,
  scoped to boss fights only — the global default and regular missions are
  untouched. One-line isolated diff, `frame_10/DoAction.as`.
- **Mission-select dropdown trimmed back to Mission 1-15.** The pre-boot
  HTML dropdown (`index.html`) had grown to also list "Bonus Mission 1/2/3"
  and the 4 "*Name* (Boss Fight)" entries added in earlier sessions -
  removed those two `<option>`-generating loops so the dropdown is just
  Mission 1-15 again. Both are meant to be reached in-game instead: bonus
  missions via the Character Sheet's real "BONUS LEVELS" button plus a
  webcode, boss fights via the Character Sheet's new "Boss Fights" button
  (below). The now-dead `BOSS_FIGHTS`/`chosenCamp` JS in `launchPlayer` was
  left in place rather than ripped out - `selectedValue` can only ever be
  `"1".."15"` now, so those branches never fire, but it's harmless and the
  trim didn't need the extra risk of touching more than the two loops.

  Added a small note under the dropdown surfacing the 3 real bonus-mission
  webcodes, recovered directly from `sprSettings01_EN.xml`'s
  `<webcodes>shadow,Lumens,Grasshop</webcodes>` (confirmed against
  `DefineSprite_1161/frame_1/PlaceObject2_147_10`'s `onClipEvent(load)`:
  `webcode = root.webcodeArray[0/1/2]` for camp 1/2/3 respectively, checked
  via a plain client-side string compare against `webcodeTxt.text` - no
  server call, so this already works fully offline, nothing to fix): Bonus
  1 = `shadow`, Bonus 2 = `Lumens`, Bonus 3 = `Grasshop` (exact case). Pure
  `index.html` change, no SWF patch - styled to match the existing dark
  mission-select screen.
- **Character Sheet boss-fight button.** Removing the boss-fight dropdown
  shortcuts above raised a real question: are the 4 boss fights still
  reachable at all without them? Traced the shell SWF's full display list
  (`ffdec -dumpSWF`, not `-export script` alone - script export only
  surfaces clips that *have* a clip action, and the placement in question
  turned out to have none) for every `PlaceObject2` referencing `optionBar`
  (`DefineSprite_1960`, whose nested `PlaceObject2_1958_68` button calls
  `root.charWindow.drawWindow3()` on press - the same function the
  existing in-game boss menu, see "In-game boss/bonus-mission menu" above,
  hangs off). There is exactly one such placement in the whole SWF:
  main-timeline frame 46, depth 7 - inside the "world" label's frame range
  (45-50, right before "level1" at 51), the background guild/chat/
  multiplayer-hub preload chain this single-player rebuild walks through
  but never actually renders (see "Other gated content" below). Its
  `onPress` handler also closes `root.upPanel`/`root.downPanel` - world-hub
  HUD panels, confirming it's world-hub-only, not Character Sheet content.
  Cross-checked by grepping every `.drawWindow3()` call across a fresh
  808-file script export: `optionBar` is the *only* caller anywhere in the
  SWF. By contrast, the real Character Sheet (`charWindow.drawWindow()`,
  the "charSheet" tab) has a genuine per-mission trigger - every
  `scr1_2.swf` through `scr15_2.swf` places a HUD button (e.g. `scr1_2.swf`'s
  `frame_2/PlaceObject2_154_231`) whose press sets
  `root.upPanel.endFct = root.charWindow.drawWindow` before closing the
  panels, so the Character Sheet itself is genuinely reachable mid-mission
  - the boss-fight/"options" tab never was.

  Fixed by adding a small always-visible "Boss Fights" button directly to
  the Character Sheet's own tab (`scripts/DefineSprite_1865/frame_8/
  DoAction.as`, the "charSheet" frame body - `DefineSprite_1865` is
  `charWindow`'s own character id) - same `createEmptyMovieClip`+
  drawing-API pattern the existing boss-menu overlay itself already uses
  (no new `DefineButton2`/`PlaceObject2` tags), calling the exact same
  `drawWindow3()` `optionBar` already used. Verified via isolated diff
  (fresh `-export script` before/after the reimport, full 808-file tree):
  only this one file changed, exactly the added block. **Confirmed with an
  actual live playthrough** - Ruffle rendered normally this session
  (unlike most of this file's other "could not confirm live" notes):
  logged in, landed on the auto-opened Character Sheet, the new "Boss
  Fights" button appeared bottom-left exactly as placed, clicking it
  opened the "OPTIONS" tab with the same Buguese/Magma/Stag/Prince Lumens
  overlay the in-world menu draws, and clicking Buguese launched the real
  battle (Dice 18/Defence 20/Life 45 opponent, matching the documented
  stats above, a geared player, a populated hand, zero console errors).

- **Boss Fights button didn't match the game's own button chrome, and
  overlapped the character sheet's own tab row.** The button added above
  was a flat, hand-drawn rectangle at a hardcoded `(_x=10, _y=450)` -
  measuring every `PlaceObject2` matrix in `DefineSprite_1865/frame_8` via
  `-swf2xml` showed that position landing almost exactly on `btn_saveAva`
  (y=453.8), i.e. on top of the persistent LOGOUT/SAVE AVATAR/MISSION/
  ARACHNA ONLINE/BONUS LEVELS bar, matching a user screenshot report
  exactly. Moved it to an empirically-empty band (y≈36-84px, below the
  character sheet's own sub-tabs, above the stat grid) checked against
  every named button and text field's actual measured position in that
  frame - no linkage/export name exists for the game's real button symbol
  (character 624), so it's redrawn by hand via `beginGradientFill`/
  `lineStyle` using the exact gradient/border RGBA stops and near-white
  label color (`0xECFFFF`) confirmed from the real MISSION/Solo buttons'
  own shape and text data, as a slanted banner instead of a flat box. Font
  is an approximation (`_sans` device font, no embedded-font linkage
  found) - everything else is a measured match, not a guess.
- **Boss fights permanently set `playerStats.mission = 15`, sending any
  fallback redirect (e.g. after the battle ends) to the *start* of Mission
  15 instead of treating the campaign as finished.** The game already has
  a canonical "campaign complete" value for this: frame 158 (the real
  "level16" frame, reached when Mission 15 is finished normally) sets
  `playerStats.mission = 16` and shows `nameMisEnd` -
  `"CONGRATULATIONS ON COMPLETING THE MISSIONS!"` - confirmed via
  `-swf2xml`, verified no code anywhere indexes `playerStats.mission` as
  an array (only clamped math and the `"level"+mission` string). Changed
  `startBossFight()` to set `16` instead of `15`, reusing the game's own
  existing "only boss fights and bonus levels left" state rather than
  inventing a new one. Also added a "Missions Complete (Boss Fights +
  Bonus only)" option to the `index.html` mission dropdown, wired through
  the same `startMission` FlashVar, so players can jump straight to that
  state without going through a boss fight first.
- **Cheats toggle.** Before this, picking *any* mission from the
  `index.html` dropdown - even Mission 1 - unconditionally called
  `grantAllCards()` (all 61 cards) and, for missions after 1,
  `gearUpForMission()` (mission-tier victory points, early spider-mount
  access, mission-appropriate gear cards): there was no way to actually
  play the game normally from this launcher. Added a "Cheats" checkbox to
  the mission-select screen, default **off**, sent as a new
  `cheatsEnabled` FlashVar. `scripts/frame_10/DoAction.as` now only calls
  those two functions from the `startMission` handler when
  `cheatsEnabled` is true (normalized from the FlashVar string *before*
  first use, not near the unrelated `autoBattle` normalization further
  down the same frame script - this is sequential top-level frame code,
  not a function, so normalizing after the gates had already evaluated
  the raw truthy string would have made the toggle always-on). The
  cosmetic armor/manacle tier (`typeArmor`/`typeManacle` - which outfit
  renders, not a stat) still auto-adjusts regardless, and
  `startBossFight()`'s own unconditional `grantAllCards()`/
  `gearUpForMission(15)` (the boss-fight fair-fight guarantee) is
  untouched.
- **Boss selection menu overlapped the Boss Fights button and wasted
  space.** `openBossMenu()` (`scripts/frame_10/PlaceObject2_1865_201/
  CLIPACTIONRECORD onClipEvent(load).as`, the real `charWindow` clip
  actions) drew a fixed 220x150 vertical list at a hardcoded `(40,40)` -
  which happened to sit almost exactly on top of the Boss Fights button
  itself (still mounted and visible underneath, at a lower depth, while
  the menu is open), matching a user screenshot showing "Buguese" and
  "Boss Fights" text overlapping. Measured every named instance's position
  in the charSheet frame via `-swf2xml`: the sub-tab icon row ends around
  y=45 and the stat grid starts around y=96, a wider gap than previously
  assumed. Redrew the menu as a single compact horizontal strip (5 items -
  Buguese/Magma/Stag/Prince Lumens/Close - each sized to its own label,
  22px tall instead of a 150px-tall vertical stack), anchored to
  `bossFightBtn`'s own position instead of a hardcoded coordinate, and
  hide the Boss Fights button (`_visible = false`) while the menu is open
  so the two can never overlap regardless of layout math - restored on
  Close or on `closeWindow()` (added a defensive restore there too, for
  the case where the whole Character Sheet gets closed while the boss
  menu happens to be open). Verified via isolated diff: only this one
  file changed, only within `openBossMenu()`/`closeWindow()`.
- **Boss fights granted literally every card in the game, diluting the
  fight with weak ones.** `startBossFight()` called `grantAllCards()`
  (all 61 cards) before forcing `deckActive = "A"` - but only 21 of those
  61 cards actually cost >=1500g, the tier Deck A's filter
  (`deckNbrArr = [1,4,5,7]`, which only ever matches `deckForCard()`'s
  reachable outputs 5 and 7) actually draws from. The other 40 land in
  `deckForCard()` buckets 3 or 6, neither of which Deck A's filter
  includes - so they never even show up in the boss-fight deck, they just
  bloat `playerStats.card` for no benefit while still being real weight
  in a game that reports 61 as "the full catalog." Added a new
  `grantStrongCards()` (`scripts/frame_10/DoAction.as`, right after
  `grantAllCards()`) that loops the same 61-id list but only pushes a
  card if `deckForCard()` returns 5 or 7, and swapped `startBossFight()`
  to call it instead. Boss fights still guarantee a full, non-empty Deck
  A (all 21 qualifying cards, same as before `grantAllCards()` would have
  produced once filtered) without the other 40 cards ever touching
  `playerStats.card` in the first place. `gearUpForMission(15)` (mission-
  tier victory points/rank/spider access, plus a small curated gear list)
  is untouched - only the full-catalog grant was replaced. Verified via
  isolated diff: only this one file changed, exactly the new function
  plus the one call-site swap.
- **Sound wasn't actually muted by default, despite existing code that
  looked like it should.** `index.html` already had `player.volume = 0;`
  right after `ruffle.createPlayer()` - but it was a silent no-op.
  Traced why in `ruffle-vendor/ruffle.js`: `<ruffle-player>`'s `volume`
  setter is `this.instance && this.instance.set_volume(e)`, and
  `this.instance` stays `null` until `player.load(...)` finishes building
  the WASM core - so setting it any earlier gets silently dropped and the
  movie plays at Ruffle's own hardcoded default (100%). Confirmed live:
  polling `player.volume` against the unmodified file stayed `1` for 10+
  seconds past full load, never `0`. Fixed by moving the assignment into
  `.load(...).then(...)`, after `this.instance` is guaranteed to exist -
  reverified live, volume now reads `1` for ~270ms then drops to `0` and
  stays there, including across the 2x-speed toggle's player-rebuild path
  (there's only one `createPlayer()` call site, shared by every load
  path). Caveat: the SWF has its own independent AS2 audio mixer with its
  own speaker-icon toggle on the Character Sheet
  (`root.setNewVolume()`/`sVol`, `scripts/frame_1/DoAction.as`) that has
  no connection to Ruffle's player-level volume - the icon still shows
  and toggles normally, but since the new fix mutes downstream of the
  SWF's own mixer, clicking "unmute" in-game no longer actually produces
  sound. The icon is now decorative with respect to audible output.
- **Boost (yellow) cards with dice value +3 and up never reach Deck A,
  even the ones `gearUpForMission()` grants.** Confirmed: Deep Freeze(3),
  Super Size(3), Poison Fang(4), Barbecue(5), Intervention(7), Warrior
  path(8), and Arachna power(10) all cost 300g-1400g, which
  `deckForCard()` buckets into deck 3 or 6 - neither is in Deck A's
  filter (`[1,4,5,7]`, effectively only 5 and 7 since nothing ever
  produces 1 or 4). `gearUpForMission(15)` does grant Intervention
  (`minMission:11`) as part of its curated gear list, but since it's
  tagged via `deckForCard()` like everything else, it still lands in
  deck 6 and still never shows up in a boss fight's Deck A. Requested
  directly: guarantee 2 copies each of the dice+5 (Barbecue) and dice+7
  (Intervention) cards for boss fights specifically, tagged so they
  actually land in Deck A regardless of their real gold cost. Added
  `grantBossBoostCards()` (`scripts/frame_10/DoAction.as`, right before
  `gearUpForMission`) - counts existing copies of ids 508/509 in
  `playerStats.card`, tops each up to 2 if short (never removes extras
  if you already own more), tagging any newly-added copies `deck:7` (the
  same "always in every deck" tag mission/guild pickups use) instead of
  their real cost tier. Called from `startBossFight()` right after
  `grantStrongCards()`. Verified via isolated diff: only this one file
  changed, exactly the new function plus the one call-site addition.
  Extended right after with the rest of the dice+3-and-up Boost lineup,
  per specific requested counts: dice+4 (Poison fang, id 507) x3, dice+8
  (Warrior path, id 510) x1, dice+10 (Arachna power, id 511) x1. The
  dice+3 pair (Deep Freeze id 505, Super Size id 506) was deliberately
  left out at 0 - not every Boost tier needed guaranteeing, just these
  five. Same isolated-diff verification: only `grantBossBoostCards()`'s
  `wantCounts` array line changed.

## Other gated content found but not yet unlocked

A survey for other "Buguese-style" content — stuff fully coded but gated
behind something permanently broken (dead server, expired promo) or
multiplayer-only — turned up the below. **Magma, Stag, and Prince Lumens are
now built** (see the boss fights entry above) — kept here for the record of
what was found and why each call was made:

- **`BATTLESYSTEM_DEBUG` test harness** (`battleSystem/scripts/frame_1/DoAction.as:34-97`):
  hardcoded off, but if forced on it self-populates a standalone battle
  against a preset player vs. whatever `FromEngineOpponent.type` is set to —
  i.e. a general "fight any encounter-table id directly" dev tool, not just
  one boss. More general-purpose than adding fights one at a time, if that's
  useful. Not built.
- **`rewardAccess` flag** (`SpiderRider/.../frame_1:99` +
  `frame_4/PlaceObject2_333_1662`): defaults false; a dead validation pattern
  like the old webcode lock. If forced true, four world-hub minigame events
  grant bonus collectibles instead of just gold — but this only matters if
  the world hub itself gets unlocked (see below), so lower priority alone.
  Not built.
- **The full world hub** (`world_2.swf`, plus `miniGame1_2.swf`–`miniGame6_2.swf`
  and `battleMulti_2.swf`, all present on disk): everything above only reuses
  the *battle* module standalone, same as Buguese. Unlocking the hub itself —
  chat, trading, real-time PvP dueling, minigames — is a much bigger project;
  it depends on systems that were built assuming a live server and were never
  designed to run offline.

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
