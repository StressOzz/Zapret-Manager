#!/bin/sh
# ==========================================
# Zapret on remittor Manager by StressOzz
# =========================================
ZAPRET_MANAGER_VERSION="7.9"; ZAPRET_VERSION="72.20260108"; STR_VERSION_AUTOINSTALL="v6"
TEST_HOST="https://rr1---sn-gvnuxaxjvh-jx3z.googlevideo.com"; LAN_IP=$(uci get network.lan.ipaddr)
GREEN="\033[1;32m"; RED="\033[1;31m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"; BLUE="\033[0;34m"; NC="\033[0m"; DGRAY="\033[38;5;244m"
WORKDIR="/tmp/zapret-update"; CONF="/etc/config/zapret"; CUSTOM_DIR="/opt/zapret/init.d/openwrt/custom.d/"
STR_URL="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/ListStrYou"
TMP_LIST="/opt/zapret_yt_list.txt"; SAVED_STR="/opt/StrYou"; OLD_STR="/opt/StrOLD"
BACKUP_FILE="/opt/hosts_temp.txt"; HOSTLIST_FILE="/opt/zapret/ipset/zapret-hosts-user.txt"
HOSTLIST_MIN_SIZE=1800000; FINAL_STR="/opt/StrFINAL"; NEW_STR="/opt/StrNEW"; HOSTS_USER="/opt/hosts-user.txt"
EXCLUDE_FILE="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"; fileDoH="/etc/config/https-dns-proxy"
RKN_URL="https://raw.githubusercontent.com/IndeecFOX/zapret4rocket/refs/heads/master/extra_strats/TCP/RKN/List.txt"
EXCLUDE_URL="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/zapret-hosts-user-exclude.txt"
HOSTS_LIST="185.87.51.182 4pda.to www.4pda.to|130.255.77.28 ntc.party|30.255.77.28 ntc.party|173.245.58.219 rutor.info d.rutor.info|185.39.18.98 lib.rus.ec www.lib.rus.ec
57.144.222.34 instagram.com www.instagram.com|157.240.9.174 instagram.com www.instagram.com|157.240.245.174 instagram.com www.instagram.com|157.240.205.174 instagram.com www.instagram.com"
ZAPRET_RESTART () { chmod +x /opt/zapret/sync_config.sh; /opt/zapret/sync_config.sh; /etc/init.d/zapret restart >/dev/null 2>&1; }
hosts_add() { echo "$HOSTS_LIST" | tr '|' '\n' | grep -Fxv -f /etc/hosts >> /etc/hosts; /etc/init.d/dnsmasq restart >/dev/null 2>&1; }
hosts_clear() { for ip in 185.87.51.182 130.255.77.28 30.255.77.28 173.245.58.219 185.39.18.98 57.144.222.34 157.240.9.174 157.240.245.174 157.240.205.174; do sed -i "/$ip/d" /etc/hosts >/dev/null 2>&1; done; /etc/init.d/dnsmasq restart >/dev/null 2>&1; }
# ==========================================
# Получение версии
# ==========================================
get_versions() { LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release); [ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v "noarch" | sort -k3 -n | tail -n1 | awk '{print $2}')
USED_ARCH="$LOCAL_ARCH"; LATEST_URL="https://github.com/remittor/zapret-openwrt/releases/download/v${ZAPRET_VERSION}/zapret_v${ZAPRET_VERSION}_${LOCAL_ARCH}.zip"
INSTALLED_VER=$(opkg list-installed zapret | awk '{sub(/-r[0-9]+$/, "", $3); print $3}'); [ -z "$INSTALLED_VER" ] && INSTALLED_VER="не найдена"
ZAPRET_STATUS=$([ -f /etc/init.d/zapret ] && /etc/init.d/zapret status 2>/dev/null | grep -qi running && echo "${GREEN}запущен${NC}" || echo "${RED}остановлен${NC}"); [ -f /etc/init.d/zapret ] || ZAPRET_STATUS=""
[ "$INSTALLED_VER" = "$ZAPRET_VERSION" ] && INST_COLOR=$GREEN INSTALLED_DISPLAY="$INSTALLED_VER" || { INST_COLOR=$RED; INSTALLED_DISPLAY=$([ "$INSTALLED_VER" != "не найдена" ] && echo "$INSTALLED_VER" || echo "$INSTALLED_VER"); }; }
# ==========================================
# Установка Zapret
# ==========================================
install_Zapret() { local NO_PAUSE=$1; get_versions; if [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ]; then echo -e "\nZapret ${GREEN}уже установлен!${NC}\n"; read -p "Нажмите Enter..." dummy; return; fi
[ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Устанавливаем ZAPRET${NC}"; if [ -f /etc/init.d/zapret ]; then echo -e "${CYAN}Останавливаем ${NC}zapret" && /etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; fi
echo -e "${CYAN}Обновляем список пакетов${NC}"; opkg update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении списка пакетов!${NC}\n"; read -p "Нажмите Enter..." dummy; return; }
mkdir -p "$WORKDIR"; rm -f "$WORKDIR"/* 2>/dev/null; cd "$WORKDIR" || return; FILE_NAME=$(basename "$LATEST_URL"); if ! command -v unzip >/dev/null 2>&1; then
echo -e "${CYAN}Устанавливаем ${NC}unzip" && opkg install unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}\n"; read -p "Нажмите Enter..." dummy; return; }; fi
echo -e "${CYAN}Скачиваем архив ${NC}$FILE_NAME"; wget -q -U "Mozilla/5.0" -O "$FILE_NAME" "$LATEST_URL" || { echo -e "\n${RED}Не удалось скачать ${NC}$FILE_NAME\n"; read -p "Нажмите Enter..." dummy; return; }
echo -e "${CYAN}Распаковываем архив${NC}"; unzip -o "$FILE_NAME" >/dev/null; for PKG in zapret_*.ipk luci-app-zapret_*.ipk; do [ -f "$PKG" ] && echo -e "${CYAN}Устанавливаем ${NC}$PKG" && opkg install --force-reinstall "$PKG" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить $PKG!${NC}\n"
read -p "Нажмите Enter..." dummy; return; } ; done; echo -e "${CYAN}Удаляем временные файлы${NC}"; cd /; rm -rf "$WORKDIR" /tmp/*.ipk /tmp/*.zip /tmp/*zapret* 2>/dev/null; if [ -f /etc/init.d/zapret ]; then echo -e "Zapret ${GREEN}установлен!${NC}\n"
[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter..." dummy; else echo -e "\n${RED}Zapret не был установлен!${NC}\n"; read -p "Нажмите Enter..." dummy; fi; }
# ==========================================
# Меню настройки Discord
# ==========================================
Fin_IP_Dis="104\.25\.158\.178 finland[0-9]\{5\}\.discord\.media"; STRAT1="--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=multisplit\n--dpi-desync-split-seqovl=652\n--dpi-desync-split-pos=2\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
STRAT2="--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,multisplit\n--dpi-desync-split-seqovl=681\n--dpi-desync-split-pos=1\n--dpi-desync-fooling=ts\n--dpi-desync-repeats=8\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin\n--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com"
switch_Dv() { CURRENT=$(grep -o -E '#[[:space:]]*Dv[12]' "$CONF" | cut -d'v' -f2); [ -z "$CURRENT" ] && CURRENT=1; if [ "$CURRENT" = "1" ]; then NEW_STRAT="$STRAT2"; NEW_NUM=2; else NEW_STRAT="$STRAT1"; NEW_NUM=1; fi
grep -q -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" || { echo "ERROR: strategy block not found" >&2; return 1; }; START=$(grep -n -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" | cut -d: -f1)
END=$(tail -n +"$START" "$CONF" | grep -n -m1 -E '^--new$|^'\''$' | cut -d: -f1); END=$((START + END -1)); sed -i "${START},$((END-1))d" "$CONF"; LINE=$START; echo "$NEW_STRAT" | while IFS= read -r l; do sed -i "${LINE}i$l" "$CONF"
LINE=$((LINE + 1)); done; if grep -q -E '^#[[:space:]]*Dv' "$CONF"; then sed -i "s/^#[[:space:]]*Dv[12]/#Dv$NEW_NUM/" "$CONF"; else sed -i "$START i#Dv$NEW_NUM" "$CONF"; fi
echo -e "\n${MAGENTA}Меняем стратегию для discord.media${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия для ${NC}discord.media ${GREEN}изменена!${NC}\n"; read -p "Нажмите Enter..." dummy; }
toggle_finland_hosts() { if grep -q "$Fin_IP_Dis" /etc/hosts; then sed -i "/$Fin_IP_Dis/d" /etc/hosts; echo -e "\n${MAGENTA}Удаляем Финские IP${NC}"; /etc/init.d/dnsmasq restart 2>/dev/null
echo -e "${GREEN}Финские ${NC}IP${GREEN} удалены${NC}\n"; else seq 10000 10199 | awk '{print "104.25.158.178 finland"$1".discord.media"}' | grep -vxFf /etc/hosts >> /etc/hosts; echo -e "\n${MAGENTA}Добавляем Финские IP${NC}"; /etc/init.d/dnsmasq restart 2>/dev/null
echo -e "${GREEN}Финские ${NC}IP${GREEN} добавлены${NC}\n"; fi; read -p "Нажмите Enter..." dummy; }
show_script_50() { [ -f "/opt/zapret/init.d/openwrt/custom.d/50-script.sh" ] || return; line=$(head -n1 /opt/zapret/init.d/openwrt/custom.d/50-script.sh)
name=$(case "$line" in *QUIC*) echo "50-quic4all" ;; *stun*) echo "50-stun4all" ;; *"discord media"*) echo "50-discord-media" ;; *"discord subnets"*) echo "50-discord" ;; *) echo "" ;; esac); }
scrypt_install() { local NO_PAUSE=$1; while true; do [ "$NO_PAUSE" != "1" ] && clear && echo -e "${MAGENTA}Меню настройки Discord${NC}\n"; output_shown=false
[ "$NO_PAUSE" != "1" ] && show_script_50 && [ -n "$name" ] && echo -e "${YELLOW}Установлен скрипт:${NC} $name" && output_shown=true
[ "$NO_PAUSE" != "1" ] && grep -q "$Fin_IP_Dis" /etc/hosts && echo -e "${YELLOW}Финские IP для Discord: ${GREEN}включены${NC}" && output_shown=true
[ "$NO_PAUSE" != "1" ] && NUMDv=$(grep -o -E '^#[[:space:]]*Dv[12]' "$CONF" | grep -o '[12]' | head -n1) && [ -n "$NUMDv" ] && echo -e "${YELLOW}Стратегия для discord.media: ${CYAN}Dv$NUMDv${NC}"  && output_shown=true
$output_shown && echo; if [ "$NO_PAUSE" = "1" ]; then SELECTED="50-stun4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all"; else
echo -e "${CYAN}1) ${GREEN}Установить скрипт ${NC}50-stun4all\n${CYAN}2) ${GREEN}Установить скрипт ${NC}50-quic4all\n${CYAN}3) ${GREEN}Установить скрипт ${NC}50-discord-media\n${CYAN}4) ${GREEN}Установить скрипт ${NC}50-discord\n${CYAN}5) ${GREEN}Удалить скрипт${NC}"
grep -q '104\.25\.158\.178 finland[0-9]\{5\}\.discord\.media' /etc/hosts && FIN_TXT="${GREEN}Удалить Финские ${NC}IP ${GREEN}из ${NC}hosts" || FIN_TXT="${GREEN}Добавить Финские ${NC}IP ${GREEN}в ${NC}hosts"
echo -ne "${CYAN}6) $FIN_TXT\n${CYAN}7) ${GREEN}Сменить стратегию для ${NC}discord.media\n${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choiceSC; case "$choiceSC" in
1) SELECTED="50-stun4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all" ;; 2) SELECTED="50-quic4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-quic4all" ;;
3) SELECTED="50-discord-media"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-discord-media" ;; 4) SELECTED="50-discord"; URL="https://raw.githubusercontent.com/bol-van/zapret/v70.5/init.d/custom.d.examples.linux/50-discord" ;;
5) [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter..." dummy; continue; }; echo -e "\n${MAGENTA}Удаляем скрипт${NC}"; rm -f "$CUSTOM_DIR/50-script.sh" 2>/dev/null; ZAPRET_RESTART; echo -e "${GREEN}Скрипт удалён!${NC}\n"; read -p "Нажмите Enter..." dummy; continue ;; 
6) toggle_finland_hosts; continue ;; 7) switch_Dv; continue ;; *) return ;; esac; fi; [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter..." dummy; continue; }
if wget -q -U "Mozilla/5.0" -O "$CUSTOM_DIR/50-script.sh" "$URL"; then [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Устанавливаем скрипт${NC}\n${GREEN}Скрипт ${NC}$SELECTED${GREEN} успешно установлен!${NC}\n"; else echo -e "\n${RED}Ошибка при скачивании скрипта!${NC}\n"; read -p "Нажмите Enter..." dummy; continue; fi
sed -i "/DISABLE_CUSTOM/s/'1'/'0'/" /etc/config/zapret; ZAPRET_RESTART; [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter..." dummy; [ "$NO_PAUSE" = "1" ] && break; done }
# ==========================================
# FIX GAME
# ==========================================
fix_GAME() { local NO_PAUSE=$1; [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter..." dummy; return; }
[ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Настраиваем стратегию для игр${NC}"; if grep -q "option NFQWS_PORTS_UDP.*88,500,1024-19293,19345-49999,50101-65535" "$CONF" && grep -q -- "--filter-udp=88,500,1024-19293,19345-49999,50101-65535" "$CONF"; then echo -e "${CYAN}Удаляем настройки для игр${NC}"
sed -i ':a;N;$!ba;s|--new\n--filter-udp=88,500,1024-19293,19345-49999,50101-65535\n--dpi-desync=fake\n--dpi-desync-cutoff=d2\n--dpi-desync-any-protocol=1\n--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com\.bin\n*||g' "$CONF"
sed -i "s/,88,500,1024-19293,19345-49999,50101-65535//" "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Игровая стратегия удалена!${NC}\n"; read -p "Нажмите Enter..." dummy; return; fi
if ! grep -q "option NFQWS_PORTS_UDP.*88,500,1024-19293,19345-49999,50101-65535" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,88,500,1024-19293,19345-49999,50101-65535'/" "$CONF"; fi; if ! grep -q -- "--filter-udp=88,500,1024-19293,19345-49999,50101-65535" "$CONF"; then last_line=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1)
if [ -n "$last_line" ]; then sed -i "${last_line},\$d" "$CONF"; fi; printf "%s\n" "--new" "--filter-udp=88,500,1024-19293,19345-49999,50101-65535" "--dpi-desync=fake" "--dpi-desync-cutoff=d2" "--dpi-desync-any-protocol=1" "--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com.bin" "'" >> "$CONF"; fi
echo -e "${CYAN}Включаем настройки для игр${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Игровая стратегия включена!${NC}\n";[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter..." dummy; }
# ==========================================
# Zapret под ключ
# ==========================================
zapret_key() { clear; echo -e "${MAGENTA}Удаление, установка и настройка Zapret${NC}\n"; get_versions; uninstall_zapret "1"; install_Zapret "1"
[ ! -f /etc/init.d/zapret ] && return; install_strategy $STR_VERSION_AUTOINSTALL "1"; echo; scrypt_install "1"; fix_GAME "1"; echo -e "Zapret ${GREEN}установлен и настроен!${NC}\n"; read -p "Нажмите Enter..." dummy; }
# ==========================================
# Вернуть настройки по умолчанию
# ==========================================
comeback_def () { if [ -f /opt/zapret/restore-def-cfg.sh ]; then echo -e "\n${MAGENTA}Возвращаем настройки по умолчанию${NC}"; rm -f /opt/zapret/init.d/openwrt/custom.d/50-script.sh; for i in 1 2 3 4; do rm -f "/opt/zapret/ipset/cust$i.txt"; done
[ -f /etc/init.d/zapret ] && /etc/init.d/zapret stop >/dev/null 2>&1; echo -e "${CYAN}Возвращаем ${NC}настройки${CYAN}, ${NC}стратегию${CYAN} и ${NC}hostlist${CYAN} к значениям по умолчанию${NC}"; cp -f /opt/zapret/ipset_def/* /opt/zapret/ipset/
chmod +x /opt/zapret/restore-def-cfg.sh && /opt/zapret/restore-def-cfg.sh; ZAPRET_RESTART
hosts_clear; echo -e "Настройки по умолчанию ${GREEN}возвращены!${NC}\n"; else echo -e "\n${RED}Zapret не установлен!${NC}\n"; fi; read -p "Нажмите Enter..." dummy; }
# ==========================================
# Cтарт/стоп Zapret
# ==========================================
stop_zapret() { echo -e "\n${MAGENTA}Останавливаем Zapret${NC}\n${CYAN}Останавливаем ${NC}Zapret"; /etc/init.d/zapret stop >/dev/null 2>&1
for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; echo -e "Zapret ${GREEN}остановлен!${NC}\n"; read -p "Нажмите Enter..." dummy; }
start_zapret() { if [ -f /etc/init.d/zapret ]; then echo -e "\n${MAGENTA}Запускаем Zapret${NC}"; echo -e "${CYAN}Запускаем ${NC}Zapret"; /etc/init.d/zapret start >/dev/null 2>&1; ZAPRET_RESTART
echo -e "Zapret ${GREEN}запущен!${NC}\n"; else echo -e "\n${RED}Zapret не установлен!${NC}\n"; fi; read -p "Нажмите Enter..." dummy; }
# ==========================================
# Полное удаление Zapret
# ==========================================
uninstall_zapret() { local NO_PAUSE=$1; [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Удаляем ZAPRET${NC}\n${CYAN}Останавливаем ${NC}zapret\n${CYAN}Убиваем процессы${NC}"
/etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; echo -e "${CYAN}Удаляем пакеты${NC}"; opkg --force-removal-of-dependent-packages --autoremove remove zapret luci-app-zapret >/dev/null 2>&1
echo -e "${CYAN}Удаляем временные файлы${NC}"; rm -rf /opt/zapret /etc/config/zapret /etc/firewall.zapret /etc/init.d/zapret /tmp/*zapret* /var/run/*zapret* /tmp/*.ipk /tmp/*.zip 2>/dev/null; crontab -l 2>/dev/null | grep -v -i "zapret" | crontab - 2>/dev/null
nft list tables 2>/dev/null | awk '{print $2}' | grep -E '(zapret|ZAPRET)' | while read t; do [ -n "$t" ] && nft delete table "$t" 2>/dev/null; done;  rm -f "$FINAL_STR" "$NEW_STR" "$OLD_STR" "$SAVED_STR" "$TMP_LIST" $HOSTS_USER $BACKUP_FILE
hosts_clear; echo -e "Zapret ${GREEN}полностью удалён!${NC}\n"; [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter..." dummy; }
# ==========================================
# Подбор стратегии для Ютуб
# ==========================================
auto_stryou() { awk '/^[[:space:]]*option NFQWS_OPT '\''/{flag=1} flag{print}' "$CONF" > "$OLD_STR"; curl -fsSL "$STR_URL" -o "$TMP_LIST" || { echo -e "\n${RED}Не удалось скачать список${NC}\n"; read -p "Нажмите Enter..." dummy </dev/tty; return 1; }
TOTAL=$(grep -c '^Yv[0-9]\+' "$TMP_LIST"); echo -e "\n${MAGENTA}Подбираем стратегию для ${NC}YouTube${NC}"; echo -e "${CYAN}Найдено ${NC}$TOTAL${CYAN} стратегий${NC}"; CURRENT_NAME=""; CURRENT_BODY=""; COUNT=0; apply_strategy() { NAME="$1"; BODY="$2"
sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; { echo "  option NFQWS_OPT '"; echo "#AUTO $NAME"; printf "%b\n" "$BODY"; echo "'"; } >> "$CONF"; ZAPRET_RESTART; }
check_access() { curl -s --connect-timeout 4 -m 4 "$TEST_HOST" >/dev/null && echo "ok" || echo "fail"; }; while IFS= read -r LINE || [ -n "$LINE" ]; do if echo "$LINE" | grep -q '^Yv[0-9]\+'; then if [ -n "$CURRENT_NAME" ]; then COUNT=$((COUNT + 1))
echo -e "\n${CYAN}Проверяем стратегию: ${NC}$CURRENT_NAME ($COUNT/$TOTAL)"; apply_strategy "$CURRENT_NAME" "$CURRENT_BODY"; STATUS=$(check_access); if [ "$STATUS" = "ok" ]; then echo -e "${GREEN}Видео на ПК открывается!${NC}\n${YELLOW}Проверьте работу ${NC}YouTube${YELLOW} на других устройствах!${NC}"
echo -en "Enter${GREEN} - применить стратегию, ${NC}S/s${GREEN} - остановить, ${NC}N/n${GREEN} - продолжить подбор:${NC} "; read -r ANSWER </dev/tty
if [ -z "$ANSWER" ]; then { echo "#$CURRENT_NAME"; printf "%b\n" "$CURRENT_BODY"; } > "$SAVED_STR"; echo -e "${CYAN}Применяем стратегию и перезапускаем ${NC}Zapret"
awk '{if(skip){if($0=="--new"||$0~/\047/){skip=0;next}if($0~/^[[:space:]]*$/)next;next}if($0=="--filter-tcp=443"){getline n;if(n=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"){skip=1;next}else{print $0;print n;next}}if($0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt")has_google=1;if($0~/^[[:space:]]*#Yv/)next;print}' "$OLD_STR" > "$NEW_STR"
awk 'BEGIN{inserted=0;has_google=0}$0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"{has_google=1}$0=="--new"&&!inserted{while((getline l<"'"$SAVED_STR"'")>0)if(l!~/^[[:space:]]*$/)print l;print "--new";inserted=1;next}$0~/^[[:space:]]*option NFQWS_OPT \047$/&&!has_google&&!inserted{print;while((getline l<"'"$SAVED_STR"'")>0)if(l!~/^[[:space:]]*$/)print l;print "--new";inserted=1;next}{print}' "$NEW_STR" > "$FINAL_STR"
sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$FINAL_STR" >> "$CONF"; awk '{if($0=="--new"){if(prev!="--new")print}else print;prev=$0}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
grep -q "^[[:space:]]*' *\$" "$CONF" || echo "'" >> "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия применена!${NC}\n"; read -p "Нажмите Enter..." dummy </dev/tty; return 0; elif [[ "$ANSWER" =~ ^[Ss]$ ]]; then sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART
echo -e "\n${YELLOW}Подбор остановлен. Стратегия восстановлена.${NC}\n"; read -p "Нажмите Enter..." dummy </dev/tty; return 1; fi; else echo -e "${RED}Видео не открывается, продолжаем подбор...${NC}"; fi; fi; CURRENT_NAME="$LINE"; CURRENT_BODY=""; else [ -n "$LINE" ] && CURRENT_BODY="${CURRENT_BODY}${LINE}\n"; fi; done < "$TMP_LIST"
if [ -n "$CURRENT_NAME" ]; then COUNT=$((COUNT + 1)); echo -e "\n${CYAN}Проверяем стратегию: ${NC}$CURRENT_NAME ($COUNT/$TOTAL)"; apply_strategy "$CURRENT_NAME" "$CURRENT_BODY"; STATUS=$(check_access); if [ "$STATUS" = "ok" ]; then echo -e "${GREEN}Видео на ПК открывается!${NC}\n${YELLOW}Проверьте работу ${NC}YouTube${YELLOW} на других устройствах!${NC}"
echo -en "Enter${GREEN} - применить стратегию, ${NC}S/s${GREEN} - остановить, ${NC}N/n${GREEN} - продолжить подбор:${NC} "; read -r ANSWER </dev/tty; if [ -z "$ANSWER" ]; then { echo "#$CURRENT_NAME"; printf "%b\n" "$CURRENT_BODY"; } > "$SAVED_STR"; echo -e "${CYAN}Применяем стратегию и перезапускаем ${NC}Zapret"
awk '{ if(skip) { if($0=="--new" || $0 ~ /'\''/) { skip=0; print; next } next } if($0=="--filter-tcp=443") { getline next_line; if(next_line=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt") { skip=1; next } else { print $0; print next_line; next } } if($0~/^[[:space:]]*#Yv/) next; print }' "$OLD_STR" > $NEW_STR
awk 'BEGIN { inserted=0 } /^--new/ && !inserted { system("cat '"$SAVED_STR"'"); inserted=1 } { print }' $NEW_STR > $FINAL_STR; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat $FINAL_STR >> "$CONF"; ZAPRET_RESTART
echo -e "${GREEN}Стратегия применена!${NC}\n"; read -p "Нажмите Enter..." dummy </dev/tty; return 0; elif [[ "$ANSWER" =~ ^[Ss]$ ]]; then sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART
echo -e "\n${YELLOW}Подбор остановлен. Cтратегия восстановлена.${NC}\n"; read -p "Нажмите Enter..." dummy </dev/tty; return 1; fi; else echo -e "${RED}Видео не открывается...${NC}\n"; fi; fi; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART
echo -e "\n${RED}Рабочая стратегия для YouTube не найдена!${NC}\n"; read -p "Нажмите Enter..." dummy </dev/tty; return 1; }
# ==========================================
# РКН список ВКЛ / ВЫКЛ
# ==========================================
enable_rkn() { echo -e "\n${MAGENTA}Включаем списки РКН${NC}"; [ -f "$HOSTLIST_FILE" ] && cp "$HOSTLIST_FILE" $BACKUP_FILE && cp "$HOSTLIST_FILE" $HOSTS_USER
curl -fsSL "$RKN_URL" -o "$HOSTLIST_FILE" || { echo -e "\n${RED}Не удалось скачать список РКН${NC}\n"; read -p "Нажмите Enter..." dummy; return; }
sed -i 's|--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt|--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt|' "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Обход по спискам ${NC}РКН${GREEN} включен${NC}\n"; }
disable_rkn() { echo -e "\n${MAGENTA}Выключаем списки РКН${NC}"; sed -i 's|--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt|--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt|' "$CONF"
if [ -s $BACKUP_FILE ]; then cp $BACKUP_FILE "$HOSTLIST_FILE"; else : > "$HOSTLIST_FILE"; fi; rm -f $HOSTS_USER $BACKUP_FILE; ZAPRET_RESTART; echo -e "${GREEN}Обход по спискам ${NC}РКН${GREEN} выключен${NC}\n"; }
toggle_rkn_bypass() { if grep -q -- "--filter-tcp=443 ˂HOSTLIST˃" "$CONF"; then if [ -f "$HOSTLIST_FILE" ] && [ "$(wc -c < "$HOSTLIST_FILE")" -gt "$HOSTLIST_MIN_SIZE" ]; then disable_rkn; else [ -f "$HOSTLIST_FILE" ] && cp "$HOSTLIST_FILE" "$BACKUP_FILE"
enable_rkn; fi; read -p "Нажмите Enter..." dummy </dev/tty; return; fi; if grep -q -- "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "$CONF" && grep -qE "#v[1-99]" "$CONF"; then enable_rkn; read -p "Нажмите Enter..." dummy </dev/tty
elif grep -q -- "--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt" "$CONF"; then disable_rkn; read -p "Нажмите Enter..." dummy </dev/tty; else echo -e "\n${RED}Стратегия не подходит для списков РКН\n${NC}"; read -p "Нажмите Enter..." dummy </dev/tty; fi; }
RKN_Check() { if (grep -q -- "--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt" "$CONF" >/dev/null 2>&1 || grep -q -- "--filter-tcp=443 ˂HOSTLIST˃" "$CONF" >/dev/null 2>&1) && [ "$(wc -c < /opt/zapret/ipset/zapret-hosts-user.txt)" -gt 1800000 ]
then RKN_STATUS="/ РКН"; RKN_TEXT_MENU="${GREEN}Выключить обход по спискам${NC} РКН"; else RKN_STATUS=""; RKN_TEXT_MENU="${GREEN}Включить обход по спискам${NC} РКН"; fi; }
# ==========================================
# Стратегии
# ==========================================
strategy_v1() { printf '%s\n' "#v1" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,multidisorder" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=badseq"
printf '%s\n' "--dpi-desync-badseq-increment=10000000" "--dpi-desync-repeats=6" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com" "--new"
printf '%s\n' "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v2() { printf '%s\n' "#v2" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=10,midsld" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin" "--dpi-desync-split-seqovl=336"
printf '%s\n' "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0" "--new" "--filter-udp=443"
printf '%s\n' "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v3() { printf '%s\n' "#v3" "#Dv1" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--ip-id=zero" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=10,midsld" "--dpi-desync-fake-tls=/opt/zapret/files/fake/t2.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=m.ok.ru" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin"
printf '%s\n' "--dpi-desync-split-seqovl=336" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0"
printf '%s\n' "--new" "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v4() { printf '%s\n' "#v4" "#Yv15" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=google.com" "--dpi-desync-split-seqovl=2108" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badseq" "--new" "--filter-tcp=443"
printf '%s\n' "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync-any-protocol=1" "--dpi-desync-cutoff=n5" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=582" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/4pda.bin"
printf '%s\n' "--new" "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v5() { printf '%s\n' "#v5" "#Yv01" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--ip-id=zero" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=10,midsld" "--dpi-desync-fake-tls=/opt/zapret/files/fake/max.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid"
printf '%s\n' "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0" "--new" "--filter-udp=443"
printf '%s\n' "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v6() { printf '%s\n' "#v6" "#Yv03" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com" "--dpi-desync-split-seqovl=620" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badsum,badseq"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-hostfakesplit-mod=host=max.ru" "--dpi-desync-hostfakesplit-midhost=host-2" "--dpi-desync-split-seqovl=726" "--dpi-desync-fooling=badsum,badseq" "--dpi-desync-badseq-increment=0"; }
strategy_v7() { printf '%s\n' "#v7" "#Yv03" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com" "--dpi-desync-split-seqovl=620" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badsum,badseq"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=654" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=ts" "--dpi-desync-repeats=8" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/max.bin" "--dpi-desync-fake-tls=/opt/zapret/files/fake/max.bin"; }
# ==========================================
# Меню стратегий
# ==========================================
menu_str() { [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; read -p "Нажмите Enter..." dummy; return; }; while true; do show_current_strategy; RKN_Check; clear; echo -e "${MAGENTA}Меню стратегий${NC}\n"
menu_game=$( [ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*88,500,1024-19293,19345-49999,50101-65535" "$CONF" && grep -q -- "--filter-udp=88,500,1024-19293,19345-49999,50101-65535" "$CONF" && echo "Удалить стратегию для игр" || echo "Включить стратегию для игр" )
print=0; current="$ver$( [ -n "$ver" ] && [ -n "$yv_ver" ] && echo " / " )$yv_ver"; if [ -n "$current" ]; then echo -e "${YELLOW}Используется стратегия:${NC} $current $RKN_STATUS"; print=1; elif [ -n "$RKN_STATUS" ]; then echo -e "${YELLOW}Используется стратегия:${NC} РКН"; print=1; fi
[ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*88,500,1024-19293,19345-49999,50101-65535" "$CONF" && grep -q -- "--filter-udp=88,500,1024-19293,19345-49999,50101-65535" "$CONF" && echo -e "${YELLOW}Стратегия для игр:${NC} ${GREEN}включена${NC}" && print=1
[ "$print" -eq 1 ] && echo; echo -e "${CYAN}1) ${GREEN}Выбрать стратегию для установки ${NC}v1-v7\n${CYAN}2) ${GREEN}$menu_game\n${CYAN}3) $RKN_TEXT_MENU\n${CYAN}4) ${GREEN}Подобрать стратегию для ${NC}YouTube"
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read choiceST; case "$choiceST" in 1) strategy_CHOUSE ;; 2) fix_GAME ;; 3) toggle_rkn_bypass; continue ;; 4) auto_stryou ;; *) return ;; esac; done }
strategy_CHOUSE () { echo -ne "\n${YELLOW}Введите версию стратегии для установки (1-7):${NC} "; read -r choice; if [[ "$choice" =~ ^[1-7]$ ]]; then install_strategy "v$choice"; fi; }
show_current_strategy() { [ -f "$CONF" ] || return; ver=""; for i in $(seq 1 99); do grep -q "#v$i" "$CONF" && { ver="v$i"; break; }; done; yv_ver=""; for i in $(seq -w 1 99); do grep -q "#Yv$i" "$CONF" && { yv_ver="Yv$i"; break; }; done; }
discord_str_add() { if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,19294-19344,50000-50100'/" "$CONF"; fi
if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'$/,2053,2083,2087,2096,8443'/" "$CONF"; fi
if ! grep -q -- "--filter-udp=19294-19344,50000-50100" "$CONF"; then last_line1=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1); if [ -n "$last_line1" ]; then sed -i "${last_line1},\$d" "$CONF"; fi
printf "%s\n" "--new" "--filter-udp=19294-19344,50000-50100" "--filter-l7=discord,stun" "--dpi-desync=fake" "--dpi-desync-repeats=6" "#Dv1" "--new" "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" \
"--dpi-desync=multisplit" "--dpi-desync-split-seqovl=652" "--dpi-desync-split-pos=2" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "'" >> "$CONF"; fi; }
install_strategy() { local version="$1"; local NO_PAUSE="${2:-0}"; local fileGP="/opt/zapret/ipset/zapret-hosts-google.txt"; [ "$NO_PAUSE" != "1" ] && echo
echo -e "${MAGENTA}Устанавливаем стратегию ${version}${NC}\n${CYAN}Меняем стратегию${NC}"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; { echo "  option NFQWS_OPT '"; strategy_"$version"; echo "'"; } >> "$CONF"
printf '%s\n' "gvt1.com" "googleplay.com" "play.google.com" "beacons.gvt2.com" "play.googleapis.com" "play-fe.googleapis.com" "lh3.googleusercontent.com" "android.clients.google.com" "connectivitycheck.gstatic.com" \
"play-lh.googleusercontent.com" "play-games.googleusercontent.com" "prod-lt-playstoregatewayadapter-pa.googleapis.com" | grep -Fxv -f "$fileGP" 2>/dev/null >> "$fileGP"; echo -e "${CYAN}Редактируем ${NC}/etc/hosts${NC}"; hosts_add
echo -e "${CYAN}Добавляем домены в исключения${NC}"; rm -f "$EXCLUDE_FILE"; wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || echo -e "\n${RED}Не удалось загрузить exclude файл${NC}\n"
discord_str_add; echo -e "${CYAN}Применяем новую стратегию и настройки${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия ${NC}${version}${GREEN} установлена!${NC}"; [ "$NO_PAUSE" != "1" ] && echo && read -p "Нажмите Enter..." dummy; }
# ==========================================
# DNS over HTTPS
# ==========================================
DoH_menu() { while true; do get_doh_status; clear; echo -e "${MAGENTA}Меню DNS over HTTPS${NC}\n"; opkg list-installed | grep -q '^https-dns-proxy ' && doh_st="Удалить" || doh_st="Установить"
[ -n "$DOH_STATUS" ] && opkg list-installed | grep -q '^https-dns-proxy ' && echo -e "${YELLOW}DNS over HTTPS: ${NC}$DOH_STATUS\n"
echo -e "${CYAN}1)${GREEN} $doh_st ${NC}DNS over HTTPS\n${CYAN}2)${GREEN} Настроить ${NC}Comss DNS\n${CYAN}3)${GREEN} Настроить ${NC}Xbox DNS\n${CYAN}4)${GREEN} Настроить ${NC}dns.malw.link"
echo -e "${CYAN}5)${GREEN} Настроить ${NC}dns.malw.link (CloudFlare)\n${CYAN}6)${GREEN} Настроить ${NC}dns.mafioznik.xyz\n${CYAN}7)${GREEN} Настроить ${NC}dns.astracat.ru\n${CYAN}0)${GREEN} Вернуть ${NC}настройки по умолчанию"
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r choiceDOH; [ -z "$choiceDOH" ] && return; case "$choiceDOH" in 1) D_o_H ;; 2) doh_install && setup_doh "$doh_comss" "Comss.one DNS" ;;
3) doh_install && setup_doh "$doh_xbox" "Xbox DNS" ;; 4) doh_install && setup_doh "$doh_query" "dns.malw.link" ;; 5) doh_install && setup_doh "$doh_queryCF" "dns.malw.link (CloudFlare)" ;;
6) doh_install && setup_doh "$doh_mafioznik" "dns.mafioznik.xyz" ;; 7) doh_install && setup_doh "$doh_astracat" "dns.astracat.ru" ;; 0) doh_install && setup_doh "$doh_def" "настройки по умолчанию" ;; *) return ;; esac; done; }
setup_doh() { local config="$1"; local name="$2"; echo -e "\n${MAGENTA}Настраиваем DNS over HTTPS${NC}\n${CYAN}Настраиваем ${NC}$name\n${CYAN}Применяем новые настройки${NC}"
rm -f "$fileDoH"; printf '%s\n' "$doh_set" "$config" > "$fileDoH"; /etc/init.d/https-dns-proxy reload >/dev/null 2>&1; /etc/init.d/https-dns-proxy restart >/dev/null 2>&1; echo -e "DNS over HTTP ${GREEN}настроен!${NC}\n"; read -p "Нажмите Enter..." dummy; }
get_doh_status() { DOH_STATUS=""; [ ! -f "$fileDoH" ] && return; if grep -q "dns.comss.one" "$fileDoH"; then DOH_STATUS="Comss DNS"; elif grep -q "xbox-dns.ru" "$fileDoH"; then DOH_STATUS="Xbox DNS"; elif grep -q "5u35p8m9i7.cloudflare-gateway.com" "$fileDoH"
then DOH_STATUS="dns.malw.link (CloudFlare)"; elif grep -q "dns.malw.link" "$fileDoH"; then DOH_STATUS="dns.malw.link"; elif grep -q "dns.mafioznik.xyz" "$fileDoH"; then DOH_STATUS="dns.mafioznik.xyz"; elif grep -q "dns.astracat.ru" "$fileDoH"; then DOH_STATUS="dns.astracat.ru"; else DOH_STATUS="установлен"; fi; }
D_o_H() { if opkg list-installed | grep -q '^https-dns-proxy '; then echo -e "\n${MAGENTA}Удаляем DNS over HTTPS\n${CYAN}Удаляем пакеты${NC}"; opkg --force-removal-of-dependent-packages --autoremove remove https-dns-proxy luci-app-https-dns-proxy >/dev/null 2>&1
echo -e "${CYAN}Удаляем файлы конфигурации ${NC}"; rm -f /etc/config/https-dns-proxy /etc/init.d/https-dns-proxy; echo -e "DNS over HTTPS${GREEN} удалён!${NC}\n"; read -p "Нажмите Enter..." dummy; else echo -e "\n${MAGENTA}Устанавливаем DNS over HTTPS\n${CYAN}Обновляем список пакетов${NC}"
opkg update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении списка пакетов!${NC}\n"; read -p "Нажмите Enter..." dummy; return; }; echo -e "${CYAN}Устанавливаем ${NC}https-dns-proxy"; opkg install https-dns-proxy >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установки!${NC}\n"; read -p "Нажмите Enter..." dummy; return; }
echo -e "${CYAN}Устанавливаем ${NC}luci-app-https-dns-proxy"; opkg install luci-app-https-dns-proxy >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установки!${NC}\n"; read -p "Нажмите Enter..." dummy; return; }; echo -e "DNS over HTTPS${GREEN} установлен!${NC}\n"; read -p "Нажмите Enter..." dummy; fi; }
doh_install() { [ -f "$fileDoH" ] && return 0; echo -e "\n${RED}DNS over HTTPS не установлен!${NC}\n"; read -p "Нажмите Enter..." dummy; return 1; }
doh_set=$(printf "%s\n" "config main 'config'" "	option canary_domains_icloud '1'" "	option canary_domains_mozilla '1'" "	option dnsmasq_config_update '*'" "	option force_dns '1'" "	list force_dns_port '53'" "	list force_dns_port '853'" \
"	list force_dns_src_interface 'lan'" "	option procd_trigger_wan6 '0'" "	option heartbeat_domain 'heartbeat.melmac.ca'" "	option heartbeat_sleep_timeout '10'" "	option heartbeat_wait_timeout '10'" "	option user 'nobody'" "	option group 'nogroup'" "	option listen_addr '127.0.0.1'")
doh_def=$(printf "%s\n" "" "config https-dns-proxy" "	option bootstrap_dns '1.1.1.1,1.0.0.1'" "	option resolver_url 'https://cloudflare-dns.com/dns-query'" "	option listen_port '5053'" "" "config https-dns-proxy" "	option bootstrap_dns '8.8.8.8,8.8.4.4'" "	option resolver_url 'https://dns.google/dns-query'" "	option listen_port '5054'")
doh_comss=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.comss.one/dns-query'"); doh_xbox=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://xbox-dns.ru/dns-query'")
doh_query=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.malw.link/dns-query'"); doh_queryCF=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://5u35p8m9i7.cloudflare-gateway.com/dns-query'")
doh_mafioznik=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.mafioznik.xyz/dns-query'"); doh_astracat=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.astracat.ru/dns-query'")
# ==========================================
# Доступ из браузера
# ==========================================
web_is_enabled() { command -v ttyd >/dev/null 2>&1 && uci -q get ttyd.@ttyd[0].command | grep -q "/usr/bin/zms"; }
toggle_web() { if web_is_enabled; then echo -e "\n${MAGENTA}Удаляем доступ из браузера${NC}";opkg remove luci-app-ttyd ttyd >/dev/null 2>&1; rm -f /etc/config/ttyd; rm -f /usr/bin/zms
echo -e "${GREEN}Доступ удалён!${NC}\n"; read -p "Нажмите Enter..." dummy; else echo -e "\n${MAGENTA}Активируем доступ из браузера${NC}"; echo 'sh <(wget -O - https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh)' > /usr/bin/zms
chmod +x /usr/bin/zms; echo -e "${CYAN}Обновляем список пакетов${NC}"; if ! opkg update >/dev/null 2>&1; then echo -e "\n${RED}Ошибка при обновлении!${NC}\n"; return; fi; echo -e "${CYAN}Устанавливаем ${NC}ttyd"
if ! opkg install ttyd >/dev/null 2>&1; then echo -e "\n${RED}Ошибка при установке ttyd!${NC}\n"; read -p "Нажмите Enter..." dummy; return; fi
echo -e "${CYAN}Устанавливаем ${NC}luci-app-ttyd"; if ! opkg install luci-app-ttyd >/dev/null 2>&1; then echo -e "\n${RED}Ошибка при установке luci-app-ttyd!${NC}\n"; read -p "Нажмите Enter..." dummy; return; fi
echo -e "${CYAN}Настраиваем ${NC}ttyd"; sed -i 's#/bin/login#-t fontSize=15 sh /usr/bin/zms#' /etc/config/ttyd; /etc/init.d/ttyd restart >/dev/null 2>&1; if pidof ttyd >/dev/null
then echo -e "${GREEN}Служба запущена!${NC}\n\n${YELLOW}Доступ: ${NC}$LAN_IP:7681\n"; read -p "Нажмите Enter..." dummy; else echo -e "\n${RED}Ошибка! Служба не запущена!${NC}\n"; read -p "Нажмите Enter..." dummy; fi; fi; }
# ==========================================
# Вкл/Выкл QUIC
# ==========================================
quic_is_blocked() { uci show firewall | grep -q "name='Block_UDP_80'" && uci show firewall | grep -q "name='Block_UDP_443'"; }
toggle_quic() {	if quic_is_blocked; then echo -e "\n${MAGENTA}Отключаем блокировку QUIC${NC}"; for RULE in Block_UDP_80 Block_UDP_443; do
while true; do IDX=$(uci show firewall | grep "name='$RULE'" | cut -d. -f2 | cut -d= -f1 | head -n1); [ -z "$IDX" ] && break; uci delete firewall.$IDX >/dev/null 2>&1; done; done
uci commit firewall >/dev/null 2>&1; /etc/init.d/firewall restart >/dev/null 2>&1; echo -e "${GREEN}Блокировка ${NC}QUIC ${GREEN}отключена${NC}\n"; read -p "Нажмите Enter..." dummy; else echo -e "\n${MAGENTA}Включаем блокировку QUIC${NC}"
uci add firewall rule >/dev/null 2>&1; uci set firewall.@rule[-1].name='Block_UDP_80' >/dev/null 2>&1; uci add_list firewall.@rule[-1].proto='udp' >/dev/null 2>&1; uci set firewall.@rule[-1].src='lan' >/dev/null 2>&1
uci set firewall.@rule[-1].dest='wan' >/dev/null 2>&1; uci set firewall.@rule[-1].dest_port='80' >/dev/null 2>&1; uci set firewall.@rule[-1].target='REJECT' >/dev/null 2>&1
uci add firewall rule >/dev/null 2>&1; uci set firewall.@rule[-1].name='Block_UDP_443' >/dev/null 2>&1; uci add_list firewall.@rule[-1].proto='udp' >/dev/null 2>&1; uci set firewall.@rule[-1].src='lan' >/dev/null 2>&1
uci set firewall.@rule[-1].dest='wan' >/dev/null 2>&1; uci set firewall.@rule[-1].dest_port='443' >/dev/null 2>&1; uci set firewall.@rule[-1].target='REJECT' >/dev/null 2>&1
uci commit firewall >/dev/null 2>&1; /etc/init.d/firewall restart >/dev/null 2>&1;	echo -e "${GREEN}Блокировка ${NC}QUIC ${GREEN}включена${NC}\n";	read -p "Нажмите Enter..." dummy; fi; }
# ==========================================
# Системное меню
# ==========================================
sys_menu() { while true; do web_is_enabled && WEB_TEXT="Удалить доступ к скрипту из браузера" || WEB_TEXT="Активировать доступ к скрипту из браузера"
quic_is_blocked && QUIC_TEXT="${GREEN}Отключить блокировку${NC} QUIC ${GREEN}(80,443)${NC}" || QUIC_TEXT="${GREEN}Включить блокировку${NC} QUIC ${GREEN}(80,443)${NC}"
clear; echo -e "${MAGENTA}Системное меню${NC}\n"; printed=0; if web_is_enabled; then echo -e "${YELLOW}Доступ из браузера:${NC} $LAN_IP:7681"; printed=1; fi
if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then echo -e "${YELLOW}FIX для Flow Offloading:${NC} ${GREEN}включён${NC}"; printed=1; fi
if quic_is_blocked; then echo -e "${YELLOW}Блокировка QUIC: ${GREEN}включена${NC}"; printed=1; fi
[ "$printed" -eq 1 ] && echo; echo -e "${CYAN}1) ${GREEN}Системная информация${NC}\n${CYAN}2) ${GREEN}$WEB_TEXT${NC}\n${CYAN}3) ${GREEN}$QUIC_TEXT${NC}"
if uci get firewall.@defaults[0].flow_offloading 2>/dev/null | grep -q '^1$' || uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null | grep -q '^1$'
then if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then echo -e "${CYAN}0) ${GREEN}Отключить${NC} FIX ${GREEN}для${NC} Flow Offloading"
else echo -e "${CYAN}0) ${GREEN}Применить${NC} FIX ${GREEN}для${NC} Flow Offloading"; fi; fi
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read -r choiceMN; case "$choiceMN" in
1) wget -q -U "Mozilla/5.0" -O - https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/sys_info.sh | sh; echo; read -p "Нажмите Enter..." dummy ;; 2) toggle_web ;; 3) toggle_quic ;; 
0) if uci get firewall.@defaults[0].flow_offloading 2>/dev/null | grep -q '^1$' || uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null | grep -q '^1$'
then if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then echo -e "\n${MAGENTA}Отключаем FIX для Flow Offloading${NC}"
sed -i 's/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/meta l4proto { tcp, udp } flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc; fw4 restart >/dev/null 2>&1
echo -e "FIX ${GREEN}отключён!${NC}\n"; else echo -e "\n${MAGENTA}Применяем FIX для Flow Offloading${NC}"; sed -i 's/meta l4proto { tcp, udp } flow offload @ft;/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc
fw4 restart >/dev/null 2>&1; echo -e "FIX ${GREEN}успешно применён!${NC}\n"; fi; read -p "Нажмите Enter..." dummy; fi ;; *) echo; return ;; esac; done; }
# ==========================================
# Главное меню
# ==========================================
show_menu() { get_versions; get_doh_status; show_current_strategy; RKN_Check; clear; echo -e "╔════════════════════════════════════╗\n║     ${BLUE}Zapret on remittor Manager${NC}     ║\n╚════════════════════════════════════╝\n                     ${DGRAY}by StressOzz v$ZAPRET_MANAGER_VERSION${NC}"
for pkg in byedpi youtubeUnblock; do if opkg list-installed | grep -q "^$pkg"; then echo -e "\n${RED}Найден установленный ${NC}$pkg${RED}!${NC}\nZapret${RED} может работать некорректно с ${NC}$pkg${RED}!${NC}"; fi; done
if uci get firewall.@defaults[0].flow_offloading 2>/dev/null | grep -q '^1$' || uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null | grep -q '^1$'; then if ! grep -q 'meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc
then echo -e "\n${RED}Включён ${NC}Flow Offloading${RED}!${NC}\n${NC}Zapret${RED} некорректно работает с включённым ${NC}Flow Offloading${RED}!\nПримените ${NC}FIX${RED} в системном меню!${NC}"; fi; fi
pgrep -f "/opt/zapret" >/dev/null 2>&1 && str_stp_zpr="Остановить" || str_stp_zpr="Запустить"; echo -e "\n${YELLOW}Установленная версия:    ${INST_COLOR}$INSTALLED_DISPLAY${NC}"; [ -n "$ZAPRET_STATUS" ] && echo -e "${YELLOW}Статус Zapret:${NC}           $ZAPRET_STATUS"
show_script_50 && [ -n "$name" ] && echo -e "${YELLOW}Установлен скрипт:${NC}       $name"; grep -q "$Fin_IP_Dis" /etc/hosts && echo -e "${YELLOW}Финские IP для Discord:  ${GREEN}включены${NC}"
[ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*88,500,1024-19293,19345-49999,50101-65535" "$CONF" && grep -q -- "--filter-udp=88,500,1024-19293,19345-49999,50101-65535" "$CONF" && echo -e "${YELLOW}Стратегия для игр:${NC}       ${GREEN}включена${NC}"
[ -n "$DOH_STATUS" ] && opkg list-installed | grep -q '^https-dns-proxy ' && echo -e "${YELLOW}DNS over HTTPS:${NC}          $DOH_STATUS"; web_is_enabled && if web_is_enabled; then echo -e "${YELLOW}Доступ из браузера:${NC}      $LAN_IP:7681"; fi
quic_is_blocked && if quic_is_blocked; then echo -e "${YELLOW}Блокировка QUIC:${NC}         ${GREEN}включена${NC}"; fi; if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc
then echo -e "${YELLOW}FIX для Flow Offloading:${NC} ${GREEN}включён${NC}"; fi; if [ -f "$CONF" ]; then current="$ver$( [ -n "$ver" ] && [ -n "$yv_ver" ] && echo " / " )$yv_ver"; DV=$(grep -o -E '^#[[:space:]]*Dv[12]' "$CONF" | sed 's/^#[[:space:]]*/\/ /' | head -n1)
if [ -n "$current" ]; then echo -e "${YELLOW}Используется стратегия:${NC}  ${CYAN}$current $DV $RKN_STATUS${NC}"; elif [ -n "$RKN_STATUS" ]; then echo -e "${YELLOW}Используется стратегия:${NC}${CYAN}  РКН $DV${NC}"; fi; fi
echo -e "\n${CYAN}1) ${GREEN}Установить${NC} Zapret\n${CYAN}2) ${GREEN}Меню стратегий${NC}\n${CYAN}3) ${GREEN}Вернуть ${NC}настройки по умолчанию\n${CYAN}4) ${GREEN}$str_stp_zpr ${NC}Zapret"
echo -e "${CYAN}5) ${GREEN}Удалить ${NC}Zapret\n${CYAN}6) ${GREEN}Меню настройки ${NC}Discord\n${CYAN}7) ${GREEN}Меню ${NC}DNS over HTTPS\n${CYAN}8) ${GREEN}Удалить → установить → настроить${NC} Zapret\n${CYAN}0) ${GREEN}Системное меню${NC}" ; echo -ne "${CYAN}Enter) ${GREEN}Выход${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in 1) install_Zapret ;; 2) menu_str ;; 3) comeback_def ;; 4) pgrep -f /opt/zapret >/dev/null 2>&1 && stop_zapret || start_zapret ;; 5) uninstall_zapret ;; 6) scrypt_install ;; 7) DoH_menu ;; 8) zapret_key ;; 
888) echo; uninstall_zapret "1"; install_Zapret "1"; curl -fsSL https://raw.githubusercontent.com/StressOzz/Test/refs/heads/main/zapret -o "$CONF"; ZAPRET_RESTART; echo -e "\033[5m${GREEN}OK${NC}"; read -n 1 -s ;; 0) sys_menu ;; *) echo; exit 0 ;; esac; }
# ==========================================
# Старт скрипта
# ==========================================
while true; do show_menu; done
