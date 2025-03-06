#!/bin/bash
#Author: Matteo Veroni

export SMART_ACTIONS_PROJECT_DIR="/opt/FasterWhisper"
export SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE=/tmp/smart_actions_command_builder_output_file

# Funzione dinamica per invocare gli script
invoke_action() {
  action_name="${FUNCNAME[1]}" # Ottieni il nome della funzione chiamante
  action_script="${SMART_ACTIONS_PROJECT_DIR}/actions/${action_name}/action.sh"

  # Verifica se lo script esiste
  if [[ -f "$action_script" ]]; then
    "$action_script" "$@" # Passa gli argomenti al comando
  else
    echo "Error: Script for action '$action_name' does not exist!"
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
  pkill -f "arecord" # Uccide il processo di registrazione (se in esecuzione)
}

help() {
  echo
  echo "Usage: $0 {action_name|end|help}"
  echo
  echo "Available actions:"

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
  echo "Other commands:"
  echo "  end - Stop the recording and ongoing processes."
  echo "  help - Show this help message."
  echo
  echo "Examples:"
  echo "  ./smart-actions.sh dictate_text - Start audio recording and convert it to text (stop the recording with CTRL+C or end)."
  echo "  ./smart-actions.sh end - Stop the recording if it's in progress."
  echo "  ./smart-actions.sh audio_to_text -f /home/file.wav"
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
*)
  if declare -f "$1" >/dev/null; then
    action="$1"
    shift
    "$action" "$@"
  else
    if [[ -z "$(echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" ]]; then
      help
      exit 1
    else
      echo "Error: Unknown command '$1'"
      help
      exit 1
    fi
  fi
  ;;
esac

unset $SMART_ACTIONS_COMMAND_BUILDER_OUTPUT_FILE