#!/bin/bash

# ANSI color codes
readonly COLOR_ERROR=$'\x1b[31m'
readonly COLOR_WARN=$'\x1b[33m'
readonly COLOR_INFO=$'\x1b[36m'
readonly COLOR_DEBUG=$'\x1b[90m'
readonly COLOR_RESET=$'\x1b[0m'

# Check if output is a terminal and NO_COLOR is not set
is_terminal() {
  [[ -t 1 ]] && [[ -z "$NO_COLOR" ]]
}

# Format timestamp as YYYY-MM-DD HH:mm:ss
format_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

# Log function
log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(format_timestamp)

  local max_level_length=5
  local padding_size=$((max_level_length - ${#level} + 1))
  local padding
  padding=$(printf ' %.0s' $(seq 1 "$padding_size"))

  local color_code
  case "$level" in
    ERROR) color_code="$COLOR_ERROR" ;;
    WARN)  color_code="$COLOR_WARN" ;;
    INFO)  color_code="$COLOR_INFO" ;;
    DEBUG) color_code="$COLOR_DEBUG" ;;
    *)     color_code="" ;;
  esac

  if is_terminal; then
    echo "${timestamp} ${color_code}[${level}]${COLOR_RESET}${padding}${message}"
  else
    echo "${timestamp} [${level}]${padding}${message}"
  fi
}

# Convenience functions
log_error() { log ERROR "$1"; }
log_warn()  { log WARN "$1"; }
log_info()  { log INFO "$1"; }
log_debug() { log DEBUG "$1"; }

# Examples
log_info "Application started"
log_warn "Configuration validation failed"
log_error "Database connection timeout"
log_debug "Processing request id=12345"
