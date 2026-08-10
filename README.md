# Hollow Hour

**Hollow Hour** is a dark horror-survival mobile game built with **Flutter / Dart**.  
Atmospheric UI, a playable survival loop, shared economy state, persistence, and audio — packaged as a portfolio-ready demo.

> **Current state:** Full player journey with **real in-match gameplay** (move, aim-fire, enemies, XP/level-ups, win/lose), **Provider-backed economy** (Embers, owned/equipped gear, talents) persisted via `shared_preferences`, and **Mixkit-licensed audio** (ambient music + SFX). No multiplayer or server backend.

---

## Game Concept

Survive a timed **Hollow Hour** in fog-covered desolation. Embers keep the dark at bay. Choose a survivor, equip a weapon, set difficulty (**Hollow Depth**), and endure until dawn — or fall to the Hollow.

| Theme | Detail |
|--------|--------|
| Genre | Dark horror-survival |
| Tone | Gothic, premium, atmospheric |
| Currency | **Embers** |
| Motif | Lantern, fog, charcoal + oxblood red |

### Design tokens

| Token | Value | Use |
|--------|--------|-----|
| Charcoal | `#0A0A0A` | Backgrounds |
| Maroon | `#8B1A1A` | Borders, accents, HP |
| Maroon glow | `#C41E1E` | Glow, selected states |
| Typography | Serif / monospace | Titles vs timers/stats |

---

## Features (Implemented)

### App flow
- **Onboarding** — first-launch welcome + disclaimer (`shared_preferences`)
- **Splash** — app icon entrance, hourglass, “Tap to Begin”
- **Main Menu** — live Embers balance, Help (`?`), Settings, Play / Characters / Talents / Shop
- **How to Play** — Move / Aim overlay (also on first match)
- **Character Select** — carousel unlocks from `EconomyState` (Wanderer, Huntress, Scholar, Brute, Ghost)
- **Prepare** — equipped character/weapon from economy, game mode, Hollow Depth → Begin
- **Gameplay** — joystick move, AIM drag-to-aim / release-to-fire, enemy spawns, collisions, XP orbs, level-up cards with real stat buffs, pause, win at 20:00 or game over on death
- **Game Over / Win** — real run stats (kills, time, embers earned) + economy payout
- **Talent Tree** — permanent upgrades persisted (Max HP, Damage, Speed, Luck, Warding, Emberheart)
- **Shop** — Characters / Weapons / Runes — purchase & equip against shared economy
- **Settings** — SFX / Music toggles (persisted), Vibration, Reset Progress dialog, About

### Gameplay systems (`lib/game/`)
- `GameState` — HP, XP, timer, kills, pause/win/lose
- `PlayerController` / `AimFireController` — stick + 20MTD-style manual aim
- `Enemy` + `EnemySpawner` — fast / tank / ranged; spawn rate scales with time + Hollow Depth
- `CollisionService` — projectiles, contact damage (i-frames), XP pickup
- `Leveling` — Bloodbound (+max HP), Shadow Step (+move speed), Ember Edge (+damage / fire rate)
- `GameLoop` — ticker ~60fps orchestration → results screens

### Economy & state
- **Provider** `EconomyState` — single source of truth for Embers, owned/equipped IDs, talent levels
- **Persistence** — `economy_state` JSON in `shared_preferences` (auto-save on every mutation)
- Loaded in `_RootGate` before Onboarding/Splash (brief charcoal spinner)

### Audio (`lib/audio/`)
- Looping ambient music from Main Menu through gameplay
- SFX: fire, hit, death, damage, pickup, level-up, UI tap, purchase/confirm
- Music pauses on Pause / tutorial / level-up; Settings Music toggle stops playback
- Assets under `assets/audio/` — Mixkit Free License (see `assets/audio/CREDITS.md`)

### UX / polish
- Immersive sticky system UI, fade transitions, fog/field backdrops
- Shared chrome (`ThemedBackButton`, `EmberBalanceChip`, `AppAssets`)
- Asset `errorBuilder` so missing art does not crash the UI
- Audio failures fail silently (debug log only)

---

## Tech Stack

| Layer | Choice |
|--------|--------|
| Framework | Flutter |
| Language | Dart (SDK `^3.12.1`) |
| UI | Flutter Material + custom themed widgets |
| State | **Provider** (`ChangeNotifier` / `EconomyState`, match `GameState`) |
| Navigation | `Navigator` + `PageRouteBuilder` (fade / fog enter) |
| Storage | `shared_preferences` |
| Audio | `audioplayers` |
| Assets | PNG branding/BG/icons/portraits + MP3 audio |
| Platforms | Android, iOS, Web |
| Lint | `flutter_lints` |
| Tests | Widget + audio smoke tests |

### Key dependencies
- `provider`
- `shared_preferences`
- `audioplayers`

---

## Project Structure

```
lib/
  main.dart                 # Entry, Provider, RootGate (load economy + onboarding)
  audio/audio_manager.dart  # Music + SFX singleton (audio_* prefs)
  state/economy_state.dart  # Embers, owned/equipped, talents + disk I/O
  prefs/app_flags.dart      # Onboarding / tutorial flags
  game/                     # Match loop (state, player, aim, enemies, collisions, leveling)
  theme/                    # AppAssets, FieldBackdrop, themed chrome
  screens/                  # All UI screens + overlays
assets/
  branding/  bg/  icons/  characters/  audio/
android/  ios/  web/  test/
```

---

## Navigation Map

```
Onboarding (first launch only)
    ↓
Splash → Main Menu  (ambient music starts)
            ├─ Play → Prepare → HUD (live combat loop)
            │              ├─ Pause (music pauses)
            │              ├─ Level Up (real stat picks)
            │              ├─ Game Over → embers saved
            │              └─ Win → embers saved
            ├─ Characters → Prepare → HUD
            ├─ Talents    (persisted upgrades)
            ├─ Shop       (persisted purchases)
            └─ Settings / How to Play
```

---

## How to Run

```bash
cd HollowHour
flutter pub get
flutter run
```

### Android
```bash
flutter devices
flutter run -d android
```

### Release APK
```bash
flutter build apk --release
```

Smaller APK (per ABI):
```bash
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

> **Note (Windows):** If Kotlin fails with “different roots” (project on `D:`, pub-cache on `C:`), `android/gradle.properties` already sets `kotlin.incremental=false`.

---

## Interview Talking Points

1. **UI → systems path** — started as atmospheric shell, then layered Provider economy, persistence, combat loop, and audio without rewriting navigation.
2. **Shared economy** — `EconomyState` as single source of truth across Menu / Shop / Characters / Prepare / Talents; auto-persist after mutations.
3. **Gameplay architecture** — ticker-driven loop, separated controllers (move / aim / spawn / collision), HUD stays a presentation layer.
4. **Balance knobs** — spawn interval vs Hollow Depth + elapsed time; documented base stats for tuning.
5. **Audio production** — Mixkit royalty-free assets with `CREDITS.md` for Play Store licensing hygiene; silent failure on missing files.
6. **Flutter craft** — custom routes, overlays, `AnimationController` polish, immersive system UI.
7. **Scope honesty** — circle placeholders for entities (no portrait combat art yet); no multiplayer/backend.

### Sample Q&A

| Question | Strong answer |
|----------|----------------|
| Why Provider? | Lightweight shared mutable state for economy + match; enough before introducing Bloc/Riverpod. |
| How does progress survive restarts? | JSON blob under `economy_state` + `audio_*` / onboarding keys; loaded in `_RootGate` before UI. |
| How does combat work? | Manual AIM (drag direction, release fire), chase enemies, circle collisions, XP → level-up pause → resume. |
| What’s next? | Character art in-arena, haptics, Quick/Endless modes, stronger enemy ranged AI. |

---

## Version

- App version: **1.0.0**
- Package: `hollow_hour`
- Repo: [MominaYaqoob/HollowHour](https://github.com/MominaYaqoob/HollowHour)

---

## License / Status

Private student / portfolio project unless otherwise stated.  
Fiction / entertainment demo.  
Third-party audio: Mixkit Free License — see `assets/audio/CREDITS.md`.
