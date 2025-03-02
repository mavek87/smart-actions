#!/bin/bash

folder="$HOME/FasterWhisper"

convert_audio_to_text() {
    echo "CONVERT AUDIO TO TEXT"

    "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.mp4" \
           && echo type "$(tr '\n' ' ' < "${folder}/rec_audio.text")" \
           | DOTOOL_XKB_LAYOUT=it dotool \
           && echo key Enter \
           | DOTOOL_XKB_LAYOUT=it dotool
}

dictate_command() {
    echo "DICTATE COMMAND"

    echo "Starting audio recording and transcription..."
    arecord -D hw:3,0 -f cd -c 1 -r 48000 -t wav "${folder}/rec_audio.wav" \
           ; "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.wav" \
           && echo type "$(tr '\n' ' ' < "${folder}/rec_audio.text")" \
           | DOTOOL_XKB_LAYOUT=it dotool \
           && echo key Enter \
           | DOTOOL_XKB_LAYOUT=it dotool
}

#&& while IFS= read -r line; do
#	echo type "$line" | DOTOOL_XKB_LAYOUT=it dotool
#        echo key Enter | DOTOOL_XKB_LAYOUT=it dotool
#done < "${folder}/rec_audio.text"
dictate_text() {
    echo "DICTATE TEXT"

    echo "Starting audio recording and transcription..."
    arecord -D hw:3,0 -f cd -c 1 -r 48000 -t wav "${folder}/rec_audio.wav" \
           ; "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.wav" \
	   && mapfile -t lines < "${folder}/rec_audio.text" \
           && printf 'type %s\nkey Enter\n' "${lines[@]}" | DOTOOL_XKB_LAYOUT=it dotool
}

ai_reply_terminal() {
    echo "AI REPLY TERMINAL"

    echo "Starting audio recording and transcription..."
    arecord -D hw:3,0 -f cd -c 1 -r 48000 -t wav "${folder}/rec_audio.wav" \
           ; "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.wav" \
           && echo "$(tr '\n' ' ' < "${folder}/rec_audio.text")" \
	   && tgpt -q "$(cat "${folder}/rec_audio.text")"
}

#&& while IFS= read -r line; do
#	echo type "$line" | DOTOOL_XKB_LAYOUT=it dotool
#	 echo key Enter | DOTOOL_XKB_LAYOUT=it dotool
#done < "${folder}/ai_reply.txt"
#
#{     for line in "${lines[@]}"; do         echo type $line;         echo key Enter;     done; } | DOTOOL_XKB_LAYOUT=it dotool
#
#
#
#questo non funziona bene:
#&& printf 'type %s\nkey Enter\n' "${lines[@]}" | DOTOOL_XKB_LAYOUT=it dotoo
#
ai_reply_text(){
    echo "AI REPLY TEXT"

    echo "Starting audio recording..."
    arecord -D hw:3,0 -f cd -c 1 -r 48000 -t wav "${folder}/rec_audio.wav" \
           ; "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.wav" \
           && echo "$(tr '\n' ' ' < "${folder}/rec_audio.text")" \
	   && tgpt -q "$(cat "${folder}/rec_audio.text")" > "${folder}/ai_reply.txt" \
           && sed -i 's/\r//' "${folder}/ai_reply.txt" \
	   && mapfile -t lines < "${folder}/ai_reply.txt" \
	   && {     for line in "${lines[@]}"; do         echo type $line;         echo key Enter;     done; } | dotool
}


# KP_Enter
#
# && {     for line in "${lines[@]}"; do         echo type $line;         echo key Enter;     done; } | DOTOOL_XKB_LAYOUT=it dotool
ai_reply_text_for_selection() {
	echo "AI REPLY TEXT FOR SELECTION"

	echo "Starting audio recording..."
    arecord -D hw:3,0 -f cd -c 1 -r 48000 -t wav "${folder}/rec_audio.wav" \
           ; "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.wav" \
           && echo "$(tr '\n' ' ' < "${folder}/rec_audio.text")" \
	   && tgpt -q -preprompt "$(xclip -selection primary -o)" "$(cat "${folder}/rec_audio.text")" > "${folder}/ai_reply.txt" \
	   && sed -i 's/\r//' "${folder}/ai_reply.txt" \
           && mapfile -t lines < "${folder}/ai_reply.txt" \
	   && {     for line in "${lines[@]}"; do         echo type "$line";         echo key Enter;     done; } | dotool
}

ai_reply_text_for_copy() {
        echo "AI REPLY TEXT FOR COPY"

        echo "Starting audio recording..."
    arecord -D hw:3,0 -f cd -c 1 -r 48000 -t wav "${folder}/rec_audio.wav" \
           ; "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.wav" \
           && echo "$(tr '\n' ' ' < "${folder}/rec_audio.text")" \
           && tgpt -q -preprompt "$(xclip -selection clipboard -o)" "$(cat "${folder}/rec_audio.text")" > "${folder}/ai_reply.txt" \
           && sed -i 's/\r//' "${folder}/ai_reply.txt" \
           && mapfile -t lines < "${folder}/ai_reply.txt" \
           && {     for line in "${lines[@]}"; do         echo type "$line";         echo key Enter;     done; } | dotool
}


# Funzione per fermare eventuali processi (placeholder, da implementare)
end() {
    echo "Stopping the process..."
    pkill -f "arecord"  # Uccide il processo di registrazione (se in esecuzione)
}

# Funzione per mostrare l'aiuto
help() {
    echo "Usage: $0 {start|stop|help}"
    echo
    echo "start     - Avvia la registrazione audio e la trascrizione."
    echo "end      - Ferma la registrazione e i processi in corso."
    echo "help      - Mostra questo messaggio di aiuto."
    echo
    echo "Esempi:"
    echo "./ai-command.sh start  - Avvia la registrazione e la trascrizione."
    echo "./ai-command.sh end   - Ferma la registrazione, se in corso."
}

# Controllo dei parametri passati allo script
case "$1" in
    convert_audio_to_text)
        convert_audio_to_text
	;;
    dictate_text)
	dictate_text
	;;
    dictate_command)
        dictate_command
        ;;
    ai_reply_text)
	ai_reply_text
	;;
    ai_reply_text_for_selection)
	ai_reply_text_for_selection
	;;
    ai_reply_text_for_copy)
	ai_reply_text_for_copy
    	;;
    ai_reply_terminal)
	ai_reply_terminal
	;;
    end)
        end
        ;;
    help)
        help
        ;;
    *)
        help  # Se il parametro è invalido, mostra l'aiuto
        exit 1
        ;;
esac
