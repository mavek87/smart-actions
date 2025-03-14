# Smart Actions

Project to perform several actions like vocal dictation, vocal query to AI chatbot, etc..

## Installation

### 1) Faster Whisper

https://github.com/Purfview/whisper-standalone-win/releases

```bash
curl https://github.com/Purfview/whisper-standalone-win/releases/download/Faster-Whisper-XXL/Faster-Whisper-XXL_r245.2_linux.7z 
```

In the future maybe also Whisper.cpp could be supported:

https://github.com/ggerganov/whisper.cpp

but this is not being used yet in the scripts

### 2) Arecord

```bash
sudo apt install alsa-utils
```

### 3) Dotool

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

### 4) TGPT

https://github.com/aandrew-me/tgpt

```bash
curl -sSL https://raw.githubusercontent.com/aandrew-me/tgpt/main/install | bash -s /usr/local/bin
```

## Roadmap

- solve all the todos...
- passing tgpt models
- smart action generate image to clipboard

## Useful commands

convert mp3 to wav:
```bash
ffmpeg -i input.mp3 -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

## Author

Matteo Veroni

---------------

TORNA TUTTE I DISPOSITIVI AUDIO:
arecord -l | grep -P '^\w+\s\d+: ' | sed 's/^[^:]*: \([^,]*\).*/\1/'