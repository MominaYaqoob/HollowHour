# Hollow Hour

**Hollow Hour** is a dark horror-survival mobile game **UI mockup** built with **Flutter / Dart**.  
It focuses on atmospheric screens, navigation flow, animations, and game-ready UI — not a full combat backend yet.

> **Current state:** Complete click-through UI shell (splash → menu → characters → prepare → HUD → pause / level-up → win / game over → shop / talents / settings). Local mock data + light preferences only. No real gameplay engine, multiplayer, or server.

---

## Game Concept

Survive a timed **Hollow Hour** in fog-covered desolation. Embers keep the dark at bay. Choose a survivor, equip a weapon, set difficulty (**Hollow Depth**), and endure until dawn — or fall to the Hollow.

| Theme | Detail |
|--------|--------|
| Genre | Dark horror-survival (UI prototype) |
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
- **Onboarding** — first-launch welcome + disclaimer (flag in `shared_preferences`)
- **Splash** — app icon entrance, hourglass, “Tap to Begin”
- **Main Menu** — Embers balance, Help (`?`), Settings, Play / Characters / Talents / Shop + button animations
- **How to Play** — Move / Aim overlay (also shown on first match)
- **Character Select** — carousel: Wanderer, Huntress, Scholar, Brute, Ghost (locked + Ember costs)
- **Prepare** — character preview, weapon chips, game mode (Standard / Quick / Endless), Hollow Depth slider → Begin
- **Gameplay HUD** — vitality bar, timer, joystick + AIM, pickup toast, damage vignette, demo actions
- **Pause** — resume / restart / quit to menu
- **Level Up** — upgrade cards (Bloodbound, Shadow Step, Ember Edge)
- **Game Over / Win** — results headlines, counted stats, CTAs
- **Talent Tree** — permanent upgrades (Max HP, Damage, Speed, Luck, Warding, Emberheart)
- **Shop** — tabs: Characters / Weapons / Runes — purchase & equip (local `setState`)
- **Settings** — SFX / Music / Vibration toggles, Reset Progress dialog, About

### UX / polish
- Immersive sticky system UI
- Fade page transitions
- Fog / field backdrop layers + custom fog blobs
- Idle glow / press / stagger animations on main menu
- Centralized asset paths (`AppAssets`)
- Asset `errorBuilder` so missing art does not show Flutter error text

### Persistence (light)
- `shared_preferences` for:
  - `hasSeenOnboarding`
  - `hasSeenTutorial`

### Not implemented yet (honest scope)
- Real combat / enemy AI / physics
- Save of purchases, talents, or Ember balance across restarts
- Backend / auth / leaderboards
- Audio / haptics wiring beyond UI toggles

---

## Tech Stack

| Layer | Choice |
|--------|--------|
| Framework | Flutter |
| Language | Dart (SDK `^3.12.1`) |
| UI | Flutter Material (`MaterialApp`, custom widgets) |
| State | Local `StatefulWidget` + `setState` (no Provider/Bloc/Riverpod yet) |
| Navigation | `Navigator` + `PageRouteBuilder` (fade) |
| Storage | `shared_preferences` |
| Assets | PNG branding, field/fog BG, icons, character portraits |
| Platforms | Android, iOS, Web (demo) |
| Lint | `flutter_lints` |
| Tests | Widget tests (`test/widget_test.dart`) |

### Key dependencies
- `flutter` / `cupertino_icons`
- `shared_preferences`

---

## Project Structure

```
lib/
  main.dart                 # App entry, immersive UI, RootGate (onboarding vs splash)
  prefs/app_flags.dart      # Preference helpers
  theme/
    app_assets.dart         # Asset path constants
    field_backdrop.dart     # Shared field + fog backdrop
  screens/
    onboarding_screen.dart
    splash_screen.dart
    main_menu_screen.dart
    how_to_play_overlay.dart
    character_select_screen.dart
    pre_game_setup_screen.dart
    gameplay_hud_screen.dart
    pause_overlay.dart
    game_over_screen.dart
    win_screen.dart
    talent_tree_screen.dart
    shop_screen.dart
    settings_screen.dart
assets/
  branding/  bg/  icons/  characters/
android/  ios/  web/  test/
```

---

## Navigation Map

```
Onboarding (first launch only)
    ↓
Splash → Main Menu
            ├─ Play → Prepare → HUD
            │              ├─ Pause
            │              ├─ Level Up (demo)
            │              ├─ Game Over (demo)
            │              └─ Win (demo)
            ├─ Characters → Prepare → HUD
            ├─ Talents
            ├─ Shop
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

Use these in interviews / viva / portfolio reviews:

1. **UI-first product thinking** — shipped a full player journey before gameplay backend; useful for design validation and demos.
2. **Flutter architecture** — screen-based modules, shared theme/backdrop, centralized assets, thin prefs layer.
3. **State management choice** — intentional `setState` for a UI mock; clear migration path to Provider/Riverpod/Bloc when economy + combat need global state.
4. **Navigation UX** — custom fade routes, overlays (pause / how-to-play / level-up) without losing HUD context.
5. **Animation** — `AnimationController`, stagger entry, idle glow, press feedback; `TickerProviderStateMixin` when multiple controllers share a State.
6. **Local persistence** — first-run onboarding/tutorial flags via `shared_preferences` + `FutureBuilder` gate in `main.dart`.
7. **Asset pipeline** — branded art, character locked/unlocked portraits, defensive `errorBuilder` for missing assets.
8. **Platform build** — Android release APK, Gradle/Kotlin Windows path issues understood and mitigated.
9. **Scope honesty** — can clearly separate UI shell vs real game systems (combat, economy persistence, audio).
10. **Next steps you can pitch** — Ember economy persistence, equip sync between Shop ↔ Prepare, real timer/HP logic, audio manager, clean architecture / feature folders.

### Sample Q&A (short)

| Question | Strong answer |
|----------|----------------|
| Why Flutter? | Single codebase, fast UI iteration, strong animation APIs for atmospheric games. |
| Why no Bloc yet? | Mock uses local screen state; adding Bloc early would over-engineer before domain rules exist. |
| How did you handle first launch? | Prefs flag + `_RootGate` `FutureBuilder` routes to Onboarding or Splash. |
| What’s reusable? | `FieldBackdrop`, `AppAssets`, overlay pattern, menu button animation pattern. |
| Biggest limitation? | HUD demos mutate UI only — no combat sim or durable economy. |

---

## Version

- App version: **1.0.0**
- Package: `hollow_hour`

---

## License / Status

Private student / portfolio project unless otherwise stated.  
UI presentation build — fiction / entertainment demo.
