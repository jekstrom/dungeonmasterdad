class_name PaperFactory extends Building

@export var smoke_consume_amt: int = 3

func paper_produced(_animation: String) -> void:
	animation_player.play("RESET")
	animation_player.animation_finished.disconnect(paper_produced)

func _process(delta: float) -> void:
	if !multiplayer.is_server(): return
	if is_ghost: return
	sync_blizzard_interval()
	timer += delta
	
	if timer >= interval:
		timer -= interval
		if PlayerManager.smoke_amt >= smoke_consume_amt and PlayerManager.use_smoke(smoke_consume_amt):
			PlayerManager.update_reality_level(10)
			animation_player.play("paper")
			await get_tree().process_frame
			animation_player.animation_finished.connect(paper_produced)
