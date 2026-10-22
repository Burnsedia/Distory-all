# Sector Defense
Sector Defense is an open-source hybrid tower defense / space combat game set in a decaying Dyson swarm. The objective of the game is to defend your sector's core from waves of enemy attacks — by flying your fighter into the swarm and building defense stations from the salvage you earn. The game is being developed with the goal of providing a fun and engaging experience for players. We plan to release it on Steam Deck and also sell binaries.

Built with [Godot 4](https://godotengine.org/).

# Project Goals
- Create an engaging and fun open-source game for players to enjoy.
- Release the game on Steam Deck and sell binaries to expand our audience.
- Continuously improve and refine the game mechanics based on player feedback.

# Current Status
**Playable vertical slice.** Fly, fight waves, earn minerals, build gun and missile
stations, defend the Sector Core, and destroy all 10 enemy shipyards to win.
See [docs/GDD.md](docs/GDD.md) for the full design document and roadmap.

# How to Play
- **Fly** — `W`/`S` pitch + throttle, `A`/`D` yaw, `Q`/`E` roll, `Shift` boost, `Space` fire.
- **Build** — `B` opens the build menu, `1`/`2` selects gun/missile station,
  fly near the core until the ghost turns green, `Enter` places it, `Esc` cancels.
- **Pause** — `Esc`. **Retry after defeat** — `R`.
- Gamepad (Steam Deck) bindings are included: `A`/`B` throttle, right stick yaw,
  `RB` fire, `View` build menu, `X`/`Y` select station, `Start` pause.

# How to Run
1. Download [Godot 4.x](https://godotengine.org/download) (4.2+).
2. Open the project in Godot and press **F5**, or run headless:
   `godot --path . --fixed-fps 60`

# How to Test
- Unit tests (damage system): `godot --headless --path . res://test/unit_runner.tscn`
- Smoke test (full gameplay arc): `godot --headless --path . res://test/smoke_launcher.tscn`

# How to Contribute
We welcome contributions from anyone who wants to help make Sector Defense a better game. If you're interested in contributing, please read our contribution guidelines and get in touch with us via our GitHub repository or email.

# License
Sector Defense is licensed under the GNU Affero General Public License v3.0 (AGPL). You are free to use, modify, and distribute the game as long as you comply with the terms of the license.

---

**GNU Affero General Public License (AGPL)**

Copyright (c) 2023 Bailey Burnsed. All rights reserved.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License or (at your option) any later version.

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of **MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.** See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

# Support Us on Patreon and GitHub Sponsors
If you enjoy playing Sector Defense and want to help us continue developing it, please consider supporting us on Patreon or GitHub Sponsors. By becoming a patron or sponsor, you'll get access to exclusive updates, behind-the-scenes content, and the ability to vote on future features and updates.

Your support will help cover development costs, including software, server hosting, and equipment. It will also enable us to dedicate more time and resources to making the game even better for players.

- Support us on [Patreon](https://www.patreon.com/RetroFOSS)
- Support us on [GitHub Sponsors](https://github.com/sponsors/Burnsedia/)
