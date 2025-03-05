#!/bin/bash

export SMART_ACTIONS_CONFIG_FOLDER="${SMART_ACTIONS_PROJECT_DIR}/actions/dictate_text"
export SMART_ACTIONS_CONFIG_FILE="${SMART_ACTIONS_CONFIG_FOLDER}/action.conf"

read_command_builder_data_output() {
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
    echo "Error: input file '$input_file' does not exist!"
    exit 1
  fi

  model="${CMD_VARS["model"]}"
  task="${CMD_VARS["task"]}"
  language="${CMD_VARS["language"]}"
  audio_device="${CMD_VARS["audio_device"]}"
}

execute_action() {
  echo "DICTATE TEXT"

  faster_whisper_cmd="${SMART_ACTIONS_PROJECT_DIR}/faster-whisper --vad_method pyannote_v3 --device cuda --model ${model} --output_format text --task ${task}"

  if [[ -n "$language" ]]; then
    faster_whisper_cmd+=" --language $language"
  fi

  faster_whisper_cmd+=" ${SMART_ACTIONS_PROJECT_DIR}/rec_audio.wav"

  echo "Starting audio recording..."
  arecord -D "${audio_device}" -f cd -c 1 -r 48000 "${SMART_ACTIONS_PROJECT_DIR}/rec_audio.wav" &&
    $faster_whisper_cmd &&
    mapfile -t lines <"${SMART_ACTIONS_PROJECT_DIR}/rec_audio.text" &&
    {
      for line in "${lines[@]}"; do
        echo type "$line" ##########
        echo key Enter
      done
    } | DOTOOL_XKB_LAYOUT=it dotool
}

#dictate_text() {
#  echo "DICTATE TEXT"
#
#  echo "Starting audio recording and transcription..."
#  arecord -D hw:3,0 -f cd -c 1 -r 48000 -t wav "${folder}/rec_audio.wav" \
#    ;
#  "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.wav" &&
#    mapfile -t lines <"${folder}/rec_audio.text" &&
#    { for line in "${lines[@]}"; do
#      echo type $line
#      echo key Enter
#    done; } | DOTOOL_XKB_LAYOUT=it dotool
#}

./command_builder.sh "$@"
result=$?

if [[ $result -ne 0 ]]; then
  exit $result
fi

read_command_builder_data_output

execute_action
