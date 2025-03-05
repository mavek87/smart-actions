#!/bin/bash

#set -x
echo "AUDIO TO TEXT"

#if [[ "$-" == *x* ]]; then
#    echo "AUDIO TO TEXT"
#fi

audio_to_text() {
    local input_file=""
    local language=""
    local model="medium"
    local task="transcribe"

    # Legge gli argomenti
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|-file|--file)
                shift
                input_file="$1"
                ;;
            -l|-language|--language)
                shift
                language="$1"
                ;;
            -m|-model|--model)
                shift
                model="$1"
                ;;
            -t|-task|--task)
                shift
                task="$1"
                ;;
            -h|-help|--help)
                shift
                help
                exit 1
                ;;
            *)
                echo "Error: unknown parameter ($1)!"
                return 1
                ;;
        esac
        shift
    done

    # Controllo input obbligatorio
    if [[ -z "$input_file" ]]; then
        echo "Error: you must pass the path of the audio file with the -f parameter"
        return 1
    fi

    # Costruisce il comando con gli argomenti opzionali
    local cmd="${folder}/faster-whisper --vad_method pyannote_v3 --device cuda --model $model --output_format text --task $task"

    # Aggiunge l'opzione lingua se specificata
    if [[ -n "$language" ]]; then
        cmd+=" --language $language"
    fi

    echo "cmd: $cmd"
    echo "file: $input_file"
    echo "model: $model"
    echo "language: $language"
    echo "task: $task"

#    # Esegue il comando
#    cp "$input_file" "${folder}/rec_audio.wav" \
#        && $cmd "${folder}/rec_audio.wav" \
#        && echo type "$(tr '\n' ' ' < "${folder}/rec_audio.text")" \
#        | DOTOOL_XKB_LAYOUT=it dotool
}

help() {
    echo "Usage: $0 audio-to-text -f <audio-file{.mp3|.wav|etc...}> (OPTIONAL) -m <fasterwhisper-model-name> {small|medium|etc...} (OPTIONAL) -l <language> (OPTIONAL) -t <task> {trascribe|translate}"
    echo
    echo "Examples:"
    echo "$0 audio_to_text -f /tmp/audio.wav"
    echo "$0 audio_to_text -f audio.mp3 -l en -m small"
}

if [ $# -eq 0 ]; then
    help
    exit 1
else
    audio_to_text "$@"
fi