#!/bin/sh
GREEN="\033[1;32m"; RED="\033[1;31m"; NC="\033[0m"; CONF="/etc/config/zapret"
if command -v apk >/dev/null 2>&1; then PKG_IS_APK=1; else PKG_IS_APK=0; fi
if ! command -v curl >/dev/null 2>&1; then echo -e "\n${GREEN}Устанавливаем ${NC}curl"
if command -v apk >/dev/null 2>&1; then apk update >/dev/null 2>&1 && apk add curl >/dev/null 2>&1
else opkg update >/dev/null 2>&1 && opkg install curl >/dev/null 2>&1; fi; fi
clear; echo -e "${GREEN}===== Информация о системе =====${NC}"
MODEL=$(cat /tmp/sysinfo/model); ARCH=$(sed -n "s/.*ARCH='\(.*\)'/\1/p" /etc/openwrt_release)
OWRT=$(grep '^DISTRIB_RELEASE=' /etc/openwrt_release | cut -d"'" -f2); echo -e "$MODEL\n$ARCH\n$OWRT"
echo -e "\n${GREEN}===== Пользовательские пакеты =====${NC}"
if [ "$PKG_IS_APK" -eq 1 ]; then
apk info -v | awk '
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
echo -e "\n${GREEN}===== Flow Offloading =====${NC}"
sw=$(uci -q get firewall.@defaults[0].flow_offloading); hw=$(uci -q get firewall.@defaults[0].flow_offloading_hw)
if grep -q 'ct original packets ge 30' /usr/share/firewall4/templates/ruleset.uc 2>/dev/null; then
dpi="${RED}yes${NC}"; else dpi="${GREEN}no${NC}"; fi
if [ "$hw" = "1" ]; then out="HW: ${RED}on${NC}"; elif [ "$sw" = "1" ]; then out="SW: ${RED}on${NC}"
else out="SW: ${GREEN}off${NC} | HW: ${GREEN}off${NC}"; fi
out="$out | FIX: ${dpi}"; echo -e "$out"; if /etc/init.d/https-dns-proxy status >/dev/null 2>&1; then
echo -e "\n${GREEN}===== Настройки DNS over HTTPS =====${NC}"
[ -f /etc/config/https-dns-proxy ] && sed -n "s/^[[:space:]]*option resolver_url '\([^']*\)'.*/\1/p" /etc/config/https-dns-proxy; else
echo -e "\n${GREEN}===== Проверка GitHub =====${NC}"
RATE=$(curl -s https://api.github.com/rate_limit | grep '"remaining"' | head -1 | awk '{print $2}' | tr -d ,)
[ -z "$RATE" ] && RATE_OUT="${RED}N/A${NC}" || RATE_OUT=$([ "$RATE" -eq 0 ] && echo -e "${RED}0${NC}" || echo -e "${GREEN}$RATE${NC}")
echo -n "API: "; curl -Is --connect-timeout 3 https://api.github.com >/dev/null 2>&1 && echo -e "${GREEN}ok${NC} | Limit: $RATE_OUT" || echo -e "${RED}fail${NC} | Limit: $RATE_OUT"; fi
echo -e "\n${GREEN}===== Проверка IPv4 / IPv6 =====${NC}"
PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "https://ipinfo.io/$IP/org" 2>/dev/null | sed -E 's/AS[0-9]+ ?//; s/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//g; s/  +/ /g; s/^ +| +$//g')
[ -z "$PROVIDER" ] && PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "http://ip-api.com/line/?fields=as" 2>/dev/null | sed -E 's/AS[0-9]+ ?//; s/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//g; s/  +/ /g; s/^ +| +$//g')
[ -z "$PROVIDER" ] && PROVIDER=$(curl -fsSL --connect-timeout 2 --max-time 3 "https://ipwho.is/$IP" 2>/dev/null | sed -E 's/.*"isp":"([^"]+)".*/\1/' | sed -E 's/\b(OJSC|PJSC|IROKO|JSC|LLC|Inc\.?|Ltd\.?)\b//Ig' | sed -E 's/  +/ /g; s/^ +| +$//g')
[ -n "$PROVIDER" ] && echo "Провайдер: $PROVIDER"
echo -n "Google IPv4: "; time=$(ping -4 -c 1 -W 2 google.com 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
if [ -n "$time" ]; then echo -e "${GREEN}ok ($time ms)${NC}"; else echo -e "${RED}fail${NC}"; fi
echo -n "Google IPv6: "; time=$(ping -6 -c 1 -W 2 google.com 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
if [ -n "$time" ]; then echo -e "${GREEN}ok ($time ms)${NC}"; else echo -e "${RED}fail${NC}"; fi
echo -e "\n${GREEN}===== Настройки Zapret =====${NC}"
zpr_info() { if [ "$PKG_IS_APK" -eq 1 ]; then INSTALLED_VER=$(apk info zapret | awk '/^zapret-[0-9]/ {gsub(/^zapret-|-r[0-9]+.*$/,""); print; exit}')
else INSTALLED_VER=$(opkg list-installed | awk '/^zapret / {gsub(/-r[0-9]+$/,"",$3); print $3; exit}'); fi
NFQ_RUN=$(pgrep -f nfqws | wc -l); NFQ_ALL=$(/etc/init.d/zapret info 2>/dev/null | grep -o 'instance[0-9]\+' | wc -l); NFQ_STAT=""
[ "$NFQ_RUN" -ne 0 ] || [ "$NFQ_ALL" -ne 0 ] && { [ "$NFQ_RUN" -eq "$NFQ_ALL" ] && NFQ_CLR="$GREEN" || NFQ_CLR="$RED"; NFQ_STAT="${NFQ_CLR}[${NFQ_RUN}/${NFQ_ALL}]${NC}"; }
if /etc/init.d/zapret status 2>/dev/null | grep -qi "running"; then ZAPRET_STATUS="${GREEN}запущен${NC} $NFQ_STAT"
else ZAPRET_STATUS="${RED}остановлен${NC}"; fi; SCRIPT_FILE="/opt/zapret/init.d/openwrt/custom.d/50-script.sh"
if [ -f "$SCRIPT_FILE" ]; then line=$(head -n1 "$SCRIPT_FILE"); case "$line" in *QUIC*) name="50-quic4all" ;;
*stun*) name="50-stun4all" ;; *"discord media"*) name="50-discord-media" ;;
*"discord subnets"*) name="50-discord" ;; *) name="" ;; esac; fi
TCP_VAL=$(grep -E "^[[:space:]]*option NFQWS_PORTS_TCP[[:space:]]+'" "$CONF" | sed "s/.*'\(.*\)'.*/\1/")
UDP_VAL=$(grep -E "^[[:space:]]*option NFQWS_PORTS_UDP[[:space:]]+'" "$CONF" | sed "s/.*'\(.*\)'.*/\1/")
echo -e "${GREEN}$INSTALLED_VER${NC} | $ZAPRET_STATUS"; [ -n "$name" ] && echo -e "${GREEN}$name${NC}"
echo -e "TCP: ${GREEN}$TCP_VAL${NC}\nUDP: ${GREEN}$UDP_VAL${NC}"
echo -e "\n${GREEN}===== Стратегия =====${NC}"
awk '/^[[:space:]]*option[[:space:]]+NFQWS_OPT[[:space:]]*'\''/ {flag=1; sub(/^[[:space:]]*option[[:space:]]+NFQWS_OPT[[:space:]]*'\''/, ""); next}  
flag {if(/'\''/) {sub(/'\''$/, ""); print; exit} print}' "$CONF"; }
if [ -f /etc/init.d/zapret ]; then zpr_info; else echo -e "${RED}Zapret не установлен!${NC}\n"; fi
echo -e "${GREEN}===== Доступность сайтов =====${NC}"
SITES=$(cat <<'EOF'
gosuslugi.ru
esia.gosuslugi.ru
nalog.ru
lkfl2.nalog.ru
rutube.ru
youtube.com
facebook.com
instagram.com
rutor.info
ntc.party
rutracker.org
epidemz.net.co
nnmclub.to
openwrt.org
github.com
redirector.googlevideo.com/report_mapping
sxyprn.net
spankbang.com
pornhub.com
discord.com
x.com
filmix.my
flightradar24.com
cdn77.com
play.google.com
genderize.io
ottai.com
kinozal.tv
cub.red
mobile.de
exleasingcar.com
EOF
)
sites_clean=$(echo "$SITES" | grep -v '^#' | grep -v '^\s*$'); total=$(echo "$sites_clean" | wc -l); half=$(( (total + 1) / 2 ))
sites_list=""; for site in $sites_clean; do sites_list="$sites_list $site"; done; for idx in $(seq 1 $half); do
left=$(echo $sites_list | cut -d' ' -f$idx); right_idx=$((idx + half)); right=$(echo $sites_list | cut -d' ' -f$right_idx)
left_pad=$(printf "%-25s" "$left"); right_pad=$(printf "%-25s" "$right")
if curl -sL --connect-timeout 3 --max-time 5 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "https://$left" >/dev/null 2>&1
then left_color="[${GREEN}OK${NC}]  "; else left_color="[${RED}FAIL${NC}]"; fi; if [ -n "$right" ]
then if curl -sL --connect-timeout 3 --max-time 5 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "https://$right" >/dev/null 2>&1
then right_color="[${GREEN}OK${NC}]  "; else right_color="[${RED}FAIL${NC}]"; fi; echo -e "$left_color $left_pad $right_color $right_pad"; else echo -e "$left_color $left_pad"; fi; done
