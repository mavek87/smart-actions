#!/bin/bash

export SMART_ACTIONS_PARAMETER_OUTPUT_FILE=/tmp/smart_actions_parameters_output_file

mkdir -p /tmp

touch "$SMART_ACTIONS_PARAMETER_OUTPUT_FILE"

./audio_to_text.sh "$@"

unset NOME_VARIABILE