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

  model="${CMD_VARS["model"]}"
  ai_provider="${CMD_VARS["ai_provider"]}"
  task="${CMD_VARS["task"]}"
  language="${CMD_VARS["language"]}"
  audio_device="${CMD_VARS["audio_device"]}"
  audio_sampling_rate="${CMD_VARS["audio_sampling_rate"]}"
  selection_target="${CMD_VARS["selection_target"]}"
  output_destination="${CMD_VARS["output_destination"]}"
  output_format="${CMD_VARS["output_format"]}"
}

execute_action() {
  echo "$CURRENT_SMART_ACTION_NAME"

  if [[ "$ai_provider" != "duckduckgo" && "$ai_provider" != "phind" && "$ai_provider" != "ollama" && "$ai_provider" != "pollinations" ]]; then
    # TODO is it ok? No complete help print...
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: output target '$output_destination' does not exist${SMART_ACTIONS_COLOR_RESET}"
    echo -e "${SMART_ACTIONS_COLOR_RED}The possible values are: 'duckduckgo', 'phind', 'ollama', 'pollinations'${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi

  if [[ "$output_destination" != "terminal" && "$output_destination" != "display" ]]; then
    # TODO is it ok? No complete help print...
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: output target '$output_destination' does not exist${SMART_ACTIONS_COLOR_RESET}"
    echo -e "${SMART_ACTIONS_COLOR_RED}The possible values are: 'terminal', 'display'${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi

  if [[ "$output_format" != "text" && "$output_format" != "string" ]]; then
    # TODO is it ok? No complete help print...
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: output format '$output_format' does not exist${SMART_ACTIONS_COLOR_RESET}"
    echo -e "${SMART_ACTIONS_COLOR_RED}The possible values are: 'text', 'string'${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi

  faster_whisper_cmd="${SMART_ACTIONS_PROJECT_DIR}/faster-whisper --vad_method pyannote_v3 --device cuda --model ${model} --output_format text --task ${task}"
  if [[ -n "$language" ]]; then
    faster_whisper_cmd+=" --language $language"
  fi
  faster_whisper_cmd+=" ${SMART_ACTIONS_PROJECT_DIR}/rec_audio.mp3"

  echo "Starting audio recording..."
  #  arecord -D "${audio_device}" -f cd -c 1 -r "${audio_sampling_rate}" "${SMART_ACTIONS_PROJECT_DIR}/rec_audio.wav"
  ffmpeg -f alsa -i "${audio_device}" -ac 1 -ar "${audio_sampling_rate}" -codec:a libmp3lame -b:a 96k -y "${SMART_ACTIONS_PROJECT_DIR}/rec_audio.mp3"

  tgpt_whole_text_param=""
  if [[ "$output_format" == "text" ]]; then
    tgpt_whole_text_param="-w"
  fi

  $faster_whisper_cmd &&
    pre_prompt="" &&
    {
      if [[ "$selection_target" != "none" ]]; then
        pre_prompt="$(xclip -selection "${selection_target}" -o)"
        ## debug
        #echo "selection: $pre_prompt"
      fi
    } &&
    if [[ "$output_destination" == "terminal" ]]; then
      echo "$(tr '\n' ' ' <"${SMART_ACTIONS_PROJECT_DIR}/rec_audio.text")" &&
        tgpt -q $tgpt_whole_text_param --provider "$ai_provider" -preprompt "$pre_prompt" "$(cat "${SMART_ACTIONS_PROJECT_DIR}/rec_audio.text")"

    elif [[ "$output_destination" == "display" ]]; then
      tgpt -q $tgpt_whole_text_param --provider "$ai_provider" -preprompt "$pre_prompt" "$(cat "${SMART_ACTIONS_PROJECT_DIR}/rec_audio.text")" >"${SMART_ACTIONS_PROJECT_DIR}/reply_ai.txt" &&
        sed -i 's/\r//' "${SMART_ACTIONS_PROJECT_DIR}/reply_ai.txt" &&
        mapfile -t lines <"${SMART_ACTIONS_PROJECT_DIR}/reply_ai.txt" &&
        {
          for line in "${lines[@]}"; do
            # echo type "$line"
            # TODO: evaluate if typedelay and typehold should be dynamic values
            echo "typedelay 2
                    typehold 1
                    type $line"
            if [[ "$output_format" == "text" ]]; then
              echo key Enter
              # TODO: evaluate if the next commented elif is needed!
              #            elif [[ "$output_format" == "string" ]]; then
              #              echo key Space
            fi
          done
        } | DOTOOL_XKB_LAYOUT=it dotool
    fi
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
