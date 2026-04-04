# Anthill engine (Luanti fork)

This directory contains a **unified patch** (`patches/0001-anthill-engine.patch`) applied on top of [Luanti](https://www.luanti.org/) **5.10.0** source. It is **not** a full VCS fork: the canonical upstream remains `luanti-org/luanti`; we track it with a pinned tag and a small patch set.

## What the patch changes

- **Display name** `PROJECT_NAME_CAPITALIZED` → **Anthill** (window title, in-game branding strings that use `PROJECT_NAME_C`, etc.). The CMake project name stays `luanti` so install paths remain `share/luanti` and compatibility is preserved.
- **Client binary** output name → **`anthill`** (server → **`anthillserver`** if you enable `BUILD_SERVER`).
- **`builtin/mainmenu/dlg_create_world.lua`**: same “single mapgen → hide dropdown” behavior as `luanti_menu_patch/` in the repo (the patch embeds it so a stock clone + `git apply` is enough).

## Build dependencies (Debian / Ubuntu)

Install Luanti’s build dependencies, for example:

```bash
sudo apt install build-essential cmake git libgmp-dev libpng-dev \
  libjpeg-dev libxi-dev libgl1-mesa-dev libsqlite3-dev libogg-dev \
  libvorbis-dev libopenal-dev libcurl4-openssl-dev libfreetype6-dev \
  libjsoncpp-dev libzstd-dev liblzma-dev
```

(Adjust for your distro; see upstream `doc/compiling/*.md` and **`docs/building-from-source.md`**.)

## Build and install

From the **repository root**:

```bash
./engine/build.sh
```

Defaults:

- Source clone: `third_party/luanti-src/` (created on first run; **gitignored**).
- Install prefix: `$HOME/.local` (override with `ANTHILL_INSTALL_PREFIX=/usr/local`).
- Tag: `5.10.0` (override with `LUANTI_TAG=...`).

`build.sh` copies **`CMakeUserPresets-anthill.json`** to **`third_party/luanti-src/CMakeUserPresets.json`** (CMake loads presets from the **Luanti source** directory, not the Anthill repo root). It then runs the **`anthill-engine`** configure/build preset when `cmake --list-presets` shows it; otherwise it uses a manual `cmake` invocation. Install uses **`cmake --install ../../engine/out/build`** from the preset layout.

Manual steps (after clone + patch + copy of the user presets file):

```bash
export ANTHILL_INSTALL_PREFIX="$HOME/.local"
cp engine/CMakeUserPresets-anthill.json third_party/luanti-src/CMakeUserPresets.json
cd third_party/luanti-src
cmake --preset anthill-engine
cmake --build --preset anthill-engine
cmake --install ../../engine/out/build
```

The **`anthill`** executable is installed to `$PREFIX/bin/anthill`. The script also symlinks **`anthill_game`** into `$PREFIX/share/luanti/games/` and appends **`~/.local/bin`** to **`~/.bashrc`** once if needed for `PATH`.

## Register the Anthill subgame

The engine still looks for games under `$PREFIX/share/luanti/games/`:

```bash
ln -sfn /path/to/anthill/anthill_game ~/.local/share/luanti/games/anthill_game
```

## Upgrading Luanti

Bump `LUANTI_TAG` in `build.sh` (or your environment), delete `third_party/luanti-src`, refresh `0001-anthill-engine.patch` against the new tree if upstream touched the same files, then rebuild.
