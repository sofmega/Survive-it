# Survive it

`Survive it` is a Godot 4 top-down survival-defense prototype inspired by Warcraft 3 Fortress Survival.

## Core Loop

- Control one hero and one builder with RTS-style mouse input.
- Survive waves `1` through `100`.
- Enemies spawn from four visible edge portals.
- Enemy priority is to hunt the hero and builder, then pressure player-built territory.
- Build towers, walls, banners, and support structures to create a survivable base.
- Gain gold from kills and wave clears, then spend it before the next surge.

The support relay still exists as a build anchor and upgradeable support structure, but it is no longer the main loss condition.

## Loss And Victory

- Defeat: both the hero and builder are dead.
- Victory: Wave `100` is fully cleared.

## Current Systems

- `RunDirector` owns phases, defeat, and victory.
- `WaveDirector` owns 100-wave progression and scaling.
- `SpawnDirector` owns portal spawning.
- `Enemy` owns local chase and attack behavior.
- `BuildSystem` owns placement legality.
- `EconomySystem` owns gold rewards and spending.
- `HUD` displays state without owning gameplay rules.

## Controls

- Left click: select the hero or builder
- Right click: move selected unit
- Build panel: choose a structure while the builder is selected
- Left click in build mode: place the structure
- Right click in build mode: cancel placement

## Open The Project

1. Install Godot 4.
2. Import this folder.
3. Run the project.
