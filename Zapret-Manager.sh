#!/bin/sh
# ==========================================
# Zapret on remittor Manager by StressOzz
# ==========================================
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
BLUE="\033[0;34m"
NC="\033[0m"
GRAY="\033[38;5;239m"
DGRAY="\033[38;5;236m"
# --- Рабочая директория для скачивания и распаковки
WORKDIR="/tmp/zapret-update"
# ==========================================
# Функция получения информации о версиях, архитектуре и статусе
# ==========================================
get_versions() {
# --- Проверка byedpi и youtubeUnblock
if opkg list-installed | grep -q "byedpi"; then
clear
echo -e "${RED}Найден установленный ${NC}ByeDPI${RED}!${NC}\n"
echo -e "${NC}Zapret${RED} не может работать совместно с ${NC}ByeDPI${RED}!${NC}\n"
read -p $'\033[1;32mУдалить \033[0mByeDPI\033[1;32m ?\033[0m [y/N] ' answer
case "$answer" in
[Yy]* ) opkg --force-removal-of-dependent-packages --autoremove remove byedpi >/dev/null 2>&1; echo -e "\n${BLUE}🔴 ${GREEN}ByeDPI удалён!${NC}"; sleep 3;;
* ) echo -e "\n${RED}Скрипт остановлен! Удалите ${NC}ByeDPI${RED}!${NC}\n"; exit 1;;
esac
fi
if opkg list-installed | grep -q "youtubeUnblock"; then
clear
echo -e "${RED}Найден установленный ${NC}youtubeUnblock${RED}!${NC}\n"
echo -e "${NC}Zapret${RED} не может работать совместно с ${NC}youtubeUnblock${RED}!${NC}\n"
read -p $'\033[1;32mУдалить \033[0myoutubeUnblock\033[1;32m ?\033[0m [y/N] ' answer
case "$answer" in
[Yy]* ) opkg --force-removal-of-dependent-packages --autoremove remove youtubeUnblock luci-app-youtubeUnblock >/dev/null 2>&1; echo -e "\n${BLUE}🔴 ${GREEN}youtubeUnblock удалён!${NC}"; sleep 3;;
* ) echo -e "\n${RED}Скрипт остановлен! Удалите ${NC}youtubeUnblock ${RED}!${NC}\n"; exit 1;;
esac
fi
# --- Проверка Flow Offloading (программного и аппаратного)
local FLOW_STATE=$(uci get firewall.@defaults[0].flow_offloading 2>/dev/null)
local HW_FLOW_STATE=$(uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null)
if [ "$FLOW_STATE" = "1" ] || [ "$HW_FLOW_STATE" = "1" ]; then
if ! grep -q 'meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then
clear
echo -e "${RED}Включён ${NC}Flow Offloading ${RED}!${NC}\n"
echo -e "${NC}Zapret${RED} не может работать с включённым ${NC}Flow Offloading${RED}!\n"
echo -e "${CYAN}1) ${GREEN}Отключить ${NC}Flow Offloading"
echo -e "${CYAN}2) ${GREEN}Применить фикс для работы ${NC}Zapret${GREEN} с включённым ${NC}Flow Offloading"
echo -e "${CYAN}Enter) ${GREEN}Выход\n"
echo -ne "${YELLOW}Выберите пункт:${NC} "
read choice
case "$choice" in
1) echo -e "\n${GREEN}Flow Offloading успешно отключён!${NC}"
uci set firewall.@defaults[0].flow_offloading='0'
uci set firewall.@defaults[0].flow_offloading_hw='0'
uci commit firewall
/etc/init.d/firewall restart
sleep 2 ;;
2) echo -e "\n${GREEN}Фикс успешно применён!${NC}"
sed -i 's/meta l4proto { tcp, udp } flow offload @ft;/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc
fw4 restart >/dev/null 2>&1
sleep 2 ;;
*) echo -e "\n${RED}Скрипт остановлен! Отключите или примените фикс!${NC}\n"
exit 1 ;;
esac
fi
fi
# --- Проверка наличия curl и unzip
TO_INSTALL=""
command -v curl >/dev/null 2>&1 || TO_INSTALL="$TO_INSTALL curl"
command -v unzip >/dev/null 2>&1 || TO_INSTALL="$TO_INSTALL unzip"
if [ -n "$TO_INSTALL" ]; then
clear
echo -e "${MAGENTA}ZAPRET on remittor Manager by StressOzz${NC}\n"
echo -e "${GREEN}🔴 ${CYAN}Устанавливаем${NC}$TO_INSTALL${NC}\n"
opkg update >/dev/null 2>&1 || { 
echo -e "${RED}Ошибка при обновлении списка пакетов!${NC}\n"; exit 1; 
}
for pkg in $TO_INSTALL; do
pkg_installed=0
for i in 1 2 3; do
command -v "$pkg" >/dev/null 2>&1 && { pkg_installed=1; break; }
opkg install "$pkg" >/dev/null 2>&1 && { pkg_installed=1; break; }
sleep 1
done
if [ $pkg_installed -eq 0 ]; then
echo -e "${RED}Не удалось установить ${NC}$pkg${RED} после ${NC}3${RED} попыток!${NC}"
echo -e "Установите вручную: ${CYAN}opkg install $pkg${NC}\n"
exit 1
fi
done
echo -e "${BLUE}🔴 ${GREEN}Установленно!${NC}"
sleep 2
fi
# --- Получаем текущую установленную версию zapret
INSTALLED_VER=$(opkg list-installed | grep '^zapret ' | awk '{print $3}')
[ -z "$INSTALLED_VER" ] && INSTALLED_VER="не найдена"
# --- Определяем архитектуру устройства
LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)
[ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v "noarch" | sort -k3 -n | tail -n1 | awk '{print $2}')
# --- Проверяем лимит GitHub API и доступность
LIMIT_REACHED=0
LIMIT_CHECK=$(curl -s -4 --connect-timeout 5 "https://api.github.com/repos/remittor/zapret-openwrt/releases/latest" 2>/dev/null)
if [ -z "$LIMIT_CHECK" ]; then
echo -e "api.github.com ${RED}недоступен!${NC}\nСкрипт остановлен!\n"
exit 1
fi
if echo "$LIMIT_CHECK" | grep -q 'API rate limit exceeded'; then
LATEST_VER="${RED}Достигнут лимит GitHub API! Подождите 15 минут.${NC}"
LIMIT_REACHED=1
else
# --- Извлекаем номер версии из имени архива
LATEST_URL=$(echo "$LIMIT_CHECK" | grep browser_download_url | grep "$LOCAL_ARCH.zip" | cut -d '"' -f 4)
if [ -n "$LATEST_URL" ] && echo "$LATEST_URL" | grep -q '\.zip$'; then
LATEST_VER=$(basename "$LATEST_URL" | sed -E 's/.*zapret_v([0-9]+\.[0-9]+)_.*\.zip/\1/')
USED_ARCH="$LOCAL_ARCH"
else
LATEST_VER="не найдена"
USED_ARCH="нет пакета для вашей архитектуры"
fi
fi
# --- Проверяем состояние сервиса zapret
if [ -f /etc/init.d/zapret ]; then
if /etc/init.d/zapret status 2>/dev/null | grep -qi "running"; then
ZAPRET_STATUS="${GREEN}запущен${NC}"
else
ZAPRET_STATUS="${RED}остановлен${NC}"
fi
else
ZAPRET_STATUS=""
fi
}
# ==========================================
# Установка Zapret
# ==========================================
install_Zapret() {
local NO_PAUSE=$1
[ "$NO_PAUSE" != "1" ] && clear
echo -e "${MAGENTA}Устанавливаем ZAPRET${NC}\n"
get_versions
# --- Проверка лимита API GitHub
if [ "$LIMIT_REACHED" -eq 1 ]; then
echo -e "$LATEST_VER\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
# --- Проверка доступности пакета для архитектуры
if [ "$USED_ARCH" = "нет пакета для вашей архитектуры" ]; then
echo -e "${RED}Нет доступного пакета для вашей архитектуры: ${NC}$LOCAL_ARCH\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
# --- Проверка уже установленной версии
if [ "$INSTALLED_VER" = "$LATEST_VER" ]; then
echo -e "${BLUE}🔴 ${GREEN}Последняя версия уже установлена!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
# --- Обновление списка пакетов
echo -e "${GREEN}🔴 ${CYAN}Обновляем список пакетов${NC}"
opkg update >/dev/null 2>&1 || { 
echo -e "\n${RED}Ошибка при обновлении списка пакетов!${NC}\n"; exit 1; 
}
# --- Остановка сервиса и старых процессов Zapret
if [ -f /etc/init.d/zapret ]; then
echo -e "${GREEN}🔴 ${CYAN}Останавливаем сервис ${NC}zapret"
/etc/init.d/zapret stop >/dev/null 2>&1
PIDS=$(pgrep -f /opt/zapret)
[ -n "$PIDS" ] && for pid in $PIDS; do kill -9 "$pid" >/dev/null 2>&1; done
fi
# --- Подготовка временной директории для загрузки и распаковки
mkdir -p "$WORKDIR"
rm -f "$WORKDIR"/* 2>/dev/null
cd "$WORKDIR" || return
# --- Получаем имя архива
FILE_NAME=$(basename "$LATEST_URL")
echo -e "${GREEN}🔴 ${CYAN}Скачиваем архив ${NC}$FILE_NAME"
# --- Скачивание архива с GitHub
wget -q "$LATEST_URL" -O "$FILE_NAME" || {
echo -e "${RED}Не удалось скачать ${NC}$FILE_NAME"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
return
}
# --- Распаковка архива
echo -e "${GREEN}🔴 ${CYAN}Распаковываем архив${NC}"
unzip -o "$FILE_NAME" >/dev/null
# --- Убиваем старые процессы
PIDS=$(pgrep -f /opt/zapret)
[ -n "$PIDS" ] && for pid in $PIDS; do kill -9 "$pid" >/dev/null 2>&1; done
# --- Установка пакетов
for PKG in zapret_*.ipk luci-app-zapret_*.ipk; do
[ -f "$PKG" ] && {
echo -e "${GREEN}🔴 ${CYAN}Устанавливаем пакет ${NC}$PKG"
opkg install --force-reinstall "$PKG" >/dev/null 2>&1
}
done
# --- Остановка сервиса при фоновом режиме
[ "$NO_PAUSE" = "1" ] && { /etc/init.d/zapret stop >/dev/null 2>&1 || pkill -9 -f /opt/zapret >/dev/null 2>&1; }
# --- Очистка временных файлов и пакетов
echo -e "${GREEN}🔴 ${CYAN}Удаляем временные файлы и пакеты${NC}"
cd /
rm -rf "$WORKDIR" /tmp/*.ipk /tmp/*.zip /tmp/*zapret* 2>/dev/null
# --- Перезапуск службы Zapret
[ "$NO_PAUSE" != "1" ] && {
if [ -f /etc/init.d/zapret ]; then
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
fi
}
# --- Сообщение об успешной установке или нет
if [ -f /etc/init.d/zapret ]; then
echo -e "\n${BLUE}🔴 ${GREEN}Zapret установлен!${NC}\n"
else
echo -e "\n${RED}Zapret не был установлен! Попробуйте ещё раз!${NC}\n"
fi
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Чиним дефолтную стратегию
# ==========================================
fix_default() {
local NO_PAUSE=$1
[ "$NO_PAUSE" != "1" ] && clear
echo -e "${MAGENTA}Редактируем стратегию${NC}\n"
# Проверка, установлен ли Zapret
if [ ! -f /etc/init.d/zapret ]; then
echo -e "${RED}Zapret не установлен!${NC}"
[ "$NO_PAUSE" != "1" ] && echo -e ""
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
echo -e "${GREEN}🔴 ${CYAN}Меняем стратегию, добавляем домены в ${NC}hostlist${CYAN} и редактируем ${NC}/etc/hosts\n"
# Удаляем строку и всё, что идёт ниже строки с option NFQWS_OPT '
sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" /etc/config/zapret
# Вставляем новый блок сразу после строки option NFQWS_OPT '
cat <<'EOF' >> /etc/config/zapret
option NFQWS_OPT '
--filter-tcp=443
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--dpi-desync=fake,multidisorder
--dpi-desync-split-seqovl=681
--dpi-desync-split-pos=1
--dpi-desync-fooling=badseq
--dpi-desync-badseq-increment=10000000
--dpi-desync-repeats=2
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com
--new
--filter-udp=443
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--dpi-desync=fake
--dpi-desync-repeats=4
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
'
EOF
# Проверка и перезапись файла исключений пользователей
sed -i \
'/^play\.google\.com$/d; \
/^android\.com$/d; \
/^google-analytics\.com$/d; \
/^googleusercontent\.com$/d; \
/^gstatic\.com$/d; \
/^gvt1\.com$/d; \
/^ggpht\.com$/d; \
/^dl\.google\.com$/d; \
/^dl-ssl\.google\.com$/d; \
/^android\.clients\.google\.com$/d; \
/^gvt2\.com$/d; \
/^gvt3\.com$/d' /opt/zapret/ipset/zapret-hosts-user-exclude.txt
file="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"
cat <<'EOF' | grep -Fxv -f "$file" >> "$file"
gosuslugi.ru
api.steampowered.com
cdn.akamai.steamstatic.com
cdn.cloudflare.steamstatic.com
cdn.steamcommunity.com
cdn.steamstatic.com
checkout.steampowered.com
client-download.steampowered.com
community.cloudflare.steamstatic.com
community.steampowered.com
cs.steampowered.com
help.steampowered.com
login.steampowered.com
media.steampowered.com
partner.steamgames.com
partner.steampowered.com
s.team
scontent.steamusercontent.com
steam.tv
steambroadcast.akamaized.net
steambroadcast.com
steamcdn.com
steamcdn.net
steamcdn-a.akamaihd.net
steamcdn-a.akamaihd.net.edgesuite.net
steamcdn-a.akamaized.net
steamchat.com
steam-chat.com
steamcommunity.akamaized.net
steamcommunity.cloudflare.steamstatic.com
steamcommunity.com
steamcommunity-a.akamaihd.net
steamcommunity-a.akamaized.net
steamcontent.com
steamcontent-a.akamaihd.net
steamdeck.com
steamdeckcdn.akamaized.net
steamdeckusercontent.com
steamgames.com
steamgames.net
steampowered.com
steamserver.net
steamstat.us
steamstatic.akamaized.net
steamstatic.com
steamstore-a.akamaihd.net
steamusercontent.com
steamuserimages-a.akamaihd.net
store.akamai.steamstatic.com
store.cloudflare.steamstatic.com
store.steampowered.com
support.steampowered.com
valve.net
valvecdn.com
valvecontent.com
valvesoftware.com
valvesoftware.net
workshop.steampowered.com
epicgames.com
store.epicgames.com
accounts.epicgames.com
account-public-service-prod03.ol.epicgames.com
accountportal-website-prod07.ol.epicgames.com
launcher-public-service-prod06.ol.epicgames.com
launcherwaitingroom-public-service-prod06.ol.epicgames.com
launcher-website-prod07.ol.epicgames.com
tracking.epicgames.com
catalog-public-service-prod06.ol.epicgames.com
entitlement-public-service-prod08.ol.epicgames.com
lightswitch-public-service-prod06.ol.epicgames.com
friends-public-service-prod06.ol.epicgames.com
orderprocessor-public-service-ecomprod01.ol.epicgames.com
ut-public-service-prod10.ol.epicgames.com
library-service.live.use1a.on.epicgames.com
datastorage-public-service-liveegs.live.use1a.on.epicgames.com
cdn1.unrealengine.com
cdn2.unrealengine.com
download.epicgames.com
download2.epicgames.com
download3.epicgames.com
download4.epicgames.com
fastly-download.epicgames.com
static-assets-prod.epicgames.com
store-site-backend-static.ak.epicgames.com
store-content.ak.epicgames.com
datarouter.ol.epicgames.com
epicgames-download1.akamaized.net
api.epicgames.dev
metrics.ol.epicgames.com
et.epicgames.com
EOF
# Проверка и добавление hosts
file="/etc/hosts"
cat <<'EOF' | grep -Fxv -f "$file" 2>/dev/null >> "$file"
130.255.77.28 ntc.party
57.144.222.34 instagram.com www.instagram.com
173.245.58.219 rutor.info d.rutor.info
193.46.255.29 rutor.info
157.240.9.174 instagram.com www.instagram.com
EOF
/etc/init.d/dnsmasq restart >/dev/null 2>&1
# Применяем конфиг
[ "$NO_PAUSE" != "1" ] && { chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1; }
echo -e "${BLUE}🔴 ${GREEN}Стратегия отредактирована!${NC}"
[ "$NO_PAUSE" != "1" ] && echo -e ""
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Включение Discord и звонков в TG и WA
# ==========================================
enable_discord_calls() {
local NO_PAUSE=$1
[ "$NO_PAUSE" != "1" ] && clear
[ "$NO_PAUSE" != "1" ] && echo -e "${MAGENTA}Меню настройки Discord и звонков в TG/WA${NC}\n"
if [ ! -f /etc/init.d/zapret ]; then
echo -e "${RED}Zapret не установлен!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
if [ -f "$CUSTOM_DIR/50-script.sh" ]; then
case "$(sed -n '1p' "$CUSTOM_DIR/50-script.sh")" in
*QUIC*) CURRENT_SCRIPT="50-quic4all" ;;
*stun*) CURRENT_SCRIPT="50-stun4all" ;;
*"discord media"*) CURRENT_SCRIPT="50-discord-media" ;;
*"discord subnets"*) CURRENT_SCRIPT="50-discord" ;;
*) CURRENT_SCRIPT="неизвестный" ;;
esac
fi
[ "$NO_PAUSE" != "1" ] && echo -e "${YELLOW}Установленный скрипт:${NC} $CURRENT_SCRIPT\n"
if [ "$NO_PAUSE" = "1" ]; then
SELECTED="50-stun4all"
URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all"
else
echo -e "${CYAN}1) ${GREEN}Установить скрипт ${NC}50-stun4all ${GREEN}для${NC} Discord ${GREEN}и${NC} звонков"
echo -e "${CYAN}2) ${GREEN}Установить скрипт ${NC}50-quic4all ${GREEN}для${NC} Discord ${GREEN}и${NC} звонков"
echo -e "${CYAN}3) ${GREEN}Установить скрипт ${NC}50-discord-media ${GREEN}для${NC} Discord"
echo -e "${CYAN}4) ${GREEN}Установить скрипт ${NC}50-discord ${GREEN}для${NC} Discord"
echo -e "${CYAN}5) ${GREEN}Удалить скрипт${NC}"
echo -e "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n"
echo -ne "${YELLOW}Выберите пункт:${NC} "
read choice
case "$choice" in
1)
SELECTED="50-stun4all"
URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all" ;;
2)
SELECTED="50-quic4all"
URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-quic4all" ;;
3)
SELECTED="50-discord-media"
URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-discord-media" ;;
4)
SELECTED="50-discord"
URL="https://raw.githubusercontent.com/bol-van/zapret/v70.5/init.d/custom.d.examples.linux/50-discord" ;;
5)
echo -e "\n${BLUE}🔴 ${GREEN}Скрипт удалён!${NC}\n"
rm -f "$CUSTOM_DIR/50-script.sh" 2>/dev/null
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
read -p "Нажмите Enter для выхода в главное меню..." dummy
show_menu
return ;;
*)
echo -e "\nВыходим в главное меню..."
sleep 2
show_menu
return ;;
esac
fi
if [ "$CURRENT_SCRIPT" = "$SELECTED" ]; then
echo -e "\n${RED}Выбранный скрипт уже установлен!${NC}"
else
mkdir -p "$CUSTOM_DIR"
if curl -fsSLo "$CUSTOM_DIR/50-script.sh" "$URL"; then
[ "$NO_PAUSE" != "1" ] && 
echo -e "\n${GREEN}🔴 ${CYAN}Скрипт ${NC}$SELECTED${CYAN} успешно установлен!${NC}\n"
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
if [ "$SELECTED" = "50-quic4all" ] || [ "$SELECTED" = "50-stun4all" ]; then
echo -e "${BLUE}🔴 ${GREEN}Звонки и Discord включены!${NC}"
elif [ "$SELECTED" = "50-discord-media" ] || [ "$SELECTED" = "50-discord" ]; then
echo -e "${BLUE}🔴 ${GREEN}Discord включён!${NC}"
else
echo -e "${BLUE}🔴 ${GREEN}Скрипт активирован!${NC}"
fi
else
echo -e "${RED}Ошибка при скачивании скрипта!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
fi
echo -e ""
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# FIX Battlefield REDSEC
# ==========================================
fix_REDSEC() {
local NO_PAUSE=$1
[ "$NO_PAUSE" != "1" ] && clear
echo -e "${MAGENTA}Настраиваем стратегию для игры Battlefield REDSEC${NC}\n"
CONF="/etc/config/zapret"
if [ ! -f /etc/init.d/zapret ]; then
[ "$NO_PAUSE" != "1" ] && echo -e "${RED}Zapret не установлен!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
if grep -q "option NFQWS_PORTS_UDP.*20000-22000" "$CONF" && grep -q -- "--filter-udp=20000-22000" "$CONF"; then
echo -e "${RED}Стратегия для Battlefield REDSEC уже применена!${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
if ! grep -q "option NFQWS_PORTS_UDP.*20000-22000" "$CONF"; then
sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,20000-22000'/" "$CONF"
fi
if ! grep -q -- "--filter-udp=20000-22000" "$CONF"; then
last_line=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1)
if [ -n "$last_line" ]; then
sed -i "${last_line},\$d" "$CONF"
fi
cat <<'EOF' >> "$CONF"
--new
--filter-udp=20000-22000
--dpi-desync=fake
--dpi-desync-cutoff=d2
--dpi-desync-any-protocol
--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com.bin
'
EOF
fi
echo -e "${GREEN}🔴 ${CYAN}Добавляем в стратегию блок необходимый для игры${NC}"
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
echo -e "\n${BLUE}🔴 ${GREEN}Zapret настроен для игры Battlefield REDSEC!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Zapret под ключ
# ==========================================
zapret_key(){
clear
echo -e "${MAGENTA}Удаление, установка и настройка Zapret${NC}\n"
get_versions
# Проверка лимита API
if [ "$LIMIT_REACHED" -eq 1 ]; then
echo -e "${RED}Достигнут лимит GitHub API! Подождите 15 минут.${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
# Проверка версии
if ! [[ "$LATEST_VER" =~ 7 ]]; then
echo -e "${RED}Внимание! Версия для установки не найдена!${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
uninstall_zapret "1"
install_Zapret "1"
fix_default "1"
echo -e "\n${MAGENTA}Включаем Discord и звонки в TG и WA${NC}\n"
enable_discord_calls "1"
fix_REDSEC "1"
if [ -f /etc/init.d/zapret ]; then
echo -e "${BLUE}🔴 ${GREEN}Zapret ${GREEN}установлен и настроен!${NC}\n"
else
echo -e "${RED}Zapret не установлен!${NC}\n"
fi
read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Вернуть настройки по умолчанию
# ==========================================
comeback_def () {
clear
echo -e "${MAGENTA}Возвращаем настройки по умолчанию${NC}\n"
# Проверка скрипта восстановления и его запуск
if [ -f /opt/zapret/restore-def-cfg.sh ]; then
rm -f /opt/zapret/init.d/openwrt/custom.d/50-script.sh
[ -f /etc/init.d/zapret ] && /etc/init.d/zapret stop >/dev/null 2>&1
echo -e "${GREEN}🔴 ${CYAN}Возвращаем ${NC}настройки${CYAN}, ${NC}стратегию${CYAN} и ${NC}hostlist${CYAN} к значениям по умолчанию${NC}\n"
IPSET_DIR="/opt/zapret/ipset"
mkdir -p "$IPSET_DIR"
FILES="zapret-hosts-google.txt zapret-hosts-user-exclude.txt"
URL_BASE="https://raw.githubusercontent.com/remittor/zapret-openwrt/master/zapret/ipset"
for f in $FILES; do
curl -fsSLo "$IPSET_DIR/$f" "$URL_BASE/$f"
done
chmod +x /opt/zapret/restore-def-cfg.sh && /opt/zapret/restore-def-cfg.sh && chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh
[ -f /etc/init.d/zapret ] && /etc/init.d/zapret restart >/dev/null 2>&1
echo -e "${BLUE}🔴 ${GREEN}Настройки по умолчанию возвращены!${NC}\n"
else
echo -e "${RED}Zapret не установлен!${NC}\n"
fi
read -p "Нажмите Enter для выхода в главное меню..." dummy
show_menu
}
# ==========================================
# Остановить Zapret
# ==========================================
stop_zapret() {
clear
echo -e "${MAGENTA}Останавливаем Zapret${NC}\n"
# Остановка службы через init.d и убийство процессов
if [ -f /etc/init.d/zapret ]; then
echo -e "${GREEN}🔴 ${CYAN}Останавливаем сервис ${NC}Zapret"
/etc/init.d/zapret stop >/dev/null 2>&1
PIDS=$(pgrep -f /opt/zapret)
if [ -n "$PIDS" ]; then
echo -e "${GREEN}🔴 ${CYAN}Убиваем все процессы ${NC}Zapret"
for pid in $PIDS; do kill -9 "$pid" >/dev/null 2>&1; done
fi
echo -e "\n${BLUE}🔴 ${GREEN}Zapret остановлен!${NC}\n"
else
echo -e "${RED}Zapret не установлен!${NC}\n"
fi
read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Запустить Zapret
# ==========================================
start_zapret() {
clear
echo -e "${MAGENTA}Запускаем Zapret${NC}\n"
# Запуск службы через init.d
if [ -f /etc/init.d/zapret ]; then
echo -e "${GREEN}🔴 ${CYAN}Запускаем сервис ${NC}Zapret"
/etc/init.d/zapret start >/dev/null 2>&1
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
echo -e "\n${BLUE}🔴 ${GREEN}Zapret запущен!${NC}\n"
else
echo -e "${RED}Zapret не установлен!${NC}\n"
fi
read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Полное удаление Zapret
# ==========================================
uninstall_zapret() {
local NO_PAUSE=$1
[ "$NO_PAUSE" != "1" ] && clear
echo -e "${MAGENTA}Удаляем ZAPRET${NC}\n"
if ! [[ "$LATEST_VER" =~ 7 ]]; then
echo -e "${RED}Внимание! Версия для установки не найдена!${NC}\n"
echo -e "После удаления, установка возможна только в ручном режиме!\n"
read -p "Продолжить удаление? [y/N]: " answer
case "$answer" in
[yY]) echo -e "";;  # продолжаем удаление
*) echo -e "\n${GREEN}Удаление отменено!${NC}\n"
echo -e "Выходим в главное меню..."
sleep 2
return;;
esac
fi
echo -e "${GREEN}🔴 ${CYAN}Останавливаем сервис${NC}"
echo -e "${GREEN}🔴 ${CYAN}Убиваем процессы${NC}"
/etc/init.d/zapret stop >/dev/null 2>&1
for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done
echo -e "${GREEN}🔴 ${CYAN}Удаляем пакеты${NC}"
opkg --force-removal-of-dependent-packages --autoremove remove zapret luci-app-zapret >/dev/null 2>&1
echo -e "${GREEN}🔴 ${CYAN}Чистим конфиги и временные файлы${NC}"
rm -rf /opt/zapret /etc/config/zapret /etc/firewall.zapret /etc/init.d/zapret /tmp/*zapret* /var/run/*zapret* /tmp/*.ipk /tmp/*.zip 2>/dev/null
crontab -l 2>/dev/null | grep -v -i "zapret" | crontab - 2>/dev/null
nft list tables 2>/dev/null | awk '{print $2}' | grep -E '(zapret|ZAPRET)' | while read t; do [ -n "$t" ] && nft delete table "$t" 2>/dev/null; done
echo -e "\n${BLUE}🔴 ${GREEN}Zapret полностью удалён!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}
# ==========================================
# Запустить/Остановить Zapret
# ==========================================
startstop_zpr() {
clear
if pgrep -f /opt/zapret >/dev/null 2>&1; then
stop_zapret
else
start_zapret
fi
}
# ==========================================
# Главное меню
# ==========================================
show_menu() {
get_versions
clear
echo -e "╔════════════════════════════════════╗"
echo -e "║     ${BLUE}Zapret on remittor Manager${NC}     ║"
echo -e "╚════════════════════════════════════╝"
echo -e "                     ${DGRAY}by StressOzz v5.3${NC}"
# Определяем актуальная/устарела
if [ "$LIMIT_REACHED" -eq 1 ] || [ "$LATEST_VER" = "не найдена" ]; then
INST_COLOR=$CYAN; INSTALLED_DISPLAY="$INSTALLED_VER"
elif [ "$INSTALLED_VER" = "$LATEST_VER" ]; then
INST_COLOR=$GREEN; INSTALLED_DISPLAY="$INSTALLED_VER (актуальная)"
elif [ "$INSTALLED_VER" != "не найдена" ]; then
INST_COLOR=$RED; INSTALLED_DISPLAY="$INSTALLED_VER (устарела)"
else
INST_COLOR=$RED; INSTALLED_DISPLAY="$INSTALLED_VER"
fi
# Вывод информации о версиях и архитектуре
echo -e "\n${YELLOW}Установленная версия: ${INST_COLOR}$INSTALLED_DISPLAY${NC}\n"
echo -e "${YELLOW}Последняя версия на GitHub: ${CYAN}$LATEST_VER${NC}"
echo -e "\n${YELLOW}Архитектура устройства:${NC} $LOCAL_ARCH"
# Выводим статус службы zapret, если он известен
[ -n "$ZAPRET_STATUS" ] && echo -e "\n${YELLOW}Статус Zapret: ${NC}$ZAPRET_STATUS"
# Проверяем, установлен ли кастомный скрипт
CUSTOM_DIR="/opt/zapret/init.d/openwrt/custom.d/"
SCRIPT_FILE="$CUSTOM_DIR/50-script.sh"
CURRENT_SCRIPT=$(
[ -f "$SCRIPT_FILE" ] && case "$(head -n1 "$SCRIPT_FILE")" in
*QUIC*) echo "50-quic4all" ;;
*stun*) echo "50-stun4all" ;;
*discord\ media*) echo "50-discord-media" ;;
*discord\ subnets*) echo "50-discord" ;;
*) echo "неизвестный" ;;
esac
)
# Если скрипт найден, выводим строку
[ -n "$CURRENT_SCRIPT" ] && echo -e "\n${YELLOW}Установлен скрипт: ${NC}$CURRENT_SCRIPT"
CONF="/etc/config/zapret"
if [ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*20000-22000" "$CONF" && grep -q -- "--filter-udp=20000-22000" "$CONF"; then
echo -e "\n${YELLOW}Стратегия для Battlefield REDSEC: ${NC}активна${NC}"
fi
echo -e ""
# Вывод пунктов меню
echo -e "${CYAN}1) ${GREEN}Установить последнюю версию${NC}"
echo -e "${CYAN}2) ${GREEN}Оптимизировать стратегию${NC}"
echo -e "${CYAN}3) ${GREEN}Вернуть настройки по умолчанию${NC}"
echo -e "${CYAN}4) ${GREEN}Остановить / Запустить ${NC}Zapret"
echo -e "${CYAN}5) ${GREEN}Удалить ${NC}Zapret"
echo -e "${CYAN}6) ${GREEN}Добавить в стратегию блок для ${NC}Battlefield REDSEC"
echo -e "${CYAN}7) ${GREEN}Меню настройки ${NC}Discord${GREEN} и звонков в ${NC}TG${GREEN}/${NC}WA"
echo -e "${CYAN}8) ${GREEN}Удалить / Установить / Настроить${NC} Zapret"
echo -e "${CYAN}Enter) ${GREEN}Выход${NC}\n"
echo -ne "${YELLOW}Выберите пункт:${NC} "
read choice
case "$choice" in
1) install_Zapret ;;
2) fix_default ;;
3) comeback_def ;;
4) startstop_zpr ;;
5) uninstall_zapret;;
6) fix_REDSEC  ;;
7) enable_discord_calls ;;
8) zapret_key ;;
*) 
echo -e ""
exit 0 ;;
esac
}
# ==========================================
# Старт скрипта (цикл)
# ==========================================
while true; do
show_menu
done
