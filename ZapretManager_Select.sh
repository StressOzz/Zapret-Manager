#!/bin/sh
GREEN="\033[1;32m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"; MAGENTA="\033[1;35m"; NC="\033[0m"; DGRAY="\033[38;5;244m"
ZMS_URL="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/ZapretManager_LuCI.sh"
ZMS_MIRRORS="gh-proxy.org ghfast.top gh.llkk.cc ghproxy.net"
ZMS_SRC="/tmp/zm-select-full.sh"
ZMS_STATE="/opt/zapret-manager-luci/state"
V="/www/luci-static/resources/view/zapret-manager"
IDS="strategy zapret2 steer forkozz bytetube tgproxy mixomo hosts adblock doh awg tailscale terminal monitor openwrt"
LIST='strategy|Zapret|Обход блокировок|стратегии, тесты, Discord, игры
zapret2|Zapret2|Обход блокировок|установка и управление
steer|Steer|Обход блокировок|сервисы через WARP или VPN
forkozz|Forkozz|Обход блокировок|сервисы через свой VPN
bytetube|ByeTube|Обход блокировок|YouTube через ByeDPI
tgproxy|TG WS Proxy|Обход блокировок|прокси для Telegram
mixomo|Mixomo|Обход блокировок|Mihomo, MagiTrickle, WARP
hosts|Hosts|Сеть|домены в hosts, GeoHide
adblock|Блокировка рекламы|Сеть|для всей сети
doh|DNS over HTTPS|Сеть|шифрованный DNS
awg|AmneziaWG|Сеть|туннели и WARP
tailscale|Удалённый доступ|Сеть|роутер из любой сети
terminal|Терминал|Сеть|SSH в браузере
monitor|Монитор ресурсов|Сервис|процессор, память
openwrt|Настройка OpenWrt|Сервис|время, Wi-Fi, зеркало'

say() { echo -e "${CYAN}==>${NC} $*"; }
ok() { echo -e "   ${GREEN}✓${NC} $*"; }
warn() { echo -e "   ${YELLOW}!${NC} $*"; }
die() { echo -e "${YELLOW}$*${NC}"; rm -f "$ZMS_SRC"; exit 1; }
f() { printf '%s\n' "$LIST" | awk -F'|' -v id="$1" -v n="$2" '$1 == id { print $n; exit }'; }
files() {
	case "$1" in
		forkozz) echo "$V/forkozz.js /opt/zapret-manager-luci/netshift.uc" ;;
		bytetube) echo "$V/bytetube.js /www/luci-static/resources/bytetube/common.js /www/luci-static/resources/bytetube/presets.js /www/luci-static/resources/view/bytetube/style.css" ;;
		*) echo "$V/$1.js" ;;
	esac
}
num() { echo "$1" | sed -e ':a' -e 's/\([0-9]\)\([0-9]\{3\}\)\($\| \)/\1 \2\3/' -e 'ta'; }
kfree() { df -kP "$1" 2>/dev/null | awk 'NR == 2 { print $4 + 0; f = 1 } END { if (!f) print 0 }'; }

get() {
	rm -f "$ZMS_SRC"
	if command -v curl >/dev/null 2>&1; then curl -fsSL --connect-timeout 10 --max-time 180 -o "$ZMS_SRC" "$1"
	else wget -q -T 30 -O "$ZMS_SRC" "$1"; fi || return 1
	[ -s "$ZMS_SRC" ] && head -n1 "$ZMS_SRC" | grep -qx '#!/bin/sh' && grep -q '^# Version:' "$ZMS_SRC" && tail -n 5 "$ZMS_SRC" | grep -q 'Web UI:' && sh -n "$ZMS_SRC" 2>/dev/null
}

used() {
	case "$1" in
		strategy) [ -f /etc/init.d/zapret ] ;;
		zapret2) [ -f /etc/init.d/zapret2 ] ;;
		steer) command -v steer >/dev/null 2>&1 || [ -s /etc/zm-steer/owned ] ;;
		forkozz) [ -x /usr/bin/netshift ] ;;
		bytetube) [ -x /usr/bin/bytetube ] ;;
		tgproxy) [ -x /etc/init.d/tg-ws-proxy ] || [ -x /etc/init.d/tg-ws-proxy-go ] || [ -x /etc/init.d/tg-ws-proxy-rs ] || [ -x /etc/init.d/tgws ] ;;
		mixomo) [ -x /usr/bin/mihomo ] || [ -x /etc/init.d/mihomo ] || [ -x /etc/init.d/magitrickle ] ;;
		adblock) grep -qx 'on=1' "$ZMS_STATE/adblock/settings" 2>/dev/null ;;
		doh) [ -x /etc/init.d/https-dns-proxy ] ;;
		awg) command -v awg >/dev/null 2>&1 ;;
		tailscale) [ -x /usr/sbin/tailscaled ] ;;
		terminal) [ -x /usr/bin/ttyd ] ;;
		*) return 1 ;;
	esac
}
lock() {
	used "$1" && { echo "уже стоит на роутере"; return 0; }
	return 1
}
is_on() { case " $ON " in *" $1 "*) return 0 ;; esac; return 1; }
set_on() {
	local id out=""
	for id in $IDS; do
		if [ "$id" = "$1" ]; then [ "$2" = 1 ] && out="$out $id"
		elif is_on "$id"; then out="$out $id"; fi
	done
	ON="${out# }"
}
fix() { local id; for id in $IDS; do lock "$id" >/dev/null && set_on "$id" 1; done; return 0; }
kb() { printf '%s' "$SIZES" | awk -v id="$1" '$1 == id { print int(($2 + 1023) / 1024); exit }'; }
bar() {
	local n i=0 b=""
	n=$(( ($1 * 14 + MAX - 1) / MAX ))
	[ "$n" -lt 1 ] && n=1
	while [ "$i" -lt 14 ]; do
		if [ "$i" -lt "$n" ]; then b="$b█"; else b="$b░"; fi
		i=$((i + 1))
	done
	printf '%s' "$b"
}
draw() {
	local id t g d k i=0 grp="" lk mark col tcol sel=0 selkb=0
	clear 2>/dev/null || printf '\033[2J\033[H'
	echo -e "${MAGENTA}Zapret Manager $VER — установка с выбором страниц${NC}"
	echo -e "${DGRAY}Ядро ставится всегда: Дашборд, Система, резервные копии, фоновые проверки,"
	echo -e "Web UI и вся логика панели. Ниже — страницы бокового меню.${NC}"
	for id in $IDS; do
		i=$((i + 1))
		t="$(f "$id" 2)"; g="$(f "$id" 3)"; d="$(f "$id" 4)"; k="$(kb "$id")"
		if [ "$g" != "$grp" ]; then echo; echo -e "  ${CYAN}$g${NC}"; grp="$g"; fi
		if lk="$(lock "$id")"; then mark="[■]"; col="$GREEN"; tcol="$NC"; d="$lk"
		elif is_on "$id"; then mark="[✓]"; col="$GREEN"; tcol="$NC"
		else mark="[ ]"; col="$DGRAY"; tcol="$DGRAY"; fi
		if is_on "$id"; then sel=$((sel + 1)); selkb=$((selkb + k)); fi
		printf "  %b%s%b %2d  %5s КБ  %b%s%b  %b%s%b %b· %s%b\n" "$col" "$mark" "$NC" "$i" "$(num "$k")" "$col" "$(bar "$k")" "$NC" "$tcol" "$t" "$NC" "$DGRAY" "$d" "$NC"
	done
	echo
	echo -e "  ${DGRAY}────────────────────────────────────────────────────────────${NC}"
	printf "  Ядро панели                %7s КБ\n" "$(num "$BASE")"
	printf "  Страницы: %2d из %-2d          %7s КБ\n" "$sel" "$i" "$(num "$selkb")"
	printf "  %bВсего займёт               %7s КБ%b" "$GREEN" "$(num "$((BASE + selkb))")" "$NC"
	if [ "$selkb" -lt "$PAGES" ]; then printf "   %bэкономия %s КБ%b" "$CYAN" "$(num "$((PAGES - selkb))")" "$NC"; fi
	echo
	echo -e "  ${DGRAY}На флеше файлы хранятся сжатыми — реально займёт примерно в 2 раза меньше.${NC}"
	if [ "${FREE:-0}" -gt 0 ]; then echo -e "  ${DGRAY}Свободно на флеше сейчас: $(num "$FREE") КБ${NC}"; fi
	echo
	if [ -n "$MSG" ]; then echo -e "  ${YELLOW}$MSG${NC}"; echo; fi
	echo -e "  ${CYAN}Цифра${NC} — поставить или убрать страницу, можно несколько: ${CYAN}3 4 9${NC}"
	echo -e "  ${CYAN}a${NC} — все   ${CYAN}m${NC} — минимум   ${CYAN}Enter${NC} — установить   ${CYAN}q${NC} — отменить"
	return 0
}
menu() {
	local ans t id n
	MSG=""
	while :; do
		draw
		printf '  > '
		ans=""
		IFS= read -r ans <&3 || { echo; return 0; }
		MSG=""
		ans="$(printf '%s' "$ans" | tr ',;' '  ' | tr 'A-Z' 'a-z')"
		case "$ans" in
			''|' ') return 0 ;;
			q|й) echo; echo -e "${YELLOW}Установка отменена — на роутере ничего не изменилось${NC}"; rm -f "$ZMS_SRC"; exit 0 ;;
			a|ф|all) ON="$IDS"; MSG="Отмечены все страницы" ;;
			m|ь|min) ON=""; fix; MSG="Оставлен минимум — только то, без чего нельзя" ;;
			*)
				for t in $ans; do
					case "$t" in *[!0-9]*|'') MSG="${MSG:+$MSG · }Не понял «$t» — введите номера страниц, a, m, q или просто Enter"; continue ;; esac
					n=0; id=""
					for id in $IDS; do n=$((n + 1)); [ "$n" = "$t" ] && break; done
					if [ "$n" != "$t" ] || [ "$t" = 0 ]; then MSG="${MSG:+$MSG · }Страницы с номером $t нет"; continue; fi
					if lock "$id" >/dev/null; then MSG="${MSG:+$MSG · }«$(f "$id" 2)» убрать нельзя: $(lock "$id")"; continue; fi
					if is_on "$id"; then set_on "$id" 0; else set_on "$id" 1; fi
				done ;;
		esac
	done
}

[ "$(id -u 2>/dev/null)" = 0 ] || die "Запустите установщик от root"
clear 2>/dev/null || true
echo -e "${MAGENTA}Zapret Manager — установка с выбором страниц${NC}\n"
say "Скачиваем полный установщик панели"
if get "$ZMS_URL"; then ok "Скачан напрямую с GitHub"
else
	warn "GitHub напрямую не ответил — пробуем зеркала"
	for m in $ZMS_MIRRORS; do
		if get "https://$m/$ZMS_URL"; then ok "Скачан через $m"; break; fi
	done
fi
[ -s "$ZMS_SRC" ] && sh -n "$ZMS_SRC" 2>/dev/null || die "Не удалось скачать установщик — проверьте интернет на роутере и запустите ещё раз"
VER="$(grep -m1 '^# Version:' "$ZMS_SRC" | sed 's/^# Version:[[:space:]]*//' | tr -d '\r ')"
ok "Версия панели: $VER"
if ! grep -q '_zpg_enforce' "$ZMS_SRC"; then
	warn "В этой версии панели ещё нет выбора страниц — ставим её полностью"
	sh "$ZMS_SRC"; r=$?; rm -f "$ZMS_SRC"; exit $r
fi

SIZES=""; PAGES=0; MAX=1
for id in $IDS; do
	b=0
	for p in $(files "$id"); do
		s="$(awk -v h="cat > '$p' << 'ZM_INSTALLER_EOF'" 'f && $0 == "ZM_INSTALLER_EOF" { exit } f { n += length($0) + 1 } $0 == h { f = 1 } END { print n + 0 }' "$ZMS_SRC")"
		b=$((b + ${s:-0}))
	done
	SIZES="$SIZES$id $b
"
	k=$(( (b + 1023) / 1024 ))
	PAGES=$((PAGES + k))
	if [ "$k" -gt "$MAX" ]; then MAX=$k; fi
done
BASE=$(( $(wc -c < "$ZMS_SRC") / 1024 - PAGES - 24 ))
[ "$BASE" -gt 1000 ] || BASE=2210
FREE="$(kfree /overlay)"
[ "${FREE:-0}" -gt 0 ] || FREE="$(kfree /)"
SAVED=""
[ -s "$ZMS_STATE/pages.off" ] && SAVED="$(tr -s ' \n' '  ' < "$ZMS_STATE/pages.off")"
ON=""
for id in $IDS; do case " $SAVED " in *" $id "*) ;; *) ON="$ON $id" ;; esac; done
ON="${ON# }"
fix

if [ -t 0 ]; then exec 3<&0
elif ( exec 3</dev/tty ) 2>/dev/null; then exec 3</dev/tty
else die "Нужен терминал, чтобы выбрать страницы. Запустите так: wget -O /tmp/zm-select.sh <ссылка> && sh /tmp/zm-select.sh"
fi
menu
exec 3<&-

OFF=""
for id in $IDS; do is_on "$id" || OFF="$OFF $id"; done
OFF="${OFF# }"
mkdir -p "$ZMS_STATE" || die "Не удалось создать $ZMS_STATE"
if [ -n "$OFF" ]; then printf '%s\n' "$OFF" > "$ZMS_STATE/pages.off"; else rm -f "$ZMS_STATE/pages.off"; fi
{
	[ -s "$ZMS_STATE/pages.size" ] && awk -v off=" $OFF " '!index(off, " " $1 " ")' "$ZMS_STATE/pages.size"
	for id in $OFF; do printf '%s %s\n' "$id" "$(printf '%s' "$SIZES" | awk -v id="$id" '$1 == id { print $2; exit }')"; done
} > "$ZMS_STATE/pages.size.new" && mv -f "$ZMS_STATE/pages.size.new" "$ZMS_STATE/pages.size"

clear 2>/dev/null || true
if [ -n "$OFF" ]; then
	t=""; for id in $OFF; do t="$t, $(f "$id" 2)"; done
	echo -e "${MAGENTA}Ставим панель без страниц:${NC} ${t#, }"
else
	echo -e "${MAGENTA}Ставим панель со всеми страницами${NC}"
fi
echo -e "${DGRAY}Изменить выбор потом можно в панели: Система → Компоненты панели${NC}\n"
sleep 2
sh "$ZMS_SRC"
r=$?
rm -f "$ZMS_SRC"
[ "$r" = 0 ] || exit $r
if [ -x /opt/zapret-manager-luci/backend.sh ]; then
	/opt/zapret-manager-luci/backend.sh zm_pages status >/dev/null 2>&1 || true
	n=0; for id in $IDS; do is_on "$id" && n=$((n + 1)); done
	echo -e "${GREEN}Страниц в панели: $n из $(echo $IDS | wc -w)${NC}${OFF:+ · ${DGRAY}убраны: ${t#, }${NC}}"
fi
exit 0
