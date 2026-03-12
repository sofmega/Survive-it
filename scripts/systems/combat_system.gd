extends Node


func apply_damage(source: Node, target: Node, amount: float) -> void:
	if target == null or amount <= 0.0:
		return

	if target.has_method("receive_damage"):
		target.receive_damage(amount, source)

