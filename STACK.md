# Survive it - Chosen Stack

## Core Stack

- Engine: Godot 4
- Language: GDScript
- Game View: 2D top-down
- Project Style: Data-driven, AI-friendly, modular
- Version Control: Git

## Why This Stack

This project is a Warcraft 3-inspired fortress survival / hero defense game, and the main challenge is gameplay systems rather than high-end graphics.

Godot 4 with GDScript is the chosen stack because:

- it is fast to prototype with
- it is easier to drive with AI agents and prompt-based development
- project files are text-friendly and easier to inspect and edit
- it is well suited for gameplay-heavy systems like waves, buildings, units, economy, and combat

## Planned Technical Direction

- Start in 2D, not 3D
- Use TileMap for map layout and building footprint logic
- Use Godot UI (`Control` nodes) for HUD, menus, and build panels
- Use resource files (`.tres`) for unit, building, wave, and item data
- Keep multiplayer out of scope until single-player is fun

## AI-Friendly Development Rules

- Keep systems small and modular
- Store gameplay values in data files, not hardcoded everywhere
- Prefer one feature per script where possible
- Use clear folder names and predictable scene structure
- Build one playable loop first before adding content

## First Scope

- 1 map
- 1 hero
- 1 builder unit
- 3 building types
- 3 enemy wave types
- simple gold/resource economy
- nightly survival loop

## Final Decision

`Survive it` will use `Godot 4 + GDScript + 2D top-down`.

This is the preferred choice for fast prototyping, modular gameplay systems, and AI-assisted iteration.
