#!/bin/bash
#Author: Matteo Veroni

script_dir="$(dirname "$(realpath "$0")")"
script_folder_name="$(basename "$script_dir")"
export CURRENT_SMART_ACTION_NAME="$script_folder_name"
export SMART_ACTIONS_CONFIG_FOLDER="${SMART_ACTIONS_PROJECT_DIR}/actions/${CURRENT_SMART_ACTION_NAME}"
export SMART_ACTIONS_CONFIG_FILE="${SMART_ACTIONS_CONFIG_FOLDER}/action.conf"

# TODO: duplicated code except last lines
read_command_action_builder_data_output() {
  declare -A CMD_VARS

  while IFS='=' read -r key value; do
    key=$(echo "$key" | tr -d '[:space:]')
    value=$(echo "$value" | tr -d '[:space:]')

    [[ -z "$key" ]] && continue

    CMD_VARS["$key"]="${value:-""}"
  done < <(tr -d '\r' <"$SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE")

  rm -rf "$SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE" 2>/dev/null || true

  input_file="${CMD_VARS["input_file"]}"
  if [ ! -f "$input_file" ]; then
    # TODO is it ok? No complete help print...
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: input file '$input_file' does not exist${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi

  model="${CMD_VARS["model"]}"
  task="${CMD_VARS["task"]}"
  language="${CMD_VARS["language"]}"
}

execute_action() {
  echo "Execute: $CURRENT_SMART_ACTION_NAME"

  faster_whisper_cmd="${FASTER_WHISPER_DIR}/faster-whisper --vad_method pyannote_v3 --device cuda --model ${model} --output_format text --task ${task}"
  if [[ -n "$language" ]]; then
    faster_whisper_cmd+=" --language $language"
  fi
  faster_whisper_cmd+=" ${FASTER_WHISPER_DIR}/rec_audio.wav"

  cp "$input_file" "${FASTER_WHISPER_DIR}/rec_audio.wav" &&
    $faster_whisper_cmd &&
    #    echo type "$(tr '\n' ' ' <"${SMART_ACTIONS_PROJECT_DIR}/rec_audio.text")" |
    # TODO: evaluate if typedelay and typehold should be dynamic values
    echo "typedelay 2
            typehold 2
            type $(tr '\n' ' ' <"${FASTER_WHISPER_DIR}/rec_audio.text")" |
    DOTOOL_XKB_LAYOUT=it dotool
}

"${SMART_ACTIONS_PROJECT_DIR}/actions/command_action_builder.sh" "$@"
result=$?

if [[ $result -ne 0 ]]; then
  exit $result
fi

read_command_action_builder_data_output

execute_action

unset SMART_ACTION_NAME
unset SMART_ACTIONS_CONFIG_FOLDER
unset SMART_ACTIONS_CONFIG_FILE
