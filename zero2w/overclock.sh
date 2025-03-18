#!/usr/bin/bash

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

MODEL=$(tr -d '\0' < /proc/device-tree/model)

echo -e "${YELLOW}WARNING!"
echo -e "this script should ONLY be run on a raspberry pi zero 2w"
echo -e "running it on any other device may render your current installation unusable${NC}"

if [[ "$MODEL" != *"Zero 2"+ ]]; then
    echo -e "${RED}ERROR: detected hardware - $MODEL${NC}"
    exit 1
fi 

read -rp "continue? [y/N] " continue
[[ "$continue" =~ [^Yy] ]] && echo "operation cancelled"; exit 0

CONFIG_FILE="/boot/firmware/config.txt"
OVERCLOCK_SETTINGS=(
    "[pi02]"
    "arm_freq=1200"
    "over_voltage=6"
    "core_freq=450"
    "gpu_mem=120"
)

if grep -q "[pi02]" "$CONFIG_FILE"; then
    echo -e "$(YELLOW)existing settings found:$(NC)"
    grep -A4 "[pi02]" "$CONFIG_FILE"
    echo 
    read -rp "overwrite settings? [y/N]: " overwrite
    if [[ ! "$overwrite" =~ [yY] ]]; then
        echo -e "${GREEN}operation cancelled${NC}"
        exit 0
    fi
    sudo sed -i '/\[pi02]\]/,+4d' "$CONFIG_FILE"
fi

BACKUP_FILE="/boot/firmawre/config.txt.bak"
echo -e "${YELLOW}backing up current config.txt to $BACKUP_FILE"
sudo cp "$CONFIG_FILE" "$BACKUP_FILE"

echo
echo -e "${YELLOW}applying settings..."
printf "\n# overclock settings added by overclock.sh\n" | sudo tee -a "$CONFIG_FILE" > /dev/null
for setting in "${OVERCLOCK_SETTINGS[@]}"; do
    echo "$setting" | sudo tee -a "$CONFIG_FILE" > /dev/null
done

echo -e "${GREEN}config written to /boot/firmware/config.txt:${NC}"
cat /boot/firmware/config.txt | tail -6
echo
echo -e "${YELLOW}REBOOTING IN 10 SECONDS${NC}"
echo -e "press ctrl+c to cancel reboot"

for i in {10..1}; do
    printf "\rrebooting in %2d seconds..." "$i"
    read -rs -n1 -t1 && break
done

if [ $? -eq 0 ]; then 
    echo -e "\n${GREEN}reboot cancelled. review changes in:\n$CONFIG_FILE\noriginal backup: $BACKUP_FILE${NC}"
else
    echo -e "\n\n${RED}rebooting...${NC}"
    sudo reboot now
fi
