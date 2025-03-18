#!/bin/bash
#Author: Matteo Veroni

# set -x

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SCRIPT_NAME="$(basename "$SCRIPT_DIR")"
export SMART_ACTIONS_CONFIG_FILE="${SCRIPT_DIR}/action.conf"

source "${SCRIPT_DIR}/../commons.sh"

execute_action() {
  echo "Execute: $SCRIPT_NAME"

  faster_whisper_cmd="${FASTER_WHISPER_DIR}/faster-whisper --vad_method pyannote_v3 --device cuda --model ${model} --output_format text --task ${task}"
  if [[ -n "$language" ]]; then
    faster_whisper_cmd+=" --language $language"
  fi
  faster_whisper_cmd+=" ${FASTER_WHISPER_DIR}/rec_audio.wav"

  cp "$input_file" "${FASTER_WHISPER_DIR}/rec_audio.wav" &&
    $faster_whisper_cmd &&
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

load_args_from_built_command

model="${CMD_ARGS["model"]}"
task="${CMD_ARGS["task"]}"
language="${CMD_ARGS["language"]}"
input_file="${CMD_ARGS["input_file"]}"

validate_file_exists "$input_file"

execute_action