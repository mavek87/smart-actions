#!/bin/bash
#Author: Matteo Veroni

if [ -z "$SMART_ACTIONS_CONFIG_FILE" ]; then
    echo "Error: SMART_ACTIONS_CONFIG_FILE not set."
    exit 1
fi

declare -A OPTIONS
declare -A EXAMPLES
declare -A DEFAULTS
MANDATORY_OPTIONS=()

load_config() {
    if [[ -f "$SMART_ACTIONS_CONFIG_FILE" ]]; then
        while IFS="=" read -r key value; do
            # Rimuove spazi iniziali e finali
            key="$(echo "$key" | xargs)"
            value="$(echo "$value" | xargs)"

            # Ignora righe vuote o commenti
            [[ -z "$key" || "$key" =~ ^# ]] && continue

            if [[ "$key" == OPTIONS_* ]]; then
                var_name="${key#OPTIONS_}"
                OPTIONS["$var_name"]="$value"
            elif [[ "$key" == EXAMPLES_* ]]; then
                example_key="${key#EXAMPLES_}"
                EXAMPLES["$example_key"]="$value"
            elif [[ "$key" == DEFAULTS_* ]]; then
                default_key="${key#DEFAULTS_}"
                DEFAULTS["$default_key"]="$value"
            elif [[ "$key" == "MANDATORY_OPTIONS" ]]; then
                read -r -a MANDATORY_OPTIONS <<< "$value"
            fi
        done < "$SMART_ACTIONS_CONFIG_FILE"
    else
        echo "Error: Configuration file '$SMART_ACTIONS_CONFIG_FILE' not found!"
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        shift
        matched=0

        for var_name in "${!OPTIONS[@]}"; do
            for opt in ${OPTIONS[$var_name]}; do
                if [[ "$key" == "$opt" ]]; then
                    if [[ -n "$1" && "$1" != -* ]]; then
                        eval "$var_name='$1'"
                        shift
                    else
                        echo "Error: option '$key' requires a value!"
                        echo
                        help
                        exit 1
                    fi
                    matched=1
                    break 2
                fi
            done
        done

        if [[ $matched -eq 0 ]]; then
            if [[ "$key" == "-h" || "$key" == "--help" ]]; then
                help
                exit 0
            else
                echo "Error: unknown parameter ($key)!"
                echo
                help
                exit 1
            fi
        fi
    done
}

help() {
    script_name=$(basename "$0")
    echo "Usage: $script_name [options]"
    echo
    echo "Options:"
    for var_name in "${!OPTIONS[@]}"; do
        opts="${OPTIONS[$var_name]}"
        mandatory=""
        if [[ " ${MANDATORY_OPTIONS[*]} " =~ " $var_name " ]]; then
            mandatory="(mandatory)"
        fi
        echo "  $opts <value>  Set $var_name $mandatory"
    done

    # Stampa gli esempi solo se esistono
    if [[ ${#EXAMPLES[@]} -gt 0 ]]; then
        echo
        echo "Examples:"
        for key in "${!EXAMPLES[@]}"; do
            echo "  ${EXAMPLES[$key]//\$0/$script_name}"
        done
    fi

    echo
}

check_mandatory_options() {
    for var_name in "${MANDATORY_OPTIONS[@]}"; do
        if [[ -z "${!var_name}" ]]; then
            echo "Error: option '${OPTIONS[$var_name]}' is mandatory!"
            help
            exit 1
        fi
    done
}

load_config

if [ $# -eq 0 ]; then
    help
    exit 1
else
    parse_args "$@"
fi

check_mandatory_options

output=""

for var_name in "${!OPTIONS[@]}"; do
    value="${!var_name}"

    # Check if there is a default value for this option in the DEFAULTS array
    default_value="${DEFAULTS[$var_name]}"

    # If a default value exists and the current value is empty, use the default value
    if [ -n "$default_value" ] && [ -z "$value" ]; then
        value="$default_value"
    fi

    output+="$var_name=$value\n"
done

echo -e "$output" > "$SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE"

#echo -e
#
#Sequenze di escape comuni:
#\n — Nuova riga (line break)
#\t — Tabulazione orizzontale (tab)
#\\ — Backslash
#\a — Suono di allarme (beep)
#\b — Backspace