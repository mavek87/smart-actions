#!/bin/bash
#Author: Matteo Veroni

declare -A OPTIONS
declare -a OPTIONS_ORDERED_KEYS
declare -A EXAMPLES
declare -A DEFAULTS
MANDATORY_OPTIONS=()
description=""

add_option() {
  local key="$1"
  local opt_value="$2"

  if [[ -z "${OPTIONS[$key]}" ]]; then
    OPTIONS["$key"]="$opt_value"
    OPTIONS_ORDERED_KEYS+=("$key")
  fi
}

load_config() {
  if [[ -f "$SMART_ACTIONS_CONFIG_FILE" ]]; then
    while IFS="=" read -r key value_rest; do
      # Rimuove spazi iniziali e finali
      key="$(echo "$key" | xargs)"
      value="$(echo "$value_rest" | xargs)"

      # Ignora righe vuote o commenti
      [[ -z "$key" || "$key" =~ ^# ]] && continue

      # Aggiungi solo se l'opzione non è già stata aggiunta
      if [[ "$key" == OPTIONS_* && -z "${OPTIONS[$key]}" ]]; then
        option_key="${key#OPTIONS_}"
        add_option "$option_key" "$value"
      elif [[ "$key" == EXAMPLES_* ]]; then
        example_key="${key#EXAMPLES_}"
        EXAMPLES["$example_key"]="$value"
      elif [[ "$key" == DEFAULTS_* ]]; then
        default_key="${key#DEFAULTS_}"
        DEFAULTS["$default_key"]="$value"
      elif [[ "$key" == "MANDATORY_OPTIONS" ]]; then
        read -r -a MANDATORY_OPTIONS <<<"$value"
      elif [[ "$key" == "DESCRIPTION" ]]; then
        description="$value"
      fi
    done < <(grep -v '^#' "$SMART_ACTIONS_CONFIG_FILE") # Esclude commenti prima di leggere
  else
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: Configuration file '$SMART_ACTIONS_CONFIG_FILE' not found${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi
}

#load_config() {
#  if [[ -f "$SMART_ACTIONS_CONFIG_FILE" ]]; then
#    while IFS="=" read -r key value_rest; do
#      # Rimuove spazi iniziali e finali
#      key="$(echo "$key" | xargs)"
#      value="$(echo "$value_rest" | xargs)"
#
#      # Ignora righe vuote o commenti
#      [[ -z "$key" || "$key" =~ ^# ]] && continue
#
#      if [[ "$key" == OPTIONS_* ]]; then
#        option_key="${key#OPTIONS_}"
#        add_option "$option_key" "$value"
#      elif [[ "$key" == EXAMPLES_* ]]; then
#        example_key="${key#EXAMPLES_}"
#        EXAMPLES["$example_key"]="$value"
#      elif [[ "$key" == DEFAULTS_* ]]; then
#        default_key="${key#DEFAULTS_}"
#        DEFAULTS["$default_key"]="$value"
#      elif [[ "$key" == "MANDATORY_OPTIONS" ]]; then
#        read -r -a MANDATORY_OPTIONS <<<"$value"
#      elif [[ "$key" == "DESCRIPTION" ]]; then
#        description="$value"
#      fi
#    done < <(grep -v '^#' "$SMART_ACTIONS_CONFIG_FILE") # Esclude commenti prima di leggere
#  else
#    echo -e "${SMART_ACTIONS_COLOR_RED}Error: Configuration file '$SMART_ACTIONS_CONFIG_FILE' not found${SMART_ACTIONS_COLOR_RESET}"
#    exit 1
#  fi
#}

print_config() {
  cat "$SMART_ACTIONS_CONFIG_FILE"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    shift
    matched=0

    for option_key in "${OPTIONS_ORDERED_KEYS[@]}"; do
      for opt in ${OPTIONS[$option_key]}; do
        if [[ "$key" == "$opt" ]]; then
          if [[ -n "$1" && "$1" != -* ]]; then
            eval "$option_key='$1'"
            shift
          else
            echo -e "${SMART_ACTIONS_COLOR_RED}Error: option '$key' requires a value${SMART_ACTIONS_COLOR_RESET}"
            echo
            help
          fi
          matched=1
          break 2
        fi
      done
    done

    if [[ $matched -eq 0 ]]; then
      if [[ "$key" == "-h" || "$key" == "--help" ]]; then
        help
      elif [[ "$key" == "--print-config" ]]; then
        print_config
        exit 1
      else
        echo -e "${SMART_ACTIONS_COLOR_RED}Error: unknown parameter ($key)${SMART_ACTIONS_COLOR_RESET}"
        help
      fi
    fi
  done
}

help() {
  echo
  echo -e "${SMART_ACTIONS_COLOR_BLUE}Action:${SMART_ACTIONS_COLOR_RESET} $CURRENT_SMART_ACTION_NAME"
  echo -e "${SMART_ACTIONS_COLOR_BLUE}Description:${SMART_ACTIONS_COLOR_RESET} $description"
  echo
  echo -e "${SMART_ACTIONS_COLOR_BLUE}Usage:${SMART_ACTIONS_COLOR_RESET} smart-actions.sh $CURRENT_SMART_ACTION_NAME [options]"
  echo
  echo -e "${SMART_ACTIONS_COLOR_BLUE}Options:${SMART_ACTIONS_COLOR_RESET}"

  for option_key in "${OPTIONS_ORDERED_KEYS[@]}"; do
    opt="${OPTIONS[$option_key]}"
    mandatory=""
    if [[ " ${MANDATORY_OPTIONS[*]} " =~ " ${option_key} " ]]; then
      mandatory="(mandatory)"
    fi
    echo "  ${opt} <value>  Set ${option_key} ${mandatory}"
  done
  echo "  --print-config | Print the configuration file for this action"

  # Stampa gli esempi solo se esistono
  if [[ ${#EXAMPLES[@]} -gt 0 ]]; then
    echo
    echo -e "${SMART_ACTIONS_COLOR_GREEN}Examples:${SMART_ACTIONS_COLOR_RESET}"
    for key in "${!EXAMPLES[@]}"; do
      echo "  ${EXAMPLES[$key]//\$0/$CURRENT_SMART_ACTION_NAME}"
    done
  fi
  echo

  exit 1
}

check_mandatory_options() {
  for option_key in "${MANDATORY_OPTIONS[@]}"; do
    if [[ -z "${!option_key}" ]]; then
      echo -e "${SMART_ACTIONS_COLOR_RED}Error: option '${OPTIONS[$option_key]}' is mandatory${SMART_ACTIONS_COLOR_RESET}"
      help
    fi
  done
}

load_config

parse_args "$@"

check_mandatory_options

output=""
for opt_key in "${OPTIONS_ORDERED_KEYS[@]}"; do
  # Extract the passed param value expanding the param key name
  value="${!opt_key}"

  # Check if there is a default value for this option in the DEFAULTS array
  default_value="${DEFAULTS[$opt_key]}"

  # If a default value exists and the current passed value is empty, use the default value
  if [ -n "$default_value" ] && [ -z "$value" ]; then
    value="$default_value"
  fi

  output+="$opt_key=$value\n"
done

echo -e "$output" >"$SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE"

#echo -e
#
#Sequenze di escape comuni:
#\n — Nuova riga (line break)
#\t — Tabulazione orizzontale (tab)
#\\ — Backslash
#\a — Suono di allarme (beep)
#\b — Backspace
