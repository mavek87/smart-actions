#!/bin/bash
#Author: Matteo Veroni

# set -x

script_dir="$(dirname "$(realpath "$0")")"
script_folder_name="$(basename "$script_dir")"
export CURRENT_SMART_ACTION_NAME="$script_folder_name"
export SMART_ACTIONS_CONFIG_FOLDER="${SMART_ACTIONS_PROJECT_DIR}/actions/${CURRENT_SMART_ACTION_NAME}"
export SMART_ACTIONS_CONFIG_FILE="${SMART_ACTIONS_CONFIG_FOLDER}/action.conf"

source "${script_dir}/../commons.sh"

execute_action() {
  echo "Execute: $CURRENT_SMART_ACTION_NAME"

  if [[ -n "$model" ]]; then
    PIPER_MODEL="${model}"
  else
    if [[ -n "$language" ]]; then
      PIPER_LANG="${language}"
    else
      PIPER_LANG="en" # default language is english
    fi

    PIPER_MODEL_FOR_LANGUAGE=$(eval "ls ${PIPER_DIR} | grep '^${PIPER_LANG}.*\.onnx$' | head -n 1")

    if [[ $PIPER_MODEL_FOR_LANGUAGE != "" ]]; then
      PIPER_MODEL="${PIPER_DIR}/${PIPER_MODEL_FOR_LANGUAGE}"
    else
      echo -e "${SMART_ACTIONS_COLOR_RED}Error: No ONNX Piper model found for language '$PIPER_LANG' in piper folder $PIPER_DIR${SMART_ACTIONS_COLOR_RESET}"
      exit 1
    fi
  fi

  if [[ -n "$PIPER_MODEL" ]]; then
    input="${text:-$(cat)}"
    command=("${PIPER_DIR}/piper" --model "$PIPER_MODEL")

    if [[ -n "$output_file" ]]; then
      "${command[@]}" --output-file "$output_file" <<<"$input"
    else
      "${command[@]}" --output-raw <<<"$input" | ffmpeg -f s16le -ar 22050 -ac 1 -i - -f alsa default
    fi
  else
    echo "${SMART_ACTIONS_COLOR_RED}Error: No piper model specified and no model found in piper dir $PIPER_DIR for language $PIPER_LANG${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi

  exit 0
}

"${SMART_ACTIONS_PROJECT_DIR}/actions/command_action_builder.sh" "$@"
result=$?

if [[ $result -ne 0 ]]; then
  exit $result
fi

load_args_from_built_command

text="${CMD_ARGS["text"]}"
language="${CMD_ARGS["language"]}"
model="${CMD_ARGS["model"]}"
output_file="${CMD_ARGS["output_file"]}"

execute_action