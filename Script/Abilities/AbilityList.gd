extends Resource
class_name AbilityList

## Holds the player's unlocked abilities. Add or remove entries at any time;
## the UI listens to `changed` and rebuilds automatically.

var abilities: Array[AbilityData] = []


signal changeAdded(ability: AbilityData)
signal changeRemoved(ability: AbilityData)

func add_ability(ability: AbilityData) -> void:
	if not abilities.has(ability):
		abilities.append(ability)
		changeAdded.emit(ability)

func remove_ability(ability: AbilityData) -> void:
	if abilities.has(ability):
		abilities.erase(ability)
		changeRemoved.emit(ability)

## Passive stat aggregation — queried by player every physics frame.
func get_passive_speed_bonus() -> float:
	var total := 0.0
	for ab:Slot in abilities:
		if ab is AbilityData:
			total += ab.get_speed_bonus()
	return total

func get_passive_damage_bonus() -> float:
	var total := 0.0
	for ab:Slot in abilities:
		if ab is AbilityData:
			total += ab.get_damage_bonus()
	return total

func get_passive_health_regen() -> float:
	var total := 0.0
	for ab:Slot in abilities:
		if ab is AbilityData:
			total += ab.get_health_regen()
	return total
