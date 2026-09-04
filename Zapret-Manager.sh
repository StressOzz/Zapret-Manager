#!/bin/sh
# =========================================
# Zapret Manager by StressOzz
# =========================================
ZAPRET_MANAGER_VERSION="9.85"; STR_VERSION_AUTOINSTALL="v7"
GREEN="\033[1;32m"; RED="\033[1;31m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"; MAGENTA="\033[1;35m"; BLUE="\033[0;34m"; NC="\033[0m"; DGRAY="\033[38;5;244m"

GH_RAW_HOST="https://raw.githubusercontent.com"; GH_MAIN_HOST="https://github.com"
# GH_PROXY="https://gh-proxy.org/"; GH_CHECK_URL="${GH_RAW_HOST}/StressOzz/Zapret-Manager/refs/heads/main/Zapret-Manager.sh"
# echo -e "${CYAN}Проверяем доступность ${NC}raw.githubusercontent.com"; if wget -q -T 4 -O /dev/null "$GH_CHECK_URL" 2>/dev/null; then GH_OK=1
GH_RAW="$GH_RAW_HOST"
GH_MAIN="$GH_MAIN_HOST"
# echo -e "raw.githubusercontent.com ${GREEN}доступен!${NC}\n"; else GH_OK=0; GH_RAW="${GH_PROXY}${GH_RAW_HOST}"; GH_MAIN="${GH_PROXY}${GH_MAIN_HOST}"
# echo -e "raw.githubusercontent.com ${RED}недоступен${CYAN} — ${YELLOW}используем прокси!${NC}\n"; fi

ZAPRET_VERSION="72.20260307"; PODKOP_LATEST_VER="0.9.6"; TG_MTProto="0.9.3"; MT_VERSION="0.8.2"; ZAPRET2_VERSION="1.0.4"
SPL_VER="26.8.1.3"; TG_GO_VERSION="1.4.1"; TG_RS_VERSION="2.2.5"; BYEDPI_LATEST_VER="0.17.3"

echo "sh <(wget -q -O - ${GH_RAW}/StressOzz/Zapret-Manager/main/Zapret-Manager.sh)" > /usr/bin/zms; chmod +x /usr/bin/zms
echo "sh <(wget -q -O - ${GH_RAW}/StressOzz/Zapret-Manager/main/Zapret-Manager.sh) \"\$@\"" > /usr/bin/zmsA; chmod +x /usr/bin/zmsA

BASE_URL="${GH_MAIN}/2Grey/awg-openwrt/releases/download/"
FLOWSEAL_STR_ZIP="${GH_MAIN}/Flowseal/zapret-discord-youtube/archive/refs/heads/main.zip"
GEO_HOSTS="${GH_RAW}/Internet-Helper/GeoHideDNS/refs/heads/main/hosts/hosts"
STR_URL="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/StrYoutube"
RAW="${GH_RAW}/hyperion-cs/dpi-checkers/refs/heads/main/ru/tcp-16-20/suite.v2.json"
RKN_URL="${GH_RAW}/IndeecFOX/zapret4rocket/refs/heads/master/extra_strats/TCP/RKN/List.txt"
URL_OLD="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/MagiTrickle/configOLD.yaml"
URL_DEFAULT="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/MagiTrickle/config.yaml"
URL_ITDOG="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/MagiTrickle/configAD.yaml"
EXCLUDE_URL="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/zapret-hosts-user-exclude.txt"

PORTS_UDP="88,1024-2407,2409-4499,4502-19293,19345-49999,50101-65535"; PORTS_TCP="2802,2302,2502,3478-3480,3724,6000-8000,8085,8090,8100,8903,8904,25565,27015-27030,27036-27037,50001,60442"

DOMAINS="youtu.be youtube.com i.ytimg.com i9.ytimg.com yt3.ggpht.com yt4.ggpht.com googleapis.com jnn-pa.googleapis.com googleusercontent.com signaler-pa.youtube.com youtubei.googleapis.com manifest.googlevideo.com yt3.googleusercontent.com rr4---sn-4g5e6nze.googlevideo.com rr4---sn-5go7yner.googlevideo.com rr4---sn-q4flrnsl.googlevideo.com rr5---sn-n8v7knez.googlevideo.com rr2---sn-q4fl6ndl.googlevideo.com rr1---sn-q4fl6n6y.googlevideo.com rr1---sn-aj5go5-53.googlevideo.com rr1---sn-4axm-n8vs.googlevideo.com rr14---sn-n8v7kn7r.googlevideo.com rr16---sn-axq7sn76.googlevideo.com rr4---sn-jvhnu5g-c35d.googlevideo.com rr1---sn-8ph2xajvh-5xge.googlevideo.com rr1---sn-xguxaxjvh-gufl.googlevideo.com rr1---sn-gvnuxaxjvh-jx3z.googlevideo.com rr1---sn-gvnuxaxjvh-jx3l.googlevideo.com rr1---sn-gvnuxaxjvh-o8ge.googlevideo.com rr5---sn-gvnuxaxjvh-n8vk.googlevideo.com rr10---sn-gvnuxaxjvh-304z.googlevideo.com rr12---sn-gvnuxaxjvh-bvwz.googlevideo.com rr3---sn-ug5onuxaxjvh-n8v6.googlevideo.com rr1---sn-ug5onuxaxjvh-p5ge.googlevideo.com rr1---sn-ug5onuxaxjvh-p3ul.googlevideo.com rr1---sn-ug5onuxaxjvh-n8v6.googlevideo.com rr1---sn-u5uuxaxjvhg0-ocje.googlevideo.com"

OWRTAWG=$(grep '^DISTRIB_RELEASE=' /etc/openwrt_release | cut -d"'" -f2); ARCHAWG="$(grep DISTRIB_ARCH /etc/openwrt_release | cut -d"'" -f2)_$(grep DISTRIB_TARGET /etc/openwrt_release | cut -d"'" -f2 | tr '/' '_')" 
CRON_CMD="/etc/init.d/mihomo restart"; CONFIGPATH="/etc/magitrickle/state/config.yaml"; PACKAGES_UPDATED=0; TS_WARN_FLAG="/opt/zapret/tmp/ts_warning_shown"
CRON_FILE="/etc/crontabs/root"; CONFIGMIX="/etc/mihomo/config.yaml"; LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null | cut -d/ -f1)
CONF="/etc/config/zapret"; CUSTOM_DIR="/opt/zapret/init.d/openwrt/custom.d/"; HOSTLIST_FILE="/opt/zapret/ipset/zapret-hosts-user.txt"; fileGP="/opt/zapret/ipset/zapret-hosts-google.txt"
TMP_SF="/tmp/zapret_temp"; HOSTS_FILE="/etc/hosts"; TMP_LIST="$TMP_SF/zapret_yt_list.txt"; tmpDIR="/tmp/PodkopAWG"
GV_XTREME_FILE="/opt/zapret/tmp/GvXtreme"; GV_XTREME_PORTS="80,88,444-65535"; GV_XTREME_NFQWS_PORTS="80,88,443-65535"
IF_NAME="AWG"; PROTO="amneziawg"; DEV_NAME="amneziawg0"; DISCORD_DEF_HOSTLIST="/opt/zapret/ipset_def/zapret-hosts-user.txt"
SAVED_STR="$TMP_SF/StrYou.txt"; HOSTS_USER="$TMP_SF/hosts-user.txt"; OUT_DPI="$TMP_SF/dpi_urls.txt"; OUT="$TMP_SF/str_flow.txt"; ZIP="$TMP_SF/repo.zip"
BACKUP_FILE="/opt/zapret/tmp/hosts_temp.txt"; STR_FILE="$TMP_SF/str_test.txt"; TEMP_FILE="$TMP_SF/str_temp.txt"
RESULTS="/opt/zapret/tmp/zapret_bench.txt"; BACK="$TMP_SF/zapret_back.txt"; TMP_RES="$TMP_SF/zapret_results_all.$$"
FINAL_STR="$TMP_SF/StrFINAL.txt"; NEW_STR="$TMP_SF/StrNEW.txt"; OLD_STR="$TMP_SF/StrOLD.txt"; SECRET_FILE="/etc/tg-ws-proxy/secret.conf"
ARCH_FULL="$(cat /etc/openwrt_release | grep DISTRIB_ARCH | cut -d"'" -f2)"; MODEL="$(cat /tmp/sysinfo/model 2>/dev/null)"
RES1="/opt/zapret/tmp/results_flowseal.txt"; RES2="/opt/zapret/tmp/results_versions.txt"; RES3="/opt/zapret/tmp/results_all.txt"
RES_CUSTOM="/opt/zapret/tmp/results_custom.txt"; CUSTOM_STR_FILE="/root/custom_test.txt"; CUSTOM_RESULTS="$RES_CUSTOM"; CUSTOM_BACK="$TMP_SF/zapret_custom_backup.conf"
RES_DOMAIN="/opt/zapret/tmp/results_domain.txt"; RES_YOUTUBE="/opt/zapret/tmp/results_youtube.txt"; Fin_IP_Dis="104\.25\.158\.178 finland[0-9]\{5\}\.discord\.media"; PARALLEL=8
EXCLUDE_FILE="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"; fileDoH="/etc/config/https-dns-proxy"; EXPERT_MODE_FILE="/etc/zapret_manager_expert_mode"
INSTAGRAM="#Instagram&Facebook\n57.144.222.34 instagram.com www.instagram.com\n157.240.9.174 instagram.com www.instagram.com\n157.240.245.174 instagram.com www.instagram.com b.i.instagram.com z-p42-chat-e2ee-ig.facebook.com help.instagram.com
157.240.205.174 instagram.com www.instagram.com\n57.144.244.192 static.cdninstagram.com graph.instagram.com i.instagram.com api.instagram.com edge-chat.instagram.com\n31.13.66.63 scontent.cdninstagram.com scontent-hel3-1.cdninstagram.com
57.144.244.1 facebook.com www.facebook.com fb.com fbsbx.com\n57.144.244.128 static.xx.fbcdn.net scontent.xx.fbcdn.net\n31.13.67.20 scontent-hel3-1.xx.fbcdn.net"
TGWeb="#TelegramWeb\n149.154.167.220 core.telegram.org api.telegram.org flora.web.telegram.org kws1-1.web.telegram.org kws1.web.telegram.org kws2-1.web.telegram.org kws2.web.telegram.org kws4-1.web.telegram.org
149.154.167.220 kws4.web.telegram.org kws5-1.web.telegram.org kws5.web.telegram.org pluto-1.web.telegram.org pluto.web.telegram.org td.telegram.org telegram.dog
149.154.167.220 telegram.me telegram.org telegram.space telesco.pe venus.web.telegram.org web.telegram.org zws1-1.web.telegram.org zws1.web.telegram.org
149.154.167.220 tg.dev t.me zws2-1.web.telegram.org zws2.web.telegram.org zws4-1.web.telegram.org zws5-1.web.telegram.org zws5.web.telegram.org"
NTC="#ntc.party\n130.255.77.28 ntc.party"; TWCH="#Twitch\n45.155.204.190 usher.ttvnw.net gql.twitch.tv"; NALOG="#Nalog\n213.24.64.175 lkfl2.nalog.ru\n213.24.64.181 lknpd.nalog.ru"
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
SCell="#Supercell\n103.27.157.38 accounts.supercell.com cdn.id.supercell.com clashofclans.inbox.supercell.com game-assets.brawlstarsgame.com
103.27.157.38 game-assets.clashofclans.com game-assets.clashroyaleapp.com security.id.supercell.com store.supercell.com
31.25.239.132 accounts.supercell.com cdn.id.supercell.com clashofclans.inbox.supercell.com game-assets.brawlstarsgame.com
31.25.239.132 game-assets.clashofclans.com game-assets.clashroyaleapp.com game.boombeachgame.com game.mocogame.com security.id.supercell.com store.supercell.com
185.246.223.127 game.brawlstarsgame.com\n62.133.62.97 game.clashroyaleapp.com\n193.23.209.189 gamea.clashofclans.com\n108.61.167.26 game.squadbustersgame.com"
SPFY="#Spotify\n45.155.204.190 api.spotify.com login5.spotify.com encore.scdn.co gew1-spclient.spotify.com spclient.wg.spotify.com
45.155.204.190 api-partner.spotify.com aet.spotify.com www.spotify.com accounts.spotify.com open.spotify.com
45.155.204.190 accounts.scdn.co gew1-dealer.spotify.com open-exp.spotifycdn.com www-growth.scdn.co"; TAPEop="#tapeop.dev\n216.24.57.251 www.tapeop.dev tapeop.dev\n216.24.57.3 www.tapeop.dev tapeop.dev"
SPFYEXT="#SpotifyEXT\n45.155.204.190 spotify.com www.spotify.com accounts.spotify.com login.spotify.com login5.spotify.com login.app.spotify.com auth.spotify.com account.spotify.com api.spotify.com api-partner.spotify.com spclient.wg.spotify.com gew1-spclient.spotify.com
45.155.204.190 guc3-spclient.spotify.com gae2-spclient.spotify.com gue1-spclient.spotify.com gnl-spclient.spotify.com spclient.spotify.com ap-gew1.spotify.com ap-gue1.spotify.com ap-gae2.spotify.com ap-gew4.spotify.com ap-sto3.spotify.com
45.155.204.190 ap-guc3.spotify.com ap.spotify.com apresolve.spotify.com aet.spotify.com gew1-dealer.g2.spotify.com guc3-dealer.g2.spotify.com gue1-dealer.g2.spotify.com dealer.spotify.com dealer-wg.spotify.com edge-web.dual-gslb.spotify.com
45.155.204.190 client.spotify.com web-partner.spotify.com connect.spotify.com gce.spotify.com clienttoken.spotify.com exp.wg.spotify.com pixel.spotify.com pixel-static.spotify.com image-upload.spotify.com content.spotify.com analytics.spotify.com
45.155.204.190 crashdump.spotify.com log.spotify.com logger.spotify.com metrics.spotify.com desktop.spotify.com audio-fa-tls13.spotifycdn.com heads-fa-tls13.spotifycdn.com heads4-fa-tls13.spotifycdn.com image-cdn-fa.spotifycdn.com
45.155.204.190 concerts.spotifycdn.com mrkt.spotifycdn.com pickasso.spotifycdn.com podz-content.spotifycdn.com seed-mix-image.spotifycdn.com thisis-images.spotifycdn.com wap.spotifycdn.com web-sdk-assets.spotifycdn.com spotifycdn.com spotifycdn.net
35.186.224.24 open.spotify.com\n162.159.141.124 audio4-fa-tls13.spotifycdn.com audio-cf.spotifycdn.com open-exp.spotifycdn.com\n23.36.163.34 audio-ak-spotify-com.akamaized.net\n2.16.168.44 audio4-ak-spotify-com.akamaized.net
199.232.210.248 scdn.co i.scdn.co line-up.scdn.co mosaic.scdn.co daily-mix.scdn.co lineup-images.scdn.co encore.scdn.co image-cdn-fa.scdn.co accounts.scdn.co www.scdn.co www-growth.scdn.co av.scdn.co seafoam.scdn.co
23.48.23.145 heads-ak-spotify-com.akamaized.net\n45.155.204.190 xpui.app.spotify.com"
GITH_RAW="#githubusercontent.com\n146.75.22.132 objects.githubusercontent.com release-assets.githubusercontent.com raw.githubusercontent.com private-user-images.githubusercontent.com gist.githubusercontent.com
146.75.22.132 camo.githubusercontent.com avatars.githubusercontent.com avatars0.githubusercontent.com avatars1.githubusercontent.com avatars2.githubusercontent.com avatars3.githubusercontent.com avatars4.githubusercontent.com avatars5.githubusercontent.com"
GITH="#github.com\n140.82.114.3 github.com\n185.199.110.154 github.githubassets.com\n185.199.110.133 camo.githubassets.com"
USoft="#Ubisoft\n52.6.7.14 ubi.com\n172.67.139.108 r6s.com\n54.155.2.87 rainbow6.com\n52.222.149.31 ubisoft.com\n54.76.54.196 uplay.ubisoft.com\n2.23.89.92 static3.cdn.ubi.com
18.209.141.203 connect.ubisoft.com\n2.23.89.244 ubiservices.cdn.ubi.com\n99.83.188.134 public-ubiservices.ubi.com\n3.33.249.140 public-ws-ubiservices.ubi.com\n"
ALL_BLOCKS="$AI\n$INSTAGRAM\n$NTC\n$LIBRUSEC\n$TGWeb\n$TWCH\n$SCell\n$SPFY"; TMP_ARCHIVE_RS="/tmp/tg-ws-proxy-rs.tar.gz"; TMP_DIR_RS="/tmp/tg-ws-proxy-rs"
hosts_enabled() { if grep -q "### dns.malw.link" /etc/hosts; then hosts_echo="Malw.link"; return 0; elif grep -q "#mafioznik" /etc/hosts; then hosts_echo="Mafioznik"; return 0
elif grep -q "### geohide.ru: hosts file" /etc/hosts; then if grep -q "^# Регион серверов: US$" /etc/hosts; then hosts_echo="GeoHide US"; elif grep -q "^# Регион серверов: EU$" /etc/hosts
then hosts_echo="GeoHide EU"; elif grep -q "^# Регион серверов: RU$" /etc/hosts; then hosts_echo="GeoHide RU"; else hosts_echo="GeoHide"; fi; return 0
elif grep -q "45.155.204.190\|instagram.com\|rutor.info\|lib.rus.ec\|ntc.party\|twitch.tv\|web.telegram.org\|www.spotify.com\|store.supercell.com\|raw.githubusercontent.com\|lkfl2.nalog.ru" /etc/hosts; then hosts_echo="добавлены"; return 0; fi; return 1; }
hosts_add() { printf "%b\n" "$1" | while IFS= read -r L; do grep -qxF "$L" /etc/hosts || echo "$L" >> /etc/hosts; done; /etc/init.d/dnsmasq restart >/dev/null 2>&1; }; D() { printf '%b' "$(printf '%s' "$1" | sed 's/../\\x&/g')"; }
ZAPRET_RESTART () { chmod +x /opt/zapret/sync_config.sh; /opt/zapret/sync_config.sh; /etc/init.d/zapret restart >/dev/null 2>&1; sleep 1; }
PAUSE() { echo -ne "Нажмите Enter..."; read dummy; }; BACKUP_DIR="/opt/zapret_backup"; DATE_FILE="$BACKUP_DIR/date_backup.txt"
BIN_PATH_GO="/usr/bin/tg-ws-proxy-go"; INIT_PATH_GO="/etc/init.d/tg-ws-proxy-go"; BIN_PATH_RS="/usr/bin/tg-ws-proxy-rs"; INIT_PATH_RS="/etc/init.d/tg-ws-proxy-rs"
X1="68747470733a2f2f7767636c692e76657263656c2e617070"; X2="68747470733a2f2f73616e74612d61746d6f2e72752f776172702f776172702e706870"
REPO="xyzmean/splify"; WARP_EP="engage.cloudflareclient.com:4500"; WARP_IFACE="warp0"; TMP_SPL="/tmp/splify"; S101="$(D "$X1")"; S102="$(D "$X2")"; W1="$S101"; II="$S102"
AWG_JC=4; AWG_JMIN=40; AWG_JMAX=70; AWG_H1=1; AWG_H2=2; AWG_H3=3; AWG_H4=4; AWG_S1=0; AWG_S2=0; AWG_JMAX=70; AWG_H1=1; AWG_H2=2; AWG_H3=3; AWG_H4=4; AWG_S1=0; AWG_S2=0
AWG_I1="<b 0xce000000010897a297ecc34cd6dd000044d0ec2e2e1ea2991f467ace4222129b5a098823784694b4897b9986ae0b7280135fa85e196d9ad980b150122129ce2a9379531b0fd3e871ca5fdb883c369832f730e272d7b8b74f393f9f0fa43f11e510ecb2219a52984410c204cf875585340c62238e14ad04dff382f2c200e0ee22fe743b9c6b8b043121c5710ec289f471c91ee414fca8b8be8419ae8ce7ffc53837f6ade262891895f3f4cecd31bc93ac5599e18e4f01b472362b8056c3172b513051f8322d1062997ef4a383b01706598d08d48c221d30e74c7ce000cdad36b706b1bf9b0607c32ec4b3203a4ee21ab64df336212b9758280803fcab14933b0e7ee1e04a7becce3e2633f4852585c567894a5f9efe9706a151b615856647e8b7dba69ab357b3982f554549bef9256111b2d67afde0b496f16962d4957ff654232aa9e845b61463908309cfd9de0a6abf5f425f577d7e5f6440652aa8da5f73588e82e9470f3b21b27b28c649506ae1a7f5f15b876f56abc4615f49911549b9bb39dd804fde182bd2dcec0c33bad9b138ca07d4a4a1650a2c2686acea05727e2a78962a840ae428f55627516e73c83dd8893b02358e81b524b4d99fda6df52b3a8d7a5291326e7ac9d773c5b43b8444554ef5aea104a738ed650aa979674bbed38da58ac29d87c29d387d80b526065baeb073ce65f075ccb56e47533aef357dceaa8293a523c5f6f790be90e4731123d3c6152a70576e90b4ab5bc5ead01576c68ab633ff7d36dcde2a0b2c68897e1acfc4d6483aaaeb635dd63c96b2b6a7a2bfe042f6aed82e5363aa850aace12ee3b1a93f30d8ab9537df483152a5527faca21efc9981b304f11fc95336f5b9637b174c5a0659e2b22e159a9fed4b8e93047371175b1d6d9cc8ab745f3b2281537d1c75fb9451871864efa5d184c38c185fd203de206751b92620f7c369e031d2041e152040920ac2c5ab5340bfc9d0561176abf10a147287ea90758575ac6a9f5ac9f390d0d5b23ee12af583383d994e22c0cf42383834bcd3ada1b3825a0664d8f3fb678261d57601ddf94a8a68a7c273a18c08aa99c7ad8c6c42eab67718843597ec9930457359dfdfbce024afc2dcf9348579a57d8d3490b2fa99f278f1c37d87dad9b221acd575192ffae1784f8e60ec7cee4068b6b988f0433d96d6a1b1865f4e155e9fe020279f434f3bf1bd117b717b92f6cd1cc9bea7d45978bcc3f24bda631a36910110a6ec06da35f8966c9279d130347594f13e9e07514fa370754d1424c0a1545c5070ef9fb2acd14233e8a50bfc5978b5bdf8bc1714731f798d21e2004117c61f2989dd44f0cf027b27d4019e81ed4b5c31db347c4a3a4d85048d7093cf16753d7b0d15e078f5c7a5205dc2f87e330a1f716738dce1c6180e9d02869b5546f1c4d2748f8c90d9693cba4e0079297d22fd61402dea32ff0eb69ebd65a5d0b687d87e3a8b2c42b648aa723c7c7daf37abcc4bb85caea2ee8f55bec20e913b3324ab8f5c3304f820d42ad1b9f2ffc1a3af9927136b4419e1e579ab4c2ae3c776d293d397d575df181e6cae0a4ada5d67ecea171cca3288d57c7bbdaee3befe745fb7d634f70386d873b90c4d6c6596bb65af68f9e5121e67ebf0d89d3c909ceedfb32ce9575a7758ff080724e1ab5d5f43074ecb53a479af21ed03d7b6899c36631c0166f9d47e5e1d4528a5d3d3f744029c4b1c190cbfbad06f5f83f7ad0429fa9a2719c56ffe3783460e166de2d8>"
AUTO_RESULTS="/opt/zapret/tmp/results_auto.txt"; AUTO_BACK="$TMP_SF/zapret_auto_back.txt"; AUTO_LOG="/opt/zapret/tmp/auto_best.log"; AUTO_CRON_CMD="/usr/bin/zmsA --auto-best"
AUTO_LOCK="/tmp/zapret_auto_best.lock"; AUTO_STOP_FLAG="$TMP_SF/zapret_auto_best.stop"; LOCAL_ARCH="$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)"
BIN_VER_GO="/usr/bin/tg-ws-proxy-go_ver"; BIN_VER_RS="/usr/bin/tg-ws-proxy-rs_ver"; BYEDPI_DNS_BACKUP="/etc/byedpi_dns_localuse"

if command -v opkg >/dev/null 2>&1; then PKG="opkg"; GO_SUF="1"; CONFZ="/etc/opkg/distfeeds.conf"; PKG_IS_APK=0; UPDATE="opkg update"; INSTALL="opkg install"
DELETE="opkg remove"; ARCH="$(opkg print-architecture | awk '{print $2}' | tail -n1)"; VER_SUF="r1-all"; SUF_MT=""; SPL_SUF="all"; RELEASE_TAG="v${BYEDPI_LATEST_VER}-24.10"
RAZ="ipk"; TMP_FILE_GO="/tmp/tg-ws-proxy.ipk"; else PKG="apk"; GO_SUF="r1"; CONFZ="/etc/apk/repositories.d/distfeeds.list"; PKG_IS_APK=1; SPL_SUF="noarch"; RELEASE_TAG="v${BYEDPI_LATEST_VER}-25.12"
UPDATE="apk update"; INSTALL="apk add --allow-untrusted"; DELETE="apk del"; ARCH="$(apk --print-arch 2>/dev/null)"; RAZ="apk"; VER_SUF="r1"; SUF_MT="r"; TMP_FILE_GO="/tmp/tg-ws-proxy.apk"; fi

update_packages() {
    [ "$PACKAGES_UPDATED" = "1" ] && return 0
    echo -e "${CYAN}Обновляем список пакетов${NC}"
    if $UPDATE >/dev/null 2>&1; then
        PACKAGES_UPDATED=1
        return 0
    fi
    echo -e "${RED}Ошибка обновления списка пакетов!${NC}"
    echo -e "\n${CYAN}Подбираем рабочее зеркало ${NC}OpenWRT"

    [ -f "$CONFZ" ] || {
        echo -e "\n${RED}Файл репозиториев не найден: $CONFZ${NC}\n"
        PAUSE
        return 1
    }
    CURRENT_MIRROR=$(head -n1 "$CONFZ" 2>/dev/null | awk '{print $NF}' | sed 's|https\://||;s|/releases/.*||')
    cp "$CONFZ" /tmp/distfeeds.conf.bak

try_mirror() {
        MIRROR="$1"
        echo -e "\n${CYAN}Проверяем ${NC}$MIRROR"
        if ! wget -q --spider --timeout=3 "https://$MIRROR/releases/" >/dev/null 2>&1; then
            echo -e "$MIRROR ${RED}недоступен!${NC}"
            return 1
        fi      
        echo -e "$MIRROR ${GREEN}доступен!${NC}"
        sed -i "s|https://.*/releases/|https://$MIRROR/releases/|g" "$CONFZ"
        echo -e "${CYAN}Проверяем обновление пакетов${NC}"
        if $UPDATE >/dev/null 2>&1; then
            echo -e "${GREEN}Обновление пакетов выполнено успешно!${NC}"
            echo -e "${CYAN}Используем зеркало: ${NC}$MIRROR"
            return 0
        fi
        echo -e "${RED}Ошибка обновления пакетов!${NC}"
        cp /tmp/distfeeds.conf.bak "$CONFZ"
        return 1
}
    for MIRROR in \
        "mirror-03.infra.openwrt.org" \
        "ftp.halifax.rwth-aachen.de/openwrt" \
        "mirror.accum.se/mirror/openwrt.org" \
        "ftp.snt.utwente.nl/pub/software/openwrt" \
        "mirror.berlin.freifunk.net/downloads.openwrt" \
        "mirror.sjtu.edu.cn/openwrt" \
        "downloads.openwrt.org"
    do
        [ "$MIRROR" = "$CURRENT_MIRROR" ] && continue
        if try_mirror "$MIRROR"; then
            rm -f /tmp/distfeeds.conf.bak
            PACKAGES_UPDATED=1
            return 0
        fi
    done
    cp /tmp/distfeeds.conf.bak "$CONFZ"
    rm -f /tmp/distfeeds.conf.bak
    echo -e "\n${RED}Не удалось найти рабочее зеркало OpenWRT!${NC}\n"
    PAUSE
    return 1
}

if ! curl --version >/dev/null 2>&1; then clear; echo -e "curl ${RED}отсутствует ${NC}или${RED} работает некорректно${NC}\n"; echo -e "${MAGENTA}Устанавливаем ${NC}curl"
$DELETE curl libcurl >/dev/null 2>&1; if ! update_packages; then echo -e "\n${RED}Ошибка обновления списка пакетов!${NC}\n"; else PACKAGES_UPDATED=1; fi
echo -e "${CYAN}Устанавливаем ${NC}curl"; if ! $INSTALL libcurl curl >/dev/null 2>&1; then echo -e "\n${RED}Не удалось установить curl!${NC}\n"; PAUSE; fi; fi

get_zapret2_ver() {
    if [ "$PKG_IS_APK" -eq 1 ]; then
        IDX_URL2="https://packages.routerich.ru/25.12/mediatek/filogic/routerich/"
        PATTERN='zapret2-[0-9][^"]*\.apk'
    else
        IDX_URL2="https://packages.routerich.ru/24.10/mediatek/filogic/routerich/"
        PATTERN='zapret2_[0-9][^"]*_aarch64_cortex-a53\.ipk'
    fi

    FNAME2=""

    for i in 1 2 3; do
        FNAME2=$(curl -fsS --connect-timeout 3 --max-time 5 "$IDX_URL2" 2>/dev/null |
            grep -oE "$PATTERN" | head -n1)

        [ -n "$FNAME2" ] && break
        sleep 1
    done

    VER2=$(printf '%s\n' "$FNAME2" |
        grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)*-r[0-9]+' |
        sed 's/-r[0-9]*$//')

    if [ -z "$VER2" ]; then
        echo -e "Zapret2: ${RED}ошибка получения версии${NC}"
        return 1
    fi

    echo "$VER2" > "$TMP_VER_Z2"
    echo -e "Zapret2: ${GREEN}$VER2${NC}"
}
get_ver() { URL="$1"; OUT_FILE="$2"; NAME="$3"; RESULT=$(curl -sIL --connect-timeout 3 --max-time 4 --retry 1 -w "%{url_effective}" -o /dev/null "$URL" 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$RESULT" ]; then echo -e "$NAME: ${RED}ошибка получения версии${NC}"; return 1; fi; VERSION="${RESULT##*/}"; VERSION="${VERSION#v}"; [ "$NAME" = "ByeDPI" ] && VERSION="${VERSION%%-*}"
if [ -z "$VERSION" ]; then echo -e "$NAME - ${RED}не удалось извлечь версию${NC}"; echo -e "${YELLOW}URL:${NC} $RESULT"; return 1; fi; echo "$VERSION" > "$OUT_FILE"; echo -e "$NAME: ${GREEN}$VERSION${NC}"; }

rm -f "$TMP_VER" "$TMP_VER_POD" "$TMP_VER_TG_MT" "$TMP_VER_TG_GO" "$TMP_VER_TG_RS" "$TMP_MAG_VER" "$TMP_VER_SPL" "$TMP_VER_BYEDPI" "$TMP_VER_Z2"

clear

echo -e "${CYAN}Cобираем версии:${NC}"
TMP_VER="/tmp/zapret_version"; TMP_VER_POD="/tmp/podkop_version"; TMP_VER_TG_MT="/tmp/tg_ws_proxy_MTp_ver"; TMP_VER_TG_GO="/tmp/tg_ws_proxy_GO_ver"
TMP_VER_TG_RS="/tmp/tg_ws_proxy_RS_ver"; TMP_MAG_VER="/tmp/MagiTrickle_version"; TMP_VER_SPL="/tmp/splify_version"; TMP_VER_BYEDPI="/tmp/byedpi_version"; TMP_VER_Z2="/tmp/zapret2_version"
# get_ver "https://github.com/MagiTrickle/MagiTrickle/releases/latest" "$TMP_MAG_VER" "MagiTrickle" &
# get_ver "https://github.com/spatiumstas/tg-ws-proxy-go/releases/latest" "$TMP_VER_TG_MT" "TG-WS Proxy MTProto" &
get_ver "https://github.com/DPITrickster/ByeDPI-OpenWrt/releases/latest" "$TMP_VER_BYEDPI" "ByeDPI" & get_ver "https://github.com/yandexru45/netshift/releases/latest" "$TMP_VER_POD" "NetShift" &
get_ver "https://github.com/remittor/zapret-openwrt/releases/latest" "$TMP_VER" "Zapret" & get_ver "https://github.com/xyzmean/splify/releases/latest" "$TMP_VER_SPL" "splify" &
get_ver "https://github.com/d0mhate/-tg-ws-proxy-Manager-go/releases/latest" "$TMP_VER_TG_GO" "TG-WS Proxy SOCKS5" & get_ver "https://github.com/valnesfjord/tg-ws-proxy-rs/releases/latest" "$TMP_VER_TG_RS" "TG-WS Proxy Rust" & get_zapret2_ver & wait
[ -s "$TMP_MAG_VER" ] && MT_VERSION="$(cat "$TMP_MAG_VER")"; [ -s "$TMP_VER_BYEDPI" ] && BYEDPI_LATEST_VER="$(cat "$TMP_VER_BYEDPI" | sed 's/^v//' | cut -d'-' -f1)"; [ -s "$TMP_VER_Z2" ] && ZAPRET2_VERSION="$(cat "$TMP_VER_Z2")"
[ -s "$TMP_VER" ] && ZAPRET_VERSION="$(cat "$TMP_VER")"; [ -s "$TMP_VER_POD" ] && PODKOP_LATEST_VER="$(cat "$TMP_VER_POD")"; [ -s "$TMP_VER_TG_MT" ] && TG_MTProto="$(cat "$TMP_VER_TG_MT")"
[ -s "$TMP_VER_SPL" ] && SPL_VER="$(cat "$TMP_VER_SPL")"; [ -s "$TMP_VER_TG_GO" ] && TG_GO_VERSION="$(cat "$TMP_VER_TG_GO")"; [ -s "$TMP_VER_TG_RS" ] && TG_RS_VERSION="$(cat "$TMP_VER_TG_RS")"

ADD_FAKE_FLOW() { MSG=0; for f in stun2.bin quic_initial_tencent_com.bin quic_initial_steamcommunity_com.bin tls_clienthello_sochi_park.bin quic_initial_4pda_to.bin quic_initial_5ka_ru.bin tls_clienthello_5ka_ru.bin quic_initial_rutube_ru.bin
do [ -d /opt/zapret ] && [ ! -f "/opt/zapret/files/fake/$f" ] && [ -f "$CONF" ] && { [ "$MSG" = 0 ] && { echo -e "${CYAN}Скачиваем ${NC}fake ${CYAN}файлы${NC}"; MSG=1; }; wget -q -U "Mozilla/5.0" -O "/opt/zapret/files/fake/$f" "${GH_MAIN}/Flowseal/zapret-discord-youtube/raw/refs/heads/main/bin/$f" || { echo -e "\n${RED}Не удалось загрузить файл ${NC}$f\n"; }; }; done; }

ADD_FAKE_FLOW

show_ts_warning() { grep -Fq "=ts" "$CONF" || return; [ -f "$TS_WARN_FLAG" ] && [ "$(cat "$TS_WARN_FLAG" 2>/dev/null)" = "1" ] && return
mkdir -p "$(dirname "$TS_WARN_FLAG")"; echo 1 > "$TS_WARN_FLAG"; echo -e "${YELLOW}Для работы этой стратегии нужно один раз в терминале Windows выполнить:${NC}\nnetsh int tcp set global timestamps=enabled\n"; }

# ==========================================
#ZAPRET2
# ==========================================
ZAPRET2_ARCH_SUFFIX="aarch64_cortex-a53"
if [ "$PKG_IS_APK" -eq 1 ]; then ZAPRET2_BASE_URL="https://packages.routerich.ru/25.12/mediatek/filogic/routerich/"; else ZAPRET2_BASE_URL="https://packages.routerich.ru/24.10/mediatek/filogic/routerich/"; fi; ZAPRET2_TMP_DIR="/tmp/routerich"; ZAPRET2_CACHE_FILE="$ZAPRET2_TMP_DIR/index.html"
zapret2_update_cache() { mkdir -p "$ZAPRET2_TMP_DIR"; curl -L -s --connect-timeout 10 "$ZAPRET2_BASE_URL" -o "$ZAPRET2_CACHE_FILE"; }
zapret2_remote_file() { [ -f "$ZAPRET2_CACHE_FILE" ] || zapret2_update_cache; if [ "$PKG_IS_APK" -eq 1 ]; then grep -o "zapret2-[0-9][^\"]*\.${RAZ}" "$ZAPRET2_CACHE_FILE" | head -n1; else grep -o "zapret2_[0-9][^\"]*_${ZAPRET2_ARCH_SUFFIX}\.${RAZ}" "$ZAPRET2_CACHE_FILE" | head -n1; fi; }
zapret2_remote_luci_file() { [ -f "$ZAPRET2_CACHE_FILE" ] || zapret2_update_cache; if [ "$PKG_IS_APK" -eq 1 ]; then grep -o "luci-app-zapret2-[0-9][^\"]*\.${RAZ}" "$ZAPRET2_CACHE_FILE" | head -n1; else grep -o "luci-app-zapret2_[0-9][^\"]*_all\.${RAZ}" "$ZAPRET2_CACHE_FILE" | head -n1; fi; }
zapret2_local_version() { if [ "$PKG_IS_APK" -eq 1 ]; then apk list --installed 2>/dev/null | grep "^zapret2" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)*-r[0-9]+' | head -n1 | sed 's/-r[0-9]*$//'; else opkg list-installed 2>/dev/null | grep "^zapret2 -" | awk '{print $3}' | sed 's/-r[0-9]*$//'; fi; }
zapret2_luci_installed() { if [ "$PKG_IS_APK" -eq 1 ]; then apk list --installed 2>/dev/null | grep -q "^luci-app-zapret2"; else opkg list-installed 2>/dev/null | grep -q "luci-app-zapret2"; fi; }
install_zapret2() { [ "$(grep '^DISTRIB_ARCH=' /etc/openwrt_release | cut -d"'" -f2)" = "aarch64_cortex-a53" ] || { echo -e "\n${RED}Архитектура не поддерживается!\n${YELLOW}Только для ${NC}aarch64_cortex-a53${YELLOW}!${NC}\n"; PAUSE; return 1; }
if [ -f /etc/init.d/zapret ] && ! is_expert_mode; then echo -e "\n${RED}Установлен ${NC}Zapret${RED}!${NC}"; echo -e "${YELLOW}Установка ${NC}Zapret2${YELLOW} невозможна!${NC}\n"; PAUSE; return 1; fi
echo -e "\n${MAGENTA}Устанавливаем Zapret2${NC}"; rm -rf "$ZAPRET2_TMP_DIR"; mkdir -p "$ZAPRET2_TMP_DIR"; zapret2_update_cache; MAIN_FILE2="$(zapret2_remote_file)"; LUCI_FILE2="$(zapret2_remote_luci_file)"
if [ -z "$MAIN_FILE2" ]; then echo -e "\n${RED}Не удалось найти пакет ${NC}zapret2\n"; PAUSE; return 1; fi; update_packages || return 1
echo -e "${CYAN}Скачиваем ${NC}$MAIN_FILE2"; curl -L -s --connect-timeout 10 "${ZAPRET2_BASE_URL}${MAIN_FILE2}" -o "$ZAPRET2_TMP_DIR/$MAIN_FILE2" || { echo -e "\n${RED}Не удалось скачать ${NC}$MAIN_FILE2\n"; PAUSE; return 1; }
if [ -n "$LUCI_FILE2" ]; then echo -e "${CYAN}Скачиваем ${NC}$LUCI_FILE2"; curl -L -s --connect-timeout 10 "${ZAPRET2_BASE_URL}${LUCI_FILE2}" -o "$ZAPRET2_TMP_DIR/$LUCI_FILE2"; fi
echo -e "${CYAN}Устанавливаем ${NC}Zapret2"; $INSTALL "$ZAPRET2_TMP_DIR"/*.${RAZ} >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить ${NC}Zapret2\n"; rm -rf "$ZAPRET2_TMP_DIR"; PAUSE; return 1; }
rm -rf "$ZAPRET2_TMP_DIR"; echo -e "${CYAN}Добавляем домены в исключения${NC}"; wget -q -U "Mozilla/5.0" -O /opt/zapret2/ipset/zapret_hosts_user_exclude.txt "$EXCLUDE_URL" || echo -e "${RED}Не удалось загрузить exclude файл${NC}"
echo -e "${CYAN}Включаем стратегию по умолчанию${NC}"; sed -i "/config strategy 'default'/,/config /s/option enabled '0'/option enabled '1'/" /etc/config/zapret2 >/dev/null 2>&1
echo -e "${CYAN}Запускаем ${NC}Zapret2"; /etc/init.d/zapret2 enable >/dev/null 2>&1; /etc/init.d/zapret2 restart >/dev/null 2>&1; echo -e "Zapret2 ${GREEN}установлен!${NC}\n"; PAUSE; }
remove_zapret2() { echo -e "\n${MAGENTA}Удаляем Zapret2${NC}"; echo -e "${CYAN}Останавливаем ${NC}zapret2"; /etc/init.d/zapret2 stop >/dev/null 2>&1
echo -e "${CYAN}Удаляем пакеты${NC}"; $DELETE luci-app-zapret2 >/dev/null 2>&1; $DELETE zapret2 >/dev/null 2>&1; echo -e "${CYAN}Удаляем файлы${NC}"; rm -f /etc/config/zapret2; rm -rf /opt/zapret2; echo -e "Zapret2 ${GREEN}удалён!${NC}\n"; PAUSE; }
# ==========================================
# Автоподбор
# ==========================================
AUTO_MODE_FILE="$TMP_SF/auto_best_mode"
get_auto_best_mode() { if [ -f "$AUTO_MODE_FILE" ]; then MODE_VAL=$(cat "$AUTO_MODE_FILE" 2>/dev/null); fi; case "$MODE_VAL" in 1|2|3) echo "$MODE_VAL" ;; *) echo 3 ;; esac; }
auto_best_mode_text() { case "$(get_auto_best_mode)" in 1) echo "v" ;; 2) echo "Flowseal" ;; *) echo "v + Flowseal" ;; esac; }
set_auto_best_mode() { echo -e "\n${MAGENTA}Выберите стратегии для автоподбора${NC}"; echo -e "${CYAN}1) ${GREEN}Стратегии ${NC}v\n${CYAN}2) ${GREEN}Стратегии ${NC}Flowseal\n${CYAN}3) ${GREEN}Стратегии ${NC}v ${GREEN}+ ${NC}Flowseal"
echo -ne "${CYAN}Enter) ${GREEN}Оставить текущую${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r choiceMode; case "$choiceMode" in 1|2|3) mkdir -p "$TMP_SF"; echo "$choiceMode" > "$AUTO_MODE_FILE"; echo -e "\n${GREEN}Выбраны стратегии: ${NC}$(auto_best_mode_text)\n"; PAUSE;; *) return ;; esac; }
sync_ntp() { echo -e "\n${MAGENTA}Синхронизируем время через NTP${NC}"; if command -v ntpd >/dev/null 2>&1; then ntpd -n -q -p 0.openwrt.pool.ntp.org -p 1.openwrt.pool.ntp.org >/dev/null 2>&1
else /etc/init.d/sysntpd restart >/dev/null 2>&1; sleep 3; fi; command -v hwclock >/dev/null 2>&1 && hwclock -w >/dev/null 2>&1; echo -e "${GREEN}Время синхронизировано!${NC}\n"; PAUSE; }
set_timezone() { CUR_TZ=$(uci -q get system.@system[0].zonename); echo -e "\n${MAGENTA}Выберите часовой пояс${NC}\n ${CYAN}1) ${GREEN}Калининград  ${NC}(UTC+2)\n ${CYAN}2) ${GREEN}Москва       ${NC}(UTC+3)"
echo -e " ${CYAN}3) ${GREEN}Самара       ${NC}(UTC+4)\n ${CYAN}4) ${GREEN}Екатеринбург ${NC}(UTC+5)\n ${CYAN}5) ${GREEN}Омск         ${NC}(UTC+6)\n ${CYAN}6) ${GREEN}Красноярск   ${NC}(UTC+7)\n ${CYAN}7) ${GREEN}Иркутск      ${NC}(UTC+8)"
echo -e " ${CYAN}8) ${GREEN}Якутск       ${NC}(UTC+9)\n ${CYAN}9) ${GREEN}Владивосток  ${NC}(UTC+10)\n${CYAN}10) ${GREEN}Магадан      ${NC}(UTC+11)\n${CYAN}11) ${GREEN}Камчатка     ${NC}(UTC+12)\n${CYAN}12) ${GREEN}UTC${NC}"
echo -ne "${CYAN}Enter) ${GREEN}Отмена${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r choiceTZ; case "$choiceTZ" in 1) TZSTR="MSK-1"; ZONE="Europe/Kaliningrad" ;; 2) TZSTR="MSK-3"; ZONE="Europe/Moscow" ;;
3) TZSTR="MSK-4"; ZONE="Europe/Samara" ;; 4) TZSTR="MSK-5"; ZONE="Asia/Yekaterinburg" ;; 5) TZSTR="MSK-6"; ZONE="Asia/Omsk" ;; 6) TZSTR="MSK-7"; ZONE="Asia/Krasnoyarsk" ;; 7) TZSTR="MSK-8"; ZONE="Asia/Irkutsk" ;;
8) TZSTR="MSK-9"; ZONE="Asia/Yakutsk" ;; 9) TZSTR="MSK-10"; ZONE="Asia/Vladivostok" ;; 10) TZSTR="MSK-11"; ZONE="Asia/Magadan" ;; 11) TZSTR="MSK-12"; ZONE="Asia/Kamchatka" ;; 12) TZSTR="UTC"; ZONE="UTC" ;; *) return ;; esac
uci set system.@system[0].timezone="$TZSTR"; uci set system.@system[0].zonename="$ZONE"; uci commit system; /etc/init.d/system reload >/dev/null 2>&1; echo -e "\n${GREEN}Часовой пояс установлен:${NC} $ZONE\n"; PAUSE; }
TIME_MENU() { while true; do clear; echo -e "${MAGENTA}Меню настройки времени${NC}\n"; echo -e "${YELLOW}Текущее время:${NC} ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"; TZ_CUR=$(uci -q get system.@system[0].zonename)
[ -n "$TZ_CUR" ] && echo -e "${YELLOW}Часовой пояс:${NC} ${CYAN}$TZ_CUR${NC}"; echo -e "\n${CYAN}1) ${GREEN}Синхронизировать время через ${NC}NTP\n${CYAN}2) ${GREEN}Установить часовой пояс${NC}"
echo -ne "${CYAN}Enter) ${GREEN}Выход в меню автоподбора стратегий${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r choiceTM; case "$choiceTM" in 1) sync_ntp ;; 2) set_timezone ;; *) return ;; esac; done; }
auto_best_running() { [ -f "$AUTO_LOCK" ] || return 1; _lock_pid=$(head -n1 "$AUTO_LOCK" 2>/dev/null); if [ -n "$_lock_pid" ] && kill -0 "$_lock_pid" 2>/dev/null; then return 0; fi; rm -f "$AUTO_LOCK"; return 1; }
sort_results_desc() { local in="$1" out="$2" tmp="$TMP_SF/sort_res.$$"; awk -F'[/ ]' '{ for (i = 1; i <= NF; i++) { if ($i ~ /^[0-9]+$/) { print $i, $0; break } } }' "$in" | sort -k1,1 -nr | cut -d' ' -f2- > "$tmp"; mv "$tmp" "$out"; }
auto_best_stop_cleanup() { { echo ""; echo "=== $(date '+%Y-%m-%d %H:%M:%S') Автоподбор остановлен пользователем ==="; if [ -f "$AUTO_BACK" ]; then echo "Восстанавливаем предыдущую конфигурацию"
mv -f "$AUTO_BACK" "$CONF"; ZAPRET_RESTART; echo "Конфигурация восстановлена"; else echo "Файл резервной конфигурации не найден, восстановление невозможно"; fi; } >> "$AUTO_LOG" 2>&1; }
stop_auto_best() { touch "$AUTO_STOP_FLAG"; echo -en "${CYAN}Завершаем текущий автоподбор${NC}"; _i=0; while auto_best_running && [ "$_i" -lt 90 ]; do sleep 1; _i=$((_i + 1)); [ $((_i % 5)) -eq 0 ]; done
echo; if auto_best_running; then PID=$(head -n1 "$AUTO_LOCK" 2>/dev/null); [ -n "$PID" ] && kill -KILL "$PID" 2>/dev/null; rm -f "$AUTO_LOCK"; if [ -f "$AUTO_BACK" ]; then mv -f "$AUTO_BACK" "$CONF"; ZAPRET_RESTART; fi; fi; rm -f "$AUTO_STOP_FLAG"; }
restore_dv_number() { local NUM="$1"; [ -z "$NUM" ] && return; discord_str_add; [ "$NUM" = "1" ] && return; local NEW_STRAT; NEW_STRAT=$(eval echo \"\$Dv$NUM\"); [ -z "$NEW_STRAT" ] && return; grep -q -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" || return
local START END LINE; START=$(grep -n -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" | cut -d: -f1); END=$(tail -n +"$START" "$CONF" | grep -n -m1 -E '^--new$|^#|^'\''$' | cut -d: -f1); END=$((START + END - 1))
sed -i "${START},$((END-1))d" "$CONF"; LINE=$START; echo "$NEW_STRAT" | while IFS= read -r l; do sed -i "${LINE}i$l" "$CONF"; LINE=$((LINE + 1)); done; if grep -q -E '^#[[:space:]]*Dv' "$CONF"; then sed -i "s/^#[[:space:]]*Dv[0-9]\+/#Dv$NUM/" "$CONF"; else sed -i "${START}i#Dv$NUM" "$CONF"; fi; }
restore_yv_number() { local NUM="$1"; if [ -z "$NUM" ] || [ "$NUM" = "08" ]; then ADD_Yv; return; fi; local SELECTED_NAME="#Yv$NUM"; curl -fsSL "$STR_URL" -o "$TMP_LIST" || { ADD_Yv; return; }; grep -qxF "$SELECTED_NAME" "$TMP_LIST" || { ADD_Yv; return; }
local SAVED="$TMP_SF/restore_yv_str" NEW_TMP="$TMP_SF/restore_yv_new" FINAL_TMP="$TMP_SF/restore_yv_final" FLAG=0; : > "$SAVED"; while IFS= read -r LINE; do [ "$LINE" = "$SELECTED_NAME" ] && FLAG=1 && continue
case "$LINE" in \#Yv[0-9]*) FLAG=0 ;; esac; [ "$FLAG" -eq 1 ] && printf "%b\n" "$LINE" >> "$SAVED"; done < "$TMP_LIST"; sed -i "/^[[:space:]]*#Yv[0-9]\+/d" "$CONF"
awk '{if(skip){if($0=="--new"||$0~/\047/){skip=0;next}if($0~/^[[:space:]]*$/)next;next}if($0=="--filter-tcp=443"){getline n;if(n=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"){skip=1;next}else{print $0;print n;next}}if($0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt")has_google=1;print}' "$CONF" > "$NEW_TMP"
awk -v sel="$SELECTED_NAME" -v savedfile="$SAVED" 'BEGIN{inserted=0;has_google=0} $0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"{has_google=1} $0~/^[[:space:]]*option NFQWS_OPT '\''$/&&!has_google&&!inserted{print;print sel;while((getline l<savedfile)>0)if(l!~/^[[:space:]]*$/)print l;print "--new";inserted=1;next} {print}' "$NEW_TMP" > "$FINAL_TMP"
grep -q "^[[:space:]]*'[[:space:]]*\$" "$FINAL_TMP" || echo "'" >> "$FINAL_TMP"; mv "$FINAL_TMP" "$CONF"; }
auto_apply_best_strategy() { echo $$ > "$AUTO_LOCK"; rm -f "$AUTO_STOP_FLAG"; trap 'rm -f "$AUTO_LOCK"' EXIT; mkdir -p "$TMP_SF" "/opt/zapret/tmp"; : > "$AUTO_LOG"; { echo "===> Автоподбор стратегии запущен <==="; if [ ! -f /etc/init.d/zapret ]; then echo "Zapret не установлен, выход"; exit 0; fi
STR_FILE_AUTO="$TMP_SF/str_auto.txt"; TEMP_FILE_AUTO="$TMP_SF/str_temp_auto.txt"; : > "$STR_FILE_AUTO"; cp "$CONF" "$AUTO_BACK"; ORIG_YV_NUM=$(grep -o '^#Yv[0-9]\+' "$AUTO_BACK" | head -n1 | sed 's/#Yv//')
ORIG_DV_NUM=$(grep -o '^#Dv[0-9]\+' "$AUTO_BACK" | head -n1 | sed 's/#Dv//'); ORIG_GV_NUM=$(grep -o '^#Gv[0-9]\+$' "$AUTO_BACK" | head -n1 | sed 's/#Gv//'); MODE_SEL=$(get_auto_best_mode); case "$MODE_SEL" in
1) echo "Тестируем стратегии: v" ;; 2) echo "Тестируем стратегии: Flowseal" ;; *) echo "Тестируем стратегии: v + Flowseal" ;; esac; if [ "$MODE_SEL" != "1" ]; then echo "Собираем Flowseal стратегии"; download_strategies 1; cat "$OUT" >> "$STR_FILE_AUTO"; fi
if [ "$MODE_SEL" != "2" ]; then echo "Собираем v стратегии"; for N in $(seq 1 100); do strategy_v"$N" >> "$STR_FILE_AUTO" 2>/dev/null || break; done; fi; sed -i '/#Y/d' "$STR_FILE_AUTO"
if [ ! -s "$STR_FILE_AUTO" ]; then echo "Не удалось собрать ни одной стратегии для теста (проверьте выбранный режим)"; mv -f "$AUTO_BACK" "$CONF"; exit 1; fi; prepare_urls || { echo "Не удалось получить список для теста"; mv -f "$AUTO_BACK" "$CONF"; exit 1; }
URLS="$(cat "$OUT_DPI")"; TOTAL=$(grep -c "|" "$OUT_DPI"); TOTAL_STR=$(grep -c '^#' "$STR_FILE_AUTO"); echo "Найдено стратегий: $TOTAL_STR"; echo "Доменов для теста: $TOTAL"; RESULTS="$AUTO_RESULTS"; MODE="normal"; : > "$AUTO_RESULTS"; check_zpr_off
if [ -f "$AUTO_STOP_FLAG" ]; then echo "Автоподбор остановлен пользователем"; rm -f "$AUTO_STOP_FLAG"; mv -f "$AUTO_BACK" "$CONF"; ZAPRET_RESTART; echo "Конфигурация восстановлена"; rm -f "$OUT_DPI"; exit 0; fi
LINES=$(grep -n '^#' "$STR_FILE_AUTO" | cut -d: -f1); CUR=0; echo "$LINES" | while read -r START; do CUR=$((CUR + 1)); if [ -f "$AUTO_STOP_FLAG" ]; then echo "===> Получен сигнал остановки, прерываем тестирование"; break; fi
NEXT=$(echo "$LINES" | awk -v s="$START" '$1>s{print;exit}'); if [ -z "$NEXT" ]; then sed -n "${START},\$p" "$STR_FILE_AUTO" > "$TEMP_FILE_AUTO"; else sed -n "${START},$((NEXT-1))p" "$STR_FILE_AUTO" > "$TEMP_FILE_AUTO"; fi; BLOCK=$(cat "$TEMP_FILE_AUTO"); NAME=$(head -n1 "$TEMP_FILE_AUTO"); NAME="${NAME#\#}"
awk -v block="$BLOCK" 'BEGIN{skip=0} /option NFQWS_OPT '\''/ {printf "\toption NFQWS_OPT '\''\n%s\n'\''\n", block; skip=1; next} skip && /^'\''$/ {skip=0; next} !skip {print}' "$CONF" > "${CONF}.tmp" && mv "${CONF}.tmp" "$CONF"
ZAPRET_RESTART; OK=0; LOG_TMP="/tmp/zapret_log_auto_${CUR}"; : > "$LOG_TMP"; check_all_urls; echo "${NAME} → ${OK}/${TOTAL}" >> "$AUTO_RESULTS"; echo "===> Стратегия: ${NAME} = ${OK}/${TOTAL}"; done
if [ -f "$AUTO_STOP_FLAG" ]; then echo "Автоподбор остановлен пользователем во время тестирования"; rm -f "$AUTO_STOP_FLAG"; mv -f "$AUTO_BACK" "$CONF"; ZAPRET_RESTART; echo "Конфигурация восстановлена"; rm -f "$OUT_DPI"; exit 0; fi
sort_results_desc "$AUTO_RESULTS" "$AUTO_RESULTS"; echo ""; echo "Результат тестирования стратегии"; echo ""; cat "$AUTO_RESULTS"; echo ""; BEST_LINE=$(grep -v '^Контрольный тест' "$AUTO_RESULTS" | head -n1)
if [ -z "$BEST_LINE" ]; then echo "Не удалось определить лучшую стратегию, восстанавливаем прежнюю"; mv -f "$AUTO_BACK" "$CONF"; ZAPRET_RESTART; rm -f "$OUT_DPI"; exit 1; fi
BEST_NAME=$(echo "$BEST_LINE" | cut -d'→' -f1 | sed 's/[[:space:]]*$//'); echo "Лучшая стратегия: $BEST_LINE"; mv -f "$AUTO_BACK" "$CONF"; START=$(grep -nxF "#${BEST_NAME}" "$STR_FILE_AUTO" | head -n1 | cut -d: -f1)
if [ -n "$START" ]; then NEXT=$(echo "$LINES" | awk -v s="$START" '$1>s{print;exit}'); if [ -z "$NEXT" ]; then sed -n "${START},\$p" "$STR_FILE_AUTO" > "$TEMP_FILE_AUTO"; else sed -n "${START},$((NEXT-1))p" "$STR_FILE_AUTO" > "$TEMP_FILE_AUTO"; fi
BLOCK=$(cat "$TEMP_FILE_AUTO"); sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; { echo "  option NFQWS_OPT '"; echo "$BLOCK"; echo "'"; } >> "$CONF"
if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'\$/,19294-19344,50000-50100'/" "$CONF"; fi; if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"
then sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'\$/,2053,2083,2087,2096,8443'/" "$CONF"; fi; IS_GENERAL=0; grep -q '^#general' "$CONF" && IS_GENERAL=1; [ -n "$ORIG_YV_NUM" ] && restore_yv_number "$ORIG_YV_NUM"
[ -n "$ORIG_DV_NUM" ] && restore_dv_number "$ORIG_DV_NUM"; case "$ORIG_GV_NUM" in 1|2|3|4) NEED_GV=1 ;; *) NEED_GV=0 ;; esac; [ "$IS_GENERAL" = "1" ] && sed -i '/--new/{N;/--filter-tcp=2802/{s/--new/#Gv0\n--new/;};}' "$CONF"
[ "$NEED_GV" = "1" ] && fix_GAME "$ORIG_GV_NUM"; ZAPRET_RESTART; echo "Стратегия '$BEST_NAME' применена и сохранена"; [ -n "$ORIG_YV_NUM" ] && echo "Стратегия для YouTube восстановлена: Yv$ORIG_YV_NUM"
[ -n "$ORIG_DV_NUM" ] && echo "Стратегия для discord.media восстановлена: Dv$ORIG_DV_NUM"; [ "$NEED_GV" = "1" ] && echo "Игровая стратегия восстановлена: Gv$ORIG_GV_NUM"; else echo "Не удалось повторно найти блок стратегии '$BEST_NAME', конфиг восстановлен без применения"; fi; rm -f "$OUT_DPI"; } >> "$AUTO_LOG" 2>&1; }
auto_best_cron_line() { grep -F "$AUTO_CRON_CMD" "$CRON_FILE" 2>/dev/null | head -n1; }; LINECR=$(auto_best_cron_line); HOURC=$(echo "$LINECR" | awk '{print $2}')
set_auto_best_time() { CUR_YEAR=$(date '+%Y'); if [ "$CUR_YEAR" -lt 2020 ]; then echo -e "\n${RED}Внимание! Время на роутере выглядит неверным:${NC}$(date '+%Y-%m-%d %H:%M:%S')${RED}!${NC}"; echo -e "${YELLOW}Расписание будет работать некорректно!${NC}"
echo -e "${YELLOW}Сначала настройте время!${NC}\n"; PAUSE; return; fi; echo -ne "\n${YELLOW}Введите час автозапуска (${NC}0-23${YELLOW}):${NC} "; read -r HOUR; case "$HOUR" in ''|*[!0-9]*) echo -e "\n${RED}Введите число от ${NC}0${RED} до ${NC}23\n"; PAUSE; return ;; esac
{ [ "$HOUR" -ge 0 ] && [ "$HOUR" -le 23 ]; } || { echo -e "\n${RED}Ошибка! Диапазон ${NC}0-23\n"; PAUSE; return; }; mkdir -p "$(dirname "$CRON_FILE")"; touch "$CRON_FILE"; sed -i "\|$AUTO_CRON_CMD|d" "$CRON_FILE"
echo "0 $HOUR * * * $AUTO_CRON_CMD >/dev/null 2>&1" >> "$CRON_FILE"; /etc/init.d/cron restart >/dev/null 2>&1; echo -e "\n${GREEN}Автоподбор запланирован ежедневно в ${NC}$(printf "%02d" "$HOUR"):00${GREEN}!${NC}\n"; PAUSE; }
disable_auto_best() { sed -i "\|$AUTO_CRON_CMD|d" "$CRON_FILE"; /etc/init.d/cron restart >/dev/null 2>&1; echo -e "\n${GREEN}Автоподбор отключен!${NC}\n"; PAUSE; }
run_auto_best_background() { echo -e "\n${MAGENTA}Запускаем автоподбор в фоне${NC}"; rm -f "$AUTO_LOCK"; $AUTO_CRON_CMD >/dev/null 2>&1 & echo -en "${CYAN}Запускаем фоновое выполнение${NC}"; _i=0; while [ ! -f "$AUTO_LOCK" ] && [ "$_i" -lt 20 ]; do sleep 1; _i=$((_i + 1)); done; echo; if auto_best_running; then echo -e "${GREEN}Автоподбор в фоне запущен!${NC}\n"; else echo -e "${YELLOW}Процесс запускается медленнее обычного, статус обновится при следующем открытии меню${NC}\n"; fi; PAUSE; }
AUTO_BEST_MENU() { [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }
while true; do clear; echo -e "${MAGENTA}Меню автоподбора стратегий по расписанию${NC}\n"; echo -e "${YELLOW}Текущее время на роутере:${NC} ${CYAN}$(date '+%H:%M:%S')${NC}"; if auto_best_running; then RUNNING=1; echo -e "${YELLOW}Автоподбор в фоне:${NC} ${GREEN}выполняется${NC}"; else RUNNING=0; fi
LINE=$(auto_best_cron_line); if [ -n "$LINE" ]; then HOUR=$(echo "$LINE" | awk '{print $2}'); echo -e "${YELLOW}Автоподбор стратегий:${NC} ${GREEN}ежедневно в ${NC}$(printf "%02d" "$HOUR"):00${NC}"
else echo -e "${YELLOW}Автоподбор стратегий:${NC} ${RED}отключен${NC}"; fi; echo -e "${YELLOW}Тестируемые стратегии:${NC} $(auto_best_mode_text)"; echo ""; N=1
echo -e "${CYAN}${N}) ${GREEN}$( [ -n "$LINE" ] && echo "Изменить время автоподбора по расписанию" || echo "Включить автоподбор по расписанию" )${NC}"; OPT_TIME=$N; N=$((N+1))
if [ -n "$LINE" ]; then echo -e "${CYAN}${N}) ${GREEN}Отключить автоподбор по расписанию${NC}"; OPT_DISABLE=$N; N=$((N+1)); else OPT_DISABLE=""; fi
if [ "$RUNNING" = "1" ]; then echo -e "${CYAN}${N}) ${GREEN}Остановить автоподбор в фоне${NC}"; else echo -e "${CYAN}${N}) ${GREEN}Запустить автоподбор в фоне${NC}"; fi; OPT_RUN=$N; N=$((N+1))
if [ -s "$AUTO_RESULTS" ]; then echo -e "${CYAN}${N}) ${GREEN}Показать результаты последнего теста${NC}"; OPT_RESULTS=$N; N=$((N+1)); else OPT_RESULTS=""; fi
if [ -f "$AUTO_LOG" ]; then echo -e "${CYAN}${N}) ${GREEN}Показать полный лог последнего теста${NC}"; OPT_LOG=$N; N=$((N+1)); else OPT_LOG=""; fi
echo -e "${CYAN}${N}) ${GREEN}Настроить время на роутере${NC}"; OPT_TZ=$N; N=$((N+1)); echo -e "${CYAN}${N}) ${GREEN}Выбрать стратегии для автоподбора${NC}"; OPT_MODE=$N; N=$((N+1))
if [ -s "$AUTO_RESULTS" ] || [ -f "$AUTO_LOG" ]; then echo -e "${CYAN}${N}) ${GREEN}Удалить результаты теста и лог${NC}"; OPT_CLEAR=$N; N=$((N+1)); else OPT_CLEAR=""; fi
echo -ne "${CYAN}Enter) ${GREEN}Выход в меню тестирования стратегий${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r choiceAB; if [ "$choiceAB" = "$OPT_TIME" ]; then set_auto_best_time
elif [ -n "$OPT_DISABLE" ] && [ "$choiceAB" = "$OPT_DISABLE" ]; then disable_auto_best; elif [ "$choiceAB" = "$OPT_RUN" ]; then if [ "$RUNNING" = "1" ]; then echo -e "\n${MAGENTA}Останавливаем автоподбор${NC}"; stop_auto_best; echo -e "${GREEN}Автоподбор в фоне остановлен!${NC}\n"; PAUSE
else run_auto_best_background; fi; elif [ -n "$OPT_RESULTS" ] && [ "$choiceAB" = "$OPT_RESULTS" ]; then show_single_result "$AUTO_RESULTS"; elif [ -n "$OPT_LOG" ] && [ "$choiceAB" = "$OPT_LOG" ]; then
clear; cat "$AUTO_LOG"; echo; PAUSE; elif [ "$choiceAB" = "$OPT_TZ" ]; then TIME_MENU; elif [ "$choiceAB" = "$OPT_MODE" ]; then set_auto_best_mode; elif [ -n "$OPT_CLEAR" ] && [ "$choiceAB" = "$OPT_CLEAR" ]; then
echo -e "\n${GREEN}Результаты теста и лог удалены!${NC}\n"; rm -rf "$AUTO_RESULTS" "$AUTO_BACK" "$AUTO_LOG" "$AUTO_LOCK"; PAUSE; else return; fi; done; }
# ==========================================
# splify
# ==========================================
# ──────────────────────────── 1. environment checks ────────────────────────
ZAVISIM() { local NEED=""; command -v jq >/dev/null 2>&1 || NEED="$NEED jq"; command -v wg >/dev/null 2>&1 || NEED="$NEED wireguard-tools"; [ -z "$NEED" ] && return 0; echo -e "\n${MAGENTA}Ставим зависимости для генерации${NC}"; update_packages || return 1; echo -e "${CYAN}Ставим зависимости${NC}"; $INSTALL $NEED >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установке!${NC}\n"; PAUSE; return 1; }; }
# ──────────────────────────── 2. install splify packages ───────────────────
install_splify() { SPL_SPL="${GH_MAIN}/xyzmean/splify/releases/download/v$SPL_VER/splify-$SPL_VER-1_$SPL_SUF.$RAZ"; SPL_LUCI="${GH_MAIN}/xyzmean/splify/releases/download/v$SPL_VER/luci-app-splify-$SPL_VER-1_$SPL_SUF.$RAZ"
SPL_RUS="${GH_MAIN}/xyzmean/splify/releases/download/v$SPL_VER/luci-i18n-splify-ru-$SPL_VER-1_$SPL_SUF.$RAZ"; echo -e "${CYAN}Скачиваем ${NC}splify"; wget -q -U "Mozilla/5.0" -O "$TMP_SF/splify.$RAZ" "$SPL_SPL" || { echo -e "\n${RED}Не удалось скачать:\n${NC}$SPL_SPL\n"; PAUSE; return 1; }
wget -q -U "Mozilla/5.0" -O "$TMP_SF/luci-app-splify.$RAZ" "$SPL_LUCI" || { echo -e "\n${RED}Не удалось скачать:\n${NC}$SPL_LUCI\n"; PAUSE; return 1; }; wget -q -U "Mozilla/5.0" -O "$TMP_SF/luci-i18n-splify-ru.$RAZ" "$SPL_RUS" || { echo -e "\n${RED}Не удалось скачать:\n${NC}$SPL_RUS\n"; PAUSE; return 1; }
update_packages || return 1; echo -e "${CYAN}Устанавливаем ${NC}splify"; $INSTALL "$TMP_SF/splify.$RAZ" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить:\n${NC}$SPL_SPL\n"; PAUSE; return 1; }
$INSTALL "$TMP_SF/luci-app-splify.$RAZ" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить:\n${NC}$SPL_LUCI\n"; PAUSE; return 1; }; $INSTALL "$TMP_SF/luci-i18n-splify-ru.$RAZ" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить:\n${NC}$SPL_RUS\n"; PAUSE; return 1; }
rm -f /tmp/luci-indexcache* /tmp/luci-modulecache* 2>/dev/null; /etc/init.d/rpcd reload 2>/dev/null || /etc/init.d/rpcd restart 2>/dev/null; sleep 5; }
# ──────────────────────────── 4. register Cloudflare WARP ───────────────────
colo_name() { case "$1" in AMS) echo "Amsterdam" ;; ARN) echo "Stockholm" ;; ATH) echo "Athens" ;; BUD) echo "Budapest" ;; FRA) echo "Frankfurt" ;; HEL) echo "Helsinki" ;; IST) echo "Istanbul" ;; KBP) echo "Kiev" ;; KIV) echo "Chisinau" ;; PRG) echo "Prague" ;; RIX) echo "Riga" ;; SOF) echo "Sofia" ;; TLL) echo "Tallinn" ;; VIE) echo "Vienna" ;; VNO) echo "Vilnius" ;; WAW) echo "Warsaw" ;; ZRH) echo "Zurich" ;; *) echo "$1" ;; esac; }
find_best_endpoint() { echo -e "\n${CYAN}Подбираем лучший ${NC}endpoint"; echo -en "${YELLOW}Подождите...${NC}"; _prefixes="188.114.96. 188.114.97. 188.114.98. 188.114.99. 162.159.192. 162.159.193. 162.159.195. 8.34.146. 8.39.214. 8.39.204. 8.6.112. 8.35.211. 8.39.125. 8.47.69."
_candidates=$(awk -v prefixes="$_prefixes" 'BEGIN { srand(); n = split(prefixes, arr, " "); for (i=0; i<100; i++) { idx = int(rand() * n) + 1; last = int(rand() * 256); print arr[idx] last; } }'); _pings="$TMP_SPL/warp_pings"; _count=0
for ip in $_candidates; do ( if trace_data=$(curl -s --connect-timeout 2 -w "\n%{time_total}" -H "Host: trace.cloudflare.com" "http://${ip}/cdn-cgi/trace"); then colo=$(echo "$trace_data" | awk -F'=' '$1=="colo"{print $2}'); case "$colo" in DME) exit 0 ;; "") exit 0 ;; esac
ping_ms=$(echo "$trace_data" | tail -n 1 | awk '{printf "%d", $1 * 1000}'); [ -n "$ping_ms" ] && echo "$ping_ms $ip $colo" >> "$_pings"; fi ) & _count=$((_count + 1)); [ $((_count % 20)) -eq 0 ] && wait; done; wait; if [ -s "$_pings" ]
then _best=$(sort -n "$_pings" | head -n 1); _best_ping=$(echo "$_best" | awk '{print $1}'); _best_ip=$(echo "$_best" | awk '{print $2}'); _best_colo=$(echo "$_best" | awk '{print $3}'); echo -e "\n\n${CYAN}Используем:${NC} $_best_ip ($(colo_name "$_best_colo"), ping: ${_best_ping}ms)"
WARP_EP="${_best_ip}:4500"; else WARP_EP="engage.cloudflareclient.com:4500"; echo -e "\n${CYAN}Подбор не удался!\nИспользуем ${NC}endpoint${CYAN}:${NC} $WARP_EP"; fi; }
choose_endpoint() { echo -e "\n${MAGENTA}Меню выбора endpoint${NC}"; echo -e "${CYAN}1) ${GREEN}Использовать${NC} engage.cloudflareclient.com:4500\n${CYAN}2) ${GREEN}Подобрать ${NC}endpoint${GREEN} автоматически${NC}\n"
echo -en "${YELLOW}Выберите пункт: ${NC}"; read -r choiceWRP; case "$choiceWRP" in 2) find_best_endpoint ;; *) WARP_EP="engage.cloudflareclient.com:4500"; echo -e "\n${CYAN}Используем: ${NC}$WARP_EP" ;; esac; }
register_request() { curl -fsSL --max-time 30 -X POST "${W1%/}/api/reg" -H "Content-Type: application/json" -H "Accept: application/json" -d "{\"key\":\"$PUB\",\"install_id\":\"\",\"fcm_token\":\"\",\"model\":\"PC\",\"locale\":\"en_US\",\"tos\":\"$TOS\",\"type\":\"Android\"}" -o "$REG" >/dev/null 2>&1; }
register_warp() { [ -d "$TMP_SPL" ] || mkdir -p "$TMP_SPL"; REG="$TMP_SPL/reg.json"; rm -f "$REG"; echo -e "\n${MAGENTA}Генерируем WARP${NC}"; echo -e "${CYAN}Используем основной метод${NC}"; if curl -fsSL --max-time 30 "$II" -o "$REG" 2>/dev/null && grep -q '"public_key"' "$REG"; then
PRIV=$(grep -o '"key"[[:space:]]*:[[:space:]]*"[^"]*"' "$REG" | head -n1 | sed 's/.*:[[:space:]]*"//;s/"$//'); WARP_PEER=$(grep -o '"public_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$REG" | head -n1 | sed 's/.*:[[:space:]]*"//;s/"$//')
WARP_V4=$(grep -o '"v4"[[:space:]]*:[[:space:]]*"[^"]*"' "$REG" | sed -n '2p' | sed 's/.*:[[:space:]]*"//;s/"$//'); WARP_V6=$(grep -o '"v6"[[:space:]]*:[[:space:]]*"[^"]*"' "$REG" | sed -n '2p' | sed 's/.*:[[:space:]]*"//;s/"$//')
if [ -n "$PRIV" ] && [ -n "$WARP_PEER" ] && [ -n "$WARP_V4" ]; then echo -e "WARP ${GREEN}сгенерирован!${NC}"; return 0; fi; echo -e "${YELLOW}Основной метод вернул неполные данные, переключаемся на запасной${NC}"; else echo -e "${YELLOW}Основной метод недоступен, переключаемся на запасной${NC}"; fi
ZAVISIM || return 1; if command -v awg >/dev/null 2>&1; then GEN=awg; else GEN=wg; fi; PRIV="$("$GEN" genkey 2>/dev/null)"; PUB="$(printf '%s\n' "$PRIV" | "$GEN" pubkey 2>/dev/null)"
TOS="$(date -u +%Y-%m-%dT%H:%M:%S.000000000Z)"; echo -e "${CYAN}Регистрируем устройство${NC}"; if register_request && jq -e '.config.peers[0].public_key' "$REG" >/dev/null 2>&1; then echo -e "${CYAN}Используем основной сервер${NC}"; else echo -e "${CYAN}Используем резервный сервер${NC}"
if ! curl -fsSL --max-time 60 "$II" -o "$REG" >/dev/null 2>&1; then echo -e "${RED}Не удалось получить WARP${NC}"; PAUSE; return 1; fi; if ! jq -e '.result.config.peers[0].public_key' "$REG" >/dev/null 2>&1; then echo -e "${RED}Резервный источник вернул неверный формат${NC}"; PAUSE; return 1; fi
PRIV="$(jq -r '.result.key' "$REG")"; WARP_PEER="$(jq -r '.result.config.peers[0].public_key' "$REG")"; WARP_V4="$(jq -r '.result.config.interface.addresses.v4' "$REG")"; WARP_V6="$(jq -r '.result.config.interface.addresses.v6 // empty' "$REG")"; fi; if [ -z "$WARP_PEER" ]
then WARP_PEER="$(jq -r '.config.peers[0].public_key' "$REG")"; WARP_V4="$(jq -r '.config.interface.addresses.v4' "$REG")"; WARP_V6="$(jq -r '.config.interface.addresses.v6 // empty' "$REG")"; fi
[ -n "$WARP_PEER" ] && [ "$WARP_PEER" != "null" ] || { echo -e "${RED}Нет peer public_key${NC}"; PAUSE; return 1; }; [ -n "$WARP_V4" ] && [ "$WARP_V4" != "null" ] || { echo -e "${RED}Нет IPv4${NC}"; PAUSE; return 1; }; echo -e "WARP ${GREEN}сгенерирован!${NC}"; }
restart_splify() { echo -e "\n${MAGENTA}Перезапускаем splify${NC}"; echo -en "${YELLOW}Подождите...${NC}"; /usr/local/sbin/splify-disable >/dev/null 2>&1; /etc/init.d/splify enable >/dev/null 2>&1; /etc/init.d/splify-agent enable >/dev/null 2>&1
uci -q set splify.global.telemetry="0" && uci commit splify; /etc/init.d/splify restart >/dev/null 2>&1; sleep 3; /etc/init.d/splify-agent restart >/dev/null 2>&1; sleep 3; /usr/local/sbin/splify-apply >/dev/null 2>&1
sleep 10; echo -e "\n\nsplify ${GREEN}перезапущен!${NC}"; echo -e "\n${YELLOW}Инициализация splify может занять несколько минут!${NC}"; }
WARP_TO_ROOT() { printf '%s\n' "[Interface]" "PrivateKey = $PRIV" "Address = $WARP_V4${WARP_V6:+, $WARP_V6}" "DNS = 9.9.9.9" "MTU = 1280" "S1 = $AWG_S1" "S2 = $AWG_S2" "Jc = $AWG_JC" "Jmin = $AWG_JMIN" "Jmax = $AWG_JMAX" "H1 = $AWG_H1" "H2 = $AWG_H2" "H3 = $AWG_H3" "H4 = $AWG_H4" "I1 = $AWG_I1" "" "[Peer]" "PublicKey = $WARP_PEER" "AllowedIPs = 0.0.0.0/0, ::/0" "Endpoint = $WARP_EP" "PersistentKeepalive = 25" > /root/WARP.conf; echo -e "${YELLOW}Файл ${NC}WARP${YELLOW} сохранён в ${NC}/root/WARP.conf"; }
# ──────────────────────────── 5. create warp0 interface ─────────────────────
create_warp_iface() { echo -e "\n${MAGENTA}Создаём интерфейс $WARP_IFACE${NC}"; if [ -n "$(uci -q get "network.$WARP_IFACE")" ]; then echo -e "${CYAN}Перенастраиваем интерфейс ${NC}$WARP_IFACE"; ifdown "$WARP_IFACE" >/dev/null 2>&1; fi
uci -q set "network.$WARP_IFACE=interface"; uci set "network.$WARP_IFACE.proto=amneziawg"; uci set "network.$WARP_IFACE.private_key=$PRIV"; uci -q delete "network.$WARP_IFACE.addresses"; uci add_list "network.$WARP_IFACE.addresses=$WARP_V4"
[ -n "$WARP_V6" ] && uci add_list "network.$WARP_IFACE.addresses=$WARP_V6"; uci -q delete "network.$WARP_IFACE.dns"; uci add_list "network.$WARP_IFACE.dns=9.9.9.9"; uci set "network.$WARP_IFACE.mtu=1280"
uci set "network.$WARP_IFACE.route_allowed_ips=0"; uci set "network.$WARP_IFACE.awg_jc=$AWG_JC"; uci set "network.$WARP_IFACE.awg_jmin=$AWG_JMIN"; uci set "network.$WARP_IFACE.awg_jmax=$AWG_JMAX"; uci set "network.$WARP_IFACE.awg_h1=$AWG_H1"
uci set "network.$WARP_IFACE.awg_h2=$AWG_H2"; uci set "network.$WARP_IFACE.awg_h3=$AWG_H3"; uci set "network.$WARP_IFACE.awg_h4=$AWG_H4"; uci set "network.$WARP_IFACE.awg_s1=$AWG_S1"; uci set "network.$WARP_IFACE.awg_s2=$AWG_S2"
uci set "network.$WARP_IFACE.awg_i1=$AWG_I1"; _pt="amneziawg_$WARP_IFACE"; while [ -n "$(uci -q get "network.@${_pt}[0]")" ]; do uci -q delete "network.@${_pt}[0]"; done; uci add network "$_pt" >/dev/null; uci set "network.@${_pt}[-1].public_key=$WARP_PEER"
uci -q delete "network.@${_pt}[-1].allowed_ips"; uci add_list "network.@${_pt}[-1].allowed_ips=0.0.0.0/0"; uci add_list "network.@${_pt}[-1].allowed_ips=::/0"; uci set "network.@${_pt}[-1].endpoint_host=${WARP_EP%:*}"
uci set "network.@${_pt}[-1].endpoint_port=${WARP_EP##*:}"; uci set "network.@${_pt}[-1].persistent_keepalive=25"; echo -e "${CYAN}Перезапускаем сеть${NC}"; uci commit network >/dev/null 2>&1; /etc/init.d/rpcd restart >/dev/null 2>&1
/etc/init.d/uhttpd restart >/dev/null 2>&1; rm -rf /tmp/luci-* >/dev/null 2>&1; ip link del "$WARP_IFACE" >/dev/null 2>&1; killall netifd >/dev/null 2>&1; sleep 3; ifup "$WARP_IFACE" >/dev/null 2>&1; sleep 3; }
# ──────────────────────────── 6. register endpoint in splify ────────────────
register_in_splify() { _ei=0; while [ -n "$(uci -q get "splify.@endpoint[$_ei]" 2>/dev/null)" ]; do _ei_if="$(uci -q get "splify.@endpoint[$_ei].iface" 2>/dev/null)"; if [ -n "$_ei_if" ] && [ -z "$(uci -q get "network.$_ei_if" 2>/dev/null)" ]
then uci -q delete "splify.@endpoint[$_ei]"; else _ei=$((_ei + 1)); fi; done; uci commit splify; grep -q "option iface '$WARP_IFACE'" /etc/config/splify 2>/dev/null || printf "\nconfig endpoint\n\toption iface '$WARP_IFACE'\n\toption priority '1'\n\toption type 'wg'\n" >> /etc/config/splify; }
# ──────────────────────────── 7. firewall zone ──────────────────────────────
setup_firewall() { echo -e "\n${MAGENTA}Создаём зону firewall${NC}"; if /usr/local/sbin/splify-firewall check "$WARP_IFACE" >/dev/null 2>&1
then echo -e "${CYAN}Зона${NC} firewall ${CYAN}для ${NC}$WARP_IFACE уже настроена${NC}"; else echo -e "${CYAN}Настраиваем зону ${NC}firewall${CYAN} для ${NC}$WARP_IFACE${NC}"; echo -en "${YELLOW}Подождите...${NC}"; /usr/local/sbin/splify-firewall fix "$WARP_IFACE" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось создать зону ${NC}firewall${RED}!${NC}\n"; PAUSE; return 1; }; echo; fi; }
# ──────────────────────────── main ──────────────────────────────────────────
SPL_V_VER() { if [ "$PKG_IS_APK" -eq 1 ]; then SPL_INST_VER=$(awk '$0=="P:splify"{f=1} f&&/^V:/{v=substr($0,3);sub(/-r[0-9]+$/,"",v);print v;exit}' /lib/apk/db/installed); else SPL_INST_VER=$(opkg list-installed splify 2>/dev/null | awk '{sub(/(-r[0-9]+|-[0-9]+)$/, "", $3); print $3}'); fi; }
SPL_MENU() { while true; do SPL_V_VER; UPD_SPL="0"; mkdir -p "$TMP_SPL"; clear; echo -e "${MAGENTA}Меню splify${NC}\n"; if [ -z "$SPL_INST_VER" ]; then SPL_STATUS="${RED}не установлен${NC}"; elif [ "$SPL_VER" = "$SPL_INST_VER" ]; then SPL_STATUS="${GREEN}$SPL_INST_VER${NC}"
else SPL_STATUS="${RED}$SPL_INST_VER (версия устарела)${NC}"; UPD_SPL="1"; fi; echo -e "${YELLOW}splify:    $SPL_STATUS" 
if [ -f /etc/init.d/steer ]; then echo -e "${YELLOW}splify2:${NC}   ${GREEN}установлен${NC}"; fi
if pkg_is_installed amneziawg-tools && pkg_is_installed luci-proto-amneziawg && pkg_is_installed kmod-amneziawg
then echo -e "${YELLOW}AmneziaWG: ${GREEN}установлен${NC}"; else echo -e "${YELLOW}AmneziaWG: ${RED}не установлен${NC}"; fi; if uci -q get network.warp0 >/dev/null 2>&1; then echo -e "${YELLOW}Интерфейс: ${GREEN}установлен${NC}"
else echo -e "${YELLOW}Интерфейс: ${RED}не установлен${NC}"; fi; if uci show firewall | grep -q "network='.*warp0"; then echo -e "${YELLOW}Firewall:  ${GREEN}настроен${NC}"; else echo -e "${YELLOW}Firewall:  ${RED}не настроен${NC}"; fi
if [ "$UPD_SPL" = "0" ]; then echo -e "\n${CYAN}1) ${GREEN}Установить ${NC}splify"; else echo -e "\n${CYAN}1) ${GREEN}Обновить ${NC}splify"; fi
echo -e "${CYAN}2) ${GREEN}Удалить ${NC}splify"
echo -e "${CYAN}3) ${GREEN}Установить ${NC}splify2"
echo -e "${CYAN}4) ${GREEN}Удалить ${NC}splify2"
echo -e "${CYAN}5) ${GREEN}Сгенерировать и применить ${NC}WARP ${GREEN}для${NC} splify"
echo -e "${CYAN}6) ${GREEN}Перезапустить ${NC}splify"
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read choiceSP; case "$choiceSP" in 
1) if [ -f /etc/init.d/steer ]; then echo -e "\n${RED}установлен${NC} splify2\n"; PAUSE; continue; fi
if [ "$UPD_SPL" = "0" ]; then clear; echo -e "${MAGENTA}Устанавливаем ${NC}splify"
install_splify || continue; install_AWG || continue; echo; register_warp || continue; echo -e "${CYAN}Используем ${NC}endpoint${CYAN}:${NC} $WARP_EP"; create_warp_iface || continue; WARP_TO_ROOT; register_in_splify; setup_firewall || continue; restart_splify; echo -e "splify ${GREEN}установлен!${NC}\n"
else echo -e "\n${MAGENTA}Обновляем ${NC}splify"; install_splify || continue; register_in_splify; restart_splify; echo -e "splify ${GREEN}обновлён!${NC}\n"; fi; PAUSE ;; 2) DELETE_SPL ;; 
3) if [ -f /etc/init.d/splify ]; then echo -e "\n${RED}установлен${NC} splify"\n; PAUSE; continue; fi
clear; echo -e "${MAGENTA}Запускаем официальный установщик splify2${NC}\n"
echo -e "${YELLOW}При выборе движка выбирайте ${NC}1\n"
sh -c "$(wget -qO- https://gitlab.com/xyzmean/splify2/-/raw/main/install.sh)"; echo; PAUSE ;;
4) echo -e "\n${MAGENTA}Удаляем splify2${NC}"
/etc/init.d/steer stop >/dev/null 2>&1
/etc/init.d/steer disable >/dev/null 2>&1
$DELETE steer-extended >/dev/null 2>&1
$DELETE steer >/dev/null 2>&1
$DELETE luci-app-splify2 >/dev/null 2>&1
rm -rf /etc/config/steer* /etc/config/splify2* /etc/init.d/steer /tmp/*steer* /tmp/*splify2* /etc/steer* /etc/splify2* 2>/dev/null
echo -e "splify2 ${GREEN}удалён!${NC}\n"; PAUSE;;
5) if [ -z "$SPL_INST_VER" ]; then echo -e "\nsplify ${RED}не установлен!${NC}\n"
else register_warp || continue; choose_endpoint || continue; create_warp_iface || continue; WARP_TO_ROOT; register_in_splify; restart_splify; echo -e "\nWARP ${GREEN}изменён!${NC}\n"; fi; PAUSE ;;
6) if [ -z "$SPL_INST_VER" ]; then echo -e "\nsplify ${RED}не установлен!${NC}\n"; else register_in_splify; restart_splify; fi; echo; PAUSE ;; *) return ;; esac; done; }
uget() { uci -q get "$1" 2>/dev/null; }
DELETE_SPL() { echo -e "\n${MAGENTA}Удаляем splify${NC}"; 
# ──────────────────────────── 1. stop splify services ───────────────────────
echo -e "${CYAN}Останавливаем службы${NC}"; for s in splify splify-agent; do if [ -x "/etc/init.d/$s" ]; then "/etc/init.d/$s" stop >/dev/null 2>&1; "/etc/init.d/$s" disable >/dev/null 2>&1; fi; done; if [ -x /etc/init.d/splify-singbox ]; then /etc/init.d/splify-singbox stop >/dev/null 2>&1; /etc/init.d/splify-singbox disable >/dev/null 2>&1; fi
# ──────────────────────────── 2. warp0 interface + peers ────────────────────
if [ -n "$(uget "network.$WARP_IFACE")" ]; then echo -e "${CYAN}Удаляем интерфейс ${NC}$WARP_IFACE"; ifdown "$WARP_IFACE" >/dev/null 2>&1; uci -q delete "network.$WARP_IFACE"; fi; for _pt in amneziawg_"$WARP_IFACE" wireguard_"$WARP_IFACE"; do while [ -n "$(uget "network.@${_pt}[0]")" ]; do uci -q delete "network.@${_pt}[0]"; done; done
# ──────────────────────────── 3. firewall zone + forwardings ────────────────
_ep_ifaces="$(uci show splify 2>/dev/null | sed -n "s/^splify\.[^=]*\.iface='\([^']*\)'\$/\1/p" | sort -u)"; _ep_ifaces="$WARP_IFACE $_ep_ifaces"; echo -e "${CYAN}Удаляем ${NC}firewall${CYAN} зону${NC}"; _zi=0; while [ -n "$(uget "firewall.@zone[$_zi]")" ]; do _zn="$(uget "firewall.@zone[$_zi].name")"; _znet="$(uget "firewall.@zone[$_zi].network")"
_zdev="$(uget "firewall.@zone[$_zi].device")"; _match=""; for _ep in $_ep_ifaces; do [ -n "$_ep" ] || continue; if [ "$_zn" = "$_ep" ]; then _match=1; break; fi; case " $_znet " in *" $_ep "*) _match=1; break ;; esac; case " $_zdev " in *" $_ep "*) _match=1; break ;; esac; done; if [ -n "$_match" ]; then uci -q delete "firewall.@zone[$_zi]"
else _zi=$((_zi + 1)); fi; done; _fi=0; while [ -n "$(uget "firewall.@forwarding[$_fi]")" ]; do _fsrc="$(uget "firewall.@forwarding[$_fi].src")"; _fdest="$(uget "firewall.@forwarding[$_fi].dest")"; _match=""; for _ep in $_ep_ifaces; do [ -n "$_ep" ] || continue; if [ "$_fsrc" = "$_ep" ] || [ "$_fdest" = "$_ep" ]; then _match=1; break; fi; done; if [ -n "$_match" ]; then uci -q delete "firewall.@forwarding[$_fi]"; else _fi=$((_fi + 1)); fi; done
# ──────────────────────────── 4. commit UCI + reload ────────────────────────
echo -e "${CYAN}Перезапускаем сеть${NC}"; uci commit network >/dev/null 2>&1; uci commit firewall >/dev/null 2>&1; /etc/init.d/rpcd restart >/dev/null 2>&1; /etc/init.d/uhttpd restart >/dev/null 2>&1
rm -rf /tmp/luci-* >/dev/null 2>&1; ip link del "$WARP_IFACE" >/dev/null 2>&1; killall netifd >/dev/null 2>&1; /etc/init.d/ttyd restart >/dev/null 2>&1; /etc/init.d/firewall reload >/dev/null 2>&1
# ──────────────────────────── 5. splify runtime (ip rules, nft, cron) ───────
if [ -x /usr/local/sbin/splify-uninstall ]; then echo -e "${CYAN}Удаляем активные правила"; /usr/local/sbin/splify-uninstall >/dev/null 2>&1; else while ip -4 rule del priority 999 >/dev/null 2>&1; do :; done
while ip -4 rule del priority 1000 >/dev/null 2>&1; do :; done; ip -4 route flush table 200 >/dev/null 2>&1; rm -f /etc/nftables.d/30-splify.nft; rm -f /tmp/dnsmasq.d/splify-*.conf /tmp/dnsmasq.cfg*.d/splify-*.conf
if [ -f /etc/crontabs/root ]; then grep -v 'splify-' /etc/crontabs/root > /tmp/splify-cron.uninst; cat /tmp/splify-cron.uninst > /etc/crontabs/root; rm -f /tmp/splify-cron.uninst; /etc/init.d/cron restart >/dev/null 2>&1; fi
rm -f /var/run/splify-state /var/run/splify-failcount /var/run/splify-events; /etc/init.d/firewall reload >/dev/null 2>&1; /etc/init.d/dnsmasq reload >/dev/null 2>&1; fi
# ──────────────────────────── 6. remove packages ─────────────────────
echo -e "${CYAN}Удаляем пакеты ${NC}splify"; $DELETE luci-i18n-splify-ru >/dev/null 2>&1; $DELETE luci-app-splify >/dev/null 2>&1; $DELETE splify >/dev/null 2>&1; if ! pkg_is_installed netshift; then echo -e "${CYAN}Удаляем пакеты ${NC}AWG"; $DELETE luci-i18n-amneziawg-ru >/dev/null 2>&1; $DELETE luci-proto-amneziawg >/dev/null 2>&1; $DELETE amneziawg-tools >/dev/null 2>&1; $DELETE kmod-amneziawg >/dev/null 2>&1; fi
# ──────────────────────────── 8. splify config + leftover data ──────────────
echo -e "${CYAN}Удаляем данные ${NC}splify"; rm -rf /etc/splify* /etc/init.d/splify* /etc/config/splify* /var/run/splify* /tmp/luci-indexcache* /tmp/luci-modulecache* /usr/local/sbin/splify* /tmp/splify*; /etc/init.d/rpcd reload 2>/dev/null || /etc/init.d/rpcd restart 2>/dev/null; echo -e "splify ${GREEN}удалён!${NC}\n"; PAUSE; }
# ==========================================
# Получение версии
# ==========================================
get_versions() { if [ "$PKG_IS_APK" -eq 1 ]; then INSTALLED_VER=$(apk info -v 2>/dev/null | grep '^zapret-' | head -n1 | cut -d'-' -f2 | sed 's/-r[0-9]\+$//'); else INSTALLED_VER=$(opkg list-installed zapret 2>/dev/null | awk '{sub(/-r[0-9]+$/, "", $3); print $3}'); fi
INSTALLED_VER2="$(zapret2_local_version)"; command -v netshift >/dev/null 2>&1 && INST_VER_POD=$(netshift show_version 2>/dev/null) && VER_POD=$(netshift show_version 2>/dev/null)
NFQ_RUN=$(pgrep -f "/opt/zapret/.*nfqws" 2>/dev/null | wc -l); NFQ_RUN=${NFQ_RUN:-0}; NFQ_ALL=$(/etc/init.d/zapret info 2>/dev/null | grep -o 'instance[0-9]\+' | wc -l)
NFQ_ALL=${NFQ_ALL:-0}; NFQ_STAT=""; if [ "$NFQ_ALL" -gt 0 ]; then [ "$NFQ_RUN" -eq "$NFQ_ALL" ] && NFQ_CLR="$GREEN" || NFQ_CLR="$RED"; NFQ_STAT="${NFQ_CLR}[${NFQ_RUN}/${NFQ_ALL}]${NC}"; fi; }
# ==========================================
# Установка Zapret
# ==========================================
install_pkg() { local display_name="$1"; local pkg_file="$2"; echo -e "${CYAN}Устанавливаем ${NC}$display_name"; $INSTALL $pkg_file >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить: ${NC}$display_name\n"; PAUSE; return 1; }; }
install_Zapret() { if [ -f /etc/init.d/zapret2 ] && ! is_expert_mode; then echo -e "\n${RED}Установлен ${NC}Zapret2${RED}!${NC}"; echo -e "${YELLOW}Установка ${NC}Zapret${YELLOW} невозможна!${NC}\n"; PAUSE; return 1; fi
get_versions; LATEST_URL="${GH_MAIN}/remittor/zapret-openwrt/releases/download/v${ZAPRET_VERSION}/zapret_v${ZAPRET_VERSION}_${LOCAL_ARCH}.zip"
mkdir -p "$TMP_SF"; local NO_PAUSE=$1; [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ] && { echo -e "\n${GREEN}Zapret уже установлен!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; return; }; [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Устанавливаем Zapret${NC}"
if [ -f /etc/init.d/zapret ]; then echo -e "${CYAN}Останавливаем ${NC}zapret"; /etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; fi;  update_packages || return
rm -f "$TMP_SF"/* 2>/dev/null; cd "$TMP_SF" || return; FILE_NAME=$(basename "$LATEST_URL"); if ! command -v unzip >/dev/null 2>&1; then echo -e "${CYAN}Устанавливаем ${NC}unzip";  update_packages || return; $INSTALL unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить ${NC}unzip\n"; PAUSE; return; }; fi
echo -e "${CYAN}Скачиваем архив ${NC}$FILE_NAME"; wget -q -U "Mozilla/5.0" -O "$FILE_NAME" "$LATEST_URL" || { echo -e "\n${RED}Не удалось скачать ${NC}$FILE_NAME\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; return; }; echo -e "${CYAN}Распаковываем архив${NC}"
unzip -o "$FILE_NAME" >/dev/null; if [ "$PKG_IS_APK" -eq 1 ]; then PKG_PATH="$TMP_SF/apk"; for PKG in "$PKG_PATH"/zapret*; do [ -f "$PKG" ] || continue; echo "$PKG" | grep -q "luci" && continue; install_pkg "$(basename "$PKG")" "$PKG" || return; done
for PKG in "$PKG_PATH"/luci*; do [ -f "$PKG" ] || continue; install_pkg "$(basename "$PKG")" "$PKG" || return; done; else PKG_PATH="$TMP_SF"; for PKG in "$PKG_PATH"/zapret_*.ipk; do [ -f "$PKG" ] || continue; install_pkg "$(basename "$PKG")" "$PKG" || return; done
for PKG in "$PKG_PATH"/luci-app-zapret_*.ipk; do [ -f "$PKG" ] || continue; install_pkg "$(basename "$PKG")" "$PKG" || return; done; fi; ADD_FAKE_FLOW
echo -e "${CYAN}Удаляем временные файлы${NC}"; cd /; rm -rf "$TMP_SF" /tmp/*.ipk /tmp/*.zip /tmp/*zapret* 2>/dev/null; echo -e "Zapret ${GREEN}установлен!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
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
stat_f() { [ "$FAKE_DIC" = "$1" ] && [ "$FAKE_DISABLED" = 0 ] && echo "${GREEN}(используется)${NC}"; }; stat_del() { [ "$FAKE_DISABLED" = 1 ] && echo "${GREEN}(используется)${NC}"; }
DIC_FAKE() { if ! grep -q -- "--filter-l7=discord,stun" "$CONF" || ! grep -q -- "--dpi-desync=fake" "$CONF"; then echo -e "\n${RED}Блок ${NC}discord,stun${RED} не найден!${NC}\n"; PAUSE; return; fi
FAKE_DIC=$(awk '/--filter-l7=discord,stun/ {blk=1; next} blk && /^.*--filter-l7=/ {exit} blk && /--dpi-desync-fake-discord=/ {sub(/.*fake\//,""); print; exit}' "$CONF")
FAKE_DISABLED=$(awk '/--filter-l7=discord,stun/ {blk=1; next} blk && /^.*--filter-l7=/ {exit} blk && /--dpi-desync-fake-discord=/ {found=1; exit} END {print found ? 0 : 1}' "$CONF")
echo -e "\n${MAGENTA}Выберите fake для discord,stun${NC}\n${CYAN}1) ${GREEN}Установить ${NC}stun.bin $(stat_f stun.bin)\n${CYAN}2) ${GREEN}Установить ${NC}stun2.bin $(stat_f stun2.bin)\n${CYAN}3) ${GREEN}Установить ${NC}quic_initial_4pda_to.bin $(stat_f quic_initial_4pda_to.bin)"
echo -e "${CYAN}4) ${GREEN}Установить ${NC}quic_initial_tencent_com.bin $(stat_f quic_initial_tencent_com.bin)\n${CYAN}5) ${GREEN}Установить ${NC}tls_clienthello_sochi_park.bin $(stat_f tls_clienthello_sochi_park.bin)"
echo -e "${CYAN}6) ${GREEN}Установить ${NC}quic_initial_www_google_com.bin $(stat_f quic_initial_www_google_com.bin)\n${CYAN}7) ${GREEN}Установить ${NC}quic_initial_steamcommunity_com.bin $(stat_f quic_initial_steamcommunity_com.bin)"
echo -e "${CYAN}8) ${GREEN}Установить ${NC}quic_initial_5ka_ru.bin $(stat_f quic_initial_5ka_ru.bin)\n${CYAN}9) ${GREEN}Установить ${NC}quic_initial_rutube_ru.bin $(stat_f quic_initial_rutube_ru.bin)\n${CYAN}0) ${GREEN}Удалить ${NC}fake $(stat_del)\n${CYAN}Enter) ${GREEN}Выход в меню настройки Discord${NC}"; echo -ne "\n${YELLOW}Выберите пункт:${NC} "; read -r choiceF; case "$choiceF" in 1) new_fileD="stun.bin";;
2) new_fileD="stun2.bin";; 3) new_fileD="quic_initial_4pda_to.bin";; 4) new_fileD="quic_initial_tencent_com.bin";; 5) new_fileD="tls_clienthello_sochi_park.bin";; 6) new_fileD="quic_initial_www_google_com.bin";; 7) new_fileD="quic_initial_steamcommunity_com.bin";;
8) new_fileD="quic_initial_5ka_ru.bin";; 9) new_fileD="quic_initial_rutube_ru.bin";; 0) new_fileD="DELETE";; *) return;; esac; [ "$new_fileD" = "DELETE" ] && echo -e "\n${CYAN}Удаляем ${NC}fake" || echo -e "\n${CYAN}Устанавливаем${NC} ${new_fileD}"; if [ "$new_fileD" = "DELETE" ]; then
awk 'BEGIN{skip=0}{if(skip>0){skip--;next}if($0=="--filter-l7=discord,stun"){print;getline nextline;print nextline;if(nextline=="--dpi-desync=fake"){getline a;getline b;if(a~/^--dpi-desync-fake-discord=/&&b~/^--dpi-desync-fake-stun=/){next}if(a!="")print a;if(b!="")print b}next}print}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"; else
awk -v new="$new_fileD" '{if($0=="--filter-l7=discord,stun"){print;getline;print;if($0=="--dpi-desync=fake"){getline nextline;if(nextline~/^--dpi-desync-fake-discord=/){print "--dpi-desync-fake-discord=/opt/zapret/files/fake/"new;getline;print "--dpi-desync-fake-stun=/opt/zapret/files/fake/"new}else{print "--dpi-desync-fake-discord=/opt/zapret/files/fake/"new;print "--dpi-desync-fake-stun=/opt/zapret/files/fake/"new;print nextline}}next}print}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"; fi
ZAPRET_RESTART; if [ "$new_fileD" = "DELETE" ]; then echo -e "fake ${GREEN}удалён!${NC}\n"; else echo -e "fake ${GREEN}изменён на ${NC}${new_fileD}${GREEN}!${NC}\n"; fi; PAUSE; }
select_Dv() { DVS=$(set | grep -E '^Dv[0-9]+=' | sed 's/=.*//' | sort -V); COUNT_dv=$(echo "$DVS" | wc -l); echo; echo -en "${YELLOW}Введите версию стратегии для discord.media (${NC}1-$COUNT_dv${YELLOW}):${NC} "; read CHOICE_DV </dev/tty
case "$CHOICE_DV" in ''|*[!0-9]*|0) return 1;; esac; SELECTED_dv="Dv$CHOICE_DV"; echo "$DVS" | grep -qx "$SELECTED_dv" || return 1; NEW_NUM="$CHOICE_DV"; NEW_STRAT=$(eval echo \"\$$SELECTED_dv\"); }
switch_Dv() { select_Dv || return 1; grep -q -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" || { echo -e "\n${RED}Стратегия не подходит!${NC}\n"; PAUSE; return 1; }; START=$(grep -n -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" | cut -d: -f1)
END=$(tail -n +"$START" "$CONF" | grep -n -m1 -E '^--new$|^#|^'\''$' | cut -d: -f1); END=$((START + END - 1)); sed -i "${START},$((END-1))d" "$CONF"; LINE=$START; echo "$NEW_STRAT" | while IFS= read -r l; do sed -i "${LINE}i$l" "$CONF"; LINE=$((LINE + 1)); done
if grep -q -E '^#[[:space:]]*Dv' "$CONF"; then sed -i "s/^#[[:space:]]*Dv[0-9]\+/#Dv$NEW_NUM/" "$CONF"; else sed -i "$START i#Dv$NEW_NUM" "$CONF"; fi; echo -e "\n${MAGENTA}Меняем стратегию для discord.media${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия ${NC}Dv$NEW_NUM${GREEN} применена!${NC}\n"; PAUSE; }
toggle_finland_hosts() { if grep -q "$Fin_IP_Dis" /etc/hosts; then sed -i "/$Fin_IP_Dis/d" /etc/hosts; echo -e "\n${MAGENTA}Удаляем Финские IP${NC}"; /etc/init.d/dnsmasq restart 2>/dev/null
echo -e "${GREEN}Финские ${NC}IP${GREEN} удалены${NC}\n"; else seq 10000 10199 | awk '{print "104.25.158.178 finland"$1".discord.media"}' | grep -vxFf /etc/hosts >> /etc/hosts; echo -e "\n${MAGENTA}Добавляем Финские IP${NC}"; /etc/init.d/dnsmasq restart 2>/dev/null; echo -e "${GREEN}Финские ${NC}IP${GREEN} добавлены${NC}\n"; fi; PAUSE; }
show_script_50() { [ -f "/opt/zapret/init.d/openwrt/custom.d/50-script.sh" ] || return; line=$(head -n1 /opt/zapret/init.d/openwrt/custom.d/50-script.sh)
name=$(case "$line" in *QUIC*) echo "50-quic4all";; *stun*) echo "50-stun4all";; *"discord media"*) echo "50-discord-media";; *"discord subnets"*) echo "50-discord";; *) echo "";; esac); }
Discord_menu() { if [ -f /etc/init.d/zapret2 ] && ! is_expert_mode; then echo -e "\n${RED}Установлен ${NC}Zapret2${RED}!${NC}"; echo -e "${YELLOW}Меню настройки Discord доступно только с ${NC}Zapret${NC}\n"; PAUSE; return 1; fi;
[ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; local NO_PAUSE=$1; while true; do [ "$NO_PAUSE" != "1" ] && clear && echo -e "${MAGENTA}Меню настройки Discord${NC}\n"; output_shown=false
[ "$NO_PAUSE" != "1" ] && show_script_50 && [ -n "$name" ] && echo -e "${YELLOW}Установлен скрипт:${NC} $name" && output_shown=true; [ "$NO_PAUSE" != "1" ] && grep -q "$Fin_IP_Dis" /etc/hosts && echo -e "${YELLOW}Финские IP для Discord: ${GREEN}включены${NC}" && output_shown=true
if [ "$NO_PAUSE" != "1" ]; then FAKE_FILE=$(awk '/--filter-l7=discord,stun/ {blk=1; next} blk && /^.*--filter-l7=/ {exit} blk && /--dpi-desync-fake-discord=/ {sub(/.*fake\//,""); print; exit}' "$CONF"); if [ -n "$FAKE_FILE" ]; then echo -e "${YELLOW}fake в discord,stun:${NC} $FAKE_FILE"; else echo -e "${YELLOW}fake в discord,stun:${RED} отсутствует${NC}"; fi; output_shown=true; fi
[ "$NO_PAUSE" != "1" ] && NUMDv=$(grep -o -E '^#[[:space:]]*Dv[0-9][0-9]*' "$CONF" | sed 's/[^0-9]//g' | head -n1) && [ -n "$NUMDv" ] && echo -e "${YELLOW}Стратегия для discord.media: ${CYAN}Dv$NUMDv${NC}"  && output_shown=true
$output_shown && echo; if [ "$NO_PAUSE" = "1" ]; then SELECTED="50-stun4all"; URL="${GH_RAW}/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all"; else
echo -e "${CYAN}1) ${GREEN}Установить скрипт ${NC}50-stun4all\n${CYAN}2) ${GREEN}Установить скрипт ${NC}50-quic4all\n${CYAN}3) ${GREEN}Установить скрипт ${NC}50-discord-media\n${CYAN}4) ${GREEN}Установить скрипт ${NC}50-discord\n${CYAN}5) ${GREEN}Удалить скрипт${NC}"
grep -q '104\.25\.158\.178 finland[0-9]\{5\}\.discord\.media' /etc/hosts && FIN_TXT="${GREEN}Удалить Финские ${NC}IP ${GREEN}из ${NC}hosts" || FIN_TXT="${GREEN}Добавить ${NC}Финские IP ${GREEN}в ${NC}hosts"
echo -e "${CYAN}6) $FIN_TXT\n${CYAN}7) ${GREEN}Выбрать и установить стратегию для ${NC}discord.media\n${CYAN}8) ${GREEN}Меню выбора ${NC}fake ${GREEN}для ${NC}discord,stun"; echo -en "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choiceSC; case "$choiceSC" in
1) SELECTED="50-stun4all"; URL="${GH_RAW}/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all";; 2) SELECTED="50-quic4all"; URL="${GH_RAW}/bol-van/zapret/master/init.d/custom.d.examples.linux/50-quic4all";;
3) SELECTED="50-discord-media"; URL="${GH_RAW}/bol-van/zapret/master/init.d/custom.d.examples.linux/50-discord-media";; 4) SELECTED="50-discord"; URL="${GH_RAW}/bol-van/zapret/v70.5/init.d/custom.d.examples.linux/50-discord";;
5) [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; continue; }; echo -e "\n${MAGENTA}Удаляем скрипт${NC}"; rm -f "$CUSTOM_DIR/50-script.sh" 2>/dev/null; sed -i "/DISABLE_CUSTOM/s/'0'/'1'/" $CONF; ZAPRET_RESTART; echo -e "${GREEN}Скрипт удалён!${NC}\n"; PAUSE; continue;;
6) toggle_finland_hosts; continue;; 7) switch_Dv; continue;; 8) DIC_FAKE; continue;; *) return;; esac; fi; [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; continue; }
if wget -q -U "Mozilla/5.0" -O "$CUSTOM_DIR/50-script.sh" "$URL"; then [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Устанавливаем скрипт${NC}\n${GREEN}Скрипт ${NC}$SELECTED${GREEN} успешно установлен!${NC}\n"; else echo -e "\n${RED}Ошибка при скачивании скрипта!${NC}\n"; PAUSE; continue; fi
sed -i "/DISABLE_CUSTOM/s/'1'/'0'/" $CONF; ZAPRET_RESTART; [ "$NO_PAUSE" != "1" ] && PAUSE; [ "$NO_PAUSE" = "1" ] && break; done; }
# ==========================================
# FIX GAME
# ==========================================
Gv_Xtreme() { if ! grep -q '^#Gv[0-9]\+' "$CONF"; then echo -e "\n${RED}Игровая стратегия ${NC}Gv${RED} не найдена!${NC}\n"; PAUSE; return; fi; mkdir -p "$(dirname "$GV_XTREME_FILE")"; if grep -q "^#Gv[0-9]\+Xtreme$" "$CONF"; then [ ! -f "$GV_XTREME_FILE" ] && { echo -e "\n${RED}Файл восстановления не найден!${NC}\n"; PAUSE; return; }
echo -e "\n${CYAN}Отключаем ${NC}Xtreme ${CYAN}режим${NC}"; OLD_GV=$(sed -n '1p' "$GV_XTREME_FILE"); OLD_UDP=$(sed -n '2p' "$GV_XTREME_FILE"); OLD_TCP=$(sed -n '3p' "$GV_XTREME_FILE"); OLD_TCP_OPTION=$(sed -n '4p' "$GV_XTREME_FILE"); OLD_UDP_OPTION=$(sed -n '5p' "$GV_XTREME_FILE")
awk -v gv="$OLD_GV" -v udp="$OLD_UDP" -v tcp="$OLD_TCP" '/^#Gv[0-9]+Xtreme$/ {print gv; restore=1; next} restore && /^--filter-udp=/ {print udp; next} restore && /^--filter-tcp=/ {print tcp; restore=0; next} {print}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
[ -n "$OLD_TCP_OPTION" ] && sed -i "s|^[[:space:]]*option NFQWS_PORTS_TCP .*|$OLD_TCP_OPTION|" "$CONF"; [ -n "$OLD_UDP_OPTION" ] && sed -i "s|^[[:space:]]*option NFQWS_PORTS_UDP .*|$OLD_UDP_OPTION|" "$CONF"; rm -f "$GV_XTREME_FILE"; ZAPRET_RESTART; echo -e "Xtreme${GREEN} режим отключён!${NC}\n"; PAUSE; return; fi; echo -e "\n${CYAN}Включаем ${NC}Xtreme ${CYAN}режим${NC}"
awk '/^#Gv[0-9]+$/ {gv=$0; found=1; next} found && /^--filter-udp=/ {udp=$0} found && /^--filter-tcp=/ {tcp=$0} /^[[:space:]]*option NFQWS_PORTS_TCP / {tcp_option=$0} /^[[:space:]]*option NFQWS_PORTS_UDP / {udp_option=$0} END {print gv; print udp; print tcp; print tcp_option; print udp_option}' "$CONF" > "$GV_XTREME_FILE"
sed -i -e "s|^[[:space:]]*option NFQWS_PORTS_TCP .*|	option NFQWS_PORTS_TCP '$GV_XTREME_NFQWS_PORTS'|" -e "s|^[[:space:]]*option NFQWS_PORTS_UDP .*|	option NFQWS_PORTS_UDP '$GV_XTREME_NFQWS_PORTS'|" "$CONF"; sed -i "s/^#\(Gv[0-9]\+\)$/#\1Xtreme/" "$CONF"
awk -v ports="$GV_XTREME_PORTS" '/^#Gv[0-9]+Xtreme$/ {gv=1; print; next} gv && /^--filter-udp=/ {print "--filter-udp=" ports; next} gv && /^--filter-tcp=/ {print "--filter-tcp=" ports; gv=0; next} {print}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"; ZAPRET_RESTART
echo -e "Xtreme${GREEN} режим включён!${NC}"; echo -e "\n${RED}Внимание: ${YELLOW}Xtreme режим может повлиять на работу приложений и соединений !\n          Используйте его только для проверки работы игр !${NC}\n"; PAUSE; }
remove_ports_if_present() { local OPTION="$1"; local PORTS="$2"; for p in $(echo "$PORTS" | tr ',' ' '); do sed -i "\#option $OPTION '#s#,$p##g" "$CONF"; done; sed -i "\#option $OPTION '#s#,,#,#g; s#,\$##" "$CONF"; }
add_ports_if_missing() { local OPTION="$1"; local PORTS="$2"; for p in $(echo "$PORTS" | tr ',' ' '); do grep -q "option $OPTION '.*\b$p\b" "$CONF" || sed -i "\#option $OPTION '#s#'\$#,$p'#" "$CONF"; done; }
strategy_TCP_common() { printf "%s\n" "--new" "--filter-tcp=$PORTS_TCP" "--dpi-desync-any-protocol=1" "--dpi-desync-cutoff=n5" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=582" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin"; }
strategy_Gv1() { printf "%s\n" "#Gv1" "--new" "--filter-udp=$PORTS_UDP" "--dpi-desync=fake" "--dpi-desync-cutoff=d2" "--dpi-desync-any-protocol=1" "--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/stun.bin"; }
strategy_Gv() { local N="$1"; printf "%s\n" "#Gv$N" "--new" "--filter-udp=$PORTS_UDP" "--dpi-desync=fake" "--dpi-desync-repeats=10" "--dpi-desync-any-protocol=1" "--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/stun.bin" "--dpi-desync-cutoff=n$N"; }
GV_FAKE() { if ! grep -q -- "--dpi-desync-fake-unknown-udp=" "$CONF"; then echo -e "\n${RED}Блок ${NC}dpi-desync-fake-unknown-udp${RED} не найден!${NC}\n"; PAUSE; return; fi; CURRENT_FAKE=$(grep -m1 -- '--dpi-desync-fake-unknown-udp=' "$CONF" | sed 's|.*fake/||'); gv_fake() { [ "$CURRENT_FAKE" = "$1" ] && echo "${GREEN}(используется)${NC}"; }
echo -e "\n${MAGENTA}Выберите fake для игровой стратегии${NC}\n${CYAN}1) ${GREEN}Установить ${NC}stun.bin $(gv_fake stun.bin)\n${CYAN}2) ${GREEN}Установить ${NC}stun2.bin $(gv_fake stun2.bin)\n${CYAN}3) ${GREEN}Установить ${NC}quic_initial_4pda_to.bin $(gv_fake quic_initial_4pda_to.bin)"
echo -e "${CYAN}4) ${GREEN}Установить ${NC}quic_initial_tencent_com.bin $(gv_fake quic_initial_tencent_com.bin)\n${CYAN}5) ${GREEN}Установить ${NC}tls_clienthello_sochi_park.bin $(gv_fake tls_clienthello_sochi_park.bin)"
echo -e "${CYAN}6) ${GREEN}Установить ${NC}quic_initial_www_google_com.bin $(gv_fake quic_initial_www_google_com.bin)\n${CYAN}7) ${GREEN}Установить ${NC}quic_initial_steamcommunity_com.bin $(gv_fake quic_initial_steamcommunity_com.bin)"
echo -e "${CYAN}8) ${GREEN}Установить ${NC}quic_initial_5ka_ru.bin $(gv_fake quic_initial_5ka_ru.bin)\n${CYAN}9) ${GREEN}Установить ${NC}quic_initial_rutube_ru.bin $(gv_fake quic_initial_rutube_ru.bin)"
echo -en "${CYAN}Enter) ${GREEN}Выход в меню стратегий${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r choiceF; case "$choiceF" in 1) new_file="stun.bin";; 2) new_file="stun2.bin";; 3) new_file="quic_initial_4pda_to.bin";; 4) new_file="quic_initial_tencent_com.bin";; 5) new_file="tls_clienthello_sochi_park.bin";; 6) new_file="quic_initial_www_google_com.bin";; 7) new_file="quic_initial_steamcommunity_com.bin";; 8) new_file="quic_initial_5ka_ru.bin";; 9) new_file="quic_initial_rutube_ru.bin";; *) return;; esac; echo -e "\n${CYAN}Устанавливаем fake${NC} ${new_file}"
awk -v new="$new_file" 'BEGIN{done=0} !done && /--dpi-desync-fake-unknown-udp=/{sub(/\/opt\/zapret\/files\/fake\/[^ ]+/, "/opt/zapret/files/fake/" new); done=1} {print}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"; ZAPRET_RESTART; echo -e "fake ${GREEN}изменён на ${NC}${new_file}${GREEN}!${NC}\n"; PAUSE; }
fix_GAME() { local NO_PAUSE=$1; [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; local CURRENT_GAME=""; for i in 1 2 3 4; do grep -q "^#Gv$i" "$CONF" && CURRENT_GAME="Gv$i"; done
if [ -n "$NO_PAUSE" ]; then GAME_CHOICE="$NO_PAUSE"; else echo -e "\n${MAGENTA}Меню управления стратегией для игр${NC}"; for i in $(seq 1 4); do if [ "$CURRENT_GAME" = "Gv$i" ]; then echo -e "${CYAN}$i) ${GREEN}Удалить ${NC}Gv$i"; else echo -e "${CYAN}$i) ${GREEN}Установить ${NC}Gv$i"; fi; done
grep -q "^#Gv[0-9]\+Xtreme" "$CONF" && XTREME_TXT="${GREEN}Отключить ${NC}Xtreme${GREEN} режим${NC}" ||	XTREME_TXT="${GREEN}Включить ${NC}Xtreme${GREEN} режим${NC}"; echo -e "${CYAN}5) $XTREME_TXT\n${CYAN}6) ${GREEN}Выбрать и сменить ${NC}fake${GREEN} для игровой стратегии${NC}"
echo -en "${CYAN}Enter) ${GREEN}Выход в меню стратегий\n\n${YELLOW}Выберите пункт: ${NC}"; read GAME_CHOICE; fi; if [ "$GAME_CHOICE" = "6" ]; then GV_FAKE; return; fi; if [ "$GAME_CHOICE" = "5" ]; then Gv_Xtreme; return; fi
case "$GAME_CHOICE" in 1|2|3|4) ;; *) return;; esac; LAST_QUOTE=$(grep -n "^'\$" "$CONF" | tail -n1 | cut -d: -f1); if grep -q "^#Gv" "$CONF"; then Gv_LINE=$(grep -n "^#Gv" "$CONF" | tail -n1 | cut -d: -f1); sed -i "${Gv_LINE},${LAST_QUOTE}d" "$CONF"; elif [ -n "$LAST_QUOTE" ]; then sed -i "${LAST_QUOTE},\$d" "$CONF"; fi
if [ "$CURRENT_GAME" = "Gv$GAME_CHOICE" ]; then remove_ports_if_present NFQWS_PORTS_UDP "$PORTS_UDP"; remove_ports_if_present NFQWS_PORTS_TCP "$PORTS_TCP"; echo "'" >> "$CONF"; echo -e "\n${CYAN}Удаляем стратегию для игр ${NC}"; ZAPRET_RESTART
echo -e "${GREEN}Стратегия для игр удалена!${NC}\n"; [ -z "$NO_PAUSE" ] && PAUSE; return; fi; if [ "$GAME_CHOICE" -eq 1 ]; then STRATEGY="$(strategy_Gv1; strategy_TCP_common)"; else STRATEGY="$(strategy_Gv "$GAME_CHOICE"; strategy_TCP_common)"; fi
echo "$STRATEGY" | sed '/^$/d' >> "$CONF"; echo "'" >> "$CONF"; add_ports_if_missing NFQWS_PORTS_UDP "$PORTS_UDP"; add_ports_if_missing NFQWS_PORTS_TCP "$PORTS_TCP"
[ -z "$NO_PAUSE" ] && echo; echo -e "${CYAN}Устанавливаем стратегию для игр ${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия для игр ${NC}Gv$GAME_CHOICE${GREEN} установлена!${NC}\n"; [ -z "$NO_PAUSE" ] && PAUSE; }
# ==========================================
# Zapret под ключ
# ==========================================
zapret_key() { if [ -f /etc/init.d/zapret2 ] && ! is_expert_mode; then echo -e "\n${RED}Установлен ${NC}Zapret2${RED}!${NC}"; echo -e "${YELLOW}Установка ${NC}Zapret${YELLOW} невозможна!${NC}\n"; PAUSE; return 1; fi; clear; echo -e "${MAGENTA}Удаление, установка и настройка Zapret${NC}\n"; get_versions; uninstall_zapret "1"; install_Zapret "1"
[ ! -f /etc/init.d/zapret ] && { echo -e "Zapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; install_strategy $STR_VERSION_AUTOINSTALL "1"; echo -e "${MAGENTA}Редактируем hosts${NC}\n${CYAN}Добавляем домены в${NC} hosts"
hosts_add "$ALL_BLOCKS"; echo -e "${GREEN}Домены добавлены в ${NC}hosts${GREEN}!${NC}\n"; Discord_menu "1"; echo -e "${MAGENTA}Настраиваем стратегию для игр${NC}"; fix_GAME "1"; echo -e "Zapret ${GREEN}установлен и настроен!${NC}\n"; PAUSE; }
# ==========================================
# Резервная копия
# ==========================================
delete_backup() { if [ -d "$BACKUP_DIR" ]; then rm -rf "$BACKUP_DIR"; echo -e "\n${GREEN}Резервная копия удалена!${NC}\n"; else echo -e "\n${RED}Резервная копия не найдена!${NC}\n"; fi; PAUSE; }
save_backup() { [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; rm -rf "$BACKUP_DIR"; mkdir -p "$BACKUP_DIR"; tar -czf "$BACKUP_DIR/zapret.tar.gz" -C /opt zapret 2>/dev/null
cp -p $CONF "$BACKUP_DIR/"; printf '%s / %s\n' "$(date '+%d.%m.%y')" "$(du -sh /opt/zapret_backup 2>/dev/null | cut -f1 | sed -E 's/\.0K$/K/;s/K$/ КБ/;s/M$/ МБ/')" > "$DATE_FILE"; echo -e "\n${GREEN}Резервная копия настроек сохранена в${NC} $BACKUP_DIR\n"; PAUSE; }
restore_backup() { [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; [ ! -f "$BACKUP_DIR/zapret.tar.gz" ] && { echo -e "\n${RED}Резервная копия не найдена!${NC}\n"; PAUSE; return; }
echo -e "\n${MAGENTA}Восстанавливаем настройки из резервной копии${NC}"; /etc/init.d/zapret stop >/dev/null 2>&1; rm -rf /opt/zapret; rm -f $CONF; mkdir -p /opt; tar -xzf "$BACKUP_DIR/zapret.tar.gz" -C /opt 2>/dev/null
[ -f "$BACKUP_DIR/zapret" ] && cp -p "$BACKUP_DIR/zapret" $CONF; echo -e "${CYAN}Применяем настройки${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Настройки восстановлены из резервной копии!${NC}\n"; PAUSE; }
# ==========================================
# Cтарт/стоп Zapret
# ==========================================
stop_zapret() { local NO_PAUSE=$1; echo -e "\n${MAGENTA}Останавливаем Zapret${NC}\n${CYAN}Останавливаем ${NC}Zapret"; /etc/init.d/zapret stop >/dev/null 2>&1
for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; echo -e "Zapret ${GREEN}остановлен!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
start_zapret() { if [ -f /etc/init.d/zapret ]; then echo -e "\n${MAGENTA}Запускаем Zapret${NC}"; /etc/init.d/zapret start >/dev/null 2>&1; ZAPRET_RESTART;
if /etc/init.d/zapret status >/dev/null 2>&1; then echo -e "Zapret ${GREEN}запущен!${NC}\n"; else echo -e "Zapret ${RED}не удалось запустить!${NC}\n"; fi; else echo -e "\nZapret ${RED}не установлен!${NC}\n"; fi; [ "$NO_PAUSE" != "1" ] && PAUSE; }
toggle_zapret() { if [ -f /etc/init.d/zapret2 ]; then if /etc/init.d/zapret2 status >/dev/null 2>&1; then echo -e "\n${MAGENTA}Останавливаем Zapret2${NC}"; /etc/init.d/zapret2 stop >/dev/null 2>&1
for pid in $(pgrep -f /opt/zapret2 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; echo -e "Zapret2 ${GREEN}остановлен!${NC}\n"; else echo -e "\n${MAGENTA}Запускаем Zapret2${NC}"; /etc/init.d/zapret2 start >/dev/null 2>&1
if /etc/init.d/zapret2 status >/dev/null 2>&1; then echo -e "Zapret2 ${GREEN}запущен!${NC}\n"; else echo -e "Zapret2 ${RED}не удалось запустить!${NC}\n"; fi; fi; PAUSE
elif [ -f /etc/init.d/zapret ]; then if pgrep -f "/opt/zapret" >/dev/null 2>&1; then stop_zapret; else start_zapret; fi; fi; }
toggle_zapret1_only() { if pgrep -f "/opt/zapret/" >/dev/null 2>&1; then echo -e "\n${MAGENTA}Останавливаем Zapret${NC}"; /etc/init.d/zapret stop >/dev/null 2>&1; for pid in $(pgrep -f "/opt/zapret/" 2>/dev/null)
do kill -9 "$pid" 2>/dev/null; done; echo -e "Zapret ${GREEN}остановлен!${NC}\n"; else echo -e "\n${MAGENTA}Запускаем Zapret${NC}"; /etc/init.d/zapret start >/dev/null 2>&1; ZAPRET_RESTART; if /etc/init.d/zapret status >/dev/null 2>&1
then echo -e "Zapret ${GREEN}запущен!${NC}\n"; else echo -e "Zapret ${RED}не удалось запустить!${NC}\n"; fi; fi; PAUSE; }
toggle_zapret2_only() { if /etc/init.d/zapret2 status >/dev/null 2>&1; then echo -e "\n${MAGENTA}Останавливаем Zapret2${NC}"; /etc/init.d/zapret2 stop >/dev/null 2>&1; for pid in $(pgrep -f /opt/zapret2 2>/dev/null)
do kill -9 "$pid" 2>/dev/null; done; echo -e "Zapret2 ${GREEN}остановлен!${NC}\n"; else echo -e "\n${MAGENTA}Запускаем Zapret2${NC}"; /etc/init.d/zapret2 start >/dev/null 2>&1
if /etc/init.d/zapret2 status >/dev/null 2>&1; then echo -e "Zapret2 ${GREEN}запущен!${NC}\n"; else echo -e "Zapret2 ${RED}не удалось запустить!${NC}\n"; fi; fi; PAUSE; }
# ==========================================
# Удаление Zapret
# ==========================================
uninstall_zapret() { local NO_PAUSE=$1; [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Удаляем Zapret${NC}\n${CYAN}Останавливаем ${NC}zapret"; /etc/init.d/zapret stop >/dev/null 2>&1; /etc/init.d/zapret disable >/dev/null 2>&1; echo -e "${CYAN}Убиваем процессы${NC}"
for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; echo -e "${CYAN}Удаляем пакеты${NC}"; $DELETE luci-app-zapret >/dev/null 2>&1; $DELETE zapret >/dev/null 2>&1; echo -e "${CYAN}Удаляем временные файлы${NC}"
rm -rf /opt/zapret $CONF /etc/firewall.zapret /etc/init.d/zapret /tmp/*.ipk /tmp/*.zip 2>/dev/null; crontab -l 2>/dev/null | grep -v -i -E "zapret|/usr/bin/zmsA --auto-best" | crontab - 2>/dev/null; /etc/init.d/cron restart >/dev/null 2>&1
nft list tables 2>/dev/null | awk '{print $2}' | grep -E '(zapret|ZAPRET)' | while read t; do [ -n "$t" ] && nft delete table "$t" 2>/dev/null; done; rm -rf -- "$TMP_SF" tmp/zapret* ; echo -e "Zapret ${GREEN}удалён!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
uninstall_zapret_all() { local NO_PAUSE=$1; [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Удаляем Zapret и Zapret2${NC}"
echo -e "${CYAN}Останавливаем службы${NC}"; /etc/init.d/zapret stop >/dev/null 2>&1; /etc/init.d/zapret2 stop >/dev/null 2>&1; /etc/init.d/zapret disable >/dev/null 2>&1; /etc/init.d/zapret2 disable >/dev/null 2>&1
echo -e "${CYAN}Убиваем процессы${NC}"; for pid in $(pgrep -f /opt/zapret 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; for pid in $(pgrep -f /opt/zapret2 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done; for pid in $(pgrep -f nfqws 2>/dev/null); do kill -9 "$pid" 2>/dev/null; done
echo -e "${CYAN}Удаляем пакеты${NC}"; $DELETE zapret >/dev/null 2>&1; $DELETE luci-app-zapret >/dev/null 2>&1; $DELETE zapret2 >/dev/null 2>&1; $DELETE luci-app-zapret2 >/dev/null 2>&1
echo -e "${CYAN}Удаляем папки и конфиги${NC}"; rm -rf /opt/zapret /opt/zapret2 2>/dev/null; rm -f /etc/config/zapret /etc/config/zapret2 2>/dev/null; rm -f /etc/firewall.zapret /etc/firewall.zapret2 2>/dev/null; rm -f /etc/init.d/zapret /etc/init.d/zapret2 2>/dev/null; rm -rf /tmp/*zapret*
echo -e "${CYAN}Удаляем временные файлы, логи и резервные копии${NC}"; rm -rf /tmp/*zapret* /tmp/zapret_temp /tmp/routerich 2>/dev/null; rm -rf /var/run/*zapret* 2>/dev/null; rm -rf "$TMP_SF" 2>/dev/null; rm -f /tmp/*.ipk /tmp/*.apk /tmp/*.zip 2>/dev/null; rm -rf "$BACKUP_DIR" 2>/dev/null
echo -e "${CYAN}Очищаем cron${NC}"; crontab -l 2>/dev/null | grep -v -i -E "zapret|/usr/bin/zmsA --auto-best" | crontab - 2>/dev/null; sed -i "\|$AUTO_CRON_CMD|d" "$CRON_FILE" 2>/dev/null; /etc/init.d/cron restart >/dev/null 2>&1
echo -e "${CYAN}Удаляем nftables таблицы${NC}"; nft list tables 2>/dev/null | awk '{print $2}' | grep -Ei '^(zapret|zapret2)$' | while read -r t; do [ -n "$t" ] && nft delete table "$t" 2>/dev/null; done
echo -e "Zapret ${GREEN}и${NC} Zapret2 ${GREEN}полностью удалены!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
# ==========================================
# Тест стратегии для Ютуб
# ==========================================
YOUTUBE_TEST_MENU() { echo -e "\n${MAGENTA}Выберите способ тестирования стратегий${NC}"; echo -e "${CYAN}1) ${GREEN}Тестировать каждую стратегию отдельно${NC}"; echo -e "${CYAN}2) ${GREEN}Тестировать все стратегии сразу${NC}"
echo -ne "${CYAN}Enter) ${GREEN}Выход в меню тестирования стратегий${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r yt_choice; case "$yt_choice" in 1) auto_stryou ;; 2) run_test_youtube_all ;; *) return ;; esac; }
run_test_youtube_all() { echo -e "\n${MAGENTA}Выберите источник стратегий:${NC}"; echo -e "${CYAN}1) ${GREEN}Встроенные стратегии ${NC}Yv"; echo -e "${CYAN}2) ${GREEN}Стратегии из ${NC}/root/custom_test.txt"
echo -ne "${CYAN}Enter) ${GREEN}Выход в меню тестирования стратегий${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r SRC; mkdir -p "$TMP_SF"; : > "$STR_FILE"; case "$SRC" in
1) curl -fsSL "$STR_URL" -o "$STR_FILE" || { echo -e "\n${RED}Не удалось скачать список стратегий!${NC}\n"; PAUSE; return 1; } ;;
2) if [ ! -s "$CUSTOM_STR_FILE" ]; then echo -e "\n${RED}Файл ${NC}$CUSTOM_STR_FILE${RED} не найден!${NC}\n"; PAUSE; return 1; fi; cp "$CUSTOM_STR_FILE" "$STR_FILE"; sed -i 's/\r$//' "$STR_FILE"
sed -i '/^[[:space:]]*$/d' "$STR_FILE"; sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "$STR_FILE" ;; *) return ;; esac
clear; echo -e "${MAGENTA}Тестирование всех стратегий YouTube${NC}\n\n${CYAN}Собираем стратегии для теста${NC}"; cp "$CONF" "$BACK"; run_test_core_youtube "$RES_YOUTUBE"; }
run_test_core_youtube() { local RESULTS="$1"; URLS=""; for d in $DOMAINS; do URLS="${URLS}${d}|https://${d}/
"; done; TOTAL=$(echo $DOMAINS | wc -w); TOTAL_STR=$(grep -c '^#' "$STR_FILE"); echo -e "${CYAN}Найдено стратегий: ${NC}$TOTAL_STR"; echo -e "${CYAN}Доменов для теста:${NC} $TOTAL"; : > "$RESULTS"; check_zpr_off; LINES=$(grep -n '^#' "$STR_FILE" | cut -d: -f1); CUR=0
echo "$LINES" | while read START; do CUR=$((CUR+1)); NEXT=$(echo "$LINES" | awk -v s="$START" '$1>s{print;exit}'); if [ -z "$NEXT" ]; then
sed -n "${START},\$p" "$STR_FILE" > "$TEMP_FILE"; else sed -n "${START},$((NEXT-1))p" "$STR_FILE" > "$TEMP_FILE"; fi; BLOCK=$(cat "$TEMP_FILE"); NAME=$(head -n1 "$TEMP_FILE"); NAME="${NAME#\#}"
awk -v block="$BLOCK" 'BEGIN{skip=0} /option NFQWS_OPT '\''/ {printf "\toption NFQWS_OPT '\''\n%s\n'\''\n", block; skip=1; next} skip && /^'\''$/ {skip=0; next} !skip {print}' "$CONF" > "${CONF}.tmp"
echo -e "\n${CYAN}Тестируем стратегию: ${YELLOW}${NAME}${NC} ($CUR/$TOTAL_STR)"; ZAPRET_RESTART; OK=0; LOG_TMP="/tmp/zapret_log_yt_${CUR}"; : > "$LOG_TMP"; check_all_urls
if [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; elif [ "$OK" -ge $((TOTAL/2)) ]; then COLOR="${YELLOW}"; else COLOR="${RED}"; fi; echo -e "${CYAN}Результат теста: ${COLOR}$OK/$TOTAL${NC}"; echo -e "${NAME} → ${OK}/${TOTAL}" >> "$RESULTS"; done
sort -t'/' -k1 -nr "$RESULTS" -o "$RESULTS"; mv -f "$BACK" "$CONF"; ZAPRET_RESTART; BEST_LINE=$(grep -v '^Контрольный тест' "$RESULTS" | head -n1)
[ -n "$BEST_LINE" ] && echo -e "\n${GREEN}Лучшая стратегия для YouTube: ${NC}${BEST_LINE}"; show_single_result "$RESULTS"; }
auto_stryou() { awk '/^[[:space:]]*option NFQWS_OPT '\''/{flag=1} flag{print}' "$CONF" > "$OLD_STR"; echo -e "\n${MAGENTA}Выберите источник стратегий:${NC}"; echo -e "${CYAN}1) ${GREEN}Встроенные стратегии ${NC}Yv"; echo -e "${CYAN}2) ${GREEN}Стратегии из ${NC}/root/custom_test.txt"
echo -ne "${CYAN}Enter) ${GREEN}Выход в меню тестирования стратегий${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r SRC; case "$SRC" in 1) curl -fsSL "$STR_URL" -o "$TMP_LIST" || { echo -e "\n${RED}Не удалось скачать список стратегий!${NC}\n"; PAUSE; return 1; } ;;
2) if [ ! -s "$CUSTOM_STR_FILE" ]; then echo -e "\n${RED}Файл ${NC}$CUSTOM_STR_FILE${RED} не найден!${NC}\n"; PAUSE; return 1; fi; cp "$CUSTOM_STR_FILE" "$TMP_LIST"; cp "$CUSTOM_STR_FILE" "$TMP_LIST"; sed -i 's/\r$//' "$TMP_LIST"
sed -i '/^[[:space:]]*$/d' "$TMP_LIST"; sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "$TMP_LIST" ;; *) return ;; esac; clear; echo -e "${MAGENTA}Тестируем стратегии для YouTube${NC}"
TOTAL=$(grep -c '^#' "$TMP_LIST"); echo -e "\n${CYAN}Найдено стратегий: ${NC}$TOTAL"; CURRENT_NAME=""; CURRENT_BODY=""; COUNT=0; while IFS= read -r LINE || [ -n "$LINE" ]; do if echo "$LINE" | grep -q '^#'; then if [ -n "$CURRENT_NAME" ]; then COUNT=$((COUNT + 1))
echo -e "\n${CYAN}Тестируем стратегию: ${NC}${CURRENT_NAME#\#} ($COUNT/$TOTAL)"; apply_strategy "$CURRENT_NAME" "$CURRENT_BODY"; echo -e "${CYAN}Тестируем домены:${NC}"
STATUS=$(check_access); if [ "$STATUS" = "ok" ]; then echo -e "\n${GREEN}Домены доступны!${NC}\n${YELLOW}Проверьте работу ${NC}YouTube${YELLOW} на устройствах!${NC}"
echo -en "Enter${GREEN} - применить стратегию, ${NC}S/s${GREEN} - остановить, ${NC}N/n${GREEN} - продолжить тест:${NC} "; read -r ANSWER </dev/tty
if [ -z "$ANSWER" ]; then { echo "$CURRENT_NAME"; printf "%b\n" "$CURRENT_BODY"; } > "$SAVED_STR"; echo -e "${CYAN}Применяем стратегию и перезапускаем ${NC}Zapret"
awk '{if(skip){if($0=="--new"||$0~/\047/){skip=0;next}if($0~/^[[:space:]]*$/)next;next}if($0=="--filter-tcp=443"){getline n;if(n=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"){skip=1;next}else{print $0;print n;next}}if($0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt")has_google=1;if($0~/^[[:space:]]*#Yv/)next;print}' "$OLD_STR" > "$NEW_STR"
awk 'BEGIN{inserted=0;has_google=0}$0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"{has_google=1}$0=="--new"&&!inserted{while((getline l<"'"$SAVED_STR"'")>0)if(l!~/^[[:space:]]*$/)print l;print "--new";inserted=1;next}$0~/^[[:space:]]*option NFQWS_OPT \047$/&&!has_google&&!inserted{print;while((getline l<"'"$SAVED_STR"'")>0)if(l!~/^[[:space:]]*$/)print l;print "--new";inserted=1;next}{print}' "$NEW_STR" > "$FINAL_STR"
sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$FINAL_STR" >> "$CONF"; awk '{if($0=="--new"){if(prev!="--new")print}else print;prev=$0}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
grep -q "^[[:space:]]*' *\$" "$CONF" || echo "'" >> "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия применена!${NC}\n"; PAUSE </dev/tty; return 0; elif [[ "$ANSWER" =~ ^[Ss]$ ]]; then sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART
echo -e "\n${GREEN}Тест остановлен!${NC}\n"; PAUSE </dev/tty; return 1; fi; else echo -e "${RED}Домены не доступны, продолжаем тест...${NC}"; fi; fi; CURRENT_NAME="$LINE"; CURRENT_BODY=""; else [ -n "$LINE" ] && CURRENT_BODY="${CURRENT_BODY}${LINE}\n"; fi; done < "$TMP_LIST"
if [ -n "$CURRENT_NAME" ]; then COUNT=$((COUNT + 1)); echo -e "\n${CYAN}Проверяем стратегию: ${NC}${CURRENT_NAME#\#} ($COUNT/$TOTAL)"; apply_strategy "$CURRENT_NAME" "$CURRENT_BODY"; echo -e "${CYAN}Тестируем домены:${NC}"; STATUS=$(check_access); if [ "$STATUS" = "ok" ]; then echo -e "\n${GREEN}Домены доступны!${NC}\n${YELLOW}Проверьте работу ${NC}YouTube${YELLOW} на устройствах!${NC}"
echo -en "Enter${GREEN} - применить стратегию, ${NC}S/s${GREEN} - остановить, ${NC}N/n${GREEN} - продолжить тест:${NC} "; read -r ANSWER </dev/tty; if [ -z "$ANSWER" ]; then { echo "#$CURRENT_NAME"; printf "%b\n" "$CURRENT_BODY"; } > "$SAVED_STR"; echo -e "${CYAN}Применяем стратегию и перезапускаем ${NC}Zapret"
awk '{ if(skip) { if($0=="--new" || $0 ~ /'\''/) { skip=0; print; next } next } if($0=="--filter-tcp=443") { getline next_line; if(next_line=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt") { skip=1; next } else { print $0; print next_line; next } } if($0~/^[[:space:]]*#Yv/) next; print }' "$OLD_STR" > $NEW_STR
awk 'BEGIN { inserted=0 } /^--new/ && !inserted { system("cat '"$SAVED_STR"'"); inserted=1 } { print }' $NEW_STR > $FINAL_STR; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat $FINAL_STR >> "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия применена!${NC}\n"; PAUSE </dev/tty; return 0; elif [[ "$ANSWER" =~ ^[Ss]$ ]]; then sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; 
cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART; echo -e "\n${GREEN}Тест остановлен!${NC}\n"; PAUSE </dev/tty; return 1; fi; else echo -e "${RED}Видео не открывается...${NC}\n"; fi; fi; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; cat "$OLD_STR" >> "$CONF"; ZAPRET_RESTART; echo -e "\n${RED}Рабочая стратегия для YouTube не найдена!${NC}\n"; PAUSE </dev/tty; return 1; }
check_access() { ANY_OK=0; ALL_OK=1; for domain in $DOMAINS; do echo -ne "$domain" >&2; if curl -s --connect-timeout 1 -m 2 "https://$domain" >/dev/null; then echo -ne " - ${GREEN}доступен${NC}\n" >&2; ANY_OK=1; else echo -ne " - ${RED}недоступен${NC}\n" >&2; ALL_OK=0; fi; done
if [ "$ALL_OK" -ne 1 ] && [ "$ANY_OK" -eq 1 ]; then echo -e "\n${RED}Не все домены доступны, возможны проблемы с воспроизведением видео!${NC}" >&2; fi; [ "$ANY_OK" = "1" ] && echo "ok" || echo "fail"; }
apply_strategy() { NAME="$1"; BODY="$2"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; { echo "  option NFQWS_OPT '"; echo "#AUTO $NAME"; printf "%b\n" "$BODY"; echo "'"; } >> "$CONF"; ZAPRET_RESTART; }
# ==========================================
# РКН список ВКЛ / ВЫКЛ
# ==========================================
enable_rkn() { echo -e "\n${MAGENTA}Включаем списки РКН${NC}"; SIZE=0; [ -f "$HOSTLIST_FILE" ] && SIZE=$(wc -c < "$HOSTLIST_FILE" 2>/dev/null || echo 0); if [ "$SIZE" -le 1800000 ]
then [ -f "$HOSTLIST_FILE" ] && cp "$HOSTLIST_FILE" "$BACKUP_FILE" && cp "$HOSTLIST_FILE" "$HOSTS_USER"; curl -fsSL "$RKN_URL" >> "$HOSTLIST_FILE" || { echo -e "\n${RED}Не удалось скачать список РКН${NC}\n"; PAUSE; return; }; fi
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
ADD_Yv() { if ! grep -q "^#Yv" "$CONF" && ! grep -q "^#general" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_OPT '/a\\#Yv08\\n--filter-tcp=443\\n--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt\\n--dpi-desync=hostfakesplit\\n--dpi-desync-hostfakesplit-mod=host=google.com\\n--dpi-desync-fooling=ts\\n--new" "$CONF"; fi; }
strategy_v1() { printf '%s\n' "#v1" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=split2" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin"; }
strategy_v2() { printf '%s\n' "#v2" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=ts" "--dpi-desync-repeats=8" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com"; }
strategy_v3() { printf '%s\n' "#v3" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-hostfakesplit-mod=host=ozon.ru" "--dpi-desync-repeats=4" "--dpi-desync-fooling=ts,md5sig" "--dpi-desync-badseq-increment=0"; }
strategy_v4() { printf '%s\n' "#v4" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=582" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin"; }
strategy_v5() { printf '%s\n' "#v5" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=1" "--dpi-desync-fake-tls=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0"; }
strategy_v6() { printf '%s\n' "#v6" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-hostfakesplit-mod=host=i2.photo.2gis.com" "--dpi-desync-hostfakesplit-midhost=host-2" "--dpi-desync-split-seqovl=726" "--dpi-desync-fooling=badsum,badseq" "--dpi-desync-badseq-increment=0"; }
strategy_v7() { printf '%s\n' "#v7" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=654" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-repeats=8" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-tls=/opt/zapret/files/fake/stun.bin" "--dpi-desync-badseq-increment=0"; }
strategy_v8() { printf '%s\n' "#v8" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-fooling=ts" "--dpi-desync-fake-tls=/opt/zapret/files/fake/4pda.bin" "--dpi-desync-fake-tls-mod=none"; }
strategy_v9() { printf '%s\n' "#v9" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-hostfakesplit-mod=host=ozon.ru" "--dpi-desync-badseq-increment=0"; }
strategy_v10() { printf '%s\n' "#v10" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,split2" "--dpi-desync-split-pos=2" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-hostfakesplit-mod=host=maxcdn.bootstrapcdn.com" "--dpi-desync-fake-tls-mod=rnd,sni=maxcdn.bootstrapcdn.com" "--dpi-desync-fooling=ts"; }
# ==========================================
# Cтратегии Flowseal
# ==========================================
flowseal_menu() { [ ! -f "$OUT" ] && download_strategies; while true; do STRATEGIES=$(grep '^#' "$OUT" | sed 's/^#//'); clear
echo -e "${YELLOW}Список стратегий от Flowseal${NC}\n"; i=1; echo "$STRATEGIES" | while IFS= read -r line; do if [ "$i" -lt 10 ]; then echo -e " ${CYAN}$i) ${NC}$line"; else echo -e "${CYAN}$i) ${NC}$line"; fi; i=$((i+1)); done
echo -en "${CYAN}99) ${GREEN}Обновить стратегии${NC}\n${CYAN}Enter) ${GREEN}Выход в меню стратегий${NC}\n\n${YELLOW}Выберите пункт: ${NC}"; read CHOICE_SF
[ -z "$CHOICE_SF" ] && return; echo "$CHOICE_SF" | grep -qE '^[0-9]+$' || return; [ "$CHOICE_SF" -eq 99 ] && { rm -rf "$TMP_SF"; download_strategies; continue; }; SEL_NAME=$(echo "$STRATEGIES" | sed -n "${CHOICE_SF}p"); [ -z "$SEL_NAME" ] && return
BLOCK=$(awk -v name="$SEL_NAME" '$0=="#"name {flag=1; print; next} /^#/ && flag {exit} flag {print}' "$OUT"); sed -i "/option NFQWS_OPT '/,\$d" "$CONF"; { echo "	option NFQWS_OPT '"; echo "$BLOCK"; echo "'"; } >> "$CONF"
if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,19294-19344,50000-50100'/" "$CONF"; fi; if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"
then sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'$/,2053,2083,2087,2096,8443'/" "$CONF"; fi; echo -e "\n${MAGENTA}Устанавливаем стратегию\n${CYAN}Добавляем домены в исключения${NC}"; ADD_GP_DOMAINS; rm -f "$EXCLUDE_FILE"
wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || { echo -e "\n${RED}Не удалось загрузить exclude файл${NC}\n"; PAUSE; return; }; sed -i '/--new/{N;/--filter-tcp=2802/{s/--new/#Gv0\n--new/;};}' "$CONF"
echo -e "${CYAN}Применяем стратегию${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия ${NC}$SEL_NAME ${GREEN}установлена!${NC}\n"; show_ts_warning; PAUSE; break; done; }
download_strategies() { local NO_PAUSE=$1; [ "$NO_PAUSE" != "1" ] && echo -e "\n${MAGENTA}Скачиваем и формируем стратегии${NC}"; mkdir -p "$TMP_SF"; : > "$OUT"; wget -q -U "Mozilla/5.0" -O "$ZIP" "$FLOWSEAL_STR_ZIP" || { echo -e "\n${RED}Не удалось загрузить файл стратегий${NC}\n"; PAUSE; return; }
if ! command -v unzip >/dev/null 2>&1; then echo -e "${CYAN}Устанавливаем ${NC}unzip";  update_packages || return; $INSTALL unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}\n"; PAUSE; return; }; fi
unzip -oq "$ZIP" -d "$TMP_SF" || { echo -e "\n${RED}Не удалось распоковать файл${NC}\n"; PAUSE; return; }; BASE="$TMP_SF/zapret-discord-youtube-main"
find "$BASE" -type f -name 'general*.bat' ! -name 'general (ALT5).bat' | while read -r F; do MATCH=$(grep -E '^--filter-udp=19294-19344,50000-50100|^--filter-tcp=%GameFilterTCP%|^--filter-udp=%GameFilterUDP%|^--filter-tcp=2053,2083,2087,2096,8443|^--filter-tcp=443 --hostlist="%LISTS%list-google.txt"|^--filter-tcp=80,443 --hostlist="%LISTS%list-general.txt"' "$F")
[ -z "$MATCH" ] && continue; NAME=$(basename "$F" .bat); { echo "#$NAME"; echo "$MATCH" | sed 's/--/\n--/g' | sed '/^$/d' | sed 's/[[:space:]]*$//'; echo; } >> "$OUT"; done
sed -i 's|"%BIN%tls_clienthello_www_google_com.bin"|/opt/zapret/files/fake/tls_clienthello_www_google_com.bin|g' "$OUT"; sed -i '/--hostlist="%LISTS%list-general.txt"/d' "$OUT"
sed -i '/--ipset="%LISTS%ipset-all.txt"/d' "$OUT"; sed -i '/--hostlist="%LISTS%list-general-user.txt"/d' "$OUT"; sed -i '/--ipset-exclude="%LISTS%ipset-exclude.txt"/d' "$OUT"; sed -i '/--ipset-exclude="%LISTS%ipset-exclude-user.txt"/d' "$OUT"
sed -i '/--hostlist-exclude="%LISTS%list-exclude-user.txt"/d' "$OUT"; sed -i 's|"%LISTS%list-exclude.txt"|/opt/zapret/ipset/zapret-hosts-user-exclude.txt|g' "$OUT"; sed -i 's/--new[[:space:]]\^/--new/g' "$OUT"; sed -i 's|"%LISTS%list-google.txt"|/opt/zapret/ipset/zapret-hosts-google.txt|g' "$OUT"
sed -i 's|"%BIN%tls_clienthello_sochi_park.bin"|/opt/zapret/files/fake/tls_clienthello_sochi_park.bin|g' "$OUT"; sed -i 's|"%BIN%stun.bin"|/opt/zapret/files/fake/stun.bin|g' "$OUT"; sed -i 's|"%BIN%tls_clienthello_4pda_to.bin"|/opt/zapret/files/fake/4pda.bin|g' "$OUT"
sed -i 's|"%BIN%quic_initial_www_google_com.bin"|/opt/zapret/files/fake/quic_initial_www_google_com.bin|g' "$OUT"; sed -i 's|"%BIN%stun2.bin"|/opt/zapret/files/fake/stun2.bin|g' "$OUT"; sed -i 's|"%BIN%quic_initial_tencent_com.bin"|/opt/zapret/files/fake/quic_initial_tencent_com.bin|g' "$OUT"
sed -i 's|"%BIN%quic_initial_steamcommunity_com.bin"|/opt/zapret/files/fake/quic_initial_steamcommunity_com.bin|g' "$OUT"; sed -i 's|"%BIN%quic_initial_4pda_to.bin"|/opt/zapret/files/fake/quic_initial_4pda_to.bin|g' "$OUT"
sed -i 's|"%BIN%ACTIVE_DISCORD_UDP.bin"|/opt/zapret/files/fake/quic_initial_steamcommunity_com.bin|g' "$OUT"; sed -i 's|"%BIN%ACTIVE_GAME_UDP.bin"|/opt/zapret/files/fake/quic_initial_4pda_to.bin|g' "$OUT"
sed -i 's|"%BIN%tls_clienthello_max_ru.bin"|/opt/zapret/files/fake/tls_clienthello_www_onetrust_com.bin|g' "$OUT"; sed -i 's|"%BIN%quic_initial_5ka_ru.bin"|/opt/zapret/files/fake/quic_initial_5ka_ru.bin|g' "$OUT"; sed -i 's|"%BIN%quic_initial_rutube_ru.bin"|/opt/zapret/files/fake/quic_initial_rutube_ru.bin|g' "$OUT"
sed -i "s|%GameFilterTCP%|$PORTS_TCP|g" "$OUT"; sed -i "s|%GameFilterUDP%|$PORTS_UDP|g" "$OUT"; sed -i 's|\^!|/opt/zapret/files/fake/tls_clienthello_www_google_com.bin|g' "$OUT"; sed -i 's/[[:space:]]\+$//' "$OUT"; sed -i '/^[[:space:]]*$/d' "$OUT"
sed -i '/^--new$/ { N; /^\--new\n$/d; }' "$OUT"; rm -rf "$TMP_SF/zapret-discord-youtube-main" "$ZIP"; ADD_FAKE_FLOW; [ "$NO_PAUSE" != "1" ] && echo -e "${GREEN}Стратегии сформированы!${NC}\n"; [ "$NO_PAUSE" != "1" ] && PAUSE; }
# ==========================================
# Меню стратегий
# ==========================================
ADD_GP_DOMAINS() { printf '%s\n' "gvt1.com" "googleplay.com" "play.google.com" "beacons.gvt2.com" "play.googleapis.com" "play-fe.googleapis.com" "lh3.googleusercontent.com" "android.clients.google.com" "connectivitycheck.gstatic.com" "play-lh.googleusercontent.com" "play-games.googleusercontent.com" "prod-lt-playstoregatewayadapter-pa.googleapis.com" "youtubei.youtube.com" | grep -Fxv -f "$fileGP" 2>/dev/null >> "$fileGP"; }
manage_block() { action="$1"; f1="$2"; f2="$3"; if [ "$action" = "add" ]; then echo -e "\n${MAGENTA}Добавляем блок с ${f2}\n${CYAN}Добавляем блок в стратегию\nПерезапускаем ${NC}Zapret"; last_line=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1)
[ -n "$last_line" ] && sed -i "${last_line},\$d" "$CONF"; printf "%s\n" "--new" "$f1" "$f2" "'" >> "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Блок с ${NC}${f2}${GREEN} добавлен!${NC}"
echo -e "\n${YELLOW}Блок может влиять на скорость и стабильность интернета!${NC}\n"; PAUSE; fi; if [ "$action" = "remove" ]; then echo -e "\n${MAGENTA}Удаляем блок с ${f2}${NC}\n${CYAN}Удаляем блок из стратегию\nПерезапускаем ${NC}Zapret"
awk -v l1="$f1" -v l2="$f2" '$0=="--new" && getline a && getline b { if (a==l1 && b==l2) next; print "--new"; print a; print b; next } 1' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"; ZAPRET_RESTART; echo -e "${GREEN}Блок с ${NC}${f2}${GREEN} удалён!${NC}\n"; PAUSE; fi; }
add_wssize() { manage_block add "--filter-tcp=443" "--wssize 1:6"; }; remove_wssize() { manage_block remove "--filter-tcp=443" "--wssize 1:6"; }; add_methodeol() { manage_block add "--filter-tcp=80,443" "--methodeol"; }; remove_methodeol() { manage_block remove "--filter-tcp=80,443" "--methodeol"; }
menu_str() { if [ -f /etc/init.d/zapret2 ] && ! is_expert_mode; then echo -e "\n${RED}Установлен ${NC}Zapret2${RED}!${NC}"; echo -e "${YELLOW}Меню стратегий доступно только с ${NC}Zapret${NC}\n"; PAUSE; return 1; fi
[ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; while true; do show_current_strategy; RKN_Check; clear; echo -e "${MAGENTA}Меню стратегий${NC}\n"; pri=0
GV_FAKE_FILE=$(grep -m1 -- '--dpi-desync-fake-unknown-udp=' "$CONF" | sed 's|.*fake/||'); [ -n "$GV_FAKE_FILE" ] && echo -e "${YELLOW}fake для Gv:${NC} $GV_FAKE_FILE"; if [ "$SIZE" -gt 1800000 ] && ! grep -q -- "--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt" "$CONF"; then echo -e "User hostname entries ${YELLOW}содержит список ${NC}РКН"; fi
INFO_ZPR_STR; echo -e "\n${CYAN}0) ${GREEN}Меню тестирования стратегий${NC}"; echo -e "${CYAN}1) ${GREEN}Выбрать и установить стратегию ${NC}v1-v10\n${CYAN}2) ${GREEN}Выбрать и установить стратегию от ${NC}Flowseal\n${CYAN}3) ${GREEN}Выбрать и установить стратегию для ${NC}YouTube\n${CYAN}4) ${GREEN}Меню управления стратегией для ${NC}игр"
echo -e "${CYAN}5) ${NC}$RKN_TEXT_MENU${NC}\n${CYAN}6) ${GREEN}Обновить список исключений${NC}"; if grep -q -F -- "--wssize 1:6" "$CONF"; then WSSIZE_MENU_TEXT="${GREEN}Удалить из стратегии блок с ${NC}--wssize 1:6"; else WSSIZE_MENU_TEXT="${GREEN}Добавить в стратегию блок с ${NC}--wssize 1:6"; fi
if grep -q -F -- "--methodeol" "$CONF"; then methodeol_MENU_TEXT="${GREEN}Удалить из стратегии блок с ${NC}--methodeol"; else methodeol_MENU_TEXT="${GREEN}Добавить в стратегию блок с ${NC}--methodeol"; fi
echo -e "${CYAN}7) ${WSSIZE_MENU_TEXT}${NC}"; echo -e "${CYAN}8) ${methodeol_MENU_TEXT}${NC}"; if grep -q "^#udp443" $CONF; then echo -e "${CYAN}9) ${GREEN}Удалить из стратегии блок с ${NC}--filter-udp=443"; else echo -e "${CYAN}9) ${GREEN}Добавить в стратегию блок с ${NC}--filter-udp=443"; fi
echo -e "${CYAN}c) ${GREEN}Собрать собственную стратегию${NC}"; echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read choiceST; case "$choiceST" in 1) strategy_CHOUSE;; 2) flowseal_menu;; 3) choose_strategy_YOUTUBE;; 4) fix_GAME;;
c|C|с|С) build_custom_strategy;; 5) toggle_rkn_bypass; continue;; 6) echo -e "\n${MAGENTA}Обновляем список исключений${NC}\n${CYAN}Останавливаем ${NC}Zapret"; /etc/init.d/zapret stop >/dev/null 2>&1; echo -e "${CYAN}Добавляем домены в исключения${NC}"
rm -f "$EXCLUDE_FILE"; wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || echo -e "\n${RED}Не удалось загрузить exclude файл${NC}\n"; echo -e "${CYAN}Перезапускаем ${NC}Zapret"; ZAPRET_RESTART; echo -e "${GREEN}Список исключений обновлён!${NC}\n"; PAUSE;;
7) if grep -q -F -- "--wssize 1:6" "$CONF"; then remove_wssize; else add_wssize; fi; continue;; 8) if grep -q -F -- "--methodeol" "$CONF"; then remove_methodeol; else add_methodeol; fi; continue;; 0) TEST_menu;;
9) if grep -q "^#udp443" $CONF; then echo -e "\n${MAGENTA}Удаляем блок с --filter-udp=443\n${CYAN}Удаляем блок из стратегии\nПерезапускаем ${NC}Zapret"; sed -i '/^#udp443$/,+6d' $CONF; ZAPRET_RESTART; echo -e "${GREEN}Блок с ${NC}--filter-udp=443${GREEN} удалён!${NC}\n"; PAUSE; else echo -e "\n${MAGENTA}Добавляем блок с --filter-udp=443\n${CYAN}Добавляем блок в стратегию\nПерезапускаем ${NC}Zapret"
sed -i "/^[[:space:]]*option NFQWS_OPT '/a\\#udp443\\n--filter-udp=443\\n--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt\\n--dpi-desync=fake\\n--dpi-desync-repeats=11\\n--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin\\n--new" $CONF
ZAPRET_RESTART; echo -e "${GREEN}Блок с ${NC}--filter-udp=443${GREEN} добавлен!${NC}\n"; PAUSE; fi ;; *) return;; esac; done; }
strategy_CHOUSE() { echo -ne "\n${YELLOW}Введите версию стратегии (${NC}1-10${YELLOW}):${NC} "; read -r choice; if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le 10 ]]; then install_strategy "v$choice"; fi; }
show_current_strategy() { [ -f "$CONF" ] || return; ver=$(grep -o '#v[0-9]*' "$CONF" | sed 's/#v//' | sort -n | tail -1 | sed 's/^/v/'); yv_ver=$(grep -o '#Yv[0-9]*' "$CONF" | sed 's/#Yv//' | sort -n | tail -1 | sed 's/^/Yv/'); }
discord_str_add() { if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'$/,19294-19344,50000-50100'/" "$CONF"; fi
if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'$/,2053,2083,2087,2096,8443'/" "$CONF"; fi
if ! grep -q -- "--filter-udp=19294-19344,50000-50100" "$CONF"; then last_line1=$(grep -n "^'$" "$CONF" | tail -n1 | cut -d: -f1); if [ -n "$last_line1" ]; then sed -i "${last_line1},\$d" "$CONF"; fi
printf "%s\n" "--new" "--filter-udp=19294-19344,50000-50100" "--filter-l7=discord,stun" "--dpi-desync=fake" "--dpi-desync-fake-discord=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-stun=/opt/zapret/files/fake/stun.bin" \
"--dpi-desync-repeats=6" "#Dv1" "--new" "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=652" "--dpi-desync-split-pos=2" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "'" >> "$CONF"; fi; }
install_strategy() { local version="$1"; local NO_PAUSE="${2:-0}"; [ "$NO_PAUSE" != "1" ] && echo; echo -e "${MAGENTA}Устанавливаем стратегию ${version}${NC}\n${CYAN}Меняем стратегию${NC}"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; { echo "  option NFQWS_OPT '"; strategy_"$version"; echo "'"; } >> "$CONF"
ADD_GP_DOMAINS; echo -e "${CYAN}Добавляем домены в исключения${NC}"; rm -f "$EXCLUDE_FILE"; wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || { echo -e "\n${RED}Не удалось загрузить exclude файл${NC}\n"; PAUSE; return; }
ADD_Yv; discord_str_add; echo -e "${CYAN}Применяем новую стратегию${NC}"; ZAPRET_RESTART; echo -e "${GREEN}Стратегия ${NC}${version}${GREEN} установлена!${NC}\n"; show_ts_warning; [ "$NO_PAUSE" != "1" ] && PAUSE; }
choose_strategy_YOUTUBE() { curl -fsSL "$STR_URL" -o "$TMP_LIST" || { echo -e "\n${RED}Не удалось скачать список${NC}\n"; PAUSE; return 1; }
COUNT=0; > $TMP_SF/strategy_list; while IFS= read -r LINE; do case "$LINE" in \#Yv[0-9]*) COUNT=$((COUNT + 1)); echo "$LINE" >> $TMP_SF/strategy_list;; esac; done < "$TMP_LIST"
[ "$COUNT" -eq 0 ] && echo -e "${RED}Стратегий не найдено!${NC}\n" && PAUSE && rm -f $TMP_SF/strategy_list && return 1; echo -en "\n${YELLOW}Введите версию стратегии для YouTube (${NC}1-$COUNT${YELLOW}):${NC} "
read CHOICE </dev/tty; if ! echo "$CHOICE" | grep -qE '^[0-9]+$' || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "$COUNT" ]; then return 1; fi; SELECTED_NAME=$(sed -n "${CHOICE}p" $TMP_SF/strategy_list); DISPLAY_NAME="${SELECTED_NAME#\#}"; rm -f $TMP_SF/strategy_list
echo -e "\n${CYAN}Применяем стратегию: ${NC}$DISPLAY_NAME"; SAVED_STR="$TMP_SF/selected_str"; > "$SAVED_STR"; FLAG=0; while IFS= read -r LINE; do [ "$LINE" = "$SELECTED_NAME" ] && FLAG=1 && continue; case "$LINE" in \#Yv[0-9]*) FLAG=0;; esac
[ "$FLAG" -eq 1 ] && printf "%b\n" "$LINE" >> "$SAVED_STR"; done < "$TMP_LIST"; awk '/^[[:space:]]*option NFQWS_OPT '\''/{flag=1} flag{print}' "$CONF" > "$OLD_STR"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; sed -i "/^[[:space:]]*#Yv[0-9]\+/d" "$OLD_STR"
awk '{if(skip){if($0=="--new"||$0~/\047/){skip=0;next}if($0~/^[[:space:]]*$/)next;next}if($0=="--filter-tcp=443"){getline n;if(n=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"){skip=1;next}else{print $0;print n;next}}if($0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt")has_google=1;if($0~/^[[:space:]]*#Yv/)next;print}' "$OLD_STR" > "$NEW_STR"
awk 'BEGIN{inserted=0;has_google=0} $0=="--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt"{has_google=1} $0=="--new"&&!inserted{while((getline l<"'"$SAVED_STR"'")>0) if(l!~/^[[:space:]]*$/) print l; print "--new"; inserted=1; next} $0~/^[[:space:]]*option NFQWS_OPT \047$/&&!has_google&&!inserted{print; print "'"$SELECTED_NAME"'"; while((getline l<"'"$SAVED_STR"'")>0) if(l!~/^[[:space:]]*$/) print l; print "--new"; inserted=1; next} {print}' "$NEW_STR" > "$FINAL_STR"
cat "$FINAL_STR" >> "$CONF"; awk '{if($0=="--new"){if(prev!="--new")print}else print;prev=$0}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"; grep -q "^[[:space:]]*' *\$" "$CONF" || echo "'" >> "$CONF"; ADD_GP_DOMAINS; ZAPRET_RESTART; echo -e "${GREEN}Стратегия применена!${NC}\n"; show_ts_warning; PAUSE; }
# ==========================================
# DNS over HTTPS
# ==========================================
DoH_menu() { while true; do get_doh_status; clear; echo -e "${MAGENTA}Меню DNS over HTTPS${NC}\n"; if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e https-dns-proxy >/dev/null 2>&1 && doh_st="Удалить" || doh_st="Установить"; else
opkg list-installed | grep -q '^https-dns-proxy ' && doh_st="Удалить" || doh_st="Установить"; fi; if [ -n "$DOH_STATUS" ]; then if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e https-dns-proxy >/dev/null 2>&1 && echo -e "${YELLOW}DNS over HTTPS: ${NC}$DOH_STATUS\n"
else opkg list-installed | grep -q '^https-dns-proxy ' && echo -e "${YELLOW}DNS over HTTPS: ${NC}$DOH_STATUS\n"; fi; fi; echo -e "${CYAN} 1)${GREEN} $doh_st ${NC}DNS over HTTPS\n${CYAN} 2)${GREEN} Настроить ${NC}Xbox\n${CYAN} 3)${GREEN} Настроить ${NC}Comss"
echo -e "${CYAN} 4)${GREEN} Настроить ${NC}Google\n${CYAN} 5)${GREEN} Настроить ${NC}Quad 9\n${CYAN} 6)${GREEN} Настроить ${NC}GeoHide\n${CYAN} 7)${GREEN} Настроить ${NC}Cloudflare\n${CYAN} 8)${GREEN} Настроить ${NC}dns.malw.link\n${CYAN} 9)${GREEN} Настроить ${NC}dns.astracat.ru"
echo -e "${CYAN}10)${GREEN} Настроить ${NC}dns.mafioznik.xyz\n${CYAN}11)${GREEN} Настроить ${NC}dns.malw.link (CloudFlare)\n${CYAN}12)${GREEN} Настроить ${NC}dns.nullsproxy.com (Supercell)\n${CYAN}13)${GREEN} Вернуть ${NC}настройки по умолчанию"
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read -r choiceDOH; [ -z "$choiceDOH" ] && return; case "$choiceDOH" in 1) D_o_H;; 2) doh_install && setup_doh "$doh_xbox" "Xbox";; 3) doh_install && setup_doh "$doh_comss" "Comss.one";;
4) doh_install && setup_doh "$doh_GOO" "Google";; 5) doh_install && setup_doh "$doh_Quad" "Quad 9";; 6) doh_install && menu_GEOHIDE_DOH;; 7) doh_install && setup_doh "$doh_CLF" "Cloudflare";; 8) doh_install && setup_doh "$doh_query" "dns.malw.link";;
9) doh_install && setup_doh "$doh_astracat" "dns.astracat.ru";; 10) doh_install && setup_doh "$doh_mafioznik" "dns.mafioznik.xyz";; 11) doh_install && setup_doh "$doh_queryCF" "dns.malw.link (CloudFlare)";; 12) doh_install && setup_doh "$doh_nullsproxy" "dns.nullsproxy.com";; 13) doh_install && setup_doh "$doh_def" "настройки по умолчанию";; *) return;; esac; done; }
setup_doh() { local config="$1"; local name="$2"; echo -e "\n${MAGENTA}Настраиваем DNS over HTTPS${NC}\n${CYAN}Настраиваем ${NC}$name\n${CYAN}Применяем новые настройки${NC}"
rm -f "$fileDoH"; printf '%s\n' "$doh_set" "$config" > "$fileDoH"; /etc/init.d/https-dns-proxy reload >/dev/null 2>&1; /etc/init.d/https-dns-proxy restart >/dev/null 2>&1; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "DNS over HTTP ${GREEN}настроен!${NC}\n"; PAUSE; }
get_doh_status() { DOH_STATUS=""; [ ! -f "$fileDoH" ] && return; if grep -q "dns.comss.one" "$fileDoH"; then DOH_STATUS="Comss"; elif grep -q "xbox-dns.ru" "$fileDoH"; then DOH_STATUS="Xbox"; elif grep -q "5u35p8m9i7.cloudflare-gateway.com" "$fileDoH"
then DOH_STATUS="dns.malw.link (CloudFlare)"; elif grep -q "dns.malw.link" "$fileDoH"; then DOH_STATUS="dns.malw.link"; elif grep -q "dns.mafioznik.xyz" "$fileDoH"; then DOH_STATUS="dns.mafioznik.xyz"
elif grep -q "eu.geohide.ru" "$fileDoH"; then DOH_STATUS="GeoHide EU"; elif grep -q "us.geohide.ru" "$fileDoH"; then DOH_STATUS="GeoHide US"; elif grep -q "geohide.ru" "$fileDoH"
then DOH_STATUS="GeoHide RU"; elif grep -q "cloudflare-dns.com" "$fileDoH" && grep -q "dns.google" "$fileDoH"; then DOH_STATUS="по умолчанию"; elif grep -q "cloudflare-dns.com" "$fileDoH"; then DOH_STATUS="Cloudflare"; elif grep -q "dns.quad9.net" "$fileDoH"; then DOH_STATUS="Quad 9"
elif grep -q "dns.google" "$fileDoH"; then DOH_STATUS="Google"; elif grep -q "dns.astracat.ru" "$fileDoH"; then DOH_STATUS="dns.astracat.ru"; elif grep -q "dns.nullsproxy.com" "$fileDoH"; then DOH_STATUS="dns.nullsproxy.com"; else DOH_STATUS="установлен"; fi; }
D_o_H(){ if { [ "$PKG_IS_APK" -eq 1 ] && apk info -e https-dns-proxy >/dev/null 2>&1; } || { [ "$PKG_IS_APK" -eq 0 ] && opkg list-installed | grep -q '^https-dns-proxy '; }; then echo -e "\n${MAGENTA}Удаляем DNS over HTTPS${NC}\n${CYAN}Удаляем пакеты${NC}"; $DELETE https-dns-proxy luci-app-https-dns-proxy >/dev/null 2>&1; echo -e "${CYAN}Удаляем файлы конфигурации${NC}"; rm -f /etc/config/https-dns-proxy /etc/init.d/https-dns-proxy
sed -i -e "/option doh_backup_noresolv '-1'/d" -e "/option noresolv '1'/d" -e "/list doh_backup_server ''/d" -e "/list server '\/mask\.icloud\.com\/'/d" -e "/list server '\/mask-h2\.icloud\.com\/'/d" -e "/list server '\/use-application-dns\.net\/'/d" -e "/list server '127\.0\.0\.1#5053'/d" -e "/list server '127\.0\.0\.1#5054'/d" -e "/list doh_server '127\.0\.0\.1#5053'/d" -e "/list doh_server '127\.0\.0\.1#5054'/d" /etc/config/dhcp
/etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "DNS over HTTPS${GREEN} удалён!${NC}\n"; PAUSE; else if pkg_is_installed netshift; then echo -e "\n${RED}Обнаружен ${NC}NetShift${RED}!"; echo -e "${YELLOW}Удалите ${NC}NetShift\n"; PAUSE; return; fi; echo -e "\n${MAGENTA}Устанавливаем DNS over HTTPS${NC}"; update_packages || return; echo -e "${CYAN}Устанавливаем ${NC}https-dns-proxy"
$INSTALL https-dns-proxy >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установке!${NC}\n"; PAUSE; return; }; echo -e "${CYAN}Устанавливаем ${NC}luci-app-https-dns-proxy"; $INSTALL luci-app-https-dns-proxy >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установке!${NC}\n"; PAUSE; return; }; echo -e "DNS over HTTPS${GREEN} установлен!${NC}\n"; PAUSE; fi; }
doh_install() { [ -f "$fileDoH" ] && return 0; echo -e "\n${RED}DNS over HTTPS не установлен!${NC}\n"; PAUSE; return 1; }
doh_set=$(printf "%s\n" "config main 'config'" "	option canary_domains_icloud '1'" "	option canary_domains_mozilla '1'" "	option dnsmasq_config_update '*'" "	option force_dns '1'" "	option notrack_dns '1'" "	list force_dns_port '53'" "	list force_dns_port '853'" "	list force_dns_src_interface 'lan'" "	option procd_trigger_wan6 '0'" "	option heartbeat_domain 'heartbeat.mossdef.org'" "	option heartbeat_sleep_timeout '10'" "	option heartbeat_wait_timeout '10'" "	option user 'nobody'" "	option group 'nogroup'" "	option listen_addr '127.0.0.1'" "	option force_ip_family 'auto'")
doh_def=$(printf "%s\n" "" "config https-dns-proxy" "	option bootstrap_dns '1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001'" "	option resolver_url 'https://cloudflare-dns.com/dns-query'" "	option listen_port '5053'" "" "config https-dns-proxy" "	option bootstrap_dns '8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844'" "	option resolver_url 'https://dns.google/dns-query'" "	option listen_port '5054'")
doh_CLF=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://cloudflare-dns.com/dns-query'" "	option bootstrap_dns '1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001'"); doh_xbox=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://xbox-dns.ru/dns-query'"); doh_nullsproxy=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.nullsproxy.com/dns-query'")
doh_query=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.malw.link/dns-query'"); doh_comss=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.comss.one/dns-query'" "	option bootstrap_dns '92.38.152.163,93.115.24.204,2a03:90c0:56::1a5,2a02:7b40:5eb0:e95d::1'")
doh_mafioznik=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.mafioznik.xyz/dns-query'"); doh_astracat=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.astracat.ru/dns-query'")
doh_GOO=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.google/dns-query'" "	option bootstrap_dns '8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844'"); doh_Quad=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://dns.quad9.net/dns-query'" "	option bootstrap_dns '9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9'")
doh_queryCF=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://5u35p8m9i7.cloudflare-gateway.com/dns-query'"); doh_GEOHIDE_RU=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://geohide.ru/dns-query'")
doh_GEOHIDE_EU=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://eu.geohide.ru/dns-query'"); doh_GEOHIDE_US=$(printf "%s\n" "" "config https-dns-proxy" "	option resolver_url 'https://us.geohide.ru/dns-query'")
menu_GEOHIDE_DOH() { echo -e "\n${MAGENTA}Выберите сервер GeoHide DNS${NC}"; echo -e "${CYAN}1) ${GREEN}GeoHide ${NC}RU\n${CYAN}2) ${GREEN}GeoHide ${NC}EU\n${CYAN}3) ${GREEN}GeoHide ${NC}US\n${CYAN}Enter) ${GREEN}Отменить выбор${NC}\n"
echo -ne "${YELLOW}Выберите пункт:${NC} "; read -r c; case "$c" in 1) setup_doh "$doh_GEOHIDE_RU" "GeoHide RU";; 2) setup_doh "$doh_GEOHIDE_EU" "GeoHide EU";; 3) setup_doh "$doh_GEOHIDE_US" "GeoHide US";; esac; }
# ==========================================
# Доступ из браузера
# ==========================================
web_is_enabled() { command -v ttyd >/dev/null 2>&1 && uci -q get ttyd.@ttyd[0].command | grep -q "/usr/bin/zms"; }
toggle_web() { if web_is_enabled; then echo -e "\n${MAGENTA}Удаляем доступ из браузера${NC}"; $DELETE luci-app-ttyd >/dev/null 2>&1; $DELETE ttyd >/dev/null 2>&1; rm -f /etc/config/ttyd /etc/init.d/ttyd
echo -e "${GREEN}Доступ удалён!${NC}\n"; PAUSE; else echo -e "\n${MAGENTA}Активируем доступ из браузера${NC}"; update_packages || return 1
echo -e "${CYAN}Устанавливаем ${NC}ttyd"; $INSTALL ttyd >/dev/null 2>&1; $INSTALL luci-app-ttyd >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка при установке ttyd!${NC}\n"; PAUSE; return; }; echo -e "${CYAN}Настраиваем ${NC}ttyd"; sed -i 's#/bin/login#-t fontSize=15 sh /usr/bin/zms#' /etc/config/ttyd; /etc/init.d/ttyd restart >/dev/null 2>&1; if pidof ttyd >/dev/null
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
is_expert_mode() { [ -f "$EXPERT_MODE_FILE" ]; }; toggle_expert_mode() { [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; if is_expert_mode; then rm -f "$EXPERT_MODE_FILE"; echo -e "\nExpert mode ${GREEN}выключен!${NC}\n"; else echo 1 > "$EXPERT_MODE_FILE"; echo -e "\nExpert mode ${GREEN}включён!${NC}\n"; fi; PAUSE; }
sys_menu() { while true; do web_is_enabled && WEB_TEXT="Удалить доступ к скрипту из браузера" || WEB_TEXT="Активировать доступ к скрипту из браузера"; is_expert_mode && EXPERT_TEXT="${GREEN}Выключить${NC} expert mode" || EXPERT_TEXT="${GREEN}Включить${NC} expert mode"
quic_is_blocked && QUIC_TEXT="${GREEN}Отключить блокировку${NC} QUIC ${GREEN}${NC}" || QUIC_TEXT="${GREEN}Включить блокировку${NC} QUIC ${GREEN}${NC}"
CURR=$(curr_MIR); clear; OTSTUP=0; echo -e "${MAGENTA}Системное меню${NC}\n"; if [ -f "$DATE_FILE" ] && [ -f "$BACKUP_DIR/zapret.tar.gz" ] && [ -f "$BACKUP_DIR/zapret" ]; then CREATE_DATE=$(cat "$DATE_FILE"); echo -e "${YELLOW}Резервная копия:${NC} $CREATE_DATE" && OTSTUP=1; fi
is_expert_mode && echo -e "${YELLOW}Expert mode: ${GREEN}включён${NC}" && OTSTUP=1; if [ "$CURR" != "default / OpenWrt" ]; then echo -e "${YELLOW}Используется зеркало: ${NC}$CURR" && OTSTUP=1; fi
if web_is_enabled; then echo -e "${YELLOW}Доступ из браузера:${NC} $LAN_IP:7681" && OTSTUP=1; fi; if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then echo -e "${YELLOW}FIX для Flow Offloading:${NC} ${GREEN}включён${NC}" && OTSTUP=1; fi
if quic_is_blocked; then echo -e "${YELLOW}Блокировка QUIC: ${GREEN}включена${NC}" && OTSTUP=1; fi; if [ -f /etc/init.d/zapret ] && [ -f "$CONF" ] && grep -Eq "^[[:space:]]*option DISABLE_IPV6 '0'" "$CONF"; then echo -e "${YELLOW}IPv6 в Zapret: ${GREEN}включён${NC}" && OTSTUP=1; fi
[ "$OTSTUP" -eq 1 ] && echo; echo -e "${CYAN}1) ${GREEN}Системная информация${NC}\n${CYAN}2) ${GREEN}$WEB_TEXT${NC}\n${CYAN}3) ${GREEN}$QUIC_TEXT${NC}\n${CYAN}4) ${GREEN}Меню выбора зеркала ${NC}OpenWrt\n${CYAN}5) ${GREEN}Запустить${NC} blockcheck\n${CYAN}6) ${GREEN}Удалить ${NC}Zapret ${GREEN}& ${NC}Zapret2"
if [ -f "$DATE_FILE" ] && [ -f "$BACKUP_DIR/zapret.tar.gz" ] && [ -f "$BACKUP_DIR/zapret" ]; then CREATE_DATE=$(cat "$DATE_FILE"); echo -e "${CYAN}7) ${GREEN}Удалить резервную копию настроек${NC} Zapret"; else echo -e "${CYAN}7) ${GREEN}Сделать резервную копию настроек${NC} Zapret"; fi
if [ -f "$DATE_FILE" ] && [ -f "$BACKUP_DIR/zapret.tar.gz" ] && [ -f "$BACKUP_DIR/zapret" ]; then echo -e "${CYAN}8) ${GREEN}Восстановить настройки ${NC}Zapret${GREEN} из резервной копии${NC}"; fi
if [ -f /etc/init.d/zapret ] && [ -f "$CONF" ]; then if grep -Eq "^[[:space:]]*option DISABLE_IPV6 '0'" "$CONF"; then echo -e "${CYAN}9) ${GREEN}Выключить ${NC}IPv6${GREEN} в ${NC}Zapret"; elif grep -Eq "^[[:space:]]*option DISABLE_IPV6 '1'" "$CONF"; then
ping -6 -c 1 -W 2 google.com >/dev/null 2>&1 && echo -e "${CYAN}9) ${GREEN}Включить ${NC}IPv6${GREEN} в ${NC}Zapret"; fi; fi
FO=$(uci get firewall.@defaults[0].flow_offloading 2>/dev/null); FOHW=$(uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null); FIX=$(grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc && echo 1 || echo 0)
if [ "$FO" = 1 ] || [ "$FOHW" = 1 ] || [ "$FIX" = 1 ]; then if [ "$FIX" = 1 ]; then echo -e "${CYAN}0) ${GREEN}Отключить${NC} FIX ${GREEN}для${NC} Flow Offloading"; else echo -e "${CYAN}0) ${GREEN}Применить${NC} FIX ${GREEN}для${NC} Flow Offloading"; fi; fi
echo -e "${CYAN}i) ${GREEN}Меню исключений ${NC}IP${GREEN} из ${NC}Zapret\n${CYAN}e) ${GREEN}$EXPERT_TEXT${NC}"; echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read -r choiceMN; case "$choiceMN" in 1) Sys_Info;; 2) toggle_web;; 3) toggle_quic;; 4) menu_MIR;; e|Е|у|У) toggle_expert_mode;;
5) [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; continue; }; stop_zapret "1"; grep -q 'echo "Start Zapret"' /opt/zapret/blockcheck.sh || sed -i $'/^[[:space:]]*read A/a\\\t\techo "Start Zapret"; /etc/init.d/zapret restart >/dev/null 2>&1' /opt/zapret/blockcheck.sh
echo -e "${GREEN}Ctrl+C - oстановить blockcheck${NC}\n"; chmod +x /opt/zapret/blockcheck.sh; /opt/zapret/blockcheck.sh; start_zapret;; 6) uninstall_zapret_all;; 9) toggle_ipv6;; i|I|Ш|ш) Exclusions_menu;;
7) if [ -f "$DATE_FILE" ] && [ -f "$BACKUP_DIR/zapret.tar.gz" ] && [ -f "$BACKUP_DIR/zapret" ]; then CREATE_DATE=$(cat "$DATE_FILE"); delete_backup; else save_backup; fi;; 8) restore_backup ;;
0) FO=$(uci get firewall.@defaults[0].flow_offloading 2>/dev/null); FOHW=$(uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null); if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc; then echo -e "\n${MAGENTA}Отключаем FIX для Flow Offloading${NC}"
sed -i 's/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/meta l4proto { tcp, udp } flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc; fw4 restart >/dev/null 2>&1; echo -e "FIX ${GREEN}отключён!${NC}\n"; PAUSE; elif [ "$FO" = 1 ] || [ "$FOHW" = 1 ]; then echo -e "\n${MAGENTA}Применяем FIX для Flow Offloading${NC}"
sed -i 's/meta l4proto { tcp, udp } flow offload @ft;/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/' /usr/share/firewall4/templates/ruleset.uc; fw4 restart >/dev/null 2>&1; echo -e "FIX ${GREEN}успешно применён!${NC}\n"; PAUSE; fi;; *) return;; esac; done; }
toggle_ipv6() { [ ! -f /etc/init.d/zapret ] || [ ! -f "$CONF" ] && { echo -e "\n${RED}Zapret не установлен или отсутствует конфиг!${NC}\n"; PAUSE; return; }; if grep -q "option DISABLE_IPV6 '0'" "$CONF"; then
sed -i "s/option DISABLE_IPV6 '0'/option DISABLE_IPV6 '1'/" "$CONF"; echo -e "\n${MAGENTA}Выключаем IPv6 в Zapret${NC}"; ZAPRET_RESTART; echo -e "IPv6${GREEN} в ${NC}Zapret ${GREEN}выключен!${NC}\n"; PAUSE; return; fi
echo -e "\n${MAGENTA}Проверяем IPv6${NC}"; time=$(ping -6 -c 1 -W 2 google.com 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}'); if [ -z "$time" ]; then echo -e "Google IPv6: ${RED}FAIL${NC}\n"
echo -e "${RED}IPv6 недоступен! Включение не рекомендуется!${NC}\n"; PAUSE; return; fi; echo -e "Google IPv6: ${GREEN}OK ($time ms)${NC}\n"; sed -i "s/option DISABLE_IPV6 '1'/option DISABLE_IPV6 '0'/" "$CONF"
echo -e "\n${MAGENTA}Включаем IPv6 в Zapret${NC}"; ZAPRET_RESTART; echo -e "IPv6${GREEN} в ${NC}Zapret ${GREEN}включён!${NC}\n"; PAUSE; return; }
# ==========================================
# Hosts menu
# ==========================================
hosts_reset() { echo -e "\n${MAGENTA}Восстанавливаем hosts${NC}"; : > /etc/hosts; echo -e "127.0.0.1\tlocalhost\n\n::1\tlocalhost ip6-localhost ip6-loopback\nff02::1 ip6-allnodes\nff02::2 ip6-allrouters" > /etc/hosts; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "hosts ${GREEN}восстановлен!${NC}\n"; PAUSE; }
add_block() { printf '%b\n' "$1" | while IFS= read -r line; do [ -z "$line" ] && continue; grep -Fxq "$line" "$HOSTS_FILE" || echo "$line" >> "$HOSTS_FILE"; done; }
add_GEO_HOSTS() { echo -e "\n${MAGENTA}Заменяем hosts на GeoHide hosts${NC}"; : > /etc/hosts; echo -e "127.0.0.1\tlocalhost\n\n::1\tlocalhost ip6-localhost ip6-loopback\nff02::1 ip6-allnodes\nff02::2 ip6-allrouters" > /etc/hosts
wget -q -U "Mozilla/5.0" -O - "$GEO_HOSTS" >> /etc/hosts; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "hosts ${GREEN}заменён на ${NC}GeoHide hosts${GREEN}!${NC}\n"; PAUSE; }
remove_block() { printf '%b\n' "$1" | while IFS= read -r line; do [ -z "$line" ] && continue; sed -i "\|^$line$|d" "$HOSTS_FILE"; done; }
toggle_block() { if status_block "$1"; then remove_block "$1"; echo -e "\n${CYAN}Удаляем и применяем${NC}"; else add_block "$1"; echo -e "\n${CYAN}Добавляем и применяем${NC}"; fi; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "${GREEN}Изменения применены!${NC}\n"; PAUSE; }
toggle_all() { if status_block "$ALL_BLOCKS"; then remove_block "$ALL_BLOCKS"; echo -e "\n${CYAN}Удаляем и применяем${NC}"; else add_block "$ALL_BLOCKS"; echo -e "\n${CYAN}Добавляем и применяем${NC}"; fi; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "${GREEN}Изменения применены!${NC}\n"; PAUSE; }
get_state() { status_block "$1" && echo "Удалить " || echo "Добавить"; }
menu_hosts() { while true; do clear; S_ALL=$(status_block "$ALL_BLOCKS" && echo "${GREEN}Удалить все домены${NC}" || echo "${GREEN}Добавить все домены${NC}"); prin=0
echo -e "${MAGENTA}Меню управления доменами в hosts${NC}\n"; if hosts_enabled; then echo -e "${YELLOW}Домены в hosts: ${GREEN}$hosts_echo${NC}"; prin=1; fi; [ "$prin" -eq 1 ] && echo
echo -e "${CYAN} 0) ${GREEN}$(get_state "$NALOG")${NC} nalog.ru\n${CYAN} 1) ${GREEN}$(get_state "$RUTOR")${NC} rutor.info\n${CYAN} 2) ${GREEN}$(get_state "$NTC")${NC} ntc.party"
echo -e "${CYAN} 3) ${GREEN}$(get_state "$INSTAGRAM")${NC} Instagram & Facebook\n${CYAN} 4) ${GREEN}$(get_state "$LIBRUSEC")${NC} lib.rus.ec\n${CYAN} 5) ${GREEN}$(get_state "$AI")${NC} AI сервисы"
echo -e "${CYAN} 6) ${GREEN}$(get_state "$TWCH")${NC} Twitch\n${CYAN} 7) ${GREEN}$(get_state "$TGWeb")${NC} Telegram Web\n${CYAN} 8) ${GREEN}$(get_state "$SPFY")${NC} Spotify\n${CYAN} 9) ${GREEN}$(get_state "$SPFYEXT")${NC} Spotify extended"
echo -e "${CYAN}10) ${GREEN}$(get_state "$SCell")${NC} Supercell\n${CYAN}11) ${GREEN}$(get_state "$GITH_RAW")${NC} githubusercontent.com\n${CYAN}12) ${GREEN}$(get_state "$GITH")${NC} github.com\n${CYAN}13) ${GREEN}$(get_state "$USoft")${NC} Ubisoft"
echo -e "${CYAN}14) ${GREEN}$(get_state "$TAPEop")${NC} tapeop.dev\n${CYAN}15) $S_ALL\n${CYAN}16) ${GREEN}Заменить ${NC}hosts${GREEN} на ${NC}GeoHide hosts"
echo -e "${CYAN}17) ${GREEN}Заменить ${NC}hosts${GREEN} на ${NC}Mafioznik hosts\n${CYAN}18) ${GREEN}Заменить ${NC}hosts${GREEN} на ${NC}Malw.link hosts\n${CYAN}19) ${GREEN}Восстановить ${NC}hosts"
echo -ne "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n\n${YELLOW}Выберите пункт:${NC} ";read -r c; case "$c" in 0) toggle_block "$NALOG";; 1) toggle_block "$RUTOR";; 2) toggle_block "$NTC";; 3) toggle_block "$INSTAGRAM";;
4) toggle_block "$LIBRUSEC";; 5) toggle_block "$AI";; 6) toggle_block "$TWCH";; 7) toggle_block "$TGWeb";; 8) toggle_block "$SPFY";; 9) toggle_block "$SPFYEXT";; 10) toggle_block "$SCell";; 11) toggle_block "$GITH_RAW";; 12) toggle_block "$GITH";;
13) toggle_block "$USoft";; 14) toggle_block "$TAPEop";; 15) toggle_all;; 16) menu_GEO_HOSTS;; 17) echo -e "\n${MAGENTA}Заменяем hosts на Mafioznik hosts${NC}"; wget -qO /etc/hosts ${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/hosts_mafioznik.txt >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось скачать файл hosts${NC}\n"; PAUSE; }
/etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "hosts ${GREEN}заменён на ${NC}Mafioznik hosts${GREEN}!${NC}\n"; PAUSE;; 18) echo -e "\n${MAGENTA}Заменяем hosts на Malw.link hosts${NC}"
wget -qO /etc/hosts ${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/hosts_malw.link.txt >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось скачать файл hosts${NC}\n"; PAUSE; }
/etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "hosts ${GREEN}заменён на ${NC}Malw.link hosts${GREEN}!${NC}\n"; PAUSE;; 19) hosts_reset;; *) break;; esac; done; }
status_block() { local line; while IFS= read -r line; do [ -z "$line" ] && continue; grep -Fxq "$line" "$HOSTS_FILE" || return 1; done <<EOF
$(printf '%b\n' "$1")
EOF
}
menu_GEO_HOSTS() {
    while true; do
        echo -e "\n${MAGENTA}Выберите сервер GeoHide${NC}"
        echo -e "${CYAN}1) ${GREEN}GeoHide ${NC}RU"
        echo -e "${CYAN}2) ${GREEN}GeoHide ${NC}EU"
        echo -e "${CYAN}3) ${GREEN}GeoHide ${NC}US"
        echo -e "${CYAN}Enter) ${GREEN}Отменить выбор${GREEN}${NC}\n"
        echo -ne "${YELLOW}Выберите пункт:${NC} "
        read -r c
        case "$c" in
            1) GEO_FILE="$GH_RAW/StressOzz/Zapret-Manager/refs/heads/main/files/GeoHide_hosts_RU"; GEO_NAME="RU";;
            2) GEO_FILE="$GH_RAW/StressOzz/Zapret-Manager/refs/heads/main/files/GeoHide_hosts_EU"; GEO_NAME="EU";;
            3) GEO_FILE="$GH_RAW/StressOzz/Zapret-Manager/refs/heads/main/files/GeoHide_hosts_US"; GEO_NAME="US";;
            *) break;;
        esac
        echo -e "\n${MAGENTA}Заменяем hosts на GeoHide ${GEO_NAME} hosts${NC}"
        GEO_TMP="/tmp/GeoHide_hosts"
        if wget -q -U "Mozilla/5.0" -O "$GEO_TMP" "$GEO_FILE" >/dev/null 2>&1 &&
           [ -s "$GEO_TMP" ]; then
            mv "$GEO_TMP" /etc/hosts
            /etc/init.d/dnsmasq restart >/dev/null 2>&1
            echo -e "hosts ${GREEN}заменён на ${NC}GeoHide ${GEO_NAME} hosts${GREEN}!${NC}\n"
        else
            rm -f "$GEO_TMP"
            echo -e "\n${RED}Не удалось скачать GeoHide ${GEO_NAME} hosts${NC}\n"
        fi
        PAUSE
        return
    done
}
# ==========================================
# Тест стратегий
# ==========================================
show_domain_results(){ clear; echo -e "${MAGENTA}Результат тестирования по домену${NC}\n"; FILE="$RES_DOMAIN"; [ ! -s "$FILE" ] && { echo -e "${RED}Результат не найден!${NC}\n"; PAUSE; return; }
while IFS= read -r line; do if echo "$line" | grep -q "^Контрольный тест"; then LEFT=$(echo "$line" | cut -d'→' -f1); RIGHT=$(echo "$line" | cut -d'→' -f2); RIGHT_CLEAN=$(echo "$RIGHT" | tr -cd '0-9/')
OK=$(echo "$RIGHT_CLEAN" | cut -d'/' -f1); TOTAL=$(echo "$RIGHT_CLEAN" | cut -d'/' -f2); [ -z "$OK" ] && OK=0; [ -z "$TOTAL" ] && TOTAL=0; if [ "$OK" -eq "$TOTAL" ] && [ "$TOTAL" -ne 0 ]; then COLOR="$GREEN"
elif [ "$OK" -eq 0 ]; then COLOR="$RED"; else COLOR="$YELLOW"; fi; echo -e "${CYAN}${LEFT}→ ${COLOR}${OK}/${TOTAL}${NC}"; continue; fi; if echo "$line" | grep -q "→"; then LEFT=$(echo "$line" | cut -d'→' -f1)
RIGHT=$(echo "$line" | cut -d'→' -f2); RIGHT_CLEAN=$(echo "$RIGHT" | tr -cd '0-9/'); OK=$(echo "$RIGHT_CLEAN" | cut -d'/' -f1); TOTAL=$(echo "$RIGHT_CLEAN" | cut -d'/' -f2); [ -z "$OK" ] && OK=0
[ -z "$TOTAL" ] && TOTAL=0; if [ "$OK" -eq "$TOTAL" ] && [ "$TOTAL" -ne 0 ]; then COLOR="$GREEN"; elif [ "$OK" -eq 0 ]; then COLOR="$RED"; else COLOR="$YELLOW"; fi; echo -e "${LEFT}→ ${COLOR}${OK}/${TOTAL}${NC}"; continue; fi
if echo "$line" | grep -q "\[ OK \]"; then echo -e "${GREEN}${line}${NC}"; elif echo "$line" | grep -q "\[FAIL\]"; then echo -e "${RED}${line}${NC}"; else echo "$line"; fi; done < "$FILE"; PAUSE; }
run_test_by_domain() { MODE="domain"; clear; echo -e "${MAGENTA}Тестирование стратегий по домену${NC}\n\n${CYAN}Введите один или несколько доменов через пробел (${NC}x.com vk.com${CYAN})${NC}\n"; echo -ne "${YELLOW}Введите домен: ${NC}"; read -r INPUT
INPUT="$(printf "%s" "$INPUT" | tr -s ' ')"; [ -z "$INPUT" ] && return; URLS=""; COUNT=0; for item in $INPUT; do item="$(printf "%s" "$item" | tr -d ' \t\r\n')"; [ -z "$item" ] && continue; case "$item" in http://*|https://*) TARGET="$item" ;; *) TARGET="https://$item" ;; esac
HOST=$(printf "%s\n" "$TARGET" | sed -E 's#^https?://##; s#/.*##'); URLS="${URLS}${HOST}|https://${HOST}/"$'\n'; COUNT=$((COUNT+1)); done; TOTAL="$COUNT"; [ "$TOTAL" -eq 0 ] && { echo -e "\n${RED}Домены введены неверно${NC}\n"; PAUSE; return; }
RESULTS="$RES_DOMAIN"; : > "$RESULTS"; : > "$STR_FILE"; cp "$CONF" "$BACK"; echo -e "\n${CYAN}Собираем ${NC}Flowseal${CYAN} стратегии${NC}"; download_strategies 1; cp "$OUT" "$STR_FILE"
echo -e "${CYAN}Собираем ${NC}v${CYAN} стратегии${NC}"; for N in $(seq 1 100); do strategy_v$N >> "$STR_FILE" 2>/dev/null || break; done; sed -i '/#Y/d' "$STR_FILE"; LINES=$(grep -n '^#' "$STR_FILE" | cut -d: -f1); CUR=0; TOTAL_STR=$(grep -c '^#' "$STR_FILE")
echo -e "${CYAN}Найдено стратегий:${NC} $TOTAL_STR\n${CYAN}Доменов для теста:${NC} $TOTAL"; check_zpr_off; echo "$LINES" | while read -r START; do CUR=$((CUR+1)); NEXT=$(echo "$LINES" | awk -v s="$START" '$1>s{print;exit}'); if [ -z "$NEXT" ]; then
sed -n "${START},\$p" "$STR_FILE" > "$TEMP_FILE"; else sed -n "${START},$((NEXT-1))p" "$STR_FILE" > "$TEMP_FILE"; fi; BLOCK=$(cat "$TEMP_FILE"); NAME=$(head -n1 "$TEMP_FILE"); NAME="${NAME#\#}"; awk -v block="$BLOCK" 'BEGIN{skip=0}
/option NFQWS_OPT '\''/ {printf "\toption NFQWS_OPT '\''\n%s\n'\''\n", block; skip=1; next}
skip && /^'\''$/ {skip=0; next}
!skip {print}' "$CONF" > "${CONF}.tmp"; mv "${CONF}.tmp" "$CONF"; echo -e "\n${CYAN}Тестируем стратегию:${NC} ${YELLOW}${NAME}${NC} ($CUR/$TOTAL_STR)"; ZAPRET_RESTART; OK=0;
LOG_TMP="/tmp/zapret_log_${CUR}"; : > "$LOG_TMP"; check_all_urls; if [ "$OK" -eq 0 ]; then COLOR="${RED}"; elif [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; else COLOR="${YELLOW}"; fi; echo -e "${CYAN}Результат теста:${NC} ${COLOR}$OK/$TOTAL${NC}"
{ echo "${NAME} → ${OK}/${TOTAL}"; cat "$LOG_TMP"; echo; } >> "$RESULTS"; done; [ -f "$BACK" ] && mv -f "$BACK" "$CONF"; ZAPRET_RESTART; show_single_result "$RESULTS"; }
check_zpr_off() { echo -e "\n${CYAN}Контрольный тест: ${YELLOW}Zapret выключен${NC}"; /etc/init.d/zapret stop >/dev/null 2>&1; OK=0; LOG_TMP="/tmp/zapret_log_${CUR}"; : > "$LOG_TMP"; check_all_urls
if [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; elif [ "$OK" -ge $((TOTAL/2)) ]; then COLOR="${YELLOW}"; else COLOR="${RED}"; fi; echo -e "${CYAN}Результат теста: ${COLOR}$OK/$TOTAL${NC}"
if [ "$MODE" = "domain" ]; then { echo "Контрольный тест (Zapret выключен) → ${OK}/${TOTAL}"; cat "$LOG_TMP"; echo; } >> "$RESULTS"; else echo "Контрольный тест (Zapret выключен) → ${OK}/${TOTAL}" >> "$RESULTS"; fi; /etc/init.d/zapret start >/dev/null 2>&1; }
check_url() { TEXT=$(echo "$1" | cut -d"|" -f1); LINK=$(echo "$1" | cut -d"|" -f2); if curl -sL --connect-timeout 4 --max-time 6 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "$LINK" >/dev/null 2>&1; then echo 1 >> "$TMP_OK"; echo -e "${GREEN}[ OK ]${NC} $TEXT"; echo "[ OK ] $TEXT" >> "$LOG_TMP"; else echo -e "${RED}[FAIL]${NC} $TEXT";echo "[FAIL] $TEXT" >> "$LOG_TMP"; fi; }
check_all_urls() { TMP_OK="$TMP_SF/z_ok.$$"; : > "$TMP_OK"; RUN=0; while IFS= read -r URL; do [ -z "$URL" ] && continue; check_url "$URL" & RUN=$((RUN+1)); if [ "$RUN" -ge "$PARALLEL" ]; then wait; RUN=0; fi
done <<EOF
$URLS
EOF
wait; OK=$(wc -l < "$TMP_OK" | tr -d ' '); rm -f "$TMP_OK"; }
prepare_urls() { : > "$OUT_DPI"; printf '%s\n' "gosuslugi.ru|https://www.gosuslugi.ru" "esia.gosuslugi.ru|https://esia.gosuslugi.ru" "nalog.ru|https://nalog.ru" "lkfl2.nalog.ru|https://lkfl2.nalog.ru" "rutube.ru|https://rutube.ru" "ntc.party|https://ntc.party/" "instagram.com|https://instagram.com" "facebook.com|https://facebook.com" "rutor.info|https://rutor.info" "rutracker.org|https://rutracker.org" \
"epidemz.net.co|https://epidemz.net.co" "nnmclub.to|https://nnmclub.to" "openwrt.org|https://openwrt.org" "sxyprn.net|https://sxyprn.net" "spankbang.com|https://ru.spankbang.com" "pornhub.com|https://pornhub.com" "discord.com|https://discord.com" "x.com|https://x.com" "filmix.my|https://filmix.my" "flightradar24.com|https://flightradar24.com" "play.google.com|https://play.google.com" \
"anitokyo.tv|https://anitokyo.tv" "cub.red|https://cub.red" "downloads.openwrt.org|https://downloads.openwrt.org" "githubusercontent.com|https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/Zapret-Manager.sh" >> "$OUT_DPI"
curl -fsSL "$RAW" | sed -n 's/.*"id":[[:space:]]*"\([^"]*\)".*"host":[[:space:]]*"\([^"]*\)".*/\1|\2/p' >> "$OUT_DPI" || { echo -e "\n${RED}Ошибка загрузки DPI списка${NC}\n"; PAUSE; return 1; }; TOTAL=$(grep -c "|" "$OUT_DPI"); }
check_current_strategy() { clear; echo -e "${MAGENTA}Тестирование текущей стратегии${NC}\n"; prepare_urls; URLS="$(cat "$OUT_DPI")"; OK=0; URLS="$(cat "$OUT_DPI")"; TOTAL=$(grep -c "|" "$OUT_DPI"); echo -e "${CYAN}Доменов для теста:${NC} $TOTAL\n"; LOG_TMP="/tmp/zapret_log_${CUR}"; : > "$LOG_TMP"
check_all_urls; if [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; elif [ "$OK" -ge $((TOTAL/2)) ]; then COLOR="${YELLOW}"; else COLOR="${RED}"; fi; echo -e "\n${CYAN}Результат теста: ${COLOR}$OK/$TOTAL${NC}\n"; rm -f "$OUT_DPI"; PAUSE; }
show_test_results() { clear; echo -e "${MAGENTA}Результаты тестирования стратегий${NC}\n"; TMP_RES="/tmp/zapret_results_show.$$"; : > "$TMP_RES"; if [ -s "$RES3" ]; then cat "$RES3" > "$TMP_RES"; else [ -s "$RES1" ] && cat "$RES1" >> "$TMP_RES"
[ -s "$RES2" ] && cat "$RES2" >> "$TMP_RES"; [ ! -s "$TMP_RES" ] && { rm -f "$TMP_RES"; echo -e "${RED}Результаты не найдены!${NC}\n"; PAUSE; return; }; fi; awk '!seen && /^Контрольный тест/ {print; seen=1; next} !/^Контрольный тест/ {print}' "$TMP_RES" > "${TMP_RES}.u"
mv "${TMP_RES}.u" "$TMP_RES"; TOTAL=$(head -n1 "$TMP_RES" | cut -d'/' -f2); awk -F'[/ ]' '{for(i=1;i<=NF;i++) if($i~/^[0-9]+$/){print $i "/" $(i+1), $0; break}}' "$TMP_RES" | sort -nr -k1,1 | while read -r line; do COUNT=$(echo "$line" | awk -F'/' '{print $1}')
TEXT=$(echo "$line" | cut -d' ' -f2-); if echo "$TEXT" | grep -q Zapret; then COLOR="$CYAN"; elif [ "$COUNT" -eq "$TOTAL" ]; then COLOR="$GREEN"; elif [ "$COUNT" -gt $((TOTAL/2)) ]; then COLOR="$YELLOW"; else COLOR="$RED"; fi
echo -e "${COLOR}${TEXT}${NC}"; done; rm -f "$TMP_RES"; echo; PAUSE; }
show_single_result() { clear; echo -e "${MAGENTA}Результат тестирования стратегии${NC}\n"; local FILE="$1"; [ ! -s "$FILE" ] && { echo -e "${RED}Результат не найден!${NC}\n"; [ -z "$NO_PAUSE" ] && PAUSE; return; }; TMP_RES="/tmp/zapret_results_single.$$"
cat "$FILE" > "$TMP_RES"; awk '!seen && /^Контрольный тест/ {print; seen=1; next} !/^Контрольный тест/ {print}' "$TMP_RES" > "${TMP_RES}.u"; mv "${TMP_RES}.u" "$TMP_RES"; TOTAL=$(head -n1 "$TMP_RES" | cut -d'/' -f2); awk -F'[/ ]' '{for(i=1;i<=NF;i++) if($i~/^[0-9]+$/){print $i "/" $(i+1), $0; break}}' "$TMP_RES" |
sort -nr -k1,1 | while read -r line; do COUNT=$(echo "$line" | awk -F'/' '{print $1}'); TEXT=$(echo "$line" | cut -d' ' -f2-); if echo "$TEXT" | grep -q Zapret; then COLOR="$CYAN"; elif [ "$COUNT" -eq "$TOTAL" ]; then COLOR="$GREEN"; elif [ "$COUNT" -gt $((TOTAL/2)) ]; then
COLOR="$YELLOW"; else COLOR="$RED"; fi; echo -e "${COLOR}${TEXT}${NC}"; done; rm -f "$TMP_RES"; [ -z "$NO_PAUSE" ] && echo && PAUSE; }
run_test_flowseal() { clear; echo -e "${MAGENTA}Тестирование стратегий Flowseal${NC}\n\n${CYAN}Собираем стратегии для теста${NC}"; RESULTS="/opt/zapret/tmp/results_flowseal.txt"; rm -rf "$TMP_SF"
download_strategies 1; cp "$OUT" "$STR_FILE"; cp "$CONF" "$BACK"; sed -i '/#Y/d' "$STR_FILE"; run_test_core "$RESULTS"; }
run_test_versions() { clear; echo -e "${MAGENTA}Тестирование стратегий v${NC}\n\n${CYAN}Собираем стратегии для теста${NC}"; RESULTS="/opt/zapret/tmp/results_versions.txt"; : > "$STR_FILE"; cp "$CONF" "$BACK"
for N in $(seq 1 100); do strategy_v$N >> "$STR_FILE" 2>/dev/null || break; done; sed -i '/#Y/d' "$STR_FILE"; run_test_core "$RESULTS"; }
run_all_tests() { clear; echo -e "${MAGENTA}Тестирование всех стратегий${NC}\n"; RESULTS="/opt/zapret/tmp/results_all.txt"; : > "$STR_FILE"; [ -f "$BACK" ] || cp "$CONF" "$BACK"; echo -e "${CYAN}Собираем ${NC}Flowseal${CYAN} стратегии${NC}"
download_strategies 1; cat "$OUT" >> "$STR_FILE"; echo -e "${CYAN}Собираем ${NC}v${CYAN} стратегии${NC}"; for N in $(seq 1 100); do strategy_v$N >> "$STR_FILE" 2>/dev/null || break; done; sed -i '/#Y/d' "$STR_FILE"; LINES=$(grep -n '^#' "$STR_FILE" | cut -d: -f1)
CUR=0; TOTAL_STR=$(grep -c '^#' "$STR_FILE"); echo -e "${CYAN}Найдено стратегий:${NC} $TOTAL_STR"; prepare_urls || return 1; URLS="$(cat "$OUT_DPI")"; TOTAL=$(grep -c "|" "$OUT_DPI"); echo -e "${CYAN}Доменов для теста:${NC} $TOTAL"
check_zpr_off; echo "$LINES" | while read -r START; do CUR=$((CUR+1)); NEXT=$(echo "$LINES" | awk -v s="$START" '$1>s{print;exit}'); if [ -z "$NEXT" ]; then sed -n "${START},\$p" "$STR_FILE" > "$TEMP_FILE"; else sed -n "${START},$((NEXT-1))p" "$STR_FILE" > "$TEMP_FILE"; fi
BLOCK=$(cat "$TEMP_FILE"); NAME=$(head -n1 "$TEMP_FILE"); NAME="${NAME#\#}"; awk -v block="$BLOCK" 'BEGIN{skip=0}
/option NFQWS_OPT '\''/ {printf "\toption NFQWS_OPT '\''\n%s\n'\''\n", block; skip=1; next}
skip && /^'\''$/ {skip=0; next}
!skip {print}' "$CONF" > "${CONF}.tmp" && mv "${CONF}.tmp" "$CONF"; echo -e "\n${CYAN}Тестируем стратегию:${NC} ${YELLOW}${NAME}${NC} ($CUR/$TOTAL_STR)"; ZAPRET_RESTART; OK=0; LOG_TMP="/tmp/zapret_log_${CUR}"; : > "$LOG_TMP"; check_all_urls
if [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; elif [ "$OK" -ge $((TOTAL/2)) ]; then COLOR="${YELLOW}"; else COLOR="${RED}"; fi; echo -e "${CYAN}Результат:${NC} ${COLOR}$OK/$TOTAL${NC}"; { echo "${NAME} → ${OK}/${TOTAL}"; cat "$LOG_TMP"; echo; } >> "$RESULTS"; done
sort -t'/' -k1 -nr "$RESULTS" -o "$RESULTS"; [ -f "$BACK" ] && mv -f "$BACK" "$CONF"; ZAPRET_RESTART; show_single_result "$RESULTS"; }
run_test_core() { local RESULTS="$1"; prepare_urls || return 1; URLS="$(cat "$OUT_DPI")"; TOTAL=$(grep -c "|" "$OUT_DPI"); TOTAL_STR=$(grep -c '^#' "$STR_FILE")
echo -e "${CYAN}Найдено стратегий: ${NC}$TOTAL_STR"; echo -e "${CYAN}Доменов для теста:${NC} $TOTAL"; : > "$RESULTS"; check_zpr_off; LINES=$(grep -n '^#' "$STR_FILE" | cut -d: -f1); CUR=0
echo "$LINES" | while read START; do CUR=$((CUR+1)); NEXT=$(echo "$LINES" | awk -v s="$START" '$1>s{print;exit}'); if [ -z "$NEXT" ]; then
sed -n "${START},\$p" "$STR_FILE" > "$TEMP_FILE"; else sed -n "${START},$((NEXT-1))p" "$STR_FILE" > "$TEMP_FILE"; fi
BLOCK=$(cat "$TEMP_FILE"); NAME=$(head -n1 "$TEMP_FILE"); NAME="${NAME#\#}"; awk -v block="$BLOCK" 'BEGIN{skip=0}
/option NFQWS_OPT '\''/ {printf "\toption NFQWS_OPT '\''\n%s\n'\''\n", block; skip=1; next}
skip && /^'\''$/ {skip=0; next}
!skip {print}' "$CONF" > "${CONF}.tmp"; mv "${CONF}.tmp" "$CONF"; echo -e "\n${CYAN}Тестируем стратегию: ${YELLOW}${NAME}${NC} ($CUR/$TOTAL_STR)"; ZAPRET_RESTART; OK=0; LOG_TMP="/tmp/zapret_log_${CUR}"; : > "$LOG_TMP"; check_all_urls
if [ "$OK" -eq "$TOTAL" ]; then COLOR="${GREEN}"; elif [ "$OK" -ge $((TOTAL/2)) ]; then COLOR="${YELLOW}"; else COLOR="${RED}"; fi; echo -e "${CYAN}Результат теста: ${COLOR}$OK/$TOTAL${NC}"; echo -e "${NAME} → ${OK}/${TOTAL}" >> "$RESULTS"; done
sort -t'/' -k1 -nr "$RESULTS" -o "$RESULTS"; mv -f "$BACK" "$CONF"; rm -f "$OUT_DPI"; ZAPRET_RESTART; [ -z "$NO_PAUSE" ] && show_single_result "$RESULTS"; }
TEST_CUSTOM() { if [ ! -f "$CUSTOM_STR_FILE" ]; then echo -e "\n${RED}Файл ${NC}$CUSTOM_STR_FILE${RED} не найден!${NC}\n"; PAUSE; return; fi; if [ ! -s "$CUSTOM_STR_FILE" ]; then echo -e "\n${RED}Файл ${NC}$CUSTOM_STR_FILE ${RED}пустой!${NC}\n"; PAUSE; return; fi
if ! grep -q '^#' "$CUSTOM_STR_FILE"; then echo -e "\n${RED}В файле не найдено ни одной стратегии!${NC}\n\n${YELLOW}Каждая стратегия должна начинаться со строки ${NC}#Название${NC}\n${CYAN}Пример содержимого ${NC}$CUSTOM_STR_FILE${CYAN}:${NC}\n#Strategy1\n--filter-tcp=443\n--dpi-desync=fake\n. . .\n#Strategy2\n--filter-tcp=443\n--dpi-desync=multidisorder\n. . .\n"; PAUSE; return; fi
clear; mkdir -p "$TMP_SF"; echo -e "${MAGENTA}Тестирование пользовательских стратегий${NC}\n"; rm -f "$RES_CUSTOM"; sed -i 's/\r$//' "$CUSTOM_STR_FILE"; sed -i '/^[[:space:]]*$/d' "$CUSTOM_STR_FILE"; sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "$CUSTOM_STR_FILE"; : > "$CUSTOM_RESULTS"
OLD_STR_FILE="$STR_FILE"; OLD_RESULTS="$RESULTS"; OLD_BACK="$BACK"; OLD_MODE="$MODE"; STR_FILE="$CUSTOM_STR_FILE"; RESULTS="$CUSTOM_RESULTS"; BACK="$CUSTOM_BACK"; MODE="custom"; cp "$CONF" "$CUSTOM_BACK"; run_test_core "$CUSTOM_RESULTS"; STR_FILE="$OLD_STR_FILE"; RESULTS="$OLD_RESULTS"; BACK="$OLD_BACK"; MODE="$OLD_MODE"; rm -f "$OUT_DPI"; [ -f "$CUSTOM_BACK" ] && mv -f "$CUSTOM_BACK" "$CONF"; ZAPRET_RESTART; }
TEST_menu() { [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; while true; do show_current_strategy; RKN_Check; MODE="normal"; clear; echo -e "${MAGENTA}Меню тестирования стратегий${NC}\n"; 
INFO_ZPR_STR; STATUS_V=""; STATUS_FLOW=""; STATUS_DOMAIN=""; if [ -s "$RES3" ]; then STATUS_V="${GREEN}v${NC}"; STATUS_FLOW="${GREEN}Flowseal${NC}"; elif [ -s "$RES2" ] || [ -s "$RES1" ]; then [ -s "$RES2" ] && STATUS_V="${GREEN}v${NC}" || STATUS_V="${RED}v${NC}"
[ -s "$RES1" ] && STATUS_FLOW="${GREEN}Flowseal${NC}" || STATUS_FLOW="${RED}Flowseal${NC}"; else STATUS_V="${RED}v${NC}"; STATUS_FLOW="${RED}Flowseal${NC}"; fi; [ -s "$RES_DOMAIN" ] && STATUS_DOMAIN="${GREEN}Domain${NC}" || STATUS_DOMAIN="${RED}Domain${NC}"; [ -s "$RES_CUSTOM" ] && STATUS_CUSTOM="${GREEN}Custom${NC}" || STATUS_CUSTOM="${RED}Custom${NC}"; [ -s "$RES_YOUTUBE" ] && STATUS_YOUTUBE="${GREEN}YouTube${NC}" || STATUS_YOUTUBE="${RED}YouTube${NC}"
[ -f /root/custom_test.txt ] && echo -e "${YELLOW}/root/custom_test.txt:  ${GREEN}присутствует${NC}"; echo -e "${YELLOW}Тест пройден:${NC} ${STATUS_V} | ${STATUS_FLOW} | ${STATUS_DOMAIN} | ${STATUS_CUSTOM} | ${STATUS_YOUTUBE}"
echo -e "\n${CYAN}1) ${GREEN}Тестирование стратегий ${NC}v ${GREEN}/${NC} Flowseal${NC}\n${CYAN}2) ${GREEN}Тестировать ${NC}текущую${GREEN} стратегию ${NC}\n${CYAN}3) ${GREEN}Тестировать стратегии ${NC}по домену${NC}"
echo -e "${CYAN}4) ${GREEN}Тестировать стратегии для ${NC}YouTube\n${CYAN}5) ${GREEN}Тестировать стратегии из ${NC}/root/custom_test.txt\n${CYAN}6) ${GREEN}Меню автоподбора стратегий по расписанию${NC}"
if [ -s "$RES_DOMAIN" ]; then echo -e "${CYAN}7) ${GREEN}Результаты тестирования ${NC}по домену"; fi; if [ -s "$RES1" ] || [ -s "$RES2" ] || [ -s "$RES3" ]; then echo -e "${CYAN}8) ${GREEN}Результаты тестирования стратегий${NC}"; fi
if [ -s "$RES_YOUTUBE" ]; then echo -e "${CYAN}9) ${GREEN}Результаты тестирования ${NC}YouTube"; fi; if [ -s "$RES_CUSTOM" ]; then echo -e "${CYAN}0) ${GREEN}Результаты тестирования ${NC}Custom${GREEN} стратегий${NC}"; fi
if [ -s "$RES1" ] || [ -s "$RES2" ] || [ -s "$RES3" ] || [ -s "$RES_DOMAIN" ] || [ -s "$RES_CUSTOM" ] || [ -s "$RES_YOUTUBE" ]; then echo -e "${CYAN}10) ${GREEN}Удалить результаты тестирования${NC}"; fi
echo -ne "${CYAN}Enter) ${GREEN}Выход в меню стратегий${NC}\n\n${YELLOW}Выберите пункт:${NC} ";read -r t; case "$t" in 1) TEST_STRATEGY_MENU;; 2) check_current_strategy;; 3) run_test_by_domain;; 4) YOUTUBE_TEST_MENU;; 5) TEST_CUSTOM;; 6) AUTO_BEST_MENU;; 0) show_single_result "$RES_CUSTOM";; 9) show_single_result "$RES_YOUTUBE";;
7) show_domain_results;; 8) show_test_results;;  10) rm -f /opt/zapret/tmp/results*; echo -e "\n${GREEN}Результаты тестирования удалены!${NC}\n"; PAUSE;; *) break;; esac; done; }
TEST_STRATEGY_MENU() { echo -e "\n${MAGENTA}Выберите стратегии для тестирования${NC}"; echo -e "${CYAN}1) ${GREEN}Тестировать стратегии ${NC}v\n${CYAN}2) ${GREEN}Тестировать стратегии ${NC}Flowseal"
echo -e "${CYAN}3) ${GREEN}Тестировать ${NC}v${GREEN} и ${NC}Flowseal${GREEN} стратегии${NC}\n${CYAN}Enter) ${GREEN}Выход в меню тестирования стратегий${NC}\n"; echo -ne "${YELLOW}Выберите пункт:${NC} "
read -r t; case "$t" in 1) rm -f "$RES3"; run_test_versions ;; 2) rm -f "$RES3"; run_test_flowseal ;; 3) rm -f "$RES1" "$RES2" "$RES3"; run_all_tests ;; *) return ;; esac; }
# ==========================================
# Системная информация
# ==========================================
Sys_Info() { get_versions; get_doh_status; show_current_strategy; RKN_Check; clear; echo -e "${GREEN}===== Информация о системе =====${NC}"; FREEMEM="$(df -h /tmp / 2>/dev/null | awk 'NR==2{printf "/tmp : used %-6s free %-6s\n",$3,$4} NR==3{printf "   /root: used %-6s free %-6s\n",$3,$4}')"
OWRT="$(grep '^DISTRIB_RELEASE=' /etc/openwrt_release 2>/dev/null | cut -d"'" -f2)"; echo -e "Model   : $MODEL\nArch    : $ARCH_FULL\nOpenWrt : $OWRT\nStorage :\n   $FREEMEM"; echo -e "\n${GREEN}===== Пользовательские пакеты =====${NC}"
if [ "$PKG_IS_APK" -eq 1 ]; then apk info -v 2>/dev/null | awk 'BEGIN{grp[""]=0}{pkg=$1; gsub(/^(luci-(app|mod|proto|theme)-|kmod-|lib|ucode-mod-)/,"",pkg); grp[pkg]=grp[pkg]?grp[pkg]"\n"$1:$1}END{for(k in grp){n=split(grp[k],a,"\n");if(n<2) continue;for(i=1;i<=n;i++)for(j=i+1;j<=n;j++)if(a[i]>a[j]){t=a[i];a[i]=a[j];a[j]=t}for(i=1;i<=n;i+=2)if(i+1<=n){L=a[i];R=a[i+1];if(L~/^luci-/&&R!~/^luci-/){t=L;L=R;R=t}print L" | "R}else print a[i]}}'
else awk '/^Package:/{p=$2}/^Status: install user/{k=p;sub(/^(luci-(app|mod|proto|theme)-|kmod-|lib|ucode-mod-)/,"",k);grp[k]=grp[k]?grp[k]"\n"p:p}END{for(k in grp){n=split(grp[k],a,"\n");if(n<2)continue;for(i=1;i<=n;i++)for(j=i+1;j<=n;j++)if(a[i]>a[j]){t=a[i];a[i]=a[j];a[j]=t}for(i=1;i<=n;i+=2)if(i+1<=n){L=a[i];R=a[i+1];if(L~/^luci-/&&R!~/^luci-/){t=L;L=R;R=t}print L" | "R}else print a[i]}for(k in grp){n=split(grp[k],a,"\n");if(n==1)single[++s]=a[1]}for(i=1;i<=s;i++)for(j=i+1;j<=s;j++)if(length(single[i])<length(single[j])||(length(single[i])==length(single[j])&&single[i]>single[j])){t=single[i];single[i]=single[j];single[j]=t}half=int((s+1)/2);for(i=1;i<=half;i++){j=s-i+1;if(i<j){L=single[i];R=single[j];if(L~/^luci-/&&R!~/^luci-/){t=L;L=R;R=t}print L" | "R}else print single[i]}}' /usr/lib/opkg/status; fi
echo -e "\n${GREEN}===== Flow Offloading =====${NC}"; sw=$(uci -q get firewall.@defaults[0].flow_offloading); hw=$(uci -q get firewall.@defaults[0].flow_offloading_hw)
if grep -q 'ct original packets ge 30' /usr/share/firewall4/templates/ruleset.uc 2>/dev/null; then dpi="${RED}yes${NC}"; else dpi="${GREEN}no${NC}"; fi; if [ "$hw" = "1" ]; then out="HW: ${RED}on${NC}"; elif [ "$sw" = "1" ]; then out="SW: ${RED}on${NC}"
else out="SW: ${GREEN}off${NC} | HW: ${GREEN}off${NC}"; fi; out="$out | FIX: ${dpi}"; echo -e "$out"; if /etc/init.d/https-dns-proxy status >/dev/null 2>&1; then
echo -e "\n${GREEN}===== Настройки DNS over HTTPS =====${NC}"; [ -f /etc/config/https-dns-proxy ] && sed -n "s/^[[:space:]]*option resolver_url '\([^']*\)'.*/\1/p" /etc/config/https-dns-proxy; else
echo -e "\n${GREEN}===== Проверка GitHub =====${NC}"; RATE=$(curl -s https://api.github.com/rate_limit | grep '"remaining"' | head -1 | awk '{print $2}' | tr -d ,)
[ -z "$RATE" ] && RATE_OUT="${RED}N/A${NC}" || RATE_OUT=$([ "$RATE" -eq 0 ] && echo -e "${RED}0${NC}" || echo -e "${GREEN}$RATE${NC}")
echo -n "API: "; curl -Is --connect-timeout 3 https://api.github.com >/dev/null 2>&1 && echo -e "${GREEN}ok${NC} | Limit: $RATE_OUT" || echo -e "${RED}fail${NC} | Limit: $RATE_OUT"; fi
echo -e "\n${GREEN}===== Проверка IPv4 / IPv6 =====${NC}"; PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "https://ipinfo.io/$IP/org" 2>/dev/null | sed -E 's/AS[0-9]+ ?//; s/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//g; s/[.,-]//g; s/  +/ /g; s/^ +| +$//g')
[ -z "$PROVIDER" ] && PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "http://ip-api.com/line/?fields=as" 2>/dev/null | sed -E 's/AS[0-9]+ ?//; s/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//g; s/[.,-]//g; s/  +/ /g; s/^ +| +$//g')
[ -z "$PROVIDER" ] && PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "https://ipwho.is/$IP" 2>/dev/null | sed -E 's/.*"isp":"([^"]+)".*/\1/' | sed -E 's/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//Ig' | sed -E 's/[.,-]//g; s/  +/ /g; s/^ +| +$//g'); [ -n "$PROVIDER" ] && echo "Провайдер: $PROVIDER"
echo -n "Google IPv4: "; time=$(ping -4 -c 1 -W 2 google.com 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}'); if [ -n "$time" ]; then echo -e "${GREEN}ok ($time ms)${NC}"; else echo -e "${RED}fail${NC}"; fi
echo -n "Google IPv6: "; time=$(ping -6 -c 1 -W 2 google.com 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}'); if [ -n "$time" ]; then echo -e "${GREEN}ok ($time ms)${NC}"; else echo -e "${RED}fail${NC}"; fi
echo -e "\n${GREEN}===== Настройки Zapret =====${NC}"; INFO_ZPR; if [ -f /etc/init.d/zapret ]; then TCP_VAL=$(grep -E "^[[:space:]]*option NFQWS_PORTS_TCP[[:space:]]+'" "$CONF" | sed "s/.*'\(.*\)'.*/\1/")
UDP_VAL=$(grep -E "^[[:space:]]*option NFQWS_PORTS_UDP[[:space:]]+'" "$CONF" | sed "s/.*'\(.*\)'.*/\1/"); echo -e "TCP: ${GREEN}$TCP_VAL${NC}\nUDP: ${GREEN}$UDP_VAL${NC}"; echo -e "\n${GREEN}===== Стратегия =====${NC}"
awk '/^[[:space:]]*option[[:space:]]+NFQWS_OPT[[:space:]]*'\''/ {flag=1; sub(/^[[:space:]]*option[[:space:]]+NFQWS_OPT[[:space:]]*'\''/, ""); next} flag {if(/'\''/) {sub(/'\''$/, ""); print; exit} print}' "$CONF"; fi
grep -q '^#' /etc/hosts && ! grep -qE 'dns\.geohide\.ru|mafioznik|dns\.malw\.link' /etc/hosts && { echo -e "\n${GREEN}===== Домены в hosts =====${NC}"; grep '^#' /etc/hosts | cut -c2- | awk '{printf "%-23s", $0; if (++n % 3 == 0) printf "\n"} END {if (n % 3) printf "\n"}'; }
echo -e "\n${GREEN}===== Доступность доменов =====${NC}"; prepare_urls; total=$(wc -l < "$OUT_DPI"); half=$(( (total + 1) / 2 )); COL_OFFSET=25; checked=0; ok=0; for idx in $(seq 1 $half); do left_line=$(sed -n "${idx}p" "$OUT_DPI")
left_name=$(echo "$left_line" | cut -d'|' -f1); left_url=$(echo "$left_line" | cut -d'|' -f2); right_idx=$((idx + half)); right_line=$(sed -n "${right_idx}p" "$OUT_DPI"); right_name=$(echo "$right_line" | cut -d'|' -f1); right_url=$(echo "$right_line" | cut -d'|' -f2)
if curl -sL --connect-timeout 2 --max-time 3 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "$left_url" >/dev/null 2>&1; then left_status="[${GREEN} OK ${NC}]"; ok=$((ok+1)); else left_status="[${RED}FAIL${NC}]"; fi
checked=$((checked+1)); if [ -n "$right_url" ]; then if curl -sL --connect-timeout 2 --max-time 3 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "$right_url" >/dev/null 2>&1; then right_status="[${GREEN} OK ${NC}]"
ok=$((ok+1)); else right_status="[${RED}FAIL${NC}]"; fi; checked=$((checked+1)); echo -e "$left_status $left_name$(printf '%*s' $((COL_OFFSET - ${#left_name})) '')$right_status $right_name"; else echo -e "$left_status $left_name"; fi; done; echo -e "\n${CYAN}Результат тестирования: ${NC}$ok/$checked\n"; PAUSE; }
# ==========================================
# Смена зеркала
# ==========================================

set_mirror() { NEW_BASE="$1"; echo -e "\n${CYAN}Проверяем доступность ${NC}$NEW_BASE"
if ! wget -q --spider --timeout=5 "https://$NEW_BASE/releases/" >/dev/null 2>&1; then echo -e "${RED}Зеркало недоступно!${NC}\n"; PAUSE; return 1; fi
sed -i "s|https://.*/releases/|https://$NEW_BASE/releases/|g" "$CONFZ"; echo -e "${GREEN}Зеркало доступно!${NC}"
if ! update_packages; then echo -e "\n${RED}Ошибка обновления списка пакетов!${NC}\n${GREEN}Зеркало сброшено на ${NC}default ${GREEN}/${NC} OpenWrt${GREEN}!${NC}\n"
sed -i "s|https://.*/releases/|https://downloads.openwrt.org/releases/|g" "$CONFZ"; PAUSE; return 1; fi; echo -e "${GREEN}Пакеты обновлены! Зеркало работает!${NC}\n"; PAUSE; }

curr_MIR() { if [ -f "$CONFZ" ]; then URL=$(head -n1 "$CONFZ"); case "$URL" in
*mirror-03.infra.openwrt.org*) echo "infra.openwrt.org" ;;
*tiguinet.net*) echo "Belgium" ;;
*utwente.nl*) echo "Netherlands" ;;
*freifunk.net*) echo "Germany" ;;
*rwth-aachen.de*) echo "Germany (RWTH Aachen)" ;;
*ps.kz*) echo "Kazakhstan" ;;
*sjtu.edu.cn*) echo "China" ;;
*accum.se*) echo "Sweden" ;;
*downloads.openwrt.org*) echo "default / OpenWrt" ;;
*) echo "неизвестное" ;;
esac; else echo "файл не найден"; fi; }

menu_MIR() { while true; do clear; CURR=$(curr_MIR); echo -e "${MAGENTA}Меню выбора зеркала OpenWrt${NC}\n\n${YELLOW}Используется зеркало: ${GREEN}$CURR${NC}\n\n${CYAN}1)${NC} infra.openwrt.org\n${CYAN}2)${NC} China"
echo -e "${CYAN}3)${NC} Germany\n${CYAN}4)${NC} Belgium\n${CYAN}5)${NC} Kazakhstan\n${CYAN}6)${NC} Netherlands\n${CYAN}7)${NC} Germany (RWTH Aachen)\n${CYAN}8)${NC} Sweden\n${CYAN}9)${NC} default / OpenWrt${NC}"
echo -e "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n"
echo -en "${YELLOW}Выберите зеркало: ${NC}"; read -r z; case "$z" in
1) set_mirror "mirror-03.infra.openwrt.org" ;;
2) set_mirror "mirror.sjtu.edu.cn/openwrt" ;;
3) set_mirror "mirror.berlin.freifunk.net/downloads.openwrt.org" ;;
4) set_mirror "mirror.tiguinet.net/openwrt" ;;
5) set_mirror "mirror.ps.kz/openwrt" ;;
6) set_mirror "ftp.snt.utwente.nl/pub/software/openwrt" ;;
7) set_mirror "ftp.halifax.rwth-aachen.de/openwrt" ;;
8) set_mirror "mirror.accum.se/mirror/openwrt.org" ;;
9) set_mirror "downloads.openwrt.org" ;;
*) break ;;
esac; done; }
# ==========================================
# МЕНЮ TG WS Proxy
# ==========================================
restart_all_TG() {
    echo -e "\n${MAGENTA}Перезапускаем все TG WS Proxy${NC}"
    for s in /etc/init.d/tg-ws-proxy /etc/init.d/tg-ws-proxy-go /etc/init.d/tg-ws-proxy-rs; do
        [ -x "$s" ] || continue
        "$s" restart >/dev/null 2>&1
    done
    sleep 1
    STATUS_LINE=""
    pidof tg-ws-proxy    >/dev/null 2>&1 && STATUS_LINE="${STATUS_LINE:+$STATUS_LINE, }MTProto"
    pidof tg-ws-proxy-go >/dev/null 2>&1 && STATUS_LINE="${STATUS_LINE:+$STATUS_LINE, }SOCKS5"
    pidof tg-ws-proxy-rs >/dev/null 2>&1 && STATUS_LINE="${STATUS_LINE:+$STATUS_LINE, }Rust"
    if [ -n "$STATUS_LINE" ]; then
        echo -e "TG WS Proxy ${GREEN}перезапущены!${NC}\n"
    else
        echo -e "${YELLOW}Ни один TG WS Proxy не установлен или не запущен.${NC}\n"
    fi
    PAUSE
}
# УСТАНОВКА RUST
get_arch_RS() { case "$ARCH" in aarch64*) echo "tg-ws-proxy-aarch64-unknown-linux-musl" ;; x86_64) echo "tg-ws-proxy-x86_64-unknown-linux-musl" ;; arm*) echo "tg-ws-proxy-armv7-unknown-linux-musleabihf" ;; mipsel*) echo "tg-ws-proxy-mipsel-unknown-linux-musl" ;; mips*) echo "tg-ws-proxy-mips-unknown-linux-musl" ;; *) echo -e "\n${RED}Архитектура не поддерживается: ${NC}$ARCH\n"; PAUSE; return 1 ;; esac; }
delete_TG_RS() { echo -e "\n${MAGENTA}Удаляем TG WS Proxy Rust${NC}"; /etc/init.d/tg-ws-proxy-rs stop >/dev/null 2>&1; /etc/init.d/tg-ws-proxy-rs disable >/dev/null 2>&1; rm -f "$BIN_PATH_RS" "$INIT_PATH_RS" "$BIN_VER_RS"; echo -e "TG WS Proxy Rust ${GREEN}удалён!${NC}\n"; PAUSE; }
install_TG_RS() { echo -e "\n${MAGENTA}Устанавливаем TG WS Proxy Rust${NC}"; ARCH_FILE_RS="$(get_arch_RS)" || return 1; echo -e "${CYAN}Скачиваем и устанавливаем${NC} $ARCH_FILE_RS"; DOWNLOAD_URL_RS="${GH_MAIN}/valnesfjord/tg-ws-proxy-rs/releases/download/v${TG_RS_VERSION}/${ARCH_FILE_RS}.tar.gz"
curl -L --fail -o "$TMP_ARCHIVE_RS" "$DOWNLOAD_URL_RS" >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка скачивания${NC}\n"; PAUSE; return 1; }; rm -rf "$TMP_DIR_RS"; mkdir -p "$TMP_DIR_RS"; tar -xzf "$TMP_ARCHIVE_RS" -C "$TMP_DIR_RS" || { echo -e "\n${RED}Ошибка распаковки${NC}\n"
rm -f "$TMP_ARCHIVE_RS"; PAUSE; return 1; }; rm -f "$BIN_PATH_RS"; mv "$TMP_DIR_RS"/tg-ws-proxy* "$BIN_PATH_RS" || { echo -e "\n${RED}Ошибка установки бинарника${NC}\n"; rm -rf "$TMP_DIR_RS" "$TMP_ARCHIVE_RS"; PAUSE; return 1; }
chmod +x "$BIN_PATH_RS"; rm -rf "$TMP_DIR_RS" "$TMP_ARCHIVE_RS"; echo "$TG_RS_VERSION" > "$BIN_VER_RS"; if [ ! -f "$INIT_PATH_RS" ]; then
printf '#!/bin/sh /etc/rc.common\nSTART=99\nUSE_PROCD=1\n\nstart_service() {\n    procd_open_instance\n    procd_set_param command /usr/bin/tg-ws-proxy-rs --host 0.0.0.0 --port 2443 --secret %s --default-domains --cf-balance --cf-priority\n    procd_set_param respawn\n    procd_close_instance\n}\n' "$SECRET" > "$INIT_PATH_RS"
chmod +x "$INIT_PATH_RS"; "$INIT_PATH_RS" enable >/dev/null 2>&1; fi; "$INIT_PATH_RS" restart >/dev/null 2>&1; if pidof tg-ws-proxy-rs >/dev/null 2>&1; then echo -e "TG WS Proxy Rust ${GREEN}установлен!${NC}\n"; else echo -e "${RED}TG WS Proxy Rust не запущен!${NC}\n"; fi; PAUSE; }
# УСТАНОВКА SOCKS5
get_arch_GO() { case "$ARCH" in aarch64*) echo "tg-ws-proxy-openwrt-aarch64" ;; arm*) echo "tg-ws-proxy-openwrt-armv7" ;; mipsel*) echo "tg-ws-proxy-openwrt-mipsel_24kc" ;; mips*) echo "tg-ws-proxy-openwrt-mips_24kc" ;; x86_64) echo "tg-ws-proxy-openwrt-x86_64" ;; *) echo -e "\n${RED}Архитектура не поддерживается: ${NC}$ARCH\n"; PAUSE; return 1 ;; esac; }
delete_TG_GO() { echo -e "\n${MAGENTA}Удаляем TG WS Proxy SOCKS5${NC}"; /etc/init.d/tg-ws-proxy-go stop >/dev/null 2>&1; /etc/init.d/tg-ws-proxy-go disable >/dev/null 2>&1; rm -f "$BIN_PATH_GO" "$INIT_PATH_GO" "$BIN_VER_GO"; echo -e "TG WS Proxy SOCKS5 ${GREEN}удалён!${NC}\n"; PAUSE; }
install_TG_GO() { echo -e "\n${MAGENTA}Устанавливаем TG WS Proxy SOCKS5${NC}"; ARCH_FILE_GO="$(get_arch_GO)" || return 1; echo -e "${CYAN}Скачиваем и устанавливаем${NC} $ARCH_FILE_GO"; DOWNLOAD_URL_GO="${GH_MAIN}/d0mhate/-tg-ws-proxy-Manager-go/releases/download/v${TG_GO_VERSION}/${ARCH_FILE_GO}"
curl -L --fail -o "$BIN_PATH_GO" "$DOWNLOAD_URL_GO" >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка скачивания${NC}\n"; rm -f "$BIN_PATH_GO"; PAUSE; return 1; }; chmod +x "$BIN_PATH_GO"; echo "$TG_GO_VERSION" > "$BIN_VER_GO"; if [ ! -f "$INIT_PATH_GO" ]; then
printf '#!/bin/sh /etc/rc.common\nSTART=99\nUSE_PROCD=1\n\nstart_service() {\n    procd_open_instance\n    procd_set_param command /usr/bin/tg-ws-proxy-go --host 0.0.0.0 --port 2080 --cf-proxy --cf-proxy-first --cf-balance\n    procd_set_param respawn\n    procd_close_instance\n}\n' > "$INIT_PATH_GO"
chmod +x "$INIT_PATH_GO"; "$INIT_PATH_GO" enable >/dev/null 2>&1; fi; "$INIT_PATH_GO" restart >/dev/null 2>&1; if pidof tg-ws-proxy-go >/dev/null 2>&1; then echo -e "TG WS Proxy SOCKS5 ${GREEN}установлен!${NC}\n"; else echo -e "${RED}TG WS Proxy SOCKS5 не запущен!${NC}\n"; fi; PAUSE; }
# УСТАНОВКА MTProto
install_update_TG_PKG() { echo -e "\n${MAGENTA}Устанавливаем TG WS Proxy MTProto${NC}"; rm -f /etc/tg-ws-proxy.conf /etc/tg-ws-proxy.conf-opkg; URL="${GH_MAIN}/spatiumstas/tg-ws-proxy-go/releases/download/${TG_MTProto}/tg-ws-proxy_${TG_MTProto}-${GO_SUF}_openwrt_${ARCH_FULL}.${RAZ}"
update_packages || return; FILE_NAME_GO="$(basename "$URL")"; echo -e "${CYAN}Скачиваем и устанавливаем${NC} $FILE_NAME_GO"
wget -q -O "$TMP_FILE_GO" "$URL" || { echo -e "\n${RED}Ошибка скачивания $URL${NC}\n"; PAUSE; return 1; }; $INSTALL "$TMP_FILE_GO" >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка установки $TMP_FILE_GO!${NC}\n"; rm -f "$TMP_FILE_GO"; PAUSE; return 1; }
rm -f "$TMP_FILE_GO"; if ! grep -q '^SECRET=.' "$SECRET_FILE" 2>/dev/null; then echo "SECRET=$SECRET" > "$SECRET_FILE"; fi; rm -f /etc/tg-ws-proxy.conf /etc/tg-ws-proxy.conf-opkg; /etc/init.d/tg-ws-proxy enable >/dev/null 2>&1; /etc/init.d/tg-ws-proxy restart >/dev/null 2>&1
if pidof tg-ws-proxy >/dev/null 2>&1; then echo -e "TG WS Proxy MTProto ${GREEN}установлен!${NC}\n"; else echo -e "${RED}TG WS Proxy MTProto не установлен!${NC}\n"; fi; PAUSE; }
remove_TG_PKG() { echo -e "\n${MAGENTA}Удаляем TG WS Proxy MTProto${NC}"; /etc/init.d/tg-ws-proxy stop >/dev/null 2>&1; /etc/init.d/tg-ws-proxy disable >/dev/null 2>&1; $DELETE tg-ws-proxy >/dev/null 2>&1; rm -rf /etc/tg-ws-proxy /etc/tg-ws-proxy.conf /etc/tg-ws-proxy.conf-opkg; echo -e "TG WS Proxy MTProto ${GREEN}удалён!${NC}\n"; PAUSE; }
# МЕНЮ
menu_TG() { while true; do SECRET="$(head -c16 /dev/urandom | hexdump -e '16/1 "%02x"')"; get_TG_versions; if command -v opkg >/dev/null 2>&1; then INSTALLED_VER_MT="$(opkg list-installed 2>/dev/null | grep '^tg-ws-proxy' | awk '{print $3}' | cut -d'-' -f1)"; else INSTALLED_VER_MT="$(apk list -I 2>/dev/null | grep '^tg-ws-proxy-' | sed -E 's/tg-ws-proxy-([0-9.]+).*/\1/')"; fi
if [ -z "$INSTALLED_VER_MT" ]; then MT_ACTION="install"; elif [ "$INSTALLED_VER_MT" != "$TG_MTProto" ]; then MT_ACTION="update"; else MT_ACTION="installed"; fi; if [ -f "$BIN_PATH_GO" ] && [ -f "$INIT_PATH_GO" ]; then if [ -n "$INSTALLED_VER_GO" ] && [ "$INSTALLED_VER_GO" = "$TG_GO_VERSION" ]; then GO_ACTION="installed"; else GO_ACTION="update"; fi; else GO_ACTION="install"; fi
if [ -f "$BIN_PATH_RS" ] && [ -f "$INIT_PATH_RS" ]; then if [ -n "$INSTALLED_VER_RS" ] && [ "$INSTALLED_VER_RS" = "$TG_RS_VERSION" ]; then RS_ACTION="installed"; else RS_ACTION="update"; fi; else RS_ACTION="install"; fi; clear; echo -e "${MAGENTA}Меню TG WS Proxy${NC}\n"; TGSTATUS=""; pidof tg-ws-proxy-go >/dev/null 2>&1 && TGSTATUS="${TGSTATUS:+$TGSTATUS/}${NC}SOCKS5${GREEN}"
pidof tg-ws-proxy >/dev/null 2>&1 && TGSTATUS="${TGSTATUS:+$TGSTATUS/}${NC}MTProto${GREEN}"; pidof tg-ws-proxy-rs >/dev/null 2>&1 && TGSTATUS="${TGSTATUS:+$TGSTATUS/}${NC}Rust${GREEN}"; if [ -n "$TGSTATUS" ]; then echo -e "${YELLOW}TG WS Proxy:${NC} ${GREEN}запущен [${TGSTATUS}]${NC}"; else echo -e "${YELLOW}TG WS Proxy:${NC} ${RED}не установлен${NC}"; fi
if [ -n "$INSTALLED_VER_MT" ]; then if [ "$MT_ACTION" = "update" ]; then echo -e "${YELLOW}TG WS Proxy MTProto версия:${NC} ${RED}$INSTALLED_VER_MT (версия устарела)${NC}"; else echo -e "${YELLOW}TG WS Proxy MTProto версия:${NC} ${GREEN}$INSTALLED_VER_MT${NC}"; fi; fi; if [ -n "$INSTALLED_VER_GO" ]; then if [ "$GO_ACTION" = "update" ]
then echo -e "${YELLOW}TG WS Proxy SOCKS5 версия:${NC} ${RED}$INSTALLED_VER_GO (версия устарела)${NC}"; else echo -e "${YELLOW}TG WS Proxy SOCKS5 версия:${NC} ${GREEN}$INSTALLED_VER_GO${NC}"; fi; fi; if [ -n "$INSTALLED_VER_RS" ]; then if [ "$RS_ACTION" = "update" ]; then echo -e "${YELLOW}TG WS Proxy Rust версия:${NC} ${RED}$INSTALLED_VER_RS (версия устарела)${NC}"
else echo -e "${YELLOW}TG WS Proxy Rust версия:${NC} ${GREEN}$INSTALLED_VER_RS${NC}"; fi; fi; if pidof tg-ws-proxy-go >/dev/null 2>&1 && [ -f "$BIN_PATH_GO" ] && [ -f "$INIT_PATH_GO" ]; then echo -e "\n${YELLOW}Настройки ${CYAN}TG WS Proxy SOCKS5${YELLOW}:${NC}\n${YELLOW}Тип прокси:${NC} SOCKS5\n${YELLOW}Хост:${NC} $LAN_IP\n${YELLOW}Порт:${NC} 2080"
echo -e "${YELLOW}Ссылка для подключения:${NC}"; echo -e "tg://socks?server=$LAN_IP&port=2080"; fi; if pgrep -f tg-ws-proxy-rs >/dev/null 2>&1 && [ -f "$BIN_PATH_RS" ] && [ -f "$INIT_PATH_RS" ]; then SECRET_IN_RS="$(sed -n 's/.*--secret[[:space:]]*\([0-9a-fA-F]\{32\}\).*/\1/p' "$INIT_PATH_RS")"; echo -e "\n${YELLOW}Настройки ${CYAN}TG WS Proxy Rust${YELLOW}:${NC}"
echo -e "${YELLOW}Тип прокси:${NC} MTProto\n${YELLOW}Хост:${NC} $LAN_IP\n${YELLOW}Порт:${NC} 2443\n${YELLOW}Ключ:${NC} dd$SECRET_IN_RS\n${YELLOW}Ссылка для подключения:${NC}\ntg://proxy?server=$LAN_IP&port=2443&secret=dd$SECRET_IN_RS"; fi; if pidof tg-ws-proxy >/dev/null 2>&1 && [ -f "/etc/init.d/tg-ws-proxy" ]
then SECRET_CONF="$(grep '^SECRET=' "$SECRET_FILE" 2>/dev/null | cut -d'=' -f2)"; echo -e "\n${YELLOW}Настройки ${CYAN}TG WS Proxy MTProto${YELLOW}:${NC}\n${YELLOW}Тип прокси:${NC} MTProto\n${YELLOW}Хост:${NC} $LAN_IP\n${YELLOW}Порт:${NC} 1443\n${YELLOW}Ключ:${NC} dd$SECRET_CONF"
echo -e "${YELLOW}Ссылка для подключения:${NC}\ntg://proxy?server=$LAN_IP&port=1443&secret=dd$SECRET_CONF"; fi; case "$GO_ACTION" in install) echo -e "\n${CYAN}1)${GREEN} Установить ${NC}TG WS Proxy SOCKS5" ;; update) echo -e "\n${CYAN}1)${GREEN} Обновить ${NC}TG WS Proxy SOCKS5" ;;
installed) echo -e "\n${CYAN}1)${GREEN} Удалить ${NC}TG WS Proxy SOCKS5" ;; esac; case "$RS_ACTION" in install) echo -e "${CYAN}2)${GREEN} Установить ${NC}TG WS Proxy Rust" ;; update) echo -e "${CYAN}2)${GREEN} Обновить ${NC}TG WS Proxy Rust" ;;
installed) echo -e "${CYAN}2)${GREEN} Удалить ${NC}TG WS Proxy Rust" ;; esac; case "$MT_ACTION" in install) echo -e "${CYAN}3)${GREEN} Установить ${NC}TG WS Proxy MTProto" ;; update) echo -e "${CYAN}3)${GREEN} Обновить ${NC}TG WS Proxy MTProto" ;;
installed) echo -e "${CYAN}3)${GREEN} Удалить ${NC}TG WS Proxy MTProto" ;; esac; echo -e "${CYAN}4)${GREEN} Удалить все ${NC}TG WS Proxy\n${CYAN}5)${GREEN} Перезапустить все ${NC}TG WS Proxy\n${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n"; echo -en "${YELLOW}Выберите пункт: ${NC}"; read choice
case "$choice" in 1) case "$GO_ACTION" in install|update) install_TG_GO ;; installed) delete_TG_GO ;; esac ;; 2) case "$RS_ACTION" in install|update) install_TG_RS ;; installed) delete_TG_RS ;; esac ;; 3) case "$MT_ACTION" in install|update) install_update_TG_PKG ;;
installed) remove_TG_PKG ;; esac ;; 4) echo -e "\n${MAGENTA}Удаляем все TG WS Proxy${NC}"; for s in /etc/init.d/tg-ws*; do [ -e "$s" ] || continue; "$s" stop >/dev/null 2>&1; "$s" disable >/dev/null 2>&1; done
$DELETE tg-ws* >/dev/null 2>&1; rm -rf /usr/bin/tg-ws* /etc/init.d/tg-ws* /etc/tg-ws* /etc/config/tg-ws*; echo -e "${GREEN}Все ${NC}TG WS Proxy ${GREEN}удалены!${NC}\n"; PAUSE ;; 5) restart_all_TG ;; *) break ;; esac; done; }
get_TG_versions() { INSTALLED_VER_GO=""; INSTALLED_VER_RS=""; INSTALLED_VER_MT=""; [ -s "$BIN_VER_GO" ] && INSTALLED_VER_GO="$(cat "$BIN_VER_GO")"; [ -s "$BIN_VER_RS" ] && INSTALLED_VER_RS="$(cat "$BIN_VER_RS")"; if command -v opkg >/dev/null 2>&1
then INSTALLED_VER_MT="$(opkg list-installed 2>/dev/null | grep '^tg-ws-proxy' | awk '{print $3}' | cut -d'-' -f1)"; else INSTALLED_VER_MT="$(apk list -I 2>/dev/null | grep '^tg-ws-proxy-' | sed -E 's/tg-ws-proxy-([0-9.]+).*/\1/')"; fi; }
# ==========================================
# PODKOP EVOLUTION и AWG
# ==========================================
pkg_is_installed () { local pkg_name="$1"; if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e "$pkg_name" >/dev/null 2>&1; else opkg list-installed | grep -q "^$pkg_name"; fi }
PODKOP_VER() { LOCALPOD="$(netshift show_version 2>/dev/null | cut -d'-' -f1 | sed 's/^v//')"; if [ -z "$LOCALPOD" ]; then PODKOP_STATUS="${RED}не установлен${NC}"; return; fi; if [ "$PODKOP_LATEST_VER" = "$LOCALPOD" ]
then PODKOP_STATUS="${GREEN}$LOCALPOD${NC}"; else PODKOP_STATUS="${RED}$LOCALPOD (версия устарела)${NC}"; fi; }
PODKOP_INSTALL() { if ! pkg_is_installed netshift; then ACTION="install"; elif [ "$PODKOP_LATEST_VER" != "$LOCALPOD" ]; then ACTION="update"; else ACTION="remove"; fi; if [ "$ACTION" = "install" ] || [ "$ACTION" = "update" ]; then rm -rf "$tmpDIR"; mkdir -p "$tmpDIR"
AVAILABLE_SPACE=$(df /overlay 2>/dev/null | awk 'NR==2 {print $4}'); [ -z "$AVAILABLE_SPACE" ] && AVAILABLE_SPACE=$(df / 2>/dev/null | awk 'NR==2 {print $4}'); REQUIRED_SPACE=20000; if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]
then echo -e "\n${RED}Недостаточно свободного места${NC}\n"; echo -e "${YELLOW}Доступно: ${NC}$((AVAILABLE_SPACE/1024)) MB"; echo -e "${YELLOW}Требуется: ${NC}$((REQUIRED_SPACE/1024)) MB\n"; if [ "$ACTION" = "update" ]
then echo -ne "${YELLOW}Удалить старую версию NetShift и установить новую? (${NC}y/n${YELLOW}): ${NC}"; read -r answer; case "$answer" in y|Y) PODKOP_DELETE ;; *) echo -e "\n${RED}Обновление отменено!${NC}\n"; PAUSE; return ;; esac; else PAUSE; return; fi; fi
if pkg_is_installed https-dns-proxy; then echo -e "\n${RED}Обнаружен ${NC}DNS over HTTPS${RED}!"; echo -e "${YELLOW}Удалите ${NC}DNS over HTTPS\n"; PAUSE; return; fi
[ "$ACTION" = "install" ] && echo -e "\n${MAGENTA}Устанавливаем NetShift${NC}" || echo -e "\n${MAGENTA}Обновляем NetShift${NC}";  update_packages || return
PODKOP_INST="${GH_MAIN}/yandexru45/netshift/releases/download/$PODKOP_LATEST_VER/netshift-$PODKOP_LATEST_VER-$VER_SUF.$RAZ"; PODKOP_LUCI="${GH_MAIN}/yandexru45/netshift/releases/download/$PODKOP_LATEST_VER/luci-app-netshift-$PODKOP_LATEST_VER-$VER_SUF.$RAZ"
PODKOP_RUS="${GH_MAIN}/yandexru45/netshift/releases/download/$PODKOP_LATEST_VER/luci-i18n-netshift-ru-$PODKOP_LATEST_VER.$RAZ"; cd "$tmpDIR"; echo -e "${CYAN}Скачиваем ${NC}NetShift"; wget -q -U "Mozilla/5.0" -O netshift.$RAZ "$PODKOP_INST" || { echo -e "\n${RED}Не удалось скачать:\n${NC}$PODKOP_INST\n"; PAUSE; return; }
wget -q -U "Mozilla/5.0" -O luci-app-netshift.$RAZ "$PODKOP_LUCI" || { echo -e "\n${RED}Не удалось скачать:\n${NC}$PODKOP_LUCI\n"; PAUSE; return; }
wget -q -U "Mozilla/5.0" -O luci-i18n-netshift-ru.$RAZ "$PODKOP_RUS" || { echo -e "\n${RED}Не удалось скачать:\n${NC}$PODKOP_RUS\n"; PAUSE; return; }
echo -en "${CYAN}Устанавливаем ${NC}NetShift\n${YELLOW}Подождите...${NC}"; $INSTALL ./netshift.$RAZ >/dev/null 2>&1 || { echo -e "\n\n${RED}Не удалось установить:\n${NC}$PODKOP_INST\n"; PAUSE; return; }
$INSTALL ./luci-app-netshift.$RAZ >/dev/null 2>&1 || { echo -e "\n\n${RED}Не удалось установить:\n${NC}$PODKOP_LUCI\n"; PAUSE; return; }
$INSTALL ./luci-i18n-netshift-ru.$RAZ >/dev/null 2>&1 || { echo -e "\n\n${RED}Не удалось установить:\n${NC}$PODKOP_RUS\n"; PAUSE; return; }; rm -rf "$tmpDIR"
echo -e "\nNetShift ${GREEN}$( [ "$ACTION" = "install" ] && echo "установлен" || echo "обновлён" )!${NC}\n"; PAUSE; else PODKOP_DELETE; fi; }
PODKOP_DELETE() { echo -e "\n${MAGENTA}Удаляем NetShift${NC}"; echo -e "${CYAN}Останавливаем сервисы${NC}"; netshift stop >/dev/null 2>&1; netshift disable >/dev/null 2>&1; sing-box stop >/dev/null 2>&1; sing-box disable >/dev/null 2>&1
echo -e "${CYAN}Удаляем пакеты ${NC}NetShift"; $DELETE luci-i18n-netshift-ru luci-app-netshift netshift >/dev/null 2>&1; echo -e "${CYAN}Удаляем пакеты ${NC}sing-box"; $DELETE sing-box >/dev/null 2>&1
echo -e "NetShift${GREEN} удалён!${NC}"; [ "$ACTION" != "update" ] && { rm -rf /etc/config/netshift* /usr/bin/netshift /etc/config/sing-box* /etc/sing-box >/dev/null 2>&1; echo; PAUSE; }; }
install_AWG_INTER() { echo -e "\n${MAGENTA}Устанавливаем интерфейс AWG${NC}"; echo -e "${CYAN}Создаем ${NC}интерфейс AWG"; if uci show network.$IF_NAME >/dev/null 2>&1; then echo -e "\n${RED}Интерфейс уже существует!${NC}"; else uci set network.$IF_NAME=interface
uci set network.$IF_NAME.proto=$PROTO; uci set network.$IF_NAME.device=$DEV_NAME; uci commit network; fi; echo -en "${CYAN}Перезапускаем сеть${NC}"; /etc/init.d/network restart >/dev/null 2>&1; /etc/init.d/ttyd restart >/dev/null 2>&1; echo -e "\nИнтерфейс AWG ${GREEN}установлен!${NC}"; echo -e "\n${YELLOW}Необходимо в ${NC}LuCI${YELLOW} в интерфейс ${NC}AWG${YELLOW} загрузить файл ${NC}*.conf${YELLOW}:${NC}"
echo -e "${NC}Network ${GREEN}→${NC} Interfaces ${GREEN}→${NC} AWG ${GREEN}→${NC} Edit ${GREEN}→${NC} Load configuration… ${GREEN}→${NC} Save ${GREEN}→${NC} Save & Apply\n"; PAUSE; rm -rf "$tmpDIR"; }
AWG_DELETE(){ echo -e "\n${MAGENTA}Удаляем AmneziaWG${NC}"; $DELETE luci-i18n-amneziawg-ru >/dev/null 2>&1; $DELETE luci-proto-amneziawg >/dev/null 2>&1; $DELETE amneziawg-tools >/dev/null 2>&1; $DELETE kmod-amneziawg >/dev/null 2>&1; echo -e "AmneziaWG ${GREEN}удалён!${NC}\n"; PAUSE; }
INT_DELETE(){ echo -e "\n${MAGENTA}Удаляем ${NC}интерфейс AWG"; uci delete network.AWG >/dev/null 2>&1; uci commit network >/dev/null 2>&1; for peer in $(uci show network | grep "interface='AWG'" | cut -d. -f2); do uci delete network.$peer; done; uci commit network >/dev/null 2>&1; echo -en "${CYAN}Перезапускаем сеть${NC}"; /etc/init.d/network restart; /etc/init.d/ttyd restart >/dev/null 2>&1; echo -e "\nинтерфейс AWG ${GREEN}удалён!${NC}\n"; PAUSE; }
install_AWG() { echo -e "\n${MAGENTA}Устанавливаем AmneziaWG${NC}"; rm -rf "$tmpDIR"; mkdir -p "$tmpDIR"; update_packages || return 1
AWG_kmod="${GH_MAIN}/2Grey/awg-openwrt/releases/download/v$OWRTAWG/kmod-amneziawg_v${OWRTAWG}_$ARCHAWG.$RAZ"; AWG_tools="${GH_MAIN}/2Grey/awg-openwrt/releases/download/v$OWRTAWG/amneziawg-tools_v${OWRTAWG}_$ARCHAWG.$RAZ"
AWG_luci="${GH_MAIN}/2Grey/awg-openwrt/releases/download/v$OWRTAWG/luci-proto-amneziawg_v${OWRTAWG}_$ARCHAWG.$RAZ"; AWG_ru="${GH_MAIN}/2Grey/awg-openwrt/releases/download/v$OWRTAWG/luci-i18n-amneziawg-ru_v${OWRTAWG}_$ARCHAWG.$RAZ"; cd "$tmpDIR"
echo -e "${CYAN}Скачиваем ${NC}AWG"; wget -q -U "Mozilla/5.0" -O AWG_kmod.$RAZ "$AWG_kmod" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось скачать:\n${NC}$AWG_kmod\n"; PAUSE; return 1; }; wget -q -U "Mozilla/5.0" -O AWG_tools.$RAZ "$AWG_tools" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось скачать:\n${NC}$AWG_tools\n"; PAUSE; return 1; }; wget -q -U "Mozilla/5.0" -O AWG_luci.$RAZ "$AWG_luci" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось скачать:\n${NC}$AWG_luci\n"; PAUSE; return 1; }
wget -q -U "Mozilla/5.0" -O AWG_ru.$RAZ "$AWG_ru" >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось скачать:\n${NC}$AWG_ru\n"; PAUSE; return 1; }; echo -e "${CYAN}Устанавливаем ${NC}AWG"; $INSTALL ./AWG_kmod.$RAZ >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить:\n${NC}$AWG_kmod\n"; PAUSE; return 1; }; $INSTALL ./AWG_tools.$RAZ >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить:\n${NC}$AWG_tools\n"; PAUSE; return 1; }
$INSTALL ./AWG_luci.$RAZ >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить:\n${NC}$AWG_luci\n"; PAUSE; return 1; }; $INSTALL ./AWG_ru.$RAZ >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить:\n${NC}$AWG_ru\n"; PAUSE; return 1; }; rm -rf "$tmpDIR"; }
integration_AWG() { if ! pkg_is_installed netshift; then echo -e "\n${RED}NetShift не установлен!${NC}\n"; PAUSE; return 1; fi; if ! awg --version >/dev/null 2>&1; then echo -e "\n${RED}AWG не установлен!${NC}\n"; PAUSE; return 1; fi; echo -e "\n${MAGENTA}Интегрируем AWG в NetShift${NC}"; echo -e "${CYAN}Меняем конфигурацию в ${NC}NetShift${NC}"
printf "%s\n" "config settings 'settings'" "option dns_type 'udp'" "option dns_server '9.9.9.9'" "option bootstrap_dns_server '77.88.8.8'" "option dns_rewrite_ttl '60'" "list source_network_interfaces 'br-lan'" "option enable_output_network_interface '0'" "option enable_badwan_interface_monitoring '0'" "option enable_yacd '0'" "option disable_quic '0'" > /etc/config/netshift
printf "%s\n" "option update_interval '1d'" "option download_lists_via_proxy '1'" "option dont_touch_dhcp '0'" "option config_path '/etc/sing-box/config.json'" "option cache_path '/tmp/sing-box/cache.db'" "option log_level 'warn'" "option exclude_ntp '0'" "option shutdown_correctly '0'" "" "config section 'StressAWG'" "option connection_type 'vpn'" >> /etc/config/netshift
printf "%s\n" "option interface 'AWG'" "option domain_resolver_enabled '0'" "list community_lists 'geoblock'" "list community_lists 'block'" "list community_lists 'porn'" "list community_lists 'news'" "list community_lists 'anime'" "list community_lists 'youtube'" "list community_lists 'discord'" "list community_lists 'meta'" "list community_lists 'twitter'" >> /etc/config/netshift
printf "%s\n" "list community_lists 'hdrezka'" "list community_lists 'tiktok'" "list community_lists 'telegram'" "list community_lists 'cloudflare'" "list community_lists 'google_ai'" "list community_lists 'google_play'" "list community_lists 'hodca'" "list community_lists 'roblox'" "list community_lists 'hetzner'" "list community_lists 'ovh'" >> /etc/config/netshift
printf "%s\n" "list community_lists 'digitalocean'" "list community_lists 'cloudfront'" "option user_domain_list_type 'disabled'" "option user_subnet_list_type 'disabled'" "option mixed_proxy_enabled '0'" >> /etc/config/netshift
echo -e "${CYAN}Запускаем ${NC}NetShift${NC}"; netshift enable >/dev/null 2>&1; echo -en "${CYAN}Перезапускаем сервис${NC}\n${YELLOW}Подождите...${NC}"
netshift restart >/dev/null 2>&1; echo -e "\nAWG ${GREEN}интегрирован в ${NC}NetShift${GREEN}!${NC}\n"; echo -e "${YELLOW}Необходимо в ${NC}LuCI${YELLOW} в интерфейс ${NC}AWG${YELLOW} загрузить файл ${NC}*.conf${YELLOW}:${NC}"
echo -e "${NC}Network ${GREEN}→${NC} Interfaces ${GREEN}→${NC} AWG ${GREEN}→${NC} Edit ${GREEN}→${NC} Load configuration… ${GREEN}→${NC} Save ${GREEN}→${NC} Save & Apply\n"; PAUSE; }
PODKOP_VPN() { if ! pkg_is_installed netshift; then echo -e "\n${RED}NetShift не установлен!${NC}\n"; PAUSE; return; fi; echo -e "\n${MAGENTA}Интегрируем VPN подписку в NetShift${NC}"; echo -ne "\n${YELLOW}Введите ссылку на подписку (${NC}https://...${YELLOW}): ${NC}"
read -r SUB_URL; SUB_URL="$(echo "$SUB_URL" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"; echo "$SUB_URL" | grep -qE '^https?://' || { echo -e "\n${RED}Ошибка ввода! Только ${NC}http://${RED} или ${NC}https://${RED} ссылки!${NC}\n"; PAUSE; return; }; 
if grep -q "^[[:space:]]*option subscription_url" /etc/config/netshift; then echo -e "${CYAN}Меняем подписку${NC}"; sed -i "s|^[[:space:]]*option subscription_url.*|	option subscription_url '$SUB_URL'|" /etc/config/netshift; else echo -e "\n${CYAN}Меняем конфигурацию в ${NC}NetShift${NC}"
printf "%s\n" "config settings 'settings'" "option dns_type 'udp'" "option dns_server '9.9.9.9'" "option bootstrap_dns_server '77.88.8.8'" "option dns_rewrite_ttl '60'" "list source_network_interfaces 'br-lan'" "option enable_output_network_interface '0'" "option enable_badwan_interface_monitoring '0'" "option enable_yacd '0'" > /etc/config/netshift
printf "%s\n" "option disable_quic '0'" "option update_interval '1d'" "option download_lists_via_proxy '1'" "option dont_touch_dhcp '0'" "option config_path '/etc/sing-box/config.json'" "option cache_path '/tmp/sing-box/cache.db'" "option log_level 'panic'" "option exclude_ntp '0'" "option shutdown_correctly '0'" >> /etc/config/netshift
printf "%s\n" "option dns_via_outbound '0'" "option block_doh '0'" "option enable_ipv6 '0'" "" "config section 'StressKVN'" "option connection_type 'proxy'" "option proxy_config_type 'subscription'" "option subscription_url '$SUB_URL'" "option subscription_insecure '0'" "option subscription_update_interval '1h'" >> /etc/config/netshift
printf "%s\n" "option subscription_group_by_countries '0'" "option urltest_check_interval '3m'" "option urltest_tolerance '100'" "option urltest_testing_url 'https://www.gstatic.com/generate_204'" "option enable_udp_over_tcp '0'" "option global_proxy '0'" "list community_lists 'geoblock'" "list community_lists 'block'" >> /etc/config/netshift
printf "%s\n" "list community_lists 'porn'" "list community_lists 'news'" "list community_lists 'anime'" "list community_lists 'discord'" "list community_lists 'meta'" "list community_lists 'twitter'" "list community_lists 'hdrezka'" "list community_lists 'tiktok'" "list community_lists 'telegram'" "list community_lists 'cloudflare'" >> /etc/config/netshift
printf "%s\n" "list community_lists 'google_ai'" "list community_lists 'google_play'" "list community_lists 'hodca'" "list community_lists 'roblox'" "list community_lists 'hetzner'" "list community_lists 'ovh'" "list community_lists 'digitalocean'" "list community_lists 'cloudfront'" "option user_domain_list_type 'disabled'" >> /etc/config/netshift
printf "%s\n" "option user_subnet_list_type 'disabled'" "option mixed_proxy_enabled '0'" "option resolve_real_ip_for_routing '0'" "list subscription_filter_exclude_keywords '⬇️'" "list subscription_filter_exclude_keywords 'LTE'" "list subscription_filter_exclude_keywords '🇪🇺'" "list subscription_filter_exclude_keywords 'Мобильный'" "list subscription_filter_exclude_keywords 'SS'" "list subscription_filter_exclude_keywords 'Авто'" >> /etc/config/netshift
fi; echo -e "${CYAN}Запускаем ${NC}NetShift${NC}"; netshift enable >/dev/null 2>&1; echo -en "${CYAN}Перезапускаем сервис${NC}\n${YELLOW}Подождите...${NC}"; netshift restart >/dev/null 2>&1; echo -e "\nVPN подписка ${GREEN}интегрирована в ${NC}NetShift${GREEN}!${NC}\n"; PAUSE; }
BYEDPI_STATUS() { if pkg_is_installed byedpi; then if [ "$PKG_IS_APK" -eq 1 ]; then LOCAL_BYEDPI="$(apk list -I 2>/dev/null | grep '^byedpi-' | head -1 | sed -E 's/^byedpi-//;s/-r[0-9]+.*//')"; else LOCAL_BYEDPI="$(opkg list-installed 2>/dev/null | awk '$1=="byedpi" {print $3}' | sed 's/-r[0-9]\+$//')"; fi; [ "$LOCAL_BYEDPI" = "$BYEDPI_LATEST_VER" ] && BYEDPI_STATUS="${GREEN}${LOCAL_BYEDPI}${NC}" || BYEDPI_STATUS="${RED}${LOCAL_BYEDPI} (версия устарела)${NC}"; else BYEDPI_STATUS="${RED}не установлен${NC}"; fi; }
BYEDPI_SAVE_DNS_STATE() { if [ ! -f "$BYEDPI_DNS_BACKUP" ]; then { echo "LOCALUSE=$(uci -q get dhcp.@dnsmasq[0].localuse 2>/dev/null || echo "__UNSET__")"; echo "SERVER=$(uci -q get dhcp.@dnsmasq[0].server 2>/dev/null || echo "__UNSET__")"
echo "NORESOLV=$(uci -q get dhcp.@dnsmasq[0].noresolv 2>/dev/null || echo "__UNSET__")"; echo "NETSHIFT_NORESOLV=$(uci -q get dhcp.@dnsmasq[0].netshift_noresolv 2>/dev/null || echo "__UNSET__")"; } > "$BYEDPI_DNS_BACKUP"; fi; }
BYEDPI_RESTORE_DNS_STATE() { [ ! -f "$BYEDPI_DNS_BACKUP" ] && return; . "$BYEDPI_DNS_BACKUP"; echo -e "${CYAN}Восстанавливаем настройки ${NC}DNS"; if [ "$LOCALUSE" = "__UNSET__" ]; then uci -q delete dhcp.@dnsmasq[0].localuse
else uci set dhcp.@dnsmasq[0].localuse="$LOCALUSE"; fi; if [ "$SERVER" = "__UNSET__" ]; then uci -q delete dhcp.@dnsmasq[0].server; else uci set dhcp.@dnsmasq[0].server="$SERVER"; fi; if [ "$NORESOLV" = "__UNSET__" ]
then uci -q delete dhcp.@dnsmasq[0].noresolv; else uci set dhcp.@dnsmasq[0].noresolv="$NORESOLV"; fi; uci commit dhcp >/dev/null 2>&1; echo -e "${CYAN}Перезапускаем ${NC}dnsmasq"; /etc/init.d/dnsmasq restart >/dev/null 2>&1; rm -f "$BYEDPI_DNS_BACKUP"; }
BYEDPI_INSTALL() { if pkg_is_installed byedpi; then BYEDPI_DELETE; return; fi; echo -e "\n${MAGENTA}Установка ByeDPI${NC}"; rm -rf "$tmpDIR"; mkdir -p "$tmpDIR"; BYEDPI_FILE="byedpi_${BYEDPI_LATEST_VER}-r1_${LOCAL_ARCH}.${RAZ}"
BYEDPI_URL="${GH_MAIN}/DPITrickster/ByeDPI-OpenWrt/releases/download/${RELEASE_TAG}/${BYEDPI_FILE}"; echo -e "${CYAN}Скачиваем ${NC}$BYEDPI_FILE"; cd "$tmpDIR" || return 1; wget -q -U "Mozilla/5.0" -O "$BYEDPI_FILE" "$BYEDPI_URL" || { echo -e "\n${RED}Не удалось скачать:${NC}\n"; echo "$BYEDPI_URL"; rm -rf "$tmpDIR"; PAUSE; return 1; }
echo -e "${CYAN}Устанавливаем ${NC}ByeDPI"; if ! $INSTALL "$BYEDPI_FILE" >/dev/null 2>&1; then echo -e "\n${RED}Не удалось установить ByeDPI!${NC}\n"; rm -rf "$tmpDIR"; PAUSE; return 1; fi; rm -rf "$tmpDIR"; if [ -f /etc/init.d/byedpi ]
then /etc/init.d/byedpi enable >/dev/null 2>&1; /etc/init.d/byedpi start >/dev/null 2>&1; fi; echo -e "ByeDPI ${GREEN}установлен!${NC}\n"; PAUSE; }
BYEDPI_DELETE() { echo -e "\n${MAGENTA}Удаление ByeDPI${NC}"; echo -e "${CYAN}Останавливаем ${NC}ByeDPI"; /etc/init.d/byedpi stop >/dev/null 2>&1; /etc/init.d/byedpi disable >/dev/null 2>&1; echo -e "${CYAN}Удаляем пакет ${NC}ByeDPI"
$DELETE byedpi >/dev/null 2>&1; rm -f /etc/init.d/byedpi; rm -rf /opt/byedpi; rm -f /etc/config/byedpi; BYEDPI_RESTORE_DNS_STATE; echo -e "ByeDPI ${GREEN}удалён!${NC}\n"; PAUSE; }
BYEDPI_NETSHIFT() { if ! pkg_is_installed byedpi; then echo -e "\nByeDPI${RED} не установлен!${NC}\n"; PAUSE; return; fi; if ! pkg_is_installed netshift; then echo -e "\nNetShift${RED} не установлен!${NC}\n"; PAUSE; return; fi; echo -e "\n${MAGENTA}Интеграция ByeDPI в NetShift${NC}"
rm -f /tmp/byedpi_dns_backup; BYEDPI_SAVE_DNS_STATE; echo -e "${CYAN}Отключаем локальный ${NC}DNS"; uci set dhcp.@dnsmasq[0].localuse='0'; uci commit dhcp; echo -e "${CYAN}Перезапускаем ${NC}dnsmasq"; /etc/init.d/dnsmasq restart >/dev/null 2>&1; echo -e "${CYAN}Настраиваем стратегию ${NC}ByeDPI"
if [ -f /etc/config/byedpi ]; then sed -i "s|option cmd_opts .*|	option cmd_opts '-d1 -s1+s -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -a1'|" /etc/config/byedpi; fi; echo -e "${CYAN}Меняем конфигурацию в ${NC}NetShift"
printf "config settings 'settings'\n\toption dns_type 'doh'\n\toption dns_server '9.9.9.9'\n\toption bootstrap_dns_server '77.88.8.8'\n\toption dns_rewrite_ttl '60'\n\tlist source_network_interfaces 'br-lan'\n\toption enable_output_network_interface '0'\n\toption enable_badwan_interface_monitoring '0'\n\toption enable_yacd '0'\n\toption disable_quic '0'\n\toption update_interval '1d'\n\toption download_lists_via_proxy '1'\n\toption dont_touch_dhcp '0'\n\toption config_path '/etc/sing-box/config.json'\n\toption cache_path '/tmp/sing-box/cache.db'\n\toption log_level 'warn'\n\toption exclude_ntp '0'\n\toption shutdown_correctly '0'\n\toption block_doh '0'\n\toption enable_ipv6 '0'\n\toption dns_via_outbound '0'\n\nconfig section 'ByeDPI'\n\toption connection_type 'proxy'\n\toption proxy_config_type 'outbound'\n\toption enable_udp_over_tcp '0'\n\toption global_proxy '0'\n\toption outbound_json '{\n\"type\": \"socks\",\n\"server\": \"127.0.0.1\",\n\"server_port\": 1080\n}'\n\toption user_domain_list_type 'disabled'\n\toption user_subnet_list_type 'disabled'\n\toption mixed_proxy_enabled '0'\n\toption resolve_real_ip_for_routing '0'\n\tlist community_lists 'youtube'\n" > /etc/config/netshift
echo -e "${CYAN}Запускаем ${NC}ByeDPI"; /etc/init.d/byedpi enable >/dev/null 2>&1; /etc/init.d/byedpi restart >/dev/null 2>&1; echo -e "${CYAN}Запускаем ${NC}NetShift"; netshift enable >/dev/null 2>&1
echo -e "${CYAN}Перезапускаем ${NC}NetShift"; netshift restart >/dev/null 2>&1; echo -e "ByeDPI ${GREEN}интегрирован в ${NC}NetShift${GREEN}!${NC}"
echo -ne "\n${YELLOW}Для работы ${NC}ByeDPI${YELLOW} необходимо перезагрузить роутер!\nПерезагрузить сейчас? (${NC}y/N${YELLOW}): ${NC}"; read -r REBOOT_CHOICE; case "$REBOOT_CHOICE" in y|Y) echo -e "\n${GREEN}Перезагрузка роутера!${NC}"; reboot; exit 0 ;; *) echo -e "\n${YELLOW}Перезагрузка отложена!${NC}\n"; PAUSE ;; esac; }
fix_strategy() { echo -e "\n${MAGENTA}Изменение стратегии ByeDPI${NC}"; if [ ! -f /etc/config/byedpi ]; then echo -e "\n${RED}ByeDPI не установлен!${NC}\n"; PAUSE; return; fi; CURRENT_STRATEGY="$(grep "option cmd_opts" /etc/config/byedpi | sed -E "s/.*'(.+)'/\1/")"
[ -z "$CURRENT_STRATEGY" ] && CURRENT_STRATEGY="(не задана)"; echo -e "${GREEN}Текущая стратегия:${NC} $CURRENT_STRATEGY"; echo -ne "\n${YELLOW}Введите новую стратегию (Enter — оставить текущую):${NC} "; read -r NEW_STRATEGY; echo; if [ -z "$NEW_STRATEGY" ]
then echo -e "${GREEN}Стратегия не изменена!${NC}\n"; else sed -i "s|option cmd_opts .*|	option cmd_opts '$NEW_STRATEGY'|" /etc/config/byedpi; /etc/init.d/byedpi enable >/dev/null 2>&1; /etc/init.d/byedpi restart >/dev/null 2>&1; echo -e "${GREEN}Стратегия изменена на:${NC} $NEW_STRATEGY\n"; fi; PAUSE; }
# Меню NetShift
PODKOP_menu() { while true; do openwrt_version=$(grep DISTRIB_RELEASE /etc/openwrt_release | cut -d"'" -f2 | cut -d'.' -f1); if [ "$openwrt_version" = "23" ]; then echo -e "\nOpenWrt${RED} версии ниже 24 не поддерживаются!${NC}\n"; PAUSE; return; fi
PODKOP_VER; BYEDPI_STATUS; clear; echo -e "${MAGENTA}Меню NetShift${NC}\n"; echo -e "${YELLOW}NetShift:${NC} $PODKOP_STATUS"; echo -e "${YELLOW}ByeDPI:${NC} $BYEDPI_STATUS"; if pkg_is_installed byedpi; then CURRENT_STRATEGY="$(grep "option cmd_opts" /etc/config/byedpi 2>/dev/null | sed -E "s/.*'(.+)'/\1/")"
[ -z "$CURRENT_STRATEGY" ] && CURRENT_STRATEGY="(не задана)"; echo -e "${YELLOW}Стратегия ByeDPI:${NC} $CURRENT_STRATEGY"; fi; if pkg_is_installed amneziawg-tools && pkg_is_installed luci-proto-amneziawg && pkg_is_installed kmod-amneziawg
then echo -e "${YELLOW}AmneziaWG: ${GREEN}установлен${NC}"; else echo -e "${YELLOW}AmneziaWG: ${RED}не установлен${NC}"; fi; if uci -q get network.AWG >/dev/null 2>&1; then echo -e "${YELLOW}Интерфейс AWG: ${GREEN}установлен${NC}"
else echo -e "${YELLOW}Интерфейс AWG: ${RED}не установлен${NC}"; fi; if ! pkg_is_installed netshift; then echo -e "\n${CYAN}1) ${GREEN}Установить ${NC}NetShift"; elif [ "$PODKOP_LATEST_VER" != "$LOCALPOD" ]
then echo -e "\n${CYAN}1) ${GREEN}Обновить ${NC}NetShift"; else echo -e "\n${CYAN}1) ${GREEN}Удалить ${NC}NetShift"; fi; if pkg_is_installed byedpi; then echo -e "${CYAN}2) ${GREEN}Удалить ${NC}ByeDPI"
else echo -e "${CYAN}2) ${GREEN}Установить ${NC}ByeDPI"; fi; if pkg_is_installed amneziawg-tools && pkg_is_installed luci-proto-amneziawg && pkg_is_installed kmod-amneziawg; then echo -e "${CYAN}3) ${GREEN}Удалить ${NC}AmneziaWG"
else echo -e "${CYAN}3) ${GREEN}Установить ${NC}AmneziaWG"; fi; if uci -q get network.AWG >/dev/null 2>&1; then echo -e "${CYAN}4) ${GREEN}Удалить ${NC}интерфейс AWG"; else echo -e "${CYAN}4) ${GREEN}Установить ${NC}интерфейс AWG"; fi
if [ -f /etc/config/netshift ] && grep -q "^[[:space:]]*option subscription_url" /etc/config/netshift; then echo -e "${CYAN}5) ${GREEN}Сменить ${NC}VPN подписку${GREEN} в ${NC}NetShift"; else echo -e "${CYAN}5) ${GREEN}Интегрировать ${NC}VPN подписку${GREEN} в ${NC}NetShift"; fi
echo -e "${CYAN}6) ${GREEN}Интегрировать ${NC}AWG${GREEN} в ${NC}NetShift"; echo -e "${CYAN}7) ${GREEN}Интегрировать ${NC}ByeDPI${GREEN} в ${NC}NetShift"; if pkg_is_installed byedpi; then echo -e "${CYAN}8) ${GREEN}Изменить стратегию ${NC}ByeDPI"; fi
echo -e "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}"; echo -ne "\n${YELLOW}Выберите пункт:${NC} "; read -r choicePOD; case "$choicePOD" in 1) PODKOP_INSTALL ;; 2) BYEDPI_INSTALL ;;
3) if pkg_is_installed amneziawg-tools && pkg_is_installed luci-proto-amneziawg && pkg_is_installed kmod-amneziawg; then if ! pkg_is_installed splify; then AWG_DELETE
else echo -e "\n${RED}Удаление невозможно!${NC}"; echo -e "AmneziaWG ${YELLOW}используется в ${NC}splify\n"; PAUSE; fi; else install_AWG; echo -e "\nAmneziaWG ${GREEN}установлен!${NC}\n"; PAUSE; fi ;;
4) if uci -q get network.AWG >/dev/null 2>&1; then INT_DELETE; else install_AWG_INTER; echo -e "\n\nИнтерфейс AWG ${GREEN}установлен!${NC}\n"; fi ;; 5) PODKOP_VPN ;; 6) integration_AWG ;; 7) BYEDPI_NETSHIFT ;; 8) if pkg_is_installed byedpi; then fix_strategy; fi ;; *) return ;; esac; done; }
# ==========================================
# Информация
# ==========================================
INFO_ZPR() { if [ -f /etc/init.d/zapret ]; then /etc/init.d/zapret status >/dev/null 2>&1 && ZAPRET_STATUS="${GREEN}запущен${NC} $NFQ_STAT" || ZAPRET_STATUS="${RED}остановлен${NC}"; if [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ]; then echo -e "${YELLOW}Zapret:${NC}              ${GREEN}$INSTALLED_VER${NC} / $ZAPRET_STATUS"
else echo -e "${YELLOW}Zapret:${NC}              ${RED}$INSTALLED_VER (версия устарела)${NC} / $ZAPRET_STATUS"; fi; fi
if [ -f /etc/init.d/zapret2 ]; then /etc/init.d/zapret2 status >/dev/null 2>&1 && ZAPRET2_STATUS="${GREEN}запущен${NC}" || ZAPRET2_STATUS="${RED}остановлен${NC}"; if [ "$INSTALLED_VER2" = "$ZAPRET2_VERSION" ]; then echo -e "${YELLOW}Zapret2:${NC}             ${GREEN}$INSTALLED_VER2${NC} / $ZAPRET2_STATUS"
else echo -e "${YELLOW}Zapret2:${NC}             ${RED}$INSTALLED_VER2 (версия устарела)${NC} / $ZAPRET2_STATUS"; fi; fi; is_expert_mode && echo -e "${YELLOW}Expert mode:${NC}         ${GREEN}включён${NC}"
SPL_V_VER; [ -n "$SPL_INST_VER" ] && { [ "$SPL_VER" = "$SPL_INST_VER" ] && echo -e "${YELLOW}splify:${NC}              ${GREEN}$SPL_INST_VER${NC}" || echo -e "${YELLOW}splify:${NC}              ${RED}$SPL_INST_VER (версия устарела)${NC}"; }
if [ -f /etc/init.d/steer ]; then echo -e "${YELLOW}splify2:${NC}             ${GREEN}установлен${NC}"; fi
case "$(/etc/init.d/mihomo status 2>/dev/null)" in running) echo -e "${YELLOW}Mixomo:              ${GREEN}запущен${NC}" ;; inactive) echo -e "${YELLOW}Mixomo:              ${RED}остановлен${NC}" ;; esac
get_TG_versions; TGSTATUS=""; if pidof tg-ws-proxy-go >/dev/null 2>&1; then if [ -n "$INSTALLED_VER_GO" ] && [ -n "$TG_GO_VERSION" ] && [ "$INSTALLED_VER_GO" != "$TG_GO_VERSION" ]; then TGSTATUS="${TGSTATUS:+$TGSTATUS/}${RED}SOCKS5 NEW${GREEN}"
else TGSTATUS="${TGSTATUS:+$TGSTATUS/}${NC}SOCKS5${GREEN}"; fi; fi; if pidof tg-ws-proxy >/dev/null 2>&1; then if [ -n "$INSTALLED_VER_MT" ] && [ -n "$TG_MTProto" ] && [ "$INSTALLED_VER_MT" != "$TG_MTProto" ]; then TGSTATUS="${TGSTATUS:+$TGSTATUS/}${RED}MTProto NEW${GREEN}"
else TGSTATUS="${TGSTATUS:+$TGSTATUS/}${NC}MTProto${GREEN}"; fi; fi; if pidof tg-ws-proxy-rs >/dev/null 2>&1; then if [ -n "$INSTALLED_VER_RS" ] && [ -n "$TG_RS_VERSION" ] && [ "$INSTALLED_VER_RS" != "$TG_RS_VERSION" ]; then TGSTATUS="${TGSTATUS:+$TGSTATUS/}${RED}Rust NEW${GREEN}"
else TGSTATUS="${TGSTATUS:+$TGSTATUS/}${NC}Rust${GREEN}"; fi; fi; if [ -n "$TGSTATUS" ]; then echo -e "${YELLOW}TG WS Proxy:${NC}         ${GREEN}запущен [${TGSTATUS}]${NC}"; fi
if hosts_enabled; then echo -e "${YELLOW}Домены в hosts:      ${GREEN}$hosts_echo${NC}"; fi; [ -f "$DATE_FILE" ] && echo -e "${YELLOW}Резервная копия:${NC}     ${GREEN}сохранена"; show_script_50 && [ -n "$name" ] && echo -e "${YELLOW}Установлен скрипт:${NC}   $name"; grep -q "$Fin_IP_Dis" /etc/hosts && echo -e "${YELLOW}IP для Discord:      ${GREEN}включены${NC}"
if [ -n "$DOH_STATUS" ]; then if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e https-dns-proxy >/dev/null 2>&1 && echo -e "${YELLOW}DNS over HTTPS:${NC}      ${GREEN}$DOH_STATUS${NC}"; else opkg list-installed | grep -q '^https-dns-proxy ' && echo -e "${YELLOW}DNS over HTTPS:${NC}      ${GREEN}$DOH_STATUS${NC}"; fi; fi
pkg_is_installed netshift && PODKOP_VER && echo -e "${YELLOW}NetShift:${NC}            $PODKOP_STATUS"; if web_is_enabled; then echo -e "${YELLOW}Доступ из браузера:${NC}  $LAN_IP:7681"; fi; quic_is_blocked && if quic_is_blocked; then echo -e "${YELLOW}Блокировка QUIC:${NC}     ${GREEN}включена${NC}"; fi; if grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc
then echo -e "${YELLOW}Flow Offloading FIX:${NC} ${GREEN}включён${NC}"; fi; if [ "$CURR" != "default / OpenWrt" ]; then echo -e "${YELLOW}Зеркало OpenWRT:${NC}     $CURR"; fi; if [ -f /etc/init.d/zapret ] && [ -f "$CONF" ] && grep -Eq "^[[:space:]]*option DISABLE_IPV6 '0'" "$CONF"; then echo -e "${YELLOW}IPv6 в Zapret:       ${GREEN}включён${NC}"; fi
LINEAV=$(auto_best_cron_line); HOURAV=$(echo "$LINEAV" | awk '{print $2}'); if auto_best_running; then if [ -n "$HOURAV" ]; then echo -e "${YELLOW}Автоподбор стратегий:${NC}${GREEN}выполняется в фоне ${NC}/${GREEN} ежедневно в ${NC}$(printf "%02d" "$HOURAV"):00${NC}"
else echo -e "${YELLOW}Автоподбор стратегий:${NC}${GREEN}выполняется в фоне${NC}"; fi; else if [ -n "$HOURAV" ]; then echo -e "${YELLOW}Автоподбор стратегий:${NC}${GREEN}ежедневно в ${NC}$(printf "%02d" "$HOURAV"):00"; fi; fi; INFO_ZPR_STR; }
INFO_ZPR_STR() { if [ -f "$CONF" ]; then line=$(grep -m1 '^#general' "$CONF"); GEN="${line:+${line#?} / }"; current="$ver$( [ -n "$ver" ] && [ -n "$yv_ver" ] && echo " / " )$yv_ver"; DV=$(grep -o -E '^#Dv[0-9][0-9]*' "$CONF" | sed 's/^#[[:space:]]*/\/ /' | head -n1)
GV=$(grep -m1 '^#Gv' "$CONF" | sed 's/^#/\/ /'); [ "$GV" = "/ Gv0" ] && GV="/ GvF"; UPD=$(grep -q '^#udp443' "$CONF" && echo '/ udp443'); WS=$(grep -q -- '--wssize 1:6' "$CONF" && echo '/ wssize'); ME=$(grep -q -- '--methodeol' "$CONF" && echo '/ methodeol'); if [ -n "$current" ]
then echo -e "${YELLOW}Стратегия Zapret:${NC}    ${CYAN}${GEN}$current${DV:+ $DV}${GV:+ $GV}${UPD:+ $UPD}${WS:+ $WS}${ME:+ $ME}${RKN_STATUS:+ $RKN_STATUS}${NC}"; elif [ -n "$RKN_STATUS" ]
then echo -e "${YELLOW}Стратегия Zapret:${NC}    ${CYAN}${GEN}РКН${DV:+ $DV}${GV:+ $GV}${UPD:+ $UPD}${WS:+ $WS}${ME:+ $ME}${NC}"; elif [ -n "$line" ]; then echo -e "${YELLOW}Стратегия Zapret:${NC}    ${CYAN}${line#?}${GV:+ $GV}${NC}"
elif [ -n "$GV" ] && [ -z "$DV" ]; then echo -e "${YELLOW}Стратегия Zapret:${NC}    ${CYAN}${GV#/ }${NC}"; elif [ -z "$GV" ] && [ -n "$DV" ]; then echo -e "${YELLOW}Стратегия Zapret:${NC}    ${CYAN}${DV#/ }${NC}"; elif [ -n "$GV" ] && [ -n "$DV" ]; then echo -e "${YELLOW}Стратегия Zapret:${NC}    ${CYAN}${GV#/ } / ${DV#/ }${NC}"; fi; fi
grep -Fq "$DISCORD_DEF_HOSTLIST" "$CONF" 2>/dev/null && echo -e "${YELLOW}Основная стратегия:${NC}  ${CYAN}только Discord${NC}"; }
# ==========================================
# Mixomo
# ==========================================
magitrickle_config() { echo -e "\n${MAGENTA}Выбор списка для MagiTrickle${NC}"; echo -e "${CYAN}1) ${GREEN}Список от${NC} ITDog\n${CYAN}2) ${GREEN}Список от${NC} Internet Helper #1\n${CYAN}3) ${GREEN}Список от${NC} Internet Helper #2\n${CYAN}Enter) ${GREEN}Выход в меню Mixomo${NC}\n"
while true; do echo -en "${YELLOW}Выберите пункт: ${NC}"; read -r choice; case "$choice" in 1) MAGITRICKLE_CONFIG_URL="$URL_ITDOG"; break ;; 2) MAGITRICKLE_CONFIG_URL="$URL_DEFAULT"; break ;; 3) MAGITRICKLE_CONFIG_URL="$URL_OLD"; break ;; *) return ;; esac; done
if [ -n "$MAGITRICKLE_CONFIG_URL" ]; then echo -e "\n${CYAN}Скачиваем и устанавливаем список${NC}"; wget -q -O "$CONFIGPATH" "$MAGITRICKLE_CONFIG_URL" || { echo -e "\n${RED}Не удалось скачать список:\n${NC}$MAGITRICKLE_CONFIG_URL\n"; PAUSE; return 1; }
if [ ! -s "$CONFIGPATH" ]; then echo -e "\n${RED}Файл пустой или не создан:${NC} $CONFIGPATH\n"; PAUSE; return 1; fi; /etc/init.d/magitrickle enable >/dev/null 2>&1; /etc/init.d/magitrickle reload >/dev/null 2>&1; /etc/init.d/magitrickle start >/dev/null 2>&1; /etc/init.d/magitrickle restart >/dev/null 2>&1; echo -e "${GREEN}Список успешно изменён!${NC}\n"; PAUSE; fi; }
check_status() { MIHOMO_STATUS="${RED}не установлен${NC}"; HEV_STATUS="${RED}не установлен${NC}"; MAGITRICKLE_STATUS="${RED}не установлен${NC}"; if [ -x /etc/init.d/mihomo ]; then
STATUS=$(/etc/init.d/mihomo status 2>/dev/null); case "$STATUS" in running|active) MIHOMO_STATUS="${GREEN}запущен${NC}" ;; *) MIHOMO_STATUS="${RED}остановлен${NC}" ;; esac; fi
if [ -x /etc/init.d/hev-socks5-tunnel ]; then STATUS=$(/etc/init.d/hev-socks5-tunnel status 2>/dev/null); case "$STATUS" in running|active) HEV_STATUS="${GREEN}запущен${NC}" ;;
*) HEV_STATUS="${RED}остановлен${NC}" ;; esac; fi; if [ -x /etc/init.d/magitrickle ]; then STATUS=$(/etc/init.d/magitrickle status 2>/dev/null)
case "$STATUS" in running|active) MAGITRICKLE_STATUS="${GREEN}запущен${NC}" ;; *) MAGITRICKLE_STATUS="${RED}остановлен${NC}" ;; esac; fi; echo -e "${YELLOW}Mihomo:${NC}              $MIHOMO_STATUS"
echo -ne "${YELLOW}MagiTrickle:${NC}         $MAGITRICKLE_STATUS"; [ -n "$Magi_INSTALL_VER" ] && { if [ "$Magi_INSTALL_VER" != "$MT_VERSION" ]; then echo -e " / ${RED}$Magi_INSTALL_VER (версия устарела)${NC}"; else echo -e " / ${GREEN}$Magi_INSTALL_VER${NC}"; fi; } || echo; echo -e "${YELLOW}HevSocks5Tunnel:${NC}     $HEV_STATUS"; }
PODPISKA() { echo -ne "\n${YELLOW}Введите ссылку на подписку (${CYAN}https://...${YELLOW}): ${NC}"; read -r SUB_URL; case "$SUB_URL" in http://*|https://*) ;;
*) echo -e "\n${RED}Ошибка! Ссылка должна начинаться с ${NC}http:// ${RED}или ${NC}https://${NC}\n"; PAUSE; return ;; esac; /etc/init.d/mihomo stop; rm -rf /etc/mihomo/proxy-providers /etc/mihomo/proxies/
SUB_URL_ESC=$(printf '%s' "$SUB_URL" | sed 's/[&|]/\\&/g'); if grep -q "^[[:space:]]*proxy-providers:" "$CONFIGMIX" 2>/dev/null; then TMP_FILE=$(mktemp)
if awk -v url="$SUB_URL_ESC" 'BEGIN { updated = 0 } { if ($0 ~ /^[[:space:]]*type:[[:space:]]*http[[:space:]]*$/) { print; getline; if ($0 ~ /^[[:space:]]*url:[[:space:]]*"/) { sub(/url:[[:space:]]*".*"/, "url: \"" url "\""); updated = 1 } print; next } print } END { exit (updated ? 0 : 1) }' "$CONFIGMIX" > "$TMP_FILE"
then mv "$TMP_FILE" "$CONFIGMIX"; /etc/init.d/mihomo reload >/dev/null 2>&1; /etc/init.d/mihomo restart >/dev/null 2>&1; echo -e "\n${GREEN}Подписка успешно обновлена!${NC}\n"; PAUSE; rm -f "$TMP_FILE"; return; else rm -f "$TMP_FILE"; echo -e "\n${YELLOW}Не удалось обновить URL в конфиге, создаем новый конфиг${NC}\n"; fi; fi
printf '%s\n' 'mode: rule' 'ipv6: false' 'mixed-port: 7890' 'log-level: error' 'allow-lan: false' 'unified-delay: true' 'tcp-concurrent: false' 'find-process-mode: off' 'external-controller: 0.0.0.0:9090' 'external-ui: ./ui' 'routing-mark: 2' 'profile:' '  store-selected: true' '  store-fake-ip: true' '  tracing: true' 'sniffer:' '  enable: true' '  force-dns-mapping: true' '  parse-pure-ip: true' '  sniff:' '    HTTP:' '      ports: [80]' '      override-destination: true' '    TLS:' '      ports: [443, 8443]' '    QUIC:' '      ports: [443, 8443]' '  skip-domain:' '    - Mijia Cloud' '    - +.lan' '    - +.local' '    - +.msftconnecttest.com' '    - +.msftncsi.com' '    - +.3gppnetwork.org' '    - +.openwrt.org' '    - +.vsean.net' '    - cudy.net' '' 'hosts:' '  ntc.party: 130.255.77.28' '' 'proxies:' '' '  - name: "Домашний интернет"' '    type: direct' '' 'proxy-providers:' '' '  Подписка:' '    type: http' "    url: \"$SUB_URL\"" '    exclude-filter: "LTE|Мобильный|🇪🇺"' '    path: ./proxy-providers/sub.yaml' '    interval: 86400' '    health-check:' '      enable: true' '      url: http://www.gstatic.com/generate_204' '      interval: 300' '      timeout: 5000' '      lazy: true' '' 'proxy-groups:' '' '  - name: "Сервер для YouTube"' '    type: select' '    icon: https://www.clashverge.dev/assets/icons/youtube.svg' '    proxies:' '      - "Домашний интернет"' '    use:' '      - "Подписка"' '' '  - name: "Сервер для остального трафика"' '    type: select' '    icon: https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.3/assets/svg/1f310.svg' '    use:' '      - "Подписка"' '' 'rule-providers:' '' '  youtube:' '    type: http' '    format: yaml' '    behavior: classical' '    url: "${GH_RAW}/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"' '    path: ./rule-providers/youtube-list.yaml' '    interval: 86400' '' 'rules:' '  - RULE-SET,youtube,Сервер для YouTube' '  - MATCH,Сервер для остального трафика' > "$CONFIGMIX"
/etc/init.d/mihomo reload >/dev/null 2>&1; /etc/init.d/mihomo restart >/dev/null 2>&1; echo -e "\n${GREEN}Подписка успешно применена!${NC}\n"; PAUSE; }
UI_INSTALL() { while true; do echo -e "\n${MAGENTA}Выбор панели для Mihomo${NC} "; echo -e "${CYAN}1) ${GREEN}Установить ${NC}Zashboard"; echo -e "${CYAN}2) ${GREEN}Установить ${NC}MetaCubeXD"
echo -e "${CYAN}Enter) ${GREEN}Выход в меню Mixomo${NC}\n"; echo -en "${YELLOW}Выберите пункт:${NC} "; read -r choice; case "$choice" in 1) echo -e "\n${MAGENTA}Устанавливаем Zashboard${NC}"
rm -rf /etc/mihomo/ui; for i in 1 2 3; do curl -fL --connect-timeout 3 --max-time 7 -o /tmp/zashboard.zip ${GH_MAIN}/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip >/dev/null 2>&1 && break
sleep 1; done; [ -f /tmp/zashboard.zip ] || { echo -e "\n${RED}Ошибка загрузки Zashboard${NC}\n"; PAUSE; return; }; mkdir -p /etc/mihomo/ui; rm -rf /etc/mihomo/ui/*; rm -rf /tmp/zashboard
if ! command -v unzip >/dev/null 2>&1; then echo -e "${CYAN}Устанавливаем ${NC}unzip"; update_packages || return; $INSTALL unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить ${NC}unzip\n"; PAUSE; return; }; fi
unzip -oq /tmp/zashboard.zip -d /tmp/zashboard || { echo -e "\n${RED}Ошибка распаковки архива${NC}\n"; rm -rf /tmp/zashboard.zip /tmp/zashboard; PAUSE; return; }; cp -r /tmp/zashboard/dist/* /etc/mihomo/ui/
rm -rf /tmp/zashboard.zip /tmp/zashboard; echo -e "\nZashboard${GREEN} успешно установлен${NC}\n"; PAUSE; break ;; 2) echo -e "\n${MAGENTA}Устанавливаем MetaCubeXD${NC}"; rm -rf /etc/mihomo/ui; for i in 1 2 3
do curl -fL --connect-timeout 3 --max-time 7 -o /tmp/metacubexd.tgz ${GH_MAIN}/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz >/dev/null 2>&1 && break; sleep 1; done
[ -f /tmp/metacubexd.tgz ] || { echo -e "\n${RED}Ошибка загрузки MetaCubeXD${NC}\n"; PAUSE; return; }; mkdir -p /etc/mihomo/ui; rm -rf /etc/mihomo/ui/*; rm -rf /tmp/metacubexd; mkdir -p /tmp/metacubexd
tar -xzf /tmp/metacubexd.tgz -C /tmp/metacubexd || { echo -e "\n${RED}Ошибка распаковки архива${NC}\n"; rm -rf /tmp/metacubexd.tgz /tmp/metacubexd; PAUSE; return; }; cp -r /tmp/metacubexd/* /etc/mihomo/ui/
rm -rf /tmp/metacubexd.tgz /tmp/metacubexd; echo -e "\nMetaCubeXD${GREEN} успешно установлен${NC}\n"; PAUSE; break ;; *) return ;; esac; done; }
MIXOMO_RESTART() { if grep -qF "$CRON_CMD" "$CRON_FILE" 2>/dev/null; then sed -i "\|$CRON_CMD|d" "$CRON_FILE"; /etc/init.d/cron restart; echo -e "\n${GREEN}Автоперезапуск ${NC}Mihomo${GREEN} отключен!${NC}\n"
PAUSE; return; fi; echo -e "\n${MAGENTA}Выбор режима автоперезапуска${NC}"; echo -e "${CYAN}1) ${GREEN}Каждые ${NC}2–22${GREEN} часа${NC}\n${CYAN}2) ${GREEN}Ежедневно в указанное время${NC}"
echo -ne "${CYAN}Enter) ${GREEN}Выход в меню Mixomo${NC}\n\n${YELLOW}Выберите пункт:${NC} "; read MODE; case "$MODE" in 1) while :; do echo -en "\n${YELLOW}Введите интервал (${NC}2,4,6,8,10,12,14,16,18,20,22${YELLOW}):${NC} "
read HOURS; case "$HOURS" in 2|4|6|8|10|12|14|16|18|20|22) break ;; *) echo -e "\n${RED}Ошибка! Только чётные значения от ${NC}2 ${RED}до ${NC}22\n"; PAUSE; return ;; esac; done; echo "0 */$HOURS * * * $CRON_CMD" >> "$CRON_FILE"
/etc/init.d/cron restart; echo -e "\n${GREEN}Автоперезапуск ${NC}Mihomo ${GREEN}включен!${NC}\n"; PAUSE ;; 2) while :; do echo -en "\n${YELLOW}Введите час перезапуска (${NC}0,1,...,22,23${YELLOW}):${NC} "
read HOUR; case "$HOUR" in ''|*[!0-9]*) echo -e "\n${RED}Ошибка! Введите число от ${NC}0 ${RED}до ${NC}23\n"; PAUSE; return ;; esac; HOUR=$((HOUR + 0)); if [ "$HOUR" -lt 0 ] || [ "$HOUR" -gt 23 ]
then echo -e "\n${RED}Ошибка! Диапазон должен быть от ${NC}0 ${RED}до ${NC}23\n"; PAUSE; return; fi; break; done; echo "0 $HOUR * * * $CRON_CMD" >> "$CRON_FILE"; /etc/init.d/cron restart
echo -e "\n${GREEN}Автоперезапуск ${NC}Mihomo ${GREEN}включен!${NC}\n"; PAUSE ;; *) return ;; esac; }
check_mihomo() { if [ ! -f /etc/init.d/mihomo ]; then echo -e "\n${RED}Mixomo не установлен!${NC}\n"; PAUSE; return 1; fi; return 0; }
MIXOMO_MENU() { while true; do LINECRON=$(grep -F "/etc/init.d/mihomo restart" /etc/crontabs/root 2>/dev/null | head -n 1); if command -v apk >/dev/null 2>&1; then Magi_INSTALL_VER="$(apk info -v 2>/dev/null | grep '^magitrickle-' | cut -d- -f2)"
else Magi_INSTALL_VER="$(opkg status magitrickle 2>/dev/null | awk '/^Version:/ {sub(/-1$/,"",$2); sub(/-r1$/,"",$2); print $2}')"; fi; clear; echo -e "${MAGENTA}Меню Mixomo${NC}\n"; check_status; [ -f /etc/mihomo/config.yaml ] && grep -q "engage.cloudflareclient.com" /etc/mihomo/config.yaml && echo -e "${YELLOW}WARP endpoint:       ${CYAN}Россия${NC}"
if [ -f "$CONFIGPATH" ]; then if grep -Fq 'name: Google_ai' "$CONFIGPATH"; then echo -e "${YELLOW}Используется список: ${NC}ITDog"; elif grep -Fq 'name: Meta (WA+FB+Instagram)' "$CONFIGPATH"
then echo -e "${YELLOW}Используется список: ${NC}Internet Helper #2"; elif grep -Fq 'url: https://sw.ext.io/ipset/ipset_cf.list' "$CONFIGPATH"; then echo -e "${YELLOW}Используется список: ${NC}Internet Helper #1"; fi; fi
[ -f /root/WARP.conf ] && echo -e "${YELLOW}WARP.conf в /root/:${NC}  ${GREEN}присутствует${NC}"; if [ -n "$LINECRON" ]; then HOURM=$(echo "$LINECRON" | awk '{print $2}'); if echo "$HOURM" | grep -q "/"; then INTERVAL=$(echo "$HOURM" | cut -d'/' -f2)
echo -e "${YELLOW}Автоперезапуск Mihomo: ${GREEN}каждые ${NC}$INTERVAL ${GREEN}часа(ов)"; else echo -e "${YELLOW}Автоперезапуск Mihomo: ${GREEN}ежедневно в ${NC}$(printf "%02d" "$HOURM"):00"; fi; fi
[ -f /etc/mihomo/config.yaml ] && echo -e "${YELLOW}Web-интерфейс Mihomo:${NC}       ${CYAN}$LAN_IP:9090/ui${NC}"; [ -f "$CONFIGPATH" ] && echo -e "${YELLOW}Web-интерфейс MagiTrickle:${NC}  ${CYAN}$LAN_IP:8080${NC}"
echo -e "\n${CYAN}1) ${GREEN}Установить ${NC}Mixomo"; echo -e "${CYAN}2) ${GREEN}Удалить ${NC}Mixomo"; echo -e "${CYAN}3) ${GREEN}Сменить список ${NC}MagiTrickle"; if [ -f /etc/mihomo/config.yaml ] && grep -q '^[[:space:]]*[^#].*url: "' /etc/mihomo/config.yaml
then echo -e "${CYAN}4) ${GREEN}Сменить ${NC}VPN${GREEN} подписку${NC}"; else echo -e "${CYAN}4) ${GREEN}Интегрировать ${NC}VPN${GREEN} подписку в ${NC}Mihomo${NC}"; fi; echo -e "${CYAN}5) ${GREEN}Сгенерировать ${NC}WARP"
echo -e "${CYAN}6) ${GREEN}Интегрировать ${NC}/root/WARP.conf${GREEN} в ${NC}Mihomo"; echo -e "${CYAN}7) ${GREEN}Выбрать и установить панель для ${NC}Mihomo"; if grep -qF "/etc/init.d/mihomo restart" /etc/crontabs/root 2>/dev/null
then echo -e "${CYAN}8) ${GREEN}Выключить автоперезапуск ${NC}Mihomo"; else echo -e "${CYAN}8) ${GREEN}Включить автоперезапуск ${NC}Mihomo"; fi; [ -n "$Magi_INSTALL_VER" ] && { [ "$Magi_INSTALL_VER" != "$MT_VERSION" ] && echo -e "${CYAN}9) ${GREEN}Обновить ${NC}MagiTrickle"; }
echo -e "${CYAN}Enter) ${GREEN}Выход в главное меню\n"; echo -ne "${YELLOW}Выберите пункт: ${NC}"; read choiceM; case "$choiceM" in 1) wget -q -O - ${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/Mixomo/mixomo_openwrt_install.sh | sh; PAUSE ;;
2) wget -q -O - ${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/Mixomo/mixomo_openwrt_delete.sh | sh; sed -i "\|$CRON_CMD|d" "$CRON_FILE" >/dev/null 2>&1; /etc/init.d/cron restart >/dev/null 2>&1; echo -e "\n${YELLOW}Рекомендую сделать перезагрузку роутера!${NC}\n"; PAUSE ;;
3) check_mihomo || continue; magitrickle_config ;; 4) check_mihomo || continue; PODPISKA ;; 5) register_warp || return 1; choose_endpoint || return 1; WARP_TO_ROOT; echo; PAUSE ;; 6) check_mihomo || continue; wget -q -O - ${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/Mixomo/WARP_to_conf.sh | sh; echo; PAUSE ;;
7) check_mihomo || continue; UI_INSTALL ;; 8) check_mihomo || continue; MIXOMO_RESTART ;; 9) check_mihomo || continue; ARCH_MT=$(grep "^OPENWRT_ARCH=" /etc/os-release | cut -d'"' -f2); FILE_MT="/tmp/magitrickle.$RAZ"; URL_MT="${GH_MAIN}/MagiTrickle/MagiTrickle/releases/download/${MT_VERSION}/magitrickle_${MT_VERSION}-${SUF_MT}1_openwrt_${ARCH_MT}.$RAZ"
echo -e "\n${MAGENTA}Обновляем MagiTrickle\n${CYAN}Скачиваем\n${NC}$URL_MT"; curl -Lf --connect-timeout 6 --retry 3 --retry-delay 1 -o "$FILE_MT" "$URL_MT" >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка скачивания${NC}\n"; PAUSE; return 1; };  update_packages || return 1
echo -e "${CYAN}Обновляем ${NC}MagiTrickle"; $INSTALL "$FILE_MT" >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка установки${NC} $(basename "$URL_MT")\n"; rm -f "$FILE_MT"; PAUSE; return 1; }; /etc/init.d/magitrickle enable >/dev/null 2>&1; /etc/init.d/magitrickle restart >/dev/null 2>&1; echo -e "MagiTrickle ${GREEN}обновлён!${NC}\n"; rm -f "$FILE_MT"; PAUSE ;; *) return ;; esac; done; }
# ==========================================
# Собственная стратегия
# ==========================================
clean_new_lines() { awk '{ lines[NR]=$0 } END { n=NR; m=0; for (i=1; i<=n; i++) { if (lines[i]=="--new" && (i+2)<=n && lines[i+1] ~ /^#/ && lines[i+2]=="--new") continue; m++; out[m]=lines[i] } k=0; for (i=1; i<=m; i++) { if (out[i]=="--new" && k>0 && res[k]=="--new") continue; k++; res[k]=out[i] } start=1; end=k; while (start<=end && res[start]=="--new") start++; while (end>=start && res[end]=="--new") end--; while (start<=end && res[start] ~ /^#/ && (start+1)<=end && res[start+1]=="--new") { start2=start+1; for (j=start2; j<end; j++) res2[j]=res[j+1]; end=end-1; for (j=start2; j<=end; j++) res[j]=res2[j] } for (i=start; i<=end; i++) print res[i] }'; }
build_custom_strategy() { [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; mkdir -p "$TMP_SF"; clear; echo -e "${MAGENTA}Собираем собственную стратегию${NC}"
echo -e "\n${CYAN}Основная ${NC}v${CYAN} стратегия${NC}"; MV_MAX=0; i=1; while type "strategy_v$i" >/dev/null 2>&1; do MV_MAX=$i; i=$((i + 1)); done; echo -ne "${YELLOW}Введите версию (${NC}1-$MV_MAX${YELLOW}) или ${NC}0${YELLOW} — без стратегии:${NC} "; read -r MV
MAIN_BODY=""; if [ "$MV" -ge 1 ] 2>/dev/null && [ "$MV" -le "$MV_MAX" ]; then MAIN_BODY="$(strategy_v"$MV")"; fi
TRAFFIC="all"; if [ -n "$MAIN_BODY" ]; then echo -e "\n${CYAN}Выберите трафик для стратегии${NC}"; echo -e "${CYAN}1) ${GREEN}Весь трафик${NC}\n${CYAN}2) ${GREEN}Только по спискам ${NC}РКН\n${CYAN}3) ${GREEN}Только ${NC}Discord"
echo -ne "\n${YELLOW}Выберите пункт:${NC} "; read -r TR; case "$TR" in 2) TRAFFIC="rkn" ;; 3) TRAFFIC="discord" ;; *) TRAFFIC="all" ;; esac; case "$TRAFFIC" in rkn) MAIN_BODY=$(printf '%s\n' "$MAIN_BODY" | sed 's|--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt|--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt|') ;;
discord) MAIN_BODY=$(printf '%s\n' "$MAIN_BODY" | sed "s|--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt|--hostlist=$DISCORD_DEF_HOSTLIST|") ;; esac; fi
echo -e "\n${CYAN}Стратегия для ${NC}YouTube"; curl -fsSL "$STR_URL" -o "$TMP_LIST" 2>/dev/null; YV_LIST_FILE="$TMP_SF/custom_yv_list.txt"; : > "$YV_LIST_FILE"; [ -s "$TMP_LIST" ] && while IFS= read -r LINE; do case "$LINE" in \#Yv[0-9]*) echo "$LINE" >> "$YV_LIST_FILE";; esac; done < "$TMP_LIST"
YV_COUNT=$(wc -l < "$YV_LIST_FILE" 2>/dev/null); YV_COUNT=${YV_COUNT:-0}; YV_BODY=""; YV_NAME=""; if [ "$YV_COUNT" -gt 0 ]; then echo -ne "${YELLOW}Введите версию (${NC}1-$YV_COUNT${YELLOW}) или ${NC}0${YELLOW} — без стратегии:${NC} "; read -r YVCH
if [ -n "$YVCH" ] && [ "$YVCH" != "0" ]; then YV_NAME=$(sed -n "${YVCH}p" "$YV_LIST_FILE"); if [ -n "$YV_NAME" ]; then YV_BODY_FILE="$TMP_SF/custom_yv_body.txt"; : > "$YV_BODY_FILE"; FLAG=0; while IFS= read -r LINE; do [ "$LINE" = "$YV_NAME" ] && FLAG=1 && continue
case "$LINE" in \#Yv[0-9]*) FLAG=0;; esac; [ "$FLAG" -eq 1 ] && printf "%b\n" "$LINE" >> "$YV_BODY_FILE"; done < "$TMP_LIST"; YV_BODY=$(cat "$YV_BODY_FILE"); fi; fi; else echo -e "\n${RED}Не удалось получить список стратегий для YouTube!${NC}\n"; fi
echo -e "\n${CYAN}Cтратегия для ${NC}игр"; echo -ne "${YELLOW}Введите версию (${NC}1-4${YELLOW}) или ${NC}0${YELLOW} — без стратегии:${NC} "; read -r GVCH; GV_BODY=""; case "$GVCH" in 1) GV_BODY="$(strategy_Gv1; strategy_TCP_common)" ;; 2|3|4) GV_BODY="$(strategy_Gv "$GVCH"; strategy_TCP_common)" ;; esac
echo -e "\n${CYAN}Стратегия для ${NC}discord.media"; DV_MAX=$(set | grep -oE '^Dv[0-9]+=' | sed 's/^Dv//;s/=//' | sort -n | tail -1); DV_MAX=${DV_MAX:-0}; echo -ne "${YELLOW}Введите версию (${NC}1-$DV_MAX${YELLOW}) или ${NC}0${YELLOW} — без стратегии:${NC} "; read -r DVCH
DV_SEG=""; if [ "$DVCH" -ge 1 ] 2>/dev/null && [ "$DVCH" -le "$DV_MAX" ]; then DV_BODY=$(eval "printf '%s' \"\$Dv$DVCH\"")
DISCORD_UDP_BODY=$(printf '%s\n' "--filter-udp=19294-19344,50000-50100" "--filter-l7=discord,stun" "--dpi-desync=fake" "--dpi-desync-fake-discord=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-stun=/opt/zapret/files/fake/stun.bin" "--dpi-desync-repeats=6")
DV_SEG=$(printf '%s\n%s\n--new\n%s' "$DISCORD_UDP_BODY" "#Dv$DVCH" "$DV_BODY"); fi; if [ -z "$MAIN_BODY" ] && [ -z "$YV_BODY" ] && [ -z "$GV_BODY" ] && [ -z "$DV_SEG" ]; then echo -e "\n${RED}Не выбрано ни одной стратегии, отмена!${NC}\n"; PAUSE; return; fi
FULL=""; add_segment() { seg="$1"; [ -z "$seg" ] && return; if [ -n "$FULL" ]; then FULL="$(printf '%s\n--new\n%s' "$FULL" "$seg")"; else FULL="$seg"; fi; }; [ -n "$YV_BODY" ] && add_segment "$(printf '%s\n%s' "$YV_NAME" "$YV_BODY")"
add_segment "$MAIN_BODY"; add_segment "$DV_SEG"; add_segment "$GV_BODY"; echo -e "\n${MAGENTA}Применяем собственную стратегию${NC}"; sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"; { echo "  option NFQWS_OPT '"; printf '%s\n' "$FULL" | clean_new_lines; echo "'"; } >> "$CONF"
ADD_GP_DOMAINS; case "$TRAFFIC" in rkn) echo -e "${CYAN}Скачиваем список ${NC}РКН"; [ -f "$HOSTLIST_FILE" ] && cp "$HOSTLIST_FILE" "$BACKUP_FILE"; curl -fsSL "$RKN_URL" > "$HOSTLIST_FILE" || echo -e "${RED}Не удалось скачать список РКН${NC}" ;;
discord) [ -f "$DISCORD_DEF_HOSTLIST" ] || echo -e "${RED}Файл ${NC}$DISCORD_DEF_HOSTLIST${RED} не найден!${NC}" ;; *) echo -e "${CYAN}Добавляем домены в исключения${NC}"; rm -f "$EXCLUDE_FILE"
wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL" || echo -e "${RED}Не удалось загрузить exclude файл${NC}" ;; esac; if [ -n "$GV_BODY" ]; then add_ports_if_missing NFQWS_PORTS_UDP "$PORTS_UDP"; add_ports_if_missing NFQWS_PORTS_TCP "$PORTS_TCP"; fi
if [ -n "$DV_SEG" ]; then if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'\$/,19294-19344,50000-50100'/" "$CONF"; fi
if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"; then sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'\$/,2053,2083,2087,2096,8443'/" "$CONF"; fi; fi
ZAPRET_RESTART; echo -e "\n${GREEN}Собственная стратегия применена!${NC}"; grep -Fq "$DISCORD_DEF_HOSTLIST" "$CONF" && echo -e "${YELLOW}Область применения:${NC} ${CYAN}только Discord${NC}\n"; show_ts_warning; PAUSE; }
# ==========================================
# Исключения IP
# ==========================================
Exclusions_menu() { [ ! -f /etc/init.d/zapret ] && { echo -e "\nZapret ${RED}не установлен!${NC}\n"; PAUSE; return; }; IPV4_RE='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; EXCL_FILE="${CUSTOM_DIR}20-script.sh"; LAN_DEV=$(uci -q get network.lan.device); [ -z "$LAN_DEV" ] && LAN_DEV="br-lan"; mkdir -p "$CUSTOM_DIR"; [ -f "$EXCL_FILE" ] || touch "$EXCL_FILE"
while true; do clear; echo -e "${MAGENTA}Меню исключений IP из Zapret${NC}\n"; CURRENT_EXCL=$(grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$EXCL_FILE" 2>/dev/null | sort -u); DEV_LIST="$TMP_SF/zapret_excl_devices.txt"; LEASE_TMP="$TMP_SF/zapret_excl_leases.txt"
mkdir -p "$TMP_SF"; : > "$DEV_LIST"; : > "$LEASE_TMP"; if [ -f /tmp/dhcp.leases ]; then while read -r _ts _mac _ip _name _rest; do [ -z "$_ip" ] && continue; echo "$_ip" | grep -qE "$IPV4_RE" || continue; [ -z "$_name" ] || [ "$_name" = "*" ] && _name="Неизвестное устройство"
printf '%s|%s|%s\n' "$_ip" "$_name" "$_mac" >> "$LEASE_TMP"; printf '%s|%s\n' "$_ip" "$_name" >> "$DEV_LIST"; done < /tmp/dhcp.leases; fi; if [ -f /proc/net/arp ]; then tail -n +2 /proc/net/arp | while read -r _ip _hwtype _flags _mac _mask _dev
do [ -z "$_ip" ] && continue; [ "$_dev" = "$LAN_DEV" ] || continue; echo "$_ip" | grep -qE "$IPV4_RE" || continue; [ "$_flags" = "0x0" ] && continue; grep -qxE "${_ip}\|.*" "$DEV_LIST" 2>/dev/null && continue
NAME_BY_MAC=$(grep -iF "|${_mac}" "$LEASE_TMP" 2>/dev/null | head -n1 | cut -d'|' -f2); if [ -z "$NAME_BY_MAC" ] || [ "$NAME_BY_MAC" = "Неизвестное устройство" ]; then NAME_BY_MAC=$(logread 2>/dev/null | grep -i "DHCPACK" | grep -i "$_ip" | grep -i "$_mac" | tail -n1 | awk '{print $NF}')
[ "$NAME_BY_MAC" = "$_mac" ] && NAME_BY_MAC=""; fi; [ -n "$NAME_BY_MAC" ] || NAME_BY_MAC="Неизвестное устройство"; printf '%s|%s\n' "$_ip" "$NAME_BY_MAC" >> "$DEV_LIST"; done; fi; rm -f "$LEASE_TMP"
if [ -n "$CURRENT_EXCL" ]; then for ip in $CURRENT_EXCL; do grep -qxE "${ip}\|.*" "$DEV_LIST" 2>/dev/null || printf '%s|%s\n' "$ip" "Устройство offline" >> "$DEV_LIST"; done; fi
[ -s "$DEV_LIST" ] && sort -t. -k1,1n -k2,2n -k3,3n -k4,4n -o "$DEV_LIST" "$DEV_LIST"; echo -e "${YELLOW}Обнаруженные устройства:${NC}"; i=1; IDX_LIST="$TMP_SF/zapret_excl_index.txt"; : > "$IDX_LIST"; COUNTI=$(wc -l < "$DEV_LIST")
PAD=""; [ "$COUNTI" -ge 10 ] && PAD=" "; if [ -s "$DEV_LIST" ]; then while IFS='|' read -r ip name; do mark="${GREEN}●${NC}"; if [ -n "$CURRENT_EXCL" ] && echo "$CURRENT_EXCL" | grep -qx "$ip"; then mark="${RED}●${NC}"; fi
echo -e "${CYAN}${PAD}${i}) ${mark} ${ip} ${CYAN}-${NC} ${name}"; echo "$ip" >> "$IDX_LIST"; i=$((i + 1)); done < "$DEV_LIST"; else echo -e "${RED}Устройства не найдены!${NC}"; fi; echo -e "\n${CYAN}a) ${GREEN}Добавить ${NC}IP${GREEN} вручную${NC}"
echo -e "${CYAN}c) ${GREEN}Очистить ${NC}все${GREEN} исключения\n${CYAN}r) ${GREEN}Обновить ${NC}список${GREEN} устройств\n${CYAN}Enter) ${GREEN}Выход в системное меню${NC}\n"; echo -ne "${YELLOW}Выберите пункт:${NC} "; read -r sel; case "$sel" in
"") rm -f "$DEV_LIST" "$IDX_LIST"; return;; r|R|к|К) rm -f "$DEV_LIST" "$IDX_LIST"; BASE=$(echo "${LAN_IP:-192.168.1.1}" | cut -d. -f1-3); echo -en "\n${CYAN}Сканируем локальную сеть\n${YELLOW}Подождите...${NC}"
RUN=0; for oct in $(seq 1 254); do ping -c1 -W1 "${BASE}.${oct}" >/dev/null 2>&1 & RUN=$((RUN+1)); if [ "$RUN" -ge 32 ]; then wait; RUN=0; fi; done; wait; echo -e "\n${GREEN}Список обновлён!${NC}\n"; PAUSE; continue;;
a|A|ф|Ф) echo -ne "\n${YELLOW}Введите IPv4 адрес: ${NC}"; read -r manual_ip; if echo "$manual_ip" | grep -qE "$IPV4_RE"; then CURRENT_EXCL=$(printf '%s\n%s\n' "$CURRENT_EXCL" "$manual_ip")
ACTION_MSG="${GREEN}IP ${NC}${manual_ip}${GREEN} добавлен в исключения!${NC}"; else echo -e "\n${RED}Некорректный IPv4 адрес!${NC}\n"; PAUSE; rm -f "$DEV_LIST" "$IDX_LIST"; continue; fi;;
c|C|с|С) CURRENT_EXCL=""; ACTION_MSG="${GREEN}Все исключения очищены!${NC}";; *) case "$sel" in *[!0-9\ ]*) rm -f "$DEV_LIST" "$IDX_LIST"; return;; esac; CHANGED=0; for num in $sel; do
ip=$(sed -n "${num}p" "$IDX_LIST"); if [ -z "$ip" ]; then rm -f "$DEV_LIST" "$IDX_LIST"; return; fi; if echo "$CURRENT_EXCL" | grep -qx "$ip"; then CURRENT_EXCL=$(echo "$CURRENT_EXCL" | grep -vx "$ip"); ACTION_MSG="${GREEN}IP ${NC}${ip}${GREEN} удалён из исключений!${NC}"
else CURRENT_EXCL=$(printf '%s\n%s\n' "$CURRENT_EXCL" "$ip"); ACTION_MSG="${GREEN}IP ${NC}${ip}${GREEN} добавлен в исключения!${NC}"; fi; CHANGED=1; done ;; esac; CURRENT_EXCL=$(echo "$CURRENT_EXCL" | grep -v '^$' | sort -u)
if [ -n "$CURRENT_EXCL" ]; then FORMATTED=$(echo "$CURRENT_EXCL" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g'); { echo "EXCEPT_SRC='{ $FORMATTED }'"; echo "nft insert rule inet zapret postrouting_hook index 0 \\"; echo "  ip saddr \$EXCEPT_SRC meta mark set meta mark \\| 0x40000000"; } > "$EXCL_FILE"; else : > "$EXCL_FILE"; fi
echo -e "\n${CYAN}Применяем и перезапускаем ${NC}Zapret"; ZAPRET_RESTART; echo -e "\n${ACTION_MSG}\n"; PAUSE; rm -f "$DEV_LIST" "$IDX_LIST"; done; }
# ==========================================
# Package Installer
# ==========================================
PAKET_INSTALL() {
clear
echo -e "${MAGENTA}Установка пакетов из ${NC}/root/\n"

FILES=$(find /root -maxdepth 1 -type f -name "*.${RAZ}" | sort)
[ -z "$FILES" ] && {
    echo -e "${RED}Файлы ${NC}*.${RAZ}${RED} не найдены в${NC} /root\n"
    PAUSE
    return
}

echo -e "${YELLOW}Найденные пакеты ${NC}*.${RAZ}${YELLOW}:${NC}\n"

OLD_IFS=$IFS
IFS='
'
set -- $FILES
IFS=$OLD_IFS
TOTAL=$#

i=1
for f in "$@"; do
    echo -e "${CYAN}$i) ${GREEN}$(basename "$f")${NC}"
    i=$((i + 1))
done

echo -ne "\n${YELLOW}Введите порядок установки (${NC}например: 2 1 3${YELLOW}):${NC} "
read ORDER
echo

update_packages

for n in $ORDER; do
    case "$n" in
        ''|*[!0-9]*)
            echo -e "${RED}Неверный номер:${NC} $n\n"
            continue
            ;;
    esac
    if [ "$n" -lt 1 ] || [ "$n" -gt "$TOTAL" ]; then
        echo -e "${RED}Неверный номер:${NC} $n\n"
        continue
    fi

    eval "FILE=\$$n"
    if [ -f "$FILE" ]; then
        NAME=$(basename "$FILE")
        echo -e "${CYAN}Устанавливаем: ${NC}$NAME"
        $INSTALL "$FILE" >/dev/null 2>&1 || {
            echo -e "\n${RED}Ошибка установки${NC} $NAME\n"
            PAUSE
            return
        }
        echo -e "$NAME ${GREEN}установлен!${NC}\n"
    else
        echo -e "${RED}Файл не найден:${NC} $FILE\n"
    fi
done

echo -e "${GREEN}Установка завершена!${NC}\n"
PAUSE
}
# ==========================================
# Главное меню
# ==========================================
show_menu() { get_versions; get_doh_status; show_current_strategy; RKN_Check; mkdir -p "$TMP_SF"; CURR=$(curr_MIR); clear; echo -e "╔═══════════════════════════════╗\n║  ${BLUE}Zapret Manager by StressOzz${NC}  ║\n╚═══════════════════════════════╝\n"
if [ -f /etc/init.d/zapret ] && [ -f "$CONF" ] && grep -Eq "^[[:space:]]*option DISABLE_IPV6 '1'" "$CONF" && ping -6 -c 1 -W 2 google.com >/dev/null 2>&1; then echo -e "${RED}Обнаружен IPv6! ${GREEN}Включите ${NC}IPv6${GREEN} в системном меню!${NC}\n"; fi
if [ ! -f /etc/init.d/zapret ]; then Z_ACTION_TEXT="Установить"; Z_ACTION_FUNC="install_Zapret"; elif [ "$INSTALLED_VER" = "$ZAPRET_VERSION" ]; then Z_ACTION_TEXT="Удалить" Z_ACTION_FUNC="uninstall_zapret"; else Z_ACTION_TEXT="Обновить"; Z_ACTION_FUNC="install_Zapret"; fi
if [ ! -f /etc/init.d/zapret2 ]; then Z2_ACTION_TEXT="Установить"; Z2_ACTION_FUNC="install_zapret2"; elif [ "$INSTALLED_VER2" = "$ZAPRET2_VERSION" ]; then Z2_ACTION_TEXT="Удалить"; Z2_ACTION_FUNC="remove_zapret2"; else Z2_ACTION_TEXT="Обновить"; Z2_ACTION_FUNC="install_zapret2"; fi
for pkg in byedpi youtubeUnblock; do if [ "$PKG_IS_APK" -eq 1 ]; then apk info -e "$pkg" >/dev/null 2>&1 && echo -e "${RED}Найден установленный ${NC}$pkg${RED}!${NC}\nZapret${RED} может работать некорректно с ${NC}$pkg${RED}!${NC}\n"
else opkg list-installed | grep -q "^$pkg" && echo -e "${RED}Найден установленный ${NC}$pkg${RED}!${NC}\nZapret${RED} может работать некорректно с ${NC}$pkg${RED}!${NC}\n"; fi; done; if is_expert_mode && [ -f /etc/init.d/zapret2 ] && [ -f /etc/init.d/zapret ]; then SHOW_S=2
pgrep -f "/opt/zapret" >/dev/null 2>&1 && S1_ACTION="Остановить" || S1_ACTION="Запустить"; /etc/init.d/zapret2 status >/dev/null 2>&1 && S2_ACTION="Остановить" || S2_ACTION="Запустить"
elif [ -f /etc/init.d/zapret2 ]; then S_NAME="Zapret2"; /etc/init.d/zapret2 status >/dev/null 2>&1 && S_ACTION="Остановить" || S_ACTION="Запустить"; SHOW_S=1; elif [ -f /etc/init.d/zapret ]; then S_NAME="Zapret"; pgrep -f "/opt/zapret" >/dev/null 2>&1 && S_ACTION="Остановить" || S_ACTION="Запустить"; SHOW_S=1; else SHOW_S=0; fi
if uci get firewall.@defaults[0].flow_offloading 2>/dev/null | grep -q '^1$' || uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null | grep -q '^1$'; then if ! grep -q 'meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc
then echo -e "${RED}Включён ${NC}Flow Offloading${RED}!${NC}\n${NC}Zapret${RED} некорректно работает с включённым ${NC}Flow Offloading${RED}!\nПримените ${NC}FIX${RED} в системном меню!\n${NC}"; fi; fi
INFO_ZPR; if grep -qE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$EXCL_FILE" 2>/dev/null; then echo -e "${YELLOW}Исключённые IP:      ${RED}есть${NC}"; fi
echo -e "\n${CYAN}1) ${GREEN}$Z_ACTION_TEXT${NC} Zapret\n${CYAN}2) ${GREEN}$Z2_ACTION_TEXT${NC} Zapret2\n${CYAN}3) ${GREEN}Меню стратегий${NC} Zapret\n${CYAN}4) ${GREEN}Меню ${NC}splify\n${CYAN}5) ${GREEN}Меню ${NC}Mixomo\n${CYAN}6) ${GREEN}Меню ${NC}NetShift\n${CYAN}7) ${GREEN}Меню ${NC}TG WS Proxy\n${CYAN}8) ${GREEN}Меню ${NC}DNS over HTTPS\n${CYAN}9) ${GREEN}Меню настройки ${NC}Discord\n${CYAN}0) ${GREEN}Меню управления доменами в ${NC}hosts"
echo -e "${CYAN}f) ${GREEN}Удалить ${NC}→${GREEN} установить ${NC}→${GREEN} настроить${NC} Zapret\n${CYAN}m) ${GREEN}Системное меню${NC}"; [ "$SHOW_S" = "1" ] && echo -e "${CYAN}s) ${GREEN}$S_ACTION${NC} $S_NAME"
[ "$SHOW_S" = "2" ] && echo -e "${CYAN}s1) ${GREEN}$S1_ACTION${NC} Zapret\n${CYAN}s2) ${GREEN}$S2_ACTION${NC} Zapret2"; echo -e "${CYAN}i) ${GREEN}Установить пакеты из ${NC}/root/"; echo -ne "${CYAN}Enter) ${GREEN}Выход${NC}\n\n${YELLOW}Выберите пункт:${NC} " && read choice
case "$choice" in 999) echo; uninstall_zapret "1"; install_Zapret "1"; curl -fsSL ${GH_RAW}/StressOzz/Test/refs/heads/main/zapret -o "$CONF"; hosts_add "$ALL_BLOCKS"; rm -f "$EXCLUDE_FILE"; wget -q -U "Mozilla/5.0" -O "$EXCLUDE_FILE" "$EXCLUDE_URL"; ZAPRET_RESTART; PAUSE;;
2) $Z2_ACTION_FUNC;; I|i|ш|Ш) PAKET_INSTALL;; s|S|ы|Ы) toggle_zapret;; f|F|а|А) zapret_key;; s1|S1|ы1|Ы1) toggle_zapret1_only;; s2|S2|ы2|Ы2) toggle_zapret2_only;; 1) $Z_ACTION_FUNC;; 3) menu_str;; 4) SPL_MENU ;; 5) MIXOMO_MENU;; 6) PODKOP_menu ;; 7) menu_TG;; 8) DoH_menu;; 9) Discord_menu;; 0) menu_hosts;; m|M|ь|Ь) sys_menu;; r|R|к|К) show_menu;; *) echo; exit 0;; esac; }
case "$1" in --auto-best) auto_apply_best_strategy; exit 0 ;; esac; while true; do show_menu; done
