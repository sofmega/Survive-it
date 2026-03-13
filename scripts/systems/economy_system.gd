extends Node

signal gold_changed(current_gold: int)
signal spend_failed(reason: String)

var current_gold: int = 0


func setup(starting_gold: int) -> void:
	current_gold = starting_gold
	gold_changed.emit(current_gold)


func can_afford(cost: int) -> bool:
	return current_gold >= cost


func spend(cost: int) -> bool:
	if cost < 0:
		spend_failed.emit("Invalid cost")
		return false

	if not can_afford(cost):
		spend_failed.emit("Not enough gold")
		return false

	current_gold -= cost
	gold_changed.emit(current_gold)
	return true


func add_gold(amount: int) -> void:
	if amount <= 0:
		return

	current_gold += amount
	gold_changed.emit(current_gold)
