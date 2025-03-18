#!/bin/bash
#Author: Matteo Veroni

declare -A CMD_ARGS  # Dichiarazione fuori dalla funzione

load_args_from_built_command() {
  echo "load_args_from_built_command"

  while IFS='=' read -r key value; do
    key=$(echo "$key" | tr -d '[:space:]')
    value=$(echo "$value" | tr -d '[:space:]')

    [[ -z "$key" ]] && continue

    CMD_ARGS["$key"]="${value:-""}"
  done < <(tr -d '\r' <"$SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE")

  rm -rf "$SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE" 2>/dev/null || true
}

validate_supported_value() {
    local option_name="$1"
    local option_value="$2"
    shift 2
    local valid_values=("$@")

    for value in "${valid_values[@]}"; do
        if [[ "$option_value" == "$value" ]]; then
            return 0
        fi
    done

    echo -e "${SMART_ACTIONS_COLOR_RED}Error: $option_name '$option_value' does not exist${SMART_ACTIONS_COLOR_RESET}"
    echo -e "${SMART_ACTIONS_COLOR_RED}The possible values are: ${valid_values[*]}${SMART_ACTIONS_COLOR_RESET}"
    exit 1
}

validate_file_exists() {
    local file_path="$1"
    if [ ! -f "$file_path" ]; then
        echo -e "${SMART_ACTIONS_COLOR_RED}Error: input file '$file_path' does not exist${SMART_ACTIONS_COLOR_RESET}"
        exit 1
    fi
}