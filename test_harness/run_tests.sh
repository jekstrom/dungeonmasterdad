#!/bin/bash

# Dungeon Master Dad Test Harness Runner Script
# This script provides easy commands to run various tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Dungeon Master Dad Test Suite${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

print_section() {
    echo -e "${YELLOW}$1${NC}"
    echo "----------------------------------------"
}

check_dependencies() {
    print_section "Checking dependencies..."
    
    if ! command -v godot &> /dev/null; then
        echo -e "${RED}Error: godot command not found in PATH${NC}"
        echo "Please install Godot or add it to your PATH"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 not found${NC}"
        echo "Please install Python 3"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All dependencies found${NC}"
    echo
}

run_quick_test() {
    print_section "Running Quick Test (2 clients, 10 seconds)"
    python3 "$SCRIPT_DIR/test_harness.py" --clients 2 --duration 10
}

run_standard_test() {
    print_section "Running Standard Test (4 clients, 30 seconds)"
    python3 "$SCRIPT_DIR/test_harness.py" --clients 4 --duration 30
}

run_stress_test() {
    print_section "Running Stress Test (up to 10 clients)"
    python3 "$SCRIPT_DIR/test_harness.py" --stress-test --max-clients 10
}

run_extended_test() {
    print_section "Running Extended Test (6 clients, 300 seconds)"
    python3 "$SCRIPT_DIR/test_harness.py" --clients 6 --duration 300
}

analyze_logs() {
    print_section "Analyzing recent logs"
    if [ -z "$1" ]; then
        echo "Analyzing all logs in logs directory..."
        python3 "$SCRIPT_DIR/test_harness.py" --analyze-only "$(date +'%Y%m%d')"
    else
        echo "Analyzing logs for test ID: $1"
        python3 "$SCRIPT_DIR/test_harness.py" --analyze-only "$1"
    fi
}

show_help() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
  quick       Run quick test (2 clients, 60 seconds)
  standard    Run standard test (4 clients, 120 seconds) [DEFAULT]
  stress      Run stress test (ramping up to 10 clients)
  extended    Run extended test (6 clients, 300 seconds)
  analyze     Analyze logs from recent tests
  analyze ID  Analyze logs from specific test ID
  clean       Clean up old logs and results
  help        Show this help message

Examples:
  $0                    # Run standard test
  $0 quick             # Run quick test
  $0 stress            # Run stress test
  $0 analyze           # Analyze recent logs
  $0 analyze 20240206  # Analyze logs from specific date

The test harness will create logs in: $SCRIPT_DIR/logs/
Results are saved in: $SCRIPT_DIR/results/
EOF
}

clean_old_files() {
    print_section "Cleaning old logs and results"
    
    # Remove logs older than 7 days
    find "$SCRIPT_DIR/logs" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # Remove results older than 14 days
    find "$SCRIPT_DIR/results" -name "*.json" -mtime +14 -delete 2>/dev/null || true
    
    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

setup_directories() {
    mkdir -p "$SCRIPT_DIR/logs"
    mkdir -p "$SCRIPT_DIR/results"
}

main() {
    print_header
    check_dependencies
    setup_directories
    
    case "${1:-standard}" in
        "quick")
            run_quick_test
            ;;
        "standard")
            run_standard_test
            ;;
        "stress")
            run_stress_test
            ;;
        "extended")
            run_extended_test
            ;;
        "analyze")
            analyze_logs "$2"
            ;;
        "clean")
            clean_old_files
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"
