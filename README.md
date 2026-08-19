# Hollow Hour

**Hollow Hour** is a dark horror-survival mobile game built with **Flutter / Dart**.  
Players choose a survivor, clear timed campaign stages (1–30), spend **Embers** on weapons / runes / talents, and endure fog-filled arenas with a full combat loop — plus **Google AdMob TEST ads** for interstitial exits and a one-time rewarded revive.

> **Current state:** Playable end-to-end journey: onboarding → menu → prepare → live match → win / game over, with **Provider** economy persistence, pixel sprites, Mixkit audio, and **test-only AdMob**. No multiplayer or backend server.

**Repo:** [MominaYaqoob/HollowHour](https://github.com/MominaYaqoob/HollowHour)  
**Package:** `hollow_hour` · **Version:** `1.0.0+1`

---

## Table of contents

1. [Game concept](#game-concept)
2. [Tech stack](#tech-stack)
3. [Project structure](#project-structure)
4. [App startup & navigation](#app-startup--navigation)
5. [Screens — how each one works](#screens--how-each-one-works)
6. [Gameplay systems — how combat is implemented](#gameplay-systems--how-combat-is-implemented)
7. [Economy, audio, prefs, theme](#economy-audio-prefs-theme)
8. [AdMob — full implementation detail](#admob--full-implementation-detail)
9. [How to run & build](#how-to-run--build)
10. [Testing](#testing)
11. [Interview talking points](#interview-talking-points)
12. [Known limitations](#known-limitations)
13. [License / credits](#license--credits)

---

## Game concept

Pick a survivor, clear timed **stages** (Level 1 ≈ 1 minute → Level 30 = 15 minutes), unlock the next stage, and finish Level 30 to free-unlock the next character. Drag to move, aim on the right, collect XP, pick power-ups, and endure the Hollow.

| Theme | Detail |
|--------|--------|
| Genre | Dark horror-survival |
| Tone | Gothic, premium, atmospheric |
| Currency | **Embers** |
| Progression | Per-character stages **1–30** |
| Motif | Lantern, fog, charcoal + oxblood red |

### Design tokens

| Token | Value | Use |
|--------|--------|-----|
| Charcoal | `#0A0A0A` | Backgrounds |
| Maroon | `#8B1A1A` | Borders, accents, HP |
| Maroon glow | `#C41E1E` | Glow, selected states |
| Typography | Serif / monospace | Titles vs timers/stats |

### Campaign rules (from code)

- Owned character starts at **Level 1**.
- Clear stage **N** → unlock **N+1** (`EconomyState` best-level tracking).
- Clear **Level 30** → free-unlock next character in order:  
  **Wanderer → Huntress → Scholar → Brute → Ghost**.
- Duration scales ~**1:00 → 15:00** across levels (`stageDurationForLevel`).
- Spawn pressure scales with stage (`stageDepthForLevel`, mapped to former Hollow Depth 1–15).

---

## Tech stack

| Layer | Choice |
|--------|--------|
| Framework | Flutter |
| Language | Dart (SDK `^3.12.1`) |
| State | **Provider** (`provider`) |
| Navigation | `Navigator` + `PageRouteBuilder` + `FadeTransition` |
| Storage | `shared_preferences` |
| Audio | `audioplayers` |
| Ads | **`google_mobile_ads` ^9.0.0** (TEST IDs only) |
| Lint / tests | `flutter_lints`, `flutter_test` |
| Icons | `flutter_launcher_icons` |

---

## Project structure

```
lib/
  main.dart                 # Binding, audio + Mobile Ads init, Provider, _RootGate
  ads/
    ad_manager.dart         # Singleton: interstitial + rewarded (TEST units)
  audio/
    audio_manager.dart      # Music / SFX / haptics + prefs
  prefs/
    app_flags.dart          # Onboarding + tutorial booleans
  state/
    economy_state.dart      # Embers, unlocks, talents, stage progress
  theme/
    app_assets.dart         # Paths for branding, icons, sprites
    field_backdrop.dart     # Charcoal + fog field backdrop
    themed_chrome.dart      # Shared chrome widgets
  game/
    game_state.dart         # Runtime match state + revive helpers
    game_loop.dart          # ~60fps ticker, end / revive dispatch
    game_mode.dart          # Stage duration / depth helpers (+ unused modes)
    player_controller.dart  # Drag-to-move
    aim_fire_controller.dart# AIM stick + fire / reload
    enemy.dart              # Enemy AI (chase)
    enemy_spawner.dart      # Timed spawns by depth + elapsed
    collision_service.dart  # Hits, contact damage, XP collect
    magnet_spawner.dart     # Magnet pickup cadence
    leveling.dart           # In-run power-up cards
    weapon_catalog.dart     # Weapon multipliers
    rune_catalog.dart       # Rune bonuses
  screens/                  # All UI screens / overlays (see below)
assets/
  branding/  bg/  icons/  characters/  audio/  game/
android/  ios/  web/  test/
```

---

## App startup & navigation

### `main.dart` boot sequence

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Immersive sticky system UI
3. `AudioManager.instance.init()`
4. **Mobile Ads (fail-soft):**
   - `MobileAds.instance.initialize()` (8s timeout)
   - `AdManager.instance.init()` — preloads interstitial + rewarded (10s timeout)
   - Errors are caught/logged; the app **still launches** if ads fail
5. `runApp(HollowHourApp)` → `ChangeNotifierProvider<EconomyState>` → `MaterialApp`
6. **`_RootGate`** loads economy from disk, starts ambient music, then:
   - First launch → **Onboarding**
   - Else → **Splash**

### Navigation map

```
Onboarding (first launch only)
    ↓
Splash ──Tap to Begin──► Main Menu
                            ├─ ? → How to Play (overlay)
                            ├─ Settings → Privacy Policy
                            ├─ Play → Pre-Game Setup (next stage) → Gameplay HUD
                            ├─ Characters → Character Select → Pre-Game Setup → HUD
                            ├─ Talents → Talent Tree
                            └─ Shop → Shop
Gameplay HUD
    ├─ Pause overlay (Resume / Restart / Quit)
    ├─ First-match How to Play
    ├─ Level-up power-up cards
    ├─ WIN  → WinScreen (Next Level / Replay / Main Menu)
    └─ DEATH
          ├─ 1st death this run → GameOver (pushed; revive available)
          └─ later death        → GameOver (replaced; no revive)
```

---

## Screens — how each one works

| Screen | File | Purpose |
|--------|------|---------|
| Onboarding | `onboarding_screen.dart` | First-launch welcome; sets `hasSeenOnboarding` → Splash |
| Splash | `splash_screen.dart` | Icon / hourglass / fog; **Tap to Begin** → Main Menu |
| Main Menu | `main_menu_screen.dart` | Hub: Embers, Help, Settings, Play / Characters / Talents / Shop |
| How to Play | `how_to_play_overlay.dart` | Move + Aim tutorial; also first match |
| Character Select | `character_select_screen.dart` | Roster carousel + tappable level circles → Prepare |
| Pre-Game Setup | `pre_game_setup_screen.dart` | Equip weapon, stage summary → **Begin the Hour** |
| Gameplay HUD | `gameplay_hud_screen.dart` | Live match presentation + `GameLoop` wiring |
| Pause | `pause_overlay.dart` | Resume / Restart / Quit |
| Win | `win_screen.dart` | Level Cleared + Next / Replay / Main Menu |
| Game Over | `game_over_screen.dart` | Stats + optional **Watch Ad to Revive** + Retry / Menu |
| Talent Tree | `talent_tree_screen.dart` | Spend Embers on permanent nodes |
| Shop | `shop_screen.dart` | Buy/equip Characters, Weapons, Runes |
| Settings | `settings_screen.dart` | Music / SFX / Vibration; Privacy Policy |
| Privacy | `privacy_policy_screen.dart` | Local privacy copy |

### Screen-by-screen behavior

#### Onboarding
- Shown only when `AppFlags.hasSeenOnboarding()` is false.
- Continue / Skip persists the flag and navigates to Splash.
- Ambient music starts from `_RootGate` before/during this flow.

#### Splash
- Brand entrance animation (icon, hourglass, fog drift).
- **Tap to Begin** → `pushReplacement` to Main Menu.

#### Main Menu
- Reads Embers from `EconomyState`.
- **Play** jumps into Prepare for the next playable stage of the equipped character.
- **Characters / Talents / Shop / Settings / ?** open their screens with fade routes.

#### Character Select
- Carousel for Wanderer, Huntress, Scholar, Brute, Ghost.
- Level circles: cleared / current / locked from `characterBestLevel`.
- Selecting a playable level → Pre-Game Setup for that stage.

#### Pre-Game Setup
- Shows character preview, owned weapons to equip, stage duration label.
- **Begin the Hour** → `GameplayHudScreen(stageLevel: N)` via `pushReplacement`.
- Game Mode / Hollow Depth pickers were removed — **stage level owns time + difficulty**.

#### Gameplay HUD (core match screen)
- Builds `GameState` with:
  - `matchDuration = stageDurationForLevel(stage)`
  - `hollowDepth = stageDepthForLevel(stage)`
  - Talent bonuses: **maxhp**, **damage**, **speed**
  - Equipped **weapon** multipliers + **rune** bonuses
- Starts `GameLoop` (ticker), loads player/enemy/environment/pickup sprites.
- Left stick: move · Right AIM: aim / release to fire.
- HUD: HP segments, XP, stage timer, ammo/reload, pause, magnet toast, level-up cards.
- On run end → Win or Game Over (see Ads / revive below).

#### Pause overlay
- Freezes match (`isPaused`).
- Resume / Restart stage / Quit to menu (`popUntil` first route).

#### Win screen
- Shown after surviving the stage timer with HP > 0.
- Awards Embers (including win bonus) before navigation from HUD.
- Updates character best level on clear.
- Buttons:
  - **Next Level** → new HUD for `N+1` (**no interstitial**)
  - **Replay Level / Play Again** → Pre-Game Setup (**interstitial first**)
  - **Main Menu** → root (**interstitial first**)

#### Game Over screen
- Dramatic headline, counting stats, maroon glow buttons.
- **First death in a run:** HUD **pushes** this screen (HUD stays underneath) with `showReviveButton: true`.
- **Later death:** HUD **replaces** itself with Game Over (no revive).
- **Watch Ad to Revive** (rewarded TEST ad) — see [AdMob](#admob--full-implementation-detail).
- **Retry** / **Main Menu** — interstitial first, then navigate.

#### Talent Tree
- Nodes: maxhp, damage, speed, luck, warding, emberheart (Embers + prerequisites).
- Applied in match today: **maxhp / damage / speed** (others stored for UI/progression).

#### Shop
- Tabs: Characters / Weapons / Runes.
- Purchase spends Embers; equip updates `EconomyState` and persists.

#### Settings
- Toggles Music / SFX / Vibration through `AudioManager` prefs.
- Opens Privacy Policy.

---

## Gameplay systems — how combat is implemented

### Architecture

```
GameplayHudScreen (UI)
        │
        ▼
    GameLoop (Ticker ~60fps)
        ├─ PlayerController.update
        ├─ AimFireController.update
        ├─ EnemyBehavior.tickAll
        ├─ EnemySpawner.update
        ├─ MagnetSpawner.update
        ├─ CollisionService.update
        └─ GameState.tick (timer / win-lose)
```

Delta time is capped (~33ms) to avoid spiral-of-death after hitches.

### `GameState`
Owns HP, XP, level, ammo, magnet, entities, camera/world (`worldScale = 2.4`), pause / win / game-over flags, and:

| Field / method | Role |
|----------------|------|
| `reviveOfferedThisRun` | Revive offered at most once per run |
| `markReviveOffered()` | Sets flag (no notify — called mid-tick) |
| `reviveWithPartialHp(fraction: 0.5)` | Restore ~50% max HP, clear game-over, unpause |

### `GameLoop` end conditions

1. **Win** (`isWin`) → `onEnded(won: true, canRevive: false)` + Embers bonus `+40`.
2. **First death** (`isGameOver` && `!reviveOfferedThisRun`) → mark offered → `canRevive: true`.
3. **Later death** → `canRevive: false`.
4. `onEnded` is scheduled with **`SchedulerBinding.addPostFrameCallback`** so routes are not pushed mid-ticker tick.
5. `resumeAfterRevive()` clears `_endedDispatched` and restarts the ticker.

### Controls & combat

| System | Behavior |
|--------|----------|
| `PlayerController` | Arena drag-to-move; obstacle resolution; facing |
| `AimFireController` | Drag AIM, release fire; magazine (default 6); reload ~1.2s; cooldown from state |
| `CollisionService` | Projectiles vs enemies; contact damage (~0.65s); XP collect radius; magnet pull |
| Kill XP | fast 4 / ranged 7 / tank 12 |
| Kill Embers | fast 2 / ranged 3 / tank 5 |

### Enemies

| Kind | Approx HP | Role |
|------|-----------|------|
| fast | 14 | Quicker chaser |
| tank | 70 | Slow, heavy |
| ranged | 28 | Mid stats (still chase AI) |

Spawner rate rises with `hollowDepth` + elapsed time; soft cap ~19 enemies; early stages prefer spawns near the camera.

### In-run leveling (`leveling.dart`)

On level-up, match pauses for a card pick:

- **Bloodbound** — +22 max HP and heal 22  
- **Shadow Step** — moveSpeed × 1.12  
- **Ember Edge** — damage × 1.18, fire cooldown × 0.9 (floor 0.16)

### Weapons & runes

- **Weapons** (`weapon_catalog.dart`): blade, pistol, axe, staff, bow — multipliers for damage / fire rate / projectile speed / radius / aim range. Applied when HUD builds `GameState`.
- **Runes** (`rune_catalog.dart`): e.g. Vein (+max HP), Gale (+move speed). One equipped at a time.

### Magnet power-up

Spawns roughly every 20–30s; while active (~8–10s), XP orbs pull from across the map.

---

## Economy, audio, prefs, theme

### `EconomyState` (Provider)

- Seeded demo economy (Embers, starter Wanderer, blade/pistol, gale rune, some talent levels).
- Persisted JSON in `shared_preferences` under key `economy_state`.
- Tracks: embers, owned/equipped IDs, talent levels, **per-character best cleared stage**.
- Auto-saves on mutations; grants free character unlocks when Level 30 is cleared.

### `AudioManager`

- Ambient loop + SFX: fire, hit, enemy death, damage, pickup, level-up, UI taps.
- Prefs: music / sfx / vibration enabled.
- Fail-soft if an asset fails to play.
- Credits: `assets/audio/CREDITS.md` (Mixkit Free License).

### `AppFlags`

- `hasSeenOnboarding`
- `hasSeenTutorial` (first-match How to Play)

### Theme helpers

- `AppAssets` — branding, portraits, sprite path helpers  
- `FieldBackdrop` — charcoal + fog field  
- `ThemedChrome` — shared back button / icon chrome  

---

## AdMob — full implementation detail

> **Important:** This project uses **Google’s official TEST App IDs and ad unit IDs only**.  
> Do **not** use real/production AdMob IDs during development (policy risk). Swap IDs only when preparing a Play Store / App Store release.

### Dependency

```yaml
# pubspec.yaml
dependencies:
  google_mobile_ads: ^9.0.0
```

### Platform setup

#### Android — `android/app/src/main/AndroidManifest.xml`

- `INTERNET` permission
- TEST Application ID meta-data:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

#### iOS — `ios/Runner/Info.plist`

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

### `AdManager` singleton — `lib/ads/ad_manager.dart`

| Role | TEST ID |
|------|---------|
| Interstitial ad unit | `ca-app-pub-3940256099942544/1033173712` |
| Rewarded ad unit | `ca-app-pub-3940256099942544/5224354917` |

**Behavior:**

1. `init()` preloads interstitial **and** rewarded in parallel.
2. `showInterstitial()` — if no ad ready, skips and preloads; never blocks navigation forever (60s safety timeout).
3. `showRewarded()` — returns `true` **only** when `onUserEarnedReward` fires; otherwise `false`.
4. After dismiss / fail → dispose safely → **preload the next** ad.
5. All load/show paths wrapped in try/catch; failures log and continue.

### Where ads appear in UX

| Moment | Ad type | What happens |
|--------|---------|--------------|
| Game Over → **Retry** | Interstitial | Show (or skip if unload) → start stage again |
| Game Over → **Main Menu** | Interstitial | Show (or skip) → `popUntil` root |
| Win → **Replay / Play Again** | Interstitial | Show (or skip) → Pre-Game Setup |
| Win → **Main Menu** | Interstitial | Show (or skip) → root |
| Win → **Next Level** | *(none)* | Goes straight into next HUD |
| Game Over → **Watch Ad to Revive** | Rewarded | On reward → revive at **50% HP** and resume same match |

### Rewarded revive — exact flow

```
Player HP hits 0
    → GameLoop sees isGameOver
    → if !reviveOfferedThisRun:
          markReviveOffered()
          onEnded(canRevive: true)
    → GameplayHud PUSHES GameOverScreen (HUD kept alive underneath)
          showReviveButton: true
          polls AdManager.isRewardedReady (bounded retries)
    → User taps "Watch Ad to Revive"
          → AdManager.showRewarded()
          → if earned:
                reviveWithPartialHp(0.5)
                GameLoop.resumeAfterRevive()
                pop GameOver → match continues
          → if not earned:
                hide revive button (Retry / Menu still work)
    → If user leaves via Retry/Menu without revive:
          onConfirmLeave awards pending Embers, then interstitial + navigate

Second death in same run:
    → reviveOfferedThisRun == true
    → onEnded(canRevive: false)
    → pushReplacement GameOver (no revive button)
```

### Fail-soft guarantees

- Ads SDK init timeout → app still opens.
- Interstitial missing → navigation continues immediately.
- Rewarded missing → revive button stays hidden/disabled.
- Show callback dropped → 60s timeout unblocks UI.
- Double dispose guarded.

### Manual test checklist

1. Play a match and die once → **Watch Ad to Revive** appears (when rewarded loaded).
2. Watch the TEST rewarded ad (on-screen **Test Ad** label) → revive at half HP, match resumes.
3. Die again → Game Over **without** revive.
4. Tap Main Menu / Retry → TEST interstitial appears (or skips if not loaded), then navigation.
5. Win a short stage → Replay / Main Menu show interstitial; Next Level does not.

---

## How to run & build

```bash
cd HollowHour
flutter pub get
flutter run
```

### Release APK

```bash
flutter build apk --release
# smaller per-ABI:
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

> **Windows note:** If Kotlin fails with “different roots”, `android/gradle.properties` sets `kotlin.incremental=false`.

### Launcher icons

```bash
dart run flutter_launcher_icons
```

---

## Testing

```bash
flutter test
flutter analyze
```

Coverage includes widget smoke tests, game mode helpers, loadout/catalog, progression, audio smoke, and gameplay feature/visual asset checks under `test/`.

---

## Interview talking points

1. **UI → systems** — atmospheric shell → shared economy → ticker combat → stage campaign.
2. **Shared economy** — one `EconomyState` across Menu / Shop / Characters / stages with disk persistence.
3. **Gameplay architecture** — `GameLoop` + separated controllers; HUD is presentation only.
4. **Progression design** — timed stages per character; Level 30 gates the next unlock.
5. **Ads architecture** — singleton `AdManager`, TEST IDs only, fail-soft navigation, one revive per run.
6. **Audio / art hygiene** — Mixkit + pixel art credits for commercial clarity.

---

## Known limitations

1. `GameMode.quick` / `endless` exist in code but the live HUD path always uses **standard + stage duration**.
2. Talents **luck / warding / emberheart** are purchasable/persisted; match start currently applies **maxhp / damage / speed**.
3. Privacy Policy copy may still describe a pre-ads app — update before store release.
4. AdMob IDs are **TEST only** — replace with real App / unit IDs for production and update privacy disclosures.
5. Settings “Reset Progress” UI may not fully wipe economy (verify before shipping).

---

## License / credits

Private student / portfolio project unless otherwise stated.  
Fiction / entertainment demo.  

- Third-party audio: Mixkit Free License — `assets/audio/CREDITS.md`
- Pixel art: `assets/game/CREDITS.md`
- Ads: Google Mobile Ads SDK with **official Google test units** during development

---

## Ads used

- Interstitial
- Rewarded
