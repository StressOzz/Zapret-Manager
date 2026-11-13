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
# Где держать панель: 1 — флеш, 2 — страницы в памяти и архив на флеше, 3 — всё в памяти до перезагрузки
MODES="1 2 3"
MODE_ARG_1=flash; MODE_ARG_2=light; MODE_ARG_3=ram

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
mb() { awk -v k="$1" 'BEGIN { m = k / 1024; if (m < 10) printf "%.1f МБ", m; else printf "%d МБ", m + 0.5 }' | tr '.' ','; }
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
# Размер файла из установщика (байты): таблица «путь<TAB>байты» собирается одним проходом
sz() { printf '%s\n' "$TABLE" | awk -F'\t' -v p="$1" '$1 == p { print $2 + 0; f = 1; exit } END { if (!f) print 0 }'; }
kb() { printf '%s' "$SIZES" | awk -v id="$1" '$1 == id { print int(($2 + 1023) / 1024); exit }'; }
pb() { printf '%s' "$SIZES" | awk -v id="$1" '$1 == id { print $2 + 0; exit }'; }
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
	echo -e "  ${CYAN}a${NC} — все   ${CYAN}m${NC} — минимум   ${CYAN}Enter${NC} — дальше   ${CYAN}q${NC} — отменить"
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
			q|й) cancel ;;
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
cancel() { echo; echo -e "${YELLOW}Установка отменена — на роутере ничего не изменилось${NC}"; rm -f "$ZMS_SRC"; exit 0; }

# ---- Где держать панель ----
# Сколько займёт каждый вариант (КБ): ui — страницы и модули, be — основа панели (backend и Forkozz), core — остальное.
# На флеше файлы лежат сжатыми (~в 2 раза меньше), архив страниц сжат gzip (~в 4 раза меньше)
calc() {
	local id p b off=""
	for id in $IDS; do is_on "$id" || off="$off $(files "$id")"; done
	UI_B=0; BE_B=0; CORE_B=0
	eval "$(printf '%s\n' "$TABLE" | awk -F'\t' -v off=" $off " '
		index(off, " " $1 " ") { next }
		$1 ~ /^\$_zmi_st\/mod\// || $1 ~ /^\/www\/luci-static\/resources\/(view\/)?(zapret-manager|bytetube)\// || $1 ~ /^\/www\/zm\// { u += $2; next }
		$1 == "$_zmi_st/backend.sh" || $1 == "/opt/zapret-manager-luci/netshift.uc" { b += $2; next }
		{ c += $2 }
		END { printf "UI_B=%d; BE_B=%d; CORE_B=%d\n", u, b, c }')"
	UI=$(( (UI_B + 1023) / 1024 )); BE=$(( (BE_B + 1023) / 1024 )); CORE=$(( (CORE_B + 1023) / 1024 ))
	FL_1=$(( (UI + BE + CORE) / 2 )); RAM_1=0
	FL_2=$(( (BE + CORE) / 2 + UI / 4 )); RAM_2=$UI
	FL_3=$(( CORE / 2 )); RAM_3=$(( UI + BE ))
}
# Почему вариант нельзя выбрать (пусто — можно)
why_not() {
	local need
	[ "$1" = 1 ] && return 0
	case "$1" in
		2) [ -n "$CAN_LIGHT" ] || { echo "этот установщик ещё не умеет — обновите его"; return; } ;;
		3) [ -n "$CAN_RAM" ] || { echo "этот установщик ещё не умеет — обновите его"; return; } ;;
	esac
	need=$(( $(eval echo "\$RAM_$1") + 4096 )); [ "$need" -lt 12288 ] && need=12288
	[ "${TFREE:-0}" -ge "$need" ] || { echo "мало оперативной памяти: нужно $(mb "$need"), свободно $(mb "${TFREE:-0}")"; return; }
	[ -n "$NOSYM" ] && { echo "веб-сервер uhttpd настроен не открывать файлы по ссылкам (no_symlinks)"; return; }
	[ "$1" = 2 ] && ! { command -v tar >/dev/null 2>&1 && command -v gzip >/dev/null 2>&1; } && { echo "на роутере нет tar или gzip"; return; }
	return 0
}
mdraw() {
	local m mark col tcol t d1 d2 fl ram w
	calc
	clear 2>/dev/null || printf '\033[2J\033[H'
	echo -e "${MAGENTA}Zapret Manager $VER — где держать панель${NC}"
	echo
	echo -e "  ${DGRAY}Свободно: флеш $(num "${FREE:-0}") КБ · память $(mb "${TFREE:-0}")${NC}"
	[ -n "$CUR_TXT" ] && echo -e "  ${DGRAY}Сейчас: $CUR_TXT${NC}"
	echo
	for m in $MODES; do
		case "$m" in
			1) t="На флеше        "; d1="обычная установка, всё сохраняется"; d2="" ;;
			2) t="В памяти + архив"; d1="страницы в оперативной памяти, на флеше их сжатый архив,"; d2="переживает перезагрузку" ;;
			3) t="Только в памяти "; d1="до перезагрузки роутера, потом запустить установщик снова;"; d2="Zapret, Steer и остальное работают и без панели" ;;
		esac
		fl="$(eval echo "\$FL_$m")"; ram="$(eval echo "\$RAM_$m")"
		w="$(why_not "$m")"
		if [ -n "$w" ]; then mark="[×]"; col="$DGRAY"; tcol="$DGRAY"
		elif [ "$m" = "$MODE" ]; then mark="[✓]"; col="$GREEN"; tcol="$NC"
		else mark="[ ]"; col="$DGRAY"; tcol="$NC"; fi
		if [ "$m" = 3 ]; then fl="почти 0"; else fl="≈ $(num "$fl") КБ"; fi
		printf "  %b%s%b %d  %b%s%b   %bфлеш %s%s%b\n" "$col" "$mark" "$NC" "$m" "$tcol" "$t" "$NC" "$DGRAY" "$fl" "$([ "$ram" -gt 0 ] && echo " · память $(mb "$ram")")" "$NC"
		if [ -n "$w" ]; then echo -e "        ${DGRAY}нельзя: $w${NC}"
		else
			echo -e "        ${DGRAY}$d1${NC}"
			[ -n "$d2" ] && echo -e "        ${DGRAY}$d2${NC}"
		fi
	done
	echo
	if [ -n "$MSG" ]; then echo -e "  ${YELLOW}$MSG${NC}"; echo; fi
	echo -e "  ${CYAN}1–3${NC} — выбрать   ${CYAN}Enter${NC} — установить"
	echo -e "  ${CYAN}b${NC} — назад к страницам   ${CYAN}q${NC} — отменить"
}
mmenu() {
	local ans w eof=""
	MSG=""
	calc
	w="$(why_not "$MODE")"
	if [ -n "$w" ]; then
		MSG="Вариант $MODE сейчас нельзя: $w — отмечен вариант 1"
		MODE=1
	fi
	while :; do
		mdraw
		printf '  > '
		ans=""
		IFS= read -r ans <&3 || { echo; ans=""; eof=1; }
		MSG=""
		ans="$(printf '%s' "$ans" | tr -d ' ' | tr 'A-Z' 'a-z')"
		case "$ans" in
			'')
				w="$(why_not "$MODE")"
				[ -z "$w" ] && return 0
				[ -n "$eof" ] && cancel
				MSG="Этот вариант сейчас нельзя: $w — выберите другой" ;;
			q|й) cancel ;;
			b|и) return 1 ;;
			1|2|3)
				w="$(why_not "$ans")"
				if [ -n "$w" ]; then MSG="Вариант $ans нельзя: $w"; else MODE="$ans"; fi ;;
			*) MSG="Не понял «$ans» — введите 1, 2 или 3, b, q или просто Enter" ;;
		esac
	done
}

[ "$(id -u 2>/dev/null)" = 0 ] || die "Запустите установщик от root"
PRESET=""
case "${1:-}" in
	'') ;;
	flash) PRESET=1 ;;
	light) PRESET=2 ;;
	ram) PRESET=3 ;;
	*) die "Не понял «$1». Можно: flash — на флеш, light — в память с архивом на флеше, ram — в память до перезагрузки" ;;
esac
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

say "Считаем размеры"
# Один проход по установщику: путь каждого встроенного файла и его размер
TABLE="$(LC_ALL=C awk -v q="'" '
	f && $0 == "ZM_INSTALLER_EOF" { print p "\t" n; f = 0; next }
	f { n += length($0) + 1; next }
	/ << .ZM_INSTALLER_EOF.$/ && / > / {
		p = $0; sub(/ << .ZM_INSTALLER_EOF.$/, "", p); sub(/.* > /, "", p); gsub("[\"" q "]", "", p)
		f = 1; n = 0
	}' "$ZMS_SRC")"
SIZES=""; PAGES=0; MAX=1; PB=0
for id in $IDS; do
	b=0
	for p in $(files "$id"); do s="$(sz "$p")"; b=$((b + ${s:-0})); done
	SIZES="$SIZES$id $b
"
	k=$(( (b + 1023) / 1024 ))
	PAGES=$((PAGES + k))
	PB=$((PB + b))
	if [ "$k" -gt "$MAX" ]; then MAX=$k; fi
done
BASE=$(( ($(printf '%s\n' "$TABLE" | awk -F'\t' '{ s += $2 } END { print s + 0 }') - PB + 1023) / 1024 ))
[ "$BASE" -gt 1000 ] || BASE=2210
FREE="$(kfree /overlay)"
[ "${FREE:-0}" -gt 0 ] || FREE="$(kfree /)"
TFREE="$(kfree /tmp)"
NOSYM=""
for s in main zmweb; do [ "$(uci -q get "uhttpd.$s.no_symlinks" 2>/dev/null)" = 1 ] && NOSYM=1; done
CAN_LIGHT=""; CAN_RAM=""
grep -qF '"$ZM_INST_MODE" = light' "$ZMS_SRC" && CAN_LIGHT=1
grep -qF '"$ZM_INST_MODE" = ram' "$ZMS_SRC" && CAN_RAM=1
CUR=""; [ -f "$ZMS_STATE/ui.ram" ] && read -r CUR < "$ZMS_STATE/ui.ram"
case "$CUR" in
	light) MODE=2; CUR_TXT="страницы в памяти, архив на флеше" ;;
	tmp) MODE=3; CUR_TXT="панель в памяти до перезагрузки" ;;
	*) MODE=1; CUR_TXT=""; [ -x /opt/zapret-manager-luci/backend.sh ] && CUR_TXT="на флеше" ;;
esac
[ -n "$PRESET" ] && MODE="$PRESET"
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
while :; do
	menu
	mmenu && break
done
exec 3<&-

OFF=""
for id in $IDS; do is_on "$id" || OFF="$OFF $id"; done
OFF="${OFF# }"
mkdir -p "$ZMS_STATE" || die "Не удалось создать $ZMS_STATE"
if [ -n "$OFF" ]; then printf '%s\n' "$OFF" > "$ZMS_STATE/pages.off"; else rm -f "$ZMS_STATE/pages.off"; fi
{
	[ -s "$ZMS_STATE/pages.size" ] && awk -v off=" $OFF " '!index(off, " " $1 " ")' "$ZMS_STATE/pages.size"
	for id in $OFF; do printf '%s %s\n' "$id" "$(pb "$id")"; done
} > "$ZMS_STATE/pages.size.new" && mv -f "$ZMS_STATE/pages.size.new" "$ZMS_STATE/pages.size"

ARG="$(eval echo "\$MODE_ARG_$MODE")"
# Старый установщик не знает «flash» — без слова он и так ставит на флеш
[ "$ARG" = flash ] && [ -z "$CAN_LIGHT" ] && ARG=""
case "$MODE" in 1) WHERE="на флеш" ;; 2) WHERE="в память, архив страниц — на флеш" ;; 3) WHERE="в память до перезагрузки" ;; esac

clear 2>/dev/null || true
if [ -n "$OFF" ]; then
	t=""; for id in $OFF; do t="$t, $(f "$id" 2)"; done
	echo -e "${MAGENTA}Ставим панель $WHERE, без страниц:${NC} ${t#, }"
else
	echo -e "${MAGENTA}Ставим панель $WHERE, со всеми страницами${NC}"
fi
echo -e "${DGRAY}Изменить выбор потом можно в панели: Система → Компоненты панели${NC}\n"
sleep 2
sh "$ZMS_SRC" $ARG
r=$?
rm -f "$ZMS_SRC"
[ "$r" = 0 ] || exit $r
if [ -x /opt/zapret-manager-luci/backend.sh ]; then
	/opt/zapret-manager-luci/backend.sh zm_pages status >/dev/null 2>&1 || true
	n=0; for id in $IDS; do is_on "$id" && n=$((n + 1)); done
	echo -e "${GREEN}Страниц в панели: $n из $(echo $IDS | wc -w)${NC}${OFF:+ · ${DGRAY}убраны: ${t#, }${NC}}"
fi
exit 0
