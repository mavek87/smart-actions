#!/bin/bash
#Author: Matteo Veroni

# set -x

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SCRIPT_NAME="$(basename "$SCRIPT_DIR")"
export SMART_ACTIONS_CONFIG_FILE="${SCRIPT_DIR}/action.conf"

source "${SCRIPT_DIR}/../commons.sh"

execute_action() {
  echo "Execute: $SCRIPT_NAME"

  #
  # Using nerd-dictation (if the language is chosen) or faster-whisper (auto-detects the language) to convert audio to text
  #
  OUTPUT_DIR=""
  if [[ -n "$language" ]]; then
    OUTPUT_DIR="${NERD_DICTATATION_DIR}"
#    nerd_dictate_cmd="${NERD_DICTATATION_DIR}/nerd-dictation begin --vosk-model-dir=${NERD_DICTATATION_DIR}/model-${language} --pulse-device-name alsa_input.usb-GN_Netcom_A_S_Jabra_EVOLVE_LINK_MS_00004F9F0F5A09-00.mono-fallback --output STDOUT > ${OUTPUT_DIR}/rec_audio.text"
    nerd_dictate_cmd="${NERD_DICTATATION_DIR}/nerd-dictation begin --vosk-model-dir=${NERD_DICTATATION_DIR}/model-${language} --output STDOUT > ${OUTPUT_DIR}/rec_audio.text"
    echo "executing: ${nerd_dictate_cmd}. Use the end command to stop it."
    eval "${nerd_dictate_cmd}"
  else
    OUTPUT_DIR="${FASTER_WHISPER_DIR}"

    faster_whisper_cmd="${FASTER_WHISPER_DIR}/faster-whisper --vad_method pyannote_v3 --device cuda --model ${model} --output_format text --task ${task}"
    if [[ -n "$language" ]]; then
      faster_whisper_cmd+=" --language $language"
    fi
    faster_whisper_cmd+=" ${FASTER_WHISPER_DIR}/rec_audio.mp3"

    # arecord -D "${audio_device}" -f cd -c 1 -r "${audio_sampling_rate}" "${FASTER_WHISPER_DIR}/rec_audio.wav"
    ffmpeg_cmd="ffmpeg -f alsa -i ${audio_device} -ac 1 -ar ${audio_sampling_rate} -codec:a libmp3lame -b:a 96k -y ${FASTER_WHISPER_DIR}/rec_audio.mp3"
    echo "Starting audio recording..."
    echo "ffmpeg command: $ffmpeg_cmd"
    eval "$ffmpeg_cmd"

    eval "$faster_whisper_cmd"
  fi

  #
  # Preparing tgpt to extract the text from the audio and send it to the AI provider
  #
  tgpt_quiet_param="-q"
  tgpt_output_format=""
  if [[ "$output_format" == "text" ]]; then
    tgpt_output_format="-w"
  elif [[ "$output_format" == "code_string" || "$output_format" == "code_text" ]]; then
    tgpt_output_format="-c"
    tgpt_quiet_param="" # no quiet -q for code otherwise the code doesn't work...
  fi

  pre_prompt=""
  {
    if [[ "$selection_target" != "none" ]]; then
      pre_prompt="$(xclip -selection "${selection_target}" -o)"
    fi
  }

  tgpt_cmd="tgpt $tgpt_quiet_param $tgpt_output_format --provider \"$ai_provider\""
  if [[ -n "$pre_prompt" ]]; then
    tgpt_cmd+=" --preprompt \"$pre_prompt\""
  fi
  if [[ -n "$model" ]]; then
    tgpt_cmd+=" --model \"$model\""
  fi
  if [[ -n "$url" ]]; then
    tgpt_cmd+=" --url \"$url\""
  fi
  tgpt_cmd+=" \"$(cat "${OUTPUT_DIR}/rec_audio.text")\""

  #
  # Executing tgpt, then printing the AI response output in the terminal or displaying it on screen
  #
  if [[ "$output_destination" == "terminal" ]]; then
    echo "$(tr '\n' ' ' <"${OUTPUT_DIR}/rec_audio.text")"
    echo "Executing: $tgpt_cmd"
    eval "$tgpt_cmd"
    echo "The AI is elaborating a response..."

  elif [[ "$output_destination" == "display" ]]; then
    # Note: dont use "" on $tgpt_quiet_param and $tgpt_output_format otherwise it wont work
    tgpt_cmd+=" \"$(cat "${OUTPUT_DIR}/rec_audio.text")\""
    echo "Executing: $tgpt_cmd"
    eval "$tgpt_cmd" > "${OUTPUT_DIR}/reply_ai.txt"
    echo "The AI is elaborating a response..."

    sed -i 's/\r//' "${OUTPUT_DIR}/reply_ai.txt" # Remove \r characters

    #
    # If the audio output is enabled, use piper to convert the text to audio
    #
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

url="${CMD_ARGS["url"]}"
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

if [[ "${ai_provider}" == "ollama" ]]; then
  ai_provider="openai"
fi

# duplicated code
if [[ -z "${audio_device}" || "${audio_device}" == "default" ]]; then
  if [[ -f "$AUDIO_CONFIG_FILE" ]]; then
    audio_device=$(<"$AUDIO_CONFIG_FILE")

    audio_device_extracted=$(echo "$audio_device" | sed -n 's/.*(\([^)]*\)).*/\1/p')

    audio_device_extracted="${audio_device_extracted#"${audio_device_extracted%%[![:space:]]*}"}"
    audio_device_extracted="${audio_device_extracted%"${audio_device_extracted##*[![:space:]]}"}"

    if [[ -z "${audio_device_extracted}" ]]; then
      audio_device="default"
    else
      audio_device="$audio_device_extracted"
    fi

    echo "Using default audio device from config: $audio_device"
  else
    echo "No audio device specified and no default device found."
  fi
else
  echo "Using audio device passed as parameter: $audio_device"
fi

validate_supported_value "output_audio_voice" "$output_audio_voice" "true" "false"
validate_supported_value "ai_provider" "$ai_provider" "openai" "duckduckgo" "phind" "ollama" "pollinations"
validate_supported_value "output_destination" "$output_destination" "terminal" "display"
validate_supported_value "output_format" "$output_format" "text" "string" "code_string" "code_text"

execute_action