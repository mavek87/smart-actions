#!/bin/bash

folder="/opt/FasterWhisper"

audio_file_to_text() {
    echo "CONVERT AUDIO FILE TO TEXT"

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
#
#&& printf 'type %s\nkey Enter\n' "${lines[@]}" | DOTOOL_XKB_LAYOUT=it dotool
dictate_text() {
    echo "DICTATE TEXT"

    echo "Starting audio recording and transcription..."
    arecord -D hw:3,0 -f cd -c 1 -r 48000 -t wav "${folder}/rec_audio.wav" \
           ; "${folder}/faster-whisper" --vad_method pyannote_v3 --device cuda --model medium --output_format text --task transcribe "${folder}/rec_audio.wav" \
	   && mapfile -t lines < "${folder}/rec_audio.text" \
           && {     for line in "${lines[@]}"; do         echo type $line;         echo key Enter;     done; } | DOTOOL_XKB_LAYOUT=it dotool
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
	   && {     for line in "${lines[@]}"; do         echo type $line;         echo key Enter;     done; } | DOTOOL_XKB_LAYOUT=it dotool
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
	   && {     for line in "${lines[@]}"; do         echo type "$line";         echo key Enter;     done; } | DOTOOL_XKB_LAYOUT=it dotool
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
           && {     for line in "${lines[@]}"; do         echo type "$line";         echo key Enter;     done; } | DOTOOL_XKB_LAYOUT=it dotool
}


# Funzione per fermare eventuali processi (placeholder, da implementare)
end() {
    echo "Stopping the process..."
    pkill -f "arecord"  # Uccide il processo di registrazione (se in esecuzione)
}

help() {
    echo "Usage: $0 {start|stop|help}"
    echo
    echo "audio_file_to_text - Convert an audio file to text."
    echo "dictate_text - Record an audio and convert it to text"
    echo "dictate_command - Record an audio and convert it into a text line terminated by the enter key (command)."
    echo "ai_reply_text - Record an audio question and provide a text response generated by an AI."
    echo "ai_reply_text_for_selection - Record an audio question about a selected text and provide a text response generated by an AI."
    echo "ai_reply_text_for_copy - Record an audio question about a text present in the clipboard (copied text) and provide a text response generated by an AI."
    echo "ai_reply_terminal - Record an audio question and provide a text response in the terminal."
    echo "end - Stop the recording and ongoing processes."
    echo "help - Show this help message."
    echo
    echo "Examples:"
    echo "./smart-action.sh dictate_text - Start audio recording and convert it to text (stop the recording with CTRL+C or end)."
    echo "./smart-action.sh end - Stop the recording if it's in progress."
}

# Controllo dei parametri passati allo script
case "$1" in
    audio_file_to_text)
        audio_file_to_text
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
