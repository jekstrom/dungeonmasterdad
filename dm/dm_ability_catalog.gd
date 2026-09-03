class_name DmAbilityCatalog extends RefCounted

const GREMLIN: String = "gremlin"
const KNIGHTLING: String = "knightling"
const GOBLIN: String = "goblin"
const FIREBALL: String = "fireball"
const BEMIDJI_BLIZZARD: String = "bemidji_blizzard"
const DAD_ALL_POWERFUL: String = "dad_all_powerful"

const UNKNOWN_COST: int = -1

const COST_GREMLIN: int = 20
const COST_KNIGHTLING: int = 40
const COST_GOBLIN: int = 20
const COST_FIREBALL: int = 15
const COST_BEMIDJI_BLIZZARD: int = 30
const COST_DAD_ALL_POWERFUL: int = 0

const UNLOCK_FIREBALL: String = "fireball"
const UNLOCK_KNIGHTLING: String = "knightling"
const UNLOCK_BEMIDJI_BLIZZARD: String = "bemidji_blizzard"
const UNLOCK_DAD_ALL_POWERFUL: String = "dad_all_powerful"

const ABILITIES: Dictionary = {
	GREMLIN: {"cost": COST_GREMLIN, "unlock_id": ""},
	KNIGHTLING: {"cost": COST_KNIGHTLING, "unlock_id": UNLOCK_KNIGHTLING},
	GOBLIN: {"cost": COST_GOBLIN, "unlock_id": ""},
	FIREBALL: {"cost": COST_FIREBALL, "unlock_id": UNLOCK_FIREBALL},
	BEMIDJI_BLIZZARD: {"cost": COST_BEMIDJI_BLIZZARD, "unlock_id": UNLOCK_BEMIDJI_BLIZZARD},
	DAD_ALL_POWERFUL: {"cost": COST_DAD_ALL_POWERFUL, "unlock_id": UNLOCK_DAD_ALL_POWERFUL},
}

static func is_known(ability_id: String) -> bool:
	return ABILITIES.has(ability_id)

static func cost(ability_id: String) -> int:
	if not is_known(ability_id):
		return UNKNOWN_COST
	return int(ABILITIES[ability_id]["cost"])

static func unlock_id(ability_id: String) -> String:
	if not is_known(ability_id):
		return ""
	return str(ABILITIES[ability_id]["unlock_id"])
