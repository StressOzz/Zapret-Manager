#!/bin/sh
# ==========================================
# Zapret on remittor Manager by StressOzz
# =========================================
ZAPRET_MANAGER_VERSION="9.0"; ZAPRET_VERSION="72.20260207"; STR_VERSION_AUTOINSTALL="v1"
TEST_HOST="https://rr1---sn-gvnuxaxjvh-jx3z.googlevideo.com"; LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null | cut -d/ -f1)
GREEN="\033[1;32m"; RED="\033[1;31m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"; MAGENTA="\033[1;35m"; BLUE="\033[0;34m"; NC="\033[0m"; DGRAY="\033[38;5;244m"
CONF="/etc/config/zapret"; CUSTOM_DIR="/opt/zapret/init.d/openwrt/custom.d/"; HOSTLIST_FILE="/opt/zapret/ipset/zapret-hosts-user.txt"
STR_URL="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/ListStrYou"
TMP_SF="/tmp/zapret_temp"; HOSTS_FILE="/etc/hosts"; TMP_LIST="$TMP_SF/zapret_yt_list.txt"
SAVED_STR="$TMP_SF/StrYou.txt"; HOSTS_USER="$TMP_SF/hosts-user.txt"; OUT_DPI="$TMP_SF/dpi_urls.txt"; OUT="$TMP_SF/str_flow.txt"; ZIP="$TMP_SF/repo.zip"
BACKUP_FILE="/opt/zapret/tmp/hosts_temp.txt"; STR_FILE="$TMP_SF/str_test.txt"; TEMP_FILE="$TMP_SF/str_temp.txt"
RESULTS="/opt/zapret/tmp/zapret_bench.txt"; BACK="$TMP_SF/zapret_back.txt"; TMP_RES="$TMP_SF/zapret_results_all.$$"
FINAL_STR="$TMP_SF/StrFINAL.txt"; NEW_STR="$TMP_SF/StrNEW.txt"; OLD_STR="$TMP_SF/StrOLD.txt"
RES1="/opt/zapret/tmp/results_flowseal.txt"; RES2="/opt/zapret/tmp/results_versions.txt"
Fin_IP_Dis="104\.25\.158\.178 finland[0-9]\{5\}\.discord\.media"; PARALLEL=8
RAW="https://raw.githubusercontent.com/hyperion-cs/dpi-checkers/refs/heads/main/ru/tcp-16-20/suite.json"
EXCLUDE_FILE="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"; fileDoH="/etc/config/https-dns-proxy"
RKN_URL="https://raw.githubusercontent.com/IndeecFOX/zapret4rocket/refs/heads/master/extra_strats/TCP/RKN/List.txt"
EXCLUDE_URL="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/zapret-hosts-user-exclude.txt"
INSTAGRAM="#Instagram&Facebook\n57.144.222.34 instagram.com www.instagram.com\n157.240.9.174 instagram.com www.instagram.com\n157.240.245.174 instagram.com www.instagram.com b.i.instagram.com z-p42-chat-e2ee-ig.facebook.com help.instagram.com
157.240.205.174 instagram.com www.instagram.com\n57.144.244.192 static.cdninstagram.com graph.instagram.com i.instagram.com api.instagram.com edge-chat.instagram.com\n31.13.66.63 scontent.cdninstagram.com scontent-hel3-1.cdninstagram.com
57.144.244.1 facebook.com www.facebook.com fb.com fbsbx.com\n57.144.244.128 static.xx.fbcdn.net scontent.xx.fbcdn.net\n31.13.67.20 scontent-hel3-1.xx.fbcdn.net"
TGWeb="#TelegramWeb\n149.154.167.220 api.telegram.org flora.web.telegram.org kws1-1.web.telegram.org kws1.web.telegram.org kws2-1.web.telegram.org kws2.web.telegram.org kws4-1.web.telegram.org
149.154.167.220 kws4.web.telegram.org kws5-1.web.telegram.org kws5.web.telegram.org pluto-1.web.telegram.org pluto.web.telegram.org td.telegram.org telegram.dog
149.154.167.220 telegram.me telegram.org telegram.space telesco.pe venus.web.telegram.org web.telegram.org zws1-1.web.telegram.org zws1.web.telegram.org
149.154.167.220 tg.dev t.me zws2-1.web.telegram.org zws2.web.telegram.org zws4-1.web.telegram.org zws5-1.web.telegram.org zws5.web.telegram.org"
PDA="#4pda\n185.87.51.182 4pda.to www.4pda.to"; NTC="#ntc.party\n130.255.77.28 ntc.party"; TWCH="#Twitch\n45.155.204.190 usher.ttvnw.net gql.twitch.tv"
RUTOR="#rutor\n173.245.58.219 rutor.info d.rutor.info"; LIBRUSEC="#lib.rus.ec\n185.39.18.98 lib.rus.ec www.lib.rus.ec"
AI="#Gemini\n45.155.204.190 gemini.google.com\n#Grok\n45.155.204.190 grok.com accounts.x.ai assets.grok.com
#OpenAI\n45.155.204.190 chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com
45.155.204.190 tcr9i.chat.openai.com webrtc.chatgpt.com android.chat.openai.com api.openai.com operator.chatgpt.com
45.155.204.190 sora.chatgpt.com sora.com videos.openai.com ios.chat.openai.com cdn.auth0.com files.oaiusercontent.com
#Microsoft\n45.155.204.190 copilot.microsoft.com sydney.bing.com edgeservices.bing.com rewards.bing.com
45.155.204.190 xsts.auth.xboxlive.com xgpuwebf2p.gssv-play-prod.xboxlive.com xgpuweb.gssv-play-prod.xboxlive.com
#ElevenLabs\n45.155.204.190 elevenlabs.io api.us.elevenlabs.io elevenreader.io api.elevenlabs.io help.elevenlabs.io
#DeepL\n45.155.204.190 deepl.com www.deepl.com www2.deepl.com login-wall.deepl.com w.deepl.com dict.deepl.com ita-free.www.deepl.com
45.155.204.190 write-free.www.deepl.com experimentation.deepl.com experimentation-grpc.deepl.com ita-free.app.deepl.com
45.155.204.190 ott.deepl.com api-free.deepl.com backend.deepl.com clearance.deepl.com errortracking.deepl.com
45.155.204.190 oneshot-free.www.deepl.com checkout.www.deepl.com gtm.deepl.com auth.deepl.com shield.deepl.com
#Claude\n45.155.204.190 claude.ai console.anthropic.com api.anthropic.com
#Trae.ai\n45.155.204.190 trae-api-sg.mchost.guru api.trae.ai api-sg-central.trae.ai api16-normal-alisg.mchost.guru
#Windsurf\n45.155.204.190 windsurf.com codeium.com server.codeium.com web-backend.codeium.com  marketplace.windsurf.com
45.155.204.190 unleash.codeium.com inference.codeium.com windsurf-stable.codeium.com
144.31.14.104 windsurf-telemetry.codeium.com\n#Manus\n45.155.204.190 manus.im api.manus.im\n#Notion\n45.155.204.190 www.notion.so calendar.notion.so
#AIStudio\n45.155.204.190 aistudio.google.com generativelanguage.googleapis.com aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com xsts.auth.xboxlive.com
45.155.204.190 webchannel-alkalimakersuite-pa.clients6.google.com alkalimakersuite-pa.clients6.google.com assistant-s3-pa.googleapis.com
45.155.204.190 proactivebackend-pa.googleapis.com robinfrontend-pa.googleapis.com o.pki.goog labs.google labs.google.com notebooklm.google
45.155.204.190 notebooklm.google.com jules.google.com stitch.withgoogle.com gemini.google.com copilot.microsoft.com edgeservices.bing.com
45.155.204.190 rewards.bing.com sydney.bing.com xboxdesignlab.xbox.com xgpuweb.gssv-play-prod.xboxlive.com xgpuwebf2p.gssv-play-prod.xboxlive.com"
ALL_BLOCKS="$AI\n$INSTAGRAM\n$NTC\n$RUTOR\n$LIBRUSEC\n$TGWeb\n$TWCH"
hosts_enabled() { grep -q "45.155.204.190\|4pda.to\|instagram.com\|rutor.info\|lib.rus.ec\|ntc.party\|twitch.tv\|web.telegram.org" /etc/hosts; }
hosts_add() { printf "%b\n" "$1" | while IFS= read -r L; do grep -qxF "$L" /etc/hosts || echo "$L" >> /etc/hosts; done; /etc/init.d/dnsmasq restart >/dev/null 2>&1; }
ZAPRET_RESTART () { chmod +x /opt/zapret/sync_config.sh; /opt/zapret/sync_config.sh; /etc/init.d/zapret restart >/dev/null 2>&1; sleep 1; }
PAUSE() { echo "Нажмите Enter..."; read dummy; }; BACKUP_DIR="/opt/zapret_backup"; DATE_FILE="$BACKUP_DIR/date_backup.txt"
if command -v apk >/dev/null 2>&1; then CONFZ="/etc/apk/repositories.d/distfeeds.list"; PKG_IS_APK=1; else CONFZ="/etc/opkg/distfeeds.conf"; PKG_IS_APK=0; fi
echo 'sh <(wget -O - https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh)' > /usr/bin/zms; chmod +x /usr/bin/zms
# ==========================================
# Получение версии
# ==========================================
get_versions() { LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release); [ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v "noarch" | sort -k3 -n | tail -n1 | awk '{print $2}'); USED_ARCH="$LOCAL_ARCH"
LATEST_URL="https://github.com/remittor/zapret-openwrt/releases/download/v${ZAPRET_VERSION}/zapret_v${ZAPRET_VERSION}_${LOCAL_ARCH}.zip"; if [ "$PKG_IS_APK" -eq 1 ]; then INSTALLED_VER=$(apk info -v | grep '^zapret-' | head -n1 | cut -d'-' -f2 | sed 's/-r[0-9]\+$//')
[ -z "$INSTALLED_VER" ] && INSTALLED_VER="не найдена"; else INSTALLED_VER=$(opkg list-installed zapret 2>/dev/null | awk '{sub(/-r[0-9]+$/, "", $3); print $3}'); [ -z "$INSTALLED_VER" ] && INSTALLED_VER="не найдена"; fi
NFQ_RUN=$(pgrep -f nfqws 2>/dev/null | wc -l); NFQ_RUN=${NFQ_RUN:-0}; NFQ_ALL=$(/etc/init.d/zapret info 2>/dev/null | grep -o 'instance[0-9]\+' | wc -l); NFQ_ALL=${NFQ_ALL:-0}; NFQ_STAT=""; if [ "$NFQ_ALL" -gt 0 ]; then
[ "$NFQ_RUN" -eq "$NFQ_ALL" ] && NFQ_CLR="$GREEN" || NFQ_CLR="$RED"; NFQ_STAT="${NFQ_CLR}[${NFQ_RUN}/${NFQ_ALL}]${NC}"; fi; if [ -f /etc/init.d/zapret ]; then /etc/init.d/zapret status >/dev/null 2>&1 && ZAPRET_STATUS="${GREEN}запущен $NFQ_STAT${NC}" || ZAPRET_STATUS="${RED}остановлен${NC}"
else ZAPRET_STATUS=""; fi; [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ] && INST_COLOR=$GREEN || INST_COLOR=$RED; INSTALLED_DISPLAY=${INSTALLED_VER:-"не найдена"}; }
# ==========================================
# Установка Zapret
# ==========================================
install_pkg() { local display_name="$1"; local pkg_file="$2"; if [ "$PKG_IS_APK" -eq 1 ]; then echo -e "${CYAN}Устанавливаем ${NC}$display_name"; apk add --allow-untrusted "$pkg_file" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить $display_name!${NC}\n"; PAUSE; return 1; }
else echo -e "${CYAN}Устанавливаем ${NC}$display_name"; opkg install --force-reinstall "$pkg_file" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить $display_name!${NC}\n"; PAUSE; return 1; }; fi; }
install_Zapret() { mkdir -p "$TMP_SF"; local NO_PAUSE=$1; get_versions; [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ] && { echo -e "\n${GREEN}Zapret уже установлен!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; return; }; [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Устанавливаем ZAPRET${NC}"
if [ -f /etc/init.d/zapret ]; then echo -e "${CYAN}Останавливаем ${NC}zapret"; /etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; fi; echo -e "${CYAN}Обновляем список пакетов${NC}"
if [ "$PKG_IS_APK" -eq 1 ]; then apk update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении apk!${NC}\n"; PAUSE; return; }; else opkg update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении opkg!${NC}\n"; PAUSE; return; }; fi
rm -f "$TMP_SF"/* 2>/dev/null; cd "$TMP_SF" || return; FILE_NAME=$(basename "$LATEST_URL"); if ! command -v unzip >/dev/null 2>&1; then echo -e "${CYAN}Устанавливаем ${NC}unzip"; if [ "$PKG_IS_APK" -eq 1 ]; then
apk add unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}\n"; PAUSE; return; }; else opkg install unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}\n"; PAUSE; return; }; fi; fi
echo -e "${CYAN}Скачиваем архив ${NC}$FILE_NAME"; wget -q -U "Mozilla/5.0" -O "$FILE_NAME" "$LATEST_URL" || { echo -e "\n${RED}Не удалось скачать $FILE_NAME${NC}\n"; PAUSE; return; }; echo -e "${CYAN}Распаковываем архив${NC}"
unzip -o "$FILE_NAME" >/dev/null; if [ "$PKG_IS_APK" -eq 1 ]; then PKG_PATH="$TMP_SF/apk"; for PKG in "$PKG_PATH"/zapret*; do [ -f "$PKG" ] || continue; echo "$PKG" | grep -q "luci" && continue; install_pkg "$(basename "$PKG")" "$PKG" || return; done
for PKG in "$PKG_PATH"/luci*; do [ -f "$PKG" ] || continue; install_pkg "$(basename "$PKG")" "$PKG" || return; done; else PKG_PATH="$TMP_SF"; for PKG in "$PKG_PATH"/zapret_*.ipk; do [ -f "$PKG" ] || continue; install_pkg "$(basename "$PKG")" "$PKG" || return; done
for PKG in "$PKG_PATH"/luci-app-zapret_*.ipk; do [ -f "$PKG" ] || continue; install_pkg "$(basename "$PKG")" "$PKG" || return; done; fi; echo -e "${CYAN}Удаляем временные файлы${NC}"; cd /
rm -rf "$TMP_SF" /tmp/*.ipk /tmp/*.zip /tmp/*zapret* 2>/dev/null; echo -e "Zapret ${GREEN}установлен!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
# ==========================================
# Меню настройки Discord
# ==========================================
Dv1=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=multisplit\n--dpi-desync-split-seqovl=652\n--dpi-desync-split-pos=2\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin'
Dv2=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,multisplit\n--dpi-desync-split-seqovl=681\n--dpi-desync-split-pos=1\n--dpi-desync-fooling=ts\n--dpi-desync-repeats=8\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin\n--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com'
Dv3=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake\n--dpi-desync-repeats=6\n--dpi-desync-fooling=ts\n--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin\n--dpi-desync-fake-tls-mod=none'
Dv4=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=multisplit\n--dpi-desync-split-seqovl=652\n--dpi-desync-split-pos=2\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin'
Dv5=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,multisplit\n--dpi-desync-repeats=6\n--dpi-desync-fooling=badseq\n--dpi-desync-badseq-increment=1000\n--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin'
Dv6=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=multisplit\n--dpi-desync-split-seqovl=681\n--dpi-desync-split-pos=1\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin'
Dv7=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=multisplit\n--dpi-desync-split-pos=2,sniext+1\n--dpi-desync-split-seqovl=679\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin'
Dv8=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake\n--dpi-desync-fake-tls-mod=none\n--dpi-desync-repeats=6\n--dpi-desync-fooling=badseq\n--dpi-desync-badseq-increment=2'
Dv9=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,fakedsplit\n--dpi-desync-split-pos=1\n--dpi-desync-fooling=badseq\n--dpi-desync-badseq-increment=2\n--dpi-desync-repeats=8\n--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com'
Dv10=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,multisplit\n--dpi-desync-split-seqovl=681\n--dpi-desync-split-pos=1\n--dpi-desync-fooling=badseq\n--dpi-desync-badseq-increment=10000000\n--dpi-desync-repeats=8\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin\n--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com'
Dv11=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,multisplit\n--dpi-desync-split-seqovl=681\n--dpi-desync-split-pos=1\n--dpi-desync-fooling=ts\n--dpi-desync-repeats=8\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin\n--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com'
Dv12=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake\n--dpi-desync-repeats=6\n--dpi-desync-fooling=badseq\n--dpi-desync-badseq-increment=2\n--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin'
Dv13=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake\n--dpi-desync-repeats=6\n--dpi-desync-fooling=ts\n--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin'
Dv14=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,fakedsplit\n--dpi-desync-repeats=6\n--dpi-desync-fooling=ts\n--dpi-desync-fakedsplit-pattern=0x00\n--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin'
Dv15=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,multidisorder\n--dpi-desync-split-pos=1,midsld\n--dpi-desync-repeats=11\n--dpi-desync-fooling=badseq\n--dpi-desync-fake-tls=0x00000000\n--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin\n--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com'
Dv16=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=fake,hostfakesplit\n--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com\n--dpi-desync-hostfakesplit-mod=host=www.google.com,altorder=1\n--dpi-desync-fooling=ts'
Dv17=$'--filter-tcp=2053,2083,2087,2096,8443\n--hostlist-domains=discord.media\n--dpi-desync=hostfakesplit\n--dpi-desync-repeats=4\n--dpi-desync-fooling=ts\n--dpi-desync-hostfakesplit-mod=host=www.google.com'
select_Dv() { DVS=$(set | grep -E '^Dv[0-9]+=' | sed 's/=.*//' | sort -V); COUNT_dv=$(echo "$DVS" | wc -l); echo; echo -en "${YELLOW}Введите версию стратегии для discord.media ${NC}(1-$COUNT_dv)${YELLOW}:${NC} "; read CHOICE_DV </dev/tty
case "$CHOICE_DV" in ''|*[!0-9]*|0) return 1;; esac; SELECTED_dv="Dv$CHOICE_DV"; echo "$DVS" | grep -qx "$SELECTED_dv" || return 1; NEW_NUM="$CHOICE_DV"; NEW_STRAT=$(eval echo \"\$$SELECTED_dv\"); }
switch_Dv() { select_Dv || return 1; grep -q -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" || { echo -e "\n${RED}Стратегия не подходит!${NC}\n"; PAUSE; return 1; }; START=$(grep -n -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" | cut -d: -f1)
END=$(tail -n +"$START" "$CONF" | grep -n -m1 -E '^--new$|^'\''$' | cut -d: -f1); END=$((START + END - 1)); sed -i "${START},$((END-1))d" "$CONF"; LINE=$START; echo "$NEW_STRAT" | while IFS= read -r l; do sed -i "${LINE}i$l" "$CONF"; LINE=$((LINE + 1)); done
if grep -q -E '^#[[:space:]]*Dv' "$CONF"; then sed -i "s/^#[[:space:]]*Dv[0-9]\+/#Dv$NEW_NUM/" "$CONF"; else sed -i "$START i#Dv$NEW_NUM" "$CONF"; fi; echo -e "\n${MAGENTA}Меняем стратегию для discord.media${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия ${NC}Dv$NEW_NUM${GREEN} применена!${NC}\n"; PAUSE; }
toggle_finland_hosts() { if grep -q "$Fin_IP_Dis" /etc/hosts; then sed -i "/$Fin_IP_Dis/d" /etc/hosts; echo -e "\n${MAGENTA}Удаляем Финские IP${NC}"; /etc/init.d/dnsmasq restart 2>/dev/null
echo -e "${GREEN}Финские ${NC}IP${GREEN} удалены${NC}\n"; else seq 10000 10199 | awk '{print "104.25.158.178 finland"$1".discord.media"}' | grep -vxFf /etc/hosts >> /etc/hosts; echo -e "\n${MAGENTA}Добавляем Финские IP${NC}"; /etc/init.d/dnsmasq restart 2>/dev/null
echo -e "${GREEN}Финские ${NC}IP${GREEN} добавлены${NC}\n"; fi; PAUSE; }
show_script_50() { [ -f "/opt/zapret/init.d/openwrt/custom.d/50-script.sh" ] || return; line=$(head -n1 /opt/zapret/init.d/openwrt/custom.d/50-script.sh)
name=$(case "$line" in *QUIC*) echo "50-quic4all";; *stun*) echo "50-stun4all";; *"discord media"*) echo "50-discord-media";; *"discord subnets"*) echo "50-discord";; *) echo "";; esac); }
Discord_menu() { [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; PAUSE; return; }
local NO_PAUSE=$1; while true; do [ "$NO_PAUSE" != "1" ] && clear && echo -e "${MAGENTA}Меню настройки Discord${NC}\n"; output_shown=false
[ "$NO_PAUSE" != "1" ] && show_script_50 && [ -n "$name" ] && echo -e "${YELLOW}Установлен скрипт:${NC} $name" && output_shown=true
[ "$NO_PAUSE" != "1" ] && grep -q "$Fin_IP_Dis" /etc/hosts && echo -e "${YELLOW}Финские IP для Discord: ${GREEN}включены${NC}" && output_shown=true
[ "$NO_PAUSE" != "1" ] && NUMDv=$(grep -o -E '^#[[:space:]]*Dv[0-9][0-9]*' "$CONF" | sed 's/[^0-9]//g' | head -n1) && [ -n "$NUMDv" ] && echo -e "${YELLOW}Стратегия для discord.media: ${CYAN}Dv$NUMDv${NC}"  && output_shown=true
$output_shown && echo; if [ "$NO_PAUSE" = "1" ]; then SELECTED="50-stun4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all"; else
echo -e "${CYAN}1) ${GREEN}Установить скрипт ${NC}50-stun4all\n${CYAN}2) ${GREEN}Установить скрипт ${NC}50-quic4all\n${CYAN}3) ${GREEN}Установить скрипт ${NC}50-discord-media\n${CYAN}4) ${GREEN}Установить скрипт ${NC}50-discord\n${CYAN}5) ${GREEN}Удалить скрипт${NC}"
grep -q '104\.25\.158\.178 finland[0-9]\{5\}\.discord\.media' /etc/hosts && FIN_TXT="${GREEN}Удалить Финские ${NC}IP ${GREEN}из ${NC}hosts" || FIN_TXT="${GREEN}Добавить ${NC}Финские IP ${GREEN}в ${NC}hosts"
echo -ne "${CYAN}6) $FIN_TXT\n${CYAN}7) ${GREEN}Выбрать и установить стратегию для ${NC}discord.media\n${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choiceSC; case "$choiceSC" in
1) SELECTED="50-stun4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all";; 2) SELECTED="50-quic4all"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-quic4all";;
3) SELECTED="50-discord-media"; URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-discord-media";; 4) SELECTED="50-discord"; URL="https://raw.githubusercontent.com/bol-van/zapret/v70.5/init.d/custom.d.examples.linux/50-discord";;
5) [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; PAUSE; continue; }; echo -e "\n${MAGENTA}Удаляем скрипт${NC}"; rm -f "$CUSTOM_DIR/50-script.sh" 2>/dev/null; sed -i "/DISABLE_CUSTOM/s/'0'/'1'/" /etc/config/zapret; ZAPRET_RESTART; echo -e "${GREEN}Скрипт удалён!${NC}\n"; PAUSE; continue;;
6) toggle_finland_hosts; continue;; 7) switch_Dv; continue;; *) return;; esac; fi; [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; PAUSE; continue; }
if wget -q -U "Mozilla/5.0" -O "$CUSTOM_DIR/50-script.sh" "$URL"; then [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Устанавливаем скрипт${NC}\n${GREEN}Скрипт ${NC}$SELECTED${GREEN} успешно установлен!${NC}\n"; else echo -e "\n${RED}Ошибка при скачивании скрипта!${NC}\n"; PAUSE; continue; fi
sed -i "/DISABLE_CUSTOM/s/'1'/'0'/" /etc/config/zapret; ZAPRET_RESTART; [ "$NO_PAUSE" != "1" ] && PAUSE; [ "$NO_PAUSE" = "1" ] && break; done }
# ==========================================
# FIX GAME
# ==========================================
fix_GAME() { local NO_PAUSE=$1; [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; PAUSE; return; }
[ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Настраиваем стратегию для игр${NC}"; if grep -q "option NFQWS_PORTS_UDP.*88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF" && grep -q -- "--filter-udp=88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF"; then echo -e "${CYAN}Удаляем настройки для игр${NC}"
sed -i ':a;N;$!ba;s|#Gv1\n--new\n--filter-udp=88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535\n--dpi-desync=fake\n--dpi-desync-cutoff=d2\n--dpi-desync-any-protocol=1\n--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com\.bin\n--new\n--filter-tcp=25565\n--dpi-desync-any-protocol=1\n--dpi-desync-cutoff=n5\n--dpi-desync=multisplit\n--dpi-desync-split-seqovl=582\n--dpi-desync-split-pos=1\n--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/4pda\.bin\n*||g' "$CONF"
sed -i "s/,88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535//" "$CONF"; sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/,25565//" "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Игровая стратегия удалена!${NC}\n"; PAUSE; return; fi
if ! grep -q "option NFQWS_PORTS_UDP.*88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535'/" "$CONF"; fi; if ! grep -q -- "--filter-udp=88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF"; then last_line=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1); if [ -n "$last_line" ]; then sed -i "${last_line},\$d" "$CONF"; fi; 
printf "%s\n" "#Gv1" "--new" "--filter-udp=88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "--dpi-desync=fake" "--dpi-desync-cutoff=d2" "--dpi-desync-any-protocol=1" "--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/quic_initial_www_google_com.bin" "--new" "--filter-tcp=25565" "--dpi-desync-any-protocol=1" "--dpi-desync-cutoff=n5" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=582" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/4pda.bin" "'" >> "$CONF"; fi
echo -e "${CYAN}Включаем настройки для игр${NC}"; if ! grep -q "option NFQWS_PORTS_TCP.*,25565" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'$/,25565'/" "$CONF"; fi; ZAPRET_RESTART; echo -e "${GREEN}Игровая стратегия включена!${NC}\n";[ "$NO_PAUSE" != "1" ] && PAUSE; }
# ==========================================
# Zapret под ключ
# ==========================================
zapret_key() { clear; echo -e "${MAGENTA}Удаление, установка и настройка Zapret${NC}\n"; get_versions; uninstall_zapret "1"; install_Zapret "1"
[ ! -f /etc/init.d/zapret ] && { echo -e "${RED}Zapret не установлен!${NC}\n"; PAUSE; return; }; install_strategy $STR_VERSION_AUTOINSTALL "1"; echo -e "\n${MAGENTA}Редактируем hosts${NC}\n${CYAN}Добавляем IP и домены в${NC} hosts"
hosts_add "$ALL_BLOCKS"; echo -e "IP ${GREEN}и${NC} домены ${GREEN}добавлены в ${NC}hosts${GREEN}!${NC}\n"; Discord_menu "1"; fix_GAME "1"; echo -e "Zapret ${GREEN}установлен и настроен!${NC}\n"; PAUSE; }
# ==========================================
# Меню настроек
# ==========================================
backup_menu() { while true; do clear; echo -e "${MAGENTA}Меню управления настройками${NC}\n"; if [ -f "$DATE_FILE" ] && [ -f "$BACKUP_DIR/zapret.tar.gz" ] && [ -f "$BACKUP_DIR/zapret" ]; then CREATE_DATE=$(cat "$DATE_FILE")
echo -e "${YELLOW}Резервная копия:${NC} $CREATE_DATE\n"; else echo -e "${YELLOW}Резервная копия: ${RED}отсутствует${NC}\n"; fi
echo -e "${CYAN}1) ${GREEN}Сделать резервную копию настроек${NC} Zapret\n${CYAN}2) ${GREEN}Восстановить настройки ${NC}Zapret${GREEN} из резервной копии${NC}\n${CYAN}3) ${GREEN}Вернуть настройки по умолчанию${NC}"
echo -ne "${CYAN}4) ${GREEN}Показать стратегию из резервной копии${NC}\n${CYAN}5) ${GREEN}Удалить резервную копию${NC}\n${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт: ${NC}"
read choice; case $choice in 1) save_backup;; 2) restore_backup;; 3) restore_default;; 5) delete_backup;;
4) if [ -d "$BACKUP_DIR" ]; then echo; awk 'f{if($0=="'\''")exit;print} /option NFQWS_OPT '\''/{f=1}' /opt/zapret_backup/zapret; echo; PAUSE; else echo -e "\n${RED}Резервная копия не найдена!${NC}\n"; PAUSE; fi;; *) break;; esac; done; }
delete_backup() { if [ -d "$BACKUP_DIR" ]; then rm -rf "$BACKUP_DIR"; echo -e "\n${GREEN}Резервная копия удалена!${NC}\n"; else echo -e "\n${RED}Резервная копия не найдена!${NC}\n"; fi; PAUSE; }
restore_default() { if [ -f /opt/zapret/restore-def-cfg.sh ]; then echo -e "\n${MAGENTA}Возвращаем настройки по умолчанию${NC}"; rm -f /opt/zapret/init.d/openwrt/custom.d/50-script.sh; for i in 1 2 3 4; do rm -f "/opt/zapret/ipset/cust$i.txt"; done
[ -f /etc/init.d/zapret ] && /etc/init.d/zapret stop >/dev/null 2>&1; echo -e "${CYAN}Возвращаем ${NC}настройки${CYAN}, ${NC}стратегию${CYAN} и ${NC}hostlist${CYAN} к значениям по умолчанию${NC}"; cp -f /opt/zapret/ipset_def/* /opt/zapret/ipset/
chmod +x /opt/zapret/restore-def-cfg.sh && /opt/zapret/restore-def-cfg.sh; ZAPRET_RESTART; echo -e "${GREEN}Настройки по умолчанию возвращены!${NC}\n"; else echo -e "\n${RED}Zapret не установлен!${NC}\n"; fi; PAUSE; }
save_backup() { [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; PAUSE; return; }; rm -rf "$BACKUP_DIR"; mkdir -p "$BACKUP_DIR"; tar -czf "$BACKUP_DIR/zapret.tar.gz" -C /opt zapret 2>/dev/null
cp -p /etc/config/zapret "$BACKUP_DIR/"; printf '%s / %s\n' "$(date '+%d.%m.%y')" "$(du -sh /opt/zapret_backup 2>/dev/null | cut -f1 | sed -E 's/\.0K$/K/;s/K$/ КБ/;s/M$/ МБ/')" > "$DATE_FILE"
echo -e "\n${GREEN}Настройки сохранены в${NC} $BACKUP_DIR\n"; PAUSE; }
restore_backup() { [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; PAUSE; return; }; [ ! -f "$BACKUP_DIR/zapret.tar.gz" ] && { echo -e "\n${RED}Резервная копия не найдена!${NC}\n"; PAUSE; return; }
echo -e "\n${MAGENTA}Восстанавливаем настройки из резервной копии${NC}"; /etc/init.d/zapret stop >/dev/null 2>&1; rm -rf /opt/zapret; rm -f /etc/config/zapret; mkdir -p /opt; tar -xzf "$BACKUP_DIR/zapret.tar.gz" -C /opt 2>/dev/null
[ -f "$BACKUP_DIR/zapret" ] && cp -p "$BACKUP_DIR/zapret" /etc/config/zapret; echo -e "${CYAN}Применяем настройки${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Настройки восстановлены из резервной копии!${NC}\n"; PAUSE; }
# ==========================================
# Cтарт/стоп Zapret
# ==========================================
stop_zapret() { local NO_PAUSE=$1; echo -e "\n${MAGENTA}Останавливаем Zapret${NC}\n${CYAN}Останавливаем ${NC}Zapret"; /etc/init.d/zapret stop >/dev/null 2>&1
for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; echo -e "Zapret ${GREEN}остановлен!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
start_zapret() { if [ -f /etc/init.d/zapret ]; then echo -e "\n${MAGENTA}Запускаем Zapret${NC}"; echo -e "${CYAN}Запускаем ${NC}Zapret"; /etc/init.d/zapret start >/dev/null 2>&1; ZAPRET_RESTART
echo -e "Zapret ${GREEN}запущен!${NC}\n"; else echo -e "\n${RED}Zapret не установлен!${NC}\n"; fi; [ "$NO_PAUSE" != "1" ] && PAUSE; }
# ==========================================
# Удаление Zapret
# ==========================================
pkg_remove() { local pkg_name="$1"; if [ "$PKG_IS_APK" -eq 1 ]; then apk del "$pkg_name" >/dev/null 2>&1 || true; else opkg remove --force-depends "$pkg_name" >/dev/null 2>&1 || true; fi; }
uninstall_zapret() { local NO_PAUSE=$1; [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Удаляем ZAPRET${NC}\n${CYAN}Останавливаем ${NC}zapret"; /etc/init.d/zapret stop >/dev/null 2>&1; echo -e "${CYAN}Убиваем процессы${NC}"
for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; echo -e "${CYAN}Удаляем пакеты${NC}"; pkg_remove zapret; pkg_remove luci-app-zapret; echo -e "${CYAN}Удаляем временные файлы${NC}"
rm -rf /opt/zapret /etc/config/zapret /etc/firewall.zapret /etc/init.d/zapret /tmp/*zapret* /var/run/*zapret* /tmp/*.ipk /tmp/*.zip 2>/dev/null; crontab -l 2>/dev/null | grep -v -i "zapret" | crontab - 2>/dev/null
nft list tables 2>/dev/null | awk '{print $2}' | grep -E '(zapret|ZAPRET)' | while read t; do [ -n "$t" ] && nft delete table "$t" 2>/dev/null; done; rm -rf -- "$TMP_SF"; echo -e "Zapret ${GREEN}удалён!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
# ==========================================
# Тест стратегии для Ютуб
# ==========================================
auto_stryou() { clear; echo -e "${MAGENTA}Тестируем стратегии для ${NC}YouTube${NC}"; awk '/^[[:space:]]*option NFQWS_OPT '\''/{flag=1} flag{print}' "$CONF" > "$OLD_STR"; curl -fsSL "$STR_URL" -o "$TMP_LIST" || { echo -e "\n${RED}Не удалось скачать список${NC}\n"; PAUSE </dev/tty; return 1; }
TOTAL=$(grep -c '^Yv[0-9]\+' "$TMP_LIST"); echo -e "\n${CYAN}Найдено стратегий: ${NC}$TOTAL"; CURRENT_NAME=""; CURRENT_BODY=""; COUNT=0
while IFS= read -r LINE || [ -n "$LINE" ]; do if echo "$LINE" | grep -q '^Yv[0-9]\+'; then if [ -n "$CURRENT_NAME" ]; then COUNT=$((COUNT + 1))
echo -e "\n${CYAN}Тестируем стратегию: ${NC}$CURRENT_NAME ($COUNT/$TOTAL)"; apply_strategy "$CURRENT_NAME" "$CURRENT_BODY"; STATUS=$(check_access); if [ "$STATUS" = "ok" ]; then echo -e "${GREEN}Видео на ПК открывается!${NC}\n${YELLOW}Проверьте работу ${NC}YouTube${YELLOW} на других устройствах!${NC}"
echo -en "Enter${GREEN} - применить стратегию, ${NC}S/s${GREEN} - остановить, ${NC}N/n${GREEN} - продолжить тест:${NC} "; read -r ANSWER </dev/tty
if [ -z "$ANSWER" ]; then { echo "#$CURRENT_NAME"; printf "%b\n" "$CURRENT_BODY"; } > "$SAVED_STR"; echo -e "${CYAN}Применяем стратегию и перезапускаем ${NC}Zapret"
awk '{if(skip){if($0=="--new"||$0~/\047/){skip=0;next}if($0~/^[[:space:]]*$/)next;next}if($0=="--filter-tcp=443"){getline n;if(n=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"){skip=1;next}else{print $0;print n;next}}if($0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt")has_google=1;if($0~/^[[:space:]]*#Yv/)next;print}' "$OLD_STR" > "$NEW_STR"
awk 'BEGIN{inserted=0;has_google=0}$0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"{has_google=1}$0=="--new"&&!inserted{while((getline l<"'"$SAVED_STR"'")>0)if(l!~/^[[:space:]]*$/)print l;print "--new";inserted=1;next}$0~/^[[:space:]]*option NFQWS_OPT \047$/&&!has_google&&!inserted{print;while((getline l<"'"$SAVED_STR"'")>0)if(l!~/^[[:space:]]*$/)print l;print "--new";inserted=1;next}{print}' "$NEW_STR" > "$FINAL_STR"
sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$FINAL_STR" >> "$CONF"; awk '{if($0=="--new"){if(prev!="--new")print}else print;prev=$0}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
grep -q "^[[:space:]]*' *\$" "$CONF" || echo "'" >> "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия применена!${NC}\n"; PAUSE </dev/tty; return 0; elif [[ "$ANSWER" =~ ^[Ss]$ ]]; then sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART
echo -e "\n${GREEN}Тест остановлен!${NC}\n"; PAUSE </dev/tty; return 1; fi; else echo -e "${RED}Видео не открывается, продолжаем тест...${NC}"; fi; fi; CURRENT_NAME="$LINE"; CURRENT_BODY=""; else [ -n "$LINE" ] && CURRENT_BODY="${CURRENT_BODY}${LINE}\n"; fi; done < "$TMP_LIST"
if [ -n "$CURRENT_NAME" ]; then COUNT=$((COUNT + 1)); echo -e "\n${CYAN}Проверяем стратегию: ${NC}$CURRENT_NAME ($COUNT/$TOTAL)"; apply_strategy "$CURRENT_NAME" "$CURRENT_BODY"; STATUS=$(check_access); if [ "$STATUS" = "ok" ]; then echo -e "${GREEN}Видео на ПК открывается!${NC}\n${YELLOW}Проверьте работу ${NC}YouTube${YELLOW} на других устройствах!${NC}"
echo -en "Enter${GREEN} - применить стратегию, ${NC}S/s${GREEN} - остановить, ${NC}N/n${GREEN} - продолжить тест:${NC} "; read -r ANSWER </dev/tty; if [ -z "$ANSWER" ]; then { echo "#$CURRENT_NAME"; printf "%b\n" "$CURRENT_BODY"; } > "$SAVED_STR"; echo -e "${CYAN}Применяем стратегию и перезапускаем ${NC}Zapret"
awk '{ if(skip) { if($0=="--new" || $0 ~ /'\''/) { skip=0; print; next } next } if($0=="--filter-tcp=443") { getline next_line; if(next_line=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt") { skip=1; next } else { print $0; print next_line; next } } if($0~/^[[:space:]]*#Yv/) next; print }' "$OLD_STR" > $NEW_STR
awk 'BEGIN { inserted=0 } /^--new/ && !inserted { system("cat '"$SAVED_STR"'"); inserted=1 } { print }' $NEW_STR > $FINAL_STR; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat $FINAL_STR >> "$CONF"; ZAPRET_RESTART
echo -e "${GREEN}Стратегия применена!${NC}\n"; PAUSE </dev/tty; return 0; elif [[ "$ANSWER" =~ ^[Ss]$ ]]; then sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART
echo -e "\n${GREEN}Тест остановлен!${NC}\n"; PAUSE </dev/tty; return 1; fi; else echo -e "${RED}Видео не открывается...${NC}\n"; fi; fi; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART
echo -e "\n${RED}Рабочая стратегия для YouTube не найдена!${NC}\n"; PAUSE </dev/tty; return 1; }
check_access() { curl -s --connect-timeout 4 -m 4 "$TEST_HOST" >/dev/null && echo "ok" || echo "fail"; }
apply_strategy() { NAME="$1"; BODY="$2"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; { echo "  option NFQWS_OPT '"; echo "#AUTO $NAME"; printf "%b\n" "$BODY"; echo "'"; } >> "$CONF"; ZAPRET_RESTART; }
# ==========================================
# РКН список ВКЛ / ВЫКЛ
# ==========================================
enable_rkn() { echo -e "\n${MAGENTA}Включаем списки РКН${NC}"; [ -f "$HOSTLIST_FILE" ] && cp "$HOSTLIST_FILE" "$BACKUP_FILE" && cp "$HOSTLIST_FILE" "$HOSTS_USER"; curl -fsSL "$RKN_URL" -o "$HOSTLIST_FILE" || { echo -e "\n${RED}Не удалось скачать список РКН${NC}\n"; PAUSE; return; }
sed -i 's|--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt|--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt|' "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Обход по спискам ${NC}РКН${GREEN} включен${NC}\n"; }
disable_rkn() { echo -e "\n${MAGENTA}Выключаем списки РКН${NC}"; sed -i 's|--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt|--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt|' "$CONF"; if [ -s "$BACKUP_FILE" ]
then cp "$BACKUP_FILE" "$HOSTLIST_FILE"; else : > "$HOSTLIST_FILE"; fi; rm -f "$HOSTS_USER" "$BACKUP_FILE"; ZAPRET_RESTART; echo -e "${GREEN}Обход по спискам ${NC}РКН${GREEN} выключен${NC}\n"; }
toggle_rkn_bypass() { if grep -q -- "--filter-tcp=443 <HOSTLIST>" "$CONF"; then if [ -f "$BACKUP_FILE" ]; then disable_rkn; else [ -f "$HOSTLIST_FILE" ] && cp "$HOSTLIST_FILE" "$BACKUP_FILE"; enable_rkn; fi; PAUSE </dev/tty; return; fi; if grep -q -- "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "$CONF"
then enable_rkn; PAUSE </dev/tty; elif grep -q -- "--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt" "$CONF"; then disable_rkn; PAUSE </dev/tty; else echo -e "\n${RED}Стратегия не подходит для списков РКН\n${NC}"; PAUSE </dev/tty; fi; }
RKN_Check() { SIZE=0; [ -f /opt/zapret/ipset/zapret-hosts-user.txt ] && SIZE=$(wc -c < /opt/zapret/ipset/zapret-hosts-user.txt 2>/dev/null || echo 0)
if [ -f "$CONF" ] && { grep -q -- "--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt" "$CONF" 2>/dev/null || grep -q -- "--filter-tcp=443 <HOSTLIST>" "$CONF" 2>/dev/null; } && [ "$SIZE" -gt 1800000 ]; then RKN_STATUS="/ РКН"; RKN_TEXT_MENU="${GREEN}Выключить обход по спискам${NC} РКН"; else RKN_STATUS=""; RKN_TEXT_MENU="${GREEN}Включить обход по спискам${NC} РКН"; fi; }
# ==========================================
# Стратегии
# ==========================================
strategy_v1() { printf '%s\n' "#v1" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=split2" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin"; }
strategy_v2() { printf '%s\n' "#v2" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=10,midsld" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin" "--dpi-desync-split-seqovl=336"
printf '%s\n' "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0"
printf '%s\n' "--new" "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v3() { printf '%s\n' "#v3" "#Yv01" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--ip-id=zero" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=10,midsld" "--dpi-desync-fake-tls=/opt/zapret/files/fake/t2.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=m.ok.ru" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin"
printf '%s\n' "--dpi-desync-split-seqovl=336" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0"
printf '%s\n' "--new" "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v4() { printf '%s\n' "#v4" "#Yv15" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=google.com" "--dpi-desync-split-seqovl=2108" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badseq"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=582" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin"
printf '%s\n' "--new" "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v5() { printf '%s\n' "#v5" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=1" "--dpi-desync-fake-tls=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0"
printf '%s\n' "--new" "--filter-udp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin"; }
strategy_v6() { printf '%s\n' "#v6" "#Yv03" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com" "--dpi-desync-split-seqovl=620" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badsum,badseq"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-hostfakesplit-mod=host=i2.photo.2gis.com" "--dpi-desync-hostfakesplit-midhost=host-2" "--dpi-desync-split-seqovl=726" "--dpi-desync-fooling=badsum,badseq" "--dpi-desync-badseq-increment=0"; }
strategy_v7() { printf '%s\n' "#v7" "#Yv03" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com" "--dpi-desync-split-seqovl=620" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badsum,badseq"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=654" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-tls=/opt/zapret/files/fake/stun.bin" "--dpi-desync-badseq-increment=0"; }
strategy_v8() { printf '%s\n' "#v8" "#Yv03" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com" "--dpi-desync-split-seqovl=620" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badsum,badseq"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-fooling=ts" "--dpi-desync-fake-tls=/opt/zapret/files/fake/4pda.bin" "--dpi-desync-fake-tls-mod=none" ; }
strategy_v9() { printf '%s\n' "#v9" "#Yv03" "--filter-tcp=443" "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-pos=2,sld" "--dpi-desync-fake-tls=0x0F0F0F0F" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
printf '%s\n' "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com" "--dpi-desync-split-seqovl=620" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badsum,badseq"
printf '%s\n' "--new" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-hostfakesplit-mod=host=mapgl.2gis.com" "--dpi-desync-badseq-increment=0" ; }
# ==========================================
# Cтратегии Flowseal
# ==========================================
flowseal_menu() { [ ! -f "$OUT" ] && download_strategies; while true; do STRATEGIES=$(grep '^#' "$OUT" | sed 's/^#//'); clear
echo -e "${YELLOW}Список стратегий от Flowseal${NC}\n"; i=1; echo "$STRATEGIES" | while IFS= read -r line; do echo -e "${CYAN}$i) ${NC}$line"; i=$((i+1)); done
echo -en "${CYAN}0) ${GREEN}Обновить стратегии${NC}\n${CYAN}Enter) ${GREEN}Выход в меню стратегий${NC}\n\n${YELLOW}Выберите пункт: ${NC}"; read CHOICE_SF
[ -z "$CHOICE_SF" ] && return; echo "$CHOICE_SF" | grep -qE '^[0-9]+$' || return; [ "$CHOICE_SF" -eq 0 ] && { rm -rf "$TMP_SF"; download_strategies; continue; }; SEL_NAME=$(echo "$STRATEGIES" | sed -n "${CHOICE_SF}p"); [ -z "$SEL_NAME" ] && return
BLOCK=$(awk -v name="$SEL_NAME" '$0=="#"name {flag=1; print; next} /^#/ && flag {exit} flag {print}' "$OUT"); sed -i "/option NFQWS_OPT '/,\$d" "$CONF"; { echo "	option NFQWS_OPT '"; echo "$BLOCK"; echo "'"; } >> "$CONF"
if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,19294-19344,50000-50100'/" "$CONF"; fi
if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'$/,2053,2083,2087,2096,8443'/" "$CONF"; fi;
echo -e "\n${MAGENTA}Устанавливаем стратегию\n${CYAN}Добавляем домены в исключения${NC}"; rm -f "$EXCLUDE_FILE"; wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || { echo -e "\n${RED}Не удалось загрузить exclude файл${NC}\n"; PAUSE; return; }
echo -e "${CYAN}Применяем стратегию${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия ${NC}$SEL_NAME ${GREEN}установлена!${NC}\n"
grep -Fq "=ts" "$CONF" && echo -e "${YELLOW}Для работы этой стратегии, в терминале Windows нужно выполнить:${NC}\nnetsh int tcp set global timestamps=enabled\n" ; PAUSE; break; done; }
download_strategies() { local NO_PAUSE=$1; [ "$NO_PAUSE" != "1" ] && echo -e "\n${MAGENTA}Скачиваем и формируем стратегии${NC}"; mkdir -p "$TMP_SF"; : > "$OUT"; wget -qO "$ZIP" https://github.com/Flowseal/zapret-discord-youtube/archive/refs/heads/main.zip || { echo -e "\n${RED}Не удалось загрузить файл стратегий${NC}\n"; PAUSE; return; }
if ! command -v unzip >/dev/null 2>&1; then echo -e "${CYAN}Устанавливаем ${NC}unzip"; if [ "$PKG_IS_APK" -eq 1 ]; then apk add unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}\n"; PAUSE; return; }
else opkg install unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}\n"; PAUSE; return; }; fi; fi; unzip -oq "$ZIP" -d "$TMP_SF" || { echo -e "\n${RED}Не удалось распоковать файл${NC}\n"; PAUSE; return; }
BASE="$TMP_SF/zapret-discord-youtube-main"; find "$BASE" -type f -name 'general*.bat' ! -name 'general (ALT5).bat' | while read -r F; do MATCH=$(grep -E '^--filter-udp=19294-19344,50000-50100|^--filter-tcp=2053,2083,2087,2096,8443|^--filter-tcp=443 --hostlist="%LISTS%list-google.txt"|^--filter-tcp=80,443 --hostlist="%LISTS%list-general.txt"' "$F")
[ -z "$MATCH" ] && continue; NAME=$(basename "$F" .bat); { echo "#$NAME"; echo "$MATCH" | sed 's/--/\n--/g' | sed '/^$/d' | sed 's/[[:space:]]*$//'; echo; } >> "$OUT"; done; sed -i 's|"%BIN%tls_clienthello_www_google_com.bin"|/opt/zapret/files/fake/tls_clienthello_www_google_com.bin|g' "$OUT"; sed -i '/--hostlist="%LISTS%list-general.txt"/d' "$OUT"
sed -i '/--ipset-exclude="%LISTS%ipset-exclude.txt"/d' "$OUT"; sed -i 's|"%LISTS%list-exclude.txt"|/opt/zapret/ipset/zapret-hosts-user-exclude.txt|g' "$OUT"; sed -i 's/--new[[:space:]]\^/--new/g' "$OUT"; sed -i 's|"%LISTS%list-google.txt"|/opt/zapret/ipset/zapret-hosts-google.txt|g' "$OUT"
sed -i 's|"%BIN%tls_clienthello_4pda_to.bin"|/opt/zapret/files/fake/4pda.bin|g' "$OUT"; sed -i 's|"%BIN%tls_clienthello_max_ru.bin"|/opt/zapret/files/fake/tls_clienthello_www_onetrust_com.bin|g' "$OUT"; sed -i 's|\^!|/opt/zapret/files/fake/tls_clienthello_www_google_com.bin|g' "$OUT"; sed -i 's/[[:space:]]\+$//g' "$OUT"; sed -i '/^--new$/ { N; /^\--new\n$/d; }' "$OUT"
rm -rf "$TMP_SF/zapret-discord-youtube-main" "$ZIP"; [ "$NO_PAUSE" != "1" ] && echo -e "${GREEN}Стратегии сформированы!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
# ==========================================
# Меню стратегий
# ==========================================
menu_str() { [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; PAUSE; return; }; while true; do show_current_strategy; RKN_Check; clear; echo -e "${MAGENTA}Меню стратегий${NC}\n"; pri=0
menu_game=$( [ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF" && grep -q -- "--filter-udp=88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF" && echo "Удалить стратегию для игр" || echo "Включить стратегию для игр" )
[ -f "$CONF" ] && line=$(grep -m1 '^#general' "$CONF") && [ -n "$line" ] && echo -e "${YELLOW}Используется стратегия:${NC} ${CYAN}${line#?}${NC}" && pri=1
if [ -f "$CONF" ]; then current="$ver$( [ -n "$ver" ] && [ -n "$yv_ver" ] && echo " / " )$yv_ver"; DV=$(grep -o -E '^#[[:space:]]*Dv[0-9][0-9]*' "$CONF" | sed 's/^#[[:space:]]*/\/ /' | head -n1)
if [ -n "$current" ]; then echo -e "${YELLOW}Используется стратегия:${NC} ${CYAN}$current${DV:+ $DV}${RKN_STATUS:+ $RKN_STATUS}${NC}"; pri=1; elif [ -n "$RKN_STATUS" ]; then  echo -e "${YELLOW}Используется стратегия:${NC}${CYAN} РКН${DV:+ $DV}${NC}"; pri=1; fi; fi
[ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF" && grep -q -- "--filter-udp=88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF" && echo -e "${YELLOW}Стратегия для игр:${NC} ${GREEN}включена${NC}" && pri=1
[ "$pri" -eq 1 ] && echo; echo -e "${CYAN}1) ${GREEN}Выбрать и установить стратегию ${NC}v1-v9\n${CYAN}2) ${GREEN}Выбрать и установить стратегию от ${NC}Flowseal\n${CYAN}3) ${GREEN}Выбрать и установить стратегию для ${NC}YouTube\n${CYAN}4) ${GREEN}Меню тестирования стратегий ${NC}"
echo -e "${CYAN}5) ${NC}$RKN_TEXT_MENU${NC}\n${CYAN}6) ${GREEN}$menu_game\n${CYAN}7) ${GREEN}Обновить список исключений${NC}"
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read choiceST; case "$choiceST" in 1) strategy_CHOUSE;; 2) flowseal_menu;; 3) choose_strategy_manual;; 4) TEST_menu;;
5) toggle_rkn_bypass; continue;; 6) fix_GAME;; 0) show_test_results;; 7) echo -e "\n${MAGENTA}Обновляем список исключений${NC}\n${CYAN}Останавливаем ${NC}Zapret"; /etc/init.d/zapret stop >/dev/null 2>&1; echo -e "${CYAN}Добавляем домены в исключения${NC}"
rm -f "$EXCLUDE_FILE"; wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || echo -e "\n${RED}Не удалось загрузить exclude файл${NC}\n"; echo -e "${CYAN}Перезапускаем ${NC}Zapret"
ZAPRET_RESTART; echo -e "${GREEN}Список исключений обновлён!${NC}\n"; PAUSE;; *) return;; esac; done }
strategy_CHOUSE () { echo -ne "\n${YELLOW}Введите версию стратегии ${NC}(1-9)${YELLOW}:${NC} "; read -r choice; if [[ "$choice" =~ ^[1-9]$ ]]; then install_strategy "v$choice"; fi; }
show_current_strategy() { [ -f "$CONF" ] || return; ver=""; for i in $(seq 1 99); do grep -q "#v$i" "$CONF" && { ver="v$i"; break; }; done; yv_ver=""; for i in $(seq -w 1 99); do grep -q "#Yv$i" "$CONF" && { yv_ver="Yv$i"; break; }; done; }
discord_str_add() { if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,19294-19344,50000-50100'/" "$CONF"; fi
if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'$/,2053,2083,2087,2096,8443'/" "$CONF"; fi
if ! grep -q -- "--filter-udp=19294-19344,50000-50100" "$CONF"; then last_line1=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1); if [ -n "$last_line1" ]; then sed -i "${last_line1},\$d" "$CONF"; fi
printf "%s\n" "--new" "--filter-udp=19294-19344,50000-50100" "--filter-l7=discord,stun" "--dpi-desync=fake" "--dpi-desync-repeats=6" "#Dv1" "--new" "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" \
"--dpi-desync=multisplit" "--dpi-desync-split-seqovl=652" "--dpi-desync-split-pos=2" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "'" >> "$CONF"; fi; }
install_strategy() { local version="$1"; local NO_PAUSE="${2:-0}"; local fileGP="/opt/zapret/ipset/zapret-hosts-google.txt"; [ "$NO_PAUSE" != "1" ] && echo
echo -e "${MAGENTA}Устанавливаем стратегию ${version}${NC}\n${CYAN}Меняем стратегию${NC}"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; { echo "  option NFQWS_OPT '"; strategy_"$version"; echo "'"; } >> "$CONF"
printf '%s\n' "gvt1.com" "googleplay.com" "play.google.com" "beacons.gvt2.com" "play.googleapis.com" "play-fe.googleapis.com" "lh3.googleusercontent.com" "android.clients.google.com" "connectivitycheck.gstatic.com" \
"play-lh.googleusercontent.com" "play-games.googleusercontent.com" "prod-lt-playstoregatewayadapter-pa.googleapis.com" | grep -Fxv -f "$fileGP" 2>/dev/null >> "$fileGP"
echo -e "${CYAN}Добавляем домены в исключения${NC}"; rm -f "$EXCLUDE_FILE"; wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || { echo -e "\n${RED}Не удалось загрузить exclude файл${NC}\n"; PAUSE; return; }
discord_str_add; echo -e "${CYAN}Применяем новую стратегию и настройки${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия ${NC}${version}${GREEN} установлена!${NC}"
grep -Fq "=ts" "$CONF" && echo -e "\n${YELLOW}Для работы этой стратегии, в терминале Windows нужно выполнить:${NC}\nnetsh int tcp set global timestamps=enabled"; [ "$NO_PAUSE" != "1" ] && echo && PAUSE; }
choose_strategy_manual() { curl -fsSL "$STR_URL" -o "$TMP_LIST" || { echo -e "\n${RED}Не удалось скачать список${NC}\n"; PAUSE; return 1; }
COUNT=0; > $TMP_SF/strategy_list; while IFS= read -r LINE; do case "$LINE" in Yv[0-9]*) COUNT=$((COUNT + 1)); echo "$LINE" >> $TMP_SF/strategy_list;; esac; done < "$TMP_LIST"
[ "$COUNT" -eq 0 ] && echo -e "${RED}Стратегий не найдено!${NC}" && PAUSE && rm -f $TMP_SF/strategy_list && return 1; echo -en "\n${YELLOW}Введите версию стратегии для YouTube ${NC}(1-$COUNT)${YELLOW}:${NC} "
read CHOICE </dev/tty; if ! echo "$CHOICE" | grep -qE '^[0-9]+$' || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "$COUNT" ]; then return 1; fi; SELECTED_NAME=$(sed -n "${CHOICE}p" $TMP_SF/strategy_list); rm -f $TMP_SF/strategy_list
echo -e "\n${CYAN}Применяем стратегию: ${NC}$SELECTED_NAME"; SAVED_STR="$TMP_SF/selected_str"; > "$SAVED_STR"; FLAG=0; while IFS= read -r LINE; do [ "$LINE" = "$SELECTED_NAME" ] && FLAG=1 && continue; case "$LINE" in Yv[0-9]*) FLAG=0;; esac
[ "$FLAG" -eq 1 ] && printf "%b\n" "$LINE" >> "$SAVED_STR"; done < "$TMP_LIST"; awk '/^[[:space:]]*option NFQWS_OPT '\''/{flag=1} flag{print}' "$CONF" > "$OLD_STR"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; sed -i "/^[[:space:]]*#Yv[0-9]\+/d" "$OLD_STR"
awk '{if(skip){if($0=="--new"||$0~/\047/){skip=0;next}if($0~/^[[:space:]]*$/)next;next}if($0=="--filter-tcp=443"){getline n;if(n=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"){skip=1;next}else{print $0;print n;next}}if($0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt")has_google=1;if($0~/^[[:space:]]*#Yv/)next;print}' "$OLD_STR" > "$NEW_STR"
awk 'BEGIN{inserted=0;has_google=0} $0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"{has_google=1} $0=="--new"&&!inserted{while((getline l<"'"$SAVED_STR"'")>0) if(l!~/^[[:space:]]*$/) print l; print "--new"; inserted=1; next} $0~/^[[:space:]]*option NFQWS_OPT \047$/&&!has_google&&!inserted{print; print "#'"$SELECTED_NAME"'"; while((getline l<"'"$SAVED_STR"'")>0) if(l!~/^[[:space:]]*$/) print l; print "--new"; inserted=1; next} {print}' "$NEW_STR" > "$FINAL_STR"
cat "$FINAL_STR" >> "$CONF"; awk '{if($0=="--new"){if(prev!="--new")print}else print;prev=$0}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"; grep -q "^[[:space:]]*' *\$" "$CONF" || echo "'" >> "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия применена!${NC}\n"; 
grep -Fq "=ts" "$CONF" && echo -e "\n${YELLOW}Для работы этой стратегии, в терминале Windows нужно выполнить:${NC}\nnetsh int tcp set global timestamps=enabled"; PAUSE; }
# ==========================================
# DNS over HTTPS
# ==========================================
DoH_menu() { while true; do get_doh_status; clear; echo -e "${MAGENTA}Меню DNS over HTTPS${NC}\n"; if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e https-dns-proxy >/dev/null 2>&1 && doh_st="Удалить" || doh_st="Установить"; else
opkg list-installed | grep -q '^https-dns-proxy ' && doh_st="Удалить" || doh_st="Установить"; fi; if [ -n "$DOH_STATUS" ]; then if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e https-dns-proxy >/dev/null 2>&1 && echo -e "${YELLOW}DNS over HTTPS: ${NC}$DOH_STATUS\n"
else opkg list-installed | grep -q '^https-dns-proxy ' && echo -e "${YELLOW}DNS over HTTPS: ${NC}$DOH_STATUS\n"; fi; fi
echo -e "${CYAN}1)${GREEN} $doh_st ${NC}DNS over HTTPS\n${CYAN}2)${GREEN} Настроить ${NC}Comss DNS\n${CYAN}3)${GREEN} Настроить ${NC}Xbox DNS\n${CYAN}4)${GREEN} Настроить ${NC}dns.malw.link"
echo -e "${CYAN}5)${GREEN} Настроить ${NC}dns.malw.link (CloudFlare)\n${CYAN}6)${GREEN} Настроить ${NC}dns.mafioznik.xyz\n${CYAN}7)${GREEN} Настроить ${NC}dns.astracat.ru\n${CYAN}0)${GREEN} Вернуть ${NC}настройки по умолчанию"
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r choiceDOH; [ -z "$choiceDOH" ] && return; case "$choiceDOH" in 1) D_o_H;; 2) doh_install && setup_doh "$doh_comss" "Comss.one DNS";;
3) doh_install && setup_doh "$doh_xbox" "Xbox DNS";; 4) doh_install && setup_doh "$doh_query" "dns.malw.link";; 5) doh_install && setup_doh "$doh_queryCF" "dns.malw.link (CloudFlare)";;
6) doh_install && setup_doh "$doh_mafioznik" "dns.mafioznik.xyz";; 7) doh_install && setup_doh "$doh_astracat" "dns.astracat.ru";; 0) doh_install && setup_doh "$doh_def" "настройки по умолчанию";; *) return;; esac; done; }
setup_doh() { local config="$1"; local name="$2"; echo -e "\n${MAGENTA}Настраиваем DNS over HTTPS${NC}\n${CYAN}Настраиваем ${NC}$name\n${CYAN}Применяем новые настройки${NC}"
rm -f "$fileDoH"; printf '%s\n' "$doh_set" "$config" > "$fileDoH"; /etc/init.d/https-dns-proxy reload >/dev/null 2>&1; /etc/init.d/https-dns-proxy restart >/dev/null 2>&1; echo -e "DNS over HTTP ${GREEN}настроен!${NC}\n"; PAUSE; }
get_doh_status() { DOH_STATUS=""; [ ! -f "$fileDoH" ] && return; if grep -q "dns.comss.one" "$fileDoH"; then DOH_STATUS="Comss DNS"; elif grep -q "xbox-dns.ru" "$fileDoH"; then DOH_STATUS="Xbox DNS"; elif grep -q "5u35p8m9i7.cloudflare-gateway.com" "$fileDoH"
then DOH_STATUS="dns.malw.link (CloudFlare)"; elif grep -q "dns.malw.link" "$fileDoH"; then DOH_STATUS="dns.malw.link"; elif grep -q "dns.mafioznik.xyz" "$fileDoH"; then DOH_STATUS="dns.mafioznik.xyz"; elif grep -q "dns.astracat.ru" "$fileDoH"; then DOH_STATUS="dns.astracat.ru"; else DOH_STATUS="установлен"; fi; }
D_o_H() { if [ "$PKG_IS_APK" -eq 1 ]; then PKG_CHECK="https-dns-proxy"; PKG_MANAGER="apk"; else PKG_CHECK="https-dns-proxy"; PKG_MANAGER="opkg"; fi; if { [ "$PKG_MANAGER" = "apk" ] && apk info -e "$PKG_CHECK" >/dev/null 2>&1; } || { [ "$PKG_MANAGER" = "opkg" ] && opkg list-installed | grep -q '^https-dns-proxy '; }; then
echo -e "\n${MAGENTA}Удаляем DNS over HTTPS${NC}\n${CYAN}Удаляем пакеты${NC}"; if [ "$PKG_MANAGER" = "apk" ]; then apk del https-dns-proxy luci-app-https-dns-proxy >/dev/null 2>&1; else opkg --force-removal-of-dependent-packages --autoremove remove https-dns-proxy luci-app-https-dns-proxy >/dev/null 2>&1; fi
echo -e "${CYAN}Удаляем файлы конфигурации${NC}"; rm -f /etc/config/https-dns-proxy /etc/init.d/https-dns-proxy; echo -e "DNS over HTTPS${GREEN} удалён!${NC}\n"; PAUSE; else echo -e "\n${MAGENTA}Устанавливаем DNS over HTTPS${NC}\n${CYAN}Обновляем список пакетов${NC}"
if [ "$PKG_MANAGER" = "apk" ]; then apk update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении apk!${NC}\n"; PAUSE; return; }; else opkg update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при обновлении списка пакетов!${NC}\n"; PAUSE; return; }; fi
echo -e "${CYAN}Устанавливаем ${NC}https-dns-proxy"; if [ "$PKG_MANAGER" = "apk" ]; then apk add https-dns-proxy >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установке!${NC}\n"; PAUSE; return; }; else opkg install https-dns-proxy >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установке!${NC}\n"; PAUSE; return; }; fi
echo -e "${CYAN}Устанавливаем ${NC}luci-app-https-dns-proxy"; if [ "$PKG_MANAGER" = "apk" ]; then apk add luci-app-https-dns-proxy >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установке!${NC}\n"; PAUSE; return; }; else opkg install luci-app-https-dns-proxy >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установке!${NC}\n"; PAUSE; return; }; fi
echo -e "DNS over HTTPS${GREEN} установлен!${NC}\n"; PAUSE; fi; }
doh_install() { [ -f "$fileDoH" ] && return 0; echo -e "\n${RED}DNS over HTTPS не установлен!${NC}\n"; PAUSE; return 1; }
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
toggle_web() { if web_is_enabled; then echo -e "\n${MAGENTA}Удаляем доступ из браузера${NC}"; if [ "$PKG_IS_APK" -eq 1 ]; then apk del luci-app-ttyd ttyd >/dev/null 2>&1; else opkg remove luci-app-ttyd ttyd >/dev/null 2>&1; fi
rm -f /etc/config/ttyd; echo -e "${GREEN}Доступ удалён!${NC}\n"; PAUSE; else echo -e "\n${MAGENTA}Активируем доступ из браузера${NC}"; echo -e "${CYAN}Обновляем список пакетов${NC}"; if [ "$PKG_IS_APK" -eq 1 ]
then if ! apk update >/dev/null 2>&1; then echo -e "\n${RED}Ошибка при обновлении apk!${NC}\n"; PAUSE; return; fi; else if ! opkg update >/dev/null 2>&1; then echo -e "\n${RED}Ошибка при обновлении opkg!${NC}\n"; PAUSE; return; fi; fi
echo -e "${CYAN}Устанавливаем ${NC}ttyd"; if [ "$PKG_IS_APK" -eq 1 ]; then if ! apk add luci-app-ttyd >/dev/null 2>&1; then echo -e "\n${RED}Ошибка при установке ttyd!${NC}\n"; PAUSE; return; fi; else if ! opkg install luci-app-ttyd >/dev/null 2>&1
then echo -e "\n${RED}Ошибка при установке ttyd!${NC}\n"; PAUSE; return; fi; fi; echo -e "${CYAN}Настраиваем ${NC}ttyd"; sed -i 's#/bin/login#-t fontSize=15 sh /usr/bin/zms#' /etc/config/ttyd; /etc/init.d/ttyd restart >/dev/null 2>&1; if pidof ttyd >/dev/null
then echo -e "${GREEN}Служба запущена!${NC}\n\n${YELLOW}Доступ из браузера: ${NC}$LAN_IP:7681\n"; PAUSE; else echo -e "\n${RED}Ошибка! Служба не запущена!${NC}\n"; PAUSE; fi; fi; }
# ==========================================
# Вкл/Выкл QUIC
# ==========================================
quic_is_blocked() { uci show firewall | grep -q "name='Block_UDP_80'" && uci show firewall | grep -q "name='Block_UDP_443'"; }
toggle_quic() {	if quic_is_blocked; then echo -e "\n${MAGENTA}Отключаем блокировку QUIC${NC}"; for RULE in Block_UDP_80 Block_UDP_443; do
while true; do IDX=$(uci show firewall | grep "name='$RULE'" | cut -d. -f2 | cut -d= -f1 | head -n1); [ -z "$IDX" ] && break; uci delete firewall.$IDX >/dev/null 2>&1; done; done
uci commit firewall >/dev/null 2>&1; /etc/init.d/firewall restart >/dev/null 2>&1; echo -e "${GREEN}Блокировка ${NC}QUIC ${GREEN}отключена${NC}\n"; PAUSE; else echo -e "\n${MAGENTA}Включаем блокировку QUIC${NC}"
uci add firewall rule >/dev/null 2>&1; uci set firewall.@rule[-1].name='Block_UDP_80' >/dev/null 2>&1; uci add_list firewall.@rule[-1].proto='udp' >/dev/null 2>&1; uci set firewall.@rule[-1].src='lan' >/dev/null 2>&1
uci set firewall.@rule[-1].dest='wan' >/dev/null 2>&1; uci set firewall.@rule[-1].dest_port='80' >/dev/null 2>&1; uci set firewall.@rule[-1].target='REJECT' >/dev/null 2>&1
uci add firewall rule >/dev/null 2>&1; uci set firewall.@rule[-1].name='Block_UDP_443' >/dev/null 2>&1; uci add_list firewall.@rule[-1].proto='udp' >/dev/null 2>&1; uci set firewall.@rule[-1].src='lan' >/dev/null 2>&1
uci set firewall.@rule[-1].dest='wan' >/dev/null 2>&1; uci set firewall.@rule[-1].dest_port='443' >/dev/null 2>&1; uci set firewall.@rule[-1].target='REJECT' >/dev/null 2>&1
uci commit firewall >/dev/null 2>&1; /etc/init.d/firewall restart >/dev/null 2>&1;	echo -e "${GREEN}Блокировка ${NC}QUIC ${GREEN}включена${NC}\n";	PAUSE; fi; }
# ==========================================
# Системное меню
# ==========================================
sys_menu() { while true; do web_is_enabled && WEB_TEXT="Удалить доступ к скрипту из браузера" || WEB_TEXT="Активировать доступ к скрипту из браузера"
quic_is_blocked && QUIC_TEXT="${GREEN}Отключить блокировку${NC} QUIC ${GREEN}(80,443)${NC}" || QUIC_TEXT="${GREEN}Включить блокировку${NC} QUIC ${GREEN}(80,443)${NC}"
CURR=$(curr_MIR); clear; echo -e "${MAGENTA}Системное меню${NC}\n"; printed=0; if [ "$CURR" != "default / OpenWrt" ]; then echo -e "${YELLOW}Используется зеркало: ${NC}$CURR"; printed=1; fi
if web_is_enabled; then echo -e "${YELLOW}Доступ из браузера:${NC} $LAN_IP:7681"; printed=1; fi
if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then echo -e "${YELLOW}FIX для Flow Offloading:${NC} ${GREEN}включён${NC}"; printed=1; fi
if quic_is_blocked; then echo -e "${YELLOW}Блокировка QUIC: ${GREEN}включена${NC}"; printed=1; fi
[ "$printed" -eq 1 ] && echo; echo -e "${CYAN}1) ${GREEN}Системная информация${NC}\n${CYAN}2) ${GREEN}$WEB_TEXT${NC}\n${CYAN}3) ${GREEN}$QUIC_TEXT${NC}\n${CYAN}4) ${GREEN}Меню выбора зеркала ${NC}OpenWrt\n${CYAN}5) ${GREEN}Запустить${NC} blockcheck\n${CYAN}6) ${GREEN}Удалить ${NC}Zapret"
FO=$(uci get firewall.@defaults[0].flow_offloading 2>/dev/null); FOHW=$(uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null); FIX=$(grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc && echo 1 || echo 0)
if [ "$FO" = 1 ] || [ "$FOHW" = 1 ] || [ "$FIX" = 1 ]; then if [ "$FIX" = 1 ]; then echo -e "${CYAN}0) ${GREEN}Отключить${NC} FIX ${GREEN}для${NC} Flow Offloading"; else echo -e "${CYAN}0) ${GREEN}Применить${NC} FIX ${GREEN}для${NC} Flow Offloading"; fi; fi
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read -r choiceMN; case "$choiceMN" in 1) Sys_Info;; 2) toggle_web;; 3) toggle_quic;; 4) menu_MIR;;
5) [ ! -f /etc/init.d/zapret ] && { echo -e "\n${RED}Zapret не установлен!${NC}\n"; PAUSE; continue; }; stop_zapret "1"; grep -q 'echo "Start Zapret"' /opt/zapret/blockcheck.sh || sed -i $'/^[[:space:]]*read A/a\\\t\techo "Start Zapret"; /etc/init.d/zapret restart >/dev/null 2>&1' /opt/zapret/blockcheck.sh
echo -e "${GREEN}Ctrl+C - oстановить blockcheck${NC}\n"; chmod +x /opt/zapret/blockcheck.sh; /opt/zapret/blockcheck.sh; start_zapret;; 6) uninstall_zapret;;
0) FO=$(uci get firewall.@defaults[0].flow_offloading 2>/dev/null); FOHW=$(uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null); if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then echo -e "\n${MAGENTA}Отключаем FIX для Flow Offloading${NC}"
sed -i 's/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/meta l4proto { tcp, udp } flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc; fw4 restart >/dev/null 2>&1; echo -e "FIX ${GREEN}отключён!${NC}\n"; PAUSE; elif [ "$FO" = 1 ] || [ "$FOHW" = 1 ]; then echo -e "\n${MAGENTA}Применяем FIX для Flow Offloading${NC}"
sed -i 's/meta l4proto { tcp, udp } flow offload @ft;/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc; fw4 restart >/dev/null 2>&1; echo -e "FIX ${GREEN}успешно применён!${NC}\n"; PAUSE; fi;; *) echo; return;; esac; done; }
# ==========================================
# Hosts menu
# ==========================================
hosts_reset() { echo -e "\n${MAGENTA}Восстанавливаем hosts${NC}"; : > /etc/hosts; echo -e "127.0.0.1\tlocalhost\n\n::1\tlocalhost ip6-localhost ip6-loopback\nff02::1 ip6-allnodes\nff02::2 ip6-allrouters" > /etc/hosts; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "hosts ${GREEN}восстановлен!${NC}\n"; PAUSE; }
status_block() { while IFS= read -r line; do [ -z "$line" ] && continue; grep -Fxq "$line" "$HOSTS_FILE" || return 1; done < <(printf '%b\n' "$1"); return 0; }
add_block() { while IFS= read -r line; do [ -z "$line" ] && continue; grep -Fxq "$line" "$HOSTS_FILE" || echo "$line" >> "$HOSTS_FILE"; done < <(printf '%b\n' "$1"); }
remove_block() { while IFS= read -r line; do [ -z "$line" ] && continue; sed -i "\|^$line$|d" "$HOSTS_FILE"; done < <(printf '%b\n' "$1"); }
toggle_block() { if status_block "$1"; then remove_block "$1"; echo -e "\n${CYAN}Удаляем и применяем${NC}"; else add_block "$1"; echo -e "\n${CYAN}Добавляем и применяем${NC}"; fi; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "${GREEN}Готово!${NC}\n"; PAUSE; }
toggle_all() { if status_block "$ALL_BLOCKS"; then remove_block "$ALL_BLOCKS"; echo -e "\n${CYAN}Удаляем и применяем${NC}"; else add_block "$ALL_BLOCKS"; echo -e "\n${CYAN}Добавляем и применяем${NC}"; fi; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "${GREEN}Готово!${NC}\n"; PAUSE; }
get_state() { status_block "$1" && echo "Удалить " || echo "Добавить"; }
menu_hosts() { while true; do clear; S_ALL=$(status_block "$ALL_BLOCKS" && echo "${GREEN}Удалить все домены${NC}" || echo "${GREEN}Добавить все домены${NC}"); prin=0
echo -e "${MAGENTA}Меню управления доменами в hosts${NC}\n"; if hosts_enabled; then echo -e "${YELLOW}Домены в hosts: ${GREEN}добавлены${NC}"; prin=1; fi; [ "$prin" -eq 1 ] && echo
echo -e "${CYAN}1) ${GREEN}$(get_state "$PDA")${NC} 4pda.to\n${CYAN}2) ${GREEN}$(get_state "$RUTOR")${NC} rutor.info\n${CYAN}3) ${GREEN}$(get_state "$NTC")${NC} ntc.party"
echo -e "${CYAN}4) ${GREEN}$(get_state "$INSTAGRAM")${NC} Instagram & Facebook\n${CYAN}5) ${GREEN}$(get_state "$LIBRUSEC")${NC} lib.rus.ec\n${CYAN}6) ${GREEN}$(get_state "$AI")${NC} AI сервисы\n${CYAN}7) ${GREEN}$(get_state "$TWCH")${NC} Twitch\n${CYAN}8) ${GREEN}$(get_state "$TGWeb")${NC} Telegram Web\n${CYAN}9) $S_ALL\n${CYAN}0) ${GREEN}Восстановить ${NC}hosts"
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} ";read -r c; case "$c" in
1) toggle_block "$PDA";; 2) toggle_block "$RUTOR";; 3) toggle_block "$NTC";; 4) toggle_block "$INSTAGRAM";; 5) toggle_block "$LIBRUSEC";; 6) toggle_block "$AI";; 7) toggle_block "$TWCH";; 8) toggle_block "$TGWeb";; 9) toggle_all;; 0) hosts_reset;; *) break;; esac; done; }
# ==========================================
# Тест стратегий
# ==========================================
check_zpr_off() { echo -e "\n${CYAN}Контрольный тест: ${YELLOW}Zapret выключен${NC}"; /etc/init.d/zapret stop >/dev/null 2>&1; OK=0; check_all_urls; if [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; elif [ "$OK" -ge $((TOTAL/2)) ]
then COLOR="${YELLOW}"; else COLOR="${RED}"; fi; echo -e "${CYAN}Результат теста: ${COLOR}$OK/$TOTAL${NC}"; echo -e "Контрольный тест (Zapret выключен) → ${OK}/${TOTAL}" >> "$RESULTS"; /etc/init.d/zapret start >/dev/null 2>&1; }
check_url() { TEXT=$(echo "$1" | cut -d"|" -f1); LINK=$(echo "$1" | cut -d"|" -f2); if curl -sL --connect-timeout 3 --max-time 5 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "$LINK" >/dev/null 2>&1; then echo 1 >> "$TMP_OK"; echo -e "${GREEN}[ OK ]${NC} $TEXT"; else echo -e "${RED}[FAIL]${NC} $TEXT"; fi; }
check_all_urls() { TMP_OK="$TMP_SF/z_ok.$$"; : > "$TMP_OK"; RUN=0; while IFS= read -r URL; do [ -z "$URL" ] && continue; check_url "$URL" & RUN=$((RUN+1)); if [ "$RUN" -ge "$PARALLEL" ]; then wait; RUN=0; fi
done <<EOF
$URLS
EOF
wait; OK=$(wc -l < "$TMP_OK" | tr -d ' '); rm -f "$TMP_OK"; }
prepare_urls() { : > "$OUT_DPI"; printf '%s\n' "gosuslugi|https://gosuslugi.ru" "esia.gosuslugi.ru|https://esia.gosuslugi.ru" "nalog.ru|https://nalog.ru" "lkfl2.nalog.ru|https://lkfl2.nalog.ru" \
"rutube.ru|https://rutube.ru" "ntc.party|https://ntc.party/" "instagram.com|https://instagram.com" "facebook.com|https://facebook.com" "rutor.info|https://rutor.info" "rutracker.org|https://rutracker.org" \
"epidemz.net.co|https://epidemz.net.co" "nnmclub.to|https://nnmclub.to" "openwrt.org|https://openwrt.org" "sxyprn.net|https://sxyprn.net" "spankbang.com|https://ru.spankbang.com" "pornhub.com|https://pornhub.com" \
"discord.com|https://discord.com" "updates.discord.com|https://updates.discord.com" "x.com|https://x.com" "filmix.my|https://filmix.my" "flightradar24.com|https://flightradar24.com" "play.google.com|https://play.google.com" \
"kinozal.tv|https://kinozal.tv" "cub.red|https://cub.red" "ottai.com|https://ottai.com" >> "$OUT_DPI"; curl -fsSL "$RAW" | sed -n 's/.*"id":[[:space:]]*"\([^"]*\)".*"url":[[:space:]]*"\([^"]*\)".*/\1|\2/p' >> "$OUT_DPI" \
|| { echo -e "\n${RED}Ошибка загрузки DPI списка${NC}\n"; PAUSE; return 1; }; TOTAL=$(grep -c "|" "$OUT_DPI"); }
check_current_strategy() { clear; echo -e "${MAGENTA}Тестирование текущей стратегии${NC}\n"; prepare_urls; URLS="$(cat "$OUT_DPI")"; OK=0; check_all_urls; if [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; elif [ "$OK" -ge $((TOTAL/2)) ]; then COLOR="${YELLOW}"; else COLOR="${RED}"; fi; echo -e "\n${CYAN}Результат теста: ${COLOR}$OK/$TOTAL${NC}\n"; rm -f "$OUT_DPI"; PAUSE; }
show_test_results() { clear; echo -e "${MAGENTA}Результат тестирования стратегий${NC}\n"; : > "$TMP_RES"; [ -s "$RES1" ] && cat "$RES1" >> "$TMP_RES"; [ -s "$RES2" ] && cat "$RES2" >> "$TMP_RES"; [ ! -s "$TMP_RES" ] && { rm -f "$TMP_RES"; echo -e "${RED}Результат не найден!${NC}\n"; PAUSE; return; }
awk '!seen && /^Контрольный тест/ {print; seen=1; next} !/^Контрольный тест/ {print}' "$TMP_RES" > "${TMP_RES}.u"; mv "${TMP_RES}.u" "$TMP_RES"; TOTAL=$(head -n1 "$TMP_RES" | cut -d'/' -f2); awk -F'[/ ]' '{for(i=1;i<=NF;i++) if($i~/^[0-9]+$/){print $i "/" $(i+1), $0; break}}' "$TMP_RES" | sort -nr -k1,1 | while read -r line; do
COUNT=$(echo "$line" | awk -F'/' '{print $1}'); TEXT=$(echo "$line" | cut -d' ' -f2-); if echo "$TEXT" | grep -q Zapret; then COLOR="$CYAN"; elif [ "$COUNT" -eq "$TOTAL" ]; then COLOR="$GREEN"; elif [ "$COUNT" -gt $((TOTAL/2)) ]; then COLOR="$YELLOW"
else COLOR="$RED"; fi; echo -e "${COLOR}${TEXT}${NC}"; done; rm -f "$TMP_RES"; echo; PAUSE; }
show_single_result() { clear; echo -e "${MAGENTA}Результат тестирования стратегий${NC}\n"; local FILE="$1"; [ ! -s "$FILE" ] && { echo -e "${RED}Результат не найден!${NC}\n"; [ -z "$NO_PAUSE" ] && PAUSE; return; }; TMP_RES="/tmp/zapret_results_single.$$"
cat "$FILE" > "$TMP_RES"; awk '!seen && /^Контрольный тест/ {print; seen=1; next} !/^Контрольный тест/ {print}' "$TMP_RES" > "${TMP_RES}.u"; mv "${TMP_RES}.u" "$TMP_RES"; TOTAL=$(head -n1 "$TMP_RES" | cut -d'/' -f2); awk -F'[/ ]' '{for(i=1;i<=NF;i++) if($i~/^[0-9]+$/){print $i "/" $(i+1), $0; break}}' "$TMP_RES" |
sort -nr -k1,1 | while read -r line; do COUNT=$(echo "$line" | awk -F'/' '{print $1}'); TEXT=$(echo "$line" | cut -d' ' -f2-); if echo "$TEXT" | grep -q Zapret; then COLOR="$CYAN"; elif [ "$COUNT" -eq "$TOTAL" ]; then COLOR="$GREEN"; elif [ "$COUNT" -gt $((TOTAL/2)) ]; then
COLOR="$YELLOW"; else COLOR="$RED"; fi; echo -e "${COLOR}${TEXT}${NC}"; done; rm -f "$TMP_RES"; [ -z "$NO_PAUSE" ] && echo && PAUSE; }
run_test_flowseal() { clear; echo -e "${MAGENTA}Тестирование стратегий Flowseal${NC}\n\n${CYAN}Собираем стратегии для теста${NC}"; RESULTS="/opt/zapret/tmp/results_flowseal.txt"; rm -rf "$TMP_SF"
download_strategies 1; cp "$OUT" "$STR_FILE"; cp "$CONF" "$BACK"; sed -i '/#Y/d' "$STR_FILE"; run_test_core "$RESULTS"; }
run_test_versions() { clear; echo -e "${MAGENTA}Тестирование стратегий v${NC}\n\n${CYAN}Собираем стратегии для теста${NC}"; RESULTS="/opt/zapret/tmp/results_versions.txt"; : > "$STR_FILE"; cp "$CONF" "$BACK"
for N in $(seq 1 100); do strategy_v$N >> "$STR_FILE" 2>/dev/null || break; done; sed -i '/#Y/d' "$STR_FILE"; run_test_core "$RESULTS"; }
run_all_tests() { NO_PAUSE=1 RESULTS="/opt/zapret/tmp/results_flowseal.txt" run_test_flowseal; NO_PAUSE=1 RESULTS="/opt/zapret/tmp/results_versions.txt" run_test_versions; show_test_results; }
run_test_core() { local RESULTS="$1"; prepare_urls || return 1; URLS="$(cat "$OUT_DPI")"; TOTAL=$(grep -c "|" "$OUT_DPI"); TOTAL_STR=$(grep -c '^#' "$STR_FILE")
echo -e "${CYAN}Найдено стратегий: ${NC}$TOTAL_STR"; : > "$RESULTS"; check_zpr_off; LINES=$(grep -n '^#' "$STR_FILE" | cut -d: -f1); CUR=0
echo "$LINES" | while read START; do CUR=$((CUR+1)); NEXT=$(echo "$LINES" | awk -v s="$START" '$1>s{print;exit}'); if [ -z "$NEXT" ]; then
sed -n "${START},\$p" "$STR_FILE" > "$TEMP_FILE"; else sed -n "${START},$((NEXT-1))p" "$STR_FILE" > "$TEMP_FILE"; fi
BLOCK=$(cat "$TEMP_FILE"); NAME=$(head -n1 "$TEMP_FILE"); NAME="${NAME#\#}"; awk -v block="$BLOCK" 'BEGIN{skip=0}
/option NFQWS_OPT '\''/ {printf "\toption NFQWS_OPT '\''\n%s\n'\''\n", block; skip=1; next}
skip && /^'\''$/ {skip=0; next}
!skip {print}' "$CONF" > "${CONF}.tmp"; mv "${CONF}.tmp" "$CONF"; echo -e "\n${CYAN}Тестируем стратегию: ${YELLOW}${NAME}${NC} ($CUR/$TOTAL_STR)"; ZAPRET_RESTART; OK=0; check_all_urls
if [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; elif [ "$OK" -ge $((TOTAL/2)) ]; then COLOR="${YELLOW}"; else COLOR="${RED}"; fi; echo -e "${CYAN}Результат теста: ${COLOR}$OK/$TOTAL${NC}"; echo -e "${NAME} → ${OK}/${TOTAL}" >> "$RESULTS"; done
sort -t'/' -k1 -nr "$RESULTS" -o "$RESULTS"; mv -f "$BACK" "$CONF"; rm -f "$OUT_DPI"; ZAPRET_RESTART; [ -z "$NO_PAUSE" ] && show_single_result "$RESULTS"; }
TEST_menu() { while true; do show_current_strategy; RKN_Check; clear; echo -e "${MAGENTA}Меню тестирования стратегий${NC}\n"; 
[ -f "$CONF" ] && line=$(grep -m1 '^#general' "$CONF") && [ -n "$line" ] && echo -e "${YELLOW}Используется стратегия:${NC}  ${CYAN}${line#?}${NC}"
if [ -f "$CONF" ]; then current="$ver$( [ -n "$ver" ] && [ -n "$yv_ver" ] && echo " / " )$yv_ver"; DV=$(grep -o -E '^#[[:space:]]*Dv[0-9][0-9]*' "$CONF" | sed 's/^#[[:space:]]*/\/ /' | head -n1)
if [ -n "$current" ]; then echo -e "${YELLOW}Используется стратегия:${NC}  ${CYAN}$current${DV:+ $DV}${RKN_STATUS:+ $RKN_STATUS}${NC}"; elif [ -n "$RKN_STATUS" ]; then echo -e "${YELLOW}Используется стратегия:${NC}${CYAN}  РКН${DV:+ $DV}${NC}"; fi; fi
STATUS_V=""; STATUS_FLOW=""; [ -s "/opt/zapret/tmp/results_versions.txt" ] && STATUS_V="${GREEN}v${NC}" || STATUS_V="${RED}v${NC}"
[ -s "/opt/zapret/tmp/results_flowseal.txt" ] && STATUS_FLOW="${GREEN}Flowseal${NC}" || STATUS_FLOW="${RED}Flowseal${NC}"; echo -e "${YELLOW}Тест пройден:${NC} ${STATUS_V} | ${STATUS_FLOW}\n"
echo -e "${CYAN}1) ${GREEN}Тестировать стратегии ${NC}v\n${CYAN}2) ${GREEN}Тестировать стратегии ${NC}Flowseal\n${CYAN}3) ${GREEN}Тестировать ${NC}v${GREEN} и ${NC}Flowseal${GREEN} стратегии${NC}\n${CYAN}4) ${GREEN}Тестировать ${NC}текущую${GREEN} стратегию ${NC}\n${CYAN}5) ${GREEN}Тестировать стратегии ${NC}YouTube"
if { [ -s "/opt/zapret/tmp/results_flowseal.txt" ] || [ -s "/opt/zapret/tmp/results_versions.txt" ]; }; then echo -e "${CYAN}9) ${GREEN}Результаты тестирования стратегий${NC}"; fi
if { [ -s "/opt/zapret/tmp/results_flowseal.txt" ] || [ -s "/opt/zapret/tmp/results_versions.txt" ]; }; then echo -e "${CYAN}0) ${GREEN}Удалить результаты тестования${NC}"; fi
echo -ne "${CYAN}Enter) ${GREEN}Выход в меню стратегий${NC}\n\n${YELLOW}Выберите пункт:${NC} ";read -r t; case "$t" in
1) run_test_versions;; 2) run_test_flowseal;; 3) run_all_tests;; 4) check_current_strategy;;  5) auto_stryou;; 9) show_test_results;; 0) rm -f /opt/zapret/tmp/results_flowseal.txt; rm -f /opt/zapret/tmp/results_versions.txt; echo -e "\n${GREEN}Результаты тестирования удалены!${NC}\n"; PAUSE;; *) break;; esac; done; }
# ==========================================
# Системная информация
# ==========================================
Sys_Info() { if command -v apk >/dev/null 2>&1; then PKG_IS_APK=1; else PKG_IS_APK=0; fi; if ! command -v curl >/dev/null 2>&1; then echo -e "\n${GREEN}Устанавливаем ${NC}curl"
if command -v apk >/dev/null 2>&1; then apk update >/dev/null 2>&1 && apk add curl >/dev/null 2>&1; else opkg update >/dev/null 2>&1 && opkg install curl >/dev/null 2>&1; fi; fi
clear; echo -e "${GREEN}===== Информация о системе =====${NC}"; MODEL=$(cat /tmp/sysinfo/model); ARCH=$(sed -n "s/.*ARCH='\(.*\)'/\1/p" /etc/openwrt_release); OWRT=$(grep '^DISTRIB_RELEASE=' /etc/openwrt_release | cut -d"'" -f2); echo -e "$MODEL\n$ARCH\n$OWRT"
echo -e "\n${GREEN}===== Пользовательские пакеты =====${NC}"; if [ "$PKG_IS_APK" -eq 1 ]; then apk info -v | awk '
BEGIN{grp[""]=0}
{pkg=$1; gsub(/^(luci-(app|mod|proto|theme)-|kmod-|lib|ucode-mod-)/,"",pkg); grp[pkg]=grp[pkg]?grp[pkg]"\n"$1:$1}
END{
for(k in grp){
n=split(grp[k],a,"\n");
if(n<2) continue;
for(i=1;i<=n;i++) for(j=i+1;j<=n;j++) if(a[i]>a[j]){t=a[i];a[i]=a[j];a[j]=t}
for(i=1;i<=n;i+=2) if(i+1<=n){L=a[i];R=a[i+1];if(L~/^luci-/&&R!~/^luci-/){t=L;L=R;R=t} print L" | "R}else print a[i]
}
}'
else awk '/^Package:/{p=$2}/^Status: install user/{k=p;sub(/^(luci-(app|mod|proto|theme)-|kmod-|lib|ucode-mod-)/,"",k);grp[k]=grp[k]?grp[k]"\n"p:p}
END{
for(k in grp){n=split(grp[k],a,"\n");if(n<2)continue;for(i=1;i<=n;i++)for(j=i+1;j<=n;j++)if(a[i]>a[j]){t=a[i];a[i]=a[j];a[j]=t}
for(i=1;i<=n;i+=2)if(i+1<=n){L=a[i];R=a[i+1];if(L~/^luci-/&&R!~/^luci-/){t=L;L=R;R=t}print L" | "R}else print a[i]}
for(k in grp){n=split(grp[k],a,"\n"); if(n==1)single[++s]=a[1]}
for(i=1;i<=s;i++)for(j=i+1;j<=s;j++)if(length(single[i])<length(single[j])||(length(single[i])==length(single[j])&&single[i]>single[j])){t=single[i];single[i]=single[j];single[j]=t}
half=int((s+1)/2);for(i=1;i<=half;i++){j=s-i+1;if(i<j){L=single[i];R=single[j];if(L~/^luci-/&&R!~/^luci-/){t=L;L=R;R=t}print L" | "R}else print single[i]}; }' /usr/lib/opkg/status; fi
echo -e "\n${GREEN}===== Flow Offloading =====${NC}"; sw=$(uci -q get firewall.@defaults[0].flow_offloading); hw=$(uci -q get firewall.@defaults[0].flow_offloading_hw)
if grep -q 'ct original packets ge 30' /usr/share/firewall4/templates/ruleset.uc 2>/dev/null; then dpi="${RED}yes${NC}"; else dpi="${GREEN}no${NC}"; fi; if [ "$hw" = "1" ]; then out="HW: ${RED}on${NC}"; elif [ "$sw" = "1" ]; then out="SW: ${RED}on${NC}"
else out="SW: ${GREEN}off${NC} | HW: ${GREEN}off${NC}"; fi; out="$out | FIX: ${dpi}"; echo -e "$out"; if /etc/init.d/https-dns-proxy status >/dev/null 2>&1; then
echo -e "\n${GREEN}===== Настройки DNS over HTTPS =====${NC}"; [ -f /etc/config/https-dns-proxy ] && sed -n "s/^[[:space:]]*option resolver_url '\([^']*\)'.*/\1/p" /etc/config/https-dns-proxy; else
echo -e "\n${GREEN}===== Проверка GitHub =====${NC}"; RATE=$(curl -s https://api.github.com/rate_limit | grep '"remaining"' | head -1 | awk '{print $2}' | tr -d ,)
[ -z "$RATE" ] && RATE_OUT="${RED}N/A${NC}" || RATE_OUT=$([ "$RATE" -eq 0 ] && echo -e "${RED}0${NC}" || echo -e "${GREEN}$RATE${NC}")
echo -n "API: "; curl -Is --connect-timeout 3 https://api.github.com >/dev/null 2>&1 && echo -e "${GREEN}ok${NC} | Limit: $RATE_OUT" || echo -e "${RED}fail${NC} | Limit: $RATE_OUT"; fi
echo -e "\n${GREEN}===== Проверка IPv4 / IPv6 =====${NC}"; PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "https://ipinfo.io/$IP/org" 2>/dev/null | sed -E 's/AS[0-9]+ ?//; s/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//g; s/  +/ /g; s/^ +| +$//g')
[ -z "$PROVIDER" ] && PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "http://ip-api.com/line/?fields=as" 2>/dev/null | sed -E 's/AS[0-9]+ ?//; s/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//g; s/  +/ /g; s/^ +| +$//g')
[ -z "$PROVIDER" ] && PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "https://ipwho.is/$IP" 2>/dev/null | sed -E 's/.*"isp":"([^"]+)".*/\1/' | sed -E 's/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//Ig' | sed -E 's/  +/ /g; s/^ +| +$//g'); [ -n "$PROVIDER" ] && echo "Провайдер: $PROVIDER"
echo -n "Google IPv4: "; time=$(ping -4 -c 1 -W 2 google.com 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}'); if [ -n "$time" ]; then echo -e "${GREEN}ok ($time ms)${NC}"; else echo -e "${RED}fail${NC}"; fi
echo -n "Google IPv6: "; time=$(ping -6 -c 1 -W 2 google.com 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}'); if [ -n "$time" ]; then echo -e "${GREEN}ok ($time ms)${NC}"; else echo -e "${RED}fail${NC}"; fi
echo -e "\n${GREEN}===== Настройки Zapret =====${NC}"; zpr_info() { if [ "$PKG_IS_APK" -eq 1 ]; then INSTALLED_VER=$(apk info zapret | awk '/^zapret-[0-9]/ {gsub(/^zapret-|-r[0-9]+.*$/,""); print; exit}')
else INSTALLED_VER=$(opkg list-installed | awk '/^zapret / {gsub(/-r[0-9]+$/,"",$3); print $3; exit}'); fi; NFQ_RUN=$(pgrep -f nfqws | wc -l); NFQ_ALL=$(/etc/init.d/zapret info 2>/dev/null | grep -o 'instance[0-9]\+' | wc -l); NFQ_STAT=""
[ "$NFQ_RUN" -ne 0 ] || [ "$NFQ_ALL" -ne 0 ] && { [ "$NFQ_RUN" -eq "$NFQ_ALL" ] && NFQ_CLR="$GREEN" || NFQ_CLR="$RED"; NFQ_STAT="${NFQ_CLR}[${NFQ_RUN}/${NFQ_ALL}]${NC}"; }
if /etc/init.d/zapret status 2>/dev/null | grep -qi "running"; then ZAPRET_STATUS="${GREEN}запущен${NC} $NFQ_STAT"; else ZAPRET_STATUS="${RED}остановлен${NC}"; fi; SCRIPT_FILE="/opt/zapret/init.d/openwrt/custom.d/50-script.sh"
if [ -f "$SCRIPT_FILE" ]; then line=$(head -n1 "$SCRIPT_FILE"); case "$line" in *QUIC*) name="50-quic4all" ;; *stun*) name="50-stun4all" ;; *"discord media"*) name="50-discord-media" ;; *"discord subnets"*) name="50-discord" ;; *) name="" ;; esac; fi
TCP_VAL=$(grep -E "^[[:space:]]*option NFQWS_PORTS_TCP[[:space:]]+'" "$CONF" | sed "s/.*'\(.*\)'.*/\1/"); UDP_VAL=$(grep -E "^[[:space:]]*option NFQWS_PORTS_UDP[[:space:]]+'" "$CONF" | sed "s/.*'\(.*\)'.*/\1/")
echo -e "${GREEN}$INSTALLED_VER${NC} | $ZAPRET_STATUS"; [ -n "$name" ] && echo -e "${GREEN}$name${NC}"; echo -e "TCP: ${GREEN}$TCP_VAL${NC}\nUDP: ${GREEN}$UDP_VAL${NC}"
echo -e "\n${GREEN}===== Стратегия =====${NC}"; awk '/^[[:space:]]*option[[:space:]]+NFQWS_OPT[[:space:]]*'\''/ {flag=1; sub(/^[[:space:]]*option[[:space:]]+NFQWS_OPT[[:space:]]*'\''/, ""); next}  
flag {if(/'\''/) {sub(/'\''$/, ""); print; exit} print}' "$CONF"; }; if [ -f /etc/init.d/zapret ]; then zpr_info; else echo -e "${RED}Zapret не установлен!${NC}\n"; fi
echo -e "\n${GREEN}===== Доступность сайтов =====${NC}"; prepare_urls; total=$(wc -l < "$OUT_DPI"); half=$(( (total + 1) / 2 )); COL_OFFSET=25; for idx in $(seq 1 $half); do
left_line=$(sed -n "${idx}p" "$OUT_DPI"); left_name=$(echo "$left_line" | cut -d'|' -f1); left_url=$(echo "$left_line" | cut -d'|' -f2)
right_idx=$((idx + half)); right_line=$(sed -n "${right_idx}p" "$OUT_DPI"); right_name=$(echo "$right_line" | cut -d'|' -f1); right_url=$(echo "$right_line" | cut -d'|' -f2)
if curl -sL --connect-timeout 2 --max-time 3 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "$left_url" >/dev/null 2>&1; then
left_status="[${GREEN} OK ${NC}]"; else left_status="[${RED}FAIL${NC}]"; fi; if [ -n "$right_url" ]; then
if curl -sL --connect-timeout 2 --max-time 3 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "$right_url" >/dev/null 2>&1; then
right_status="[${GREEN} OK ${NC}]"; else right_status="[${RED}FAIL${NC}]"; fi; echo -e "$left_status $left_name$(printf '%*s' $((COL_OFFSET - ${#left_name})) '')$right_status $right_name"; else echo -e "$left_status $left_name"; fi; done; echo; PAUSE; }
# ==========================================
# Смена зеркала
# ==========================================
set_mirror() { NEW_BASE="$1"; sed -i "s|https://.*/releases/|https://$NEW_BASE/releases/|g" "$CONFZ"; echo -e "\n${CYAN}Изменяем зеркало\nОбновляем список пакетов${NC}"
PKGM="$(command -v apk >/dev/null 2>&1 && echo apk || echo opkg)"; if ! $PKGM update >/dev/null 2>&1; then echo -e "\n${RED}Ошибка! Зеркало не работает!\n${GREEN}Зеркало сброшено на ${NC}default ${GREEN}/${NC} OpenWrt${GREEN}!${NC}\n"
sed -i "s|https://.*/releases/|https://downloads.openwrt.org/releases/|g" "$CONFZ"; PAUSE; return 1; fi; echo -e "${GREEN}Пакеты обновлены! Зеркало работает!${NC}\n"; PAUSE; }
curr_MIR() { if [ -f "$CONFZ" ]; then URL=$(head -n1 "$CONFZ"); case "$URL" in *tiguinet.net*) echo "Belgium" ;; *utwente.nl*) echo "Netherlands" ;; *freifunk.net*) echo "Germany" ;; *ps.kz*) echo "Kazakhstan" ;;
*sjtu.edu.cn*) echo "China" ;; *downloads.openwrt.org*) echo "default / OpenWrt" ;; *) echo "неизвестное" ;; esac; else echo "файл не найден"; fi; }
menu_MIR() { while true; do clear; CURR=$(curr_MIR); echo -e "${MAGENTA}Меню выбора зеркала OpenWrt${NC}\n\n${YELLOW}Используется зеркало: ${GREEN}$CURR${NC}\n\n${CYAN}1)${NC} China"
echo -e "${CYAN}2)${NC} Germany\n${CYAN}3)${NC} Belgium\n${CYAN}4)${NC} Kazakhstan\n${CYAN}5)${NC} Netherlands\n${CYAN}6)${NC} default / OpenWrt\n${CYAN}Enter)${GREEN} Выход в системное меню${NC}"
echo -en "\n${YELLOW}Выберите зеркало: ${NC}"; read -r z; case "$z" in 1) set_mirror "mirror.sjtu.edu.cn/openwrt" ;; 2) set_mirror "mirror.berlin.freifunk.net/downloads.openwrt.org" ;;
3) set_mirror "mirror.tiguinet.net/openwrt" ;; 4) set_mirror "mirror.ps.kz/openwrt" ;; 5) set_mirror "ftp.snt.utwente.nl/pub/software/openwrt" ;; 6) set_mirror "downloads.openwrt.org" ;; *) break ;; esac; done; }
# ==========================================
# Главное меню
# ==========================================
show_menu() { get_versions; get_doh_status; show_current_strategy; RKN_Check; mkdir -p "$TMP_SF"; CURR=$(curr_MIR); clear; echo -e "╔════════════════════════════════════╗\n║     ${BLUE}Zapret on remittor Manager${NC}     ║\n╚════════════════════════════════════╝\n                     ${DGRAY}by StressOzz v$ZAPRET_MANAGER_VERSION${NC}"
if [ ! -f /etc/init.d/zapret ]; then Z_ACTION_TEXT="Установить"; Z_ACTION_FUNC="install_Zapret"; elif [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ]; then Z_ACTION_TEXT="Удалить" Z_ACTION_FUNC="uninstall_zapret"; else Z_ACTION_TEXT="Обновить"; Z_ACTION_FUNC="install_Zapret"; fi
for pkg in byedpi youtubeUnblock; do if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e "$pkg" >/dev/null 2>&1 && echo -e "\n${RED}Найден установленный ${NC}$pkg${RED}!${NC}\nZapret${RED} может работать некорректно с ${NC}$pkg${RED}!${NC}"
else opkg list-installed | grep -q "^$pkg" && echo -e "\n${RED}Найден установленный ${NC}$pkg${RED}!${NC}\nZapret${RED} может работать некорректно с ${NC}$pkg${RED}!${NC}"; fi; done
if uci get firewall.@defaults[0].flow_offloading 2>/dev/null | grep -q '^1$' || uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null | grep -q '^1$'; then if ! grep -q 'meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc
then echo -e "\n${RED}Включён ${NC}Flow Offloading${RED}!${NC}\n${NC}Zapret${RED} некорректно работает с включённым ${NC}Flow Offloading${RED}!\nПримените ${NC}FIX${RED} в системном меню!${NC}"; fi; fi; pgrep -f "/opt/zapret" >/dev/null 2>&1 && str_stp_zpr="Остановить" || str_stp_zpr="Запустить"
echo -e "\n${YELLOW}Установленная версия:    ${INST_COLOR}$INSTALLED_DISPLAY${NC}"; [ -n "$ZAPRET_STATUS" ] && echo -e "${YELLOW}Статус Zapret:${NC}           $ZAPRET_STATUS"
if hosts_enabled; then echo -e "${YELLOW}Домены в hosts:          ${GREEN}добавлены${NC}"; fi; [ -f "$DATE_FILE" ] && echo -e "${YELLOW}Резервная копия:${NC}         ${GREEN}сохранена"; show_script_50 && [ -n "$name" ] && echo -e "${YELLOW}Установлен скрипт:${NC}       $name"; grep -q "$Fin_IP_Dis" /etc/hosts && echo -e "${YELLOW}Финские IP для Discord:  ${GREEN}включены${NC}"
[ -f "$CONF" ] && grep -q "option NFQWS_PORTS_UDP.*88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF" && grep -q -- "--filter-udp=88,1024-2407,2409-4499,4501-19293,19345-49999,50101-65535" "$CONF" && echo -e "${YELLOW}Стратегия для игр:${NC}       ${GREEN}включена${NC}"
if [ -n "$DOH_STATUS" ]; then if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e https-dns-proxy >/dev/null 2>&1 && echo -e "${YELLOW}DNS over HTTPS:${NC}          $DOH_STATUS"; else opkg list-installed | grep -q '^https-dns-proxy ' && echo -e "${YELLOW}DNS over HTTPS:${NC}          $DOH_STATUS"; fi; fi
if web_is_enabled; then echo -e "${YELLOW}Доступ из браузера:${NC}      $LAN_IP:7681"; fi; quic_is_blocked && if quic_is_blocked; then echo -e "${YELLOW}Блокировка QUIC:${NC}         ${GREEN}включена${NC}"; fi; if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc
then echo -e "${YELLOW}FIX для Flow Offloading:${NC} ${GREEN}включён${NC}"; fi; if [ "$CURR" != "default / OpenWrt" ]; then echo -e "${YELLOW}Используется зеркало:${NC}    $CURR"; fi; [ -f "$CONF" ] && line=$(grep -m1 '^#general' "$CONF") && [ -n "$line" ] && echo -e "${YELLOW}Используется стратегия:${NC}  ${CYAN}${line#?}${NC}"
if [ -f "$CONF" ]; then current="$ver$( [ -n "$ver" ] && [ -n "$yv_ver" ] && echo " / " )$yv_ver"; DV=$(grep -o -E '^#[[:space:]]*Dv[0-9][0-9]*' "$CONF" | sed 's/^#[[:space:]]*/\/ /' | head -n1)
if [ -n "$current" ]; then echo -e "${YELLOW}Используется стратегия:${NC}  ${CYAN}$current${DV:+ $DV}${RKN_STATUS:+ $RKN_STATUS}${NC}"; elif [ -n "$RKN_STATUS" ]; then echo -e "${YELLOW}Используется стратегия:${NC}${CYAN}  РКН${DV:+ $DV}${NC}"; fi; fi
echo -e "\n${CYAN}1) ${GREEN}$Z_ACTION_TEXT${NC} Zapret\n${CYAN}2) ${GREEN}$str_stp_zpr ${NC}Zapret\n${CYAN}3) ${GREEN}Меню стратегий${NC}"
echo -e "${CYAN}4) ${GREEN}Меню ${NC}DNS over HTTPS\n${CYAN}5) ${GREEN}Меню настройки ${NC}Discord\n${CYAN}6) ${GREEN}Меню управления настройками\n${CYAN}7) ${GREEN}Меню управления доменами в ${NC}hosts\n${CYAN}8) ${GREEN}Удалить ${NC}→${GREEN} установить ${NC}→${GREEN} настроить${NC} Zapret\n${CYAN}0) ${GREEN}Системное меню${NC}" ; echo -ne "${CYAN}Enter) ${GREEN}Выход${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in 888) echo; uninstall_zapret "1"; install_Zapret "1"; curl -fsSL https://raw.githubusercontent.com/StressOzz/Test/refs/heads/main/zapret -o "$CONF"; hosts_add "$ALL_BLOCKS"; rm -f "$EXCLUDE_FILE"; wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL"; ZAPRET_RESTART; PAUSE;;
1) $Z_ACTION_FUNC;; 2) pgrep -f /opt/zapret >/dev/null 2>&1 && stop_zapret || start_zapret;; 3) menu_str;; 4) DoH_menu;; 5) Discord_menu;; 6) backup_menu;; 7) menu_hosts;; 8) zapret_key;; 0) sys_menu;; *) echo; exit 0;; esac; }; while true; do show_menu; done
