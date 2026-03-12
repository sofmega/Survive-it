extends Node2D

const HERO_DEF = preload("res://data/heroes/default_hero.tres")
const FORTRESS_TIER_DEF = preload("res://data/fortress/fortress_tier_1.tres")

@onready var fortress: Node2D = $World/Fortress
@onready var hero: Node2D = $World/Hero
@onready var builder: Node2D = $World/Builder
@onready var enemies_root: Node2D = $World/Enemies
@onready var structures_root: Node2D = $World/Structures
@onready var run_director: Node = $Directors/RunDirector
@onready var wave_director: Node = $Directors/WaveDirector
@onready var spawn_director: Node = $Directors/SpawnDirector
@onready var build_system: Node = $Directors/BuildSystem
@onready var economy_system: Node = $Directors/EconomySystem
@onready var combat_system: Node = $Directors/CombatSystem
@onready var hud: CanvasLayer = $UI/HUD

var controlled_unit: Node2D = null


func _ready() -> void:
	fortress.tier_def = FORTRESS_TIER_DEF
	hero.hero_def = HERO_DEF
	fortress.destroyed.connect(_on_fortress_destroyed)

	economy_system.setup(120)
	spawn_director.setup(
		enemies_root,
		fortress,
		combat_system,
		{&"west_lane": Vector2(96.0, 450.0)}
	)
	wave_director.setup(spawn_director, economy_system)
	run_director.setup(wave_director)
	build_system.setup(structures_root, fortress, economy_system, run_director, combat_system, enemies_root)
	hero.setup(combat_system, enemies_root)
	builder.set_controlled(false)
	hero.set_controlled(true)
	controlled_unit = hero
	hud.setup(run_director, wave_director, economy_system, fortress, self)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB:
				_toggle_controlled_unit()
			KEY_SPACE:
				if controlled_unit == builder:
					build_system.request_place_building(builder.selected_building_def, builder.global_position)


func _toggle_controlled_unit() -> void:
	if controlled_unit == hero:
		hero.set_controlled(false)
		builder.set_controlled(true)
		controlled_unit = builder
	else:
		builder.set_controlled(false)
		hero.set_controlled(true)
		controlled_unit = hero


func get_controlled_unit_label() -> String:
	if controlled_unit == builder:
		return "Builder (%s)" % builder.get_selected_building_name()

	return "Hero"


func _on_fortress_destroyed() -> void:
	run_director.enter_game_over("The fortress fell")
