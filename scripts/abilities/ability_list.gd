extends Node
class_name AbilityList

## Holds the player's unlocked abilities. Add or remove entries at any time;
## the UI listens to `changed` and rebuilds automatically.

var abilities: Array[AbilityData] = []

signal changed

func add_ability(ability: AbilityData) -> void:
	if not abilities.has(ability):
		abilities.append(ability)
		changed.emit()

func remove_ability(ability: AbilityData) -> void:
	if abilities.has(ability):
		abilities.erase(ability)
		changed.emit()
