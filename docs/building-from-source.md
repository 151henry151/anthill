# Building Anthill from source

End users will eventually get a **prebuilt binary**; this document is for **developers** who build the patched Luanti client (`anthill`) and the `anthill_game` subgame from this repository.

## What gets built

- **Engine**: [Luanti](https://www.luanti.org/) 5.10.0, cloned into `third_party/luanti-src/` (gitignored), with `engine/patches/0001-anthill-engine.patch` applied. The install produces the **`anthill`** binary (and related data under the install prefix).
- **Subgame**: `anthill_game/` in this repo is symlinked into `$PREFIX/share/luanti/games/` by `engine/build.sh`.

## Prerequisites

- **CMake** 3.22 or newer (presets; 3.22+ matches `engine/CMakeUserPresets-anthill.json`).
- A C++ toolchain (`build-essential` on Debian).
- **Luanti build dependencies** for your OS. On Debian / Ubuntu, install packages such as:

```bash
sudo apt install build-essential cmake git libgmp-dev libpng-dev \
  libjpeg-dev libxi-dev libgl1-mesa-dev libsqlite3-dev libogg-dev \
  libvorbis-dev libopenal-dev libcurl4-openssl-dev libfreetype6-dev \
  libjsoncpp-dev libzstd-dev liblzma-dev
```

Adjust for other distributions; upstream references include `doc/compiling/linux.md` in the Luanti tree after clone.

Common configure failures:

- **Could NOT find JPEG** — install `libjpeg-dev` (or your distro’s equivalent).
- **Missing OpenGL / X11** — install `libgl1-mesa-dev`, `libxi-dev`, etc.

## Build and install (recommended)

From the **repository root**:

```bash
./engine/build.sh
```

This clones or refreshes Luanti, applies the patch, copies `engine/CMakeUserPresets-anthill.json` to `third_party/luanti-src/CMakeUserPresets.json`, configures with the **`anthill-engine`** preset when CMake supports it, builds, installs to `$HOME/.local` by default (`ANTHILL_INSTALL_PREFIX` overrides), links `anthill_game`, and may append `~/.local/bin` to `~/.bashrc` once.

Then ensure `~/.local/bin` is on your `PATH` and run:

```bash
anthill
```

## Manual CMake (same as the script)

After `./engine/build.sh` has cloned and patched Luanti at least once (or perform those steps yourself):

```bash
export ANTHILL_INSTALL_PREFIX="$HOME/.local"
cp engine/CMakeUserPresets-anthill.json third_party/luanti-src/CMakeUserPresets.json
cd third_party/luanti-src
cmake --preset anthill-engine
cmake --build --preset anthill-engine
cmake --install ../../engine/out/build
```

Install prefix and build flags come from the preset and environment; see **`engine/README.md`** for patch contents and licensing.

## Preset vs manual fallback

`engine/build.sh` uses the **`anthill-engine`** preset when `cmake --list-presets` run inside `third_party/luanti-src` lists it. If your CMake is too old or preset parsing fails, the script falls back to an explicit `cmake` / `cmake --build` / `cmake --install` invocation against `engine/out/build`.

The preset file must live **next to Luanti’s** `CMakePresets.json` (CMake loads user presets from the **source** directory), which is why the canonical file is **`engine/CMakeUserPresets-anthill.json`** and is copied into the clone by `build.sh`—not a `CMakePresets.json` at the Anthill repo root.
