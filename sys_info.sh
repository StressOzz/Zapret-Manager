#!/bin/sh
GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m"
CONF="/etc/config/zapret"
clear
echo -e "\n${GREEN}===== Модель и архитектура роутера =====${NC}"
cat /tmp/sysinfo/model
awk -F= '
/DISTRIB_ARCH/   { gsub(/'\''/, ""); print $2 }
/DISTRIB_TARGET/ { gsub(/'\''/, ""); print $2 }
' /etc/openwrt_release
echo -e "\n${GREEN}===== Версия OpenWrt =====${NC}"
awk -F= '
/DISTRIB_DESCRIPTION/ {
gsub(/'\''|OpenWrt /, "")
print $2
}
' /etc/openwrt_release
echo -e "\n${GREEN}===== Пользовательские пакеты =====${NC}"
awk '
/^Package:/ { p=$2 }
/^Status: install user/ { print p }
' /usr/lib/opkg/status
echo -e "\n${GREEN}===== Flow Offloading =====${NC}"
sw=$(uci -q get firewall.@defaults[0].flow_offloading)
hw=$(uci -q get firewall.@defaults[0].flow_offloading_hw)
if grep -q 'ct original packets ge 30' /usr/share/firewall4/templates/ruleset.uc 2>/dev/null; then
dpi="${RED}yes${NC}"
else
dpi="${GREEN}no${NC}"
fi
if [ "$hw" = "1" ]; then
out="HW: ${RED}on${NC}"
elif [ "$sw" = "1" ]; then
out="SW: ${RED}on${NC}"
else
out="SW: ${GREEN}off${NC} | HW: ${GREEN}off${NC}"
fi
out="$out | FIX: ${dpi}"
echo -e "$out"
echo -e "\n${GREEN}===== Настройки запрет =====${NC}"
INSTALLED_VER=$(opkg list-installed | grep '^zapret ' | awk '{print $3}')
if /etc/init.d/zapret status 2>/dev/null | grep -qi "running"; then
ZAPRET_STATUS="${GREEN}запущен${NC}"
else
ZAPRET_STATUS="${RED}остановлен${NC}"
fi
SCRIPT_FILE="/opt/zapret/init.d/openwrt/custom.d/50-script.sh"
[ -f "$SCRIPT_FILE" ] || return
line=$(head -n1 "$SCRIPT_FILE")
case "$line" in
*QUIC*) name="50-quic4all" ;;
*stun*) name="50-stun4all" ;;
*"discord media"*) name="50-discord-media" ;;
*"discord subnets"*) name="50-discord" ;;
*) name="" ;;
esac
TCP_VAL=$(grep -E "^[[:space:]]*option NFQWS_PORTS_TCP[[:space:]]+'" "$CONF" \
| sed "s/.*'\(.*\)'.*/\1/")
UDP_VAL=$(grep -E "^[[:space:]]*option NFQWS_PORTS_UDP[[:space:]]+'" "$CONF" \
| sed "s/.*'\(.*\)'.*/\1/")
echo -e "Версия: ${GREEN}$INSTALLED_VER${NC}"
echo -e "Статус: $ZAPRET_STATUS"
echo -e "Скрипт: ${GREEN}$name${NC}"
echo -e "Порты: TCP: ${GREEN}$TCP_VAL${NC} | UDP: ${GREEN}$UDP_VAL${NC}"
echo -e "\n${GREEN}===== Стратегия=====${NC}"
awk '
/^[[:space:]]*option[[:space:]]+NFQWS_OPT[[:space:]]*'\''/ {flag=1; sub(/^[[:space:]]*option[[:space:]]+NFQWS_OPT[[:space:]]*'\''/, ""); next}
flag {
if (/'\''/) {sub(/'\''$/, ""); print; exit}
print
}' "$CONF"
echo -e "${GREEN}===== Доступность сайтов =====${NC}"
SITES=$(cat <<'EOF'
gosuslugi.ru
esia.gosuslugi.ru/login
rutube.ru
youtube.com
instagram.com
rutor.info
ntc.party
rutracker.org
epidemz.net.co
nnmclub.to
openwrt.org
sxyprn.net
pornhub.com
discord.com
x.com
filmix.my
flightradar24.com
genderize.io
EOF
)
sites_clean=$(echo "$SITES" | grep -v '^#' | grep -v '^\s*$')
total=$(echo "$sites_clean" | wc -l)
half=$(( (total + 1) / 2 ))
sites_list=""
for site in $sites_clean; do
sites_list="$sites_list $site"
done
for idx in $(seq 1 $half); do
left=$(echo $sites_list | cut -d' ' -f$idx)
right_idx=$((idx + half))
right=$(echo $sites_list | cut -d' ' -f$right_idx)
left_pad=$(printf "%-25s" "$left")
right_pad=$(printf "%-25s" "$right")
if curl -Is --connect-timeout 3 --max-time 4 "https://$left" >/dev/null 2>&1; then
left_color="[${GREEN}OK${NC}]  "
else
left_color="[${RED}FAIL${NC}]"
fi
if [ -n "$right" ]; then
if curl -Is --connect-timeout 3 --max-time 4 "https://$right" >/dev/null 2>&1; then
right_color="[${GREEN}OK${NC}]  "
else
right_color="[${RED}FAIL${NC}]"
fi
echo -e "$left_color $left_pad $right_color $right_pad"
else
echo -e "$left_color $left_pad"
fi
done
echo -e ""
