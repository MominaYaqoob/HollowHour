# Hollow Hour

**Hollow Hour** is a dark horror-survival mobile game built with **Flutter / Dart**.  
Atmospheric UI, a playable combat loop, character stage progression, shared economy, persistence, and audio — packaged as a portfolio-ready demo.

> **Current state:** Full player journey with **real in-match gameplay**, **character campaign levels (1–30)**, **Provider-backed economy** (Embers, gear, talents) via `shared_preferences`, pixel sprites, and **Mixkit-licensed audio**. No multiplayer or server backend.

---

## Game Concept

Pick a survivor, clear timed **stages** (Level 1 ≈ 1 minute → Level 30 = 15 minutes), unlock the next stage — and finish Level 30 to free the next character. Drag to move, aim on the right, collect XP, pick power-ups, and endure the Hollow.

| Theme | Detail |
|--------|--------|
| Genre | Dark horror-survival |
| Tone | Gothic, premium, atmospheric |
| Currency | **Embers** |
| Progression | Per-character stages 1–30 |
| Motif | Lantern, fog, charcoal + oxblood red |

### Design tokens

| Token | Value | Use |
|--------|--------|-----|
| Charcoal | `#0A0A0A` | Backgrounds |
| Maroon | `#8B1A1A` | Borders, accents, HP |
| Maroon glow | `#C41E1E` | Glow, selected states, enemy halos |
| Typography | Serif / monospace | Titles vs timers/stats |

---

## Features (Implemented)

### App flow
- **Onboarding** — first-launch welcome aligned with stage progression
- **Splash** — app icon entrance, hourglass, “Tap to Begin”
- **Main Menu** — Embers, Help (`?`), Settings, Play / Characters / Talents / Shop
- **How to Play** — stages + Move / Aim (also on first match)
- **Character Select** — carousel + **tappable level circles** (cleared / next / locked)
- **Prepare** — weapon equip + stage summary (duration) → Begin  
  *(Game Mode / Hollow Depth pickers removed — level owns time + difficulty)*
- **Gameplay** — finger-drag move, red crosshair AIM, enemies, obstacles/trees, ammo/reload, magnet XP pull, level-up power-ups, pause
- **Win** — **Level Cleared** + **Next Level** / Replay / Main Menu
- **Game Over** — retry same stage or menu
- **Talent Tree** / **Shop** / **Settings** — persisted economy + audio toggles

### Campaign levels
- Owned character starts at **Level 1**
- Clear stage N → unlock **N+1**
- Clear **Level 30** → free-unlock next character (Wanderer → Huntress → Scholar → Brute → Ghost)
- Duration scales **~1:00 → 15:00** across levels 1–30
- Spawn pressure scales with stage level

### Gameplay systems (`lib/game/`)
- `GameState` — HP, XP, stage timer, world/camera, obstacles
- `game_mode.dart` — `stageDurationForLevel` / `stageDepthForLevel`
- `PlayerController` — arena drag-to-move
- `AimFireController` — drag aim / release fire + range glow
- `Enemy` + `EnemySpawner` — fast / tank / ranged; early stages spawn near camera
- `CollisionService` / `Leveling` / `GameLoop` / magnet pickup

### Economy & state
- **Provider** `EconomyState` — Embers, owned/equipped IDs, talents, **per-character cleared level**
- Persisted JSON in `shared_preferences` (auto-save)

### Audio (`lib/audio/`)
- Ambient music + SFX (fire, hit, death, damage, pickup, level-up, UI)
- Mixkit Free License — see `assets/audio/CREDITS.md`

### Art
- Distinct top-down sprites per character + enemy kinds
- Environment trees/rocks/bushes + XP/magnet pickups
- Credits: `assets/game/CREDITS.md`

---

## Tech Stack

| Layer | Choice |
|--------|--------|
| Framework | Flutter |
| Language | Dart (SDK `^3.12.1`) |
| State | **Provider** |
| Navigation | `Navigator` + fade / fog routes |
| Storage | `shared_preferences` |
| Audio | `audioplayers` |
| Platforms | Android, iOS, Web |
| Lint / Tests | `flutter_lints` + unit tests |

---

## Project Structure

```
lib/
  main.dart
  audio/          # Music + SFX
  state/          # EconomyState (embers, unlocks, stage progress)
  prefs/          # Onboarding / tutorial flags
  game/           # Match loop, spawners, stage helpers
  theme/          # AppAssets, FieldBackdrop, chrome
  screens/        # UI + overlays
assets/
  branding/  bg/  icons/  characters/  audio/  game/
android/  ios/  web/  test/
```

---

## Navigation Map

```
Onboarding (first launch)
    ↓
Splash → Main Menu
            ├─ Play / Characters
            │     → pick Level N → Prepare → HUD (stage timer)
            │           ├─ Win → Next Level / Replay
            │           └─ Game Over → Retry stage
            ├─ Talents / Shop / Settings
            └─ How to Play
```

---

## How to Run

```bash
cd HollowHour
flutter pub get
flutter run
```

### Release APK
```bash
flutter build apk --release
# or smaller:
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

> **Note (Windows):** If Kotlin fails with “different roots”, `android/gradle.properties` sets `kotlin.incremental=false`.

---

## Interview Talking Points

1. **UI → systems** — atmospheric shell → economy → combat → **stage campaign**.
2. **Shared economy** — one `EconomyState` across Menu / Shop / Characters / stages.
3. **Gameplay architecture** — ticker loop, separated controllers, HUD as presentation.
4. **Progression design** — timed stages per character; Level 30 gates the next unlock.
5. **Audio / art hygiene** — Mixkit + Anokolisa credits for commercial clarity.
6. **Scope honesty** — weapons equip/shop today; distinct combat per weapon still future work.

---

## Version

- App version: **1.0.0**
- Package: `hollow_hour`
- Repo: [MominaYaqoob/HollowHour](https://github.com/MominaYaqoob/HollowHour)

---

## License / Status

Private student / portfolio project unless otherwise stated.  
Fiction / entertainment demo.  
Third-party audio: Mixkit Free License — `assets/audio/CREDITS.md`.  
Pixel art: see `assets/game/CREDITS.md`.
