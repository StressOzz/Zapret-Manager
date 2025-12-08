#!/bin/sh
# ==========================================
# Zapret on remittor Manager by StressOzz
# ==========================================
ZAPRET_MANAGER_VERSION="7.2"; ZAPRET_VERSION="72.20251122"; STR_VERSION_AUTOINSTALL="v5"
GREEN="\033[1;32m"; RED="\033[1;31m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"; BLUE="\033[0;34m"; NC="\033[0m"; DGRAY="\033[38;5;244m"
WORKDIR="/tmp/zapret-update"; CONF="/etc/config/zapret"; CUSTOM_DIR="/opt/zapret/init.d/openwrt/custom.d/"
EXCLUDE_FILE="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"
EXCLUDE_URL="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/zapret-hosts-user-exclude.txt"
# ==========================================
# Проверяем наличие byedpi, youtubeUnblock, Flow Offloading
# ==========================================
for pkg in byedpi youtubeUnblock; do opkg list-installed | grep -q "$pkg" || continue
clear; echo -e "${RED}Найден установленный ${NC}$pkg${RED}!${NC}\n${NC}Zapret${RED} может не работать совместно с ${NC}$pkg${RED}!\n"; read -p $'\033[1;32mУдалить \033[0m'"$pkg"$'\033[1;32m ?\033[0m [y/N] ' answer; case "$answer" in [Yy]* )
opkg --force-removal-of-dependent-packages --autoremove remove $([ "$pkg" = "byedpi" ] && echo "byedpi" || echo "youtubeUnblock luci-app-youtubeUnblock") >/dev/null 2>&1
echo -e "\n$pkg${GREEN} удалён!${NC}\n"; read -p "Нажмите Enter для продолжения..." dummy ;; * ) echo -e "\n${RED}Скрипт остановлен! Удалите ${NC}$pkg${RED}!${NC}\n"; exit 1 ;; esac; done
FLOW_STATE=$(uci get firewall.@defaults[0].flow_offloading 2>/dev/null); HW_FLOW_STATE=$(uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null)
if [ "$FLOW_STATE" = "1" ] || [ "$HW_FLOW_STATE" = "1" ]; then if ! grep -q 'meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then
clear; echo -e "${RED}Включён ${NC}Flow Offloading ${RED}!${NC}\n${NC}Zapret${RED} может не работать с включённым ${NC}Flow Offloading${RED}!\n\n${CYAN}1) ${GREEN}Отключить ${NC}Flow Offloading"
echo -ne "${CYAN}2) ${GREEN}Применить фикс для работы ${NC}Zapret${GREEN} с включённым ${NC}Flow Offloading\n${CYAN}Enter) ${GREEN}Выход\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in 
1) echo -e "\n${GREEN}Flow Offloading успешно отключён!${NC}\n"; uci set firewall.@defaults[0].flow_offloading='0'; uci set firewall.@defaults[0].flow_offloading_hw='0'; uci commit firewall; /etc/init.d/firewall restart; read -p "Нажмите Enter для продолжения..." dummy ;;
2) echo -e "\n${GREEN}Фикс успешно применён!${NC}\n"; sed -i 's/meta l4proto { tcp, udp } flow offload @ft;/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc
fw4 restart >/dev/null 2>&1; read -p "Нажмите Enter для продолжения..." dummy ;; *) echo -e "\n${RED}Скрипт остановлен!${NC}\n"; exit 1 ;; esac; fi; fi; 
# ==========================================
# Получение версии
# ==========================================
get_versions() { LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release); [ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v "noarch" | sort -k3 -n | tail -n1 | awk '{print $2}')
USED_ARCH="$LOCAL_ARCH"; LATEST_URL="https://github.com/remittor/zapret-openwrt/releases/download/v${ZAPRET_VERSION}/zapret_v${ZAPRET_VERSION}_${LOCAL_ARCH}.zip"
INSTALLED_VER=$(opkg list-installed zapret | awk '{print $3}'); [ -z "$INSTALLED_VER" ] && INSTALLED_VER="не найдена"
ZAPRET_STATUS=$([ -f /etc/init.d/zapret ] && /etc/init.d/zapret status 2>/dev/null | grep -qi running && echo "${GREEN}запущен${NC}" || echo "${RED}остановлен${NC}"); [ -f /etc/init.d/zapret ] || ZAPRET_STATUS=""
[ "$INSTALLED_VER" = "$ZAPRET_VERSION" ] && INST_COLOR=$GREEN INSTALLED_DISPLAY="$INSTALLED_VER" || { INST_COLOR=$RED; INSTALLED_DISPLAY=$([ "$INSTALLED_VER" != "не найдена" ] && echo "$INSTALLED_VER (устарела)" || echo "$INSTALLED_VER"); }; }
# ==========================================
# Установка Zapret
# ==========================================
install_Zapret() { local NO_PAUSE=$1; get_versions; if [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ]; then echo -e "\n${GREEN}Последняя версия уже установлена!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; fi
[ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Устанавливаем ZAPRET${NC}"; if [ -f /etc/init.d/zapret ]; then echo -e "${CYAN}Останавливаем ${NC}zapret" && /etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; fi
echo -e "${CYAN}Обновляем список пакетов${NC}"; opkg update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении списка пакетов!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }
mkdir -p "$WORKDIR"; rm -f "$WORKDIR"/* 2>/dev/null; cd "$WORKDIR" || return; FILE_NAME=$(basename "$LATEST_URL"); if ! command -v unzip >/dev/null 2>&1; then
echo -e "${CYAN}Устанавливаем ${NC}unzip" && opkg install unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }; fi
echo -e "${CYAN}Скачиваем архив ${NC}$FILE_NAME"; wget -q "$LATEST_URL" -O "$FILE_NAME" || { echo -e "\n${RED}Не удалось скачать ${NC}$FILE_NAME\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }
echo -e "${CYAN}Распаковываем архив${NC}"; unzip -o "$FILE_NAME" >/dev/null; for PKG in zapret_*.ipk luci-app-zapret_*.ipk; do [ -f "$PKG" ] && echo -e "${CYAN}Устанавливаем ${NC}$PKG" && opkg install --force-reinstall "$PKG" >/dev/null 2>&1; done
echo -e "${CYAN}Удаляем временные файлы${NC}"; cd /; rm -rf "$WORKDIR" /tmp/*.ipk /tmp/*.zip /tmp/*zapret* 2>/dev/null; if [ -f /etc/init.d/zapret ]; then echo -e "${GREEN}Zapret установлен!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy; else echo -e "\n${RED}Zapret не был установлен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; fi; }
# ==========================================
# Установка скриптов
# ==========================================
show_script_50() { [ -f "/opt/zapret/init.d/openwrt/custom.d/50-script.sh" ] || return; line=$(head -n1 /opt/zapret/init.d/openwrt/custom.d/50-script.sh)
name=$(case "$line" in *QUIC*) echo "50-quic4all" ;; *stun*) echo "50-stun4all" ;; *"discord media"*) echo "50-discord-media" ;; *"discord subnets"*) echo "50-discord" ;; *) echo "" ;; esac); }
enable_discord_calls() { local NO_PAUSE=$1; [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }
[ "$NO_PAUSE" != "1" ] && clear && echo -e "${MAGENTA}Меню установки скриптов${NC}"; [ "$NO_PAUSE" = "1" ] && echo -e "${MAGENTA}Устанавливаем скрипт${NC}"; [ "$NO_PAUSE" != "1" ] && show_script_50 && [ -n "$name" ] && echo -e "\n${YELLOW}Установлен скрипт:${NC} $name"
if [ "$NO_PAUSE" = "1" ]; then SELECTED="50-stun4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all"; else
echo -e "\n${CYAN}1) ${GREEN}Установить скрипт ${NC}50-stun4all\n${CYAN}2) ${GREEN}Установить скрипт ${NC}50-quic4all\n${CYAN}3) ${GREEN}Установить скрипт ${NC}50-discord-media\n${CYAN}4) ${GREEN}Установить скрипт ${NC}50-discord"
echo -ne "${CYAN}5) ${GREEN}Удалить скрипт${NC}\n${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice; case "$choice" in
1) SELECTED="50-stun4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all" ;; 2) SELECTED="50-quic4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-quic4all" ;;
3) SELECTED="50-discord-media"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-discord-media" ;; 4) SELECTED="50-discord"; URL="https://raw.githubusercontent.com/bol-van/zapret/v70.5/init.d/custom.d.examples.linux/50-discord" ;;
5) echo -e "\n${GREEN}Скрипт удалён!${NC}\n"; rm -f "$CUSTOM_DIR/50-script.sh" 2>/dev/null; sed -i "s/,50000-50099//" "$CONF"; sed -i ':a;N;$!ba;s|--new\n--filter-udp=50000-50099\n--filter-l7=discord,stun\n--dpi-desync=fake\n*||g' "$CONF"
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1; read -p "Нажмите Enter для выхода в главное меню..." dummy; return ;; *) return ;; esac; fi
if wget -qO "$CUSTOM_DIR/50-script.sh" "$URL"; then [ "$NO_PAUSE" != "1" ] && echo; echo -e "${GREEN}Скрипт ${NC}$SELECTED${GREEN} успешно установлен!${NC}\n"; else echo -e "\n${RED}Ошибка при скачивании скрипта!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; fi
if ! grep -q "option NFQWS_PORTS_UDP.*50000-50099" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,50000-50099'/" "$CONF"; fi; if ! grep -q -- "--filter-udp=50000-50099" "$CONF"; then last_line1=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1)
if [ -n "$last_line1" ]; then sed -i "${last_line1},\$d" "$CONF"; fi; printf "%s\n" "--new" "--filter-udp=50000-50099" "--filter-l7=discord,stun" "--dpi-desync=fake" "'" >> "$CONF";
fi; chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1; [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy; }
# ==========================================
# FIX GAME
# ==========================================
fix_GAME() { local NO_PAUSE=$1; [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }
[ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Настраиваем стратегию для игр${NC}"; if grep -q "option NFQWS_PORTS_UDP.*1024-49999,50100-65535" "$CONF" && grep -q -- "--filter-udp=1024-49999,50100-65535" "$CONF"; then echo -e "${CYAN}Удаляем из стратегии настройки для игр${NC}"
sed -i ':a;N;$!ba;s|--new\n--filter-udp=1024-49999,50100-65535\n--dpi-desync=fake\n--dpi-desync-cutoff=d2\n--dpi-desync-any-protocol=1\n--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com\.bin\n*||g' "$CONF"
sed -i "s/,1024-49999,50100-65535//" "$CONF"; chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1; echo -e "${GREEN}Настройки для игр удалены!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; fi
if ! grep -q "option NFQWS_PORTS_UDP.*1024-49999,50100-65535" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,1024-49999,50100-65535'/" "$CONF"; fi; if ! grep -q -- "--filter-udp=1024-49999,50100-65535" "$CONF"; then last_line=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1)
if [ -n "$last_line" ]; then sed -i "${last_line},\$d" "$CONF"; fi; printf "%s\n" "--new" "--filter-udp=1024-49999,50100-65535" "--dpi-desync=fake" "--dpi-desync-cutoff=d2" "--dpi-desync-any-protocol=1" "--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com.bin" "'" >> "$CONF"; fi
echo -e "${CYAN}Добавляем в стратегию настройки для игр${NC}"; chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1; echo -e "${GREEN}Игровые настройки добавлены!${NC}\n";[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy; }
zapret_key(){ clear; echo -e "${MAGENTA}Удаление, установка и настройка Zapret${NC}\n"; get_versions; uninstall_zapret "1"; install_Zapret "1"; [ ! -f /etc/init.d/zapret ] && return; wget -qO- "https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/Str${STR_VERSION_AUTOINSTALL}.sh" | sh
if [ ! -f "$CONF" ]; then echo -e "\n${RED}Файл ${NC}$CONF${RED} не найден!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; fi; if ! grep -q "#v" "$CONF"; then echo -e "\n${RED}Cтратегия не установлена!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; fi
echo; enable_discord_calls "1"; fix_GAME "1"; echo -e "${GREEN}Zapret установлен и настроен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; }
# ==========================================
# Zapret под ключ
# ==========================================
zapret_key(){ clear; echo -e "${MAGENTA}Удаление, установка и настройка Zapret${NC}\n"
get_versions; uninstall_zapret "1"; install_Zapret "1"
[ ! -f /etc/init.d/zapret ] && return
menu_str "1"; echo; enable_discord_calls "1"; fix_GAME "1"; echo -e "${GREEN}Zapret установлен и настроен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; }
# ==========================================
# Вернуть настройки по умолчанию
# ==========================================
comeback_def () { if [ -f /opt/zapret/restore-def-cfg.sh ]; then echo -e "\n${MAGENTA}Возвращаем настройки по умолчанию${NC}"; rm -f /opt/zapret/init.d/openwrt/custom.d/50-script.sh; for i in 1 2 3 4; do rm -f "/opt/zapret/ipset/cust$i.txt"; done
[ -f /etc/init.d/zapret ] && /etc/init.d/zapret stop >/dev/null 2>&1; echo -e "${CYAN}Возвращаем ${NC}настройки${CYAN}, ${NC}стратегию${CYAN} и ${NC}hostlist${CYAN} к значениям по умолчанию${NC}"
for f in zapret-hosts-google.txt zapret-hosts-user-exclude.txt zapret-ip-exclude.txt; do wget -qO "/opt/zapret/ipset/$f" "https://raw.githubusercontent.com/remittor/zapret-openwrt/master/zapret/ipset/$f"; done
for f in zapret-hosts-user-ipban.txt zapret-ip-user-ipban.txt zapret-hosts-user.txt zapret-ip-user.txt zapret-ip-user-exclude.txt; do : > "/opt/zapret/ipset/$f"; done
chmod +x /opt/zapret/restore-def-cfg.sh && /opt/zapret/restore-def-cfg.sh; chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh; /etc/init.d/zapret restart >/dev/null 2>&1
sed -i '/185\.87\.51\.182 4pda\.to www\.4pda\.to/d; /130\.255\.77\.28 ntc\.party/d; /173\.245\.58\.219 rutor\.info d\.rutor\.info/d; /57\.144\.222\.34 instagram\.com www\.instagram\.com/d; /157\.240\.9\.174 instagram\.com www\.instagram\.com/d' /etc/hosts
/etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "${GREEN}Настройки по умолчанию возвращены!${NC}\n"; else echo -e "\n${RED}Zapret не установлен!${NC}\n"; fi; read -p "Нажмите Enter для выхода в главное меню..." dummy; }
# ==========================================
# Cтарт/стоп Zapret
# ==========================================
stop_zapret() { echo -e "\n${MAGENTA}Останавливаем Zapret${NC}\n${CYAN}Останавливаем ${NC}Zapret"; /etc/init.d/zapret stop >/dev/null 2>&1
for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; echo -e "${GREEN}Zapret остановлен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; }
start_zapret() { if [ -f /etc/init.d/zapret ]; then echo -e "\n${MAGENTA}Запускаем Zapret${NC}"; echo -e "${CYAN}Запускаем ${NC}Zapret";
/etc/init.d/zapret start >/dev/null 2>&1; chmod +x /opt/zapret/sync_config.sh; /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
echo -e "${GREEN}Zapret запущен!${NC}\n"; else echo -e "\n${RED}Zapret не установлен!${NC}\n"; fi; read -p "Нажмите Enter для выхода в главное меню..." dummy; }
# ==========================================
# Полное удаление Zapret
# ==========================================
uninstall_zapret() { local NO_PAUSE=$1
[ "$NO_PAUSE" != "1" ] && echo
echo -e "${MAGENTA}Удаляем ZAPRET${NC}\n${CYAN}Останавливаем ${NC}zapret\n${CYAN}Убиваем процессы${NC}"
/etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done
echo -e "${CYAN}Удаляем пакеты${NC}"; opkg --force-removal-of-dependent-packages --autoremove remove zapret luci-app-zapret >/dev/null 2>&1
echo -e "${CYAN}Удаляем временные файлы${NC}"; rm -rf /opt/zapret /etc/config/zapret /etc/firewall.zapret /etc/init.d/zapret /tmp/*zapret* /var/run/*zapret* /tmp/*.ipk /tmp/*.zip 2>/dev/null
crontab -l 2>/dev/null | grep -v -i "zapret" | crontab - 2>/dev/null; nft list tables 2>/dev/null | awk '{print $2}' | grep -E '(zapret|ZAPRET)' | while read t; do [ -n "$t" ] && nft delete table "$t" 2>/dev/null; done
sed -i '/185\.87\.51\.182 4pda\.to www\.4pda\.to/d; /130\.255\.77\.28 ntc\.party/d; /173\.245\.58\.219 rutor\.info d\.rutor\.info/d; /57\.144\.222\.34 instagram\.com www\.instagram\.com/d; /157\.240\.9\.174 instagram\.com www\.instagram\.com/d' /etc/hosts
/etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "${GREEN}Zapret полностью удалён!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy; }
# ==========================================
# Выбор стратегий
# ==========================================
show_current_strategy() { [ -f "$CONF" ] || return; for v in v1 v2 v3 v4 v5; do grep -q "#$v" "$CONF" && { ver="$v"; return; } done
grep -q -- "--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt" "$CONF" && grep -q -- "--hostlist-exclude-domains=openwrt.org" "$CONF" && ver="дефолтная"; }
menu_str() { local NO_PAUSE=$1; [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter для выхода в главное меню..." dummy; return; }
if [ "$NO_PAUSE" = "1" ]; then version=$STR_VERSION_AUTOINSTALL
else clear; echo -e "${MAGENTA}Меню выбора стратегии${NC}"; show_current_strategy && [ -n "$ver" ] && echo -e "\n${YELLOW}Используется стратегия:${NC} $ver\n"
echo -e "${CYAN}1) ${GREEN}Установить стратегию${NC} v1\n${CYAN}2) ${GREEN}Установить стратегию${NC} v2\n${CYAN}3) ${GREEN}Установить стратегию${NC} v3\n${CYAN}4) ${GREEN}Установить стратегию${NC} v4"
echo -ne "${CYAN}5) ${GREEN}Установить стратегию${NC} v5\n${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in 1) version="v1" ;; 2) version="v2" ;; 3) version="v3" ;; 4) version="v4" ;; 5) version="v5" ;; *) return ;; esac; fi
[ "$NO_PAUSE" != "1" ] && echo
echo -e "${MAGENTA}Устанавливаем стратегию ${version}${NC}\n${CYAN}Меняем стратегию${NC}"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"
strategy_v1() { \
printf '%s\n' "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,multidisorder" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=badseq" | cat; \
printf '%s\n' "--dpi-desync-badseq-increment=10000000" "--dpi-desync-repeats=6" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com" "--new" | cat; \
printf '%s\n' "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin" | cat; \
}
strategy_v2() { \
printf '%s\n' "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=10,midsld" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" | cat; \
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin" "--dpi-desync-split-seqovl=336" | cat; \
printf '%s\n' "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0" "--new" "--filter-udp=443" | cat; \
printf '%s\n' "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin" | cat; \
}
strategy_v3() { \
printf '%s\n' "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--ip-id=zero" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" | cat; \
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=10,midsld" "--dpi-desync-fake-tls=/opt/zapret/files/fake/t2.bin" | cat; \
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=m.ok.ru" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin" | cat; \
printf '%s\n' "--dpi-desync-split-seqovl=336" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0" | cat; \
printf '%s\n' "--new" "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin" | cat; \
}
strategy_v4() { \
printf '%s\n' "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" | cat; \
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=google.com" "--dpi-desync-split-seqovl=2108" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badseq" "--new" "--filter-tcp=443" | cat; \
printf '%s\n' "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync-any-protocol=1" "--dpi-desync-cutoff=n5" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=582" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/4pda.bin" | cat; \
printf '%s\n' "--new" "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin" | cat; \
}
strategy_v5() { \
printf '%s\n' "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--ip-id=zero" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" | cat; \
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=10,midsld" "--dpi-desync-fake-tls=/opt/zapret/files/fake/max.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid" | cat; \
printf '%s\n' "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0" "--new" "--filter-udp=443" | cat; \
printf '%s\n' "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin" | cat; \
}
{ echo "  option NFQWS_OPT '"; echo "#${version} УДАЛИТЕ ЭТУ СТРОЧКУ, ЕСЛИ ИЗМЕНЯЕТЕ СТРАТЕГИЮ !!!"; strategy_${version}; echo "'"; } >> "$CONF"
echo -e "${CYAN}Добавляем домены в исключения${NC}"; rm -f "$EXCLUDE_FILE"; wget -q -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || echo -e "\n${RED}Не удалось загрузить exclude файл${NC}\n"
case "$version" in v3) echo -e "${CYAN}Копируем ${NC}t2.bin${CYAN} на устройство${NC}"; file="t2.bin" ;;
v4) echo -e "${CYAN}Копируем ${NC}4pda.bin${CYAN} на устройство${NC}"; file="4pda.bin" ;; v5) echo -e "${CYAN}Копируем ${NC}max.bin${CYAN} на устройство${NC}"; file="max.bin" ;;
esac; [ -n "$file" ] && wget -q -O "/opt/zapret/files/fake/$file" "https://github.com/StressOzz/Zapret-Manager/raw/refs/heads/main/$file"; echo -e "${CYAN}Редактируем ${NC}/etc/hosts${NC}"
printf '%s\n' "130.255.77.28 ntc.party" "185.87.51.182 4pda.to www.4pda.to" "173.245.58.219 rutor.info d.rutor.info" "57.144.222.34 instagram.com www.instagram.com" "157.240.9.174 instagram.com www.instagram.com" | grep -Fxv -f /etc/hosts 2>/dev/null >> /etc/hosts; /etc/init.d/dnsmasq restart >/dev/null 2>&1;
fileGP="/opt/zapret/ipset/zapret-hosts-google.txt"; printf '%s\n' "android.clients.google.com" "beacons.gvt2.com" "connectivitycheck.gstatic.com" "googleplay.com" "gvt1.com" "lh3.googleusercontent.com" "play.google.com" "play.googleapis.com" | grep -Fxv -f "$fileGP" 2>/dev/null >> "$fileGP"
printf '%s\n' "play-fe.googleapis.com" "play-games.googleusercontent.com" "play-lh.googleusercontent.com" "prod-lt-playstoregatewayadapter-pa.googleapis.com" | grep -Fxv -f "$fileGP" 2>/dev/null >> "$fileGP"
echo -e "${CYAN}Применяем новую стратегию и настройки${NC}"; chmod +x /opt/zapret/sync_config.sh; /opt/zapret/sync_config.sh; /etc/init.d/zapret restart >/dev/null 2>&1; echo -e "${GREEN}Стратегия ${NC}${version} ${GREEN}установлена!${NC}"
[ "$NO_PAUSE" != "1" ] && echo && read -p "Нажмите Enter для выхода в главное меню..." dummy; }
# ==========================================
# DNS over HTTP
# ==========================================
D_o_H() {
if opkg list-installed | grep -q '^https-dns-proxy '; then echo -e "\n${MAGENTA}Удаляем DNS over HTTPS\n${CYAN}Удаляем пакеты${NC}"; /etc/init.d/https-dns-proxy stop >/dev/null 2>&1; /etc/init.d/https-dns-proxy disable >/dev/null 2>&1
opkg remove https-dns-proxy luci-app-https-dns-proxy --force-removal-of-dependent-packages >/dev/null 2>&1; echo -e "${CYAN}Удаляем файлы конфигурации ${NC}"
rm -f /etc/config/https-dns-proxy; rm -f /etc/init.d/https-dns-proxy; echo -e "DNS over HTTPS${GREEN} удалён!${NC}\n"; else echo -e "\n${MAGENTA}Устанавливаем и настраиваем DNS over HTTPS\n${CYAN}Обновляем список пакетов${NC}"
opkg update >/dev/null 2>&1; echo -e "${CYAN}Устанавливаем ${NC}https-dns-proxy"; opkg install https-dns-proxy >/dev/null 2>&1
echo -e "${CYAN}Устанавливаем ${NC}luci-app-https-dns-proxy"; opkg install luci-app-https-dns-proxy >/dev/null 2>&1; echo -e "${CYAN}Настраиваем ${NC}Comss.one DNS"; fileDoH="/etc/config/https-dns-proxy"; rm -f "$fileDoH"
printf '%s\n' "config main 'config'" "	option canary_domains_icloud '1'" "	option canary_domains_mozilla '1'" "	option dnsmasq_config_update '*'" "	option force_dns '1'" "	list force_dns_port '53'" "	list force_dns_port '853'" \
"	list force_dns_src_interface 'lan'" "	option procd_trigger_wan6 '0'" "	option heartbeat_domain 'heartbeat.melmac.ca'" "	option heartbeat_sleep_timeout '10'" "	option heartbeat_wait_timeout '10'" "	option user 'nobody'" "	option group 'nogroup'" \
"	option listen_addr '127.0.0.1'" "" "config https-dns-proxy" "	option resolver_url 'https://dns.comss.one/dns-query'" > "$fileDoH"
/etc/init.d/https-dns-proxy enable >/dev/null 2>&1; /etc/init.d/https-dns-proxy restart >/dev/null 2>&1; echo -e "DNS over HTTPS${GREEN} установлен и настроен!${NC}\n"; fi; read -p "Нажмите Enter для выхода в главное меню..." dummy; }
# ==========================================
# Главное меню
# ==========================================
show_menu() { get_versions; clear
echo -e "╔════════════════════════════════════╗\n║     ${BLUE}Zapret on remittor Manager${NC}     ║\n╚════════════════════════════════════╝\n                     ${DGRAY}by StressOzz v$ZAPRET_MANAGER_VERSION${NC}"
echo -e "\n${YELLOW}Установленная версия:   ${INST_COLOR}$INSTALLED_DISPLAY${NC}"
[ -n "$ZAPRET_STATUS" ] && echo -e "${YELLOW}Статус Zapret:${NC}          $ZAPRET_STATUS"; show_script_50 && [ -n "$name" ] && echo -e "${YELLOW}Установлен скрипт:${NC}      $name"
[ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*1024-49999,50100-65535" "$CONF" && grep -q -- "--filter-udp=1024-49999,50100-65535" "$CONF" && echo -e "${YELLOW}Стратегия для игр:${NC}      ${GREEN}активирована${NC}"
if opkg list-installed | grep -q '^https-dns-proxy '; then if grep -q 'dns.comss.one' /etc/config/https-dns-proxy 2>/dev/null; then echo -e "${YELLOW}DNS over HTTPS:         ${GREEN}установлен / настроен${NC}"
else echo -e "${YELLOW}DNS over HTTPS:         ${GREEN}установлен${NC}"; fi; fi; show_current_strategy && [ -n "$ver" ] && echo -e "${YELLOW}Используется стратегия:${NC} ${CYAN}$ver${NC}"
echo -e "\n${CYAN}1) ${GREEN}Установить последнюю версию${NC}\n${CYAN}2) ${GREEN}Меню выбора стратегий${NC}\n${CYAN}3) ${GREEN}Вернуть настройки по умолчанию${NC}\n${CYAN}4) ${GREEN}Остановить / Запустить ${NC}Zapret"
echo -e "${CYAN}5) ${GREEN}Удалить ${NC}Zapret\n${CYAN}6) ${GREEN}Добавить / Удалить стратегию для игр\n${CYAN}7) ${GREEN}Меню установки скриптов${NC}\n${CYAN}8) ${GREEN}Удалить / Установить / Настроить${NC} Zapret"
echo -e "${CYAN}9) ${GREEN}Системная информация${NC}"; if opkg list-installed | grep -q '^https-dns-proxy '; then echo -e "${CYAN}0) ${GREEN}Удалить ${NC}DNS over HTTPS"
else echo -e "${CYAN}0) ${GREEN}Установить и настроить ${NC}DNS over HTTPS"; fi; echo -ne "${CYAN}Enter) ${GREEN}Выход${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in 1) install_Zapret ;; 2) menu_str ;; 3) comeback_def ;; 4) pgrep -f /opt/zapret >/dev/null 2>&1 && stop_zapret || start_zapret ;; 5) uninstall_zapret ;; 6) fix_GAME ;; 7) enable_discord_calls ;; 8) zapret_key ;;
9) wget -qO- https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/sys_info.sh | sh; echo; read -p "Нажмите Enter для выхода в главное меню..." dummy ;; 0) D_o_H ;; *) echo; exit 0 ;; esac; }
# ==========================================
# Старт скрипта
# ==========================================
while true; do show_menu; done
