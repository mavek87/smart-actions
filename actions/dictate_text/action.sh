#!/bin/bash
#Author: Matteo Veroni

# set -x

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SCRIPT_NAME="$(basename "$SCRIPT_DIR")"
export SMART_ACTIONS_CONFIG_FILE="${SCRIPT_DIR}/action.conf"

source "${SCRIPT_DIR}/../commons.sh"

execute_action() {
  echo "Execute: $SCRIPT_NAME"

  if [[ -n "$language" ]]; then
    eval "${NERD_DICTATATION_DIR}/nerd-dictation begin --vosk-model-dir=${NERD_DICTATATION_DIR}/model-${language} --pulse-device-name alsa_input.usb-GN_Netcom_A_S_Jabra_EVOLVE_LINK_MS_00004F9F0F5A09-00.mono-fallback"
  else
    faster_whisper_cmd="${FASTER_WHISPER_DIR}/faster-whisper --vad_method pyannote_v3 --device cuda --model ${model} --output_format text --task ${task}"
    # This is now impossible, if language is present nerd-dictataton is used
    if [[ -n "$language" ]]; then
      faster_whisper_cmd+=" --language $language"
    fi
    faster_whisper_cmd+=" ${FASTER_WHISPER_DIR}/rec_audio.mp3"

    # arecord -D "${audio_device}" -f cd -c 1 -r "${audio_sampling_rate}" "${FASTER_WHISPER_DIR}/rec_audio.wav"
    ffmpeg_cmd="ffmpeg -f alsa -i ${audio_device} -ac 1 -ar ${audio_sampling_rate} -codec:a libmp3lame -b:a 96k -y ${FASTER_WHISPER_DIR}/rec_audio.mp3"
    echo "Starting audio recording..."
    echo "ffmpeg command: $ffmpeg_cmd"
    eval "$ffmpeg_cmd"

    echo "Converting the recorded audio to text..."
    eval "$faster_whisper_cmd"

    echo "Writing the text..."
    mapfile -t lines <"${FASTER_WHISPER_DIR}/rec_audio.text" &&
      {
        for line in "${lines[@]}"; do
          # echo type "$line"
          # TODO: evaluate if typedelay and typehold should be dynamic values
          echo "typedelay 2
        typehold 2
        type $line"
          if [[ "$output_format" == "text" ]]; then
            echo key Enter
          elif [[ "$output_format" == "string" ]]; then
            echo key Space
          fi
        done
        if [[ "$output_terminator" != "none" ]]; then
          echo key "$output_terminator"
        fi
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
task="${CMD_ARGS["task"]}"
language="${CMD_ARGS["language"]}"
audio_device="${CMD_ARGS["audio_device"]}"
audio_sampling_rate="${CMD_ARGS["audio_sampling_rate"]}"
output_format="${CMD_ARGS["output_format"]}"
output_terminator="${CMD_ARGS["output_terminator"]}"

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

validate_supported_value "output_terminator" "$output_terminator" "none" "enter"
validate_supported_value "output_format" "$output_format" "text" "string"

execute_action
