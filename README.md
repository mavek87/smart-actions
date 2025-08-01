# Smart Actions

Project to perform several actions like vocal dictation, vocal query to AI chatbot, etc..

## Installation

### 1) Faster Whisper (Speech to text)

https://github.com/Purfview/whisper-standalone-win/releases

```bash
curl https://github.com/Purfview/whisper-standalone-win/releases/download/Faster-Whisper-XXL/Faster-Whisper-XXL_r245.2_linux.7z 
```

Fix:

```bash
sudo apt install patchelf
patchelf --clear-execstack /opt/FasterWhisper/_xxl_data/ctranslate2.libs/libctranslate2-d3638643.so.4.4.0
```

In the future maybe also **Whisper.cpp** could be supported:

https://github.com/ggerganov/whisper.cpp

but this is not being used yet in the scripts

### 2) NerdDictation (Dictation)

https://github.com/ideasman42/nerd-dictation

### Issues

https://github.com/ideasman42/nerd-dictation/issues/20

### 3) FFMPEG

```bash
sudo apt install ffmpeg
```

### 4) Dotool

https://sr.ht/~geb/dotool/

```bash
git clone https://git.sr.ht/~geb/dotool

cd dotool

sudo apt install golang libxkbcommon-dev scdoc -y

./build.sh && sudo ./build.sh install

sudo udevadm control --reload && sudo udevadm trigger

groupadd -f input

usermod -a -G input $USER

sudo reboot
```

### 5) TGPT (AI in terminal)

https://github.com/aandrew-me/tgpt

```bash
curl -sSL https://raw.githubusercontent.com/aandrew-me/tgpt/main/install | bash -s /usr/local/bin
```

### setup with ollama:

```bash
tgpt --provider openai --url "http://localhost:11434/v1/chat/completions" --model "llama3:latest" "hi how are you?"
```

(export the arguments in .bashrc to avoid typing them every time:)

### 6) Piper (Text to speech)

https://github.com/rhasspy/piper

## Roadmap

- audio_to_text needs a destination (output_file/display)
- solve all the todos...
- smart action generate image to clipboard

## Useful commands

### record an audio file:

```bash
ffmpeg -f alsa -i default -y output.wav
ffmpeg -f alsa -i hw:3,0 output.wav
ffmpeg -f alsa -i plughw:3,0 output.wav
```

alternative:

```bash
  arecord -D hw:3,0 -f cd -c 1 -r 44000 output.wav
```

### play an audio file

```bash
ffplay -v 0 -nodisp -autoexit dictate-text-on.mp3
```

alternative:

```bash
aplay audio.wav
```

### convert mp3 to wav:

```bash
ffmpeg -i input.mp3 -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

### run whisper.cpp

```bash
./build/bin/whisper-cli -f output.wav -m models/ggml-medium.bin -l auto
```

## Author

Matteo Veroni