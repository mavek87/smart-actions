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

  if [[ "${output_audio_voice}" != "true" && "${output_audio_voice}" != "false" ]]; then
    # TODO is it ok? No complete help print...
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: output target '$output_audio_voice' does not exist${SMART_ACTIONS_COLOR_RESET}"
    echo -e "${SMART_ACTIONS_COLOR_RED}The possible values are: 'true', 'false'${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi

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

  if [[ "$output_format" != "text" && "$output_format" != "string" && "$output_format" != "code_string" && "$output_format" != "code_text" ]]; then
    # TODO is it ok? No complete help print...
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: output format '$output_format' does not exist${SMART_ACTIONS_COLOR_RESET}"
    echo -e "${SMART_ACTIONS_COLOR_RED}The possible values are: 'text', 'string', 'code_string', 'code_text'${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi

  tgpt_quiet_param="-q"
  tgpt_output_format=""
  if [[ "$output_format" == "text" ]]; then
    tgpt_output_format="-w"
  elif [[ "$output_format" == "code_string" || "$output_format" == "code_text" ]]; then
    tgpt_output_format="-c"
    tgpt_quiet_param="" # no quiet -q for code otherwhise the code doesn't work...
  fi

  OUTPUT_DIR=""
  if [[ -n "$language" ]]; then
    OUTPUT_DIR="${NERD_DICTATATION_DIR}"

    eval "${NERD_DICTATATION_DIR}/nerd-dictation begin --vosk-model-dir=${NERD_DICTATATION_DIR}/model-${language} --output STDOUT > ${OUTPUT_DIR}/rec_audio.text"
  else
    OUTPUT_DIR="${FASTER_WHISPER_DIR}"

    faster_whisper_cmd="${FASTER_WHISPER_DIR}/faster-whisper --vad_method pyannote_v3 --device cuda --model ${model} --output_format text --task ${task}"
    if [[ -n "$language" ]]; then
      faster_whisper_cmd+=" --language $language"
    fi
    faster_whisper_cmd+=" ${FASTER_WHISPER_DIR}/rec_audio.mp3"

    echo "Starting audio recording..."
    #  arecord -D "${audio_device}" -f cd -c 1 -r "${audio_sampling_rate}" "${FASTER_WHISPER_DIR}/rec_audio.wav"
    ffmpeg -f alsa -i "${audio_device}" -ac 1 -ar "${audio_sampling_rate}" -codec:a libmp3lame -b:a 96k -y "${FASTER_WHISPER_DIR}/rec_audio.mp3"

    eval "$faster_whisper_cmd"
  fi

  echo "The AI is elaborating a response..."
  pre_prompt=""
  {
    if [[ "$selection_target" != "none" ]]; then
      pre_prompt="$(xclip -selection "${selection_target}" -o)"
    fi
  }
  if [[ "$output_destination" == "terminal" ]]; then
    echo "$(tr '\n' ' ' <"${OUTPUT_DIR}/rec_audio.text")" &&
      # Note: dont use "" on $tgpt_quiet_param and $tgpt_output_format otherwise it wont work
      tgpt $tgpt_quiet_param $tgpt_output_format --provider "$ai_provider" -preprompt "$pre_prompt" "$(cat "${OUTPUT_DIR}/rec_audio.text")"

  elif [[ "$output_destination" == "display" ]]; then
    # Note: dont use "" on $tgpt_quiet_param and $tgpt_output_format otherwise it wont work
    tgpt $tgpt_quiet_param $tgpt_output_format --provider "$ai_provider" -preprompt "$pre_prompt" "$(cat "${OUTPUT_DIR}/rec_audio.text")" >"${OUTPUT_DIR}/reply_ai.txt"
    sed -i 's/\r//' "${OUTPUT_DIR}/reply_ai.txt" # Remove \r characters

    if [[ "$output_audio_voice" == "true" ]]; then
      (
        if [[ -n "$language" ]]; then
          PIPER_LANG="${language}"
        else
          PIPER_LANG="en" # default language is english
        fi

        PIPER_MODEL_FOR_LANGUAGE=$(eval "ls ${PIPER_DIR} | grep '^${PIPER_LANG}.*\.onnx$' | head -n 1")

        if [[ $PIPER_MODEL_FOR_LANGUAGE != "" ]]; then
          sed 's/[*#]//g' "${OUTPUT_DIR}/reply_ai.txt" >"${OUTPUT_DIR}/reply_ai_audio.txt" # Remove * and # characters
          cat "${OUTPUT_DIR}/reply_ai_audio.txt" | "${PIPER_DIR}/piper" --model "${PIPER_DIR}/${PIPER_MODEL_FOR_LANGUAGE}" --output-raw | ffmpeg -f s16le -ar 22050 -ac 1 -i - -f alsa default
        else
          echo "Error: No ONNX Piper model found for language '$PIPER_MODEL_FOR_LANGUAGE' in piper folder $PIPER_DIR"
        fi
      ) &
    fi

    mapfile -t lines <"${OUTPUT_DIR}/reply_ai.txt" &&
      {
        for line in "${lines[@]}"; do
          # echo type "$line"
          # TODO: evaluate if typedelay and typehold should be dynamic values
          echo "typedelay 2
                    typehold 2
                    type $line"
          if [[ "$output_format" == "text" || "$output_format" == "code_text" ]]; then
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

load_args_from_built_command

model="${CMD_ARGS["model"]}"
ai_provider="${CMD_ARGS["ai_provider"]}"
task="${CMD_ARGS["task"]}"
language="${CMD_ARGS["language"]}"
audio_device="${CMD_ARGS["audio_device"]}"
audio_sampling_rate="${CMD_ARGS["audio_sampling_rate"]}"
selection_target="${CMD_ARGS["selection_target"]}"
output_destination="${CMD_ARGS["output_destination"]}"
output_format="${CMD_ARGS["output_format"]}"
output_audio_voice="${CMD_ARGS["output_audio_voice"]}"

execute_action