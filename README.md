# Gone — Godot 3 Endless Runner

Neon stickman endless runner built with Godot 3.6 (GDScript). Dark sci-fi grid background, jump/double-jump/slide, coins, score persistence.

## Controls

| Action | Key / Touch |
|--------|------------|
| Jump | Space / Up arrow / Tap |
| Double jump | Tap again in air |
| Slide | Down / S / Swipe down |

## How to play locally (Godot 3.6)

1. Download [Godot 3.6 Standard](https://godotengine.org/download/3.x/) (no Mono needed)
2. Open `project.godot` in the editor
3. Press F5 to run

## APK Build (GitHub Actions)

Every push to `main` triggers the build workflow automatically.

1. Go to **Actions → Build Godot Android APK**
2. Wait ~10-15 minutes
3. Download `gone-apk-N` from the Artifacts section

No Unity license, no PC required — pure Godot + GitHub Actions.

## Game design

- **Neon blue stickman** drawn with GDScript `_draw()` — procedural, no sprites needed
- **Procedural sine-wave running animation** with heel-kick on back leg
- **3 obstacle types**: short (jump over), tall (jump over), hanging (slide under)
- **Coins** in rows, collected on contact — pulsing gold glow
- **Parallax grid background** — perspective-lined, scrolling stars
- **Speed ramps up** over time; spawn interval shrinks
- **Persistent best score** saved to `user://save.cfg`
