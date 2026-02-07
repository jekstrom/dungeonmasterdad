extends Node
# Log Analyzer Script
# Analyzes console output and log files from test runs

class_name LogAnalyzer

enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR,
	CRITICAL
}

class LogEntry:
	var timestamp: String
	var category: String
	var level: LogLevel
	var message: String
	var source: String  # server or client_id
	
	func _init(ts: String, cat: String, lvl: LogLevel, msg: String, src: String = "unknown"):
		timestamp = ts
		category = cat
		level = lvl
		message = msg
		source = src

class AnalysisResult:
	var total_entries: int = 0
	var error_count: int = 0
	var warning_count: int = 0
	var network_events: int = 0
	var rpc_calls: int = 0
	var connection_issues: int = 0
	var performance_warnings: int = 0
	var test_duration: float = 0.0
	var unique_clients: Array[String] = []
	var critical_errors: Array[String] = []
	var network_timeline: Array[Dictionary] = []
	var performance_metrics: Dictionary = {}
	
	func print_summary():
		print("=== LOG ANALYSIS SUMMARY ===")
		print("Total log entries: %d" % total_entries)
		print("Errors: %d" % error_count)
		print("Warnings: %d" % warning_count)
		print("Network events: %d" % network_events)
		print("RPC calls: %d" % rpc_calls)
		print("Connection issues: %d" % connection_issues)
		print("Performance warnings: %d" % performance_warnings)
		print("Test duration: %.2f seconds" % test_duration)
		print("Unique clients: %d (%s)" % [unique_clients.size(), ", ".join(unique_clients)])
		
		if critical_errors.size() > 0:
			print("\nCRITICAL ERRORS:")
			for error in critical_errors:
				print("  - %s" % error)
		
		if performance_metrics.size() > 0:
			print("\nPERFORMANCE METRICS:")
			for metric in performance_metrics:
				print("  %s: %s" % [metric, performance_metrics[metric]])

var log_entries: Array[LogEntry] = []
var analysis_result: AnalysisResult

# Patterns for detecting different types of log events
var error_patterns: Array[String] = [
	"ERROR",
	"error",
	"Error",
	"FAILED",
	"failed",
	"Failed",
	"CRASH",
	"crash",
	"exception",
	"Exception"
]

var warning_patterns: Array[String] = [
	"WARNING",
	"warning",
	"Warning",
	"WARN",
	"warn"
]

var network_patterns: Array[String] = [
	"connected",
	"disconnected",
	"connection",
	"peer",
	"multiplayer",
	"network"
]

var rpc_patterns: Array[String] = [
	"rpc",
	"RPC",
	"remote",
	"call_remote"
]

var performance_patterns: Array[String] = [
	"memory",
	"Memory",
	"MEMORY",
	"fps",
	"FPS",
	"lag",
	"slow",
	"timeout"
]

func analyze_log_file(file_path: String) -> AnalysisResult:
	print("Analyzing log file: %s" % file_path)
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open log file: %s" % file_path)
		return null
	
	log_entries.clear()
	analysis_result = AnalysisResult.new()
	
	var first_timestamp: String = ""
	var last_timestamp: String = ""
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
			
		var entry = parse_log_line(line)
		if entry:
			log_entries.append(entry)
			analysis_result.total_entries += 1
			
			# Track timestamps for duration calculation
			if first_timestamp.is_empty():
				first_timestamp = entry.timestamp
			last_timestamp = entry.timestamp
			
			# Track unique clients
			if entry.source != "unknown" and entry.source != "server" and not analysis_result.unique_clients.has(entry.source):
				analysis_result.unique_clients.append(entry.source)
			
			# Categorize and count different types of events
			categorize_entry(entry)
	
	file.close()
	
	# Calculate test duration (simplified - would need proper timestamp parsing)
	if not first_timestamp.is_empty() and not last_timestamp.is_empty():
		analysis_result.test_duration = calculate_duration(first_timestamp, last_timestamp)
	
	# Perform additional analysis
	analyze_network_timeline()
	analyze_performance_metrics()
	detect_patterns()
	
	return analysis_result

func parse_log_line(line: String) -> LogEntry:
	# Parse log line format: [timestamp] category (source): message
	var regex = RegEx.new()
	regex.compile(r"^\[([^\]]+)\]\s+([A-Z_]+)(?:\s+\(([^)]+)\))?\s*:\s*(.*)$")
	var result = regex.search(line)
	
	if result:
		var timestamp = result.get_string(1)
		var category = result.get_string(2)
		var source = result.get_string(3) if result.get_string(3) else "unknown"
		var message = result.get_string(4)
		
		var level = determine_log_level(category, message)
		return LogEntry.new(timestamp, category, level, message, source)
	
	# Fallback for lines that don't match the expected format
	return LogEntry.new("", "UNKNOWN", LogLevel.INFO, line, "unknown")

func determine_log_level(category: String, message: String) -> LogLevel:
	var text = (category + " " + message).to_lower()
	
	for pattern in error_patterns:
		if pattern.to_lower() in text:
			return LogLevel.ERROR
	
	for pattern in warning_patterns:
		if pattern.to_lower() in text:
			return LogLevel.WARNING
	
	if category in ["SERVER_ERROR", "CLIENT_ERROR", "NETWORK_ERROR"]:
		return LogLevel.ERROR
	
	if category in ["CRITICAL", "CRASH"]:
		return LogLevel.CRITICAL
	
	return LogLevel.INFO

func categorize_entry(entry: LogEntry):
	var text = (entry.category + " " + entry.message).to_lower()
	
	# Count by log level
	match entry.level:
		LogLevel.ERROR, LogLevel.CRITICAL:
			analysis_result.error_count += 1
			if entry.level == LogLevel.CRITICAL:
				analysis_result.critical_errors.append("[%s] %s: %s" % [entry.timestamp, entry.category, entry.message])
		LogLevel.WARNING:
			analysis_result.warning_count += 1
	
	# Count network events
	for pattern in network_patterns:
		if pattern.to_lower() in text:
			analysis_result.network_events += 1
			analysis_result.network_timeline.append({
				"timestamp": entry.timestamp,
				"event": entry.category,
				"message": entry.message,
				"source": entry.source
			})
			break
	
	# Count RPC calls
	for pattern in rpc_patterns:
		if pattern.to_lower() in text:
			analysis_result.rpc_calls += 1
			break
	
	# Count performance issues
	for pattern in performance_patterns:
		if pattern.to_lower() in text:
			analysis_result.performance_warnings += 1
			break
	
	# Count connection issues
	if "failed" in text or "timeout" in text or "disconnect" in text:
		analysis_result.connection_issues += 1

func analyze_network_timeline():
	# Analyze the sequence of network events for patterns
	var connect_events = 0
	var disconnect_events = 0
	
	for event in analysis_result.network_timeline:
		var msg = event.message.to_lower()
		if "connect" in msg and "disconnect" not in msg:
			connect_events += 1
		elif "disconnect" in msg:
			disconnect_events += 1
	
	analysis_result.performance_metrics["connections"] = connect_events
	analysis_result.performance_metrics["disconnections"] = disconnect_events
	analysis_result.performance_metrics["connection_stability"] = float(connect_events - disconnect_events) / max(1, connect_events)

func analyze_performance_metrics():
	# Extract performance-related metrics from logs
	var memory_entries = log_entries.filter(func(entry): return "memory" in entry.message.to_lower())
	var movement_entries = log_entries.filter(func(entry): return "movement" in entry.category.to_lower())
	
	if memory_entries.size() > 0:
		analysis_result.performance_metrics["memory_reports"] = memory_entries.size()
	
	if movement_entries.size() > 0:
		analysis_result.performance_metrics["movement_updates"] = movement_entries.size()

func detect_patterns():
	# Look for recurring issues or patterns
	var message_counts: Dictionary = {}
	
	for entry in log_entries:
		var key = entry.category + ": " + entry.message
		if key in message_counts:
			message_counts[key] += 1
		else:
			message_counts[key] = 1
	
	# Find the most common messages
	var sorted_messages = []
	for key in message_counts:
		sorted_messages.append({"message": key, "count": message_counts[key]})
	
	sorted_messages.sort_custom(func(a, b): return a.count > b.count)
	
	analysis_result.performance_metrics["most_common_messages"] = sorted_messages.slice(0, 5)

func calculate_duration(start_time: String, end_time: String) -> float:
	# Simplified duration calculation
	# In a real implementation, you'd parse the timestamp format properly
	return 60.0  # Placeholder - return 1 minute

func analyze_directory(dir_path: String) -> Array[AnalysisResult]:
	print("Analyzing all log files in directory: %s" % dir_path)
	
	var results: Array[AnalysisResult] = []
	var dir = DirAccess.open(dir_path)
	
	if not dir:
		print("Failed to open directory: %s" % dir_path)
		return results
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".log"):
			var file_path = dir_path + "/" + file_name
			var result = analyze_log_file(file_path)
			if result:
				results.append(result)
		file_name = dir.get_next()
	
	return results

func compare_results(results: Array[AnalysisResult]):
	print("\n=== COMPARATIVE ANALYSIS ===")
	
	if results.size() == 0:
		print("No results to compare")
		return
	
	var total_errors = 0
	var total_warnings = 0
	var total_network_events = 0
	var avg_duration = 0.0
	
	for result in results:
		total_errors += result.error_count
		total_warnings += result.warning_count
		total_network_events += result.network_events
		avg_duration += result.test_duration
	
	avg_duration /= results.size()
	
	print("Total test runs analyzed: %d" % results.size())
	print("Combined errors: %d" % total_errors)
	print("Combined warnings: %d" % total_warnings)
	print("Combined network events: %d" % total_network_events)
	print("Average test duration: %.2f seconds" % avg_duration)
	
	# Find the run with the most issues
	var worst_run = results[0]
	for result in results:
		if result.error_count + result.warning_count > worst_run.error_count + worst_run.warning_count:
			worst_run = result
	
	print("\nMost problematic run had %d errors and %d warnings" % [worst_run.error_count, worst_run.warning_count])

# Standalone function to run analysis
static func run_analysis(log_path: String):
	var analyzer = LogAnalyzer.new()
	
	if DirAccess.dir_exists_absolute(log_path):
		# Analyze entire directory
		var results = analyzer.analyze_directory(log_path)
		for result in results:
			result.print_summary()
			print("---")
		analyzer.compare_results(results)
	elif FileAccess.file_exists(log_path):
		# Analyze single file
		var result = analyzer.analyze_log_file(log_path)
		if result:
			result.print_summary()
	else:
		print("Log path not found: %s" % log_path)
