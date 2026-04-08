# Anthill

**Anthill** is a **grain-scale, voxel-based simulation** of an ant colony, implemented in **Godot 4.2+**. The model is **inspired by the biology and chemistry of *Lasius niger*** (black garden ant): discrete-time colony dynamics, **recruitment pheromone** trails, **cuticular hydrocarbon (CHC)** footprint fields, **Dufour gland / alarm**–like signaling, nest excavation in granular substrate, brood development, and worker polyethism. The program is intended as a **research-oriented executable model**: observers inspect emergent behavior through a scientific HUD, optional **pheromone overlays**, and **validation CSV export**—not as an interactive game with player-directed ants.

**Scope and limitations.** This is a **simplified, algorithmic** representation. Parameters are tuned for stability and interpretability; they should **not** be read as species-wide empirical constants. Comparative validation against field or laboratory data is **out of scope** unless you add it. See **`docs/reference/technical_specification.txt`** for the modeling narrative, **`docs/reference/briefing.txt`** for foraging feedback logic, **`docs/reference/architecture_of_emergence.txt`** for the integrated feedback narrative (and the mapping below), and **`CHANGELOG.md`** for implementation history.

### Architecture of Emergence (reference mapping)

The note **`docs/reference/architecture_of_emergence.txt`** describes positive and negative feedback in ant spatial networks (stigmergy, footprint hydrocarbons, species contrasts). The simulation is ***Lasius niger*–inspired**, not a full replication of every mechanism in that text. The following summarizes **what is reflected in code** versus **what is not** (at a high level):

| Theme (document) | In this repository |
|------------------|-------------------|
| **Positive feedback / mass recruitment** — trail deposition reinforces later visits | **Yes.** Recruitment **pheromone** grid with deposit-on-return behavior, diffusion, evaporation (`pheromone_field.gd`, `colony_ants.gd`). |
| **Stigmergy** — environment carries the signal | **Yes.** Trail and footprint fields are sampled from the substrate; workers do not share a central map. |
| **Shorter paths → faster reinforcement** | **Partially.** Return-segment length scales recruitment deposit strength (**RTT**-style multipliers in `constants.gd` / `colony_ants.gd`), not a full shortest-path competition experiment. |
| **Higher food quality → more marking** | **Partially.** Food sources differ by type and supply; pickup and deposit logic does not implement every biological detail of “feed faster → more pheromone” from the literature. |
| **Negative feedback / footprint hydrocarbons** — avoid over-searched substrate | **Yes.** **CHC footprint** field: passive deposit while walking, slow decay, repellent / exploration weights (`footprint_field.gd`, tropotaxis and scout steps in `colony_ants.gd`). |
| **Trail vs footprint at bifurcations** (ratio-style balance) | **Yes.** Recruit tropotaxis uses a **ratio** form with trail in the numerator and footprint (and crowding) in the denominator (`TROPOTAXIS_*` in `constants.gd`). |
| **Crowding / overshoot-style relief** | **Partially.** **Feeder crowding** reduces pickup when many workers are near a patch; there is no explicit “depleted patch” overshoot model beyond finite food and rot. |
| **Alarm / Dufour gland / undecane** | **Partially.** An **alarm** field exists and is framed as Dufour-type; it is **not** a chemical identity model for undecane. |
| ***Monomorium pharaonis*** **contrast** (polydomy, sting dragging, volatile repellent half-life, etc.) | **No.** The executable does not simulate a second species or *M. pharaonis* trail rules. |
| **Physical “interaction mechanism” at forks** (experienced ant steers naive nestmate) | **No.** No pairwise ant–ant steering at bifurcations; only field-based movement. |
| **Visual landmarks** | **No.** |
| **Explicit ABM benchmark** (pheromone-only vs dual-signal efficiency) | **No.** The program does not ship a built-in A/B toggle for that comparison; you would compare runs or fork behavior externally. |

**Nest excavation** (granular substrate, procedural blueprint galleries, dig scoring) implements **spatial nest expansion** described elsewhere in the repo; the *Architecture of Emergence* text is mainly about **foraging networks**, not the nest voxel model.

## What the simulation contains

- **Substrate:** A chunked **heightmap-style** world in which one voxel represents one **sand grain** in the fiction (~3 mm; see `game/anthill/scripts/constants.gd`); **loose sand** undergoes gravity-driven updates each physics tick.
- **Colony:** Founding **queen** lifecycle (flight, search, claustral phase), **brood** (egg / larva / pupa durations in ant-days), **nanitic and worker** emergence, **trophallaxis**-style feeding from colony stores to the queen, task allocation (foraging, digging, brood care, nest maintenance).
- **Chemical fields (2D grids aligned to the nest plane):** **recruitment trail** (positive feedback, diffusion + evaporation), **CHC footprint** (traffic-dependent deposit, slow decay), **nest-construction** pheromone, and an **alarm** field with deposits tied to colony nutritional stress.
- **Workers:** State-based movement (scout vs recruit tropotaxis, substrate-dependent **zigzag** and **stop** sampling, memory of food patches, round-trip–scaled recruitment marking, crowding-aware patch choice).
- **Instrumentation:** Optional **`user://`** CSV logs when validation flags are enabled in code; optional **`PerfTrace`** autoload for frame-cost logging (see `CHANGELOG`).

## Reference materials

PDFs (articles and thesis), briefing notes, **architecture of emergence** narrative, the **technical specification** text, and a **pheromone reference table** (CSV) live under **`docs/reference/`**. See **`docs/reference/README.md`**. The **intro video** source file (**MP4**) and the **Ogg Theora** asset used at startup are under **`game/anthill/assets/intro/`** (Godot’s built-in player supports **`.ogv`** only; regenerate **`intro.ogv`** from the MP4 with **`ffmpeg`** if you replace the clip).

## Running the simulation

Open the Godot project under **`game/anthill`** (see **`game/anthill/README.md`** for controls and UI), or:

```bash
godot --path game/anthill
```

### System install (`anthill` launcher)

Runtime dependency: **Godot 4** on `PATH` as **`godot4`** or **`godot`**. If needed:

```bash
sudo ./scripts/install-godot4.sh
```

That installs **`/usr/local/bin/godot4`** (override: `sudo GODOT_VERSION=4.3.0 ./scripts/install-godot4.sh`). Alternatively use a [distribution package](https://godotengine.org/download/linux/).

From the repository root:

```bash
sudo ./scripts/install-anthill.sh
```

This copies **`game/anthill`** to **`/usr/local/share/anthill/game/anthill`** and installs **`/usr/local/bin/anthill`**, which invokes Godot with the project path. Override install prefix: `sudo PREFIX=/opt/anthill ./scripts/install-anthill.sh`. One-shot custom binary: `GODOT_BIN=/path/to/Godot_v4.x_linux.x86_64 anthill`.

**PATH conflict:** If **`anthill`** opens an unrelated engine (e.g. a **Luanti** binary in **`~/.local/bin`**), rename that binary or call **`/usr/local/bin/anthill`** explicitly.

## Repository layout

The **Ogg Theora** intro (**`game/anthill/assets/intro/intro.ogv`**) is tracked in Git under GitHub’s per-file size limit. The **MP4** source for transcoding is **not** committed (see **`game/anthill/.gitignore`**); place a copy locally if you need to re-encode.

| Path | Role |
|------|------|
| **`game/anthill/`** | Godot project: scenes, scripts, packaged **`assets/`** (splash, intro media). |
| **`docs/reference/`** | Bibliography, specification text, briefing, CSV tables (not loaded at runtime). |
| **`docs/cursor-agent-shell.md`** | Notes if the Cursor agent shell misbehaves. |
| **`CHANGELOG.md`** | Versioned list of code and asset changes. |
| **`releases/`** | Linux **`anthill-*-linux.x86_64`** export, repo-relative **`anthill`** launcher (see **`releases/README.md`**). |
| **`scripts/install-godot4.sh`**, **`scripts/install-anthill.sh`**, **`scripts/export-linux.sh`** | Install Godot, install the **`anthill`** launcher system-wide, or build the Linux export binary. |

## Citation and reuse

If you use this software or its documentation in academic work, cite the **repository** and **version** (see **`game/anthill/project.godot`** `config/version` and **`CHANGELOG.md`**), and describe which **commit or release** you ran. Model assumptions belong in your methods section; point readers to **`docs/reference/technical_specification.txt`** and the **CHANGELOG** for the mapping from biology to code.
