class_name SkillTreeCatalog extends RefCounted

const TREE_DM := "dm"
const TREE_DAD := "dad"

const REASON_OK := "ok"
const REASON_NOT_ENOUGH_SP := "not_enough_sp"
const REASON_ROW_GATED := "row_gated"
const REASON_ULTIMATE_PREREQ := "ultimate_prereq"
const REASON_ALREADY_OWNED := "already_owned"
const REASON_UNKNOWN := "unknown"

const ROW2_FL := 10
const ROW3_FL := 50
const ULTIMATE_COST := 5

const NODES: Array[Dictionary] = [
	{"id": "overcharged", "tree": TREE_DM, "row": 1, "col": 1, "cost": 1, "ultimate": false},
	{"id": "spark", "tree": TREE_DM, "row": 1, "col": 2, "cost": 2, "ultimate": false},
	{"id": "chain_lightning", "tree": TREE_DM, "row": 1, "col": 3, "cost": 3, "ultimate": false},
	{"id": "minions", "tree": TREE_DM, "row": 2, "col": 1, "cost": 1, "ultimate": false},
	{"id": "blind_one_legged_monkeys", "tree": TREE_DM, "row": 2, "col": 2, "cost": 2, "ultimate": false},
	{"id": "crib_death", "tree": TREE_DM, "row": 2, "col": 3, "cost": 3, "ultimate": false},
	{"id": "challenge_rating", "tree": TREE_DM, "row": 3, "col": 1, "cost": 1, "ultimate": false},
	{"id": "plus_one_swords", "tree": TREE_DM, "row": 3, "col": 2, "cost": 2, "ultimate": false},
	{"id": "random_encounter", "tree": TREE_DM, "row": 3, "col": 3, "cost": 3, "ultimate": false},
	{"id": "tsb", "tree": TREE_DM, "row": 0, "col": 0, "cost": ULTIMATE_COST, "ultimate": true},
	{"id": "bemidji_cold", "tree": TREE_DAD, "row": 1, "col": 1, "cost": 1, "ultimate": false},
	{"id": "tshirt_in_december", "tree": TREE_DAD, "row": 1, "col": 2, "cost": 2, "ultimate": false},
	{"id": "put_a_sweater_on", "tree": TREE_DAD, "row": 1, "col": 3, "cost": 3, "ultimate": false},
	{"id": "stoke", "tree": TREE_DAD, "row": 2, "col": 1, "cost": 1, "ultimate": false},
	{"id": "full_cord", "tree": TREE_DAD, "row": 2, "col": 2, "cost": 2, "ultimate": false},
	{"id": "everything_burns", "tree": TREE_DAD, "row": 2, "col": 3, "cost": 3, "ultimate": false},
	{"id": "thermostat_lock", "tree": TREE_DAD, "row": 3, "col": 1, "cost": 1, "ultimate": false},
	{"id": "dad_reflexes", "tree": TREE_DAD, "row": 3, "col": 2, "cost": 2, "ultimate": false},
	{"id": "grounded", "tree": TREE_DAD, "row": 3, "col": 3, "cost": 3, "ultimate": false},
	{"id": "dad_all_powerful", "tree": TREE_DAD, "row": 0, "col": 0, "cost": ULTIMATE_COST, "ultimate": true},
]


static func node_for(node_id: String) -> Dictionary:
	for entry in NODES:
		if str(entry["id"]) == node_id:
			return entry
	return {}


static func is_known(node_id: String) -> bool:
	return not node_for(node_id).is_empty()


static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in NODES:
		ids.append(str(entry["id"]))
	return ids


static func tree_of(node_id: String) -> String:
	return str(node_for(node_id).get("tree", ""))


static func row_of(node_id: String) -> int:
	return int(node_for(node_id).get("row", 0))


static func cost_of(node_id: String) -> int:
	return int(node_for(node_id).get("cost", 0))


static func is_ultimate(node_id: String) -> bool:
	return bool(node_for(node_id).get("ultimate", false))


static func ids_in_tree_row(tree: String, row: int) -> Array[String]:
	var ids: Array[String] = []
	for entry in NODES:
		if str(entry["tree"]) != tree:
			continue
		if bool(entry.get("ultimate", false)):
			continue
		if int(entry.get("row", 0)) != row:
			continue
		ids.append(str(entry["id"]))
	return ids


static func fl_gate_for_row(row: int) -> int:
	if row == 2:
		return ROW2_FL
	if row == 3:
		return ROW3_FL
	return 0
