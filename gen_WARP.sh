#!/bin/sh

EP_LIST='Россия    |engage.cloudflareclient.com:4500
Россия #2 |engage.cloudflareclient.com:2408
Россия #3 |engage.cloudflareclient.com:500'

#Америка    |usa.tribukvy.ltd:4500
#Нидерланды |nl.tribukvy.ltd:4500
#Финляндия  |fi1.tribukvy.ltd:4500
#Россия #4  |ru0.tribukvy.ltd:4500
#Эстония    |ee.tribukvy.ltd:4500
#Польша     |pl.tribukvy.ltd:4500'

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"

clear

chose_endpoint() {
while true; do
echo -e "${CYAN}Тестируем пинг до ${NC}endpoint\n"
TMP_FILE=$(mktemp)
while IFS='|' read -r country ep; do
(
host="${ep%%:*}"
ping_ms="$(ping -c2 -W2 "$host" 2>/dev/null | awk -F'/' 'END{print int($5)}')"
if [ -z "$ping_ms" ] || [ "$ping_ms" -eq 0 ]; then
ping_val="FAIL"
ping_sort=9999
else
ping_val="${ping_ms} ms"
ping_sort="$ping_ms"
fi
echo "${ping_sort}|${country}|${ep}|${ping_val}" >> "$TMP_FILE"
) &
done <<EOF
$EP_LIST
EOF
wait

SORTED_LIST=$(sort -t'|' -k1n "$TMP_FILE")
rm -f "$TMP_FILE"

i=1
echo "$SORTED_LIST" | while IFS='|' read -r ping_sort country ep ping_val; do
if [ "$ping_val" = "FAIL" ]; then
color="$RED"
else
ping_num=${ping_val%% *}
if [ "$ping_num" -lt 50 ]; then
color="$GREEN"
elif [ "$ping_num" -lt 100 ]; then
color="$YELLOW"
else
color="$RED"
fi
fi
printf "${CYAN}%d) ${GREEN}%-10s${MAGENTA}| ${color}%-7s${MAGENTA}| ${CYAN}%s${NC}\n" "$i" "$country" "$ping_val" "$ep"
i=$((i+1))
done

echo -e "${CYAN}0) ${YELLOW}Обновить пинг${NC}"

echo -en "\n${YELLOW}Выберите страну (Enter = Россия):${NC} "
read num

MAX_NUM=$(echo "$SORTED_LIST" | wc -l)

if [ -z "$num" ]; then
ENDPOINT="engage.cloudflareclient.com:4500"
break
fi

if [ "$num" = "0" ]; then
clear
continue
fi

if ! printf '%s' "$num" | grep -qE '^[0-9]+$' || [ "$num" -lt 1 ] || [ "$num" -gt "$MAX_NUM" ]; then
ENDPOINT="engage.cloudflareclient.com:4500"
break
fi

ENDPOINT="$(echo "$SORTED_LIST" | sed -n "${num}p" | cut -d'|' -f3)"
[ -z "$ENDPOINT" ] && ENDPOINT="engage.cloudflareclient.com:4500"
break

done
echo
}

echo -e "${MAGENTA}Генерируем WARP${NC}"

if command -v apk >/dev/null 2>&1; then
PKG="apk"
elif command -v opkg >/dev/null 2>&1; then
PKG="opkg"
else
echo -e "${RED}Не найден пакетный менеджер!${NC}"
exit 1
fi

echo -e "${CYAN}Проверяем зависимости${NC}"

deps="wireguard-tools curl jq"
missing=""

for pkg in $deps; do
if [ "$PKG" = "apk" ]; then
apk info -e "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
else
opkg list-installed 2>/dev/null | grep -q "^$pkg " || missing="$missing $pkg"
fi
done

if [ -n "$missing" ]; then
echo -e "${CYAN}Обновляем пакеты${NC}"
if [ "$PKG" = "apk" ]; then
apk update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка обновления пакетов!${NC}"; exit 1; }
else
opkg update >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка обновления пакетов!${NC}"; exit 1; }
fi

install_pkg() {
pkg="$1"
if [ "$PKG" = "apk" ]; then
apk info -e "$pkg" >/dev/null 2>&1 && return
echo -e "${GREEN}Устанавливаем:${NC} $pkg"
apk add "$pkg" >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка установки${NC} $pkg"; exit 1; }
else
opkg list-installed 2>/dev/null | grep -qF "^$pkg " && return
echo -e "${GREEN}Устанавливаем:${NC} $pkg"
opkg install "$pkg" >/dev/null 2>&1 || { echo -e "\n${RED}Ошибка установки${NC} $pkg"; exit 1; }
fi
}

for pkg in $missing; do
install_pkg "$pkg"
done
fi

echo -e "${CYAN}Генерируем ключи${NC}"
priv="$(wg genkey)"
pub="$(printf "%s" "$priv" | wg pubkey)"

api="https://api.cloudflareclient.com/v0i1909051800"

ins() {
curl -s \
-H "User-Agent: okhttp/3.12.1" \
-H "Content-Type: application/json" \
-X "$1" "$api/$2" "${@:3}"
}

sec() {
ins "$1" "$2" -H "Authorization: Bearer $3" "${@:4}"
}

echo -e "${CYAN}Регистрируем устройство в ${NC}Cloudflare"

response=$(ins POST "reg" \
-d "{\"install_id\":\"\",\"tos\":\"$(date -u +%FT%TZ)\",\"key\":\"${pub}\",\"fcm_token\":\"\",\"type\":\"ios\",\"locale\":\"en_US\"}")

id=$(echo "$response" | jq -r '.result.id')
token=$(echo "$response" | jq -r '.result.token')

if [ -z "$id" ] || [ "$id" = "null" ]; then
    echo -e "${RED}Ошибка регистрации${NC} $response"
    if [ "$(/etc/init.d/zapret status 2>/dev/null)" = "running" ]; then
        echo -e "${YELLOW}Zapret запущен. Направьте через него ${NC}cloudflareclient.com${YELLOW} и повторите попытку.${NC}"
    else
        echo -e "${YELLOW}Требуется установленный и запущенный ${NC}Zapret${YELLOW} с маршрутизацией ${NC}cloudflareclient.com${YELLOW} через него.${NC}"
    fi
    exit 1
fi

################################################################################################
chose_endpoint
################################################################################################

echo -e "${GREEN}Активируем и генерируем ${NC}WARP${NC}"

response=$(sec PATCH "reg/${id}" "$token" -d '{"warp_enabled":true}')

peer_pub=$(echo "$response" | jq -r '.result.config.peers[0].public_key')
client_ipv4=$(echo "$response" | jq -r '.result.config.interface.addresses.v4')
client_ipv6=$(echo "$response" | jq -r '.result.config.interface.addresses.v6')

if [ -z "$peer_pub" ] || [ "$peer_pub" = "null" ]; then
echo -e "\n${RED}Ошибка получения конфигурации${NC}"
exit 1
fi

conf=$(cat <<EOF
[Interface]
PrivateKey = ${priv}
Address = ${client_ipv4}, ${client_ipv6}
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001
MTU = 1280
S1 = 0
S2 = 0
Jc = 4
Jmin = 40
Jmax = 70
H1 = 1
H2 = 2
H3 = 3
H4 = 4
I1 = <b 0xce000000010897a297ecc34cd6dd000044d0ec2e2e1ea2991f467ace4222129b5a098823784694b4897b9986ae0b7280135fa85e196d9ad980b150122129ce2a9379531b0fd3e871ca5fdb883c369832f730e272d7b8b74f393f9f0fa43f11e510ecb2219a52984410c204cf875585340c62238e14ad04dff382f2c200e0ee22fe743b9c6b8b043121c5710ec289f471c91ee414fca8b8be8419ae8ce7ffc53837f6ade262891895f3f4cecd31bc93ac5599e18e4f01b472362b8056c3172b513051f8322d1062997ef4a383b01706598d08d48c221d30e74c7ce000cdad36b706b1bf9b0607c32ec4b3203a4ee21ab64df336212b9758280803fcab14933b0e7ee1e04a7becce3e2633f4852585c567894a5f9efe9706a151b615856647e8b7dba69ab357b3982f554549bef9256111b2d67afde0b496f16962d4957ff654232aa9e845b61463908309cfd9de0a6abf5f425f577d7e5f6440652aa8da5f73588e82e9470f3b21b27b28c649506ae1a7f5f15b876f56abc4615f49911549b9bb39dd804fde182bd2dcec0c33bad9b138ca07d4a4a1650a2c2686acea05727e2a78962a840ae428f55627516e73c83dd8893b02358e81b524b4d99fda6df52b3a8d7a5291326e7ac9d773c5b43b8444554ef5aea104a738ed650aa979674bbed38da58ac29d87c29d387d80b526065baeb073ce65f075ccb56e47533aef357dceaa8293a523c5f6f790be90e4731123d3c6152a70576e90b4ab5bc5ead01576c68ab633ff7d36dcde2a0b2c68897e1acfc4d6483aaaeb635dd63c96b2b6a7a2bfe042f6aed82e5363aa850aace12ee3b1a93f30d8ab9537df483152a5527faca21efc9981b304f11fc95336f5b9637b174c5a0659e2b22e159a9fed4b8e93047371175b1d6d9cc8ab745f3b2281537d1c75fb9451871864efa5d184c38c185fd203de206751b92620f7c369e031d2041e152040920ac2c5ab5340bfc9d0561176abf10a147287ea90758575ac6a9f5ac9f390d0d5b23ee12af583383d994e22c0cf42383834bcd3ada1b3825a0664d8f3fb678261d57601ddf94a8a68a7c273a18c08aa99c7ad8c6c42eab67718843597ec9930457359dfdfbce024afc2dcf9348579a57d8d3490b2fa99f278f1c37d87dad9b221acd575192ffae1784f8e60ec7cee4068b6b988f0433d96d6a1b1865f4e155e9fe020279f434f3bf1bd117b717b92f6cd1cc9bea7d45978bcc3f24bda631a36910110a6ec06da35f8966c9279d130347594f13e9e07514fa370754d1424c0a1545c5070ef9fb2acd14233e8a50bfc5978b5bdf8bc1714731f798d21e2004117c61f2989dd44f0cf027b27d4019e81ed4b5c31db347c4a3a4d85048d7093cf16753d7b0d15e078f5c7a5205dc2f87e330a1f716738dce1c6180e9d02869b5546f1c4d2748f8c90d9693cba4e0079297d22fd61402dea32ff0eb69ebd65a5d0b687d87e3a8b2c42b648aa723c7c7daf37abcc4bb85caea2ee8f55bec20e913b3324ab8f5c3304f820d42ad1b9f2ffc1a3af9927136b4419e1e579ab4c2ae3c776d293d397d575df181e6cae0a4ada5d67ecea171cca3288d57c7bbdaee3befe745fb7d634f70386d873b90c4d6c6596bb65af68f9e5121e67ebf0d89d3c909ceedfb32ce9575a7758ff080724e1ab5d5f43074ecb53a479af21ed03d7b6899c36631c0166f9d47e5e1d4528a5d3d3f744029c4b1c190cbfbad06f5f83f7ad0429fa9a2719c56ffe3783460e166de2d8>

[Peer]
PublicKey = ${peer_pub}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${ENDPOINT}
PersistentKeepalive = 25
EOF
)

echo
echo -e "${GREEN}========== ${YELLOW}WARP CONFIG${GREEN} ==========${NC}"
echo "$conf"
echo -e "${GREEN}=================================${NC}"
echo "$conf" > /root/WARP.conf
echo -e "\n${YELLOW}Файл сохранён:${NC} /root/WARP.conf"
