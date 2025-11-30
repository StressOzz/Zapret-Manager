#!/bin/sh
# ==========================================
# Zapret on remittor Manager by StressOzz
# ==========================================
ZAPRET_MANAGER_VERSION="7.0"
ZAPRET_VERSION="72.20251122"
STR_VERSION_AUTOINSTALL="2"
GREEN="\033[1;32m"; RED="\033[1;31m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"; BLUE="\033[0;34m"; NC="\033[0m"; DGRAY="\033[38;5;236m"
WORKDIR="/tmp/zapret-update"; CONF="/etc/config/zapret"
CUSTOM_DIR="/opt/zapret/init.d/openwrt/custom.d/"
# ==========================================
# Проверяем наличие byedpi, youtubeUnblock, Flow Offloading
# ==========================================
if opkg list-installed | grep -q "byedpi"; then
clear
echo -e "${RED}Найден установленный ${NC}ByeDPI${RED}!${NC}\n"
echo -e "${NC}Zapret${RED} не может работать совместно с ${NC}ByeDPI${RED}!${NC}\n"
read -p $'\033[1;32mУдалить \033[0mByeDPI\033[1;32m ?\033[0m [y/N] ' answer
case "$answer" in
[Yy]* ) opkg --force-removal-of-dependent-packages --autoremove remove byedpi >/dev/null 2>&1; echo -e "\n${GREEN}ByeDPI удалён!${NC}"; sleep 3;;
* ) echo -e "\n${RED}Скрипт остановлен! Удалите ${NC}ByeDPI${RED}!${NC}\n"; exit 1;;
esac
fi
if opkg list-installed | grep -q "youtubeUnblock"; then
clear; echo -e "${RED}Найден установленный ${NC}youtubeUnblock${RED}!${NC}\n"
echo -e "${NC}Zapret${RED} не может работать совместно с ${NC}youtubeUnblock${RED}!${NC}\n"
read -p $'\033[1;32mУдалить \033[0myoutubeUnblock\033[1;32m ?\033[0m [y/N] ' answer
case "$answer" in
[Yy]* ) opkg --force-removal-of-dependent-packages --autoremove remove youtubeUnblock luci-app-youtubeUnblock >/dev/null 2>&1; echo -e "\n${GREEN}youtubeUnblock удалён!${NC}"; sleep 3;;
* ) echo -e "\n${RED}Скрипт остановлен! Удалите ${NC}youtubeUnblock ${RED}!${NC}\n"; exit 1;;
esac
fi
FLOW_STATE=$(uci get firewall.@defaults[0].flow_offloading 2>/dev/null)
HW_FLOW_STATE=$(uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null)
if [ "$FLOW_STATE" = "1" ] || [ "$HW_FLOW_STATE" = "1" ]; then
if ! grep -q 'meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then
clear; echo -e "${RED}Включён ${NC}Flow Offloading ${RED}!${NC}\n"
echo -e "${NC}Zapret${RED} не может работать с включённым ${NC}Flow Offloading${RED}!\n"
echo -e "${CYAN}1) ${GREEN}Отключить ${NC}Flow Offloading"
echo -e "${CYAN}2) ${GREEN}Применить фикс для работы ${NC}Zapret${GREEN} с включённым ${NC}Flow Offloading"
echo -ne "${CYAN}Enter) ${GREEN}Выход\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in
1) echo -e "\n${GREEN}Flow Offloading успешно отключён!${NC}"
uci set firewall.@defaults[0].flow_offloading='0'
uci set firewall.@defaults[0].flow_offloading_hw='0'
uci commit firewall; /etc/init.d/firewall restart
sleep 2 ;;
2) echo -e "\n${GREEN}Фикс успешно применён!${NC}"
sed -i 's/meta l4proto { tcp, udp } flow offload @ft;/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc
fw4 restart >/dev/null 2>&1; sleep 2 ;;
*) echo -e "\n${RED}Скрипт остановлен!${NC}\n"; exit 1 ;;
esac
fi
fi
# ==========================================
# Получение версии и подготовка установки Zapret
# ==========================================
get_versions() {
LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)
[ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v "noarch" | sort -k3 -n | tail -n1 | awk '{print $2}')
USED_ARCH="$LOCAL_ARCH"
LATEST_URL="https://github.com/remittor/zapret-openwrt/releases/download/v${ZAPRET_VERSION}/zapret_v${ZAPRET_VERSION}_${LOCAL_ARCH}.zip"
INSTALLED_VER=$(opkg list-installed | grep '^zapret ' | awk '{print $3}')
[ -z "$INSTALLED_VER" ] && INSTALLED_VER="не найдена"
if [ -f /etc/init.d/zapret ]; then
if /etc/init.d/zapret status 2>/dev/null | grep -qi "running"; then
ZAPRET_STATUS="${GREEN}запущен${NC}"
else
ZAPRET_STATUS="${RED}остановлен${NC}"
fi
else
ZAPRET_STATUS=""
fi
if [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ]; then
INST_COLOR=$GREEN; INSTALLED_DISPLAY="$INSTALLED_VER"
elif [ "$INSTALLED_VER" != "не найдена" ]; then
INST_COLOR=$RED; INSTALLED_DISPLAY="$INSTALLED_VER (устарела)"
else
INST_COLOR=$RED; INSTALLED_DISPLAY="$INSTALLED_VER"
fi
}
# ==========================================
# Установка Zapret
# ==========================================
install_Zapret() {
local NO_PAUSE=$1
get_versions
if [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ]; then
echo -e "\n${GREEN}Последняя версия уже установлена!${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
[ "$NO_PAUSE" != "1" ] && echo
echo -e "${MAGENTA}Устанавливаем ZAPRET${NC}"
if [ -f /etc/init.d/zapret ]; then
echo -e "${CYAN}Останавливаем ${NC}zapret" && /etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done
fi
echo -e "${CYAN}Обновляем список пакетов${NC}"
opkg update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении списка пакетов!${NC}\n"; sleep 7; return; }
mkdir -p "$WORKDIR"; rm -f "$WORKDIR"/* 2>/dev/null; cd "$WORKDIR" || return
FILE_NAME=$(basename "$LATEST_URL")
if ! command -v unzip >/dev/null 2>&1; then
echo -e "${CYAN}Устанавливаем ${NC}unzip"
opkg install unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}\n"; sleep 7; return; }
fi
echo -e "${CYAN}Скачиваем архив ${NC}$FILE_NAME"
wget -q "$LATEST_URL" -O "$FILE_NAME" || {
echo -e "\n${RED}Не удалось скачать ${NC}$FILE_NAME\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
return
}
echo -e "${CYAN}Распаковываем архив${NC}"
unzip -o "$FILE_NAME" >/dev/null; for PKG in zapret_*.ipk luci-app-zapret_*.ipk; do
[ -f "$PKG" ] && {
echo -e "${CYAN}Устанавливаем пакет ${NC}$PKG"
opkg install --force-reinstall "$PKG" >/dev/null 2>&1
}
done
echo -e "${CYAN}Удаляем временные файлы${NC}"
cd /; rm -rf "$WORKDIR" /tmp/*.ipk /tmp/*.zip /tmp/*zapret* 2>/dev/null
if [ -f /etc/init.d/zapret ]; then
echo -e "${GREEN}Zapret установлен!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
else
echo -e "\n${RED}Zapret не был установлен!${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
fi
}
# ==========================================
# Включение Discord и звонков в TG и WA
# ==========================================
show_script_50() {
[ -f "/opt/zapret/init.d/openwrt/custom.d/50-script.sh" ] || return
line=$(head -n1 /opt/zapret/init.d/openwrt/custom.d/50-script.sh)
name=$(case "$line" in *QUIC*) echo "50-quic4all" ;; *stun*) echo "50-stun4all" ;; *"discord media"*) echo "50-discord-media" ;; *"discord subnets"*) echo "50-discord" ;; *) echo "" ;; esac)
}

enable_discord_calls() {
local NO_PAUSE=$1
[ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }
[ "$NO_PAUSE" != "1" ] && clear && echo -e "${MAGENTA}Меню установки скриптов${NC}"
[ "$NO_PAUSE" = "1" ] && echo -e "${MAGENTA}Устанавливаем скрипт${NC}"
[ "$NO_PAUSE" != "1" ] && show_script_50 && [ -n "$name" ] && echo -e "\n${YELLOW}Установлен скрипт:${NC} $name"
if [ "$NO_PAUSE" = "1" ]; then
SELECTED="50-stun4all"
URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all"
else
echo -e "\n${CYAN}1) ${GREEN}Установить скрипт ${NC}50-stun4all\n${CYAN}2) ${GREEN}Установить скрипт ${NC}50-quic4all"
echo -e "${CYAN}3) ${GREEN}Установить скрипт ${NC}50-discord-media\n${CYAN}4) ${GREEN}Установить скрипт ${NC}50-discord"
echo -ne "${CYAN}5) ${GREEN}Удалить скрипт${NC}\n${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in
1) SELECTED="50-stun4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all" ;;
2) SELECTED="50-quic4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-quic4all" ;;
3) SELECTED="50-discord-media"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-discord-media" ;;
4) SELECTED="50-discord"; URL="https://raw.githubusercontent.com/bol-van/zapret/v70.5/init.d/custom.d.examples.linux/50-discord" ;;
5) echo -e "\n${GREEN}Скрипт удалён!${NC}\n"
rm -f "$CUSTOM_DIR/50-script.sh" 2>/dev/null
sed -i "s/,50000-50099//" "$CONF"
sed -i ':a;N;$!ba;s|--new\n--filter-udp=50000-50099\n--filter-l7=discord,stun\n--dpi-desync=fake\n*||g' "$CONF"
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
read -p "Нажмите Enter для выхода в главное меню..." dummy
return ;;
*) return ;;
esac
fi
if wget -qO "$CUSTOM_DIR/50-script.sh" "$URL"; then
[ "$NO_PAUSE" != "1" ] && echo
echo -e "${GREEN}Скрипт ${NC}$SELECTED${GREEN} успешно установлен!${NC}\n"
else
echo -e "\n${RED}Ошибка при скачивании скрипта!${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
if ! grep -q "option NFQWS_PORTS_UDP.*50000-50099" "$CONF"; then
sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,50000-50099'/" "$CONF"
fi
if ! grep -q -- "--filter-udp=50000-50099" "$CONF"; then
last_line1=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1)
if [ -n "$last_line1" ]; then
sed -i "${last_line1},\$d" "$CONF"
fi
cat <<'EOF' >> "$CONF"
--new
--filter-udp=50000-50099
--filter-l7=discord,stun
--dpi-desync=fake
'
EOF
fi
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# FIX GAME
# ==========================================
fix_GAME() {
local NO_PAUSE=$1
[ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }
[ "$NO_PAUSE" != "1" ] && echo
echo -e "${MAGENTA}Настраиваем стратегию для игр${NC}"
if grep -q "option NFQWS_PORTS_UDP.*1024-49999,50100-65535" "$CONF" && grep -q -- "--filter-udp=1024-49999,50100-65535" "$CONF"; then
echo -e "${CYAN}Удаляем из стратегии настройки для игр${NC}"
sed -i ':a;N;$!ba;s|--new\n--filter-udp=1024-49999,50100-65535\n--dpi-desync=fake\n--dpi-desync-cutoff=d2\n--dpi-desync-any-protocol=1\n--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com\.bin\n*||g' "$CONF"
sed -i "s/,1024-49999,50100-65535//" "$CONF"
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
echo -e "${GREEN}Настройки для игр удалены!${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
if ! grep -q "option NFQWS_PORTS_UDP.*1024-49999,50100-65535" "$CONF"; then
sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,1024-49999,50100-65535'/" "$CONF"
fi
if ! grep -q -- "--filter-udp=1024-49999,50100-65535" "$CONF"; then
last_line=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1)
if [ -n "$last_line" ]; then
sed -i "${last_line},\$d" "$CONF"
fi
cat <<'EOF' >> "$CONF"
--new
--filter-udp=1024-49999,50100-65535
--dpi-desync=fake
--dpi-desync-cutoff=d2
--dpi-desync-any-protocol=1
--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com.bin
'
EOF
fi
echo -e "${CYAN}Добавляем в стратегию настройки для игр${NC}"
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
echo -e "${GREEN}Игровые настройки добавлены!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Zapret под ключ
# ==========================================
zapret_key(){
clear; echo -e "${MAGENTA}Удаление, установка и настройка Zapret${NC}\n"
get_versions
uninstall_zapret "1"; install_Zapret "1"
[ ! -f /etc/init.d/zapret ] && return
wget -qO- "https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/Str${STR_VERSION_AUTOINSTALL}.sh" | sh
if [ ! -f "$CONF" ]; then
echo -e "\n${RED}Файл ${NC}$CONF${RED} не найден!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
if ! grep -q "#v" "$CONF"; then
echo -e "\n${RED}Cтратегия не установлена!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
echo; enable_discord_calls "1"; fix_GAME "1"
echo -e "${GREEN}Zapret установлен и настроен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Вернуть настройки по умолчанию
# ==========================================
comeback_def () {
if [ -f /opt/zapret/restore-def-cfg.sh ]; then
echo -e "\n${MAGENTA}Возвращаем настройки по умолчанию${NC}"
rm -f /opt/zapret/init.d/openwrt/custom.d/50-script.sh
[ -f /etc/init.d/zapret ] && /etc/init.d/zapret stop >/dev/null 2>&1
echo -e "${CYAN}Возвращаем ${NC}настройки${CYAN}, ${NC}стратегию${CYAN} и ${NC}hostlist${CYAN} к значениям по умолчанию${NC}"
IPSET_DIR="/opt/zapret/ipset"; FILES="zapret-hosts-google.txt zapret-hosts-user-exclude.txt"
URL_BASE="https://raw.githubusercontent.com/remittor/zapret-openwrt/master/zapret/ipset"
for f in $FILES; do
wget -qO "$IPSET_DIR/$f" "$URL_BASE/$f"
done
chmod +x /opt/zapret/restore-def-cfg.sh && /opt/zapret/restore-def-cfg.sh
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh; /etc/init.d/zapret restart >/dev/null 2>&1
sed -i '/130\.255\.77\.28 ntc.party/d; /57\.144\.222\.34 instagram.com www.instagram.com/d; \
/173\.245\.58\.219 rutor.info d.rutor.info/d; /193\.46\.255\.29 rutor.info/d; \
/157\.240\.9\.174 instagram.com www.instagram.com/d' /etc/hosts; /etc/init.d/dnsmasq restart >/dev/null 2>&1
echo -e "${GREEN}Настройки по умолчанию возвращены!${NC}\n"
else
echo -e "\n${RED}Zapret не установлен!${NC}\n"
fi
read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Остановить Zapret
# ==========================================
stop_zapret() {
echo -e "\n${MAGENTA}Останавливаем Zapret${NC}\n${CYAN}Останавливаем ${NC}Zapret"
/etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done
echo -e "${GREEN}Zapret остановлен!${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Запустить Zapret
# ==========================================
start_zapret() {
if [ -f /etc/init.d/zapret ]; then
echo -e "\n${MAGENTA}Запускаем Zapret${NC}"; echo -e "${CYAN}Запускаем ${NC}Zapret"
/etc/init.d/zapret start >/dev/null 2>&1
chmod +x /opt/zapret/sync_config.sh; /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
echo -e "${GREEN}Zapret запущен!${NC}\n"
else
echo -e "\n${RED}Zapret не установлен!${NC}\n"
fi
read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Полное удаление Zapret
# ==========================================
uninstall_zapret() {
local NO_PAUSE=$1
[ "$NO_PAUSE" != "1" ] && echo
echo -e "${MAGENTA}Удаляем ZAPRET${NC}\n${CYAN}Останавливаем ${NC}zapret\n${CYAN}Убиваем процессы${NC}"
/etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done
echo -e "${CYAN}Удаляем пакеты${NC}"
opkg --force-removal-of-dependent-packages --autoremove remove zapret luci-app-zapret >/dev/null 2>&1
echo -e "${CYAN}Удаляем временные файлы${NC}"
rm -rf /opt/zapret /etc/config/zapret /etc/firewall.zapret /etc/init.d/zapret /tmp/*zapret* /var/run/*zapret* /tmp/*.ipk /tmp/*.zip 2>/dev/null
crontab -l 2>/dev/null | grep -v -i "zapret" | crontab - 2>/dev/null
nft list tables 2>/dev/null | awk '{print $2}' | grep -E '(zapret|ZAPRET)' | while read t; do [ -n "$t" ] && nft delete table "$t" 2>/dev/null; done
sed -i '/130\.255\.77\.28 ntc.party/d; /57\.144\.222\.34 instagram.com www.instagram.com/d; \
/173\.245\.58\.219 rutor.info d.rutor.info/d; /193\.46\.255\.29 rutor.info/d; \
/157\.240\.9\.174 instagram.com www.instagram.com/d' /etc/hosts; /etc/init.d/dnsmasq restart >/dev/null 2>&1
echo -e "${GREEN}Zapret полностью удалён!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Выбор стратегий
# ==========================================
show_current_strategy() {
[ -f "$CONF" ] || return
for v in v1 v2 v3 v4; do grep -q "#$v" "$CONF" && { ver="$v"; return; } done
grep -q -- "--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt" "$CONF" && grep -q -- "--hostlist-exclude-domains=openwrt.org" "$CONF" && ver="дефолтная"
}
menu_str() {
[ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }
clear; echo -e "${MAGENTA}Меню выбора стратегии${NC}"
show_current_strategy && [ -n "$ver" ] && echo -e "\n${YELLOW}Используется стратегия:${NC} $ver"
echo -e "\n${CYAN}1) ${GREEN}Установить стратегию${NC} v1\n${CYAN}2) ${GREEN}Установить стратегию${NC} v2"
echo -ne "${CYAN}3) ${GREEN}Установить стратегию${NC} v3\n${CYAN}4) ${GREEN}Установить стратегию${NC} v4\n${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in
1) echo; wget -qO- https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/Str1.sh | sh
echo; read -p "Нажмите Enter для выхода в главное меню..." dummy
;;
2)echo; wget -qO- https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/Str2.sh | sh
echo; read -p "Нажмите Enter для выхода в главное меню..." dummy
;;
3) echo; wget -qO- https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/Str3.sh | sh
echo; read -p "Нажмите Enter для выхода в главное меню..." dummy
;;
4) echo; wget -qO- https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/Str4.sh | sh
echo; read -p "Нажмите Enter для выхода в главное меню..." dummy
;;
*) return ;;
esac
}
# ==========================================
# Главное меню
# ==========================================
show_menu() {
get_versions
clear; echo -e "╔════════════════════════════════════╗"
echo -e "║     ${BLUE}Zapret on remittor Manager${NC}     ║"
echo -e "╚════════════════════════════════════╝"
echo -e "                     ${DGRAY}by StressOzz v$ZAPRET_MANAGER_VERSION${NC}"
echo -e "\n${YELLOW}Установленная версия:   ${INST_COLOR}$INSTALLED_DISPLAY${NC}"
[ -n "$ZAPRET_STATUS" ] && echo -e "${YELLOW}Статус Zapret:${NC}          $ZAPRET_STATUS"
show_script_50 && [ -n "$name" ] && echo -e "${YELLOW}Установлен скрипт:${NC}      $name"
[ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*1024-49999,50100-65535" "$CONF" && grep -q -- "--filter-udp=1024-49999,50100-65535" "$CONF" && echo -e "${YELLOW}Стратегия для игр:${NC}      ${GREEN}активна${NC}"
show_current_strategy && [ -n "$ver" ] && echo -e "${YELLOW}Используется стратегия:${NC} ${CYAN}$ver${NC}"
echo -e "\n${CYAN}1) ${GREEN}Установить последнюю версию${NC}\n${CYAN}2) ${GREEN}Меню выбора стратегий${NC}"
echo -e "${CYAN}3) ${GREEN}Вернуть настройки по умолчанию${NC}\n${CYAN}4) ${GREEN}Остановить / Запустить ${NC}Zapret"
echo -e "${CYAN}5) ${GREEN}Удалить ${NC}Zapret\n${CYAN}6) ${GREEN}Добавить / Удалить стратегию для игр"
echo -e "${CYAN}7) ${GREEN}Меню установки скриптов${NC}\n${CYAN}8) ${GREEN}Удалить / Установить / Настроить${NC} Zapret"
echo -ne "${CYAN}9) ${GREEN}Системная информация${NC}\n${CYAN}Enter) ${GREEN}Выход${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in
1) install_Zapret ;;
2) menu_str ;;
3) comeback_def ;;
4) pgrep -f /opt/zapret >/dev/null 2>&1 && stop_zapret || start_zapret ;;
5) uninstall_zapret;;
6) fix_GAME  ;;
7) enable_discord_calls ;;
8) zapret_key ;;
9) wget -qO- https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/sys_info.sh | sh; echo; read -p "Нажмите Enter для выхода в главное меню..." dummy
;;
*) echo; exit 0 ;;
esac
}
# ==========================================
# Старт скрипта (цикл)
# ==========================================
while true; do show_menu; done
