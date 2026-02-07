extends SceneTree

func _init():
	var log_dir = "res://test_harness/logs/"
	LogAnalyzer.run_analysis(log_dir)
	quit()
