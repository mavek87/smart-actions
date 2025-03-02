#!/bin/bash

echo -e "\033[1;32m"
echo
echo "      8\"\"\"\"                                    8   8  8                                       8   8 8   8 8     "
echo "      8     eeeee eeeee eeeee eeee eeeee       8   8  8 e   e e  eeeee eeeee eeee eeeee        8 8   8 8  8     "
echo "      8eeee 8   8 8   \"   8   8    8   8       8e  8  8 8   8 8  8   \" 8   8 8    8   8        eee   eee  8e    "
echo "      88    8eee8 8eeee   8e  8eee 8eee8e eeee 88  8  8 8eee8 8e 8eeee 8eee8 8eee 8eee8e eeee 88  8 88  8 88    "
echo "      88    88  8    88   88  88   88   8      88  8  8 88  8 88    88 88    88   88   8      88  8 88  8 88    "
echo "      88    88  8 8ee88   88  88ee 88   8      88ee8ee8 88  8 88 8ee88 88    88ee 88   8      88  8 88  8 88eee "
echo
echo

# Check if any files were passed as arguments
if [ "$#" -eq 0 ]; then
    echo "Nothing to do. Read usage instructions at this link:"
    echo "https://github.com/Purfview/whisper-standalone-win/discussions/337"
    echo
    read -p "Press Enter to continue..."
    echo -e "\033[0m"
    exit 1
fi

# Collect all file paths
file_list=("$@")

# Construct the file list for the command
command_files=""
for file in "${file_list[@]}"; do
    command_files+="\"$file\" "
done


# The command
eval "./faster-whisper $command_files -pp -o source --batch_recursive --check_files --standard -f json srt -m medium"


read -p "Press Enter to exit..."
echo -e "\033[0m"
exit 0

