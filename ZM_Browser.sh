#!/bin/sh

GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

clear

echo -e 'sh <(wget -O - https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh)' > /usr/bin/zms
chmod +x /usr/bin/zms

echo -e "${GREEN}Установка${NC}"

echo -e "${CYAN}Обновляем список пакетов${NC}"
if ! opkg update >/dev/null 2>&1; then
    echo -e "\n${RED}Ошибка при обновлении!${NC}\n"
    exit 1
fi

echo -e "${CYAN}Устанавливаем ${NC}ttyd"
if ! opkg install ttyd >/dev/null 2>&1; then
    echo -e "\n${RED}Ошибка при установке ttyd!${NC}\n"
    exit 1
fi

echo -e "${CYAN}Устанавливаем ${NC}luci-app-ttyd"
if ! opkg install luci-app-ttyd >/dev/null 2>&1; then
    echo -e "\n${RED}Ошибка при установке luci-app-ttyd!${NC}\n"
    exit 1
fi

echo -e "${CYAN}Настраиваем ${NC}ttyd"
sed -i "s#/bin/login#sh /usr/bin/zms#" /etc/config/ttyd

/etc/init.d/ttyd restart >/dev/null 2>&1

if pidof ttyd >/dev/null; then
    echo -e "${GREEN}Служба запущена!${NC}\n\n${YELLOW}Доступ: ${NC}http://192.168.1.1:7681\n"
else
    echo -e "\n${RED}Ошибка! Служба не запущена!${NC}\n"
fi
