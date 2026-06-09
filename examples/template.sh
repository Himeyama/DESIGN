#!/usr/bin/env bash
set -euo pipefail

# ====================
# Global Variables
# ====================

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERBOSE=false
OUTPUT=""
COMMAND=""
declare -a ARGS=()

# ====================
# Color codes
# ====================

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly YELLOW='\033[0;33m'
  readonly GREEN='\033[1;32m'
  readonly CYAN='\033[0;36m'
  readonly CYAN_DIM='\033[36m'
  readonly GRAY='\033[0;90m'
  readonly NC='\033[0m'
else
  readonly RED=''
  readonly YELLOW=''
  readonly GREEN=''
  readonly CYAN=''
  readonly CYAN_DIM=''
  readonly GRAY=''
  readonly NC=''
fi

# ====================
# Functions
# ====================

log_error() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[ERROR]%b %s\n" "$timestamp" "${RED}" "${NC}" "$1" >&2
}

log_warn() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[WARN]%b  %s\n" "$timestamp" "${YELLOW}" "${NC}" "$1" >&2
}

log_info() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[INFO]%b  %s\n" "$timestamp" "${CYAN}" "${NC}" "$1"
}

log_debug() {
  [[ "${VERBOSE}" == "true" ]] || return 0
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[DEBUG]%b %s\n" "$timestamp" "${GRAY}" "${NC}" "$1"
}

show_help() {
  echo "Template Script"
  echo
  printf "%bUsage:%b template.sh [OPTIONS] <COMMAND>\n\n" "${GREEN}" "${NC}"
  printf "%bOptions:%b\n" "${GREEN}" "${NC}"
  printf "  %b-v%b, %b--verbose%b                  Enable verbose output\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}"
  printf "  %b-o%b, %b--output%b %bFILE%b            Write output to FILE\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}" "${CYAN_DIM}" "${NC}"
  printf "  %b-h%b, %b--help%b                    Show this help message\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}"
  printf "  %b-V%b, %b--version%b                 Show version\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}"
  printf "\n"
  printf "%bCommands:%b\n" "${GREEN}" "${NC}"
  printf "  %brun%b                        Run a command or script\n" "${CYAN}" "${NC}"
  printf "  %bversion%b                    Read or update the project's version\n" "${CYAN}" "${NC}"
}

show_version() {
  echo "Template Script 1.0.0"
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        show_help
        exit 0
        ;;
      -V | --version)
        show_version
        exit 0
        ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      -o | --output)
        if [[ -z "${2:-}" ]]; then
          log_error "Option $1 requires a value"
          show_help >&2
          exit 2
        fi
        OUTPUT="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        log_error "Unknown option: $1"
        show_help >&2
        exit 2
        ;;
      *)
        COMMAND="$1"
        shift
        break
        ;;
    esac
  done

  ARGS=("$@")
}

cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_error "Script failed with exit code $exit_code"
  fi
  exit "$exit_code"
}

cmd_run() {
  log_info "Running command..."
  log_debug "Arguments: ${ARGS[*]:-none}"

  if [[ -n "$OUTPUT" ]]; then
    log_info "Writing output to: $OUTPUT"
    echo "Command output at $(date)" > "$OUTPUT"
    log_debug "Output file created"
  fi

  log_info "Command completed successfully"
}

cmd_version() {
  show_version
}

# ====================
# Main
# ====================

trap cleanup EXIT

parse_arguments "$@"

log_debug "VERBOSE=$VERBOSE, OUTPUT=$OUTPUT, COMMAND=$COMMAND"

if [[ -z "$COMMAND" ]]; then
  log_error "No command specified"
  show_help >&2
  exit 2
fi

case "$COMMAND" in
  run)
    cmd_run
    ;;
  version)
    cmd_version
    ;;
  *)
    log_error "Unknown command: $COMMAND"
    show_help >&2
    exit 2
    ;;
esac
