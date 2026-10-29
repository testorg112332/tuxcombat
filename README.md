# 🐧 Tux Combat

<p align="center">
  <img src="sources/tuxcombat-logo.svg" alt="Tux Combat — Open-Source Fighting Arena" width="800">
</p>

Tux Combat is a small Godot 2D mascot fighting-game prototype built around Linux, Unix, BSD, and open-source culture.

## Current prototype

- 🥊 4 selectable Unix/Linux/BSD-inspired fighters
- 🎮 Character selection screen with mouse + keyboard navigation
- ⚔️ Selected fighter goes directly into the match
- 🤖 CPU opponent selected automatically
- 🥊 Punch and kick attacks
- 🦘 Jumping, crouching, and side-to-side movement
- ❤️ Health bars
- 🔄 Best-of-3 round system
- 🎮 Basic gamepad support
- 🎨 Procedural fighter artwork
- 🖥️ 1280×720 PC presentation

## Fighters

| Fighter | Theme | Current role |
|---|---|---|
| Tux | Linux penguin | Balanced |
| GNU | GNU project wildebeest | Heavy |
| Beastie | BSD daemon | Aggressive |
| Puffy | OpenBSD pufferfish | Quick |

These are simplified procedural interpretations for the prototype. Any public release should document applicable rights, permissions, trademarks, and licenses for mascot artwork and names.

## Controls

### Character select

| Action | Keyboard / Mouse |
|---|---|
| Previous / next | Left / Right |
| Select | Enter or click a fighter |

### Player 1

| Action | Keyboard |
|---|---|
| Move | A / D |
| Jump | W |
| Crouch | S |
| Punch | J |
| Kick | K |

A compatible gamepad can also control Player 1 with the left stick, A for punch, B for kick, and Y for jump.

## Run it

1. Install Godot 4.x.
2. Clone this repository.
3. Open the repository as a Godot project.
4. Press Play Project.
5. Pick a fighter.
6. Fight the CPU.

## Development stack

- Godot 4.x — game engine and 2D renderer
- GDScript — gameplay code
- Git + GitHub — source control and collaboration
- Optional later tools: Aseprite/Krita for original art, Audacity/LMMS for original audio, and GitHub Actions for automated builds.

## Roadmap

### Phase 1 — Playable prototype
- [x] Basic arena
- [x] Fighter
- [x] Movement
- [x] Jump
- [x] Crouch
- [x] Punch
- [x] Kick
- [x] Health
- [x] Rounds
- [x] CPU opponent
- [x] Gamepad input

### Phase 2 — Character system
- [x] Character selection screen
- [x] Multiple Unix/Linux/BSD-inspired fighters
- [x] Selected character enters the match
- [ ] Proper sprite sheets
- [ ] Idle/walk/jump/crouch/attack animations
- [ ] Hit and hurt boxes
- [ ] Better CPU behavior
- [ ] Character-specific moves

### Phase 3 — Full game
- [ ] Title screen
- [ ] Pause menu
- [ ] Sound effects
- [ ] Original music
- [ ] Multiple arenas
- [ ] Local 2-player mode
- [ ] Training mode
- [ ] Arcade mode
- [ ] Settings
- [ ] Controller remapping
- [ ] Accessibility options

### Phase 4 — Releases
- [x] Windows build
- [x] Linux x86_64 build
- [x] GitHub Releases
- [x] Automated builds
- [ ] Optional itch.io release
- [ ] Evaluate Steam release later

## Character and asset licensing

Mascots, logos, names, artwork, fonts, sounds, and other third-party material can have separate rights and licenses. This project does not assume that something is free to redistribute just because it is associated with Linux or open source.

For new fighters and assets, prefer original project artwork, public-domain/CC0 assets, or clearly licensed material whose terms allow the intended distribution. Record attribution and license information in the repository.

See CHARACTERS.md for project notes.

## License

The original Tux Combat material is covered by the custom project license in LICENSE.

Third-party names, characters, artwork, trademarks, fonts, sounds, and other assets remain subject to their own rights and licenses.

## Status

🚧 Early prototype — expect placeholder visuals and rapid changes.

Built as a GitHub-first game project. 🐧💻
