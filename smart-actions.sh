#!/bin/bash
#Author: Matteo Veroni

SMART_ACTIONS_SCRIPT_NAME=$(basename "$0")
export SMART_ACTIONS_SCRIPT_NAME
SMART_ACTIONS_PROJECT_DIR="$(dirname "$(realpath "$0")")"
export SMART_ACTIONS_PROJECT_DIR

source "$SMART_ACTIONS_PROJECT_DIR/settings.conf"
AUDIO_CONFIG_FILE="$SMART_ACTIONS_PROJECT_DIR/audio.conf"

UUID=$(uuidgen)
export SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE="/tmp/smart_actions_command_builder_output_file_${UUID}"

export SMART_ACTIONS_COLOR_RED="\e[31m"
export SMART_ACTIONS_COLOR_GREEN="\e[32m"
export SMART_ACTIONS_COLOR_YELLOW="\e[33m"
export SMART_ACTIONS_COLOR_BLUE="\e[34m"
export SMART_ACTIONS_COLOR_RESET="\e[0m"

# Dynamic function to invoke the action scripts
invoke_action() {
  action_name="${FUNCNAME[1]}" # Ottieni il nome della funzione chiamante
  action_script="${SMART_ACTIONS_PROJECT_DIR}/actions/${action_name}/action.sh"

  # Verify if the action script exists
  if [[ -f "$action_script" ]]; then
    "$action_script" "$@" # Pass the arguments to the command
  else
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: Script for action '$action_name' does not exist${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi
}

# TODO: this is valid only for commands which record audio, not for the others (eg. audio_to_text)
end() {
  echo "Stopping the process..."
  # pkill -f "arecord"
  sleep 0.5
  pkill -f "ffmpeg"
  eval "${NERD_DICTATATION_DIR}/nerd-dictation end"
}

end_output_audio_vocal() {
  echo "Stopping the process..."
  pkill -f "piper"
}

# Used to read the audio devices from the system using arecord (and populating the ./audio.conf file)
#
# OUTPUT EXAMPLE:
#   Yeti Nano (plughw:1,0)
#   HD-Audio Generic (plughw:2,0)
#   HD-Audio Generic (plughw:2,2)
#   Jabra EVOLVE LINK MS (plughw:3,0)
#   HD Pro Webcam C920 (plughw:4,0)
read_audio_devices() {
  mapfile -t devices < <(LANG=C arecord -l | awk '
    /^card [0-9]+:/ {
      card_num = $2; sub(/:$/, "", card_num)
      match($0, /\[[^]]*\]/)
      card_name = substr($0, RSTART+1, RLENGTH-2)
      line = $0
      while (match(line, /device [0-9]+:/)) {
        dev_str = substr(line, RSTART, RLENGTH)
        split(dev_str, parts, " ")
        device_num = parts[2]
        sub(/:$/, "", device_num)
        print card_name " (plughw:" card_num "," device_num ")"
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ')
}

show_audio_devices() {
  local selected_device=""
  [[ -f "$AUDIO_CONFIG_FILE" ]] && selected_device=$(<"$AUDIO_CONFIG_FILE")

  echo "Available audio devices:"
  for i in "${!devices[@]}"; do
    local marker=" "
    if [[ "${devices[i]}" == "$selected_device" ]]; then
      marker="*"
    fi
    printf "  %d) %s %s\n" "$i" "${devices[i]}" "$marker"
  done
}

select_default_audio_device() {
  while true; do
    show_audio_devices
    echo
    read -rp "Insert the audio device number to select it (or 'q' to quit): " choice
    if [[ "$choice" == "q" ]]; then
      echo "Quit without selecting a device."
      exit 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 0 && choice < ${#devices[@]} )); then
      echo "${devices[choice]}" > "$AUDIO_CONFIG_FILE"
      echo "Selected audio device: ${devices[choice]} *"
      break
    else
      echo "Input not valid. Please retry."
    fi
  done
}

read_audio_devices

help() {
  echo
  echo -e "${SMART_ACTIONS_COLOR_BLUE}Usage:${SMART_ACTIONS_COLOR_RESET} $0 {action_name|end|help}"
  echo
  echo -e "${SMART_ACTIONS_COLOR_BLUE}Available actions:${SMART_ACTIONS_COLOR_RESET}"

  for action_dir in "$SMART_ACTIONS_PROJECT_DIR/actions"/*/; do
    action_name=$(basename "$action_dir")
    action_conf="$action_dir/action.conf"

    if [[ -f "$action_conf" ]]; then
      # Legge la descrizione dal file action.conf
      action_description=$(grep '^DESCRIPTION=' "$action_conf" | cut -d '=' -f2- | tr -d '"')
    else
      action_description="No description available."
    fi

    echo "  $action_name - $action_description"
  done
  echo
  echo -e "${SMART_ACTIONS_COLOR_BLUE}Other commands:${SMART_ACTIONS_COLOR_RESET}"
  echo "  end - Stop the recording and ongoing processes."
  echo "  end_output_audio_vocal - Stop the output audio vocal."
  echo "  show_audio_devices - Show all the available audio devices."
  echo "  select_default_audio_device - Select the default audio device."
  echo "  print_settings - Print the smart actions script settings."
  echo "  help - Show this help message."
  echo
  echo -e "${SMART_ACTIONS_COLOR_GREEN}Examples:${SMART_ACTIONS_COLOR_RESET}"
  echo "  ./${SMART_ACTIONS_SCRIPT_NAME} dictate_text - Start audio recording and convert it to text (stop the recording with CTRL+C or end)."
  echo "  ./${SMART_ACTIONS_SCRIPT_NAME} end"
  echo "  ./${SMART_ACTIONS_SCRIPT_NAME} end_output_audio_vocal"
  echo "  ./${SMART_ACTIONS_SCRIPT_NAME} show_audio_devices"
  echo "  ./${SMART_ACTIONS_SCRIPT_NAME} select_default_audio_device"
  echo "  ./${SMART_ACTIONS_SCRIPT_NAME} audio_to_text -f /home/file.wav"
  exit 1
}

print_settings () {
   echo ""
   echo "Smart actions project dir: $SMART_ACTIONS_PROJECT_DIR"
   echo "Faster whisper dir: $FASTER_WHISPER_DIR"
   echo "Nerd dictation dir: $NERD_DICTATATION_DIR"
   echo "Piper dir: $PIPER_DIR"
   echo ""
}

mkdir -p /tmp
touch "$SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE"

# Cycle which explores the actions folders and creates the functions dinamically
for action_dir in "$SMART_ACTIONS_PROJECT_DIR/actions"/*/; do
  # Extract the name of the action directory (remove the trailing '/')
  action_name=$(basename "$action_dir")
  # echo $action_name

  # Create a function for each folder in actions
  eval "
    $action_name() {
      invoke_action \"\$@\"
    }
  "
done

case "$1" in
help | -h | --help)
  help
  ;;
print_settings | -ps | --print_settings)
  print_settings
  ;;
end | -e | --end)
  end
  ;;
end_output_audio_vocal | -ev | --end_output_audio_vocal)
  end_output_audio_vocal
  ;;
*)
  if declare -f "$1" >/dev/null; then
    action="$1"
    shift
    "$action" "$@"
    # Exit using the invoked action exit code (0 ok, otherwise error)
    exit $?
  else
    if [[ -z "$(echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" ]]; then
      help
    else
      echo -e "${SMART_ACTIONS_COLOR_RED}Error: Unknown command '$1'${SMART_ACTIONS_COLOR_RESET}"
      help
    fi
  fi
  ;;
esac

unset SMART_ACTIONS_PROJECT_DIR
unset FASTER_WHISPER_DIR
unset NERD_DICTATATION_DIR
unset PIPER_DIR

unset SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE

unset SMART_ACTIONS_COLOR_RED
unset SMART_ACTIONS_COLOR_GREEN
unset SMART_ACTIONS_COLOR_YELLOW
unset SMART_ACTIONS_COLOR_BLUE
unset SMART_ACTIONS_COLOR_RESET
