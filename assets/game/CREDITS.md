# Game pixel-art credits — Hollow Hour

Assets under `assets/game/` are free for use in commercial games (including Play Store)
per each author’s terms. **Do not resell the raw art packs as asset packs.**

---

## Downloaded & shipped in this repo

### Anokolisa — Pixel Crawler Free Pack (primary source)

| Field | Detail |
|--------|--------|
| Title | Free - Pixel Art Asset Pack - Topdown Tileset - 16x16 Sprites |
| Author | Anokolisa |
| Page | https://anokolisa.itch.io/free-pixel-art-asset-pack-topdown-tileset-rpg-16x16-sprites |
| File | `Pixel Crawler - Free Pack 2.11.zip` (itch upload id `18272589`) |
| License | Author **Terms.txt**: free for commercial / study projects; credit appreciated but **not required**; may alter art; **may not** resell assets as a final art product |
| Contact | AnomalyPixel@gmail.com · https://www.patreon.com/Anokolisa |

**Mapped into this project:**

| Project path | Source within pack |
|--------------|--------------------|
| `player/wanderer_*` | `Entities/NPC's/Rogue` Idle + Run (hooded adventurer) |
| `player/huntress_*` | `Entities/NPC's/Citizen_F/Peasant_A` Idle + Walk |
| `player/scholar_*` | `Entities/NPC's/Wizzard` Idle + Run |
| `player/brute_*` | `Entities/NPC's/Knight` Idle + Run |
| `player/ghost_*` | Rogue Idle + Run with pale ghost palette recolor |
| (side/up sheets) | Same strip reused per facing; painter flips for left |
| `enemies/fast/{idle,walk}.png` | `Entities/Mobs/Orc Crew/Orc - Rogue` Idle / Run sheets |
| `enemies/tank/{idle,walk}.png` | `Entities/Mobs/Orc Crew/Orc - Warrior` Idle / Run sheets |
| `enemies/ranged/{idle,walk}.png` | `Entities/Mobs/Skeleton Crew/Skeleton - Mage` Idle / Run sheets |
| `environment/bush_dead.png`, `bush_autumn.png`, `rock_01.png`, `rock_02.png` | Crops from `Environment/Props/Static/*` |
| `environment/tree_01.png`, `tree_dead.png` | Crops from vegetation tall-tree row (autumn / olive) |
| `environment/tree_gothic_a.png`, `tree_gothic_b.png` | Generated dark twisted-trunk trees (muted blue-grey canopy) for 20MTD-like foggy arenas |
| `pickups/xp_orb.png` | Crop from `Environment/Props/Static/Resources.png` (gold collectible tile) |
| `pickups/magnet.png` | Crop from `Environment/Props/Static/Tools.png` (circular metal blade — magnet / attractor icon stand-in) |

A copy of the author’s terms is at `assets/game/SOURCE_Terms_Anokolisa.txt`.

---

## Manual download candidates (itch.io blocked / no upload id via curl)

These pages match the brief but **did not yield a terminal-downloadable zip** in this session
(itch anti-bot / missing `data-upload_id` in HTML). Download in a browser, then drop files
into the folders below.

### 1) Free Enemy Pixel Pack for Top-Down Game

| Field | Detail |
|--------|--------|
| Author | Free Game Assets (GUI, Sprite, Tilesets) |
| itch.io | https://free-game-assets.itch.io/free-enemy-pixel-pack-for-top-down-defense |
| CraftPix mirror | https://craftpix.net/freebies/free-enemy-pixel-pack-for-top-down-defense/ |
| Zip (on page) | `Free-Enemy-Pixel-Pack-for-Top-Down-Defense.zip` (~936 kB) |
| License | CraftPix freebie royalty-free commercial use — verify [CraftPix license](https://craftpix.net/file-licenses/) before ship |
| Suggested fold-in | Extra / alternate sprites under `enemies/` (rat / sorcerer / robber) |

### 2) itch.io “Free Pixel Sprites \| Top-down” style CC0 packs

| Pack | URL | License | Notes |
|------|-----|---------|--------|
| FreeRPG pixel project (OLTEANU) | https://ochiogrande.itch.io/free-rpg-pixel-project-by-olteanu | **CC0** | Player + enemy sprites |
| CHROME DISTRICT (booliebuilds) | https://booliebuilds.itch.io/chrome-district | **CC0** | 20 top-down walk cycles (cyber palette — optional) |
| MetroCity Free Top Down Character Pack | https://jik-a-4.itch.io/metrocity-free-topdown-character-pack | Free (check page) | Extra character variety |
| Bit Bonanza (VEXED) | https://v3x3d.itch.io/bit-bonanza | **CC0** | Tiny top-down props / entities |
| CC0 Top-Down filter | https://itch.io/game-assets/assets-cc0/tag-top-down | CC0 | Browse more |

### 3) Collection link

- itch.io Free Pixel Sprites / Top-down browsing: start from  
  https://itch.io/game-assets/free/tag-top-down  
  and prefer pages marked **CC0** or explicit “free for commercial use”.

---

## Style note (20 Minutes Till Dawn tone)

Anokolisa Pixel Crawler **kept** — small chibi proportions and muted player Body_A already match the reference tone. Enemy/environment sheets are grade-muted at paint time (desaturation matrices in `_ArenaPainter`) rather than replaced with a new itch pack.

## Gaps

| Requested | Status |
|-----------|--------|
| 5 distinct character sprite sets | **Partial** — one Anokolisa Body_A set reused for all five IDs (allowed by task). Manual CC0 packs above can diversify later. |
| 3 enemy move sets | **Done** (rogue orc / warrior orc / skeleton mage) |
| Environment trees/obstacles | **Done** (gothic/tall trees + bush crops + rocks) |
| XP orb | **Done** (`pickups/xp_orb.png`) |
| Magnet power-up icon | **Done** (`pickups/magnet.png`) |
| Free Enemy Pixel Pack (named) | **Not auto-downloaded** — see manual candidate #1 |

---

## Play Store note

Anokolisa free pack terms allow commercial game use and do not require attribution.  
CraftPix / other freebies: re-check their license page at ship time. Prefer **CC0** packs from the manual list when adding more characters.
