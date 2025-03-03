# Smart Actions

Project to perform several actions like vocal dictation, vocal query to AI chatbot, etc..

## Installation

### 1) Faster Whisper

https://github.com/Purfview/whisper-standalone-win/releases

```bash
curl https://github.com/Purfview/whisper-standalone-win/releases/download/Faster-Whisper-XXL/Faster-Whisper-XXL_r245.2_linux.7z 
```

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
