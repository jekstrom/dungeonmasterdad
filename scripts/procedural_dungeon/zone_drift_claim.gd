class_name ZoneDriftClaim extends RefCounted

## Shared Reality/Fantasy drift claim winner (US-002 FR-007 / US-004 FR-006).
## Pockets override homes. Overlapping homes: higher covering level wins. Ties keep current art.

const CLAIM_NONE := 0
const CLAIM_REALITY := 1
const CLAIM_FANTASY := -1

static func for_cell(tree: SceneTree, cell: Vector2i) -> int:
	if tree == null:
		return CLAIM_NONE
	var reality: Node = tree.get_first_node_in_group("RealityZone")
	var fantasy: Node = tree.get_first_node_in_group("FantasyZone")
	if _zone_pocket_covers(reality, cell):
		return CLAIM_REALITY
	if _zone_pocket_covers(fantasy, cell):
		return CLAIM_FANTASY
	var reality_home := _zone_home_covers(reality, cell)
	var fantasy_home := _zone_home_covers(fantasy, cell)
	if reality_home and fantasy_home:
		var reality_level: int = int(PlayerManager.reality_level)
		var fantasy_level: int = int(DmManager.fantasy_level)
		if reality_level > fantasy_level:
			return CLAIM_REALITY
		if fantasy_level > reality_level:
			return CLAIM_FANTASY
		return CLAIM_NONE
	if reality_home:
		return CLAIM_REALITY
	if fantasy_home:
		return CLAIM_FANTASY
	return CLAIM_NONE

static func _zone_pocket_covers(zone: Node, cell: Vector2i) -> bool:
	if zone == null or not zone.has_method("winning_pocket_id"):
		return false
	return int(zone.winning_pocket_id(cell)) >= 0

static func _zone_home_covers(zone: Node, cell: Vector2i) -> bool:
	if zone == null:
		return false
	var rect: Rect2i = zone.home_rect
	return rect.size.x > 0 and rect.size.y > 0 and rect.has_point(cell)
