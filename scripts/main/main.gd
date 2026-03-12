extends Node2D

@onready var world: Node = $World
@onready var status_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/StatusLabel


func _process(_delta: float) -> void:
	if world.has_method("get_status_text"):
		status_label.text = world.get_status_text()

