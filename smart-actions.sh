#!/bin/bash
#Author: Matteo Veroni

SMART_ACTIONS_PROJECT_DIR=$(dirname "$0")
echo "Smart actions project dir: $SMART_ACTIONS_PROJECT_DIR"
export SMART_ACTIONS_PROJECT_DIR

source "$SMART_ACTIONS_PROJECT_DIR/settings.conf"

echo "Faster whisper dir: $FASTER_WHISPER_DIR"
echo "Nerd dictation dir: $NERD_DICTATATION_DIR"
echo "Piper dir: $PIPER_DIR"
echo ""

export SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE=/tmp/smart_actions_command_builder_output_file

export SMART_ACTIONS_COLOR_RED="\e[31m"
export SMART_ACTIONS_COLOR_GREEN="\e[32m"
export SMART_ACTIONS_COLOR_YELLOW="\e[33m"
export SMART_ACTIONS_COLOR_BLUE="\e[34m"
export SMART_ACTIONS_COLOR_RESET="\e[0m"

# Funzione dinamica per invocare gli script
invoke_action() {
  action_name="${FUNCNAME[1]}" # Ottieni il nome della funzione chiamante
  action_script="${SMART_ACTIONS_PROJECT_DIR}/actions/${action_name}/action.sh"

  # Verifica se lo script esiste
  if [[ -f "$action_script" ]]; then
    "$action_script" "$@" # Passa gli argomenti al comando
  else
    echo -e "${SMART_ACTIONS_COLOR_RED}Error: Script for action '$action_name' does not exist${SMART_ACTIONS_COLOR_RESET}"
    exit 1
  fi
}

# Ciclo che esplora la cartella actions e crea le funzioni dinamicamente
for action_dir in "$SMART_ACTIONS_PROJECT_DIR/actions"/*/; do
  # Estrai il nome della cartella (rimuovi la parte finale '/')
  action_name=$(basename "$action_dir")
  # echo $action_name

  # Crea una funzione per ogni cartella in actions
  eval "
    $action_name() {
      invoke_action \"\$@\"
    }
  "
done

# TODO: this is valid only for commands which record audio, not for the others (eg. audio_to_text)
end() {
  echo "Stopping the process..."
  # pkill -f "arecord"
  pkill -f "ffmpeg"
}

end_output_audio_vocal() {
  echo "Stopping the process..."
    pkill -f "piper"
}

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
  echo "  end_output_audio_vocal - Stop the output audio vocal"
  echo "  help - Show this help message."
  echo
  echo -e "${SMART_ACTIONS_COLOR_GREEN}Examples:${SMART_ACTIONS_COLOR_RESET}"
  echo "  ./smart-actions.sh dictate_text - Start audio recording and convert it to text (stop the recording with CTRL+C or end)."
  echo "  ./smart-actions.sh end"
  echo "  ./smart-actions.sh end_output_audio_vocal"
  echo "  ./smart-actions.sh audio_to_text -f /home/file.wav"
  exit 1
}

mkdir -p /tmp
touch "$SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE"

case "$1" in
help | -h | --help)
  help
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