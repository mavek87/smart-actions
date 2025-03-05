#!/bin/bash

# File di configurazione di default
export SMART_ACTIONS_PARAMS_CONFIG_FILE="audio_to_text.conf"

./parameters.sh "$@"

dati=$(cat $SMART_ACTIONS_PARAMETER_OUTPUT_FILE 2>/dev/null || true)

# Controlla se $dati è nullo o una stringa vuota
if [[ -z "$dati" ]]; then
    echo "Nessun dato ricevuto."
else
    # Usa i dati letti
    echo "$dati"
fi