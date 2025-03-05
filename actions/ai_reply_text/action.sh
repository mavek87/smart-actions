#!/bin/bash
#Author: Matteo Veroni

export CURRENT_SMART_ACTION_NAME="ai_reply_text"
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
  task="${CMD_VARS["task"]}"
  language="${CMD_VARS["language"]}"
  audio_device="${CMD_VARS["audio_device"]}"
  audio_sampling_rate="${CMD_VARS["audio_sampling_rate"]}"
  selection_target="${CMD_VARS["selection_target"]}"
  output_target="${CMD_VARS["output_target"]}"
}

execute_action() {
  echo "$CURRENT_SMART_ACTION_NAME"

  faster_whisper_cmd="${SMART_ACTIONS_PROJECT_DIR}/faster-whisper --vad_method pyannote_v3 --device cuda --model ${model} --output_format text --task ${task}"

  if [[ -n "$language" ]]; then
    faster_whisper_cmd+=" --language $language"
  fi

  faster_whisper_cmd+=" ${SMART_ACTIONS_PROJECT_DIR}/rec_audio.wav"

  echo "Starting audio recording..."
  arecord -D "${audio_device}" -f cd -c 1 -r "${audio_sampling_rate}" "${SMART_ACTIONS_PROJECT_DIR}/rec_audio.wav"

  $faster_whisper_cmd &&
    pre_prompt="" &&
    {
      if [[ "$selection_target" != "none" ]]; then
        pre_prompt="$(xclip -selection "${selection_target}" -o)"
        ## debug
        #echo "selection: $pre_prompt"
      fi
    } &&
    if [[ "$output_target" == "terminal" ]]; then
      echo "$(tr '\n' ' ' <"${SMART_ACTIONS_PROJECT_DIR}/rec_audio.text")" &&
        tgpt -q -preprompt "$pre_prompt" "$(cat "${SMART_ACTIONS_PROJECT_DIR}/rec_audio.text")"
    elif [[ "$output_target" == "display" ]]; then
      tgpt -q -preprompt "$pre_prompt" "$(cat "${SMART_ACTIONS_PROJECT_DIR}/rec_audio.text")" >"${SMART_ACTIONS_PROJECT_DIR}/ai_reply.txt" &&
        sed -i 's/\r//' "${SMART_ACTIONS_PROJECT_DIR}/ai_reply.txt" &&
        mapfile -t lines <"${SMART_ACTIONS_PROJECT_DIR}/ai_reply.txt" &&
        {
          for line in "${lines[@]}"; do
            echo type "$line"
            echo key Enter
          done
        } | DOTOOL_XKB_LAYOUT=it dotool
    else
      # TODO è ok? non stampa help...
      echo "Error: output target '$output_target' does not exist"
      exit 1
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
