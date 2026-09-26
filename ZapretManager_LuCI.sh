#!/bin/sh
# Version: 1.65
set -e

GREEN="\033[1;32m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"; MAGENTA="\033[1;35m"; BLUE="\033[0;34m"; NC="\033[0m"; DGRAY="\033[38;5;244m"

echo -e "\n${MAGENTA}Устанавливаем Zapret Manager для LuCI${NC}"

if [ -f /tmp/zapret-manager-luci/redbtn_deep.pid ]; then
	_zm_kill_tree() {
		for _c in $(cat "/proc/$1/task/$1/children" 2>/dev/null); do _zm_kill_tree "$_c"; done
		kill -9 "$1" 2>/dev/null || true
	}
	_zm_kill_tree "$(cat /tmp/zapret-manager-luci/redbtn_deep.pid 2>/dev/null)"
	for _p in $(ps w | grep "[q]num=8397" | awk '{print $1}'); do kill "$_p" 2>/dev/null || true; done
	nft delete table inet zm_rb_ztest >/dev/null 2>&1 || true
fi
for _zm_job in redbtn steer awg; do
	if [ -f /tmp/zapret-manager-luci/$_zm_job.pid ] && kill -0 "$(cat /tmp/zapret-manager-luci/$_zm_job.pid 2>/dev/null)" 2>/dev/null &&
	   ! grep -q '^__DONE__' /tmp/zapret-manager-luci/$_zm_job.log 2>/dev/null; then
		echo -e "${YELLOW}Идёт операция Steer или AmneziaWG — дождитесь окончания и запустите установку снова${NC}"
		exit 1
	fi
done

rm -rf \
	/usr/lib/zapret-manager* \
	/etc/zapret_manager_expert_mode* \
	/tmp/zapret-manager \
	/tmp/zapret-manager-luci* \
	/tmp/zm_uninstall_panel.sh \
	/tmp/luci-indexcache* \
	/tmp/luci-modulecache/* 2>/dev/null
rm -f \
	/www/luci-static/resources/view/zapret-manager/test.js \
	/www/luci-static/resources/view/zapret-manager/redbtn.js \
	/www/luci-static/resources/view/zapret-manager/youtube.js \
	/www/luci-static/resources/view/zapret-manager/game.js \
	/www/luci-static/resources/view/zapret-manager/discord.js \
	/www/luci-static/resources/view/zapret-manager/exclusions.js \
	/usr/share/luci/menu.d/luci-app-ytbypass.json \
	/usr/share/rpcd/acl.d/luci-app-ytbypass.json \
	/www/luci-static/resources/view/ytbypass/main.js 2>/dev/null

if [ -x /etc/init.d/ytbypass ] || [ -f /etc/config/ytbypass ] || [ -x /usr/bin/ytbypass ]; then
	[ -x /usr/bin/ytbypass ] && /usr/bin/ytbypass test stop >/dev/null 2>&1
	if [ -x /etc/init.d/ytbypass ]; then
		/etc/init.d/ytbypass stop >/dev/null 2>&1
		/etc/init.d/ytbypass disable >/dev/null 2>&1
	fi
	[ -x /usr/libexec/ytbypass/net.sh ] && /usr/libexec/ytbypass/net.sh purge >/dev/null 2>&1
	if [ -f /usr/libexec/ytbypass/common.sh ]; then
		. /usr/libexec/ytbypass/common.sh
		rm -f "$(dnsmasq_confdir)/ytbypass.conf" 2>/dev/null
	fi
	[ -f /etc/config/ytbypass ] && [ ! -f /etc/config/bytetube ] && mv /etc/config/ytbypass /etc/config/bytetube
	[ -d /etc/ytbypass ] && [ ! -d /etc/bytetube ] && mv /etc/ytbypass /etc/bytetube
	rm -rf /etc/config/ytbypass /etc/init.d/ytbypass /etc/hotplug.d/firewall/90-ytbypass \
		/usr/bin/ytbypass /usr/libexec/ytbypass /usr/share/ytbypass \
		/usr/share/nftables.d/chain-pre/forward/50-ytbypass.nft \
		/var/etc/ytbypass /var/run/ytbypass.started /tmp/ytbypass-test \
		/etc/ytbypass /lib/upgrade/keep.d/ytbypass \
		/www/luci-static/resources/ytbypass /www/luci-static/resources/view/ytbypass 2>/dev/null
fi

mkdir -p /opt/zapret-manager-luci
chmod 0755 /opt/zapret-manager-luci
cat > '/opt/zapret-manager-luci/backend.sh' << 'ZM_INSTALLER_EOF'

umask 022

CONF="/etc/config/zapret"
ZM_VERSION="1.65"
ZM_SCRIPT_URL="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/ZapretManager_LuCI.sh"
GH_RAW="https://raw.githubusercontent.com"
GH_MAIN="https://github.com"
MT_URL_ITDOG="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/MagiTrickle/configAD.yaml"
MT_URL_IH1="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/MagiTrickle/config.yaml"
MT_URL_IH2="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/MagiTrickle/configOLD.yaml"
EXCLUDE_URL="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/zapret-hosts-user-exclude.txt"
FLOWSEAL_ZIP="${GH_MAIN}/Flowseal/zapret-discord-youtube/archive/refs/heads/main.zip"
FLOWSEAL_FAKE_RAW="${GH_MAIN}/Flowseal/zapret-discord-youtube/raw/refs/heads/main/bin"
STR_URL="${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/StrYoutube"
JOBS_DIR="/tmp/zapret-manager-luci"
ZM_STATE_DIR="/opt/zapret-manager-luci/state"
CRON_FILE="/etc/crontabs/root"
MIHOMO_DIR="/etc/mihomo"
MIHOMO_BIN="/usr/bin/mihomo"
MIHOMO_CONF="/etc/mihomo/config.yaml"
MAGITRICKLE_CONF="/etc/magitrickle/state/config.yaml"
MIXOMO_CRON_CMD="/etc/init.d/mihomo restart"
HOSTS_FILE="/etc/hosts"
EXPERT_MODE_FILE="/opt/zapret-manager-luci/expert_mode"
PORTS_UDP="88,1024-2407,2409-4499,4502-19293,19345-49999,50101-65535"
PORTS_TCP="2099,2802,2302,2502,3478-3480,3724,6000-8000,8085,8090,8100,8903,8904,25565,27015-27030,27036-27037,35500-35600,50001,60442"
mkdir -p "$JOBS_DIR" "$ZM_STATE_DIR" 2>/dev/null

if command -v timeout >/dev/null 2>&1; then
	T90="timeout 90"; T60="timeout 60"
else
	T90=""; T60=""
fi

if command -v opkg >/dev/null 2>&1; then
	PKG="opkg"; INSTALL="$T90 opkg install"; DELETE="$T60 opkg remove"; UPDATE="$T60 opkg update"
	TG_ARCH="$(opkg print-architecture 2>/dev/null | awk '{print $2}' | tail -n1)"
	RAZ="ipk"
else
	PKG="apk"; INSTALL="$T90 apk add --allow-untrusted"; DELETE="$T60 apk del"; UPDATE="$T60 apk update"
	TG_ARCH="$(apk --print-arch 2>/dev/null)"
	RAZ="apk"
fi


esc() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '
}

esc_ml() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

_zm_zone_sec() { # ИМЯ_ЗОНЫ -> секция firewall
	local z
	for z in $(uci -q -X show firewall | sed -n "s/^firewall\.\([^.=]*\)=zone\$/\1/p"); do
		[ "$(uci -q get "firewall.$z.name")" = "$1" ] && { echo "$z"; return 0; }
	done
	return 1
}
_zm_zone_of_net() { # СЕТЬ -> имя зоны firewall, где она есть
	local z
	for z in $(uci -q -X show firewall | sed -n "s/^firewall\.\([^.=]*\)=zone\$/\1/p"); do
		case " $(uci -q get "firewall.$z.network") " in *" $1 "*) uci -q get "firewall.$z.name"; return 0 ;; esac
	done
	return 1
}
_zm_lan_zone() {
	local f w
	_zm_zone_of_net lan && return 0
	_zm_zone_sec lan >/dev/null && { echo lan; return 0; }
	w="$(_zm_wan_zone)"
	for f in $(uci -q -X show firewall | sed -n "s/^firewall\.\([^.=]*\)=forwarding\$/\1/p"); do
		[ "$(uci -q get "firewall.$f.dest")" = "$w" ] && { uci -q get "firewall.$f.src"; return 0; }
	done
	echo lan
}
_zm_wan_zone() { _zm_zone_of_net wan || echo wan; }
_zm_lan_nets() {
	local s n=""
	s="$(_zm_zone_sec "$(_zm_lan_zone)")" && n="$(uci -q get "firewall.$s.network")"
	echo "${n:-lan}"
}
_zm_lan_devs() {
	local s n d out=""
	for n in $(_zm_lan_nets); do
		d="$(ifstatus "$n" 2>/dev/null | jsonfilter -e '@.l3_device' 2>/dev/null)"
		[ -n "$d" ] || d="$(ifstatus "$n" 2>/dev/null | jsonfilter -e '@.device' 2>/dev/null)"
		[ -n "$d" ] || d="$(uci -q get "network.$n.device")"
		[ -n "$d" ] && [ -d "/sys/class/net/$d" ] || continue
		case " $out " in *" $d "*) ;; *) out="$out $d" ;; esac
	done
	if s="$(_zm_zone_sec "$(_zm_lan_zone)")"; then
		for d in $(uci -q get "firewall.$s.device"); do
			[ -d "/sys/class/net/$d" ] || continue
			case " $out " in *" $d "*) ;; *) out="$out $d" ;; esac
		done
	fi
	[ -n "$out" ] || out="br-lan"
	echo $out
}
_zm_lan_ip() {
	local n ip d
	for n in lan $(_zm_lan_nets); do
		ip="$(ifstatus "$n" 2>/dev/null | jsonfilter -e "@['ipv4-address'][0].address" 2>/dev/null)"
		[ -n "$ip" ] && { echo "$ip"; return 0; }
	done
	ip="$(uci -q get network.lan.ipaddr 2>/dev/null | awk '{ print $1 }' | cut -d/ -f1)"
	[ -n "$ip" ] && { echo "$ip"; return 0; }
	for d in $(_zm_lan_devs); do
		ip="$(ip -4 -o addr show dev "$d" 2>/dev/null | awk '{ print $4; exit }' | cut -d/ -f1)"
		[ -n "$ip" ] && { echo "$ip"; return 0; }
	done
	return 1
}

_pkg_is_installed() {
	if [ "$PKG" = "apk" ]; then apk info -e "$1" >/dev/null 2>&1
	else opkg list-installed 2>/dev/null | grep -q "^$1 "; fi
}

_ensure_deps() {
	local need="" updated=0
	command -v curl >/dev/null 2>&1 || need="$need curl"
	command -v unzip >/dev/null 2>&1 || need="$need unzip"
	[ -z "$need" ] && return 0
	echo "==> Устанавливаем зависимости:$need"
	$UPDATE >&2
	updated=1
	$INSTALL $need >&2
}


_job_running() { # ИМЯ
	local pid="$JOBS_DIR/$1.pid"
	[ -f "$pid" ] && kill -0 "$(cat "$pid" 2>/dev/null)" 2>/dev/null || return 1
	! grep -q '^__DONE__' "$JOBS_DIR/$1.log" 2>/dev/null
}

job_start() {
	local name="$1"; shift
	local log="$JOBS_DIR/$name.log"
	local pid="$JOBS_DIR/$name.pid"
	if _job_running "$name"; then
		printf '{"started":true,"job":"%s","already_running":true}\n' "$name"
		return 0
	fi
	: > "$log"
	( "$@" >>"$log" 2>&1; echo "__DONE__ $?" >>"$log" ) &
	echo $! > "$pid"
	printf '{"started":true,"job":"%s"}\n' "$name"
}

job_status() {
	local name="$1"
	local pid="$JOBS_DIR/$name.pid"
	local log="$JOBS_DIR/$name.log"
	local running="false" done="false" rc=""
	_job_running "$name" && running="true"
	if [ -f "$log" ] && grep -q '^__DONE__' "$log"; then
		done="true"
		rc=$(grep '^__DONE__' "$log" | tail -1 | awk '{print $2}')
	fi
	printf '{"running":%s,"done":%s,"rc":"%s"}\n' "$running" "$done" "$rc"
}

log_tail() {
	local name="$1"
	local log="$JOBS_DIR/$name.log"
	[ -f "$log" ] || { echo '{"lines":""}'; return; }
	printf '{"lines":"%s"}\n' "$(esc_ml "$(tail -n 300 "$log" | grep -v '^__DONE__')")"
}

zapret_restart() {
	[ -n "$ZM_NO_RESTART" ] && return 0
	chmod -R a+rX /opt/zapret/ipset /opt/zapret/files 2>/dev/null
	[ -x /opt/zapret/sync_config.sh ] && /opt/zapret/sync_config.sh >/dev/null 2>&1
	/etc/init.d/zapret restart >/dev/null 2>&1
}


_cpu_stat() { awk '/^cpu / { t = 0; for (i = 2; i <= NF; i++) t += $i; print t, $5 + $6; exit }' /proc/stat 2>/dev/null; }

_cpu_load() {
	local f="$JOBS_DIR/cpu.stat" now prev t1 i1 t2 i2
	mkdir -p "$JOBS_DIR"
	now="$(_cpu_stat)"
	[ -n "$now" ] || return 0
	if [ -s "$f" ] && [ -z "$(find "$f" -mmin +1 2>/dev/null)" ]; then
		prev="$(cat "$f")"
	else
		prev="$now"
		sleep 1
		now="$(_cpu_stat)"
	fi
	set -- $prev $now
	t1=$1; i1=$2; t2=$3; i2=$4
	# Замер слишком короткий (панель и боковое меню спросили почти одновременно) — отдаём прошлое значение
	if [ $((t2 - t1)) -lt 50 ] 2>/dev/null && [ -s "$f.pct" ]; then cat "$f.pct"; return 0; fi
	[ "$t2" -gt "$t1" ] 2>/dev/null || { echo 0; return 0; }
	echo "$now" > "$f"
	echo $(( (100 * ((t2 - t1) - (i2 - i1)) + (t2 - t1) / 2) / (t2 - t1) )) | tee "$f.pct"
}

_cpu_temp() {
	local z t typ best="" v
	for z in /sys/class/thermal/thermal_zone*; do
		[ -r "$z/temp" ] || continue
		t=$(cat "$z/temp" 2>/dev/null)
		case "$t" in ''|*[!0-9-]*) continue ;; esac
		typ=$(cat "$z/type" 2>/dev/null)
		case "$typ" in *cpu*|*CPU*|*soc*|*SOC*) best="$t"; break ;; esac
		{ [ -z "$best" ] || [ "$t" -gt "$best" ]; } && best="$t"
	done
	if [ -z "$best" ]; then
		for z in /sys/class/hwmon/hwmon*/temp1_input; do
			[ -r "$z" ] || continue
			t=$(cat "$z" 2>/dev/null)
			case "$t" in ''|*[!0-9-]*) continue ;; esac
			best="$t"; break
		done
	fi
	[ -n "$best" ] || return 0
	if [ "$best" -gt 1000 ] 2>/dev/null; then v=$(( (best + 50) / 100 )); echo "$((v / 10)).$((v % 10))"
	else echo "$best"; fi
}

# Есть ли интернет: пинг 1.1.1.1, затем 8.8.8.8 и 77.88.8.8. Пинг идёт в фоне,
# результат («время ok|fail мс») живёт 10 секунд — панель не ждёт сеть.
_inet_ping() {
	local h out ms
	for h in 1.1.1.1 8.8.8.8 77.88.8.8; do
		out=$(ping -c 1 -W 2 "$h" 2>/dev/null)
		ms=$(echo "$out" | sed -n 's/.*time=\([0-9.]*\).*/\1/p' | head -n1)
		[ -n "$ms" ] && { echo "$(date +%s) ok ${ms%%.*}"; return 0; }
	done
	echo "$(date +%s) fail"
}
_inet_state() { # печатает «ok|fail мс» или пусто, пока не проверяли
	local f="$ZM_STATE_DIR/inet" t r ms age
	read -r t r ms 2>/dev/null < "$f"
	age=$(( $(date +%s) - ${t:-0} ))
	if [ "$age" -ge 10 ] || [ "$age" -lt 0 ]; then
		mkdir -p "$ZM_STATE_DIR"
		if mkdir "$f.lock" 2>/dev/null; then
			( _inet_ping > "$f.new" 2>/dev/null && mv -f "$f.new" "$f"; rmdir "$f.lock" ) >/dev/null 2>&1 &
		elif [ -n "$(find "$f.lock" -mmin +1 2>/dev/null)" ]; then
			rmdir "$f.lock" 2>/dev/null
		fi
	fi
	[ -n "$r" ] && [ "$age" -lt 120 ] && echo "$r $ms"
}

system_info() {
	local model arch owrt df_out tmp_used tmp_free root_used root_free
	model=$(cat /tmp/sysinfo/model 2>/dev/null)
	arch=$(grep DISTRIB_ARCH /etc/openwrt_release 2>/dev/null | cut -d"'" -f2)
	owrt=$(grep '^DISTRIB_RELEASE=' /etc/openwrt_release 2>/dev/null | cut -d"'" -f2)
	local target
	target=$(grep '^DISTRIB_TARGET=' /etc/openwrt_release 2>/dev/null | cut -d"'" -f2)
	df_out=$(df -h /tmp / 2>/dev/null)
	tmp_used=$(echo "$df_out" | awk 'NR==2{print $3}')
	tmp_free=$(echo "$df_out" | awk 'NR==2{print $4}')
	root_used=$(echo "$df_out" | awk 'NR==3{print $3}')
	root_free=$(echo "$df_out" | awk 'NR==3{print $4}')
	local inet inet_ms
	set -- $(_inet_state)
	inet="$1"; inet_ms="$2"
	printf '{"model":"%s","arch":"%s","openwrt":"%s","target":"%s","hostname":"%s","kernel":"%s","tmp_used":"%s","tmp_free":"%s","root_used":"%s","root_free":"%s","cpu_temp":"%s","cpu_load":"%s","inet":"%s","inet_ms":"%s"}\n' \
		"$(esc "$model")" "$(esc "$arch")" "$(esc "$owrt")" "$(esc "$target")" "$(esc "$(cat /proc/sys/kernel/hostname 2>/dev/null)")" "$(esc "$(uname -r 2>/dev/null)")" \
		"$(esc "$tmp_used")" "$(esc "$tmp_free")" "$(esc "$root_used")" "$(esc "$root_free")" "$(_cpu_temp)" "$(_cpu_load)" "$inet" "$inet_ms"
}

status() {
	local zr="not_installed" zr_running="false" zr_ver=""
	_test_recover
	if [ -f /etc/init.d/zapret ]; then
		zr="installed"
		if [ "$PKG" = "opkg" ]; then
			zr_ver=$(opkg list-installed zapret 2>/dev/null | awk '{sub(/-r[0-9]+$/,"",$3); print $3}')
		else
			zr_ver=$(apk info -v 2>/dev/null | grep '^zapret-' | head -n1 | cut -d- -f2 | sed 's/-r[0-9]\+$//')
		fi
		pgrep -f "/opt/zapret/" >/dev/null 2>&1 && zr_running="true"
	fi

	local zr2="not_installed" zr2_running="false"
	if [ -f /etc/init.d/zapret2 ]; then
		zr2="installed"
		/etc/init.d/zapret2 status >/dev/null 2>&1 && zr2_running="true"
	fi

	local strat="" fs_marker=""
	if [ -f "$CONF" ]; then
		strat=$(sed -n "/^[[:space:]]*option NFQWS_OPT '\$/,/^[[:space:]]*'\$/p" "$CONF" | grep '^#' | sed 's/^#[[:space:]]*//; s/[[:space:]]*$//; /^udp443$/d' | tr '\n' ' ' | sed 's/ $//')
		_udp443_on && strat="${strat:+$strat }QUIC"
		fs_marker=$(grep -m1 '^# ZMFS:' "$CONF" | sed 's/^# ZMFS://')
		sed -n "/^[[:space:]]*option NFQWS_OPT '\$/,/^[[:space:]]*'\$/p" "$CONF" | grep -qi '^#[[:space:]]*customstart' && strat="Custom"
	fi

	printf '{"pkg":"%s","zapret":"%s","zapret_running":%s,"zapret_version":"%s","zapret2":"%s","zapret2_running":%s,"strategy":"%s","flowseal":"%s","yv_off":%s,"quic_yt":%s}\n' \
		"$PKG" "$zr" "$zr_running" "$(esc "$zr_ver")" "$zr2" "$zr2_running" "$(esc "$strat")" "$(esc "$fs_marker")" \
		"$([ -f /opt/zapret-manager-luci/yv_off ] && echo true || echo false)" \
		"$([ -f "$CONF" ] && _udp443_on && echo true || echo false)"
}


_zapret_latest_version() {
	local ver
	ver=$(curl -fsSI --connect-timeout 4 --max-time 6 \
		"https://github.com/remittor/zapret-openwrt/releases/latest" 2>/dev/null \
		| tr -d '\r' | awk -F': ' 'tolower($1)=="location"{print $2}' | tail -n1 | sed 's#.*/v##')
	echo "$ver" | grep -qE '^[0-9]+\.[0-9]+$' && echo "$ver" || echo ""
}

zapret_latest_version() {
	printf '{"version":"%s"}\n' "$(esc "$(_zapret_latest_version)")"
}

do_install_zapret() {
	_ensure_deps
	if [ -f /etc/init.d/zapret2 ] && [ ! -f "$EXPERT_MODE_FILE" ]; then
		echo "ОШИБКА: установлен Zapret2, он несовместим с Zapret — сначала удалите Zapret2"
		return 1
	fi
	echo "==> Определяем версию Zapret"
	local ver arch url tmp
	ver="$(_zapret_latest_version)"
	[ -z "$ver" ] && { echo "!! Не удалось определить версию, использую фиксированную 72.20260307"; ver="72.20260307"; }
	arch="$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)"
	url="${GH_MAIN}/remittor/zapret-openwrt/releases/download/v${ver}/zapret_v${ver}_${arch}.zip"
	tmp="$JOBS_DIR/install_tmp"; rm -rf "$tmp"; mkdir -p "$tmp"; cd "$tmp" || return 1

	echo "==> Обновляем список пакетов"
	$UPDATE

	if [ -f /etc/init.d/zapret ]; then
		echo "==> Останавливаем текущий Zapret"
		/etc/init.d/zapret stop >/dev/null 2>&1
		for p in $(pgrep -f "/opt/zapret/" 2>/dev/null); do kill -9 "$p" 2>/dev/null; done
	fi

	echo "==> Скачиваем $url"
	local attempt=1 max_attempts=5
	while [ "$attempt" -le "$max_attempts" ]; do
		rm -f zapret.zip
		wget -q --timeout=20 -U "Mozilla/5.0" -O zapret.zip "$url" >&2 || echo "!! Попытка $attempt из $max_attempts: архив не скачался"
		command -v unzip >/dev/null 2>&1 || { echo "==> Устанавливаем unzip"; $INSTALL unzip >&2; }
		if [ -s zapret.zip ] && unzip -tq zapret.zip >/dev/null 2>&1; then
			break
		fi
		attempt=$((attempt + 1))
	done
	if [ "$attempt" -gt "$max_attempts" ]; then
		echo "ОШИБКА: не удалось скачать целый архив за $max_attempts попыток — проверьте соединение с GitHub"
		return 1
	fi
	unzip -o zapret.zip >/dev/null 2>&1

	echo "==> Устанавливаем пакеты"
	if [ "$PKG" = "apk" ]; then
		for p in apk/zapret*; do
			[ -f "$p" ] || continue
			echo "$p" | grep -q luci && continue
			echo "  - $(basename "$p")"; $INSTALL "$p" >&2 || { echo "ОШИБКА: $p"; return 1; }
		done
		for p in apk/luci*; do
			[ -f "$p" ] || continue
			echo "  - $(basename "$p")"; $INSTALL "$p" >&2
		done
	else
		for p in zapret_*.ipk; do
			[ -f "$p" ] || continue
			echo "  - $(basename "$p")"; $INSTALL "$p" >&2 || { echo "ОШИБКА: $p"; return 1; }
		done
		for p in luci-app-zapret_*.ipk; do
			[ -f "$p" ] || continue
			echo "  - $(basename "$p")"; $INSTALL "$p" >&2
		done
	fi

	echo "==> Добавляем домены в исключения"
	rm -f /opt/zapret/ipset/zapret-hosts-user-exclude.txt
	wget -q --timeout=20 -U "Mozilla/5.0" -O /opt/zapret/ipset/zapret-hosts-user-exclude.txt "$EXCLUDE_URL"

	do_add_fake_flow

	echo "==> Включаем автозапуск и custom.d-скрипты"
	/etc/init.d/zapret enable >/dev/null 2>&1
	sed -i "/DISABLE_CUSTOM/s/'1'/'0'/" "$CONF" 2>/dev/null

	cd /; rm -rf "$tmp"
	echo "==> Готово, Zapret установлен ($ver)"
}

do_install_zapret_full() {
	do_install_zapret || return 1
	[ -f /etc/init.d/zapret ] || return 1

	echo "==> Применяем базовую стратегию v7"
	strategy_set_v v7 >/dev/null

	echo "==> Добавляем домены в hosts"
	local b blocks="ai instagram ntc librusec telegram twitch scell spotify rutor"
	for b in $blocks; do
		local content line
		content="$(_hosts_block "$b")"
		while IFS= read -r line; do
			[ -z "$line" ] && continue
			_hosts_has_line "$line" || echo "$line" >> "$HOSTS_FILE"
		done <<-HOSTBLOCK
		$content
		HOSTBLOCK
	done
	/etc/init.d/dnsmasq restart >/dev/null 2>&1

	echo "==> Настраиваем игровую стратегию Gv1"
	game_set 1 >/dev/null

	echo "==> Готово, Zapret установлен и настроен"
}

do_remove_zapret() {
	echo "==> Останавливаем Zapret"
	/etc/init.d/zapret stop >/dev/null 2>&1
	for p in $(pgrep -f "/opt/zapret/" 2>/dev/null); do kill -9 "$p" 2>/dev/null; done
	echo "==> Удаляем пакеты"
	$DELETE luci-app-zapret >&2
	$DELETE zapret >&2
	echo "==> Удаляем файлы"
	rm -rf /opt/zapret "$CONF" /etc/init.d/zapret /etc/firewall.zapret "$YV_OFF_FLAG" "$DV_OFF_FLAG"
	crontab -l 2>/dev/null | awk '{ l = tolower($0) } l ~ /zapret/ && l !~ /zapret-manager|zapret2/ { next } { print }' | crontab - 2>/dev/null
	echo "==> Готово, Zapret удалён"
}

zapret_action() {
	local action="$1"
	case "$action" in
		install)        job_start install_zapret do_install_zapret_full ;;
		update)         job_start install_zapret do_install_zapret ;;
		remove)         job_start remove_zapret  do_remove_zapret ;;
		start)          /etc/init.d/zapret start >/dev/null 2>&1; zapret_restart; status ;;
		stop)
			/etc/init.d/zapret stop >/dev/null 2>&1
			for p in $(pgrep -f "/opt/zapret/" 2>/dev/null); do kill -9 "$p" 2>/dev/null; done
			status ;;
		*) echo '{"error":"неизвестное действие"}' ;;
	esac
}


do_install_zapret2() {
	_ensure_deps
	local arch
	arch="$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)"
	if [ "$arch" != "aarch64_cortex-a53" ]; then
		echo "ОШИБКА: Zapret2 поддерживает только архитектуру aarch64_cortex-a53 (у вас: $arch)"
		return 1
	fi
	if [ -f /etc/init.d/zapret ] && [ ! -f "$EXPERT_MODE_FILE" ]; then
		echo "ОШИБКА: установлен основной Zapret, он несовместим с Zapret2 — сначала удалите Zapret"
		return 1
	fi

	local base_url raz
	if [ "$PKG" = "apk" ]; then
		base_url="https://packages.routerich.ru/25.12/mediatek/filogic/routerich/"; raz="apk"
	else
		base_url="https://packages.routerich.ru/24.10/mediatek/filogic/routerich/"; raz="ipk"
	fi

	local tmp="$JOBS_DIR/install_z2_tmp"; rm -rf "$tmp"; mkdir -p "$tmp"; cd "$tmp" || return 1

	echo "==> Ищем актуальный пакет Zapret2 в $base_url"
	curl -fsS --connect-timeout 8 --max-time 15 "$base_url" -o index.html \
		|| { echo "ОШИБКА: не удалось получить список пакетов"; return 1; }

	local main_file luci_file
	if [ "$PKG" = "apk" ]; then
		main_file=$(grep -oE 'zapret2-[0-9][^"]*\.apk' index.html | head -n1)
		luci_file=$(grep -oE 'luci-app-zapret2-[0-9][^"]*\.apk' index.html | head -n1)
	else
		main_file=$(grep -oE 'zapret2_[0-9][^"]*_aarch64_cortex-a53\.ipk' index.html | head -n1)
		luci_file=$(grep -oE 'luci-app-zapret2_[0-9][^"]*_all\.ipk' index.html | head -n1)
	fi
	[ -z "$main_file" ] && { echo "ОШИБКА: пакет zapret2 не найден в репозитории"; return 1; }

	echo "==> Скачиваем $main_file"
	curl -fsSL --max-time 30 "${base_url}${main_file}" -o "$main_file" || { echo "ОШИБКА скачивания $main_file"; return 1; }
	if [ -n "$luci_file" ]; then
		echo "==> Скачиваем $luci_file"
		curl -fsSL --max-time 30 "${base_url}${luci_file}" -o "$luci_file"
	fi

	echo "==> Обновляем список пакетов"
	$UPDATE

	echo "==> Устанавливаем"
	$INSTALL ./*."$raz" || { echo "ОШИБКА установки"; return 1; }

	echo "==> Добавляем домены в исключения"
	mkdir -p /opt/zapret2/ipset
	wget -q --timeout=20 -U "Mozilla/5.0" -O /opt/zapret2/ipset/zapret_hosts_user_exclude.txt "$EXCLUDE_URL"

	echo "==> Настраиваем стратегии"
	mkdir -p /opt/zapret2/init.d/openwrt/custom.d
	wget -q --timeout=20 -U "Mozilla/5.0" -O /opt/zapret2/init.d/openwrt/custom.d/50-discord_media.sh \
		"${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/Zapret2/50-discord_media.sh" \
		|| echo "!! Не удалось загрузить 50-discord_media.sh"
	wget -q --timeout=20 -U "Mozilla/5.0" -O /etc/config/zapret2 \
		"${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/Zapret2/zapret2" \
		|| echo "!! Не удалось загрузить zapret2"
	wget -q --timeout=20 -U "Mozilla/5.0" -O /opt/zapret2/ipset/zapret_hosts_discord.txt \
		"${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/Zapret2/zapret_hosts_discord.txt" \
		|| echo "!! Не удалось загрузить zapret_hosts_discord.txt"

	echo "==> Запускаем Zapret2"
	/etc/init.d/zapret2 enable >/dev/null 2>&1
	/etc/init.d/zapret2 restart >/dev/null 2>&1

	cd /; rm -rf "$tmp"
	echo "==> Готово, Zapret2 установлен"
}

do_remove_zapret2() {
	echo "==> Останавливаем Zapret2"
	/etc/init.d/zapret2 stop >/dev/null 2>&1
	echo "==> Удаляем пакеты"
	$DELETE luci-app-zapret2 >&2
	$DELETE zapret2 >&2
	echo "==> Удаляем файлы"
	rm -f /etc/config/zapret2
	rm -rf /opt/zapret2
	echo "==> Готово, Zapret2 удалён"
}

zapret2_action() {
	local action="$1"
	case "$action" in
		install|update) job_start install_zapret2 do_install_zapret2 ;;
		remove)         job_start remove_zapret2  do_remove_zapret2 ;;
		start)          /etc/init.d/zapret2 start >/dev/null 2>&1; status ;;
		stop)           /etc/init.d/zapret2 stop >/dev/null 2>&1; status ;;
		*) echo '{"error":"неизвестное действие"}' ;;
	esac
}


strategy_v1()  { printf '%s\n' "#v1"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=split2" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin"; }
strategy_v2()  { printf '%s\n' "#v2"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=ts" "--dpi-desync-repeats=8" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com"; }
strategy_v3()  { printf '%s\n' "#v3"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-hostfakesplit-mod=host=ozon.ru" "--dpi-desync-repeats=4" "--dpi-desync-fooling=ts,md5sig" "--dpi-desync-badseq-increment=0"; }
strategy_v4()  { printf '%s\n' "#v4"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=582" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin"; }
strategy_v5()  { printf '%s\n' "#v5"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,fakeddisorder" "--dpi-desync-split-pos=1" "--dpi-desync-fake-tls=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-badseq-increment=0"; }
strategy_v6()  { printf '%s\n' "#v6"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-hostfakesplit-mod=host=i2.photo.2gis.com" "--dpi-desync-hostfakesplit-midhost=host-2" "--dpi-desync-split-seqovl=726" "--dpi-desync-fooling=badsum,badseq" "--dpi-desync-badseq-increment=0"; }
strategy_v7()  { printf '%s\n' "#v7"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=654" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-repeats=8" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin" "--dpi-desync-fake-tls=/opt/zapret/files/fake/stun.bin" "--dpi-desync-badseq-increment=0"; }
strategy_v8()  { printf '%s\n' "#v8"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake" "--dpi-desync-fooling=ts" "--dpi-desync-fake-tls=/opt/zapret/files/fake/4pda.bin" "--dpi-desync-fake-tls-mod=none"; }
strategy_v9()  { printf '%s\n' "#v9"  "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=hostfakesplit" "--dpi-desync-fooling=badseq,badsum" "--dpi-desync-hostfakesplit-mod=host=ozon.ru" "--dpi-desync-badseq-increment=0"; }
strategy_v10() { printf '%s\n' "#v10" "--filter-tcp=443" "--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt" "--dpi-desync=fake,split2" "--dpi-desync-split-pos=2" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-hostfakesplit-mod=host=maxcdn.bootstrapcdn.com" "--dpi-desync-fake-tls-mod=rnd,sni=maxcdn.bootstrapcdn.com" "--dpi-desync-fooling=ts"; }


_add_gp_domains() {
	local f="/opt/zapret/ipset/zapret-hosts-google.txt" tmp
	mkdir -p "$(dirname "$f")"
	tmp="$f.tmp"
	{
		[ -f "$f" ] && cat "$f"
		printf '%s\n' "gvt1.com" "googleplay.com" "play.google.com" "beacons.gvt2.com" \
			"play.googleapis.com" "play-fe.googleapis.com" "lh3.googleusercontent.com" \
			"android.clients.google.com" "connectivitycheck.gstatic.com" \
			"play-lh.googleusercontent.com" "play-games.googleusercontent.com" \
			"prod-lt-playstoregatewayadapter-pa.googleapis.com" "youtubei.youtube.com"
	} | sort -u > "$tmp"
	mv "$tmp" "$f"
}

_refresh_exclude_file() {
	rm -f /opt/zapret/ipset/zapret-hosts-user-exclude.txt
	wget -q --timeout=20 -U "Mozilla/5.0" -O /opt/zapret/ipset/zapret-hosts-user-exclude.txt "$EXCLUDE_URL"
}

YV_OFF_FLAG="/opt/zapret-manager-luci/yv_off"
DV_OFF_FLAG="/opt/zapret-manager-luci/dv_off"
DISCORD_RX='^--filter-l7=discord,stun$|^--filter-udp=19294-19344,50000-50100$|^--filter-tcp=2053,2083,2087,2096,8443$|^--hostlist-domains=discord[.]media$|^#[ \t]*Dv[0-9]+$'

YV_RX='^#[ \t]*Yv[0-9]+$|^--hostlist=/opt/zapret/ipset/zapret-hosts-google[.]txt$'
NFQ_MARK_RX='^[ \t]*#[ \t]*((Yv|Dv|Gv)[0-9]|udp443[ \t]*$)'
UDP443_MARK_RX='^[ \t]*#[ \t]*udp443[ \t]*$'

_nfq_drop_profiles() {
	local rx="$1" force="$2" keep="$3" old="$JOBS_DIR/nfq_drop_old" new="$JOBS_DIR/nfq_drop_new" rc
	mkdir -p "$JOBS_DIR"
	awk "/^[[:space:]]*option NFQWS_OPT '\$/ { f = 1 } f" "$CONF" > "$old"
	[ -s "$old" ] || { rm -f "$old"; return 1; }
	grep -q "^[[:space:]]*'[[:space:]]*\$" "$old" || { rm -f "$old"; return 1; }
	awk -v RX="$rx" -v KP="$keep" -v MK="$NFQ_MARK_RX" -v UQ="$UDP443_MARK_RX" -v q="'" '
		function emit(l) { o[++no] = l }
		function flush(   i, drop, real, udp) {
			if (n == 0 && np == 0) return
			drop = 0; real = 0; udp = 0
			for (i = 1; i <= np; i++) if (pc[i] ~ RX) drop = 1
			for (i = 1; i <= n; i++) {
				if (b[i] ~ RX) drop = 1
				if (b[i] !~ /^[ \t]*#/) real++
				if (b[i] == "--filter-udp=443") udp = 1
			}
			if (drop && KP != "") {
				for (i = 1; i <= np; i++) if (pc[i] ~ KP) drop = 0
				for (i = 1; i <= n; i++) if (b[i] ~ KP) drop = 0
			}
			if (drop) removed = 1
			else if (real > 0) {
				for (i = 1; i <= np; i++) if (udp || pc[i] !~ UQ) emit(pc[i])
				if (printed) emit("--new")
				for (i = 1; i <= n; i++) if (udp || b[i] !~ UQ) emit(b[i])
				printed = 1
			}
			n = 0; np = 0
		}
		function hold_in(   i) { for (i = 1; i <= nh; i++) b[++n] = h[i]; nh = 0 }
		NR == 1 { head = $0; next }
		done { tail[++nt] = $0; next }
		$0 ~ ("^[ \t]*" q "[ \t]*$") {
			hold_in(); flush()
			print head
			for (i = 1; i <= nn; i++) print nm[i]
			for (i = 1; i <= no; i++) print o[i]
			print
			done = 1; next
		}
		/^[ \t]*$/ { next }
		$0 == "--new" { flush(); for (k = 1; k <= nh; k++) pc[++np] = h[k]; nh = 0; next }
		/^[ \t]*#/ {
			if ($0 ~ MK) h[++nh] = $0
			else if (!(($0) in seen)) { seen[$0] = 1; nm[++nn] = $0 }
			next
		}
		{ hold_in(); b[++n] = $0 }
		END {
			if (!done) exit 1
			for (i = 1; i <= nt; i++) print tail[i]
			exit (removed ? 0 : 3)
		}' "$old" > "$new"
	rc=$?
	if [ "$rc" = 0 ] || { [ "$rc" = 3 ] && [ -n "$force" ]; }; then
		sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"
		cat "$new" >> "$CONF"
	fi
	rm -f "$old" "$new"
	return $rc
}

_nfq_normalize() { _nfq_drop_profiles '^#ZM_NEVER_MATCHES$' force; return 0; }

# Блок QUIC (UDP 443) для YouTube — тот же, что в консольном Zapret Manager («#udp443»)
_nfq_opt_body() { sed -n "/^[[:space:]]*option NFQWS_OPT '\$/,/^[[:space:]]*'\$/p" "$CONF" 2>/dev/null; }
_udp443_on() { _nfq_opt_body | grep -qx -- '--filter-udp=443'; }
_udp443_add() {
	_udp443_on && return 0
	sed -i '/^[[:space:]]*#[[:space:]]*udp443[[:space:]]*$/d' "$CONF"
	sed -i "/^[[:space:]]*option NFQWS_OPT '/a\\#udp443\\n--filter-udp=443\\n--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt\\n--dpi-desync=fake\\n--dpi-desync-repeats=11\\n--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin\\n--new" "$CONF"
	_add_ports_if_missing NFQWS_PORTS_UDP 443
}

youtube_quic_set() {
	local mode="$1"
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	case "$mode" in
		on)
			_udp443_on && { printf '{"ok":true,"quic":true}\n'; return 0; }
			_add_gp_domains
			_udp443_add
			_nfq_normalize ;;
		off)
			_udp443_on || { sed -i '/^[[:space:]]*#[[:space:]]*udp443[[:space:]]*$/d' "$CONF"; printf '{"ok":true,"quic":false}\n'; return 0; }
			_nfq_drop_profiles '^--filter-udp=443$'
			case $? in 0|3) ;; *) echo '{"error":"блок стратегий Zapret (NFQWS_OPT) записан не так, как его пишет панель, — блок QUIC не тронут"}'; return 1 ;; esac
			sed -i '/^[[:space:]]*#[[:space:]]*udp443[[:space:]]*$/d' "$CONF" ;;
		*) echo '{"error":"неизвестное действие"}'; return 1 ;;
	esac
	zapret_restart
	printf '{"ok":true,"quic":%s}\n' "$(_udp443_on && echo true || echo false)"
}

_add_yv_default() {
	[ -f "$YV_OFF_FLAG" ] && return 0
	if ! grep -q "^#Yv" "$CONF" && ! grep -q "^#general" "$CONF"; then
		sed -i "/^[[:space:]]*option NFQWS_OPT '/a\\#Yv08\\n--filter-tcp=443\\n--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt\\n--dpi-desync=hostfakesplit\\n--dpi-desync-hostfakesplit-mod=host=google.com\\n--dpi-desync-fooling=ts\\n--new" "$CONF"
	fi
}

_discord_str_add() {
	[ -f "$DV_OFF_FLAG" ] && return 0
	if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then
		sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'\$/,19294-19344,50000-50100'/" "$CONF"
	fi
	if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"; then
		sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'\$/,2053,2083,2087,2096,8443'/" "$CONF"
	fi
	if ! grep -q -- "--filter-udp=19294-19344,50000-50100" "$CONF"; then
		local last_line1
		last_line1=$(grep -n "^'\$" "$CONF" | tail -n1 | cut -d: -f1)
		[ -n "$last_line1" ] && sed -i "${last_line1},\$d" "$CONF"
		printf "%s\n" "--new" "--filter-udp=19294-19344,50000-50100" "--filter-l7=discord,stun" \
			"--dpi-desync=fake" "--dpi-desync-fake-discord=/opt/zapret/files/fake/stun.bin" \
			"--dpi-desync-fake-stun=/opt/zapret/files/fake/stun.bin" "--dpi-desync-repeats=6" \
			"#Dv1" "--new" "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" \
			"--dpi-desync=multisplit" "--dpi-desync-split-seqovl=652" "--dpi-desync-split-pos=2" \
			"--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" \
			"'" >> "$CONF"
	fi
}

_ts_warning() { grep -q "=ts" "$CONF" 2>/dev/null && echo true || echo false; }

strategy_list_v() {
	printf '{"items":[%s]}\n' "$(
		i=1
		while [ "$i" -le 10 ]; do
			printf '{"id":"v%s","label":"Стратегия v%s"}' "$i" "$i"
			[ "$i" -lt 10 ] && printf ','
			i=$((i + 1))
		done
	)"
}

strategy_set_v() {
	local version="$1" yv dv gv xt q
	echo "$version" | grep -qE '^v([1-9]|10)$' || { echo '{"error":"некорректная версия"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	_udp443_on && q=1
	yv=$(grep -oE '^#[[:space:]]*Yv[0-9]+$' "$CONF" | head -n1 | sed 's/^#[[:space:]]*//')
	dv=$(grep -oE '^#[[:space:]]*Dv[0-9]+$' "$CONF" | head -n1 | sed 's/^#[[:space:]]*Dv//')
	gv=$(grep -oE '^#Gv[1-4](Xtreme)?$' "$CONF" | head -n1 | sed 's/^#Gv//; s/Xtreme$//')
	grep -q "^#Gv[0-9]\+Xtreme\$" "$CONF" && xt=1
	_game_xtreme_undo_opts
	_remove_ports_if_present NFQWS_PORTS_UDP "$PORTS_UDP"
	_remove_ports_if_present NFQWS_PORTS_TCP "$PORTS_TCP"
	sed -i '/^# ZMFS:/d' "$CONF"
	sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"
	{ echo "	option NFQWS_OPT '"; strategy_"$version"; echo "'"; } >> "$CONF"
	_add_gp_domains
	_refresh_exclude_file
	_add_yv_default
	_discord_str_add
	ZM_NO_RESTART=1
	if [ -n "$yv" ] && [ "$yv" != Yv08 ] && [ ! -f "$YV_OFF_FLAG" ] && [ ! -s "$(_yv_file)" ]; then
		do_yv_download >/dev/null 2>&1
	fi
	if [ -n "$yv" ] && [ "$yv" != Yv08 ] && [ ! -f "$YV_OFF_FLAG" ] && [ -s "$(_yv_file)" ] && grep -qxF "#$yv" "$(_yv_file)"; then
		strategy_set_youtube "$yv" >/dev/null
	fi
	[ -n "$dv" ] && [ "$dv" != 1 ] && [ ! -f "$DV_OFF_FLAG" ] && discord_set_dv "$dv" >/dev/null
	if [ -n "$gv" ]; then
		game_set "$gv" >/dev/null
		[ -n "$xt" ] && game_toggle_xtreme >/dev/null
	fi
	[ -n "$q" ] && _udp443_add
	ZM_NO_RESTART=""
	_nfq_normalize
	zapret_restart
	printf '{"ok":true,"strategy":"%s","ts_warning":%s}\n' "$version" "$(_ts_warning)"
}


_flowseal_file() { echo "$JOBS_DIR/flowseal_strategies.txt"; }

do_add_fake_flow() {
	[ -d /opt/zapret ] || return 0
	[ -f "$CONF" ] || return 0
	local f msg=0
	for f in stun2.bin quic_initial_tencent_com.bin quic_initial_steamcommunity_com.bin \
		tls_clienthello_sochi_park.bin quic_initial_4pda_to.bin quic_initial_5ka_ru.bin \
		tls_clienthello_5ka_ru.bin quic_initial_rutube_ru.bin; do
		if [ ! -f "/opt/zapret/files/fake/$f" ]; then
			[ "$msg" = 0 ] && { echo "==> Скачиваем дополнительные fake-файлы"; msg=1; }
			wget -q --timeout=20 -U "Mozilla/5.0" -O "/opt/zapret/files/fake/$f" "${FLOWSEAL_FAKE_RAW}/$f" \
				|| echo "!! Не удалось загрузить файл $f"
		fi
	done
}

do_flowseal_download() {
	_ensure_deps
	local out zip tmp attempt=1 max_attempts=5
	out="$(_flowseal_file)"; zip="$JOBS_DIR/flowseal.zip"; tmp="$JOBS_DIR/flowseal_src"
	echo "==> Скачиваем список стратегий Flowseal"
	rm -rf "$tmp" "$zip"; : > "$out"
	command -v unzip >/dev/null 2>&1 || $INSTALL unzip >&2

	while [ "$attempt" -le "$max_attempts" ]; do
		rm -f "$zip"
		wget -q --timeout=20 -U "Mozilla/5.0" -O "$zip" "$FLOWSEAL_ZIP" >&2
		if [ -s "$zip" ] && unzip -tq "$zip" >/dev/null 2>&1; then
			break
		fi
		attempt=$((attempt + 1))
	done
	if [ "$attempt" -gt "$max_attempts" ]; then
		echo "ОШИБКА: не удалось скачать целый архив за $max_attempts попыток — проверьте соединение с GitHub"
		return 1
	fi

	mkdir -p "$tmp"; unzip -oq "$zip" -d "$tmp" || { echo "ОШИБКА распаковки"; return 1; }
	local base="$tmp/zapret-discord-youtube-main"

	echo "==> Разбираем .bat-стратегии"
	find "$base" -type f -name 'general*.bat' ! -name 'general (ALT5).bat' | while read -r F; do
		MATCH=$(grep -E '^--filter-udp=19294-19344,50000-50100|^--filter-tcp=%GameFilterTCP%|^--filter-udp=%GameFilterUDP%|^--filter-tcp=2053,2083,2087,2096,8443|^--filter-tcp=443 --hostlist="%LISTS%list-google.txt"|^--filter-tcp=80,443 --hostlist="%LISTS%list-general.txt"' "$F")
		[ -z "$MATCH" ] && continue
		NAME=$(basename "$F" .bat)
		{ echo "#$NAME"; echo "$MATCH" | sed 's/--/\n--/g' | sed '/^$/d' | sed 's/[[:space:]]*$//'; echo; } >> "$out"
	done

	echo "==> Приводим пути и плейсхолдеры к реальным (как в оригинальном download_strategies)"
	sed -i '/--hostlist="%LISTS%list-general.txt"/d' "$out"
	sed -i '/--ipset="%LISTS%ipset-all.txt"/d' "$out"
	sed -i '/--hostlist="%LISTS%list-general-user.txt"/d' "$out"
	sed -i '/--ipset-exclude="%LISTS%ipset-exclude.txt"/d' "$out"
	sed -i '/--ipset-exclude="%LISTS%ipset-exclude-user.txt"/d' "$out"
	sed -i '/--hostlist-exclude="%LISTS%list-exclude-user.txt"/d' "$out"
	sed -i 's|"%LISTS%list-exclude.txt"|/opt/zapret/ipset/zapret-hosts-user-exclude.txt|g' "$out"
	sed -i 's|"%LISTS%list-google.txt"|/opt/zapret/ipset/zapret-hosts-google.txt|g' "$out"
	sed -i 's/--new[[:space:]]\^/--new/g' "$out"

	sed -i 's|"%BIN%tls_clienthello_www_google_com.bin"|/opt/zapret/files/fake/tls_clienthello_www_google_com.bin|g' "$out"
	sed -i 's|"%BIN%tls_clienthello_sochi_park.bin"|/opt/zapret/files/fake/tls_clienthello_sochi_park.bin|g' "$out"
	sed -i 's|"%BIN%stun.bin"|/opt/zapret/files/fake/stun.bin|g' "$out"
	sed -i 's|"%BIN%tls_clienthello_4pda_to.bin"|/opt/zapret/files/fake/4pda.bin|g' "$out"
	sed -i 's|"%BIN%quic_initial_www_google_com.bin"|/opt/zapret/files/fake/quic_initial_www_google_com.bin|g' "$out"
	sed -i 's|"%BIN%stun2.bin"|/opt/zapret/files/fake/stun2.bin|g' "$out"
	sed -i 's|"%BIN%quic_initial_tencent_com.bin"|/opt/zapret/files/fake/quic_initial_tencent_com.bin|g' "$out"
	sed -i 's|"%BIN%quic_initial_steamcommunity_com.bin"|/opt/zapret/files/fake/quic_initial_steamcommunity_com.bin|g' "$out"
	sed -i 's|"%BIN%quic_initial_4pda_to.bin"|/opt/zapret/files/fake/quic_initial_4pda_to.bin|g' "$out"
	sed -i 's|"%BIN%ACTIVE_DISCORD_UDP.bin"|/opt/zapret/files/fake/quic_initial_steamcommunity_com.bin|g' "$out"
	sed -i 's|"%BIN%ACTIVE_GAME_UDP.bin"|/opt/zapret/files/fake/quic_initial_4pda_to.bin|g' "$out"
	sed -i 's|"%BIN%tls_clienthello_max_ru.bin"|/opt/zapret/files/fake/tls_clienthello_www_onetrust_com.bin|g' "$out"
	sed -i 's|"%BIN%quic_initial_5ka_ru.bin"|/opt/zapret/files/fake/quic_initial_5ka_ru.bin|g' "$out"
	sed -i 's|"%BIN%quic_initial_rutube_ru.bin"|/opt/zapret/files/fake/quic_initial_rutube_ru.bin|g' "$out"
	sed -i 's|\^!|/opt/zapret/files/fake/tls_clienthello_www_google_com.bin|g' "$out"

	sed -i "s|%GameFilterTCP%|$PORTS_TCP|g" "$out"
	sed -i "s|%GameFilterUDP%|$PORTS_UDP|g" "$out"

	sed -i 's/[[:space:]]\+$//' "$out"
	sed -i '/^[[:space:]]*$/d' "$out"
	sed -i '/^--new$/ { N; /^--new\n$/d; }' "$out"

	rm -rf "$tmp" "$zip"

	do_add_fake_flow

	echo "==> Готово, стратегий: $(grep -c '^#' "$out")"
}


strategy_list_flowseal() {
	local f; f="$(_flowseal_file)"
	if [ ! -s "$f" ] || [ "$1" = refresh ]; then
		job_start flowseal_download do_flowseal_download
		return
	fi
	printf '{"items":[%s]}\n' "$(
		grep '^#' "$f" | sed 's/^#//' | awk '{
			gsub(/\\/,"\\\\"); gsub(/"/,"\\\"");
			printf "%s{\"id\":\"%s\",\"label\":\"%s\"}", (NR>1?",":""), $0, $0
		}'
	)"
}

strategy_set_flowseal() {
	local name="$1" f block q
	f="$(_flowseal_file)"
	[ -s "$f" ] || { echo '{"error":"список не загружен — сначала обновите"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	block=$(awk -v n="#$name" '$0==n{flag=1; print; next} /^#/ && flag{exit} flag{print}' "$f")
	[ -z "$block" ] && { echo '{"error":"стратегия не найдена"}'; return 1; }
	_udp443_on && q=1
	rm -f "$YV_OFF_FLAG" "$DV_OFF_FLAG"
	_game_xtreme_undo_opts
	_remove_ports_if_present NFQWS_PORTS_UDP "$PORTS_UDP"
	_remove_ports_if_present NFQWS_PORTS_TCP "$PORTS_TCP"
	sed -i '/^# ZMFS:/d' "$CONF"
	{ printf '# ZMFS:%s\n' "$name"; cat "$CONF"; } > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
	sed -i "/option NFQWS_OPT '/,\$d" "$CONF"
	{ echo "	option NFQWS_OPT '"; echo "$block"; echo "'"; } >> "$CONF"
	if ! grep -q "option NFQWS_PORTS_UDP.*19294-19344,50000-50100" "$CONF"; then
		sed -i "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/'\$/,19294-19344,50000-50100'/" "$CONF"
	fi
	if ! grep -q "option NFQWS_PORTS_TCP.*2053,2083,2087,2096,8443" "$CONF"; then
		sed -i "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/'\$/,2053,2083,2087,2096,8443'/" "$CONF"
	fi
	_add_gp_domains
	_refresh_exclude_file
	sed -i '/--new/{N;/--filter-tcp=2802/{s/--new/#Gv0\n--new/;};}' "$CONF"
	if printf '%s\n' "$block" | grep -qxF -e "--filter-udp=$PORTS_UDP" -e "--filter-tcp=$PORTS_TCP"; then
		_add_ports_if_missing NFQWS_PORTS_UDP "$PORTS_UDP"
		_add_ports_if_missing NFQWS_PORTS_TCP "$PORTS_TCP"
	fi
	[ -n "$q" ] && _udp443_add
	zapret_restart
	printf '{"ok":true,"strategy":"%s","ts_warning":%s}\n' "$(esc "$name")" "$(_ts_warning)"
}


_yv_file() { echo "$JOBS_DIR/youtube_strategies.txt"; }

do_yv_download() {
	_ensure_deps
	local out; out="$(_yv_file)"
	echo "==> Скачиваем список стратегий для YouTube"
	curl -fsSL --connect-timeout 8 --max-time 15 "$STR_URL" -o "$out" || { echo "ОШИБКА скачивания"; return 1; }
	echo "==> Готово, стратегий: $(grep -c '^#Yv' "$out")"
}

strategy_list_youtube() {
	local f; f="$(_yv_file)"
	if [ ! -s "$f" ] || [ "$1" = refresh ]; then
		job_start youtube_download do_yv_download
		return
	fi
	printf '{"items":[%s]}\n' "$(
		grep -oE '^#Yv[0-9]+' "$f" | sed 's/^#//' | awk '{
			printf "%s{\"id\":\"%s\"}", (NR>1?",":""), $0
		}'
	)"
}

_yv_block_remove() { _nfq_drop_profiles "$YV_RX" "" '^--filter-udp=443$'; }

strategy_set_youtube() {
	local name="$1" f selected
	if [ "$name" = off ]; then
		[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
		_yv_block_remove
		case $? in
			0) mkdir -p "$(dirname "$YV_OFF_FLAG")"; touch "$YV_OFF_FLAG"; zapret_restart; printf '{"ok":true,"strategy":"off","removed":true}\n' ;;
			3) mkdir -p "$(dirname "$YV_OFF_FLAG")"; touch "$YV_OFF_FLAG"; printf '{"ok":true,"strategy":"off","removed":false}\n' ;;
			*) echo '{"error":"блок стратегий Zapret (NFQWS_OPT) записан не так, как его пишет панель, — YouTube-часть не тронута"}'; return 1 ;;
		esac
		return 0
	fi
	f="$(_yv_file)"
	[ -s "$f" ] || { echo '{"error":"список не загружен — сначала обновите"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	selected="#$name"
	grep -qxF "$selected" "$f" || { echo '{"error":"стратегия не найдена"}'; return 1; }
	rm -f "$YV_OFF_FLAG"

	local saved="$JOBS_DIR/yv_saved" newtmp="$JOBS_DIR/yv_new" finaltmp="$JOBS_DIR/yv_final" oldtmp="$JOBS_DIR/yv_old"
	local awk_strip="$JOBS_DIR/yv_strip.awk" awk_insert="$JOBS_DIR/yv_insert.awk" awk_dedup="$JOBS_DIR/yv_dedup.awk"
	local flag=0
	: > "$saved"
	while IFS= read -r line; do
		[ "$line" = "$selected" ] && flag=1 && continue
		case "$line" in \#Yv[0-9]*) flag=0 ;; esac
		[ "$flag" -eq 1 ] && printf '%s\n' "$line" >> "$saved"
	done < "$f"

	local awk_cut="$JOBS_DIR/yv_cut.awk"
	cat > "$awk_cut" << 'AWK_CUT_EOF'
/^[ \t]*option NFQWS_OPT '$/ { flag = 1 }
flag { print }
AWK_CUT_EOF
	awk -f "$awk_cut" "$CONF" > "$oldtmp"
	rm -f "$awk_cut"
	sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"
	sed -i "/^[[:space:]]*#Yv[0-9]\+/d" "$oldtmp"

	cat > "$awk_strip" << 'AWK_STRIP_EOF'
{
	if (skip) {
		if ($0 == "--new" || $0 ~ /^[ \t]*'$/) { skip = 0; next }
		if ($0 ~ /^[ \t]*$/) next
		next
	}
	if ($0 == "--filter-tcp=443") {
		getline n
		if (n == "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt") { skip = 1; next }
		else { print $0; print n; next }
	}
	if ($0 == "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt") has_google = 1
	if ($0 ~ /^[ \t]*#Yv/) next
	print
}
AWK_STRIP_EOF
	awk -f "$awk_strip" "$oldtmp" > "$newtmp"

	cat > "$awk_insert" << 'AWK_INSERT_EOF'
BEGIN { inserted = 0; has_google = 0 }
$0 == "--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt" { has_google = 1 }
$0 == "--new" && !inserted {
	while ((getline l < savedfile) > 0) if (l !~ /^[ \t]*$/) print l
	print "--new"
	inserted = 1
	next
}
$0 ~ /^[ \t]*option NFQWS_OPT '$/ && !has_google && !inserted {
	print
	print sel
	while ((getline l < savedfile) > 0) if (l !~ /^[ \t]*$/) print l
	print "--new"
	inserted = 1
	next
}
{ print }
AWK_INSERT_EOF
	awk -v sel="$selected" -v savedfile="$saved" -f "$awk_insert" "$newtmp" > "$finaltmp"

	cat "$finaltmp" >> "$CONF"

	cat > "$awk_dedup" << 'AWK_DEDUP_EOF'
{
	if ($0 == "--new") { if (prev != "--new") print }
	else print
	prev = $0
}
AWK_DEDUP_EOF
	awk -f "$awk_dedup" "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
	grep -qE "^[ \t]*'[ \t]*\$" "$CONF" || echo "'" >> "$CONF"
	_nfq_normalize

	_add_gp_domains
	zapret_restart
	rm -f "$saved" "$newtmp" "$finaltmp" "$oldtmp" "$awk_strip" "$awk_insert" "$awk_dedup"

	printf '{"ok":true,"strategy":"%s","ts_warning":%s}\n' "$(esc "$name")" "$(_ts_warning)"
}


Dv1()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=652" "--dpi-desync-split-pos=2" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"; }
Dv2()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=ts" "--dpi-desync-repeats=8" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com"; }
Dv3()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fooling=ts" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fake-tls-mod=none"; }
Dv4()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=652" "--dpi-desync-split-pos=2" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"; }
Dv5()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake,multisplit" "--dpi-desync-repeats=6" "--dpi-desync-fooling=badseq" "--dpi-desync-badseq-increment=1000" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"; }
Dv6()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"; }
Dv7()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=multisplit" "--dpi-desync-split-pos=2,sniext+1" "--dpi-desync-split-seqovl=679" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"; }
Dv8()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake" "--dpi-desync-fake-tls-mod=none" "--dpi-desync-repeats=6" "--dpi-desync-fooling=badseq" "--dpi-desync-badseq-increment=2"; }
Dv9()  { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake,fakedsplit" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=badseq" "--dpi-desync-badseq-increment=2" "--dpi-desync-repeats=8" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com"; }
Dv10() { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=badseq" "--dpi-desync-badseq-increment=10000000" "--dpi-desync-repeats=8" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com"; }
Dv11() { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake,multisplit" "--dpi-desync-split-seqovl=681" "--dpi-desync-split-pos=1" "--dpi-desync-fooling=ts" "--dpi-desync-repeats=8" "--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com"; }
Dv12() { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fooling=badseq" "--dpi-desync-badseq-increment=2" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"; }
Dv13() { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake" "--dpi-desync-repeats=6" "--dpi-desync-fooling=ts" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"; }
Dv14() { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake,fakedsplit" "--dpi-desync-repeats=6" "--dpi-desync-fooling=ts" "--dpi-desync-fakedsplit-pattern=0x00" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"; }
Dv15() { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake,multidisorder" "--dpi-desync-split-pos=1,midsld" "--dpi-desync-repeats=11" "--dpi-desync-fooling=badseq" "--dpi-desync-fake-tls=0x00000000" "--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com"; }
Dv16() { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=fake,hostfakesplit" "--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com" "--dpi-desync-hostfakesplit-mod=host=www.google.com,altorder=1" "--dpi-desync-fooling=ts"; }
Dv17() { printf '%s\n' "--filter-tcp=2053,2083,2087,2096,8443" "--hostlist-domains=discord.media" "--dpi-desync=hostfakesplit" "--dpi-desync-repeats=4" "--dpi-desync-fooling=ts" "--dpi-desync-hostfakesplit-mod=host=www.google.com"; }

_discord_active() {
	[ -f "$CONF" ] || return 1
	grep -qx -- '--filter-l7=discord,stun' "$CONF" || grep -qE '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443$' "$CONF"
}

discord_status() {
	local dv="" fake="" active=false
	if [ -f "$CONF" ]; then
		dv=$(grep -oE '^#[[:space:]]*Dv[0-9]+' "$CONF" | head -n1 | sed 's/^#[[:space:]]*//')
		fake=$(grep -m1 -- '--dpi-desync-fake-discord=' "$CONF" | sed 's|.*fake/||')
		_discord_active && active=true
	fi
	printf '{"current":"%s","current_fake":"%s","active":%s,"available":["Dv1","Dv2","Dv3","Dv4","Dv5","Dv6","Dv7","Dv8","Dv9","Dv10","Dv11","Dv12","Dv13","Dv14","Dv15","Dv16","Dv17"]}\n' "$(esc "$dv")" "$(esc "$fake")" "$active"
}

discord_off() {
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	_nfq_drop_profiles "$DISCORD_RX"
	case $? in
		0)
			sed -i -e "/^[[:space:]]*option NFQWS_PORTS_UDP '/s/,19294-19344,50000-50100//" \
				-e "/^[[:space:]]*option NFQWS_PORTS_TCP '/s/,2053,2083,2087,2096,8443//" "$CONF"
			mkdir -p "$(dirname "$DV_OFF_FLAG")"; touch "$DV_OFF_FLAG"
			zapret_restart
			printf '{"ok":true,"dv":"off","removed":true}\n' ;;
		3)
			mkdir -p "$(dirname "$DV_OFF_FLAG")"; touch "$DV_OFF_FLAG"
			printf '{"ok":true,"dv":"off","removed":false}\n' ;;
		*) echo '{"error":"блок стратегий Zapret (NFQWS_OPT) записан не так, как его пишет панель, — Discord-часть не тронута"}'; return 1 ;;
	esac
}

discord_set_dv() {
	local num="$1" strat
	[ "$num" = off ] && { discord_off; return; }
	echo "$num" | grep -qE '^(1[0-7]|[1-9])$' || { echo '{"error":"некорректный номер Dv"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	strat="$(Dv"$num")"
	if ! grep -qx -- '--filter-l7=discord,stun' "$CONF" || ! grep -q -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF"; then
		_nfq_drop_profiles "$DISCORD_RX"
		case $? in 0|3) ;; *) echo '{"error":"блок стратегий Zapret (NFQWS_OPT) записан не так, как его пишет панель, — Discord-часть не добавлена"}'; return 1 ;; esac
		rm -f "$DV_OFF_FLAG"
		_discord_str_add
		grep -q -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" || {
			echo '{"error":"не удалось добавить блок Discord — сначала выберите основную стратегию"}'; return 1; }
	fi
	rm -f "$DV_OFF_FLAG"
	local start end line
	start=$(grep -n -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" | head -n1 | cut -d: -f1)
	end=$(tail -n +"$start" "$CONF" | grep -n -m1 -E '^--new$|^#|^'"'"'$' | cut -d: -f1)
	end=$((start + end - 1))
	sed -i "${start},$((end - 1))d" "$CONF"
	line=$start
	echo "$strat" | while IFS= read -r l; do sed -i "${line}i$l" "$CONF"; line=$((line + 1)); done
	if grep -q -E '^#[[:space:]]*Dv' "$CONF"; then
		sed -i "s/^#[[:space:]]*Dv[0-9]\+/#Dv$num/" "$CONF"
	else
		sed -i "${start}i#Dv$num" "$CONF"
	fi
	zapret_restart
	printf '{"ok":true,"dv":"Dv%s"}\n' "$num"
}

discord_set_fake() {
	local file="$1"
	case "$file" in
		stun.bin|stun2.bin|quic_initial_4pda_to.bin|quic_initial_tencent_com.bin|tls_clienthello_sochi_park.bin|quic_initial_www_google_com.bin|quic_initial_steamcommunity_com.bin|quic_initial_5ka_ru.bin|quic_initial_rutube_ru.bin) ;;
		*) echo '{"error":"неизвестный fake-файл"}'; return 1 ;;
	esac
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	grep -q -- "--filter-l7=discord,stun" "$CONF" || { echo '{"error":"стратегия Discord выключена — сначала выберите Dv"}'; return 1; }
	awk -v new="$file" '{
		if ($0 == "--filter-l7=discord,stun") { print; getline; print;
			if ($0 == "--dpi-desync=fake") { getline a; getline b;
				if (a ~ /^--dpi-desync-fake-discord=/) {
					print "--dpi-desync-fake-discord=/opt/zapret/files/fake/" new
					print "--dpi-desync-fake-stun=/opt/zapret/files/fake/" new
				} else { print a; print b }
			}
			next
		}
		print
	}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
	zapret_restart
	printf '{"ok":true,"fake":"%s"}\n' "$(esc "$file")"
}


_hosts_block() {
	case "$1" in
		nalog) printf '%s\n' \
			"#Nalog" \
			"213.24.64.175 lkfl2.nalog.ru" \
			"213.24.64.181 lknpd.nalog.ru" ;;
		ntc) printf '%s\n' \
			"#ntc.party" \
			"130.255.77.28 ntc.party" ;;
		instagram) printf '%s\n' \
			"#Instagram&Facebook" \
			"57.144.222.34 instagram.com www.instagram.com" \
			"157.240.9.174 instagram.com www.instagram.com" \
			"157.240.245.174 instagram.com www.instagram.com b.i.instagram.com z-p42-chat-e2ee-ig.facebook.com help.instagram.com" \
			"157.240.205.174 instagram.com www.instagram.com" \
			"57.144.244.192 static.cdninstagram.com graph.instagram.com i.instagram.com api.instagram.com edge-chat.instagram.com" \
			"31.13.66.63 scontent.cdninstagram.com scontent-hel3-1.cdninstagram.com" \
			"57.144.244.1 facebook.com www.facebook.com fb.com fbsbx.com" \
			"57.144.244.128 static.xx.fbcdn.net scontent.xx.fbcdn.net" \
			"31.13.67.20 scontent-hel3-1.xx.fbcdn.net" ;;
		librusec) printf '%s\n' \
			"#lib.rus.ec" \
			"185.39.18.98 lib.rus.ec www.lib.rus.ec" ;;
		ai) printf '%s\n' \
			"#Gemini" \
			"45.155.204.190 gemini.google.com" \
			"#Grok" \
			"45.155.204.190 grok.com accounts.x.ai assets.grok.com" \
			"#OpenAI" \
			"45.155.204.190 chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com" \
			"45.155.204.190 tcr9i.chat.openai.com webrtc.chatgpt.com android.chat.openai.com api.openai.com operator.chatgpt.com" \
			"45.155.204.190 sora.chatgpt.com sora.com videos.openai.com ios.chat.openai.com cdn.auth0.com files.oaiusercontent.com" \
			"#Microsoft" \
			"45.155.204.190 copilot.microsoft.com sydney.bing.com edgeservices.bing.com rewards.bing.com" \
			"45.155.204.190 xsts.auth.xboxlive.com xgpuwebf2p.gssv-play-prod.xboxlive.com xgpuweb.gssv-play-prod.xboxlive.com" \
			"#ElevenLabs" \
			"45.155.204.190 elevenlabs.io api.us.elevenlabs.io elevenreader.io api.elevenlabs.io help.elevenlabs.io" \
			"#DeepL" \
			"45.155.204.190 deepl.com www.deepl.com www2.deepl.com login-wall.deepl.com w.deepl.com dict.deepl.com ita-free.www.deepl.com" \
			"45.155.204.190 write-free.www.deepl.com experimentation.deepl.com experimentation-grpc.deepl.com ita-free.app.deepl.com" \
			"45.155.204.190 ott.deepl.com api-free.deepl.com backend.deepl.com clearance.deepl.com errortracking.deepl.com" \
			"45.155.204.190 oneshot-free.www.deepl.com checkout.www.deepl.com gtm.deepl.com auth.deepl.com shield.deepl.com" \
			"#Claude" \
			"45.155.204.190 claude.ai console.anthropic.com api.anthropic.com" \
			"#Trae.ai" \
			"45.155.204.190 trae-api-sg.mchost.guru api.trae.ai api-sg-central.trae.ai api16-normal-alisg.mchost.guru" \
			"#Windsurf" \
			"45.155.204.190 windsurf.com codeium.com server.codeium.com web-backend.codeium.com marketplace.windsurf.com" \
			"45.155.204.190 unleash.codeium.com inference.codeium.com windsurf-stable.codeium.com" \
			"144.31.14.104 windsurf-telemetry.codeium.com" \
			"#Manus" \
			"45.155.204.190 manus.im api.manus.im" \
			"#Notion" \
			"45.155.204.190 www.notion.so calendar.notion.so" \
			"#AIStudio" \
			"45.155.204.190 aistudio.google.com generativelanguage.googleapis.com aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com xsts.auth.xboxlive.com" \
			"45.155.204.190 webchannel-alkalimakersuite-pa.clients6.google.com alkalimakersuite-pa.clients6.google.com assistant-s3-pa.googleapis.com" \
			"45.155.204.190 proactivebackend-pa.googleapis.com robinfrontend-pa.googleapis.com o.pki.goog labs.google labs.google.com notebooklm.google" \
			"45.155.204.190 notebooklm.google.com jules.google.com stitch.withgoogle.com gemini.google.com copilot.microsoft.com edgeservices.bing.com" \
			"45.155.204.190 rewards.bing.com sydney.bing.com xboxdesignlab.xbox.com xgpuweb.gssv-play-prod.xboxlive.com xgpuwebf2p.gssv-play-prod.xboxlive.com" ;;
		twitch) printf '%s\n' \
			"#Twitch" \
			"45.155.204.190 usher.ttvnw.net gql.twitch.tv" ;;
		telegram) printf '%s\n' \
			"#TelegramWeb" \
			"149.154.167.220 core.telegram.org api.telegram.org flora.web.telegram.org kws1-1.web.telegram.org kws1.web.telegram.org kws2-1.web.telegram.org kws2.web.telegram.org kws4-1.web.telegram.org" \
			"149.154.167.220 kws4.web.telegram.org kws5-1.web.telegram.org kws5.web.telegram.org pluto-1.web.telegram.org pluto.web.telegram.org td.telegram.org telegram.dog" \
			"149.154.167.220 telegram.me telegram.org telegram.space telesco.pe venus.web.telegram.org web.telegram.org zws1-1.web.telegram.org zws1.web.telegram.org" \
			"149.154.167.220 tg.dev t.me zws2-1.web.telegram.org zws2.web.telegram.org zws4-1.web.telegram.org zws5-1.web.telegram.org zws5.web.telegram.org" ;;
		spotify) printf '%s\n' \
			"#Spotify" \
			"45.155.204.190 api.spotify.com login5.spotify.com encore.scdn.co gew1-spclient.spotify.com spclient.wg.spotify.com" \
			"45.155.204.190 api-partner.spotify.com aet.spotify.com www.spotify.com accounts.spotify.com open.spotify.com" \
			"45.155.204.190 accounts.scdn.co gew1-dealer.spotify.com open-exp.spotifycdn.com www-growth.scdn.co" ;;
		rutor) printf '%s\n' \
			"#rutor" \
			"172.66.159.63 rutor.info d.rutor.info" ;;
		scell) printf '%s\n' \
			"#Supercell" \
			"103.27.157.38 accounts.supercell.com cdn.id.supercell.com clashofclans.inbox.supercell.com game-assets.brawlstarsgame.com" \
			"103.27.157.38 game-assets.clashofclans.com game-assets.clashroyaleapp.com security.id.supercell.com store.supercell.com" \
			"31.25.239.132 accounts.supercell.com cdn.id.supercell.com clashofclans.inbox.supercell.com game-assets.brawlstarsgame.com" \
			"31.25.239.132 game-assets.clashofclans.com game-assets.clashroyaleapp.com game.boombeachgame.com game.mocogame.com security.id.supercell.com store.supercell.com" \
			"185.246.223.127 game.brawlstarsgame.com" \
			"62.133.62.97 game.clashroyaleapp.com" \
			"193.23.209.189 gamea.clashofclans.com" \
			"108.61.167.26 game.squadbustersgame.com" ;;
		githubraw) printf '%s\n' \
			"#githubusercontent.com" \
			"146.75.22.132 objects.githubusercontent.com release-assets.githubusercontent.com raw.githubusercontent.com private-user-images.githubusercontent.com gist.githubusercontent.com" \
			"146.75.22.132 camo.githubusercontent.com avatars.githubusercontent.com avatars0.githubusercontent.com avatars1.githubusercontent.com avatars2.githubusercontent.com avatars3.githubusercontent.com avatars4.githubusercontent.com avatars5.githubusercontent.com" ;;
		github) printf '%s\n' \
			"#github.com" \
			"140.82.114.3 github.com" \
			"185.199.110.154 github.githubassets.com" \
			"185.199.110.133 camo.githubassets.com" ;;
		tapeop) printf '%s\n' \
			"#tapeop.dev" \
			"216.24.57.251 www.tapeop.dev tapeop.dev" \
			"216.24.57.3 www.tapeop.dev tapeop.dev" ;;
		*) return 1 ;;
	esac
}

_hosts_block_status() {
	local block="$1" content
	content="$(_hosts_block "$block")" || return 1
	[ -f "$HOSTS_FILE" ] || { echo false; return; }
	printf '%s\n' "$content" | awk -v hf="$HOSTS_FILE" 'function n(s) { gsub(/\r/, "", s); gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
		BEGIN { while ((getline l < hf) > 0) have[n(l)] = 1; close(hf) }
		{ k = n($0); if (k == "" || (k in seen)) next; seen[k] = 1; total++; if (k in have) found++ }
		END { print (total > 0 && found == total) ? "true" : "false" }'
}
_hosts_drop_lines() {
	local tmp="$HOSTS_FILE.zmtmp" list="$HOSTS_FILE.zmdrop"
	cat > "$list"
	awk -v list="$list" 'function n(s) { gsub(/\r/, "", s); gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
		BEGIN { while ((getline l < list) > 0) { k = n(l); if (k != "") drop[k] = 1 } close(list) }
		!(n($0) in drop)' "$HOSTS_FILE" > "$tmp" && cat "$tmp" > "$HOSTS_FILE"
	rm -f "$tmp" "$list"
}
_hosts_has_line() {
	awk -v want="$1" 'function n(s) { gsub(/\r/, "", s); gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
		BEGIN { want = n(want) } n($0) == want { f = 1; exit } END { exit !f }' "$HOSTS_FILE" 2>/dev/null
}

hosts_status() {
	local blocks="nalog ntc instagram librusec ai twitch telegram spotify rutor scell githubraw github tapeop" b first=1
	local geohide=""
	if grep -q '^### geohide.ru: hosts file' "$HOSTS_FILE" 2>/dev/null; then
		if grep -q '^# Регион серверов: US$' "$HOSTS_FILE" 2>/dev/null; then geohide="us"
		elif grep -q '^# Регион серверов: EU$' "$HOSTS_FILE" 2>/dev/null; then geohide="eu"
		elif grep -q '^# Регион серверов: RU$' "$HOSTS_FILE" 2>/dev/null; then geohide="ru"
		else geohide="unknown"; fi
	fi
	printf '{"geohide":"%s","items":[' "$(esc "$geohide")"
	for b in $blocks; do
		[ "$first" -eq 1 ] || printf ','
		first=0
		printf '{"id":"%s","enabled":%s}' "$b" "$(_hosts_block_status "$b")"
	done
	printf ']}\n'
}

hosts_toggle() {
	local block="$1" content line enabled
	content="$(_hosts_block "$block")" || { echo '{"error":"неизвестный блок"}'; return 1; }
	enabled="$(_hosts_block_status "$block")"
	if [ "$enabled" = "true" ]; then
		printf '%s\n' "$content" | _hosts_drop_lines
	else
		while IFS= read -r line; do [ -z "$line" ] && continue; _hosts_has_line "$line" || echo "$line" >> "$HOSTS_FILE"; done <<-EOF
		$content
		EOF
	fi
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	printf '{"ok":true,"block":"%s","enabled":%s}\n' "$(esc "$block")" "$([ "$enabled" = "true" ] && echo false || echo true)"
}

hosts_replace_geohide() {
	local region="$1" url tmp
	case "$region" in
		ru) url="${GH_RAW}/Internet-Helper/GeoHideDNS/refs/heads/main/hosts/hosts" ;;
		eu) url="${GH_RAW}/Internet-Helper/GeoHideDNS/refs/heads/main/hosts/eu/hosts" ;;
		us) url="${GH_RAW}/Internet-Helper/GeoHideDNS/refs/heads/main/hosts/us/hosts" ;;
		*) echo '{"error":"неизвестный регион"}'; return 1 ;;
	esac
	tmp="$JOBS_DIR/geohide_hosts.tmp"
	wget -q --timeout=20 -U "Mozilla/5.0" -O "$tmp" "$url" >/dev/null 2>&1
	if [ ! -s "$tmp" ]; then
		rm -f "$tmp"
		echo '{"error":"не удалось скачать GeoHide hosts"}'
		return 1
	fi
	mv "$tmp" "$HOSTS_FILE"
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	printf '{"ok":true,"region":"%s"}\n' "$region"
}

hosts_reset() {
	printf '%s\n' "127.0.0.1	localhost" "" "::1	localhost ip6-localhost ip6-loopback" "ff02::1 ip6-allnodes" "ff02::2 ip6-allrouters" > "$HOSTS_FILE"
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	printf '{"ok":true}\n'
}

hosts_file_get() {
	[ -f "$HOSTS_FILE" ] || { echo '{"error":"файл hosts не найден"}'; return 1; }
	printf '{"content":"%s"}\n' "$(esc_ml "$(cat "$HOSTS_FILE")")"
}

hosts_file_set() {
	local content="$1"
	[ -n "$content" ] || { echo '{"error":"пустой файл — сохранение отменено"}'; return 1; }
	cp "$HOSTS_FILE" "$HOSTS_FILE.bak" 2>/dev/null
	printf '%s' "$content" > "$HOSTS_FILE"
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	printf '{"ok":true}\n'
}


_ports_get() { sed -n "s/^[[:space:]]*option $1 '\([^']*\)'.*/\1/p" "$CONF" | head -n1; }
_ports_put() { sed -i "s|^\([[:space:]]*option $1 '\)[^']*'|\1$2'|" "$CONF"; }
_remove_ports_if_present() {
	local option="$1" ports="$2" cur out="" p
	grep -q "^[[:space:]]*option $option '" "$CONF" || return 0
	cur="$(_ports_get "$option")"
	for p in $(echo "$cur" | tr ',' ' '); do
		case ",$ports," in *",$p,"*) continue ;; esac
		out="$out${out:+,}$p"
	done
	[ "$out" = "$cur" ] || _ports_put "$option" "$out"
}

_add_ports_if_missing() {
	local option="$1" ports="$2" cur p
	grep -q "^[[:space:]]*option $option '" "$CONF" || return 0
	cur="$(_ports_get "$option")"
	for p in $(echo "$ports" | tr ',' ' '); do
		case ",$cur," in *",$p,"*) ;; *) cur="$cur${cur:+,}$p" ;; esac
	done
	_ports_put "$option" "$cur"
}

strategy_TCP_common() {
	printf '%s\n' "--new" "--filter-tcp=$PORTS_TCP" "--dpi-desync-any-protocol=1" "--dpi-desync-cutoff=n5" \
		"--dpi-desync=multisplit" "--dpi-desync-split-seqovl=582" "--dpi-desync-split-pos=1" \
		"--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/stun.bin"
}

strategy_Gv1() {
	printf '%s\n' "#Gv1" "--new" "--filter-udp=$PORTS_UDP" "--dpi-desync=fake" "--dpi-desync-cutoff=d2" \
		"--dpi-desync-any-protocol=1" "--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/stun.bin"
}

strategy_Gv() {
	local n="$1"
	printf '%s\n' "#Gv$n" "--new" "--filter-udp=$PORTS_UDP" "--dpi-desync=fake" "--dpi-desync-repeats=10" \
		"--dpi-desync-any-protocol=1" "--dpi-desync-fake-unknown-udp=/opt/zapret/files/fake/stun.bin" "--dpi-desync-cutoff=n$n"
}

_game_rx() {
	printf '%s' "^#Gv[0-9]+(Xtreme)?\$|^--filter-(udp|tcp)=($PORTS_UDP|$PORTS_TCP|80,88,444-65535)\$"
}

_game_active() {
	[ -f "$CONF" ] || return 1
	sed -n "/^[[:space:]]*option NFQWS_OPT '\$/,\$p" "$CONF" | grep -qE "$(_game_rx)"
}

_game_xtreme_undo_opts() {
	local xfile="/opt/zapret/tmp/GvXtreme" old_tcp_opt old_udp_opt
	grep -q "^#Gv[0-9]\+Xtreme\$" "$CONF" || { rm -f "$xfile"; return 0; }
	if [ -f "$xfile" ]; then
		old_tcp_opt=$(sed -n '4p' "$xfile")
		old_udp_opt=$(sed -n '5p' "$xfile")
		[ -n "$old_tcp_opt" ] && sed -i "s|^[[:space:]]*option NFQWS_PORTS_TCP .*|$old_tcp_opt|" "$CONF"
		[ -n "$old_udp_opt" ] && sed -i "s|^[[:space:]]*option NFQWS_PORTS_UDP .*|$old_udp_opt|" "$CONF"
	fi
	rm -f "$xfile"
}

game_status() {
	local current="" xtreme="false" fake="" active="false"
	if [ -f "$CONF" ]; then
		current=$(grep -oE '^#Gv[1-4](Xtreme)?$' "$CONF" | head -n1 | sed 's/^#//; s/Xtreme$//')
		grep -q "^#Gv[0-9]\+Xtreme\$" "$CONF" && xtreme="true"
		fake=$(grep -m1 -- '--dpi-desync-fake-unknown-udp=' "$CONF" | sed 's|.*fake/||')
		_game_active && active="true"
	fi
	printf '{"current":"%s","xtreme":%s,"fake":"%s","active":%s}\n' "$(esc "$current")" "$xtreme" "$(esc "$fake")" "$active"
}

game_set() {
	local choice="$1" current="" rc
	echo "$choice" | grep -qE '^([1-4]|off)$' || { echo '{"error":"некорректный номер Gv"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	current=$(grep -oE '^#Gv[1-4](Xtreme)?$' "$CONF" | head -n1 | sed 's/^#//; s/Xtreme$//')

	if [ "$choice" = off ]; then
		_game_active || { printf '{"ok":true,"game":"none","removed":false}\n'; return 0; }
		cp "$CONF" "$CONF.gvbak"
		_game_xtreme_undo_opts
		_nfq_drop_profiles "$(_game_rx)"
		rc=$?
		case $rc in
			0|3)
				rm -f "$CONF.gvbak"
				_remove_ports_if_present NFQWS_PORTS_UDP "$PORTS_UDP"
				_remove_ports_if_present NFQWS_PORTS_TCP "$PORTS_TCP"
				zapret_restart
				printf '{"ok":true,"game":"none","removed":true}\n' ;;
			*)
				mv -f "$CONF.gvbak" "$CONF"
				echo '{"error":"блок стратегий Zapret (NFQWS_OPT) записан не так, как его пишет панель, — игровая часть не тронута"}'; return 1 ;;
		esac
		return 0
	fi

	[ "$current" = "Gv$choice" ] && { printf '{"ok":true,"game":"Gv%s"}\n' "$choice"; return 0; }

	cp "$CONF" "$CONF.gvbak"
	_game_xtreme_undo_opts
	_nfq_drop_profiles "$(_game_rx)"
	case $? in
		0|3) rm -f "$CONF.gvbak" ;;
		*) mv -f "$CONF.gvbak" "$CONF"
			echo '{"error":"блок стратегий Zapret (NFQWS_OPT) записан не так, как его пишет панель, — игровая часть не тронута"}'; return 1 ;;
	esac

	local last_quote strat
	last_quote=$(grep -n "^[[:space:]]*'[[:space:]]*\$" "$CONF" | tail -n1 | cut -d: -f1)
	[ -n "$last_quote" ] && sed -i "${last_quote},\$d" "$CONF"
	if [ "$choice" = "1" ]; then strat="$(strategy_Gv1; strategy_TCP_common)"; else strat="$(strategy_Gv "$choice"; strategy_TCP_common)"; fi
	echo "$strat" | sed '/^$/d' >> "$CONF"
	echo "'" >> "$CONF"
	_add_ports_if_missing NFQWS_PORTS_UDP "$PORTS_UDP"
	_add_ports_if_missing NFQWS_PORTS_TCP "$PORTS_TCP"
	zapret_restart
	printf '{"ok":true,"game":"Gv%s"}\n' "$choice"
}

game_set_fake() {
	local file="$1"
	case "$file" in
		stun.bin|stun2.bin|quic_initial_4pda_to.bin|quic_initial_tencent_com.bin|tls_clienthello_sochi_park.bin|quic_initial_www_google_com.bin|quic_initial_steamcommunity_com.bin|quic_initial_5ka_ru.bin|quic_initial_rutube_ru.bin) ;;
		*) echo '{"error":"неизвестный fake-файл"}'; return 1 ;;
	esac
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	grep -q -- '--dpi-desync-fake-unknown-udp=' "$CONF" || { echo '{"error":"игровая стратегия не установлена"}'; return 1; }
	awk -v new="$file" 'BEGIN{done=0} !done && /--dpi-desync-fake-unknown-udp=/{sub(/\/opt\/zapret\/files\/fake\/[^ ]+/, "/opt/zapret/files/fake/" new); done=1} {print}' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
	zapret_restart
	printf '{"ok":true,"fake":"%s"}\n' "$(esc "$file")"
}

game_toggle_xtreme() {
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	local xfile="/opt/zapret/tmp/GvXtreme"
	local xports="80,88,444-65535"
	local xnfqws="80,88,443-65535"
	mkdir -p "$(dirname "$xfile")"

	if grep -q "^#Gv[0-9]\+Xtreme\$" "$CONF"; then
		[ -f "$xfile" ] || { echo '{"error":"файл восстановления отсутствует"}'; return 1; }
		local old_gv old_udp old_tcp old_tcp_opt old_udp_opt
		old_gv=$(sed -n '1p' "$xfile")
		old_udp=$(sed -n '2p' "$xfile")
		old_tcp=$(sed -n '3p' "$xfile")
		old_tcp_opt=$(sed -n '4p' "$xfile")
		old_udp_opt=$(sed -n '5p' "$xfile")
		awk -v gv="$old_gv" -v udp="$old_udp" -v tcp="$old_tcp" '
			/^#Gv[0-9]+Xtreme$/ { print gv; restore = 1; next }
			restore && /^--filter-udp=/ { print udp; next }
			restore && /^--filter-tcp=/ { print tcp; restore = 0; next }
			{ print }
		' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
		[ -n "$old_tcp_opt" ] && sed -i "s|^[[:space:]]*option NFQWS_PORTS_TCP .*|$old_tcp_opt|" "$CONF"
		[ -n "$old_udp_opt" ] && sed -i "s|^[[:space:]]*option NFQWS_PORTS_UDP .*|$old_udp_opt|" "$CONF"
		rm -f "$xfile"
		zapret_restart
		printf '{"ok":true,"xtreme":false}\n'
		return
	fi

	grep -q "^#Gv[0-9]\+\$" "$CONF" || { echo '{"error":"игровая стратегия не установлена"}'; return 1; }
	awk '
		/^#Gv[0-9]+$/ { gv = $0; found = 1; next }
		found && /^--filter-udp=/ { udp = $0 }
		found && /^--filter-tcp=/ { tcp = $0 }
		/^[ \t]*option NFQWS_PORTS_TCP / { tcp_option = $0 }
		/^[ \t]*option NFQWS_PORTS_UDP / { udp_option = $0 }
		END { print gv; print udp; print tcp; print tcp_option; print udp_option }
	' "$CONF" > "$xfile"
	sed -i -e "s|^[[:space:]]*option NFQWS_PORTS_TCP .*|	option NFQWS_PORTS_TCP '$xnfqws'|" \
		-e "s|^[[:space:]]*option NFQWS_PORTS_UDP .*|	option NFQWS_PORTS_UDP '$xnfqws'|" "$CONF"
	sed -i "s/^#\(Gv[0-9]\+\)\$/#\1Xtreme/" "$CONF"
	awk -v ports="$xports" '
		/^#Gv[0-9]+Xtreme$/ { gv = 1; print; next }
		gv && /^--filter-udp=/ { print "--filter-udp=" ports; next }
		gv && /^--filter-tcp=/ { print "--filter-tcp=" ports; gv = 0; next }
		{ print }
	' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
	zapret_restart
	printf '{"ok":true,"xtreme":true}\n'
}


_quic_blocked() {
	uci show firewall 2>/dev/null | grep -q "name='Block_UDP_80'" \
		&& uci show firewall 2>/dev/null | grep -q "name='Block_UDP_443'" \
		&& echo true || echo false
}

_ipv6_enabled_in_zapret() {
	[ -f "$CONF" ] && grep -q "option DISABLE_IPV6 '0'" "$CONF" && echo true || echo false
}

_flow_offloading_fix_applied() {
	grep -q 'ct original packets ge 30 flow offload @ft;' /usr/share/firewall4/templates/ruleset.uc 2>/dev/null \
		&& echo true || echo false
}

_expert_mode() { [ -f "$EXPERT_MODE_FILE" ] && echo true || echo false; }

system_status() {
	printf '{"quic_blocked":%s,"ipv6_enabled":%s,"flow_offloading_fix":%s,"expert_mode":%s,"pkg":"%s"}\n' \
		"$(_quic_blocked)" "$(_ipv6_enabled_in_zapret)" "$(_flow_offloading_fix_applied)" "$(_expert_mode)" "$PKG"
}

system_check_connectivity() {
	local t4 t6
	t4=$(ping -4 -c1 -W2 google.com 2>/dev/null | grep 'time=' | sed -E 's/.*time=([0-9.]+).*/\1/')
	t6=$(ping -6 -c1 -W2 google.com 2>/dev/null | grep 'time=' | sed -E 's/.*time=([0-9.]+).*/\1/')
	printf '{"ipv4_ok":%s,"ipv4_ms":"%s","ipv6_ok":%s,"ipv6_ms":"%s"}\n' \
		"$([ -n "$t4" ] && echo true || echo false)" "$(esc "$t4")" \
		"$([ -n "$t6" ] && echo true || echo false)" "$(esc "$t6")"
}

system_toggle_quic() {
	if [ "$(_quic_blocked)" = "true" ]; then
		local rule idx
		for rule in Block_UDP_80 Block_UDP_443; do
			while true; do
				idx=$(uci show firewall | grep "name='$rule'" | cut -d. -f2 | cut -d= -f1 | head -n1)
				[ -z "$idx" ] && break
				uci delete firewall.$idx >/dev/null 2>&1
			done
		done
		uci commit firewall >/dev/null 2>&1
		/etc/init.d/firewall restart >/dev/null 2>&1
		printf '{"ok":true,"quic_blocked":false}\n'
		return
	fi
	local lz wz
	lz="$(_zm_lan_zone)"; wz="$(_zm_wan_zone)"
	uci add firewall rule >/dev/null 2>&1
	uci set firewall.@rule[-1].name='Block_UDP_80' >/dev/null 2>&1
	uci add_list firewall.@rule[-1].proto='udp' >/dev/null 2>&1
	uci set "firewall.@rule[-1].src=$lz" >/dev/null 2>&1
	uci set "firewall.@rule[-1].dest=$wz" >/dev/null 2>&1
	uci set firewall.@rule[-1].dest_port='80' >/dev/null 2>&1
	uci set firewall.@rule[-1].target='REJECT' >/dev/null 2>&1
	uci add firewall rule >/dev/null 2>&1
	uci set firewall.@rule[-1].name='Block_UDP_443' >/dev/null 2>&1
	uci add_list firewall.@rule[-1].proto='udp' >/dev/null 2>&1
	uci set "firewall.@rule[-1].src=$lz" >/dev/null 2>&1
	uci set "firewall.@rule[-1].dest=$wz" >/dev/null 2>&1
	uci set firewall.@rule[-1].dest_port='443' >/dev/null 2>&1
	uci set firewall.@rule[-1].target='REJECT' >/dev/null 2>&1
	uci commit firewall >/dev/null 2>&1
	/etc/init.d/firewall restart >/dev/null 2>&1
	printf '{"ok":true,"quic_blocked":true}\n'
}

system_toggle_ipv6() {
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	if grep -q "option DISABLE_IPV6 '0'" "$CONF"; then
		sed -i "s/option DISABLE_IPV6 '0'/option DISABLE_IPV6 '1'/" "$CONF"
		zapret_restart
		printf '{"ok":true,"ipv6_enabled":false}\n'
		return
	fi
	local t6
	t6=$(ping -6 -c1 -W2 google.com 2>/dev/null | grep 'time=')
	if [ -z "$t6" ]; then
		echo '{"error":"IPv6 недоступен на роутере — включение не рекомендуется"}'
		return 1
	fi
	sed -i "s/option DISABLE_IPV6 '1'/option DISABLE_IPV6 '0'/" "$CONF"
	zapret_restart
	printf '{"ok":true,"ipv6_enabled":true}\n'
}

system_toggle_flow_offloading_fix() {
	local template="/usr/share/firewall4/templates/ruleset.uc"
	[ -f "$template" ] || { echo '{"error":"шаблон firewall4 не найден"}'; return 1; }
	if grep -q 'ct original packets ge 30 flow offload @ft;' "$template"; then
		sed -i 's/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/meta l4proto { tcp, udp } flow offload @ft;/' "$template"
		fw4 restart >/dev/null 2>&1
		printf '{"ok":true,"flow_offloading_fix":false}\n'
		return
	fi
	sed -i 's/meta l4proto { tcp, udp } flow offload @ft;/meta l4proto { tcp, udp } ct original packets ge 30 flow offload @ft;/' "$template"
	fw4 restart >/dev/null 2>&1
	printf '{"ok":true,"flow_offloading_fix":true}\n'
}

system_toggle_expert_mode() {
	if [ -f "$EXPERT_MODE_FILE" ]; then
		rm -f "$EXPERT_MODE_FILE"
		printf '{"ok":true,"expert_mode":false}\n'
	else
		echo 1 > "$EXPERT_MODE_FILE"
		printf '{"ok":true,"expert_mode":true}\n'
	fi
}

system_uninstall_panel() {
	local script="/tmp/zm_uninstall_panel.sh"
	cat > "$script" << 'ZM_UNINSTALL_EOF'
sleep 1
/opt/zapret-manager-luci/backend.sh redbtn_panel_gone >/dev/null 2>&1
rm -rf /opt/zapret-manager-luci /usr/libexec/rpcd/zapret-manager \
	/usr/share/luci/menu.d/luci-app-zapret-manager.json \
	/usr/share/rpcd/acl.d/luci-app-zapret-manager.json \
	/www/luci-static/resources/view/zapret-manager \
	/www/luci-static/resources/zapret-manager \
	/www/luci-static/resources/bytetube \
	/www/luci-static/resources/view/bytetube \
	/tmp/zapret-manager-luci /tmp/luci-indexcache* /tmp/luci-modulecache/* \
	/www/zm /www/zm-webui.html /etc/zm-warp-own.conf 2>/dev/null
[ -s /etc/zm-steer/owned ] || rm -rf /usr/share/zm-redbtn
uci -q delete uhttpd.zmweb && uci -q commit uhttpd
/etc/init.d/rpcd restart >/dev/null 2>&1
/etc/init.d/uhttpd restart >/dev/null 2>&1
rm -f "$0"
ZM_UNINSTALL_EOF
	chmod 0755 "$script"
	( sh "$script" >/dev/null 2>&1 & )
	printf '{"ok":true}\n'
}


_confz() {
	if [ "$PKG" = "apk" ]; then echo "/etc/apk/repositories.d/distfeeds.list"
	else echo "/etc/opkg/distfeeds.conf"; fi
}

_mirror_name() {
	local f url
	f="$(_confz)"
	[ -f "$f" ] || { echo "файл не найден"; return; }
	url=$(head -n1 "$f")
	case "$url" in
		*mirror-03.infra.openwrt.org*) echo "Infra OpenWrt" ;;
		*c3sl.ufpr.br*) echo "Brazil" ;;
		*ustc.edu.cn*) echo "China" ;;
		*tetaneutral.net*) echo "France" ;;
		*garr.it*) echo "Italy" ;;
		*marwan.ma*) echo "Morocco" ;;
		*pixeldeck.net*) echo "USA" ;;
		*rwth-aachen.de*) echo "Germany" ;;
		*downloads.openwrt.org*) echo "default / OpenWrt" ;;
		*) echo "неизвестное" ;;
	esac
}

mirror_status() {
	printf '{"current":"%s"}\n' "$(esc "$(_mirror_name)")"
}

do_mirror_set() {
	local host="$1" f
	echo "==> Проверяем доступность $host"
	if ! wget -q --spider --timeout=5 "https://$host/releases/" >/dev/null 2>&1; then
		echo "ОШИБКА: зеркало недоступно"
		return 1
	fi
	f="$(_confz)"
	sed -i "s|https://.*/releases/|https://$host/releases/|g" "$f"
	echo "==> Зеркало доступно, обновляем список пакетов"
	if ! $UPDATE >&2; then
		echo "ОШИБКА обновления пакетов — зеркало сброшено на default"
		sed -i "s|https://.*/releases/|https://downloads.openwrt.org/releases/|g" "$f"
		return 1
	fi
	echo "==> Готово, зеркало переключено и работает"
}

mirror_set() {
	local id="$1" host
	case "$id" in
		infra)        host="mirror-03.infra.openwrt.org" ;;
		brazil)       host="openwrt.c3sl.ufpr.br" ;;
		china)        host="mirrors.ustc.edu.cn/openwrt" ;;
		france)       host="openwrt.tetaneutral.net" ;;
		italy)        host="openwrt.mirror.garr.it/mirrors/openwrt" ;;
		morocco)      host="mirror.marwan.ma/openwrt" ;;
		usa)          host="openwrt.pixeldeck.net" ;;
		germany_rwth) host="ftp.halifax.rwth-aachen.de/openwrt" ;;
		default)      host="downloads.openwrt.org" ;;
		*) echo '{"error":"неизвестное зеркало"}'; return 1 ;;
	esac
	job_start mirror_set do_mirror_set "$host"
}


_excl_dir() { echo "/opt/zapret/init.d/openwrt/custom.d"; }
_excl_file() { echo "$(_excl_dir)/20-script.sh"; }

_excl_current() {
	local f; f="$(_excl_file)"
	[ -f "$f" ] || return 0
	grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$f" | sort -u
}

_excl_enable_custom() {
	[ -f "$CONF" ] || return 0
	if grep -q "^[[:space:]]*option DISABLE_CUSTOM " "$CONF"; then
		sed -i "s/^\([[:space:]]*option DISABLE_CUSTOM \).*/\1'0'/" "$CONF"
	else
		sed -i "/^config main/a\\	option DISABLE_CUSTOM '0'" "$CONF"
	fi
}

_excl_write() {
	local ips="$1" f
	f="$(_excl_file)"
	mkdir -p "$(_excl_dir)"
	if [ -n "$ips" ]; then
		_excl_enable_custom
		local formatted
		formatted=$(printf '%s\n' "$ips" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
		{
			echo "EXCEPT_SRC='{ $formatted }'"
			echo "nft insert rule inet zapret postrouting_hook index 0 \\"
			echo "  ip saddr \$EXCEPT_SRC meta mark set meta mark \\| 0x40000000"
		} > "$f"
	else
		: > "$f"
	fi
}

exclusions_status() {
	[ -f /etc/init.d/zapret ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	local current devjson="" first=1 ip name ts mac rest aip ahw aflags amac amask adev aname

	current=$(_excl_current)

	if [ -f /tmp/dhcp.leases ]; then
		while read -r ts mac ip name rest; do
			[ -z "$ip" ] && continue
			echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || continue
			[ -z "$name" ] && name="*"
			[ "$name" = "*" ] && name="Неизвестное устройство"
			[ "$first" -eq 1 ] || devjson="$devjson,"
			first=0
			devjson="$devjson{\"ip\":\"$ip\",\"name\":\"$(esc "$name")\",\"excluded\":$(printf '%s\n' "$current" | grep -qx "$ip" && echo true || echo false)}"
		done < /tmp/dhcp.leases
	fi

	local lan_dev arp_tmp
	lan_dev=" $(_zm_lan_devs) "
	arp_tmp="$JOBS_DIR/excl_arp_tmp"
	rm -f "$arp_tmp"
	if [ -f /proc/net/arp ]; then
		tail -n +2 /proc/net/arp | while read -r aip ahw aflags amac amask adev; do
			[ -z "$aip" ] && continue
			case "$lan_dev" in *" $adev "*) ;; *) continue ;; esac
			echo "$aip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || continue
			[ "$aflags" = "0x0" ] && continue
			printf '%s' "$devjson" | grep -q "\"ip\":\"$aip\"" && continue
			aname=""
			[ -f /tmp/dhcp.leases ] && aname=$(awk -v mac="$amac" 'tolower($2)==tolower(mac){print $4; exit}' /tmp/dhcp.leases)
			if [ -z "$aname" ] || [ "$aname" = "*" ]; then
				aname=$(logread 2>/dev/null | grep -i "DHCPACK" | grep -i "$aip" | grep -i "$amac" | tail -n1 | awk '{print $NF}')
			fi
			[ "$aname" = "$amac" ] && aname=""
			[ -n "$aname" ] || aname="Неизвестное устройство"
			printf '%s|%s\n' "$aip" "$aname" >> "$arp_tmp"
		done
	fi
	if [ -f "$arp_tmp" ]; then
		while IFS='|' read -r aip aname; do
			[ -z "$aip" ] && continue
			[ "$first" -eq 1 ] || devjson="$devjson,"
			first=0
			devjson="$devjson{\"ip\":\"$aip\",\"name\":\"$(esc "$aname")\",\"excluded\":$(printf '%s\n' "$current" | grep -qx "$aip" && echo true || echo false)}"
		done < "$arp_tmp"
		rm -f "$arp_tmp"
	fi

	local ip2
	for ip2 in $current; do
		[ -z "$ip2" ] && continue
		printf '%s' "$devjson" | grep -q "\"ip\":\"$ip2\"" && continue
		[ "$first" -eq 1 ] || devjson="$devjson,"
		first=0
		devjson="$devjson{\"ip\":\"$ip2\",\"name\":\"Устройство offline\",\"excluded\":true}"
	done

	printf '{"devices":[%s]}\n' "$devjson"
}

exclusions_toggle() {
	local ip="$1" current new_list excluded="false"
	echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || { echo '{"error":"некорректный IP-адрес"}'; return 1; }
	[ -f /etc/init.d/zapret ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	current=$(_excl_current)
	if printf '%s\n' "$current" | grep -qx "$ip"; then
		new_list=$(printf '%s\n' "$current" | grep -vx "$ip")
	else
		new_list=$(printf '%s\n%s\n' "$current" "$ip" | grep -v '^$' | sort -u)
		excluded="true"
	fi
	_excl_write "$new_list"
	zapret_restart
	printf '{"ok":true,"ip":"%s","excluded":%s}\n' "$(esc "$ip")" "$excluded"
}

exclusions_clear() {
	[ -f /etc/init.d/zapret ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	_excl_write ""
	zapret_restart
	printf '{"ok":true}\n'
}

EXCLUDE_DOMAINS_FILE="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"

exclusions_file_get() {
	[ -f "$EXCLUDE_DOMAINS_FILE" ] || { printf '{"content":""}\n'; return 0; }
	printf '{"content":"%s"}\n' "$(esc_ml "$(cat "$EXCLUDE_DOMAINS_FILE")")"
}

exclusions_file_set() {
	local content="$1"
	[ -x /etc/init.d/zapret ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	mkdir -p "$(dirname "$EXCLUDE_DOMAINS_FILE")"
	printf '%s' "$content" > "$EXCLUDE_DOMAINS_FILE"
	zapret_restart
	printf '{"ok":true}\n'
}

exclusions_file_restore() {
	[ -x /etc/init.d/zapret ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	mkdir -p "$(dirname "$EXCLUDE_DOMAINS_FILE")"
	rm -f "$EXCLUDE_DOMAINS_FILE"
	wget -q --timeout=20 -U "Mozilla/5.0" -O "$EXCLUDE_DOMAINS_FILE" "$EXCLUDE_URL"
	[ -s "$EXCLUDE_DOMAINS_FILE" ] || { echo '{"error":"не удалось скачать список исключений"}'; return 1; }
	printf '{"content":"%s"}\n' "$(esc_ml "$(cat "$EXCLUDE_DOMAINS_FILE")")"
}

nfqws_opt_get() {
	[ -f "$CONF" ] || { printf '{"content":""}\n'; return 0; }
	local content
	content=$(sed -n "/^[[:space:]]*option NFQWS_OPT '\$/,/^[[:space:]]*'\$/p" "$CONF" | sed '1d;$d')
	printf '{"content":"%s"}\n' "$(esc_ml "$content")"
}

nfqws_opt_set() {
	local content="$1"
	[ -x /etc/init.d/zapret ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"конфигурация Zapret не найдена"}'; return 1; }
	grep -q "^[[:space:]]*option NFQWS_OPT '\$" "$CONF" || { echo '{"error":"в конфигурации не найден блок NFQWS_OPT"}'; return 1; }
	sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"
	{ echo "	option NFQWS_OPT '"; printf '%s\n' "$content"; echo "'"; } >> "$CONF"
	[ -f /opt/zapret/sync_config.sh ] && chmod +x /opt/zapret/sync_config.sh
	zapret_restart
	sleep 1
	printf '{"ok":true}\n'
}


TG_MTPROTO_VER="0.10"
TGWS_VERSION="0.3.1"
TGWS_BASE_URL="https://gitlab.com/xyzmean/brb/-/raw/main/dist"
TGWS_VERSION_URL="https://gitlab.com/xyzmean/brb/-/raw/main/VERSION"
TG_GO_VER="1.4.1"
TG_RS_VER="2.3.3"
TG_BIN_GO="/usr/bin/tg-ws-proxy-go"
TG_INIT_GO="/etc/init.d/tg-ws-proxy-go"
TG_BIN_RS="/usr/bin/tg-ws-proxy-rs"
TG_INIT_RS="/etc/init.d/tg-ws-proxy-rs"
TG_SECRET_RS_FILE="/etc/tg-ws-proxy-rs.secret"
TG_SECRET_MT_FILE="/etc/tg-ws-proxy/secret.conf"
TG_VER_GO_FILE="/usr/bin/tg-ws-proxy-go.ver"
TG_VER_RS_FILE="/usr/bin/tg-ws-proxy-rs.ver"

_tg_arch_rs() {
	case "$TG_ARCH" in
		aarch64*) echo "tg-ws-proxy-aarch64-unknown-linux-musl" ;;
		x86_64) echo "tg-ws-proxy-x86_64-unknown-linux-musl" ;;
		arm*) echo "tg-ws-proxy-armv7-unknown-linux-musleabihf" ;;
		mips64*) return 1 ;;
		mipsel*) echo "tg-ws-proxy-mipsel-unknown-linux-musl" ;;
		mips*) echo "tg-ws-proxy-mips-unknown-linux-musl" ;;
		*) return 1 ;;
	esac
}

_tg_arch_go() {
	case "$TG_ARCH" in
		aarch64*) echo "tg-ws-proxy-openwrt-aarch64" ;;
		arm*) echo "tg-ws-proxy-openwrt-armv7" ;;
		mips64*) return 1 ;;
		mipsel*) echo "tg-ws-proxy-openwrt-mipsel_24kc" ;;
		mips*) echo "tg-ws-proxy-openwrt-mips_24kc" ;;
		x86_64) echo "tg-ws-proxy-openwrt-x86_64" ;;
		*) return 1 ;;
	esac
}

tg_status() {
	local mt="not_installed" mt_running="false" mt_ver=""
	local go="not_installed" go_running="false" go_ver=""
	local rs="not_installed" rs_running="false" rs_ver=""
	local secret_mt="" secret_rs="" lan_ip

	if [ -f /etc/init.d/tg-ws-proxy ]; then
		mt="installed"; pidof tg-ws-proxy >/dev/null 2>&1 && mt_running="true"
		if [ "$PKG" = "apk" ]; then
			mt_ver=$(apk info -v 2>/dev/null | grep '^tg-ws-proxy-' | grep -v '^tg-ws-proxy-go' | head -n1 | sed -E 's/^tg-ws-proxy-([0-9.]+).*/\1/')
		else
			mt_ver=$(opkg list-installed 2>/dev/null | awk '$1=="tg-ws-proxy"{print $3}' | cut -d'-' -f1)
		fi
	fi
	if [ -f "$TG_INIT_GO" ]; then
		go="installed"; pidof tg-ws-proxy-go >/dev/null 2>&1 && go_running="true"
		[ -f "$TG_VER_GO_FILE" ] && go_ver=$(cat "$TG_VER_GO_FILE")
	fi
	if [ -f "$TG_INIT_RS" ]; then
		rs="installed"; pidof tg-ws-proxy-rs >/dev/null 2>&1 && rs_running="true"
		[ -f "$TG_VER_RS_FILE" ] && rs_ver=$(cat "$TG_VER_RS_FILE")
	fi

	[ -f "$TG_SECRET_MT_FILE" ] && secret_mt=$(grep '^SECRET=' "$TG_SECRET_MT_FILE" | cut -d= -f2)
	if [ -f "$TG_INIT_RS" ]; then
		secret_rs=$(sed -n 's/.*--secret[[:space:]]*\([0-9a-fA-F]\{32\}\).*/\1/p' "$TG_INIT_RS" | head -n1)
	fi
	[ -z "$secret_rs" ] && [ -f "$TG_SECRET_RS_FILE" ] && secret_rs=$(cat "$TG_SECRET_RS_FILE")
	lan_ip="$(_zm_lan_ip)"

	printf '{"mtproto":"%s","mtproto_running":%s,"mtproto_version":"%s","mtproto_latest":"%s","socks5":"%s","socks5_running":%s,"socks5_version":"%s","socks5_latest":"%s","rust":"%s","rust_running":%s,"rust_version":"%s","rust_latest":"%s","lan_ip":"%s","secret_mtproto":"%s","secret_rust":"%s"}\n' \
		"$mt" "$mt_running" "$(esc "$mt_ver")" "$TG_MTPROTO_VER" \
		"$go" "$go_running" "$(esc "$go_ver")" "$TG_GO_VER" \
		"$rs" "$rs_running" "$(esc "$rs_ver")" "$TG_RS_VER" \
		"$(esc "$lan_ip")" "$(esc "$secret_mt")" "$(esc "$secret_rs")"
}

do_tg_install_mtproto() {
	_ensure_deps
	echo "==> Устанавливаем TG WS Proxy MTProto"
	local go_suf raz url tmp arch_full
	if [ "$PKG" = "apk" ]; then go_suf="r1"; raz="apk"; else go_suf="1"; raz="ipk"; fi
	arch_full="$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)"
	url="${GH_MAIN}/spatiumstas/tg-ws-proxy-go/releases/download/${TG_MTPROTO_VER}/tg-ws-proxy_${TG_MTPROTO_VER}-${go_suf}_openwrt_${arch_full}.${raz}"
	tmp="/tmp/tg-ws-proxy.$raz"
	rm -f /etc/tg-ws-proxy.conf /etc/tg-ws-proxy.conf-opkg
	$UPDATE >&2
	echo "==> Скачиваем $(basename "$url")"
	wget -q --timeout=20 -O "$tmp" "$url" || { echo "ОШИБКА скачивания $url"; return 1; }
	$INSTALL "$tmp" >&2 || { echo "ОШИБКА установки"; rm -f "$tmp"; return 1; }
	rm -f "$tmp"
	mkdir -p "$(dirname "$TG_SECRET_MT_FILE")"
	if ! grep -q '^SECRET=.' "$TG_SECRET_MT_FILE" 2>/dev/null; then
		echo "SECRET=$(head -c16 /dev/urandom | hexdump -e '16/1 "%02x"')" > "$TG_SECRET_MT_FILE"
	fi
	rm -f /etc/tg-ws-proxy.conf /etc/tg-ws-proxy.conf-opkg
	/etc/init.d/tg-ws-proxy enable >/dev/null 2>&1
	/etc/init.d/tg-ws-proxy restart >/dev/null 2>&1
	echo "==> Готово"
}

do_tg_remove_mtproto() {
	echo "==> Удаляем TG WS Proxy MTProto"
	/etc/init.d/tg-ws-proxy stop >/dev/null 2>&1
	/etc/init.d/tg-ws-proxy disable >/dev/null 2>&1
	$DELETE tg-ws-proxy >&2
	rm -rf /etc/tg-ws-proxy /etc/tg-ws-proxy.conf /etc/tg-ws-proxy.conf-opkg
	echo "==> Готово"
}

do_tg_install_socks5() {
	_ensure_deps
	echo "==> Устанавливаем TG WS Proxy SOCKS5"
	local file url
	file="$(_tg_arch_go)" || { echo "ОШИБКА: архитектура не поддерживается ($TG_ARCH)"; return 1; }
	url="${GH_MAIN}/d0mhate/-tg-ws-proxy-Manager-go/releases/download/v${TG_GO_VER}/${file}"
	echo "==> Скачиваем $file"
	curl -fL --max-time 30 -o "$TG_BIN_GO" "$url" || { echo "ОШИБКА скачивания"; rm -f "$TG_BIN_GO"; return 1; }
	chmod +x "$TG_BIN_GO"
	if [ ! -f "$TG_INIT_GO" ]; then
		printf '#!/bin/sh /etc/rc.common\nSTART=99\nUSE_PROCD=1\n\nstart_service() {\n\tprocd_open_instance\n\tprocd_set_param command /usr/bin/tg-ws-proxy-go --host 0.0.0.0 --port 2080 --cf-proxy --cf-proxy-first --cf-balance\n\tprocd_set_param respawn\n\tprocd_close_instance\n}\n' > "$TG_INIT_GO"
		chmod +x "$TG_INIT_GO"
		"$TG_INIT_GO" enable >/dev/null 2>&1
	fi
	"$TG_INIT_GO" restart >/dev/null 2>&1
	echo "$TG_GO_VER" > "$TG_VER_GO_FILE"
	echo "==> Готово"
}

do_tg_remove_socks5() {
	echo "==> Удаляем TG WS Proxy SOCKS5"
	[ -x "$TG_INIT_GO" ] && { "$TG_INIT_GO" stop >/dev/null 2>&1; "$TG_INIT_GO" disable >/dev/null 2>&1; }
	rm -f "$TG_BIN_GO" "$TG_INIT_GO" "$TG_VER_GO_FILE"
	echo "==> Готово"
}

do_tg_install_rust() {
	_ensure_deps
	echo "==> Устанавливаем TG WS Proxy Rust"
	local file url tmp_archive tmp_dir secret
	file="$(_tg_arch_rs)" || { echo "ОШИБКА: архитектура не поддерживается ($TG_ARCH)"; return 1; }
	url="${GH_MAIN}/valnesfjord/tg-ws-proxy-rs/releases/download/v${TG_RS_VER}/${file}.tar.gz"
	tmp_archive="/tmp/tg-ws-proxy-rs.tar.gz"; tmp_dir="/tmp/tg-ws-proxy-rs"
	echo "==> Скачиваем $file"
	curl -fL --max-time 30 -o "$tmp_archive" "$url" || { echo "ОШИБКА скачивания"; return 1; }
	rm -rf "$tmp_dir"; mkdir -p "$tmp_dir"
	tar -xzf "$tmp_archive" -C "$tmp_dir" || { echo "ОШИБКА распаковки"; rm -f "$tmp_archive"; return 1; }
	rm -f "$TG_BIN_RS"
	mv "$tmp_dir"/tg-ws-proxy* "$TG_BIN_RS" || { echo "ОШИБКА установки бинарника"; rm -rf "$tmp_dir" "$tmp_archive"; return 1; }
	chmod +x "$TG_BIN_RS"
	rm -rf "$tmp_dir" "$tmp_archive"

	if [ ! -f "$TG_SECRET_RS_FILE" ]; then
		head -c16 /dev/urandom | hexdump -e '16/1 "%02x"' > "$TG_SECRET_RS_FILE"
	fi
	secret=$(cat "$TG_SECRET_RS_FILE")

	if [ ! -f "$TG_INIT_RS" ]; then
		printf '#!/bin/sh /etc/rc.common\nSTART=99\nUSE_PROCD=1\n\nstart_service() {\n\tprocd_open_instance\n\tprocd_set_param command /usr/bin/tg-ws-proxy-rs --host 0.0.0.0 --port 2443 --secret %s --default-domains --cf-balance --cf-priority\n\tprocd_set_param respawn\n\tprocd_close_instance\n}\n' "$secret" > "$TG_INIT_RS"
		chmod +x "$TG_INIT_RS"
		"$TG_INIT_RS" enable >/dev/null 2>&1
	fi
	"$TG_INIT_RS" restart >/dev/null 2>&1
	echo "$TG_RS_VER" > "$TG_VER_RS_FILE"
	echo "==> Готово"
}

do_tg_remove_rust() {
	echo "==> Удаляем TG WS Proxy Rust"
	[ -x "$TG_INIT_RS" ] && { "$TG_INIT_RS" stop >/dev/null 2>&1; "$TG_INIT_RS" disable >/dev/null 2>&1; }
	rm -f "$TG_BIN_RS" "$TG_INIT_RS" "$TG_SECRET_RS_FILE" "$TG_VER_RS_FILE"
	echo "==> Готово"
}

tg_action() {
	local variant="$1" action="$2"
	case "$variant:$action" in
		mtproto:install|mtproto:update) job_start tg_install_mtproto do_tg_install_mtproto ;;
		mtproto:remove)                 job_start tg_remove_mtproto do_tg_remove_mtproto ;;
		socks5:install|socks5:update)   job_start tg_install_socks5 do_tg_install_socks5 ;;
		socks5:remove)                  job_start tg_remove_socks5 do_tg_remove_socks5 ;;
		rust:install|rust:update)       job_start tg_install_rust do_tg_install_rust ;;
		rust:remove)                    job_start tg_remove_rust do_tg_remove_rust ;;
		*) echo '{"error":"неизвестный вариант/действие"}' ;;
	esac
}

tg_restart_all() {
	[ -x /etc/init.d/tg-ws-proxy ] && /etc/init.d/tg-ws-proxy restart >/dev/null 2>&1
	[ -x "$TG_INIT_GO" ] && "$TG_INIT_GO" restart >/dev/null 2>&1
	[ -x "$TG_INIT_RS" ] && "$TG_INIT_RS" restart >/dev/null 2>&1
	[ -x /etc/init.d/tgws ] && /etc/init.d/tgws restart >/dev/null 2>&1
	printf '{"ok":true}\n'
}

_tgws_domain() {
	tgws status 2>/dev/null | sed -n 's/^[[:space:]]*домен:[[:space:]]*//p' | head -n1
}

tgws_status() {
	local installed="not_installed" ver="" domain="" running="false" latest=""
	if [ "$PKG" = "apk" ]; then
		ver=$(apk info -v 2>/dev/null | grep '^tgws-' | sed -E 's/^tgws-([0-9.]+).*/\1/')
	else
		ver=$(opkg list-installed 2>/dev/null | awk '$1=="tgws"{print $3}' | sed 's/-r[0-9]\+$//')
	fi
	if [ -x /etc/init.d/tgws ]; then
		installed="installed"
		[ -n "$(tgws status 2>/dev/null)" ] && running="true"
		domain=$(_tgws_domain)
	fi
	latest="$(_zm_cached tgws _tgws_latest)"
	printf '{"installed":"%s","running":%s,"version":"%s","latest":"%s","domain":"%s"}\n' "$installed" "$running" "$(esc "$ver")" "$(esc "$latest")" "$(esc "$domain")"
}

do_tgws_install() {
	_ensure_deps
	echo "==> Устанавливаем sTGWS"
	local ver arch file tmp
	ver=$(curl -fsSL --connect-timeout 4 --max-time 6 "$TGWS_VERSION_URL" 2>/dev/null | tr -d '[:space:]')
	[ -n "$ver" ] || ver="$TGWS_VERSION"
	arch="$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)"
	[ -n "$arch" ] || arch="$(opkg print-architecture 2>/dev/null | awk '$2!="all"&&$2!="noarch"{print $2}' | tail -1)"
	if [ -z "$arch" ]; then
		echo "ОШИБКА: не удалось определить архитектуру роутера"
		return 1
	fi
	file="tgws-${ver}-1_${arch}.${RAZ}"
	tmp="$JOBS_DIR/tgws_install.$RAZ"
	echo "==> Роутер: $arch, формат пакетов: $PKG"
	echo "==> Скачиваем $file"
	local attempt=1 max_attempts=5
	while [ "$attempt" -le "$max_attempts" ]; do
		rm -f "$tmp"
		wget -q --timeout=20 -O "$tmp" "$TGWS_BASE_URL/$file" >&2
		if [ -s "$tmp" ]; then
			if [ "$RAZ" = "ipk" ]; then
				tar -tzf "$tmp" 2>/dev/null | grep -q 'debian-binary' && break
			else
				head -c 512 "$tmp" | grep -qiE '<html|<!doctype' || break
			fi
		fi
		attempt=$((attempt + 1))
	done
	if [ "$attempt" -gt "$max_attempts" ]; then
		echo "ОШИБКА: не удалось скачать пакет sTGWS ($TGWS_BASE_URL/$file)"
		rm -f "$tmp"
		return 1
	fi
	echo "==> Обновляем список пакетов"
	$UPDATE >&2
	if [ "$PKG" = "apk" ]; then
		if apk info -e kmod-nft-queue >/dev/null 2>&1; then
			apk add kmod-nft-queue >&2
		fi
	elif opkg list-installed kmod-nft-queue 2>/dev/null | grep -q .; then
		opkg flag user kmod-nft-queue >/dev/null 2>&1
	fi
	echo "==> Устанавливаем пакет"
	$INSTALL "$tmp" || { echo "ОШИБКА: менеджер пакетов отказался ставить sTGWS"; rm -f "$tmp"; return 1; }
	rm -f "$tmp"
	if [ ! -x /etc/init.d/tgws ]; then
		echo "ОШИБКА: установка sTGWS не удалась"
		return 1
	fi
	echo "==> Подбираем домен"
	/etc/init.d/tgws enable >/dev/null 2>&1
	/etc/init.d/tgws restart >/dev/null 2>&1
	tgws pick >/dev/null 2>&1
	local i started=0
	for i in $(seq 1 20); do
		if [ -n "$(tgws status 2>/dev/null)" ]; then
			started=1
			break
		fi
		sleep 5
	done
	if [ "$started" != "1" ]; then
		echo "ОШИБКА: не удалось подобрать домен"
		return 1
	fi
	local domain
	domain=$(_tgws_domain)
	echo "==> Используем домен: ${domain:-не определён}"
	echo "==> Готово, sTGWS установлен и запущен"
}

do_tgws_remove() {
	echo "==> Удаляем sTGWS"
	/etc/init.d/tgws disable >/dev/null 2>&1
	/etc/init.d/tgws stop >/dev/null 2>&1
	$DELETE tgws >&2
	/usr/sbin/stgws apply --spec /dev/null --state-dir /var/lib/stgws >/dev/null 2>&1
	/usr/sbin/tgws apply --spec /dev/null --state-dir /var/lib/tgws >/dev/null 2>&1
	killall tgws >/dev/null 2>&1
	killall stgws >/dev/null 2>&1
	nft delete table inet stgws >/dev/null 2>&1
	nft delete table inet tgws >/dev/null 2>&1
	rm -rf /etc/*tgws*
	rm -rf /var/lib/*tgws*
	rm -rf /var/lock/*tgws*
	rm -rf /etc/rc.d/*tgws*
	rm -rf /etc/init.d/*tgws*
	rm -rf /usr/sbin/*tgws*
	rm -rf /usr/bin/*tgws*
	rm -rf /etc/config/*tgws*
	echo "==> Готово, sTGWS удалён"
}

do_tgws_restart() {
	[ -x /etc/init.d/tgws ] || { echo "ОШИБКА: sTGWS не установлен"; return 1; }
	echo "==> Перезапускаем sTGWS"
	/etc/init.d/tgws restart >/dev/null 2>&1
	sleep 5
	if [ -z "$(tgws status 2>/dev/null)" ]; then
		echo "ОШИБКА: sTGWS не запущен после перезапуска"
		return 1
	fi
	echo "==> Готово, sTGWS перезапущен"
}

do_tgws_reconfigure() {
	[ -x /etc/init.d/tgws ] || { echo "ОШИБКА: sTGWS не установлен"; return 1; }
	echo "==> Подбираем новый домен"
	tgws pick >/dev/null 2>&1
	sleep 6
	/etc/init.d/tgws restart >/dev/null 2>&1
	sleep 3
	local domain
	domain=$(_tgws_domain)
	if [ -z "$(tgws status 2>/dev/null)" ] || [ -z "$domain" ]; then
		echo "ОШИБКА: не удалось подобрать домен"
		return 1
	fi
	echo "==> Новый домен: $domain"
	echo "==> Готово, домен перенастроен"
}

tgws_action() {
	local action="$1"
	case "$action" in
		install|update) job_start tgws_install do_tgws_install ;;
		remove)         job_start tgws_remove do_tgws_remove ;;
		restart)        job_start tgws_restart do_tgws_restart ;;
		reconfigure)    job_start tgws_reconfigure do_tgws_reconfigure ;;
		*) echo '{"error":"неизвестное действие"}' ;;
	esac
}


TEST_DIR="$JOBS_DIR/strategy_test"
_test_results_file() { echo "$TEST_DIR/results_$1.txt"; }
_test_running() { [ -f "$JOBS_DIR/strategy_test.pid" ] && kill -0 "$(cat "$JOBS_DIR/strategy_test.pid" 2>/dev/null)" 2>/dev/null; }
_test_recover() { # тест оборвался (перезагрузка, переустановка) — возвращаем конфиг Zapret, который был до теста
	[ -s "$ZM_STATE_DIR/strategy_test.backup" ] || return 0
	_test_running && return 0
	[ -d /opt/zapret ] && cp -f "$ZM_STATE_DIR/strategy_test.backup" "$CONF" && zapret_restart
	rm -f "$ZM_STATE_DIR/strategy_test.backup"
}
TEST_BACKUP="$ZM_STATE_DIR/strategy_test.backup"
TEST_STOP_FLAG="$TEST_DIR/stop"
TEST_MODE_FILE="$TEST_DIR/mode"
TEST_DOMAINS_JSON="${GH_RAW}/hyperion-cs/dpi-checkers/refs/heads/main/ru/tcp-16-20/suite.v2.json"
TEST_YT_DOMAINS="youtu.be youtube.com i.ytimg.com i9.ytimg.com yt3.ggpht.com yt4.ggpht.com googleapis.com jnn-pa.googleapis.com googleusercontent.com signaler-pa.youtube.com youtubei.googleapis.com manifest.googlevideo.com yt3.googleusercontent.com rr4---sn-4g5e6nze.googlevideo.com rr4---sn-5go7yner.googlevideo.com rr4---sn-q4flrnsl.googlevideo.com rr5---sn-n8v7knez.googlevideo.com rr2---sn-q4fl6ndl.googlevideo.com rr1---sn-q4fl6n6y.googlevideo.com rr1---sn-aj5go5-53.googlevideo.com rr1---sn-4axm-n8vs.googlevideo.com rr14---sn-n8v7kn7r.googlevideo.com rr16---sn-axq7sn76.googlevideo.com rr4---sn-jvhnu5g-c35d.googlevideo.com rr1---sn-8ph2xajvh-5xge.googlevideo.com rr1---sn-xguxaxjvh-gufl.googlevideo.com rr1---sn-gvnuxaxjvh-jx3z.googlevideo.com rr1---sn-gvnuxaxjvh-jx3l.googlevideo.com rr1---sn-gvnuxaxjvh-o8ge.googlevideo.com rr5---sn-gvnuxaxjvh-n8vk.googlevideo.com rr10---sn-gvnuxaxjvh-304z.googlevideo.com rr12---sn-gvnuxaxjvh-bvwz.googlevideo.com rr3---sn-ug5onuxaxjvh-n8v6.googlevideo.com rr1---sn-ug5onuxaxjvh-p5ge.googlevideo.com rr1---sn-ug5onuxaxjvh-p3ul.googlevideo.com rr1---sn-ug5onuxaxjvh-n8v6.googlevideo.com rr1---sn-u5uuxaxjvhg0-ocje.googlevideo.com"
TEST_PARALLEL=8

_test_sort_results() {
	local f="$1" tmp
	tmp="$TEST_DIR/sort.$$"
	awk -F'[/ ]' '{ for (i = 1; i <= NF; i++) { if ($i ~ /^[0-9]+$/) { print $i, $0; break } } }' "$f" | sort -k1,1 -nr | cut -d' ' -f2- > "$tmp"
	mv "$tmp" "$f"
}

_test_prepare_urls() {
	local out="$1"
	: > "$out"
	printf '%s\n' \
		"gosuslugi.ru|https://www.gosuslugi.ru" \
		"esia.gosuslugi.ru|https://esia.gosuslugi.ru" \
		"nalog.ru|https://nalog.ru" \
		"lkfl2.nalog.ru|https://lkfl2.nalog.ru" \
		"rutube.ru|https://rutube.ru" \
		"ntc.party|https://ntc.party/" \
		"instagram.com|https://instagram.com" \
		"facebook.com|https://facebook.com" \
		"rutracker.org|https://rutracker.org" \
		"nnmclub.to|https://nnmclub.to" \
		"rutor.info|https://rutor.info" \
		"openwrt.org|https://openwrt.org" \
		"discord.com|https://discord.com" \
		"x.com|https://x.com" \
		"forum.ru-board.com|https://forum.ru-board.com" \
		"play.google.com|https://play.google.com" \
		"downloads.openwrt.org|https://downloads.openwrt.org" \
		"githubusercontent.com|https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/Zapret-Manager.sh" \
		>> "$out"
	curl -fsSL --connect-timeout 8 --max-time 15 "$TEST_DOMAINS_JSON" 2>/dev/null \
		| sed -n 's/.*"id":[[:space:]]*"\([^"]*\)".*"host":[[:space:]]*"\([^"]*\)".*/\1|\2/p' >> "$out"
}

_test_yt_urls() {
	local d
	for d in $TEST_YT_DOMAINS; do
		printf '%s|https://%s/\n' "$d" "$d"
	done
}

_test_kill_pid_tree() {
	local pid="$1" ch c
	[ -n "$pid" ] || return 0
	ch=$(cat "/proc/$pid/task/$pid/children" 2>/dev/null)
	for c in $ch; do _test_kill_pid_tree "$c"; done
	kill -9 "$pid" 2>/dev/null
}

_test_kill_bg_jobs() {
	local pf="$1" pid
	[ -s "$pf" ] || return 0
	while IFS= read -r pid; do
		[ -n "$pid" ] && _test_kill_pid_tree "$pid"
	done < "$pf"
	wait 2>/dev/null
}

_test_check_url() {
	local entry="$1" okfile="$2" logfile="$3" text link
	text=$(echo "$entry" | cut -d'|' -f1)
	link=$(echo "$entry" | cut -d'|' -f2)
	if curl -sL --connect-timeout 4 --max-time 6 --speed-time 3 --speed-limit 1 --range 0-65535 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0" -o /dev/null "$link" >/dev/null 2>&1; then
		echo 1 >> "$okfile"
		echo "[ OK ] $text" >> "$logfile"
	else
		echo "[FAIL] $text" >> "$logfile"
	fi
}

_test_check_all_urls() {
	local urls="$1" logfile="$2" okfile pidfile total run=0 ok entry
	okfile="$TEST_DIR/ok.$$"
	pidfile="$TEST_DIR/pids.$$"
	: > "$okfile"
	: > "$pidfile"
	total=$(printf '%s\n' "$urls" | grep -c '|')
	while IFS= read -r entry; do
		[ -z "$entry" ] && continue
		[ -f "$TEST_STOP_FLAG" ] && break
		_test_check_url "$entry" "$okfile" "$logfile" &
		echo $! >> "$pidfile"
		run=$((run + 1))
		if [ "$run" -ge "$TEST_PARALLEL" ]; then
			wait
			run=0
			[ -f "$TEST_STOP_FLAG" ] && break
		fi
	done <<-TEST_URLS_EOF
	$urls
	TEST_URLS_EOF
	if [ -f "$TEST_STOP_FLAG" ]; then
		_test_kill_bg_jobs "$pidfile"
	else
		wait
	fi
	ok=$(wc -l < "$okfile" | tr -d ' ')
	rm -f "$okfile" "$pidfile"
	printf '%s %s\n' "$ok" "$total"
}

_test_build_candidates() {
	local mode="$1" out="$2" n f
	: > "$out"
	case "$mode" in
		v)
			for n in 1 2 3 4 5 6 7 8 9 10; do strategy_v"$n" >> "$out"; done
			;;
		flowseal)
			f="$(_flowseal_file)"
			[ -s "$f" ] || do_flowseal_download >/dev/null 2>&1
			[ -s "$f" ] && cat "$f" >> "$out"
			;;
		v_flowseal)
			f="$(_flowseal_file)"
			[ -s "$f" ] || do_flowseal_download >/dev/null 2>&1
			[ -s "$f" ] && cat "$f" >> "$out"
			for n in 1 2 3 4 5 6 7 8 9 10; do strategy_v"$n" >> "$out"; done
			;;
		youtube)
			f="$(_yv_file)"
			[ -s "$f" ] || do_yv_download >/dev/null 2>&1
			[ -s "$f" ] && cat "$f" >> "$out"
			;;
	esac
	[ "$mode" = "youtube" ] || sed -i '/^#Y/d' "$out"
}

_test_apply_block() {
	local block="$1"
	sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"
	{ echo "	option NFQWS_OPT '"; echo "$block"; echo "'"; } >> "$CONF"
}

do_test_run() {
	local mode="$1" results
	mkdir -p "$TEST_DIR"
	rm -f "$TEST_STOP_FLAG"
	results="$(_test_results_file "$mode")"
	: > "$results"
	echo "$mode" > "$TEST_MODE_FILE"
	[ -f "$CONF" ] || { echo "ОШИБКА: Zapret не установлен"; return 1; }

	if [ "$mode" = "current" ]; then
		_add_gp_domains
		_refresh_exclude_file
		echo "==> Проверяем текущую применённую стратегию"
		zapret_restart

		local urls_file="$TEST_DIR/urls.txt" dpi_urls yt_urls
		echo "==> Собираем список доменов DPI"
		_test_prepare_urls "$urls_file"
		dpi_urls="$(cat "$urls_file")"
		yt_urls="$(_test_yt_urls)"

		local dpi_log="$TEST_DIR/log_current_dpi.txt" dpi_res dpi_ok dpi_total
		: > "$dpi_log"
		echo "==> Идёт тест по доменам DPI"
		dpi_res=$(_test_check_all_urls "$dpi_urls" "$dpi_log")
		dpi_ok=$(echo "$dpi_res" | cut -d' ' -f1)
		dpi_total=$(echo "$dpi_res" | cut -d' ' -f2)
		echo "==> Результат (DPI): ${dpi_ok}/${dpi_total}"
		echo "Текущая стратегия — домены DPI → ${dpi_ok}/${dpi_total}" >> "$results"

		if [ -f "$TEST_STOP_FLAG" ]; then
			echo "==> Тестирование остановлено пользователем"
			rm -f "$TEST_STOP_FLAG"
			echo "==> Готово"
			return 0
		fi

		local yt_log="$TEST_DIR/log_current_yt.txt" yt_res yt_ok yt_total
		: > "$yt_log"
		echo "==> Идёт тест по доменам YouTube"
		yt_res=$(_test_check_all_urls "$yt_urls" "$yt_log")
		yt_ok=$(echo "$yt_res" | cut -d' ' -f1)
		yt_total=$(echo "$yt_res" | cut -d' ' -f2)
		echo "==> Результат (YouTube): ${yt_ok}/${yt_total}"
		echo "Текущая стратегия — домены YouTube → ${yt_ok}/${yt_total}" >> "$results"

		rm -f "$TEST_STOP_FLAG"
		echo "==> Готово"
		return 0
	fi

	mkdir -p "$ZM_STATE_DIR"
	cp "$CONF" "$TEST_BACKUP"
	_add_gp_domains
	_refresh_exclude_file

	local cand="$TEST_DIR/candidates.txt"
	echo "==> Собираем стратегии для теста"
	_test_build_candidates "$mode" "$cand"
	if [ ! -s "$cand" ]; then
		echo "ОШИБКА: не удалось собрать ни одной стратегии для теста"
		rm -f "$TEST_BACKUP"
		return 1
	fi

	local urls total_domains
	if [ "$mode" = "youtube" ]; then
		urls="$(_test_yt_urls)"
	else
		local urls_file="$TEST_DIR/urls.txt"
		echo "==> Собираем список доменов для теста"
		_test_prepare_urls "$urls_file"
		urls="$(cat "$urls_file")"
	fi
	total_domains=$(printf '%s\n' "$urls" | grep -c '|')

	local total_str
	total_str=$(grep -c '^#' "$cand")
	echo "==> Найдено стратегий: $total_str"
	echo "==> Доменов для теста: $total_domains"

	echo "==> Контрольный тест: Zapret выключен"
	/etc/init.d/zapret stop >/dev/null 2>&1
	local ctrl_log="$TEST_DIR/log_control.txt" ctrl_res ctrl_ok ctrl_total
	: > "$ctrl_log"
	ctrl_res=$(_test_check_all_urls "$urls" "$ctrl_log")
	ctrl_ok=$(echo "$ctrl_res" | cut -d' ' -f1)
	ctrl_total=$(echo "$ctrl_res" | cut -d' ' -f2)
	echo "Контрольный тест (Zapret выключен) → ${ctrl_ok}/${ctrl_total}" >> "$results"
	echo "==> Результат: ${ctrl_ok}/${ctrl_total}"
	/etc/init.d/zapret start >/dev/null 2>&1

	local lines cur=0
	lines=$(grep -n '^#' "$cand" | cut -d: -f1)
	echo "$lines" | while read -r start; do
		cur=$((cur + 1))
		if [ -f "$TEST_STOP_FLAG" ]; then
			echo "==> Получен сигнал остановки, прерываем тестирование"
			break
		fi
		local next name block res ok tot log
		next=$(echo "$lines" | awk -v s="$start" '$1>s{print;exit}')
		if [ -z "$next" ]; then
			sed -n "${start},\$p" "$cand" > "$TEST_DIR/block.txt"
		else
			sed -n "${start},$((next-1))p" "$cand" > "$TEST_DIR/block.txt"
		fi
		name=$(head -n1 "$TEST_DIR/block.txt")
		name="${name#\#}"
		block=$(cat "$TEST_DIR/block.txt")
		echo "==> [$cur/$total_str] Тестируем: $name"
		_test_apply_block "$block"
		zapret_restart
		log="$TEST_DIR/log_$cur.txt"
		: > "$log"
		res=$(_test_check_all_urls "$urls" "$log")
		ok=$(echo "$res" | cut -d' ' -f1)
		tot=$(echo "$res" | cut -d' ' -f2)
		echo "==> Результат: ${ok}/${tot}"
		echo "${name} → ${ok}/${tot}" >> "$results"
	done

	if [ -f "$TEST_STOP_FLAG" ]; then
		echo "==> Тестирование остановлено пользователем, восстанавливаем конфигурацию"
		rm -f "$TEST_STOP_FLAG"
	else
		echo "==> Тестирование завершено, восстанавливаем конфигурацию"
	fi

	echo "==> Результаты теста"
	_test_sort_results "$results"
	cat "$results"
	local best_line
	best_line=$(grep -v '^Контрольный тест' "$results" | head -n1)
	[ -n "$best_line" ] && echo "==> Лучшая стратегия по результатам теста: $best_line"

	cp "$TEST_BACKUP" "$CONF"
	zapret_restart
	rm -f "$TEST_BACKUP"
	echo "==> Готово, конфигурация восстановлена"
}

test_action() {
	local action="$1" mode="$2"
	case "$action" in
		start)
			case "$mode" in
				v|flowseal|v_flowseal|youtube|current) ;;
				*) echo '{"error":"неизвестный режим теста"}'; return 1 ;;
			esac
			job_start strategy_test do_test_run "$mode"
			;;
		stop)
			if [ ! -f "$JOBS_DIR/strategy_test.pid" ] || ! kill -0 "$(cat "$JOBS_DIR/strategy_test.pid" 2>/dev/null)" 2>/dev/null; then
				echo '{"error":"тест не запущен"}'
				return 1
			fi
			mkdir -p "$TEST_DIR"
			touch "$TEST_STOP_FLAG"
			printf '{"ok":true}\n'
			;;
		clear)
			case "$mode" in
				v|flowseal|v_flowseal|youtube|current) rm -f "$(_test_results_file "$mode")" ;;
				*) rm -f "$TEST_DIR"/results_*.txt ;;
			esac
			printf '{"ok":true}\n'
			;;
		*) echo '{"error":"неизвестное действие"}' ;;
	esac
}

test_status() {
	local running="false" mode=""
	_test_recover
	if [ -f "$JOBS_DIR/strategy_test.pid" ] && kill -0 "$(cat "$JOBS_DIR/strategy_test.pid" 2>/dev/null)" 2>/dev/null; then
		running="true"
	fi
	[ -f "$TEST_MODE_FILE" ] && mode=$(cat "$TEST_MODE_FILE")
	printf '{"running":%s,"mode":"%s","has_results_v":%s,"has_results_flowseal":%s,"has_results_v_flowseal":%s,"has_results_youtube":%s,"has_results_current":%s}\n' \
		"$running" "$(esc "$mode")" \
		"$([ -s "$(_test_results_file v)" ] && echo true || echo false)" \
		"$([ -s "$(_test_results_file flowseal)" ] && echo true || echo false)" \
		"$([ -s "$(_test_results_file v_flowseal)" ] && echo true || echo false)" \
		"$([ -s "$(_test_results_file youtube)" ] && echo true || echo false)" \
		"$([ -s "$(_test_results_file current)" ] && echo true || echo false)"
}

test_results() {
	local mode="$1" f
	f="$(_test_results_file "$mode")"
	[ -s "$f" ] || { echo '{"lines":""}'; return; }
	printf '{"lines":"%s"}\n' "$(esc_ml "$(cat "$f")")"
}

_zm_gh_get() { # URL ФАЙЛ [ДИАПАЗОН] — напрямую, а если GitHub не открывается — через туннель WARP
	local i
	curl -fsSL --connect-timeout 6 --max-time 120 ${3:+-r "$3"} -o "$2" "$1" 2>/dev/null && [ -s "$2" ] && return 0
	i="$(_st_warp_first 2>/dev/null)"
	[ -n "$i" ] && [ -d "/sys/class/net/$i" ] || return 1
	curl -fsSL --interface "$i" --connect-timeout 6 --max-time 120 ${3:+-r "$3"} -o "$2" "$1" 2>/dev/null && [ -s "$2" ]
}

_zm_panel_latest() {
	local f="$JOBS_DIR/zm_head.$$" v
	mkdir -p "$JOBS_DIR"
	_zm_gh_get "$ZM_SCRIPT_URL" "$f" 0-400 || { rm -f "$f"; return 1; }
	v="$(grep -m1 '^# Version:' "$f" | sed 's/^# Version:[[:space:]]*//' | tr -d '\r ')"
	rm -f "$f"
	echo "$v" | grep -qE '^[0-9]+(\.[0-9]+)*$' && echo "$v"
}

_zm_newer() { [ -n "$1" ] && _st_ver_lt "$ZM_VERSION" "$1"; }

zm_update_status() {
	local latest
	if [ -s "$ZM_STATE_DIR/latest.panel" ]; then latest="$(_zm_cached panel _zm_panel_latest)"
	else latest="$(ZM_VER_FORCE=1 _zm_cached panel _zm_panel_latest)"; fi
	printf '{"current":"%s","latest":"%s","newer":%s}\n' "$(esc "$ZM_VERSION")" "$(esc "$latest")" "$(_zm_newer "$latest" && echo true || echo false)"
}

_zm_update_fetch() { # ФАЙЛ -> причина отказа в stdout
	rm -f "$1"
	_zm_gh_get "$ZM_SCRIPT_URL" "$1" || { echo "не удалось скачать установщик с GitHub — ни напрямую, ни через WARP"; return 1; }
	head -n1 "$1" | grep -qx '#!/bin/sh' || { echo "скачанный файл не похож на установщик (возможно, вместо него пришла страница-заглушка)"; return 1; }
	grep -q '^# Version:' "$1" || { echo "в установщике нет номера версии"; return 1; }
	tail -n 5 "$1" | grep -q 'Web UI:' || { echo "установщик скачался не полностью — попробуйте ещё раз"; return 1; }
	sh -n "$1" 2>/dev/null || { echo "установщик повреждён — установка отменена"; return 1; }
	return 0
}

zm_update_action() {
	local tmp="/tmp/zm_update_install.sh" why v j
	for j in steer awg redbtn; do
		_job_alive "$j" && { echo '{"error":"идёт операция Steer или AmneziaWG — дождитесь её окончания и обновите панель"}'; return 1; }
	done
	if ! why="$(_zm_update_fetch "$tmp")"; then
		rm -f "$tmp"
		printf '{"error":"%s"}\n' "$(esc "$why")"
		return 1
	fi
	v="$(grep -m1 '^# Version:' "$tmp" | sed 's/^# Version:[[:space:]]*//' | tr -d '\r ')"
	chmod +x "$tmp"
	rm -f "$ZM_STATE_DIR/latest.panel"
	( sh "$tmp" >/tmp/zm_update_install.log 2>&1; rm -f "$tmp" ) >/dev/null 2>&1 </dev/null &
	printf '{"ok":true,"version":"%s"}\n' "$(esc "$v")"
}

_mixomo_lan_ip() { _zm_lan_ip; }

_zm_cached() { # КЛЮЧ КОМАНДА... — значение из кеша на 6 часов; устаревшее обновляется в фоне, страница не ждёт сеть
	local f="$ZM_STATE_DIR/latest.$1" v age=360
	[ "$1" = panel ] && age=60
	shift
	mkdir -p "$ZM_STATE_DIR"
	if [ -n "$ZM_VER_FORCE" ]; then
		v="$("$@")"
		[ -n "$v" ] && echo "$v" > "$f"
	elif [ ! -s "$f" ] || [ -n "$(find "$f" -mmin +$age 2>/dev/null)" ]; then
		if mkdir "$f.lock" 2>/dev/null; then
			( v="$("$@")"; [ -n "$v" ] && echo "$v" > "$f"; rmdir "$f.lock" ) >/dev/null 2>&1 &
		elif [ -n "$(find "$f.lock" -mmin +2 2>/dev/null)" ]; then
			rmdir "$f.lock" 2>/dev/null
		fi
	fi
	cat "$f" 2>/dev/null
}
_mihomo_latest() { curl -Ls --connect-timeout 4 --max-time 6 -o /dev/null -w '%{url_effective}' "https://github.com/MetaCubeX/mihomo/releases/latest" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1; }
_mt_latest() { curl -fsSL --connect-timeout 4 --max-time 6 -o /dev/null -w '%{url_effective}' "https://github.com/MagiTrickle/MagiTrickle/releases/latest" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1; }
_tgws_latest() { curl -fsSL --connect-timeout 4 --max-time 6 "$TGWS_VERSION_URL" 2>/dev/null | tr -d '[:space:]'; }

_mixomo_arch() {
	local arch endian_byte
	arch=$(uname -m)
	endian_byte=$(hexdump -s 5 -n 1 -e '1/1 "%d"' /bin/busybox 2>/dev/null || echo "0")
	case "$arch" in
		x86_64)
			if grep -q avx2 /proc/cpuinfo 2>/dev/null; then echo "amd64"; else echo "amd64-compatible"; fi
			;;
		i?86) echo "386" ;;
		aarch64|arm64) echo "arm64" ;;
		armv7*) echo "armv7" ;;
		armv5*|armv4*) echo "armv5" ;;
		mips64*)
			if [ "$endian_byte" = "1" ]; then echo "mips64le"; else echo "mips64"; fi
			;;
		mips*)
			local fpu floattype
			fpu=$(grep -c FPU /proc/cpuinfo 2>/dev/null || echo 0)
			floattype="softfloat"
			[ "$fpu" -gt 0 ] && floattype="hardfloat"
			if [ "$endian_byte" = "1" ]; then echo "mipsle-${floattype}"; else echo "mips-${floattype}"; fi
			;;
		riscv64) echo "riscv64" ;;
		*) return 1 ;;
	esac
}

mixomo_status() {
	local mihomo="not_installed" mihomo_running="false" mihomo_ver="" mihomo_latest=""
	local magitrickle="not_installed" magitrickle_running="false" mt_ver="" mt_latest=""
	local hev="not_installed" hev_running="false" hev_ver=""
	local lan_ip subscription="false" mt_list="" autorestart="" ui_panel=""

	if [ -x "$MIHOMO_BIN" ]; then
		mihomo="installed"
		pidof mihomo >/dev/null 2>&1 && mihomo_running="true"
		mihomo_ver=$("$MIHOMO_BIN" -v 2>/dev/null | head -n1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
		mihomo_latest="$(_zm_cached mihomo _mihomo_latest)"
		[ -f "$MIHOMO_DIR/.ui_panel" ] && ui_panel=$(cat "$MIHOMO_DIR/.ui_panel")
	fi
	if [ -x /etc/init.d/magitrickle ]; then
		magitrickle="installed"
		/etc/init.d/magitrickle status >/dev/null 2>&1 && magitrickle_running="true"
		if [ "$PKG" = "apk" ]; then
			mt_ver=$(apk info -v 2>/dev/null | grep '^magitrickle-' | cut -d- -f2)
		else
			mt_ver=$(opkg status magitrickle 2>/dev/null | awk '/^Version:/ {sub(/-1$/,"",$2); sub(/-r1$/,"",$2); print $2}')
		fi
		mt_latest="$(_zm_cached magitrickle _mt_latest)"
	fi
	if [ -x /etc/init.d/hev-socks5-tunnel ]; then
		hev="installed"
		/etc/init.d/hev-socks5-tunnel status >/dev/null 2>&1 && hev_running="true"
		if [ "$PKG" = "apk" ]; then
			hev_ver=$(apk info -v 2>/dev/null | grep '^hev-socks5-tunnel-' | cut -d- -f4-)
		else
			hev_ver=$(opkg status hev-socks5-tunnel 2>/dev/null | awk '/^Version:/ {print $2}')
		fi
	fi

	lan_ip=$(_mixomo_lan_ip)
	[ -f "$MIHOMO_CONF" ] && grep -q '^[[:space:]]*[^#].*url: "' "$MIHOMO_CONF" && subscription="true"

	if [ -f "$MAGITRICKLE_CONF" ]; then
		if grep -Fq 'name: Google_ai' "$MAGITRICKLE_CONF"; then mt_list="itdog"
		elif grep -Fq 'name: Meta (WA+FB+Instagram)' "$MAGITRICKLE_CONF"; then mt_list="ih2"
		elif grep -Fq 'url: https://sw.ext.io/ipset/ipset_cf.list' "$MAGITRICKLE_CONF"; then mt_list="ih1"
		fi
	fi

	local cronline hourm
	cronline=$(grep -F "$MIXOMO_CRON_CMD" "$CRON_FILE" 2>/dev/null | head -n1)
	if [ -n "$cronline" ]; then
		hourm=$(echo "$cronline" | awk '{print $2}')
		case "$hourm" in
			*/*) autorestart="every:$(echo "$hourm" | cut -d'/' -f2)" ;;
			*) autorestart="daily:$hourm" ;;
		esac
	fi

	printf '{"mihomo":"%s","mihomo_running":%s,"mihomo_version":"%s","mihomo_latest":"%s","magitrickle":"%s","magitrickle_running":%s,"magitrickle_version":"%s","magitrickle_latest":"%s","hev":"%s","hev_running":%s,"hev_version":"%s","lan_ip":"%s","subscription":%s,"magitrickle_list":"%s","autorestart":"%s","ui_panel":"%s"}\n' \
		"$mihomo" "$mihomo_running" "$(esc "$mihomo_ver")" "$(esc "$mihomo_latest")" \
		"$magitrickle" "$magitrickle_running" "$(esc "$mt_ver")" "$(esc "$mt_latest")" \
		"$hev" "$hev_running" "$(esc "$hev_ver")" \
		"$(esc "$lan_ip")" "$subscription" "$mt_list" "$(esc "$autorestart")" "$(esc "$ui_panel")"
}

_mt_list_known() {
	[ -f "$MAGITRICKLE_CONF" ] || return 1
	grep -Fq 'name: Google_ai' "$MAGITRICKLE_CONF" ||
		grep -Fq 'name: Meta (WA+FB+Instagram)' "$MAGITRICKLE_CONF" ||
		grep -Fq 'url: https://sw.ext.io/ipset/ipset_cf.list' "$MAGITRICKLE_CONF"
}

do_mixomo_install() {
	_ensure_deps
	echo "==> Устанавливаем Mixomo (Mihomo + hev-socks5-tunnel + MagiTrickle)"

	echo "==> Устанавливаем зависимости (unzip, ca-certificates, модули ядра TUN/nftables)"
	$UPDATE >&2
	if [ "$PKG" = "apk" ]; then
		$INSTALL unzip ca-certificates kmod-tun kmod-nft-tproxy kmod-nft-nat curl >&2
	else
		$INSTALL unzip ca-certificates kmod-tun kmod-nft-tproxy kmod-nft-nat curl libcurl4 ca-bundle >&2
	fi

	command -v curl >/dev/null 2>&1 || { echo "ОШИБКА: не найден curl"; return 1; }
	if [ ! -f /etc/ssl/certs/ca-certificates.crt ] && [ ! -f /etc/ssl/certs/ca-bundle.crt ]; then
		echo "ОШИБКА: не найден пакет ca-certificates"
		return 1
	fi
	if [ ! -c /dev/net/tun ]; then
		modprobe tun >/dev/null 2>&1
		[ -c /dev/net/tun ] || { echo "ОШИБКА: в ядре нет поддержки TUN"; return 1; }
	fi

	local avail_tmp avail_root
	avail_tmp=$(df -k /tmp | awk 'NR==2{print $4}')
	if [ "$avail_tmp" -lt 16000 ]; then
		echo "ОШИБКА: недостаточно места в /tmp (нужно около 16 МБ свободных)"
		return 1
	fi
	avail_root=$(df -k /usr/bin | awk 'NR==2{print $4}')
	if [ "$avail_root" -lt 18000 ]; then
		echo "ОШИБКА: недостаточно места на диске (нужно около 18 МБ свободных)"
		return 1
	fi

	[ -f /etc/init.d/mihomo ] && /etc/init.d/mihomo stop >/dev/null 2>&1

	local arch
	arch=$(_mixomo_arch) || { echo "ОШИБКА: архитектура $(uname -m) не распознана"; return 1; }
	echo "==> Архитектура: $(uname -m) -> $arch"

	mkdir -p "$MIHOMO_DIR" "$MIHOMO_DIR/proxy-providers" "$MIHOMO_DIR/rule-providers" "$MIHOMO_DIR/rule-files"
	echo "$arch" > "$MIHOMO_DIR/.arch"

	echo "==> Определяем последнюю версию Mihomo"
	local tag
	tag=$(curl -Ls --connect-timeout 5 --max-time 10 -o /dev/null -w '%{url_effective}' "https://github.com/MetaCubeX/mihomo/releases/latest" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
	[ -n "$tag" ] || { echo "ОШИБКА: не удалось определить версию Mihomo"; return 1; }
	echo "==> Версия: $tag"

	local file url tmp
	file="mihomo-linux-${arch}-${tag}.gz"
	url="${GH_MAIN}/MetaCubeX/mihomo/releases/download/${tag}/${file}"
	tmp="/tmp/mihomo.gz"
	echo "==> Скачиваем $file"
	curl -sSLf --connect-timeout 5 --max-time 90 --retry 3 --retry-delay 2 "$url" -o "$tmp" >&2 || { echo "ОШИБКА: не удалось скачать $file ($url)"; return 1; }
	gunzip -c "$tmp" > "$MIHOMO_BIN" 2>/dev/null || { echo "ОШИБКА: не удалось распаковать архив"; rm -f "$tmp"; return 1; }
	chmod +x "$MIHOMO_BIN"
	rm -f "$tmp"
	"$MIHOMO_BIN" -v >/dev/null 2>&1 || { echo "ОШИБКА: ядро Mihomo не запускается — возможно, неверная архитектура"; return 1; }

	if [ -f "$MIHOMO_CONF" ] && grep -q "mixed-port: 7890" "$MIHOMO_CONF"; then
		echo "==> Используем существующую конфигурацию"
	else
		if [ -f "$MIHOMO_CONF" ]; then
			cp "$MIHOMO_CONF" "$MIHOMO_CONF.bak"
			echo "==> Найден старый конфиг без mixed-port — сохранён как config.yaml.bak"
		fi
		echo "==> Создаём базовую конфигурацию"
		printf '%s\n' \
			'mode: rule' 'ipv6: false' 'mixed-port: 7890' 'log-level: error' 'allow-lan: true' \
			'unified-delay: true' 'tcp-concurrent: false' 'find-process-mode: off' \
			'external-controller: 0.0.0.0:9090' 'external-ui: ./ui' 'routing-mark: 2' \
			'profile:' '  store-selected: true' '  store-fake-ip: true' '  tracing: true' \
			'sniffer:' '  enable: true' '  force-dns-mapping: true' '  parse-pure-ip: true' \
			'  sniff:' '    HTTP:' '      ports: [80]' '      override-destination: true' \
			'    TLS:' '      ports: [443, 8443]' '    QUIC:' '      ports: [443, 8443]' \
			'  skip-domain:' '    - Mijia Cloud' '    - +.lan' '    - +.local' \
			'    - +.msftconnecttest.com' '    - +.msftncsi.com' '    - +.3gppnetwork.org' \
			'    - +.openwrt.org' '    - +.vsean.net' '    - cudy.net' '' \
			'dns:' '  enable: true' '  listen: 0.0.0.0:7880' '  ipv6: false' '  nameserver:' \
			'    - https://8.8.8.8/dns-query' '    - https://8.8.4.4/dns-query' \
			'    - https://1.1.1.1/dns-query' '    - https://1.0.0.1/dns-query' \
			'    - https://9.9.9.9/dns-query' '    - https://149.112.112.112/dns-query' \
			'    - https://94.140.14.140/dns-query' '    - https://94.140.14.141/dns-query' \
			'    - https://77.88.8.8/dns-query' '    - https://77.88.8.1/dns-query' '' \
			'proxies:' '  - name: Домашний интернет' '    type: direct' '' \
			'proxy-groups:' '' 'rule-providers:' '' 'rules:' '  - MATCH,Домашний интернет' \
			> "$MIHOMO_CONF"
	fi

	echo "==> Создаём службу mihomo"
	printf '%s\n' '#!/bin/sh /etc/rc.common' 'START=99' 'USE_PROCD=1' '' \
		"MIHOMO_BIN=\"$MIHOMO_BIN\"" "MIHOMO_DIR=\"$MIHOMO_DIR\"" "MIHOMO_CONF=\"$MIHOMO_CONF\"" '' \
		'start_service() {' '	[ -x "$MIHOMO_BIN" ] || return 1' '	[ -s "$MIHOMO_CONF" ] || return 1' '' \
		'	procd_open_instance "main"' '	procd_set_param command "$MIHOMO_BIN" -d "$MIHOMO_DIR" -f "$MIHOMO_CONF"' \
		'	procd_set_param stdout 1' '	procd_set_param stderr 1' '	procd_set_param respawn' '	procd_close_instance' '}' '' \
		'service_triggers() {' '	procd_add_reload_trigger "mihomo"' '}' \
		> /etc/init.d/mihomo
	chmod +x /etc/init.d/mihomo
	/etc/init.d/mihomo enable >/dev/null 2>&1

	echo "==> Устанавливаем hev-socks5-tunnel"
	$UPDATE >&2
	$INSTALL hev-socks5-tunnel >&2
	if [ "$PKG" = "apk" ]; then
		apk info -e hev-socks5-tunnel >/dev/null 2>&1 || { echo "ОШИБКА: не удалось установить hev-socks5-tunnel — проверьте интернет и репозитории пакетов"; return 1; }
	else
		opkg list-installed 2>/dev/null | grep -q '^hev-socks5-tunnel ' || { echo "ОШИБКА: не удалось установить hev-socks5-tunnel — проверьте интернет и репозитории пакетов"; return 1; }
	fi
	mkdir -p /etc/hev-socks5-tunnel
	printf '%s\n' 'tunnel:' '  name: Mihomo' '  mtu: 8500' '  multi-queue: false' '  ipv4: 198.18.0.1' \
		'socks5:' '  port: 7890' '  address: 127.0.0.1' "  udp: 'udp'" > /etc/hev-socks5-tunnel/main.yml
	chmod 600 /etc/hev-socks5-tunnel/main.yml

	echo "==> Настраиваем сетевой интерфейс и firewall"
	uci -q delete network.Mihomo
	local fw_section
	for fw_section in $(uci show firewall 2>/dev/null | grep -E "\.name='Mihomo'" | sed "s/\.name.*//"); do
		uci -q delete "$fw_section"
	done
	for fw_section in $(uci show firewall 2>/dev/null | grep -E "\.(src|dest)='Mihomo'" | sed -E "s/\.(src|dest).*//"); do
		uci -q delete "$fw_section"
	done
	uci -q delete firewall.Mihomo
	uci -q delete firewall.lan_to_Mihomo
	uci commit firewall
	/etc/init.d/firewall restart >/dev/null 2>&1
	sleep 1

	if ! uci -q get hev-socks5-tunnel.@instance[0] >/dev/null 2>&1; then
		uci add hev-socks5-tunnel instance >/dev/null
	fi
	uci set hev-socks5-tunnel.@instance[0].enabled='1'
	uci set hev-socks5-tunnel.@instance[0].conffile='/etc/hev-socks5-tunnel/main.yml'
	uci commit hev-socks5-tunnel
	/etc/init.d/hev-socks5-tunnel restart >/dev/null 2>&1
	sleep 2

	uci set network.Mihomo=interface
	uci set network.Mihomo.proto='none'
	uci set network.Mihomo.device='Mihomo'
	uci commit network
	/etc/init.d/network reload >/dev/null 2>&1

	local fw_zone fw_fwd
	fw_zone=$(uci add firewall zone)
	uci set "firewall.${fw_zone}.name=Mihomo"
	uci set "firewall.${fw_zone}.input=REJECT"
	uci set "firewall.${fw_zone}.output=REJECT"
	uci set "firewall.${fw_zone}.forward=REJECT"
	uci set "firewall.${fw_zone}.masq=1"
	uci set "firewall.${fw_zone}.mtu_fix=1"
	uci add_list "firewall.${fw_zone}.network=Mihomo"
	fw_fwd=$(uci add firewall forwarding)
	uci set "firewall.${fw_fwd}.src=$(_zm_lan_zone)"
	uci set "firewall.${fw_fwd}.dest=Mihomo"
	uci commit firewall
	/etc/init.d/firewall restart >/dev/null 2>&1

	echo "==> Устанавливаем MagiTrickle"
	local arch_mt mt_tag assets_page file_mt url_mt
	arch_mt=$(grep '^OPENWRT_ARCH=' /etc/os-release 2>/dev/null | cut -d'"' -f2)
	mt_tag=$(curl -Ls --connect-timeout 5 --max-time 10 -o /dev/null -w '%{url_effective}' "https://github.com/MagiTrickle/MagiTrickle/releases/latest" 2>/dev/null | sed 's#.*/tag/##')
	if [ -n "$mt_tag" ] && [ -n "$arch_mt" ]; then
		assets_page=$(curl -fsSL --connect-timeout 5 --max-time 15 "https://github.com/MagiTrickle/MagiTrickle/releases/expanded_assets/${mt_tag}" 2>/dev/null)
		url_mt=$(printf '%s' "$assets_page" | grep -oE "href=\"/MagiTrickle/MagiTrickle/releases/download/[^\"]*_openwrt_${arch_mt}\.${RAZ}\"" | head -n1 | sed 's/^href="//; s/"$//')
		if [ -n "$url_mt" ]; then
			url_mt="${GH_MAIN}${url_mt}"
			file_mt=$(basename "$url_mt")
			tmp="/tmp/$file_mt"
			echo "==> Скачиваем $file_mt"
			if curl -sSLf --connect-timeout 5 --max-time 90 --retry 3 --retry-delay 2 -o "$tmp" "$url_mt" >&2; then
				$INSTALL "$tmp" >&2 || echo "!! Не удалось установить MagiTrickle"
				rm -f "$tmp"
			else
				echo "!! Не удалось скачать MagiTrickle"
			fi
		else
			echo "!! Не найден файл MagiTrickle для архитектуры $arch_mt в версии $mt_tag"
		fi
	else
		echo "!! Не удалось определить версию или архитектуру MagiTrickle"
	fi

	if [ -x /etc/init.d/magitrickle ] && ! _mt_list_known; then
		echo "==> Включаем список Internet Helper в MagiTrickle"
		mkdir -p "$(dirname "$MAGITRICKLE_CONF")"
		if wget -q --timeout=20 -O "$MAGITRICKLE_CONF.new" "$MT_URL_IH1" && [ -s "$MAGITRICKLE_CONF.new" ]; then
			mv -f "$MAGITRICKLE_CONF.new" "$MAGITRICKLE_CONF"
		else
			rm -f "$MAGITRICKLE_CONF.new"
			echo "!! Не удалось скачать список Internet Helper — его можно выбрать позже на вкладке Mixomo"
		fi
	fi

	echo "==> Запускаем сервисы"
	/etc/init.d/mihomo restart >/dev/null 2>&1
	if [ -x /etc/init.d/magitrickle ]; then
		/etc/init.d/magitrickle enable >/dev/null 2>&1
		/etc/init.d/magitrickle restart >/dev/null 2>&1
	fi

	if [ ! -f "$MIHOMO_DIR/.ui_panel" ]; then
		echo "==> Устанавливаем веб-панель MetaCubeXD (по умолчанию)"
		do_mixomo_ui_install metacubexd || echo "!! Не удалось установить веб-панель — можно поставить позже вручную"
	fi

	echo "==> Готово, Mixomo установлен"
}

do_mixomo_remove() {
	echo "==> Удаляем Mixomo"
	if [ -x /etc/init.d/mihomo ]; then
		/etc/init.d/mihomo stop >/dev/null 2>&1
		/etc/init.d/mihomo disable >/dev/null 2>&1
	fi
	rm -f /etc/init.d/mihomo "$MIHOMO_BIN"
	rm -rf "$MIHOMO_DIR"

	[ -x /etc/init.d/hev-socks5-tunnel ] && /etc/init.d/hev-socks5-tunnel stop >/dev/null 2>&1
	if [ -x /etc/init.d/bytetube ]; then
		echo "==> hev-socks5-tunnel используется ByeTube — оставляю пакет"
	else
		$DELETE hev-socks5-tunnel >&2
	fi
	rm -rf /etc/hev-socks5-tunnel
	uci -q delete hev-socks5-tunnel.@instance[0]
	uci commit hev-socks5-tunnel 2>/dev/null

	uci -q delete network.Mihomo
	local fw_section
	for fw_section in $(uci show firewall 2>/dev/null | grep -E "\.name='Mihomo'" | sed "s/\.name.*//"); do
		uci -q delete "$fw_section"
	done
	for fw_section in $(uci show firewall 2>/dev/null | grep -E "\.(src|dest)='Mihomo'" | sed -E "s/\.(src|dest).*//"); do
		uci -q delete "$fw_section"
	done
	uci -q delete firewall.Mihomo
	uci -q delete firewall.lan_to_Mihomo
	uci commit network
	uci commit firewall
	/etc/init.d/network reload >/dev/null 2>&1
	/etc/init.d/firewall restart >/dev/null 2>&1

	if [ -x /etc/init.d/magitrickle ]; then
		/etc/init.d/magitrickle stop >/dev/null 2>&1
		/etc/init.d/magitrickle disable >/dev/null 2>&1
	fi
	$DELETE magitrickle >&2
	rm -rf /etc/magitrickle

	sed -i "\\|$MIXOMO_CRON_CMD|d" "$CRON_FILE" 2>/dev/null
	/etc/init.d/cron restart >/dev/null 2>&1

	echo "==> Готово, Mixomo удалён. Рекомендуется перезагрузить роутер"
}

mixomo_action() {
	local action="$1"
	case "$action" in
		install|update) job_start mixomo_install do_mixomo_install ;;
		remove)  job_start mixomo_remove do_mixomo_remove ;;
		start)
			[ -x /etc/init.d/mihomo ] || { echo '{"error":"Mixomo не установлен"}'; return 1; }
			/etc/init.d/mihomo start >/dev/null 2>&1
			[ -x /etc/init.d/hev-socks5-tunnel ] && /etc/init.d/hev-socks5-tunnel start >/dev/null 2>&1
			[ -x /etc/init.d/magitrickle ] && /etc/init.d/magitrickle start >/dev/null 2>&1
			mixomo_status ;;
		stop)
			[ -x /etc/init.d/mihomo ] || { echo '{"error":"Mixomo не установлен"}'; return 1; }
			[ -x /etc/init.d/magitrickle ] && /etc/init.d/magitrickle stop >/dev/null 2>&1
			[ -x /etc/init.d/hev-socks5-tunnel ] && /etc/init.d/hev-socks5-tunnel stop >/dev/null 2>&1
			/etc/init.d/mihomo stop >/dev/null 2>&1
			mixomo_status ;;
		restart)
			[ -x /etc/init.d/mihomo ] || { echo '{"error":"Mixomo не установлен"}'; return 1; }
			/etc/init.d/mihomo restart >/dev/null 2>&1
			[ -x /etc/init.d/hev-socks5-tunnel ] && /etc/init.d/hev-socks5-tunnel restart >/dev/null 2>&1
			[ -x /etc/init.d/magitrickle ] && /etc/init.d/magitrickle restart >/dev/null 2>&1
			mixomo_status ;;
		*) echo '{"error":"неизвестное действие"}' ;;
	esac
}

mixomo_config_get() {
	[ -f "$MIHOMO_CONF" ] || { echo '{"error":"конфигурация не найдена"}'; return 1; }
	printf '{"content":"%s"}\n' "$(esc_ml "$(cat "$MIHOMO_CONF")")"
}

mixomo_config_set() {
	local content="$1"
	[ -x /etc/init.d/mihomo ] || { echo '{"error":"Mixomo не установлен"}'; return 1; }
	cp "$MIHOMO_CONF" "$MIHOMO_CONF.bak" 2>/dev/null
	printf '%s' "$content" > "$MIHOMO_CONF"
	/etc/init.d/mihomo restart >/dev/null 2>&1
	sleep 1
	if pidof mihomo >/dev/null 2>&1; then
		printf '{"ok":true}\n'
	else
		cp "$MIHOMO_CONF.bak" "$MIHOMO_CONF" 2>/dev/null
		/etc/init.d/mihomo restart >/dev/null 2>&1
		echo '{"error":"mihomo не запустился с новой конфигурацией — изменения отменены, проверьте синтаксис"}'
		return 1
	fi
}

mixomo_subscription_set() {
	local sub_url="$1"
	case "$sub_url" in
		http://*|https://*) ;;
		*) echo '{"error":"ссылка должна начинаться с http:// или https://"}'; return 1 ;;
	esac
	[ -x /etc/init.d/mihomo ] || { echo '{"error":"Mixomo не установлен"}'; return 1; }
	/etc/init.d/mihomo stop >/dev/null 2>&1
	rm -rf "$MIHOMO_DIR/proxy-providers" "$MIHOMO_DIR/proxies"

	if grep -q '^[[:space:]]*proxy-providers:' "$MIHOMO_CONF" 2>/dev/null; then
		local tmp
		tmp=$(mktemp)
		if awk -v url="$sub_url" 'BEGIN { updated = 0; in_provider = 0; section = "" } { if ($0 ~ /^[a-zA-Z_-]+:/) { section = $0; sub(/:.*/, "", section) } if (!updated && section == "proxy-providers" && $0 ~ /^[[:space:]]*type:[[:space:]]*http[[:space:]]*$/) { in_provider = 1; print; next } if (!updated && in_provider && $0 ~ /^[[:space:]]*url:[[:space:]]*"/) { sub(/url:[[:space:]]*".*"/, "url: \"" url "\""); updated = 1; in_provider = 0; print; next } print } END { exit (updated ? 0 : 1) }' "$MIHOMO_CONF" > "$tmp"
		then
			mv "$tmp" "$MIHOMO_CONF"
			/etc/init.d/mihomo restart >/dev/null 2>&1
			printf '{"ok":true,"mode":"updated"}\n'
			return 0
		fi
		rm -f "$tmp"
	fi

	printf '%s\n' \
		'mixed-port: 7890' 'allow-lan: false' 'tcp-concurrent: true' 'mode: rule' \
		'log-level: info' 'ipv6: false' 'external-controller: 0.0.0.0:9090' \
		'external-ui: ui' 'secret:' 'unified-delay: true' \
		'profile:' '  store-selected: true' '  store-fake-ip: true' '' \
		'proxy-groups:' '  - name: GLOBAL' '    type: select' '    proxies:' \
		'      - DIRECT' '    use:' '      - Подписка' '' \
		'  - name: YouTube' '    type: select' '    proxies:' \
		'      - DIRECT' '    use:' '      - Подписка' '' \
		'rules:' '  - RULE-SET,youtube,YouTube' '  - MATCH,GLOBAL' '' \
		'proxy-providers:' '  Подписка:' '    type: http' '    proxy: DIRECT' \
		'    header:' '      x-hwid:' '        - b6e2d53b1b2c8618719f42fb95ab1e43' \
		"    url: \"$sub_url\"" '    interval: 43200' '    health-check:' \
		'      enable: true' '      interval: 300' \
		'      url: "https://google.com/generate_204"' '      expected-status: 204' '' \
		'rule-providers:' '  youtube:' '    type: http' '    format: yaml' \
		'    behavior: classical' \
		'    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"' \
		'    path: ./rule-providers/youtube.yaml' '    interval: 86400' \
		> "$MIHOMO_CONF"
	/etc/init.d/mihomo restart >/dev/null 2>&1
	printf '{"ok":true,"mode":"created"}\n'
}

mixomo_magitrickle_list_set() {
	local id="$1" url
	case "$id" in
		itdog) url="$MT_URL_ITDOG" ;;
		ih1) url="$MT_URL_IH1" ;;
		ih2) url="$MT_URL_IH2" ;;
		*) echo '{"error":"неизвестный список"}'; return 1 ;;
	esac
	[ -x /etc/init.d/magitrickle ] || { echo '{"error":"MagiTrickle не установлен"}'; return 1; }
	wget -q --timeout=20 -O "$MAGITRICKLE_CONF" "$url" || { echo '{"error":"не удалось скачать список"}'; return 1; }
	[ -s "$MAGITRICKLE_CONF" ] || { echo '{"error":"скачанный файл пуст"}'; return 1; }
	/etc/init.d/magitrickle enable >/dev/null 2>&1
	/etc/init.d/magitrickle restart >/dev/null 2>&1
	[ -x /etc/init.d/mihomo ] && /etc/init.d/mihomo restart >/dev/null 2>&1
	printf '{"ok":true}\n'
}

mixomo_autorestart_set() {
	local mode="$1" value="$2"
	mkdir -p "$(dirname "$CRON_FILE")"
	sed -i "\\|$MIXOMO_CRON_CMD|d" "$CRON_FILE" 2>/dev/null
	case "$mode" in
		off) ;;
		every)
			case "$value" in
				2|4|6|8|10|12|14|16|18|20|22) echo "0 */$value * * * $MIXOMO_CRON_CMD" >> "$CRON_FILE" ;;
				*) echo '{"error":"допустимы только чётные значения от 2 до 22"}'; return 1 ;;
			esac
			;;
		daily)
			case "$value" in
				''|*[!0-9]*) echo '{"error":"введите число от 0 до 23"}'; return 1 ;;
			esac
			if [ "$value" -lt 0 ] || [ "$value" -gt 23 ]; then
				echo '{"error":"допустимый диапазон 0-23"}'
				return 1
			fi
			echo "0 $value * * * $MIXOMO_CRON_CMD" >> "$CRON_FILE"
			;;
		*) echo '{"error":"неизвестный режим"}'; return 1 ;;
	esac
	/etc/init.d/cron restart >/dev/null 2>&1
	printf '{"ok":true}\n'
}

do_mixomo_ui_install() {
	local which="$1"
	[ -d "$MIHOMO_DIR" ] || { echo "ОШИБКА: Mixomo не установлен"; return 1; }
	rm -rf "$MIHOMO_DIR/ui"
	mkdir -p "$MIHOMO_DIR/ui"
	case "$which" in
		zashboard)
			echo "==> Скачиваем Zashboard"
			local tmp="/tmp/zashboard.zip" ok=0 i
			for i in 1 2 3; do
				curl -sSfL --connect-timeout 3 --max-time 7 -o "$tmp" "${GH_MAIN}/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip" >&2 && { ok=1; break; }
				sleep 1
			done
			[ "$ok" = "1" ] || { echo "ОШИБКА: не удалось скачать Zashboard"; return 1; }
			command -v unzip >/dev/null 2>&1 || $INSTALL unzip >&2
			rm -rf /tmp/zashboard
			unzip -oq "$tmp" -d /tmp/zashboard || { echo "ОШИБКА: не удалось распаковать архив"; rm -rf "$tmp" /tmp/zashboard; return 1; }
			cp -r /tmp/zashboard/dist/* "$MIHOMO_DIR/ui/"
			rm -rf "$tmp" /tmp/zashboard
			echo "zashboard" > "$MIHOMO_DIR/.ui_panel"
			echo "==> Готово, Zashboard установлен"
			;;
		metacubexd)
			echo "==> Скачиваем MetaCubeXD"
			local tmp="/tmp/metacubexd.tgz" ok=0 i
			for i in 1 2 3; do
				curl -sSfL --connect-timeout 3 --max-time 7 -o "$tmp" "${GH_MAIN}/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz" >&2 && { ok=1; break; }
				sleep 1
			done
			[ "$ok" = "1" ] || { echo "ОШИБКА: не удалось скачать MetaCubeXD"; return 1; }
			rm -rf /tmp/metacubexd; mkdir -p /tmp/metacubexd
			tar -xzf "$tmp" -C /tmp/metacubexd || { echo "ОШИБКА: не удалось распаковать архив"; rm -rf "$tmp" /tmp/metacubexd; return 1; }
			cp -r /tmp/metacubexd/* "$MIHOMO_DIR/ui/"
			rm -rf "$tmp" /tmp/metacubexd
			echo "metacubexd" > "$MIHOMO_DIR/.ui_panel"
			echo "==> Готово, MetaCubeXD установлен"
			;;
		*) echo "ОШИБКА: неизвестная панель"; return 1 ;;
	esac
}

mixomo_ui_action() {
	job_start mixomo_ui_install do_mixomo_ui_install "$1"
}

MIXOMO_WARP_CONF="/root/WARP.conf"
MIXOMO_WARP_PRIMARY="https://santa-atmo.ru/warp/warp.php"
MIXOMO_WARP_SECONDARY="https://wgcli.vercel.app"
MIXOMO_AWG_JC=4
MIXOMO_AWG_JMIN=40
MIXOMO_AWG_JMAX=70
MIXOMO_AWG_H1=1
MIXOMO_AWG_H2=2
MIXOMO_AWG_H3=3
MIXOMO_AWG_H4=4
MIXOMO_AWG_S1=0
MIXOMO_AWG_S2=0
MIXOMO_AWG_I1="<b 0xce000000010897a297ecc34cd6dd000044d0ec2e2e1ea2991f467ace4222129b5a098823784694b4897b9986ae0b7280135fa85e196d9ad980b150122129ce2a9379531b0fd3e871ca5fdb883c369832f730e272d7b8b74f393f9f0fa43f11e510ecb2219a52984410c204cf875585340c62238e14ad04dff382f2c200e0ee22fe743b9c6b8b043121c5710ec289f471c91ee414fca8b8be8419ae8ce7ffc53837f6ade262891895f3f4cecd31bc93ac5599e18e4f01b472362b8056c3172b513051f8322d1062997ef4a383b01706598d08d48c221d30e74c7ce000cdad36b706b1bf9b0607c32ec4b3203a4ee21ab64df336212b9758280803fcab14933b0e7ee1e04a7becce3e2633f4852585c567894a5f9efe9706a151b615856647e8b7dba69ab357b3982f554549bef9256111b2d67afde0b496f16962d4957ff654232aa9e845b61463908309cfd9de0a6abf5f425f577d7e5f6440652aa8da5f73588e82e9470f3b21b27b28c649506ae1a7f5f15b876f56abc4615f49911549b9bb39dd804fde182bd2dcec0c33bad9b138ca07d4a4a1650a2c2686acea05727e2a78962a840ae428f55627516e73c83dd8893b02358e81b524b4d99fda6df52b3a8d7a5291326e7ac9d773c5b43b8444554ef5aea104a738ed650aa979674bbed38da58ac29d87c29d387d80b526065baeb073ce65f075ccb56e47533aef357dceaa8293a523c5f6f790be90e4731123d3c6152a70576e90b4ab5bc5ead01576c68ab633ff7d36dcde2a0b2c68897e1acfc4d6483aaaeb635dd63c96b2b6a7a2bfe042f6aed82e5363aa850aace12ee3b1a93f30d8ab9537df483152a5527faca21efc9981b304f11fc95336f5b9637b174c5a0659e2b22e159a9fed4b8e93047371175b1d6d9cc8ab745f3b2281537d1c75fb9451871864efa5d184c38c185fd203de206751b92620f7c369e031d2041e152040920ac2c5ab5340bfc9d0561176abf10a147287ea90758575ac6a9f5ac9f390d0d5b23ee12af583383d994e22c0cf42383834bcd3ada1b3825a0664d8f3fb678261d57601ddf94a8a68a7c273a18c08aa99c7ad8c6c42eab67718843597ec9930457359dfdfbce024afc2dcf9348579a57d8d3490b2fa99f278f1c37d87dad9b221acd575192ffae1784f8e60ec7cee4068b6b988f0433d96d6a1b1865f4e155e9fe020279f434f3bf1bd117b717b92f6cd1cc9bea7d45978bcc3f24bda631a36910110a6ec06da35f8966c9279d130347594f13e9e07514fa370754d1424c0a1545c5070ef9fb2acd14233e8a50bfc5978b5bdf8bc1714731f798d21e2004117c61f2989dd44f0cf027b27d4019e81ed4b5c31db347c4a3a4d85048d7093cf16753d7b0d15e078f5c7a5205dc2f87e330a1f716738dce1c6180e9d02869b5546f1c4d2748f8c90d9693cba4e0079297d22fd61402dea32ff0eb69ebd65a5d0b687d87e3a8b2c42b648aa723c7c7daf37abcc4bb85caea2ee8f55bec20e913b3324ab8f5c3304f820d42ad1b9f2ffc1a3af9927136b4419e1e579ab4c2ae3c776d293d397d575df181e6cae0a4ada5d67ecea171cca3288d57c7bbdaee3befe745fb7d634f70386d873b90c4d6c6596bb65af68f9e5121e67ebf0d89d3c909ceedfb32ce9575a7758ff080724e1ab5d5f43074ecb53a479af21ed03d7b6899c36631c0166f9d47e5e1d4528a5d3d3f744029c4b1c190cbfbad06f5f83f7ad0429fa9a2719c56ffe3783460e166de2d8>"

mixomo_warp_status() {
	local exists="false" content=""
	if [ -s "$MIXOMO_WARP_CONF" ]; then
		exists="true"
		content=$(cat "$MIXOMO_WARP_CONF")
	fi
	printf '{"exists":%s,"content":"%s"}\n' "$exists" "$(esc_ml "$content")"
}

mixomo_warp_config_set() {
	local content="$1"
	[ -n "$content" ] || { echo '{"error":"пустая конфигурация — сохранение отменено"}'; return 1; }
	echo "$content" | grep -q '^\[Interface\]' || { echo '{"error":"файл должен начинаться с секции [Interface]"}'; return 1; }
	echo "$content" | grep -q '^\[Peer\]' || { echo '{"error":"в файле нет секции [Peer]"}'; return 1; }
	echo "$content" | grep -q '^PrivateKey' || { echo '{"error":"в секции [Interface] нет PrivateKey"}'; return 1; }
	echo "$content" | grep -q '^PublicKey' || { echo '{"error":"в секции [Peer] нет PublicKey"}'; return 1; }
	mkdir -p "$(dirname "$MIXOMO_WARP_CONF")"
	printf '%s' "$content" > "$MIXOMO_WARP_CONF"
	chmod 600 "$MIXOMO_WARP_CONF"
	printf '{"ok":true}\n'
}

_mixomo_warp_best_endpoint() {
	local warp_tmp="$JOBS_DIR/mixomo_warp"
	local prefixes="188.114.96. 188.114.97. 188.114.98. 188.114.99. 162.159.192. 162.159.193. 162.159.195. 8.34.70. 8.34.146. 8.39.214. 8.39.204. 8.6.112. 8.35.211. 8.39.125. 8.47.69."
	local pings="$warp_tmp/pings" candidates count=0 ip
	mkdir -p "$warp_tmp"
	rm -f "$pings"
	candidates=$(awk -v prefixes="$prefixes" 'BEGIN { srand(); n = split(prefixes, arr, " "); for (i = 0; i < 60; i++) { idx = int(rand() * n) + 1; last = int(rand() * 256); print arr[idx] last } }')
	for ip in $candidates; do
		(
			trace_data=$(curl -s --connect-timeout 2 -w "\n%{time_total}" -H "Host: trace.cloudflare.com" "http://${ip}/cdn-cgi/trace" 2>/dev/null)
			[ -n "$trace_data" ] || exit 0
			colo=$(echo "$trace_data" | awk -F'=' '$1=="colo"{print $2}')
			[ "$colo" = "DME" ] && exit 0
			[ -z "$colo" ] && exit 0
			ping_ms=$(echo "$trace_data" | tail -n1 | awk '{printf "%d", $1 * 1000}')
			[ -n "$ping_ms" ] && echo "$ping_ms $ip $colo" >> "$pings"
		) &
		count=$((count + 1))
		[ $((count % 20)) -eq 0 ] && wait
	done
	wait
	if [ -s "$pings" ]; then
		sort -n "$pings" | head -n1 | awk '{print $2":4500"}'
	else
		echo "engage.cloudflareclient.com:4500"
	fi
}

do_mixomo_warp_register() {
	local endpoint_mode="$1" warp_tmp="$JOBS_DIR/mixomo_warp" reg
	mkdir -p "$warp_tmp"
	reg="$warp_tmp/reg.json"
	rm -f "$reg"

	echo "==> Генерируем WARP"
	echo "==> Используем основной метод"
	local priv="" peer="" v4="" v6=""
	if curl -fsSL --max-time 30 "$MIXOMO_WARP_PRIMARY" -o "$reg" 2>/dev/null && grep -q '"public_key"' "$reg"; then
		priv=$(grep -o '"key"[[:space:]]*:[[:space:]]*"[^"]*"' "$reg" | head -n1 | sed 's/.*:[[:space:]]*"//;s/"$//')
		peer=$(grep -o '"public_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$reg" | head -n1 | sed 's/.*:[[:space:]]*"//;s/"$//')
		v4=$(grep -o '"v4"[[:space:]]*:[[:space:]]*"[^"]*"' "$reg" | sed -n '2p' | sed 's/.*:[[:space:]]*"//;s/"$//')
		v6=$(grep -o '"v6"[[:space:]]*:[[:space:]]*"[^"]*"' "$reg" | sed -n '2p' | sed 's/.*:[[:space:]]*"//;s/"$//')
	fi

	if [ -z "$priv" ] || [ -z "$peer" ] || [ -z "$v4" ]; then
		echo "==> Основной метод не сработал, пробуем резервный"
		if ! command -v jq >/dev/null 2>&1 || { ! command -v wg >/dev/null 2>&1 && ! command -v awg >/dev/null 2>&1; }; then
			$UPDATE >&2
		fi
		command -v jq >/dev/null 2>&1 || $INSTALL jq >&2
		command -v wg >/dev/null 2>&1 || command -v awg >/dev/null 2>&1 || $INSTALL wireguard-tools >&2
		command -v jq >/dev/null 2>&1 || { echo "ОШИБКА: не удалось установить jq для резервного метода"; return 1; }
		local gen=wg
		command -v awg >/dev/null 2>&1 && gen=awg
		command -v "$gen" >/dev/null 2>&1 || { echo "ОШИБКА: не удалось установить wireguard-tools для резервного метода"; return 1; }
		priv=$("$gen" genkey 2>/dev/null)
		if ! curl -fsSL --max-time 60 "$MIXOMO_WARP_SECONDARY" -o "$reg" 2>/dev/null; then
			echo "ОШИБКА: не удалось получить WARP через резервный метод"
			return 1
		fi
		if jq -e '.result.config.peers[0].public_key' "$reg" >/dev/null 2>&1; then
			priv=$(jq -r '.result.key' "$reg")
			peer=$(jq -r '.result.config.peers[0].public_key' "$reg")
			v4=$(jq -r '.result.config.interface.addresses.v4' "$reg")
			v6=$(jq -r '.result.config.interface.addresses.v6 // empty' "$reg")
		elif jq -e '.config.peers[0].public_key' "$reg" >/dev/null 2>&1; then
			peer=$(jq -r '.config.peers[0].public_key' "$reg")
			v4=$(jq -r '.config.interface.addresses.v4' "$reg")
			v6=$(jq -r '.config.interface.addresses.v6 // empty' "$reg")
		else
			echo "ОШИБКА: резервный источник вернул неверный формат"
			return 1
		fi
	fi

	[ -n "$peer" ] && [ "$peer" != "null" ] || { echo "ОШИБКА: не получен публичный ключ сервера"; return 1; }
	[ -n "$v4" ] && [ "$v4" != "null" ] || { echo "ОШИБКА: не получен IPv4-адрес"; return 1; }
	echo "==> WARP сгенерирован"

	local ep
	if [ "$endpoint_mode" = "auto" ]; then
		echo "==> Подбираем лучший endpoint"
		ep=$(_mixomo_warp_best_endpoint)
	else
		ep="engage.cloudflareclient.com:4500"
	fi
	echo "==> Используем endpoint: $ep"

	printf '%s\n' \
		"[Interface]" "PrivateKey = $priv" "Address = ${v4}${v6:+, $v6}" "DNS = 9.9.9.9" "MTU = 1280" \
		"S1 = $MIXOMO_AWG_S1" "S2 = $MIXOMO_AWG_S2" "Jc = $MIXOMO_AWG_JC" "Jmin = $MIXOMO_AWG_JMIN" "Jmax = $MIXOMO_AWG_JMAX" \
		"H1 = $MIXOMO_AWG_H1" "H2 = $MIXOMO_AWG_H2" "H3 = $MIXOMO_AWG_H3" "H4 = $MIXOMO_AWG_H4" "I1 = $MIXOMO_AWG_I1" "" \
		"[Peer]" "PublicKey = $peer" "AllowedIPs = 0.0.0.0/0, ::/0" "Endpoint = $ep" "PersistentKeepalive = 25" \
		> "$MIXOMO_WARP_CONF"
	echo "==> Готово, файл сохранён в $MIXOMO_WARP_CONF"
}

mixomo_warp_action() {
	local endpoint_mode="$1"
	job_start mixomo_warp do_mixomo_warp_register "$endpoint_mode"
}

do_mixomo_warp_integrate() {
	[ -s "$MIXOMO_WARP_CONF" ] || { echo "ОШИБКА: сначала сгенерируйте WARP.conf"; return 1; }
	[ -x /etc/init.d/mihomo ] || { echo "ОШИБКА: Mixomo не установлен"; return 1; }
	echo "==> Интегрируем WARP.conf в Mihomo"
	local tmp; tmp=$(mktemp)
	awk -v OUT="$tmp" '
	function trim(s){ gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s); return s }
	function lc(s){ return tolower(s) }
	function yaml_quote(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\r/,"",s); return "\"" s "\"" }
	function split_endpoint(s,    a,n){ s=trim(s); n=split(s,a,":"); if(n<2){ host=s; port="" } else { port=a[n]; host=a[1]; for(i=2;i<n;i++) host=host ":" a[i] } }
	BEGIN{ sec=""; addr4=""; addr6=""; priv=""; pub=""; psk=""; allowed=""; endpoint=""; keep=""; s1=""; s2=""; jc=""; jmin=""; jmax=""; h1=""; h2=""; h3=""; h4=""; i1=""; mtu="" }
	{
		line=$0; sub(/[;#].*$/, "", line); line=trim(line)
		if(line=="") next
		if(line ~ /^\[.*\]$/){ sec=lc(trim(substr(line,2,length(line)-2))); next }
		if(index(line,"=")==0) next
		key=trim(substr(line,1,index(line,"=")-1)); val=trim(substr(line,index(line,"=")+1)); k=lc(key)
		if(sec=="interface"){
			if(k=="address"){ gsub(/,/, " ", val); n=split(val, a, /[ \t]+/); for(i=1;i<=n;i++){ if(a[i] ~ /:/) addr6=a[i]; else addr4=a[i] } }
			else if(k=="privatekey") priv=val
			else if(k=="mtu") mtu=val
			else if(k=="s1") s1=val
			else if(k=="s2") s2=val
			else if(k=="jc") jc=val
			else if(k=="jmin") jmin=val
			else if(k=="jmax") jmax=val
			else if(k=="h1") h1=val
			else if(k=="h2") h2=val
			else if(k=="h3") h3=val
			else if(k=="h4") h4=val
			else if(k=="i1") i1=val
		} else if(sec=="peer"){
			if(k=="publickey") pub=val
			else if(k=="presharedkey") psk=val
			else if(k=="allowedips") { gsub(/[ \t]+/, "", val); allowed=val }
			else if(k=="endpoint") endpoint=val
			else if(k=="persistentkeepalive") keep=val
		}
	}
	END{
		if(priv=="" || pub=="" || endpoint==""){ print "нет обязательных полей" > "/dev/stderr"; exit 2 }
		split_endpoint(endpoint)
		ip=addr4; sub(/\/32$/, "", ip)
		ipv6=addr6; sub(/\/128$/, "", ipv6)
		if(allowed=="") allowed="0.0.0.0/0,::/0"
		n=split(allowed, aip, ",")
		allowed_block=""
		for(i=1;i<=n;i++){ if(aip[i]=="") continue; allowed_block = allowed_block "      - " yaml_quote(aip[i]) "\n" }

		print "mixed-port: 7890" > OUT
		print "allow-lan: false" >> OUT
		print "tcp-concurrent: true" >> OUT
		print "mode: rule" >> OUT
		print "log-level: error" >> OUT
		print "ipv6: false" >> OUT
		print "external-controller: 0.0.0.0:9090" >> OUT
		print "external-ui: ./ui" >> OUT
		print "unified-delay: true" >> OUT
		print "profile:" >> OUT
		print "  store-selected: true" >> OUT
		print "  store-fake-ip: true" >> OUT
		print "" >> OUT
		print "proxy-groups:" >> OUT
		print "  - name: GLOBAL" >> OUT
		print "    type: select" >> OUT
		print "    proxies:" >> OUT
		print "      - WARP" >> OUT
		print "      - DIRECT" >> OUT
		print "" >> OUT
		print "rules:" >> OUT
		print "  - \"MATCH,GLOBAL\"" >> OUT
		print "" >> OUT
		print "proxies:" >> OUT
		print "  - name: WARP" >> OUT
		print "    type: wireguard" >> OUT
		print "    server: " host >> OUT
		if(port!="") print "    port: " port >> OUT
		print "    private-key: " yaml_quote(priv) >> OUT
		print "    udp: true" >> OUT
		if(ip!="") print "    ip: " ip >> OUT
		if(ipv6!="") print "    ipv6: " ipv6 >> OUT
		print "    public-key: " yaml_quote(pub) >> OUT
		if(psk!="") print "    pre-shared-key: " yaml_quote(psk) >> OUT
		print "    allowed-ips:" >> OUT
		printf "%s", allowed_block >> OUT
		if(mtu!="") print "    mtu: " mtu >> OUT
		if(keep!="") print "    persistent-keepalive: " keep >> OUT
		if(s1!="" || s2!="" || jc!="" || jmin!="" || jmax!="" || h1!="" || h2!="" || h3!="" || h4!="" || i1!=""){
			print "    amnezia-wg-option:" >> OUT
			if(s1!="") print "      s1: " s1 >> OUT
			if(s2!="") print "      s2: " s2 >> OUT
			if(jc!="") print "      jc: " jc >> OUT
			if(jmin!="") print "      jmin: " jmin >> OUT
			if(jmax!="") print "      jmax: " jmax >> OUT
			if(h1!="") print "      h1: " h1 >> OUT
			if(h2!="") print "      h2: " h2 >> OUT
			if(h3!="") print "      h3: " h3 >> OUT
			if(h4!="") print "      h4: " h4 >> OUT
			if(i1!="") print "      i1: " yaml_quote(i1) >> OUT
		}
	}' "$MIXOMO_WARP_CONF" 2>"$tmp.err"
	if [ -s "$tmp.err" ]; then
		echo "ОШИБКА: в WARP.conf отсутствуют обязательные поля"
		rm -f "$tmp" "$tmp.err"
		return 1
	fi
	rm -f "$tmp.err"
	cp "$MIHOMO_CONF" "$MIHOMO_CONF.bak" 2>/dev/null
	chmod 600 "$tmp"
	mv -f "$tmp" "$MIHOMO_CONF"
	/etc/init.d/mihomo restart >/dev/null 2>&1
	echo "==> Готово, WARP интегрирован в Mihomo"
}

mixomo_warp_integrate_action() {
	job_start mixomo_warp_integrate do_mixomo_warp_integrate
}


BYEDPI_REPO="DPITrickster/ByeDPI-OpenWrt"

_bytetube_fetch() { # URL OUT
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 15 --max-time 90 -o "$2" "$1"
	else
		wget -q -T 20 -O "$2" "$1"
	fi
}

health() {
	local zr=0 zr2=0 bt=0 tg=0 mx=0 doh=0 hs=0 inst=0 bad=0 out="" rb=0
	if [ -f /etc/init.d/zapret ]; then zr=2; pgrep -f "/opt/zapret/" >/dev/null 2>&1 && zr=1; fi
	if [ -f /etc/init.d/zapret2 ]; then zr2=2; /etc/init.d/zapret2 status >/dev/null 2>&1 && zr2=1; fi
	if [ -x /usr/bin/bytetube ]; then
		bt=2
		out=$(/usr/bin/bytetube status 2>/dev/null)
		case "$out" in *'"enabled":true'*'"byedpi":true'*'"hev":true'*) bt=1 ;; esac
	fi
	if [ -f /etc/init.d/tg-ws-proxy ]; then inst=1; pidof tg-ws-proxy >/dev/null 2>&1 || bad=1; fi
	if [ -f "$TG_INIT_GO" ]; then inst=1; pidof tg-ws-proxy-go >/dev/null 2>&1 || bad=1; fi
	if [ -f "$TG_INIT_RS" ]; then inst=1; pidof tg-ws-proxy-rs >/dev/null 2>&1 || bad=1; fi
	if [ -x /etc/init.d/tgws ]; then inst=1; [ -n "$(tgws status 2>/dev/null)" ] || bad=1; fi
	if [ "$inst" = "1" ]; then tg=1; [ "$bad" = "1" ] && tg=2; fi
	if [ -x "$MIHOMO_BIN" ]; then
		mx=1
		pidof mihomo >/dev/null 2>&1 || mx=2
		if [ -x /etc/init.d/magitrickle ]; then /etc/init.d/magitrickle status >/dev/null 2>&1 || mx=2; fi
		if [ -x /etc/init.d/hev-socks5-tunnel ]; then /etc/init.d/hev-socks5-tunnel status >/dev/null 2>&1 || mx=2; fi
	fi
	if [ "$PKG" = "apk" ]; then apk info -e https-dns-proxy >/dev/null 2>&1 && doh=2
	else opkg list-installed 2>/dev/null | grep -q '^https-dns-proxy ' && doh=2; fi
	if [ "$doh" = "2" ]; then pidof https-dns-proxy >/dev/null 2>&1 && doh=1; fi
	out=$(hosts_status 2>/dev/null)
	case "$out" in *'"enabled":true'*|*'"geohide":"'[a-z]*) hs=1 ;; esac
	local sr=0 w
	if _st_installed; then
		if [ -f /etc/zm-steer/stopped ] || ! grep -qx 'steer-spec' /etc/zm-steer/owned 2>/dev/null || [ "$(_st_exit)" = none ]; then
			sr=5
		else
			sr=2
			if /etc/init.d/steer running >/dev/null 2>&1; then
				if [ "$(_st_exit)" = vpn ]; then
					# интерфейс поднят, но трафик не идёт — это поломка
					[ -d "/sys/class/net/$ST_VPN_OUT" ] && { _st_vpn_live; [ $? -ne 1 ] && sr=1; }
				else
					for w in $(awk '{print $1}' /etc/zm-steer/warp.up 2>/dev/null) zmwarp; do
						[ -d "/sys/class/net/$w" ] && { sr=1; break; }
					done
				fi
			fi
		fi
	fi
	local sx=""
	if _st_installed; then sx="$(_st_exit)"; [ "$sx" = warp ] && _st_warp_own && sx=own; fi
	printf '{"zapret":%s,"zapret2":%s,"bytetube":%s,"tg":%s,"mixomo":%s,"doh":%s,"hosts":%s,"steer":%s,"steer_off":%s,"steer_exit":"%s","awg":%s}\n' \
		"$zr" "$zr2" "$bt" "$tg" "$mx" "$doh" "$hs" "$sr" \
		"$([ -f /etc/zm-steer/stopped ] && echo true || echo false)" "$sx" "$(_awg_health)"
}

VERSIONS_CACHE="$ZM_STATE_DIR/versions.json"

_ver_norm() { printf '%s' "$1" | sed 's/^[vV]//; s/-r[0-9]*$//; s/[[:space:]]//g'; }
_ver_gh_latest() { # ВЛАДЕЛЕЦ/РЕПО
	curl -Ls --connect-timeout 5 --max-time 10 -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" 2>/dev/null |
		sed -n 's#.*/tag/##p' | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1
}

_ver_feed_latest() { # ПАКЕТ — версия в репозитории пакетов OpenWrt
	if [ "$PKG" = apk ]; then
		apk list "$1" 2>/dev/null | sed -n "s/^$1-\([0-9][^ ]*\) .*/\1/p" | head -n1
	else
		opkg list "$1" 2>/dev/null | awk -v p="$1" '$1 == p { v = $3 } END { print v }'
	fi
}

_ver_item() { # ИМЯ УСТАНОВЛЕННАЯ ПОСЛЕДНЯЯ
	local cur latest
	cur="$(_ver_norm "$2")"; latest="$(_ver_norm "$3")"
	[ -n "$cur" ] || return 0
	printf '{"name":"%s","installed":"%s","latest":"%s"}' "$(esc "$1")" "$(esc "$cur")" "$(esc "$latest")"
}
_jf() { jsonfilter -s "$1" -e "$2" 2>/dev/null; }

do_versions_refresh() {
	local out="" sep="" j it tmp="$VERSIONS_CACHE.tmp"
	add() { [ -n "$1" ] && { out="$out$sep$1"; sep=","; }; }
	j="$(zm_update_status)"
	if [ "$(_jf "$j" '@.newer')" = true ]; then
		add "$(_ver_item 'Zapret Manager' "$(_jf "$j" '@.current')" "$(_jf "$j" '@.latest')")"
	else
		add "$(_ver_item 'Zapret Manager' "$(_jf "$j" '@.current')" "$(_jf "$j" '@.current')")"
	fi
	if [ -f /etc/init.d/zapret ]; then
		j="$(status)"
		add "$(_ver_item Zapret "$(_jf "$j" '@.zapret_version')" "$(_zapret_latest_version)")"
	fi
	if [ -x "$MIHOMO_BIN" ] || [ -x /etc/init.d/magitrickle ] || [ -x /etc/init.d/hev-socks5-tunnel ]; then
		j="$(mixomo_status)"
		add "$(_ver_item Mihomo "$(_jf "$j" '@.mihomo_version')" "$(_jf "$j" '@.mihomo_latest')")"
		add "$(_ver_item MagiTrickle "$(_jf "$j" '@.magitrickle_version')" "$(_jf "$j" '@.magitrickle_latest')")"
		add "$(_ver_item hev-socks5-tunnel "$(_jf "$j" '@.hev_version')" "$(_ver_feed_latest hev-socks5-tunnel)")"
	fi
	j="$(tg_status)"
	add "$(_ver_item 'TG WS Proxy (Go, MTProto)' "$(_jf "$j" '@.mtproto_version')" "$(_jf "$j" '@.mtproto_latest')")"
	add "$(_ver_item 'TG WS Proxy (SOCKS5)' "$(_jf "$j" '@.socks5_version')" "$(_jf "$j" '@.socks5_latest')")"
	add "$(_ver_item 'TG WS Proxy (Rust)' "$(_jf "$j" '@.rust_version')" "$(_jf "$j" '@.rust_latest')")"
	if [ -x /etc/init.d/tgws ]; then
		j="$(tgws_status)"
		add "$(_ver_item sTGWS "$(_jf "$j" '@.version')" "$(_jf "$j" '@.latest')")"
	fi
	command -v steer >/dev/null 2>&1 && add "$(_ver_item 'Движок Steer' "$(_st_steer_ver)" "$(_st_latest_ver)")"
	local feeds=0 v
	[ -n "$(_ver_feed_latest busybox)" ] || { $UPDATE >/dev/null 2>&1; }
	if [ -f /etc/init.d/zapret2 ]; then
		v="$(_awg_pkg_ver zapret2)"
		add "$(_ver_item Zapret2 "$v" "$(_ver_feed_latest zapret2)")"
	fi
	if [ -x /usr/bin/ciadpi ] || [ -x /usr/bin/byedpi ]; then
		add "$(_ver_item ByeDPI "$(_awg_pkg_ver byedpi)" "$(_ver_gh_latest "$BYEDPI_REPO")")"
	fi
	if ! { [ -x "$MIHOMO_BIN" ] || [ -x /etc/init.d/magitrickle ]; } && _pkg_is_installed hev-socks5-tunnel; then
		add "$(_ver_item hev-socks5-tunnel "$(_awg_pkg_ver hev-socks5-tunnel)" "$(_ver_feed_latest hev-socks5-tunnel)")"
	fi
	if _awg_installed; then
		add "$(_ver_item AmneziaWG "$(_awg_pkg_ver amneziawg-tools)" '')"
	fi
	if _pkg_is_installed https-dns-proxy; then
		add "$(_ver_item 'DNS over HTTPS (https-dns-proxy)' "$(_awg_pkg_ver https-dns-proxy)" "$(_ver_feed_latest https-dns-proxy)")"
	fi
	printf '{"ts":"%s","items":[%s]}\n' "$(date '+%d.%m %H:%M')" "$out" > "$tmp" && mv "$tmp" "$VERSIONS_CACHE"
	echo "==> Версии проверены"
}

versions_status() { # [refresh]
	local busy=false
	local age=180
	[ "$1" = auto ] && age=2
	if [ "$1" = refresh ] || [ ! -s "$VERSIONS_CACHE" ] || [ -n "$(find "$VERSIONS_CACHE" -mmin +$age 2>/dev/null)" ]; then
		_job_running versions || ZM_VER_FORCE=1 job_start versions do_versions_refresh >/dev/null
	fi
	_job_running versions && busy=true
	if [ -s "$VERSIONS_CACHE" ]; then
		sed "s/}\$/,\"pending\":$busy}/" "$VERSIONS_CACHE"
	else
		printf '{"ts":"","items":[],"pending":%s}\n' "$busy"
	fi
}

bytetube_installed() {
	if [ -x /usr/bin/bytetube ]; then
		printf '{"installed":true}\n'
	else
		printf '{"installed":false}\n'
	fi
}

_bytetube_ensure_dnsmasq_full() {
	if dnsmasq --version 2>/dev/null | grep -Eq '(^| )nftset( |$)'; then
		echo "==> dnsmasq с поддержкой nftset уже установлен"
		return 0
	fi
	echo "==> Заменяю dnsmasq на dnsmasq-full (нужен nftset)"
	cp /etc/config/dhcp /tmp/dhcp.ytb.bak 2>/dev/null
	_pkg_is_installed dnsmasq && $DELETE dnsmasq >&2
	_pkg_is_installed dnsmasq-dhcpv6 && $DELETE dnsmasq-dhcpv6 >&2
	rm -f /tmp/resolv.conf
	if grep -qs '^nameserver' /tmp/resolv.conf.d/resolv.conf.auto 2>/dev/null; then
		cp /tmp/resolv.conf.d/resolv.conf.auto /tmp/resolv.conf
	else
		printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /tmp/resolv.conf
	fi
	if ! $INSTALL dnsmasq-full >&2; then
		echo "!! не удалось поставить dnsmasq-full, возвращаю обычный dnsmasq"
		rm -f /tmp/resolv.conf
		if grep -qs '^nameserver' /tmp/resolv.conf.d/resolv.conf.auto 2>/dev/null; then
			cp /tmp/resolv.conf.d/resolv.conf.auto /tmp/resolv.conf
		else
			printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /tmp/resolv.conf
		fi
		$INSTALL dnsmasq >&2
		[ -f /etc/config/dhcp ] || cp /tmp/dhcp.ytb.bak /etc/config/dhcp 2>/dev/null
		/etc/init.d/dnsmasq restart >/dev/null 2>&1
		echo "ОШИБКА: dnsmasq-full не установлен"
		return 1
	fi
	[ -f /etc/config/dhcp ] || cp /tmp/dhcp.ytb.bak /etc/config/dhcp 2>/dev/null
	/etc/init.d/dnsmasq enable >/dev/null 2>&1
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
}

_bytetube_install_byedpi() {
	local arch rel_mm url json cands f
	if [ -x /usr/bin/ciadpi ]; then
		echo "==> ByeDPI уже установлен"
		return 0
	fi
	. /etc/openwrt_release
	arch="$DISTRIB_ARCH"
	rel_mm=$(echo "$DISTRIB_RELEASE" | cut -d. -f1,2)
	echo "==> Ищу пакет byedpi ($arch, .$RAZ) в $BYEDPI_REPO"
	json=$(_bytetube_fetch "https://api.github.com/repos/$BYEDPI_REPO/releases?per_page=40" - 2>/dev/null)
	cands=$(printf '%s\n' "$json" \
		| grep -o '"browser_download_url": *"[^"]*"' \
		| sed 's/^[^:]*: *"//; s/"$//' \
		| grep -E "/byedpi_[^/]*_${arch}\.${RAZ}\$")
	url=$(printf '%s\n' "$cands" | grep -F "$rel_mm" | head -n 1)
	[ -n "$url" ] || url=$(printf '%s\n' "$cands" | head -n 1)
	if [ -z "$url" ]; then
		echo "ОШИБКА: не нашёл пакет byedpi для $arch (.$RAZ)"
		return 1
	fi
	echo "==> Скачиваю $url"
	mkdir -p /tmp/ytb-dl
	f="/tmp/ytb-dl/$(basename "$url")"
	_bytetube_fetch "$url" "$f" || { echo "ОШИБКА: не удалось скачать byedpi"; return 1; }
	if [ "$PKG" = apk ]; then apk add --allow-untrusted "$f"; else opkg install "$f"; fi \
		|| { echo "ОШИБКА: не удалось установить byedpi"; return 1; }
	NEW_BYEDPI=1
}

_bytetube_install_payload() {
	mkdir -p /etc/config
	[ -f /etc/config/bytetube ] || cat > /etc/config/bytetube <<'YTB_FILE_END_7f3a9c'
config bytetube 'main'
	option enabled '1'
	option byedpi_port '1088'
	option byedpi_opts '-d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -S -a1'
	option ipv6 '1'
	option quic 'block'
	option default_domains '1'
YTB_FILE_END_7f3a9c
	chmod 644 /etc/config/bytetube
	mkdir -p /etc/hotplug.d/firewall
	cat > /etc/hotplug.d/firewall/90-bytetube <<'YTB_FILE_END_7f3a9c'
#!/bin/sh
[ -f /var/run/bytetube.started ] || exit 0
nft list table inet bytetube >/dev/null 2>&1 && exit 0
logger -t bytetube "таблица nft пропала после reload firewall — восстанавливаю"
/etc/init.d/bytetube restart >/dev/null 2>&1
exit 0
YTB_FILE_END_7f3a9c
	chmod 755 /etc/hotplug.d/firewall/90-bytetube
	mkdir -p /etc/init.d
	cat > /etc/init.d/bytetube <<'YTB_FILE_END_7f3a9c'
#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

NAME=bytetube
LIBEXEC=/usr/libexec/bytetube
RUNDIR=/var/etc/bytetube
DOMAINS_DEFAULT=/usr/share/bytetube/domains.list
STARTED_FLAG=/var/run/bytetube.started

. "$LIBEXEC/common.sh"

log() { logger -t "$NAME" "$*"; }
_echo() { echo "$1"; }

collect_domains() {
	local use_default
	config_get use_default main default_domains 1
	{
		[ "$use_default" = "1" ] && [ -f "$DOMAINS_DEFAULT" ] && cat "$DOMAINS_DEFAULT"
		config_list_foreach main domain _echo
	} | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
	  | tr 'A-Z' 'a-z' \
	  | grep -E '^[a-z0-9]([a-z0-9._-]*[a-z0-9])?$' \
	  | sort -u \
	  | awk '
		{ name[NR] = $0; have[$0] = 1 }
		END {
			for (i = 1; i <= NR; i++) {
				n = split(name[i], p, ".")
				suf = ""; redundant = 0
				for (j = n; j >= 2; j--) {
					suf = (suf == "") ? p[j] : p[j] "." suf
					if (suf in have) { redundant = 1; break }
				}
				if (!redundant) print name[i]
			}
		}'
}

dns_remove() {
	local d r=0
	for d in $(dnsmasq_confdirs); do
		[ -f "$d/bytetube.conf" ] && { rm -f "$d/bytetube.conf"; r=1; }
	done
	[ "$r" = 1 ] && /etc/init.d/dnsmasq restart >/dev/null 2>&1
	return 0
}

dns_apply() {
	local ipv6="$1" d domains suffix new r=0
	domains=$(collect_domains)
	if [ -z "$domains" ]; then
		dns_remove
		return 0
	fi
	suffix="4#inet#${NFT_TABLE}#yt4"
	[ "$ipv6" = "1" ] && suffix="$suffix,6#inet#${NFT_TABLE}#yt6"
	new=$(printf '%s\n' "$domains" | awk -v suffix="$suffix" -v max=800 '
		{
			if (cur != "" && length("nftset=/" cur "/" $0 "/" suffix) > max) {
				print "nftset=/" cur "/" suffix
				cur = ""
			}
			cur = (cur == "") ? $0 : cur "/" $0
		}
		END { if (cur != "") print "nftset=/" cur "/" suffix }')
	for d in $(dnsmasq_confdirs); do
		[ "$(cat "$d/bytetube.conf" 2>/dev/null)" = "$new" ] && continue
		mkdir -p "$d"
		printf '%s\n' "$new" > "$d/bytetube.conf"
		r=1
	done
	[ "$r" = 1 ] && /etc/init.d/dnsmasq restart >/dev/null 2>&1
	return 0
}

write_hev_conf() {
	local port="$1" ipv6="$2" f="$RUNDIR/hev.yml"
	{
		echo "tunnel:"
		echo "  name: $TUN"
		echo "  mtu: 1500"
		echo "  ipv4: 198.18.0.1"
		[ "$ipv6" = "1" ] && echo "  ipv6: 'fc00::1'"
		echo "  post-up-script: $LIBEXEC/route-up.sh"
		echo "socks5:"
		echo "  port: $port"
		echo "  address: 127.0.0.1"
		echo "  udp: 'udp'"
		echo "misc:"
		echo "  log-level: warn"
	} > "$f"
}

ensure_fw4_include() {
	command -v fw4 >/dev/null 2>&1 || { log "fw4 не найден — нужен OpenWrt 22.03+"; return 0; }
	nft list chain inet fw4 forward 2>/dev/null | grep -q "bytetube" && return 0
	[ -f /usr/share/nftables.d/chain-pre/forward/50-bytetube.nft ] || return 0
	log "перезагружаю firewall, чтобы подхватить правило forward"
	/etc/init.d/firewall reload >/dev/null 2>&1
}

start_service() {
	local enabled byedpi_port byedpi_opts ipv6 byedpi hev

	config_load "$NAME"
	config_get enabled main enabled 0
	if [ "$enabled" != "1" ]; then
		"$LIBEXEC/net.sh" purge
		dns_remove
		rm -f "$STARTED_FLAG"
		return 0
	fi

	config_get byedpi_port main byedpi_port 1088
	config_get byedpi_opts main byedpi_opts ""
	byedpi_opts=$(byedpi_opts_clean "$byedpi_opts")
	config_get ipv6 main ipv6 1
	[ -f /proc/net/if_inet6 ] || ipv6=0

	case "$byedpi_port" in
		''|*[!0-9]*) log "некорректный порт: $byedpi_port"; return 1 ;;
	esac

	byedpi=$(find_byedpi)
	hev=$(command -v hev-socks5-tunnel)
	[ -n "$byedpi" ] || { log "ciadpi не найден: установите пакет byedpi"; return 1; }
	[ -n "$hev" ] || { log "hev-socks5-tunnel не найден: установите пакет"; return 1; }
	dnsmasq_has_nftset || { log "dnsmasq без поддержки nftset: установите dnsmasq-full"; return 1; }
	[ -c /dev/net/tun ] || modprobe tun 2>/dev/null

	mkdir -p "$RUNDIR"
	write_hev_conf "$byedpi_port" "$ipv6"

	"$LIBEXEC/net.sh" up || { log "не удалось настроить nftables/маршрутизацию"; return 1; }
	ensure_fw4_include
	dns_apply "$ipv6"

	procd_open_instance byedpi
	procd_set_param command "$byedpi" -i 127.0.0.1 -p "$byedpi_port"
	set -f
	[ -n "$byedpi_opts" ] && procd_append_param command $byedpi_opts
	set +f
	procd_set_param respawn 3600 5 0
	procd_set_param stderr 1
	procd_close_instance

	procd_open_instance hev
	procd_set_param command "$hev" "$RUNDIR/hev.yml"
	procd_set_param respawn 3600 5 0
	procd_set_param stderr 1
	procd_close_instance

	touch "$STARTED_FLAG"
}

stop_service() {
	rm -f "$STARTED_FLAG"
	"$LIBEXEC/net.sh" down
}

service_triggers() {
	procd_add_reload_trigger "$NAME"
}
YTB_FILE_END_7f3a9c
	chmod 755 /etc/init.d/bytetube
	mkdir -p /lib/upgrade/keep.d
	cat > /lib/upgrade/keep.d/bytetube <<'YTB_FILE_END_7f3a9c'
/etc/bytetube/
YTB_FILE_END_7f3a9c
	chmod 644 /lib/upgrade/keep.d/bytetube
	mkdir -p /usr/bin
	cat > /usr/bin/bytetube <<'YTB_FILE_END_7f3a9c'
#!/bin/sh

. /lib/functions.sh
. /usr/libexec/bytetube/common.sh

svc_running() {
	ubus call service list '{"name":"bytetube"}' 2>/dev/null \
		| jsonfilter -e "@.bytetube.instances.$1.running" 2>/dev/null | grep -q true
}

count_set() {
	nft list set inet "$NFT_TABLE" "$1" 2>/dev/null | grep -o 'expires' | wc -l
}

b() { if [ "$1" = "1" ]; then echo true; else echo false; fi; }

case "$1" in
status)
	config_load bytetube
	config_get enabled main enabled 0
	config_get ipv6 main ipv6 1
	config_get quic main quic block

	v_byedpi=0; svc_running byedpi && v_byedpi=1
	v_hev=0;    svc_running hev && v_hev=1
	v_tun=0;    ip link show "$TUN" >/dev/null 2>&1 && v_tun=1
	v_nft=0;    nft list table inet "$NFT_TABLE" >/dev/null 2>&1 && v_nft=1
	v_rule=0;   ip rule show 2>/dev/null | grep -q "lookup $TABLE" && v_rule=1
	v_route=0;  ip route show table "$TABLE" 2>/dev/null | grep -q "$TUN" && v_route=1
	v_dns=0;    [ -s "$(dnsmasq_confdir)/bytetube.conf" ] && v_dns=1
	v_nftset=0; dnsmasq_has_nftset && v_nftset=1
	v_fw=0;     nft list chain inet fw4 forward 2>/dev/null | grep -q bytetube && v_fw=1
	v_bin=0;    { [ -x /usr/bin/ciadpi ] || [ -x /usr/bin/byedpi ]; } && [ -x /usr/bin/hev-socks5-tunnel ] && v_bin=1

	printf '{"enabled":%s,"byedpi":%s,"hev":%s,"tun":%s,"nft":%s,"rule":%s,"route":%s,"dns":%s,"dnsmasq_nftset":%s,"fw":%s,"binaries":%s,"ipv6":%s,"quic":"%s","ips4":%s,"ips6":%s}\n' \
		"$(b "$enabled")" "$(b $v_byedpi)" "$(b $v_hev)" "$(b $v_tun)" "$(b $v_nft)" \
		"$(b $v_rule)" "$(b $v_route)" "$(b $v_dns)" "$(b $v_nftset)" "$(b $v_fw)" "$(b $v_bin)" \
		"$(b "$ipv6")" "$quic" "$(count_set yt4)" "$(count_set yt6)"
	;;
flush)
	nft flush set inet "$NFT_TABLE" yt4 2>/dev/null
	nft flush set inet "$NFT_TABLE" yt6 2>/dev/null
	echo "наборы очищены"
	;;
list)
	nft list set inet "$NFT_TABLE" yt4 2>/dev/null
	nft list set inet "$NFT_TABLE" yt6 2>/dev/null
	;;
diag)
	arg="$2"; secs="${3:-20}"
	LEASES="${YTB_LEASES:-/tmp/dhcp.leases}"
	CT="${YTB_CT:-/proc/net/nf_conntrack}"
	case "$secs" in ''|*[!0-9]*) secs=20 ;; esac

	echo "=== YouTube Bypass: диагностика ==="
	"$0" status
	echo
	echo "--- счётчики nft (растут, когда трафик попадает под правила) ---"
	{ nft list chain inet "$NFT_TABLE" prerouting; nft list chain inet "$NFT_TABLE" forward; } 2>/dev/null \
		| grep counter | sed 's/^[[:space:]]*//'
	echo
	echo "--- какие DNS раздаются клиентам по DHCP ---"
	uci -q show dhcp | grep -E 'dhcp_option|\.dns=' || echo "своих dhcp_option/dns нет (клиенты получают DNS роутера)"
	echo "--- IPv6: маршрут по умолчанию: $(ip -6 route show default 2>/dev/null | head -n 1)"

	router_addrs=$(ip -o addr show 2>/dev/null | awk '{print $4}' | sed 's#/.*##' | tr '\n' ' ')
	lan_ip=$(uci -q get network.lan.ipaddr 2>/dev/null | awk '{ print $1 }' | sed 's#/.*##')
	[ -n "$lan_ip" ] && router_addrs="$router_addrs $lan_ip"

	list_leases() {
		echo "--- клиенты в DHCP ---"
		if [ -s "$LEASES" ]; then
			awk '{printf "  %-16s %-18s %s\n", $3, $2, $4}' "$LEASES"
		else
			echo "  (файл аренд пуст — смотрите IP в LuCI: Состояние → Обзор)"
		fi
	}

	if [ -z "$arg" ]; then
		echo
		list_leases
		echo
		echo "Запустите: bytetube diag <IP|MAC|имя телефона> [секунд, по умолчанию 20]"
		exit 0
	fi

	client="$arg"
	if ! printf '%s' "$arg" | grep -Eq '^[0-9]+(\.[0-9]+){3}$'; then
		found=$(grep -i -- "$arg" "$LEASES" 2>/dev/null)
		n=$(printf '%s\n' "$found" | grep -c .)
		if [ "$n" -eq 0 ]; then
			echo; echo "«$arg» не найден в DHCP-арендах."; list_leases; exit 0
		elif [ "$n" -gt 1 ]; then
			echo; echo "«$arg» подходит нескольким клиентам — уточните:"; list_leases; exit 0
		fi
		client=$(printf '%s\n' "$found" | awk '{print $3}')
	fi
	case " $router_addrs " in
		*" $client "*)
			echo
			echo "$client — это адрес самого РОУТЕРА. Нужен IP телефона:"
			list_leases
			exit 0 ;;
	esac

	mac=$(ip neigh show 2>/dev/null | awk -v ip="$client" '$1==ip {for(i=1;i<=NF;i++) if($i=="lladdr") print $(i+1)}' | head -n 1)
	ips="$client"
	[ -n "$mac" ] && ips="$ips $(ip -6 neigh show 2>/dev/null | awk -v m="$mac" 'tolower($0) ~ tolower(m) {print $1}' | grep -v '^fe80' | tr '\n' ' ')"
	echo
	echo "=== клиент: $ips (MAC: ${mac:-не найден}) ==="
	echo ">>> Собираю данные ${secs} с. ОТКРОЙТЕ YouTube НА ТЕЛЕФОНЕ (перезапустите приложение / обновите страницу) <<<"

	raw="/tmp/ytb-ct.$$"; out="/tmp/ytb-diag.$$"; ins="/tmp/ytb-ins.$$"
	: > "$raw"; : > "$ins"
	i=0
	while [ "$i" -lt "$secs" ]; do
		cat "$CT" >> "$raw" 2>/dev/null
		i=$((i + 1))
		[ "$i" -lt "$secs" ] && sleep 1
	done

	awk -v ips=" $ips " '
	{
		proto=$3; src=""; dst=""; sport=""; dport=""; mark=0
		for (i=1;i<=NF;i++) {
			if (src=="" && $i ~ /^src=/) src=substr($i,5)
			else if (dst=="" && $i ~ /^dst=/) dst=substr($i,5)
			else if (sport=="" && $i ~ /^sport=/) sport=substr($i,7)
			else if (dport=="" && $i ~ /^dport=/) dport=substr($i,7)
			else if ($i ~ /^mark=/) mark=substr($i,6)+0
		}
		if (index(ips, " " src " ") == 0) next
		key=proto " " src " " sport " " dst " " dport
		if (!(key in P)) { P[key]=proto; D[key]=dst; Q[key]=dport; M[key]=0 }
		if (int(mark/65536)%2==1) M[key]=1
	}
	END {
		for (k in P) {
			if (Q[k]=="53" || Q[k]=="853") c["DNS " P[k] " " D[k] ":" Q[k]]++
			else if (Q[k]=="443") c["443 " P[k] " " (M[k] ? "tunnel" : "direct") " " D[k]]++
		}
		for (k in c) print k, c[k]
	}' "$raw" 2>/dev/null | sort > "$out"

	echo
	echo "--- DNS-запросы клиента (куда он реально их шлёт) ---"
	dns_ok=0; dns_bad=0
	if grep -q '^DNS' "$out"; then
		while read -r _ proto target n; do
			host="${target%:*}"; port="${target##*:}"
			if [ "$port" = "853" ]; then
				who="DNS-over-TLS (Частный DNS) — МИМО роутера"; dns_bad=1
			elif case " $router_addrs " in *" $host "*) true ;; *) false ;; esac; then
				who="роутер (ок)"; dns_ok=1
			else
				who="НЕ роутер — набор для этого клиента не заполнится"; dns_bad=1
			fi
			echo "  $proto $target x$n — $who"
		done <<EOF_DNS
$(grep '^DNS' "$out")
EOF_DNS
	else
		echo "  DNS-запросов не было (клиент мог отвечать из кэша или использует DoH по :443)"
	fi

	echo "--- соединения клиента на :443 ---"
	tcp_t=$(awk '$1=="443" && $2=="tcp" && $3=="tunnel" {s+=$NF} END{print s+0}' "$out")
	tcp_d=$(awk '$1=="443" && $2=="tcp" && $3=="direct" {s+=$NF} END{print s+0}' "$out")
	udp_n=$(awk '$1=="443" && $2=="udp" {s+=$NF} END{print s+0}' "$out")
	echo "  tcp: через туннель — $tcp_t, напрямую — $tcp_d;  udp/443 (QUIC): $udp_n"

	echo "--- топ прямых TCP/443 (нет ли среди них YouTube/Google?) ---"
	grep '^443 tcp direct' "$out" | awk '{printf "%09d %s\n", 999999999-$NF, $0}' | sort | head -n 8 | cut -d' ' -f2- | while read -r _ _ _ dst n; do
		fam=yt4; case "$dst" in *:*) fam=yt6 ;; esac
		if nft get element inet "$NFT_TABLE" "$fam" "{ $dst }" >/dev/null 2>&1; then
			echo "  $dst x$n — в наборе, но трафик не помечен" | tee -a "$ins"
		else
			echo "  $dst x$n — не в наборе"
		fi
	done
	in_set=$(grep -c . "$ins")

	echo
	found_any=0
	if [ "$dns_bad" -eq 1 ]; then
		found_any=1
		if [ "$dns_ok" -eq 0 ]; then
			echo "ВЫВОД: телефон шлёт DNS мимо роутера (Частный DNS / DoT / внешний DNS) — набор не заполняется, YouTube идёт напрямую."
		else
			echo "ВЫВОД: часть DNS-запросов телефона идёт мимо роутера (Частный DNS / DoT / внешний DNS) — для таких имён набор не заполнится."
		fi
		echo "       Отключите «Частный DNS» и «Безопасный DNS» в Chrome, уберите статический DNS/VPN/AdGuard и переподключите Wi-Fi."
	fi
	if [ "$in_set" -gt 0 ]; then
		found_any=1
		echo "ВЫВОД: есть соединения на IP из набора, но без метки — пришлите этот вывод целиком."
	fi
	if [ "$tcp_t" -gt 0 ]; then
		found_any=1
		echo "ИНФО: часть трафика YouTube от телефона идёт через туннель — маршрутизация работает."
		[ "$dns_bad" -eq 0 ] && [ "$in_set" -eq 0 ] && \
			echo "      Если видео всё равно не грузится — стратегия ByeDPI (вкладка «Тест стратегий») или домены, которых нет в списке."
	fi
	if [ "$tcp_t" -eq 0 ] && [ "$tcp_d" -eq 0 ] && [ "$dns_ok" -eq 0 ] && [ "$dns_bad" -eq 0 ]; then
		found_any=1
		echo "ВЫВОД: от этого клиента не было ни DNS, ни :443-трафика. Проверьте IP/MAC, что телефон в этой сети, и откройте YouTube во время сбора."
	fi
	[ "$found_any" -eq 1 ] || echo "ВЫВОД: однозначно определить не удалось — пришлите этот вывод целиком."
	rm -f "$raw" "$out" "$ins"
	;;
test)
	shift
	exec /usr/libexec/bytetube/test.sh "$@"
	;;
set-strategy)
	opts="$2"
	if [ -z "$opts" ] || [ "$(printf '%s' "$opts" | wc -l)" -gt 0 ]; then
		echo '{"error":"пустая или многострочная стратегия"}'
		exit 0
	fi
	uci set bytetube.main.byedpi_opts="$opts" && uci commit bytetube
	/etc/init.d/bytetube restart >/dev/null 2>&1
	echo '{"ok":true}'
	;;
*)
	echo "usage: bytetube status|flush|list|diag|test|set-strategy" >&2
	exit 1
	;;
esac
YTB_FILE_END_7f3a9c
	chmod 755 /usr/bin/bytetube
	mkdir -p /usr/libexec/bytetube
	cat > /usr/libexec/bytetube/common.sh <<'YTB_FILE_END_7f3a9c'
#!/bin/sh

TUN=ytb0            # имя TUN-интерфейса hev-socks5-tunnel
MARK=0x10000        # fwmark (один выделенный бит)
MASK=0x10000
TABLE=89            # таблица маршрутизации
PREF=8900           # приоритет ip rule
NFT_TABLE=bytetube

dnsmasq_confdirs() {
	local d
	d=$(sed -n 's/^conf-dir=\([^,]*\).*/\1/p' /var/etc/dnsmasq.conf.* 2>/dev/null | sort -u)
	[ -n "$d" ] || d=/tmp/dnsmasq.d
	echo "$d"
}
dnsmasq_confdir() { dnsmasq_confdirs | head -n 1; }

dnsmasq_has_nftset() {
	dnsmasq --version 2>/dev/null | grep -Eq '(^| )nftset( |$)'
}

find_byedpi() {
	local b
	for b in /usr/bin/ciadpi /usr/bin/byedpi; do
		[ -x "$b" ] && { echo "$b"; return 0; }
	done
	command -v ciadpi
}

byedpi_opts_clean() {
	printf '%s' "$1" | tr -d "\"'" | tr '\n\r\t' '   ' | sed 's/^ *//; s/ *$//; s/  */ /g'
}
YTB_FILE_END_7f3a9c
	chmod 755 /usr/libexec/bytetube/common.sh
	cat > /usr/libexec/bytetube/net.sh <<'YTB_FILE_END_7f3a9c'
#!/bin/sh

. /lib/functions.sh
. /usr/libexec/bytetube/common.sh

config_load bytetube
config_get IPV6 main ipv6 1
config_get QUIC main quic block
[ -f /proc/net/if_inet6 ] || IPV6=0

rules_del() {
	while ip rule del pref "$PREF" 2>/dev/null; do :; done
	while ip -6 rule del pref "$PREF" 2>/dev/null; do :; done
	ip route del default dev "$TUN" table "$TABLE" 2>/dev/null
	ip -6 route del default dev "$TUN" table "$TABLE" 2>/dev/null
}

set_mark_stmt="counter ct mark set ct mark | $MARK meta mark set meta mark | $MARK"

gen_ruleset() {
	cat <<NFT
table inet $NFT_TABLE {
	set yt4 {
		type ipv4_addr
		flags timeout
		timeout 12h
		size 65535
	}
	set yt6 {
		type ipv6_addr
		flags timeout
		timeout 12h
		size 65535
	}
	chain prerouting {
		type filter hook prerouting priority mangle; policy accept;
		iifname "$TUN" return
		ct mark & $MASK == $MARK meta mark set meta mark | $MARK return
		meta l4proto tcp ip daddr @yt4 $set_mark_stmt
NFT
	[ "$IPV6" = "1" ] && echo "		meta l4proto tcp ip6 daddr @yt6 $set_mark_stmt"
	if [ "$QUIC" = "proxy" ]; then
		echo "		udp dport 443 ip daddr @yt4 $set_mark_stmt"
		[ "$IPV6" = "1" ] && echo "		udp dport 443 ip6 daddr @yt6 $set_mark_stmt"
	fi
	echo "	}"
	if [ "$QUIC" != "proxy" ]; then
		cat <<NFT
	chain forward {
		type filter hook forward priority filter - 10; policy accept;
		udp dport 443 ip daddr @yt4 counter reject
		udp dport 443 ip6 daddr @yt6 counter reject
	}
NFT
	fi
	echo "}"
}

case "$1" in
up)
	rules_del
	nft delete table inet "$NFT_TABLE" 2>/dev/null
	gen_ruleset | nft -f - || exit 1
	ip rule add pref "$PREF" fwmark "$MARK/$MASK" lookup "$TABLE" || exit 1
	[ "$IPV6" = "1" ] && ip -6 rule add pref "$PREF" fwmark "$MARK/$MASK" lookup "$TABLE"
	ip link show "$TUN" >/dev/null 2>&1 && /usr/libexec/bytetube/route-up.sh "$TUN"
	exit 0
	;;
down)
	rules_del
	nft flush chain inet "$NFT_TABLE" prerouting 2>/dev/null
	nft flush chain inet "$NFT_TABLE" forward 2>/dev/null
	;;
purge)
	rules_del
	nft delete table inet "$NFT_TABLE" 2>/dev/null
	;;
*)
	echo "usage: $0 up|down|purge" >&2
	exit 1
	;;
esac
exit 0
YTB_FILE_END_7f3a9c
	chmod 755 /usr/libexec/bytetube/net.sh
	cat > /usr/libexec/bytetube/route-up.sh <<'YTB_FILE_END_7f3a9c'
#!/bin/sh

. /lib/functions.sh
. /usr/libexec/bytetube/common.sh

config_load bytetube
config_get IPV6 main ipv6 1
[ -f /proc/net/if_inet6 ] || IPV6=0

ip link set "$TUN" up 2>/dev/null
ip route replace default dev "$TUN" table "$TABLE"
[ "$IPV6" = "1" ] && ip -6 route replace default dev "$TUN" table "$TABLE"

echo 2 > "/proc/sys/net/ipv4/conf/$TUN/rp_filter" 2>/dev/null
exit 0
YTB_FILE_END_7f3a9c
	chmod 755 /usr/libexec/bytetube/route-up.sh
	cat > /usr/libexec/bytetube/test.sh <<'YTB_FILE_END_7f3a9c'
#!/bin/sh

. /lib/functions.sh
. /usr/libexec/bytetube/common.sh

TEST_DIR=/tmp/bytetube-test
PIDF="$TEST_DIR/job.pid"
LOGF="$TEST_DIR/job.log"
RES="$TEST_DIR/results.txt"
RAW="$TEST_DIR/results.raw"
STOP="$TEST_DIR/stop"
CPID="$TEST_DIR/ciadpi.pid"
USER_DIR=/etc/bytetube
STRATS_DEFAULT=/usr/share/bytetube/strategies.txt
DOMS_DEFAULT=/usr/share/bytetube/test-domains.txt
PORT_BASE=22000
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0'
TAB=$(printf '\t')

is_running() {
	[ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null
}

count_lines() { # файл -> число строк без пустых и комментариев
	sed 's/#.*//' "$1" 2>/dev/null | tr -d '\r' | grep -c '[^[:space:]]'
}

list_name() {
	case "$1" in
		strategies) echo strategies.txt ;;
		domains)    echo test-domains.txt ;;
	esac
}

list_file() {
	local nm
	nm=$(list_name "$1")
	if [ -n "$nm" ] && [ -s "$USER_DIR/$nm" ]; then
		echo "$USER_DIR/$nm"
	else
		case "$1" in
			strategies) echo "$STRATS_DEFAULT" ;;
			domains)    echo "$DOMS_DEFAULT" ;;
		esac
	fi
}

list_is_custom() { # kind
	local nm
	nm=$(list_name "$1")
	[ -n "$nm" ] && [ -s "$USER_DIR/$nm" ]
}

json_esc() {
	printf '%s' "$1" | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g'
}

norm_domains() {
	awk -v badf="$1" '
	{
		gsub(/\r/, "")
		line = $0
		sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
		if (line == "") next
		if (substr(line, 1, 1) == "#") { print line; next }
		sub(/#.*/, "", line)
		n = split(line, tok, /[ \t,;]+/)
		for (i = 1; i <= n; i++) {
			d = tolower(tok[i])
			if (d == "") continue
			sub(/^[a-z][a-z0-9+.-]*:\/\//, "", d)
			sub(/[\/?#].*$/, "", d)
			sub(/^\*?\./, "", d)
			if (d ~ /^[a-z0-9]([a-z0-9._-]*[a-z0-9])?$/ && index(d, ".") > 0) {
				if (!(d in seen)) { seen[d] = 1; print d }
			} else if (!bad) { bad = 1; print tok[i] > badf }
		}
	}'
}

norm_strategies() {
	awk '
	{
		gsub(/\r/, ""); gsub(/[ \t]+/, " ")
		line = $0; sub(/^ /, "", line); sub(/ $/, "", line)
		if (line == "") next
		if (substr(line, 1, 1) == "#") { print line; next }
		if (!(line in seen)) { seen[line] = 1; print line }
	}'
}

cmd_list() {
	local action="$1" kind="$2" text="$3" nm tmp bad n
	nm=$(list_name "$kind")
	if [ -z "$nm" ]; then
		echo '{"error":"неизвестный список"}'
		return 0
	fi
	case "$action" in
	get)
		local f
		f=$(list_file "$kind")
		[ -f "$f" ] && cat "$f"
		;;
	set)
		if is_running; then
			echo '{"error":"тест выполняется — остановите его перед сохранением списка"}'
			return 0
		fi
		mkdir -p "$TEST_DIR"
		tmp="$TEST_DIR/list.$$"; bad="$TEST_DIR/bad.$$"; : > "$bad"
		if [ "$kind" = "domains" ]; then
			printf '%s\n' "$text" | norm_domains "$bad" > "$tmp"
		else
			printf '%s\n' "$text" | norm_strategies > "$tmp"
		fi
		if [ -s "$bad" ]; then
			printf '{"error":"Некорректный домен: %s"}\n' "$(json_esc "$(head -n 1 "$bad")")"
			rm -f "$tmp" "$bad"
			return 0
		fi
		rm -f "$bad"
		n=$(count_lines "$tmp")
		if [ "${n:-0}" -le 0 ]; then
			echo '{"error":"список пуст — чтобы вернуть встроенный, нажмите «Сбросить к встроенному»"}'
			rm -f "$tmp"
			return 0
		fi
		mkdir -p "$USER_DIR"
		mv "$tmp" "$USER_DIR/$nm"
		printf '{"ok":true,"count":%s,"custom":true}\n' "$n"
		;;
	reset)
		if is_running; then
			echo '{"error":"тест выполняется — остановите его перед сбросом списка"}'
			return 0
		fi
		rm -f "$USER_DIR/$nm"
		printf '{"ok":true,"count":%s,"custom":false}\n' "$(count_lines "$(list_file "$kind")")"
		;;
	*)
		echo '{"error":"неизвестное действие"}'
		;;
	esac
	return 0
}

cmd_start() {
	if is_running; then
		echo '{"started":true,"already_running":true}'
		return 0
	fi
	command -v curl >/dev/null 2>&1 || { echo '{"error":"не установлен curl (apk add curl / opkg install curl)"}'; return 0; }
	[ -n "$(find_byedpi)" ] || { echo '{"error":"не найден ciadpi (пакет byedpi)"}'; return 0; }
	mkdir -p "$TEST_DIR"
	rm -f "$STOP"
	: > "$LOGF"
	( "$0" run >>"$LOGF" 2>&1; echo "__DONE__ $?" >>"$LOGF" ) >/dev/null 2>&1 </dev/null &
	echo $! > "$PIDF"
	echo '{"started":true}'
}

cmd_stop() {
	if ! is_running; then
		echo '{"error":"тест не запущен"}'
		return 0
	fi
	touch "$STOP"
	[ -f "$CPID" ] && kill "$(cat "$CPID" 2>/dev/null)" 2>/dev/null
	echo '{"ok":true}'
}

cmd_status() {
	local running=false has=false cu=false rc=""
	is_running && running=true
	[ -s "$RES" ] && has=true
	command -v curl >/dev/null 2>&1 && cu=true
	[ -f "$LOGF" ] && rc=$(grep '^__DONE__' "$LOGF" | tail -n 1 | awk '{print $2}')
	local sc=false dc=false
	list_is_custom strategies && sc=true
	list_is_custom domains && dc=true
	printf '{"running":%s,"has_results":%s,"curl":%s,"strategies":%s,"domains":%s,"strategies_custom":%s,"domains_custom":%s,"rc":"%s"}\n' \
		"$running" "$has" "$cu" "$(count_lines "$(list_file strategies)")" "$(count_lines "$(list_file domains)")" "$sc" "$dc" "$rc"
}

cmd_log() {
	[ -f "$LOGF" ] && tail -n 400 "$LOGF" | grep -v '^__DONE__'
	return 0
}

cmd_results() {
	[ -s "$RES" ] && cat "$RES"
	return 0
}

cmd_clear() {
	if is_running; then
		echo '{"error":"тест выполняется"}'
		return 0
	fi
	rm -f "$RES" "$RAW"
	echo '{"ok":true}'
}

check_url() {
	local entry="$1" okfile="$2" logfile="$3" proxy="$4" host url rc
	host="${entry%%|*}"
	url="${entry#*|}"
	if [ -n "$proxy" ]; then
		curl -4 -sL --socks5 "$proxy" --connect-timeout 4 --max-time 6 --speed-time 3 --speed-limit 1 \
			--range 0-65535 -A "$UA" -o /dev/null "$url" </dev/null >/dev/null 2>&1
	else
		curl -4 -sL --connect-timeout 4 --max-time 6 --speed-time 3 --speed-limit 1 \
			--range 0-65535 -A "$UA" -o /dev/null "$url" </dev/null >/dev/null 2>&1
	fi
	rc=$?
	if [ "$rc" -eq 0 ]; then
		echo 1 >> "$okfile"
		echo "[ OK ] $host" >> "$logfile"
	else
		echo "[FAIL] $host" >> "$logfile"
	fi
}

check_all() {
	local urls="$1" logfile="$2" proxy="$3" okf run=0 total=0 ok entry
	okf="$TEST_DIR/ok.$$"
	: > "$okf"
	: > "$logfile"
	while IFS= read -r entry; do
		[ -n "$entry" ] || continue
		[ -f "$STOP" ] && break
		total=$((total + 1))
		check_url "$entry" "$okf" "$logfile" "$proxy" &
		run=$((run + 1))
		if [ "$run" -ge "$PARALLEL" ]; then
			wait
			run=0
		fi
	done < "$urls"
	wait
	ok=$(wc -l < "$okf" | tr -d ' ')
	rm -f "$okf"
	echo "$ok $total"
}

cleanup() {
	[ -f "$CPID" ] && kill "$(cat "$CPID" 2>/dev/null)" 2>/dev/null
	rm -f "$CPID"
}

cmd_run() {
	local BIN cand keys urls line k opts port idx total ntot res ok tot cok ctot cpid skipped=0 best

	set -f      # параметры ciadpi раскрываем по пробелам без glob
	trap cleanup EXIT
	trap 'exit 130' INT TERM

	config_load bytetube
	config_get PARALLEL main test_parallel 8
	config_get CUR main byedpi_opts ""
	case "$PARALLEL" in ''|*[!0-9]*) PARALLEL=8 ;; esac
	[ "$PARALLEL" -ge 1 ] || PARALLEL=8

	BIN=$(find_byedpi)
	[ -n "$BIN" ] || { echo "ОШИБКА: ciadpi не найден"; exit 1; }
	command -v curl >/dev/null 2>&1 || { echo "ОШИБКА: не установлен curl"; exit 1; }

	mkdir -p "$TEST_DIR"
	rm -f "$STOP"
	cand="$TEST_DIR/candidates.txt"
	keys="$TEST_DIR/keys.txt"
	urls="$TEST_DIR/urls.txt"
	: > "$cand"; : > "$keys"; : > "$RAW"

	echo "==> Собираем стратегии для теста"
	{ printf '%s\n' "$CUR"; cat "$(list_file strategies)"; } | tr -d '\r' | while IFS= read -r line; do
		line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
		case "$line" in ''|'#'*) continue ;; esac
		k=$(byedpi_opts_clean "$line")
		[ -n "$k" ] || continue
		grep -qxF -- "$k" "$keys" && continue
		echo "$k" >> "$keys"
		echo "$line" >> "$cand"
	done
	total=$(wc -l < "$cand" | tr -d ' ')
	[ "$total" -gt 0 ] || { echo "ОШИБКА: нет стратегий для теста"; exit 1; }

	echo "==> Собираем список доменов"
	tr -d '\r' < "$(list_file domains)" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
		| grep -E '^[A-Za-z0-9._-]+$' | awk '!s[$0]++' | sed 's#.*#&|https://&/#' > "$urls"
	ntot=$(wc -l < "$urls" | tr -d ' ')
	[ "$ntot" -gt 0 ] || { echo "ОШИБКА: нет доменов для теста"; exit 1; }
	echo "==> Стратегий: $total, доменов: $ntot, параллельно: $PARALLEL"

	echo "==> Контрольный тест: без обхода"
	res=$(check_all "$urls" "$TEST_DIR/log_control.txt" "")
	if [ -f "$STOP" ]; then
		echo "==> Тест остановлен на контрольном замере, результатов нет"
		rm -f "$STOP"
		return 0
	fi
	cok=${res% *}; ctot=${res#* }
	echo "==> Результат: $cok/$ctot"

	idx=0
	while IFS= read -r line; do
		[ -f "$STOP" ] && break
		idx=$((idx + 1))
		opts=$(byedpi_opts_clean "$line")
		port=$((PORT_BASE + idx))
		echo "==> [$idx/$total] $line"
		"$BIN" -i 127.0.0.1 -p "$port" $opts >/dev/null 2>&1 </dev/null &
		cpid=$!
		echo "$cpid" > "$CPID"
		sleep 1
		if ! kill -0 "$cpid" 2>/dev/null; then
			echo "    пропуск: ciadpi не запустился с этими параметрами"
			skipped=$((skipped + 1))
			continue
		fi
		res=$(check_all "$urls" "$TEST_DIR/log_$idx.txt" "127.0.0.1:$port")
		kill "$cpid" 2>/dev/null
		wait "$cpid" 2>/dev/null
		rm -f "$CPID"
		if [ -f "$STOP" ]; then
			echo "    прервано — эта стратегия в результаты не входит"
			break
		fi
		ok=${res% *}; tot=${res#* }
		ok=${ok:-0}
		echo "    результат: $ok/$tot"
		printf '%06d\t%06d\t%s\t%s\t%s\n' "$((999999 - ok))" "$idx" "$ok" "$tot" "$line" >> "$RAW"
	done < "$cand"

	if [ -f "$STOP" ]; then
		echo "==> Тест остановлен пользователем, показываю то, что успели проверить"
		rm -f "$STOP"
	else
		echo "==> Тест завершён"
	fi
	[ "$skipped" -gt 0 ] && echo "==> Пропущено стратегий (не запустились): $skipped"

	{
		echo "Контрольный тест (без обхода) → $cok/$ctot"
		sort "$RAW" | while IFS="$TAB" read -r _ _ ok tot line; do
			echo "$line → $ok/$tot"
		done
	} > "$RES"

	echo "==> Основной сервис и его настройки не менялись."
	return 0
}

case "$1" in
	start)   cmd_start ;;
	stop)    cmd_stop ;;
	status)  cmd_status ;;
	log)     cmd_log ;;
	results) cmd_results ;;
	clear)   cmd_clear ;;
	list)    shift; cmd_list "$@" ;;
	run)     cmd_run ;;
	*) echo "usage: bytetube test start|stop|status|log|results|clear|list" >&2; exit 1 ;;
esac
exit 0
YTB_FILE_END_7f3a9c
	chmod 755 /usr/libexec/bytetube/test.sh
	mkdir -p /usr/share/nftables.d/chain-pre/forward
	cat > /usr/share/nftables.d/chain-pre/forward/50-bytetube.nft <<'YTB_FILE_END_7f3a9c'
oifname "ytb0" accept comment "bytetube"
YTB_FILE_END_7f3a9c
	chmod 644 /usr/share/nftables.d/chain-pre/forward/50-bytetube.nft
	mkdir -p /usr/share/bytetube
	cat > /usr/share/bytetube/domains.list <<'YTB_FILE_END_7f3a9c'
android.clients.google.com
beacons.gvt2.com
cdn.youtube.com
connectivitycheck.gstatic.com
fonts.googleapis.com
fonts.gstatic.com
ggpht.com
googleapis.com
googleplay.com
googleusercontent.com
googlevideo.com
gvt1.com
i.ytimg.com
i9.ytimg.com
jnn-pa.googleapis.com
kids.youtube.com
lh3.googleusercontent.com
m.youtube.com
manifest.googlevideo.com
music.youtube.com
nhacmp3youtube.com
play-fe.googleapis.com
play-games.googleusercontent.com
play-lh.googleusercontent.com
play.google.com
play.googleapis.com
prod-lt-playstoregatewayadapter-pa.googleapis.com
returnyoutubedislikeapi.com
s.ytimg.com
signaler-pa.youtube.com
studio.youtube.com
tv.youtube.com
wide-youtube.l.google.com
withyoutube.com
youtu.be
youtube-nocookie.com
youtube-ui.l.google.com
youtube.ae
youtube.al
youtube.am
youtube.at
youtube.az
youtube.ba
youtube.be
youtube.bg
youtube.bh
youtube.bo
youtube.by
youtube.ca
youtube.cat
youtube.ch
youtube.cl
youtube.co
youtube.co.ae
youtube.co.at
youtube.co.cr
youtube.co.hu
youtube.co.id
youtube.co.il
youtube.co.in
youtube.co.jp
youtube.co.ke
youtube.co.kr
youtube.co.ma
youtube.co.nz
youtube.co.th
youtube.co.tz
youtube.co.ug
youtube.co.uk
youtube.co.ve
youtube.co.za
youtube.co.zw
youtube.com
youtube.com.ar
youtube.com.au
youtube.com.az
youtube.com.bd
youtube.com.bh
youtube.com.bo
youtube.com.br
youtube.com.by
youtube.com.co
youtube.com.do
youtube.com.ec
youtube.com.ee
youtube.com.eg
youtube.com.es
youtube.com.gh
youtube.com.gr
youtube.com.gt
youtube.com.hk
youtube.com.hn
youtube.com.hr
youtube.com.jm
youtube.com.jo
youtube.com.kw
youtube.com.lb
youtube.com.lv
youtube.com.ly
youtube.com.mk
youtube.com.mt
youtube.com.mx
youtube.com.my
youtube.com.ng
youtube.com.ni
youtube.com.om
youtube.com.pa
youtube.com.pe
youtube.com.ph
youtube.com.pk
youtube.com.pt
youtube.com.py
youtube.com.qa
youtube.com.ro
youtube.com.sa
youtube.com.sg
youtube.com.sv
youtube.com.tn
youtube.com.tr
youtube.com.tw
youtube.com.ua
youtube.com.uy
youtube.com.ve
youtube.cr
youtube.cz
youtube.de
youtube.dk
youtube.ee
youtube.es
youtube.fi
youtube.fr
youtube.ge
youtube.googleapis.com
youtube.gr
youtube.gt
youtube.hk
youtube.hr
youtube.hu
youtube.ie
youtube.in
youtube.iq
youtube.is
youtube.it
youtube.jo
youtube.jp
youtube.kr
youtube.kz
youtube.la
youtube.lk
youtube.lt
youtube.lu
youtube.lv
youtube.ly
youtube.ma
youtube.md
youtube.me
youtube.mk
youtube.mn
youtube.mx
youtube.my
youtube.ng
youtube.ni
youtube.nl
youtube.no
youtube.pa
youtube.pe
youtube.ph
youtube.pk
youtube.pl
youtube.pr
youtube.pt
youtube.qa
youtube.ro
youtube.rs
youtube.ru
youtube.sa
youtube.se
youtube.sg
youtube.si
youtube.sk
youtube.sn
youtube.soy
youtube.sv
youtube.tn
youtube.tv
youtube.ua
youtube.ug
youtube.uy
youtube.vn
youtubeeducation.com
youtubeembeddedplayer.googleapis.com
youtubefanfest.com
youtubegaming.com
youtubego.co.id
youtubego.co.in
youtubego.com
youtubego.com.br
youtubego.id
youtubego.in
youtubei.googleapis.com
youtubei.youtube.com
youtubekids.com
youtubemobilesupport.com
yt-video-upload.l.google.com
yt.be
yt3.ggpht.com
yt3.googleusercontent.com
yt4.ggpht.com
ytimg.com
ytimg.l.google.com
yting.com
YTB_FILE_END_7f3a9c
	chmod 644 /usr/share/bytetube/domains.list
	cat > /usr/share/bytetube/strategies.txt <<'YTB_FILE_END_7f3a9c'
-f-200 -Qr -s3:5+sm -a1 -As -d1 -s4+sm -s8+sh -f-300 -d6+sh -a1 -At,r,s -o2 -f-30 -As -r5 -Mh -r6+sh -f-250 -s2:7+s -s3:6+sm -a1 -At,r,s -s3:5+sm -s6+s -s7:9+s -q30+sm -a1
-d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -S -a1
-q2 -s2 -s3+s -r3 -s4 -r4 -s5+s -r5+s -s6 -s7+s -r8 -s9+s -Qr -Mh,d,r -a1 -At,r -s2+s -r2 -d2 -s3 -r3 -r4 -s4 -d5+s -r5 -d6 -s7+s -d7 -a1
-o1 -d1 -a1 -At,r,s -s1 -d1 -s5+s -s10+s -s15+s -s20+s -r1+s -S -a1 -As -s1 -d1 -s5+s -s10+s -s15+s -s20+s -S -a1
-n "google.com" -Qr -f-204 -s1:5+sm -a1 -As -d1 -s3+s -s5+s -q7 -a1 -As -o2 -f-43 -a1 -As -r5 -Mh -s1:5+s -s3:7+sm -a1
-n "google.com" -Qr -f-205 -a1 -As -s1:3+sm -a1 -As -s5:8+sm -a1 -As -d3 -q7 -o2 -f-43 -f-85 -f-165 -r5 -Mh -a1
-d1+s -s50+s -a1 -As -f20 -r2+s -a1 -At -d2 -s1+s -s5+s -s10+s -s15+s -s25+s -s35+s -s50+s -s60+s -a1
-o1 -a1 -At,r,s -f-1 -a1 -At,r,s -d1:11+sm -S -a1 -At,r,s -n "google.com" -Qr -f1 -d1:11+sm -s1:11+sm -S -a1
-d1 -s1 -q1 -a1 -Ar -s5 -o1+s -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -a1
-f1+nme -t6 -a1 -As -n "google.com" -Qr -s1:6+sm -a1 -As -s5:12+sm -a1 -As -d3 -q7 -r6 -Mh -a1
-d1 -s1+s -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -a1
-d1 -s1+s -d1+s -s3+s -d6+s -s12+s -d14+s -s20+s -d24+s -s30+s -a1
-o1 -a1 -At,r,s -f-1 -a1 -Ar,s -o1 -a1 -At -r1+s -f-1 -t6 -a1
-d1 -s1+s -s3+s -s6+s -s9+s -s12+s -s15+s -s20+s -s30+s -a1
-d1 -d3+s -s6+s -d6+s -s7+s -d8+s -s10+s -a1 -t12 -At,s -r3
-f1 -t5 -n "google.com" -q3+h -Qr -f2 -q1 -r1+s -t15 -q1 -o2 -a1
-n "google.com" -d2:5:2+h -f-3 -r2+sm -o2 -o50+s -r2+s -f-4 -a1
-f-1 -Qr -s1+sm -d3+s -s5+sm -o2 -a1 -As -r1+s -d8+s -a1
-r-1+s -o20+sm -s3:7+sm -d5:3+sm -f300+s -Qr -f-1 -a1
-o2 -O4 -s1 -q1 -a1 -Ar -s5 -o1+s -f1+s -r20+s -a1
-o1 -r-5+se -a1 -At,r,s -d1 -n "google.com" -Qr -f-1 -a1
--fake -1 --ttl 8 --split 1+s --disorder 3+s -a1
-n "google.com" -Qr -f6+nr -d2 -d11 -f9+hm -o3 -t7 -a1
-r5+s -s25+s -a1 -At,r,s -s50 -r5+s -s50+s -a1
-d1 -d3+s -s6+s -d9+s -s20+s -d25+s -s30+s -a1
-d9+s -q20+s -s25+s -t5 -a1 -At,r,s -r1+h -a1
-q1+s -s29+s -s30+s -s14+s -o5+s -f-1 -S -a1
-d1 -s1+s -r1+s -e1 -m1 -o1+s -f-1 -t2 -a1
-d1 -o1 -a1 -Ar -o1 -a1 -At -f-1 -r1+s -a1
-d1 -s4 -d8 -s1+s -d5+s -s10+s -d20+s -a1
-f-1 -n "google.com" -Qr -s2+s -r3 -o20 -t4 -a1
-n "google.com" -Qr -d5+sm -f3+sm -o2 -t4 -a1
-o1 -a1 -Ar -q1 -a1 -At -f-1 -r1+s -a1
-q1 -a1 -Ar -o1 -a1 -At -f-1 -r1+s -a1
-s4+sn -r9+s -Qr -n "google.com" -S -a1
-o1 -d1 -r1+s -S -s1+s -d3+s -a1
-q1+s -s29+s -o5+s -f-1 -S -a1
-n "google.com" -Qr -m2 -f-1 -d7 -a1
-d1 -s1+s -r1+s -f-1 -t8 -a1
-o1 -a1 -An -f1+nme -t6 -a1
-n "google.com" -Qr -f-1 -r1+s -a1
-n "google.com" -Qr -d1:3 -f-1 -a1
-s1 -d3+s -a1 -At -r1+s -a1
-f-1 -t8 -n "google.com" -s1+s -a1
-n "google.com" -Qr -d1 -f-1 -a1
-f64+se -n "google.com" -t5 -a1
-o1 -a1 -At,r,s -d1 -a1
-d1+s -o2 -s5 -r5 -a1
-r8 -o2 -s7 -q4+s -a1
-o1 -f-1 -r-5+se -a1
-d6+s -q4+hm -o2 -a1
-s5+s -s35+s -m4 -a1
-f-1+sm -t7 -m2 -a1
-o1 -r-5+se -a1
-o1+s -d3+s -a1
-o1 -s4 -s6 -a1
-q1 -r25+s -a1
-d1 -s3+s -a1
-o3 -d7 -a1
-d7 -s2 -a1
-o1 -a1 -r-5+se
YTB_FILE_END_7f3a9c
	chmod 644 /usr/share/bytetube/strategies.txt
	cat > /usr/share/bytetube/test-domains.txt <<'YTB_FILE_END_7f3a9c'
youtu.be
youtube.com
i.ytimg.com
i9.ytimg.com
yt3.ggpht.com
yt4.ggpht.com
googleapis.com
jnn-pa.googleapis.com
googleusercontent.com
signaler-pa.youtube.com
youtubei.googleapis.com
manifest.googlevideo.com
yt3.googleusercontent.com

rr1---sn-4axm-n8vs.googlevideo.com
rr1---sn-gvnuxaxjvh-o8ge.googlevideo.com
rr1---sn-ug5onuxaxjvh-p3ul.googlevideo.com
rr1---sn-ug5onuxaxjvh-n8v6.googlevideo.com
rr4---sn-q4flrnsl.googlevideo.com
rr10---sn-gvnuxaxjvh-304z.googlevideo.com
rr14---sn-n8v7kn7r.googlevideo.com
rr16---sn-axq7sn76.googlevideo.com
rr1---sn-8ph2xajvh-5xge.googlevideo.com
rr1---sn-gvnuxaxjvh-5gie.googlevideo.com
rr12---sn-gvnuxaxjvh-bvwz.googlevideo.com
rr5---sn-n8v7knez.googlevideo.com
rr1---sn-u5uuxaxjvhg0-ocje.googlevideo.com
rr2---sn-q4fl6ndl.googlevideo.com
rr5---sn-gvnuxaxjvh-n8vk.googlevideo.com
rr4---sn-jvhnu5g-c35d.googlevideo.com
rr1---sn-q4fl6n6y.googlevideo.com
rr2---sn-hgn7ynek.googlevideo.com
rr1---sn-xguxaxjvh-gufl.googlevideo.com
YTB_FILE_END_7f3a9c
	chmod 644 /usr/share/bytetube/test-domains.txt
}

do_bytetube_install() {
	NEW_BYEDPI=0
	NEW_HEV=0
	command -v fw4 >/dev/null 2>&1 || { echo "ОШИБКА: нужен firewall4 (OpenWrt 22.03+); hev-socks5-tunnel в пакетах — с 24.10"; return 1; }
	command -v nft >/dev/null 2>&1 || { echo "ОШИБКА: не найден nft"; return 1; }
	if ip rule add pref 8999 fwmark 0x10000/0x10000 lookup 89 2>/dev/null; then
		ip rule del pref 8999 2>/dev/null
	else
		echo "ОШИБКА: ваш ip не поддерживает fwmark с маской. Установите ip-full (замените ip-tiny на ip-full) и попробуйте снова"
		return 1
	fi

	_ensure_deps
	echo "==> Обновляю списки пакетов"
	$UPDATE >&2

	if ! _pkg_is_installed kmod-tun; then
		echo "==> Ставлю kmod-tun"
		$INSTALL kmod-tun >&2 || { echo "ОШИБКА: kmod-tun не установлен"; return 1; }
	fi
	_bytetube_ensure_dnsmasq_full || return 1

	if ! _pkg_is_installed hev-socks5-tunnel; then
		echo "==> Ставлю hev-socks5-tunnel"
		$INSTALL hev-socks5-tunnel >&2 || { echo "ОШИБКА: hev-socks5-tunnel не найден в репозитории (есть в feeds OpenWrt 24.10+)"; return 1; }
		NEW_HEV=1
	fi
	_bytetube_install_byedpi || return 1

	for p in ca-bundle curl; do
		_pkg_is_installed "$p" || $INSTALL "$p" >&2 || echo "!! не удалось поставить $p — тест стратегий работать не будет (остальное — да)"
	done

	if [ "$NEW_BYEDPI" = 1 ] && [ -x /etc/init.d/byedpi ]; then
		/etc/init.d/byedpi stop >/dev/null 2>&1; /etc/init.d/byedpi disable >/dev/null 2>&1
	fi
	if [ "$NEW_HEV" = 1 ] && [ -x /etc/init.d/hev-socks5-tunnel ]; then
		/etc/init.d/hev-socks5-tunnel stop >/dev/null 2>&1; /etc/init.d/hev-socks5-tunnel disable >/dev/null 2>&1
	fi

	echo "==> Устанавливаю ByeTube (сервис)"
	_bytetube_install_payload
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
	/etc/init.d/rpcd reload >/dev/null 2>&1

	/etc/init.d/bytetube enable >/dev/null 2>&1
	echo "==> Запускаю"
	/etc/init.d/bytetube restart >/dev/null 2>&1
	sleep 4
	nslookup youtube.com 127.0.0.1 >/dev/null 2>&1
	sleep 1

	local ST
	ST=$(/usr/bin/bytetube status 2>/dev/null)
	_bt_show() {
		if [ "$(jsonfilter -s "$ST" -e "@.$1" 2>/dev/null)" = "true" ]; then
			echo "  [ok] $2"
		else
			echo "  [--] $2"
		fi
	}
	echo
	echo "==> Состояние:"
	_bt_show byedpi "ByeDPI (ciadpi)"
	_bt_show hev    "hev-socks5-tunnel"
	_bt_show tun    "интерфейс ytb0"
	_bt_show nft    "правила nftables"
	_bt_show route  "policy routing"
	_bt_show dns    "dnsmasq -> nftset"
	_bt_show fw     "firewall forward"
	echo "==> Готово, ByeTube установлен"
}

do_bytetube_uninstall() {
	echo "==> Останавливаю и удаляю ByeTube"
	[ -x /usr/bin/bytetube ] && /usr/bin/bytetube test stop >/dev/null 2>&1
	if [ -x /etc/init.d/bytetube ]; then
		/etc/init.d/bytetube stop >/dev/null 2>&1
		/etc/init.d/bytetube disable >/dev/null 2>&1
	fi
	if [ -x /usr/libexec/bytetube/net.sh ]; then
		/usr/libexec/bytetube/net.sh purge >/dev/null 2>&1
		. /usr/libexec/bytetube/common.sh
		for d in $(dnsmasq_confdirs 2>/dev/null || dnsmasq_confdir); do rm -f "$d/bytetube.conf"; done
	fi
	rm -rf /etc/config/bytetube /etc/init.d/bytetube /etc/hotplug.d/firewall/90-bytetube \
		/usr/bin/bytetube /usr/libexec/bytetube /usr/share/bytetube \
		/usr/share/nftables.d/chain-pre/forward/50-bytetube.nft \
		/var/etc/bytetube /var/run/bytetube.started /tmp/bytetube-test \
		/etc/bytetube /lib/upgrade/keep.d/bytetube
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	/etc/init.d/firewall reload >/dev/null 2>&1
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
	/etc/init.d/rpcd reload >/dev/null 2>&1
	echo "==> Готово."
}

do_bytetube_purge() {
	do_bytetube_uninstall
	echo "==> Удаляю пакет byedpi"
	$DELETE byedpi >&2
	if [ -x "$MIHOMO_BIN" ] && [ -x /etc/init.d/magitrickle ]; then
		echo "==> hev-socks5-tunnel используется Mixomo — оставляю пакет"
	else
		echo "==> Удаляю пакет hev-socks5-tunnel"
		$DELETE hev-socks5-tunnel >&2
	fi
	echo "==> Готово."
}

bytetube_action() {
	local action="$1"
	case "$action" in
		install|update) job_start bytetube_install do_bytetube_install ;;
		remove)         job_start bytetube_remove do_bytetube_uninstall ;;
		purge)          job_start bytetube_remove do_bytetube_purge ;;
		*) echo '{"error":"неизвестное действие"}'; return 1 ;;
	esac
}


_doh_file="/etc/config/https-dns-proxy"

DOH_OFF_FLAG="/opt/zapret-manager-luci/doh_off"
_doh_pkg() {
	if [ "$PKG" = "apk" ]; then apk info -e https-dns-proxy >/dev/null 2>&1
	else opkg list-installed 2>/dev/null | grep -q '^https-dns-proxy '; fi
}
_doh_steer_active() { grep -qx 'steer-spec' /etc/zm-steer/owned 2>/dev/null && [ ! -f /etc/zm-steer/stopped ]; }

do_doh_install() {
	local installed
	installed=$(doh_status | grep -o '"installed":[a-z]*' | cut -d: -f2)
	if [ "$installed" = "true" ]; then
		echo "==> DNS over HTTPS уже установлен"
		return 0
	fi
	if _doh_pkg; then
		rm -f "$DOH_OFF_FLAG"
		echo "==> Пакет https-dns-proxy уже стоит — включаем службу"
		/etc/init.d/https-dns-proxy enable >/dev/null 2>&1
		echo "==> Готово — выберите провайдера ниже"
		return 0
	fi
	_ensure_deps
	echo "==> Обновляем список пакетов"
	$UPDATE >&2
	echo "==> Устанавливаем https-dns-proxy и luci-app-https-dns-proxy"
	$INSTALL https-dns-proxy luci-app-https-dns-proxy >&2 || { echo "ОШИБКА установки"; return 1; }
	echo "==> Готово, DNS over HTTPS установлен — выберите провайдера ниже"
}

do_doh_remove() {
	echo "==> Удаляем DNS over HTTPS"
	echo "==> Останавливаем службу — dnsmasq возвращается к прежним серверам"
	/etc/init.d/https-dns-proxy stop >/dev/null 2>&1
	/etc/init.d/https-dns-proxy disable >/dev/null 2>&1
	echo "==> Удаляем пакеты"
	$DELETE https-dns-proxy luci-app-https-dns-proxy >&2
	echo "==> Удаляем файлы конфигурации"
	rm -f /etc/config/https-dns-proxy /etc/init.d/https-dns-proxy "$DOH_OFF_FLAG"
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	echo "==> Готово, DNS over HTTPS удалён"
}

doh_remove() {
	job_start doh_remove do_doh_remove
}

doh_install() {
	job_start doh_install do_doh_install
}

_doh_provider_of() {
	case "$1" in
		https://cloudflare-dns.com/*|https://1.1.1.1/*|https://1.0.0.1/*) echo cloudflare ;;
		https://dns.google/*|https://8.8.8.8/*|https://8.8.4.4/*) echo google ;;
		https://dns.quad9.net/*) echo quad9 ;;
		https://xbox-dns.ru/*) echo xbox ;;
		https://eu.geohide.ru/*) echo geohide_eu ;;
		https://us.geohide.ru/*) echo geohide_us ;;
		https://geohide.ru/*|https://dns.geohide.ru*) echo geohide_ru ;;
		*) echo "" ;;
	esac
}

doh_status() {
	local installed="false" current="" running=false force=false list="" sep="" i url port prov n=0 provs=""
	_doh_pkg && [ ! -f "$DOH_OFF_FLAG" ] && installed="true"
	if [ -f "$_doh_file" ]; then
		i=0
		while url="$(uci -q get "https-dns-proxy.@https-dns-proxy[$i].resolver_url")"; do
			port="$(uci -q get "https-dns-proxy.@https-dns-proxy[$i].listen_port")"
			[ -n "$port" ] || port=$((5053 + i))
			prov="$(_doh_provider_of "$url")"
			list="$list$sep{\"url\":\"$(esc "$url")\",\"port\":\"$(esc "$port")\",\"provider\":\"$prov\"}"
			sep=","; n=$((n + 1)); provs="$prov"
			i=$((i + 1))
			[ "$i" -gt 16 ] && break
		done
		[ "$n" = 1 ] && current="$provs"
		[ "$(uci -q get https-dns-proxy.config.force_dns)" != "0" ] && force=true
	fi
	/etc/init.d/https-dns-proxy running >/dev/null 2>&1 && running=true
	printf '{"installed":%s,"current":"%s","running":%s,"force_dns":%s,"resolvers":[%s],"steer_active":%s}\n' \
		"$installed" "$(esc "$current")" "$running" "$force" "$list" \
		"$(_doh_steer_active && echo true || echo false)"
}

doh_set() {
	local provider="$1" url bootstrap="" n
	case "$provider" in
		cloudflare)  url="https://cloudflare-dns.com/dns-query"; bootstrap="1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001" ;;
		google)      url="https://dns.google/dns-query";         bootstrap="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844" ;;
		quad9)       url="https://dns.quad9.net/dns-query";      bootstrap="9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9" ;;
		xbox)        url="https://xbox-dns.ru/dns-query" ;;
		geohide_ru)  url="https://geohide.ru/dns-query" ;;
		geohide_eu)  url="https://eu.geohide.ru/dns-query" ;;
		geohide_us)  url="https://us.geohide.ru/dns-query" ;;
		*) echo '{"error":"неизвестный провайдер"}'; return 1 ;;
	esac
	local installed; installed=$(doh_status | grep -o '"installed":[a-z]*' | cut -d: -f2)
	if [ "$installed" != "true" ]; then
		echo '{"error":"DNS over HTTPS не установлен — сначала нажмите «Установить DNS over HTTPS»"}'
		return 1
	fi
	local force=1
	_doh_steer_active && force=0
	{
		echo "config main 'config'"
		echo "	option canary_domains_icloud '1'"
		echo "	option canary_domains_mozilla '1'"
		echo "	option dnsmasq_config_update '*'"
		echo "	option force_dns '$force'"
		echo "	option notrack_dns '1'"
		echo "	list force_dns_port '53'"
		echo "	list force_dns_port '853'"
		for n in $(_zm_lan_nets); do echo "	list force_dns_src_interface '$n'"; done
		echo "	option procd_trigger_wan6 '0'"
		echo "	option heartbeat_domain 'heartbeat.mossdef.org'"
		echo "	option heartbeat_sleep_timeout '10'"
		echo "	option heartbeat_wait_timeout '10'"
		echo "	option user 'nobody'"
		echo "	option group 'nogroup'"
		echo "	option listen_addr '127.0.0.1'"
		echo "	option force_ip_family 'auto'"
		echo ""
		echo "config https-dns-proxy"
		echo "	option resolver_url '$url'"
		[ -n "$bootstrap" ] && echo "	option bootstrap_dns '$bootstrap'"
		echo "	option listen_port '5053'"
	} > "$_doh_file"
	/etc/init.d/https-dns-proxy enable >/dev/null 2>&1
	/etc/init.d/https-dns-proxy reload >/dev/null 2>&1
	/etc/init.d/https-dns-proxy restart >/dev/null 2>&1
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	printf '{"ok":true,"provider":"%s"}\n' "$provider"
}



RB_SHARE="/usr/share/zm-redbtn"

_rb_say() { echo "==> $*"; }
_rb_warn() { echo "!! $*"; }
_rb_svc_ids() { grep -v '^#' "$RB_SHARE/services.conf" 2>/dev/null | cut -d'|' -f1 | grep .; }
_rb_svc_field() { grep "^$1|" "$RB_SHARE/services.conf" 2>/dev/null | head -n1 | cut -d'|' -f"$2"; }
_rb_svc_names() { local id; for id in $1; do printf '%s, ' "$(_rb_svc_field "$id" 2)"; done | sed 's/, $//'; }
_rb_routable() { [ "$1" = custom ] && [ -n "$(_rb_svc_field custom 1)" ] && return 0; [ -n "$(_rb_svc_field "$1" 3)$(_rb_svc_field "$1" 4)$(_rb_svc_field "$1" 8)" ]; }
_rb_in() { grep -qxF "$1" "$2" 2>/dev/null; }
_job_alive() { _job_running "$1"; }

_kill_match() { # ПОДСТРОКА
	local p
	for p in $(ps w | grep -F -- "$1" | grep -v -e grep -e "_kill_match" | awk '{print $1}'); do
		[ "$p" = "$$" ] || kill "$p" 2>/dev/null
	done
}

_rb_rpcd_ensure() {
	local i=0
	while [ "$i" -lt 3 ]; do
		ubus list zapret-manager >/dev/null 2>&1 && return 0
		/etc/init.d/rpcd reload >/dev/null 2>&1
		sleep 3
		i=$((i + 1))
	done
	ubus list zapret-manager >/dev/null 2>&1
}




ST_DIR="/etc/zm-steer"
ST_OWNED="$ST_DIR/owned"
ST_SEL="$ST_DIR/services"
ST_SKIP="$ST_DIR/skip"
ST_OFF="$ST_DIR/stopped"
ST_WARP_CONF="$ST_DIR/warp.conf"
ST_RUN="$JOBS_DIR/steer"
ST_STOP_FLAG="$ST_RUN/stop"
ST_PHASE_FILE="$ST_RUN/phase"
ST_WARP_IF="zmwarp"
ST_WARP_ZONE="zmwarp"
ST_STEER_VER="1.5.9"
ST_STEER_SPEC="/etc/steer/spec.json"
ST_STEER_URLS="https://github.com/xyzmean/steer/releases/download/v@VER@ https://gitlab.com/xyzmean/steer/-/raw/dist https://raw.githubusercontent.com/xyzmean/steer/dist"
ST_AWG_MIRRORS="${GH_MAIN}/2Grey/awg-openwrt/releases/download ${GH_MAIN}/Slava-Shchipunov/awg-openwrt/releases/download"
ST_AWG_MIRROR_FLAT="https://gitlab.com/xyzmean/brb/-/raw/main/deps/awg"
ST_CRON_TAG="# zm-steer"
ST_CRON_CMD="/etc/init.d/steer enabled && { for i in \$(awk '{print \$1}' /etc/zm-steer/warp.up 2>/dev/null); do ifup \$i; done; sleep 15; /etc/init.d/steer restart; }"
ST_WARP_N=3
ST_WARP_MAX=3                         # столько туннелей в автоматическом режиме: zmwarp, zmwarp2, zmwarp3
ST_OWN_IF="zmwarp4"                   # «Свой конфиг» — отдельный интерфейс; автоматические при этом не удаляются
ST_WARP_MODE="$ST_DIR/warp.mode"       # own — сейчас работает свой конфиг
ST_WARP_OWN="$ST_DIR/warp.own.conf"    # свой конфиг (он же — конфиг zmwarp4)
ST_WARP_OWN_KEEP="/etc/zm-warp-own.conf"
ST_WARP_UP_AUTO="$ST_DIR/warp.up.auto" # список автоматических туннелей, пока работает свой конфиг
# Туннель №1 — zmwarp в автоматическом режиме и zmwarp4 в режиме «Свой конфиг»
ST_WIF1="zmwarp"; ST_WCONF1="$ST_WARP_CONF"
_st_mode_vars() {
	if [ "$(cat "$ST_WARP_MODE" 2>/dev/null)" = own ]; then
		ST_WARP_N=1; ST_WIF1="$ST_OWN_IF"; ST_WCONF1="$ST_WARP_OWN"
	else
		ST_WARP_N="$ST_WARP_MAX"; ST_WIF1="zmwarp"; ST_WCONF1="$ST_DIR/warp.conf"
	fi
	ST_WARP_IF="$ST_WIF1"; ST_WARP_CONF="$ST_WCONF1"
}
_st_mode_vars
ST_WARP_UP="$ST_DIR/warp.up"          # поднятые туннели «интерфейс колония», лучший первым (_st_warp_order)
ST_WARP_GEO="$ST_DIR/warp.geo"
ST_RU_COLOS="DME SVX LED KJA REN OVB KZN AER VVO"
ST_DEFAULT_SEL=""

_st_phase() { printf '%s\n' "$1" > "$ST_PHASE_FILE"; }
_st_stopped() { [ -f "$ST_STOP_FLAG" ]; }
_st_own() { mkdir -p "$ST_DIR"; grep -qxF "$1" "$ST_OWNED" 2>/dev/null || echo "$1" >> "$ST_OWNED"; }
_st_owns() { grep -qxF "$1" "$ST_OWNED" 2>/dev/null; }
_st_running() { _job_alive steer; }
_st_installed() { command -v steer >/dev/null 2>&1 && { _st_owns "engine" || _st_owns "pkg steer" || _st_owns "net zmwarp" || _st_owns "net $ST_OWN_IF"; }; }
_st_warp_on() { _st_owns "net $ST_WARP_IF" && [ -s "$ST_WARP_CONF" ]; }
_st_warp_own() { [ "$(cat "$ST_WARP_MODE" 2>/dev/null)" = own ]; }
_st_ready() { _st_installed && [ ! -f "$ST_OFF" ] && [ -z "$(_st_blocker)" ]; }
_st_sel() { [ -s "$ST_SEL" ] || return 0; local id; for id in $(cat "$ST_SEL"); do _rb_routable "$id" || continue; [ "$id" = custom ] && [ ! -s "$ST_USER_DIR/custom.lst" ] && continue; echo "$id"; done; }

_st_migrate() {
	local old=/etc/zm-redbtn re='^(pkg (steer|kmod-amneziawg|amneziawg-tools|luci-proto-amneziawg)|net zmwarp|fw zmwarp|steer-spec)$' f id l
	grep -qE "$re" "$old/owned" 2>/dev/null || return 0
	mkdir -p "$ST_DIR"
	grep -E "$re" "$old/owned" | while read -r l; do _rb_in "$l" "$ST_OWNED" || echo "$l" >> "$ST_OWNED"; done
	sed -i -E "/$re/d" "$old/owned"
	for f in warp.conf warp.colo spec.before; do [ -f "$old/$f" ] && [ ! -f "$ST_DIR/$f" ] && mv "$old/$f" "$ST_DIR/$f"; done
	if [ ! -s "$ST_SEL" ]; then
		{
			grep '|warp$' "$old/services" 2>/dev/null | cut -d'|' -f1
			cat "$old/warp.pick" 2>/dev/null
		} | sort -u | while read -r id; do _rb_in "$id" "$old/warp.skip" || echo "$id"; done > "$ST_SEL"
	fi
	[ -s "$old/warp.skip" ] && [ ! -s "$ST_SKIP" ] && mv "$old/warp.skip" "$ST_SKIP"
	rm -f "$old/warp.pick" "$old/warp.skip"
	sed -i 's/# zm-autobypass$/# zm-steer/' "$CRON_FILE" 2>/dev/null
}
_st_migrate
mkdir -p "$ST_RUN" 2>/dev/null

_st_blocker() {
	if [ -x /etc/init.d/splify2 ] || ubus list splify2 >/dev/null 2>&1; then echo splify2; return; fi
	if _st_spec_foreign; then echo steer; return; fi
	echo ""
}

_st_spec_foreign() {
	[ -s "$ST_STEER_SPEC" ] || return 1
	_st_owns "steer-spec" && return 1
	if grep -q '"zm_warp"\|"zm_vpn"' "$ST_STEER_SPEC"; then _st_own "steer-spec"; return 1; fi
	grep -q '"channels"[[:space:]]*:[[:space:]]*\[[[:space:]]*{' "$ST_STEER_SPEC"
}



_rb_arch() { awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release; }
_rb_release() { awk -F\' '/DISTRIB_RELEASE/ {print $2}' /etc/openwrt_release; }
_rb_target() { awk -F\' '/DISTRIB_TARGET/ {print $2}' /etc/openwrt_release | tr '/' '_'; }

_rb_fetch_pkg() { # URL ФАЙЛ
	local err
	rm -f "$2"
	if ! err=$(curl -fsSL --connect-timeout 8 --max-time 120 -o "$2" "$1" 2>&1); then
		echo "   не скачалось: $1${err:+ — $(printf '%s' "$err" | tail -n1)}"
		rm -f "$2"; return 1
	fi
	[ -s "$2" ] || { echo "   пустой файл: $1"; rm -f "$2"; return 1; }
	if head -c 512 "$2" | grep -qi '<html\|<!doctype'; then echo "   вместо пакета пришла веб-страница: $1"; rm -f "$2"; return 1; fi
	return 0
}


_st_steer_ver() { steer --version 2>/dev/null | head -n1 | awk '{print $2}'; }
_st_tun_ensure() {
	[ -e /dev/net/tun ] && return 0
	modprobe tun >/dev/null 2>&1
	[ -e /dev/net/tun ] && return 0
	_rb_say "Ставим kmod-tun (нужен steer-extended для подписок)"
	$INSTALL kmod-tun >&2 || _rb_warn "kmod-tun не установился — подписки VPN работать не будут"
	modprobe tun >/dev/null 2>&1
	return 0
}
_st_is_ext() { steer --version 2>/dev/null | head -n1 | grep -q 'VLESS'; }

_st_ver_lt() { # A B
	awk -v a="$1" -v b="$2" 'BEGIN { n = split(a, x, "."); m = split(b, y, "."); k = n > m ? n : m
		for (i = 1; i <= k; i++) { if (x[i] + 0 < y[i] + 0) exit 0; if (x[i] + 0 > y[i] + 0) exit 1 }
		exit 1 }'
}

_st_latest_ver() {
	local c="$ZM_STATE_DIR/steer.latest" v="" m
	if [ -z "$ZM_VER_FORCE" ] && [ -s "$c" ] && [ -z "$(find "$c" -mmin +360 2>/dev/null)" ]; then cat "$c"; return 0; fi
	v="$(curl -Ls --connect-timeout 5 --max-time 12 -o /dev/null -w '%{url_effective}' https://github.com/xyzmean/steer/releases/latest 2>/dev/null |
		grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | tail -n1)"
	if ! echo "$v" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
		v=""
		for m in https://gitlab.com/xyzmean/steer/-/raw/dist https://raw.githubusercontent.com/xyzmean/steer/dist; do
			v="$(curl -fsSL --connect-timeout 6 --max-time 12 "$m/VERSION" 2>/dev/null | tr -d '[:space:]')"
			echo "$v" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' && break
			v=""
		done
	fi
	if [ -n "$v" ]; then
		mkdir -p "$ZM_STATE_DIR"
		echo "$v" > "$c"
		echo "$v"
	elif [ -s "$c" ]; then
		cat "$c"
	else
		echo "$ST_STEER_VER"
	fi
}

_st_install_steer() {
	local pkg=steer-extended want
	want="$(_st_latest_ver)"
	if command -v steer >/dev/null 2>&1; then
		if ! _st_is_ext; then
			_rb_say "Меняем движок Steer $(_st_steer_ver) на steer-extended $want"
		elif _st_ver_lt "$(_st_steer_ver)" "$want"; then
			_rb_say "Движок Steer $(_st_steer_ver) — обновляем до $want"
		else
			_rb_say "Движок steer-extended уже последней версии: $(_st_steer_ver)"
			_st_tun_ensure
			return 0
		fi
	fi
	local arch tmp base url ver was_on="" old_plain="" dropped=""
	command -v steer >/dev/null 2>&1 && /etc/init.d/steer enabled 2>/dev/null && was_on=1
	# Обычный пакет steer конфликтует с steer-extended — его надо убрать перед установкой
	command -v steer >/dev/null 2>&1 && ! _st_is_ext && _pkg_is_installed steer && old_plain="$(_st_steer_ver)"
	arch="$(_rb_arch)"
	[ -n "$arch" ] || { echo "ОШИБКА: не удалось определить архитектуру роутера"; return 1; }
	tmp="$ST_RUN/steer.$RAZ"
	_rb_say "Устанавливаем движок steer-extended $want"
	$UPDATE >&2
	for base in $ST_STEER_URLS; do
		ver="$want"
		url="$(echo "$base" | sed "s/@VER@/$ver/")/${pkg}-${ver}-1_${arch}.${RAZ}"
		if ! _rb_fetch_pkg "$url" "$tmp"; then
			case "$base" in *@VER@*) continue ;; esac
			ver=$(curl -fsSL --connect-timeout 8 --max-time 15 "$base/VERSION" 2>/dev/null | tr -d '[:space:]')
			echo "$ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || continue
			_rb_fetch_pkg "$base/${pkg}-${ver}-1_${arch}.${RAZ}" "$tmp" || continue
		fi
		if [ -n "$old_plain" ] && [ -z "$dropped" ]; then
			# новый пакет уже скачан — только теперь убираем старый; правила Steer сохраняем и возвращаем
			_rb_say "Удаляем старый пакет steer $old_plain — он мешает установке steer-extended"
			[ -s "$ST_STEER_SPEC" ] && cp -f "$ST_STEER_SPEC" "$ST_RUN/spec.keep"
			/etc/init.d/steer stop >/dev/null 2>&1
			if ! $DELETE steer >&2; then
				rm -f "$tmp" "$ST_RUN/spec.keep"
				echo "ОШИБКА: старый пакет steer не удалился — удалите его вручную и повторите"
				return 1
			fi
			dropped=1
		fi
		if $INSTALL "$tmp" >&2; then
			rm -f "$tmp"
			if [ -s "$ST_RUN/spec.keep" ]; then
				mkdir -p "$(dirname "$ST_STEER_SPEC")"
				cp -f "$ST_RUN/spec.keep" "$ST_STEER_SPEC"
				rm -f "$ST_RUN/spec.keep"
			fi
			_st_own "pkg steer"
			_st_own "pkg steer-extended"
			_st_tun_ensure
			if [ -n "$was_on" ]; then
				/etc/init.d/steer enable >/dev/null 2>&1
				/etc/init.d/steer restart >/dev/null 2>&1
			else
				/etc/init.d/steer stop >/dev/null 2>&1
				/etc/init.d/steer disable >/dev/null 2>&1
			fi
			_rb_rpcd_ensure
			_rb_say "Движок $pkg $ver установлен"
			return 0
		fi
	done
	rm -f "$tmp"
	[ -n "$dropped" ] && _rb_warn "Старый steer $old_plain уже удалён, а новый не поставился — нажмите установку ещё раз, когда появится интернет"
	echo "ОШИБКА: не удалось установить движок Steer"
	return 1
}

_st_awg_loaded() { grep -q '^amneziawg ' /proc/modules 2>/dev/null || [ -d /sys/module/amneziawg ]; }

_awg_board() { ubus call system board 2>/dev/null | jsonfilter -e "$1" 2>/dev/null; }
_awg_rel_ver() { local v; v="$(_awg_board '@.release.version')"; [ -n "$v" ] || v="$(_rb_release)"; echo "$v"; }
_awg_rel_arch() {
	local a; a="$(_awg_board '@.release.arch')"
	[ -n "$a" ] || a="$(_rb_arch)"
	[ -n "$a" ] || a="$(opkg print-architecture 2>/dev/null | awk 'BEGIN { m = 0 } $3 > m { m = $3; a = $2 } END { print a }')"
	[ -n "$a" ] || a="$(apk --print-arch 2>/dev/null)"
	echo "$a"
}
_awg_rel_target() { local t; t="$(_awg_board '@.release.target')"; [ -n "$t" ] || t="$(awk -F\' '/DISTRIB_TARGET/ {print $2}' /etc/openwrt_release)"; echo "$t"; }
_awg_luci_pkg() {
	local v="$1" ma mi pa
	ma="$(echo "$v" | cut -d. -f1)"; mi="$(echo "$v" | cut -d. -f2)"; pa="$(echo "$v" | cut -d. -f3 | sed 's/[^0-9].*//')"
	case "$ma.$mi.$pa" in *[!0-9.]*|*..*|.*|*.) echo luci-app-amneziawg; return ;; esac
	if [ "$ma" -gt 24 ] || { [ "$ma" -eq 24 ] && [ "$mi" -gt 10 ]; } || { [ "$ma" -eq 24 ] && [ "$mi" -eq 10 ] && [ "$pa" -ge 3 ]; } ||
	   { [ "$ma" -eq 23 ] && [ "$mi" -eq 5 ] && [ "$pa" -ge 6 ]; }; then
		echo luci-proto-amneziawg
	else
		echo luci-app-amneziawg
	fi
}
_awg_legacy_feeds() {
	local f
	for f in /etc/opkg/customfeeds.conf /etc/apk/repositories /etc/apk/repositories.d/*.list; do
		[ -f "$f" ] && grep -qF 'slava-shchipunov.github.io/awg-openwrt' "$f" || continue
		_rb_say "Убираем старый фид awg-openwrt из $f — его ключ конфликтует с пакетами 2Grey"
		sed '\|slava-shchipunov\.github\.io/awg-openwrt|d' "$f" > "$f.zmtmp" && cat "$f.zmtmp" > "$f"
		rm -f "$f.zmtmp"
	done
}
_awg_fetch() { # БАЗА ПАКЕТ ПОСТФИКС -> путь к файлу в stdout
	local e
	for e in "$RAZ" "$([ "$RAZ" = apk ] && echo ipk || echo apk)"; do
		if _rb_fetch_pkg "$1/$2$3.$e" "$ST_RUN/$2.$e" >&2; then echo "$ST_RUN/$2.$e"; return 0; fi
	done
	return 1
}

_st_install_awg() { # [update]
	local mode="$1"
	if [ "$mode" != update ] && _st_awg_loaded && command -v awg >/dev/null 2>&1 && _awg_proto_ok; then return 0; fi
	local rel arch tgt sub post luci old_luci base bases m p f ok=0 was_loaded=0 kver0 kver1 need="" force=""
	_st_awg_loaded && was_loaded=1
	kver0="$(_awg_pkg_ver kmod-amneziawg)"
	for p in kmod-amneziawg amneziawg-tools; do
		if [ "$mode" = update ] || ! _pkg_is_installed "$p"; then need="$need $p"; fi
	done
	[ "$p" = amneziawg-tools ] && ! command -v awg >/dev/null 2>&1 && case " $need " in *" amneziawg-tools "*) ;; *) need="$need amneziawg-tools" ;; esac
	if [ -n "$need" ]; then
		rel="$(_awg_rel_ver)"; arch="$(_awg_rel_arch)"; tgt="$(_awg_rel_target)"
		sub="${tgt#*/}"; tgt="${tgt%%/*}"
		[ -n "$rel" ] && [ -n "$arch" ] && [ -n "$tgt" ] && [ -n "$sub" ] || { echo "ОШИБКА: не удалось определить версию, архитектуру или цель OpenWrt"; return 1; }
		post="_v${rel}_${arch}_${tgt}_${sub}"
		luci="$(_awg_luci_pkg "$rel")"
		old_luci=luci-app-amneziawg; [ "$luci" = luci-app-amneziawg ] && old_luci=luci-proto-amneziawg
		{ [ "$mode" = update ] || ! _pkg_is_installed "$luci"; } && need="$need $luci"
		[ "$mode" = update ] && [ "$PKG" = opkg ] && force="--force-reinstall"
		_rb_say "Устанавливаем AmneziaWG из релиза 2Grey/awg-openwrt v$rel ($arch, $tgt/$sub)"
		mkdir -p "$ST_RUN"
		_awg_legacy_feeds
		echo "==> Обновляем список пакетов (нужен для зависимостей kmod-amneziawg)"
		$UPDATE >&2 || _rb_warn "Список пакетов обновился не полностью (какой-то фид не ответил) — продолжаем"
		bases=""
		for m in $ST_AWG_MIRRORS; do bases="$bases $m/v$rel"; done
		bases="$bases $ST_AWG_MIRROR_FLAT/$rel"
		for base in $bases; do
			ok=1
			for p in $need; do
				if f="$(_awg_fetch "$base" "$p" "$post")"; then
					if [ "$p" = "$luci" ] && _pkg_is_installed "$old_luci"; then
						_rb_say "$old_luci конфликтует с $luci — снимаем"
						$DELETE "$old_luci" >&2
					fi
					_rb_say "Ставим $p"
					if $INSTALL $force "$f" >&2; then
						[ "${ST_AWG_OWN:-1}" = 1 ] && _st_own "pkg $p"
					elif [ "$p" != "$luci" ]; then
						ok=0
					else
						_rb_warn "$p не встал — туннели работают и без него, но в «Сеть → Интерфейсы» их не будет видно"
					fi
					rm -f "$f"
				elif [ "$p" = "$luci" ]; then
					_rb_warn "$p для этой версии нет — туннели работают и без него"
				else
					ok=0
				fi
				[ "$ok" = 1 ] || break
			done
			if [ "$ok" = 1 ]; then
				if ! _pkg_is_installed luci-i18n-amneziawg-ru && f="$(_awg_fetch "$base" luci-i18n-amneziawg-ru "$post" 2>/dev/null)"; then
					$INSTALL "$f" >&2 && { [ "${ST_AWG_OWN:-1}" = 1 ] && _st_own "pkg luci-i18n-amneziawg-ru"; }
					rm -f "$f"
				fi
				break
			fi
			_rb_warn "В $base нет полного набора пакетов — пробуем следующее зеркало"
		done
		_rb_rpcd_ensure
		if [ "$ok" != 1 ]; then
			echo "ОШИБКА: не удалось установить AmneziaWG — для OpenWrt $rel ($arch, $tgt/$sub) нет готовых пакетов в релизах 2Grey/awg-openwrt"
			return 1
		fi
	fi
	kver1="$(_awg_pkg_ver kmod-amneziawg)"
	if [ "$was_loaded" = 1 ] && [ -n "$kver0" ] && [ "$kver0" != "$kver1" ]; then
		if [ -z "$(awg show interfaces 2>/dev/null)" ] && rmmod amneziawg >/dev/null 2>&1; then
			_rb_say "Модуль ядра AmneziaWG перезагружен ($kver0 → $kver1)"
		else
			_rb_warn "Модуль ядра обновлён ($kver0 → $kver1), но туннели работают на прежнем — новый заработает после перезагрузки роутера"
		fi
	fi
	_st_awg_loaded || modprobe amneziawg >/dev/null 2>&1
	if ! _st_awg_loaded || ! command -v awg >/dev/null 2>&1; then
		echo "ОШИБКА: AmneziaWG установлен, но модуль ядра не загрузился — перезагрузите роутер и повторите"
		return 1
	fi
	if ! _awg_proto_ok; then
		_rb_say "Перезапускаем сеть, чтобы она узнала протокол AmneziaWG (страница может ненадолго пропасть)"
		/etc/init.d/network restart >/dev/null 2>&1
		sleep 8
		_rb_rpcd_ensure
	fi
	return 0
}


_st_warp_field() { sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$ST_WARP_CONF" | head -n1; }

ST_WARP_API="https://api.cloudflareclient.com/v0a2158/reg https://api.cloudflareclient.com/v0a1922/reg"

_st_warp_conf_write() { # ПРИВАТНЫЙ ПИР v4 v6
	mkdir -p "$ST_DIR"
	printf '%s\n' \
		"[Interface]" "PrivateKey = $1" "Address = ${3}${4:+, $4}" "MTU = 1280" \
		"S1 = $MIXOMO_AWG_S1" "S2 = $MIXOMO_AWG_S2" "Jc = $MIXOMO_AWG_JC" "Jmin = $MIXOMO_AWG_JMIN" "Jmax = $MIXOMO_AWG_JMAX" \
		"H1 = $MIXOMO_AWG_H1" "H2 = $MIXOMO_AWG_H2" "H3 = $MIXOMO_AWG_H3" "H4 = $MIXOMO_AWG_H4" "I1 = $MIXOMO_AWG_I1" "" \
		"[Peer]" "PublicKey = $2" "AllowedIPs = 0.0.0.0/0" "Endpoint = engage.cloudflareclient.com:4500" "PersistentKeepalive = 25" \
		> "$ST_WARP_CONF"
	chmod 600 "$ST_WARP_CONF"
}

_st_warp_register() {
	[ -s "$ST_WARP_CONF" ] && [ -n "$(_st_warp_field PrivateKey)" ] && return 0
	mkdir -p "$ST_DIR" "$ST_RUN"
	local priv pub api reg="$ST_RUN/reg.json" peer v4 v6 tos nf="$ST_RUN/warp.api.fail"
	if [ -n "$(find "$nf" -mmin -10 2>/dev/null)" ]; then
		_rb_say "API Cloudflare только что не ответил — сразу берём запасной генератор"
	elif command -v awg >/dev/null 2>&1 && command -v jsonfilter >/dev/null 2>&1; then
		priv="$(awg genkey 2>/dev/null)"
		pub="$(printf '%s' "$priv" | awg pubkey 2>/dev/null)"
		tos="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
		for api in $ST_WARP_API; do
			[ -n "$pub" ] || break
			rm -f "$reg"
			curl -fsS --connect-timeout 8 --max-time 25 -X POST \
				-H 'User-Agent: okhttp/3.12.1' -H 'CF-Client-Version: a-6.10-2158' -H 'Content-Type: application/json' \
				-d "{\"install_id\":\"\",\"tos\":\"$tos\",\"key\":\"$pub\",\"fcm_token\":\"\",\"type\":\"ios\",\"locale\":\"en_US\"}" \
				-o "$reg" "$api" 2>/dev/null || continue
			peer="$(jsonfilter -i "$reg" -e '@.config.peers[0].public_key' 2>/dev/null)"
			v4="$(jsonfilter -i "$reg" -e '@.config.interface.addresses.v4' 2>/dev/null)"
			v6="$(jsonfilter -i "$reg" -e '@.config.interface.addresses.v6' 2>/dev/null)"
			if [ -n "$peer" ] && [ -n "$v4" ]; then
				_st_warp_conf_write "$priv" "$peer" "$v4" "$v6"
				rm -f "$reg"
				_rb_say "Ключи WARP получены у Cloudflare"
				return 0
			fi
		done
		rm -f "$reg"
		touch "$nf"
		_rb_warn "Cloudflare не выдал ключи напрямую — пробуем запасные генераторы"
	fi
	( MIXOMO_WARP_CONF="$ST_WARP_CONF"; do_mixomo_warp_register manual ) || return 1
	chmod 600 "$ST_WARP_CONF"
	[ -n "$(_st_warp_field PrivateKey)" ] && [ -n "$(_st_warp_field PublicKey)" ]
}

_st_warp_iface_write() { # ХОСТ ПОРТ
	local priv addr peer
	priv="$(_st_warp_field PrivateKey)"
	addr="$(_st_warp_field Address | tr ',' '\n' | sed 's/[[:space:]]//g' | grep -v ':' | head -n1)"
	peer="$(_st_warp_field PublicKey)"
	case "$addr" in */*) ;; *) addr="$addr/32" ;; esac
	uci -q delete "network.$ST_WARP_IF"
	uci -q delete "network.${ST_WARP_IF}_peer"
	_st_peers_drop "$ST_WARP_IF"
	uci set "network.$ST_WARP_IF=interface"
	uci set "network.$ST_WARP_IF.proto=amneziawg"
	uci set "network.$ST_WARP_IF.private_key=$priv"
	uci add_list "network.$ST_WARP_IF.addresses=$addr"
	uci set "network.$ST_WARP_IF.mtu=1280"
	uci set "network.$ST_WARP_IF.awg_jc=$MIXOMO_AWG_JC"
	uci set "network.$ST_WARP_IF.awg_jmin=$MIXOMO_AWG_JMIN"
	uci set "network.$ST_WARP_IF.awg_jmax=$MIXOMO_AWG_JMAX"
	uci set "network.$ST_WARP_IF.awg_s1=$MIXOMO_AWG_S1"
	uci set "network.$ST_WARP_IF.awg_s2=$MIXOMO_AWG_S2"
	uci set "network.$ST_WARP_IF.awg_h1=$MIXOMO_AWG_H1"
	uci set "network.$ST_WARP_IF.awg_h2=$MIXOMO_AWG_H2"
	uci set "network.$ST_WARP_IF.awg_h3=$MIXOMO_AWG_H3"
	uci set "network.$ST_WARP_IF.awg_h4=$MIXOMO_AWG_H4"
	uci set "network.$ST_WARP_IF.awg_i1=$MIXOMO_AWG_I1"
	uci set "network.${ST_WARP_IF}_peer=amneziawg_$ST_WARP_IF"
	uci set "network.${ST_WARP_IF}_peer.description=WARP ${ST_WARP_IF#zmwarp}"
	uci set "network.${ST_WARP_IF}_peer.public_key=$peer"
	uci add_list "network.${ST_WARP_IF}_peer.allowed_ips=0.0.0.0/0"
	uci set "network.${ST_WARP_IF}_peer.route_allowed_ips=0"
	uci set "network.${ST_WARP_IF}_peer.persistent_keepalive=25"
	uci set "network.${ST_WARP_IF}_peer.endpoint_host=$1"
	uci set "network.${ST_WARP_IF}_peer.endpoint_port=$2"
	uci commit network
	_st_own "net $ST_WARP_IF"
}

_st_warp_zone() {
	local want i changed=0
	# в зоне — все туннели Steer, и автоматические, и свой: переключение режима не трогает firewall
	want="$(for i in $(_st_wifs_every); do { _st_owns "net $i" || _st_wifs_all | grep -qx "$i"; } && echo "$i"; done | tr '\n' ' ' | sed 's/ $//')"
	if [ "$(uci -q get "firewall.$ST_WARP_ZONE")" = "zone" ] && [ "$(uci -q get "firewall.$ST_WARP_ZONE.network")" != "$want" ]; then
		uci -q delete "firewall.$ST_WARP_ZONE.network"
		for i in $want; do uci add_list "firewall.$ST_WARP_ZONE.network=$i"; done
		uci commit firewall
		/etc/init.d/firewall reload >/dev/null 2>&1
	fi
	if [ "$(uci -q get "firewall.$ST_WARP_ZONE")" != "zone" ]; then
		uci set "firewall.$ST_WARP_ZONE=zone"
		uci set "firewall.$ST_WARP_ZONE.name=$ST_WARP_ZONE"
		for i in $want; do uci add_list "firewall.$ST_WARP_ZONE.network=$i"; done
		uci set "firewall.$ST_WARP_ZONE.input=REJECT"
		uci set "firewall.$ST_WARP_ZONE.output=ACCEPT"
		uci set "firewall.$ST_WARP_ZONE.forward=REJECT"
		uci set "firewall.$ST_WARP_ZONE.masq=1"
		uci set "firewall.$ST_WARP_ZONE.mtu_fix=1"
		uci set "firewall.${ST_WARP_ZONE}_fwd=forwarding"
		uci set "firewall.${ST_WARP_ZONE}_fwd.src=$(_zm_lan_zone)"
		uci set "firewall.${ST_WARP_ZONE}_fwd.dest=$ST_WARP_ZONE"
		uci commit firewall
		_st_own "fw $ST_WARP_ZONE"
		/etc/init.d/firewall reload >/dev/null 2>&1
	fi
	_zm_fwd_fix "${ST_WARP_ZONE}_fwd"
}

_zm_fwd_fix() { # СЕКЦИЯ_FORWARDING — источник должен быть зоной LAN этого роутера
	local lz
	[ "$(uci -q get "firewall.$1")" = forwarding ] || return 0
	lz="$(_zm_lan_zone)"
	[ "$(uci -q get "firewall.$1.src")" = "$lz" ] && return 0
	uci set "firewall.$1.src=$lz"
	uci commit firewall
	/etc/init.d/firewall reload >/dev/null 2>&1
}

# Все пиры интерфейса, и безымянные тоже (их создаёт импорт конфига в LuCI): иначе у интерфейса
# останется старый пир с тем же 0.0.0.0/0, трафик уйдёт ему, и новый сервер не ответит
_st_peers_drop() { # ИНТЕРФЕЙС
	local p
	for p in $(uci -q -X show network | sed -n "s/^network\.\([^.=]*\)=amneziawg_$1\$/\1/p"); do uci -q delete "network.$p"; done
}

_st_warp_is_ru() { case " $ST_RU_COLOS " in *" $1 "*) return 0 ;; esac; return 1; }

_st_wif() { [ "$1" = 1 ] && echo "$ST_WIF1" || echo "zmwarp$1"; }
_st_wconf() { [ "$1" = 1 ] && echo "$ST_WCONF1" || echo "$ST_DIR/warp$1.conf"; }
_st_with() { # N КОМАНДА... — выполнить команду в контексте туннеля N
	local n="$1" oi="$ST_WARP_IF" oc="$ST_WARP_CONF" rc
	shift
	ST_WARP_IF="$(_st_wif "$n")"; ST_WARP_CONF="$(_st_wconf "$n")"
	"$@"; rc=$?
	ST_WARP_IF="$oi"; ST_WARP_CONF="$oc"
	return $rc
}
_st_wifs_all() { local n=1; while [ "$n" -le "$ST_WARP_N" ]; do _st_wif "$n"; n=$((n + 1)); done; }
_st_wifs_auto() { echo zmwarp; local n=2; while [ "$n" -le "$ST_WARP_MAX" ]; do echo "zmwarp$n"; n=$((n + 1)); done; }
_st_wifs_every() { _st_wifs_auto; echo "$ST_OWN_IF"; }
_st_warp_first() {
	local i
	[ -s "$ST_WARP_UP" ] && while read -r i _; do [ -d "/sys/class/net/$i" ] && { echo "$i"; return 0; }; done < "$ST_WARP_UP"
	echo "$ST_WARP_IF"
}

ST_WARP_POOLS="188.114.96. 188.114.97. 188.114.98. 188.114.99. 162.159.192. 162.159.193. 162.159.195. 8.34.70. 8.34.146. 8.39.214. 8.39.204. 8.6.112. 8.35.211. 8.39.125. 8.47.69."
ST_WARP_PORTS="2408 500 1701 4500"
ST_WARP_PORTS_EXT="854 859 864 878 880 890 891 894 903 908 928 934 939 942 943 945 946 955 968 987 988 1002 1010 1014 1018 1070 1074 1180 1387 1843 2371 2506 3138 3476 3581 3854 4177 4198 4233 5279 5956 7103 7152 7156 7281 7559 8319 8742 8854 8886"
ST_WARP_RAND=10          # случайных адресов к якорям — за разными колониями
ST_WARP_HS_WAIT=8        # секунд ждать рукопожатия: на живом роутере оно бывало и 1,25 с
ST_WARP_BURST=10
ST_WARP_TORN=3

_st_warp_link() { # ИНТЕРФЕЙС КЛЮЧ_УЗЛА АДРЕС ПОРТ
	local dev="$1" peer="$2" push w=0 hs
	awg set "$dev" peer "$peer" remove 2>/dev/null
	awg set "$dev" peer "$peer" endpoint "$3:$4" allowed-ips 0.0.0.0/0 persistent-keepalive 25 2>/dev/null || return 1
	ping -I "$dev" -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 &
	push=$!
	while [ "$w" -lt $((ST_WARP_HS_WAIT * 4)) ]; do
		hs=$(awg show "$dev" latest-handshakes 2>/dev/null | awk '{print $2; exit}')
		if [ "${hs:-0}" -gt 0 ] 2>/dev/null; then wait "$push" 2>/dev/null; return 0; fi
		w=$((w + 1))
		sleep 0.25 2>/dev/null || sleep 1
	done
	kill "$push" 2>/dev/null; wait "$push" 2>/dev/null
	return 1
}

_st_warp_probe() { # ИНТЕРФЕЙС -> «потери% круг_мс обрыв(0|1)»
	local out
	out=$(ping -I "$1" -c "$ST_WARP_BURST" -i 0.2 -W 2 -w 8 1.1.1.1 2>/dev/null)
	case "$out" in *"packet loss"*) ;; *) out=$(ping -I "$1" -c 5 -W 2 -w 10 1.1.1.1 2>/dev/null) ;; esac
	printf '%s\n' "$out" | awk -v t="$ST_WARP_TORN" '
		/seq=[0-9]/ { s = $0; sub(/.*seq=/, "", s); sub(/[^0-9].*/, "", s); s += 0; if (!got++ || s > hi) hi = s }
		/packets transmitted/ { tx = $1 + 0 }
		/packet loss/ { l = $0; sub(/%.*/, "", l); sub(/.*[^0-9]/, "", l); loss = l + 0; have = 1 }
		/min\/avg/ { v = $0; sub(/.*= */, "", v); split(v, a, "/"); rtt = int(a[2]) }
		END {
			if (!have) loss = 100
			torn = (got > 0 && tx > 0 && tx - 1 - hi >= t) ? 1 : 0
			printf "%d %d %d\n", loss, (got > 0 && rtt > 0 ? rtt : (got > 0 ? 1 : 99999)), torn
		}'
}

_cf_meta() { # [ИНТЕРФЕЙС] -> «КОЛОНИЯ ВИДЯТ_КАК СТРАНА_КОЛОНИИ ГОРОД»
	local j c s k t
	j=$(curl -s ${1:+--interface "$1"} --connect-timeout 4 --max-time 8 -H 'Referer: https://speed.cloudflare.com' https://speed.cloudflare.com/meta 2>/dev/null)
	case "$j" in *'"colo"'*) ;; *) return 1 ;; esac
	c="$(jsonfilter -s "$j" -e '@.colo.iata' 2>/dev/null)"
	[ -n "$c" ] || c="$(jsonfilter -s "$j" -e '@.colo' 2>/dev/null | grep -E '^[A-Z]{3}$')"
	[ -n "$c" ] || return 1
	s="$(jsonfilter -s "$j" -e '@.country' 2>/dev/null)"
	k="$(jsonfilter -s "$j" -e '@.colo.cca2' 2>/dev/null)"
	t="$(jsonfilter -s "$j" -e '@.colo.city' 2>/dev/null | tr -d '"\\\t\r\n')"
	echo "$c ${s:--} ${k:--} ${t:--}"
}

_st_warp_geo() { # ИНТЕРФЕЙС... — «интерфейс колония видят_как страна_колонии город» в кеш для карточек
	local i m
	mkdir -p "$ST_DIR"
	for i in "$@"; do
		[ -d "/sys/class/net/$i" ] || continue
		m="$(_cf_meta "$i")" || continue
		{ grep -v "^$i " "$ST_WARP_GEO" 2>/dev/null; echo "$i $m"; } > "$ST_WARP_GEO.tmp" && mv "$ST_WARP_GEO.tmp" "$ST_WARP_GEO"
	done
	return 0
}
_st_geo_get() { awk -v i="$1" '$1 == i { $1 = ""; sub(/^ /, ""); print; exit }' "$ST_WARP_GEO" 2>/dev/null; }
_st_geo_line() { # -> «DE (FRA), NL (AMS)» по поднятым туннелям
	local i c out="" g
	while read -r i c; do
		[ -n "$i" ] || continue
		g="$(_st_geo_get "$i")"
		set -- $g
		[ "$1" = "$c" ] && [ -n "$2" ] && [ "$2" != - ] && out="${out:+$out, }$2 ($c)"
	done < "$ST_WARP_UP" 2>/dev/null
	echo "$out"
}

_st_warp_i1() { # ИНТЕРФЕЙС МАСКА — сменить I1 на лету и в uci
	local f="$ST_RUN/i1.$1" rc
	mkdir -p "$ST_RUN"
	uci -q set "network.$1.awg_i1=$2"
	awg set "$1" i1 "$2" >/dev/null 2>&1 && return 0
	awg showconf "$1" > "$f" 2>/dev/null || { rm -f "$f"; return 1; }
	awk -v m="$2" '/^\[Interface\]/ { print; print "I1 = " m; next } /^I1[ \t]*=/ { next } { print }' "$f" > "$f.n"
	awg setconf "$1" "$f.n" >/dev/null 2>&1; rc=$?
	rm -f "$f" "$f.n"
	return $rc
}

_st_colo_of() { # ИНТЕРФЕЙС
	local c
	c=$(curl -sI --interface "$1" --max-time 8 -H 'Host: www.cloudflare.com' http://104.16.132.229/ 2>/dev/null |
		sed -n 's/^[Cc][Ff]-[Rr][Aa][Yy]: *[0-9a-f]*-\([A-Z][A-Z][A-Z]\).*/\1/p' | head -n1)
	[ -n "$c" ] || c=$(curl -s --interface "$1" --connect-timeout 5 --max-time 8 https://1.1.1.1/cdn-cgi/trace 2>/dev/null |
		sed -n 's/^colo=//p' | head -n1)
	[ -n "$c" ] && echo "$c"
}

_st_warp_ports() { # ИНТЕРФЕЙС КЛЮЧ_УЗЛА АДРЕС [ext]
	local f="$ST_DIR/warp.ports" ok="" p list="$ST_WARP_PORTS"
	[ -s "$f" ] && { cat "$f"; return 0; }
	[ "$4" = ext ] && { list="$ST_WARP_PORTS_EXT"; ST_WARP_HS_WAIT=3; }
	for p in $list; do
		_st_stopped && return 1
		_st_warp_link "$1" "$2" "$3" "$p" && ok="${ok:+$ok }$p"
		[ "$(echo "$ok" | wc -w)" -ge 2 ] && break
	done
	[ -n "$ok" ] || return 1
	echo "$ok" > "$f"
	echo "$ok"
}

_st_warp_scan1() { # ИНТЕРФЕЙС КЛЮЧ_УЗЛА ЗАНЯТЫЕ_КОЛОНИИ ЗАНЯТЫЕ_АДРЕСА [ФАЙЛ_ОБЩЕГО_СПИСКА] [quick]
	# $5 и $6 запоминаем сразу: ниже «set --» затирает позиционные параметры
	local dev="$1" peer="$2" busy=" $3 " busyip=" $4 " pool="$5" quick="$6" r="$ST_RUN/scan.$1" cand ip ports port loss rtt torn colo seen city meta pick f cls
	local tried=0 lim=3 ST_WARP_HS_WAIT="$ST_WARP_HS_WAIT"
	[ -n "$quick" ] && { lim=1; ST_WARP_HS_WAIT=4; }
	mkdir -p "$ST_RUN"
	: > "$r"; : > "$r.same"; : > "$r.nc"; : > "$r.ru"; : > "$r.notls"; : > "$r.torn"
	cand=$(awk -v p="$ST_WARP_POOLS" -v n="$ST_WARP_RAND" -v q="$quick" 'BEGIN { srand(); c = split(p, a, " ");
		if (q != "") { for (i = 1; i <= 4; i++) print a[i] "1"; for (i = 0; i < 2; i++) print a[int(rand() * c) + 1] int(rand() * 254) + 2; exit }
		for (i = 1; i <= c; i++) print a[i] "1"; for (i = 0; i < n; i++) print a[int(rand() * c) + 1] int(rand() * 254) + 2 }')
	ports=""
	for ip in $cand; do
		[ -n "$ports" ] && break
		[ "$tried" -ge "$lim" ] && break
		tried=$((tried + 1))
		ports="$(_st_warp_ports "$dev" "$peer" "$ip")"
	done
	if [ -z "$ports" ] && [ -z "$quick" ] && ! _st_stopped; then
		echo "   основные порты ($ST_WARP_PORTS) молчат — перебираем 50 запасных портов WARP, это до трёх минут" >&2
		ports="$(_st_warp_ports "$dev" "$peer" "$(echo "$cand" | head -n1)" ext)"
		[ -n "$ports" ] && echo "   открыты запасные порты: $ports" >&2
	fi
	[ -n "$ports" ] || { echo "!! WARP: ни один порт не ответил — ни основные ($ST_WARP_PORTS), ни запасные" >&2; return 1; }
	port="${ports%% *}"
	for ip in $cand; do
		_st_stopped && return 1
		case "$busyip" in *" $ip "*) continue ;; esac
		_st_warp_link "$dev" "$peer" "$ip" "$port" || { echo "   $ip:$port — рукопожатия нет" >&2; continue; }
		set -- $(_st_warp_probe "$dev"); loss="$1"; rtt="$2"; torn="$3"
		[ "$loss" -ge 100 ] 2>/dev/null && { echo "   $ip:$port — туннель молчит" >&2; continue; }
		if [ "$torn" = 1 ]; then
			echo "$loss $rtt $ip $port ?" >> "$r.torn"
			echo "   $ip:$port — трафик пошёл и оборвался: так DPI рвёт туннель" >&2
			[ "$(grep -c . "$r.torn")" -ge 6 ] && ! [ -s "$r" ] && ! [ -s "$r.same" ] && ! [ -s "$r.ru" ] && break
			continue
		fi
		seen=""; city=""
		if meta="$(_cf_meta "$dev")"; then
			set -- $meta; colo="$1"; seen="$2"; shift 3; city="$*"
			[ "$seen" = - ] && seen=""; [ "$city" = - ] && city=""
		else
			colo="$(_st_colo_of "$dev")"
			if [ -z "$colo" ]; then
				if ping -I "$dev" -c 2 -W 2 1.1.1.1 >/dev/null 2>&1; then
					echo "$loss $rtt $ip $port ?" >> "$r.nc"
					echo "   $ip:$port — пинг идёт ($rtt мс), но веб-запросы через туннель не проходят" >&2
				else
					echo "$loss $rtt $ip $port ?" >> "$r.torn"
					echo "   $ip:$port — пинг прошёл, а на первом веб-запросе туннель оборвался: так DPI рвёт туннель" >&2
					[ "$(grep -c . "$r.torn")" -ge 6 ] && ! [ -s "$r" ] && ! [ -s "$r.same" ] && ! [ -s "$r.ru" ] && break
				fi
				continue
			fi
			if ! curl -s -o /dev/null --interface "$dev" --connect-timeout 4 --max-time 8 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null; then
				echo "$loss $rtt $ip $port $colo" >> "$r.notls"; echo "   $ip:$port — колония $colo, но HTTPS через туннель не проходит" >&2; continue
			fi
		fi
		echo "   $ip:$port — потери $loss%, $rtt мс, колония $colo${city:+ ($city)}${seen:+, сайты видят $seen}" >&2
		if _st_warp_is_ru "$colo"; then echo "$loss $rtt $ip $port $colo" >> "$r.ru"; continue; fi
		case "$busy" in *" $colo "*) echo "$loss $rtt $ip $port $colo" >> "$r.same"; continue ;; esac
		echo "$loss $rtt $ip $port $colo" >> "$r"
		[ "$(grep -c . "$r")" -ge 3 ] && break
	done
	# Все найденные точки — в общий список, лучшие первыми: остальные туннели возьмут точки
	# оттуда, без своей разведки (точка входа не зависит от ключей WARP)
	if [ -n "$pool" ]; then
		for f in "$r" "$r.same" "$r.ru" "$r.notls" "$r.nc"; do
			[ -s "$f" ] || continue
			case "$f" in *.ru) cls=1 ;; *.notls) cls=2 ;; *.nc) cls=3 ;; *) cls=0 ;; esac
			awk -v c="$cls" '{ printf "%d %s %s %s\n", c * 100000000 + $1 * 100000 + $2, $3, $4, $5 }' "$f"
		done | sort -n | awk '{ print $2, $3, $4, $1 }' > "$pool"
	fi
	for f in "$r" "$r.same" "$r.ru" "$r.notls" "$r.nc"; do
		[ -s "$f" ] || continue
		case "$f" in *.ru) cls=1 ;; *.notls) cls=2 ;; *.nc) cls=3 ;; *) cls=0 ;; esac
		pick=$(awk -v c="$cls" '{ k = c * 100000000 + $1 * 100000 + $2; printf "%d\t%s %s %s %d\n", k, $3, $4, $5, k }' "$f" |
			sort -n | head -n1 | cut -f2)
		case "$f" in
			*.same) echo "   другой колонии нет — та же, но через другой адрес" >&2 ;;
			*.ru) echo "   наружных колоний нет — только российские" >&2 ;;
			*.notls) echo "!! ни через одну точку не проходит HTTPS" >&2 ;;
			*.nc) echo "!! ни через одну точку не проходят веб-запросы, только пинг" >&2 ;;
		esac
		echo "$pick"
		return 0
	done
	[ -s "$r.torn" ] && echo "!! через все ответившие точки ($(grep -c . "$r.torn")) DPI обрывает туннель — нужна другая маска" >&2
	return 1
}

# Разведка; не нашлось ни одной живой точки — перебираем маски I1: DPI чаще судит туннель по первому пакету
_st_warp_scan() { # ИНТЕРФЕЙС КЛЮЧ_УЗЛА ЗАНЯТЫЕ_КОЛОНИИ ЗАНЯТЫЕ_АДРЕСА [ФАЙЛ_ОБЩЕГО_СПИСКА]
	local dev="$1" peer="$2" busy="$3" busyip="$4" pool="$5" orig name mask got fall=""
	if got="$(_st_warp_scan1 "$dev" "$peer" "$busy" "$busyip" "$pool")"; then
		set -- $got
		[ "${4:-0}" -lt 100000000 ] 2>/dev/null && { echo "$got"; return 0; }
		fall="$got"
		[ -n "$pool" ] && cp -f "$pool" "$pool.fall" 2>/dev/null
	fi
	_st_stopped && { [ -n "$fall" ] && echo "$fall"; [ -n "$fall" ]; return; }
	orig="$(uci -q get "network.$dev.awg_i1")"
	[ -n "$orig" ] || { [ -n "$fall" ] && echo "$fall"; [ -n "$fall" ]; return; }
	if [ -n "$fall" ]; then
		echo "   хорошей зарубежной точки нет — пробуем другие маски первого пакета (I1), запасная точка остаётся" >&2
	else
		echo "   меняем маску первого пакета (I1) и пробуем ещё раз" >&2
	fi
	for name in $AWG_I1_SET; do
		_st_stopped && break
		mask="$(_awg_i1 "$name")"
		[ -n "$mask" ] && [ "$mask" != "$orig" ] || continue
		_st_warp_i1 "$dev" "$mask" || { echo "   модуль AmneziaWG не даёт сменить маску на лету" >&2; break; }
		echo "   маска $(_awg_mask_name "$mask"):" >&2
		if got="$(_st_warp_scan1 "$dev" "$peer" "$busy" "$busyip" "$pool" quick)" && set -- $got && [ "${4:-0}" -lt 100000000 ] 2>/dev/null; then
			printf '%s\n' "$mask" > "$ST_RUN/warp.mask"
			echo "   маска $(_awg_mask_name "$mask") проходит — она останется у туннеля" >&2
			[ -n "$pool" ] && rm -f "$pool.fall"
			echo "$got"
			return 0
		fi
	done
	_st_warp_i1 "$dev" "$orig" >/dev/null 2>&1
	if [ -n "$fall" ]; then
		[ -n "$pool" ] && [ -s "$pool.fall" ] && mv -f "$pool.fall" "$pool"
		set -- $fall
		case "$(( ${4:-0} / 100000000 ))" in
			1) echo "   маски не помогли — беру российскую колонию $3: блокировки через неё не снимаются" >&2 ;;
			2) echo "   маски не помогли — беру точку, где HTTPS не проходит" >&2 ;;
			*) echo "   маски не помогли — оставляю точку, где идёт хотя бы пинг" >&2 ;;
		esac
		echo "$fall"
		return 0
	fi
	return 1
}

# Точка из общего списка разведки: подключиться и проверить HTTPS — секунды вместо новой разведки.
# Порядок как у разведки: хорошая чужая колония → та же колония через другой адрес → запасные (российские, без HTTPS, без веб-запросов).
_st_warp_from_pool() { # ИНТЕРФЕЙС КЛЮЧ_УЗЛА ЗАНЯТЫЕ_КОЛОНИИ ЗАНЯТЫЕ_АДРЕСА ФАЙЛ -> «адрес порт колония ключ»
	local dev="$1" peer="$2" busy=" $3 " busyip=" $4 " f="$5" ip port colo k pass good isbusy
	[ -s "$f" ] || return 1
	[ -s "$ST_RUN/warp.mask" ] && _st_warp_i1 "$dev" "$(cat "$ST_RUN/warp.mask")" >/dev/null 2>&1
	for pass in 1 2 3 4; do
		while read -r ip port colo k <&3; do
			[ -n "$ip" ] || continue
			case "$busyip" in *" $ip "*) continue ;; esac
			good=0; [ "$k" -lt 100000000 ] 2>/dev/null && good=1
			isbusy=0; case "$busy" in *" $colo "*) isbusy=1 ;; esac
			case "$pass$good$isbusy" in 110|211|300|401) ;; *) continue ;; esac
			_st_stopped && return 1
			_st_warp_link "$dev" "$peer" "$ip" "$port" || { echo "   $ip:$port — с этими ключами рукопожатия нет" >&2; continue; }
			set -- $(_st_warp_probe "$dev")
			[ "$3" = 1 ] && { echo "   $ip:$port — трафик пошёл и оборвался" >&2; continue; }
			if [ "$good" = 1 ] && ! curl -s -o /dev/null --interface "$dev" --connect-timeout 4 --max-time 8 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null; then
				echo "   $ip:$port — HTTPS через туннель не проходит" >&2; continue
			fi
			echo "$ip $port $colo $k"
			return 0
		done 3< "$f"
	done
	return 1
}

_st_warp_alive_if() { # ИНТЕРФЕЙС — рукопожатие не старше трёх минут
	local hs
	hs=$(awg show "$1" latest-handshakes 2>/dev/null | awk '{print $2; exit}')
	[ "${hs:-0}" -gt 0 ] 2>/dev/null && [ $(( $(date +%s) - hs )) -lt 180 ]
}
_st_warp_ready_if() { ifstatus "$1" 2>/dev/null | grep -q '"up": true' && awg show "$1" peers 2>/dev/null | grep -q .; }

_st_warp_order() { # ФАЙЛ «интерфейс колония ключ|-» -> тот же файл «интерфейс колония»
	local f="$1" i c k pos=0 fresh=0
	grep -q ' [0-9][0-9]*$' "$f" && fresh=1
	: > "$f.key"
	while read -r i c k; do
		[ -n "$i" ] || continue
		pos=$((pos + 1))
		if [ "$fresh" = 0 ]; then
			k=$(awk -v i="$i" '$1 == i { print NR; exit }' "$ST_WARP_UP" 2>/dev/null)
			[ -n "$k" ] || k=$((100 + pos))
		elif [ "$k" = - ]; then
			set -- $(_st_warp_probe "$i")
			k=$(($1 * 100000 + $2))
		fi
		printf '%012d %03d %s %s\n' "$k" "$pos" "$i" "$c" >> "$f.key"
	done < "$f"
	sort "$f.key" | awk '{ print $3, $4 }' > "$f"
	rm -f "$f.key"
}

# ── «Свой конфиг»: один туннель zmwarp ровно по конфигу пользователя ──

_st_warp_own_iface() { # ФАЙЛ — интерфейс zmwarp из конфига: ключи, адреса, маскировка и точка входа как есть
	local f="$1" kv="$ST_RUN/own.kv" priv pub psk addr a ep host port keep mtu k v i="$ST_WARP_IF"
	mkdir -p "$ST_RUN"
	_awg_conf_kv "$f" > "$kv"
	priv="$(_awg_cv "$kv" interface privatekey)"; pub="$(_awg_cv "$kv" peer publickey)"
	addr="$(_awg_cv "$kv" interface address)"; ep="$(_awg_cv "$kv" peer endpoint)"
	psk="$(_awg_cv "$kv" peer presharedkey)"; keep="$(_awg_cv "$kv" peer persistentkeepalive)"; mtu="$(_awg_cv "$kv" interface mtu)"
	case "$ep" in
		\[*\]:*) host="${ep%]:*}"; host="${host#[}"; port="${ep##*]:}" ;;
		?*:*) host="${ep%:*}"; port="${ep##*:}" ;;
	esac
	if [ -z "$priv" ] || [ -z "$pub" ] || [ -z "$addr" ] || [ -z "$host" ] || [ -z "$port" ]; then
		rm -f "$kv"
		echo "ОШИБКА: в конфиге нет PrivateKey, Address, PublicKey или Endpoint (адрес:порт)"
		return 1
	fi
	uci -q delete "network.$i"
	uci -q delete "network.${i}_peer"
	_st_peers_drop "$i"
	uci set "network.$i=interface"
	uci set "network.$i.proto=amneziawg"
	uci set "network.$i.private_key=$priv"
	for a in $(echo "$addr" | tr ',' ' '); do
		case "$a" in */*) ;; *:*) a="$a/128" ;; *) a="$a/32" ;; esac
		uci add_list "network.$i.addresses=$a"
	done
	uci set "network.$i.mtu=${mtu:-1280}"
	_awg_iface_set "$f" "$i"
	uci set "network.${i}_peer=amneziawg_$i"
	uci set "network.${i}_peer.description=Свой WARP"
	uci set "network.${i}_peer.public_key=$pub"
	[ -n "$psk" ] && uci set "network.${i}_peer.preshared_key=$psk"
	uci add_list "network.${i}_peer.allowed_ips=0.0.0.0/0"
	case "$addr" in *:*) uci add_list "network.${i}_peer.allowed_ips=::/0" ;; esac
	uci set "network.${i}_peer.route_allowed_ips=0"
	uci set "network.${i}_peer.persistent_keepalive=${keep:-25}"
	uci set "network.${i}_peer.endpoint_host=$host"
	uci set "network.${i}_peer.endpoint_port=$port"
	uci commit network
	_st_own "net $i"
	rm -f "$kv"
}

_st_warp_park() { # ИНТЕРФЕЙС... — выключить и не поднимать при загрузке; конфиг и настройки остаются
	local i
	for i in "$@"; do
		_st_owns "net $i" || continue
		ifdown "$i" >/dev/null 2>&1
		uci -q set "network.$i.auto=0"
	done
	uci -q commit network
	return 0
}

_st_warp_own_up() { # поднять свой туннель и дождаться связи — без разведки и без новых ключей
	local i="$ST_WARP_IF" w=0 col
	_st_install_awg || return 1
	_st_awg_loaded || modprobe amneziawg >/dev/null 2>&1
	if [ "$(uci -q get "network.$i.proto")" != amneziawg ]; then
		_st_own_restore
		[ -s "$ST_WARP_CONF" ] || { echo "ОШИБКА: своего конфига WARP нет — вставьте его на вкладке WARP"; return 1; }
		_st_warp_own_iface "$ST_WARP_CONF" || return 1
		ubus call network reload >/dev/null 2>&1
		sleep 2
	fi
	_st_warp_zone
	uci -q get "network.$i.auto" >/dev/null && { uci -q delete "network.$i.auto"; uci -q commit network; }
	_rb_say "Поднимаем свой туннель WARP"
	ubus call "network.interface.$i" up >/dev/null 2>&1
	while [ "$w" -lt 25 ]; do
		_st_stopped && return 1
		_st_warp_alive_if "$i" && break
		ping -I "$i" -c 1 -W 1 1.1.1.1 >/dev/null 2>&1
		w=$((w + 1))
	done
	if ! _st_warp_alive_if "$i"; then
		rm -f "$ST_WARP_UP" "$ST_DIR/warp.colo"
		echo "ОШИБКА: сервер из вашего конфига не отвечает — проверьте ключи и Endpoint"
		return 1
	fi
	col="$(_st_colo_of "$i")"
	echo "$i ${col:-?}" > "$ST_WARP_UP"
	if [ -n "$col" ]; then echo "$col" > "$ST_DIR/warp.colo"; else rm -f "$ST_DIR/warp.colo"; fi
	_st_tgws_warp
	_st_warp_geo "$i"
	_rb_say "Свой WARP работает: $(uci -q get "network.${i}_peer.endpoint_host"):$(uci -q get "network.${i}_peer.endpoint_port")${col:+, колония $col}"
	col="$(_st_geo_line)"
	[ -n "$col" ] && _rb_say "Сайты видят WARP как: $col"
	col="$(awk '{ print $2; exit }' "$ST_WARP_UP")"
	[ -n "$col" ] && _st_warp_is_ru "$col" && _rb_warn "Туннель идёт через российскую колонию $col: заблокированное через неё не откроется"
	return 0
}

_st_warp_up() { # [repick]
	local repick="$1" n i peer got busy="" busyip="" ru=0 c ready="" w need=0 colos="" alt p
	_st_warp_own && { _st_warp_own_up; return; }
	_st_install_awg || return 1
	[ "$repick" = repick ] && rm -f "$ST_DIR/warp.ports"
	_rb_say "Поднимаем туннели WARP в разных колониях"
	n=1
	while [ "$n" -le "$ST_WARP_N" ]; do
		if _st_with "$n" _st_warp_register; then
			ready="$ready $n"
			i="$(_st_wif "$n")"
			if [ "$(uci -q get "network.$i.proto")" != amneziawg ]; then
				_st_with "$n" _st_warp_iface_write 162.159.192.1 2408
				need=1
			fi
		else
			[ "$n" = 1 ] && { echo "ОШИБКА: не удалось получить ключи WARP"; return 1; }
			_rb_warn "WARP $n: не удалось получить ключи — туннелей будет меньше"
		fi
		n=$((n + 1))
	done
	_st_warp_zone
	for n in $ready; do
		i="$(_st_wif "$n")"
		[ "$(uci -q get "network.$i.auto")" = 0 ] && { uci -q delete "network.$i.auto"; need=1; }
	done
	[ "$need" = 1 ] && { uci -q commit network; ubus call network reload >/dev/null 2>&1; }
	for n in $ready; do ubus call "network.interface.$(_st_wif "$n")" up >/dev/null 2>&1; done
	for n in $ready; do
		i="$(_st_wif "$n")"; w=0
		while [ "$w" -lt 20 ] && ! _st_warp_ready_if "$i"; do w=$((w + 1)); sleep 1; done
	done
	: > "$ST_WARP_UP.tmp"
	local pool="$ST_RUN/warp.pool"
	rm -f "$pool" "$ST_RUN/warp.mask"
	for n in $ready; do
		_st_stopped && break
		i="$(_st_wif "$n")"
		peer="$(_st_with "$n" _st_warp_field PublicKey)"
		_st_warp_ready_if "$i" || { _rb_warn "WARP $n: устройство не поднялось"; continue; }
		got=""
		if [ "$repick" != repick ] && grep -q "^$i " "$ST_WARP_UP" 2>/dev/null && _st_warp_alive_if "$i" && c="$(_st_colo_of "$i")" && ! _st_warp_is_ru "$c"; then
			got="$(uci -q get "network.${i}_peer.endpoint_host") $(uci -q get "network.${i}_peer.endpoint_port") $c -"
			_rb_say "WARP $n работает: колония $c"
		elif [ -s "$pool" ] && got="$(_st_warp_from_pool "$i" "$peer" "$busy" "$busyip" "$pool")"; then
			set -- $got
			_rb_say "WARP $n работает: $1:$2, колония $3 — точка из общей разведки"
		else
			echo "   WARP $n: разведка"
			if got="$(_st_warp_scan "$i" "$peer" "$busy" "$busyip" "$pool")"; then
				set -- $got
				if ! _st_warp_link "$i" "$peer" "$1" "$2"; then
					alt=""
					for p in $(cat "$ST_DIR/warp.ports" 2>/dev/null); do
						[ "$p" = "$2" ] && continue
						_st_stopped && break
						_st_warp_link "$i" "$peer" "$1" "$p" && { alt="$p"; break; }
					done
					if [ -z "$alt" ]; then
						_rb_warn "WARP $n: выбранная точка $1:$2 не ответила повторно"
						continue
					fi
					_rb_say "WARP $n: точка $1:$2 не ответила повторно, беру запасной порт $alt"
					got="$1 $alt $3 $4"
					set -- $got
				fi
				_rb_say "WARP $n работает: $1:$2, колония $3"
			else
				_rb_warn "WARP $n не поднялся"
				continue
			fi
		fi
		set -- $got
		busy="$busy $3"; busyip="$busyip $1"
		_st_warp_is_ru "$3" && ru=1
		echo "$i $3 ${4:--}" >> "$ST_WARP_UP.tmp"
		uci set "network.${i}_peer.endpoint_host=$1"
		uci set "network.${i}_peer.endpoint_port=$2"
	done
	if _st_stopped; then
		uci revert network >/dev/null 2>&1
		rm -f "$ST_WARP_UP.tmp"
		return 1
	fi
	uci commit network
	_st_warp_order "$ST_WARP_UP.tmp"
	mv "$ST_WARP_UP.tmp" "$ST_WARP_UP"
	colos="$(awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $2 }' "$ST_WARP_UP")"
	for n in $ready; do
		i="$(_st_wif "$n")"
		grep -q "^$i " "$ST_WARP_UP" || ifdown "$i" >/dev/null 2>&1
	done
	if [ ! -s "$ST_WARP_UP" ]; then
		rm -f "$ST_DIR/warp.colo"
		echo "ОШИБКА: туннель WARP не поднялся ни через одну точку входа"
		return 1
	fi
	echo "$colos" > "$ST_DIR/warp.colo"
	_st_tgws_warp
	_st_warp_geo $(awk '{ print $1 }' "$ST_WARP_UP")
	c="$(_st_geo_line)"
	[ -n "$c" ] && _rb_say "Сайты видят WARP как: $c"
	[ "$ru" = 1 ] && _rb_warn "Часть туннелей WARP идёт через российские колонии: заблокированное через них не откроется"
	return 0
}

ST_TGWS_WARP="/etc/stgws/warp.lst"
_st_tgws_warp() {
	local i c
	[ -d /etc/stgws ] || return 0
	: > "$ST_TGWS_WARP.tmp"
	while read -r i c; do
		[ -n "$i" ] || continue
		_st_warp_is_ru "$c" || echo "$i" >> "$ST_TGWS_WARP.tmp"
	done < "$ST_WARP_UP" 2>/dev/null
	mv "$ST_TGWS_WARP.tmp" "$ST_TGWS_WARP"
}

ST_LISTS_MANIFEST="https://github.com/xyzmean/splify2-lists/releases/latest/download/lists.json"
ST_SRS_FALLBACK="https://github.com/itdoginfo/allow-domains/releases/latest/download"

_st_fetch() { # URL ФАЙЛ — напрямую, потом через туннель
	curl -fsSL --connect-timeout 6 --max-time 60 -o "$2" "$1" 2>/dev/null && [ -s "$2" ] && return 0
	local i
	i="$(_st_warp_first)"
	[ -d "/sys/class/net/$i" ] &&
		curl -fsSL --interface "$i" --connect-timeout 6 --max-time 60 -o "$2" "$1" 2>/dev/null && [ -s "$2" ]
}

_st_srs_url() { # НАБОР -> ссылка из каталога или «последний релиз» издателя
	local m="$ST_RUN/lists.json" u=""
	[ -s "$m" ] || _st_fetch "$ST_LISTS_MANIFEST" "$m" || rm -f "$m"
	[ -s "$m" ] && u=$(grep -o '"url"[[:space:]]*:[[:space:]]*"[^"]*/allow-domains/releases/download/[^"]*/'"$1"'\.srs"' "$m" |
		head -n1 | sed 's/.*"\(https[^"]*\)"$/\1/')
	echo "${u:-$ST_SRS_FALLBACK/$1.srs}"
}

_st_srs_get() { # НАБОР
	local d="$ST_DIR/lists" f
	mkdir -p "$d"
	[ -f "$ST_RUN/srs.$1.done" ] && return 0
	f="$ST_RUN/$1.srs"
	_st_fetch "$(_st_srs_url "$1")" "$f" || return 1
	steer srs-read "$f" --out "$d/$1.dom.tmp" --prefixes-out "$d/$1.pfx.tmp" --meta-out "$d/$1.meta.tmp" >/dev/null 2>&1 || {
		rm -f "$f" "$d/$1".*.tmp; return 1; }
	for x in dom pfx meta; do touch "$d/$1.$x.tmp"; mv "$d/$1.$x.tmp" "$d/$1.$x"; done
	rm -f "$f"
	touch "$ST_RUN/srs.$1.done"
}

_st_chname() {
	local n="$2$3"
	[ "$(printf '%s' "$n" | wc -c)" -le 31 ] || n="$1$3"
	[ "$(printf '%s' "$n" | wc -c)" -le 31 ] || n="$(printf '%s' "$1" | cut -c1-20)$3"
	esc "$n"
}

_st_svc_channels() { # ID
	local id="$1" name sets set dom="" pfx="" narrow="" f proto ports ch="" sep="" took=""
	name="$(_rb_svc_field "$id" 2)"
	sets="$(_rb_svc_field "$id" 8 | tr ',' ' ')"
	for set in $sets; do
		[ -f "$ST_RUN/used.$set" ] && continue
		if _st_srs_get "$set"; then
			took="$took $set"
			f="$ST_DIR/lists/$set"
			[ -s "$f.dom" ] && dom="$dom${dom:+,}\"$f.dom\""
			if [ -s "$f.pfx" ]; then
				if [ -s "$f.meta" ]; then narrow="$narrow $set"; else pfx="$pfx${pfx:+,}\"$f.pfx\""; fi
			fi
		else
			_rb_warn "Список $set не скачался — беру список из пакета" >&2
			sets=""
			break
		fi
	done
	for set in $took; do [ -n "$sets" ] && touch "$ST_RUN/used.$set"; done
	if [ -z "$sets" ]; then
		dom="$(_st_json_list "$(_rb_svc_field "$id" 3 | tr ',' ' ')")"
		pfx="$(_st_json_list "$(_rb_svc_field "$id" 4 | tr ',' ' ')")"
		narrow=""
	fi
	[ "$id" = custom ] && [ -s "$ST_USER_DIR/$id.lst" ] && dom="\"$ST_USER_DIR/$id.lst\""
	[ -n "$dom" ] && { ch="$ch$sep{\"name\":\"$(_st_chname "$id" "$name")\",\"out\":\"$ST_OUT\",\"match\":{\"domains_files\":[$dom]}}"; sep=","; }
	[ -n "$pfx" ] && { ch="$ch$sep{\"name\":\"$(_st_chname "$id" "$name" " (адреса)")\",\"out\":\"$ST_OUT\",\"match\":{\"prefixes_files\":[$pfx]}}"; sep=","; }
	for set in $narrow; do
		f="$ST_DIR/lists/$set"
		proto=$(sed -n 's/^proto=//p' "$f.meta" | head -n1)
		ports=$(sed -n 's/^ports=//p' "$f.meta" | head -n1 | sed 's/,/","/g')
		ch="$ch$sep{\"name\":\"$(_st_chname "$id" "$name" " (голос)")\",\"out\":\"$ST_OUT\",\"match\":{\"prefixes_files\":[\"$f.pfx\"]${proto:+,\"proto\":\"$proto\"}${ports:+,\"ports\":[\"$ports\"]}}}"
		sep=","
	done
	printf '%s' "$ch"
}


_st_json_list() { # файлы через пробел -> "a","b"
	local f out=""
	for f in $1; do [ -s "$RB_SHARE/lists/$f" ] && out="$out${out:+,}\"$RB_SHARE/lists/$f\""; done
	printf '%s' "$out"
}

_st_spec_build() { # ID... -> JSON в stdout
	local id c chans="" schema=1 devs lans
	rm -f "$ST_RUN"/used.* "$ST_RUN"/srs.*.done "$ST_RUN/lists.json"
	mkdir -p "$ST_RUN"
	ST_OUT=zm_warp
	_st_use_vpn && ST_OUT="$ST_VPN_OUT"
	for id in "$@"; do
		c="$(_st_svc_channels "$id")"
		[ -n "$c" ] && chans="$chans${chans:+,}$c"
	done
	[ -n "$chans" ] || return 1
	case "$chans" in *'"ports"'*|*'"proto"'*) schema=2 ;; esac
	lans="$(for c in $(_zm_lan_devs); do printf ',"%s"' "$c"; done | sed 's/^,//')"
	if [ "$ST_OUT" = "$ST_VPN_OUT" ]; then
		printf '{"schema":%s,"lan_devices":[%s],"outputs":{"%s":{"kind":"vless","sub_file":"%s","nodes":[%s],"on_fail":"direct"}},"channels":[%s]}\n' \
			"$schema" "$lans" "$ST_VPN_OUT" "$ST_SUB" "$(_st_sub_node_idx)" "$chans"
		return 0
	fi
	devs="$(awk '{printf "%s\"%s\"", (NR > 1 ? "," : ""), $1}' "$ST_WARP_UP" 2>/dev/null)"
	[ -n "$devs" ] || devs="\"$ST_WARP_IF\""
	printf '{"schema":%s,"lan_devices":[%s],"outputs":{"zm_warp":{"kind":"interface","devices":[%s],"prefer":"latency","on_fail":"direct"}},"channels":[%s]}\n' \
		"$schema" "$lans" "$devs" "$chans"
}

_st_spec_apply() { # ID...
	local tmp="$ST_RUN/spec.json" out
	_st_spec_build "$@" > "$tmp" || { echo "ОШИБКА: для выбранных сервисов нет ни одного списка"; return 1; }
	if ! out=$(steer apply --spec "$tmp" --dry-run 2>&1 >/dev/null); then
		echo "ОШИБКА: движок Steer отверг настройку"
		printf '%s\n' "$out" | tail -n 5
		return 1
	fi
	mkdir -p /etc/steer
	if [ -s "$ST_STEER_SPEC" ] && ! _st_owns "steer-spec" && [ ! -f "$ST_DIR/spec.before" ]; then
		cp "$ST_STEER_SPEC" "$ST_DIR/spec.before"
	fi
	local sum
	sum="$(_st_spec_sum "$tmp")"
	if [ -s "$ST_STEER_SPEC" ] && cmp -s "$tmp" "$ST_STEER_SPEC" && [ "$sum" = "$(cat "$ST_DIR/spec.sum" 2>/dev/null)" ] &&
		/etc/init.d/steer running >/dev/null 2>&1; then
		_rb_say "Правила Steer не изменились"
		return 0
	fi
	cp "$tmp" "$ST_STEER_SPEC.tmp" && mv "$ST_STEER_SPEC.tmp" "$ST_STEER_SPEC"
	_st_own "steer-spec"
	/etc/init.d/steer enable >/dev/null 2>&1
	/etc/init.d/steer restart >/dev/null 2>&1
	mkdir -p "$ST_DIR"
	printf '%s\n' "$sum" > "$ST_DIR/spec.sum"
	_rb_say "Правила Steer применены"
}

_st_spec_sum() { # SPEC -> контрольная сумма спеки вместе со всеми файлами, на которые она ссылается
	local f
	{
		cat "$1"
		for f in $(grep -o '"/[^"]*"' "$1" | tr -d '"'); do
			[ -f "$f" ] && { echo "$f"; cat "$f"; }
		done
	} 2>/dev/null | md5sum | cut -d' ' -f1
}

_st_spec_clear() {
	_st_owns "steer-spec" || return 0
	/etc/init.d/steer stop >/dev/null 2>&1
	/etc/init.d/steer disable >/dev/null 2>&1
	if [ -s "$ST_DIR/spec.before" ]; then mv "$ST_DIR/spec.before" "$ST_STEER_SPEC"; else rm -f "$ST_STEER_SPEC"; fi
	sed -i '/^steer-spec$/d' "$ST_OWNED"
}

_st_kick() {
	_st_owns "steer-spec" || return 0
	[ -f "$ST_OFF" ] && return 0
	/etc/init.d/steer enabled 2>/dev/null || return 0
	local sel
	sel="$(_st_sel | tr '\n' ' ')"
	if [ -n "$(echo $sel)" ] && _st_spec_apply $sel; then return 0; fi
	/etc/init.d/steer restart >/dev/null 2>&1
	_rb_say "Steer перезапущен"
}


_st_dns_conflict() {
	[ -f /etc/config/https-dns-proxy ] || return 1
	[ -f "$ST_OFF" ] && return 1
	/etc/init.d/https-dns-proxy running >/dev/null 2>&1 || return 1
	_st_owns "steer-spec" || return 1
	[ "$(uci -q get https-dns-proxy.config.force_dns)" != "0" ]
}

_st_doh_force_on() {
	[ -f /etc/config/https-dns-proxy ] || return 1
	/etc/init.d/https-dns-proxy running >/dev/null 2>&1 || return 1
	[ "$(uci -q get https-dns-proxy.config.force_dns)" != "0" ]
}

_st_doh_unforce() {
	uci -q get https-dns-proxy.config >/dev/null 2>&1 || uci set https-dns-proxy.config=main
	uci set https-dns-proxy.config.force_dns='0'
	uci commit https-dns-proxy
	/etc/init.d/https-dns-proxy running >/dev/null 2>&1 && /etc/init.d/https-dns-proxy restart >/dev/null 2>&1
}

do_steer_dns_fix() {
	_st_doh_unforce
	[ -f "$ST_OFF" ] && return 0
	/etc/init.d/steer enabled 2>/dev/null && /etc/init.d/steer restart >/dev/null 2>&1
}



# Старую строку автоперезапуска (поднимала zmwarp…zmwarp3 поимённо) переписываем на новую — по списку работающих туннелей
_st_cron_refresh() {
	local cur
	cur="$(_st_cron_get)"
	[ -n "$cur" ] || return 0
	grep -F "$ST_CRON_TAG" "$CRON_FILE" 2>/dev/null | grep -qF "$ST_CRON_CMD" && return 0
	_st_cron_set "$cur" >/dev/null 2>&1
	return 0
}

_st_cron_get() {
	local line hour
	line=$(grep -F "$ST_CRON_TAG" "$CRON_FILE" 2>/dev/null | head -n1)
	[ -n "$line" ] || return 0
	hour=$(echo "$line" | awk '{print $2}')
	case "$hour" in
		*/*) echo "every:${hour#*/}" ;;
		*) echo "daily:$hour" ;;
	esac
}

_st_cron_set() { # off | every:N | daily:H
	local mode="${1%%:*}" value="${1#*:}" spec
	case "$mode" in
		off) spec="" ;;
		every)
			case "$value" in
				2|4|6|8|12) spec="0 */$value * * *" ;;
				*) echo '{"error":"допустимо каждые 2, 4, 6, 8 или 12 часов"}'; return 1 ;;
			esac ;;
		daily)
			case "$value" in ''|*[!0-9]*) echo '{"error":"введите час от 0 до 23"}'; return 1 ;; esac
			[ "$value" -ge 0 ] && [ "$value" -le 23 ] || { echo '{"error":"допустимый диапазон 0-23"}'; return 1; }
			spec="0 $value * * *" ;;
		*) echo '{"error":"неизвестный режим"}'; return 1 ;;
	esac
	mkdir -p "$(dirname "$CRON_FILE")"
	touch "$CRON_FILE"
	sed -i "\\|$ST_CRON_TAG|d" "$CRON_FILE"
	[ -n "$spec" ] && echo "$spec $ST_CRON_CMD $ST_CRON_TAG" >> "$CRON_FILE"
	/etc/init.d/cron enable >/dev/null 2>&1
	/etc/init.d/cron restart >/dev/null 2>&1
	printf '{"ok":true}\n'
}




_st_down() {
	/etc/init.d/steer stop >/dev/null 2>&1
	/etc/init.d/steer disable >/dev/null 2>&1
	local i
	for i in $(_st_wifs_all); do
		_st_owns "net $i" || continue
		ifdown "$i" >/dev/null 2>&1
		uci -q set "network.$i.auto=0"
	done
	uci -q commit network
}

_st_warp_resume() {
	[ -s "$ST_WARP_UP" ] || return 1
	local i ifs need=0 w=0 alive=""
	ifs="$(awk '{print $1}' "$ST_WARP_UP")"
	for i in $ifs; do
		[ "$(uci -q get "network.$i.proto")" = amneziawg ] || continue
		[ "$(uci -q get "network.$i.auto")" = 0 ] && { uci -q delete "network.$i.auto"; need=1; }
	done
	[ "$need" = 1 ] && uci -q commit network
	for i in $ifs; do
		_st_warp_ready_if "$i" || ubus call "network.interface.$i" up >/dev/null 2>&1
	done
	while [ "$w" -lt 25 ]; do
		alive=""
		for i in $ifs; do _st_warp_alive_if "$i" && alive="$alive $i"; done
		[ -n "$alive" ] && break
		sleep 1; w=$((w + 1))
	done
	[ -n "$alive" ] || return 1
	_rb_say "Туннели WARP уже подобраны — берём их как есть ($(cat "$ST_DIR/warp.colo" 2>/dev/null || echo "$alive"))"
	return 0
}

_st_apply() { # [tunnel_ready] — туннель только что проверен, второй раз не поднимаем
	local sel
	sel="$(_st_sel | tr '\n' ' ')"
	if [ -z "$(echo $sel)" ]; then
		_st_spec_clear
		_st_down
		_rb_say "Ничего не выбрано — туннель и Steer выключены"
		return 0
	fi
	case "$(_st_exit)" in
		vpn) _st_vpn_zone on ;;
		warp) [ "$1" = tunnel_ready ] || _st_warp_resume || _st_warp_up || return 1 ;;
		*)
			_st_spec_clear
			_st_down
			_rb_warn "Туннеля нет — подключите WARP или подписку VPN, и выбранные сервисы пойдут через него"
			return 0 ;;
	esac
	if _st_doh_force_on; then
		_st_doh_unforce
		_rb_warn "DNS over HTTPS перехватывал DNS сети — перехват выключен, шифрованный DNS работает как прежде"
	fi
	if _st_use_vpn; then _rb_say "Через VPN ($(_st_sub_label)): $(_rb_svc_names "$sel")"
	else _rb_say "Через WARP: $(_rb_svc_names "$sel")"; fi
	_st_spec_apply $sel
}

_st_selfcheck() {
	local f="$ST_RUN/diag.json" n i v what why bad=0 trace
	_rb_say "Проверяем, что всё работает"
	if [ "$(_st_sel)" ] && _st_use_vpn; then
		_st_vpn_check || bad=1
		/etc/init.d/steer running >/dev/null 2>&1 && echo "[ OK ] Служба Steer запущена" || { echo "[FAIL] Служба Steer не запущена"; bad=1; }
	elif [ "$(_st_sel)" ] && _st_warp_on; then
		trace="$(curl -s --interface "$(_st_warp_first)" --connect-timeout 5 --max-time 10 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null)"
		case "$trace" in
			*warp=on*|*warp=plus*) echo "[ OK ] Туннель WARP: трафик идёт через Cloudflare ($(echo "$trace" | sed -n 's/^colo=//p'))" ;;
			*ip=*)
				# свой конфиг может вести не в WARP, а на свой сервер — тогда важно лишь, что трафик идёт
				if _st_warp_own; then echo "[ OK ] Свой туннель: трафик идёт (выход $(echo "$trace" | sed -n 's/^ip=//p'))"
				else echo "[FAIL] Туннель WARP: трафик идёт мимо Cloudflare WARP"; bad=1; fi ;;
			*) echo "[FAIL] Туннель WARP: трафик через него не идёт"; bad=1 ;;
		esac
		/etc/init.d/steer running >/dev/null 2>&1 && echo "[ OK ] Служба Steer запущена" || { echo "[FAIL] Служба Steer не запущена"; bad=1; }
	fi
	command -v steer >/dev/null 2>&1 || return $bad
	[ -s "$ST_STEER_SPEC" ] || return $bad
	steer diag --spec "$ST_STEER_SPEC" > "$f" 2>/dev/null
	n=$(jsonfilter -i "$f" -e '@.checks[*].id' 2>/dev/null | wc -l)
	i=0
	while [ "$i" -lt "$n" ]; do
		v=$(jsonfilter -i "$f" -e "@.checks[$i].verdict" 2>/dev/null)
		what=$(jsonfilter -i "$f" -e "@.checks[$i].what" 2>/dev/null)
		why=$(jsonfilter -i "$f" -e "@.checks[$i].why" 2>/dev/null)
		case "$v" in
			ok)   echo "[ OK ] $what" ;;
			warn) echo "!! $what${why:+ — $why}" ;;
			fail) echo "[FAIL] $what${why:+ — $why}"; bad=1 ;;
		esac
		i=$((i + 1))
	done
	if [ "$bad" = 0 ]; then _rb_say "Проверка пройдена"; else _rb_warn "Проверка нашла поломку — подробности выше"; fi
	return $bad
}

_st_sel_add() {
	_rb_in "$1" "$ST_SKIP" && return 1
	mkdir -p "$ST_DIR"
	_rb_in "$1" "$ST_SEL" || echo "$1" >> "$ST_SEL"
}


do_steer_install() {
	local blk
	_st_phase install
	rm -f "$ST_STOP_FLAG"
	blk="$(_st_blocker)"
	case "$blk" in
		splify2) echo "ОШИБКА: установлен splify2 — туннели и списки настраиваются в нём"; return 1 ;;
		steer)   echo "ОШИБКА: у движка Steer уже есть чужие правила — не перезаписываем их"; return 1 ;;
	esac
	_ensure_deps
	mkdir -p "$ST_DIR"
	_st_phase pkgs
	_st_install_steer || return 1
	if ! command -v conntrack >/dev/null 2>&1; then
		$INSTALL conntrack >&2 && _st_own "pkg conntrack"
	fi
	_st_own "engine"
	rm -f "$ST_OFF"
	if [ "$(_st_exit)" != none ] && [ -n "$(_st_sel)" ]; then
		_st_phase rules
		_st_apply || return 1
		_st_phase check
		sleep 2
		_st_selfcheck
	fi
	_rb_say "Готово: движок steer-extended установлен — подключите WARP или подписку VPN на соседних вкладках"
}

do_steer_warp_setup() {
	_st_phase awg
	rm -f "$ST_STOP_FLAG"
	_st_installed || { echo "ОШИБКА: сначала установите Steer"; return 1; }
	[ -n "$(_st_blocker)" ] && { echo "ОШИБКА: движок Steer сейчас настраивает не Zapret Manager"; return 1; }
	_ensure_deps
	_st_install_awg || return 1
	_st_phase tunnel
	_st_warp_up || return 1
	[ "$(cat "$ST_EXIT" 2>/dev/null)" = vpn ] && [ -s "$ST_SUB" ] || echo warp > "$ST_EXIT"
	if [ ! -f "$ST_OFF" ] && [ -n "$(_st_sel)" ]; then
		_st_phase rules
		_st_apply tunnel_ready || return 1
		_st_phase check
		sleep 2
		_st_selfcheck
	fi
	_rb_say "Готово, WARP подключён"
}

_st_own_keep() { [ -s "$ST_WARP_OWN" ] && cp -f "$ST_WARP_OWN" "$ST_WARP_OWN_KEEP" && chmod 600 "$ST_WARP_OWN_KEEP"; return 0; }
_st_own_restore() {
	[ -s "$ST_WARP_OWN" ] || [ ! -s "$ST_WARP_OWN_KEEP" ] && return 0
	mkdir -p "$ST_DIR"
	cp -f "$ST_WARP_OWN_KEEP" "$ST_WARP_OWN" && chmod 600 "$ST_WARP_OWN"
}
_st_own_saved() { [ -s "$ST_WARP_OWN" ] || [ -s "$ST_WARP_OWN_KEEP" ]; }

do_steer_warp_own() { # подключить свой конфиг (из warp.pending или сохранённый)
	_st_phase awg
	rm -f "$ST_STOP_FLAG"
	_st_installed || { echo "ОШИБКА: сначала установите Steer"; return 1; }
	[ -n "$(_st_blocker)" ] && { echo "ОШИБКА: движок Steer сейчас настраивает не Zapret Manager"; return 1; }
	if [ -s "$ST_DIR/warp.pending" ]; then mv -f "$ST_DIR/warp.pending" "$ST_WARP_OWN"; fi
	_st_own_restore
	[ -s "$ST_WARP_OWN" ] || { echo "ОШИБКА: вставьте конфиг WARP"; return 1; }
	chmod 600 "$ST_WARP_OWN"
	_st_own_keep
	_ensure_deps
	_st_install_awg || return 1
	_st_phase tunnel
	_rb_say "Свой WARP: один туннель по вашему конфигу"
	if ! _st_warp_own; then
		# автоматические туннели не удаляем — только выключаем; их список помним, чтобы вернуться к ним как было
		grep -qv "^$ST_OWN_IF " "$ST_WARP_UP" 2>/dev/null && grep -v "^$ST_OWN_IF " "$ST_WARP_UP" > "$ST_WARP_UP_AUTO"
		_st_owns "net zmwarp" && _rb_say "Автоматические туннели WARP выключаем — они сохранятся, вернуться к ним можно в один клик"
	fi
	_st_warp_park $(_st_wifs_auto)
	echo own > "$ST_WARP_MODE"
	_st_mode_vars
	_st_awg_loaded || modprobe amneziawg >/dev/null 2>&1
	_st_warp_own_iface "$ST_WARP_CONF" || return 1
	_st_warp_zone
	ubus call network reload >/dev/null 2>&1
	sleep 2
	_st_warp_own_up || return 1
	_st_cron_refresh
	[ "$(cat "$ST_EXIT" 2>/dev/null)" = vpn ] && [ -s "$ST_SUB" ] || echo warp > "$ST_EXIT"
	if [ ! -f "$ST_OFF" ] && [ -n "$(_st_sel)" ]; then
		_st_phase rules
		_st_apply tunnel_ready || return 1
		_st_phase check
		sleep 2
		_st_selfcheck
	fi
	_rb_say "Готово, свой WARP подключён"
}

do_steer_warp_auto() { # вернуться к автоматическому режиму: ключи от Cloudflare, три туннеля
	_st_phase awg
	rm -f "$ST_STOP_FLAG"
	_st_installed || { echo "ОШИБКА: сначала установите Steer"; return 1; }
	[ -n "$(_st_blocker)" ] && { echo "ОШИБКА: движок Steer сейчас настраивает не Zapret Manager"; return 1; }
	_ensure_deps
	_st_install_awg || return 1
	_st_phase tunnel
	_rb_say "Автоматический WARP: три туннеля с ключами от Cloudflare"
	_st_owns "net $ST_OWN_IF" && _rb_say "Свой туннель $ST_OWN_IF выключаем — он сохранится, вернуться к нему можно в один клик"
	rm -f "$ST_WARP_MODE"
	_st_mode_vars
	_st_warp_park "$ST_OWN_IF"
	# 1.54 держал свой конфиг прямо в zmwarp — такой zmwarp переделываем в обычный автоматический
	if [ "$(uci -q get "network.zmwarp_peer.description")" = "Свой WARP" ]; then
		ifdown zmwarp >/dev/null 2>&1
		uci -q delete network.zmwarp; uci -q delete network.zmwarp_peer; uci commit network
		rm -f "$ST_DIR/warp.conf" "$ST_WARP_UP_AUTO"
	fi
	rm -f "$ST_WARP_UP"
	[ -s "$ST_WARP_UP_AUTO" ] && mv -f "$ST_WARP_UP_AUTO" "$ST_WARP_UP"
	if _st_warp_resume; then
		awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $2 }' "$ST_WARP_UP" > "$ST_DIR/warp.colo"
		_st_tgws_warp
	else
		_st_warp_up || return 1
	fi
	_st_cron_refresh
	[ "$(cat "$ST_EXIT" 2>/dev/null)" = vpn ] && [ -s "$ST_SUB" ] || echo warp > "$ST_EXIT"
	if [ ! -f "$ST_OFF" ] && [ -n "$(_st_sel)" ]; then
		_st_phase rules
		_st_apply tunnel_ready || return 1
		_st_phase check
		sleep 2
		_st_selfcheck
	fi
	_rb_say "Готово, автоматический WARP подключён"
}

_st_warp_fix() { # N [keys]
	local n="$1" i c peer got busy="" busyip="" w=0 host port x col
	_st_warp_own && { echo "ОШИБКА: у Steer свой конфиг WARP — замените его на вкладке WARP страницы Steer"; return 1; }
	[ "$n" -ge 1 ] 2>/dev/null && [ "$n" -le "$ST_WARP_MAX" ] || { echo "ОШИБКА: $ST_OWN_IF — свой туннель, новые ключи ему не нужны; замените конфиг на странице Steer"; return 1; }
	i="$(_st_wif "$n")"; c="$(_st_wconf "$n")"
	_st_awg_loaded || modprobe amneziawg >/dev/null 2>&1
	if [ "$2" = keys ] || [ ! -s "$c" ] || [ "$(uci -q get "network.$i.proto")" != amneziawg ]; then
		host="$(uci -q get "network.${i}_peer.endpoint_host")"; port="$(uci -q get "network.${i}_peer.endpoint_port")"
		if [ "$2" = keys ] || [ ! -s "$c" ]; then
			[ -f "$c" ] && mv "$c" "$c.old"
			_rb_say "WARP $n: получаем новые ключи"
			if ! _st_with "$n" _st_warp_register; then
				[ -f "$c.old" ] && mv "$c.old" "$c"
				echo "ОШИБКА: WARP $n — новые ключи не получены, оставляем прежние"
				return 1
			fi
			rm -f "$c.old"
		fi
		_st_with "$n" _st_warp_iface_write "${host:-162.159.192.1}" "${port:-2408}"
		_st_warp_zone
		ubus call network reload >/dev/null 2>&1
		sleep 2
	fi
	uci -q get "network.$i.auto" >/dev/null && { uci -q delete "network.$i.auto"; uci -q commit network; }
	ubus call "network.interface.$i" up >/dev/null 2>&1
	while [ "$w" -lt 20 ] && ! _st_warp_ready_if "$i"; do w=$((w + 1)); sleep 1; done
	_st_warp_ready_if "$i" || { echo "ОШИБКА: WARP $n — интерфейс не поднялся"; return 1; }
	peer="$(_st_with "$n" _st_warp_field PublicKey)"
	if [ -s "$ST_WARP_UP" ]; then
		while read -r x col; do
			[ "$x" = "$i" ] && continue
			busy="$busy $col"; busyip="$busyip $(uci -q get "network.${x}_peer.endpoint_host")"
		done < "$ST_WARP_UP"
	fi
	_rb_say "WARP $n: подбираем точку входа"
	if ! got="$(_st_warp_scan "$i" "$peer" "$busy" "$busyip")"; then
		ifdown "$i" >/dev/null 2>&1
		echo "ОШИБКА: WARP $n — ни одна точка входа не ответила; попробуйте новые ключи"
		return 1
	fi
	set -- $got
	_st_warp_link "$i" "$peer" "$1" "$2" >/dev/null 2>&1
	uci set "network.${i}_peer.endpoint_host=$1"
	uci set "network.${i}_peer.endpoint_port=$2"
	uci commit network
	{
		[ -s "$ST_WARP_UP" ] && while read -r x col; do [ "$x" = "$i" ] || echo "$x $col -"; done < "$ST_WARP_UP"
		echo "$i $3 ${4:--}"
	} > "$ST_WARP_UP.tmp"
	_st_warp_order "$ST_WARP_UP.tmp"
	mv "$ST_WARP_UP.tmp" "$ST_WARP_UP"
	awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $2 }' "$ST_WARP_UP" > "$ST_DIR/warp.colo"
	_st_tgws_warp
	_rb_say "WARP $n работает: $1:$2, колония $3"
	_st_warp_geo "$i"
}

do_steer_warp_fix() { # N [keys]
	_st_phase warp
	_st_need_warp || return 1
	rm -f "$ST_STOP_FLAG"
	_st_warp_fix "$1" "$2" || return 1
	_st_kick
	_rb_say "Готово"
}

do_steer_apply() {
	_st_phase rules
	rm -f "$ST_STOP_FLAG"
	_st_installed || { echo "ОШИБКА: Steer ещё не установлен"; return 1; }
	[ -n "$(_st_blocker)" ] && { echo "ОШИБКА: спеку Steer сейчас ведёт не Zapret Manager"; return 1; }
	rm -f "$ST_OFF"
	_st_apply || return 1
	_st_phase check
	sleep 2
	_st_selfcheck
	_rb_say "Готово"
}

do_steer_stop() {
	_st_phase rules
	_st_installed || { echo "ОШИБКА: Steer ещё не установлен"; return 1; }
	touch "$ST_OFF"
	_st_down
	rm -f "$ST_TGWS_WARP"
	_rb_say "Готово, Steer и туннель выключены — всё идёт напрямую"
}

_st_need_warp() {
	[ -n "$(_st_blocker)" ] && { echo "ОШИБКА: движок Steer сейчас настраивает не Zapret Manager"; return 1; }
	_st_warp_on && return 0
	echo "ОШИБКА: WARP ещё не подключён — подключите его на вкладке WARP"
	return 1
}

do_steer_warp_restart() {
	_st_phase warp
	_st_need_warp || return 1
	rm -f "$ST_STOP_FLAG"
	_rb_say "Перезапускаем туннель WARP"
	_st_warp_up || return 1
	_st_kick
	_rb_say "Готово"
}

do_steer_warp_endpoint() {
	_st_phase warp
	_st_need_warp || return 1
	rm -f "$ST_STOP_FLAG"
	_st_warp_up repick || return 1
	_st_kick
	_rb_say "Готово, точка входа подобрана"
}

do_steer_warp_recreate() {
	_st_phase warp
	_st_need_warp || return 1
	rm -f "$ST_STOP_FLAG"
	local n c host port
	_rb_say "Пересоздаём WARP с новыми ключами"
	n=1
	while [ "$n" -le "$ST_WARP_N" ]; do
		c="$(_st_wconf "$n")"
		[ -f "$c" ] && mv "$c" "$c.old"
		if ! _st_with "$n" _st_warp_register; then
			[ -f "$c.old" ] && mv "$c.old" "$c"
			[ "$n" = 1 ] && { echo "ОШИБКА: не удалось получить новые ключи — оставляем прежние"; return 1; }
			_rb_warn "WARP $n: новых ключей нет — оставляем прежние"
		else
			rm -f "$c.old"
			host="$(uci -q get "network.$(_st_wif "$n")_peer.endpoint_host")"
			port="$(uci -q get "network.$(_st_wif "$n")_peer.endpoint_port")"
			_st_with "$n" _st_warp_iface_write "${host:-162.159.192.1}" "${port:-2408}"
		fi
		n=$((n + 1))
	done
	ubus call network reload >/dev/null 2>&1
	_st_warp_up repick || return 1
	_st_kick
	_rb_say "Готово, WARP пересоздан"
}

do_steer_remove() {
	_st_phase remove
	_rb_say "Удаляем Steer и туннель WARP"
	local foreign=0
	[ "$(_st_blocker)" = splify2 ] && foreign=1
	if [ "$foreign" = 1 ]; then
		sed -i '/^steer-spec$/d; /^pkg steer$/d; /^pkg steer-extended$/d' "$ST_OWNED" 2>/dev/null
		_rb_warn "Установлен splify2 — движок Steer и его правила оставляем ему"
	else
		_st_spec_clear
		/etc/init.d/steer stop >/dev/null 2>&1
	fi
	local wi netrl=0
	for wi in $(_st_wifs_every); do
		_st_owns "net $wi" || continue
		ifdown "$wi" >/dev/null 2>&1
		uci -q delete "network.$wi"
		uci -q delete "network.${wi}_peer"
		netrl=1
	done
	[ "$netrl" = 1 ] && { uci commit network; /etc/init.d/network reload >/dev/null 2>&1; }
	if _st_owns "fw $ST_WARP_ZONE"; then
		uci -q delete "firewall.$ST_WARP_ZONE"
		uci -q delete "firewall.${ST_WARP_ZONE}_fwd"
		uci commit firewall
		/etc/init.d/firewall reload >/dev/null 2>&1
	fi
	if grep -qF "$ST_CRON_TAG" "$CRON_FILE" 2>/dev/null || grep -qF "# zm-subupd" "$CRON_FILE" 2>/dev/null; then
		sed -i "\\|$ST_CRON_TAG|d; \\|# zm-subupd|d" "$CRON_FILE"
		/etc/init.d/cron restart >/dev/null 2>&1
	fi
	_st_vpn_zone off
	if _st_owns "pkg steer"; then
		_rb_say "Удаляем движок Steer"
		if _pkg_is_installed steer-extended; then $DELETE steer-extended >&2; else $DELETE steer >&2; fi
	fi
	_st_owns "pkg conntrack" && $DELETE conntrack >&2
	if ! uci show network 2>/dev/null | grep -q "\.proto='amneziawg'"; then
		local p
		for p in luci-i18n-amneziawg-ru luci-proto-amneziawg luci-app-amneziawg amneziawg-tools kmod-amneziawg; do
			_st_owns "pkg $p" && $DELETE "$p" >&2
		done
	fi
	_rb_rpcd_ensure
	rm -rf "$ST_DIR" "$ST_RUN"
	rm -f "$ST_TGWS_WARP"
	_rb_say "Готово, Steer удалён"
}

steer_status() {
	local running=false phase="" blk colo="" warp_up=false installed=false ver="" run=false chans=0 dns=false
	local host="" port="" hs="" age="" rx=0 tx=0 off=false svc="" sep="" id sel=" " skip w k r
	_st_running && running=true
	[ -f "$ST_PHASE_FILE" ] && phase=$(cat "$ST_PHASE_FILE")
	blk="$(_st_blocker)"
	_st_installed && installed=true
	[ -f "$ST_OFF" ] && off=true
	if [ -s "$ST_WARP_UP" ]; then
		colo=$(while read -r w k; do [ -d "/sys/class/net/$w" ] && printf '%s\n' "$k"; done < "$ST_WARP_UP" | tr '\n' ',' | sed 's/,$//; s/,/, /g')
		[ -n "$colo" ] && warp_up=true
	elif [ -f "$ST_DIR/warp.colo" ]; then
		colo=$(cat "$ST_DIR/warp.colo")
		[ -d "/sys/class/net/$ST_WARP_IF" ] && warp_up=true
	fi
	if _st_owns "net $ST_WARP_IF"; then
		host="$(uci -q get "network.${ST_WARP_IF}_peer.endpoint_host")"
		port="$(uci -q get "network.${ST_WARP_IF}_peer.endpoint_port")"
	fi
	if [ "$warp_up" = true ] && command -v awg >/dev/null 2>&1; then
		for w in $(_st_wifs_all); do
			[ -d "/sys/class/net/$w" ] || continue
			k=$(awg show "$w" latest-handshakes 2>/dev/null | awk '{print $2; exit}')
			[ "${k:-0}" -gt "${hs:-0}" ] 2>/dev/null && hs="$k"
			set -- $(awg show "$w" transfer 2>/dev/null | head -n1)
			rx=$((rx + ${2:-0})); tx=$((tx + ${3:-0}))
		done
		[ -n "$hs" ] && [ "$hs" != 0 ] && age=$(( $(date +%s) - hs ))
	fi
	if command -v steer >/dev/null 2>&1; then
		ver="$(_st_steer_ver)"
		/etc/init.d/steer running >/dev/null 2>&1 && run=true
		_st_owns "steer-spec" && chans=$(grep -o '"out"' "$ST_STEER_SPEC" 2>/dev/null | wc -l)
	fi
	_st_dns_conflict && dns=true
	sel=" $(_st_sel | tr '\n' ' ') "
	for id in $(_rb_svc_ids); do
		_rb_routable "$id" || continue
		w=false; k=false
		case "$sel" in *" $id "*) w=true ;; esac
		_rb_in "$id" "$ST_SKIP" && k=true
		svc="$svc$sep{\"id\":\"$id\",\"name\":\"$(esc "$(_rb_svc_field "$id" 2)")\",\"on\":$w,\"skip\":$k}"
		sep=","
	done
	local vexit vup=false vsub=false latest="" ext=false won=false
	vexit="$(_st_exit)"
	_st_warp_on && won=true
	_st_is_ext && ext=true
	if [ -s "$ZM_STATE_DIR/steer.latest" ]; then latest="$(cat "$ZM_STATE_DIR/steer.latest")"
	elif command -v steer >/dev/null 2>&1; then ( _st_latest_ver >/dev/null 2>&1 & ); fi
	[ -d "/sys/class/net/$ST_VPN_OUT" ] && vup=true
	[ -s "$ST_SUB" ] && vsub=true
	local vlive=null
	if [ "$vup" = true ] && [ "$vexit" = vpn ] && [ "$off" = false ]; then
		_st_vpn_live; case $? in 0) vlive=true ;; 1) vlive=false ;; esac
	fi
	printf '{"running":%s,"phase":"%s","blocker":"%s","installed":%s,"stopped":%s,"version":"%s","steer_running":%s,"channels":%s,"warp_up":%s,"warp_colo":"%s","warp_host":"%s","warp_port":"%s","warp_hs_age":"%s","warp_rx":%s,"warp_tx":%s,"autorestart":"%s","dns_conflict":%s,"exit":"%s","vpn_up":%s,"vpn_live":%s,"has_sub":%s,"sub_label":"%s","latest":"%s","ext":%s,"warp_on":%s,"warp_mode":"%s","warp_own_saved":%s,"tunnels":%s,"services":[%s]}\n' \
		"$running" "$(esc "$phase")" "$blk" "$installed" "$off" "$(esc "$ver")" "$run" "${chans:-0}" "$warp_up" "$(esc "$colo")" \
		"$(esc "$host")" "$(esc "$port")" "$age" "${rx:-0}" "${tx:-0}" "$(_st_cron_get)" "$dns" \
		"$vexit" "$vup" "$vlive" "$vsub" "$(esc "$(_st_sub_label)")" "$(esc "$latest")" "$ext" "$won" "$(_st_warp_own && echo own || echo auto)" "$(_st_own_saved && echo true || echo false)" "$(_st_tunnels_json)" "$svc"
}

_st_tunnels_json() {
	local n=1 i up hs age rx tx host port colo out="" sep="" seen city cc
	while [ "$n" -le "$ST_WARP_N" ]; do
		i="$(_st_wif "$n")"
		if _st_owns "net $i"; then
			up=false; age=""; rx=0; tx=0
			[ -d "/sys/class/net/$i" ] && up=true
			host="$(uci -q get "network.${i}_peer.endpoint_host")"
			port="$(uci -q get "network.${i}_peer.endpoint_port")"
			colo="$(awk -v i="$i" '$1 == i {print $2; exit}' "$ST_WARP_UP" 2>/dev/null)"
			if [ "$up" = true ] && command -v awg >/dev/null 2>&1; then
				hs=$(awg show "$i" latest-handshakes 2>/dev/null | awk '{print $2; exit}')
				[ "${hs:-0}" -gt 0 ] 2>/dev/null && age=$(( $(date +%s) - hs ))
				set -- $(awg show "$i" transfer 2>/dev/null | head -n1)
				rx="${2:-0}"; tx="${3:-0}"
			fi
			seen=""; city=""; cc=""
			set -- $(_st_geo_get "$i")
			if [ $# -ge 4 ] && { [ "$1" = "$colo" ] || [ -z "$colo" ] || [ "$colo" = "?" ]; }; then
				[ -n "$colo" ] && [ "$colo" != "?" ] || colo="$1"
				seen="$2"; cc="$3"; shift 3; city="$*"
				[ "$seen" = - ] && seen=""; [ "$cc" = - ] && cc=""; [ "$city" = - ] && city=""
			fi
			out="$out$sep{\"n\":$n,\"if\":\"$i\",\"up\":$up,\"colo\":\"$(esc "$colo")\",\"city\":\"$(esc "$city")\",\"cc\":\"$(esc "$cc")\",\"seen\":\"$(esc "$seen")\",\"host\":\"$(esc "$host")\",\"port\":\"$(esc "$port")\",\"hs_age\":\"$age\",\"rx\":$rx,\"tx\":$tx}"
			sep=","
		fi
		n=$((n + 1))
	done
	printf '[%s]' "$out"
}

ST_USER_DIR="$ST_DIR/user"

_st_list_effective() { # ID -> домены в stdout, источник в ST_LIST_SRC
	local id="$1" set f any=0
	if [ -s "$ST_USER_DIR/$id.lst" ]; then ST_LIST_SRC=user; cat "$ST_USER_DIR/$id.lst"; return 0; fi
	for set in $(_rb_svc_field "$id" 8 | tr ',' ' '); do
		f="$ST_DIR/lists/$set.dom"
		[ -s "$f" ] && { cat "$f"; any=1; }
	done
	if [ "$any" = 1 ]; then ST_LIST_SRC=sets; return 0; fi
	ST_LIST_SRC=package
	for f in $(_rb_svc_field "$id" 3 | tr ',' ' '); do [ -s "$RB_SHARE/lists/$f" ] && cat "$RB_SHARE/lists/$f"; done
}

steer_list_get() { # ID
	local id="$1" body n tmp="$JOBS_DIR/steer-list.$$"
	[ "$id" = custom ] && _rb_routable "$id" || { echo '{"error":"редактируется только свой список"}'; return 1; }
	ST_LIST_SRC=""
	mkdir -p "$JOBS_DIR"
	_st_list_effective "$id" > "$tmp"
	body="$(tr -d '\r' < "$tmp" | grep -v '^[[:space:]]*$' | awk '!s[$0]++')"
	rm -f "$tmp"
	n=$(printf '%s\n' "$body" | grep -c .)
	printf '{"id":"%s","name":"%s","source":"%s","count":%s,"content":"%s"}\n' "$id" "$(esc "$(_rb_svc_field "$id" 2)")" "$ST_LIST_SRC" "$n" "$(esc_ml "$body")"
}

steer_list_set() {
	local id="${1%%|*}" body="${1#*|}" f tmp n
	case "$1" in *'|'*) ;; *) echo '{"error":"нет списка"}'; return 1 ;; esac
	[ "$id" = custom ] && _rb_routable "$id" || { echo '{"error":"редактируется только свой список"}'; return 1; }
	mkdir -p "$ST_USER_DIR"
	f="$ST_USER_DIR/$id.lst"; tmp="$f.tmp"
	printf '%s\n' "$body" | tr -d '\r' | tr 'A-Z' 'a-z' |
		sed 's/[[:space:]]*#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^domain://; s/^full://; s/^suffix://; s/^\*\.//; s/^\.//' |
		grep -E '^[a-z0-9]([a-z0-9_-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9_-]*[a-z0-9])?)+$' | awk '!s[$0]++' > "$tmp"
	n=$(grep -c . "$tmp")
	[ "$n" -gt 0 ] || { rm -f "$tmp"; echo '{"error":"в списке нет ни одного домена"}'; return 1; }
	mv "$tmp" "$f"
	if [ "$id" = custom ]; then
		mkdir -p "$ST_DIR"
		[ -f "$ST_SKIP" ] && sed -i '/^custom$/d' "$ST_SKIP"
		_rb_in custom "$ST_SEL" || echo custom >> "$ST_SEL"
	fi
	_st_list_changed "$id" "$n"
}

steer_list_reset() { # ID
	[ "$1" = custom ] && _rb_routable "$1" || { echo '{"error":"редактируется только свой список"}'; return 1; }
	rm -f "$ST_USER_DIR/$1.lst"
	if [ "$1" = custom ]; then
		if _rb_in custom "$ST_SEL"; then
			sed -i '/^custom$/d' "$ST_SEL"
			if _st_installed && [ ! -f "$ST_OFF" ] && [ -z "$(_st_blocker)" ]; then
				job_start steer do_steer_apply
				return
			fi
		fi
		printf '{"ok":true,"saved":true,"count":0}\n'
		return
	fi
	_st_list_changed "$1" 0
}

_st_list_changed() { # ID ЧИСЛО
	if _st_installed && [ ! -f "$ST_OFF" ] && [ -z "$(_st_blocker)" ] && _rb_in "$1" "$ST_SEL"; then
		job_start steer do_steer_apply
	else
		printf '{"ok":true,"saved":true,"count":%s}\n' "$2"
	fi
}

_st_sel_set() {
	local want id
	want=" $(echo "$1" | tr ',' ' ') "
	for id in $want; do
		case "$id" in *[!a-z0-9_-]*) echo '{"error":"неизвестный сервис"}'; return 1 ;; esac
		[ -n "$(_rb_svc_field "$id" 1)" ] && _rb_routable "$id" || { echo '{"error":"неизвестный сервис"}'; return 1; }
		[ "$id" = custom ] && [ ! -s "$ST_USER_DIR/custom.lst" ] && { echo '{"error":"свой список пуст — сначала добавьте в него домены"}'; return 1; }
	done
	mkdir -p "$ST_DIR"
	touch "$ST_SKIP"
	for id in $(_st_sel); do case "$want" in *" $id "*) ;; *) _rb_in "$id" "$ST_SKIP" || echo "$id" >> "$ST_SKIP" ;; esac; done
	for id in $want; do sed -i "/^$id\$/d" "$ST_SKIP"; done
	printf '%s\n' $want | grep . > "$ST_SEL"
	[ -s "$ST_SKIP" ] || rm -f "$ST_SKIP"
	return 0
}

ST_VPN_OUT="zm_vpn"
ST_VPN_ZONE="zmvpn"
ST_SUB="$ST_DIR/sub.txt"
ST_SUB_INFO="$ST_DIR/sub.userinfo"
ST_SUB_URL="$ST_DIR/sub.url"
ST_SUB_TITLE="$ST_DIR/sub.title"
ST_SUB_NODE="$ST_DIR/sub.node"
ST_EXIT="$ST_DIR/exit"

_st_exit() {
	local e
	e="$(cat "$ST_EXIT" 2>/dev/null)"
	if [ "$e" = vpn ] && [ -s "$ST_SUB" ] && _st_is_ext; then echo vpn; return; fi
	if _st_warp_on; then echo warp; return; fi
	if [ -s "$ST_SUB" ] && _st_is_ext; then echo vpn; return; fi
	echo none
}
_st_use_vpn() { [ "$(_st_exit)" = vpn ]; }

# Живой ли VPN на деле: интерфейс может быть поднят, а трафик не идти.
# Проверка (запрос к Cloudflare через туннель) идёт в фоне и кешируется на 2 минуты.
ST_VPN_PROBE="$ZM_STATE_DIR/steer.vpnprobe"
_st_vpn_probe() { # синхронно: пишет «время ok|fail ip loc»
	local trace ip="" loc="" r=fail
	if [ -d "/sys/class/net/$ST_VPN_OUT" ]; then
		trace="$(curl -s --interface "$ST_VPN_OUT" --connect-timeout 5 --max-time 10 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null)"
		ip="$(echo "$trace" | sed -n 's/^ip=//p')"; loc="$(echo "$trace" | sed -n 's/^loc=//p')"
		[ -n "$ip" ] && r=ok
	fi
	mkdir -p "$ZM_STATE_DIR"
	echo "$(date +%s) $r $ip $loc" > "$ST_VPN_PROBE"
	[ "$r" = ok ]
}
_st_vpn_live() { # 0 — трафик идёт, 1 — не идёт, 2 — ещё не проверяли
	local t r age
	read -r t r _ 2>/dev/null < "$ST_VPN_PROBE"
	age=$(( $(date +%s) - ${t:-0} ))
	if [ "$age" -gt 120 ] || [ "$age" -lt 0 ]; then
		if mkdir "$ST_VPN_PROBE.lock" 2>/dev/null; then
			( _st_vpn_probe >/dev/null 2>&1; rmdir "$ST_VPN_PROBE.lock" ) >/dev/null 2>&1 &
		elif [ -n "$(find "$ST_VPN_PROBE.lock" -mmin +1 2>/dev/null)" ]; then
			rmdir "$ST_VPN_PROBE.lock" 2>/dev/null
		fi
	fi
	[ -z "$r" ] && return 2
	[ "$age" -gt 600 ] && return 2
	[ "$r" = ok ]
}

_st_sub_label() {
	[ -s "$ST_SUB" ] || return 0
	if [ -s "$ST_SUB_TITLE" ]; then
		case "$(head -n1 "$ST_SUB_TITLE")" in
			*🌨*VPN*) echo "StressKVN" ;;
			*) head -n1 "$ST_SUB_TITLE" ;;
		esac
	elif [ -s "$ST_SUB_URL" ]; then sed -n 's#^[a-z]*://\([^/:?]*\).*#\1#p' "$ST_SUB_URL" | head -n1
	else echo "свои ссылки"; fi
}

_st_sub_node_idx() {
	local want n
	want="$(cat "$ST_SUB_NODE" 2>/dev/null)"
	[ -n "$want" ] || return 0
	n="$(steer vless-nodes "$ST_SUB" 2>/dev/null | jsonfilter -e '@.nodes[*].name' 2>/dev/null | grep -nxF -- "$want" | head -n1 | cut -d: -f1)"
	[ -n "$n" ] && echo $((n - 1))
}

_st_vpn_zone() { # on|off
	if [ "$1" = on ]; then
		[ "$(uci -q get "firewall.$ST_VPN_ZONE")" = zone ] && { _zm_fwd_fix "${ST_VPN_ZONE}_fwd"; return 0; }
		uci set "firewall.$ST_VPN_ZONE=zone"
		uci set "firewall.$ST_VPN_ZONE.name=$ST_VPN_ZONE"
		uci add_list "firewall.$ST_VPN_ZONE.device=$ST_VPN_OUT"
		uci set "firewall.$ST_VPN_ZONE.input=REJECT"
		uci set "firewall.$ST_VPN_ZONE.output=ACCEPT"
		uci set "firewall.$ST_VPN_ZONE.forward=REJECT"
		uci set "firewall.$ST_VPN_ZONE.masq=0"
		uci set "firewall.$ST_VPN_ZONE.mtu_fix=1"
		uci set "firewall.${ST_VPN_ZONE}_fwd=forwarding"
		uci set "firewall.${ST_VPN_ZONE}_fwd.src=$(_zm_lan_zone)"
		uci set "firewall.${ST_VPN_ZONE}_fwd.dest=$ST_VPN_ZONE"
		uci commit firewall
		_st_own "fw $ST_VPN_ZONE"
		/etc/init.d/firewall reload >/dev/null 2>&1
	else
		_st_owns "fw $ST_VPN_ZONE" || return 0
		uci -q delete "firewall.$ST_VPN_ZONE"
		uci -q delete "firewall.${ST_VPN_ZONE}_fwd"
		uci commit firewall
		/etc/init.d/firewall reload >/dev/null 2>&1
		sed -i "/^fw $ST_VPN_ZONE\$/d" "$ST_OWNED" 2>/dev/null
	fi
}

_st_vpn_check() {
	local w=0 tr ip loc
	while [ "$w" -lt 45 ] && [ ! -d "/sys/class/net/$ST_VPN_OUT" ]; do sleep 1; w=$((w + 1)); done
	if [ ! -d "/sys/class/net/$ST_VPN_OUT" ]; then
		echo "[FAIL] VPN: ни один узел подписки не поднялся — проверьте задержку узлов на вкладке «Подписка»"
		return 1
	fi
	tr="$(curl -s --interface "$ST_VPN_OUT" --connect-timeout 5 --max-time 10 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null)"
	ip="$(echo "$tr" | sed -n 's/^ip=//p')"; loc="$(echo "$tr" | sed -n 's/^loc=//p')"
	if [ -n "$ip" ]; then
		echo "[ OK ] VPN: трафик идёт через узел подписки (выход $ip${loc:+, $loc})"
		return 0
	fi
	echo "[FAIL] VPN: туннель поднят, но трафик через него не идёт"
	return 1
}

_st_need_ext() {
	_st_installed || { echo "ОШИБКА: сначала установите Steer"; return 1; }
	[ -n "$(_st_blocker)" ] && { echo "ОШИБКА: движок Steer сейчас настраивает не Zapret Manager"; return 1; }
	if ! _st_is_ext; then
		_ensure_deps
		_st_phase pkgs
		_st_install_steer || return 1
		_st_is_ext || { echo "ОШИБКА: steer-extended не установился"; return 1; }
	fi
	if [ ! -e /dev/net/tun ]; then
		modprobe tun >/dev/null 2>&1
		if [ ! -e /dev/net/tun ]; then
			_rb_say "Ставим kmod-tun"
			$UPDATE >&2
			$INSTALL kmod-tun >&2
			modprobe tun >/dev/null 2>&1
		fi
		[ -e /dev/net/tun ] || { echo "ОШИБКА: нет /dev/net/tun — пакет kmod-tun не установился"; return 1; }
	fi
	_st_phase sub
}

_st_sub_check() { # ФАЙЛ
	local j n
	j="$(steer vless-nodes "$1" 2>/dev/null)"
	n="$(printf '%s' "$j" | jsonfilter -e '@.usable' 2>/dev/null)"
	if [ "${n:-0}" -gt 0 ] 2>/dev/null; then
		_rb_say "Узлов, с которыми умеет работать Steer: $n"
		return 0
	fi
	echo "ОШИБКА: в подписке нет узлов, которые умеет Steer (VLESS Reality: tcp, grpc или xhttp)"
	printf '%s' "$j" | jsonfilter -e '@.skipped_reasons[*].reason' 2>/dev/null | head -n 3 | sed 's/^/   причина: /'
	return 1
}

_st_sub_fetch() { # ССЫЛКА
	local out ok e u t w
	rm -f "$ST_SUB.new"
	out="$(steer sub-fetch "$1" --out "$ST_SUB.new" --info "$ST_SUB_INFO" 2>/dev/null)"
	ok="$(printf '%s' "$out" | jsonfilter -e '@.ok' 2>/dev/null)"
	if [ "$ok" != true ] || [ ! -s "$ST_SUB.new" ]; then
		rm -f "$ST_SUB.new"
		e="$(printf '%s' "$out" | jsonfilter -e '@.error' 2>/dev/null)"
		echo "ОШИБКА: подписка не скачалась${e:+ — $e}"
		return 1
	fi
	w="$(printf '%s' "$out" | jsonfilter -e '@.warn' 2>/dev/null)"
	[ -n "$w" ] && _rb_warn "$w"
	_st_sub_check "$ST_SUB.new" || { rm -f "$ST_SUB.new"; return 1; }
	mv -f "$ST_SUB.new" "$ST_SUB"
	chmod 600 "$ST_SUB"
	u="$(printf '%s' "$out" | jsonfilter -e '@.url' 2>/dev/null)"
	printf '%s\n' "${u:-$1}" > "$ST_SUB_URL"
	chmod 600 "$ST_SUB_URL"
	t="$(printf '%s' "$out" | jsonfilter -e '@.title' 2>/dev/null)"
	if [ -n "$t" ]; then printf '%s\n' "$t" > "$ST_SUB_TITLE"; else rm -f "$ST_SUB_TITLE"; fi
	_rb_say "Подписка «$(_st_sub_label)» скачана"
}

_st_sub_apply() {
	if [ -f "$ST_OFF" ]; then
		_rb_say "Steer выключен — настройки сохранены и применятся при включении"
		return 0
	fi
	_st_phase rules
	_st_apply || return 1
	_st_phase check
	sleep 2
	_st_selfcheck
	_rb_say "Готово"
}

do_steer_sub_set() {
	local f="$ST_DIR/sub.pending" in
	rm -f "$ST_STOP_FLAG"
	_st_phase sub
	[ -s "$f" ] || { echo "ОШИБКА: нет ссылки"; return 1; }
	in="$(cat "$f")"
	rm -f "$f"
	_st_need_ext || return 1
	case "$in" in
		http://*|https://*)
			_rb_say "Скачиваем подписку"
			_st_sub_fetch "$(printf '%s' "$in" | tr -d ' \r\n\t')" || return 1
			;;
		*)
			printf '%s\n' "$in" | tr ' \t\r' '\n\n\n' | grep '^vless://' > "$ST_SUB.new"
			[ -s "$ST_SUB.new" ] || { rm -f "$ST_SUB.new"; echo "ОШИБКА: в тексте нет ссылок vless://"; return 1; }
			_st_sub_check "$ST_SUB.new" || { rm -f "$ST_SUB.new"; return 1; }
			mv -f "$ST_SUB.new" "$ST_SUB"
			chmod 600 "$ST_SUB"
			rm -f "$ST_SUB_URL" "$ST_SUB_TITLE" "$ST_SUB_INFO"
			_rb_say "Ссылки сохранены"
			;;
	esac
	rm -f "$ST_SUB_NODE"
	echo vpn > "$ST_EXIT"
	_rb_say "Выбранные сервисы теперь идут через подписку"
	_st_sub_apply
}

do_steer_sub_update() {
	rm -f "$ST_STOP_FLAG"
	_st_phase sub
	[ -s "$ST_SUB_URL" ] || { echo "ОШИБКА: это не подписка, а свои ссылки — обновлять нечего"; return 1; }
	_st_need_ext || return 1
	_rb_say "Обновляем подписку"
	_st_sub_fetch "$(head -n1 "$ST_SUB_URL")" || return 1
	if _st_use_vpn; then _st_sub_apply; else _rb_say "Готово"; fi
}

do_steer_sub_remove() {
	local was=0
	_st_phase sub
	_st_use_vpn && was=1
	rm -f "$ST_SUB" "$ST_SUB_INFO" "$ST_SUB_URL" "$ST_SUB_TITLE" "$ST_SUB_NODE"
	echo warp > "$ST_EXIT"
	_st_vpn_zone off
	_st_sub_auto_set off >/dev/null
	if _st_warp_on; then _rb_say "Подписка удалена — выбранные сервисы идут через WARP"
	else _rb_say "Подписка удалена — туннеля больше нет, сервисы идут напрямую"; fi
	[ "$was" = 1 ] && _st_installed && _st_sub_apply
	return 0
}

steer_sub_action() { # ДЕЙСТВИЕ ЗНАЧЕНИЕ
	rm -f "$ST_VPN_PROBE"
	local action="$1" mode="$2"
	case "$action" in
		sub_set)
			_st_installed || { echo '{"error":"сначала установите Steer"}'; return 1; }
			case "$mode" in
				http://*|https://*|*vless://*) ;;
				*) echo '{"error":"нужна ссылка на подписку (https://…) или ссылки vless://"}'; return 1 ;;
			esac
			mkdir -p "$ST_DIR"
			printf '%s\n' "$mode" > "$ST_DIR/sub.pending"
			chmod 600 "$ST_DIR/sub.pending"
			job_start steer do_steer_sub_set
			;;
		sub_update)
			[ -s "$ST_SUB_URL" ] || { echo '{"error":"обновлять нечего"}'; return 1; }
			job_start steer do_steer_sub_update
			;;
		sub_remove)
			[ -s "$ST_SUB" ] || { echo '{"error":"подписки нет"}'; return 1; }
			job_start steer do_steer_sub_remove
			;;
		sub_exit)
			case "$mode" in warp|vpn) ;; *) echo '{"error":"неизвестный выход"}'; return 1 ;; esac
			[ "$mode" = vpn ] && [ ! -s "$ST_SUB" ] && { echo '{"error":"сначала добавьте подписку"}'; return 1; }
			[ "$mode" = warp ] && ! _st_warp_on && { echo '{"error":"сначала подключите WARP"}'; return 1; }
			mkdir -p "$ST_DIR"
			echo "$mode" > "$ST_EXIT"
			[ "$mode" = warp ] && _st_vpn_zone off
			if _st_installed && [ ! -f "$ST_OFF" ] && [ -z "$(_st_blocker)" ] && [ -n "$(_st_sel)" ]; then
				if [ "$mode" = vpn ] && ! _st_is_ext; then job_start steer do_steer_sub_exit_vpn
				else job_start steer do_steer_apply; fi
			else
				printf '{"ok":true,"saved":true}\n'
			fi
			;;
		sub_node)
			[ -s "$ST_SUB" ] || { echo '{"error":"подписки нет"}'; return 1; }
			mkdir -p "$ST_DIR"
			if [ -n "$mode" ]; then printf '%s\n' "$mode" > "$ST_SUB_NODE"; else rm -f "$ST_SUB_NODE"; fi
			if _st_use_vpn && _st_installed && [ ! -f "$ST_OFF" ] && [ -z "$(_st_blocker)" ] && [ -n "$(_st_sel)" ]; then
				job_start steer do_steer_apply
			else
				printf '{"ok":true,"saved":true}\n'
			fi
			;;
	esac
}

ST_SUB_TAG="# zm-subupd"

_st_sub_auto_get() {
	local l h
	l="$(grep -F "$ST_SUB_TAG" "$CRON_FILE" 2>/dev/null | head -n1)"
	[ -n "$l" ] || { echo off; return; }
	h="$(echo "$l" | awk '{print $2}')"
	case "$h" in */*) echo "${h#*/}" ;; *) echo 24 ;; esac
}

_st_sub_auto_set() { # off | 3 | 6 | 12 | 24
	local spec=""
	case "$1" in
		off) ;;
		3|6|12) spec="$(( $(date +%M | sed 's/^0//') % 60 )) */$1 * * *" ;;
		24) spec="$(( $(date +%M | sed 's/^0//') % 60 )) 5 * * *" ;;
		*) echo '{"error":"допустимо: выкл, 3, 6, 12 или 24 часа"}'; return 1 ;;
	esac
	mkdir -p "$(dirname "$CRON_FILE")"
	touch "$CRON_FILE"
	sed -i "\\|$ST_SUB_TAG|d" "$CRON_FILE"
	[ -n "$spec" ] && echo "$spec /opt/zapret-manager-luci/backend.sh steer_action sub_refresh x >/dev/null 2>&1 $ST_SUB_TAG" >> "$CRON_FILE"
	/etc/init.d/cron enable >/dev/null 2>&1
	/etc/init.d/cron restart >/dev/null 2>&1
	printf '{"ok":true}\n'
}

do_steer_engine() {
	_st_phase pkgs
	rm -f "$ST_STOP_FLAG"
	_st_installed || { echo "ОШИБКА: Steer ещё не установлен"; return 1; }
	[ -n "$(_st_blocker)" ] && { echo "ОШИБКА: движок Steer сейчас настраивает не Zapret Manager"; return 1; }
	rm -f "$ZM_STATE_DIR/steer.latest"
	_ensure_deps
	_st_install_steer || return 1
	if [ ! -f "$ST_OFF" ] && [ -n "$(_st_sel)" ]; then
		_st_phase rules
		_st_apply || return 1
	fi
	_rb_say "Готово, движок: steer-extended $(_st_steer_ver)"
}

do_steer_sub_exit_vpn() {
	rm -f "$ST_STOP_FLAG"
	_st_need_ext || return 1
	_st_sub_apply
}

steer_sub_status() {
	local has=false kind="" url="" title="" ext=false vexit=warp node="" up="" down="" total="" expire="" list=null vpn=null mt=0
	_st_is_ext && ext=true
	vexit="$(_st_exit)"
	if [ -s "$ST_SUB" ]; then
		has=true
		if [ -s "$ST_SUB_URL" ]; then kind=url; url="$(head -n1 "$ST_SUB_URL")"; else kind=links; fi
		title="$(_st_sub_label)"
		node="$(cat "$ST_SUB_NODE" 2>/dev/null)"
		if [ -s "$ST_SUB_INFO" ]; then
			up="$(sed -n 's/^upload=//p' "$ST_SUB_INFO" | head -n1)"
			down="$(sed -n 's/^download=//p' "$ST_SUB_INFO" | head -n1)"
			total="$(sed -n 's/^total=//p' "$ST_SUB_INFO" | head -n1)"
			expire="$(sed -n 's/^expire=//p' "$ST_SUB_INFO" | head -n1)"
		fi
		mt="$(date -r "$ST_SUB" +%s 2>/dev/null)"
		if [ "$ext" = true ]; then
			list="$(steer vless-nodes "$ST_SUB" 2>/dev/null | tr '\n' ' ')"
			case "$list" in '{'*) ;; *) list=null ;; esac
		fi
	fi
	if _st_use_vpn && [ -s "$ST_STEER_SPEC" ] && _st_owns "steer-spec"; then
		vpn="$(steer status --spec "$ST_STEER_SPEC" 2>/dev/null | jsonfilter -e "@.outputs.$ST_VPN_OUT" 2>/dev/null | tr '\n' ' ')"
		case "$vpn" in '{'*) ;; *) vpn=null ;; esac
	fi
	printf '{"ext":%s,"has":%s,"kind":"%s","url":"%s","title":"%s","exit":"%s","auto":"%s","node":"%s","quota":{"up":"%s","down":"%s","total":"%s","expire":"%s"},"updated":%s,"list":%s,"vpn":%s}\n' \
		"$ext" "$has" "$kind" "$(esc "$url")" "$(esc "$title")" "$vexit" "$(_st_sub_auto_get)" "$(esc "$node")" \
		"$(esc "$up")" "$(esc "$down")" "$(esc "$total")" "$(esc "$expire")" "${mt:-0}" "$list" "$vpn"
}

steer_sub_probe() { # НОМЕР
	local out
	case "$1" in ''|*[!0-9]*) echo '{"ok":false,"error":"неверный номер узла"}'; return 1 ;; esac
	[ -s "$ST_SUB" ] && _st_is_ext || { echo '{"ok":false,"error":"подписки нет"}'; return 1; }
	out="$(steer vless-probe "$ST_SUB" --node "$1" --timeout 5 2>/dev/null | tr '\n' ' ')"
	case "$out" in '{'*) printf '%s\n' "$out" ;; *) echo '{"ok":false,"error":"проверка не удалась"}' ;; esac
}

steer_action() {
	local action="$1" mode="$2"
	[ "$action" = diag ] || rm -f "$ST_VPN_PROBE"
	case "$action" in
		install|apply|start|stop|remove|warp_restart|warp_endpoint|warp_recreate|lists|engine|warp_setup|warp_fix|warp_fixkeys|warp_own|warp_mode)
			_st_running && { echo '{"error":"дождитесь окончания текущей операции"}'; return 1; }
			case "$action" in
				warp_endpoint|warp_recreate|warp_fix|warp_fixkeys)
					_st_warp_own && { echo '{"error":"в режиме «Свой конфиг» ключи и точку входа задаёт ваш конфиг — замените его или вернитесь к автоматическому WARP"}'; return 1; } ;;
			esac
			case "$action" in
				warp_own)
					if [ -n "$mode" ]; then
						printf '%s\n' "$mode" | grep -qi '^[[:space:]]*\[interface\]' || { echo '{"error":"в конфиге нет секции [Interface]"}'; return 1; }
						printf '%s\n' "$mode" | grep -qi '^[[:space:]]*\[peer\]' || { echo '{"error":"в конфиге нет секции [Peer]"}'; return 1; }
						printf '%s\n' "$mode" | grep -qi '^[[:space:]]*endpoint[[:space:]]*=' || { echo '{"error":"в конфиге нет Endpoint — адреса сервера"}'; return 1; }
						mkdir -p "$ST_DIR"
						printf '%s\n' "$mode" | tr -d '\r' > "$ST_DIR/warp.pending"
						chmod 600 "$ST_DIR/warp.pending"
					else
						_st_own_saved || { echo '{"error":"вставьте конфиг WARP"}'; return 1; }
					fi
					job_start steer do_steer_warp_own ;;
				warp_mode)
					[ "$mode" = auto ] || { echo '{"error":"неизвестный режим"}'; return 1; }
					job_start steer do_steer_warp_auto ;;
				install)       job_start steer do_steer_install ;;
				apply|start)   job_start steer do_steer_apply ;;
				stop)          job_start steer do_steer_stop ;;
				remove)        job_start steer do_steer_remove ;;
				warp_restart)  job_start steer do_steer_warp_restart ;;
				engine)        job_start steer do_steer_engine ;;
				warp_setup)    job_start steer do_steer_warp_setup ;;
				warp_fix|warp_fixkeys)
					case "$mode" in [1-9]) ;; *) echo '{"error":"неверный номер туннеля"}'; return 1 ;; esac
					[ "$mode" -le "$ST_WARP_N" ] || { echo '{"error":"неверный номер туннеля"}'; return 1; }
					if [ "$action" = warp_fixkeys ]; then job_start steer do_steer_warp_fix "$mode" keys
					else job_start steer do_steer_warp_fix "$mode"; fi ;;
				warp_endpoint) job_start steer do_steer_warp_endpoint ;;
				warp_recreate) job_start steer do_steer_warp_recreate ;;
				lists)
					_st_sel_set "$mode" || return 1
					if _st_installed && [ ! -f "$ST_OFF" ]; then job_start steer do_steer_apply
					else printf '{"ok":true,"saved":true}\n'; fi ;;
			esac
			;;
		sub_status) steer_sub_status ;;
		sub_auto) _st_sub_auto_set "$mode" ;;
		sub_refresh)
			[ -s "$ST_SUB_URL" ] || return 0
			_st_running && return 0
			job_start steer do_steer_sub_update >/dev/null
			;;
		sub_probe) steer_sub_probe "$mode" ;;
		sub_set|sub_update|sub_remove|sub_exit|sub_node)
			_st_running && { echo '{"error":"дождитесь окончания текущей операции"}'; return 1; }
			steer_sub_action "$action" "$mode"
			;;
		list_get) steer_list_get "$mode" ;;
		list_set|list_reset)
			_st_running && { echo '{"error":"дождитесь окончания текущей операции"}'; return 1; }
			if [ "$action" = list_set ]; then steer_list_set "$mode"; else steer_list_reset "$mode"; fi
			;;
		halt)
			_st_running || { echo '{"error":"ничего не выполняется"}'; return 1; }
			touch "$ST_STOP_FLAG"
			printf '{"ok":true}\n'
			;;
		restart)
			_st_running && { echo '{"error":"дождитесь окончания текущей операции"}'; return 1; }
			_st_owns "steer-spec" || { echo '{"error":"правил для Steer нет — выберите сервисы"}'; return 1; }
			/etc/init.d/steer enable >/dev/null 2>&1
			/etc/init.d/steer restart >/dev/null 2>&1
			sleep 1
			/etc/init.d/steer running >/dev/null 2>&1 || { echo '{"error":"Steer не запустился — загляните в системный журнал"}'; return 1; }
			printf '{"ok":true}\n'
			;;
		autorestart) _st_cron_set "$mode" ;;
		warp_own_get)
			local of="$ST_WARP_OWN"
			[ -s "$of" ] || of="$ST_WARP_OWN_KEEP"
			if [ -s "$of" ]; then printf '{"content":"%s"}\n' "$(esc_ml "$(tr -d '\r' < "$of" | tr '\t' ' ')")"
			else printf '{"content":""}\n'; fi
			;;
		diag)
			local trace warp="none" colo="" tun="" tsep="" wi wn wv wc vpn="none" vip="" vloc="" gs gt
			if _st_installed && [ -n "$(_st_sel)" ] && [ ! -f "$ST_OFF" ] && _st_use_vpn; then
				vpn=off
				_st_vpn_probe && vpn=on
				read -r _ _ vip vloc 2>/dev/null < "$ST_VPN_PROBE"
			elif _st_installed && _st_warp_on && [ -n "$(_st_sel)" ] && [ ! -f "$ST_OFF" ]; then
				warp=off
				wn=1
				while [ "$wn" -le "$ST_WARP_N" ]; do
					wi="$(_st_wif "$wn")"
					if _st_owns "net $wi" && [ -d "/sys/class/net/$wi" ]; then
						trace="$(curl -s --interface "$wi" --connect-timeout 4 --max-time 8 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null)"
						wc="$(echo "$trace" | sed -n 's/^colo=//p')"
						wv=""
						case "$trace" in
							*warp=on*|*warp=plus*) wv=on ;;
							*ip=*) _st_warp_own && wv=on ;;
						esac
						gs=""; gt=""
						if [ "$wv" = on ]; then
							warp=on; [ -n "$colo" ] || colo="$wc"
							_st_warp_geo "$wi"
							set -- $(_st_geo_get "$wi")
							if [ $# -ge 4 ]; then
								[ -n "$wc" ] || wc="$1"
								gs="$2"; shift 3; gt="$*"
								[ "$gs" = - ] && gs=""; [ "$gt" = - ] && gt=""
							fi
						else wc="$(_st_colo_of "$wi")"; [ -n "$wc" ] && wv=notls || wv=off; fi
						tun="$tun$tsep{\"n\":$wn,\"warp\":\"$wv\",\"colo\":\"$(esc "$wc")\",\"city\":\"$(esc "$gt")\",\"seen\":\"$(esc "$gs")\"}"
						tsep=","
					fi
					wn=$((wn + 1))
				done
			fi
			local d=""
			if command -v steer >/dev/null 2>&1 && [ -s "$ST_STEER_SPEC" ] && _st_owns "steer-spec"; then
				d="$(steer diag --spec "$ST_STEER_SPEC" 2>/dev/null | tr '\n' ' ')"
				case "$d" in '{'*'}'*) ;; *) d="" ;; esac
			fi
			printf '{"warp":"%s","colo":"%s","vpn":"%s","vpn_ip":"%s","vpn_loc":"%s","tunnels":[%s],"diag":%s}\n' "$warp" "$(esc "$colo")" "$vpn" "$(esc "$vip")" "$(esc "$vloc")" "$tun" "${d:-null}"
			;;
		dns_fix)
			do_steer_dns_fix
			printf '{"ok":true}\n'
			;;
		*) echo '{"error":"неизвестное действие"}' ;;
	esac
}



AWG_DIR="/etc/zm-awg"
AWG_RUN="$JOBS_DIR/awg"
AWG_WARP_PEER="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
AWG_ENDPOINTS="engage.cloudflareclient.com:4500 engage.cloudflareclient.com:2408 162.159.192.1:2408 162.159.193.1:2408 162.159.195.1:2408 188.114.97.1:2408 188.114.98.1:500 188.114.99.1:4500"

mkdir -p "$AWG_RUN" 2>/dev/null

_awg_say() { echo "==> $*"; }
_awg_pkg_ver() { # ПАКЕТ -> версия или пусто
	if [ "$PKG" = "apk" ]; then
		apk info -v 2>/dev/null | sed -n "s/^$1-\([0-9][^ ]*\)\$/\1/p" | head -n1
	else
		opkg list-installed 2>/dev/null | awk -v p="$1" '$1 == p { print $3; exit }'
	fi
}
_awg_installed() { command -v awg >/dev/null 2>&1 && { _pkg_is_installed kmod-amneziawg || _st_awg_loaded; }; }
_awg_proto_ok() { ubus call network get_proto_handlers 2>/dev/null | grep -q '"amneziawg"'; }
_awg_ifaces() { uci -q show network | sed -n "s/^network\.\([A-Za-z0-9_]*\)\.proto='amneziawg'\$/\1/p"; }
_awg_is_steer() { case "$1" in zmwarp|zmwarp[0-9]) return 0 ;; esac; return 1; }
_awg_peer_sec() { uci -q -X show network | sed -n "s/^network\.\([^.=]*\)=amneziawg_$1\$/\1/p" | head -n1; }
_awg_zone_of() { # ИНТЕРФЕЙС -> имя зоны firewall, где он есть
	local z
	for z in $(uci -q -X show firewall | sed -n "s/^firewall\.\([^.=]*\)=zone\$/\1/p"); do
		case " $(uci -q get "firewall.$z.network") " in *" $1 "*) uci -q get "firewall.$z.name"; return 0 ;; esac
	done
	return 1
}
_awg_hs_age() { # ИНТЕРФЕЙС -> секунд с последнего рукопожатия или пусто
	local hs
	hs=$(awg show "$1" latest-handshakes 2>/dev/null | awk '$2 > 0 { print $2; exit }')
	[ -n "$hs" ] && echo $(( $(date +%s) - hs ))
}

_awg_health() {
	local i n=0 up=0 a st=0
	if _awg_installed; then
		for i in $(_awg_ifaces); do
			[ "$(uci -q get "network.$i.auto")" = 0 ] && [ ! -d "/sys/class/net/$i" ] && continue
			n=$((n + 1))
			a="$(_awg_hs_age "$i")"
			[ -n "$a" ] && [ "$a" -lt 180 ] && up=$((up + 1))
		done
		if [ "$n" = 0 ]; then st=5
		elif [ "$up" = "$n" ]; then st=1
		elif [ "$up" = 0 ]; then st=2
		else st=3; fi
	fi
	printf '%s,"awg_up":%s,"awg_total":%s' "$st" "$up" "$n"
}

_awg_iface_json() { # ИНТЕРФЕЙС
	local i="$1" p up=false addr ep host port age rx=0 tx=0 zone route auto desc warp=false owner=user mtu
	p="$(_awg_peer_sec "$i")"
	ifstatus "$i" 2>/dev/null | grep -q '"up": true' && up=true
	addr="$(uci -q get "network.$i.addresses" | tr ' ' ',')"
	mtu="$(uci -q get "network.$i.mtu")"
	host="$(uci -q get "network.$p.endpoint_host")"; port="$(uci -q get "network.$p.endpoint_port")"
	ep="$(awg show "$i" endpoints 2>/dev/null | awk '{ print $2; exit }')"
	[ -n "$ep" ] && [ "$ep" != "(none)" ] || ep="$host${port:+:$port}"
	age="$(_awg_hs_age "$i")"
	set -- $(awg show "$i" transfer 2>/dev/null | awk '{ r += $2; t += $3 } END { print r + 0, t + 0 }')
	rx="${1:-0}"; tx="${2:-0}"
	zone="$(_awg_zone_of "$i")"
	route="$(uci -q get "network.$p.route_allowed_ips")"
	auto="$(uci -q get "network.$i.auto")"
	desc="$(uci -q get "network.$p.description")"
	[ "$(uci -q get "network.$p.public_key")" = "$AWG_WARP_PEER" ] && warp=true
	_awg_is_steer "$i" && owner=steer
	printf '{"name":"%s","owner":"%s","up":%s,"enabled":%s,"address":"%s","mtu":"%s","endpoint":"%s","hs_age":"%s","rx":%s,"tx":%s,"zone":"%s","route_all":%s,"warp":%s,"desc":"%s"}' \
		"$i" "$owner" "$up" "$([ "$auto" = 0 ] && echo false || echo true)" "$(esc "$addr")" "$(esc "$mtu")" "$(esc "$ep")" "$age" \
		"$rx" "$tx" "$(esc "$zone")" "$([ "$route" = 1 ] && echo true || echo false)" "$warp" "$(esc "$desc")"
}

awg_status() {
	local i list="" sep="" running=false conf=false ep="" mih=false lp=luci-proto-amneziawg lv
	lv="$(_awg_pkg_ver luci-proto-amneziawg)"
	[ -n "$lv" ] || { lv="$(_awg_pkg_ver luci-app-amneziawg)"; [ -n "$lv" ] && lp=luci-app-amneziawg; }
	_job_alive awg && running=true
	for i in $(_awg_ifaces); do list="$list$sep$(_awg_iface_json "$i")"; sep=","; done
	if [ -s "$MIXOMO_WARP_CONF" ]; then
		conf=true
		ep="$(sed -n 's/^[[:space:]]*Endpoint[[:space:]]*=[[:space:]]*//p' "$MIXOMO_WARP_CONF" | head -n1)"
	fi
	[ -x /etc/init.d/mihomo ] && mih=true
	printf '{"running":%s,"phase":"%s","installed":%s,"kmod":"%s","tools":"%s","luci":"%s","luci_pkg":"%s","module":%s,"proto":%s,"steer":%s,"warp_conf":%s,"warp_path":"%s","warp_endpoint":"%s","mihomo":%s,"endpoints":"%s","steer_own":%s,"ifaces":[%s]}\n' \
		"$running" "$(cat "$AWG_RUN/phase" 2>/dev/null)" "$(_awg_installed && echo true || echo false)" \
		"$(esc "$(_awg_pkg_ver kmod-amneziawg)")" "$(esc "$(_awg_pkg_ver amneziawg-tools)")" "$(esc "$lv")" "$lp" \
		"$(_st_awg_loaded && echo true || echo false)" "$(_awg_proto_ok && echo true || echo false)" \
		"$(_st_warp_on && echo true || echo false)" "$conf" "$MIXOMO_WARP_CONF" "$(esc "$ep")" "$mih" "$AWG_ENDPOINTS" "$(_st_warp_own && echo true || echo false)" "$list"
}


do_awg_install() { # [update]
	echo "${1:-install}" > "$AWG_RUN/phase"
	_ensure_deps
	mkdir -p "$ST_RUN" "$AWG_DIR"
	[ "$1" = update ] && _awg_say "Переустанавливаем AmneziaWG из свежего релиза"
	ST_AWG_OWN=0 _st_install_awg "$1" || return 1
	_awg_say "Готово: AmneziaWG $(_awg_pkg_ver amneziawg-tools) установлен, модуль ядра загружен"
}

do_awg_remove() {
	local p
	echo remove > "$AWG_RUN/phase"
	_awg_say "Удаляем AmneziaWG"
	for p in luci-i18n-amneziawg-ru luci-proto-amneziawg luci-app-amneziawg amneziawg-tools kmod-amneziawg; do
		_pkg_is_installed "$p" || continue
		_awg_say "Удаляем $p"
		$DELETE "$p" >&2
	done
	rmmod amneziawg >/dev/null 2>&1
	sed -i -E '/^pkg (kmod-amneziawg|amneziawg-tools|luci-proto-amneziawg|luci-app-amneziawg|luci-i18n-amneziawg-ru)$/d' "$ST_OWNED" 2>/dev/null
	_rb_rpcd_ensure
	_awg_say "Готово, AmneziaWG удалён"
}

_awg_valid_ep() { printf '%s' "$1" | grep -Eq '^(\[[0-9A-Fa-f:]+\]|[A-Za-z0-9.-]+):[0-9]{1,5}$'; }

AWG_API1="https://api.cloudflareclient.com/v0a4005/reg"
AWG_API2="https://api.cloudflareclient.com/v0i1909051800/reg"
AWG_BOOT_PRIV="4OnO86dDLpqJ2U10ODwX3tarx6xlRGLfkmbSBtMgaHg="
AWG_BOOT_IP="172.16.0.3"
AWG_TEST_IF="zmawgtest"
AWG_TEST_HOSTS="162.159.192.1 188.114.97.1 188.114.96.3 162.159.193.2 162.159.195.2 188.114.98.2 188.114.99.2 8.6.112.2 8.34.70.2 8.34.146.2 8.39.125.2"
AWG_TEST_PORTS="2408 500 4500 1701"
AWG_I1_ICLOUD="<r 2><b 0x858000010001000000000669636c6f756403636f6d0000010001c00c000100010000105a00044d583737>"
AWG_I1_QUIC1="<b 0xc10000000114367096bb0fb3f58f3a3fb8aaacd61d63a1c8a40e14f7374b8a62dccba6431716c3abf6f5afbcfb39bd008000047c32e268567c652e6f4db58bff759bc8c5aaca183b87cb4d22938fe7d8dca22a679a79e4d9ee62e4bbb3a380dd78d4e8e48f26b38a1d42d76b371a5a9a0444827a69d1ab5872a85749f65a4104e931740b4dc1e2dd77733fc7fac4f93011cd622f2bb47e85f71992e2d585f8dc765a7a12ddeb879746a267393ad023d267c4bd79f258703e27345155268bd3cc0506ebd72e2e3c6b5b0f005299cd94b67ddabe30389c4f9b5c2d512dcc298c14f14e9b7f931e1dc397926c31fbb7cebfc668349c218672501031ecce151d4cb03c4c660b6c6fe7754e75446cd7de09a8c81030c5f6fb377203f551864f3d83e27de7b86499736cbbb549b2f37f436db1cae0a4ea39930f0534aacdd1e3534bc87877e2afabe959ced261f228d6362e6fd277c88c312d966c8b9f67e4a92e757773db0b0862fb8108d1d8fa262a40a1b4171961f0704c8ba314da2482ac8ed9bd28d4b50f7432d89fd800c25a50c5e2f5c0710544fef5273401116aa0572366d8e49ad758fcb29e6a92912e644dbe227c247cb3417eabfab2db16796b2fba420de3b1dc94e8361f1f324a331ddaf1e626553138860757fd0bf687566108b77b70fb9f8f8962eca599c4a70ed373666961a8cb506b96756d9e28b94122b20f16b54f118c0e603ce0b831efea614ad836df6cf9affbdd09596412547496967da758cec9080295d853b0861670b71d9abde0d562b1a6de82782a5b0c14d297f27283a895abc889a5f6703f0e6eb95f67b2da45f150d0d8ab805612d570c2d5cb6997ac3a7756226c2f5c8982ffbd480c5004b0660a3c9468945efde90864019a2b519458724b55d766e16b0da25c0557c01f3c11ddeb024b62e303640e17fdd57dedb3aeb4a2c1b7c93059f9c1d7118d77caac1cd0f6556e46cbc991c1bb16970273dea833d01e5090d061a0c6d25af2415cd2878af97f6d0e7f1f936247b394ecb9bd484da6be936dee9b0b92dc90101a1b4295e97a9772f2263eb09431995aa173df4ca2abd687d87706f0f93eaa5e13cbe3b574fa3cfe94502ace25265778da6960d561381769c24e0cbd7aac73c16f95ae74ff7ec38124f7c722b9cb151d4b6841343f29be8f35145e1b27021056820fed77003df8554b4155716c8cf6049ef5e318481460a8ce3be7c7bfac695255be84dc491c19e9dedc449dd3471728cd2a3ee51324ccb3eef121e3e08f8e18f0006ea8957371d9f2f739f0b89e4db11e5c6430ada61572e589519fbad4498b460ce6e4407fc2d8f2dd4293a50a0cb8fcaaf35cd9a8cc097e3603fbfa08d9036f52b3e7fcce11b83ad28a4ac12dba0395a0cc871cefd1a2856fffb3f28d82ce35cf80579974778bab13d9b3578d8c75a2d196087a2cd439aff2bb33f2db24ac175fff4ed91d36a4cdbfaf3f83074f03894ea40f17034629890da3efdbb41141b38368ab532209b69f057ddc559c19bc8ae62bf3fd564c9a35d9a83d14a95834a92bae6d9a29ae5e8ece07910d16433e4c6230c9bd7d68b47de0de9843988af6dc88b5301820443bd4d0537778bf6b4c1dd067fcf14b81015f2a67c7f2a28f9cb7e0684d3cb4b1c24d9b343122a086611b489532f1c3a26779da1706c6759d96d8ab>"

AWG_I1_SET="quic2 dns stun icloud sip quic"
AWG_I1_HOSTS="www.apple.com www.google.com www.microsoft.com cdn.jsdelivr.net"

_i1_hex() { if command -v hexdump >/dev/null 2>&1; then hexdump -ve '1/1 "%02x"'; else od -An -v -tx1 | tr -d ' \n'; fi; }
_i1_num() { # ОТ ДО
	awk -v a="$1" -v b="$2" -v s="$(head -c 4 /dev/urandom | _i1_hex)" 'BEGIN { x = 0; for (i = 1; i <= length(s); i++) x = x * 16 + index("0123456789abcdef", substr(s, i, 1)) - 1; srand(x); print a + int(rand() * (b - a + 1)) }'
}
_i1_str() { tr -dc 'a-z0-9' < /dev/urandom 2>/dev/null | head -c "$1"; }
_i1_host() { set -- $AWG_I1_HOSTS; eval "echo \"\${$(_i1_num 1 $#)}\""; }

_i1_dns() { # [ХОСТ] — A-запрос с EDNS0 и паддингом RFC 7830: случайные байты внутри корректного запроса
	local h="${1:-$(_i1_host)}" q="" l p
	for l in $(echo "$h" | tr '.' ' '); do q="$q$(printf '%02x' "${#l}")$(printf '%s' "$l" | _i1_hex)"; done
	p="$(_i1_num 60 180)"
	printf '<r 2><b 0x01000001000000000001%s0000010001000029100000000000%04x000c%04x><r %d>' "$q" $((p + 4)) "$p" "$p"
}

_i1_stun() { # STUN Binding Request с атрибутом SOFTWARE
	local s
	s=$(( $(_i1_num 4 8) * 4 ))
	printf '<b 0x0001%04x2112a442><r 12><b 0x8022%04x%s>' $((s + 4)) "$s" "$(_i1_str "$s" | _i1_hex)"
}

_i1_sip() { # [ХОСТ] — SIP OPTIONS, как у PJSIP
	local h="${1:-$(_i1_host)}"
	printf '<b 0x%s>' "$(printf '%s\r\n' \
		"OPTIONS sip:$h SIP/2.0" \
		"Via: SIP/2.0/UDP 192.168.$(_i1_num 0 255).$(_i1_num 2 254):5060;branch=z9hG4bK$(_i1_str 10)" \
		"From: <sip:$(_i1_str 8)@$h>;tag=$(_i1_num 100000 999999)" \
		"To: <sip:$h>" \
		"Call-ID: $(_i1_str 16)@$h" \
		"CSeq: $(_i1_num 1000 9999) OPTIONS" \
		"Max-Forwards: 70" \
		"User-Agent: PJSIP/2.13" \
		"Content-Length: 0" \
		"" | _i1_hex)"
}

_awg_i1() { # ИМЯ -> маска I1; dns, stun и sip каждый раз со свежими случайными полями
	case "$1" in
		quic) echo "$MIXOMO_AWG_I1" ;;
		quic2) echo "$AWG_I1_QUIC1" ;;
		icloud) echo "$AWG_I1_ICLOUD" ;;
		dns) _i1_dns ;;
		stun) _i1_stun ;;
		sip) _i1_sip ;;
	esac
}

_awg_write_conf() { # ПРИВАТНЫЙ ПИР v4 v6 ТОЧКА [I1]
	mkdir -p "$(dirname "$MIXOMO_WARP_CONF")"
	printf '%s\n' \
		"[Interface]" "PrivateKey = $1" "Address = ${3}${4:+, $4}" "DNS = 1.1.1.1, 1.0.0.1" "MTU = 1280" \
		"S1 = $MIXOMO_AWG_S1" "S2 = $MIXOMO_AWG_S2" "Jc = $MIXOMO_AWG_JC" "Jmin = $MIXOMO_AWG_JMIN" "Jmax = $MIXOMO_AWG_JMAX" \
		"H1 = $MIXOMO_AWG_H1" "H2 = $MIXOMO_AWG_H2" "H3 = $MIXOMO_AWG_H3" "H4 = $MIXOMO_AWG_H4" "I1 = ${6:-$MIXOMO_AWG_I1}" "" \
		"[Peer]" "PublicKey = $2" "AllowedIPs = 0.0.0.0/0, ::/0" "Endpoint = $5" "PersistentKeepalive = 25" \
		> "$MIXOMO_WARP_CONF"
	chmod 600 "$MIXOMO_WARP_CONF"
}

_awg_keys_santa() {
	local reg="$AWG_RUN/reg.json"
	_awg_say "Ключи: генератор santa-atmo.ru"
	rm -f "$reg"
	curl -fsSL --connect-timeout 10 --max-time 30 "$MIXOMO_WARP_PRIMARY" -o "$reg" || { echo "   не ответил"; return 1; }
	grep -q '"public_key"' "$reg" || { echo "   ответ без ключей"; rm -f "$reg"; return 1; }
	G_PRIV=$(grep -o '"key"[[:space:]]*:[[:space:]]*"[^"]*"' "$reg" | head -n1 | sed 's/.*:[[:space:]]*"//;s/"$//')
	G_PEER=$(grep -o '"public_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$reg" | head -n1 | sed 's/.*:[[:space:]]*"//;s/"$//')
	G_V4=$(grep -o '"v4"[[:space:]]*:[[:space:]]*"[^"]*"' "$reg" | sed -n '2p' | sed 's/.*:[[:space:]]*"//;s/"$//')
	G_V6=$(grep -o '"v6"[[:space:]]*:[[:space:]]*"[^"]*"' "$reg" | sed -n '2p' | sed 's/.*:[[:space:]]*"//;s/"$//')
	rm -f "$reg"
	[ -n "$G_PRIV" ] && [ -n "$G_PEER" ] && [ -n "$G_V4" ]
}
_awg_keys_wgcli() {
	local reg="$AWG_RUN/reg.json" pre
	_awg_say "Ключи: генератор wgcli.vercel.app (запасной)"
	rm -f "$reg"
	curl -fsSL --connect-timeout 10 --max-time 60 "$MIXOMO_WARP_SECONDARY" -o "$reg" || { echo "   не ответил"; return 1; }
	for pre in '@.result' '@'; do
		G_PEER="$(jsonfilter -i "$reg" -e "$pre.config.peers[0].public_key" 2>/dev/null)"
		[ -n "$G_PEER" ] || continue
		G_PRIV="$(jsonfilter -i "$reg" -e "$pre.key" 2>/dev/null)"
		G_V4="$(jsonfilter -i "$reg" -e "$pre.config.interface.addresses.v4" 2>/dev/null)"
		G_V6="$(jsonfilter -i "$reg" -e "$pre.config.interface.addresses.v6" 2>/dev/null)"
		break
	done
	rm -f "$reg"
	[ -n "$G_PRIV" ] && [ -n "$G_PEER" ] && [ -n "$G_V4" ] || { echo "   ответ без ключей"; return 1; }
}
_awg_genkey() { # -> G_PRIV и G_PUB
	local gen=awg
	command -v awg >/dev/null 2>&1 || gen=wg
	command -v "$gen" >/dev/null 2>&1 || return 1
	G_PRIV="$($gen genkey 2>/dev/null)"; G_PUB="$(printf '%s' "$G_PRIV" | $gen pubkey 2>/dev/null)"
	[ -n "$G_PRIV" ] && [ -n "$G_PUB" ]
}
_awg_cf_register() { # ПУТЬ
	local reg="$AWG_RUN/reg.json" api code pre id tok
	_awg_genkey || { echo "   нет awg/wg для ключей"; return 1; }
	for api in "$AWG_API1" "$AWG_API2" $ST_WARP_API; do
		rm -f "$reg"
		code=$(curl -s --connect-timeout 8 --max-time 20 $1 -X POST \
			-H 'Content-Type: application/json' -H 'User-Agent: okhttp/3.12.1' -H 'CF-Client-Version: a-6.10-2158' \
			-d "{\"key\":\"$G_PUB\",\"install_id\":\"\",\"fcm_token\":\"\",\"tos\":\"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",\"type\":\"Android\",\"model\":\"\",\"locale\":\"en_US\"}" \
			-o "$reg" -w '%{http_code}' "$api" 2>/dev/null)
		echo "   $api → HTTP ${code:-нет ответа}"
		[ "$code" = 200 ] || { [ "$code" = 000 ] || [ -z "$code" ] && break; continue; }
		for pre in '@.result' '@'; do
			G_PEER="$(jsonfilter -i "$reg" -e "$pre.config.peers[0].public_key" 2>/dev/null)"
			[ -n "$G_PEER" ] || continue
			G_V4="$(jsonfilter -i "$reg" -e "$pre.config.interface.addresses.v4" 2>/dev/null)"
			G_V6="$(jsonfilter -i "$reg" -e "$pre.config.interface.addresses.v6" 2>/dev/null)"
			id="$(jsonfilter -i "$reg" -e "$pre.id" 2>/dev/null)"; tok="$(jsonfilter -i "$reg" -e "$pre.token" 2>/dev/null)"
			break
		done
		if [ -n "$G_PEER" ] && [ -n "$G_V4" ]; then
			[ -n "$id" ] && [ -n "$tok" ] && curl -s --connect-timeout 8 --max-time 15 $1 -X PATCH \
				-H 'Content-Type: application/json' -H 'User-Agent: okhttp/3.12.1' -H "Authorization: Bearer $tok" \
				-d '{"warp_enabled":true}' -o /dev/null "$api/$id" 2>/dev/null
			rm -f "$reg"
			return 0
		fi
	done
	rm -f "$reg"
	return 1
}
_awg_api_ok() { # ПУТЬ — ответил ли API хоть чем-то (любой HTTP-код — дошли до Cloudflare)
	local code
	code=$(curl -s --connect-timeout 5 --max-time 8 $1 -o /dev/null -w '%{http_code}' "$AWG_API1/" 2>/dev/null)
	[ -n "$code" ] && [ "$code" != 000 ]
}

AWG_NO_I1=0
AWG_TRY_WAIT=8
_awg_try() {
	local dev="$1" conf="$AWG_RUN/try.conf" hs i=0 i1="$5"
	[ "$AWG_NO_I1" = 1 ] && i1=""
	ip link del "$dev" >/dev/null 2>&1
	ip link add dev "$dev" type amneziawg >/dev/null 2>&1 || return 2
	ip link set "$dev" mtu 1280 >/dev/null 2>&1
	ip addr add "$3/32" dev "$dev" >/dev/null 2>&1
	ip link set "$dev" up >/dev/null 2>&1
	printf '%s\n' "[Interface]" "PrivateKey = $2" \
		"Jc = $MIXOMO_AWG_JC" "Jmin = $MIXOMO_AWG_JMIN" "Jmax = $MIXOMO_AWG_JMAX" "S1 = $MIXOMO_AWG_S1" "S2 = $MIXOMO_AWG_S2" \
		"H1 = $MIXOMO_AWG_H1" "H2 = $MIXOMO_AWG_H2" "H3 = $MIXOMO_AWG_H3" "H4 = $MIXOMO_AWG_H4" ${i1:+"I1 = $i1"} "" \
		"[Peer]" "PublicKey = ${6:-$AWG_WARP_PEER}" "AllowedIPs = 0.0.0.0/0" "Endpoint = $4" "PersistentKeepalive = 5" > "$conf"
	if ! awg setconf "$dev" "$conf" >/dev/null 2>&1; then
		if [ -n "$i1" ] && sed -i '/^I1 = /d' "$conf" && awg setconf "$dev" "$conf" >/dev/null 2>&1; then
			[ "$AWG_NO_I1" = 1 ] || echo "   модуль AmneziaWG не знает маску I1 (версия 1.0) — пробуем без неё"
			AWG_NO_I1=1
		else
			rm -f "$conf"; return 1
		fi
	fi
	rm -f "$conf"
	while [ "$i" -lt "$AWG_TRY_WAIT" ]; do
		hs=$(awg show "$dev" latest-handshakes 2>/dev/null | awk '{ print $2; exit }')
		[ "${hs:-0}" -gt 0 ] 2>/dev/null && return 0
		sleep 0.5 2>/dev/null || sleep 1
		i=$((i + 1))
	done
	return 1
}
_awg_try_down() { ip link del "$1" >/dev/null 2>&1; }
_awg_ml() { [ "$AWG_NO_I1" = 1 ] || echo ", маска $(_awg_mask_name "$1")"; }
_awg_trace() { # ИНТЕРФЕЙС — идёт ли трафик: trace Cloudflare изнутри туннеля
	curl -s --interface "$1" --connect-timeout 4 --max-time 6 http://1.1.1.1/cdn-cgi/trace 2>/dev/null | grep -Eq '^warp=(on|plus)'
}
_awg_mask_name() {
	case "$1" in
		"$AWG_I1_ICLOUD") echo "iCloud-DNS" ;;
		"$AWG_I1_QUIC1") echo "QUIC-2" ;;
		"<r 2><b 0x01000001000000000001"*) echo "DNS" ;;
		"<b 0x0001"*) echo "STUN" ;;
		"<b 0x4f5054494f4e53"*) echo "SIP" ;;
		*) echo "QUIC" ;;
	esac
}

do_awg_gen() { # std ТОЧКА | check
	local mode="$1" ep="$2" path="" i hs a host port m n=0 best="" fall="" bmask="$MIXOMO_AWG_I1" bep="" masks tried=""
	echo gen > "$AWG_RUN/phase"
	mkdir -p "$AWG_RUN"
	G_PRIV=""; G_PEER=""; G_V4=""; G_V6=""
	if [ "$mode" = std ]; then
		_awg_say "Генерируем WARP"
		_awg_keys_santa || _awg_keys_wgcli || { _awg_say "Ключи: напрямую у Cloudflare"; _awg_cf_register ""; } ||
			{ echo "ОШИБКА: ключи не получены — генераторы и Cloudflare не ответили; попробуйте «Сгенерировать с проверкой связи»"; return 1; }
		_awg_say "Ключи получены (адрес $G_V4)"
		if [ "$ep" = auto ]; then
			_awg_say "Подбираем лучший endpoint"
			ep="$(_mixomo_warp_best_endpoint)"
		fi
		_awg_valid_ep "$ep" || ep="engage.cloudflareclient.com:4500"
		_awg_say "Endpoint: $ep"
		_awg_write_conf "$G_PRIV" "$G_PEER" "$G_V4" "$G_V6" "$ep"
		_awg_say "Готово: WARP.conf сохранён в $MIXOMO_WARP_CONF"
		return 0
	fi

	_awg_installed || { echo "ОШИБКА: для проверки связи нужен AmneziaWG — установите его выше"; return 1; }
	_st_awg_loaded || modprobe amneziawg >/dev/null 2>&1
	trap '_awg_try_down "$AWG_TEST_IF"' EXIT INT TERM
	AWG_NO_I1=0
	_awg_try "$AWG_TEST_IF" "$AWG_BOOT_PRIV" "$AWG_BOOT_IP" "127.0.0.1:9" "$MIXOMO_AWG_I1"
	if [ $? = 2 ]; then echo "ОШИБКА: не удаётся создать временный интерфейс AmneziaWG — модуль ядра не загружен; нажмите «Обновить / переустановить» или перезагрузите роутер"; return 1; fi
	_awg_try_down "$AWG_TEST_IF"
	_awg_say "Шаг 1 из 2: регистрация WARP у Cloudflare"
	if _awg_api_ok ""; then
		echo "   API Cloudflare открывается напрямую"
	else
		echo "   напрямую API не открывается — ищем обходной путь"
		path=""
		for i in $(_awg_ifaces); do
			a="$(_awg_hs_age "$i")"
			[ -n "$a" ] && [ "$a" -lt 180 ] || continue
			if _awg_api_ok "--interface $i"; then path="--interface $i"; echo "   через туннель $i"; break; fi
		done
		if [ -z "$path" ]; then
			echo "   поднимаем временный туннель на общих ключах"
			for host in 188.114.96.3 162.159.192.1 188.114.97.1; do
				for port in $AWG_TEST_PORTS; do
					for m in "$MIXOMO_AWG_I1" "$AWG_I1_ICLOUD" "$AWG_I1_QUIC1"; do
						[ "$AWG_NO_I1" = 1 ] && [ "$m" != "$MIXOMO_AWG_I1" ] && continue
						if _awg_try "$AWG_TEST_IF" "$AWG_BOOT_PRIV" "$AWG_BOOT_IP" "$host:$port" "$m" && _awg_api_ok "--interface $AWG_TEST_IF"; then
							path="--interface $AWG_TEST_IF"; bep="$host:$port"; bmask="$m"
							echo "   временный туннель: $host:$port$(_awg_ml "$m")"
							break 3
						fi
					done
				done
			done
		fi
		[ -n "$path" ] || { _awg_try_down "$AWG_TEST_IF"; echo "ОШИБКА: API Cloudflare недоступен ни напрямую, ни через туннели — WARP у этого провайдера, похоже, закрыт"; return 1; }
	fi
	if ! _awg_cf_register "$path"; then
		_awg_try_down "$AWG_TEST_IF"
		echo "ОШИБКА: Cloudflare не выдал ключи"; return 1
	fi
	_awg_try_down "$AWG_TEST_IF"
	_awg_say "Аккаунт WARP зарегистрирован (адрес $G_V4)"

	_awg_say "Шаг 2 из 2: ищем точку входа и маску, через которые идёт трафик"
	masks="$bmask"
	for m in "$MIXOMO_AWG_I1" "$AWG_I1_ICLOUD" "$AWG_I1_QUIC1"; do [ "$m" = "$bmask" ] || masks="$masks
$m"; done
	local ports="" oifs="$IFS" nl='
' h1="${bep%%:*}" allm meta torn seen
	allm="$masks
$(_i1_dns)
$(_i1_stun)
$(_i1_sip)"
	[ -n "$h1" ] || h1="${AWG_TEST_HOSTS%% *}"
	for port in $AWG_TEST_PORTS; do
		IFS="$nl"
		for m in $masks; do
			IFS="$oifs"
			[ "$AWG_NO_I1" = 1 ] && [ "$m" != "$bmask" ] && continue
			n=$((n + 1))
			if _awg_try "$AWG_TEST_IF" "$G_PRIV" "$G_V4" "$h1:$port" "$m" "$G_PEER"; then ports="$ports $port"; break; fi
		done
		IFS="$oifs"
		echo "   порт $port: $(case " $ports " in *" $port "*) echo открыт ;; *) echo закрыт ;; esac)"
	done
	if [ -z "$ports" ]; then
		echo "   основные порты молчат — перебираем 50 запасных портов WARP, это до двух минут"
		AWG_TRY_WAIT=4
		for port in $ST_WARP_PORTS_EXT; do
			_awg_try "$AWG_TEST_IF" "$G_PRIV" "$G_V4" "$h1:$port" "$bmask" "$G_PEER" && ports="$ports $port"
			[ "$(echo $ports | wc -w)" -ge 2 ] && break
		done
		AWG_TRY_WAIT=8
		[ -n "$ports" ] && echo "   открыты запасные порты:$ports"
	fi
	[ -n "$ports" ] || _rb_warn "Ни один порт WARP не ответил — провайдер, похоже, режет UDP к Cloudflare"
	for host in $h1 $AWG_TEST_HOSTS; do
		for port in $ports; do
			a="$host:$port"
			case " $tried " in *" $a "*) continue ;; esac
			tried="$tried $a"
			IFS="$nl"
			for m in $allm; do
				IFS="$oifs"
				[ "$AWG_NO_I1" = 1 ] && [ "$m" != "$bmask" ] && continue
				n=$((n + 1))
				[ "$n" -gt 60 ] && break 3
				if _awg_try "$AWG_TEST_IF" "$G_PRIV" "$G_V4" "$a" "$m" "$G_PEER"; then
					if _awg_trace "$AWG_TEST_IF"; then
						set -- $(_st_warp_probe "$AWG_TEST_IF"); torn="$3"
						if [ "$torn" = 1 ]; then
							echo "   $a$(_awg_ml "$m") — трафик пошёл и оборвался: так DPI рвёт туннель"
							[ -n "$fall" ] || fall="$a|$m"
							continue
						fi
						meta="потери $1%, $2 мс"
						best="$a"; bmask="$m"
						set -- $(_cf_meta "$AWG_TEST_IF")
						if [ $# -ge 4 ]; then
							meta="$meta, колония $1"
							[ "$2" != - ] && seen="$2" || seen=""
							shift 3
							[ "$*" != - ] && meta="$meta ($*)"
							[ -n "$seen" ] && meta="$meta, сайты видят $seen"
						fi
						echo "   $a$(_awg_ml "$m") — трафик идёт: $meta"
						break 3
					fi
					echo "   $a$(_awg_ml "$m") — рукопожатие есть, трафика нет"
					[ -n "$fall" ] || fall="$a|$m"
				else
					echo "   $a$(_awg_ml "$m") — нет ответа"
				fi
			done
			IFS="$oifs"
		done
	done
	IFS="$oifs"
	_awg_try_down "$AWG_TEST_IF"
	if [ -z "$best" ]; then
		if [ -n "$fall" ]; then
			best="${fall%%|*}"; bmask="${fall#*|}"
			_rb_warn "Трафик ни через одну точку не пошёл — записываю точку, где было рукопожатие ($best); туннель может не работать у этого провайдера"
		else
			best="engage.cloudflareclient.com:4500"; bmask="$MIXOMO_AWG_I1"
			_rb_warn "Ни одна точка не ответила с роутера — записываю стандартную ($best)"
		fi
	fi
	_awg_write_conf "$G_PRIV" "$G_PEER" "$G_V4" "$G_V6" "$best" "$bmask"
	if [ "$AWG_NO_I1" = 1 ]; then
		sed -i '/^I1 = /d' "$MIXOMO_WARP_CONF"
		_awg_say "Готово: WARP.conf сохранён в $MIXOMO_WARP_CONF (точка $best, без маски I1 — её не знает модуль)"
	else
		_awg_say "Готово: WARP.conf сохранён в $MIXOMO_WARP_CONF (точка $best, маска $(_awg_mask_name "$bmask"))"
	fi
}

# Параметры AmneziaWG из [Interface] -> опции uci так же, как их пишет LuCI при импорте конфига:
# HeaderProtectionKey -> awg_header_protection_key, Jc -> awg_jc, I1 -> awg_i1. Переносятся все,
# кроме ключа, адресов, DNS и MTU (их панель задаёт сама) — новые версии AmneziaWG заработают без правок панели.
_awg_iface_opts() { # ФАЙЛ -> строки «awg_имя значение»
	awk 'function trim(s) { gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s }
		{ l = $0; sub(/[#;].*$/, "", l); l = trim(l); if (l == "") next
		  if (l ~ /^\[.*\]$/) { sec = tolower(trim(substr(l, 2, length(l) - 2))); next }
		  if (sec != "interface") next
		  p = index(l, "="); if (!p) next
		  k = trim(substr(l, 1, p - 1)); v = trim(substr(l, p + 1))
		  if (v == "" || tolower(k) ~ /^(privatekey|address|dns|mtu|listenport|table|saveconfig|preup|postup|predown|postdown|fwmark)$/) next
		  n = ""
		  for (i = 1; i <= length(k); i++) { c = substr(k, i, 1); if (c ~ /[A-Z]/ && i > 1 && substr(k, i - 1, 1) ~ /[a-z0-9]/) n = n "_"; n = n tolower(c) }
		  gsub(/[^a-z0-9_]/, "", n); if (n == "") next
		  print "awg_" n, v }' "$1"
}
_awg_iface_set() { # ФАЙЛ ИНТЕРФЕЙС — записать эти параметры в uci
	local o v
	_awg_iface_opts "$1" | while read -r o v; do uci set "network.$2.$o=$v"; done
}
# Обратно: опции awg_* интерфейса -> строки конфига «Имя = значение» (awg_header_protection_key -> HeaderProtectionKey)
_awg_uci_conf() { # ИНТЕРФЕЙС
	local o v
	for o in $(uci -q show "network.$1" | sed -n "s/^network\.$1\.\(awg_[a-z0-9_]*\)=.*/\1/p"); do
		v="$(uci -q get "network.$1.$o")"
		[ -n "$v" ] || continue
		echo "$(echo "${o#awg_}" | awk -F_ '{ for (i = 1; i <= NF; i++) printf "%s%s", toupper(substr($i, 1, 1)), substr($i, 2) }') = $v"
	done
}

_awg_conf_kv() { # ФАЙЛ
	awk 'function trim(s) { gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s }
		{ l = $0; sub(/[#;].*$/, "", l); l = trim(l); if (l == "") next
		  if (l ~ /^\[.*\]$/) { sec = tolower(trim(substr(l, 2, length(l) - 2))); next }
		  p = index(l, "="); if (!p) next
		  print sec, tolower(trim(substr(l, 1, p - 1))), trim(substr(l, p + 1)) }' "$1"
}
_awg_cv() { awk -v s="$2" -v k="$3" '$1 == s && $2 == k { $1 = ""; $2 = ""; sub(/^  /, ""); print; exit }' "$1"; }

do_awg_create() { # ИМЯ МАРШРУТ(0|1) ЗОНА(0|1)
	local name="$1" route="$2" fw="$3" f="$AWG_DIR/pending.conf" kv="$AWG_RUN/kv" priv pub psk addr a allowed ep host port keep mtu k v p zone w=0 age
	echo create > "$AWG_RUN/phase"
	[ -s "$f" ] || { echo "ОШИБКА: нет конфигурации"; return 1; }
	_awg_installed || { echo "ОШИБКА: сначала установите AmneziaWG"; return 1; }
	_awg_conf_kv "$f" > "$kv"
	priv="$(_awg_cv "$kv" interface privatekey)"; pub="$(_awg_cv "$kv" peer publickey)"
	addr="$(_awg_cv "$kv" interface address)"; ep="$(_awg_cv "$kv" peer endpoint)"
	[ -n "$priv" ] && [ -n "$pub" ] && [ -n "$addr" ] && [ -n "$ep" ] || { echo "ОШИБКА: в файле нет PrivateKey, Address, PublicKey или Endpoint"; return 1; }
	case "$ep" in
		\[*\]:*) host="${ep%]:*}"; host="${host#[}"; port="${ep##*]:}" ;;
		*) host="${ep%:*}"; port="${ep##*:}" ;;
	esac
	psk="$(_awg_cv "$kv" peer presharedkey)"; allowed="$(_awg_cv "$kv" peer allowedips)"
	keep="$(_awg_cv "$kv" peer persistentkeepalive)"; mtu="$(_awg_cv "$kv" interface mtu)"

	_awg_say "Создаём интерфейс $name"
	uci -q delete "network.$name"
	for p in $(uci -q -X show network | sed -n "s/^network\.\([^.=]*\)=amneziawg_$name\$/\1/p"); do uci -q delete "network.$p"; done
	uci set "network.$name=interface"
	uci set "network.$name.proto=amneziawg"
	uci set "network.$name.private_key=$priv"
	for a in $(echo "$addr" | tr ',' ' '); do
		case "$a" in */*) ;; *:*) a="$a/128" ;; *) a="$a/32" ;; esac
		uci add_list "network.$name.addresses=$a"
	done
	uci set "network.$name.mtu=${mtu:-1280}"
	_awg_iface_set "$f" "$name"
	p="$(uci add network "amneziawg_$name")"
	uci set "network.$p.description=$name"
	uci set "network.$p.public_key=$pub"
	[ -n "$psk" ] && uci set "network.$p.preshared_key=$psk"
	for a in $(echo "${allowed:-0.0.0.0/0, ::/0}" | tr ',' ' '); do uci add_list "network.$p.allowed_ips=$a"; done
	uci set "network.$p.endpoint_host=$host"
	uci set "network.$p.endpoint_port=${port:-51820}"
	uci set "network.$p.persistent_keepalive=${keep:-25}"
	uci set "network.$p.route_allowed_ips=$route"
	uci commit network
	grep -qxF "$name" "$AWG_DIR/owned" 2>/dev/null || echo "$name" >> "$AWG_DIR/owned"

	if [ "$fw" = 1 ]; then
		zone="$(echo "$name" | cut -c1-11)"
		_awg_say "Зона firewall «$zone»: NAT и доступ из LAN в туннель"
		uci -q delete "firewall.zmawg_$name"; uci -q delete "firewall.zmawg_${name}_fwd"
		uci set "firewall.zmawg_$name=zone"
		uci set "firewall.zmawg_$name.name=$zone"
		uci add_list "firewall.zmawg_$name.network=$name"
		uci set "firewall.zmawg_$name.input=REJECT"
		uci set "firewall.zmawg_$name.output=ACCEPT"
		uci set "firewall.zmawg_$name.forward=REJECT"
		uci set "firewall.zmawg_$name.masq=1"
		uci set "firewall.zmawg_$name.mtu_fix=1"
		uci set "firewall.zmawg_${name}_fwd=forwarding"
		uci set "firewall.zmawg_${name}_fwd.src=$(_zm_lan_zone)"
		uci set "firewall.zmawg_${name}_fwd.dest=$zone"
		uci commit firewall
		/etc/init.d/firewall reload >/dev/null 2>&1
	fi
	[ "$route" = 1 ] && echo "!! Весь трафик роутера пойдёт через $name — если туннель упадёт, пропадёт и интернет"
	_awg_say "Поднимаем $name"
	ubus call network reload >/dev/null 2>&1
	sleep 2
	ubus call "network.interface.$name" up >/dev/null 2>&1
	while [ "$w" -lt 20 ]; do
		age="$(_awg_hs_age "$name")"
		[ -n "$age" ] && break
		ping -I "$name" -c 1 -W 1 1.1.1.1 >/dev/null 2>&1
		w=$((w + 1))
	done
	rm -f "$f" "$kv"
	if [ -n "$age" ]; then
		_awg_say "Готово: $name работает, рукопожатие с сервером есть"
	else
		echo "!! $name создан, но сервер пока не ответил — проверьте точку входа или подберите её кнопкой «Подобрать точку»"
	fi
}

do_awg_pick() { # ИНТЕРФЕЙС — разведка точки входа WARP (та же, что у Steer)
	local i="$1" p got
	echo pick > "$AWG_RUN/phase"
	p="$(_awg_peer_sec "$i")"
	[ "$(uci -q get "network.$p.public_key")" = "$AWG_WARP_PEER" ] || { echo "ОШИБКА: подбор точки есть только для туннелей WARP"; return 1; }
	mkdir -p "$ST_DIR" "$ST_RUN"
	rm -f "$ST_STOP_FLAG"
	ubus call "network.interface.$i" up >/dev/null 2>&1
	sleep 3
	_awg_say "Подбираем точку входа для $i"
	got="$(_st_warp_scan "$i" "$AWG_WARP_PEER" "" "")" || { echo "ОШИБКА: ни одна точка не ответила — провайдер может резать UDP к WARP"; return 1; }
	set -- $got
	_st_warp_link "$i" "$AWG_WARP_PEER" "$1" "$2" >/dev/null 2>&1
	uci set "network.$p.endpoint_host=$1"
	uci set "network.$p.endpoint_port=$2"
	uci commit network
	_awg_say "Готово: $i → $1:$2, колония $3"
	set -- $(_cf_meta "$i")
	[ $# -ge 4 ] && [ "$2" != - ] && _awg_say "Сайты видят этот туннель как $2"
	return 0
}

do_awg_regen() { # ИНТЕРФЕЙС — новые ключи WARP прямо в этот интерфейс
	local i="$1" p host port ep warp=0 route k v kk have=0 f="$AWG_DIR/pending.conf" rc
	echo gen > "$AWG_RUN/phase"
	mkdir -p "$AWG_RUN" "$AWG_DIR"
	p="$(_awg_peer_sec "$i")"
	[ "$(uci -q get "network.$p.public_key")" = "$AWG_WARP_PEER" ] && warp=1
	host="$(uci -q get "network.$p.endpoint_host")"; port="$(uci -q get "network.$p.endpoint_port")"
	case "$host" in *:*) ep="[$host]:$port" ;; *) ep="$host:$port" ;; esac
	[ "$warp" = 1 ] && _awg_valid_ep "$ep" || ep="engage.cloudflareclient.com:4500"
	route="$(uci -q get "network.$p.route_allowed_ips")"; [ "$route" = 1 ] || route=0
	G_PRIV=""; G_PEER=""; G_V4=""; G_V6=""
	_awg_say "Получаем новые ключи WARP для $i"
	_awg_keys_santa || _awg_keys_wgcli || { _awg_say "Ключи: напрямую у Cloudflare"; _awg_cf_register ""; } ||
		{ [ -d "/sys/class/net/$i" ] && _awg_say "Ключи: у Cloudflare через туннель $i" && _awg_cf_register "--interface $i"; } ||
		{ echo "ОШИБКА: ключи не получены — генераторы и Cloudflare не ответили"; return 1; }
	_awg_say "Ключи получены (адрес $G_V4)"
	if [ "$warp" = 1 ]; then
		[ -n "$(_awg_uci_conf "$i")" ] && have=1
	fi
	{
		echo "[Interface]"
		echo "PrivateKey = $G_PRIV"
		echo "Address = $G_V4${G_V6:+, $G_V6}"
		echo "MTU = $(uci -q get "network.$i.mtu" || echo 1280)"
		if [ "$have" = 1 ]; then
			_awg_uci_conf "$i"
		else
			AWG_NO_I1=0
			if _awg_installed; then
				_st_awg_loaded || modprobe amneziawg >/dev/null 2>&1
				_awg_try "$AWG_TEST_IF" "$G_PRIV" "$G_V4" "$ep" "$MIXOMO_AWG_I1" "$G_PEER"
				rc=$?
				_awg_try_down "$AWG_TEST_IF"
				[ "$rc" = 0 ] && _awg_say "Проверка: сервер WARP ответил на $ep" || _rb_warn "Проверка: сервер WARP на $ep не ответил — после создания подберите точку входа"
			fi
			printf '%s\n' "Jc = $MIXOMO_AWG_JC" "Jmin = $MIXOMO_AWG_JMIN" "Jmax = $MIXOMO_AWG_JMAX" "S1 = $MIXOMO_AWG_S1" "S2 = $MIXOMO_AWG_S2" \
				"H1 = $MIXOMO_AWG_H1" "H2 = $MIXOMO_AWG_H2" "H3 = $MIXOMO_AWG_H3" "H4 = $MIXOMO_AWG_H4"
			[ "$AWG_NO_I1" = 1 ] || echo "I1 = $MIXOMO_AWG_I1"
		fi
		echo ""
		echo "[Peer]"
		echo "PublicKey = $G_PEER"
		echo "AllowedIPs = 0.0.0.0/0, ::/0"
		echo "Endpoint = $ep"
		echo "PersistentKeepalive = 25"
	} > "$f"
	chmod 600 "$f"
	do_awg_create "$i" "$route" 0
}

_awg_steer_n() { case "$1" in zmwarp) echo 1 ;; *) echo "${1#zmwarp}" ;; esac; }

do_awg_steer_replace() { # ИНТЕРФЕЙС
	local i="$1" n c f="$AWG_DIR/pending.conf" kv="$AWG_RUN/kv" ep host port k v w=0 col
	echo replace > "$AWG_RUN/phase"
	if [ "$i" = "$ST_OWN_IF" ]; then
		# свой туннель Steer: новый конфиг становится своим конфигом
		mkdir -p "$ST_DIR" "$ST_RUN"
		if _st_warp_own; then
			mv -f "$f" "$ST_DIR/warp.pending"
			do_steer_warp_own
			return
		fi
		mv -f "$f" "$ST_WARP_OWN"; chmod 600 "$ST_WARP_OWN"
		_st_own_keep
		( ST_WARP_IF="$ST_OWN_IF"; _st_warp_own_iface "$ST_WARP_OWN" ) || return 1
		_st_warp_park "$ST_OWN_IF"
		_awg_say "Готово: конфиг сохранён — он заработает, когда на странице Steer выберете «Свой конфиг»"
		return 0
	fi
	if _st_warp_own; then
		echo "ОШИБКА: сейчас у Steer работает свой конфиг ($ST_OWN_IF) — автоматические туннели меняются, когда они включены"
		return 1
	fi
	n="$(_awg_steer_n "$i")"; c="$(_st_wconf "$n")"
	_awg_conf_kv "$f" > "$kv"
	[ -n "$(_awg_cv "$kv" interface privatekey)" ] && [ -n "$(_awg_cv "$kv" peer publickey)" ] && [ -n "$(_awg_cv "$kv" interface address)" ] ||
		{ rm -f "$f" "$kv"; echo "ОШИБКА: в конфиге нет PrivateKey, Address или PublicKey"; return 1; }
	ep="$(_awg_cv "$kv" peer endpoint)"
	case "$ep" in \[*\]:*) host="${ep%]:*}"; host="${host#[}"; port="${ep##*]:}" ;; ?*:*) host="${ep%:*}"; port="${ep##*:}" ;; esac
	[ -n "$host" ] || host="$(uci -q get "network.${i}_peer.endpoint_host")"
	[ -n "$port" ] || port="$(uci -q get "network.${i}_peer.endpoint_port")"
	mkdir -p "$ST_DIR"
	cp "$f" "$c"; chmod 600 "$c"
	_awg_say "Записываем конфиг в туннель Steer $i"
	_st_with "$n" _st_warp_iface_write "${host:-162.159.192.1}" "${port:-2408}"
	_awg_iface_set "$f" "$i"
	uci -q delete "network.$i.auto"
	uci commit network
	rm -f "$f" "$kv"
	ubus call network reload >/dev/null 2>&1
	sleep 2
	ubus call "network.interface.$i" up >/dev/null 2>&1
	while [ "$w" -lt 20 ]; do
		_st_warp_alive_if "$i" && break
		ping -I "$i" -c 1 -W 1 1.1.1.1 >/dev/null 2>&1
		w=$((w + 1))
	done
	if _st_warp_alive_if "$i"; then
		col="$(_st_colo_of "$i")"
		if [ -s "$ST_WARP_UP" ]; then
			{ while read -r x cc; do [ "$x" = "$i" ] || echo "$x $cc"; done < "$ST_WARP_UP"; echo "$i ${col:-?}"; } > "$ST_WARP_UP.tmp"
			mv "$ST_WARP_UP.tmp" "$ST_WARP_UP"
		fi
		_st_kick >/dev/null 2>&1
		_awg_say "Готово: $i работает${col:+, колония $col}"
	else
		echo "!! $i: конфиг записан, но сервер не ответил — проверьте точку входа или нажмите «Новый WARP»"
	fi
}

do_awg_steer_regen() { # ИНТЕРФЕЙС
	echo regen > "$AWG_RUN/phase"
	_job_alive steer && { echo "ОШИБКА: на странице Steer идёт операция — дождитесь её окончания"; return 1; }
	_st_warp_fix "$(_awg_steer_n "$1")" keys || return 1
	_st_kick >/dev/null 2>&1
	_awg_say "Готово: у $1 новые ключи WARP"
}

_awg_export() { # ИНТЕРФЕЙС -> .conf в stdout
	local i="$1" p a k v
	p="$(_awg_peer_sec "$i")"
	echo "[Interface]"
	echo "PrivateKey = $(uci -q get "network.$i.private_key")"
	echo "Address = $(uci -q get "network.$i.addresses" | sed 's/ /, /g')"
	v="$(uci -q get "network.$i.mtu")"; [ -n "$v" ] && echo "MTU = $v"
	_awg_uci_conf "$i"
	echo ""
	echo "[Peer]"
	echo "PublicKey = $(uci -q get "network.$p.public_key")"
	v="$(uci -q get "network.$p.preshared_key")"; [ -n "$v" ] && echo "PresharedKey = $v"
	echo "AllowedIPs = $(uci -q get "network.$p.allowed_ips" | sed 's/ /, /g')"
	a="$(uci -q get "network.$p.endpoint_host")"
	case "$a" in *:*) a="[$a]" ;; esac
	echo "Endpoint = $a:$(uci -q get "network.$p.endpoint_port")"
	v="$(uci -q get "network.$p.persistent_keepalive")"; [ -n "$v" ] && echo "PersistentKeepalive = $v"
}

_awg_delete() { # ИНТЕРФЕЙС
	local i="$1" p z
	ifdown "$i" >/dev/null 2>&1
	for p in $(uci -q -X show network | sed -n "s/^network\.\([^.=]*\)=amneziawg_$i\$/\1/p"); do uci -q delete "network.$p"; done
	uci -q delete "network.$i"
	uci commit network
	if [ "$(uci -q get "firewall.zmawg_$i")" = zone ]; then
		uci -q delete "firewall.zmawg_$i"; uci -q delete "firewall.zmawg_${i}_fwd"
	else
		for z in $(uci -q -X show firewall | sed -n "s/^firewall\.\([^.=]*\)=zone\$/\1/p"); do
			case " $(uci -q get "firewall.$z.network") " in *" $i "*) uci -q del_list "firewall.$z.network=$i" ;; esac
		done
	fi
	uci commit firewall
	/etc/init.d/firewall reload >/dev/null 2>&1
	ubus call network reload >/dev/null 2>&1
	sed -i "/^$i\$/d" "$AWG_DIR/owned" 2>/dev/null
}

_awg_check_name() { # ИМЯ
	printf '%s' "$1" | grep -Eq '^[a-z][a-z0-9_]{0,10}$' || { echo '{"error":"имя: латиница в нижнем регистре, цифры и _, начинается с буквы, до 11 символов"}'; return 1; }
	_awg_is_steer "$1" && { echo '{"error":"имена zmwarp заняты туннелями Steer"}'; return 1; }
	case "$1" in lan|wan|wan6|loopback) echo '{"error":"это имя занято системным интерфейсом"}'; return 1 ;; esac
	return 0
}

awg_action() {
	local action="$1" mode="$2" i name route fw conf ep
	case "$action" in
		install|update|remove|gen|create|pick|replace|regen)
			_job_alive awg && { echo '{"error":"дождитесь окончания текущей операции"}'; return 1; }
			_job_alive steer && { echo '{"error":"на странице Steer идёт операция — дождитесь её окончания"}'; return 1; }
			;;
	esac
	case "$action" in
		install) job_start awg do_awg_install ;;
		update)  job_start awg do_awg_install update ;;
		remove)
			_st_warp_on && { echo '{"error":"AmneziaWG нужен WARP в Steer — сначала удалите Steer на его странице"}'; return 1; }
			[ -n "$(_awg_ifaces)" ] && { echo '{"error":"сначала удалите интерфейсы AmneziaWG ниже"}'; return 1; }
			job_start awg do_awg_remove
			;;
		gen)
			i="${mode%%|*}"; ep="${mode#*|}"
			case "$i" in
				std)
					[ "$ep" = default ] && ep="engage.cloudflareclient.com:4500"
					[ "$ep" = auto ] || _awg_valid_ep "$ep" || { echo '{"error":"endpoint: адрес:порт, например 162.159.192.1:2408"}'; return 1; }
					job_start awg do_awg_gen std "$ep" ;;
				check)
					_awg_installed || { echo '{"error":"для проверки связи нужен AmneziaWG — установите его выше"}'; return 1; }
					job_start awg do_awg_gen check ;;
				*) echo '{"error":"неизвестный способ"}'; return 1 ;;
			esac
			;;
		conf_get) mixomo_warp_status ;;
		conf_set) mixomo_warp_config_set "$mode" ;;
		create)
			name="${mode%%|*}"; mode="${mode#*|}"
			route="${mode%%|*}"; mode="${mode#*|}"
			fw="${mode%%|*}"; conf="${mode#*|}"
			_awg_check_name "$name" || return 1
			case "$route$fw" in [01][01]) ;; *) echo '{"error":"неверные параметры"}'; return 1 ;; esac
			if [ -n "$(uci -q get "network.$name")" ] && [ "$(uci -q get "network.$name.proto")" != amneziawg ]; then
				echo '{"error":"интерфейс с таким именем уже есть и это не AmneziaWG"}'; return 1
			fi
			printf '%s\n' "$conf" | grep -qi '^[[:space:]]*\[interface\]' || { echo '{"error":"в конфигурации нет секции [Interface]"}'; return 1; }
			printf '%s\n' "$conf" | grep -qi '^[[:space:]]*\[peer\]' || { echo '{"error":"в конфигурации нет секции [Peer]"}'; return 1; }
			mkdir -p "$AWG_DIR"
			printf '%s\n' "$conf" | tr -d '\r' > "$AWG_DIR/pending.conf"
			chmod 600 "$AWG_DIR/pending.conf"
			job_start awg do_awg_create "$name" "$route" "$fw"
			;;
		replace)
			i="${mode%%|*}"; conf="${mode#*|}"
			[ "$(uci -q get "network.$i.proto")" = amneziawg ] || { echo '{"error":"нет такого интерфейса"}'; return 1; }
			if _awg_is_steer "$i"; then
				printf '%s\n' "$conf" | grep -qi '^[[:space:]]*\[peer\]' || { echo '{"error":"в конфигурации нет секции [Peer]"}'; return 1; }
				mkdir -p "$AWG_DIR"
				printf '%s\n' "$conf" | tr -d '\r' > "$AWG_DIR/pending.conf"
				chmod 600 "$AWG_DIR/pending.conf"
				job_start awg do_awg_steer_replace "$i"
				return
			fi
			printf '%s\n' "$conf" | grep -qi '^[[:space:]]*\[interface\]' || { echo '{"error":"в конфигурации нет секции [Interface]"}'; return 1; }
			printf '%s\n' "$conf" | grep -qi '^[[:space:]]*\[peer\]' || { echo '{"error":"в конфигурации нет секции [Peer]"}'; return 1; }
			route="$(uci -q get "network.$(_awg_peer_sec "$i").route_allowed_ips")"; [ "$route" = 1 ] || route=0
			mkdir -p "$AWG_DIR"
			printf '%s\n' "$conf" | tr -d '\r' > "$AWG_DIR/pending.conf"
			chmod 600 "$AWG_DIR/pending.conf"
			job_start awg do_awg_create "$i" "$route" 0
			;;
		regen)
			[ "$(uci -q get "network.$mode.proto")" = amneziawg ] || { echo '{"error":"нет такого интерфейса"}'; return 1; }
			if _awg_is_steer "$mode"; then job_start awg do_awg_steer_regen "$mode"; return; fi
			job_start awg do_awg_regen "$mode"
			;;
		pick)
			[ "$(uci -q get "network.$mode.proto")" = amneziawg ] || { echo '{"error":"нет такого интерфейса"}'; return 1; }
			_awg_is_steer "$mode" && { echo '{"error":"точки туннелей Steer подбираются на странице Steer"}'; return 1; }
			job_start awg do_awg_pick "$mode"
			;;
		endpoint)
			i="${mode%%|*}"; ep="${mode#*|}"
			[ "$(uci -q get "network.$i.proto")" = amneziawg ] || { echo '{"error":"нет такого интерфейса"}'; return 1; }
			_awg_is_steer "$i" && { echo '{"error":"точки туннелей Steer меняются на странице Steer"}'; return 1; }
			_awg_valid_ep "$ep" || { echo '{"error":"точка входа: адрес:порт, например 162.159.192.1:2408"}'; return 1; }
			name="$(_awg_peer_sec "$i")"
			case "$ep" in \[*\]:*) route="${ep%]:*}"; route="${route#[}" ;; *) route="${ep%:*}" ;; esac
			uci set "network.$name.endpoint_host=$route"
			uci set "network.$name.endpoint_port=${ep##*:}"
			uci commit network
			ifup "$i" >/dev/null 2>&1
			printf '{"ok":true}\n'
			;;
		restart|up|down)
			[ "$(uci -q get "network.$mode.proto")" = amneziawg ] || { echo '{"error":"нет такого интерфейса"}'; return 1; }
			case "$action" in
				restart) ifup "$mode" >/dev/null 2>&1 ;;
				up) uci -q delete "network.$mode.auto"; uci commit network; ifup "$mode" >/dev/null 2>&1 ;;
				down)
					_awg_is_steer "$mode" && { echo '{"error":"туннели Steer выключаются на странице Steer"}'; return 1; }
					uci set "network.$mode.auto=0"; uci commit network; ifdown "$mode" >/dev/null 2>&1 ;;
			esac
			printf '{"ok":true}\n'
			;;
		test)
			[ "$(uci -q get "network.$mode.proto")" = amneziawg ] || { echo '{"error":"нет такого интерфейса"}'; return 1; }
			local tr colo ip warp age seen="" city="" loss="" rtt="" torn=""
			age="$(_awg_hs_age "$mode")"
			tr="$(curl -s --interface "$mode" --connect-timeout 5 --max-time 10 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null)"
			[ -n "$tr" ] || tr="$(curl -s --interface "$mode" --connect-timeout 5 --max-time 10 https://1.1.1.1/cdn-cgi/trace 2>/dev/null)"
			colo="$(printf '%s\n' "$tr" | sed -n 's/^colo=//p')"; ip="$(printf '%s\n' "$tr" | sed -n 's/^ip=//p')"; warp="$(printf '%s\n' "$tr" | sed -n 's/^warp=//p')"
			if [ -n "$ip" ]; then
				set -- $(_cf_meta "$mode")
				if [ $# -ge 4 ]; then
					[ -n "$colo" ] || colo="$1"
					[ "$2" != - ] && seen="$2"
					shift 3; [ "$*" != - ] && city="$*"
				fi
				set -- $(_st_warp_probe "$mode"); loss="$1"; rtt="$2"; torn="$3"
				[ "$loss" -ge 100 ] 2>/dev/null && { loss=""; rtt=""; torn=""; }
			fi
			printf '{"ok":%s,"hs_age":"%s","colo":"%s","city":"%s","seen":"%s","ip":"%s","warp":"%s","loss":"%s","rtt":"%s","torn":%s}\n' "$([ -n "$ip" ] && echo true || echo false)" "$age" "$(esc "$colo")" "$(esc "$city")" "$(esc "$seen")" "$(esc "$ip")" "$(esc "$warp")" "$loss" "$rtt" "$([ "$torn" = 1 ] && echo true || echo false)"
			;;
		export)
			[ "$(uci -q get "network.$mode.proto")" = amneziawg ] || { echo '{"error":"нет такого интерфейса"}'; return 1; }
			printf '{"content":"%s"}\n' "$(esc_ml "$(_awg_export "$mode")")"
			;;
		delete)
			[ "$(uci -q get "network.$mode.proto")" = amneziawg ] || { echo '{"error":"нет такого интерфейса"}'; return 1; }
			_awg_is_steer "$mode" && { echo '{"error":"туннели Steer удаляются вместе со Steer на его странице"}'; return 1; }
			_awg_delete "$mode"
			printf '{"ok":true}\n'
			;;
		mihomo)
			[ -s "$MIXOMO_WARP_CONF" ] || { echo '{"error":"сначала получите WARP.conf"}'; return 1; }
			mixomo_warp_integrate_action
			;;
		*) echo '{"error":"неизвестное действие"}' ;;
	esac
}

redbtn_panel_gone() {
	local f r=0 line dir=/etc/zm-redbtn run="$JOBS_DIR/redbtn"
	_kill_match "redbtn_geo_watch"
	if [ -x /etc/init.d/zm-geodns ]; then
		/etc/init.d/zm-geodns stop >/dev/null 2>&1
		/etc/init.d/zm-geodns disable >/dev/null 2>&1
	fi
	rm -f /etc/init.d/zm-geodns /etc/rc.d/*zm-geodns
	for f in /tmp/dnsmasq.d/zm-geo.conf /tmp/dnsmasq.cfg*.d/zm-geo.conf; do
		[ -f "$f" ] && { rm -f "$f"; r=1; }
	done
	if grep -q redbtn_geo_watch "$CRON_FILE" 2>/dev/null; then
		sed -i '/redbtn_geo_watch/d' "$CRON_FILE"
		/etc/init.d/cron restart >/dev/null 2>&1
	fi
	if [ -s "$dir/hosts.ai" ]; then
		while IFS= read -r line; do
			[ -n "$line" ] || continue
			_hosts_has_line "$line" || { echo "$line" >> "$HOSTS_FILE"; r=1; }
		done < "$dir/hosts.ai"
	fi
	if grep -qx 'pkg https-dns-proxy' "$dir/owned" 2>/dev/null; then
		if [ -f "$DOH_OFF_FLAG" ] || ! /etc/init.d/https-dns-proxy enabled 2>/dev/null; then
			/etc/init.d/https-dns-proxy stop >/dev/null 2>&1
			$DELETE https-dns-proxy >&2
			rm -f /etc/config/https-dns-proxy
			r=1
		fi
	fi
	_doh_pkg || rm -f "$DOH_OFF_FLAG"
	[ -f "$DOH_OFF_FLAG" ] && { /etc/init.d/https-dns-proxy stop >/dev/null 2>&1; /etc/init.d/https-dns-proxy disable >/dev/null 2>&1; }
	[ "$r" = 1 ] && /etc/init.d/dnsmasq restart >/dev/null 2>&1
	[ -d "$dir" ] && _st_migrate
	rm -rf "$dir" "$run" /opt/zapret-manager-luci/autobypass_video /usr/share/zm-redbtn/doh.conf
	return 0
}

cmd="$1"; shift
if [ "$2" = @stdin ]; then ZM_IN="$(cat; echo .)"; set -- "$1" "${ZM_IN%.}"
elif [ "$1" = @stdin ]; then ZM_IN="$(cat; echo .)"; set -- "${ZM_IN%.}"; fi
case "$cmd" in
	status)                  status ;;
	system_info)             system_info ;;
	job_status)               job_status "$1" ;;
	log_tail)                  log_tail "$1" ;;
	zapret_action)              zapret_action "$1" ;;
	zapret_latest_version)       zapret_latest_version ;;
	zapret2_action)              zapret2_action "$1" ;;
	strategy_list_v)            strategy_list_v ;;
	strategy_set_v)              strategy_set_v "$1" ;;
	strategy_list_flowseal)       strategy_list_flowseal "$1" ;;
	strategy_set_flowseal)         strategy_set_flowseal "$1" ;;
	strategy_list_youtube)          strategy_list_youtube "$1" ;;
	strategy_set_youtube)            strategy_set_youtube "$1" ;;
	youtube_quic_set)                youtube_quic_set "$1" ;;
	discord_status)                 discord_status ;;
	discord_set_dv)                  discord_set_dv "$1" ;;
	discord_set_fake)                 discord_set_fake "$1" ;;
	game_status)                        game_status ;;
	game_set)                            game_set "$1" ;;
	game_set_fake)                        game_set_fake "$1" ;;
	game_toggle_xtreme)                    game_toggle_xtreme ;;
	system_status)                           system_status ;;
	system_check_connectivity)                system_check_connectivity ;;
	system_toggle_quic)                        system_toggle_quic ;;
	system_toggle_ipv6)                         system_toggle_ipv6 ;;
	system_toggle_flow_offloading_fix)           system_toggle_flow_offloading_fix ;;
	system_toggle_expert_mode)                    system_toggle_expert_mode ;;
	system_uninstall_panel)                        system_uninstall_panel ;;
	mirror_status)                                     mirror_status ;;
	mirror_set)                                          mirror_set "$1" ;;
	exclusions_status)                                     exclusions_status ;;
	exclusions_toggle)                                       exclusions_toggle "$1" ;;
	exclusions_clear)                                          exclusions_clear ;;
	exclusions_file_get)                             exclusions_file_get ;;
	exclusions_file_set)                             exclusions_file_set "$1" ;;
	exclusions_file_restore)                         exclusions_file_restore ;;
	nfqws_opt_get)                                   nfqws_opt_get ;;
	nfqws_opt_set)                                   nfqws_opt_set "$1" ;;
	tg_status)                                                   tg_status ;;
	tg_action)                                                    tg_action "$1" "$2" ;;
	tg_restart_all)                                                tg_restart_all ;;
	tgws_status)                                                    tgws_status ;;
	tgws_action)                                                     tgws_action "$1" ;;
	hosts_status)                      hosts_status ;;
	hosts_toggle)                       hosts_toggle "$1" ;;
	hosts_replace_geohide)              hosts_replace_geohide "$1" ;;
	hosts_reset)                        hosts_reset ;;
	hosts_file_get)                     hosts_file_get ;;
	hosts_file_set)                     hosts_file_set "$1" ;;
	doh_install)                         doh_install ;;
	doh_remove)                          doh_remove ;;
	doh_status)                          doh_status ;;
	doh_set)                              doh_set "$1" ;;
	test_status)                          test_status ;;
	test_action)                          test_action "$1" "$2" ;;
	test_results)                         test_results "$1" ;;
	zm_update_status)                     zm_update_status ;;
	zm_update_action)                     zm_update_action ;;
	mixomo_status)                        mixomo_status ;;
	mixomo_action)                        mixomo_action "$1" ;;
	mixomo_config_get)                    mixomo_config_get ;;
	mixomo_config_set)                    mixomo_config_set "$1" ;;
	mixomo_subscription_set)              mixomo_subscription_set "$1" ;;
	mixomo_magitrickle_list_set)          mixomo_magitrickle_list_set "$1" ;;
	mixomo_autorestart_set)               mixomo_autorestart_set "$1" "$2" ;;
	mixomo_ui_action)                     mixomo_ui_action "$1" ;;
	mixomo_warp_status)                   mixomo_warp_status ;;
	mixomo_warp_action)                   mixomo_warp_action "$1" ;;
	mixomo_warp_integrate_action)         mixomo_warp_integrate_action ;;
	mixomo_warp_config_set)               mixomo_warp_config_set "$1" ;;
	bytetube_installed)                   bytetube_installed ;;
	health)                               health ;;
	versions)                             versions_status "$1" ;;
	redbtn_panel_gone)                    redbtn_panel_gone ;;
	awg_status)                           awg_status ;;
	awg_action)                           awg_action "$1" "$2" ;;
	steer_status)                         steer_status ;;
	steer_action)                         steer_action "$1" "$2" ;;
	bytetube_action)                      bytetube_action "$1" ;;
	lan_ip)                               _zm_lan_ip ;;
	*) echo '{"error":"неизвестная команда"}'; exit 1 ;;
esac
ZM_INSTALLER_EOF
chmod 0755 '/opt/zapret-manager-luci/backend.sh'

mkdir -p /usr/libexec/rpcd
chmod 0755 /usr/libexec/rpcd
cat > '/usr/libexec/rpcd/zapret-manager' << 'ZM_INSTALLER_EOF'
#!/bin/sh

. /usr/share/libubox/jshn.sh

BACKEND="/opt/zapret-manager-luci/backend.sh"

list_methods() {
	json_init
	json_add_object "status";                 json_close_object
	json_add_object "system_info";            json_close_object
	json_add_object "job_status";             json_add_string "job" "string"; json_close_object
	json_add_object "log_tail";               json_add_string "job" "string"; json_close_object
	json_add_object "zapret_action";          json_add_string "action" "string"; json_close_object
	json_add_object "zapret_latest_version";  json_close_object
	json_add_object "zapret2_action";         json_add_string "action" "string"; json_close_object
	json_add_object "strategy_list_v";        json_close_object
	json_add_object "strategy_set_v";         json_add_string "version" "string"; json_close_object
	json_add_object "strategy_list_flowseal"; json_add_string "action" "string"; json_close_object
	json_add_object "strategy_set_flowseal";  json_add_string "name" "string"; json_close_object
	json_add_object "strategy_list_youtube";  json_add_string "action" "string"; json_close_object
	json_add_object "strategy_set_youtube";   json_add_string "name" "string"; json_close_object
	json_add_object "youtube_quic_set";       json_add_string "mode" "string"; json_close_object
	json_add_object "discord_status";         json_close_object
	json_add_object "discord_set_dv";         json_add_string "num" "string"; json_close_object
	json_add_object "discord_set_fake";       json_add_string "file" "string"; json_close_object
	json_add_object "game_status";            json_close_object
	json_add_object "game_set";               json_add_string "choice" "string"; json_close_object
	json_add_object "game_set_fake";          json_add_string "file" "string"; json_close_object
	json_add_object "game_toggle_xtreme";     json_close_object
	json_add_object "system_status";               json_close_object
	json_add_object "system_check_connectivity";   json_close_object
	json_add_object "system_toggle_quic";          json_close_object
	json_add_object "system_toggle_ipv6";          json_close_object
	json_add_object "system_toggle_flow_offloading_fix"; json_close_object
	json_add_object "system_toggle_expert_mode";   json_close_object
	json_add_object "system_uninstall_panel";      json_close_object
	json_add_object "mirror_status";               json_close_object
	json_add_object "mirror_set";                  json_add_string "id" "string"; json_close_object
	json_add_object "exclusions_status";           json_close_object
	json_add_object "exclusions_toggle";           json_add_string "ip" "string"; json_close_object
	json_add_object "exclusions_clear";            json_close_object
	json_add_object "exclusions_file_get";         json_close_object
	json_add_object "exclusions_file_set";         json_add_string "content" "string"; json_close_object
	json_add_object "exclusions_file_restore";     json_close_object
	json_add_object "nfqws_opt_get";               json_close_object
	json_add_object "nfqws_opt_set";               json_add_string "content" "string"; json_close_object
	json_add_object "tg_status";                   json_close_object
	json_add_object "tg_action";                   json_add_string "variant" "string"; json_add_string "action" "string"; json_close_object
	json_add_object "tg_restart_all";              json_close_object
	json_add_object "tgws_status";                 json_close_object
	json_add_object "tgws_action";                 json_add_string "action" "string"; json_close_object
	json_add_object "hosts_status";           json_close_object
	json_add_object "hosts_toggle";           json_add_string "block" "string"; json_close_object
	json_add_object "hosts_replace_geohide";  json_add_string "region" "string"; json_close_object
	json_add_object "hosts_reset";            json_close_object
	json_add_object "hosts_file_get";         json_close_object
	json_add_object "hosts_file_set";         json_add_string "content" "string"; json_close_object
	json_add_object "doh_status";             json_close_object
	json_add_object "doh_install";            json_close_object
	json_add_object "doh_remove";             json_close_object
	json_add_object "doh_set";                json_add_string "provider" "string"; json_close_object
	json_add_object "test_status";             json_close_object
	json_add_object "test_action";             json_add_string "action" "string"; json_add_string "mode" "string"; json_close_object
	json_add_object "test_results";            json_add_string "mode" "string"; json_close_object
	json_add_object "zm_update_status";        json_close_object
	json_add_object "zm_update_action";        json_close_object
	json_add_object "mixomo_status";           json_close_object
	json_add_object "mixomo_action";           json_add_string "action" "string"; json_close_object
	json_add_object "mixomo_config_get";       json_close_object
	json_add_object "mixomo_config_set";       json_add_string "content" "string"; json_close_object
	json_add_object "mixomo_subscription_set"; json_add_string "url" "string"; json_close_object
	json_add_object "mixomo_magitrickle_list_set"; json_add_string "id" "string"; json_close_object
	json_add_object "mixomo_autorestart_set";  json_add_string "mode" "string"; json_add_string "value" "string"; json_close_object
	json_add_object "mixomo_ui_action";        json_add_string "which" "string"; json_close_object
	json_add_object "mixomo_warp_status";      json_close_object
	json_add_object "mixomo_warp_action";      json_add_string "endpoint_mode" "string"; json_close_object
	json_add_object "mixomo_warp_integrate_action"; json_close_object
	json_add_object "mixomo_warp_config_set"; json_add_string "content" "string"; json_close_object
	json_add_object "bytetube_installed";     json_close_object
	json_add_object "health";                 json_close_object
	json_add_object "versions";               json_add_string "action" "string"; json_close_object
	json_add_object "awg_status";             json_close_object
	json_add_object "awg_action";             json_add_string "action" "string"; json_add_string "mode" "string"; json_close_object
	json_add_object "steer_status";           json_close_object
	json_add_object "steer_action";           json_add_string "action" "string"; json_add_string "mode" "string"; json_close_object
	json_add_object "bytetube_action";        json_add_string "action" "string"; json_close_object
	json_dump
}

call_method() {
	local method="$1"
	local input
	input="$(cat)"
	json_load "$input" 2>/dev/null

	case "$method" in
		status)                 "$BACKEND" status ;;
		system_info)            "$BACKEND" system_info ;;
		job_status)             json_get_var job job;         "$BACKEND" job_status "$job" ;;
		log_tail)                json_get_var job job;         "$BACKEND" log_tail "$job" ;;
		zapret_action)           json_get_var action action;   "$BACKEND" zapret_action "$action" ;;
		zapret_latest_version)   "$BACKEND" zapret_latest_version ;;
		zapret2_action)          json_get_var action action;   "$BACKEND" zapret2_action "$action" ;;
		strategy_list_v)         "$BACKEND" strategy_list_v ;;
		strategy_set_v)          json_get_var version version; "$BACKEND" strategy_set_v "$version" ;;
		strategy_list_flowseal)  json_get_var action action;   "$BACKEND" strategy_list_flowseal "$action" ;;
		strategy_set_flowseal)   json_get_var name name;       "$BACKEND" strategy_set_flowseal "$name" ;;
		strategy_list_youtube)   json_get_var action action;   "$BACKEND" strategy_list_youtube "$action" ;;
		strategy_set_youtube)    json_get_var name name;       "$BACKEND" strategy_set_youtube "$name" ;;
		youtube_quic_set)        json_get_var mode mode;       "$BACKEND" youtube_quic_set "$mode" ;;
		discord_status)          "$BACKEND" discord_status ;;
		discord_set_dv)          json_get_var num num;         "$BACKEND" discord_set_dv "$num" ;;
		discord_set_fake)        json_get_var file file;       "$BACKEND" discord_set_fake "$file" ;;
		game_status)             "$BACKEND" game_status ;;
		game_set)                json_get_var choice choice;   "$BACKEND" game_set "$choice" ;;
		game_set_fake)           json_get_var file file;       "$BACKEND" game_set_fake "$file" ;;
		game_toggle_xtreme)      "$BACKEND" game_toggle_xtreme ;;
		system_status)                 "$BACKEND" system_status ;;
		system_check_connectivity)     "$BACKEND" system_check_connectivity ;;
		system_toggle_quic)            "$BACKEND" system_toggle_quic ;;
		system_toggle_ipv6)            "$BACKEND" system_toggle_ipv6 ;;
		system_toggle_flow_offloading_fix) "$BACKEND" system_toggle_flow_offloading_fix ;;
		system_toggle_expert_mode)     "$BACKEND" system_toggle_expert_mode ;;
		system_uninstall_panel)        "$BACKEND" system_uninstall_panel ;;
		mirror_status)                 "$BACKEND" mirror_status ;;
		mirror_set)                    json_get_var id id;           "$BACKEND" mirror_set "$id" ;;
		exclusions_status)             "$BACKEND" exclusions_status ;;
		exclusions_toggle)             json_get_var ip ip;          "$BACKEND" exclusions_toggle "$ip" ;;
		exclusions_clear)              "$BACKEND" exclusions_clear ;;
		exclusions_file_get)           "$BACKEND" exclusions_file_get ;;
		exclusions_file_set)           json_get_var content content; printf '%s' "$content" | "$BACKEND" exclusions_file_set @stdin ;;
		exclusions_file_restore)       "$BACKEND" exclusions_file_restore ;;
		nfqws_opt_get)                 "$BACKEND" nfqws_opt_get ;;
		nfqws_opt_set)                 json_get_var content content; printf '%s' "$content" | "$BACKEND" nfqws_opt_set @stdin ;;
		tg_status)                     "$BACKEND" tg_status ;;
		tg_action)                     json_get_var variant variant; json_get_var action action; "$BACKEND" tg_action "$variant" "$action" ;;
		tg_restart_all)                "$BACKEND" tg_restart_all ;;
		tgws_status)                   "$BACKEND" tgws_status ;;
		tgws_action)                   json_get_var action action;   "$BACKEND" tgws_action "$action" ;;
		hosts_status)            "$BACKEND" hosts_status ;;
		hosts_toggle)            json_get_var block block;     "$BACKEND" hosts_toggle "$block" ;;
		hosts_replace_geohide)   json_get_var region region;   "$BACKEND" hosts_replace_geohide "$region" ;;
		hosts_reset)             "$BACKEND" hosts_reset ;;
		hosts_file_get)          "$BACKEND" hosts_file_get ;;
		hosts_file_set)          json_get_var content content; printf '%s' "$content" | "$BACKEND" hosts_file_set @stdin ;;
		doh_status)              "$BACKEND" doh_status ;;
		doh_install)             "$BACKEND" doh_install ;;
		doh_remove)              "$BACKEND" doh_remove ;;
		doh_set)                 json_get_var provider provider; "$BACKEND" doh_set "$provider" ;;
		test_status)             "$BACKEND" test_status ;;
		test_action)             json_get_var action action; json_get_var mode mode; "$BACKEND" test_action "$action" "$mode" ;;
		test_results)            json_get_var mode mode; "$BACKEND" test_results "$mode" ;;
		zm_update_status)        "$BACKEND" zm_update_status ;;
		zm_update_action)        "$BACKEND" zm_update_action ;;
		mixomo_status)           "$BACKEND" mixomo_status ;;
		mixomo_action)           json_get_var action action; "$BACKEND" mixomo_action "$action" ;;
		mixomo_config_get)       "$BACKEND" mixomo_config_get ;;
		mixomo_config_set)       json_get_var content content; printf '%s' "$content" | "$BACKEND" mixomo_config_set @stdin ;;
		mixomo_subscription_set) json_get_var url url; "$BACKEND" mixomo_subscription_set "$url" ;;
		mixomo_magitrickle_list_set) json_get_var id id; "$BACKEND" mixomo_magitrickle_list_set "$id" ;;
		mixomo_autorestart_set)  json_get_var mode mode; json_get_var value value; "$BACKEND" mixomo_autorestart_set "$mode" "$value" ;;
		mixomo_ui_action)        json_get_var which which; "$BACKEND" mixomo_ui_action "$which" ;;
		mixomo_warp_status)      "$BACKEND" mixomo_warp_status ;;
		mixomo_warp_action)      json_get_var endpoint_mode endpoint_mode; "$BACKEND" mixomo_warp_action "$endpoint_mode" ;;
		mixomo_warp_integrate_action) "$BACKEND" mixomo_warp_integrate_action ;;
		mixomo_warp_config_set) json_get_var content content; printf '%s' "$content" | "$BACKEND" mixomo_warp_config_set @stdin ;;
		bytetube_installed)      "$BACKEND" bytetube_installed ;;
		health)                  "$BACKEND" health ;;
		versions)                json_get_var action action; "$BACKEND" versions "$action" ;;
		awg_status)              "$BACKEND" awg_status ;;
		awg_action)              json_get_var action action; json_get_var mode mode; printf '%s' "$mode" | "$BACKEND" awg_action "$action" @stdin ;;
		steer_status)            "$BACKEND" steer_status ;;
		steer_action)            json_get_var action action; json_get_var mode mode; printf '%s' "$mode" | "$BACKEND" steer_action "$action" @stdin ;;
		bytetube_action)         json_get_var action action; "$BACKEND" bytetube_action "$action" ;;
		*) echo '{"error":"unknown method"}'; return 1 ;;
	esac
}

case "$1" in
	list) list_methods ;;
	call) call_method "$2" ;;
	*) echo '{"error":"usage: zapret-manager {list|call <method>}"}'; exit 1 ;;
esac
ZM_INSTALLER_EOF
chmod 0755 '/usr/libexec/rpcd/zapret-manager'

mkdir -p /usr/share/rpcd/acl.d
chmod 0755 /usr/share/rpcd/acl.d
cat > '/usr/share/rpcd/acl.d/luci-app-zapret-manager.json' << 'ZM_INSTALLER_EOF'
{
	"luci-app-zapret-manager": {
		"description": "Grant access to the Zapret Manager backend",
		"read": {
			"ubus": {
				"zapret-manager": [
					"status", "job_status", "log_tail", "system_info",
					"strategy_list_v", "strategy_list_flowseal", "strategy_list_youtube",
					"discord_status", "hosts_status", "hosts_file_get", "doh_status", "game_status",
					"system_status", "mirror_status", "exclusions_status", "exclusions_file_get", "nfqws_opt_get", "tg_status", "tgws_status",
					"test_status", "test_results", "zm_update_status", "mixomo_status", "mixomo_config_get",
					"mixomo_warp_status",
					"zapret_latest_version", "bytetube_installed", "health", "versions", "awg_status", "steer_status"
				],
				"system": [ "info" ]
			},
			"uci": [ "bytetube" ],
			"file": {
				"/usr/bin/bytetube": [ "exec" ],
				"/etc/init.d/bytetube": [ "exec" ]
			}
		},
		"write": {
			"ubus": {
				"zapret-manager": [
					"zapret_action", "zapret2_action",
					"strategy_set_v", "strategy_set_flowseal", "strategy_set_youtube", "youtube_quic_set",
					"discord_set_dv", "discord_set_fake",
					"hosts_toggle", "doh_set", "hosts_replace_geohide", "hosts_reset", "hosts_file_set", "doh_install", "doh_remove",
					"game_set", "game_set_fake", "game_toggle_xtreme",
					"system_check_connectivity", "system_toggle_quic", "system_toggle_ipv6",
					"system_toggle_flow_offloading_fix", "system_toggle_expert_mode", "system_uninstall_panel",
					"mirror_set", "exclusions_toggle", "exclusions_clear", "exclusions_file_set", "exclusions_file_restore", "nfqws_opt_set",
					"tg_action", "tg_restart_all", "tgws_action", "test_action", "zm_update_action",
					"mixomo_action", "mixomo_config_set", "mixomo_subscription_set",
					"mixomo_magitrickle_list_set", "mixomo_autorestart_set", "mixomo_ui_action",
					"mixomo_warp_action", "mixomo_warp_integrate_action", "mixomo_warp_config_set",
					"bytetube_action", "awg_action", "steer_action"
				]
			},
			"uci": [ "bytetube" ]
		}
	}
}
ZM_INSTALLER_EOF
chmod 0644 '/usr/share/rpcd/acl.d/luci-app-zapret-manager.json'

mkdir -p /usr/share/luci/menu.d
chmod 0755 /usr/share/luci/menu.d
cat > '/usr/share/luci/menu.d/luci-app-zapret-manager.json' << 'ZM_INSTALLER_EOF'
{
	"admin/services/zapret-manager": {
		"title": "Zapret Manager",
		"order": 60,
		"action": {
			"type": "alias",
			"path": "admin/services/zapret-manager/dashboard"
		}
	},
	"admin/services/zapret-manager/dashboard": {
		"title": "Дашборд",
		"order": 10,
		"action": { "type": "view", "path": "zapret-manager/dashboard" }
	},
	"admin/services/zapret-manager/steer": {
		"title": "Steer",
		"order": 26,
		"action": { "type": "view", "path": "zapret-manager/steer" }
	},
	"admin/services/zapret-manager/strategy": {
		"title": "Zapret",
		"order": 20,
		"action": { "type": "view", "path": "zapret-manager/strategy" }
	},
	"admin/services/zapret-manager/zapret2": {
		"title": "Zapret2",
		"order": 25,
		"action": { "type": "view", "path": "zapret-manager/zapret2" }
	},
	"admin/services/zapret-manager/hosts": {
		"title": "Hosts",
		"order": 40,
		"action": { "type": "view", "path": "zapret-manager/hosts" }
	},
	"admin/services/zapret-manager/doh": {
		"title": "DNS over HTTPS",
		"order": 50,
		"action": { "type": "view", "path": "zapret-manager/doh" }
	},
	"admin/services/zapret-manager/awg": {
		"title": "AmneziaWG",
		"order": 52,
		"action": { "type": "view", "path": "zapret-manager/awg" }
	},
	"admin/services/zapret-manager/tgproxy": {
		"title": "TG WS Proxy",
		"order": 55,
		"action": { "type": "view", "path": "zapret-manager/tgproxy" }
	},
	"admin/services/zapret-manager/mixomo": {
		"title": "Mixomo",
		"order": 57,
		"action": { "type": "view", "path": "zapret-manager/mixomo" }
	},
	"admin/services/zapret-manager/bytetube": {
		"title": "ByeTube",
		"order": 58,
		"action": { "type": "view", "path": "zapret-manager/bytetube" }
	},
	"admin/services/zapret-manager/system": {
		"title": "Система",
		"order": 60,
		"action": { "type": "view", "path": "zapret-manager/system" }
	}
}
ZM_INSTALLER_EOF
chmod 0644 '/usr/share/luci/menu.d/luci-app-zapret-manager.json'

mkdir -p /www/luci-static/resources/zapret-manager
chmod 0755 /www/luci-static/resources/zapret-manager
cat > '/www/luci-static/resources/zapret-manager/common.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require baseclass';
'require rpc';
'require ui';

var callStatus = rpc.declare({ object: 'zapret-manager', method: 'status', expect: {} });
var callAwgStatus = rpc.declare({ object: 'zapret-manager', method: 'awg_status', expect: {} });
var callAwgAction = rpc.declare({ object: 'zapret-manager', method: 'awg_action', params: ['action', 'mode'], expect: {} });
var callSteerStatus = rpc.declare({ object: 'zapret-manager', method: 'steer_status', expect: {} });
var callSteerAction = rpc.declare({ object: 'zapret-manager', method: 'steer_action', params: ['action', 'mode'], expect: {} });
var callSystemInfo = rpc.declare({ object: 'zapret-manager', method: 'system_info', expect: {} });
var callVersions = rpc.declare({ object: 'zapret-manager', method: 'versions', params: ['action'], expect: {} });
var callJobStatus = rpc.declare({ object: 'zapret-manager', method: 'job_status', params: ['job'], expect: {} });
var callLogTail = rpc.declare({ object: 'zapret-manager', method: 'log_tail', params: ['job'], expect: {} });
var callZapretAction = rpc.declare({ object: 'zapret-manager', method: 'zapret_action', params: ['action'], expect: {} });
var callZapretLatestVersion = rpc.declare({ object: 'zapret-manager', method: 'zapret_latest_version', expect: {} });
var callZapret2Action = rpc.declare({ object: 'zapret-manager', method: 'zapret2_action', params: ['action'], expect: {} });
var callStrategyListV = rpc.declare({ object: 'zapret-manager', method: 'strategy_list_v', expect: {} });
var callStrategySetV = rpc.declare({ object: 'zapret-manager', method: 'strategy_set_v', params: ['version'], expect: {} });
var callStrategyListFlowseal = rpc.declare({ object: 'zapret-manager', method: 'strategy_list_flowseal', params: ['action'], expect: {} });
var callStrategySetFlowseal = rpc.declare({ object: 'zapret-manager', method: 'strategy_set_flowseal', params: ['name'], expect: {} });
var callStrategyListYoutube = rpc.declare({ object: 'zapret-manager', method: 'strategy_list_youtube', params: ['action'], expect: {} });
var callStrategySetYoutube = rpc.declare({ object: 'zapret-manager', method: 'strategy_set_youtube', params: ['name'], expect: {} });
var callYoutubeQuicSet = rpc.declare({ object: 'zapret-manager', method: 'youtube_quic_set', params: ['mode'], expect: {} });
var callDiscordStatus = rpc.declare({ object: 'zapret-manager', method: 'discord_status', expect: {} });
var callDiscordSetDv = rpc.declare({ object: 'zapret-manager', method: 'discord_set_dv', params: ['num'], expect: {} });
var callDiscordSetFake = rpc.declare({ object: 'zapret-manager', method: 'discord_set_fake', params: ['file'], expect: {} });
var callGameStatus = rpc.declare({ object: 'zapret-manager', method: 'game_status', expect: {} });
var callGameSet = rpc.declare({ object: 'zapret-manager', method: 'game_set', params: ['choice'], expect: {} });
var callGameSetFake = rpc.declare({ object: 'zapret-manager', method: 'game_set_fake', params: ['file'], expect: {} });
var callGameToggleXtreme = rpc.declare({ object: 'zapret-manager', method: 'game_toggle_xtreme', expect: {} });
var callSystemStatus = rpc.declare({ object: 'zapret-manager', method: 'system_status', expect: {} });
var callSystemCheckConnectivity = rpc.declare({ object: 'zapret-manager', method: 'system_check_connectivity', expect: {} });
var callSystemToggleQuic = rpc.declare({ object: 'zapret-manager', method: 'system_toggle_quic', expect: {} });
var callSystemToggleIpv6 = rpc.declare({ object: 'zapret-manager', method: 'system_toggle_ipv6', expect: {} });
var callSystemToggleFlowOffloadingFix = rpc.declare({ object: 'zapret-manager', method: 'system_toggle_flow_offloading_fix', expect: {} });
var callSystemToggleExpertMode = rpc.declare({ object: 'zapret-manager', method: 'system_toggle_expert_mode', expect: {} });
var callSystemUninstallPanel = rpc.declare({ object: 'zapret-manager', method: 'system_uninstall_panel', expect: {} });
var callMirrorStatus = rpc.declare({ object: 'zapret-manager', method: 'mirror_status', expect: {} });
var callMirrorSet = rpc.declare({ object: 'zapret-manager', method: 'mirror_set', params: ['id'], expect: {} });
var callExclusionsStatus = rpc.declare({ object: 'zapret-manager', method: 'exclusions_status', expect: {} });
var callExclusionsToggle = rpc.declare({ object: 'zapret-manager', method: 'exclusions_toggle', params: ['ip'], expect: {} });
var callExclusionsClear = rpc.declare({ object: 'zapret-manager', method: 'exclusions_clear', expect: {} });
var callExclusionsFileGet = rpc.declare({ object: 'zapret-manager', method: 'exclusions_file_get', expect: {} });
var callExclusionsFileSet = rpc.declare({ object: 'zapret-manager', method: 'exclusions_file_set', params: ['content'], expect: {} });
var callExclusionsFileRestore = rpc.declare({ object: 'zapret-manager', method: 'exclusions_file_restore', expect: {} });
var callNfqwsOptGet = rpc.declare({ object: 'zapret-manager', method: 'nfqws_opt_get', expect: {} });
var callNfqwsOptSet = rpc.declare({ object: 'zapret-manager', method: 'nfqws_opt_set', params: ['content'], expect: {} });
var callTgStatus = rpc.declare({ object: 'zapret-manager', method: 'tg_status', expect: {} });
var callTgAction = rpc.declare({ object: 'zapret-manager', method: 'tg_action', params: ['variant', 'action'], expect: {} });
var callTgRestartAll = rpc.declare({ object: 'zapret-manager', method: 'tg_restart_all', expect: {} });
var callTgwsStatus = rpc.declare({ object: 'zapret-manager', method: 'tgws_status', expect: {} });
var callTgwsAction = rpc.declare({ object: 'zapret-manager', method: 'tgws_action', params: ['action'], expect: {} });
var callHostsStatus = rpc.declare({ object: 'zapret-manager', method: 'hosts_status', expect: {} });
var callHostsToggle = rpc.declare({ object: 'zapret-manager', method: 'hosts_toggle', params: ['block'], expect: {} });
var callHostsReplaceGeohide = rpc.declare({ object: 'zapret-manager', method: 'hosts_replace_geohide', params: ['region'], expect: {} });
var callHostsReset = rpc.declare({ object: 'zapret-manager', method: 'hosts_reset', expect: {} });
var callHostsFileGet = rpc.declare({ object: 'zapret-manager', method: 'hosts_file_get', expect: {} });
var callHostsFileSet = rpc.declare({ object: 'zapret-manager', method: 'hosts_file_set', params: ['content'], expect: {} });
var callDohStatus = rpc.declare({ object: 'zapret-manager', method: 'doh_status', expect: {} });
var callDohInstall = rpc.declare({ object: 'zapret-manager', method: 'doh_install', expect: {} });
var callDohRemove = rpc.declare({ object: 'zapret-manager', method: 'doh_remove', expect: {} });
var callDohSet = rpc.declare({ object: 'zapret-manager', method: 'doh_set', params: ['provider'], expect: {} });
var callTestStatus = rpc.declare({ object: 'zapret-manager', method: 'test_status', expect: {} });
var callTestAction = rpc.declare({ object: 'zapret-manager', method: 'test_action', params: ['action', 'mode'], expect: {} });
var callTestResults = rpc.declare({ object: 'zapret-manager', method: 'test_results', params: ['mode'], expect: {} });
var callZmUpdateStatus = rpc.declare({ object: 'zapret-manager', method: 'zm_update_status', expect: {} });
var callZmUpdateAction = rpc.declare({ object: 'zapret-manager', method: 'zm_update_action', expect: {} });
var callMixomoStatus = rpc.declare({ object: 'zapret-manager', method: 'mixomo_status', expect: {} });
var callMixomoAction = rpc.declare({ object: 'zapret-manager', method: 'mixomo_action', params: ['action'], expect: {} });
var callMixomoConfigGet = rpc.declare({ object: 'zapret-manager', method: 'mixomo_config_get', expect: {} });
var callMixomoConfigSet = rpc.declare({ object: 'zapret-manager', method: 'mixomo_config_set', params: ['content'], expect: {} });
var callMixomoApplySubscription = rpc.declare({ object: 'zapret-manager', method: 'mixomo_subscription_set', params: ['url'], expect: {} });
var callMixomoMagitrickleListSet = rpc.declare({ object: 'zapret-manager', method: 'mixomo_magitrickle_list_set', params: ['id'], expect: {} });
var callMixomoAutorestartSet = rpc.declare({ object: 'zapret-manager', method: 'mixomo_autorestart_set', params: ['mode', 'value'], expect: {} });
var callMixomoUiAction = rpc.declare({ object: 'zapret-manager', method: 'mixomo_ui_action', params: ['which'], expect: {} });
var callMixomoWarpStatus = rpc.declare({ object: 'zapret-manager', method: 'mixomo_warp_status', expect: {} });
var callMixomoWarpAction = rpc.declare({ object: 'zapret-manager', method: 'mixomo_warp_action', params: ['endpoint_mode'], expect: {} });
var callMixomoWarpIntegrateAction = rpc.declare({ object: 'zapret-manager', method: 'mixomo_warp_integrate_action', expect: {} });
var callMixomoWarpConfigSet = rpc.declare({ object: 'zapret-manager', method: 'mixomo_warp_config_set', params: ['content'], expect: {} });
var callBytetubeInstalled = rpc.declare({ object: 'zapret-manager', method: 'bytetube_installed', expect: {} });
var callHealth = rpc.declare({ object: 'zapret-manager', method: 'health', expect: {} });
var callBoardInfo = rpc.declare({ object: 'system', method: 'info', expect: {} });

function parseSize(v) {
	var m = String(v == null ? '' : v).trim().match(/^([\d.,]+)\s*([KMGT]?)i?B?$/i);
	if (!m) return NaN;
	return parseFloat(m[1].replace(',', '.')) * ({ '': 1, K: 1024, M: 1048576, G: 1073741824, T: 1099511627776 })[m[2].toUpperCase()];
}

// Скрытое значение (IP, адрес сервера): размыто, по нажатию показывается и снова прячется.
// Открытые запоминаются до перезагрузки страницы, чтобы перерисовка не прятала их обратно.
var _zmRevealed = {};
function secret(text) {
	text = String(text == null ? '' : text);
	var el = E('span', { 'class': 'zm-secret' + (_zmRevealed[text] ? ' zm-secret-open' : ''), 'title': _zmRevealed[text] ? 'Нажмите, чтобы скрыть' : 'Нажмите, чтобы показать', 'role': 'button', 'tabindex': '0' }, [ text ]);
	function toggle(ev) {
		if (ev) { ev.preventDefault(); ev.stopPropagation(); }
		var open = !el.classList.contains('zm-secret-open');
		el.classList.toggle('zm-secret-open', open);
		el.title = open ? 'Нажмите, чтобы скрыть' : 'Нажмите, чтобы показать';
		if (open) _zmRevealed[text] = true; else delete _zmRevealed[text];
	}
	el.addEventListener('click', toggle);
	el.addEventListener('keydown', function(ev) { if (ev.key === 'Enter' || ev.key === ' ') toggle(ev); });
	return el;
}

function fmtSize(b) {
	if (!isFinite(b)) return '—';
	var u = [ 'Б', 'КБ', 'МБ', 'ГБ', 'ТБ' ], i = 0;
	while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
	return (b >= 100 || i === 0 ? Math.round(b) : b.toFixed(1).replace(/\.0$/, '')) + ' ' + u[i];
}

function usageText(used, total) {
	if (!isFinite(used) || !isFinite(total) || total <= 0) return '—';
	return fmtSize(used) + ' из ' + fmtSize(total) + ' (' + Math.round(used / total * 100) + '%)';
}

/* Единый бейдж состояния службы: 1 — запущен, 2 — остановлен, 0 — не установлен */
function stateBadge(st, textOk) {
	if (st === 1) return badge(true, textOk || 'запущен', '');
	if (st === 2) return badge(false, '', 'остановлен');
	return badge(false, '', 'не установлен');
}

function detectMissingThemeVar() {
	if (document.documentElement.hasAttribute('data-zm-theme-checked')) return;
	document.documentElement.setAttribute('data-zm-theme-checked', '1');
	try {
		var declared = getComputedStyle(document.documentElement).getPropertyValue('--background-color-medium').trim();
		if (declared) return;

		var el = document.body, bg = '', hops = 0;
		while (el && hops < 6) {
			var c = getComputedStyle(el).backgroundColor;
			if (c && c !== 'rgba(0, 0, 0, 0)' && c !== 'transparent') { bg = c; break; }
			el = el.parentElement;
			hops++;
		}
		var m = bg.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
		if (!m) return;
		var luminance = (0.299 * (+m[1]) + 0.587 * (+m[2]) + 0.114 * (+m[3])) / 255;
		if (luminance < 0.5) document.documentElement.classList.add('zm-theme-dark');
	} catch (e) { /* определение темы не критично для работы панели — при любой ошибке просто ничего не делаем */ }
}

function injectCss() {
	detectMissingThemeVar();
	if (document.getElementById('zm-css')) return;
	var l = document.createElement('link');
	l.id = 'zm-css';
	l.rel = 'stylesheet';
	l.href = L.resource('view/zapret-manager/style.css');
	document.head.appendChild(l);
}

function badge(ok, textOk, textBad) {
	var cls = ok ? 'zm-ok' : (textBad === 'не установлен' ? 'zm-off' : 'zm-bad');
	return E('span', { 'class': 'zm-badge ' + cls }, [
		E('span', { 'class': 'zm-dot' }),
		ok ? textOk : textBad
	]);
}

function logMinPref() {
	try { return localStorage.getItem('zm.log.min') === '1'; } catch (e) { return false; }
}

function logBar(logEl) {
	if (!logEl._zmBar) {
		var btn = document.createElement('button');
		btn.type = 'button';
		btn.className = 'zm-log-min';
		var sync = function() {
			var min = logEl.classList.contains('zm-log-collapsed');
			btn.textContent = min ? '▢' : '_';
			btn.title = min ? 'Развернуть вывод' : 'Свернуть вывод';
		};
		btn.addEventListener('click', function(ev) {
			ev.preventDefault();
			ev.stopPropagation();
			var min = !logEl.classList.contains('zm-log-collapsed');
			logEl.classList.toggle('zm-log-collapsed', min);
			try { localStorage.setItem('zm.log.min', min ? '1' : '0'); } catch (e) {}
			sync();
			logEl.scrollTop = logEl.scrollHeight;
		});
		var bar = document.createElement('div');
		bar.className = 'zm-log-bar';
		bar.appendChild(btn);
		logEl._zmBar = bar;
		logEl._zmSync = sync;
		if (logMinPref()) logEl.classList.add('zm-log-collapsed');
	}
	logEl._zmSync();
	return logEl._zmBar;
}

function renderLog(logEl, text) {
	logEl.innerHTML = '';
	var lines = (text || '').split('\n');
	if (lines.some(function(l) { return l !== ''; })) logEl.appendChild(logBar(logEl));
	lines.forEach(function(line) {
		if (line === '') return;
		var div = document.createElement('div');
		var m = line.match(/^(==>)\s?(.*)$/);
		if (m) {
			var arrow = document.createElement('span');
			arrow.className = 'zm-log-arrow';
			arrow.textContent = m[1] + ' ';
			div.appendChild(arrow);
			var msgSpan = document.createElement('span');
			var msg = m[2];
			if (/ОШИБКА|error|не удалось/i.test(msg)) msgSpan.className = 'zm-log-msg-error';
			else if (/Готово|успешно|примен[её]н|установлен|удал[её]н|сгенерирован|сохран[её]н|переключен|обновлен|завершен/i.test(msg)) msgSpan.className = 'zm-log-msg-ok';
			else msgSpan.className = 'zm-log-msg-info';
			msgSpan.textContent = msg;
			div.appendChild(msgSpan);
		} else if (/^!!/.test(line)) {
			div.className = 'zm-log-msg-warn';
			div.textContent = line;
		} else {
			div.className = 'zm-log-code';
			div.textContent = line;
		}
		logEl.appendChild(div);
	});
	logEl.scrollTop = logEl.scrollHeight;
}

var _activePolls = {};

function pollJob(job, logEl, onDone, onTick) {
	if (_activePolls[job]) {
		clearInterval(_activePolls[job]);
		delete _activePolls[job];
	}
	logEl.classList.add('zm-show');
	var failCount = 0;
	var finished = false;
	var timer = setInterval(function() {
		if (finished) return;
		Promise.all([ callJobStatus(job), callLogTail(job) ]).then(function(res) {
			if (finished) return;
			failCount = 0;
			var st = res[0], lg = res[1];
			renderLog(logEl, (lg && lg.lines) || '');
			if (typeof onTick === 'function') onTick();
			if (st && st.done === true) {
				finished = true;
				clearInterval(timer);
				delete _activePolls[job];
				// Операция закончилась — пусть остальное (точки в меню Web UI и т. п.) обновится сразу
				try { window.dispatchEvent(new CustomEvent('zm:changed', { detail: { job: job } })); } catch (e) {}
				onDone(st.rc === '0');
			}
		}).catch(function() {
			if (finished) return;
			failCount++;
			if (failCount >= 8) {
				finished = true;
				clearInterval(timer);
				delete _activePolls[job];
				renderLog(logEl, '==> ОШИБКА: роутер не отвечает, не удалось получить статус операции.');
				onDone(false);
			}
		});
	}, 1200);
	_activePolls[job] = timer;
}

function refreshBanner(message) {
	return E('div', { 'class': 'zm-refresh-banner zm-show' }, [
		E('span', {}, message || 'Список меню LuCI мог измениться — выйдите и зайдите заново, чтобы увидеть изменения.'),
		E('button', {
			'class': 'cbi-button cbi-button-positive',
			'click': function() {
				fetch(L.url('admin/logout'), { credentials: 'same-origin' }).catch(function() {}).then(function() {
					location.reload();
				});
			}
		}, 'Выйти из LuCI')
	]);
}


function toastContainer() {
	var c = document.getElementById('zm-toast-container');
	if (!c) {
		c = document.createElement('div');
		c.id = 'zm-toast-container';
		document.body.appendChild(c);
	}
	return c;
}

function toast(message, kind, duration) {
	var container = toastContainer();
	var el = E('div', { 'class': 'zm-toast zm-toast-' + (kind || 'info') }, [
		E('span', { 'class': 'zm-toast-icon' }, kind === 'error' ? '✕' : (kind === 'warning' ? '!' : '✓')),
		E('span', { 'class': 'zm-toast-text' }, message)
	]);
	container.appendChild(el);
	requestAnimationFrame(function() { el.classList.add('zm-toast-show'); });
	var hide = function() {
		el.classList.remove('zm-toast-show');
		setTimeout(function() { el.parentNode && el.parentNode.removeChild(el); }, 250);
	};
	el.addEventListener('click', hide);
	setTimeout(hide, duration || (kind === 'error' ? 14000 : 9000));
}

function notifyStrategyResult(res, okLabel) {
	if (res.error) {
		toast(res.error, 'error');
		return false;
	}
	toast(okLabel + ' применена', 'info');
	return true;
}

return baseclass.extend({
	injectCss: injectCss,
	badge: badge,
	pollJob: pollJob,
	renderLog: renderLog,
	refreshBanner: refreshBanner,
	toast: toast,
	notifyStrategyResult: notifyStrategyResult,
	status: callStatus,
	systemInfo: callSystemInfo,
	jobStatus: callJobStatus,
	logTail: callLogTail,
	zapretAction: callZapretAction,
	zapretLatestVersion: callZapretLatestVersion,
	zapret2Action: callZapret2Action,
	strategyListV: callStrategyListV,
	strategySetV: callStrategySetV,
	strategyListFlowseal: callStrategyListFlowseal,
	strategySetFlowseal: callStrategySetFlowseal,
	strategyListYoutube: callStrategyListYoutube,
	strategySetYoutube: callStrategySetYoutube,
	youtubeQuicSet: callYoutubeQuicSet,
	discordStatus: callDiscordStatus,
	discordSetDv: callDiscordSetDv,
	discordSetFake: callDiscordSetFake,
	gameStatus: callGameStatus,
	gameSet: callGameSet,
	gameSetFake: callGameSetFake,
	gameToggleXtreme: callGameToggleXtreme,
	systemStatus: callSystemStatus,
	systemCheckConnectivity: callSystemCheckConnectivity,
	systemToggleQuic: callSystemToggleQuic,
	systemToggleIpv6: callSystemToggleIpv6,
	systemToggleFlowOffloadingFix: callSystemToggleFlowOffloadingFix,
	systemToggleExpertMode: callSystemToggleExpertMode,
	systemUninstallPanel: callSystemUninstallPanel,
	mirrorStatus: callMirrorStatus,
	mirrorSet: callMirrorSet,
	exclusionsStatus: callExclusionsStatus,
	exclusionsToggle: callExclusionsToggle,
	exclusionsClear: callExclusionsClear,
	exclusionsFileGet: callExclusionsFileGet,
	exclusionsFileSet: callExclusionsFileSet,
	exclusionsFileRestore: callExclusionsFileRestore,
	nfqwsOptGet: callNfqwsOptGet,
	nfqwsOptSet: callNfqwsOptSet,
	tgStatus: callTgStatus,
	tgAction: callTgAction,
	tgRestartAll: callTgRestartAll,
	tgwsStatus: callTgwsStatus,
	tgwsAction: callTgwsAction,
	hostsStatus: callHostsStatus,
	hostsToggle: callHostsToggle,
	hostsReplaceGeohide: callHostsReplaceGeohide,
	hostsReset: callHostsReset,
	hostsFileGet: callHostsFileGet,
	hostsFileSet: callHostsFileSet,
	dohStatus: callDohStatus,
	dohInstall: callDohInstall,
	dohRemove: callDohRemove,
	dohSet: callDohSet,
	testStatus: callTestStatus,
	testAction: callTestAction,
	testResults: callTestResults,
	zmUpdateStatus: callZmUpdateStatus,
	zmUpdateAction: callZmUpdateAction,
	mixomoStatus: callMixomoStatus,
	mixomoAction: callMixomoAction,
	mixomoConfigGet: callMixomoConfigGet,
	mixomoConfigSet: callMixomoConfigSet,
	mixomoApplySubscription: callMixomoApplySubscription,
	mixomoMagitrickleListSet: callMixomoMagitrickleListSet,
	mixomoAutorestartSet: callMixomoAutorestartSet,
	mixomoUiAction: callMixomoUiAction,
	mixomoWarpStatus: callMixomoWarpStatus,
	mixomoWarpAction: callMixomoWarpAction,
	mixomoWarpIntegrateAction: callMixomoWarpIntegrateAction,
	mixomoWarpConfigSet: callMixomoWarpConfigSet,
	bytetubeInstalled: callBytetubeInstalled,
	health: callHealth,
	awgStatus: callAwgStatus,
	awgAction: callAwgAction,
	steerStatus: callSteerStatus,
	versions: callVersions,
	steerAction: callSteerAction,
	boardInfo: callBoardInfo,
	parseSize: parseSize,
	fmtSize: fmtSize,
	secret: secret,
	usageText: usageText,
	stateBadge: stateBadge
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/zapret-manager/common.js'

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/dashboard.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require ui';
'require zapret-manager.common as zm';

return view.extend({
	load: function() {
		zm.injectCss();
		return Promise.all([
			zm.status(),
			zm.dohStatus().catch(function() { return {}; }),
			zm.hostsStatus().catch(function() { return { items: [] }; }),
			zm.systemStatus().catch(function() { return {}; }),
			zm.systemInfo().catch(function() { return {}; }),
			zm.zmUpdateStatus().catch(function() { return {}; }),
			zm.health().catch(function() { return {}; }),
			zm.boardInfo().catch(function() { return {}; })
		]);
	},

	render: function(all) {
		var view = this;
		var data = all[0], dohData = all[1], hostsData = all[2], sysData = all[3];
		var sysInfo = all[4] || {};
		var zmUpdate = all[5] || {};
		var healthData = all[6] || {};
		var boardInfo = all[7] || {};
		var wrap = E('div', { 'class': 'zm-wrap' });
		var overviewEl = E('div', {});
		var cards = E('div', { 'class': 'zm-cards' });

		var DOH_LABELS = { cloudflare: 'Cloudflare', google: 'Google', quad9: 'Quad9', xbox: 'XBOX', geohide_ru: 'GeoHide RU', geohide_eu: 'GeoHide EU', geohide_us: 'GeoHide US' };

		function row(label, node) {
			return E('div', { 'class': 'zm-row' }, [ E('span', { 'class': 'zm-label' }, label), node ]);
		}

		function dohNames(doh) {
			if (doh.current) return DOH_LABELS[doh.current] || doh.current;
			var names = (doh.resolvers || []).map(function(r) {
				return DOH_LABELS[r.provider] || (String(r.url || '').replace(/^https?:\/\//, '').split('/')[0]) || '';
			}).filter(function(n) { return n; });
			return names.length ? names.join(' + ') : 'провайдер не определён';
		}

		function st(h, key, fallback) {
			return (h && typeof h[key] === 'number') ? h[key] : fallback;
		}

		function renderOverview(d, doh, hosts, sys, h) {
			var hostsEnabled = (hosts.items || []).filter(function(it) { return it.enabled; }).length;
			var hostsTotal = (hosts.items || []).length;

			var sysFlags = [];
			if (sys.quic_blocked) sysFlags.push('QUIC заблокирован');
			if (sys.ipv6_enabled) sysFlags.push('IPv6 в Zapret включён');
			if (sys.flow_offloading_fix) sysFlags.push('Flow Offloading fix');

			var zrSt = st(h, 'zapret', d.zapret === 'installed' ? (d.zapret_running ? 1 : 2) : 0);
			var zr2St = st(h, 'zapret2', d.zapret2 === 'installed' ? (d.zapret2_running ? 1 : 2) : 0);
			var dohSt = st(h, 'doh', doh.installed ? 1 : 0);
			var dohNode = zm.stateBadge(dohSt);
			if (dohSt !== 0) dohNode = E('span', { 'style': 'display:inline-flex; align-items:center; gap:8px; flex-wrap:wrap' }, [
				dohNode, E('span', {}, dohNames(doh))
			]);

			var items = [];
			items.push(row('Zapret', zm.stateBadge(zrSt)));
			if (zrSt !== 0 && d.zapret_version) items.push(row('Версия Zapret', E('span', {}, d.zapret_version)));
			if (zrSt !== 0 && d.strategy) items.push(row('Стратегия', E('span', {}, d.strategy)));
			items.push(row('Zapret2', zm.stateBadge(zr2St)));
			var warnBadge = function(text) { return E('span', { 'class': 'zm-badge zm-warn' }, [ E('span', { 'class': 'zm-dot' }), text ]); };
			var offBadge = function(text) { return E('span', { 'class': 'zm-badge zm-off' }, [ E('span', { 'class': 'zm-dot' }), text ]); };
			// Steer: 2 — должен работать, но не работает; 5 — выключен или сервисы не выбраны.
			var stSt = st(h, 'steer', 0);
			var stVia = { warp: 'через WARP', own: 'через свой WARP', vpn: 'через VPN' }[h.steer_exit] || '';
			items.push(row('Steer', stSt === 1 ? zm.badge(true, 'работает' + (stVia ? ' · ' + stVia : ''), '')
				: stSt === 2 ? zm.badge(false, '', 'не работает' + (stVia ? ' · ' + stVia : ''))
				: stSt === 5 ? offBadge(h.steer_off ? 'выключен' : h.steer_exit === 'none' ? 'подключите WARP или VPN' : 'сервисы не выбраны')
				: zm.badge(false, '', 'не установлен')));
			items.push(row('ByeTube', zm.stateBadge(st(h, 'bytetube', 0))));
			items.push(row('TG WS Proxy', zm.stateBadge(st(h, 'tg', 0))));
			items.push(row('Mixomo', zm.stateBadge(st(h, 'mixomo', 0))));
			items.push(row('DNS over HTTPS', dohNode));
			var awgSt = st(h, 'awg', 0);
			items.push(row('AmneziaWG', awgSt === 1 ? zm.badge(true, h.awg_up ? 'туннелей работает: ' + h.awg_up : 'установлен', '')
				: awgSt === 3 ? warnBadge('работает ' + (h.awg_up || 0) + ' из ' + (h.awg_total || 0))
				: awgSt === 2 ? zm.badge(false, '', 'туннели не отвечают')
				: awgSt === 5 ? offBadge('установлен, туннелей нет')
				: zm.badge(false, '', 'не установлен')));
			items.push(row('Домены в hosts', hosts.geohide
				? zm.badge(true, 'GeoHide ' + hosts.geohide.toUpperCase(), '')
				: hostsTotal
					? (hostsEnabled > 0 ? zm.badge(true, 'включено ' + hostsEnabled + ' из ' + hostsTotal, '') : E('span', { 'class': 'zm-badge zm-off' }, [ E('span', { 'class': 'zm-dot' }), 'ничего не включено' ]))
					: E('span', {}, '—')));
			if (sysFlags.length) items.push(row('Система', E('span', { 'style': 'overflow-wrap:anywhere' }, sysFlags.join(', '))));

			var half = Math.ceil(items.length / 2);

			return E('div', { 'class': 'zm-card', 'style': 'margin-bottom:4px' }, [
				E('h3', {}, 'Компоненты'),
				E('div', { 'class': 'bt-cols' }, [
					E('div', { 'class': 'bt-col' }, items.slice(0, half)),
					E('div', { 'class': 'bt-col' }, items.slice(half))
				])
			]);
		}

		function renderCards() {
			cards.innerHTML = '';

			var mem = boardInfo.memory || {};
			var ramAvail = mem.available != null ? mem.available : ((mem.free || 0) + (mem.buffered || 0) + (mem.cached || 0));
			var ru = zm.parseSize(sysInfo.root_used), rf = zm.parseSize(sysInfo.root_free);
			var tu = zm.parseSize(sysInfo.tmp_used), tf = zm.parseSize(sysInfo.tmp_free);

			var rows = [
				row('Модель', E('span', {}, sysInfo.model || '—')),
				row('Архитектура', E('span', {}, sysInfo.arch || '—')),
				row('Платформа', E('span', {}, sysInfo.target || '—')),
				row('OpenWrt', E('span', {}, sysInfo.openwrt || '—'))
			];
			// Шкалы — как в боковой панели Web UI: подпись и значение сверху, полоска снизу;
			// жёлтая и красная — по тем же порогам. Классы zmw-mem-* дают в Web UI тот же вид, что и в меню.
			function meter(label, val, pct, mid, hi) {
				pct = Math.max(0, Math.min(100, pct || 0));
				return E('div', { 'class': 'zm-meter zmw-mem-row' + (pct >= hi ? ' zm-meter-hi zmw-mem-hi' : pct >= mid ? ' zm-meter-mid zmw-mem-mid' : '') }, [
					E('div', { 'class': 'zm-meter-head zmw-mem-head' }, [
						E('span', { 'class': 'zm-meter-label zmw-mem-label' }, label),
						E('span', { 'class': 'zm-meter-val zmw-mem-val' }, val)
					]),
					E('div', { 'class': 'zm-meter-bar zmw-mem-bar' }, [ E('i', { 'style': 'width:' + pct.toFixed(0) + '%' }) ])
				]);
			}
			function usage(label, used, total) {
				return total > 0 ? meter(label, zm.fmtSize(used) + ' из ' + zm.fmtSize(total), used / total * 100, 65, 85) : null;
			}
			var memRows = [];
			var t = parseFloat(sysInfo.cpu_temp);
			if (!isNaN(t)) memRows.push(meter('Температура ЦП', sysInfo.cpu_temp + ' °C', t, 65, 80));
			var cl = parseInt(sysInfo.cpu_load, 10);
			if (!isNaN(cl)) memRows.push(meter('Нагрузка ЦП', cl + '%', cl, 70, 90));
			memRows.push(usage('ОЗУ', mem.total - ramAvail, mem.total));
			memRows.push(usage('Флеш', ru, ru + rf));
			memRows.push(usage('/tmp', tu, tu + tf));
			memRows = memRows.filter(Boolean);
			var up = parseInt(boardInfo.uptime, 10), extras = [];
			if (up > 0) {
				var dd = Math.floor(up / 86400), hh = Math.floor(up % 86400 / 3600), mm = Math.floor(up % 3600 / 60);
				extras.push(row('Время работы', E('span', {}, (dd ? dd + ' дн ' : '') + (dd || hh ? hh + ' ч ' : '') + mm + ' мин')));
			}
			var ims = parseInt(sysInfo.inet_ms, 10);
			extras.push(row('Интернет', sysInfo.inet === 'ok'
				? E('span', { 'class': 'zm-badge ' + (ims >= 200 ? 'zm-warn' : 'zm-ok') }, [ E('span', { 'class': 'zm-dot' }), isNaN(ims) ? 'есть' : 'есть · ' + ims + ' мс' ])
				: sysInfo.inet === 'fail'
					? E('span', { 'class': 'zm-badge zm-bad' }, [ E('span', { 'class': 'zm-dot' }), 'нет' ])
					: E('span', { 'class': 'zm-badge zm-off' }, [ E('span', { 'class': 'zm-dot' }), 'проверяем…' ])));
			rows = rows.concat(extras);

			cards.appendChild(E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Система'),
				E('div', { 'class': 'bt-cols' }, [
					E('div', { 'class': 'bt-col' }, rows),
					E('div', { 'class': 'bt-col zm-meters' }, memRows)
				])
			]));
		}

		function refreshOverview() {
			Promise.all([
				zm.status(),
				zm.dohStatus().catch(function() { return {}; }),
				zm.hostsStatus().catch(function() { return { items: [] }; }),
				zm.systemStatus().catch(function() { return {}; }),
				zm.health().catch(function() { return {}; })
			]).then(function(res) {
				overviewEl.innerHTML = '';
				overviewEl.appendChild(renderOverview(res[0], res[1], res[2], res[3], res[4]));
			});
		}

		// ── версии пакетов ──
		var verEl = E('div', {});
		var verTimer = null, verData = null;

		function renderVersions() {
			verEl.innerHTML = '';
			var d = verData || { items: [], pending: true };
			var items = d.items || [];
			var card = E('div', { 'class': 'zm-card' }, [ E('h3', {}, 'Версии') ]);
			if (!items.length) {
				card.appendChild(E('p', { 'class': 'zm-hint' }, d.pending ? 'Проверяем версии установленных пакетов…' : 'Пакеты Zapret Manager пока не установлены.'));
			} else {
				var rows = items.map(function(it) {
					var fresh = !it.latest || it.latest === it.installed;
					return row(it.name, E('span', { 'style': 'display:inline-flex; align-items:center; gap:8px; flex-wrap:wrap' }, [
						E('span', {}, it.installed),
						fresh ? E('span', { 'class': 'zm-badge zm-ok' }, [ E('span', { 'class': 'zm-dot' }), 'актуальна' ])
							: E('span', { 'class': 'zm-badge zm-warn' }, [ E('span', { 'class': 'zm-dot' }), 'доступна ' + it.latest ])
					]));
				});
				var half = Math.ceil(rows.length / 2);
				card.appendChild(E('div', { 'class': 'bt-cols' }, [
					E('div', { 'class': 'bt-col' }, rows.slice(0, half)),
					E('div', { 'class': 'bt-col' }, rows.slice(half))
				]));
			}
			card.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', {
					'class': 'cbi-button cbi-button-action',
					'disabled': d.pending ? '' : null,
					'click': function() { loadVersions('refresh'); }
				}, d.pending ? 'Проверяем…' : 'Проверить снова'),
				d.ts ? E('span', { 'class': 'zm-hint', 'style': 'margin:0' }, 'Проверено: ' + d.ts) : ''
			]));
			verEl.appendChild(card);
		}

		function loadVersions(action) {
			if (verTimer) { clearTimeout(verTimer); verTimer = null; }
			if (action && verData) { verData.pending = true; renderVersions(); }
			(zm.versions ? zm.versions(action || '') : Promise.resolve({ items: [] })).then(function(res) {
				verData = res || { items: [] };
				renderVersions();
				if (verData.pending && document.body.contains(verEl)) verTimer = setTimeout(function() { loadVersions(''); }, 3000);
			}).catch(function() { verData = { items: (verData && verData.items) || [] }; renderVersions(); });
		}

		overviewEl.appendChild(renderOverview(data, dohData, hostsData, sysData, healthData));
		renderCards();
		var updateEl = E('div', {});
		wrap.appendChild(updateEl);
		wrap.appendChild(E('div', { 'class': 'zm-header' }, [
			E('h2', {}, 'Zapret Manager LuCI'),
			E('span', { 'class': 'zm-header-by' }, 'by StressOzz · v' + (zmUpdate.current || '?')),
			E('div', { 'class': 'zm-header-links' }, [
				E('a', { 'href': 'http://stresskvn.lol/', 'target': '_blank', 'rel': 'noreferrer' }, 'StressKVN — обход белых списков!'),
				E('a', { 'href': 'https://t.me/stressozz_manager', 'target': '_blank', 'rel': 'noreferrer' }, 'Сообщество Telegram'),
				E('a', { 'href': 'http://' + window.location.hostname + ':7788/', 'target': '_blank', 'rel': 'noreferrer', 'class': 'zm-webui-link' }, 'Web UI ↗')
			])
		]));
		wrap.appendChild(overviewEl);
		wrap.appendChild(cards);
		wrap.appendChild(verEl);
		renderVersions();
		loadVersions('auto');

		this.refreshOverview = refreshOverview;

		// Температура, нагрузка и память обновляются сами; состояние компонентов — реже
		var sysTick = 0, sysBusy = false;
		var sysTimer = setInterval(function() {
			if (!document.body.contains(cards)) { if (sysTick > 2) clearInterval(sysTimer); sysTick++; return; }
			if (document.hidden || sysBusy) return;
			sysBusy = true;
			sysTick++;
			Promise.all([
				zm.systemInfo().catch(function() { return null; }),
				zm.boardInfo().catch(function() { return null; })
			]).then(function(r) {
				if (r[0] && !r[0].error) sysInfo = r[0];
				if (r[1] && r[1].memory) boardInfo = r[1];
				renderCards();
				if (sysTick % 3 === 0) refreshOverview();
			}).catch(function() {}).then(function() { sysBusy = false; });
		}, 5000);

		var zmUpdateBusy = false;
		function waitForServerAndReload() {
			setTimeout(function() { location.href = L.url('admin/logout'); }, 4000);
		}
		function renderZmUpdate() {
			updateEl.innerHTML = '';
			if (!zmUpdate.latest || zmUpdate.latest === zmUpdate.current || zmUpdate.newer === false) return;
			updateEl.appendChild(E('div', { 'class': 'zm-refresh-banner zm-show' }, [
				E('span', {}, 'Доступна новая версия панели Zapret Manager: ' + zmUpdate.latest + ' (у вас установлена ' + zmUpdate.current + ').'),
				E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() {
						if (zmUpdateBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						zmUpdateBusy = true;
						zm.toast('Скачиваем и проверяем новую версию…', 'info', 4000);
						zm.zmUpdateAction().then(function(res) {
							zmUpdateBusy = false;
							if (res.error) { zm.toast('Обновление не началось: ' + res.error, 'error', 8000); return; }
							zm.toast('Устанавливаем версию ' + (res.version || zmUpdate.latest) + ' — через 4 секунды вы будете выведены из LuCI. Подождите полминуты и зайдите заново', 'warning', 8000);
							waitForServerAndReload();
						}).catch(function() { zmUpdateBusy = false; });
					}
				}, 'Обновить панель')
			]));
		}
		renderZmUpdate();

		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/dashboard.js'

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/doh.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var PROVIDERS = [
	{ id: 'google', label: 'Google' },
	{ id: 'cloudflare', label: 'Cloudflare' },
	{ id: 'quad9', label: 'Quad9' },
	{ id: 'xbox', label: 'XBOX' },
	{ id: 'geohide_ru', label: 'GeoHide RU' },
	{ id: 'geohide_eu', label: 'GeoHide EU' },
	{ id: 'geohide_us', label: 'GeoHide US' }
];

function label(id) {
	for (var i = 0; i < PROVIDERS.length; i++) if (PROVIDERS[i].id === id) return PROVIDERS[i].label;
	return '';
}

function badge(cls, text) {
	return E('span', { 'class': 'zm-badge ' + cls }, [ E('span', { 'class': 'zm-dot' }), text ]);
}

function row(l, node) {
	return E('div', { 'class': 'zm-row' }, [ E('span', { 'class': 'zm-label' }, l), node ]);
}

function host(url) {
	var m = /^https?:\/\/([^\/]+)/.exec(url || '');
	return m ? m[1] : url;
}

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.dohStatus();
	},

	render: function(data) {
		data = data || {};
		var wrap = E('div', { 'class': 'zm-wrap' });
		var card = E('div', { 'class': 'zm-card' });
		var logEl = E('pre', { 'class': 'zm-log' });
		var busy = false;

		function refresh() {
			return zm.dohStatus().then(function(res) { data = res || {}; render(); });
		}

		function job(call, name, startText, okText, errText) {
			if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			zm.toast(startText, 'warning');
			busy = true;
			call().then(function(res) {
				if (res.error) { busy = false; zm.toast(res.error, 'error'); return; }
				if (!res.started) { busy = false; return; }
				zm.pollJob(name, logEl, function(ok) {
					busy = false;
					zm.toast(ok ? okText : errText, ok ? 'info' : 'error');
					refresh();
				});
			}).catch(function() { busy = false; });
		}

		function render() {
			card.innerHTML = '';
			card.appendChild(E('h3', {}, 'DNS over HTTPS'));
			card.appendChild(E('p', { 'class': 'zm-hint' }, 'Шифрованный DNS для всей сети: запросы устройств уходят к выбранному провайдеру по HTTPS, и провайдер интернета их не видит и не подменяет.'));
			card.appendChild(row('Пакет', data.installed ? badge('zm-ok', 'установлен') : badge('zm-off', 'не установлен')));

			var list = data.resolvers || [];
			if (data.installed) {
				card.appendChild(row('Служба', data.running ? badge('zm-ok', 'работает') : badge('zm-bad', 'остановлена')));
				// Что на самом деле записано в /etc/config/https-dns-proxy.
				if (!list.length) card.appendChild(row('Сейчас используется', E('span', {}, 'резолвер не выбран')));
				else card.appendChild(E('div', { 'class': 'zm-row', 'style': 'align-items:flex-start; flex-wrap:nowrap' }, [
					E('span', { 'class': 'zm-label', 'style': 'line-height:22px' }, list.length > 1 ? 'Сейчас используются' : 'Сейчас используется'),
					E('div', { 'style': 'display:flex; flex-direction:column; gap:6px; min-width:0; flex:1 1 auto' }, list.map(function(r) {
						return E('div', { 'style': 'line-height:22px; overflow-wrap:anywhere' }, [
							E('b', {}, label(r.provider) || host(r.url)), ' · ' + r.url + (r.port ? ' · порт ' + r.port : '')
						]);
					}))
				]));
				card.appendChild(row('Перехват DNS устройств', data.force_dns
					? badge('zm-ok', 'включён')
					: badge('zm-off', data.steer_active ? 'выключен — работает Steer' : 'выключен')));
			}

			card.appendChild(E('div', { 'class': 'zm-actions' }, data.installed
				? [ E('button', { 'class': 'cbi-button cbi-button-remove', 'click': function() {
					job(zm.dohRemove, 'doh_remove', 'Удаляем DNS over HTTPS', 'DNS over HTTPS удалён', 'Ошибка удаления');
				} }, 'Удалить') ]
				: [ E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
					job(zm.dohInstall, 'doh_install', 'Устанавливаем DNS over HTTPS', 'DNS over HTTPS установлен — выберите провайдера', 'Ошибка установки');
				} }, 'Установить DNS over HTTPS') ]));

			if (data.installed) {
				card.appendChild(E('h4', { 'style': 'margin:14px 0 8px' }, 'Провайдер'));
				// Подсвечивается только тот, что стоит на самом деле и один: при двух и больше
				// резолверах (так пакет настроен из коробки) выбор заменит их одним.
				card.appendChild(E('div', { 'class': 'zm-grid' }, PROVIDERS.map(function(p) {
					return E('div', {
						'class': 'zm-tile' + (data.current === p.id ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Меняем DNS на ' + p.label, 'warning');
							zm.dohSet(p.id).then(function(res) {
								busy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(p.label + ' применён', 'info');
								refresh();
							}).catch(function() { busy = false; });
						}
					}, p.label);
				})));
				if (list.length > 1) card.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас настроено несколько резолверов сразу, поэтому ни одна кнопка не подсвечена. Выбор провайдера заменит их одним.'));
				else if (list.length === 1 && !data.current) card.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас стоит резолвер не из списка — он настроен вручную. Выбор провайдера заменит его.'));
			}
			card.appendChild(logEl);
		}

		render();
		wrap.appendChild(card);
		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/doh.js'
cat > '/www/luci-static/resources/view/zapret-manager/awg.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

// AmneziaWG: всё в одном месте — пакеты, интерфейсы, ключи WARP, точки входа и превращение
// .conf (WARP.conf или любого своего) в интерфейс OpenWrt со своим именем и зоной firewall.

var PHASE_TEXT = { install: 'устанавливаем AmneziaWG', update: 'переустанавливаем AmneziaWG', remove: 'удаляем AmneziaWG', gen: 'генерируем WARP', create: 'создаём интерфейс', pick: 'подбираем точку входа', replace: 'применяем конфиг', regen: 'генерируем новый WARP' };

function badge(cls, text) {
	return E('span', { 'class': 'zm-badge ' + cls }, [ E('span', { 'class': 'zm-dot' }), text ]);
}
function row(label, node) {
	return E('div', { 'class': 'zm-row' }, [ E('span', { 'class': 'zm-label' }, label), node ]);
}
function bytes(n) {
	n = +n || 0;
	if (n < 1024) return n + ' Б';
	var u = [ 'КБ', 'МБ', 'ГБ', 'ТБ' ], i = -1;
	do { n /= 1024; i++; } while (n >= 1024 && i < u.length - 1);
	return (n >= 100 ? n.toFixed(0) : n.toFixed(1)) + ' ' + u[i];
}
function age(sec) {
	sec = parseInt(sec, 10);
	if (isNaN(sec)) return 'не было';
	if (sec < 60) return sec + ' с назад';
	if (sec < 3600) return Math.floor(sec / 60) + ' мин назад';
	return Math.floor(sec / 3600) + ' ч назад';
}
function live(f) { var a = parseInt(f.hs_age, 10); return f.up && !isNaN(a) && a < 180; }
function country(cc) {
	cc = String(cc || '').toUpperCase();
	if (!/^[A-Z]{2}$/.test(cc)) return '';
	try { return new Intl.DisplayNames([ 'ru' ], { type: 'region' }).of(cc) || cc; } catch (e) { return cc; }
}
function tiles(list, cur, onPick) {
	return E('div', { 'class': 'zm-grid' }, list.map(function(it) {
		return E('div', { 'class': 'zm-tile' + (cur === it.id ? ' zm-active' : ''), 'click': function() { onPick(it.id); } }, it.name);
	}));
}
function toggleTile(on, text, onClick) {
	return E('div', { 'class': 'zm-tile' + (on ? ' zm-active' : ''), 'click': onClick }, text);
}

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.awgStatus().catch(function() { return {}; });
	},

	render: function(data) {
		data = data || {};
		var wrap = E('div', { 'class': 'zm-wrap' });
		var busy = false, lastAction = '';
		var mainCard = E('div', { 'class': 'zm-card' });
		var logEl = E('pre', { 'class': 'zm-log' });
		var ifCard = E('div', { 'class': 'zm-card' });
		var genCard = E('div', { 'class': 'zm-card' });
		var newCard = E('div', { 'class': 'zm-card' });

		var gen = { custom: false, ep: '' };
		var mk = { name: '', src: 'warp', text: '', fw: true, route: false, loaded: false };
		var open = {};          // интерфейс -> какая панель открыта (ep | conf)
		var testRes = {};       // интерфейс -> результат проверки
		var confEdit = null;    // редактор WARP.conf (null — закрыт)

		function refresh() {
			return zm.awgStatus().then(function(res) { data = res || {}; renderAll(); }).catch(function() {});
		}

		function follow(job, action) {
			busy = true; lastAction = action;
			logEl.classList.add('zm-show');
			renderAll();
			zm.pollJob(job, logEl, function(ok) {
				busy = false;
				var msg = ok ? ({ install: 'AmneziaWG установлен', update: 'AmneziaWG переустановлен', remove: 'AmneziaWG удалён', gen: 'WARP сгенерирован',
					create: 'Интерфейс создан', pick: 'Точка входа подобрана', mihomo: 'WARP добавлен в Mihomo',
					replace: 'Конфиг применён', regen: 'Новый WARP применён' }[action] || 'Готово')
					: 'Не получилось — подробности в журнале';
				zm.toast(msg, ok ? 'info' : 'error');
				if (ok && action === 'gen') mk.loaded = false;
				if (action === 'replace' || action === 'regen') Object.keys(open).forEach(function(k) { if (open[k] === 'conf') open[k] = null; });
				refresh();
			});
		}

		function job(action, mode, toastText) {
			if (busy) { zm.toast('Дождитесь окончания текущей операции', 'warning'); return; }
			zm.awgAction(action, mode || '').then(function(res) {
				if (res.error) { zm.toast(res.error, 'error'); return; }
				if (toastText) zm.toast(toastText, 'warning');
				follow(res.job || 'awg', action);
			}).catch(function() { zm.toast('Роутер не ответил', 'error'); });
		}

		function quick(action, mode, okText) {
			return zm.awgAction(action, mode || '').then(function(res) {
				if (res.error) { zm.toast(res.error, 'error'); return res; }
				if (okText) zm.toast(okText, 'info');
				refresh();
				return res;
			}).catch(function() { zm.toast('Роутер не ответил', 'error'); });
		}

		// ── пакеты ──

		function renderMain() {
			mainCard.innerHTML = '';
			mainCard.appendChild(E('h3', {}, 'AmneziaWG'));
			mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'WireGuard с маскировкой трафика: провайдеру сложнее распознать и заблокировать туннель. Пакеты ставятся из релизов 2Grey/awg-openwrt под вашу версию OpenWrt.'));
			var inst = !!data.installed;
			mainCard.appendChild(row('Состояние', inst ? badge('zm-ok', 'установлен') : badge('zm-off', 'не установлен')));
			if (data.kmod || data.tools) {
				mainCard.appendChild(row('Пакеты', E('span', { 'style': 'overflow-wrap:anywhere' }, [
					'kmod-amneziawg ' + (data.kmod || '—') + ' · amneziawg-tools ' + (data.tools || '—') + (data.luci ? ' · ' + (data.luci_pkg || 'luci-proto') + ' ' + data.luci : '')
				])));
			}
			if (inst) {
				mainCard.appendChild(row('Модуль ядра', data.module ? badge('zm-ok', 'загружен') : badge('zm-bad', 'не загружен')));
				mainCard.appendChild(row('Протокол в сети', data.proto ? badge('zm-ok', 'доступен') : badge('zm-warn', 'сеть о нём не знает — нажмите «Доустановить»')));
			}
			if (busy) {
				mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас: ' + (PHASE_TEXT[data.phase] || 'выполняется операция') + '… Можно закрыть страницу — всё доделается на роутере.'));
				return;
			}
			var acts = [];
			if (!inst) acts.push(E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
				job('install', '', 'Устанавливаем AmneziaWG — сеть может ненадолго пропасть');
			} }, 'Установить AmneziaWG'));
			else {
				if (!data.module || !data.proto) acts.push(E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
					job('install', '', 'Доустанавливаем AmneziaWG');
				} }, 'Доустановить'));
				acts.push(E('button', { 'class': 'cbi-button', 'click': function() {
					if (!confirm('Переустановить AmneziaWG из свежего релиза 2Grey/awg-openwrt?\n\nЕсли туннели заняты, новый модуль ядра заработает после перезагрузки роутера.')) return;
					job('update', '', 'Переустанавливаем AmneziaWG');
				} }, 'Обновить / переустановить'));
				acts.push(E('button', { 'class': 'cbi-button cbi-button-remove', 'click': function() {
					if (!confirm('Удалить AmneziaWG с роутера?')) return;
					job('remove', '', 'Удаляем AmneziaWG');
				} }, 'Удалить'));
			}
			mainCard.appendChild(E('div', { 'class': 'zm-actions' }, acts));
			if (inst && data.steer) mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'AmneziaWG нужен Steer — удалить его можно только вместе со Steer.'));
		}

		// ── интерфейсы ──

		function epEditor(f) {
			var box = E('div', { 'style': 'margin-top:10px' });
			var eps = String(data.endpoints || '').split(' ').filter(function(x) { return x; });
			var input = E('input', { 'class': 'cbi-input-text', 'type': 'text', 'placeholder': 'адрес:порт', 'value': f.endpoint || '', 'style': 'max-width:320px; width:100%' });
			box.appendChild(E('div', { 'class': 'zm-grid' }, eps.map(function(ep) {
				return E('div', { 'class': 'zm-tile' + (f.endpoint === ep ? ' zm-active' : ''), 'click': function() { input.value = ep; } }, ep);
			})));
			box.appendChild(E('div', { 'class': 'zm-actions' }, [
				input,
				E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
					quick('endpoint', f.name + '|' + input.value.trim(), 'Точка входа сменена — туннель перезапущен').then(function(r) { if (r && r.ok) delete open[f.name]; });
				} }, 'Применить'),
				f.warp ? E('button', { 'class': 'cbi-button cbi-button-action', 'click': function() {
					job('pick', f.name, 'Подбираем точку входа — это займёт пару минут');
				} }, 'Подобрать автоматически') : ''
			]));
			box.appendChild(E('p', { 'class': 'zm-hint' }, f.warp ? 'Подбор проверяет адреса и порты Cloudflare изнутри туннеля, отсеивает точки, где DPI обрывает связь, и берёт самую быструю зарубежную колонию. Рвутся все — сам сменит маску I1.' : 'Адрес и порт сервера из вашей конфигурации.'));
			return box;
		}

		function ifBlock(f) {
			var steer = f.owner === 'steer';
			var st = !f.enabled && !f.up ? badge('zm-off', 'выключен') : live(f) ? badge('zm-ok', 'работает') : f.up ? badge('zm-warn', 'нет рукопожатия') : badge('zm-bad', 'не поднят');
			var head = E('div', { 'style': 'display:flex; align-items:center; gap:8px; flex-wrap:wrap; margin-bottom:6px' }, [
				E('b', { 'style': 'font-size:15px' }, f.name), st,
				f.warp ? badge('zm-off', 'WARP') : '',
				steer ? badge('zm-off', 'Steer') : ''
			]);
			var box = E('div', { 'class': 'zm-awg-if' }, [ head ]);
			// Свои серверы (не Cloudflare WARP) и свой WARP Steer — адреса скрыты, по нажатию видны
			var hide = !f.warp || f.name === 'zmwarp4';
			if (f.address) box.appendChild(row('Адрес', E('span', {}, hide ? zm.secret(f.address.replace(/,/g, ', ')) : f.address.replace(/,/g, ', '))));
			box.appendChild(row('Точка входа', E('span', { 'style': 'overflow-wrap:anywhere' }, f.endpoint ? (hide ? zm.secret(f.endpoint) : f.endpoint) : '—')));
			box.appendChild(row('Рукопожатие', E('span', {}, age(f.hs_age))));
			if (f.rx || f.tx) box.appendChild(row('Трафик', E('span', {}, '↓ ' + bytes(f.rx) + ' · ↑ ' + bytes(f.tx))));
			box.appendChild(row('Зона firewall', E('span', {}, f.zone || 'нет — устройства сети в туннель не попадут')));
			box.appendChild(row('Маршруты', E('span', {}, f.route_all ? 'весь трафик роутера через туннель' : 'не трогает — трафик направляют Steer, Mihomo или PBR')));
			var t = testRes[f.name];
			if (t) {
				var ti = [];
				if (t.colo) ti.push('колония ' + t.colo + (t.city ? ' (' + t.city + ')' : ''));
				if (t.seen) ti.push('сайты видят: ' + country(t.seen));
				if (t.loss !== undefined && t.loss !== '') ti.push('потери ' + t.loss + '%' + (t.rtt ? ', ' + t.rtt + ' мс' : ''));
				if (t.warp && t.warp !== 'off') ti.push('warp=' + t.warp);
				box.appendChild(row('Проверка', t.ok
					? badge(t.torn ? 'zm-warn' : 'zm-ok', E('span', {}, [ 'выход ', hide ? zm.secret(t.ip || '?') : (t.ip || '?'), ti.length ? ' · ' + ti.join(' · ') : '' ]))
					: badge('zm-bad', 'через туннель ничего не открылось')));
				if (t.ok && t.torn) box.appendChild(E('p', { 'class': 'zm-hint' }, 'Серия пингов оборвалась на хвосте — так DPI рвёт туннель через несколько секунд после начала. ' +
					(f.warp ? 'Подберите точку входа заново: подбор отсеет такие точки, а если рвутся все — сменит маску I1.' : 'Попробуйте другую точку входа или маску I1.')));
			}

			var acts = [
				E('button', { 'class': 'cbi-button cbi-button-action', 'click': function(ev) {
					ev.target.disabled = true;
					zm.awgAction('test', f.name).then(function(r) {
						testRes[f.name] = r || {};
						zm.toast(r && r.ok ? (r.torn ? f.name + ': связь есть, но обрывается' : f.name + ': туннель работает') : f.name + ': через туннель ничего не открылось', r && r.ok ? (r.torn ? 'warning' : 'info') : 'error');
						refresh();
					}).catch(function() { zm.toast('Роутер не ответил', 'error'); refresh(); });
				} }, 'Проверить')
			];
			if (!steer) {
				acts.push(E('button', { 'class': 'cbi-button', 'click': function() { quick('restart', f.name, f.name + ' перезапущен'); } }, 'Перезапустить'));
				acts.push(f.enabled
					? E('button', { 'class': 'cbi-button', 'click': function() { quick('down', f.name, f.name + ' выключен'); } }, 'Выключить')
					: E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() { quick('up', f.name, f.name + ' включён'); } }, 'Включить'));
				acts.push(E('button', { 'class': 'cbi-button', 'click': function() { open[f.name] = open[f.name] === 'ep' ? null : 'ep'; renderIfaces(); } }, 'Точка входа'));
			}
			if (!(steer && (data.steer_own || f.name === 'zmwarp4'))) acts.push(E('button', { 'class': 'cbi-button cbi-button-action', 'click': function() {
				if (!confirm('Сгенерировать новый WARP для ' + f.name + '?\n\nНовые ключи Cloudflare WARP получит только этот интерфейс' + (f.warp ? ', точка входа и маскировка сохранятся.' : ' — вместо текущего сервера.'))) return;
				job('regen', f.name, 'Генерируем новый WARP для ' + f.name);
			} }, 'Новый WARP'));
			acts.push(E('button', { 'class': 'cbi-button', 'click': function() {
				if (open[f.name] === 'conf') { open[f.name] = null; renderIfaces(); return; }
				zm.awgAction('export', f.name).then(function(r) {
					if (r.error) { zm.toast(r.error, 'error'); return; }
					open[f.name] = 'conf'; open[f.name + ':conf'] = r.content || ''; renderIfaces();
				});
			} }, open[f.name] === 'conf' ? 'Скрыть конфиг' : 'Изменить конфиг'));
			if (!steer) acts.push(E('button', { 'class': 'cbi-button cbi-button-remove', 'click': function() {
				if (!confirm('Удалить интерфейс ' + f.name + '?\n\nЕго зона firewall, созданная здесь, тоже удалится.')) return;
				quick('delete', f.name, f.name + ' удалён');
			} }, 'Удалить'));
			box.appendChild(E('div', { 'class': 'zm-actions' }, acts));
			if (steer) box.appendChild(E('p', { 'class': 'zm-hint' }, f.name === 'zmwarp4'
				? 'Свой WARP для Steer' + (data.steer_own ? '' : ' — сейчас выключен, работают автоматические туннели') + '. Новый конфиг можно вставить здесь («Изменить конфиг») или на странице Steer.'
				: data.steer_own ? 'Автоматический туннель Steer — выключен, пока работает свой WARP (zmwarp4).'
				: 'Туннель Steer: конфиг и ключи можно менять здесь, остальным управляет страница Steer.'));
			if (open[f.name] === 'ep') box.appendChild(epEditor(f));
			if (open[f.name] === 'conf') {
				var ta = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false', 'style': 'min-height:220px' });
				ta.value = open[f.name + ':conf'];
				ta.addEventListener('input', function() { open[f.name + ':conf'] = ta.value; });
				box.appendChild(ta);
				var cacts = [];
				if (true) {
					cacts.push(E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
						var t = ta.value;
						if (!/\[interface\]/i.test(t) || !/\[peer\]/i.test(t)) { zm.toast('Нужны секции [Interface] и [Peer]', 'warning'); return; }
						if (!confirm('Заменить конфиг ' + f.name + '?\n\nЗона firewall и маршруты останутся как есть, туннель переподключится.')) return;
						job('replace', f.name + '|' + t, 'Применяем конфиг ' + f.name);
					} }, 'Применить'));
				}
				cacts.push(E('button', { 'class': 'cbi-button', 'click': function() {
					ta.select();
					try { navigator.clipboard.writeText(ta.value).then(function() { zm.toast('Скопировано', 'info'); }); }
					catch (e) { document.execCommand('copy'); zm.toast('Скопировано', 'info'); }
				} }, 'Копировать'));
				box.appendChild(E('div', { 'class': 'zm-actions' }, cacts));
				box.appendChild(E('p', { 'class': 'zm-hint' }, 'Правьте или вставьте свой .conf (например, WARP) и нажмите «Применить». «Новый WARP» — свежие ключи Cloudflare только для этого интерфейса. В конфиге закрытый ключ — не публикуйте его.'));
			}
			return box;
		}

		function renderIfaces() {
			ifCard.innerHTML = '';
			ifCard.appendChild(E('h3', {}, 'Интерфейсы'));
			var list = data.ifaces || [];
			if (!data.installed && !list.length) {
				ifCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сначала установите AmneziaWG.'));
				return;
			}
			if (!list.length) {
				ifCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Интерфейсов AmneziaWG пока нет — получите WARP или вставьте свой .conf и создайте интерфейс ниже.'));
				return;
			}
			list.forEach(function(f) { ifCard.appendChild(ifBlock(f)); });
		}

		// ── WARP ──

		function renderGen() {
			genCard.innerHTML = '';
			genCard.appendChild(E('h3', {}, 'Сгенерировать WARP'));
			genCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Бесплатный туннель Cloudflare WARP с маскировкой AmneziaWG. Файл WARP.conf общий со страницей Mixomo: из него можно сделать интерфейс ниже или отдать в Mihomo.'));
			genCard.appendChild(row('WARP.conf', data.warp_conf ? badge('zm-ok', 'сгенерирован') : badge('zm-off', 'не сгенерирован')));

			function run(mode, toastText) {
				if (busy) { zm.toast('Дождитесь окончания текущей операции', 'warning'); return; }
				if (data.warp_conf && !confirm('WARP.conf уже есть — заменить его новым?')) return;
				job('gen', mode, toastText);
			}
			genCard.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', { 'class': 'cbi-button cbi-button-positive', 'disabled': busy ? '' : null, 'click': function() {
					run('std|default', 'Генерируем WARP');
				} }, 'Сгенерировать WARP'),
				E('button', { 'class': 'cbi-button', 'disabled': busy ? '' : null, 'click': function() {
					run('std|auto', 'Подбираем сервер и генерируем WARP (может занять минуту)');
				} }, 'Сгенерировать с подбором endpoint'),
				E('button', { 'class': 'cbi-button' + (gen.custom ? ' cbi-button-action' : ''), 'disabled': busy ? '' : null, 'click': function() {
					gen.custom = !gen.custom; renderGen();
				} }, 'Свой endpoint')
			]));
			if (gen.custom) {
				var ci = E('input', { 'class': 'cbi-input-text', 'type': 'text', 'placeholder': 'например 162.159.192.7:2408', 'value': gen.ep, 'style': 'max-width:320px; width:100%' });
				ci.addEventListener('input', function() { gen.ep = ci.value.trim(); });
				genCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					ci,
					E('button', { 'class': 'cbi-button cbi-button-positive', 'disabled': busy ? '' : null, 'click': function() {
						var ep = (gen.ep || '').trim();
						if (!/^(\[[0-9A-Fa-f:]+\]|[A-Za-z0-9.-]+):[0-9]{1,5}$/.test(ep)) { zm.toast('Endpoint: адрес:порт, например 162.159.192.7:2408', 'warning'); return; }
						run('std|' + ep, 'Генерируем WARP с endpoint ' + ep);
					} }, 'Сгенерировать')
				]));
			}

			var checkBox = E('div', { 'class': 'zm-awg-if' }, [
				E('div', { 'style': 'font-weight:600; margin-bottom:4px' }, 'Сгенерировать с проверкой связи'),
				E('p', { 'class': 'zm-hint', 'style': 'margin-top:0' }, 'Регистрирует WARP прямо у Cloudflare — если его API у провайдера закрыт, то через живой туннель на роутере или временный туннель. Потом роутер сам перебирает точки входа и маски AmneziaWG и записывает ту связку, через которую реально идёт трафик. Дольше обычного — до нескольких минут, нужен установленный AmneziaWG.'),
				E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button cbi-button-action', 'disabled': (busy || !data.installed) ? '' : null, 'click': function() {
						if (!data.installed) { zm.toast('Сначала установите AmneziaWG', 'warning'); return; }
						run('check', 'Регистрируем WARP и проверяем связь — это займёт несколько минут');
					} }, 'Сгенерировать с проверкой связи'),
					!data.installed ? E('span', { 'class': 'zm-hint', 'style': 'margin:0' }, 'Нужен установленный AmneziaWG') : ''
				])
			]);
			genCard.appendChild(checkBox);

			if (data.warp_conf) {
				genCard.appendChild(row('Файл', E('span', {}, data.warp_path || '/root/WARP.conf')));
				if (data.warp_endpoint) genCard.appendChild(row('Точка входа в файле', E('span', {}, data.warp_endpoint)));
				var acts = [
					E('button', { 'class': 'cbi-button', 'click': function() {
						if (confEdit !== null) { confEdit = null; renderGen(); return; }
						zm.awgAction('conf_get', '').then(function(r) { confEdit = (r && r.content) || ''; renderGen(); });
					} }, confEdit !== null ? 'Скрыть' : 'Показать и изменить'),
					E('button', { 'class': 'cbi-button cbi-button-action', 'click': function() {
						mk.src = 'warp'; mk.loaded = false; newCard.scrollIntoView({ behavior: 'smooth', block: 'start' }); renderNew();
					} }, 'Сделать интерфейс')
				];
				if (data.mihomo) acts.push(E('button', { 'class': 'cbi-button', 'click': function() {
					if (busy) { zm.toast('Дождитесь окончания текущей операции', 'warning'); return; }
					zm.awgAction('mihomo', '').then(function(res) {
						if (res.error) { zm.toast(res.error, 'error'); return; }
						zm.toast('Добавляем WARP в Mihomo', 'warning');
						follow(res.job || 'mixomo_warp_integrate', 'mihomo');
					});
				} }, 'Отправить в Mihomo'));
				genCard.appendChild(E('div', { 'class': 'zm-actions' }, acts));
				if (confEdit !== null) {
					var ta = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false', 'style': 'min-height:260px' });
					ta.value = confEdit;
					ta.addEventListener('input', function() { confEdit = ta.value; });
					genCard.appendChild(ta);
					genCard.appendChild(E('div', { 'class': 'zm-actions' }, [
						E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
							zm.awgAction('conf_set', ta.value).then(function(r) {
								if (r.error) { zm.toast(r.error, 'error'); return; }
								zm.toast('WARP.conf сохранён', 'info'); confEdit = null; mk.loaded = false; refresh();
							});
						} }, 'Сохранить')
					]));
				}
			}
		}

		// ── .conf → интерфейс ──

		function suggestName() {
			var names = {}; (data.ifaces || []).forEach(function(f) { names[f.name] = true; });
			var base = mk.src === 'warp' ? 'warp' : 'awg', n = 0, nm = base;
			while (names[nm]) { n++; nm = base + n; }
			return nm;
		}

		function renderNew() {
			newCard.innerHTML = '';
			newCard.appendChild(E('h3', {}, 'Создать интерфейс'));
			if (!data.installed) {
				newCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сначала установите AmneziaWG.'));
				return;
			}
			newCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Из WARP.conf или из любого своего .conf AmneziaWG / WireGuard — интерфейс появится в «Сеть → Интерфейсы» со всеми параметрами маскировки.'));
			var srcs = [ { id: 'warp', name: 'WARP.conf' }, { id: 'own', name: 'Свой .conf' } ];
			if (!data.warp_conf) srcs.shift();
			if (!data.warp_conf && mk.src === 'warp') mk.src = 'own';
			newCard.appendChild(tiles(srcs, mk.src, function(id) { mk.src = id; mk.loaded = false; mk.name = ''; renderNew(); }));

			var ta = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false', 'style': 'min-height:220px',
				'placeholder': '[Interface]\nPrivateKey = …\nAddress = 10.0.0.2/32\nJc = 4\n…\n\n[Peer]\nPublicKey = …\nAllowedIPs = 0.0.0.0/0\nEndpoint = host:port' });
			if (mk.src === 'warp' && !mk.loaded) {
				mk.loaded = true;
				zm.awgAction('conf_get', '').then(function(r) { mk.text = (r && r.content) || ''; ta.value = mk.text; });
			}
			if (mk.src === 'own' && !mk.loaded) { mk.loaded = true; mk.text = ''; }
			ta.value = mk.text;
			ta.addEventListener('input', function() { mk.text = ta.value; });
			newCard.appendChild(ta);

			if (!mk.name) mk.name = suggestName();
			var ni = E('input', { 'class': 'cbi-input-text', 'type': 'text', 'value': mk.name, 'maxlength': '11', 'style': 'max-width:220px; width:100%' });
			ni.addEventListener('input', function() { mk.name = ni.value.trim().toLowerCase(); });
			newCard.appendChild(row('Имя интерфейса', ni));

			newCard.appendChild(E('div', { 'class': 'zm-grid', 'style': 'margin-top:10px' }, [
				toggleTile(mk.fw, 'Зона firewall с NAT', function() { mk.fw = !mk.fw; renderNew(); }),
				toggleTile(mk.route, 'Весь трафик роутера через туннель', function() { mk.route = !mk.route; renderNew(); })
			]));
			newCard.appendChild(E('p', { 'class': 'zm-hint' }, (mk.fw ? 'Зона с NAT пускает устройства сети в туннель — нужна для Steer, PBR и маршрутов. ' : 'Без зоны устройства сети в туннель не попадут. ')
				+ (mk.route ? 'Внимание: весь интернет роутера пойдёт через туннель, и если он упадёт — пропадёт интернет.' : 'Маршруты не трогаются: что пускать в туннель, решают Steer, Mihomo или PBR.')));

			newCard.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', { 'class': 'cbi-button cbi-button-positive', 'disabled': busy ? '' : null, 'click': function() {
					var nm = (mk.name || '').trim();
					if (!/^[a-z][a-z0-9_]{0,10}$/.test(nm)) { zm.toast('Имя: латиница в нижнем регистре, цифры и _, до 11 символов', 'warning'); return; }
					if (!/\[interface\]/i.test(mk.text) || !/\[peer\]/i.test(mk.text)) { zm.toast('Вставьте конфигурацию с секциями [Interface] и [Peer]', 'warning'); return; }
					var exists = (data.ifaces || []).some(function(f) { return f.name === nm; });
					if (exists && !confirm('Интерфейс ' + nm + ' уже есть — заменить его?')) return;
					job('create', nm + '|' + (mk.route ? 1 : 0) + '|' + (mk.fw ? 1 : 0) + '|' + mk.text, 'Создаём интерфейс ' + nm);
					mk.name = '';
				} }, 'Создать интерфейс')
			]));
		}

		function renderAll() {
			renderMain();
			renderIfaces();
			renderGen();
			renderNew();
		}

		renderAll();
		wrap.appendChild(mainCard);
		wrap.appendChild(logEl);
		wrap.appendChild(ifCard);
		wrap.appendChild(genCard);
		wrap.appendChild(newCard);
		if (data.running) follow('awg', data.phase || '');
		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/awg.js'


cat > '/www/luci-static/resources/view/zapret-manager/steer.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

// Steer: выбранные сервисы идут через бесплатный туннель Cloudflare WARP, остальное — как обычно.
// Страница ставит и связывает всё сама: движок Steer, AmneziaWG, ключи WARP, туннели и правила.

var PHASE_TEXT = {
	install: 'устанавливаем', pkgs: 'ставим движок Steer', awg: 'ставим AmneziaWG', keys: 'получаем ключи WARP',
	tunnel: 'поднимаем туннели', warp: 'настраиваем туннели', rules: 'применяем правила',
	check: 'проверяем', remove: 'удаляем', sub: 'настраиваем подписку'
};

var STEER_TABS = [ { id: 'svc', label: 'Сервисы' }, { id: 'warp', label: 'WARP' }, { id: 'sub', label: 'VPN' } ];

function fmtBytes(n) {
	n = +n || 0;
	if (n < 1024) return n + ' Б';
	var u = [ 'КБ', 'МБ', 'ГБ', 'ТБ' ], i = -1;
	do { n /= 1024; i++; } while (n >= 1024 && i < u.length - 1);
	return (n >= 100 ? n.toFixed(0) : n.toFixed(1)) + ' ' + u[i];
}

function fmtDate(sec) {
	sec = parseInt(sec, 10);
	if (!sec || sec <= 0) return '';
	var d = new Date(sec * 1000);
	if (isNaN(d.getTime())) return '';
	return ('0' + d.getDate()).slice(-2) + '.' + ('0' + (d.getMonth() + 1)).slice(-2) + '.' + d.getFullYear();
}

function latClass(ms) {
	if (!(ms > 0)) return 'zm-lat-none';
	if (ms < 400) return 'zm-lat-good';
	if (ms < 900) return 'zm-lat-mid';
	return 'zm-lat-bad';
}

var BLOCKERS = {
	splify2: 'Установлен splify2 — туннели и списки настраиваются в нём.',
	steer: 'Движок Steer уже настроен вручную — Zapret Manager его не перезаписывает.'
};

function badge(cls, text) {
	return E('span', { 'class': 'zm-badge ' + cls }, [ E('span', { 'class': 'zm-dot' }), text ]);
}

function row(label, node) {
	return E('div', { 'class': 'zm-row' }, [ E('span', { 'class': 'zm-label' }, label), node ]);
}

function fmtAge(sec) {
	sec = parseInt(sec, 10);
	if (isNaN(sec)) return 'не было';
	if (sec < 60) return 'только что';
	if (sec < 3600) return Math.floor(sec / 60) + ' мин назад';
	return Math.floor(sec / 3600) + ' ч назад';
}

// Туннель жив: поднят и рукопожатие было за последние пять минут.
function tunnelLive(t) {
	var a = parseInt(t.hs_age, 10);
	return t.up && !isNaN(a) && a < 300;
}

function country(cc) {
	cc = String(cc || '').toUpperCase();
	if (!/^[A-Z]{2}$/.test(cc)) return '';
	try { return new Intl.DisplayNames([ 'ru' ], { type: 'region' }).of(cc) || cc; } catch (e) { return cc; }
}

function plural(n, one, few, many) {
	var m10 = n % 10, m100 = n % 100;
	if (m10 === 1 && m100 !== 11) return one;
	if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
	return many;
}

function verLt(a, b) {
	var x = String(a).split('.'), y = String(b).split('.');
	for (var i = 0; i < 3; i++) {
		var p = parseInt(x[i], 10) || 0, q = parseInt(y[i], 10) || 0;
		if (p !== q) return p < q;
	}
	return false;
}

function hh(h) { return (h < 10 ? '0' : '') + h + ':00'; }

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.steerStatus().catch(function() { return {}; });
	},

	render: function(data) {
		data = data || {};
		var wrap = E('div', { 'class': 'zm-wrap' });
		var busy = false, lastAction = '', pick = null, autoBusy = false, diagRes = null, diagBusy = false;
		// Режим WARP: warpPick — что выбрано переключателем (null — как на роутере); ownTa — поле своего конфига,
		// один и тот же элемент между перерисовками, чтобы вставленный текст не пропадал; ownOpen — «Заменить конфиг».
		var warpPick = null, ownTa = null, ownOpen = false, ownLoaded = false;

		var mainCard = E('div', { 'class': 'zm-card' });
		var logEl = E('pre', { 'class': 'zm-log' });
		var dnsCard = E('div', {});
		var listCard = E('div', { 'class': 'zm-card' });
		var checkCard = E('div', { 'class': 'zm-card' });
		var customCard = E('div', { 'class': 'zm-card' });
		var customData = null, customLoading = false, customEditor = null, customDraft = null, customDirty = false;
		var warpCard = E('div', { 'class': 'zm-card' });
		var autoCard = E('div', { 'class': 'zm-card' });
		var subCard = E('div', { 'class': 'zm-card' });
		var subData = null, subLoading = false, subInput = '', lat = {}, probing = false, probeDone = 0, probeTotal = 0;
		var tab = 'svc';
		try { tab = localStorage.getItem('zm.steer.tab') || 'svc'; } catch (e) {}
		if (!STEER_TABS.some(function(t) { return t.id === tab; })) tab = 'svc';
		var tabBar = E('div', { 'class': 'zm-actions', 'style': 'margin:10px 0' });
		var panes = { svc: E('div', {}), warp: E('div', {}), sub: E('div', {}) };

		// ── ход операции ──

		function refresh() {
			return zm.steerStatus().then(function(res) { data = res || {}; renderAll(); });
		}

		function finish(ok, res) {
			busy = false;
			if (res) data = res;
			var msg = 'Готово';
			if (!ok) msg = 'Не получилось — подробности в журнале';
			else if (lastAction === 'install') msg = 'Steer установлен — подключите WARP или VPN';
			else if (lastAction === 'warp_setup') msg = 'WARP подключён';
			else if (lastAction === 'warp_own') msg = 'Свой WARP подключён';
			else if (lastAction === 'warp_mode') msg = 'Автоматический WARP подключён';
			else if (lastAction === 'warp_fix' || lastAction === 'warp_fixkeys') msg = 'Туннель переделан';
			else if (lastAction === 'remove') msg = 'Steer удалён';
			else if (lastAction === 'stop') msg = 'Steer выключен — всё идёт напрямую';
			else if (lastAction === 'domlist') msg = 'Готово, новый список доменов работает';
			else if (lastAction === 'lists' || lastAction === 'start') msg = 'Готово, выбор применён';
			else if (/^sub_/.test(lastAction)) msg = 'Готово';
			else if (lastAction === 'engine') msg = 'Движок Steer обновлён';
			zm.toast(msg, ok ? 'info' : 'error');
			var done = lastAction;
			lastAction = '';
			if (ok && (done === 'warp_own' || done === 'warp_mode')) { warpPick = null; ownOpen = false; }
			diagRes = null;
			renderAll();
			loadSub();
			// После «Выключить» и «Удалить» проверять нечего: красный пункт сразу после
			// намеренного выключения только пугает.
			if (ok && data.installed && !data.stopped && done !== 'stop' && done !== 'remove') runDiag(true);
		}

		function waitRouter() {
			zm.steerStatus().then(function(res) {
				data = res || {};
				if (data.running) { follow(); return; }
				finish(true, res);
			}).catch(function() { setTimeout(waitRouter, 5000); });
		}

		function follow() {
			var ticks = 0;
			busy = true;
			renderAll();
			zm.pollJob('steer', logEl, function(ok) {
				// Установка AmneziaWG перезапускает сеть, и роутер на время замолкает — ждём его.
				zm.steerStatus().then(function(res) {
					if (res && res.running) { data = res; follow(); return; }
					finish(ok, res);
				}).catch(function() {
					zm.toast('Роутер не отвечает — ждём', 'warning');
					setTimeout(waitRouter, 5000);
				});
			}, function() {
				if (++ticks % 3) return;
				zm.steerStatus().then(function(res) { if (res) { data = res; renderMain(); } }).catch(function() {});
			});
		}

		function act(action, arg, toastText) {
			if (busy) { zm.toast('Дождитесь окончания текущей операции', 'warning'); return; }
			zm.steerAction(action, arg || '').then(function(res) {
				if (res.error) { zm.toast(res.error, 'error'); return; }
				if (res.saved) { zm.toast(data.installed ? 'Выбор сохранён — применится при включении' : 'Выбор сохранён — применится при установке', 'info'); pick = null; refresh(); loadSub(); return; }
				if (action === 'lists') pick = null;
				if (toastText) zm.toast(toastText, 'warning');
				lastAction = action;
				data.running = true;
				data.phase = action === 'install' ? 'pkgs' : action === 'remove' ? 'remove' : /^warp_/.test(action) ? 'warp' : /^sub_/.test(action) ? 'sub' : action === 'engine' ? 'pkgs' : 'rules';
				follow();
			}).catch(function() { zm.toast('Роутер не ответил', 'error'); });
		}

		// ── главная карточка ──

		// Как называть туннель WARP: в режиме «Свой конфиг» — «Свой WARP».
		function warpName() { return data.warp_mode === 'own' ? 'Свой WARP' : 'WARP'; }

		function selectedCount() {
			var n = (data.services || []).filter(function(s) { return s.on; }).length;
			if (!n && (parseInt(data.channels, 10) || 0) > 0) n = 1;
			return n;
		}

		// Сводка по туннелям: [текст, класс бейджа].
		function tunnelState() {
			var age = parseInt(data.warp_hs_age, 10), n = parseInt(data.channels, 10) || 0;
			if (!data.warp_up) return (data.stopped || !n) ? [ 'выключены', 'zm-off' ] : [ 'не подняты', 'zm-bad' ];
			var t = data.tunnels || [], live = t.filter(tunnelLive).length;
			if (t.length > 1 && live) return [ 'работают ' + live + ' из ' + t.length + (data.warp_colo ? ' · ' + data.warp_colo : ''), live < t.length ? 'zm-warn' : 'zm-ok' ];
			if (!isNaN(age) && age < 300) return [ 'работает' + (data.warp_colo ? ' · ' + data.warp_colo : ''), 'zm-ok' ];
			return [ 'нет связи', 'zm-warn' ];
		}

		// Туннель VPN: поднят ли он и идёт ли через него трафик на деле.
		function vpnBadge() {
			if (!data.vpn_up) return badge('zm-warn', 'подключаемся');
			if (data.vpn_live === false) return badge('zm-bad', 'нет связи');
			return badge('zm-ok', 'подключено');
		}

		function statusBadge() {
			var n = selectedCount();
			if (busy || data.running) return badge('zm-warn', PHASE_TEXT[data.phase] || 'работаем');
			if (!data.installed) return badge('zm-off', 'не установлен');
			if (data.stopped) return badge('zm-off', 'выключен');
			if (!n) return badge('zm-off', 'сервисы не выбраны');
			if (data.exit === 'none') return badge('zm-warn', 'подключите WARP или VPN');
			// Работает, если служба запущена и жив хоть один туннель: упавший один из трёх —
			// штатная работа, Steer уже ведёт трафик через живые.
			if (data.exit === 'vpn') {
				if (data.steer_running && data.vpn_up && data.vpn_live === false) return badge('zm-bad', 'трафик не идёт');
				if (data.steer_running && data.vpn_up) return badge('zm-ok', 'работает');
				if (data.steer_running) return badge('zm-warn', 'подключаемся к узлу');
				return badge('zm-bad', 'не работает');
			}
			var t = data.tunnels || [], age = parseInt(data.warp_hs_age, 10);
			var live = t.length ? t.filter(tunnelLive).length > 0 : (!isNaN(age) && age < 300);
			if (data.steer_running && data.warp_up && live) return badge('zm-ok', 'работает');
			if (data.steer_running && data.warp_up) return badge('zm-warn', 'нет связи');
			return badge('zm-bad', 'не работает');
		}

		function renderMain() {
			mainCard.innerHTML = '';
			mainCard.appendChild(E('h3', {}, 'Steer'));
			mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Выбранные сервисы идут через туннель — бесплатный Cloudflare WARP или ваш VPN (подписка или VLESS). Остальной интернет — как обычно.'));

			if (data.blocker) {
				mainCard.appendChild(E('div', { 'class': 'zm-refresh-banner zm-show' }, BLOCKERS[data.blocker] || data.blocker));
				return;
			}

			mainCard.appendChild(row('Состояние', statusBadge()));
			if (data.installed) {
				var n = selectedCount(), ts = tunnelState();
				if (data.warp_on && data.has_sub && data.ext) {
					var isVpn = data.exit === 'vpn';
					mainCard.appendChild(E('div', { 'class': 'zm-row' }, [
						E('span', { 'class': 'zm-label' }, 'Сервисы идут через'),
						E('div', { 'class': 'zm-seg' }, [
							E('div', { 'class': 'zm-seg-item' + (!isVpn ? ' zm-active' : ''), 'click': function() { if (isVpn && !busy) act('sub_exit', 'warp', 'Переключаем на ' + warpName()); } }, warpName()),
							E('div', { 'class': 'zm-seg-item' + (isVpn ? ' zm-active' : ''), 'click': function() { if (!isVpn && !busy) act('sub_exit', 'vpn', 'Переключаем на VPN'); } }, data.sub_label || 'VPN')
						]),
						isVpn ? vpnBadge() : badge(ts[1], ts[0])
					]));
				} else if (data.exit === 'vpn') mainCard.appendChild(row('Сервисы идут через', E('span', {}, [ 'VPN' + (data.sub_label ? ' · ' + data.sub_label : '') + ' ', vpnBadge() ])));
				else if (data.exit === 'warp') mainCard.appendChild(row('Сервисы идут через', badge(ts[1], warpName() + ' · ' + ts[0])));
				else mainCard.appendChild(row('Сервисы идут через', badge('zm-warn', 'туннель не подключён — выберите вкладку WARP или VPN')));
				mainCard.appendChild(row('Через туннель', E('span', {}, n ? n + ' ' + plural(n, 'сервис', 'сервиса', 'сервисов') : 'ничего не выбрано')));
				var newer = data.latest && data.version && verLt(data.version, data.latest);
				mainCard.appendChild(row('Версия Steer', E('span', {}, (data.version || '—') + (data.ext ? ' · extended' : '') + (newer ? ' · доступна ' + data.latest : (!data.ext && data.version ? ' · нужен steer-extended' : '')))));
			}

			if (busy) {
				mainCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button cbi-button-remove', 'click': function() {
						zm.steerAction('halt', '').then(function(res) {
							if (res.error) zm.toast(res.error, 'error'); else zm.toast('Останавливаем — роутер закончит текущий шаг', 'warning');
						}).catch(function() { zm.toast('Роутер не ответил', 'error'); });
					} }, 'Остановить')
				]));
				mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Можно закрыть страницу — всё доделается на роутере.'));
				return;
			}

			if (!data.installed) {
				mainCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
						act('install', '', 'Устанавливаем Steer — это займёт пару минут');
					} }, 'Установить')
				]));
				mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Ставится только движок steer-extended — около минуты. Потом на вкладке WARP или VPN выберите, через что пускать сервисы.'));
				return;
			}

			var actions = [];
			if (data.stopped) actions.push(E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() { act('start', '', 'Включаем Steer'); } }, 'Включить'));
			else {
				actions.push(E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() { act('apply', '', 'Перезапускаем туннели и правила'); } }, 'Перезапустить'));
				actions.push(E('button', { 'class': 'cbi-button', 'click': function() { act('stop', '', 'Выключаем Steer'); } }, 'Выключить'));
			}
			if ((data.latest && data.version && verLt(data.version, data.latest)) || (data.version && !data.ext))
				actions.push(E('button', { 'class': 'cbi-button cbi-button-action', 'click': function() { act('engine', '', 'Обновляем движок Steer'); } }, 'Обновить движок'));
			actions.push(E('button', { 'class': 'cbi-button cbi-button-remove', 'click': function() {
				if (!confirm('Удалить Steer?\n\nБудут удалены Steer, туннели WARP и всё, что для них ставилось. Сервисы, которые шли через WARP, пойдут напрямую.')) return;
				act('remove', '', 'Удаляем Steer');
			} }, 'Удалить'));
			mainCard.appendChild(E('div', { 'class': 'zm-actions' }, actions));
			mainCard.appendChild(E('p', { 'class': 'zm-hint' }, '«Выключить» — всё пойдёт напрямую, настройки и выбор сервисов сохранятся.'));
		}

		// ── какие сервисы пускать через WARP ──

		function currentPick() {
			var m = {};
			(data.services || []).forEach(function(s) { if (s.on) m[s.id] = true; });
			return m;
		}

		var CATEGORY_IDS = [ 'geoblock', 'block', 'news', 'anime', 'porn', 'russia_inside' ];

		function renderLists() {
			listCard.innerHTML = '';
			listCard.style.display = data.blocker ? 'none' : '';
			if (data.blocker) return;
			listCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Нажмите на пункт, чтобы включить или выключить его, и затем «Применить». Списки доменов берутся из itdoginfo/allow-domains и обновляются при каждом применении.'));
			var cur = currentPick(), sel = pick || cur, changed = false;
			var list = data.services || [];
			list.forEach(function(s) { if (!!sel[s.id] !== !!cur[s.id]) changed = true; });
			function tile(s) {
				return E('div', {
					'class': 'zm-tile' + (sel[s.id] ? ' zm-active' : ''),
					'click': function() {
						if (busy) { zm.toast('Дождитесь окончания текущей операции', 'warning'); return; }
						pick = {};
						for (var k in sel) if (sel[k]) pick[k] = true;
						if (pick[s.id]) delete pick[s.id]; else pick[s.id] = true;
						renderLists();
					}
				}, s.name);
			}
			var svcs = list.filter(function(s) { return CATEGORY_IDS.indexOf(s.id) < 0; });
			var cats = list.filter(function(s) { return CATEGORY_IDS.indexOf(s.id) >= 0; });
			listCard.appendChild(E('h4', { 'style': 'margin:0 0 8px' }, 'Сервисы'));
			listCard.appendChild(E('div', { 'class': 'zm-grid' }, svcs.map(tile)));
			if (cats.length) {
				listCard.appendChild(E('h4', { 'style': 'margin:16px 0 8px' }, 'Категории'));
				listCard.appendChild(E('div', { 'class': 'zm-grid' }, cats.map(tile)));
				listCard.appendChild(E('p', { 'class': 'zm-hint' }, '«Всё сразу» — полный список Russia inside: все категории и сервисы одним набором. Он большой, на слабых роутерах лучше включать отдельные пункты.'));
			}
			if (changed) {
				listCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
						var ids = list.filter(function(s) { return sel[s.id]; }).map(function(s) { return s.id; });
						act('lists', ids.join(','), 'Применяем выбор');
					} }, 'Применить'),
					E('button', { 'class': 'cbi-button', 'click': function() { pick = null; renderLists(); } }, 'Отмена'),
					E('span', { 'class': 'zm-hint', 'style': 'margin:0' }, 'Есть несохранённые изменения')
				]));
			}
		}

		function loadCustom() {
			customLoading = true;
			renderCustom();
			zm.steerAction('list_get', 'custom').then(function(res) {
				customLoading = false;
				if (res.error) { customData = null; renderCustom(); zm.toast(res.error, 'error'); return; }
				customData = res;
				customDraft = null;
				customDirty = false;
				renderCustom();
			}).catch(function() { customLoading = false; renderCustom(); });
		}

		function saveCustom(action, arg, okText) {
			if (busy) { zm.toast('Дождитесь окончания текущей операции', 'warning'); return; }
			zm.steerAction(action, arg).then(function(res) {
				if (res.error) { zm.toast(res.error, 'error'); return; }
				customDraft = null;
				customDirty = false;
				if (res.saved) {
					zm.toast(okText + (res.count ? ' (' + res.count + ')' : ''), 'info');
					loadCustom();
					refresh();
					return;
				}
				zm.toast(okText + ' — применяем правила', 'info');
				lastAction = 'domlist';
				data.running = true;
				data.phase = 'rules';
				follow();
				loadCustom();
			}).catch(function() { zm.toast('Роутер не ответил', 'error'); });
		}

		function renderCustom() {
			if (customEditor && customDirty) customDraft = customEditor.value;
			customCard.innerHTML = '';
			var svc = (data.services || []).filter(function(s) { return s.id === 'custom'; })[0];
			customCard.style.display = data.blocker || !svc ? 'none' : '';
			if (data.blocker || !svc) return;
			customCard.appendChild(E('h3', {}, 'Свой список'));
			customCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Домены из этого списка пойдут через Steer. После сохранения список сразу включается в выбор сервисов, «Очистить» — убирает его.'));
			if (customLoading && !customData) { customCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Загружаем список…')); return; }
			var n = customData ? (parseInt(customData.count, 10) || 0) : 0;
			customCard.appendChild(row('Состояние', !n ? badge('zm-off', 'список пуст')
				: !svc.on ? badge('zm-warn', 'не выбран')
				: !data.installed ? badge('zm-warn', 'пойдёт через Steer после установки')
				: data.stopped ? badge('zm-off', 'Steer выключен')
				: data.exit === 'vpn' ? badge('zm-ok', 'идёт через VPN')
				: data.exit === 'warp' ? badge('zm-ok', 'идёт через ' + warpName())
				: badge('zm-warn', 'подключите WARP или VPN')));
			customCard.appendChild(row('Доменов', E('span', {}, String(n))));
			customEditor = E('textarea', {
				'class': 'zm-config-editor', 'spellcheck': 'false', 'style': 'min-height:200px', 'placeholder': 'example.com\nsite.org',
				'input': function() { customDirty = true; }
			});
			customEditor.value = customDirty && customDraft !== null ? customDraft : (customData && customData.content) || '';
			customCard.appendChild(customEditor);
			var acts = [
				E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
					if (!customEditor.value.trim()) { zm.toast('Добавьте хотя бы один домен', 'warning'); return; }
					saveCustom('list_set', 'custom|' + customEditor.value, 'Свой список сохранён');
				} }, 'Сохранить')
			];
			if (n) acts.push(E('button', { 'class': 'cbi-button cbi-button-remove', 'click': function() {
				if (!confirm('Очистить свой список?\n\nДомены из него пойдут напрямую.')) return;
				saveCustom('list_reset', 'custom', 'Свой список очищен');
			} }, 'Очистить'));
			customCard.appendChild(E('div', { 'class': 'zm-actions' }, acts));
			customCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Один домен на строку, поддомены включаются сами (example.com — это и www.example.com). Строки, не похожие на домен, при сохранении отбрасываются.'));
		}

		// ── проверка ──

		function runDiag(quiet) {
			if (diagBusy) return;
			diagBusy = true;
			renderCheck();
			zm.steerAction('diag', '').then(function(res) {
				diagBusy = false;
				diagRes = res || {};
				renderCheck();
				// проверка обновила кеш «идёт ли трафик» — подтягиваем состояние
				zm.steerStatus().then(function(r) { if (r) { data = r; renderMain(); } }).catch(function() {});
				if (!quiet) zm.toast('Проверка закончена', 'info');
			}).catch(function() { diagBusy = false; renderCheck(); });
		}

		function renderCheck() {
			checkCard.innerHTML = '';
			checkCard.style.display = data.installed && !data.blocker ? '' : 'none';
			if (!data.installed || data.blocker) return;
			checkCard.appendChild(E('h3', {}, 'Проверка'));
			checkCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Роутер проверит каждый туннель и спросит сам Steer, всё ли на месте.'));
			if (diagRes) {
				var items = [];
				var tn = diagRes.tunnels || [];
				if (diagRes.vpn === 'on') items.push([ 'ok', diagRes.vpn_ip ? [ 'Трафик идёт через подписку (выход ', zm.secret(diagRes.vpn_ip), (diagRes.vpn_loc ? ', ' + diagRes.vpn_loc : '') + ')' ] : 'Трафик идёт через подписку', '' ]);
				else if (diagRes.vpn === 'off') items.push([ 'fail', 'Трафик через подписку не идёт', 'проверьте задержку узлов на вкладке «Подписка» или выберите другой узел' ]);
				else if (tn.length) tn.forEach(function(t) {
					var who = tn.length > 1 ? 'Туннель ' + t.n + ': ' : '';
					var ownW = data.warp_mode === 'own';
					if (t.warp === 'on') items.push([ 'ok', who + 'трафик идёт через ' + warpName() + (t.colo ? ' (сервер ' + t.colo + (t.city ? ', ' + t.city : '') + ')' : '') + (t.seen ? ' · сайты видят: ' + country(t.seen) : ''), '' ]);
					else if (t.warp === 'notls') items.push([ 'warn', who + 'соединение есть, но HTTPS через туннель не проходит', ownW ? 'замените конфиг на вкладке WARP' : 'нажмите «Сменить точки входа»' ]);
					else items.push([ tn.length > 1 && diagRes.warp === 'on' ? 'warn' : 'fail', who + 'трафик через ' + warpName() + ' не идёт',
						ownW ? 'нажмите «Перезапустить туннель» или замените конфиг на вкладке WARP' : 'нажмите «Перезапустить туннели» или «Сменить точки входа»' ]);
				});
				else if (diagRes.warp === 'on') items.push([ 'ok', 'Трафик идёт через WARP' + (diagRes.colo ? ' (сервер ' + diagRes.colo + ')' : ''), '' ]);
				else if (diagRes.warp === 'off') items.push([ 'fail', 'Трафик через WARP не идёт', 'нажмите «Перезапустить туннели» или «Сменить точки входа»' ]);
				var d = diagRes.diag;
				if (d && d.checks) d.checks.forEach(function(c) {
					if (c.verdict === 'ok' || c.verdict === 'warn' || c.verdict === 'fail') items.push([ c.verdict, c.what, c.why ]);
				});
				var bad = items.filter(function(i) { return i[0] === 'fail'; }).length, warn = items.filter(function(i) { return i[0] === 'warn'; }).length;
				checkCard.appendChild(row('Итог', bad ? badge('zm-bad', 'есть поломка') : warn ? badge('zm-warn', 'работает, есть замечания') : badge('zm-ok', 'всё в порядке')));
				var CLS = { ok: 'zm-ok', warn: 'zm-warn', fail: 'zm-bad' }, TXT = { ok: 'ок', warn: 'внимание', fail: 'ошибка' };
				items.forEach(function(i) {
					checkCard.appendChild(E('div', { 'class': 'zm-row' }, [
						badge(CLS[i[0]], TXT[i[0]]),
						E('span', {}, [].concat(i[1], i[2] ? ' — ' + i[2] : ''))
					]));
				});
			}
			checkCard.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', { 'class': 'cbi-button', 'disabled': diagBusy || busy ? '' : null, 'click': function() { runDiag(false); } },
					diagBusy ? 'Проверяем…' : 'Проверить')
			]));
		}

		// ── туннели WARP ──

		function renderWarp() {
			warpCard.innerHTML = '';
			warpCard.style.display = data.blocker ? 'none' : '';
			if (data.blocker) return;
			var tl = data.tunnels || [];
			var own = data.warp_on && data.warp_mode === 'own';
			warpCard.appendChild(E('h3', {}, own ? 'Свой WARP' : tl.length > 1 ? 'Туннели WARP' : 'Туннель WARP'));
			if (!data.installed) { warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сначала установите Steer.')); return; }

			// Переключатель режима: «Автоматически» — ключи от Cloudflare и три туннеля; «Свой конфиг» — один туннель по конфигу.
			var sel = warpPick || (data.warp_mode === 'own' ? 'own' : 'auto');
			warpCard.appendChild(E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'Режим'),
				E('div', { 'class': 'zm-seg' }, [
					E('div', { 'class': 'zm-seg-item' + (sel === 'auto' ? ' zm-active' : ''), 'click': function() {
						if (busy || sel === 'auto') return;
						if (own) {
							if (!confirm('Перейти на автоматический WARP?\n\nВключатся прежние автоматические туннели (если их ещё не было — роутер получит ключи у Cloudflare и подберёт три туннеля за несколько минут). Свой туннель выключится, но сохранится.')) return;
							act('warp_mode', 'auto', 'Переходим на автоматический WARP — это займёт несколько минут');
							return;
						}
						warpPick = null; renderWarp();
					} }, 'Автоматически'),
					E('div', { 'class': 'zm-seg-item' + (sel === 'own' ? ' zm-active' : ''), 'click': function() {
						if (busy || sel === 'own') return;
						warpPick = own ? null : 'own'; renderWarp();
					} }, 'Свой конфиг')
				])
			]));

			function ownEditor(btnText, toastText) {
				if (!ownTa) ownTa = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false', 'style': 'min-height:220px',
					'placeholder': '[Interface]\nPrivateKey = …\nAddress = 172.16.0.2/32\n\n[Peer]\nPublicKey = …\nEndpoint = 162.159.192.1:2408' });
				warpCard.appendChild(ownTa);
				if (data.warp_own_saved && !ownLoaded && !ownTa.value.trim()) {
					ownLoaded = true;
					zm.steerAction('warp_own_get', '').then(function(r) {
						if (r && r.content && !ownTa.value.trim()) ownTa.value = r.content.replace(/\s+$/, '');
					}).catch(function() { ownLoaded = false; });
				}
				var btns = [ E('button', { 'class': 'cbi-button cbi-button-positive', 'disabled': busy ? '' : null, 'click': function() {
					var v = ownTa.value.trim();
					if (!v && !data.warp_own_saved) { zm.toast('Вставьте конфиг WARP', 'warning'); ownTa.focus(); return; }
					if (v && (!/^\s*\[interface\]/im.test(v) || !/^\s*\[peer\]/im.test(v))) { zm.toast('Это не конфиг WARP: нужны секции [Interface] и [Peer]', 'error'); return; }
					act('warp_own', v, toastText);
				} }, btnText) ];
				if (warpPick === 'own' || ownOpen) btns.push(E('button', { 'class': 'cbi-button', 'click': function() { warpPick = null; ownOpen = false; renderWarp(); } }, 'Отмена'));
				warpCard.appendChild(E('div', { 'class': 'zm-actions' }, btns));
				warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Подойдёт конфиг WireGuard или AmneziaWG: ключи, маскировка и точка входа берутся из него как есть.' +
					(data.warp_own_saved ? ' В поле — ваш сохранённый конфиг: поправьте его или вставьте новый. Он хранится отдельно и переживёт даже переустановку Steer.' : '')));
			}

			if (sel === 'own' && !own) {
				warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Один туннель по вашему конфигу. Роутер не будет получать ключи и искать точки входа сам.' +
					(data.warp_on ? ' Автоматические туннели выключатся, но сохранятся — вернуться к ним можно в один клик.' : '')));
				ownEditor(data.warp_on ? 'Перейти на свой конфиг' : 'Подключить', 'Подключаем свой WARP');
				return;
			}
			if (!data.warp_on) {
				warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Бесплатный туннель Cloudflare WARP с маскировкой AmneziaWG. Поставится AmneziaWG, роутер получит ключи и подберёт три туннеля в разных колониях — это займёт несколько минут.'));
				warpCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button cbi-button-positive', 'disabled': busy ? '' : null, 'click': function() { act('warp_setup', '', 'Подключаем WARP — это займёт несколько минут'); } }, 'Подключить WARP')
				]));
				return;
			}
			if (own) {
				if (data.exit === 'vpn') warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас сервисы идут через подписку — свой WARP не используется.'));
				var t0 = tl[0] || {}, live0 = tunnelLive(t0), info0 = [];
				var ep0 = t0.host ? zm.secret(t0.host + ':' + t0.port) : null;
				if (t0.colo && t0.colo !== '?') info0.push('сервер ' + t0.colo + (t0.city ? ' (' + t0.city + ')' : ''));
				if (t0.seen) info0.push('сайты видят: ' + country(t0.seen));
				if (t0.up) info0.push('связь ' + fmtAge(t0.hs_age));
				if (t0.up) info0.push('↓ ' + zm.fmtSize(+t0.rx || 0) + ' / ↑ ' + zm.fmtSize(+t0.tx || 0));
				warpCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Туннель'),
					badge(live0 ? 'zm-ok' : t0.up ? 'zm-warn' : 'zm-bad', live0 ? 'работает' : t0.up ? 'нет связи' : 'не поднят'),
					E('span', {}, ep0 ? [ ep0, info0.length ? ' · ' + info0.join(' · ') : '' ] : info0.join(' · '))
				]));
				if (ownOpen) { ownEditor('Сохранить и подключить', 'Меняем конфиг WARP'); return; }
				warpCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button', 'disabled': busy ? '' : null, 'click': function() { act('warp_restart', '', 'Перезапускаем туннель'); } }, 'Перезапустить туннель'),
					E('button', { 'class': 'cbi-button', 'disabled': busy ? '' : null, 'click': function() { ownOpen = true; renderWarp(); if (ownTa) ownTa.focus(); } }, 'Заменить конфиг')
				]));
				warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Не работает — «Перезапустить туннель». Не помогло — замените конфиг.'));
				return;
			}
			if (data.exit === 'vpn') warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас сервисы идут через подписку — туннели WARP не используются.'));
			if (tl.length > 1) warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Трафик идёт через самый быстрый живой туннель; упал один — Steer сам переключится на другой.'));
			var deadN = tl.filter(function(t) { return !tunnelLive(t); }).length;
			var partial = deadN > 0 && deadN < tl.length;
			if (tl.length) {
				tl.forEach(function(t) {
					var live = tunnelLive(t);
					var fix = partial && !live ? E('span', { 'style': 'display:inline-flex; gap:6px; margin-left:auto' }, [
						E('button', { 'class': 'cbi-button cbi-button-action', 'disabled': busy ? '' : null, 'click': function() { act('warp_fix', String(t.n), 'Переделываем WARP ' + t.n); } }, 'Переделать'),
						E('button', { 'class': 'cbi-button', 'disabled': busy ? '' : null, 'click': function() {
							if (!confirm('Получить новые ключи для WARP ' + t.n + '?\n\nОстальные туннели не тронутся.')) return;
							act('warp_fixkeys', String(t.n), 'Новые ключи для WARP ' + t.n);
						} }, 'Новые ключи')
					]) : '';
					var st = badge(live ? 'zm-ok' : t.up ? 'zm-warn' : 'zm-bad', live ? 'работает' : t.up ? 'нет связи' : 'не поднят');
					var info = [];
					if (t.colo) info.push('сервер ' + t.colo + (t.city ? ' (' + t.city + ')' : ''));
					if (t.seen) info.push('сайты видят: ' + country(t.seen));
					if (t.host) info.push(t.host + ':' + t.port);
					if (t.up) info.push('связь ' + fmtAge(t.hs_age));
					if (t.up) info.push('↓ ' + zm.fmtSize(+t.rx || 0) + ' / ↑ ' + zm.fmtSize(+t.tx || 0));
					warpCard.appendChild(E('div', { 'class': 'zm-row' }, [
						E('span', { 'class': 'zm-label' }, 'WARP ' + t.n),
						st,
						E('span', {}, info.join(' · ')),
						fix
					]));
				});
			} else {
				var ts = tunnelState();
				warpCard.appendChild(row('Состояние', badge(ts[1], ts[0].split(' · ')[0])));
				warpCard.appendChild(row('Точка входа', E('span', {}, data.warp_host ? data.warp_host + ':' + data.warp_port : '—')));
				warpCard.appendChild(row('Сервер Cloudflare', E('span', {}, data.warp_colo || '—')));
				warpCard.appendChild(row('Последняя связь', E('span', {}, data.warp_up ? fmtAge(data.warp_hs_age) : '—')));
				warpCard.appendChild(row('Получено / отправлено', E('span', {}, zm.fmtSize(+data.warp_rx || 0) + ' / ' + zm.fmtSize(+data.warp_tx || 0))));
			}
			if (partial) {
				warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Не работает ' + (deadN === 1 ? 'один туннель' : 'часть туннелей') + ' — переделайте только ' + (deadN === 1 ? 'его' : 'их') + ': «Переделать» подберёт новую точку входа, «Новые ключи» — новый аккаунт WARP. Работающие туннели не тронутся.'));
				return;
			}
			warpCard.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', { 'class': 'cbi-button', 'click': function() { act('warp_restart', '', 'Перезапускаем туннели'); } }, 'Перезапустить туннели'),
				E('button', { 'class': 'cbi-button', 'click': function() { act('warp_endpoint', '', 'Ищем точки входа'); } }, 'Сменить точки входа'),
				E('button', { 'class': 'cbi-button', 'click': function() {
					if (!confirm('Пересоздать WARP?\n\nБудут получены новые ключи, туннели переподключатся. Помогает, если Cloudflare перестал пускать старые ключи.')) return;
					act('warp_recreate', '', 'Пересоздаём WARP');
				} }, 'Новые ключи')
			]));
			warpCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Не работает — «Перезапустить туннели». Медленно — «Сменить точки входа». Совсем не помогает — «Новые ключи».'));
		}

		// ── автоперезапуск ──

		function renderAuto() {
			autoCard.innerHTML = '';
			autoCard.style.display = data.installed && !data.blocker && (data.warp_on || data.has_sub) ? '' : 'none';
			if (!data.installed || data.blocker || !(data.warp_on || data.has_sub)) return;
			autoCard.appendChild(E('h3', {}, 'Автоперезапуск'));
			autoCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Туннели и Steer перезапускаются по расписанию — помогает, если обход со временем «подвисает».'));
			var cur = data.autorestart || '';
			var am = cur === '' ? 'off' : (cur.indexOf('every:') === 0 ? 'every' + cur.split(':')[1] : 'daily');
			var curHour = am === 'daily' ? parseInt(cur.split(':')[1], 10) : 4;
			if (isNaN(curHour) || curHour < 0 || curHour > 23) curHour = 4;
			var opts = [];
			for (var h = 0; h < 24; h++) opts.push(E('option', { 'value': String(h), 'selected': h === curHour ? 'selected' : null }, hh(h)));
			var hourSel = E('select', { 'class': 'cbi-input-select zm-hour-select' }, opts);
			var dailyRow = E('div', { 'class': 'zm-actions', 'style': am === 'daily' ? '' : 'display:none' }, [
				E('span', { 'class': 'zm-label' }, 'Время перезапуска'),
				hourSel,
				E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() { doAuto('daily:' + hourSel.value); } },
					am === 'daily' ? 'Сохранить время' : 'Включить')
			]);
			function tile(id, label, onclick) {
				return E('div', { 'class': 'zm-tile' + (am === id ? ' zm-active' : ''), 'click': onclick }, label);
			}
			autoCard.appendChild(E('div', { 'class': 'zm-grid' }, [
				tile('off', 'Выключен', function() { if (am !== 'off') doAuto('off'); }),
				tile('every2', 'Каждые 2 часа', function() { if (am !== 'every2') doAuto('every:2'); }),
				tile('every6', 'Каждые 6 часов', function() { if (am !== 'every6') doAuto('every:6'); }),
				tile('every12', 'Каждые 12 часов', function() { if (am !== 'every12') doAuto('every:12'); }),
				tile('daily', am === 'daily' ? 'Ежедневно в ' + hh(curHour) : 'Ежедневно в заданное время', function() {
					dailyRow.style.display = '';
					hourSel.focus();
				})
			]));
			autoCard.appendChild(dailyRow);
		}

		function doAuto(value) {
			if (autoBusy) { zm.toast('Дождитесь окончания текущей операции', 'warning'); return; }
			autoBusy = true;
			zm.steerAction('autorestart', value).then(function(res) {
				autoBusy = false;
				if (res.error) { zm.toast(res.error, 'error'); return; }
				zm.toast(value === 'off' ? 'Автоперезапуск выключен' : 'Автоперезапуск настроен', 'info');
				refresh();
			}).catch(function() { autoBusy = false; zm.toast('Роутер не ответил', 'error'); });
		}

		// ── спор за DNS ──

		function renderDns() {
			dnsCard.innerHTML = '';
			dnsCard.style.display = 'none';
			if (!data.dns_conflict || busy) return;
			dnsCard.style.display = '';
			dnsCard.appendChild(E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Нужно исправить DNS'),
				E('p', { 'class': 'zm-hint' }, 'DNS over HTTPS снова перехватывает запросы устройств, и сервисы через WARP не откроются. Шифрованный DNS после исправления продолжит работать.'),
				E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function() {
						zm.steerAction('dns_fix', '').then(function(res) {
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast('DNS исправлен', 'info');
							refresh();
						}).catch(function() { zm.toast('Роутер не ответил', 'error'); });
					} }, 'Исправить')
				])
			]));
		}

		// ── подписка ──

		function loadSub() {
			if (data.blocker) return;
			subLoading = true;
			zm.steerAction('sub_status', '').then(function(res) {
				subLoading = false;
				if (res && !res.error) {
					var old = subData && subData.list && subData.list.nodes ? subData.list.nodes.map(function(n) { return n.name; }).join('|') : null;
					subData = res;
					var now = res.list && res.list.nodes ? res.list.nodes.map(function(n) { return n.name; }).join('|') : null;
					if (old !== now) lat = {};
				}
				renderSub();
			}).catch(function() { subLoading = false; renderSub(); });
		}

		function subAct(action, arg, toastText) {
			act(action, arg, toastText);
		}

		function probeAll() {
			var nodes = (subData && subData.list && subData.list.nodes) || [];
			if (probing || !nodes.length) return;
			probing = true; probeDone = 0; probeTotal = nodes.length; lat = {};
			nodes.forEach(function(n) { lat[n.index] = { busy: true }; });
			renderSub();
			var queue = nodes.map(function(n) { return n.index; });
			function next() {
				if (!queue.length) return Promise.resolve();
				var i = queue.shift();
				return zm.steerAction('sub_probe', String(i)).then(function(res) {
					var r = res && res.results && res.results[0];
					lat[i] = r ? { ok: !!r.ok, ms: r.ttfb_ms > 0 ? r.ttfb_ms : r.handshake_ms, why: r.why } : { ok: false, why: (res && res.error) || '' };
				}).catch(function() { lat[i] = { ok: false }; }).then(function() {
					probeDone++;
					renderSub();
					return next();
				});
			}
			Promise.all([ next(), next(), next() ]).then(function() {
				probing = false;
				var ok = Object.keys(lat).filter(function(k) { return lat[k].ok; }).length;
				zm.toast('Проверка закончена: отвечают ' + ok + ' из ' + probeTotal, ok ? 'info' : 'warning');
				renderSub();
			});
		}

		function nodeCard(opts) {
			var cls = 'zm-node' + (opts.active ? ' zm-active' : '') + (opts.dead ? ' zm-node-dead' : '');
			return E('div', { 'class': cls, 'title': opts.title || '', 'click': opts.click }, [
				E('div', { 'class': 'zm-node-name' }, opts.name),
				E('div', { 'class': 'zm-node-foot' }, [
					E('span', {}, opts.foot || ''),
					E('span', { 'class': 'zm-lat ' + (opts.latCls || 'zm-lat-none') }, opts.lat || '')
				])
			]);
		}

		function renderSub() {
			subCard.innerHTML = '';
			subCard.style.display = data.blocker ? 'none' : '';
			if (data.blocker) return;
			subCard.appendChild(E('h3', {}, 'VPN: подписка или VLESS'));
			if (!data.installed) {
				subCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Выбранные сервисы могут идти через ваш сервер VLESS Reality. Сначала установите Steer.'));
				return;
			}
			if (!subData) { subCard.appendChild(E('p', { 'class': 'zm-hint' }, subLoading ? 'Загружаем…' : 'Нет данных')); return; }

			if (!subData.has) {
				subCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Выбранные сервисы пойдут через ваш сервер VLESS Reality. Вставьте ссылку на подписку или ссылки vless:// — по одной на строку.'));
				var ta = E('textarea', { 'class': 'zm-config-editor zm-sub-input', 'spellcheck': 'false', 'rows': '3', 'placeholder': 'https://… или vless://…' });
				ta.value = subInput;
				ta.addEventListener('input', function() { subInput = ta.value; });
				subCard.appendChild(ta);
				subCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button cbi-button-positive', 'disabled': busy ? '' : null, 'click': function() {
						var v = (subInput || '').trim();
						if (!/^https?:\/\//i.test(v) && !/vless:\/\//i.test(v)) { zm.toast('Нужна ссылка https://… или vless://…', 'warning'); return; }
						subInput = '';
						subAct('sub_set', v, 'Подключаем подписку');
					} }, 'Добавить'),
					!subData.ext ? E('span', { 'class': 'zm-hint', 'style': 'margin:0' }, 'Движок сам заменится на steer-extended') : ''
				]));
				return;
			}

			var q = subData.quota || {}, used = (+q.up || 0) + (+q.down || 0), total = +q.total || 0;
			var facts = [];
			if (q.up !== '' || q.down !== '' || q.total !== '') {
				var pct = total > 0 ? Math.min(100, Math.round(used * 100 / total)) : 0;
				facts.push(E('div', { 'class': 'zm-sub-fact' }, [
					E('span', {}, 'Трафик'),
					E('b', {}, fmtBytes(used) + ' / ' + (total > 0 ? fmtBytes(total) : '∞')),
					total > 0 ? E('div', { 'class': 'zm-quota' + (pct >= 90 ? ' zm-quota-high' : '') }, [ E('i', { 'style': 'width:' + pct + '%' }) ]) : ''
				]));
			}
			if (fmtDate(q.expire)) facts.push(E('div', { 'class': 'zm-sub-fact' }, [ E('span', {}, 'Действует до'), E('b', {}, fmtDate(q.expire)) ]));
			var nodes = (subData.list && subData.list.nodes) || [];
			facts.push(E('div', { 'class': 'zm-sub-fact' }, [ E('span', {}, 'Узлов'), E('b', {}, String(nodes.length)) ]));
			if (subData.updated) facts.push(E('div', { 'class': 'zm-sub-fact' }, [ E('span', {}, 'Обновлена'), E('b', {}, fmtDate(subData.updated)) ]));
			subCard.appendChild(E('div', { 'class': 'zm-sub-meta' }, [
				E('div', { 'class': 'zm-sub-title' }, subData.title || 'Подписка'),
				E('div', { 'class': 'zm-sub-facts' }, facts)
			]));

			var vpn = (data.exit || subData.exit) === 'vpn';
			if (vpn) {
				var v = subData.vpn || {}, pr = v.probe || {}, st;
				if (v.up) st = badge('zm-ok', 'подключено');
				else if (pr.state === 'probing') st = badge('zm-warn', 'ищем рабочий узел · ' + pr.node + ' из ' + pr.total);
				else if (pr.state === 'failed') st = badge('zm-bad', 'ни один узел не ответил');
				else if (pr.state === 'no_such_node') st = badge('zm-bad', 'выбранного узла больше нет');
				else st = badge(data.stopped ? 'zm-off' : 'zm-warn', data.stopped ? 'Steer выключен' : 'подключаемся');
				subCard.appendChild(row('Туннель', st));
			}

			var acts = [];
			if (subData.kind === 'url') acts.push(E('button', { 'class': 'cbi-button', 'disabled': busy ? '' : null, 'click': function() { subAct('sub_update', '', 'Обновляем подписку'); } }, 'Обновить'));
			acts.push(E('button', { 'class': 'cbi-button cbi-button-action', 'disabled': (probing || busy || !nodes.length) ? '' : null, 'click': probeAll },
				probing ? 'Проверяем ' + probeDone + ' из ' + probeTotal : 'Проверить задержку'));
			acts.push(E('button', { 'class': 'cbi-button cbi-button-remove', 'disabled': busy ? '' : null, 'click': function() {
				if (!confirm('Удалить подписку?' + (data.warp_on ? '\n\nВыбранные сервисы пойдут через WARP.' : '\n\nТуннеля не останется — сервисы пойдут напрямую.'))) return;
				subAct('sub_remove', '', 'Удаляем подписку');
			} }, 'Удалить'));
			subCard.appendChild(E('div', { 'class': 'zm-actions' }, acts));

			var grid = E('div', { 'class': 'zm-nodes' });
			grid.appendChild(nodeCard({
				name: 'Авто', foot: 'первый рабочий узел', active: !subData.node,
				click: function() { if (subData.node && !busy) subAct('sub_node', '', 'Выбираем узел автоматически'); }
			}));
			nodes.forEach(function(n, ni) {
				var l = lat[n.index], txt = '', cls = 'zm-lat-none', dead = false;
				if (l && l.busy) txt = '…';
				else if (l && l.ok) { txt = (l.ms > 0 ? l.ms : '?') + ' мс'; cls = latClass(l.ms); }
				else if (l) { txt = 'нет ответа'; cls = 'zm-lat-bad'; dead = true; }
				var foot = [ n.type, n.security !== 'none' ? n.security : '', n.vision ? 'vision' : '' ].filter(function(x) { return x; }).join(' · ');
				grid.appendChild(nodeCard({
					name: n.name || 'Узел ' + (ni + 1), foot: foot, lat: txt, latCls: cls, dead: dead,
					active: subData.node === n.name, title: l && l.why ? l.why : '',
					click: function() { if (subData.node !== n.name && !busy) subAct('sub_node', n.name, 'Выбираем узел ' + n.name); }
				}));
			});
			subCard.appendChild(grid);

			var sk = subData.list && subData.list.skipped_reasons || [];
			if (subData.list && subData.list.skipped > 0) subCard.appendChild(E('p', { 'class': 'zm-hint' },
				'Пропущено узлов: ' + subData.list.skipped + (sk.length ? ' — ' + sk.map(function(r) { return r.reason; }).slice(0, 2).join('; ') : '') + '. Steer умеет VLESS Reality (tcp, grpc, xhttp).'));
			if (!vpn && data.exit === 'warp') subCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас сервисы идут через ' + warpName() + ' — переключить можно в карточке Steer вверху. Выбор узла сохранится.'));
			if (subData.kind === 'url') {
				var AUTO = [ { id: 'off', name: 'Не обновлять' }, { id: '3', name: 'Каждые 3 часа' }, { id: '6', name: 'Каждые 6 часов' }, { id: '12', name: 'Каждые 12 часов' }, { id: '24', name: 'Раз в сутки' } ];
				var curAuto = subData.auto || 'off';
				subCard.appendChild(E('h4', { 'style': 'margin:16px 0 8px' }, 'Обновлять подписку'));
				subCard.appendChild(E('div', { 'class': 'zm-grid' }, AUTO.map(function(a) {
					return E('div', { 'class': 'zm-tile' + (curAuto === a.id ? ' zm-active' : ''), 'click': function() {
						if (curAuto === a.id) return;
						zm.steerAction('sub_auto', a.id).then(function(res) {
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast(a.id === 'off' ? 'Автообновление подписки выключено' : 'Подписка будет обновляться: ' + a.name.toLowerCase(), 'info');
							loadSub();
						}).catch(function() { zm.toast('Роутер не ответил', 'error'); });
					} }, a.name);
				})));
			}
		}

		function renderTabs() {
			tabBar.innerHTML = '';
			tabBar.style.display = data.blocker ? 'none' : '';
			STEER_TABS.forEach(function(t) {
				tabBar.appendChild(E('button', {
					'class': 'cbi-button' + (t.id === tab ? ' cbi-button-positive' : ''),
					'click': function() {
						tab = t.id;
						try { localStorage.setItem('zm.steer.tab', tab); } catch (e) {}
						renderTabs();
						if (tab === 'sub') loadSub();
					}
				}, t.label));
			});
			Object.keys(panes).forEach(function(k) { panes[k].style.display = k === tab ? '' : 'none'; });
		}

		function renderAll() {
			renderTabs();
			renderSub();
			renderMain();
			renderDns();
			renderLists();
			renderCustom();
			renderCheck();
			renderWarp();
			renderAuto();
		}

		renderAll();
		[ listCard, customCard, checkCard ].forEach(function(n) { panes.svc.appendChild(n); });
		[ warpCard, autoCard ].forEach(function(n) { panes.warp.appendChild(n); });
		panes.sub.appendChild(subCard);
		[ mainCard, logEl, dnsCard, tabBar, panes.svc, panes.warp, panes.sub ].forEach(function(n) { wrap.appendChild(n); });
		if (!data.blocker) { loadCustom(); loadSub(); }

		if (data.running) { lastAction = data.phase === 'remove' ? 'remove' : [ 'install', 'pkgs', 'awg', 'keys', 'tunnel' ].indexOf(data.phase) >= 0 ? 'install' : 'apply'; follow(); }
		else if (data.installed && !data.stopped && (parseInt(data.channels, 10) || 0) > 0) runDiag(true);
		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/steer.js'

mkdir -p /usr/share/zm-redbtn/lists
cat > '/usr/share/zm-redbtn/services.conf' << 'ZM_INSTALLER_EOF'
youtube|YouTube|svc_youtube.lst||www.youtube.com,youtubei.googleapis.com,manifest.googlevideo.com|youtu.be,i.ytimg.com,i9.ytimg.com,yt3.ggpht.com,yt4.ggpht.com,jnn-pa.googleapis.com,signaler-pa.youtube.com,yt3.googleusercontent.com,rr4---sn-4g5e6nze.googlevideo.com,rr4---sn-5go7yner.googlevideo.com,rr5---sn-n8v7knez.googlevideo.com,rr2---sn-q4fl6ndl.googlevideo.com,rr1---sn-q4fl6n6y.googlevideo.com,rr14---sn-n8v7kn7r.googlevideo.com,rr4---sn-jvhnu5g-c35d.googlevideo.com,rr1---sn-gvnuxaxjvh-jx3z.googlevideo.com,rr12---sn-gvnuxaxjvh-bvwz.googlevideo.com,rr1---sn-ug5onuxaxjvh-n8v6.googlevideo.com||youtube
discord|Discord|svc_discord.lst|discord.lst|discord.com,gateway.discord.gg,updates.discord.com|cdn.discordapp.com,media.discordapp.net||discord
instagram|Instagram|svc_meta.lst|meta.lst|www.instagram.com|i.instagram.com,graph.instagram.com,scontent.cdninstagram.com||meta
whatsapp|WhatsApp|svc_meta.lst|whatsapp.lst|web.whatsapp.com|static.whatsapp.net,mmg.whatsapp.net||meta
x|X (Twitter)|svc_twitter.lst|twitter_x.lst|x.com|twitter.com,abs.twimg.com,video.twimg.com||twitter
github|GitHub|own_github.lst||github.com,raw.githubusercontent.com,objects.githubusercontent.com|codeload.github.com,api.github.com,ghcr.io||
telegram|Telegram|svc_telegram.lst|telegram.lst|web.telegram.org|t.me,core.telegram.org,telegra.ph||telegram
tiktok|TikTok||||||tiktok
hdrezka|HDRezka||||||hdrezka
google_meet|Google Meet||||||google_meet
geoblock|Геоблок||||||geoblock
block|Заблокированные сайты||||||block
news|Новости||||||news
anime|Аниме||||||anime
porn|Сайты 18+||||||porn
russia_inside|Всё сразу (Russia inside)||||||russia_inside
custom|Свой список||||||
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/svc_youtube.lst' << 'ZM_INSTALLER_EOF'
ggpht.com
googlevideo.com
jnn-pa.googleapis.com
returnyoutubedislikeapi.com
wide-youtube.l.google.com
youtu.be
youtube-nocookie.com
youtube-ui.l.google.com
youtube.com
youtubeembeddedplayer.googleapis.com
youtubei.googleapis.com
youtubekids.com
yt-video-upload.l.google.com
yt.be
yt3.googleusercontent.com
ytimg.com
ytimg.l.google.com
yting.com
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/svc_telegram.lst' << 'ZM_INSTALLER_EOF'
t.me
telegram.me
telegram.org
telegram.dog
telegra.ph
telesco.pe
tdesktop.com
telegram-cdn.org
cdn-telegram.org
graph.org
tg.dev
fragment.com
comments.app
contest.com
tx.me
telegram.space
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/telegram.lst' << 'ZM_INSTALLER_EOF'
91.105.192.0/23
91.108.4.0/22
91.108.8.0/22
91.108.12.0/22
91.108.16.0/22
91.108.20.0/22
91.108.56.0/22
95.161.64.0/20
149.154.160.0/20
185.76.151.0/24
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/svc_discord.lst' << 'ZM_INSTALLER_EOF'
dis.gd
discord-activities.com
discord-attachments-uploads-prd.storage.googleapis.com
discord.co
discord.com
discord.design
discord.dev
discord.gg
discord.gift
discord.gifts
discord.media
discord.new
discord.store
discord.tools
discordactivities.com
discordapp.com
discordapp.net
discordmerch.com
discordpartygames.com
discordsays.com
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/svc_meta.lst' << 'ZM_INSTALLER_EOF'
cdninstagram.com
circlecrewpinkcrowd.com
facebook.com
facebook.net
fb.com
fbcdn.net
fbsbx.com
ig.me
instagram.com
internalfb.com
meta.com
oculus.com
threads.com
threads.net
wa.me
whatsapp.biz
whatsapp.com
whatsapp.net
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/svc_twitter.lst' << 'ZM_INSTALLER_EOF'
ads-twitter.com
cms-twdigitalassets.com
periscope.tv
pscp.tv
t.co
tellapart.com
tweetdeck.com
twimg.com
twitpic.com
twitter.biz
twitter.com
twitter.jp
twittercommunity.com
twitterflightschool.com
twitterinc.com
twitteroauth.com
twitterstat.us
twtrdns.net
twttr.com
twttr.net
twvid.com
vine.co
x.com
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/own_github.lst' << 'ZM_INSTALLER_EOF'
api.github.com
avatars.githubusercontent.com
camo.githubusercontent.com
codeload.github.com
ghcr.io
gist.githubusercontent.com
github.com
github.dev
github.io
githubassets.com
githubusercontent.com
npm.pkg.github.com
objects.githubusercontent.com
pkg.github.com
raw.githubusercontent.com
release-assets.githubusercontent.com
uploads.github.com
user-images.githubusercontent.com
www.github.com
ZM_INSTALLER_EOF
rm -f '/usr/share/zm-redbtn/lists/geoblock.lst'
cat > '/usr/share/zm-redbtn/lists/discord.lst' << 'ZM_INSTALLER_EOF'
138.128.137.32/28
138.128.140.240/28
172.65.202.16/28
34.0.129.176/28
34.0.130.176/28
34.0.130.64/28
34.0.132.128/28
34.0.134.48/28
34.0.140.48/28
34.0.141.96/28
35.207.209.32/28
35.212.102.48/28
35.212.111.16/28
35.212.111.32/28
35.212.120.112/28
35.212.12.144/28
35.212.4.128/28
35.212.88.0/28
35.213.0.0/28
35.213.0.176/28
35.213.101.208/28
35.213.10.16/28
35.213.102.160/28
35.213.102.224/28
35.213.10.224/28
35.213.102.32/28
35.213.10.32/28
35.213.105.144/28
35.213.105.32/28
35.213.106.176/28
35.213.106.192/28
35.213.106.224/28
35.213.107.144/28
35.213.109.144/28
35.213.109.16/28
35.213.110.32/28
35.213.111.16/28
35.213.11.16/28
35.213.111.80/28
35.213.115.16/28
35.213.115.48/28
35.213.115.96/28
35.213.120.128/28
35.213.120.32/28
35.213.122.128/28
35.213.122.208/28
35.213.12.224/27
35.213.122.96/28
35.213.124.80/28
35.213.125.32/28
35.213.126.176/28
35.213.127.208/28
35.213.127.48/28
35.213.128.176/28
35.213.128.64/28
35.213.129.0/28
35.213.130.16/28
35.213.130.208/28
35.213.131.128/28
35.213.13.16/28
35.213.131.64/28
35.213.132.48/28
35.213.132.64/28
35.213.133.176/28
35.213.135.48/28
35.213.136.192/28
35.213.136.32/28
35.213.137.48/28
35.213.139.144/28
35.213.139.64/28
35.213.141.160/28
35.213.14.208/28
35.213.142.208/28
35.213.142.224/27
35.213.143.176/28
35.213.143.32/28
35.213.145.112/28
35.213.145.144/28
35.213.146.192/28
35.213.147.176/28
35.213.149.32/28
35.213.149.96/27
35.213.150.160/28
35.213.150.32/28
35.213.152.0/28
35.213.152.144/28
35.213.153.160/27
35.213.157.0/28
35.213.158.96/27
35.213.160.80/28
35.213.162.112/28
35.213.162.48/28
35.213.163.224/28
35.213.163.80/28
35.213.164.160/28
35.213.164.224/28
35.213.165.32/28
35.213.165.96/28
35.213.16.64/28
35.213.167.160/27
35.213.168.176/28
35.213.168.64/28
35.213.169.176/28
35.213.170.0/28
35.213.172.144/28
35.213.17.224/28
35.213.173.0/28
35.213.173.128/28
35.213.174.224/28
35.213.175.176/28
35.213.176.112/28
35.213.176.48/28
35.213.177.112/28
35.213.180.0/28
35.213.181.112/28
35.213.181.32/28
35.213.181.64/28
35.213.182.208/28
35.213.182.96/28
35.213.183.176/28
35.213.184.80/28
35.213.185.240/28
35.213.185.32/28
35.213.186.64/28
35.213.188.176/28
35.213.188.192/28
35.213.191.80/28
35.213.194.64/28
35.213.195.176/28
35.213.196.32/28
35.213.198.32/28
35.213.199.192/28
35.213.199.96/28
35.213.202.112/28
35.213.2.0/28
35.213.204.32/28
35.213.205.160/28
35.213.210.224/28
35.213.213.224/28
35.213.214.16/28
35.213.217.112/28
35.213.217.192/28
35.213.222.208/28
35.213.223.176/28
35.213.225.16/28
35.213.227.224/28
35.213.229.16/28
35.213.231.112/28
35.213.231.224/28
35.213.23.160/28
35.213.233.144/28
35.213.233.64/28
35.213.238.128/28
35.213.246.112/28
35.213.246.32/28
35.213.247.224/28
35.213.247.96/28
35.213.25.160/28
35.213.252.208/28
35.213.252.32/28
35.213.26.48/28
35.213.27.240/28
35.213.32.192/28
35.213.32.32/28
35.213.32.80/28
35.213.33.64/28
35.213.34.192/28
35.213.37.80/28
35.213.38.176/28
35.213.39.240/28
35.213.4.176/28
35.213.42.224/27
35.213.42.64/28
35.213.43.64/28
35.213.45.112/28
35.213.45.128/28
35.213.45.80/28
35.213.46.128/28
35.213.49.16/28
35.213.50.192/28
35.213.50.32/28
35.213.51.208/28
35.213.52.0/28
35.213.52.112/28
35.213.53.128/28
35.213.53.48/28
35.213.54.208/28
35.213.54.64/28
35.213.56.48/28
35.213.56.64/28
35.213.59.208/28
35.213.59.96/28
35.213.6.112/28
35.213.61.48/28
35.213.65.112/28
35.213.65.160/28
35.213.67.0/28
35.213.67.176/28
35.213.68.192/28
35.213.68.224/27
35.213.70.144/28
35.213.7.160/28
35.213.7.192/28
35.213.72.160/28
35.213.72.208/28
35.213.73.240/28
35.213.74.128/28
35.213.78.16/28
35.213.78.176/28
35.213.78.224/28
35.213.79.128/28
35.213.80.0/28
35.213.80.80/28
35.213.8.160/28
35.213.83.176/28
35.213.83.240/28
35.213.84.240/28
35.213.85.144/28
35.213.85.96/28
35.213.88.144/28
35.213.89.80/28
35.213.90.144/28
35.213.90.192/28
35.213.90.48/28
35.213.91.192/28
35.213.92.176/28
35.213.92.240/28
35.213.92.64/28
35.213.93.240/28
35.213.94.64/28
35.213.95.144/28
35.213.96.80/28
35.213.98.112/28
35.213.98.128/28
35.213.99.112/28
35.214.137.128/28
35.214.140.176/28
35.214.142.112/28
35.214.151.176/28
35.214.163.16/28
35.214.169.192/28
35.214.171.16/28
35.214.181.160/28
35.214.194.208/28
35.214.198.0/28
35.214.205.144/28
35.214.209.64/28
35.214.213.16/28
35.214.216.144/28
35.214.225.32/28
35.214.227.32/28
35.214.245.16/28
35.214.250.16/28
35.215.108.96/28
35.215.115.112/28
35.215.126.32/28
35.215.127.32/28
35.215.128.16/28
35.215.128.80/28
35.215.134.224/28
35.215.135.160/28
35.215.135.16/28
35.215.136.16/28
35.215.137.224/28
35.215.138.0/28
35.215.138.176/28
35.215.138.192/28
35.215.139.128/28
35.215.140.0/28
35.215.140.48/28
35.215.141.80/28
35.215.142.0/28
35.215.145.64/28
35.215.149.176/28
35.215.151.112/28
35.215.152.144/28
35.215.154.240/28
35.215.156.160/28
35.215.160.208/28
35.215.161.112/28
35.215.161.224/28
35.215.163.96/28
35.215.166.160/28
35.215.166.240/28
35.215.168.160/28
35.215.170.0/28
35.215.170.64/28
35.215.171.48/28
35.215.172.48/28
35.215.173.192/28
35.215.174.16/28
35.215.174.208/28
35.215.175.32/28
35.215.178.16/28
35.215.180.144/28
35.215.182.176/28
35.215.184.240/28
35.215.185.64/28
35.215.186.32/28
35.215.186.96/28
35.215.188.112/28
35.215.188.192/28
35.215.189.112/28
35.215.190.48/28
35.215.190.96/28
35.215.192.208/28
35.215.193.224/28
35.215.193.80/28
35.215.194.192/28
35.215.195.96/28
35.215.196.0/28
35.215.196.48/28
35.215.196.64/28
35.215.198.224/28
35.215.200.16/28
35.215.202.128/28
35.215.204.128/28
35.215.205.16/28
35.215.206.160/28
35.215.206.32/28
35.215.207.112/28
35.215.208.208/28
35.215.210.240/28
35.215.211.0/28
35.215.213.176/28
35.215.215.32/28
35.215.216.96/28
35.215.217.16/28
35.215.217.80/28
35.215.218.48/28
35.215.218.80/28
35.215.221.160/28
35.215.221.16/28
35.215.222.224/28
35.215.224.16/28
35.215.225.224/28
35.215.226.32/28
35.215.227.80/28
35.215.228.192/28
35.215.229.64/28
35.215.231.80/28
35.215.232.16/28
35.215.232.208/28
35.215.233.48/28
35.215.235.176/28
35.215.235.240/28
35.215.235.96/28
35.215.238.16/28
35.215.238.80/28
35.215.240.160/28
35.215.240.192/28
35.215.241.208/28
35.215.243.192/28
35.215.244.240/28
35.215.245.128/28
35.215.245.32/28
35.215.247.80/28
35.215.248.160/28
35.215.249.80/28
35.215.250.128/28
35.215.251.128/28
35.215.251.224/28
35.215.254.112/28
35.215.255.80/28
35.215.72.80/28
35.215.73.64/28
35.215.83.0/28
5.200.14.240/28
66.22.196.0/26
66.22.196.128/27
66.22.196.224/28
66.22.196.64/27
66.22.197.0/28
66.22.197.128/27
66.22.197.208/28
66.22.197.32/27
66.22.197.64/27
66.22.197.96/28
66.22.198.0/26
66.22.198.128/26
66.22.198.80/28
66.22.198.96/28
66.22.199.128/28
66.22.199.16/28
66.22.199.176/28
66.22.199.192/26
66.22.199.32/27
66.22.199.64/27
66.22.199.96/28
66.22.200.0/28
66.22.200.32/28
66.22.200.64/27
66.22.202.0/28
66.22.202.32/28
66.22.202.64/27
66.22.202.96/28
66.22.204.160/27
66.22.204.16/28
66.22.204.192/28
66.22.204.64/28
66.22.204.96/28
66.22.206.0/27
66.22.206.160/27
66.22.206.32/28
66.22.206.96/28
66.22.208.0/27
66.22.208.32/28
66.22.210.0/27
66.22.210.32/28
66.22.216.0/25
66.22.216.128/26
66.22.216.192/28
66.22.217.0/25
66.22.217.128/26
66.22.217.192/28
66.22.218.0/26
66.22.218.64/27
66.22.218.96/28
66.22.219.0/26
66.22.219.64/27
66.22.219.96/28
66.22.220.0/28
66.22.220.144/28
66.22.220.160/28
66.22.220.48/28
66.22.220.80/28
66.22.221.0/28
66.22.221.128/27
66.22.221.160/28
66.22.221.48/28
66.22.221.64/27
66.22.221.96/28
66.22.224.0/26
66.22.225.0/26
66.22.226.0/27
66.22.226.80/28
66.22.226.96/27
66.22.227.0/27
66.22.231.0/25
66.22.231.128/26
66.22.231.192/27
66.22.232.0/28
66.22.232.128/28
66.22.239.0/28
66.22.239.128/28
66.22.240.0/28
66.22.240.128/28
66.22.245.0/26
66.22.245.128/26
66.22.246.0/26
66.22.246.128/26
66.22.246.192/27
66.22.246.224/28
66.22.246.64/27
66.22.247.0/27
66.22.247.128/27
66.22.248.0/25
66.22.248.128/26
66.22.248.192/27
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/meta.lst' << 'ZM_INSTALLER_EOF'
31.13.24.0/21
31.13.64.0/18
45.64.40.0/22
57.141.0.0/24
57.141.2.0/23
57.141.4.0/23
57.141.6.0/24
57.141.8.0/24
57.141.10.0/24
57.141.12.0/23
57.141.14.0/24
57.141.16.0/22
57.141.20.0/24
57.141.22.0/24
57.141.24.0/24
57.144.0.0/14
66.220.144.0/20
69.63.176.0/20
69.171.224.0/19
74.119.76.0/22
102.132.96.0/20
103.4.96.0/22
129.134.0.0/17
157.240.0.0/17
157.240.192.0/18
163.70.128.0/17
163.77.132.0/23
163.77.136.0/23
173.252.64.0/18
179.60.192.0/22
185.60.216.0/22
185.89.216.0/22
204.15.20.0/22
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/whatsapp.lst' << 'ZM_INSTALLER_EOF'
31.13.24.0/21
31.13.64.0/18
45.64.40.0/22
57.141.0.0/24
57.141.2.0/23
57.141.4.0/23
57.141.6.0/24
57.141.8.0/24
57.141.10.0/24
57.141.12.0/23
57.141.14.0/24
57.141.16.0/22
57.141.20.0/24
57.141.22.0/24
57.141.24.0/24
57.144.0.0/14
66.220.144.0/20
69.63.176.0/20
69.171.224.0/19
74.119.76.0/22
102.132.96.0/20
103.4.96.0/22
129.134.0.0/17
157.240.0.0/17
157.240.192.0/18
163.70.128.0/17
163.77.132.0/23
163.77.136.0/23
173.252.64.0/18
179.60.192.0/22
185.60.216.0/22
185.89.216.0/22
204.15.20.0/22
ZM_INSTALLER_EOF
cat > '/usr/share/zm-redbtn/lists/twitter_x.lst' << 'ZM_INSTALLER_EOF'
64.63.0.0/18
103.252.112.0/22
104.244.41.0/24
104.244.42.0/24
104.244.44.0/22
184.105.99.0/24
188.64.224.0/21
192.133.76.0/22
199.16.156.0/22
199.59.148.0/22
199.96.56.0/23
202.160.128.0/22
208.91.196.0/23
ZM_INSTALLER_EOF
chmod 0644 /usr/share/zm-redbtn/services.conf /usr/share/zm-redbtn/lists/*.lst

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/hosts.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var LABELS = {
	nalog: 'nalog.ru',
	ntc: 'ntc.party',
	instagram: 'Instagram & Facebook',
	librusec: 'lib.rus.ec',
	ai: 'AI сервисы (ChatGPT, Claude, Gemini)',
	twitch: 'Twitch',
	telegram: 'Telegram Web',
	spotify: 'Spotify',
	rutor: 'rutor.info',
	scell: 'Supercell (Clash, Brawl Stars)',
	githubraw: 'githubusercontent.com',
	github: 'GitHub',
	tapeop: 'tapeop.dev'
};

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.hostsStatus();
	},

	render: function(data) {
		var wrap = E('div', { 'class': 'zm-wrap' });
		var grid = E('div', { 'class': 'zm-grid' });
		var busy = false;

		function renderGrid(items) {
			grid.innerHTML = '';
			(items || []).forEach(function(it) {
				grid.appendChild(E('div', {
					'class': 'zm-tile' + (it.enabled ? ' zm-active' : ''),
					'click': function() {
						if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						busy = true;
						zm.toast('Переключаем ' + (LABELS[it.id] || it.id) + '', 'warning');
						zm.hostsToggle(it.id).then(function(res) {
							busy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast((LABELS[it.id] || it.id) + (res.enabled ? ' включён' : ' выключен'), 'info');
							zm.hostsStatus().then(function(r) { renderGrid(r.items); });
						}).catch(function() { busy = false; });
					}
				}, LABELS[it.id] || it.id));
			});
		}

		renderGrid(data.items);

		var card = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Домены в /etc/hosts'),
			grid,
			E('p', { 'class': 'zm-hint' }, 'Нажмите на блок, чтобы включить или выключить прописанные IP этого сервиса.')
		]);
		wrap.appendChild(card);

		var geoLogEl = E('pre', { 'class': 'zm-log' });
		var geoGrid = E('div', { 'class': 'zm-grid' });

		function renderGeoGrid() {
			geoGrid.innerHTML = '';
			geoGrid.appendChild(E('div', { 'class': 'zm-tile' + (data.geohide === 'ru' ? ' zm-active' : ''), 'click': function() { replaceGeohide('ru'); } }, 'GeoHide RU'));
			geoGrid.appendChild(E('div', { 'class': 'zm-tile' + (data.geohide === 'eu' ? ' zm-active' : ''), 'click': function() { replaceGeohide('eu'); } }, 'GeoHide EU'));
			geoGrid.appendChild(E('div', { 'class': 'zm-tile' + (data.geohide === 'us' ? ' zm-active' : ''), 'click': function() { replaceGeohide('us'); } }, 'GeoHide US'));
		}
		renderGeoGrid();

		var geoCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Заменить hosts на GeoHide'),
			E('p', { 'class': 'zm-hint' }, 'Внимание: это ПОЛНОСТЬЮ заменит файл /etc/hosts на список от GeoHide DNS — все блоки выше и любые ваши собственные записи будут удалены.'),
			geoGrid,
			geoLogEl
		]);
		wrap.appendChild(geoCard);

		var resetLogEl = E('pre', { 'class': 'zm-log' });
		var resetBtn = E('button', { 'class': 'cbi-button cbi-button-remove', 'click': resetHosts }, 'Восстановить hosts');

		var resetCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Восстановить hosts'),
			E('p', { 'class': 'zm-hint' }, 'Вернёт /etc/hosts к чистому виду — уберёт и блоки выше, и GeoHide, и всё, что было добавлено вручную.'),
			E('div', { 'class': 'zm-actions' }, [ resetBtn ]),
			resetLogEl
		]);
		wrap.appendChild(resetCard);

		function refreshAll() {
			zm.hostsStatus().then(function(res) {
				data = res;
				renderGrid(res.items);
				renderGeoGrid();
			});
		}

		function replaceGeohide(region) {
			if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			busy = true;
			zm.toast('Заменяем hosts на GeoHide ' + region.toUpperCase() + '', 'warning');
			geoLogEl.classList.add('zm-show');
			zm.renderLog(geoLogEl, '==> Скачиваем и заменяем /etc/hosts');
			zm.hostsReplaceGeohide(region).then(function(res) {
				busy = false;
				if (res.error) { zm.renderLog(geoLogEl, '==> ОШИБКА: ' + res.error); zm.toast(res.error, 'error'); return; }
				zm.renderLog(geoLogEl, '==> Готово — hosts заменён на GeoHide ' + region.toUpperCase() + '.');
				zm.toast('hosts заменён на GeoHide ' + region.toUpperCase(), 'info');
				refreshAll();
			}).catch(function() { busy = false; });
		}

		function resetHosts() {
			if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			busy = true;
			zm.toast('Восстанавливаем hosts', 'warning');
			resetLogEl.classList.add('zm-show');
			zm.renderLog(resetLogEl, '==> Восстанавливаем hosts');
			zm.hostsReset().then(function(res) {
				busy = false;
				if (res.error) { zm.renderLog(resetLogEl, '==> ОШИБКА: ' + res.error); zm.toast(res.error, 'error'); return; }
				zm.renderLog(resetLogEl, '==> Готово — hosts восстановлен.');
				zm.toast('hosts восстановлен', 'info');
				refreshAll();
			}).catch(function() { busy = false; });
		}

		var editorCard = E('div', { 'class': 'zm-card' });
		var editorOpen = false;
		var hostsEl = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false', 'style': 'display:none' });
		var editorBusy = false;

		function refreshHostsFile() {
			zm.hostsFileGet().then(function(res) {
				if (res.error) { zm.toast(res.error, 'error'); return; }
				hostsEl.value = res.content || '';
			});
		}

		function renderEditorCard() {
			editorCard.innerHTML = '';
			editorCard.appendChild(E('h3', {}, 'Редактор /etc/hosts'));
			if (!editorOpen) {
				editorCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Прямое редактирование всего файла /etc/hosts.'));
				editorCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': 'cbi-button',
						'click': function() {
							editorOpen = true;
							refreshHostsFile();
							renderEditorCard();
						}
					}, 'Открыть редактор hosts')
				]));
				return;
			}
			editorCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сохранение перезапускает dnsmasq. Резервная копия предыдущей версии остаётся в /etc/hosts.bak.'));
			hostsEl.style.display = '';
			editorCard.appendChild(hostsEl);
			editorCard.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', {
					'class': 'cbi-button',
					'click': function() { refreshHostsFile(); zm.toast('Содержимое перечитано с диска', 'info'); }
				}, 'Обновить из файла'),
				E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() {
						if (editorBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						editorBusy = true;
						zm.toast('Сохраняем hosts', 'warning');
						zm.hostsFileSet(hostsEl.value).then(function(res) {
							editorBusy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast('hosts сохранён, dnsmasq перезапущен', 'info');
							refreshAll();
						}).catch(function() { editorBusy = false; });
					}
				}, 'Сохранить и применить'),
				E('button', {
					'class': 'cbi-button',
					'click': function() { editorOpen = false; renderEditorCard(); }
				}, 'Свернуть')
			]));
		}
		renderEditorCard();
		wrap.appendChild(editorCard);

		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/hosts.js'

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/mixomo.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var PRESETS = [
	{ id: 'ih1', label: 'Internet Helper' },
	{ id: 'itdog', label: 'ITDog' },
	{ id: 'ih2', label: 'Internet Helper (старый)' }
];

var TABS = [
	{ id: 'main', label: 'Mixomo' },
	{ id: 'config', label: 'Конфигурация Mihomo' },
	{ id: 'magitrickle', label: 'MagiTrickle' },
	{ id: 'warp', label: 'WARP' }
];

return view.extend({
	load: function() {
		zm.injectCss();
		return Promise.all([ zm.mixomoStatus(), zm.mixomoWarpStatus().catch(function() { return {}; }) ]);
	},

	render: function(all) {
		var view = this;
		var data = all[0];
		var warpData = all[1] || {};
		var wrap = E('div', { 'class': 'zm-wrap' });
		var busy = false;
		var activeTab = 'main';

		var tabBar = E('div', { 'class': 'zm-actions', 'style': 'margin-bottom:14px' });
		var panels = {};
		TABS.forEach(function(t) {
			panels[t.id] = E('div', { 'style': t.id === activeTab ? '' : 'display:none' });
		});

		function renderTabBar() {
			tabBar.innerHTML = '';
			TABS.forEach(function(t) {
				tabBar.appendChild(E('button', {
					'class': 'cbi-button' + (t.id === activeTab ? ' cbi-button-positive' : ''),
					'click': function() {
						activeTab = t.id;
						TABS.forEach(function(t2) { panels[t2.id].style.display = t2.id === activeTab ? '' : 'none'; });
						renderTabBar();
					}
				}, t.label));
			});
		}

		var mainLogEl = E('pre', { 'class': 'zm-log' });
		var statusCard = E('div', { 'class': 'zm-card' });
		var panelCard = E('div', { 'class': 'zm-card' });
		var subCard = E('div', { 'class': 'zm-card' });
		var autoCard = E('div', { 'class': 'zm-card' });

		function verRow(label, ver, latest) {
			var text = ver || '—';
			if (ver && latest && ver !== latest) text += ' (доступно ' + latest + ')';
			return E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, label),
				E('span', {}, text)
			]);
		}

		function applyInstalled(installed) {
			tabBar.style.display = installed ? '' : 'none';
			[ panelCard, subCard, autoCard ].forEach(function(c) { c.style.display = installed ? '' : 'none'; });
			if (!installed && activeTab !== 'main') {
				activeTab = 'main';
				TABS.forEach(function(t2) { panels[t2.id].style.display = t2.id === activeTab ? '' : 'none'; });
				renderTabBar();
			}
		}

		function renderStatus(d) {
			statusCard.innerHTML = '';
			var installed = d.mihomo === 'installed';
			applyInstalled(installed);
			var allRunning = d.mihomo_running === true && d.hev_running === true && d.magitrickle_running === true;
			var hasUpdate = (d.mihomo_version && d.mihomo_latest && d.mihomo_version !== d.mihomo_latest) ||
				(d.magitrickle_version && d.magitrickle_latest && d.magitrickle_version !== d.magitrickle_latest);
			var actions = [];
			if (installed) {
				actions.push(E('button', {
					'class': 'cbi-button cbi-button-remove',
					'click': function() { doAction('remove'); }
				}, 'Удалить'));
				actions.push(E('button', {
					'class': 'cbi-button',
					'click': function() { doAction(allRunning ? 'stop' : 'start'); }
				}, allRunning ? 'Остановить' : 'Запустить'));
				actions.push(E('button', {
					'class': 'cbi-button',
					'click': function() { doAction('restart'); }
				}, 'Перезапустить'));
				actions.push(E('button', {
					'class': hasUpdate ? 'cbi-button cbi-button-positive' : 'cbi-button',
					'click': function() { doAction('update'); }
				}, hasUpdate ? 'Обновить (есть новые версии)' : 'Переустановить/обновить'));
				if (d.mihomo_running) {
					actions.push(E('a', {
						'class': 'cbi-button',
						'href': 'http://' + window.location.hostname + ':9090/ui',
						'target': '_blank', 'rel': 'noreferrer'
					}, 'Войти в панель Mihomo'));
				}
			} else {
				actions.push(E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() { doAction('install'); }
				}, 'Установить'));
			}
			statusCard.appendChild(E('h3', {}, 'Mixomo'));
			statusCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Связка из трёх программ: Mihomo (прокси-ядро) + hev-socks5-tunnel (мост в туннель) + MagiTrickle (направляет в туннель только выбранные сайты).'));
			statusCard.appendChild(E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'Mihomo'),
				installed ? zm.badge(d.mihomo_running === true, 'запущен', 'остановлен') : zm.badge(false, '', 'не установлен')
			]));
			if (installed) {
				statusCard.appendChild(verRow('Версия Mihomo', d.mihomo_version, d.mihomo_latest));
				statusCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'hev-socks5-tunnel'),
					zm.badge(d.hev === 'installed' && d.hev_running === true, d.hev === 'installed' ? 'запущен' : '', d.hev === 'installed' ? 'остановлен' : 'не установлен')
				]));
				if (d.hev_version) {
					statusCard.appendChild(E('div', { 'class': 'zm-row' }, [
						E('span', { 'class': 'zm-label' }, 'Версия hev-socks5-tunnel'), E('span', {}, d.hev_version)
					]));
				}
				statusCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'MagiTrickle'),
					zm.badge(d.magitrickle === 'installed' && d.magitrickle_running === true, d.magitrickle === 'installed' ? 'запущен' : '', d.magitrickle === 'installed' ? 'остановлен' : 'не установлен')
				]));
				if (d.magitrickle_version) statusCard.appendChild(verRow('Версия MagiTrickle', d.magitrickle_version, d.magitrickle_latest));
				statusCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Подписка'),
					zm.badge(d.subscription === true, 'настроена', 'не настроена')
				]));
			}
			statusCard.appendChild(E('div', { 'class': 'zm-actions' }, actions));
		}

		var uiBusy = false;
		function renderPanel(d) {
			panelCard.innerHTML = '';
			panelCard.appendChild(E('h3', {}, 'Веб-панель Mihomo'));
			panelCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Собственный веб-интерфейс Mihomo (статистика, выбор прокси вручную). По умолчанию ставится MetaCubeXD.'));
			if (d.mihomo !== 'installed') {
				panelCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Установите Mixomo, чтобы выбрать панель.'));
				return;
			}
			panelCard.appendChild(E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'Сейчас'),
				E('span', {}, d.ui_panel === 'zashboard' ? 'Zashboard' : d.ui_panel === 'metacubexd' ? 'MetaCubeXD' : 'не выбрана')
			]));
			panelCard.appendChild(E('div', { 'class': 'zm-grid' }, [
				E('div', {
					'class': 'zm-tile' + (d.ui_panel === 'zashboard' ? ' zm-active' : ''),
					'click': function() { doUi('zashboard'); }
				}, 'Zashboard'),
				E('div', {
					'class': 'zm-tile' + (d.ui_panel === 'metacubexd' ? ' zm-active' : ''),
					'click': function() { doUi('metacubexd'); }
				}, 'MetaCubeXD')
			]));
		}

		function doUi(which) {
			if (uiBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			uiBusy = true;
			zm.toast('Устанавливаем панель', 'warning');
			zm.mixomoUiAction(which).then(function(res) {
				if (res.error) { uiBusy = false; zm.toast(res.error, 'error'); return; }
				zm.pollJob('mixomo_ui_install', mainLogEl, function(ok) {
					uiBusy = false;
					zm.toast(ok ? 'Панель установлена' : 'Ошибка установки', ok ? 'info' : 'error');
					zm.mixomoStatus().then(renderPanel);
				});
			}).catch(function() { uiBusy = false; });
		}

		function doAction(action) {
			if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			var job = action === 'remove' ? 'mixomo_remove' : 'mixomo_install';
			var isBg = action === 'install' || action === 'update' || action === 'remove';
			busy = true;
			zm.toast(
				action === 'remove' ? 'Удаляем Mixomo'
				: action === 'update' ? 'Обновляем Mixomo (три программы, может занять пару минут)'
				: action === 'install' ? 'Устанавливаем Mixomo (три программы, может занять пару минут)'
				: action === 'start' ? 'Запускаем Mixomo'
				: action === 'stop' ? 'Останавливаем Mixomo'
				: 'Перезапускаем Mixomo',
				'warning'
			);
			zm.mixomoAction(action).then(function(res) {
				if (res.error) { busy = false; zm.toast(res.error, 'error'); return; }
				if (isBg && res.started) {
					zm.pollJob(job, mainLogEl, function(ok) {
						busy = false;
						zm.toast(ok ? 'Готово' : 'Ошибка', ok ? 'info' : 'error');
						refreshAll();
					});
				} else {
					busy = false;
					refreshAll();
					zm.toast('Готово', 'info');
				}
			}).catch(function() { busy = false; });
		}

		function refreshAll() {
			zm.mixomoStatus().then(function(d) {
				renderStatus(d);
				renderPanel(d);
				renderPresets(d);
				renderEmbed(d);
				renderAuto(d);
				renderMtStatus(d);
			});
		}

		var subInput = E('input', { 'type': 'text', 'placeholder': 'https://...', 'class': 'cbi-input-text' });
		var subBusy = false;
		subCard.appendChild(E('h3', {}, 'Подписка'));
		subCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Вставьте ссылку на VPN-подписку — если в конфигурации уже настроен провайдер подписки, обновится только ссылка; если нет, будет создана готовая конфигурация с раздельной маршрутизацией YouTube и остального трафика через подписку.'));
		subCard.appendChild(E('div', { 'class': 'zm-actions' }, [
			subInput,
			E('button', {
				'class': 'cbi-button cbi-button-positive',
				'click': function() {
					if (subBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
					var url = subInput.value.trim();
					if (!/^https?:\/\//.test(url)) { zm.toast('Ссылка должна начинаться с http:// или https://', 'error'); return; }
					subBusy = true;
					zm.toast('Применяем подписку', 'warning');
					zm.mixomoApplySubscription(url).then(function(res) {
						subBusy = false;
						if (res.error) { zm.toast(res.error, 'error'); return; }
						zm.toast(res.mode === 'updated' ? 'Ссылка на подписку обновлена' : 'Подписка применена, создана новая конфигурация', 'info');
						refreshAll();
						refreshConfig();
					}).catch(function() { subBusy = false; });
				}
			}, 'Применить подписку')
		]));

		var autoBusy = false;
		function renderAuto(d) {
			autoCard.innerHTML = '';
			autoCard.appendChild(E('h3', {}, 'Автоперезапуск Mihomo'));
			autoCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Периодический перезапуск по расписанию — полезно для VPN-подписок, у которых иногда «зависает» соединение.'));
			var cur = d.autorestart || '';
			var mode = cur === '' ? 'off' : (cur.indexOf('every:') === 0 ? 'every' + cur.split(':')[1] : 'daily');
			var curHour = mode === 'daily' ? parseInt(cur.split(':')[1], 10) : 4;
			if (isNaN(curHour) || curHour < 0 || curHour > 23) curHour = 4;
			function hh(h) { return (h < 10 ? '0' : '') + h + ':00'; }

			var opts = [];
			for (var h = 0; h < 24; h++)
				opts.push(E('option', { 'value': String(h), 'selected': h === curHour ? 'selected' : null }, hh(h)));
			var hourSel = E('select', { 'class': 'cbi-input-select zm-hour-select' }, opts);

			var dailyRow = E('div', { 'class': 'zm-actions', 'style': mode === 'daily' ? '' : 'display:none' }, [
				E('span', { 'class': 'zm-label' }, 'Время перезапуска'),
				hourSel,
				E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() { doAuto('daily', hourSel.value); }
				}, mode === 'daily' ? 'Сохранить время' : 'Включить')
			]);

			function tile(id, label, onclick) {
				return E('div', { 'class': 'zm-tile' + (mode === id ? ' zm-active' : ''), 'click': onclick }, label);
			}
			autoCard.appendChild(E('div', { 'class': 'zm-grid' }, [
				tile('off', 'Выключен', function() { if (mode !== 'off') doAuto('off', ''); }),
				tile('every2', 'Каждые 2 часа', function() { if (mode !== 'every2') doAuto('every', '2'); }),
				tile('every6', 'Каждые 6 часов', function() { if (mode !== 'every6') doAuto('every', '6'); }),
				tile('daily', mode === 'daily' ? 'Ежедневно в ' + hh(curHour) : 'Ежедневно в заданное время', function() {
					dailyRow.style.display = '';
					hourSel.focus();
				})
			]));
			autoCard.appendChild(dailyRow);
		}

		function doAuto(mode, value) {
			if (autoBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			autoBusy = true;
			zm.toast('Настраиваем автоперезапуск', 'warning');
			zm.mixomoAutorestartSet(mode, value).then(function(res) {
				autoBusy = false;
				if (res.error) { zm.toast(res.error, 'error'); return; }
				zm.toast('Автоперезапуск настроен', 'info');
				zm.mixomoStatus().then(renderAuto);
			}).catch(function() { autoBusy = false; });
		}

		panels.main.appendChild(statusCard);
		panels.main.appendChild(mainLogEl);
		panels.main.appendChild(panelCard);
		panels.main.appendChild(subCard);
		panels.main.appendChild(autoCard);

		var configEl = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false' });
		var configBusy = false;
		var configCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Редактор конфигурации Mihomo'),
			E('p', { 'class': 'zm-hint' }, 'Прямое редактирование /etc/mihomo/config.yaml. Проверка — как в оригинальном установщике: сохранение перезапускает Mihomo, и если он не поднимается с новой конфигурацией, изменения автоматически откатываются, а рабочая версия остаётся нетронутой.')
		]);
		configCard.appendChild(configEl);

		function refreshConfig() {
			zm.mixomoConfigGet().then(function(res) {
				if (res.error) { configEl.value = ''; configEl.placeholder = res.error; return; }
				configEl.value = res.content || '';
			});
		}

		configCard.appendChild(E('div', { 'class': 'zm-actions' }, [
			E('button', {
				'class': 'cbi-button',
				'click': function() { refreshConfig(); zm.toast('Конфигурация перечитана с диска', 'info'); }
			}, 'Обновить из файла'),
			E('button', {
				'class': 'cbi-button cbi-button-positive',
				'click': function() {
					if (configBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
					configBusy = true;
					zm.toast('Сохраняем и проверяем конфигурацию', 'warning');
					zm.mixomoConfigSet(configEl.value).then(function(res) {
						configBusy = false;
						if (res.error) { zm.toast(res.error, 'error', 12000); return; }
						zm.toast('Проверка пройдена, Mihomo перезапущен с новой конфигурацией', 'info');
						refreshAll();
					}).catch(function() { configBusy = false; });
				}
			}, 'Сохранить и применить')
		]));
		panels.config.appendChild(configCard);

		var mtStatusCard = E('div', { 'class': 'zm-card' });
		var presetCard = E('div', { 'class': 'zm-card' });
		var embedCard = E('div', { 'class': 'zm-card' });

		function renderMtStatus(d) {
			mtStatusCard.innerHTML = '';
			mtStatusCard.appendChild(E('h3', {}, 'MagiTrickle'));
			mtStatusCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Направляет в туннель Mixomo только выбранные сайты и адреса — остальной трафик идёт напрямую через провайдера. Устанавливается вместе с Mixomo на вкладке «Mixomo».'));
			mtStatusCard.appendChild(E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'Статус'),
				d.magitrickle === 'installed' ? zm.badge(d.magitrickle_running === true, 'запущен', 'остановлен') : zm.badge(false, '', 'не установлен')
			]));
			if (d.magitrickle_version) mtStatusCard.appendChild(verRow('Версия', d.magitrickle_version, d.magitrickle_latest));
		}

		var presetBusy = false;
		function renderPresets(d) {
			presetCard.innerHTML = '';
			presetCard.appendChild(E('h3', {}, 'Готовые списки доменов'));
			presetCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Быстрая замена текущего списка на один из готовых наборов — зелёным отмечен список, применённый сейчас. Для собственного точного набора сайтов используйте окно ниже.'));
			if (d.magitrickle !== 'installed') {
				presetCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Установите Mixomo на вкладке «Mixomo», чтобы выбрать список.'));
				return;
			}
			presetCard.appendChild(E('div', { 'class': 'zm-grid' }, PRESETS.map(function(p) {
				return E('div', {
					'class': 'zm-tile' + (d.magitrickle_list === p.id ? ' zm-active' : ''),
					'click': function() {
						if (presetBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						presetBusy = true;
						zm.toast('Применяем список: ' + p.label, 'warning');
						zm.mixomoMagitrickleListSet(p.id).then(function(res) {
							presetBusy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast('Список применён: ' + p.label, 'info');
							waitForListAppliedThenRefresh(p.id);
						}).catch(function() { presetBusy = false; });
					}
				}, p.label);
			})));
		}

		var mtFrame = null;
		function refreshMtEmbed() {
			if (mtFrame) { mtFrame.src = mtFrame.src.split('?')[0] + '?_r=' + Date.now(); }
		}

		function waitForListAppliedThenRefresh(presetId) {
			var attempts = 0;
			var maxAttempts = 20;
			var timer = setInterval(function() {
				attempts++;
				zm.mixomoStatus().then(function(d) {
					if (d.magitrickle_list === presetId) {
						clearInterval(timer);
						renderPresets(d);
						setTimeout(refreshMtEmbed, 2500);
					} else if (attempts >= maxAttempts) {
						clearInterval(timer);
						renderPresets(d);
						setTimeout(refreshMtEmbed, 2500);
					}
				});
			}, 500);
		}

		function renderEmbed(d) {
			embedCard.innerHTML = '';
			embedCard.appendChild(E('h3', {}, 'Окно MagiTrickle'));
			if (d.magitrickle !== 'installed') {
				embedCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Установите Mixomo, чтобы открыть управление группами и подписками MagiTrickle.'));
				mtFrame = null;
				return;
			}
			var host = window.location.hostname;
			var url = 'http://' + host + ':8080';
			if (window.location.protocol === 'https:') {
				mtFrame = null;
				embedCard.appendChild(E('p', { 'class': 'zm-hint' }, 'HTTPS-соединение блокирует встроенное окно MagiTrickle. Откройте его в новой вкладке для управления «Группами» и «Подписками» — после применения готового списка выше просто обновите ту вкладку.'));
				embedCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('a', { 'class': 'cbi-button cbi-button-positive', 'href': url, 'target': '_blank', 'rel': 'noreferrer' }, 'Открыть MagiTrickle')
				]));
			} else {
				mtFrame = E('iframe', {
					'src': url,
					'style': 'width:100%; height:640px; border:1px solid rgba(0,0,0,.1); border-radius:10px'
				});
				embedCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', { 'class': 'cbi-button', 'click': refreshMtEmbed }, 'Обновить окно MagiTrickle')
				]));
				embedCard.appendChild(mtFrame);
			}
		}

		panels.magitrickle.appendChild(mtStatusCard);
		panels.magitrickle.appendChild(presetCard);
		panels.magitrickle.appendChild(embedCard);

		var warpLogEl = E('pre', { 'class': 'zm-log' });
		var warpStatusCard = E('div', { 'class': 'zm-card' });
		var warpConfCard = E('div', { 'class': 'zm-card' });
		var warpBusy = false;
		var warpIntegrateBusy = false;

		function renderWarpStatus(w) {
			warpStatusCard.innerHTML = '';
			warpStatusCard.appendChild(E('h3', {}, 'WARP'));
			warpStatusCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Генерирует бесплатный ключ Cloudflare WARP и сохраняет его в /root/WARP.conf. Дальше файл можно интегрировать в Mihomo как ещё один прокси-выход.'));
			warpStatusCard.appendChild(E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'WARP.conf'),
				zm.badge(w.exists === true, 'сгенерирован', 'не сгенерирован')
			]));
			warpStatusCard.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() { doWarpGenerate('fixed'); }
				}, 'Сгенерировать WARP'),
				E('button', {
					'class': 'cbi-button',
					'click': function() { doWarpGenerate('auto'); }
				}, 'Сгенерировать с подбором endpoint'),
				E('button', {
					'class': 'cbi-button',
					'click': function() {
						if (warpIntegrateBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						if (w.exists !== true) { zm.toast('Сначала сгенерируйте WARP.conf', 'error'); return; }
						warpIntegrateBusy = true;
						zm.toast('Интегрируем WARP в Mihomo', 'warning');
						zm.mixomoWarpIntegrateAction().then(function(res) {
							if (res.error) { warpIntegrateBusy = false; zm.toast(res.error, 'error'); return; }
							zm.pollJob('mixomo_warp_integrate', warpLogEl, function(ok) {
								warpIntegrateBusy = false;
								zm.toast(ok ? 'WARP добавлен в Mihomo как прокси' : 'Ошибка интеграции', ok ? 'info' : 'error');
								if (ok) refreshConfig();
							});
						}).catch(function() { warpIntegrateBusy = false; });
					}
				}, 'Интегрировать в Mihomo')
			]));
		}

		function doWarpGenerate(mode) {
			if (warpBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			warpBusy = true;
			zm.toast(mode === 'auto' ? 'Подбираем сервер и генерируем WARP (может занять минуту)' : 'Генерируем WARP', 'warning');
			zm.mixomoWarpAction(mode).then(function(res) {
				if (res.error) { warpBusy = false; zm.toast(res.error, 'error'); return; }
				zm.pollJob('mixomo_warp', warpLogEl, function(ok) {
					warpBusy = false;
					zm.toast(ok ? 'WARP сгенерирован' : 'Не удалось сгенерировать WARP', ok ? 'info' : 'error');
					zm.mixomoWarpStatus().then(function(w) { renderWarpStatus(w); renderWarpConf(w); });
				});
			}).catch(function() { warpBusy = false; });
		}

		var warpConfigEl = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false' });
		var warpConfigBusy = false;
		function renderWarpConf(w) {
			warpConfigEl.value = w.content || '';
		}

		warpConfCard.appendChild(E('h3', {}, 'Редактор WARP.conf'));
		warpConfCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Можно вставить сюда свой готовый WARP.conf (например, купленный отдельно ключ) вместо генерации выше — при сохранении проверяются обязательные поля ([Interface]/[Peer], PrivateKey/PublicKey).'));
		warpConfCard.appendChild(warpConfigEl);
		warpConfCard.appendChild(E('div', { 'class': 'zm-actions' }, [
			E('button', {
				'class': 'cbi-button',
				'click': function() {
					zm.mixomoWarpStatus().then(function(w) { renderWarpConf(w); });
					zm.toast('Содержимое перечитано с диска', 'info');
				}
			}, 'Обновить из файла'),
			E('button', {
				'class': 'cbi-button cbi-button-positive',
				'click': function() {
					if (warpConfigBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
					warpConfigBusy = true;
					zm.toast('Сохраняем WARP.conf', 'warning');
					zm.mixomoWarpConfigSet(warpConfigEl.value).then(function(res) {
						warpConfigBusy = false;
						if (res.error) { zm.toast(res.error, 'error', 10000); return; }
						zm.toast('WARP.conf сохранён', 'info');
						zm.mixomoWarpStatus().then(function(w) { renderWarpStatus(w); renderWarpConf(w); });
					}).catch(function() { warpConfigBusy = false; });
				}
			}, 'Сохранить')
		]));

		panels.warp.appendChild(warpStatusCard);
		panels.warp.appendChild(warpLogEl);
		panels.warp.appendChild(warpConfCard);

		renderTabBar();
		renderStatus(data);
		renderPanel(data);
		renderPresets(data);
		renderEmbed(data);
		renderAuto(data);
		renderMtStatus(data);
		renderWarpStatus(warpData);
		renderWarpConf(warpData);
		refreshConfig();

		wrap.appendChild(tabBar);
		TABS.forEach(function(t) { wrap.appendChild(panels[t.id]); });
		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/mixomo.js'

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/strategy.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var TABS = [
	{ id: 'strategy', label: 'Стратегии' },
	{ id: 'test', label: 'Тест стратегий' },
	{ id: 'youtube', label: 'YouTube' },
	{ id: 'game', label: 'Игры' },
	{ id: 'discord', label: 'Discord' },
	{ id: 'domains_exclude', label: 'Домены исключения' },
	{ id: 'exclusions', label: 'Исключение устройств' }
];

var TEST_MODES = [
	{ id: 'v', label: 'Тестировать v' },
	{ id: 'flowseal', label: 'Тестировать Flowseal' },
	{ id: 'v_flowseal', label: 'Тестировать v + Flowseal' }
];
var TEST_MODE_LABELS = {
	v: 'v', flowseal: 'Flowseal', v_flowseal: 'v + Flowseal', youtube: 'YouTube', current: 'Текущая стратегия'
};
var TEST_RESULT_MODES = ['v', 'flowseal', 'v_flowseal', 'youtube', 'current'];
var TEST_MAIN_MODES = ['v', 'flowseal', 'v_flowseal'];

var GAME_FAKES = [
	'stun.bin', 'stun2.bin', 'quic_initial_4pda_to.bin',
	'quic_initial_tencent_com.bin', 'tls_clienthello_sochi_park.bin',
	'quic_initial_www_google_com.bin', 'quic_initial_steamcommunity_com.bin',
	'quic_initial_5ka_ru.bin', 'quic_initial_rutube_ru.bin'
];

return view.extend({
	load: function() {
		zm.injectCss();
		return Promise.all([
			zm.status(),
			zm.strategyListV(),
			zm.testStatus(),
			zm.strategyListYoutube(),
			zm.gameStatus(),
			zm.discordStatus(),
			zm.exclusionsStatus(),
			zm.zapretLatestVersion().catch(function() { return {}; })
		]);
	},

	render: function(all) {
		var view = this;
		var statusData = all[0], vListData = all[1], testData = all[2], ytInitialData = all[3], gameData = all[4], discordData = all[5], exclusionsData = all[6];
		var latestVersion = (all[7] && all[7].version) || '';
		var wrap = E('div', { 'class': 'zm-wrap' });
		var mainSection = E('div', {});
		var activeTab = 'strategy';
		var zapretInstalled = statusData.zapret === 'installed';

		var tabBar = E('div', { 'class': 'zm-actions', 'style': 'margin:10px 0' });
		var panels = {};
		var tabHooks = {};
		// Смена любой стратегии меняет и соседние вкладки (Yv, Gv, Dv и строку стратегии) —
		// после каждого действия обновляются все, и ещё раз — при переходе на вкладку.
		var refreshers = {};
		function refreshAll() {
			Object.keys(refreshers).forEach(function(k) { try { refreshers[k](); } catch (e) {} });
		}
		TABS.forEach(function(t) {
			panels[t.id] = E('div', { 'style': t.id === activeTab ? '' : 'display:none' });
		});

		function renderTabBar() {
			tabBar.innerHTML = '';
			TABS.forEach(function(t) {
				tabBar.appendChild(E('button', {
					'class': 'cbi-button' + (t.id === activeTab ? ' cbi-button-positive' : ''),
					'click': function() {
						activeTab = t.id;
						TABS.forEach(function(t2) { panels[t2.id].style.display = t2.id === activeTab ? '' : 'none'; });
						renderTabBar();
						if (tabHooks[t.id]) tabHooks[t.id]();
					}
				}, t.label));
			});
		}

		(function buildStrategyPanel() {
			var status = statusData, vList = vListData;
			var lastFlowseal = null;
			var logEl = E('pre', { 'class': 'zm-log' });
			var busy = false;

			var zBusy = false;
			var zLogEl = E('pre', { 'class': 'zm-log' });
			var zBannerEl = E('div', {});
			var zCardWrap = E('div', {});

			function renderZCard(d) {
				zCardWrap.innerHTML = '';
				var zActions = [];
				if (d.zapret === 'installed') {
					zActions.push(E('button', {
						'class': 'cbi-button cbi-button-remove',
						'click': function() { doZapretAction('remove'); }
					}, 'Удалить'));
					if (/^[0-9]+\.[0-9]+$/.test(latestVersion) && d.zapret_version && latestVersion !== d.zapret_version) {
						zActions.push(E('button', {
							'class': 'cbi-button',
							'click': function() { doZapretAction('update'); }
						}, 'Обновить до ' + latestVersion));
					}
					zActions.push(E('button', {
						'class': 'cbi-button',
						'click': function() { doZapretAction(d.zapret_running ? 'stop' : 'start'); }
					}, d.zapret_running ? 'Остановить' : 'Запустить'));
				} else {
					zActions.push(E('button', {
						'class': 'cbi-button cbi-button-positive',
						'click': function() { doZapretAction('install'); }
					}, 'Установить и настроить'));
				}

				var fields = [
					E('span', { 'style': 'display:inline-flex; align-items:center; gap:8px' }, [ E('span', { 'class': 'zm-label' }, 'Статус'),
						d.zapret === 'installed'
							? zm.badge(d.zapret_running === true, 'запущен', 'остановлен')
							: zm.badge(false, '', 'не установлен')
					])
				];
				if (d.zapret_version) fields.push(E('span', { 'style': 'display:inline-flex; align-items:center; gap:8px' }, [ E('span', { 'class': 'zm-label' }, 'Версия'), E('span', {}, d.zapret_version) ]));
				if (d.strategy) fields.push(E('span', { 'style': 'display:inline-flex; align-items:center; gap:8px' }, [ E('span', { 'class': 'zm-label' }, 'Стратегия'), E('span', {}, d.strategy) ]));

				zCardWrap.appendChild(E('div', { 'class': 'zm-card', 'style': 'margin-bottom:10px' }, [
					E('h3', {}, 'Zapret'),
					E('div', { 'class': 'zm-row', 'style': 'justify-content:space-between; width:100%' }, [
						E('div', { 'style': 'display:flex; gap:22px; flex-wrap:wrap; align-items:center' }, fields),
						E('div', { 'class': 'zm-actions', 'style': 'margin:0' }, zActions)
					])
				]));
			}

			function doZapretAction(action) {
				if (zBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
				var job = (action === 'install' || action === 'update') ? 'install_zapret'
					: (action === 'remove') ? 'remove_zapret' : null;
				var LABELS = { install: 'Устанавливаем и настраиваем Zapret', update: 'Обновляем Zapret', remove: 'Удаляем Zapret', start: 'Запускаем Zapret', stop: 'Останавливаем Zapret' };
				zm.toast(LABELS[action] || 'Выполняем', 'warning');
				if (job) zBusy = true;

				zm.zapretAction(action).then(function(res) {
					if (job && res && res.started) {
						zm.pollJob(job, zLogEl, function(ok) {
							zBusy = false;
							zm.toast(ok ? 'Готово' : 'Операция завершилась с ошибкой', ok ? 'info' : 'error');
							zm.status().then(function(d) { status = d; renderZCard(d); renderBanner(); renderV(); refreshAll(); });
							if (ok && (action === 'install' || action === 'remove')) {
								zBannerEl.innerHTML = '';
								zBannerEl.appendChild(zm.refreshBanner('Пункт меню Zapret в LuCI мог измениться — выйдите и зайдите заново.'));
							}
						});
					} else if (res) {
						zBusy = false;
						status = res;
						renderZCard(res);
						renderBanner();
						renderV();
					}
				}).catch(function() { zBusy = false; });
			}

			renderZCard(status);
			mainSection.appendChild(zCardWrap);
			mainSection.appendChild(zLogEl);
			mainSection.appendChild(zBannerEl);

			var currentBanner = E('div', { 'class': 'zm-current-banner zm-current-top' });
			panels.strategy.appendChild(currentBanner);

			var vGrid = E('div', { 'class': 'zm-grid' });
			var vCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Стратегии v1 – v10'),
				vGrid
			]);

			var fGrid = E('div', { 'class': 'zm-grid' });
			var fCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Стратегии Flowseal'),
				E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': 'cbi-button',
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Обновляем список Flowseal', 'warning');
							fGrid.innerHTML = 'Загрузка списка';
							zm.strategyListFlowseal('refresh').then(function(res) {
								if (res.started) {
									zm.pollJob('flowseal_download', logEl, function(ok) {
										busy = false;
										zm.toast(ok ? 'Список Flowseal обновлён' : 'Не удалось обновить список', ok ? 'info' : 'error');
										zm.strategyListFlowseal().then(renderFlowseal);
									});
								} else {
									busy = false;
									renderFlowseal(res);
									zm.toast('Список Flowseal обновлён', 'info');
								}
							}).catch(function() { busy = false; });
						}
					}, 'Обновить список')
				]),
				fGrid
			]);

			function renderBanner() {
				currentBanner.className = 'zm-current-banner zm-current-top' + (status.strategy ? '' : ' zm-current-empty');
				currentBanner.innerHTML = '';
				if (status.strategy) {
					currentBanner.appendChild(E('span', {}, 'Сейчас применено: '));
					currentBanner.appendChild(E('b', {}, status.strategy));
				} else {
					currentBanner.appendChild(E('span', {}, 'Стратегия ещё не выбрана'));
				}
			}

			function renderV() {
				vGrid.innerHTML = '';
				(vList.items || []).forEach(function(it) {
					var words = (' ' + (status.strategy || '') + ' ');
					vGrid.appendChild(E('div', {
						'class': 'zm-tile' + (!status.flowseal && words.indexOf(' ' + it.id + ' ') !== -1 ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Применяем стратегию ' + it.id + '', 'warning');
							zm.strategySetV(it.id).then(function(res) {
								busy = false;
								if (!zm.notifyStrategyResult(res, it.id)) return;
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, it.id));
				});
			}

			function renderFlowseal(res) {
				lastFlowseal = res;
				fGrid.innerHTML = '';
				(res.items || []).forEach(function(it) {
					fGrid.appendChild(E('div', {
						'class': 'zm-tile' + (status.flowseal === it.id ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Применяем стратегию ' + it.label + '', 'warning');
							zm.strategySetFlowseal(it.id).then(function(r2) {
								busy = false;
								if (!zm.notifyStrategyResult(r2, it.id)) return;
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, it.label));
				});
				if (!res.items || !res.items.length)
					fGrid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список пуст — нажмите «Обновить список».'));
			}

			function refreshState() {
				zm.status().then(function(s) {
					status = s;
					renderBanner();
					renderV();
					if (lastFlowseal) renderFlowseal(lastFlowseal);
				});
			}

			tabHooks.strategy = refreshState;
			refreshers.strategy = refreshState;
			renderBanner();
			renderV();

			panels.strategy.appendChild(vCard);
			panels.strategy.appendChild(fCard);
			panels.strategy.appendChild(logEl);

			zm.strategyListFlowseal().then(function(res) {
				if (!res.started) { renderFlowseal(res); return; }
				busy = true;
				fGrid.appendChild(E('p', { 'class': 'zm-hint' }, 'Загружаем список…'));
				zm.pollJob('flowseal_download', logEl, function(ok) {
					busy = false;
					if (!ok) { fGrid.innerHTML = ''; fGrid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список не загрузился — нажмите «Обновить список».')); return; }
					zm.strategyListFlowseal().then(renderFlowseal);
				});
			});

			var nfqwsCard = E('div', { 'class': 'zm-card' });
			var nfqwsOpen = false;
			var nfqwsEl = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false', 'style': 'display:none' });
			var nfqwsBusy = false;

			function refreshNfqwsOpt() {
				zm.nfqwsOptGet().then(function(res) {
					if (res.error) { zm.toast(res.error, 'error'); return; }
					nfqwsEl.value = res.content || '';
				});
			}

			function renderNfqwsCard() {
				nfqwsCard.innerHTML = '';
				nfqwsCard.appendChild(E('h3', {}, 'Редактировать текущую стратегию'));
				if (!nfqwsOpen) {
					nfqwsCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Ручная правка блока NFQWS_OPT — для опытных пользователей.'));
					nfqwsCard.appendChild(E('div', { 'class': 'zm-actions' }, [
						E('button', {
							'class': 'cbi-button',
							'click': function() {
								nfqwsOpen = true;
								refreshNfqwsOpt();
								renderNfqwsCard();
							}
						}, 'Открыть редактор стратегии')
					]));
					return;
				}
				nfqwsCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Блок NFQWS_OPT из /etc/config/zapret. «Сохранить и применить» перезапустит Zapret.'));
				nfqwsEl.style.display = '';
				nfqwsCard.appendChild(nfqwsEl);
				nfqwsCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': 'cbi-button',
						'click': function() { refreshNfqwsOpt(); zm.toast('Содержимое перечитано с диска', 'info'); }
					}, 'Обновить из файла'),
					E('button', {
						'class': 'cbi-button cbi-button-positive',
						'click': function() {
							if (nfqwsBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							nfqwsBusy = true;
							zm.toast('Сохраняем стратегию', 'warning');
							zm.nfqwsOptSet(nfqwsEl.value).then(function(res) {
								nfqwsBusy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast('Сохранено, Zapret перезапущен', 'info');
								refreshAll();
							}).catch(function() { nfqwsBusy = false; });
						}
					}, 'Сохранить и применить'),
					E('button', {
						'class': 'cbi-button',
						'click': function() { nfqwsOpen = false; renderNfqwsCard(); }
					}, 'Свернуть')
				]));
			}
			renderNfqwsCard();
			panels.strategy.appendChild(nfqwsCard);
		})();

		(function buildTestPanel() {
			var logEl = E('pre', { 'class': 'zm-log' });
			var resultsEl = E('pre', { 'class': 'zm-log' });
			var busy = testData.running === true;
			var curMode = testData.mode || '';
			var status = testData;

			var mainCard = E('div', { 'class': 'zm-card' });
			var ytCard = E('div', { 'class': 'zm-card' });
			var curCard = E('div', { 'class': 'zm-card' });
			var resultsButtonsEl = E('div', {});

			function stopButton() {
				return E('button', { 'class': 'cbi-button cbi-button-remove', 'click': doStop }, 'Остановить тестирование стратегий');
			}

			function renderMain() {
				mainCard.innerHTML = '';
				mainCard.appendChild(E('h3', {}, 'Тест стратегий v / Flowseal'));
				mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Тест идёт в фоне — его не прервут ни смена вкладки, ни закрытие страницы. После теста настройки возвращаются как были. Лучшую стратегию примените сами на вкладке «Стратегии».'));
				if (busy && TEST_MAIN_MODES.indexOf(curMode) !== -1) {
					mainCard.appendChild(E('div', { 'class': 'zm-row' }, [
						E('span', { 'class': 'zm-label' }, 'Статус'),
						zm.badge(true, 'тест выполняется (' + (TEST_MODE_LABELS[curMode] || curMode) + ')', '')
					]));
					mainCard.appendChild(E('div', { 'class': 'zm-actions' }, [ stopButton() ]));
				} else if (busy) {
					mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас выполняется другой тест — дождитесь его завершения.'));
				} else {
					mainCard.appendChild(E('div', { 'class': 'zm-actions' }, TEST_MODES.map(function(m) {
						return E('button', {
							'class': 'cbi-button cbi-button-positive',
							'click': function() { doStart(m.id); }
						}, m.label);
					})));
				}
			}

			function renderYt() {
				ytCard.innerHTML = '';
				ytCard.appendChild(E('h3', {}, 'Тест стратегий YouTube (Yv)'));
				ytCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Проверяет только YouTube-стратегии (Yv).'));
				if (busy && curMode === 'youtube') {
					ytCard.appendChild(E('div', { 'class': 'zm-row' }, [
						E('span', { 'class': 'zm-label' }, 'Статус'),
						zm.badge(true, 'тест выполняется', '')
					]));
					ytCard.appendChild(E('div', { 'class': 'zm-actions' }, [ stopButton() ]));
				} else if (busy) {
					ytCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас выполняется другой тест — дождитесь его завершения.'));
				} else {
					ytCard.appendChild(E('div', { 'class': 'zm-actions' }, [
						E('button', {
							'class': 'cbi-button cbi-button-positive',
							'click': function() { doStart('youtube'); }
						}, 'Тестировать YouTube')
					]));
				}
			}

			function renderCur() {
				curCard.innerHTML = '';
				curCard.appendChild(E('h3', {}, 'Тест текущей стратегии'));
				curCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Проверяет стратегию, которая стоит сейчас, ничего не меняя: отдельно по заблокированным сайтам и по YouTube.'));
				if (busy && curMode === 'current') {
					curCard.appendChild(E('div', { 'class': 'zm-row' }, [
						E('span', { 'class': 'zm-label' }, 'Статус'),
						zm.badge(true, 'тест выполняется', '')
					]));
					curCard.appendChild(E('div', { 'class': 'zm-actions' }, [ stopButton() ]));
				} else if (busy) {
					curCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас выполняется другой тест — дождитесь его завершения.'));
				} else {
					curCard.appendChild(E('div', { 'class': 'zm-actions' }, [
						E('button', {
							'class': 'cbi-button cbi-button-positive',
							'click': function() { doStart('current'); }
						}, 'Тестировать текущую стратегию')
					]));
				}
			}

			function startPolling() {
				logEl.classList.add('zm-show');
				zm.pollJob('strategy_test', logEl, function(ok) {
					busy = false;
					curMode = '';
					zm.toast(ok ? 'Тест завершён' : 'Тест завершился с ошибкой', ok ? 'info' : 'error');
					renderMain();
					renderYt();
					renderCur();
					zm.testStatus().then(function(res) {
						status = res;
						renderResultsButtons();
					});
				});
			}

			function doStart(mode) {
				if (busy) { zm.toast('Дождитесь завершения текущего теста', 'warning'); return; }
				busy = true;
				curMode = mode;
				renderMain();
				renderYt();
				renderCur();
				zm.toast('Запускаем тест стратегий', 'warning');
				zm.testAction('start', mode).then(function(res) {
					if (res.error) { busy = false; curMode = ''; zm.toast(res.error, 'error'); renderMain(); renderYt(); renderCur(); return; }
					startPolling();
				}).catch(function() { busy = false; curMode = ''; renderMain(); renderYt(); renderCur(); });
			}

			function doStop() {
				zm.toast('Останавливаем тест', 'warning');
				zm.testAction('stop').then(function(res) {
					if (res.error) { zm.toast(res.error, 'error'); return; }
					zm.toast('Тест остановлен, конфигурация восстанавливается', 'info');
				});
			}

			function renderResultsColored(el, text) {
				el.innerHTML = '';
				var lines = (text || '').split('\n').filter(function(l) { return l; });
				var controlOk = null;
				lines.forEach(function(line) {
					var m = line.match(/^(.*?)\s*→\s*(\d+)\/(\d+)\s*$/);
					if (m && /^Контрольный тест/.test(m[1])) controlOk = +m[2];
				});
				var first = true;
				lines.forEach(function(line) {
					var div = document.createElement('div');
					var m = line.match(/^(.*?)\s*→\s*(\d+)\/(\d+)\s*$/);
					if (m) {
						var name = m[1], ok = +m[2], total = +m[3];
						var isControl = /^Контрольный тест/.test(name);
						var nameSpan = document.createElement('span');
						nameSpan.textContent = name + ' → ';
						var scoreSpan = document.createElement('span');
						scoreSpan.textContent = ok + '/' + total;
						if (isControl) {
							div.className = 'zm-log-code';
						} else {
							if (ok === total) scoreSpan.className = 'zm-log-msg-ok';
							else if (controlOk !== null && ok < controlOk) scoreSpan.className = 'zm-log-msg-error';
							else scoreSpan.className = 'zm-log-msg-warn';
							if (first) { nameSpan.style.fontWeight = '700'; first = false; }
						}
						div.appendChild(nameSpan);
						div.appendChild(scoreSpan);
					} else {
						div.className = 'zm-log-code';
						div.textContent = line;
					}
					el.appendChild(div);
				});
			}

			function showResultsFor(mode) {
				zm.testResults(mode).then(function(res) {
					resultsEl.classList.add('zm-show');
					renderResultsColored(resultsEl, res.lines || '');
				});
			}

			function renderResultsButtons() {
				resultsButtonsEl.innerHTML = '';
				var actions = [];
				TEST_RESULT_MODES.forEach(function(m) {
					if (!status['has_results_' + m]) return;
					actions.push(E('button', {
						'class': 'cbi-button',
						'click': function() { showResultsFor(m); }
					}, 'Показать результаты: ' + TEST_MODE_LABELS[m]));
				});
				if (actions.length) {
					resultsButtonsEl.appendChild(E('div', { 'class': 'zm-actions' }, actions));
				} else {
					resultsButtonsEl.appendChild(E('p', { 'class': 'zm-hint' }, 'Пока нет сохранённых результатов — запустите тест.'));
				}
			}

			var resultsCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Результаты тестирования'),
				resultsButtonsEl,
				resultsEl
			]);

			renderMain();
			renderYt();
			renderCur();
			renderResultsButtons();

			if (busy) { startPolling(); }

			panels.test.appendChild(mainCard);
			panels.test.appendChild(ytCard);
			panels.test.appendChild(curCard);
			panels.test.appendChild(logEl);
			panels.test.appendChild(resultsCard);
		})();

		(function buildYoutubePanel() {
			var status = statusData, initial = ytInitialData;
			var logEl = E('pre', { 'class': 'zm-log' });
			var grid = E('div', { 'class': 'zm-grid' });
			var lastList = null;
			var current = '';
			var busy = false;

			function currentYv(s) {
				var words = (s.strategy || '').split(' ');
				for (var i = 0; i < words.length; i++) {
					if (/^Yv[0-9]+$/.test(words[i])) return words[i];
				}
				return '';
			}

			function renderGrid(res) {
				lastList = res;
				grid.innerHTML = '';
				grid.appendChild(E('div', {
					'class': 'zm-tile' + (yvOff && !current ? ' zm-active' : ''),
					'click': function() {
						if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						if (yvOff && !current) return;
						busy = true;
						zm.toast('Выключаем YouTube-стратегию', 'warning');
						zm.strategySetYoutube('off').then(function(r2) {
							busy = false;
							if (r2.error) { zm.toast(r2.error, 'error'); return; }
							zm.toast(r2.removed ? 'YouTube-стратегия выключена' : 'YouTube-стратегии и так не было — теперь она не будет добавляться', 'info');
							refreshAll();
						}).catch(function() { busy = false; });
					}
				}, yvOff && !current ? 'Выключена' : 'Выключить'));
				(res.items || []).forEach(function(it) {
					grid.appendChild(E('div', {
						'class': 'zm-tile' + (current === it.id ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							if (current === it.id) return;
							busy = true;
							zm.toast('Применяем стратегию ' + it.id + '', 'warning');
							zm.strategySetYoutube(it.id).then(function(r2) {
								busy = false;
								if (!zm.notifyStrategyResult(r2, it.id)) return;
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, it.id));
				});
				if (!res.items || !res.items.length)
					grid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список пуст — нажмите «Обновить список».'));
			}

			// Блок QUIC (UDP 443): YouTube отдаёт видео и по QUIC, а не только по TCP
			var quicOn = !!status.quic_yt, quicBlocked = false;
			var quicCard = E('div', { 'class': 'zm-card' });

			function renderQuic() {
				quicCard.innerHTML = '';
				quicCard.appendChild(E('h3', {}, 'QUIC для YouTube'));
				quicCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Браузеры и приложение YouTube часто грузят видео по QUIC (UDP 443), а не по TCP. Этот блок обходит блокировку и для QUIC. Работает вместе с выбранной стратегией.'));
				quicCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Статус'),
					zm.badge(quicOn, 'включён', 'выключен')
				]));
				if (quicBlocked) quicCard.appendChild(E('p', { 'class': 'zm-hint' }, quicOn
					? 'QUIC сейчас заблокирован на странице «Система» — блок не работает, пока блокировка включена.'
					: 'QUIC сейчас заблокирован на странице «Система» — YouTube и так идёт по TCP, блок не нужен.'));
				quicCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': quicOn ? 'cbi-button cbi-button-remove' : 'cbi-button cbi-button-positive',
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast(quicOn ? 'Выключаем QUIC для YouTube' : 'Включаем QUIC для YouTube', 'warning');
							zm.youtubeQuicSet(quicOn ? 'off' : 'on').then(function(res) {
								busy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(res.quic ? 'QUIC для YouTube включён' : 'QUIC для YouTube выключен', 'info');
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, quicOn ? 'Выключить' : 'Включить')
				]));
			}

			function refreshState() {
				zm.status().then(function(s) {
					current = currentYv(s);
					yvOff = !!s.yv_off;
					quicOn = !!s.quic_yt;
					if (lastList) renderGrid(lastList);
					renderQuic();
				});
				zm.systemStatus().then(function(ss) {
					quicBlocked = !!(ss && ss.quic_blocked);
					renderQuic();
				}).catch(function() {});
			}

			refreshers.youtube = refreshState;
			tabHooks.youtube = refreshState;
			var yvOff = !!status.yv_off;
			current = currentYv(status);
			renderQuic();

			var card = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Стратегии для YouTube'),
				E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': 'cbi-button',
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Обновляем список YouTube-стратегий', 'warning');
							grid.innerHTML = 'Загрузка списка';
							zm.strategyListYoutube('refresh').then(function(res) {
								if (res.started) {
									zm.pollJob('youtube_download', logEl, function(ok) {
										busy = false;
										zm.toast(ok ? 'Список YouTube-стратегий обновлён' : 'Не удалось обновить список', ok ? 'info' : 'error');
										zm.strategyListYoutube().then(renderGrid);
									});
								} else {
									busy = false;
									renderGrid(res);
									zm.toast('Список YouTube-стратегий обновлён', 'info');
								}
							}).catch(function() { busy = false; });
						}
					}, 'Обновить список')
				]),
				grid,
				E('p', { 'class': 'zm-hint' }, 'Меняет только YouTube-часть текущей стратегии. «Выключить» убирает её совсем — например, если YouTube идёт через ByeTube или Steer.')
			]);

			panels.youtube.appendChild(card);
			panels.youtube.appendChild(logEl);
			panels.youtube.appendChild(quicCard);
			refreshState();

			if (!initial.started) {
				renderGrid(initial);
			} else {
				busy = true;
				grid.appendChild(E('p', { 'class': 'zm-hint' }, 'Загружаем список…'));
				zm.pollJob('youtube_download', logEl, function(ok) {
					busy = false;
					if (!ok) { grid.innerHTML = ''; grid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список не загрузился — нажмите «Обновить список».')); return; }
					zm.strategyListYoutube().then(renderGrid);
				});
			}
		})();

		(function buildGamePanel() {
			var data = gameData;
			var gvGrid = E('div', { 'class': 'zm-grid' });
			var xtremeRow = E('div', {});
			var fakeGrid = E('div', { 'class': 'zm-grid' });
			var busy = false;

			function renderGv() {
				gvGrid.innerHTML = '';
				var off = !data.active;
				gvGrid.appendChild(E('div', {
					'class': 'zm-tile' + (off ? ' zm-active' : ''),
					'click': function() {
						if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						if (off) return;
						busy = true;
						zm.toast('Выключаем игровую стратегию', 'warning');
						zm.gameSet('off').then(function(res) {
							busy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast('Игровая стратегия выключена', 'info');
							refreshAll();
						}).catch(function() { busy = false; });
					}
				}, off ? 'Выключена' : 'Выключить'));
				[1, 2, 3, 4].forEach(function(n) {
					gvGrid.appendChild(E('div', {
						'class': 'zm-tile' + (data.active && data.current === ('Gv' + n) ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							if (data.active && data.current === ('Gv' + n)) return;
							busy = true;
							zm.toast('Применяем игровую стратегию Gv' + n + '', 'warning');
							zm.gameSet(String(n)).then(function(res) {
								busy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(res.game === 'none' ? 'Игровая стратегия снята' : res.game + ' применена', 'info');
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, 'Gv' + n));
				});
			}

			function renderXtreme() {
				var xtreme = data.xtreme === true;
				xtremeRow.innerHTML = '';
				xtremeRow.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Статус'),
					zm.badge(xtreme, 'включён', 'выключен')
				]));
				xtremeRow.appendChild(E('p', { 'class': 'zm-hint' }, 'Может мешать работе других приложений. Включайте только для проверки игр.'));
				xtremeRow.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': xtreme ? 'cbi-button cbi-button-remove' : 'cbi-button cbi-button-positive',
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast(xtreme ? 'Выключаем Xtreme' : 'Включаем Xtreme', 'warning');
							zm.gameToggleXtreme().then(function(res) {
								busy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(res.xtreme ? 'Xtreme включён' : 'Xtreme выключен', 'info');
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, xtreme ? 'Выключить Xtreme' : 'Включить Xtreme')
				]));
			}

			function renderFake() {
				fakeGrid.innerHTML = '';
				GAME_FAKES.forEach(function(f) {
					fakeGrid.appendChild(E('div', {
						'class': 'zm-tile' + (data.fake === f ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Меняем fake-файл на ' + f + '', 'warning');
							zm.gameSetFake(f).then(function(res) {
								busy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(f + ' установлен', 'info');
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, f));
				});
			}

			function refreshState() {
				zm.gameStatus().then(function(res) {
					data = res;
					renderGv();
					renderXtreme();
					renderFake();
				});
			}

			refreshers.game = refreshState;
			tabHooks.game = refreshState;
			renderGv();
			renderXtreme();
			renderFake();

			var gvCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Игровая стратегия'),
				gvGrid,
				E('p', { 'class': 'zm-hint' }, '«Выключить» убирает игровую часть из Zapret совсем, вместе с её портами.')
			]);

			var xtremeCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Xtreme режим'),
				xtremeRow
			]);

			var fakeCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Fake-файл для игровой стратегии'),
				fakeGrid,
				E('p', { 'class': 'zm-hint' }, 'Работает, только когда выбрана игровая стратегия.')
			]);

			panels.game.appendChild(gvCard);
			panels.game.appendChild(xtremeCard);
			panels.game.appendChild(fakeCard);
		})();

		(function buildDiscordPanel() {
			var data = discordData;
			var dvGrid = E('div', { 'class': 'zm-grid' });
			var fakeGrid = E('div', { 'class': 'zm-grid' });
			var busy = false;

			function renderDv() {
				dvGrid.innerHTML = '';
				var off = !data.active;
				dvGrid.appendChild(E('div', {
					'class': 'zm-tile' + (off ? ' zm-active' : ''),
					'click': function() {
						if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						if (off) return;
						busy = true;
						zm.toast('Выключаем стратегию Discord', 'warning');
						zm.discordSetDv('off').then(function(res) {
							busy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast(res.removed ? 'Стратегия Discord выключена' : 'Стратегии Discord и так не было — теперь она не будет добавляться', 'info');
							refreshAll();
						}).catch(function() { busy = false; });
					}
				}, off ? 'Выключена' : 'Выключить'));
				(data.available || []).forEach(function(dv) {
					dvGrid.appendChild(E('div', {
						'class': 'zm-tile' + (data.active && data.current === dv ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							if (data.active && data.current === dv) return;
							busy = true;
							zm.toast('Применяем стратегию ' + dv + '', 'warning');
							zm.discordSetDv(dv.replace('Dv', '')).then(function(res) {
								busy = false;
								if (!zm.notifyStrategyResult(res, dv)) return;
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, dv));
				});
			}

			function renderFake() {
				fakeGrid.innerHTML = '';
				GAME_FAKES.forEach(function(f) {
					fakeGrid.appendChild(E('div', {
						'class': 'zm-tile' + (data.active && data.current_fake === f ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Меняем fake-файл на ' + f + '', 'warning');
							zm.discordSetFake(f).then(function(res) {
								busy = false;
								if (!zm.notifyStrategyResult(res, f)) return;
								refreshAll();
							}).catch(function() { busy = false; });
						}
					}, f));
				});
			}

			function refreshState() {
				zm.discordStatus().then(function(res) {
					data = res;
					renderDv();
					renderFake();
				});
			}

			refreshers.discord = refreshState;
			tabHooks.discord = refreshState;
			renderDv();
			renderFake();

			var dvCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Стратегия для Discord'),
				dvGrid,
				E('p', { 'class': 'zm-hint' }, 'Стратегия Discord — это два блока: голос (discord,stun) и discord.media. «Выключить» убирает оба, и при смене основной стратегии они не вернутся. Любая Dv включает их снова.')
			]);

			var fakeCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Fake-файл для discord,stun'),
				fakeGrid,
				E('p', { 'class': 'zm-hint' }, 'Работает, только когда включена стратегия Discord.')
			]);

			panels.discord.appendChild(dvCard);
			panels.discord.appendChild(fakeCard);
		})();

		(function buildDomainsExcludePanel() {
			var editorCard = E('div', { 'class': 'zm-card' });
			var contentEl = E('textarea', { 'class': 'zm-config-editor', 'spellcheck': 'false' });
			var editorBusy = false;

			function refreshFile() {
				zm.exclusionsFileGet().then(function(res) {
					if (res.error) { zm.toast(res.error, 'error'); return; }
					contentEl.value = res.content || '';
				});
			}

			editorCard.appendChild(E('h3', {}, 'Домены исключения'));
			editorCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сайты из этого списка Zapret не трогает — по одному домену в строке. Сохранение перезапускает Zapret.'));
			editorCard.appendChild(contentEl);
			editorCard.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() {
						if (editorBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						editorBusy = true;
						zm.toast('Сохраняем и перезапускаем Zapret', 'warning');
						zm.exclusionsFileSet(contentEl.value).then(function(res) {
							editorBusy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast('Список исключений сохранён, Zapret перезапущен', 'info');
						}).catch(function() { editorBusy = false; });
					}
				}, 'Сохранить и применить'),
				E('button', {
					'class': 'cbi-button',
					'click': function() {
						if (editorBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						editorBusy = true;
						zm.toast('Восстанавливаем список исключений', 'warning');
						zm.exclusionsFileRestore().then(function(res) {
							editorBusy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
							contentEl.value = res.content || '';
							zm.toast('Список исключений восстановлен', 'info');
						}).catch(function() { editorBusy = false; });
					}
				}, 'Восстановить исключения')
			]));

			refreshFile();
			panels.domains_exclude.appendChild(editorCard);
		})();

		(function buildExclusionsPanel() {
			var data = exclusionsData;

			if (data.error) {
				panels.exclusions.appendChild(E('div', { 'class': 'zm-card' }, [
					E('h3', {}, 'Исключение устройств'),
					E('p', { 'class': 'zm-hint' }, data.error)
				]));
				return;
			}

			var grid = E('div', { 'class': 'zm-grid-devices' });
			var busy = false;

			function renderGrid(devices) {
				grid.innerHTML = '';
				(devices || []).forEach(function(d) {
					grid.appendChild(E('div', {
						'class': 'zm-tile' + (d.excluded ? ' zm-tile-off' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Переключаем исключение для ' + d.ip + '', 'warning');
							zm.exclusionsToggle(d.ip).then(function(res) {
								busy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(d.ip + (res.excluded ? ' исключён' : ' больше не исключён'), 'info');
								zm.exclusionsStatus().then(function(r) { renderGrid(r.devices); });
							}).catch(function() { busy = false; });
						}
					}, [ E('div', {}, d.ip), E('div', { 'class': 'zm-hint' }, d.name) ]));
				});
				if (!devices || !devices.length)
					grid.appendChild(E('p', { 'class': 'zm-hint' }, 'Устройства не найдены — нажмите «Обновить список».'));
			}

			renderGrid(data.devices);

			var manualInput = E('input', { 'type': 'text', 'placeholder': '192.168.1.100', 'class': 'cbi-input-text' });

			var card = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Исключение устройств из Zapret'),
				grid,
				E('p', { 'class': 'zm-hint' }, 'Нажмите на устройство, чтобы исключить его из Zapret или вернуть обратно. Красным отмечены исключённые.'),
				E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': 'cbi-button',
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Обновляем список устройств', 'warning');
							zm.exclusionsStatus().then(function(res) {
								busy = false;
								renderGrid(res.devices);
								zm.toast('Список устройств обновлён', 'info');
							}).catch(function() { busy = false; });
						}
					}, 'Обновить список'),
					manualInput,
					E('button', {
						'class': 'cbi-button',
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							var ip = manualInput.value.trim();
							if (!/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(ip)) {
								zm.toast('Некорректный IPv4 адрес', 'error');
								return;
							}
							busy = true;
							zm.toast('Добавляем ' + ip + ' в исключения', 'warning');
							zm.exclusionsToggle(ip).then(function(res) {
								busy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								manualInput.value = '';
								zm.toast(ip + (res.excluded ? ' добавлен в исключения' : ' убран из исключений'), 'info');
								zm.exclusionsStatus().then(function(r) { renderGrid(r.devices); });
							}).catch(function() { busy = false; });
						}
					}, 'Добавить вручную'),
					E('button', {
						'class': 'cbi-button cbi-button-remove',
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Очищаем все исключения', 'warning');
							zm.exclusionsClear().then(function() {
								busy = false;
								zm.toast('Все исключения очищены', 'info');
								zm.exclusionsStatus().then(function(res) { renderGrid(res.devices); });
							}).catch(function() { busy = false; });
						}
					}, 'Очистить все')
				])
			]);

			panels.exclusions.appendChild(card);
		})();

		if (zapretInstalled) {
			renderTabBar();
			mainSection.appendChild(tabBar);
			TABS.forEach(function(t) { mainSection.appendChild(panels[t.id]); });
		}
		wrap.appendChild(mainSection);
		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/strategy.js'

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/zapret2.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.status();
	},

	render: function(data) {
		var view = this;
		var wrap = E('div', { 'class': 'zm-wrap' });
		var cards = E('div', { 'class': 'zm-cards' });
		var logEl = E('pre', { 'class': 'zm-log' });
		var bannerEl = E('div', {});

		function renderCards(d) {
			cards.innerHTML = '';

			var z2Actions = [];
			if (d.zapret2 === 'installed') {
				z2Actions.push(E('button', {
					'class': 'cbi-button cbi-button-remove',
					'click': function() { view.doAction2('remove'); }
				}, 'Удалить'));
				z2Actions.push(E('button', {
					'class': 'cbi-button',
					'click': function() { view.doAction2(d.zapret2_running ? 'stop' : 'start'); }
				}, d.zapret2_running ? 'Остановить' : 'Запустить'));
			} else {
				z2Actions.push(E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() { view.doAction2('install'); }
				}, 'Установить'));
			}

			var z2Card = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Zapret2'),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Статус'),
					d.zapret2 === 'installed'
						? zm.badge(d.zapret2_running === true, 'запущен', 'остановлен')
						: zm.badge(false, '', 'не установлен')
				]),
				E('p', { 'class': 'zm-hint' }, 'Только для архитектуры aarch64_cortex-a53. Несовместим с основным Zapret.'),
				E('div', { 'class': 'zm-actions' }, z2Actions)
			]);

			cards.appendChild(z2Card);
		}

		renderCards(data);
		wrap.appendChild(cards);
		wrap.appendChild(logEl);
		wrap.appendChild(bannerEl);

		this.logEl = logEl;
		this.bannerEl = bannerEl;
		this.renderCards = renderCards;

		return wrap;
	},

	doAction2: function(action) {
		var view = this;
		if (view.busy2) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
		var job = (action === 'install' || action === 'update') ? 'install_zapret2'
			: (action === 'remove') ? 'remove_zapret2' : null;
		var LABELS = { install: 'Устанавливаем Zapret2', update: 'Обновляем Zapret2', remove: 'Удаляем Zapret2', start: 'Запускаем Zapret2', stop: 'Останавливаем Zapret2' };
		zm.toast(LABELS[action] || 'Выполняем', 'warning');
		if (job) view.busy2 = true;

		zm.zapret2Action(action).then(function(res) {
			if (job && res && res.started) {
				zm.pollJob(job, view.logEl, function(ok) {
					view.busy2 = false;
					zm.toast(ok ? 'Готово' : 'Операция завершилась с ошибкой', ok ? 'info' : 'error');
					zm.status().then(function(d) { view.renderCards(d); });
					if (ok && (action === 'install' || action === 'remove')) {
						view.bannerEl.innerHTML = '';
						view.bannerEl.appendChild(zm.refreshBanner('Пункт меню Zapret2 в LuCI мог измениться — выйдите и зайдите заново.'));
					}
				});
			} else if (res) {
				view.busy2 = false;
				view.renderCards(res);
			}
		}).catch(function() { view.busy2 = false; });
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/zapret2.js'

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/style.css' << 'ZM_INSTALLER_EOF'
.zm-wrap { display: flex; flex-direction: column; gap: 16px; max-width: 1100px; }

.zm-header { display: flex; align-items: baseline; gap: 10px; margin-bottom: -4px; flex-wrap: wrap; }
.zm-header h2 { margin: 0; font-size: 22px; font-weight: 700; }
.zm-header-by { font-size: 13px; opacity: .55; }
.zm-header-links { display: flex; gap: 8px; margin-left: auto; flex-wrap: wrap; }
.zm-header-links a {
	font-size: 12.5px; font-weight: 600; text-decoration: none;
	color: #229ed9; background: rgba(34,158,217,.1); border: 1px solid rgba(34,158,217,.25);
	border-radius: 999px; padding: 5px 13px; transition: background .15s;
}
.zm-header-links a:hover { background: rgba(34,158,217,.18); }

.zm-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; }

.zm-card {
	min-width: 0;
	box-sizing: border-box;
	background: var(--background-color-medium, #fff);
	border: 1px solid rgba(0,0,0,.08);
	border-radius: 12px;
	padding: 18px 20px;
	box-shadow: 0 1px 3px rgba(0,0,0,.05), 0 1px 2px rgba(0,0,0,.04);
	overflow-wrap: break-word;
	transition: box-shadow .15s;
}

html.zm-theme-dark .zm-card {
	background: #1c2128;
	border-color: rgba(255,255,255,.10);
	box-shadow: 0 1px 3px rgba(0,0,0,.25), 0 1px 2px rgba(0,0,0,.2);
}
.zm-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,.08); }

.zm-card h3 { margin: 0 0 12px 0; font-size: 15px; font-weight: 600; display: flex; align-items: center; gap: 8px; }

.zm-row { display: flex; align-items: center; gap: 12px; margin: 7px 0; font-size: 13px; flex-wrap: wrap; }
.zm-row .zm-label { opacity: .65; flex-shrink: 0; }
.zm-row > span:last-child { overflow-wrap: anywhere; }

.zm-badge { display: inline-flex; align-items: center; gap: 6px; padding: 3px 11px; border-radius: 999px; font-size: 12px; font-weight: 600; white-space: nowrap; }
.zm-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; flex-shrink: 0; }

.zm-ok    { background: rgba(46,160,67,.12); color: #1a7f37; }
.zm-ok .zm-dot { background: #1a7f37; }
.zm-bad   { background: rgba(207,34,46,.10); color: #cf222e; }
.zm-bad .zm-dot { background: #cf222e; }
.zm-warn  { background: rgba(191,135,0,.12); color: #9a6700; }
.zm-warn .zm-dot { background: #9a6700; }
.zm-off   { background: rgba(110,118,129,.12); color: #57606a; }
.zm-off .zm-dot { background: #57606a; }

.zm-actions { display: flex; gap: 12px; flex-wrap: wrap; align-items: center; margin: 14px 0; }

/* Скрытые IP и адреса серверов: размыты, по нажатию видны */
.zm-secret { filter: blur(5px); cursor: pointer; user-select: none; -webkit-user-select: none; border-radius: 4px; transition: filter .2s; }
.zm-secret:hover { filter: blur(4px); }
.zm-secret.zm-secret-open { filter: none; user-select: text; -webkit-user-select: text; }

/* Шкалы в «Системе» (как в боковой панели Web UI) */
.zm-meters { display: flex; flex-direction: column; gap: 13px; padding-top: 7px; }
body:not(.zmw-body) .zm-meter-head { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; font-size: 13px; margin-bottom: 6px; }
body:not(.zmw-body) .zm-meter-label { opacity: .65; }
body:not(.zmw-body) .zm-meter-val { font-weight: 600; font-variant-numeric: tabular-nums; white-space: nowrap; }
body:not(.zmw-body) .zm-meter-bar { height: 6px; border-radius: 6px; background: rgba(110,118,129,.18); overflow: hidden; }
body:not(.zmw-body) .zm-meter-bar i { display: block; height: 100%; border-radius: 6px; background: linear-gradient(90deg, #0969da, #3b8eea); transition: width .6s cubic-bezier(.2,.8,.2,1); }
body:not(.zmw-body) .zm-meter-mid .zm-meter-bar i { background: linear-gradient(90deg, #f59e0b, #fbbf24); }
body:not(.zmw-body) .zm-meter-hi .zm-meter-bar i { background: linear-gradient(90deg, #ef4444, #f87171); }
html.zm-theme-dark body:not(.zmw-body) .zm-meter-bar { background: rgba(255,255,255,.1); }
.zm-actions .cbi-button { margin: 0; }

.zm-grid { display: flex; flex-wrap: wrap; gap: 9px; }
.zm-grid-devices { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 9px; }
.zm-grid-devices .zm-tile { flex: none; min-width: 0; width: 100%; box-sizing: border-box; }

.zm-credits-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
@media (max-width: 720px) { .zm-credits-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 460px) { .zm-credits-grid { grid-template-columns: 1fr; } }
.zm-credit-tile {
	min-width: 0;
	box-sizing: border-box;
	border: 1px solid rgba(0,0,0,.1);
	border-radius: 10px;
	padding: 12px 14px;
	text-align: center;
	background: rgba(0,0,0,.02);
}
html.zm-theme-dark .zm-credit-tile { border-color: rgba(255,255,255,.12); background: rgba(255,255,255,.03); }
.zm-credit-tile.zm-credit-self { border-color: rgba(26,127,55,.35); background: rgba(26,127,55,.06); }
.zm-credit-product { font-weight: 700; font-size: 13.5px; margin-bottom: 2px; overflow-wrap: anywhere; }
.zm-credit-author { font-size: 12px; opacity: .75; margin-bottom: 6px; }
.zm-credit-tile a { font-size: 12px; word-break: break-all; overflow-wrap: anywhere; }
.zm-credit-tile.zm-credit-all { grid-column: 1 / -1; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; }
.zm-credit-tile.zm-credit-all .zm-credit-author { margin-bottom: 0; }

.zm-tile {
	flex: 0 1 auto;
	min-width: 90px;
	max-width: 100%;
	border: 1px solid rgba(0,0,0,.1);
	border-radius: 9px;
	padding: 10px 16px;
	cursor: pointer;
	text-align: center;
	font-size: 13px;
	line-height: 1.35;
	overflow-wrap: break-word;
	transition: border-color .15s, background .15s, transform .1s;
	background: var(--background-color-low, #fafafa);
}
html.zm-theme-dark .zm-tile:not(.zm-active):not(.zm-tile-off) {
	background: #22272e;
	border-color: rgba(255,255,255,.12);
}
.zm-tile:hover { border-color: #1a7f37; transform: translateY(-1px); }
.zm-tile.zm-active {
	border-color: #1a7f37; background: rgba(26,127,55,.16);
	font-weight: 700; color: #15803d;
	box-shadow: 0 0 0 2px rgba(26,127,55,.35);
}
.zm-tile.zm-active::before { content: "✓ "; }

.zm-tile.zm-tile-off {
	border-color: rgba(207,34,46,.35); background: rgba(207,34,46,.08);
	color: #cf222e; font-weight: 600;
}
.zm-tile.zm-tile-off::before { content: "✗ "; }
.zm-tile.zm-tile-off:hover { border-color: #cf222e; }
.zm-tile.zm-tile-pending { opacity: .55; border-style: dashed; cursor: not-allowed; }
.zm-tile.zm-tile-pending:hover { border-color: rgba(0,0,0,.1); transform: none; }

.zm-log {
	background: #0d1117; color: #e6edf3;
	font-family: ui-monospace, "SF Mono", "Cascadia Code", Consolas, "Liberation Mono", monospace;
	font-size: 13.5px; line-height: 1.7;
	border: 1px solid rgba(255,255,255,.10);
	border-radius: 10px; padding: 16px 18px;
	white-space: pre-wrap; word-break: break-word; overflow-wrap: anywhere;
	max-height: 520px; min-height: 220px;
	overflow-x: hidden; overflow-y: auto;
	margin-top: 14px; display: none;
	box-shadow: inset 0 0 0 1px rgba(0,0,0,.2);
}
.zm-log.zm-show { display: block; }
.zm-log { scrollbar-width: auto; scrollbar-color: auto; }
.zm-log::-webkit-scrollbar { width: 14px; }
.zm-log::-webkit-scrollbar-track { background: transparent; margin: 8px 0; }
.zm-log::-webkit-scrollbar-thumb { background: rgba(255,255,255,.2); border-radius: 10px; border: 4px solid transparent; background-clip: padding-box; min-height: 40px; }
.zm-log::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,.34); background-clip: padding-box; }
@supports not selector(::-webkit-scrollbar) { .zm-log { scrollbar-width: thin; scrollbar-color: rgba(255,255,255,.25) transparent; } }
.zm-config-editor { scrollbar-width: auto; scrollbar-color: auto; }
.zm-config-editor::-webkit-scrollbar { width: 14px; height: 14px; }
.zm-config-editor::-webkit-scrollbar-button { display: none; }
.zm-config-editor::-webkit-scrollbar-track, .zm-config-editor::-webkit-scrollbar-corner, .zm-config-editor::-webkit-resizer { background: transparent; }
.zm-config-editor::-webkit-scrollbar-track { margin: 8px; }
.zm-config-editor::-webkit-scrollbar-thumb { background: rgba(255,255,255,.2); border-radius: 10px; border: 4px solid transparent; background-clip: padding-box; min-height: 40px; }
.zm-config-editor::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,.34); background-clip: padding-box; }
@supports not selector(::-webkit-scrollbar) { .zm-config-editor { scrollbar-width: thin; scrollbar-color: rgba(255,255,255,.25) transparent; } }
.zm-log:empty::before { content: "Ожидание вывода..."; opacity: .4; }
.zm-log-bar { position: sticky; top: 16px; height: 0; z-index: 3; }
.zm-log-min {
	position: absolute; right: -8px; top: -8px; width: 30px; height: 24px; padding: 0; margin: 0;
	border: 1px solid rgba(255,255,255,.14); border-radius: 7px; background: rgba(255,255,255,.06);
	color: #c9d1d9; font: 700 13px/1 ui-monospace, Consolas, monospace; cursor: pointer;
	display: flex; align-items: center; justify-content: center; transition: background .15s, color .15s;
}
.zm-log-min:hover { background: rgba(255,255,255,.16); color: #fff; }
.zm-log.zm-log-collapsed { min-height: 0; max-height: none; overflow: hidden; padding-right: 48px; }
.zm-log.zm-log-collapsed > div:not(.zm-log-bar):not(:last-child) { display: none; }
.zm-log.zm-log-collapsed > div:last-child { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

.zm-config-editor {
	width: 100%; box-sizing: border-box; min-height: 420px;
	background: #0d1117; color: #e6edf3;
	font-family: ui-monospace, "SF Mono", "Cascadia Code", Consolas, "Liberation Mono", monospace;
	font-size: 13px; line-height: 1.6;
	border: 1px solid rgba(255,255,255,.1); border-radius: 10px;
	padding: 14px 16px; margin: 10px 0;
	white-space: pre; overflow: auto; resize: vertical;
}
html.zm-theme-dark .zm-config-editor { border-color: rgba(255,255,255,.14); }
@media (max-width: 600px) {
	/* 16px — чтобы iOS Safari не увеличивал масштаб страницы при тапе в поле */
	.zm-config-editor { font-size: 16px; min-height: 320px; }
}

.zm-log-arrow { color: #56d4dd; font-weight: 700; }
.zm-log-msg-info { color: #e3c04a; }
.zm-log-msg-ok { color: #3fb950; font-weight: 600; }
.zm-log-msg-error { color: #ff7b72; font-weight: 600; }
.zm-log-msg-warn { color: #ffa657; }
.zm-log-code { color: #8b949e; }

.zm-hint { font-size: 12px; opacity: .65; margin-top: 6px; line-height: 1.5; overflow-wrap: break-word; }

.zm-refresh-banner {
	display: flex; align-items: center; justify-content: space-between; gap: 14px;
	background: rgba(191,135,0,.12); border: 2px solid rgba(191,135,0,.35);
	color: #9a6700; border-radius: 12px; padding: 16px 20px; font-size: 15px; font-weight: 500;
	margin-top: 12px;
}
.zm-refresh-banner button { flex-shrink: 0; }

#zm-toast-container {
	position: fixed; top: 20px; right: 20px; z-index: 10000;
	display: flex; flex-direction: column; gap: 14px;
	max-width: 520px;
}
.zm-toast {
	display: flex; align-items: flex-start; gap: 14px;
	background: #1c2128; color: #e6edf3;
	padding: 24px 28px; border-radius: 16px;
	box-shadow: 0 10px 40px rgba(0,0,0,.4);
	font-size: 18px; line-height: 1.5; font-weight: 500; cursor: pointer;
	opacity: 0; transform: translateX(24px);
	transition: opacity .22s ease, transform .22s ease;
	border-left: 6px solid #1a7f37;
}
.zm-toast-show { opacity: 1; transform: translateX(0); }
.zm-toast-error { border-left-color: #cf222e; }
.zm-toast-warning { border-left-color: #9a6700; }
.zm-toast-icon { flex-shrink: 0; font-weight: 700; font-size: 24px; line-height: 1.3; }
.zm-toast-info .zm-toast-icon { color: #3fb950; }
.zm-toast-error .zm-toast-icon { color: #ff7b72; }
.zm-toast-warning .zm-toast-icon { color: #e3b341; }
.zm-toast-text { overflow-wrap: anywhere; }
html.zm-theme-dark .zm-toast {
	background: #ffffff; color: #1f2328;
	box-shadow: 0 12px 44px rgba(0,0,0,.6), 0 0 0 1px rgba(255,255,255,.1);
}
html.zm-theme-dark .zm-toast-info .zm-toast-icon { color: #1a7f37; }
html.zm-theme-dark .zm-toast-error .zm-toast-icon { color: #cf222e; }
html.zm-theme-dark .zm-toast-warning .zm-toast-icon { color: #9a6700; }

.zm-tg-link-card {
	background: rgba(26,127,55,.06);
	border: 1px solid rgba(26,127,55,.25);
	border-radius: 12px;
	padding: 16px 18px;
	margin-bottom: 12px;
}
.zm-tg-link-card h4 { margin: 0 0 8px 0; font-size: 14px; font-weight: 700; }
.zm-tg-link-hint { font-size: 12.5px; opacity: .7; margin-bottom: 10px; }
.zm-tg-link-box {
	background: #0d1117; color: #7ee787;
	font-family: ui-monospace, "SF Mono", "Cascadia Code", Consolas, monospace;
	font-size: 14.5px; line-height: 1.6;
	border-radius: 8px; padding: 12px 14px;
	white-space: pre-wrap; word-break: break-all; overflow-wrap: anywhere;
	margin-bottom: 8px;
}
.zm-tg-link-row { display: flex; align-items: flex-start; gap: 10px; flex-wrap: wrap; }
.zm-tg-link-row .zm-tg-link-box { flex: 1 1 220px; min-width: 0; }
.zm-tg-qr-btn { white-space: nowrap; }
.zm-tg-qr-box { margin-top: 10px; text-align: center; }
.zm-tg-qr-box img { max-width: 100%; height: auto; border-radius: 8px; background: #fff; padding: 8px; box-shadow: 0 0 0 1px rgba(0,0,0,.08); box-sizing: border-box; }

.zm-current-banner {
	display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
	background: rgba(26,127,55,.07); border: 1px solid rgba(26,127,55,.22);
	border-radius: 10px; padding: 10px 16px; font-size: 13px; margin-bottom: 4px;
}
.zm-current-banner b { font-weight: 700; }
.zm-current-banner.zm-current-empty {
	background: rgba(110,118,129,.08); border-color: rgba(110,118,129,.2);
}
.zm-current-banner.zm-current-top { margin: 0 0 10px; }

.bt-cols { display: grid; grid-template-columns: 1fr 1fr; column-gap: 44px; }
.bt-col { min-width: 0; }
.bt-col .zm-label { flex: 0 0 170px; }
@media (max-width: 860px) {
	.bt-cols { grid-template-columns: 1fr; }
	.bt-col .zm-label { flex: 0 0 128px; }
}
@media (max-width: 420px) {
	.bt-col .zm-label { flex: 0 0 108px; font-size: 12px; }
}

.cbi-page-actions { display: none !important; }
.zm-ab-panel { display: flex; flex-direction: column; gap: 16px; }
.zm-ab-head { display: flex; align-items: flex-start; gap: 14px; flex-wrap: wrap; }
.zm-ab-head > .zm-badge { margin-left: auto; }
.zm-ab-title { flex: 1 1 260px; min-width: 0; }
.zm-ab-title h3 { margin: 2px 0 2px 0; font-size: 17px; }
.zm-ab-title .zm-hint { margin-top: 0; }
.zm-ab-icon {
	width: 44px; height: 44px; border-radius: 13px; flex-shrink: 0;
	display: grid; place-items: center; color: #fff;
	background: linear-gradient(135deg, #5fd8ff 0%, #1aa3ff 50%, #0a7cff 100%);
	box-shadow: 0 8px 18px -8px rgba(10,124,255,.8);
}
.zm-ab-hero .zm-grid { margin-top: 16px; }
.zm-ab-go { display: inline-flex; align-items: center; gap: 8px; font-weight: 700; }
.zm-ab-go svg { width: 17px; height: 17px; }
.zm-ab-foot { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; font-size: 12.5px; opacity: .8; border-top: 1px dashed rgba(0,0,0,.12); padding-top: 12px; margin-top: 4px; }
html.zm-theme-dark .zm-ab-foot { border-top-color: rgba(255,255,255,.12); }
.zm-ab-sum b { font-size: 15px; }
.zm-ab-sum-ok b { color: #1a7f37; }
.zm-ab-note { margin-top: 14px; border-radius: 10px; padding: 11px 14px; font-size: 13px; font-weight: 600; }
.zm-ab-note-warn { background: rgba(191,135,0,.12); color: #9a6700; border: 1px solid rgba(191,135,0,.3); }

.zm-ab-steps { display: flex; gap: 6px; margin: 18px 0 4px; counter-reset: s; overflow-x: auto; padding-bottom: 2px; }
.zm-ab-step { flex: 1 1 0; min-width: 78px; display: flex; flex-direction: column; align-items: center; gap: 6px; position: relative; font-size: 12px; opacity: .55; }
.zm-ab-step::before { content: ""; position: absolute; top: 14px; left: calc(-50% + 18px); right: calc(50% + 18px); height: 2px; background: rgba(110,118,129,.3); border-radius: 2px; }
.zm-ab-step:first-child::before { display: none; }
.zm-ab-step-dot { width: 28px; height: 28px; border-radius: 50%; display: grid; place-items: center; font-weight: 700; font-size: 12.5px; background: rgba(110,118,129,.14); color: inherit; }
.zm-ab-step-label { white-space: nowrap; font-weight: 600; }
.zm-ab-step.zm-ab-done { opacity: 1; }
.zm-ab-step.zm-ab-done .zm-ab-step-dot { background: #1a7f37; color: #fff; }
.zm-ab-step.zm-ab-done::before, .zm-ab-step.zm-ab-now::before { background: #1a7f37; }
.zm-ab-step.zm-ab-now { opacity: 1; }
.zm-ab-step.zm-ab-now .zm-ab-step-dot { background: #1aa3ff; color: #fff; animation: zm-ab-pulse 1.6s ease-in-out infinite; }
@keyframes zm-ab-pulse { 0%, 100% { box-shadow: 0 0 0 0 rgba(26,163,255,.55); } 50% { box-shadow: 0 0 0 7px rgba(26,163,255,0); } }

.zm-ab-svc { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 9px; margin-top: 10px; }
.zm-ab-svc-item .zm-badge { flex-shrink: 0; }
.zm-ab-svc-item {
	display: flex; align-items: center; justify-content: space-between; gap: 10px; min-width: 0;
	border: 1px solid rgba(0,0,0,.08); border-radius: 10px; padding: 10px 12px;
	background: var(--background-color-low, #fafafa);
}
html.zm-theme-dark .zm-ab-svc-item { background: #22272e; border-color: rgba(255,255,255,.1); }
.zm-ab-svc-item.zm-ab-svc-bad { border-color: rgba(207,34,46,.3); }
.zm-ab-svc-name { font-weight: 600; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

/* AmneziaWG: блок интерфейса */
.zm-awg-if { border: 1px solid rgba(0,0,0,.1); border-radius: 12px; padding: 14px 16px; margin-top: 12px; background: var(--background-color-low, #fafafa); }
html.zm-theme-dark .zm-awg-if { background: #22272e; border-color: rgba(255,255,255,.1); }
.zm-awg-if .zm-actions { margin-top: 10px; }

/* steer */
.zm-st-stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; margin-top: 16px; }
.zm-st-stat { display: flex; flex-direction: column; gap: 4px; min-width: 0; padding: 11px 14px; border-radius: 11px; border: 1px solid rgba(0,0,0,.08); background: var(--background-color-low, #fafafa); }
html.zm-theme-dark .zm-st-stat { background: #22272e; border-color: rgba(255,255,255,.1); }
.zm-st-stat-label { font-size: 11.5px; opacity: .65; text-transform: uppercase; letter-spacing: .04em; }
.zm-st-stat-value { font-size: 14px; font-weight: 700; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.zm-st-ok { color: #1a7f37; } .zm-st-warn { color: #9a6700; } .zm-st-bad { color: #cf222e; } .zm-st-off { opacity: .6; }
.zm-st-promo { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; margin-top: 16px; }
.zm-st-promo > div { display: flex; flex-direction: column; gap: 3px; padding: 12px 14px; border-radius: 11px; background: rgba(26,163,255,.07); border: 1px solid rgba(26,163,255,.2); }
.zm-st-promo b { font-size: 14px; } .zm-st-promo span { font-size: 12px; opacity: .7; }
.zm-svc-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 10px; margin-top: 12px; }
.zm-svc { display: flex; align-items: center; gap: 11px; min-width: 0; padding: 10px 12px; border-radius: 12px; cursor: pointer; user-select: none;
	border: 1px solid rgba(0,0,0,.1); background: var(--background-color-low, #fafafa); transition: border-color .15s, background .15s, transform .1s; }
html.zm-theme-dark .zm-svc { background: #22272e; border-color: rgba(255,255,255,.1); }
.zm-svc:hover { transform: translateY(-1px); border-color: #1aa3ff; }
.zm-svc.zm-svc-on { border-color: rgba(26,163,255,.6); background: rgba(26,163,255,.08); }
.zm-svc-ico { width: 34px; height: 34px; border-radius: 10px; flex-shrink: 0; display: grid; place-items: center; color: #fff; font-weight: 800; font-size: 12.5px; letter-spacing: -.02em; }
.zm-svc-text { display: flex; flex-direction: column; min-width: 0; flex: 1; }
.zm-svc-name { font-weight: 700; font-size: 13.5px; }
.zm-svc-sub { font-size: 11.5px; opacity: .6; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.zm-switch { width: 38px; height: 22px; border-radius: 999px; background: rgba(110,118,129,.35); position: relative; flex-shrink: 0; transition: background .15s; }
.zm-switch > span { position: absolute; top: 3px; left: 3px; width: 16px; height: 16px; border-radius: 50%; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,.3); transition: left .15s; }
.zm-switch.zm-switch-on { background: #1aa3ff; } .zm-switch.zm-switch-on > span { left: 19px; }
.zm-st-apply .zm-hint { margin: 0; }
.zm-st-note-ok { background: rgba(26,127,55,.1); color: #1a7f37; border: 1px solid rgba(26,127,55,.25); }
.zm-st-note-bad { background: rgba(207,34,46,.08); color: #cf222e; border: 1px solid rgba(207,34,46,.25); }
.zm-st-checks { display: flex; flex-direction: column; gap: 7px; margin-top: 12px; }
.zm-st-check { display: flex; gap: 10px; align-items: flex-start; font-size: 13px; }
.zm-st-check > span:last-child { display: flex; flex-direction: column; min-width: 0; }
.zm-st-check-dot { width: 20px; height: 20px; border-radius: 50%; flex-shrink: 0; display: grid; place-items: center; font-size: 11px; font-weight: 800; color: #fff; }
.zm-st-check-ok .zm-st-check-dot { background: #1a7f37; } .zm-st-check-warn .zm-st-check-dot { background: #bf8700; } .zm-st-check-fail .zm-st-check-dot { background: #cf222e; }
.zm-st-check-why { font-size: 12px; opacity: .65; }
@media (max-width: 600px) {
	.zm-st-stats, .zm-st-promo { grid-template-columns: 1fr; }
	.zm-svc-grid { grid-template-columns: 1fr; }
}
.zm-ab-player video { display: block; width: 100%; max-height: 72vh; aspect-ratio: 16 / 9; object-fit: contain; border-radius: 12px; background: #000; }
.zm-ab-player .zm-actions { margin-bottom: 0; }
.zm-ab-logcard .zm-log { margin-top: 0; }
@media (max-width: 600px) {
	.zm-ab-title { flex-basis: calc(100% - 58px); }
	.zm-ab-head > .zm-badge { margin-left: 58px; }
	.zm-ab-step { min-width: 40px; }
	.zm-ab-step:not(.zm-ab-now) .zm-ab-step-label { visibility: hidden; }
	.zm-ab-step-label { font-size: 11.5px; }
	.zm-ab-svc { grid-template-columns: 1fr; }
}
.zm-st-tunnels { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 12px; margin: 10px 0 14px; }
.zm-st-tunnel { border: 1px solid rgba(127,127,127,.25); border-radius: 12px; padding: 10px 14px; }
.zm-st-tunnel-head { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-bottom: 6px; }
.zm-st-tunnel-name { font-weight: 600; }
.zm-nodes { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 10px; margin-top: 6px; }
.zm-node {
	position: relative; display: flex; flex-direction: column; justify-content: space-between; gap: 10px;
	min-height: 64px; padding: 10px 12px; border-radius: 10px; cursor: pointer; box-sizing: border-box;
	border: 1px solid rgba(0,0,0,.1); background: var(--background-color-low, #fafafa);
	transition: border-color .15s, background .15s, transform .1s, box-shadow .15s;
}
html.zm-theme-dark .zm-node:not(.zm-active) { background: #22272e; border-color: rgba(255,255,255,.12); }
.zm-node:hover { border-color: #1a7f37; transform: translateY(-1px); }
.zm-node.zm-active { border-color: #1a7f37; background: rgba(26,127,55,.12); box-shadow: 0 0 0 2px rgba(26,127,55,.3); }
.zm-node.zm-node-dead { opacity: .6; }
.zm-node-name { font-weight: 600; font-size: 13px; line-height: 1.35; overflow-wrap: anywhere; }
.zm-node.zm-active .zm-node-name::before { content: "✓ "; color: #1a7f37; }
.zm-node-foot { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 11.5px; }
.zm-node-foot > span:first-child { opacity: .65; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.zm-lat { font-weight: 700; white-space: nowrap; font-variant-numeric: tabular-nums; }
.zm-lat-good { color: #1a7f37; } .zm-lat-mid { color: #9a6700; } .zm-lat-bad { color: #cf222e; } .zm-lat-none { opacity: .45; }
.zm-sub-meta {
	display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 12px 24px;
	padding: 12px 16px; margin: 4px 0 10px; border-radius: 10px;
	background: rgba(26,127,55,.06); border: 1px solid rgba(26,127,55,.18);
}
.zm-sub-title { font-weight: 700; font-size: 15px; overflow-wrap: anywhere; }
.zm-sub-facts { display: flex; flex-wrap: wrap; gap: 12px 24px; }
.zm-sub-fact { display: flex; flex-direction: column; gap: 3px; font-size: 12px; }
.zm-sub-fact > span { opacity: .6; }
.zm-sub-fact > b { font-size: 13px; font-variant-numeric: tabular-nums; }
.zm-quota { width: 140px; height: 5px; border-radius: 99px; background: rgba(0,0,0,.1); overflow: hidden; }
.zm-quota > i { display: block; height: 100%; border-radius: 99px; background: #1a7f37; }
.zm-quota.zm-quota-high > i { background: #cf222e; }
.zm-seg { display: inline-flex; padding: 3px; gap: 3px; border-radius: 9px; border: 1px solid rgba(0,0,0,.1); background: var(--background-color-low, #fafafa); }
html.zm-theme-dark .zm-seg { background: #22272e; border-color: rgba(255,255,255,.12); }
.zm-seg-item { padding: 5px 14px; border-radius: 7px; cursor: pointer; font-size: 13px; font-weight: 600; opacity: .7; transition: background .15s, opacity .15s; }
.zm-seg-item:hover { opacity: 1; }
.zm-seg-item.zm-active { opacity: 1; background: #1a7f37; color: #fff; cursor: default; }
.zm-sub-input { min-height: 72px !important; }
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/style.css'

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/system.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var MIRRORS = [
	{ id: 'infra', label: 'Infra OpenWrt' },
	{ id: 'brazil', label: 'Brazil' },
	{ id: 'china', label: 'China' },
	{ id: 'france', label: 'France' },
	{ id: 'italy', label: 'Italy' },
	{ id: 'morocco', label: 'Morocco' },
	{ id: 'usa', label: 'USA' },
	{ id: 'germany_rwth', label: 'Germany' },
	{ id: 'default', label: 'default / OpenWrt' }
];

return view.extend({
	load: function() {
		zm.injectCss();
		return Promise.all([ zm.systemStatus(), zm.mirrorStatus() ]);
	},

	render: function(data) {
		var sysData = data[0], mirrorData = data[1];
		var view = this;
		var wrap = E('div', { 'class': 'zm-wrap' });
		var netEl = E('div', {}, [ E('p', { 'class': 'zm-hint' }, 'Нажмите «Проверить», чтобы протестировать IPv4/IPv6') ]);

		var toggleBusy = false;
		function renderStatusCard(d) {
			var card = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Система'),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Блокировка QUIC'),
					zm.badge(d.quic_blocked === true, 'включена', 'выключена')
				]),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'IPv6 в Zapret'),
					zm.badge(d.ipv6_enabled === true, 'включён', 'выключен')
				]),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Fix для Flow Offloading'),
					zm.badge(d.flow_offloading_fix === true, 'применён', 'не применён')
				]),
				E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': d.quic_blocked ? 'cbi-button cbi-button-remove' : 'cbi-button',
						'click': function() {
							if (toggleBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							toggleBusy = true;
							zm.toast(d.quic_blocked ? 'Выключаем блокировку QUIC' : 'Включаем блокировку QUIC', 'warning');
							zm.systemToggleQuic().then(function(res) {
								toggleBusy = false;
								zm.toast(d.quic_blocked ? 'Блокировка QUIC выключена' : 'Блокировка QUIC включена', 'info');
								zm.systemStatus().then(refresh);
							}).catch(function() { toggleBusy = false; });
						}
					}, d.quic_blocked ? 'Выключить блокировку QUIC' : 'Включить блокировку QUIC'),
					E('button', {
						'class': 'cbi-button',
						'click': function() {
							if (toggleBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							toggleBusy = true;
							zm.toast(d.ipv6_enabled ? 'Выключаем IPv6 в Zapret' : 'Включаем IPv6 в Zapret', 'warning');
							zm.systemToggleIpv6().then(function(res) {
								toggleBusy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(res.ipv6_enabled ? 'IPv6 в Zapret включён' : 'IPv6 в Zapret выключен', 'info');
								zm.systemStatus().then(refresh);
							}).catch(function() { toggleBusy = false; });
						}
					}, d.ipv6_enabled ? 'Выключить IPv6 в Zapret' : 'Включить IPv6 в Zapret'),
					E('button', {
						'class': 'cbi-button',
						'click': function() {
							if (toggleBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							toggleBusy = true;
							zm.toast(d.flow_offloading_fix ? 'Отключаем Fix Flow Offloading' : 'Применяем Fix Flow Offloading', 'warning');
							zm.systemToggleFlowOffloadingFix().then(function(res) {
								toggleBusy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(res.flow_offloading_fix ? 'Fix для Flow Offloading применён' : 'Fix для Flow Offloading отключён', 'info');
								zm.systemStatus().then(refresh);
							}).catch(function() { toggleBusy = false; });
						}
					}, d.flow_offloading_fix ? 'Отключить Fix Flow Offloading' : 'Применить Fix Flow Offloading')
				])
			]);
			return card;
		}

		function refresh(d) {
			var newCard = renderStatusCard(d);
			wrap.replaceChild(newCard, wrap.firstChild);
		}

		wrap.appendChild(renderStatusCard(sysData));

		var netBusy = false;
		var netCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Проверка сети'),
			netEl,
			E('div', { 'class': 'zm-actions' }, [
				E('button', {
					'class': 'cbi-button',
					'click': function() {
						if (netBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						netBusy = true;
						netEl.textContent = 'Проверяем';
						zm.toast('Проверяем IPv4/IPv6', 'warning');
						zm.systemCheckConnectivity().then(function(res) {
							netBusy = false;
							netEl.innerHTML = '';
							netEl.appendChild(E('div', { 'class': 'zm-row' }, [
								E('span', { 'class': 'zm-label' }, 'IPv4 (google.com)'),
								zm.badge(res.ipv4_ok === true, 'доступен, ' + res.ipv4_ms + ' мс', 'недоступен')
							]));
							netEl.appendChild(E('div', { 'class': 'zm-row' }, [
								E('span', { 'class': 'zm-label' }, 'IPv6 (google.com)'),
								zm.badge(res.ipv6_ok === true, 'доступен, ' + res.ipv6_ms + ' мс', 'недоступен')
							]));
						}).catch(function() { netBusy = false; });
					}
				}, 'Проверить IPv4 / IPv6')
			])
		]);
		wrap.appendChild(netCard);

		var mirrorGrid = E('div', { 'class': 'zm-grid' });
		var mirrorCurrentEl = E('span', {}, mirrorData.current);
		var mirrorBusy = false;
		MIRRORS.forEach(function(m) {
			mirrorGrid.appendChild(E('div', {
				'class': 'zm-tile' + (mirrorData.current === m.label ? ' zm-active' : ''),
				'click': function() {
					if (mirrorBusy) { zm.toast('Дождитесь завершения переключения зеркала', 'warning'); return; }
					if (mirrorData.current === m.label) { zm.toast('Это зеркало уже выбрано', 'info'); return; }
					mirrorBusy = true;
					zm.toast('Переключаем зеркало на «' + m.label + '»', 'warning');
					mirrorLog.classList.add('zm-show');
					zm.renderLog(mirrorLog, '==> Проверяем и переключаем');
					zm.mirrorSet(m.id).then(function(res) {
						if (res.error) { mirrorBusy = false; zm.toast(res.error, 'error'); return; }
						zm.pollJob('mirror_set', mirrorLog, function(ok) {
							mirrorBusy = false;
							zm.toast(ok ? ('Зеркало переключено на «' + m.label + '»') : 'Не удалось переключить зеркало', ok ? 'info' : 'error');
							if (!ok) return;
							zm.mirrorStatus().then(function(res2) {
								mirrorData.current = res2.current;
								mirrorCurrentEl.textContent = res2.current;
								Array.prototype.forEach.call(mirrorGrid.children, function(el, i) {
									el.classList.toggle('zm-active', MIRRORS[i].label === res2.current);
								});
							});
						});
					}).catch(function() { mirrorBusy = false; });
				}
			}, m.label));
		});
		var mirrorLog = E('pre', { 'class': 'zm-log' });
		var mirrorCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Зеркало OpenWrt'),
			E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'Сейчас'), mirrorCurrentEl
			]),
			mirrorGrid,
			mirrorLog
		]);
		wrap.appendChild(mirrorCard);

		var uninstallLog = E('pre', { 'class': 'zm-log' });
		var uninstallCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Удалить Zapret Manager LuCI'),
			E('p', { 'class': 'zm-hint' },
				'Уберёт только веб-интерфейс (эту панель) — саму программу-оболочку из LuCI. ' +
				'Zapret, Zapret2, DNS over HTTPS и TG WS Proxy, если они были установлены через ' +
				'панель, останутся на роутере без изменений и продолжат работать. После удаления ' +
				'эта страница станет недоступна.'
			),
			E('div', { 'class': 'zm-actions' }, [
				E('button', {
					'class': 'cbi-button cbi-button-remove',
					'click': function() {
						if (!confirm('Удалить веб-интерфейс Zapret Manager LuCI?\n\nСам Zapret и остальные установленные через панель компоненты не пострадают. Действие необратимо — панель придётся ставить заново.')) {
							return;
						}
						uninstallLog.classList.add('zm-show');
						zm.renderLog(uninstallLog, '==> Удаляем веб-интерфейс Zapret Manager LuCI');
						zm.toast('Удаляем Zapret Manager LuCI', 'warning');
						zm.systemUninstallPanel().then(function(res) {
							if (res.error) { zm.renderLog(uninstallLog, '==> ОШИБКА: ' + res.error); zm.toast(res.error, 'error'); return; }
							zm.renderLog(uninstallLog, '==> Готово. Панель удалена, страница больше не будет отвечать. Выходим из LuCI');
							zm.toast('Zapret Manager LuCI удалён', 'info');
							setTimeout(function() { location.href = L.url('admin/logout'); }, 2500);
						}).catch(function() {
							zm.renderLog(uninstallLog, '==> Готово (соединение прервано — это ожидаемо, панель уже удалена). Выходим из LuCI');
							setTimeout(function() { location.href = L.url('admin/logout'); }, 2500);
						});
					}
				}, 'Удалить панель из LuCI')
			]),
			uninstallLog
		]);
		wrap.appendChild(uninstallCard);

		var CREDITS = [
			{ product: 'Zapret Manager и ByeTube', author: 'StressOzz', url: 'https://github.com/StressOzz', self: true },
			{ product: 'zapret, zapret2', author: 'bol-van', url: 'https://github.com/bol-van' },
			{ product: 'zapret-openwrt', author: 'remittor', url: 'https://github.com/remittor/zapret-openwrt' },
			{ product: 'Zapret2', author: 'routerich', url: 'https://github.com/routerich' },
			{ product: 'стратегии Flowseal', author: 'Flowseal', url: 'https://github.com/Flowseal/zapret-discord-youtube' },
			{ product: 'ByeDPI-OpenWrt', author: 'DPITrickster', url: 'https://github.com/DPITrickster/ByeDPI-OpenWrt' },
			{ product: 'mihomo, metacubexd', author: 'MetaCubeX', url: 'https://github.com/MetaCubeX' },
			{ product: 'zashboard', author: 'Zephyruso', url: 'https://github.com/Zephyruso/zashboard' },
			{ product: 'hev-socks5-tunnel', author: 'heiher', url: 'https://github.com/heiher/hev-socks5-tunnel' },
			{ product: 'MagiTrickle', author: 'MagiTrickle', url: 'https://github.com/MagiTrickle/MagiTrickle' },
			{ product: 'sTGWS, Steer', author: 'xyzmean', url: 'https://github.com/xyzmean' },
			{ product: 'tg-ws-proxy-go (MTProto)', author: 'spatiumstas', url: 'https://github.com/spatiumstas/tg-ws-proxy-go' },
			{ product: 'tg-ws-proxy-go (SOCKS5)', author: 'd0mhate', url: 'https://github.com/d0mhate/-tg-ws-proxy-Manager-go' },
			{ product: 'tg-ws-proxy-rs (Rust)', author: 'valnesfjord', url: 'https://github.com/valnesfjord/tg-ws-proxy-rs' },
			{ product: 'Mixomo, GeoHideDNS', author: 'Internet-Helper', url: 'https://github.com/Internet-Helper' },
			{ product: 'allow-domains', author: 'itdoginfo', url: 'https://github.com/itdoginfo/allow-domains' },
			{ product: 'dpi-checkers', author: 'hyperion-cs', url: 'https://github.com/hyperion-cs/dpi-checkers' },
			{ product: 'awg-openwrt (AmneziaWG)', author: '2Grey', url: 'https://github.com/2Grey/awg-openwrt' },
			{ product: 'warpscout (разведка WARP)', author: 'vernette', url: 'https://github.com/vernette/warpscout' },
			{ product: 'Всем пользователям', author: 'кто помогает, тестирует и поддерживает проект ❤', self: true, all: true }
		];
		var creditsGrid = E('div', { 'class': 'zm-credits-grid' }), allTile = null;
		CREDITS.forEach(function(c) {
			var tile = E('div', { 'class': 'zm-credit-tile' + (c.self ? ' zm-credit-self' : '') + (c.all ? ' zm-credit-all' : '') }, [
				E('div', { 'class': 'zm-credit-product' }, c.product),
				E('div', { 'class': 'zm-credit-author' }, c.author),
				c.url ? E('a', { 'href': c.url, 'target': '_blank', 'rel': 'noreferrer' }, c.url.replace(/^https?:\/\//, '')) : ''
			]);
			if (c.all) allTile = tile;
			creditsGrid.appendChild(tile);
		});
		function fitAll() {
			if (!allTile || !document.body.contains(creditsGrid)) return;
			var cols = (getComputedStyle(creditsGrid).gridTemplateColumns || '').split(' ').filter(function(s) { return s; }).length || 1;
			var rest = (CREDITS.length - 1) % cols;
			allTile.style.gridColumn = rest ? 'span ' + (cols - rest) : '1 / -1';
		}
		setTimeout(fitAll, 0); setTimeout(fitAll, 400);
		window.addEventListener('resize', fitAll);
		var creditsCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Спасибо'),
			E('p', { 'class': 'zm-hint' }, 'Zapret Manager собирает в одном месте работу этих проектов и их авторов.'),
			creditsGrid
		]);
		wrap.appendChild(creditsCard);

		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/system.js'

mkdir -p /www/luci-static/resources/view/zapret-manager
chmod 0755 /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/tgproxy.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var VARIANTS = [
	{ id: 'mtproto', title: 'Go (MTProto)', port: 1443, kind: 'proto' },
	{ id: 'socks5', title: 'SOCKS5', port: 2080, kind: 'socks' },
	{ id: 'rust', title: 'Rust (MTProto)', port: 2443, kind: 'proto' }
];

function copyToClipboard(text) {
	if (window.isSecureContext && navigator.clipboard && navigator.clipboard.writeText) {
		navigator.clipboard.writeText(text).then(function() {
			zm.toast('Ссылка скопирована', 'info');
		}).catch(function() {
			fallbackCopy(text);
		});
	} else {
		fallbackCopy(text);
	}
}

function fallbackCopy(text) {
	var ta = document.createElement('textarea');
	ta.value = text;
	ta.setAttribute('readonly', '');
	ta.style.position = 'fixed';
	ta.style.top = '0';
	ta.style.left = '0';
	ta.style.opacity = '0';
	document.body.appendChild(ta);
	ta.focus();
	ta.select();
	ta.setSelectionRange(0, text.length);
	var ok = false;
	try { ok = document.execCommand('copy'); } catch (e) { ok = false; }
	document.body.removeChild(ta);
	zm.toast(ok ? 'Ссылка скопирована' : 'Не удалось скопировать — выделите ссылку вручную', ok ? 'info' : 'warning');
}

return view.extend({
	load: function() {
		zm.injectCss();
		return Promise.all([ zm.tgStatus(), zm.tgwsStatus().catch(function() { return {}; }) ]);
	},

	render: function(all) {
		var view = this;
		var data = all[0];
		var tgwsData = all[1] || {};
		var wrap = E('div', { 'class': 'zm-wrap' });
		var cards = E('div', { 'class': 'zm-cards' });
		var linksWrap = E('div', {});
		var logEl = E('pre', { 'class': 'zm-log' });

		function statusOf(d, id) {
			if (id === 'mtproto') return { installed: d.mtproto === 'installed', running: d.mtproto_running === true, secret: d.secret_mtproto, version: d.mtproto_version, latest: d.mtproto_latest };
			if (id === 'socks5') return { installed: d.socks5 === 'installed', running: d.socks5_running === true, secret: '', version: d.socks5_version, latest: d.socks5_latest };
			return { installed: d.rust === 'installed', running: d.rust_running === true, secret: d.secret_rust, version: d.rust_version, latest: d.rust_latest };
		}

		function renderLinks(d) {
			linksWrap.innerHTML = '';
			var any = false;
			VARIANTS.forEach(function(v) {
				var st = statusOf(d, v.id);
				if (!st.installed || !st.running || !d.lan_ip) return;
				any = true;

				var link, extra;
				if (v.kind === 'socks') {
					link = 'tg://socks?server=' + d.lan_ip + '&port=' + v.port;
					extra = 'SOCKS5-адрес: ' + d.lan_ip + ':' + v.port;
				} else {
					var secretPrefixed = 'dd' + st.secret;
					link = 'tg://proxy?server=' + d.lan_ip + '&port=' + v.port + '&secret=' + secretPrefixed;
					extra = 'Хост: ' + d.lan_ip + '   Порт: ' + v.port + '   Ключ: ' + secretPrefixed;
				}

				var qrLink = link.replace(/^tg:\/\//, 'https://t.me/');
				var qrBox = E('div', { 'class': 'zm-tg-qr-box', 'style': 'display:none' });
				var qrShown = false;

				function toggleQr() {
					qrShown = !qrShown;
					qrBox.style.display = qrShown ? '' : 'none';
					if (qrShown && !qrBox.firstChild) {
						qrBox.appendChild(E('img', {
							'src': 'https://api.qrserver.com/v1/create-qr-code/?size=220x220&margin=8&data=' + encodeURIComponent(qrLink),
							'alt': 'QR-код',
							'width': '220',
							'height': '220'
						}));
					}
				}

				linksWrap.appendChild(E('div', { 'class': 'zm-tg-link-card' }, [
					E('h4', {}, v.title),
					E('p', { 'class': 'zm-tg-link-hint' }, 'Откройте эту ссылку на телефоне/компьютере с Telegram — прокси подключится автоматически. Либо скопируйте и вставьте её в браузер/Telegram вручную.'),
					E('div', { 'class': 'zm-tg-link-row' }, [
						E('div', { 'class': 'zm-tg-link-box' }, link),
						E('button', {
							'class': 'cbi-button cbi-button-positive',
							'click': function() { copyToClipboard(link); }
						}, 'Скопировать'),
						E('button', {
							'class': 'cbi-button zm-tg-qr-btn',
							'title': 'Показать QR-код',
							'click': function() { toggleQr(); }
						}, 'QR-код')
					]),
					E('p', { 'class': 'zm-hint' }, extra),
					qrBox
				]));
			});
		}

		var busyMap = {};

		function renderCards(d) {
			cards.innerHTML = '';
			VARIANTS.forEach(function(v) {
				var st = statusOf(d, v.id);
				var actions = [];
				if (st.installed) {
					actions.push(E('button', {
						'class': 'cbi-button cbi-button-remove',
						'click': function() { doAction(v.id, 'remove'); }
					}, 'Удалить'));
					if (st.version && st.latest && st.version !== st.latest) {
						actions.push(E('button', {
							'class': 'cbi-button',
							'click': function() { doAction(v.id, 'update'); }
						}, 'Обновить до ' + st.latest));
					}
				} else {
					actions.push(E('button', {
						'class': 'cbi-button cbi-button-positive',
						'click': function() { doAction(v.id, 'install'); }
					}, 'Установить'));
				}
				cards.appendChild(E('div', { 'class': 'zm-card' }, [
					E('h3', {}, v.title),
					E('div', { 'class': 'zm-row' }, [
						E('span', { 'class': 'zm-label' }, 'Статус'),
						st.installed ? zm.badge(st.running, 'запущен', 'остановлен') : zm.badge(false, '', 'не установлен')
					]),
					st.installed && st.version ? E('div', { 'class': 'zm-row' }, [
						E('span', { 'class': 'zm-label' }, 'Версия'), E('span', {}, st.version)
					]) : E([]),
					E('div', { 'class': 'zm-actions' }, actions)
				]));
			});
		}

		function doAction(variantId, action) {
			if (busyMap[variantId]) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			busyMap[variantId] = true;
			var job = action === 'remove' ? ('tg_remove_' + (variantId === 'mtproto' ? 'mtproto' : variantId))
				: ('tg_install_' + (variantId === 'mtproto' ? 'mtproto' : variantId));
			zm.toast((action === 'remove' ? 'Удаляем ' : action === 'update' ? 'Обновляем ' : 'Устанавливаем ') + variantId + '', 'warning');
			zm.tgAction(variantId, action).then(function(res) {
				if (res.error) { busyMap[variantId] = false; zm.toast(res.error, 'error'); return; }
				if (res.started) {
					zm.pollJob(job, logEl, function(ok) {
						busyMap[variantId] = false;
						zm.toast(ok ? 'Готово' : 'Ошибка', ok ? 'info' : 'error');
						zm.tgStatus().then(function(d) { renderCards(d); renderLinks(d); });
					});
				} else {
					busyMap[variantId] = false;
				}
			}).catch(function() { busyMap[variantId] = false; });
		}

		renderLinks(data);
		renderCards(data);
		wrap.appendChild(linksWrap);
		wrap.appendChild(cards);
		wrap.appendChild(logEl);

		var tgwsCard = E('div', { 'class': 'zm-card' });
		var tgwsBusy = false;

		function renderTgws(d) {
			var installed = d.installed === 'installed';
			var actions = [];
			if (installed) {
				actions.push(E('button', {
					'class': 'cbi-button cbi-button-remove',
					'click': function() { doTgwsAction('remove'); }
				}, 'Удалить'));
				if (d.version && d.latest && d.version !== d.latest) {
					actions.push(E('button', {
						'class': 'cbi-button',
						'click': function() { doTgwsAction('update'); }
					}, 'Обновить до ' + d.latest));
				}
				actions.push(E('button', {
					'class': 'cbi-button',
					'click': function() { doTgwsAction('restart'); }
				}, 'Перезапустить'));
				actions.push(E('button', {
					'class': 'cbi-button',
					'click': function() { doTgwsAction('reconfigure'); }
				}, 'Подобрать новый домен'));
			} else {
				actions.push(E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() { doTgwsAction('install'); }
				}, 'Установить'));
			}
			tgwsCard.innerHTML = '';
			tgwsCard.appendChild(E('h3', {}, 'sTGWS (бета)'));
			tgwsCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Бета-версия. В отдельных случаях может потребоваться сброс роутера до заводских настроек. Не устанавливайте, если не уверены, что сможете устранить возможные проблемы.'));
			tgwsCard.appendChild(E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'Статус'),
				installed ? zm.badge(d.running === true, 'запущен', 'остановлен') : zm.badge(false, '', 'не установлен')
			]));
			if (installed && d.version) {
				tgwsCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Версия'), E('span', {}, d.version)
				]));
			}
			if (installed && d.domain) {
				tgwsCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Домен'), E('span', {}, d.domain)
				]));
			}
			tgwsCard.appendChild(E('div', { 'class': 'zm-actions' }, actions));
		}

		function doTgwsAction(action) {
			if (tgwsBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			tgwsBusy = true;
			var job = action === 'remove' ? 'tgws_remove'
				: action === 'restart' ? 'tgws_restart'
				: action === 'reconfigure' ? 'tgws_reconfigure' : 'tgws_install';
			var label = action === 'remove' ? 'Удаляем sTGWS'
				: action === 'restart' ? 'Перезапускаем sTGWS'
				: action === 'reconfigure' ? 'Подбираем новый домен sTGWS'
				: action === 'update' ? 'Обновляем sTGWS' : 'Устанавливаем sTGWS';
			zm.toast(label, 'warning');
			zm.tgwsAction(action).then(function(res) {
				if (res.error) { tgwsBusy = false; zm.toast(res.error, 'error'); return; }
				if (res.started) {
					zm.pollJob(job, logEl, function(ok) {
						tgwsBusy = false;
						zm.toast(ok ? 'Готово' : 'Ошибка', ok ? 'info' : 'error');
						zm.tgwsStatus().then(function(d) { renderTgws(d); });
					});
				} else {
					tgwsBusy = false;
				}
			}).catch(function() { tgwsBusy = false; });
		}

		renderTgws(tgwsData);
		wrap.appendChild(tgwsCard);

		var restartBusy = false;
		wrap.appendChild(E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Общие действия'),
			E('div', { 'class': 'zm-actions' }, [
				E('button', {
					'class': 'cbi-button',
					'click': function() {
						if (restartBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						restartBusy = true;
						zm.toast('Перезапускаем TG WS Proxy', 'warning');
						zm.tgRestartAll().then(function() {
							restartBusy = false;
							zm.toast('Все запущенные TG WS Proxy перезапущены', 'info');
							zm.tgwsStatus().then(function(d) { renderTgws(d); });
						}).catch(function() { restartBusy = false; });
					}
				}, 'Перезапустить все')
			])
		]));

		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/tgproxy.js'


mkdir -p /www/luci-static/resources/bytetube
cat > '/www/luci-static/resources/bytetube/common.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require baseclass';
'require fs';
'require uci';
'require rpc';
'require ui';

var callUciCommit = rpc.declare({ object: 'uci', method: 'commit', params: [ 'config' ] });

var CTL = '/usr/bin/bytetube';
var INIT = '/etc/init.d/bytetube';
var CONF = 'bytetube';

function callJson(args) {
	return fs.exec(CTL, args).then(function(r) {
		var out = (r.stdout || '').trim();
		try { return JSON.parse(out); }
		catch (e) { return { error: out || r.stderr || 'нет ответа' }; }
	}).catch(function(e) { return { error: e.message }; });
}

function callText(args) {
	return fs.exec(CTL, args).then(function(r) { return r.stdout || ''; })
		.catch(function() { return ''; });
}

function detectMissingThemeVar() {
	if (document.documentElement.hasAttribute('data-zm-theme-checked')) return;
	document.documentElement.setAttribute('data-zm-theme-checked', '1');
	try {
		var declared = getComputedStyle(document.documentElement).getPropertyValue('--background-color-medium').trim();
		if (declared) return;

		var el = document.body, bg = '', hops = 0;
		while (el && hops < 6) {
			var c = getComputedStyle(el).backgroundColor;
			if (c && c !== 'rgba(0, 0, 0, 0)' && c !== 'transparent') { bg = c; break; }
			el = el.parentElement;
			hops++;
		}
		var m = bg.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
		if (!m) return;
		var luminance = (0.299 * (+m[1]) + 0.587 * (+m[2]) + 0.114 * (+m[3])) / 255;
		if (luminance < 0.5) document.documentElement.classList.add('zm-theme-dark');
	} catch (e) {}
}

function injectCss() {
	detectMissingThemeVar();
	if (document.getElementById('bt-css')) return;
	var l = document.createElement('link');
	l.id = 'bt-css';
	l.rel = 'stylesheet';
	l.href = L.resource('view/bytetube/style.css');
	document.head.appendChild(l);
}

function badge(ok, textOk, textBad) {
	var cls = ok ? 'zm-ok' : (textBad === 'не установлен' ? 'zm-off' : 'zm-bad');
	return E('span', { 'class': 'zm-badge ' + cls }, [
		E('span', { 'class': 'zm-dot' }),
		ok ? textOk : textBad
	]);
}

function toastContainer() {
	var c = document.getElementById('zm-toast-container');
	if (!c) {
		c = document.createElement('div');
		c.id = 'zm-toast-container';
		document.body.appendChild(c);
	}
	return c;
}

function toast(message, kind, duration) {
	var container = toastContainer();
	var el = E('div', { 'class': 'zm-toast zm-toast-' + (kind || 'info') }, [
		E('span', { 'class': 'zm-toast-icon' }, kind === 'error' ? '✕' : (kind === 'warning' ? '!' : '✓')),
		E('span', { 'class': 'zm-toast-text' }, [ message ])
	]);
	container.appendChild(el);
	requestAnimationFrame(function() { el.classList.add('zm-toast-show'); });
	var hide = function() {
		el.classList.remove('zm-toast-show');
		setTimeout(function() { el.parentNode && el.parentNode.removeChild(el); }, 250);
	};
	el.addEventListener('click', hide);
	setTimeout(hide, duration || (kind === 'error' ? 14000 : 9000));
}

function span(cls, text) {
	var s = document.createElement('span');
	s.className = cls;
	s.textContent = text;
	return s;
}

function scoreClass(ok, total, controlOk) {
	if (ok === total) return 'bt-c-ok';
	if (controlOk !== null && controlOk !== undefined) return ok > controlOk ? 'bt-c-warn' : 'bt-c-bad';
	return ok > 0 ? 'bt-c-warn' : 'bt-c-bad';
}

function chipClass(ok, total, controlOk) {
	return scoreClass(ok, total, controlOk).replace('bt-c-', 'bt-chip bt-chip-');
}

function logLine(line, ctx, nameOf) {
	var div = document.createElement('div');
	var m, p;

	if ((m = line.match(/^==> \[(\d+)\/(\d+)\] (.*)$/))) {
		div.appendChild(span('zm-log-arrow', '==> '));
		div.appendChild(span('bt-c-key', '[' + m[1] + '/' + m[2] + '] '));
		div.appendChild(span('bt-c-white', m[3]));
		p = nameOf ? nameOf(m[3]) : null;
		if (p) div.appendChild(span('bt-c-dim', '   ← ' + p));
	}
	else if ((m = line.match(/^==> Результат: (\d+)\/(\d+)$/))) {
		ctx.ctrl = +m[1];
		div.appendChild(span('zm-log-arrow', '==> '));
		div.appendChild(span('bt-c-dim', 'Результат контрольного замера: '));
		div.appendChild(span('bt-c-white', m[1] + '/' + m[2]));
	}
	else if ((m = line.match(/^(\s+)результат: (\d+)\/(\d+)$/))) {
		div.appendChild(span('bt-c-dim', m[1] + 'результат: '));
		div.appendChild(span(scoreClass(+m[2], +m[3], ctx.ctrl), m[2] + '/' + m[3]));
	}
	else if (/^\s+(пропуск|прервано)/.test(line)) {
		div.className = 'zm-log-msg-warn';
		div.textContent = line;
	}
	else if ((m = line.match(/^==> Лучшая стратегия: (.*?)\s*→\s*(\d+)\/(\d+)\s*$/))) {
		div.appendChild(span('zm-log-arrow', '==> '));
		div.appendChild(span('zm-log-msg-ok', 'Лучшая стратегия: '));
		div.appendChild(span('bt-c-white', m[1] + ' '));
		div.appendChild(span('bt-c-dim', '→ '));
		div.appendChild(span(scoreClass(+m[2], +m[3], ctx.ctrl), m[2] + '/' + m[3]));
	}
	else if (/^==> (Тест завершён|Готово)/.test(line)) {
		div.appendChild(span('zm-log-arrow', '==> '));
		div.appendChild(span('zm-log-msg-ok', line.slice(4)));
	}
	else if (/^==> (Тест остановлен|Пропущено)/.test(line)) {
		div.appendChild(span('zm-log-arrow', '==> '));
		div.appendChild(span('zm-log-msg-warn', line.slice(4)));
	}
	else if (/^==> Результаты$/.test(line)) {
		div.appendChild(span('zm-log-arrow', '==> '));
		div.appendChild(span('zm-log-msg-info', 'Результаты'));
	}
	else if ((m = line.match(/^(.*?)\s*→\s*(\d+)\/(\d+)\s*$/))) {
		if (/^Контрольный тест/.test(m[1])) {
			ctx.ctrl = +m[2];
			div.appendChild(span('bt-c-dim', m[1] + ' → '));
			div.appendChild(span('bt-c-white', m[2] + '/' + m[3]));
		} else {
			div.appendChild(span('bt-c-white', m[1] + ' '));
			div.appendChild(span('bt-c-dim', '→ '));
			div.appendChild(span(scoreClass(+m[2], +m[3], ctx.ctrl), m[2] + '/' + m[3]));
		}
	}
	else if (/^ОШИБКА/.test(line)) {
		div.className = 'zm-log-msg-error';
		div.textContent = line;
	}
	else if (/^==> /.test(line)) {
		div.appendChild(span('zm-log-arrow', '==> '));
		div.appendChild(span('zm-log-msg-info', line.slice(4)));
	}
	else {
		div.className = 'zm-log-code';
		div.textContent = line;
	}
	return div;
}

function renderTestLog(logEl, text, nameOf) {
	var ctx = { ctrl: null };
	while (logEl.firstChild) logEl.removeChild(logEl.firstChild);
	(text || '').split('\n').forEach(function(l) {
		if (l !== '') logEl.appendChild(logLine(l, ctx, nameOf));
	});
	logEl.scrollTop = logEl.scrollHeight;
}

function parseResults(text) {
	var rows = [], control = null;
	(text || '').split('\n').forEach(function(line) {
		var m = line.match(/^(.*?)\s*→\s*(\d+)\/(\d+)\s*$/);
		if (!m) return;
		if (/^Контрольный тест/.test(m[1]))
			control = { ok: +m[2], total: +m[3] };
		else
			rows.push({ opts: m[1], ok: +m[2], total: +m[3] });
	});
	rows.forEach(function(r, i) { r.i = i; });
	rows.sort(function(a, b) { return (b.ok - a.ok) || (a.i - b.i); });
	return { control: control, rows: rows };
}

/* ---- настройки: читаются/пишутся напрямую через UCI, commit сразу — без полного
   цикла "Save & Apply" с откатом, чтобы не показывать глобальный баннер LuCI
   "Applying/Unsaved changes" ---- */

function b2n(v, def) {
	if (v === undefined || v === null || v === '') return def;
	return (v === '1' || v === 1 || v === true) ? 1 : 0;
}

function config() {
	return uci.load(CONF).then(function() {
		var domain = uci.get(CONF, 'main', 'domain');
		return {
			enabled: b2n(uci.get(CONF, 'main', 'enabled'), 0) === 1,
			byedpi_opts: uci.get(CONF, 'main', 'byedpi_opts') || '',
			byedpi_port: uci.get(CONF, 'main', 'byedpi_port') || '1088',
			quic: uci.get(CONF, 'main', 'quic') || 'block',
			ipv6: b2n(uci.get(CONF, 'main', 'ipv6'), 1) === 1,
			default_domains: b2n(uci.get(CONF, 'main', 'default_domains'), 1) === 1,
			domain: Array.isArray(domain) ? domain : (domain ? [ domain ] : [])
		};
	}).catch(function(e) { return { error: e.message }; });
}

function configSet(pairs) {
	return uci.load(CONF).then(function() {
		Object.keys(pairs).forEach(function(k) {
			var v = pairs[k];
			if (k === 'enabled' || k === 'ipv6' || k === 'default_domains')
				v = String(v ? 1 : 0);
			else if (Array.isArray(v)) {
				/* пусто -> опция удаляется совсем, иначе список сохранится пустой строкой */
				if (!v.length) { uci.unset(CONF, 'main', k); return; }
			} else {
				v = String(v);
			}
			uci.set(CONF, 'main', k, v);
		});
		return uci.save().then(function() {
			return callUciCommit(CONF);
		}).then(function() {
			/* save() уже показал в шапке индикатор "Unsaved changes" — мы его сразу
			   закоммитили напрямую (без штатного uci.apply()), поэтому явно гасим
			   индикатор здесь, иначе он останется висеть до следующего обновления */
			try { ui.changes.setIndicator(0); } catch (e) {}
			return { ok: true };
		});
	}).catch(function(e) { return { error: e.message }; });
}

return baseclass.extend({
	injectCss: injectCss,
	toast: toast,
	badge: badge,
	span: span,
	chipClass: chipClass,
	scoreClass: scoreClass,
	renderTestLog: renderTestLog,
	parseResults: parseResults,
	callJson: callJson,
	callText: callText,

	status: function() { return callJson([ 'status' ]); },
	config: config,
	configSet: configSet,
	service: function(action) {
		return fs.exec(INIT, [ action ]).then(function() { return { ok: true }; })
			.catch(function(e) { return { error: e.message }; });
	},
	flush: function() {
		return fs.exec(CTL, [ 'flush' ]).then(function() { return { ok: true }; })
			.catch(function(e) { return { error: e.message }; });
	},
	setStrategy: function(opts) { return callJson([ 'set-strategy', opts ]); },
	listGet: function(kind) { return callText([ 'test', 'list', 'get', kind ]); },
	listSet: function(kind, text) { return callJson([ 'test', 'list', 'set', kind, text ]); },
	listReset: function(kind) { return callJson([ 'test', 'list', 'reset', kind ]); },
	testStatus: function() { return callJson([ 'test', 'status' ]); },
	testStart: function() { return callJson([ 'test', 'start' ]); },
	testStop: function() { return callJson([ 'test', 'stop' ]); },
	testClear: function() { return callJson([ 'test', 'clear' ]); },
	testLog: function() { return callText([ 'test', 'log' ]); },
	testResults: function() { return callText([ 'test', 'results' ]); }
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/bytetube/common.js'

cat > '/www/luci-static/resources/bytetube/presets.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require baseclass';

/*
 * Готовые стратегии ByeDPI (параметры ciadpi).
 * name — короткое имя для списка, чтобы не читать длинную командную строку;
 * опции подставляются в поле «Параметры ByeDPI».
 * Под своего провайдера лучшую стратегию подбирает вкладка «Тест стратегий».
 */
var LIST = [
	{
		id: 'p1',
		label: 'Стратегия 1',
		name: '1 · Каскад disorder/split + tlsrec + md5sig, авто-режим -As (по умолчанию)',
		opts: '-d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -S -a1'
	},
	{
		id: 'p2',
		label: 'Стратегия 2',
		name: '2 · Короткая: OOB + tlsrec у SNI',
		opts: '-o1 -a1 -r-5+se'
	},
	{
		id: 'p3',
		label: 'Стратегия 3',
		name: '3 · Fake SNI google.com + disorder/OOB (TTL 4)',
		opts: '-n "google.com" -Qr -d5+sm -f3+sm -o2 -t4 -a1'
	},
	{
		id: 'p4',
		label: 'Стратегия 4',
		name: '4 · Каскад disorder/split без tlsrec и авто-режима',
		opts: '-d1 -s1+s -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -a1'
	},
	{
		id: 'p5',
		label: 'Стратегия 5',
		name: '5 · Fake + disoob + tlsrec (TTL 5 и 15)',
		opts: '-f1 -t5 -n "google.com" -q3+h -Qr -f2 -q1 -r1+s -t15 -q1 -o2 -a1'
	},
	{
		id: 'p6',
		label: 'Стратегия 6',
		name: '6 · OOB + tlsrec + авто-режим -At,r,s, fake google.com',
		opts: '-o1 -r-5+se -a1 -At,r,s -d1 -n "google.com" -Qr -f-1 -a1'
	}
];

/* для сравнения: без кавычек, пробелы схлопнуты (так же, как в бэкенде) */
function clean(s) {
	return String(s == null ? '' : s).replace(/["']/g, '').replace(/\s+/g, ' ').trim();
}

/* для хранения: только пробелы, кавычки остаются как ввёл пользователь */
function norm(s) {
	return String(s == null ? '' : s).replace(/\s+/g, ' ').trim();
}

function find(opts) {
	var c = clean(opts);
	if (!c) return null;
	for (var i = 0; i < LIST.length; i++)
		if (clean(LIST[i].opts) === c) return LIST[i];
	return null;
}

function byId(id) {
	for (var i = 0; i < LIST.length; i++)
		if (LIST[i].id === id) return LIST[i];
	return null;
}

return baseclass.extend({
	list: LIST,
	DEFAULT: LIST[0].opts,
	clean: clean,
	norm: norm,
	find: find,
	byId: byId
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/bytetube/presets.js'

mkdir -p /www/luci-static/resources/view/bytetube
cat > '/www/luci-static/resources/view/bytetube/style.css' << 'ZM_INSTALLER_EOF'
.zm-header { display: flex; align-items: baseline; gap: 10px; margin-bottom: -4px; flex-wrap: wrap; }
.zm-header h2 { margin: 0; font-size: 22px; font-weight: 700; }
.zm-header-by { font-size: 13px; opacity: .55; }
.zm-header-links { display: flex; gap: 8px; margin-left: auto; flex-wrap: wrap; }
.zm-header-links a {
	font-size: 12.5px; font-weight: 600; text-decoration: none;
	color: #229ed9; background: rgba(34,158,217,.1); border: 1px solid rgba(34,158,217,.25);
	border-radius: 999px; padding: 5px 13px; transition: background .15s;
}
.zm-header-links a:hover { background: rgba(34,158,217,.18); }

.zm-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; }

.zm-card {
	min-width: 0;
	box-sizing: border-box;
	background: var(--background-color-medium, #fff);
	border: 1px solid rgba(0,0,0,.08);
	border-radius: 12px;
	padding: 18px 20px;
	box-shadow: 0 1px 3px rgba(0,0,0,.05), 0 1px 2px rgba(0,0,0,.04);
	overflow-wrap: break-word;
	transition: box-shadow .15s;
}

html.zm-theme-dark .zm-card {
	background: #1c2128;
	border-color: rgba(255,255,255,.10);
	box-shadow: 0 1px 3px rgba(0,0,0,.25), 0 1px 2px rgba(0,0,0,.2);
}
.zm-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,.08); }

.zm-card h3 { margin: 0 0 12px 0; font-size: 15px; font-weight: 600; display: flex; align-items: center; gap: 8px; }

.zm-row { display: flex; align-items: center; gap: 12px; margin: 7px 0; font-size: 13px; flex-wrap: wrap; }
.zm-row .zm-label { opacity: .65; flex-shrink: 0; }
.zm-row > span:last-child { overflow-wrap: anywhere; }

.zm-badge { display: inline-flex; align-items: center; gap: 6px; padding: 3px 11px; border-radius: 999px; font-size: 12px; font-weight: 600; white-space: nowrap; }
.zm-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; flex-shrink: 0; }

.zm-ok    { background: rgba(46,160,67,.12); color: #1a7f37; }
.zm-ok .zm-dot { background: #1a7f37; }
.zm-bad   { background: rgba(207,34,46,.10); color: #cf222e; }
.zm-bad .zm-dot { background: #cf222e; }
.zm-warn  { background: rgba(191,135,0,.12); color: #9a6700; }
.zm-warn .zm-dot { background: #9a6700; }
.zm-off   { background: rgba(110,118,129,.12); color: #57606a; }
.zm-off .zm-dot { background: #57606a; }

.zm-actions { display: flex; gap: 12px; flex-wrap: wrap; align-items: center; margin: 14px 0; }
.zm-actions .cbi-button { margin: 0; }

.zm-grid { display: flex; flex-wrap: wrap; gap: 9px; }
.zm-grid-devices { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 9px; }
.zm-grid-devices .zm-tile { flex: none; min-width: 0; width: 100%; box-sizing: border-box; }

.zm-tile {
	flex: 0 1 auto;
	min-width: 90px;
	max-width: 100%;
	border: 1px solid rgba(0,0,0,.1);
	border-radius: 9px;
	padding: 10px 16px;
	cursor: pointer;
	text-align: center;
	font-size: 13px;
	line-height: 1.35;
	overflow-wrap: break-word;
	transition: border-color .15s, background .15s, transform .1s;
	background: var(--background-color-low, #fafafa);
}
html.zm-theme-dark .zm-tile:not(.zm-active):not(.zm-tile-off) {
	background: #22272e;
	border-color: rgba(255,255,255,.12);
}
.zm-tile:hover { border-color: #1a7f37; transform: translateY(-1px); }
.zm-tile.zm-active {
	border-color: #1a7f37; background: rgba(26,127,55,.16);
	font-weight: 700; color: #15803d;
	box-shadow: 0 0 0 2px rgba(26,127,55,.35);
}
.zm-tile.zm-active::before { content: "✓ "; }

.zm-tile.zm-tile-off {
	border-color: rgba(207,34,46,.35); background: rgba(207,34,46,.08);
	color: #cf222e; font-weight: 600;
}
.zm-tile.zm-tile-off::before { content: "✗ "; }
.zm-tile.zm-tile-off:hover { border-color: #cf222e; }
.zm-tile.zm-tile-pending { opacity: .55; border-style: dashed; cursor: not-allowed; }
.zm-tile.zm-tile-pending:hover { border-color: rgba(0,0,0,.1); transform: none; }

.zm-log {
	background: #0d1117; color: #e6edf3;
	font-family: ui-monospace, "SF Mono", "Cascadia Code", Consolas, "Liberation Mono", monospace;
	font-size: 13.5px; line-height: 1.7;
	border: 1px solid rgba(255,255,255,.10);
	border-radius: 10px; padding: 16px 18px;
	white-space: pre-wrap; word-break: break-word; overflow-wrap: anywhere;
	max-height: 520px; min-height: 220px;
	overflow-x: hidden; overflow-y: auto;
	margin-top: 14px; display: none;
	box-shadow: inset 0 0 0 1px rgba(0,0,0,.2);
}
.zm-log.zm-show { display: block; }
.zm-log { scrollbar-width: auto; scrollbar-color: auto; }
.zm-log::-webkit-scrollbar { width: 14px; }
.zm-log::-webkit-scrollbar-track { background: transparent; margin: 8px 0; }
.zm-log::-webkit-scrollbar-thumb { background: rgba(255,255,255,.2); border-radius: 10px; border: 4px solid transparent; background-clip: padding-box; min-height: 40px; }
.zm-log::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,.34); background-clip: padding-box; }
@supports not selector(::-webkit-scrollbar) { .zm-log { scrollbar-width: thin; scrollbar-color: rgba(255,255,255,.25) transparent; } }
.zm-config-editor { scrollbar-width: auto; scrollbar-color: auto; }
.zm-config-editor::-webkit-scrollbar { width: 14px; height: 14px; }
.zm-config-editor::-webkit-scrollbar-button { display: none; }
.zm-config-editor::-webkit-scrollbar-track, .zm-config-editor::-webkit-scrollbar-corner, .zm-config-editor::-webkit-resizer { background: transparent; }
.zm-config-editor::-webkit-scrollbar-track { margin: 8px; }
.zm-config-editor::-webkit-scrollbar-thumb { background: rgba(255,255,255,.2); border-radius: 10px; border: 4px solid transparent; background-clip: padding-box; min-height: 40px; }
.zm-config-editor::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,.34); background-clip: padding-box; }
@supports not selector(::-webkit-scrollbar) { .zm-config-editor { scrollbar-width: thin; scrollbar-color: rgba(255,255,255,.25) transparent; } }
.zm-log:empty::before { content: "Ожидание вывода..."; opacity: .4; }
.zm-log-bar { position: sticky; top: 16px; height: 0; z-index: 3; }
.zm-log-min {
	position: absolute; right: -8px; top: -8px; width: 30px; height: 24px; padding: 0; margin: 0;
	border: 1px solid rgba(255,255,255,.14); border-radius: 7px; background: rgba(255,255,255,.06);
	color: #c9d1d9; font: 700 13px/1 ui-monospace, Consolas, monospace; cursor: pointer;
	display: flex; align-items: center; justify-content: center; transition: background .15s, color .15s;
}
.zm-log-min:hover { background: rgba(255,255,255,.16); color: #fff; }
.zm-log.zm-log-collapsed { min-height: 0; max-height: none; overflow: hidden; padding-right: 48px; }
.zm-log.zm-log-collapsed > div:not(.zm-log-bar):not(:last-child) { display: none; }
.zm-log.zm-log-collapsed > div:last-child { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

.zm-config-editor {
	width: 100%; box-sizing: border-box; min-height: 420px;
	background: #0d1117; color: #e6edf3;
	font-family: ui-monospace, "SF Mono", "Cascadia Code", Consolas, "Liberation Mono", monospace;
	font-size: 13px; line-height: 1.6;
	border: 1px solid rgba(255,255,255,.1); border-radius: 10px;
	padding: 14px 16px; margin: 10px 0;
	white-space: pre; overflow: auto; resize: vertical;
}
html.zm-theme-dark .zm-config-editor { border-color: rgba(255,255,255,.14); }
@media (max-width: 600px) {
	/* 16px — чтобы iOS Safari не увеличивал масштаб страницы при тапе в поле */
	.zm-config-editor { font-size: 16px; min-height: 320px; }
}

.zm-log-arrow { color: #56d4dd; font-weight: 700; }
.zm-log-msg-info { color: #e3c04a; }
.zm-log-msg-ok { color: #3fb950; font-weight: 600; }
.zm-log-msg-error { color: #ff7b72; font-weight: 600; }
.zm-log-msg-warn { color: #ffa657; }
.zm-log-code { color: #8b949e; }

.zm-hint { font-size: 12px; opacity: .65; margin-top: 6px; line-height: 1.5; overflow-wrap: break-word; }


#zm-toast-container {
	position: fixed; top: 20px; right: 20px; z-index: 10000;
	display: flex; flex-direction: column; gap: 14px;
	max-width: 520px;
}
.zm-toast {
	display: flex; align-items: flex-start; gap: 14px;
	background: #1c2128; color: #e6edf3;
	padding: 24px 28px; border-radius: 16px;
	box-shadow: 0 10px 40px rgba(0,0,0,.4);
	font-size: 18px; line-height: 1.5; font-weight: 500; cursor: pointer;
	opacity: 0; transform: translateX(24px);
	transition: opacity .22s ease, transform .22s ease;
	border-left: 6px solid #1a7f37;
}
.zm-toast-show { opacity: 1; transform: translateX(0); }
.zm-toast-error { border-left-color: #cf222e; }
.zm-toast-warning { border-left-color: #9a6700; }
.zm-toast-icon { flex-shrink: 0; font-weight: 700; font-size: 24px; line-height: 1.3; }
.zm-toast-info .zm-toast-icon { color: #3fb950; }
.zm-toast-error .zm-toast-icon { color: #ff7b72; }
.zm-toast-warning .zm-toast-icon { color: #e3b341; }
.zm-toast-text { overflow-wrap: anywhere; }
html.zm-theme-dark .zm-toast {
	background: #ffffff; color: #1f2328;
	box-shadow: 0 12px 44px rgba(0,0,0,.6), 0 0 0 1px rgba(255,255,255,.1);
}
html.zm-theme-dark .zm-toast-info .zm-toast-icon { color: #1a7f37; }
html.zm-theme-dark .zm-toast-error .zm-toast-icon { color: #cf222e; }
html.zm-theme-dark .zm-toast-warning .zm-toast-icon { color: #9a6700; }

.zm-current-banner {
	display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
	background: rgba(26,127,55,.07); border: 1px solid rgba(26,127,55,.22);
	border-radius: 10px; padding: 10px 16px; font-size: 13px; margin-bottom: 4px;
}
.zm-current-banner b { font-weight: 700; }
.zm-current-banner.zm-current-empty {
	background: rgba(110,118,129,.08); border-color: rgba(110,118,129,.2);
}
.zm-current-banner.zm-current-top { margin: 0 0 10px; }

.bt-cols { display: grid; grid-template-columns: 1fr 1fr; column-gap: 44px; }
.bt-col { min-width: 0; }
.bt-col .zm-label { flex: 0 0 170px; }
@media (max-width: 860px) {
	.bt-cols { grid-template-columns: 1fr; }
	.bt-col .zm-label { flex: 0 0 128px; }
}
@media (max-width: 420px) {
	.bt-col .zm-label { flex: 0 0 108px; font-size: 12px; }
}
.bt-current { flex-direction: column; align-items: stretch; gap: 8px; padding: 14px 18px; }
.bt-current-label { font-size: 13px; font-weight: 700; }
.bt-current-cmd {
	background: #0d1117; color: #7ee787;
	font-family: ui-monospace, "SF Mono", "Cascadia Code", Consolas, "Liberation Mono", monospace;
	font-size: 14px; line-height: 1.65;
	border-radius: 8px; padding: 12px 14px;
	white-space: normal; user-select: all;
}
.bt-panel { display: block; max-height: none; min-height: 0; margin-top: 10px; }
.bt-table { width: 100%; table-layout: fixed; border-collapse: collapse; border-spacing: 0; margin: 0; background: transparent; }
.bt-table td { padding: 8px 8px 8px 0; border: 0; border-top: 1px solid rgba(255,255,255,.10); vertical-align: top; background: transparent; color: inherit; white-space: normal; overflow-wrap: anywhere; }
.bt-table tr:first-child td { border-top: 0; }
.bt-td-n { width: 2.4em; color: #8b949e; }
.bt-td-s { width: 6.4em; }
.bt-td-a { width: 9em; text-align: right; padding-right: 0 !important; }
@media (max-width: 760px) {
	.bt-table, .bt-table tbody { display: block; }
	.bt-table tr { display: grid; grid-template-columns: auto 1fr auto; column-gap: 10px; align-items: center; padding: 9px 0; border-top: 1px solid rgba(255,255,255,.10); }
	.bt-table tr:first-child { border-top: 0; }
	.bt-table td { display: block; width: auto; border: 0 !important; padding: 0 !important; }
	.bt-table td.bt-td-c { grid-column: 1 / -1; grid-row: 2; margin-top: 7px; }
}
.bt-cmd { color: #e6edf3; white-space: normal; }
.bt-tok { white-space: nowrap; }
.bt-name { color: #8b949e; margin-bottom: 2px; }
.bt-chip { display: inline-block; min-width: 4.4em; text-align: center; padding: 1px 8px; border-radius: 5px; font-weight: 700; color: #0d1117; }
.bt-chip-ok { background: #3fb950; }
.bt-chip-warn { background: #ffa657; }
.bt-chip-bad { background: #ff7b72; }
.bt-chip-off { background: #8b949e; }
.bt-c-ok { color: #3fb950; font-weight: 700; }
.bt-c-warn { color: #ffa657; font-weight: 700; }
.bt-c-bad { color: #ff7b72; font-weight: 700; }
.bt-c-dim { color: #8b949e; }
.bt-c-white { color: #e6edf3; }
.bt-c-key { color: #e3c04a; font-weight: 700; }
.bt-c-cur { color: #56d4dd; font-weight: 700; }
.bt-input { width: 110px; box-sizing: border-box; }
.cbi-page-actions { display: none !important; }
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/bytetube/style.css'

cat > '/www/luci-static/resources/view/zapret-manager/bytetube.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require poll';
'require rpc';
'require zapret-manager.common as zm';
'require bytetube.common as bt';
'require bytetube.presets as presets';

var callBytetubeInstalled = rpc.declare({ object: 'zapret-manager', method: 'bytetube_installed', expect: {} });
var callBytetubeAction = rpc.declare({ object: 'zapret-manager', method: 'bytetube_action', params: [ 'action' ], expect: {} });

var TABS = [
	{ id: 'main', label: 'ByeTube' },
	{ id: 'strategy', label: 'Стратегия' },
	{ id: 'test', label: 'Тест стратегий' },
	{ id: 'domains', label: 'Домены' }
];

/* ---- домены: по одному в строке ---- */
var DOMAIN_RE = /^[a-z0-9]([a-z0-9._-]*[a-z0-9])?$/;

function normDomain(s) {
	return String(s).trim().toLowerCase()
		.replace(/^[a-z][a-z0-9+.-]*:\/\//, '')
		.replace(/[\/?#].*$/, '')
		.replace(/^\*?\./, '');
}

function parseDomains(text) {
	var list = [], bad = [], seen = {};
	String(text == null ? '' : text).split(/[\s,;]+/).forEach(function(tok) {
		if (!tok) return;
		var d = normDomain(tok);
		if (!d || d.indexOf('.') < 0 || !DOMAIN_RE.test(d)) { bad.push(tok); return; }
		if (!seen[d]) { seen[d] = true; list.push(d); }
	});
	return { list: list, bad: bad };
}

function fill(node, kids) {
	while (node.firstChild) node.removeChild(node.firstChild);
	kids.forEach(function(k) {
		if (k === null || k === undefined || k === '') return;
		node.appendChild(typeof k === 'string' ? document.createTextNode(k) : k);
	});
	return node;
}

function row(label, node) {
	return E('div', { 'class': 'zm-row' }, [ E('span', { 'class': 'zm-label' }, [ label ]), node ]);
}

function tile(label, cls, onclick, title) {
	var attrs = { 'class': 'zm-tile' + (cls ? ' ' + cls : ''), 'click': onclick };
	if (title) attrs.title = title;
	return E('div', attrs, [ label ]);
}

function btn(label, cls, onclick) {
	return E('button', { 'class': 'cbi-button' + (cls ? ' ' + cls : ''), 'click': onclick }, [ label ]);
}

function cmdNodes(text) {
	var out = [];
	String(text).split(' ').forEach(function(tok, i) {
		if (i) out.push(' ');
		out.push(E('span', { 'class': 'bt-tok' }, [ tok ]));
	});
	return out;
}

function hint(text) {
	return E('p', { 'class': 'zm-hint' }, [ text ]);
}

function renderNotInstalled() {
	var wrap = E('div', { 'class': 'zm-wrap' });
	var busy = false;
	var logEl = E('pre', { 'class': 'zm-log' });
	var card = E('div', { 'class': 'zm-card' }, [
		E('h3', {}, [ 'ByeTube' ]),
		E('p', { 'class': 'zm-hint' }, [
			'Обходит блокировку только доменов YouTube (ByeDPI + hev-socks5-tunnel), остальной трафик идёт напрямую. ' +
			'Устанавливает пакеты byedpi и hev-socks5-tunnel, при необходимости заменяет dnsmasq на dnsmasq-full.'
		]),
		E('div', { 'class': 'zm-actions' }, [
			E('button', {
				'class': 'cbi-button cbi-button-positive',
				'click': function() {
					if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
					busy = true;
					zm.toast('Устанавливаем ByeTube (byedpi + hev-socks5-tunnel), может занять пару минут', 'warning');
					callBytetubeAction('install').then(function(res) {
						if (res && res.error) { busy = false; zm.toast(res.error, 'error'); return; }
						if (res && res.started) {
							zm.pollJob('bytetube_install', logEl, function(ok) {
								busy = false;
								zm.toast(ok ? 'ByeTube установлен' : 'Ошибка установки — смотрите журнал', ok ? 'info' : 'error');
								if (ok) location.reload();
							});
						} else {
							busy = false;
						}
					}).catch(function() { busy = false; });
				}
			}, [ 'Установить' ])
		])
	]);
	wrap.appendChild(card);
	wrap.appendChild(logEl);
	return wrap;
}

function renderInstalled(all) {
		var st = all[0] || {};
		var cfg = all[1] || {};
		var tst = all[2] || {};
		var texts = { 'strategies': all[3] || '', 'domains': all[4] || '' };
		var busy = false;
		var activeTab = 'main';
		var running = tst.running === true;
		var wasRunning = running;
		var editors = {};

		var wrap = E('div', { 'class': 'zm-wrap' });
		var tabBar = E('div', { 'class': 'zm-actions', 'style': 'margin-bottom:14px' });
		var panels = {};
		TABS.forEach(function(t) {
			panels[t.id] = E('div', { 'style': t.id === activeTab ? '' : 'display:none' });
		});

		function renderTabBar() {
			fill(tabBar, TABS.map(function(t) {
				return E('button', {
					'class': 'cbi-button' + (t.id === activeTab ? ' cbi-button-positive' : ''),
					'click': function() {
						activeTab = t.id;
						TABS.forEach(function(t2) { panels[t2.id].style.display = t2.id === activeTab ? '' : 'none'; });
						renderTabBar();
					}
				}, [ t.label ]);
			}));
		}

		function guard() {
			if (busy) {
				bt.toast('Дождитесь завершения текущей операции', 'warning');
				return true;
			}
			return false;
		}

		function isWorking() {
			return !!(st.enabled && st.byedpi && st.hev && st.tun && st.nft && st.rule && st.route && st.dns && st.fw);
		}

		var portDirty = false;
		var portInput = E('input', {
			'class': 'cbi-input-text bt-input',
			'type': 'text',
			'value': String(cfg.byedpi_port || 1088),
			'inputmode': 'numeric'
		});
		portInput.addEventListener('input', function() { portDirty = true; });

		var statusCard = E('div', { 'class': 'zm-card' });
		var optionsCard = E('div', { 'class': 'zm-card' });
		var bannerEl = E('div', { 'class': 'zm-current-banner' });
		var presetsCard = E('div', { 'class': 'zm-card' });
		var domainsToggleCard = E('div', { 'class': 'zm-card' });
		var extraDomainsCard = E('div', { 'class': 'zm-card' });
		var removeLogEl = E('pre', { 'class': 'zm-log' });
		var removeBusy = false;

		function removeByeTube() {
			if (removeBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
			removeBusy = true;
			zm.toast('Удаляем ByeTube', 'warning');
			callBytetubeAction('purge').then(function(res) {
				if (res && res.error) { removeBusy = false; zm.toast(res.error, 'error'); return; }
				if (res && res.started) {
					zm.pollJob('bytetube_remove', removeLogEl, function(ok) {
						removeBusy = false;
						zm.toast(ok ? 'ByeTube удалён' : 'Ошибка удаления — смотрите журнал', ok ? 'info' : 'error');
						if (ok) location.reload();
					});
				} else {
					removeBusy = false;
				}
			}).catch(function() { removeBusy = false; });
		}

		function refreshState() {
			return Promise.all([ bt.status(), bt.config() ]).then(function(r) {
				if (r[0] && !r[0].error) st = r[0];
				if (r[1] && !r[1].error) cfg = r[1];
				renderMain();
				renderStrategy();
				renderDomainsToggle();
				renderExtraDomains();
				renderResults(resultsText);
			});
		}

		function applyConfig(pairs, okMsg) {
			if (guard()) return;
			busy = true;
			bt.toast('Применяем настройки', 'warning');
			return bt.configSet(pairs).then(function(res) {
				busy = false;
				if (res.error) {
					bt.toast(res.error, 'error');
					return null;
				}
				bt.toast(okMsg || 'Настройки применены', 'info');
				return refreshState();
			});
		}

		function serviceAction(action, okMsg) {
			if (guard()) return;
			busy = true;
			bt.toast('Выполняем', 'warning');
			bt.service(action).then(function(res) {
				busy = false;
				if (res.error) { bt.toast(res.error, 'error'); return; }
				bt.toast(okMsg, 'info');
				refreshState();
			});
		}

		function renderMain() {
			var items = [];
			items.push(row('Служба', isWorking()
				? bt.badge(true, 'работает', '')
				: bt.badge(false, '', st.enabled ? 'запущена не полностью' : 'выключена')));
			if (st.binaries === false)
				items.push(row('Пакеты', bt.badge(false, '', 'не найден byedpi или hev-socks5-tunnel')));
			items.push(row('ByeDPI (ciadpi)', bt.badge(st.byedpi, 'запущен', 'не запущен')));
			items.push(row('hev-socks5-tunnel', bt.badge(st.hev, 'запущен', 'не запущен')));
			items.push(row('Интерфейс ytb0', bt.badge(st.tun, 'поднят', 'нет')));
			items.push(row('Маркировка nftables', bt.badge(st.nft, 'активна', 'нет')));
			items.push(row('Policy routing', bt.badge(st.rule && st.route, 'активен', 'нет')));
			items.push(row('dnsmasq → nftset', st.dnsmasq_nftset === false
				? bt.badge(false, '', 'нужен dnsmasq-full')
				: bt.badge(st.dns, 'домены загружены', 'нет')));
			items.push(row('Firewall forward', bt.badge(st.fw, 'разрешён', 'нет')));
			items.push(row('IP в наборах', E('span', {}, [ 'IPv4: ' + (st.ips4 || 0) + (st.ipv6 ? ', IPv6: ' + (st.ips6 || 0) : '') ])));
			var half = Math.ceil(items.length / 2);
			var kids = [ E('div', { 'class': 'bt-cols' }, [
				E('div', { 'class': 'bt-col' }, items.slice(0, half)),
				E('div', { 'class': 'bt-col' }, items.slice(half))
			]) ];
			kids.push(E('div', { 'class': 'zm-actions' }, [
				cfg.enabled
					? btn('Выключить', 'cbi-button-remove', function() {
						applyConfig({ enabled: 0 }, 'ByeTube выключен');
					})
					: btn('Включить', 'cbi-button-positive', function() {
						applyConfig({ enabled: 1 }, 'ByeTube включён');
					}),
				btn('Перезапустить', 'cbi-button-apply', function() { serviceAction('restart', 'Служба перезапущена'); }),
				btn('Очистить наборы IP', '', function() {
					if (guard()) return;
					bt.flush().then(function() {
						bt.toast('Наборы очищены. Перезапустите браузер или обновите DNS-кэш на клиентах.', 'info');
						refreshState();
					});
				}),
				btn('Удалить', 'cbi-button-remove', removeByeTube)
			]));
			fill(statusCard, kids);

			var quic = cfg.quic || 'block';
			if (!portDirty) portInput.value = String(cfg.byedpi_port || 1088);

			fill(optionsCard, [
				E('h3', {}, [ 'Настройки' ]),
				row('QUIC (UDP/443)', E('div', { 'class': 'zm-grid' }, [
					tile('Блокировать', quic === 'block' ? 'zm-active' : '', function() {
						if (quic !== 'block') applyConfig({ quic: 'block' }, 'QUIC блокируется');
					}),
					tile('Через прокси', quic === 'proxy' ? 'zm-active' : '', function() {
						if (quic !== 'proxy') applyConfig({ quic: 'proxy' }, 'QUIC идёт через прокси');
					})
				])),
				hint('Блокировка QUIC заставляет клиента быстро откатиться на TCP, который обрабатывает ByeDPI (рекомендуется).'),
				row('IPv6', E('div', { 'class': 'zm-grid' }, [
					tile(cfg.ipv6 ? 'IPv6 включён' : 'IPv6 выключен', cfg.ipv6 ? 'zm-active' : 'zm-tile-off', function() {
						applyConfig({ ipv6: cfg.ipv6 ? 0 : 1 }, cfg.ipv6 ? 'IPv6 выключен' : 'IPv6 включён');
					})
				])),
				row('Порт SOCKS5 ByeDPI', E('div', { 'class': 'zm-actions', 'style': 'margin:0' }, [
					portInput,
					btn('Сохранить', 'cbi-button-positive', function() {
						var v = String(portInput.value).trim();
						if (!/^\d+$/.test(v) || +v < 1 || +v > 65535) {
							bt.toast('Порт должен быть числом от 1 до 65535', 'error');
							return;
						}
						portDirty = false;
						applyConfig({ byedpi_port: v }, 'Порт сохранён');
					})
				])),
				hint('Локальный порт 127.0.0.1, отдельный экземпляр — штатная служба byedpi не затрагивается.')
			]);
		}

		function currentPreset() {
			return presets.find(cfg.byedpi_opts);
		}

		function setStrategy(opts, label) {
			if (guard()) return;
			busy = true;
			bt.toast('Применяем стратегию', 'warning');
			bt.setStrategy(opts).then(function(res) {
				busy = false;
				if (res.error) { bt.toast(res.error, 'error'); return; }
				bt.toast((label || 'Стратегия') + ' применена', 'info');
				refreshState();
			});
		}

		var customTa = E('textarea', {
			'class': 'zm-config-editor',
			'spellcheck': 'false',
			'wrap': 'soft',
			'placeholder': 'Параметры ciadpi одной строкой',
			'style': 'min-height:130px;white-space:pre-wrap'
		}, [ '' ]);

		function renderStrategy() {
			var cur = currentPreset();
			fill(bannerEl, cfg.byedpi_opts
				? [ E('div', { 'class': 'bt-current-label' }, [ 'Сейчас применено' ]), E('div', { 'class': 'bt-current-cmd' }, cmdNodes(cfg.byedpi_opts)) ]
				: [ E('span', {}, [ 'Стратегия ещё не выбрана' ]) ]);
			bannerEl.className = 'zm-current-banner bt-current' + (cfg.byedpi_opts ? '' : ' zm-current-empty');

			fill(presetsCard, [
				E('h3', {}, [ 'Готовые стратегии' ]),
				E('div', { 'class': 'zm-grid' }, presets.list.map(function(p) {
					return tile(p.label || p.name, cur && cur.id === p.id ? 'zm-active' : '', function() {
						setStrategy(p.opts, p.label || p.name);
					}, p.name + '\n' + p.opts);
				})),
				hint('Стратегия зависит от провайдера — лучшую под вашего провайдера найдёт вкладка «Тест стратегий».')
			]);
		}

		var customCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, [ 'Своя стратегия' ]),
			hint('Параметры командной строки ciadpi одной строкой. Кавычки (-n "google.com") служба обрабатывает сама.'),
			customTa,
			E('div', { 'class': 'zm-actions' }, [
				btn('Применить', 'cbi-button-positive', function() {
					var v = presets.norm(customTa.value);
					if (!v) { bt.toast('Стратегия не может быть пустой', 'error'); return; }
					setStrategy(v, 'Своя стратегия');
				}),
				btn('Подставить текущую', '', function() { customTa.value = cfg.byedpi_opts || ''; })
			])
		]);

		/* ---- редакторы списков теста: strategies / domains ---- */
		function makeEditor(o) {
			var ta = E('textarea', {
				'class': 'zm-config-editor',
				'spellcheck': 'false',
				'wrap': o.wrap ? 'soft' : 'off',
				'style': 'min-height:' + o.height + 'px;' + (o.wrap ? 'white-space:pre-wrap' : '')
			}, [ texts[o.kind] ]);
			var meta = E('p', { 'class': 'zm-hint' });
			var ed = { ta: ta, locked: false };
			var saveBtn = btn('Сохранить', 'cbi-button-positive', onSave);
			var resetBtn = btn('Сбросить к встроенному', '', onReset);

			ed.node = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, [ o.title ]),
				hint(o.hint),
				ta,
				meta,
				E('div', { 'class': 'zm-actions' }, [ saveBtn, resetBtn ])
			]);

			ed.sync = function() {
				var info = o.info();
				fill(meta, [ o.meta(info) ]);
				ta.disabled = ed.locked;
				saveBtn.disabled = ed.locked;
				resetBtn.disabled = ed.locked || !info.custom;
			};

			function reload() {
				return bt.listGet(o.kind).then(function(t) {
					texts[o.kind] = t;
					ta.value = t;
				});
			}

			function onSave() {
				if (!ta.value.trim()) {
					bt.toast('Список пуст. Чтобы вернуть встроенный, нажмите «Сбросить к встроенному».', 'error');
					return;
				}
				bt.listSet(o.kind, ta.value).then(function(res) {
					if (res.error) { bt.toast(res.error, 'error'); return; }
					o.apply(res);
					reload().then(function() {
						ed.sync();
						bt.toast('Список сохранён', 'info');
					});
				});
			}

			function onReset() {
				if (!confirm('Вернуть встроенный список? Ваши правки будут удалены.')) return;
				bt.listReset(o.kind).then(function(res) {
					if (res.error) { bt.toast(res.error, 'error'); return; }
					o.apply(res);
					reload().then(function() {
						ed.sync();
						bt.toast('Возвращён встроенный список', 'info');
					});
				});
			}

			return ed;
		}

		function listMeta(unit) {
			return function(info) {
				return (info.custom ? 'Свой список' : 'Встроенный список') + ' · ' + info.count + ' ' + unit;
			};
		}

		editors['strategies'] = makeEditor({
			kind: 'strategies', title: 'Стратегии для теста', height: 260, wrap: true,
			hint: 'Одна стратегия (параметры ciadpi) в строке.',
			info: function() { return { count: tst.strategies || 0, custom: !!tst.strategies_custom }; },
			meta: listMeta('стратегий'),
			apply: function(res) { tst.strategies = res.count; tst.strategies_custom = res.custom; }
		});
		editors['domains'] = makeEditor({
			kind: 'domains', title: 'Домены для проверки', height: 220, wrap: false,
			hint: 'Один домен в строке; можно вставлять ссылки. Нужны только для проверки доступности при тесте и на маршрутизацию не влияют.',
			info: function() { return { count: tst.domains || 0, custom: !!tst.domains_custom }; },
			meta: listMeta('доменов'),
			apply: function(res) { tst.domains = res.count; tst.domains_custom = res.custom; }
		});

		function syncEditors() {
			Object.keys(editors).forEach(function(k) { editors[k].sync(); });
		}

		/* ---- вкладка «Домены»: встроенный список + свои дополнительные ---- */
		function renderDomainsToggle() {
			var on = !!cfg.default_domains;
			fill(domainsToggleCard, [
				E('h3', {}, [ 'Домены YouTube' ]),
				row('Использовать встроенный список', E('div', { 'class': 'zm-grid' }, [
					tile(on ? 'Список используется' : 'Список выключен', on ? 'zm-active' : 'zm-tile-off', function() {
						applyConfig({ default_domains: on ? 0 : 1 }, on ? 'Список выключен' : 'Список включён');
					})
				])),
				hint('Сервисы Google часто делят IP-адреса, поэтому часть трафика Google (не только YouTube) тоже пойдёт через обход, а QUIC (UDP/443) к этим адресам будет блокироваться.')
			]);
		}

		var extraTa = E('textarea', {
			'class': 'zm-config-editor',
			'spellcheck': 'false',
			'wrap': 'off',
			'placeholder': 'example.com\nanother.org',
			'style': 'min-height:220px'
		}, [ (cfg.domain || []).join('\n') ]);
		var extraDirty = false;
		extraTa.addEventListener('input', function() { extraDirty = true; });

		function renderExtraDomains() {
			if (!extraDirty) extraTa.value = (cfg.domain || []).join('\n');
			fill(extraDomainsCard, [
				E('h3', {}, [ 'Дополнительные домены' ]),
				hint('По одному домену в строке; поддомены подхватываются автоматически. Добавляются к встроенному списку. Сейчас доменов: ' + (cfg.domain || []).length + '.'),
				extraTa,
				E('div', { 'class': 'zm-actions' }, [
					btn('Сохранить', 'cbi-button-positive', function() {
						var r = parseDomains(extraTa.value);
						if (r.bad.length) {
							bt.toast('Некорректный домен: ' + r.bad[0], 'error');
							return;
						}
						extraDirty = false;
						applyConfig({ domain: r.list }, 'Домены сохранены');
					})
				])
			]);
		}

		var testActions = E('div', { 'class': 'zm-actions' });
		var testLog = E('pre', { 'class': 'zm-log' });
		var testResults = E('div', { 'class': 'zm-card' });

		function nameOf(opts) {
			var p = presets.find(opts);
			return p ? p.name : null;
		}

		function renderTestActions() {
			var kids = [];
			if (tst.curl === false) {
				kids.push(bt.badge(false, '', 'не установлен curl'));
				kids.push(hint('Нужен для теста: apk add curl (или opkg install curl).'));
			} else if (running) {
				kids.push(bt.badge(true, 'тест выполняется', ''));
				kids.push(btn('Остановить тест', 'cbi-button-remove', doStop));
			} else {
				kids.push(btn('Запустить тест', 'cbi-button-positive', doStart));
				if (tst.has_results) kids.push(btn('Очистить результаты', '', doClear));
			}
			fill(testActions, kids);
			editors['strategies'].locked = running;
			editors['domains'].locked = running;
			syncEditors();
		}

		var resultsText = '';

		function renderResults(text) {
			resultsText = text || '';
			var res = bt.parseResults(resultsText);
			if (!res.rows.length) {
				fill(testResults, [ E('h3', {}, [ 'Результаты' ]), hint(running ? 'Тест выполняется…' : 'Пока нет результатов — запустите тест.') ]);
				return;
			}
			var controlOk = res.control ? res.control.ok : null;
			var curClean = presets.clean(cfg.byedpi_opts);

			var rows = res.rows.map(function(r, i) {
				var p = presets.find(r.opts);
				var isCur = presets.clean(r.opts) === curClean;
				var body = [];
				if (p || isCur) {
					var nm = E('div', { 'class': 'bt-name' }, [ p ? p.name : '' ]);
					if (isCur) nm.appendChild(bt.span('bt-c-cur', (p ? '  ' : '') + '(текущая)'));
					body.push(nm);
				}
				body.push(E('div', { 'class': 'bt-cmd' }, cmdNodes(r.opts)));
				return E('tr', {}, [
					E('td', { 'class': 'bt-td-n' }, [ String(i + 1) ]),
					E('td', { 'class': 'bt-td-s' }, [ E('span', { 'class': bt.chipClass(r.ok, r.total, controlOk) }, [ r.ok + '/' + r.total ]) ]),
					E('td', { 'class': 'bt-td-c' }, body),
					E('td', { 'class': 'bt-td-a' }, [
						isCur ? '' : btn('Применить', 'cbi-button-apply', function() {
							var q = 'Применить стратегию и перезапустить службу?\n\n' + (p ? p.name + '\n' : '') + r.opts;
							if (confirm(q)) setStrategy(r.opts, p ? (p.label || p.name) : 'Стратегия');
						})
					])
				]);
			});

			fill(testResults, [
				E('h3', {}, [ 'Результаты' ]),
				E('div', { 'class': 'zm-log zm-show bt-panel' }, [
					E('table', { 'class': 'bt-table' }, [ E('tbody', {}, rows) ])
				])
			]);
		}

		function refreshResults() {
			return bt.testResults().then(renderResults);
		}

		function refreshLog() {
			return bt.testLog().then(function(t) {
				if (t) testLog.classList.add('zm-show');
				else testLog.classList.remove('zm-show');
				bt.renderTestLog(testLog, t, nameOf);
			});
		}

		function doStart() {
			bt.testStart().then(function(res) {
				if (res.error) { bt.toast(res.error, 'error'); return; }
				running = true;
				wasRunning = true;
				tst.has_results = false;
				renderResults('');
				renderTestActions();
				refreshLog();
				bt.toast('Тест запущен', 'info');
			});
		}

		function doStop() {
			bt.testStop().then(function(res) {
				if (res.error) { bt.toast(res.error, 'error'); return; }
				bt.toast('Останавливаю тест…', 'warning');
			});
		}

		function doClear() {
			bt.testClear().then(function(res) {
				if (res.error) { bt.toast(res.error, 'error'); return; }
				tst.has_results = false;
				renderTestActions();
				renderResults('');
				testLog.classList.remove('zm-show');
			});
		}

		function tick() {
			return bt.testStatus().then(function(s) {
				if (!s || s.error) return;
				tst = s;
				running = s.running === true;
				renderTestActions();
				if (running || wasRunning) refreshLog();
				if (wasRunning && !running) {
					wasRunning = false;
					refreshResults();
					bt.toast('Тест завершён', 'info');
				}
			});
		}

		var testCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, [ 'Тест стратегий ByeDPI' ]),
			hint('Каждая стратегия запускается во временном экземпляре ByeDPI на отдельном порту, а домены проверяются через него. Основной сервис и трафик клиентов не затрагиваются, настройки не меняются. Сначала делается контрольный замер без обхода. Тест идёт в фоне — вкладку можно закрыть.'),
			testActions,
			testLog
		]);

		panels['main'].appendChild(statusCard);
		panels['main'].appendChild(optionsCard);

		panels['strategy'].appendChild(bannerEl);
		panels['strategy'].appendChild(presetsCard);
		panels['strategy'].appendChild(customCard);

		panels['test'].appendChild(testCard);
		panels['test'].appendChild(testResults);
		panels['test'].appendChild(editors['strategies'].node);
		panels['test'].appendChild(editors['domains'].node);

		panels['domains'].appendChild(domainsToggleCard);
		panels['domains'].appendChild(extraDomainsCard);

		wrap.appendChild(tabBar);
		TABS.forEach(function(t) { wrap.appendChild(panels[t.id]); });
		wrap.appendChild(removeLogEl);

		renderTabBar();
		renderMain();
		renderStrategy();
		renderDomainsToggle();
		renderExtraDomains();
		renderTestActions();
		refreshLog();
		if (running) renderResults('');
		else refreshResults();

		poll.add(function() {
			return Promise.all([ refreshState(), tick() ]);
		}, 5);

		return wrap;
}

return view.extend({
	load: function() {
		return callBytetubeInstalled().catch(function() { return { installed: false }; }).then(function(inst) {
			if (!inst || inst.installed !== true) return { installed: false };
			bt.injectCss();
			return Promise.all([
				bt.status(),
				bt.config(),
				bt.testStatus(),
				bt.listGet('strategies'),
				bt.listGet('domains')
			]).then(function(all) {
				return { installed: true, all: all };
			});
		});
	},

	render: function(result) {
		zm.injectCss();
		if (!result || result.installed !== true) return renderNotInstalled();
		return renderInstalled(result.all);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/bytetube.js'

rm -f /tmp/luci-indexcache* /tmp/luci-modulecache/* 2>/dev/null || true
/etc/init.d/rpcd reload >/dev/null 2>&1 || /etc/init.d/rpcd restart >/dev/null 2>&1
if grep -qx 'steer-spec' /etc/zm-steer/owned 2>/dev/null && /etc/init.d/steer enabled 2>/dev/null; then
	/etc/init.d/steer reload >/dev/null 2>&1
fi

if command -v apk >/dev/null 2>&1; then PM="apk"; INSTALL="apk add"
else PM="opkg"; INSTALL="opkg install"; fi
command -v curl >/dev/null 2>&1 || $INSTALL curl >&2 || true
command -v unzip >/dev/null 2>&1 || $INSTALL unzip >&2 || true


mkdir -p /www/zm
chmod 0755 /www/zm
cat > '/www/zm/app.js' << 'ZM_INSTALLER_EOF'
/*
 * Zapret Manager — Web UI
 * Самостоятельный веб-интерфейс поверх того же rpcd-бэкенда (ubus: zapret-manager).
 * Страницы LuCI (view/zapret-manager/*.js) исполняются как есть — здесь лишь
 * лёгкая совместимая прослойка: E(), rpc, view, fs, uci, poll, ui, baseclass.
 */
(function () {
'use strict';

var BUILD = '__ZMW_BUILD__';
var RES = '/luci-static/resources/';
var NULL_SID = '00000000000000000000000000000000';
var K_SID = 'zmw.sid', K_THEME = 'zmw.theme', K_USER = 'zmw.user', K_NOTE = 'zmw.note';

/* ───────────────────────── storage ───────────────────────── */

function store(kind) {
	try { return kind === 'local' ? window.localStorage : window.sessionStorage; } catch (e) { return null; }
}
function sget(k) {
	var v = null;
	try { var s = store('session'); v = s && s.getItem(k); } catch (e) {}
	if (v) return v;
	try { var l = store('local'); v = l && l.getItem(k); } catch (e) {}
	return v || null;
}
function sset(k, v, persist) {
	['session', 'local'].forEach(function (kind) {
		try {
			var s = store(kind); if (!s) return;
			if (v == null || (kind === 'local') !== !!persist) s.removeItem(k);
			else s.setItem(k, v);
		} catch (e) {}
	});
}

var sid = sget(K_SID);

/* ───────────────────────── DOM helpers (LuCI-совместимые) ───────────────────────── */

function isNode(x) { return x != null && typeof x === 'object' && typeof x.nodeType === 'number'; }
function isObj(x) { return x != null && typeof x === 'object' && !Array.isArray(x) && !isNode(x); }
function typeOf(x) { return x === null ? 'null' : Array.isArray(x) ? 'array' : typeof x; }

function domAttr(node, attrs) {
	for (var k in attrs) {
		if (!Object.prototype.hasOwnProperty.call(attrs, k)) continue;
		var v = attrs[k];
		if (v == null) continue;
		if (typeof v === 'function') node.addEventListener(k, v);
		else if (typeof v === 'object') node.setAttribute(k, JSON.stringify(v));
		else node.setAttribute(k, v);
	}
}

function domAppend(node, ch) {
	if (Array.isArray(ch)) {
		for (var i = 0; i < ch.length; i++) {
			var c = ch[i];
			if (isNode(c)) node.appendChild(c);
			else if (Array.isArray(c)) domAppend(node, c);
			else if (c != null) node.appendChild(document.createTextNode(String(c)));
		}
	}
	else if (typeof ch === 'function') domAppend(node, ch(node));
	else if (isNode(ch)) node.appendChild(ch);
	else if (ch != null) node.innerHTML = String(ch);
}

function E(tag, attrs, data) {
	var node;
	if (isNode(tag)) node = tag;
	else if (Array.isArray(tag)) {
		node = document.createDocumentFragment();
		domAppend(node, tag);
		return node;
	}
	else if (typeof tag === 'string' && tag.charAt(0) === '<') {
		var t = document.createElement('template');
		t.innerHTML = tag.trim();
		node = t.content.firstChild;
	}
	else node = document.createElement(tag);
	if (attrs != null && !isObj(attrs)) { data = attrs; attrs = null; }
	if (attrs) domAttr(node, attrs);
	if (data !== undefined) domAppend(node, data);
	return node;
}

function tr(s) { return s; }

var dom = {
	elem: isNode,
	create: E,
	attr: function (n, k, v) { if (isObj(k)) domAttr(n, k); else { var o = {}; o[k] = v; domAttr(n, o); } },
	append: domAppend,
	content: function (n, ch) { while (n.firstChild) n.removeChild(n.firstChild); domAppend(n, ch); return n; },
	parse: function (html) { return E(html); }
};

/* ───────────────────────── Классы ───────────────────────── */

function extend(Base, props) {
	var C = function () {
		if (typeof this.__init__ === 'function') return this.__init__.apply(this, arguments);
	};
	C.prototype = Object.create(Base.prototype);
	C.prototype.constructor = C;
	for (var k in props) if (Object.prototype.hasOwnProperty.call(props, k)) C.prototype[k] = props[k];
	C.prototype.super = function (name, args) {
		var fn = Base.prototype[name];
		return typeof fn === 'function' ? fn.apply(this, args || []) : undefined;
	};
	C.extend = function (p) { return extend(C, p); };
	C.__zmClass = true;
	return C;
}
function RootClass() {}
var baseclass = { extend: function (p) { return extend(RootClass, p); } };
baseclass.singleton = function (p) { return new (baseclass.extend(p))(); };

/* ───────────────────────── ubus JSON-RPC ───────────────────────── */

var UBUS_ERR = [ 'OK', 'неверная команда', 'неверный аргумент', 'метод не найден', 'объект не найден',
	'нет данных', 'доступ запрещён', 'таймаут', 'не поддерживается', 'неизвестная ошибка', 'нет соединения' ];

var rpcSeq = 0;

function ubus(object, method, params, useSid) {
	// Запрос к роутеру не должен висеть вечно: через 60 с — ошибка вместо вечного «крутится».
	var ac = window.AbortController ? new AbortController() : null;
	var tm = ac ? setTimeout(function () { ac.abort(); }, 60000) : 0;
	return fetch('/ubus', {
		method: 'POST',
		signal: ac ? ac.signal : undefined,
		headers: { 'Content-Type': 'application/json' },
		cache: 'no-store',
		credentials: 'omit',
		body: JSON.stringify({
			jsonrpc: '2.0', id: ++rpcSeq, method: 'call',
			params: [ useSid || sid || NULL_SID, object, method, params || {} ]
		})
	}).then(function (r) {
		clearTimeout(tm);
		if (r.status === 404) {
			var e404 = new Error('На роутере не отвечает /ubus — нужен пакет uhttpd-mod-ubus.');
			e404.noUbus = true;
			throw e404;
		}
		return r.json().catch(function () { throw new Error('Некорректный ответ роутера (HTTP ' + r.status + ')'); });
	}).then(function (msg) {
		if (msg && msg.error) {
			var e = new Error(msg.error.message || 'Ошибка RPC');
			e.rpcCode = msg.error.code;
			if (msg.error.code === -32002 && !useSid) { e.authLost = true; authLost(); }
			throw e;
		}
		if (!msg || !Array.isArray(msg.result)) throw new Error('Некорректный ответ ubus');
		// Любое действие в панели (не опрос состояния) — через секунду обновляем точки в меню,
		// чтобы меню, дашборд и страницы показывали одно и то же, а не ждали 15 секунд.
		if (object === 'zapret-manager' && !/(status|info|health|list|tail|log|latest|version|export|get)/.test(method)) scheduleShellRefresh();
		return msg.result;
	}, function (err) {
		clearTimeout(tm);
		if (err && err.name === 'AbortError') throw new Error('роутер не ответил за 60 секунд');
		throw err;
	});
}

function declare(o) {
	return function () {
		var args = arguments, params = {};
		(o.params || []).forEach(function (p, i) { if (args[i] !== undefined) params[p] = args[i]; });
		return ubus(o.object, o.method, params).then(function (res) {
			var code = res[0];
			var ret = res.length > 1 ? res[1] : res[0];
			if (code !== 0) {
				var text = 'ubus ' + o.object + '.' + o.method + ': ' + (UBUS_ERR[code] || ('код ' + code));
				if (code === 6) toast('Недостаточно прав: ' + o.object + '.' + o.method, 'error');
				if (!o.expect) return code;
				var k0 = Object.keys(o.expect)[0];
				if (k0 === undefined || isObj(o.expect[k0])) return { error: text };
				return o.expect[k0];
			}
			if (o.expect) {
				for (var key in o.expect) {
					if (ret != null && key !== '') ret = ret[key];
					if (ret == null || typeOf(ret) !== typeOf(o.expect[key])) ret = o.expect[key];
					break;
				}
			}
			if (typeof o.filter === 'function') ret = o.filter(ret, params);
			return ret;
		});
	};
}

var rpc = { declare: declare, getSessionID: function () { return sid; }, setSessionID: function (s) { sid = s; } };

/* ───────────────────────── fs / uci / poll / ui ───────────────────────── */

function fsCall(method, params, pick) {
	return ubus('file', method, params).then(function (res) {
		if (res[0] !== 0) throw new Error((UBUS_ERR[res[0]] || ('код ' + res[0])) + ' (' + (params.path || params.command || method) + ')');
		var r = res[1] || {};
		return pick ? r[pick] : r;
	});
}

var fs = {
	exec: function (command, params, env) {
		var p = { command: command };
		if (Array.isArray(params)) p.params = params;
		if (isObj(env)) p.env = env;
		return fsCall('exec', p);
	},
	exec_direct: function (command, params) {
		return fs.exec(command, params).then(function (r) { return r.stdout || ''; });
	},
	read: function (path) { return fsCall('read', { path: path }, 'data'); },
	read_direct: function (path) { return fs.read(path); },
	write: function (path, data, mode) { return fsCall('write', { path: path, data: data == null ? '' : String(data), mode: mode }); },
	stat: function (path) { return fsCall('stat', { path: path }); },
	list: function (path) { return fsCall('list', { path: path }, 'entries'); },
	remove: function (path) { return fsCall('remove', { path: path }); }
};

var uciValues = {}, uciChanges = {};
var uci = {
	load: function (confs) {
		var list = Array.isArray(confs) ? confs : [ confs ];
		return Promise.all(list.map(function (c) {
			return ubus('uci', 'get', { config: c }).then(function (res) {
				uciValues[c] = (res[0] === 0 && res[1] && res[1].values) || {};
				return c;
			});
		}));
	},
	unload: function (confs) {
		(Array.isArray(confs) ? confs : [ confs ]).forEach(function (c) { delete uciValues[c]; delete uciChanges[c]; });
	},
	get: function (conf, sec, opt) {
		var ch = uciChanges[conf] && uciChanges[conf][sec];
		if (opt == null) {
			var base = uciValues[conf] && uciValues[conf][sec];
			if (!base && !ch) return null;
			var o = {}, k;
			for (k in base) o[k] = base[k];
			for (k in ch) { if (ch[k] === null) delete o[k]; else o[k] = ch[k]; }
			return o;
		}
		if (ch && Object.prototype.hasOwnProperty.call(ch, opt)) return ch[opt] === null ? null : ch[opt];
		var s = uciValues[conf] && uciValues[conf][sec];
		return s && s[opt] != null ? s[opt] : null;
	},
	get_first: function (conf, type, opt) {
		var vals = uciValues[conf] || {};
		for (var s in vals) if (!type || vals[s]['.type'] === type) return uci.get(conf, s, opt);
		return null;
	},
	set: function (conf, sec, opt, val) {
		uciChanges[conf] = uciChanges[conf] || {};
		uciChanges[conf][sec] = uciChanges[conf][sec] || {};
		uciChanges[conf][sec][opt] = (val == null || val === '') ? null : val;
	},
	unset: function (conf, sec, opt) { uci.set(conf, sec, opt, null); },
	sections: function (conf, type, cb) {
		var vals = uciValues[conf] || {}, out = [];
		Object.keys(vals).forEach(function (s) {
			if (!type || vals[s]['.type'] === type) { out.push(vals[s]); if (cb) cb(vals[s], s); }
		});
		return out;
	},
	changes: function () { return Promise.resolve(uciChanges); },
	save: function () {
		var jobs = [];
		Object.keys(uciChanges).forEach(function (conf) {
			Object.keys(uciChanges[conf]).forEach(function (sec) {
				var ch = uciChanges[conf][sec], sets = {}, dels = [], hasSet = false;
				Object.keys(ch).forEach(function (k) {
					if (ch[k] === null) dels.push(k); else { sets[k] = ch[k]; hasSet = true; }
				});
				if (hasSet) jobs.push(ubus('uci', 'set', { config: conf, section: sec, values: sets }));
				if (dels.length) jobs.push(ubus('uci', 'delete', { config: conf, section: sec, options: dels }));
			});
		});
		var confs = Object.keys(uciChanges);
		uciChanges = {};
		return Promise.all(jobs).then(function () { return confs.length ? uci.load(confs) : []; });
	},
	apply: function () {
		return uci.save().then(function () { return ubus('uci', 'apply', { rollback: false }); });
	}
};

var pollJobs = [], pollTimer = null, pollTickN = 0;
function pollEnsure() {
	if (pollTimer) return;
	pollTimer = setInterval(function () {
		pollTickN++;
		if (document.hidden) return;
		pollJobs.forEach(function (j) {
			if (j.busy || pollTickN % j.interval !== 0) return;
			j.busy = true;
			Promise.resolve().then(j.fn).catch(function () {}).then(function () { j.busy = false; });
		});
	}, 1000);
}
var poll = {
	add: function (fn, interval) {
		pollJobs.push({ fn: fn, interval: Math.max(1, +interval || 5), busy: false });
		pollEnsure();
		return true;
	},
	remove: function (fn) {
		var n = pollJobs.length;
		pollJobs = pollJobs.filter(function (j) { return j.fn !== fn; });
		return n !== pollJobs.length;
	},
	start: function () { pollEnsure(); return true; },
	stop: function () { return true; },
	active: function () { return pollJobs.length > 0; },
	_reset: function () { pollJobs = []; }
};

var modalEl = null;
var ui = {
	changes: { setIndicator: function () {}, renderChangeIndicator: function () {}, init: function () {} },
	addNotification: function (title, content, cls) {
		var txt = (title ? title + ': ' : '') + (isNode(content) ? content.textContent : (content || ''));
		toast(txt, /danger|error/.test(cls || '') ? 'error' : (/warning/.test(cls || '') ? 'warning' : 'info'));
		return null;
	},
	showModal: function (title, children) {
		ui.hideModal();
		modalEl = E('div', { 'class': 'zmw-modal-wrap' }, [
			E('div', { 'class': 'zmw-modal' }, [ title ? E('h3', {}, [ title ]) : null, E('div', {}, children) ])
		]);
		document.body.appendChild(modalEl);
		requestAnimationFrame(function () { modalEl && modalEl.classList.add('zmw-in'); });
		return modalEl;
	},
	hideModal: function () { if (modalEl) { modalEl.remove(); modalEl = null; } },
	createHandlerFn: function (ctx, fn) {
		var args = [].slice.call(arguments, 2);
		if (typeof fn === 'string') fn = ctx[fn];
		return function (ev) { return fn.apply(ctx, args.concat([ ev ])); };
	},
	awaitReconnect: function () { setTimeout(function () { location.reload(); }, 5000); }
};

/* ───────────────────────── view ───────────────────────── */

var ViewBase = extend(RootClass, {
	load: function () {},
	render: function () {},
	handleSave: null,
	handleSaveApply: null,
	handleReset: null,
	addFooter: function () { return E('div'); }
});
var viewMod = { extend: function (p) { return ViewBase.extend(p); } };

/* ───────────────────────── L ───────────────────────── */

var L = {
	env: { resource: RES.replace(/\/$/, ''), sessionid: sid },
	resource: function () { return RES + [].slice.call(arguments).join('/'); },
	url: function () {
		var p = [].slice.call(arguments).join('/').replace(/^\/+/, '');
		if (/(^|\/)logout$/.test(p)) return '/?logout=1' + location.hash;
		return '/cgi-bin/luci/' + p;
	},
	bind: function (fn, self) { var a = [].slice.call(arguments, 2); return function () { return fn.apply(self, a.concat([].slice.call(arguments))); }; },
	isObject: isObj,
	toArray: function (x) { return x == null ? [] : Array.isArray(x) ? x : [ x ]; },
	resolveDefault: function (p, d) { return Promise.resolve(p).catch(function () { return d; }); },
	sortedKeys: function (o) { return Object.keys(o || {}).sort(); },
	hasSystemFeature: function () { return false; },
	raise: function (t, m) { var e = new Error(m || t); e.name = t; throw e; },
	error: function (t, m) { L.raise(t, m); },
	dom: dom, ui: ui, Poll: poll, Class: baseclass,
	require: function (n) { return requireModule(n); }
};
window.L = L;
window.E = E;
window._ = tr;

/* ───────────────────────── Загрузчик модулей ───────────────────────── */

var BUILTIN = { baseclass: baseclass, rpc: rpc, ui: ui, view: viewMod, fs: fs, uci: uci, poll: poll, dom: dom };
var srcCache = {}, modCache = {};

function modUrl(name) { return RES + name.replace(/\./g, '/') + '.js'; }

function fetchSrc(name) {
	if (!srcCache[name]) {
		srcCache[name] = fetch(modUrl(name) + '?v=' + BUILD, { cache: 'no-cache' }).then(function (r) {
			if (!r.ok) throw new Error('Не удалось загрузить ' + name + ' (HTTP ' + r.status + ')');
			return r.text();
		});
		srcCache[name].catch(function () { delete srcCache[name]; });
	}
	return srcCache[name];
}

/* Точечные правки текста: в Web UI нет «выхода из LuCI» и меню LuCI */
var SRC_PATCHES = [
	[ /E\('h2', \{\}, 'Zapret Manager LuCI'\)/g, "E('h2', {}, 'Zapret Manager')" ],
	[ /E\('h3', \{\}, 'Удалить Zapret Manager LuCI'\)/g, "E('h3', {}, 'Удалить Zapret Manager')" ],
	[ /выведены из LuCI/g, 'выведены из панели' ],
	[ /закрытие LuCI/g, 'закрытие вкладки' ],
	[ /Выходим из LuCI/g, 'Выходим из панели' ],
	[ /Удалить панель из LuCI/g, 'Удалить панель' ],
	[ /саму программу-оболочку из LuCI/g, 'саму программу-оболочку (приложение LuCI и этот Web UI)' ],
	[ /(var tabBar = E\('div', \{ 'class': 'zm-actions)'/g, "$1 zmw-tabs'" ]
];

var REQ_RE = /^[ \t]*'require[ \t]+([A-Za-z0-9_.\-\/]+)(?:[ \t]+as[ \t]+([A-Za-z_$][A-Za-z0-9_$]*))?[ \t]*'[ \t]*;?/gm;

function evaluate(name, src) {
	SRC_PATCHES.forEach(function (p) { src = src.replace(p[0], p[1]); });
	var deps = [], m;
	REQ_RE.lastIndex = 0;
	while ((m = REQ_RE.exec(src))) deps.push({ name: m[1], as: m[2] || m[1].split(/[.\/]/).pop() });
	return Promise.all(deps.map(function (d) { return requireModule(d.name); })).then(function (insts) {
		var names = [ 'E', '_', 'N_', 'L' ].concat(deps.map(function (d) { return d.as; }));
		var fn = Function.apply(null, names.concat([ src + '\n//# sourceURL=' + location.origin + modUrl(name) ]));
		return fn.apply(window, [ E, tr, tr, L ].concat(insts));
	});
}

function postPatch(name, inst) {
	if (name === 'zapret-manager.common' && inst) {
		inst.refreshBanner = function () {
			return E('div', { 'class': 'zm-refresh-banner zm-show' }, [
				E('span', {}, 'Состав компонентов изменился — обновите страницу, чтобы увидеть актуальное состояние.'),
				E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function () { location.reload(); } }, 'Обновить')
			]);
		};
		var origPoll = inst.pollJob;
		inst.pollJob = function (job, logEl, onDone, onTick) {
			return origPoll.call(this, job, logEl, function (ok) {
				try { if (typeof onDone === 'function') onDone(ok); }
				finally { setTimeout(function () { refreshShellStatus(); refreshMemory(); }, 1000); }
			}, onTick);
		};
		setTimeout(refreshShellStatus, 300);
	}
	return inst;
}

function requireModule(name) {
	if (BUILTIN[name]) return Promise.resolve(BUILTIN[name]);
	if (!modCache[name]) {
		modCache[name] = fetchSrc(name).then(function (src) { return evaluate(name, src); }).then(function (res) {
			return postPatch(name, (typeof res === 'function' && res.__zmClass) ? new res() : res);
		});
		modCache[name].catch(function () { delete modCache[name]; });
	}
	return modCache[name];
}

/* ───────────────────────── Иконки ───────────────────────── */

var ICONS = {
	dashboard: '<rect x="3" y="3" width="7.5" height="9" rx="2"/><rect x="13.5" y="3" width="7.5" height="5.5" rx="2"/><rect x="13.5" y="11.5" width="7.5" height="9.5" rx="2"/><rect x="3" y="15" width="7.5" height="6" rx="2"/>',
	shield: '<path d="M12 3l7.5 3v5.6c0 4.6-3.2 8.4-7.5 9.4-4.3-1-7.5-4.8-7.5-9.4V6L12 3z"/><path d="M8.8 12.2l2.2 2.2 4.3-4.4"/>',
	bolt: '<path d="M13.2 2.8L5 13.5h6.2l-1.1 7.7 8.4-10.9h-6.3l1-7.5z"/>',
	list: '<path d="M8.5 6.5h11.5M8.5 12h11.5M8.5 17.5h11.5"/><circle cx="4.3" cy="6.5" r="1"/><circle cx="4.3" cy="12" r="1"/><circle cx="4.3" cy="17.5" r="1"/>',
	globe: '<circle cx="12" cy="12" r="9"/><path d="M3.5 9h17M3.5 15h17M12 3c2.6 2.6 3.8 5.6 3.8 9s-1.2 6.4-3.8 9c-2.6-2.6-3.8-5.6-3.8-9S9.4 5.6 12 3z"/>',
	send: '<path d="M21 3.5L3.5 10.3l6.7 2.8 2.8 6.9L21 3.5z"/><path d="M10.2 13.1l4.6-4.6"/>',
	layers: '<path d="M12 3.2l9 4.9-9 4.9-9-4.9 9-4.9z"/><path d="M3 12.3l9 4.9 9-4.9"/><path d="M3 16.4l9 4.9 9-4.9"/>',
	play: '<rect x="2.5" y="5" width="19" height="14" rx="4.5"/><path d="M10.2 9.3v5.4l4.6-2.7-4.6-2.7z"/>',
	cpu: '<rect x="6" y="6" width="12" height="12" rx="2.5"/><rect x="9.5" y="9.5" width="5" height="5" rx="1"/><path d="M9.5 2.5v3.5M14.5 2.5v3.5M9.5 18v3.5M14.5 18v3.5M2.5 9.5H6M2.5 14.5H6M18 9.5h3.5M18 14.5h3.5"/>',
	logout: '<path d="M14.5 4h3a2.5 2.5 0 0 1 2.5 2.5v11a2.5 2.5 0 0 1-2.5 2.5h-3"/><path d="M10 16.5L5.5 12 10 7.5M5.5 12H15"/>',
	sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M4.6 4.6l1.4 1.4M18 18l1.4 1.4M2.5 12h2M19.5 12h2M4.6 19.4L6 18M18 6l1.4-1.4"/>',
	moon: '<path d="M20.5 14.2A8.5 8.5 0 0 1 9.8 3.5a8.5 8.5 0 1 0 10.7 10.7z"/>',
	ink: '<rect x="3.5" y="3.5" width="13" height="13" rx="1.5"/><path d="M8 20.5h12.5V8"/>',
	bento: '<rect x="3.5" y="3.5" width="10" height="10" rx="2.5"/><rect x="15.5" y="3.5" width="5" height="10" rx="2"/><rect x="3.5" y="15.5" width="5" height="5" rx="2"/><rect x="10.5" y="15.5" width="10" height="5" rx="2"/>',
	minimal: '<path d="M4 12h16"/>',
	retro: '<rect x="3" y="4" width="18" height="16"/><path d="M3 8.5h18M16 6.2h3"/>',
	depth: '<path d="M12 3l8 4.5v9L12 21l-8-4.5v-9z"/><path d="M12 12l8-4.5M12 12v9M12 12L4 7.5"/>',
	palette: '<path d="M12 3a9 9 0 1 0 0 18c1.1 0 1.8-.8 1.8-1.7 0-.5-.2-.9-.5-1.2-.3-.3-.5-.7-.5-1.2 0-.9.8-1.7 1.7-1.7H16a5 5 0 0 0 5-5C21 6.6 17 3 12 3z"/><circle cx="7.5" cy="11" r="1.2"/><circle cx="10.5" cy="7" r="1.2"/><circle cx="15.5" cy="7.5" r="1.2"/>',
	refresh: '<path d="M20 11.5A8 8 0 0 0 5.6 6.8L4 8.5"/><path d="M4 4v4.5h4.5"/><path d="M4 12.5a8 8 0 0 0 14.4 4.7l1.6-1.7"/><path d="M20 20v-4.5h-4.5"/>',
	menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
	close: '<path d="M6 6l12 12M18 6L6 18"/>',
	external: '<path d="M14 4h6v6"/><path d="M20 4l-9 9"/><path d="M18 14v4.5a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 4 18.5v-11A1.5 1.5 0 0 1 5.5 6H10"/>',
	eye: '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>',
	eyeOff: '<path d="M3 3l18 18"/><path d="M10.6 5.6A10 10 0 0 1 12 5.5c6 0 9.5 6.5 9.5 6.5a17 17 0 0 1-3.1 3.9M6.2 6.9C3.9 8.6 2.5 12 2.5 12S6 18.5 12 18.5c1.7 0 3.2-.5 4.5-1.2"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
	user: '<circle cx="12" cy="8" r="4"/><path d="M4 20.5c1.3-3.8 4.3-5.5 8-5.5s6.7 1.7 8 5.5"/>',
	lock: '<rect x="4.5" y="10.5" width="15" height="10" rx="2.5"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>',
	arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
	alert: '<path d="M12 3.5l9.5 16.5h-19L12 3.5z"/><path d="M12 10v4.5M12 17.3v.2"/>',
	route: '<circle cx="6" cy="18.5" r="2.2"/><circle cx="18" cy="5.5" r="2.2"/><path d="M8.2 18.5h7.3a3.3 3.3 0 0 0 0-6.6h-7a3.3 3.3 0 0 1 0-6.6h7.3"/>',
	tunnel: '<path d="M3 20V11a9 9 0 0 1 18 0v9"/><path d="M7 20v-8a5 5 0 0 1 10 0v8"/><path d="M3 20h18"/>',
	anarchy: '<circle cx="12" cy="12.8" r="7.3"/><path d="M12 2.2L4.2 21.8M12 2.2l7.8 19.6M3.6 14.6h16.8"/>',
	rocket: '<path d="M12 2.5c2.9 2.1 4.3 5.3 4.3 9.2V16H7.7v-4.3c0-3.9 1.4-7.1 4.3-9.2z"/><circle cx="12" cy="9.3" r="1.7"/><path d="M7.7 12.2L5 14.6V18l2.7-2M16.3 12.2l2.7 2.4V18l-2.7-2"/><path d="M10.2 18.5 12 21.5l1.8-3"/>',
	telegram: '<path d="M21 4.5L2.8 11.4c-.8.3-.8 1.4 0 1.7l4.4 1.5 1.7 5.3c.2.7 1.1.9 1.6.4l2.5-2.4 4.6 3.4c.6.4 1.4.1 1.6-.6L22.3 5.8c.2-.9-.6-1.6-1.3-1.3z"/><path d="M7.3 14.6l10-6.6-7.4 8"/>'
};

function icon(name, cls) {
	var s = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
	s.setAttribute('viewBox', '0 0 24 24');
	s.setAttribute('fill', 'none');
	s.setAttribute('stroke', 'currentColor');
	s.setAttribute('stroke-width', '1.8');
	s.setAttribute('stroke-linecap', 'round');
	s.setAttribute('stroke-linejoin', 'round');
	s.setAttribute('aria-hidden', 'true');
	s.setAttribute('class', 'zmw-i' + (cls ? ' ' + cls : ''));
	s.innerHTML = ICONS[name] || '';
	return s;
}

var logoSeq = 0;
function logo(cls) {
	var id = 'zmwz' + (++logoSeq);
	return E('div', { 'class': 'zmw-logo' + (cls ? ' ' + cls : '') }, [
		E('<svg viewBox="0 0 1250 1250" aria-hidden="true">' +
			'<defs><linearGradient id="' + id + '" x1="0" y1="0" x2="0" y2="1">' +
			'<stop offset="0" stop-color="#00b6ff"/><stop offset="1" stop-color="#0090ff"/>' +
			'</linearGradient></defs>' +
			'<g fill="url(#' + id + ')" stroke="#0a0a0a" stroke-width="22" stroke-linejoin="miter">' +
			'<polygon points="455,170 1072,118 1215,25 688,615 25,1235 735,338 262,383"/>' +
			'<polygon points="1025,462 722,860 1215,800 1005,1022 315,1095"/>' +
			'</g></svg>')
	]);
}

/* ───────────────────────── Тосты ───────────────────────── */

function toast(message, kind, duration) {
	var c = document.getElementById('zm-toast-container');
	if (!c) { c = E('div', { id: 'zm-toast-container' }); document.body.appendChild(c); }
	var el = E('div', { 'class': 'zm-toast zm-toast-' + (kind || 'info') }, [
		E('span', { 'class': 'zm-toast-icon' }, [ kind === 'error' ? '✕' : (kind === 'warning' ? '!' : '✓') ]),
		E('span', { 'class': 'zm-toast-text' }, [ message ])
	]);
	c.appendChild(el);
	requestAnimationFrame(function () { el.classList.add('zm-toast-show'); });
	var hide = function () {
		el.classList.remove('zm-toast-show');
		setTimeout(function () { el.remove(); }, 250);
	};
	el.addEventListener('click', hide);
	setTimeout(hide, duration || (kind === 'error' ? 12000 : 6000));
}

/* ───────────────────────── Тема ───────────────────────── */

var mqDark = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;
var THEMES = [
	{ id: 'micro', name: 'Светлая', ico: 'sun', fonts: 'Onest:wght@400;500;600;700', color: '#f4f5f8' },
	{ id: 'light', name: 'Лёгкая', ico: 'sun' },
	{ id: 'dark', name: 'Тёмная', ico: 'moon', dark: true },
	{ id: 'ink', name: 'Контур', ico: 'ink' },
	{ id: 'bento', name: 'Бенто', ico: 'bento', fonts: 'Onest:wght@400;500;600;700&family=Unbounded:wght@600;800', color: '#efebe4' },
	{ id: 'minimal', name: 'Минимал', ico: 'minimal', fonts: 'IBM+Plex+Sans:wght@300;400;500', color: '#ffffff' },
	{ id: 'retro', name: 'Ретро 98', ico: 'retro', color: '#008080' },
	{ id: 'depth', name: 'Объём 3D', ico: 'depth', dark: true, fonts: 'Onest:wght@400;500;600;700&family=Unbounded:wght@600;800', color: '#0a0e18' }
];
function themeById(id) { return THEMES.filter(function (x) { return x.id === id; })[0]; }
function themePref() { var t = sget(K_THEME); return themeById(t) ? t : 'auto'; }
// Шрифты темы — с Google Fonts, но строго «по желанию»: грузятся в фоне
// (media=print не держит страницу), а если Google недоступен или не ответил
// за 3 секунды — запрос снимается и остаются системные шрифты.
var fontsFailed = false;
function themeFonts(t) {
	if (fontsFailed || !t || !t.fonts || document.getElementById('zmw-font-' + t.id)) return;
	var l = document.createElement('link'), done = false;
	l.id = 'zmw-font-' + t.id;
	l.rel = 'stylesheet';
	l.media = 'print';
	l.onload = function () { done = true; l.media = 'all'; };
	l.onerror = function () { done = true; fontsFailed = true; l.remove(); };
	l.href = 'https://fonts.googleapis.com/css2?family=' + t.fonts + '&display=swap';
	document.head.appendChild(l);
	setTimeout(function () { if (!done) { fontsFailed = true; l.remove(); } }, 3000);
}
function themeEffective() { var p = themePref(); return p === 'auto' ? 'micro' : p; }
function applyTheme() {
	var t = themeEffective();
	var h = document.documentElement;
	var th = themeById(t) || THEMES[0];
	themeFonts(th);
	h.setAttribute('data-theme', t);
	h.classList.toggle('zm-theme-dark', !!th.dark);
	h.setAttribute('data-zm-theme-checked', '1');
	var mc = document.querySelector('meta[name="theme-color"]');
	if (mc) mc.setAttribute('content', th.color || (t === 'dark' ? '#0a0c12' : t === 'ink' ? '#ffffff' : '#f3f5fa'));
	var cur = th;
	Array.prototype.forEach.call(document.querySelectorAll('.zmw-theme-toggle'), function (b) {
		b.innerHTML = '';
		b.appendChild(icon('palette'));
		b.title = 'Тема оформления: ' + cur.name;
		b.setAttribute('aria-label', 'Тема оформления');
		b.setAttribute('aria-haspopup', 'menu');
	});
}
var themeMenuEl = null;
function closeThemeMenu() {
	if (!themeMenuEl) return;
	themeMenuEl.remove();
	themeMenuEl = null;
	document.removeEventListener('click', themeMenuOutside, true);
	document.removeEventListener('keydown', themeMenuKey, true);
}
function themeMenuOutside(e) { if (themeMenuEl && !themeMenuEl.contains(e.target) && !(e.target.closest && e.target.closest('.zmw-theme-toggle'))) closeThemeMenu(); }
function themeMenuKey(e) { if (e.key === 'Escape') closeThemeMenu(); }
function setTheme(id) {
	sset(K_THEME, id, true);
	document.documentElement.classList.add('zmw-theme-anim');
	applyTheme();
	setTimeout(function () { document.documentElement.classList.remove('zmw-theme-anim'); }, 400);
}
if (mqDark && mqDark.addEventListener) mqDark.addEventListener('change', function () { if (themePref() === 'auto') applyTheme(); });
function toggleTheme(ev) {
	var btn = ev && ev.currentTarget;
	if (themeMenuEl) { closeThemeMenu(); return; }
	var cur = themeEffective();
	var items = [ E('div', { 'class': 'zmw-theme-group' }, [ 'Тема оформления' ]) ];
	THEMES.forEach(function (t) { items.push(themeOpt(t, cur)); });
	themeMenuEl = E('div', { 'class': 'zmw-theme-menu', 'role': 'menu' }, items);
	function themeOpt(t, cur) {
		return E('button', {
			'type': 'button', 'role': 'menuitemradio', 'aria-checked': t.id === cur ? 'true' : 'false',
			'class': 'zmw-theme-opt' + (t.id === cur ? ' zmw-on' : ''),
			'click': function (e) { e.stopPropagation(); closeThemeMenu(); if (t.id !== cur) setTheme(t.id); }
		}, [ icon(t.ico), E('span', {}, [ t.name ]), E('span', { 'class': 'zmw-theme-mark' }, [ t.id === cur ? '✓' : '' ]) ]);
	}
	document.body.appendChild(themeMenuEl);
	if (btn) {
		var r = btn.getBoundingClientRect();
		themeMenuEl.style.top = Math.round(r.bottom + 8) + 'px';
		themeMenuEl.style.right = Math.max(8, Math.round(window.innerWidth - r.right)) + 'px';
	}
	setTimeout(function () {
		document.addEventListener('click', themeMenuOutside, true);
		document.addEventListener('keydown', themeMenuKey, true);
	}, 0);
}

/* ───────────────────────── Маршруты ───────────────────────── */

var ROUTES = [
	{ id: 'dashboard', title: 'Дашборд', sub: 'Состояние всех компонентов', icon: 'dashboard', group: 'Обзор' },
	{ id: 'strategy', title: 'Zapret', sub: 'Стратегии, тесты, YouTube, игры, Discord и исключения', icon: 'shield', group: 'Обход блокировок', dot: 'zapret' },
	{ id: 'zapret2', title: 'Zapret2', sub: 'Установка и управление Zapret2', icon: 'bolt', group: 'Обход блокировок', dot: 'zapret2' },
	{ id: 'steer', title: 'Steer', sub: 'Выбранные сервисы через WARP или VPN', icon: 'route', group: 'Обход блокировок', dot: 'steer' },
	{ id: 'bytetube', title: 'ByeTube', sub: 'YouTube через ByeDPI', icon: 'play', group: 'Обход блокировок', dot: 'bytetube' },
	{ id: 'tgproxy', title: 'TG WS Proxy', sub: 'Прокси для Telegram', icon: 'send', group: 'Обход блокировок', dot: 'tg' },
	{ id: 'mixomo', title: 'Mixomo', sub: 'Mihomo, MagiTrickle и WARP', icon: 'layers', group: 'Обход блокировок', dot: 'mixomo' },
	{ id: 'hosts', title: 'Hosts', sub: 'Домены в hosts и списки GeoHide', icon: 'list', group: 'Сеть', dot: 'hosts' },
	{ id: 'doh', title: 'DNS over HTTPS', sub: 'Шифрованный DNS для всей сети', icon: 'globe', group: 'Сеть', dot: 'doh' },
	{ id: 'awg', title: 'AmneziaWG', sub: 'Туннели AmneziaWG и WARP: установка, ключи, интерфейсы', icon: 'anarchy', group: 'Сеть', dot: 'awg' },
	{ id: 'system', title: 'Система', sub: 'Параметры роутера, зеркала и обслуживание', icon: 'cpu', group: 'Сервис' }
];
var ROUTE_BY_ID = {};
ROUTES.forEach(function (r) { ROUTE_BY_ID[r.id] = r; });

function currentRoute() {
	var id = (location.hash || '').replace(/^#\/?/, '').split(/[/?]/)[0];
	return ROUTE_BY_ID[id] ? id : 'dashboard';
}

/* ───────────────────────── Оболочка ───────────────────────── */

var root, shell = null, viewEl, titleEl, subEl, navLinks = {}, navDots = {}, statusPill, deviceEl, verEl, updateEl, memEl;

function buildShell() {
	var nav = E('nav', { 'class': 'zmw-nav', 'aria-label': 'Разделы' });
	var lastGroup = null;
	ROUTES.forEach(function (r) {
		if (r.group !== lastGroup) { nav.appendChild(E('div', { 'class': 'zmw-nav-group' }, [ r.group ])); lastGroup = r.group; }
		var dot = r.dot ? E('span', { 'class': 'zmw-nav-dot' }) : null;
		var a = E('a', { 'class': 'zmw-nav-item', 'href': '#/' + r.id, 'data-route': r.id }, [
			E('span', { 'class': 'zmw-nav-ico' }, [ icon(r.icon) ]),
			E('span', { 'class': 'zmw-nav-label' }, [ r.title ]),
			dot
		]);
		a.addEventListener('click', function () { closeDrawer(); });
		navLinks[r.id] = a;
		if (dot) navDots[r.dot] = dot;
		nav.appendChild(a);
	});

	deviceEl = E('div', { 'class': 'zmw-device' }, [
		E('div', { 'class': 'zmw-device-model' }, [ 'Роутер' ]),
		E('div', { 'class': 'zmw-device-sub' }, [ location.hostname ]),
		E('div', { 'class': 'zmw-device-sub' }, [ '' ])
	]);
	verEl = E('div', { 'class': 'zmw-brand-sub' }, [ 'by StressOzz' ]);
	updateEl = E('a', { 'class': 'zmw-update', 'href': '#/dashboard', 'hidden': '' }, [ 'Доступно обновление' ]);
	memEl = E('div', { 'class': 'zmw-mem' });

	var side = E('aside', { 'class': 'zmw-side', 'id': 'zmw-side' }, [
		E('div', { 'class': 'zmw-brand' }, [
			logo(),
			E('div', { 'class': 'zmw-brand-text' }, [ E('div', { 'class': 'zmw-brand-name' }, [ 'Zapret Manager' ]), verEl ]),
			E('button', { 'class': 'zmw-icon-btn zmw-drawer-close', 'type': 'button', 'aria-label': 'Закрыть меню', 'click': closeDrawer }, [ icon('close') ])
		]),
		updateEl,
		nav,
		E('div', { 'class': 'zmw-side-foot' }, [
			deviceEl,
			memEl,
			E('div', { 'class': 'zmw-side-links' }, [
				E('a', { 'href': luciUrl(), 'target': '_blank', 'rel': 'noreferrer' }, [ icon('external'), 'Открыть LuCI' ])
			])
		])
	]);

	titleEl = E('h1', { 'class': 'zmw-title' }, [ '' ]);
	subEl = E('div', { 'class': 'zmw-sub' }, [ '' ]);
	viewEl = E('main', { 'class': 'zmw-view', 'id': 'zmw-view' });

	var themeBtn = E('button', { 'class': 'zmw-icon-btn zmw-theme-toggle', 'type': 'button', 'click': toggleTheme });
	var top = E('header', { 'class': 'zmw-top' }, [
		E('button', { 'class': 'zmw-icon-btn zmw-burger', 'type': 'button', 'aria-label': 'Меню', 'click': openDrawer }, [ icon('menu') ]),
		E('div', { 'class': 'zmw-titles' }, [ titleEl, subEl ]),
		E('div', { 'class': 'zmw-top-actions' }, [
			E('a', { 'class': 'zmw-icon-btn zmw-link-btn zmw-link-kvn', 'href': 'http://stresskvn.lol/', 'target': '_blank', 'rel': 'noreferrer', 'title': 'StressKVN — обход белых списков!' }, [
				icon('rocket'), E('span', { 'class': 'zmw-lbl-full' }, [ 'StressKVN — обход белых списков!' ]), E('span', { 'class': 'zmw-lbl-short' }, [ 'StressKVN' ])
			]),
			E('a', { 'class': 'zmw-icon-btn zmw-link-btn zmw-link-tg', 'href': 'https://t.me/stressozz_manager', 'target': '_blank', 'rel': 'noreferrer', 'title': 'Сообщество Telegram' }, [
				icon('telegram'), E('span', { 'class': 'zmw-lbl-full' }, [ 'Сообщество Telegram' ]), E('span', { 'class': 'zmw-lbl-short' }, [ 'Telegram' ])
			]),
			E('span', { 'class': 'zmw-top-sep' }),
			E('button', { 'class': 'zmw-icon-btn', 'type': 'button', 'title': 'Обновить страницу', 'click': function (ev) {
				var b = ev.currentTarget; b.classList.add('zmw-spin'); setTimeout(function () { b.classList.remove('zmw-spin'); }, 700);
				route(true);
			} }, [ icon('refresh') ]),
			themeBtn,
			E('button', { 'class': 'zmw-icon-btn zmw-logout', 'type': 'button', 'title': 'Выйти', 'click': function () { logout(); } }, [ icon('logout'), E('span', {}, [ 'Выйти' ]) ])
		])
	]);

	shell = E('div', { 'class': 'zmw-shell' }, [
		side,
		E('div', { 'class': 'zmw-main' }, [ top, viewEl, E('footer', { 'class': 'zmw-foot' }, [ '' ]) ]),
		E('div', { 'class': 'zmw-scrim', 'click': closeDrawer })
	]);
	root.appendChild(shell);
	applyTheme();
}

function luciUrl() {
	return location.protocol + '//' + location.hostname + '/cgi-bin/luci/admin/services/zapret-manager/dashboard';
}

function openDrawer() { document.body.classList.add('zmw-drawer-open'); }
function closeDrawer() { document.body.classList.remove('zmw-drawer-open'); }

var callStatus = declare({ object: 'zapret-manager', method: 'status', expect: {} });
var callSysInfo = declare({ object: 'zapret-manager', method: 'system_info', expect: {} });
var callHealth = declare({ object: 'zapret-manager', method: 'health', expect: {} });
var callUpd = declare({ object: 'zapret-manager', method: 'zm_update_status', expect: {} });
var callBoardInfo = declare({ object: 'system', method: 'info', expect: {} });

function parseSize(v) {
	var m = String(v || '').trim().match(/^([\d.,]+)\s*([KMGT]?)i?B?$/i);
	if (!m) return NaN;
	var n = parseFloat(m[1].replace(',', '.'));
	var mul = { '': 1, K: 1024, M: 1048576, G: 1073741824, T: 1099511627776 }[m[2].toUpperCase()];
	return n * mul;
}
function fmtSize(b) {
	if (!isFinite(b)) return '—';
	var u = [ 'Б', 'КБ', 'МБ', 'ГБ', 'ТБ' ], i = 0;
	while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
	return (b >= 100 || i === 0 ? Math.round(b) : b.toFixed(1).replace(/\.0$/, '')) + ' ' + u[i];
}
var memRows = {};
function memRow(key, label, used, total) {
	var pct = total > 0 ? Math.max(0, Math.min(100, used / total * 100)) : 0;
	var r = memRows[key];
	if (!r) {
		r = memRows[key] = {
			el: E('div', { 'class': 'zmw-mem-row' }, [
				E('div', { 'class': 'zmw-mem-head' }, [ E('span', { 'class': 'zmw-mem-label' }, [ label ]), E('span', { 'class': 'zmw-mem-val' }) ]),
				E('div', { 'class': 'zmw-mem-bar' }, [ E('i') ])
			])
		};
		r.order = key === 'temp' ? -1 : key === 'ram' ? 0 : key === 'flash' ? 1 : 2;
		var before = null;
		Object.keys(memRows).forEach(function (k) { var o = memRows[k]; if (o !== r && o.el.parentNode && o.order > r.order && (!before || o.order < before.order)) before = o; });
		memEl.insertBefore(r.el, before ? before.el : null);
	}
	r.el.querySelector('.zmw-mem-val').textContent = fmtSize(used) + ' из ' + fmtSize(total);
	var bar = r.el.querySelector('i');
	bar.style.width = pct.toFixed(1) + '%';
	r.el.classList.toggle('zmw-mem-hi', pct >= 85);
	r.el.classList.toggle('zmw-mem-mid', pct >= 65 && pct < 85);
	r.el.title = label + ': занято ' + Math.round(pct) + '%';
}
/* Температура процессора — той же строкой с полоской, что и память: шкала до 100 °C,
   жёлтая с 65, красная с 80. Датчика нет — строки нет. */
function tempRow(t) {
	var r = memRows.temp;
	if (!r) {
		r = memRows.temp = {
			order: -1,
			el: E('div', { 'class': 'zmw-mem-row' }, [
				E('div', { 'class': 'zmw-mem-head' }, [ E('span', { 'class': 'zmw-mem-label' }, [ 'Температура ЦП' ]), E('span', { 'class': 'zmw-mem-val' }) ]),
				E('div', { 'class': 'zmw-mem-bar' }, [ E('i') ])
			])
		};
		memEl.insertBefore(r.el, memEl.firstChild);
	}
	r.el.querySelector('.zmw-mem-val').textContent = t + ' °C';
	r.el.querySelector('i').style.width = Math.max(0, Math.min(100, t)).toFixed(0) + '%';
	r.el.classList.toggle('zmw-mem-hi', t >= 80);
	r.el.classList.toggle('zmw-mem-mid', t >= 65 && t < 80);
	r.el.title = 'Температура процессора: ' + t + ' °C';
}

function loadRow(pct) {
	var r = memRows.load;
	if (!r) {
		r = memRows.load = {
			order: -0.5,
			el: E('div', { 'class': 'zmw-mem-row' }, [
				E('div', { 'class': 'zmw-mem-head' }, [ E('span', { 'class': 'zmw-mem-label' }, [ 'Нагрузка ЦП' ]), E('span', { 'class': 'zmw-mem-val' }) ]),
				E('div', { 'class': 'zmw-mem-bar' }, [ E('i') ])
			])
		};
		var before = null;
		Object.keys(memRows).forEach(function (k) { var o = memRows[k]; if (o !== r && o.el.parentNode && o.order > r.order && (!before || o.order < before.order)) before = o; });
		memEl.insertBefore(r.el, before ? before.el : null);
	}
	pct = Math.max(0, Math.min(100, pct));
	r.el.querySelector('.zmw-mem-val').textContent = pct + '%';
	r.el.querySelector('i').style.width = pct + '%';
	r.el.classList.toggle('zmw-mem-hi', pct >= 90);
	r.el.classList.toggle('zmw-mem-mid', pct >= 70 && pct < 90);
	r.el.title = 'Нагрузка процессора: ' + pct + '%';
}

function refreshMemory() {
	if (!shell || !sid) return;
	callBoardInfo().then(function (i) {
		var m = i && i.memory;
		if (!m || !m.total) return;
		var avail = m.available != null ? m.available : (m.free + (m.buffered || 0) + (m.cached || 0));
		memRow('ram', 'ОЗУ', m.total - avail, m.total);
	}).catch(function () {});
	callSysInfo().then(function (i) {
		if (!i || i.error) return;
		var ru = parseSize(i.root_used), rf = parseSize(i.root_free);
		if (isFinite(ru) && isFinite(rf)) memRow('flash', 'Флеш', ru, ru + rf);
		var t = parseFloat(i.cpu_temp);
		if (!isNaN(t)) tempRow(t);
		var cl = parseInt(i.cpu_load, 10);
		if (!isNaN(cl)) loadRow(cl);
	}).catch(function () {});
}

var statusBusy = false;
/* 1 — работает (зелёная), 2 — сломано (красная, мигает), 3 — работает частично (жёлтая);
   остальное (0 — не установлено, 5 — выключено человеком) — без точки. */
var DOT_TEXT = { 1: 'работает', 2: 'не работает', 3: 'работает частично' };
function refreshShellStatus() {
	if (!shell || !sid || statusBusy) return;
	statusBusy = true;
	callHealth().then(function (h) {
		if (h && typeof h.zapret === 'number') return h;
		/* старый бэкенд без health — хотя бы Zapret/Zapret2 */
		return callStatus().then(function (d) {
			d = d || {};
			return {
				zapret: d.zapret === 'installed' ? (d.zapret_running ? 1 : 2) : 0,
				zapret2: d.zapret2 === 'installed' ? (d.zapret2_running ? 1 : 2) : 0
			};
		});
	}).then(function (h) {
		Object.keys(navDots).forEach(function (k) {
			var title = null;
			if (k === 'awg' && h.awg_total) title = 'туннелей работает: ' + (h.awg_up || 0) + ' из ' + h.awg_total;
			setDot(navDots[k], h[k], title);
		});
	}).catch(function () {}).then(function () { statusBusy = false; });
}
function setDot(el, st, title) {
	if (!el) return;
	el.className = 'zmw-nav-dot' + (st === 1 ? ' zmw-on' : st === 2 ? ' zmw-stop' : st === 3 ? ' zmw-part' : '');
	el.title = title || DOT_TEXT[st] || '';
}

function loadShellInfo() {
	callSysInfo().then(function (i) {
		if (!i || i.error) return;
		deviceEl.firstChild.textContent = String(i.model || 'Роутер').replace(/\s*\(.*\)\s*$/, '') || i.model;
		deviceEl.title = [ i.model, i.openwrt ? 'OpenWrt ' + i.openwrt : '', i.arch ].filter(Boolean).join('\n');
		deviceEl.children[1].textContent = i.openwrt ? 'OpenWrt ' + i.openwrt : location.hostname;
		deviceEl.children[2].textContent = i.arch || '';
	}).catch(function () {});
	callUpd().then(function (u) {
		if (!u || u.error) return;
		if (u.current) verEl.textContent = 'by StressOzz · v' + u.current;
		if (u.latest && u.current && u.latest !== u.current && u.newer !== false) {
			updateEl.hidden = false;
			updateEl.textContent = 'Доступна версия ' + u.latest;
		}
	}).catch(function () {});
}

var shellTimer = null;
var shellRefreshTimer = null;
function scheduleShellRefresh() {
	clearTimeout(shellRefreshTimer);
	shellRefreshTimer = setTimeout(function () { refreshShellStatus(); }, 1200);
}
window.addEventListener('zm:changed', scheduleShellRefresh);

function startShellPolling() {
	if (shellTimer) return;
	shellTimer = setInterval(function () { if (!document.hidden) refreshShellStatus(); }, 15000);
	setInterval(function () { if (!document.hidden) refreshMemory(); }, 5000);
}

/* ───────────────────────── Рендер страниц ───────────────────────── */

var routeToken = 0;

function skeleton() {
	return E('div', { 'class': 'zmw-skel-wrap' }, [
		E('div', { 'class': 'zmw-skel zmw-skel-bar' }),
		E('div', { 'class': 'zmw-skel-grid' }, [
			E('div', { 'class': 'zmw-skel zmw-skel-card' }),
			E('div', { 'class': 'zmw-skel zmw-skel-card' }),
			E('div', { 'class': 'zmw-skel zmw-skel-card' })
		]),
		E('div', { 'class': 'zmw-skel zmw-skel-wide' })
	]);
}

function errorCard(err, retry) {
	return E('div', { 'class': 'zmw-error' }, [
		E('div', { 'class': 'zmw-error-ico' }, [ icon('alert') ]),
		E('div', {}, [
			E('h3', {}, [ 'Не удалось открыть страницу' ]),
			E('p', {}, [ (err && err.message) || String(err) ]),
			E('button', { 'class': 'cbi-button cbi-button-positive', 'click': retry }, [ 'Повторить' ])
		])
	]);
}

function route(force) {
	if (!shell || !sid) return;
	var id = currentRoute();
	var r = ROUTE_BY_ID[id];
	var token = ++routeToken;

	Object.keys(navLinks).forEach(function (k) { navLinks[k].classList.toggle('zmw-active', k === id); });
	titleEl.textContent = r.title;
	subEl.textContent = r.sub;
	document.title = r.title + ' · Zapret Manager';

	poll._reset();
	ui.hideModal();
	refreshShellStatus();
	viewEl.innerHTML = '';
	viewEl.appendChild(skeleton());
	if (!force) window.scrollTo(0, 0);

	fetchSrc('view.zapret-manager.' + id)
		.then(function (src) { return evaluate('view.zapret-manager.' + id, src); })
		.then(function (Cls) {
			if (token !== routeToken) return;
			var v = (typeof Cls === 'function' && Cls.__zmClass) ? new Cls() : Cls;
			return Promise.resolve(v.load()).then(function (data) {
				if (token !== routeToken) return;
				return Promise.resolve(v.render(data));
			}).then(function (node) {
				if (token !== routeToken || !node) return;
				var page = E('div', { 'class': 'zmw-page' }, [ node ]);
				viewEl.innerHTML = '';
				viewEl.appendChild(page);
			});
		})
		.catch(function (err) {
			if (token !== routeToken || (err && err.authLost)) return;
			console.error(err);
			viewEl.innerHTML = '';
			viewEl.appendChild(errorCard(err, function () { route(true); }));
		});
}

/* ───────────────────────── Вход / выход ───────────────────────── */

var loginEl = null, authLostShown = false;

function showLogin(note, noteKind) {
	if (loginEl) return;
	var user = E('input', { 'type': 'text', 'name': 'username', 'autocomplete': 'username', 'autocapitalize': 'off', 'spellcheck': 'false', 'value': sget(K_USER) || 'root', 'required': '' });
	var pass = E('input', { 'type': 'password', 'name': 'password', 'autocomplete': 'current-password', 'placeholder': '••••••••' });
	var eye = E('button', { 'type': 'button', 'class': 'zmw-eye', 'tabindex': '-1', 'aria-label': 'Показать пароль' }, [ icon('eye') ]);
	eye.addEventListener('click', function () {
		var show = pass.type === 'password';
		pass.type = show ? 'text' : 'password';
		eye.innerHTML = ''; eye.appendChild(icon(show ? 'eyeOff' : 'eye'));
		pass.focus();
	});
	var remember = E('input', { 'type': 'checkbox', 'checked': '' });
	var errEl = E('div', { 'class': 'zmw-login-msg' + (note ? ' zmw-show zmw-' + (noteKind || 'info') : '') }, [ note || '' ]);
	var btn = E('button', { 'type': 'submit', 'class': 'zmw-btn-primary' }, [ E('span', {}, [ 'Войти' ]), icon('arrow') ]);

	var card = E('form', { 'class': 'zmw-login-card', 'autocomplete': 'on' }, [
		logo('zmw-logo-lg'),
		E('h1', {}, [ 'Zapret Manager' ]),
		E('p', { 'class': 'zmw-login-sub' }, [ 'Панель управления роутером ', E('b', {}, [ location.hostname ]) ]),
		E('label', { 'class': 'zmw-field' }, [ E('span', { 'class': 'zmw-field-label' }, [ 'Пользователь' ]), E('div', { 'class': 'zmw-input' }, [ icon('user'), user ]) ]),
		E('label', { 'class': 'zmw-field' }, [ E('span', { 'class': 'zmw-field-label' }, [ 'Пароль' ]), E('div', { 'class': 'zmw-input' }, [ icon('lock'), pass, eye ]) ]),
		E('label', { 'class': 'zmw-check' }, [ remember, E('span', { 'class': 'zmw-check-box' }), E('span', {}, [ 'Запомнить на этом устройстве' ]) ]),
		errEl,
		btn,
		E('div', { 'class': 'zmw-login-foot' }, [ 'Логин и пароль те же, что и для LuCI' ])
	]);

	function fail(msg) {
		errEl.className = 'zmw-login-msg zmw-show zmw-error';
		errEl.textContent = msg;
		card.classList.remove('zmw-shake'); void card.offsetWidth; card.classList.add('zmw-shake');
		btn.disabled = false;
		btn.classList.remove('zmw-loading');
	}

	card.addEventListener('submit', function (ev) {
		ev.preventDefault();
		if (btn.disabled) return;
		btn.disabled = true;
		btn.classList.add('zmw-loading');
		errEl.className = 'zmw-login-msg';
		ubus('session', 'login', { username: user.value.trim(), password: pass.value, timeout: 3600 }, NULL_SID).then(function (res) {
			if (res[0] === 6 || !res[1] || !res[1].ubus_rpc_session) { fail('Неверный логин или пароль'); return; }
			var s = res[1].ubus_rpc_session;
			var acl = res[1].acls && res[1].acls.ubus;
			if (acl && !acl['zapret-manager'] && !acl['*']) { fail('У пользователя нет доступа к Zapret Manager'); return; }
			return ubus('zapret-manager', 'status', {}, s).then(function (st) {
				if (st[0] === 3 || st[0] === 4) { fail('rpcd-плагин zapret-manager не найден — переустановите панель'); return; }
				sid = s;
				L.env.sessionid = s;
				sset(K_SID, s, remember.checked);
				sset(K_USER, user.value.trim(), true);
				closeLogin();
				startApp();
			});
		}).catch(function (e) {
			fail(e && e.noUbus ? e.message : ('Роутер не отвечает: ' + ((e && e.message) || e)));
		});
	});

	loginEl = E('div', { 'class': 'zmw-login' }, [
		E('div', { 'class': 'zmw-orbs', 'aria-hidden': 'true' }, [ E('i'), E('i'), E('i') ]),
		E('div', { 'class': 'zmw-grid-bg', 'aria-hidden': 'true' }),
		card,
		E('button', { 'type': 'button', 'class': 'zmw-icon-btn zmw-login-theme zmw-theme-toggle', 'click': toggleTheme })
	]);
	document.body.classList.add('zmw-locked');
	root.appendChild(loginEl);
	applyTheme();
	setTimeout(function () { (user.value ? pass : user).focus(); }, 60);
}

function closeLogin() {
	if (!loginEl) return;
	var el = loginEl;
	loginEl = null;
	authLostShown = false;
	el.classList.add('zmw-leave');
	document.body.classList.remove('zmw-locked');
	setTimeout(function () { el.remove(); }, 380);
}

function authLost() {
	if (authLostShown || loginEl) return;
	authLostShown = true;
	sid = null;
	sset(K_SID, null);
	poll._reset();
	freshLogin('Сессия истекла — войдите снова.', 'warning');
}

function dropCaches() {
	srcCache = {};
	modCache = {};
	try { if (window.caches && caches.keys) caches.keys().then(function (ks) { ks.forEach(function (k) { caches.delete(k); }); }).catch(function () {}); } catch (e) {}
	try { var s = store('session'); if (s) Object.keys(s).forEach(function (k) { if (/^zmw\./.test(k) && k !== K_THEME && k !== K_USER && k !== K_NOTE) s.removeItem(k); }); } catch (e) {}
}

function freshLogin(note, kind) {
	dropCaches();
	var shown = false;
	var show = function () { if (!shown) { shown = true; showLogin(note, kind); } };
	var t = setTimeout(show, 2500);
	fetch('/zm-webui.html?t=' + Date.now(), { cache: 'no-store' }).then(function (r) { return r.ok ? r.text() : ''; }).then(function (html) {
		var m = /app\.js\?v=([0-9A-Za-z_]+)/.exec(html || '');
		if (m && m[1] !== BUILD && !shown) {
			clearTimeout(t);
			shown = true;
			try { var s = store('session'); if (s) s.setItem(K_NOTE, JSON.stringify([ (note ? note + ' ' : '') + 'Панель обновлена — загружена новая версия.', kind || 'info' ])); } catch (e) {}
			location.replace('/?fresh=' + Date.now() + location.hash);
			return;
		}
		clearTimeout(t);
		show();
	}).catch(function () { clearTimeout(t); show(); });
}

function logout() {
	var s = sid;
	sid = null;
	sset(K_SID, null);
	var done = function () {
		poll._reset();
		if (viewEl) viewEl.innerHTML = '';
		freshLogin('Вы вышли из панели.', 'info');
	};
	if (!s) return done();
	ubus('session', 'destroy', {}, s).catch(function () {}).then(done);
}

var started = false;
function startApp() {
	if (!shell) buildShell();
	document.body.classList.add('zmw-ready');
	if (!started) {
		started = true;
		window.addEventListener('hashchange', function () { route(); });
		startShellPolling();
	}
	loadShellInfo();
	refreshShellStatus();
	refreshMemory();
	route();
}

/* ───────────────────────── Старт ───────────────────────── */

function boot() {
	root = document.getElementById('zmw-root');
	document.body.classList.add('zmw-body');
	applyTheme();

	document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { closeDrawer(); } });

	var note = null;
	try { var ss = store('session'); note = ss && JSON.parse(ss.getItem(K_NOTE) || 'null'); if (ss) ss.removeItem(K_NOTE); } catch (e) {}
	if (/[?&]fresh=/.test(location.search)) {
		try { history.replaceState(null, '', '/' + location.hash); } catch (e) {}
	}
	if (note && !sid) { showLogin(note[0], note[1]); return; }

	if (/[?&]logout=1/.test(location.search)) {
		var s = sid;
		sid = null;
		sset(K_SID, null);
		try { history.replaceState(null, '', '/' + location.hash); } catch (e) {}
		if (s) ubus('session', 'destroy', {}, s).catch(function () {});
		freshLogin('Вы вышли из панели. Войдите снова.', 'info');
		return;
	}

	if (!sid) { showLogin(); return; }

	/* Проверяем, жива ли сохранённая сессия */
	ubus('session', 'access', { scope: 'ubus', object: 'zapret-manager', 'function': 'status' }, sid).then(function (res) {
		if (res[0] === 0 && res[1] && res[1].access) startApp();
		else { sid = null; sset(K_SID, null); showLogin(); }
	}).catch(function (e) {
		sid = null; sset(K_SID, null);
		showLogin(e && e.noUbus ? e.message : null, 'error');
	});
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
else boot();

})();
ZM_INSTALLER_EOF
cat > '/www/zm/app.css' << 'ZM_INSTALLER_EOF'
/* Zapret Manager — Web UI theme */

:root {
	--font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
	--mono: ui-monospace, "JetBrains Mono", "SF Mono", "Cascadia Code", Consolas, "Liberation Mono", monospace;

	--a1: #7c5cff;
	--a2: #3b82f6;
	--a3: #22d3ee;
	--grad: linear-gradient(135deg, var(--a1) 0%, var(--a2) 55%, var(--a3) 100%);
	--grad-soft: linear-gradient(135deg, rgba(124,92,255,.16), rgba(34,211,238,.10));
	--ring: 0 0 0 3px rgba(124,92,255,.28);

	--radius: 18px;
	--radius-sm: 12px;
	--side-w: 272px;

	/* светлая тема */
	--bg: #f3f5fa;
	--bg-glow-1: rgba(124,92,255,.12);
	--bg-glow-2: rgba(34,211,238,.10);
	--surface: rgba(255,255,255,.82);
	--surface-solid: #ffffff;
	--surface-2: #f5f6fb;
	--surface-3: #eceff6;
	--side-bg: rgba(255,255,255,.66);
	--border: rgba(15,23,42,.08);
	--border-2: rgba(15,23,42,.14);
	--text: #0f172a;
	--text-2: #334155;
	--muted: #64748b;
	--shadow: 0 1px 2px rgba(15,23,42,.04), 0 12px 32px -18px rgba(15,23,42,.18);
	--shadow-lg: 0 24px 60px -24px rgba(15,23,42,.35);
	--input-bg: #ffffff;
	--console: #0b1020;
	--console-border: rgba(15,23,42,.12);

	--ok: #059669; --ok-bg: rgba(16,185,129,.12); --ok-dot: #10b981;
	--bad: #dc2626; --bad-bg: rgba(239,68,68,.10); --bad-dot: #ef4444;
	--warn: #b45309; --warn-bg: rgba(245,158,11,.14); --warn-dot: #f59e0b;
	--off: #64748b; --off-bg: rgba(100,116,139,.12);

	/* для detectMissingThemeVar() в страницах LuCI */
	--background-color-medium: var(--surface-solid);
	--background-color-low: var(--surface-2);
	color-scheme: light;
}

html[data-theme="dark"] {
	--bg: #07090f;
	--bg-glow-1: rgba(124,92,255,.20);
	--bg-glow-2: rgba(34,211,238,.10);
	--surface: rgba(22,27,38,.72);
	--surface-solid: #121722;
	--surface-2: rgba(255,255,255,.045);
	--surface-3: rgba(255,255,255,.08);
	--side-bg: rgba(12,15,23,.72);
	--border: rgba(255,255,255,.07);
	--border-2: rgba(255,255,255,.13);
	--text: #e8ebf4;
	--text-2: #c3c9d8;
	--muted: #8a93a8;
	--shadow: 0 1px 0 rgba(255,255,255,.03) inset, 0 16px 40px -22px rgba(0,0,0,.8);
	--shadow-lg: 0 30px 80px -30px rgba(0,0,0,.9);
	--input-bg: rgba(255,255,255,.04);
	--console: #070a12;
	--console-border: rgba(255,255,255,.08);

	--ok: #34d399; --ok-bg: rgba(52,211,153,.12); --ok-dot: #34d399;
	--bad: #f87171; --bad-bg: rgba(248,113,113,.12); --bad-dot: #f87171;
	--warn: #fbbf24; --warn-bg: rgba(251,191,36,.12); --warn-dot: #fbbf24;
	--off: #94a3b8; --off-bg: rgba(148,163,184,.12);
	color-scheme: dark;
}

*, *::before, *::after { box-sizing: border-box; }

html, body { margin: 0; padding: 0; }
body.zmw-body {
	font-family: var(--font);
	font-size: 14px;
	line-height: 1.5;
	color: var(--text);
	background-color: var(--bg);
	background-image:
		radial-gradient(900px 600px at -10% -20%, var(--bg-glow-1), transparent 60%),
		radial-gradient(800px 520px at 110% -10%, var(--bg-glow-2), transparent 60%);
	background-attachment: fixed;
	-webkit-font-smoothing: antialiased;
	-moz-osx-font-smoothing: grayscale;
	min-height: 100vh;
	overflow-x: hidden;
}
body.zmw-locked { overflow: hidden; }
html.zmw-theme-anim body, html.zmw-theme-anim .zmw-side, html.zmw-theme-anim .zm-card,
html.zmw-theme-anim .zmw-top, html.zmw-theme-anim .cbi-button { transition: background-color .35s, color .35s, border-color .35s !important; }

a { color: inherit; }
::selection { background: rgba(124,92,255,.35); }

/* Скроллбары: тонкий скруглённый ползунок без стрелок, с отступом от краёв. В Chrome/Safari —
   через ::-webkit-scrollbar (стандартные scrollbar-width/color там отключили бы это оформление и
   вернули системную полосу со стрелками), в Firefox — стандартными свойствами. */
::-webkit-scrollbar { width: 12px; height: 12px; }
::-webkit-scrollbar-button { display: none; width: 0; height: 0; }
::-webkit-scrollbar-track, ::-webkit-scrollbar-corner { background: transparent; }
::-webkit-scrollbar-thumb {
	background: rgba(128,128,140,.38); border-radius: 10px;
	border: 3px solid transparent; background-clip: padding-box; min-height: 36px;
}
::-webkit-scrollbar-thumb:hover { background: rgba(128,128,140,.6); background-clip: padding-box; }
html.zm-theme-dark ::-webkit-scrollbar-thumb { background: rgba(255,255,255,.16); background-clip: padding-box; }
html.zm-theme-dark ::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,.3); background-clip: padding-box; }
@supports not selector(::-webkit-scrollbar) {
	* { scrollbar-width: thin; scrollbar-color: rgba(128,128,140,.45) transparent; }
}
/* Поля с кодом скруглены — полоса не должна залезать на углы. */
#zmw-view .zm-config-editor::-webkit-scrollbar-track, #zmw-view textarea::-webkit-scrollbar-track { margin: 10px 0; }
#zmw-view .zm-config-editor::-webkit-scrollbar-corner, #zmw-view textarea::-webkit-scrollbar-corner, #zmw-view textarea::-webkit-resizer { background: transparent; }

.zmw-i { width: 20px; height: 20px; flex-shrink: 0; display: block; }

/* ───────────── Логотип ───────────── */

.zmw-logo {
	width: 42px; height: 42px; border-radius: 13px;
	background:
		radial-gradient(120% 90% at 30% 0%, rgba(56,189,248,.35), transparent 60%),
		linear-gradient(160deg, #13223f 0%, #0a1426 55%, #060c18 100%);
	display: grid; place-items: center; flex-shrink: 0;
	box-shadow: 0 8px 22px -8px rgba(14,165,233,.75), inset 0 1px 0 rgba(255,255,255,.14), inset 0 0 0 1px rgba(56,189,248,.28);
	position: relative;
	overflow: visible;
}
.zmw-logo svg { width: 32px; height: 32px; filter: drop-shadow(0 0 6px rgba(56,189,248,.55)) drop-shadow(0 2px 2px rgba(0,0,0,.45)); }
.zmw-logo-lg { width: 76px; height: 76px; border-radius: 22px; margin: 0 auto 18px; }
.zmw-logo-lg svg { width: 58px; height: 58px; animation: zmw-zap 4.5s ease-in-out infinite; }
.zmw-logo-lg::after {
	content: ""; position: absolute; inset: -12px; border-radius: 30px;
	background: radial-gradient(circle, rgba(14,165,233,.55), rgba(124,92,255,.25) 60%, transparent 75%);
	filter: blur(18px); z-index: -1;
}
@keyframes zmw-zap {
	0%, 86%, 100% { filter: drop-shadow(0 0 8px rgba(56,189,248,.55)) drop-shadow(0 2px 2px rgba(0,0,0,.45)); }
	90% { filter: drop-shadow(0 0 18px rgba(125,211,252,1)) drop-shadow(0 0 4px #fff); }
	94% { filter: drop-shadow(0 0 6px rgba(56,189,248,.45)) drop-shadow(0 2px 2px rgba(0,0,0,.45)); }
}

/* ───────────── Кнопки-иконки ───────────── */

.zmw-icon-btn {
	display: inline-flex; align-items: center; justify-content: center; gap: 8px;
	height: 40px; min-width: 40px; padding: 0 10px;
	border-radius: 12px; border: 1px solid var(--border);
	background: var(--surface); color: var(--text-2);
	cursor: pointer; font: 600 13px/1 var(--font);
	transition: background .15s, border-color .15s, color .15s, transform .1s;
	backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px);
}
.zmw-icon-btn:hover { border-color: var(--border-2); color: var(--text); background: var(--surface-solid); }
.zmw-icon-btn:active { transform: scale(.96); }
.zmw-icon-btn:focus-visible { outline: none; box-shadow: var(--ring); }
.zmw-icon-btn .zmw-i { width: 19px; height: 19px; }
.zmw-spin .zmw-i { animation: zmw-spin .7s cubic-bezier(.4,0,.2,1); }
@keyframes zmw-spin { to { transform: rotate(360deg); } }

/* ───────────── Оболочка ───────────── */

.zmw-shell { display: flex; min-height: 100vh; opacity: 0; transition: opacity .35s; }
body.zmw-ready .zmw-shell { opacity: 1; }
body.zmw-locked .zmw-shell { filter: blur(6px); pointer-events: none; }

.zmw-side {
	position: sticky; top: 0; height: 100vh;
	width: var(--side-w); flex-shrink: 0;
	display: flex; flex-direction: column;
	padding: 20px 14px 16px;
	background: var(--side-bg);
	border-right: 1px solid var(--border);
	backdrop-filter: blur(18px) saturate(140%); -webkit-backdrop-filter: blur(18px) saturate(140%);
	z-index: 40;
	overflow-y: auto;
}

.zmw-brand { display: flex; align-items: center; gap: 12px; padding: 2px 8px 14px; }
.zmw-brand-text { min-width: 0; flex: 1; }
.zmw-brand-name { font-weight: 750; font-size: 16px; letter-spacing: -.01em; }
.zmw-brand-sub { font-size: 12px; color: var(--muted); margin-top: 1px; }
.zmw-drawer-close { display: none; }

.zmw-update {
	display: block; margin: 0 6px 12px; padding: 9px 12px;
	border-radius: 12px; font-size: 12.5px; font-weight: 600; text-decoration: none;
	color: var(--text); background: var(--grad-soft); border: 1px solid rgba(124,92,255,.35);
}
.zmw-update::before { content: "✦ "; color: var(--a1); }
.zmw-update[hidden] { display: none; }

.zmw-nav { display: flex; flex-direction: column; gap: 2px; flex: 1; }
.zmw-nav-group {
	font-size: 11px; font-weight: 700; letter-spacing: .08em; text-transform: uppercase;
	color: var(--muted); opacity: .8; padding: 12px 12px 4px;
}
.zmw-nav-group:first-child { padding-top: 4px; }
.zmw-nav-item {
	position: relative;
	display: flex; align-items: center; gap: 12px;
	padding: 5px 12px; border-radius: 12px;
	text-decoration: none; color: var(--text-2);
	font-weight: 550; font-size: 14px;
	transition: background .15s, color .15s;
}
.zmw-nav-item:hover { background: var(--surface-2); color: var(--text); }
.zmw-nav-ico {
	width: 28px; height: 28px; border-radius: 10px;
	display: grid; place-items: center; flex-shrink: 0;
	background: var(--surface-2); border: 1px solid var(--border);
	color: var(--muted);
	transition: background .2s, color .2s, border-color .2s, box-shadow .2s;
}
.zmw-nav-ico .zmw-i { width: 18px; height: 18px; }
.zmw-nav-label { flex: 1; min-width: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.zmw-nav-item.zmw-active { background: var(--grad-soft); color: var(--text); }
.zmw-nav-item.zmw-active::before {
	content: ""; position: absolute; left: -9px; top: 10px; bottom: 10px; width: 4px;
	border-radius: 4px; background: var(--grad);
}
.zmw-nav-item.zmw-active .zmw-nav-ico {
	background: var(--grad); color: #fff; border-color: transparent;
	box-shadow: 0 6px 16px -6px rgba(99,102,241,.8);
}
.zmw-nav-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; display: none; }
.zmw-nav-dot.zmw-on, .zmw-nav-dot.zmw-stop, .zmw-nav-dot.zmw-part { display: block; }
.zmw-nav-dot.zmw-part { background: var(--warn-dot); box-shadow: 0 0 0 3px var(--warn-bg), 0 0 10px var(--warn-dot); }
.zmw-nav-dot.zmw-on { background: var(--ok-dot); box-shadow: 0 0 0 3px var(--ok-bg), 0 0 10px var(--ok-dot); }
.zmw-nav-dot.zmw-stop { background: var(--bad-dot); box-shadow: 0 0 0 3px var(--bad-bg), 0 0 10px var(--bad-dot); animation: zmw-blink 1.6s ease-in-out infinite; }
@keyframes zmw-blink { 50% { opacity: .45; } }

.zmw-side-foot { display: flex; flex-direction: column; gap: 9px; padding: 14px 6px 0; margin-top: 12px; border-top: 1px solid var(--border); }
.zmw-pill {
	display: flex; align-items: center; gap: 10px;
	padding: 8px 12px; border-radius: 12px; text-decoration: none;
	font-weight: 650; font-size: 13px;
	border: 1px solid var(--border);
	background: var(--surface-2);
}
.zmw-pill-dot { width: 9px; height: 9px; border-radius: 50%; flex-shrink: 0; background: var(--off); }
.zmw-pill-ok { color: var(--ok); background: var(--ok-bg); border-color: transparent; }
.zmw-pill-ok .zmw-pill-dot { background: var(--ok-dot); animation: zmw-pulse 2.2s infinite; }
.zmw-pill-bad { color: var(--bad); background: var(--bad-bg); border-color: transparent; }
.zmw-pill-bad .zmw-pill-dot { background: var(--bad-dot); }
.zmw-pill-off { color: var(--muted); }
@keyframes zmw-pulse {
	0% { box-shadow: 0 0 0 0 rgba(16,185,129,.55); }
	70% { box-shadow: 0 0 0 8px rgba(16,185,129,0); }
	100% { box-shadow: 0 0 0 0 rgba(16,185,129,0); }
}
.zmw-device { padding: 2px 6px 9px; border-bottom: 1px dashed var(--border); }
.zmw-device-sub:empty { display: none; }
.zmw-device-model { font-size: 12.5px; line-height: 1.35; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-weight: 650; color: var(--text); overflow-wrap: anywhere; }
.zmw-device-sub { font-size: 11.5px; color: var(--muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.zmw-side-links { display: flex; gap: 6px; }
.zmw-side-links a {
	flex: 1; padding: 8px 10px !important; display: inline-flex; align-items: center; justify-content: center; gap: 6px;
	padding: 7px 8px; border-radius: 10px; border: 1px solid var(--border);
	font-size: 12.5px; font-weight: 600; text-decoration: none; color: var(--text-2);
	transition: background .15s, color .15s;
}
.zmw-side-links a:hover { background: var(--surface-2); color: var(--text); }
.zmw-side-links .zmw-i { width: 15px; height: 15px; }
.zmw-mem { display: flex; flex-direction: column; gap: 9px; padding: 2px 6px; }
.zmw-mem:empty { display: none; }
.zmw-mem-head { display: flex; justify-content: space-between; gap: 8px; font-size: 11.5px; margin-bottom: 4px; }
.zmw-mem-label { color: var(--muted); font-weight: 600; }
.zmw-mem-val { color: var(--text-2); font-weight: 600; font-variant-numeric: tabular-nums; white-space: nowrap; }
.zmw-mem-bar { height: 6px; border-radius: 6px; background: var(--surface-3); overflow: hidden; }
.zmw-mem-bar i { display: block; height: 100%; width: 0; border-radius: 6px; background: var(--grad); transition: width .6s cubic-bezier(.2,.8,.2,1); }
.zmw-mem-mid .zmw-mem-bar i { background: linear-gradient(90deg, #f59e0b, #fbbf24); }
.zmw-mem-hi .zmw-mem-bar i { background: linear-gradient(90deg, #ef4444, #f87171); }
/* те же шкалы в «Системе» на дашборде — крупнее, под текст карточки */
#zmw-view .zm-meter .zmw-mem-head { font-size: 13px; margin-bottom: 6px; align-items: baseline; }
#zmw-view .zm-meter .zmw-mem-label { font-weight: 500; }
.zmw-credit { font-size: 11.5px; color: var(--muted); text-align: center; opacity: .7; }

.zmw-main { flex: 1; min-width: 0; display: flex; flex-direction: column; }

.zmw-top {
	position: sticky; top: 0; z-index: 30;
	display: flex; align-items: center; gap: 14px;
	padding: 18px 32px;
	background: linear-gradient(to bottom, var(--bg) 30%, transparent);
}
html[data-theme="dark"] .zmw-top { background: linear-gradient(to bottom, rgba(7,9,15,.92) 35%, rgba(7,9,15,0)); }
html[data-theme="light"] .zmw-top { background: linear-gradient(to bottom, rgba(243,245,250,.94) 35%, rgba(243,245,250,0)); }
.zmw-burger { display: none; }
.zmw-titles { flex: 1; min-width: 0; }
.zmw-title { margin: 0; font-size: 24px; font-weight: 750; letter-spacing: -.02em; line-height: 1.2; }
.zmw-sub { font-size: 13px; color: var(--muted); margin-top: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.zmw-top-actions { display: flex; gap: 8px; align-items: center; }
.zmw-logout span { padding-right: 2px; }
.zmw-title { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.zmw-link-btn { text-decoration: none; padding: 0 13px; }
.zmw-link-btn .zmw-i { width: 18px; height: 18px; }
.zmw-lbl-short { display: none; }
.zmw-link-kvn {
	color: #fff; border-color: transparent;
	background: var(--grad); background-size: 160% 100%;
	background-origin: border-box; background-repeat: no-repeat;
	box-shadow: 0 8px 20px -10px rgba(99,102,241,.9), inset 0 1px 0 rgba(255,255,255,.22);
	transition: background-position .35s, transform .1s, box-shadow .2s;
}
.zmw-link-kvn:hover { color: #fff; border-color: transparent; background: var(--grad); background-size: 160% 100%; background-origin: border-box; background-repeat: no-repeat; background-position: 100% 0; box-shadow: 0 10px 24px -10px rgba(99,102,241,1), inset 0 1px 0 rgba(255,255,255,.22); }
.zmw-link-tg { color: #229ed9; border-color: rgba(34,158,217,.35); background: rgba(34,158,217,.10); }
.zmw-link-tg:hover { color: #229ed9; border-color: rgba(34,158,217,.6); background: rgba(34,158,217,.16); }
html[data-theme="dark"] .zmw-link-tg, html[data-theme="dark"] .zmw-link-tg:hover { color: #5cc1f0; }
.zmw-top-sep { width: 1px; height: 24px; background: var(--border-2); margin: 0 4px; }
#zmw-view .zm-header-links { display: none; }

.zmw-view { padding: 6px 32px 24px; flex: 1; width: 100%; max-width: 1320px; }
.zmw-foot { padding: 8px 32px 24px; font-size: 12px; color: var(--muted); opacity: .6; }

.zmw-page { animation: zmw-page-in .42s cubic-bezier(.2,.8,.2,1) both; }
@keyframes zmw-page-in { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: none; } }

.zmw-scrim { display: none; }

/* ───────────── Скелетон / ошибка ───────────── */

.zmw-skel-wrap { display: flex; flex-direction: column; gap: 16px; }
.zmw-skel-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; }
.zmw-skel {
	border-radius: var(--radius);
	background: linear-gradient(90deg, var(--surface-2) 0%, var(--surface-3) 40%, var(--surface-2) 80%);
	background-size: 300% 100%;
	animation: zmw-shimmer 1.4s infinite linear;
	border: 1px solid var(--border);
}
.zmw-skel-bar { height: 64px; }
.zmw-skel-card { height: 170px; }
.zmw-skel-wide { height: 240px; }
@keyframes zmw-shimmer { from { background-position: 100% 0; } to { background-position: -200% 0; } }

.zmw-error {
	display: flex; gap: 16px; align-items: flex-start;
	padding: 22px 24px; border-radius: var(--radius);
	background: var(--surface); border: 1px solid rgba(239,68,68,.3);
	box-shadow: var(--shadow);
}
.zmw-error-ico { width: 44px; height: 44px; border-radius: 12px; display: grid; place-items: center; background: var(--bad-bg); color: var(--bad); flex-shrink: 0; }
.zmw-error h3 { margin: 0 0 6px; font-size: 16px; }
.zmw-error p { margin: 0 0 14px; color: var(--muted); overflow-wrap: anywhere; }

/* ───────────── Вход ───────────── */

.zmw-login {
	position: fixed; inset: 0; z-index: 200;
	display: grid; place-items: center; padding: 20px;
	background: var(--bg);
	overflow: auto;
	animation: zmw-fade .4s ease both;
}
.zmw-login.zmw-leave { animation: zmw-fade-out .38s ease both; }
@keyframes zmw-fade { from { opacity: 0; } to { opacity: 1; } }
@keyframes zmw-fade-out { to { opacity: 0; transform: scale(1.02); } }

.zmw-orbs { position: absolute; inset: 0; overflow: hidden; pointer-events: none; }
.zmw-orbs i { position: absolute; border-radius: 50%; filter: blur(70px); opacity: .55; }
.zmw-orbs i:nth-child(1) { width: 520px; height: 520px; background: #7c5cff; left: -140px; top: -160px; animation: zmw-float1 18s ease-in-out infinite alternate; }
.zmw-orbs i:nth-child(2) { width: 460px; height: 460px; background: #22d3ee; right: -140px; bottom: -160px; opacity: .38; animation: zmw-float2 22s ease-in-out infinite alternate; }
.zmw-orbs i:nth-child(3) { width: 320px; height: 320px; background: #3b82f6; right: 18%; top: 12%; opacity: .25; animation: zmw-float1 26s ease-in-out infinite alternate-reverse; }
html[data-theme="light"] .zmw-orbs i { opacity: .28; }
@keyframes zmw-float1 { to { transform: translate(120px, 80px) scale(1.1); } }
@keyframes zmw-float2 { to { transform: translate(-100px, -60px) scale(1.15); } }

.zmw-grid-bg {
	position: absolute; inset: 0; pointer-events: none;
	background-image:
		linear-gradient(var(--border) 1px, transparent 1px),
		linear-gradient(90deg, var(--border) 1px, transparent 1px);
	background-size: 44px 44px;
	-webkit-mask-image: radial-gradient(ellipse at center, #000 20%, transparent 70%);
	mask-image: radial-gradient(ellipse at center, #000 20%, transparent 70%);
	opacity: .7;
}

.zmw-login-card {
	position: relative; z-index: 1;
	width: 100%; max-width: 400px;
	padding: 36px 32px 28px;
	border-radius: 26px;
	background: var(--surface);
	border: 1px solid var(--border-2);
	box-shadow: var(--shadow-lg);
	backdrop-filter: blur(24px) saturate(150%); -webkit-backdrop-filter: blur(24px) saturate(150%);
	text-align: center;
	animation: zmw-card-in .6s cubic-bezier(.2,.8,.2,1) both;
}
@keyframes zmw-card-in { from { opacity: 0; transform: translateY(18px) scale(.98); } to { opacity: 1; transform: none; } }
.zmw-login-card h1 {
	margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -.02em;
	background: linear-gradient(135deg, var(--text) 30%, var(--a1) 75%, var(--a3));
	-webkit-background-clip: text; background-clip: text; color: transparent;
}
.zmw-login-sub { margin: 6px 0 24px; color: var(--muted); font-size: 13.5px; }
.zmw-login-sub b { color: var(--text-2); font-weight: 650; }
.zmw-shake { animation: zmw-shake .45s cubic-bezier(.36,.07,.19,.97) both; }
@keyframes zmw-shake { 10%,90% { transform: translateX(-1px); } 20%,80% { transform: translateX(3px); } 30%,50%,70% { transform: translateX(-6px); } 40%,60% { transform: translateX(6px); } }

.zmw-field { display: block; text-align: left; margin-bottom: 14px; }
.zmw-field-label { display: block; font-size: 12.5px; font-weight: 650; color: var(--text-2); margin: 0 0 6px 2px; }
.zmw-input {
	display: flex; align-items: center; gap: 10px;
	height: 48px; padding: 0 6px 0 14px;
	border-radius: 14px; border: 1px solid var(--border-2);
	background: var(--input-bg);
	color: var(--muted);
	transition: border-color .15s, box-shadow .15s;
}
.zmw-input:focus-within { border-color: var(--a1); box-shadow: var(--ring); color: var(--a1); }
.zmw-input .zmw-i { width: 18px; height: 18px; }
.zmw-input input {
	flex: 1; min-width: 0; height: 100%;
	border: 0; outline: 0; background: transparent;
	color: var(--text); font: 500 15px/1 var(--font);
}
.zmw-input input::placeholder { color: var(--muted); opacity: .6; }
.zmw-eye { border: 0; background: transparent; color: var(--muted); width: 36px; height: 36px; border-radius: 10px; display: grid; place-items: center; cursor: pointer; }
.zmw-eye:hover { background: var(--surface-2); color: var(--text); }

.zmw-check { display: flex; align-items: center; gap: 10px; margin: 4px 2px 16px; font-size: 13px; color: var(--text-2); cursor: pointer; text-align: left; user-select: none; }
.zmw-check input { position: absolute; opacity: 0; pointer-events: none; }
.zmw-check-box {
	width: 20px; height: 20px; border-radius: 7px; flex-shrink: 0;
	border: 1.5px solid var(--border-2); background: var(--input-bg);
	display: grid; place-items: center; transition: background .15s, border-color .15s;
}
.zmw-check input:checked + .zmw-check-box { background: var(--grad); border-color: transparent; }
.zmw-check input:checked + .zmw-check-box::after { content: ""; width: 10px; height: 5px; border: 2px solid #fff; border-top: 0; border-right: 0; transform: rotate(-45deg) translate(1px, -1px); }
.zmw-check input:focus-visible + .zmw-check-box { box-shadow: var(--ring); }

.zmw-login-msg { display: none; text-align: left; font-size: 13px; font-weight: 550; padding: 10px 12px; border-radius: 12px; margin-bottom: 14px; }
.zmw-login-msg.zmw-show { display: block; }
.zmw-login-msg.zmw-error { background: var(--bad-bg); color: var(--bad); }
.zmw-login-msg.zmw-warning { background: var(--warn-bg); color: var(--warn); }
.zmw-login-msg.zmw-info { background: var(--grad-soft); color: var(--text-2); }

.zmw-btn-primary {
	position: relative; width: 100%; height: 50px;
	display: inline-flex; align-items: center; justify-content: center; gap: 8px;
	border: 0; border-radius: 14px; cursor: pointer;
	background: var(--grad); background-size: 160% 100%; background-position: 0 0;
	color: #fff; font: 700 15px/1 var(--font); letter-spacing: .01em;
	box-shadow: 0 12px 28px -10px rgba(99,102,241,.8), inset 0 1px 0 rgba(255,255,255,.25);
	transition: background-position .35s, transform .1s, box-shadow .2s;
}
.zmw-btn-primary:hover { background-position: 100% 0; box-shadow: 0 16px 32px -10px rgba(99,102,241,.9), inset 0 1px 0 rgba(255,255,255,.25); }
.zmw-btn-primary:active { transform: scale(.985); }
.zmw-btn-primary:focus-visible { outline: none; box-shadow: var(--ring), 0 12px 28px -10px rgba(99,102,241,.8); }
.zmw-btn-primary .zmw-i { width: 18px; height: 18px; transition: transform .2s; }
.zmw-btn-primary:hover .zmw-i { transform: translateX(3px); }
.zmw-btn-primary.zmw-loading span, .zmw-btn-primary.zmw-loading .zmw-i { opacity: 0; }
.zmw-btn-primary.zmw-loading::after {
	content: ""; position: absolute; width: 20px; height: 20px; border-radius: 50%;
	border: 2.5px solid rgba(255,255,255,.35); border-top-color: #fff;
	animation: zmw-spin .7s linear infinite;
}
.zmw-login-foot { margin-top: 18px; font-size: 12.5px; color: var(--muted); }
.zmw-login-theme { position: absolute; top: 18px; right: 18px; z-index: 2; }

/* ───────────── Модальное окно ───────────── */

.zmw-modal-wrap { position: fixed; inset: 0; z-index: 300; display: grid; place-items: center; padding: 20px; background: rgba(5,7,12,.55); backdrop-filter: blur(6px); opacity: 0; transition: opacity .2s; }
.zmw-modal-wrap.zmw-in { opacity: 1; }
.zmw-modal { width: 100%; max-width: 560px; max-height: 85vh; overflow: auto; padding: 24px; border-radius: 20px; background: var(--surface-solid); border: 1px solid var(--border-2); box-shadow: var(--shadow-lg); }
.zmw-modal h3 { margin: 0 0 12px; }

/* ═════════════ Компоненты страниц (перекрывают style.css LuCI) ═════════════ */

#zmw-view .zm-wrap { max-width: none; gap: 18px; }
#zmw-view .zm-webui-link { display: none !important; }

#zmw-view .zm-header { align-items: center; gap: 12px; margin: 0; padding: 20px 24px; border-radius: var(--radius); background: var(--grad-soft); border: 1px solid rgba(124,92,255,.22); position: relative; overflow: hidden; }
#zmw-view .zm-header::after { content: ""; position: absolute; right: -60px; top: -80px; width: 240px; height: 240px; border-radius: 50%; background: var(--grad); filter: blur(60px); opacity: .22; pointer-events: none; }
#zmw-view .zm-header h2 { font-size: 22px; font-weight: 800; letter-spacing: -.02em; background: linear-gradient(135deg, var(--text) 35%, var(--a1) 80%, var(--a3)); -webkit-background-clip: text; background-clip: text; color: transparent; }
#zmw-view .zm-header-by { opacity: 1; color: var(--muted); font-size: 13px; }
#zmw-view .zm-header-links { position: relative; z-index: 1; }
#zmw-view .zm-header-links a {
	color: var(--text); background: var(--surface); border: 1px solid var(--border-2);
	padding: 7px 14px; font-size: 12.5px; font-weight: 650; border-radius: 999px;
	backdrop-filter: blur(8px);
	transition: border-color .15s, transform .15s, background .15s;
}
#zmw-view .zm-header-links a:hover { border-color: var(--a1); transform: translateY(-1px); background: var(--surface-solid); }

#zmw-view :not(.zm-cards) > .zm-card + .zm-current-banner,
#zmw-view .zm-current-banner + .zm-card,
#zmw-view :not(.zm-cards) > .zm-card + .zm-log,
#zmw-view .zm-card + .zm-refresh-banner,
#zmw-view .zm-card + .zm-cards,
#zmw-view .zm-cards + .zm-card { margin-top: 18px; }
#zmw-view .zm-wrap > * + * { margin-top: 0 !important; }
#zmw-view :not(.zm-cards):not(.bt-cols):not(.zm-wrap) > .zm-card:not(:last-child) { margin-bottom: 18px; }
#zmw-view .zm-current-banner { margin-bottom: 0; }

#zmw-view .zm-cards { grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 18px; }

#zmw-view .zm-card {
	background: var(--surface);
	border: 1px solid var(--border);
	border-radius: var(--radius);
	padding: 22px 24px;
	box-shadow: var(--shadow);
	backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px);
	color: var(--text);
	transition: border-color .2s, box-shadow .2s;
}
#zmw-view .zm-card:hover { border-color: var(--border-2); box-shadow: var(--shadow); }
#zmw-view .zm-card h3 { margin: 0 0 14px; font-size: 16px; font-weight: 700; letter-spacing: -.01em; color: var(--text); }
#zmw-view .zm-card h3::before {
	content: ""; width: 4px; height: 18px; border-radius: 4px; background: var(--grad); flex-shrink: 0;
}
#zmw-view .zm-card h4 { color: var(--text); }
#zmw-view .zm-card p { color: var(--text-2); }

#zmw-view .zm-row { font-size: 13.5px; margin: 9px 0; gap: 12px; }
#zmw-view .zm-row .zm-label { opacity: 1; color: var(--muted); }
#zmw-view .bt-cols { column-gap: 48px; }
#zmw-view .bt-col .zm-row { padding: 6px 0; margin: 0; border-bottom: 1px dashed var(--border); }
#zmw-view .bt-col .zm-row:last-child { border-bottom: 0; }

#zmw-view .zm-hint, #zmw-view p.zm-hint { opacity: 1; color: var(--muted); font-size: 12.5px; line-height: 1.6; }
#zmw-view a:not(.cbi-button) { color: var(--a2); text-decoration-color: rgba(59,130,246,.35); text-underline-offset: 3px; }
html[data-theme="dark"] #zmw-view a:not(.cbi-button) { color: #8ab4ff; }

/* бейджи */
#zmw-view .zm-badge { padding: 4px 11px 4px 9px; font-size: 12px; font-weight: 650; gap: 7px; letter-spacing: .01em; }
#zmw-view .zm-ok { background: var(--ok-bg); color: var(--ok); }
#zmw-view .zm-ok .zm-dot { background: var(--ok-dot); box-shadow: 0 0 8px var(--ok-dot); animation: zmw-pulse 2.4s infinite; }
#zmw-view .zm-bad { background: var(--bad-bg); color: var(--bad); }
#zmw-view .zm-bad .zm-dot { background: var(--bad-dot); }
#zmw-view .zm-warn { background: var(--warn-bg); color: var(--warn); }
#zmw-view .zm-warn .zm-dot { background: var(--warn-dot); }
#zmw-view .zm-off { background: var(--off-bg); color: var(--off); }
#zmw-view .zm-off .zm-dot { background: var(--off); }

/* кнопки */
#zmw-view .cbi-button, .zmw-modal .cbi-button, .zm-refresh-banner .cbi-button {
	display: inline-flex; align-items: center; justify-content: center; gap: 6px;
	min-height: 38px; height: auto; padding: 8px 16px; margin: 0;
	border-radius: 12px; border: 1px solid var(--border-2);
	background: var(--surface-solid); color: var(--text);
	font: 600 13.5px/1.25 var(--font); letter-spacing: .005em;
	text-decoration: none; white-space: normal; text-align: center;
	cursor: pointer; box-shadow: 0 1px 2px rgba(0,0,0,.06);
	transition: border-color .15s, background .15s, transform .1s, box-shadow .15s, color .15s;
	-webkit-appearance: none; appearance: none;
}
html[data-theme="dark"] #zmw-view .cbi-button { background: rgba(255,255,255,.05); }
#zmw-view .cbi-button:hover { border-color: rgba(124,92,255,.55); background: var(--surface-solid); transform: translateY(-1px); box-shadow: 0 6px 16px -10px rgba(99,102,241,.6); }
html[data-theme="dark"] #zmw-view .cbi-button:hover { background: rgba(255,255,255,.08); }
#zmw-view .cbi-button:active { transform: translateY(0) scale(.98); }
#zmw-view .cbi-button:focus-visible { outline: none; box-shadow: var(--ring); }
#zmw-view .cbi-button[disabled], #zmw-view .cbi-button:disabled { opacity: .5; cursor: not-allowed; transform: none; box-shadow: none; }

#zmw-view .cbi-button-positive, .zm-refresh-banner .cbi-button-positive,
html[data-theme="dark"] #zmw-view .cbi-button-positive {
	background: var(--grad); background-size: 150% 100%; color: #fff; border-color: transparent;
	box-shadow: 0 8px 20px -10px rgba(99,102,241,.9), inset 0 1px 0 rgba(255,255,255,.22);
}
#zmw-view .cbi-button-positive:hover, html[data-theme="dark"] #zmw-view .cbi-button-positive:hover {
	background: var(--grad); background-size: 150% 100%; background-position: 100% 0;
	border-color: transparent; color: #fff;
	box-shadow: 0 12px 26px -10px rgba(99,102,241,1), inset 0 1px 0 rgba(255,255,255,.22);
}
#zmw-view .cbi-button-remove, html[data-theme="dark"] #zmw-view .cbi-button-remove {
	background: var(--bad-bg); color: var(--bad); border-color: rgba(239,68,68,.28); box-shadow: none;
}
#zmw-view .cbi-button-remove:hover, html[data-theme="dark"] #zmw-view .cbi-button-remove:hover {
	background: rgba(239,68,68,.18); border-color: rgba(239,68,68,.5); color: var(--bad);
	box-shadow: 0 8px 20px -12px rgba(239,68,68,.8);
}

#zmw-view .zm-actions { gap: 10px; margin: 16px 0; }

/* вкладки внутри страниц — сегментированный переключатель */
#zmw-view .zm-actions.zmw-tabs {
	display: flex; flex-wrap: nowrap; gap: 4px;
	padding: 5px; margin: 0 0 4px !important;
	border-radius: 16px; background: var(--surface); border: 1px solid var(--border);
	box-shadow: var(--shadow);
	overflow-x: auto; scrollbar-width: none;
	backdrop-filter: blur(14px);
	width: max-content; max-width: 100%;
}
#zmw-view .zm-actions.zmw-tabs::-webkit-scrollbar { display: none; }
#zmw-view .zmw-tabs .cbi-button {
	flex-shrink: 0; white-space: nowrap;
	border: 0; background: transparent; box-shadow: none; color: var(--muted);
	min-height: 36px; padding: 7px 16px; border-radius: 11px;
}
#zmw-view .zmw-tabs .cbi-button:hover { background: var(--surface-2); color: var(--text); transform: none; box-shadow: none; }
#zmw-view .zmw-tabs .cbi-button-positive, #zmw-view .zmw-tabs .cbi-button-positive:hover {
	background: var(--grad); color: #fff;
	box-shadow: 0 6px 16px -8px rgba(99,102,241,.9);
}

/* поля ввода */
#zmw-view .cbi-input-text, #zmw-view input[type="text"], #zmw-view input[type="number"],
#zmw-view input[type="password"], #zmw-view input[type="url"], #zmw-view select, #zmw-view .bt-input,
.zmw-modal input[type="text"], .zmw-modal select {
	height: 40px; padding: 0 14px;
	border-radius: 12px; border: 1px solid var(--border-2);
	background: var(--input-bg); color: var(--text);
	font: 500 14px/1 var(--font);
	outline: none; box-shadow: none;
	transition: border-color .15s, box-shadow .15s;
	max-width: 100%;
}
#zmw-view select, .zmw-modal select {
	-webkit-appearance: none; appearance: none; cursor: pointer;
	padding-right: 38px;
	background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%238a93a8' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
	background-repeat: no-repeat; background-position: right 12px center; background-size: 16px;
}
#zmw-view select option { background: var(--surface-solid); color: var(--text); }
#zmw-view .zm-hour-select { min-width: 120px; font-variant-numeric: tabular-nums; }
#zmw-view .zm-actions > .cbi-input-text[type="text"] { flex: 1 1 240px; min-width: 0; }
#zmw-view .cbi-input-text:focus, #zmw-view input:focus, #zmw-view select:focus, #zmw-view .bt-input:focus { border-color: var(--a1); box-shadow: var(--ring); }
#zmw-view input::placeholder { color: var(--muted); opacity: .7; }

/* плитки */
#zmw-view .zm-grid { gap: 10px; }
#zmw-view .zm-grid-devices { gap: 10px; grid-template-columns: repeat(auto-fill, minmax(170px, 1fr)); }
#zmw-view .zm-tile {
	background: var(--surface-2);
	border: 1px solid var(--border);
	border-radius: 13px;
	padding: 11px 16px;
	font-size: 13.5px; font-weight: 550; color: var(--text-2);
	transition: border-color .15s, background .15s, transform .12s, box-shadow .15s, color .15s;
}
html.zm-theme-dark #zmw-view .zm-tile:not(.zm-active):not(.zm-tile-off) { background: var(--surface-2); border-color: var(--border); }
#zmw-view .zm-tile:hover { border-color: rgba(124,92,255,.55); color: var(--text); transform: translateY(-2px); box-shadow: 0 10px 20px -14px rgba(99,102,241,.7); }
html.zm-theme-dark #zmw-view .zm-tile:not(.zm-active):not(.zm-tile-off):hover { border-color: rgba(124,92,255,.55); }
#zmw-view .zm-tile.zm-active {
	background: var(--grad-soft);
	border-color: rgba(124,92,255,.65);
	color: var(--text); font-weight: 700;
	box-shadow: 0 0 0 1px rgba(124,92,255,.45) inset, 0 10px 24px -14px rgba(99,102,241,.9);
}
#zmw-view .zm-tile.zm-active::before { content: "✓ "; color: var(--a1); font-weight: 800; }
html[data-theme="dark"] #zmw-view .zm-tile.zm-active::before { color: #a594ff; }
#zmw-view .zm-tile.zm-tile-off { background: var(--bad-bg); border-color: rgba(239,68,68,.35); color: var(--bad); }
#zmw-view .zm-tile.zm-tile-pending { opacity: .5; }

/* консоль */
#zmw-view .zm-log {
	background: var(--console);
	color: #dfe6f3;
	border: 1px solid var(--console-border);
	border-radius: 16px;
	padding: 0 20px 18px;
	font: 13px/1.75 var(--mono);
	box-shadow: inset 0 1px 0 rgba(255,255,255,.04), var(--shadow);
	position: relative;
	background-image: none;
	overflow-x: hidden; overflow-y: auto;
	/* Свой скроллбар (ниже) — стандартные свойства в Chrome его бы отключили. */
	scrollbar-width: auto; scrollbar-color: auto;
}
/* Шапка с «огоньками» закреплена сверху: текст при прокрутке уходит под неё, а не наезжает. */
#zmw-view .zm-log::before {
	content: ''; display: block;
	position: sticky; top: 0; z-index: 2;
	height: 40px; margin: 0 -20px 6px;
	background:
		radial-gradient(circle at 20px 20px, #ff5f57 5px, transparent 5.5px),
		radial-gradient(circle at 38px 20px, #febc2e 5px, transparent 5.5px),
		radial-gradient(circle at 56px 20px, #28c840 5px, transparent 5.5px),
		var(--console);
	background-repeat: no-repeat;
	opacity: 1;
}
#zmw-view .zm-log:empty::before { content: ''; opacity: 1; }
#zmw-view .zm-log:empty::after { content: "Ожидание вывода..."; color: #8b949e; }
#zmw-view .zm-log.bt-panel { padding-top: 16px; }
#zmw-view .zm-log.bt-panel::before { display: none; }
/* Скроллбар консоли: тонкий, скруглённый, с отступами — не залезает на шапку и углы. */
#zmw-view .zm-log::-webkit-scrollbar { width: 14px; height: 14px; }
#zmw-view .zm-log::-webkit-scrollbar-track { background: transparent; margin: 44px 0 12px; }
#zmw-view .zm-log.bt-panel::-webkit-scrollbar-track { margin: 12px 0; }
#zmw-view .zm-log::-webkit-scrollbar-thumb {
	background: rgba(255,255,255,.18); border-radius: 10px;
	border: 4px solid transparent; background-clip: padding-box; min-height: 40px;
}
#zmw-view .zm-log::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,.32); background-clip: padding-box; }
#zmw-view .zm-log::-webkit-scrollbar-corner { background: transparent; }
@supports not selector(::-webkit-scrollbar) {
	#zmw-view .zm-log { scrollbar-width: thin; scrollbar-color: rgba(255,255,255,.25) transparent; }
}
#zmw-view .zm-log-arrow { color: #67e8f9; }
#zmw-view .zm-log-msg-info { color: #fcd34d; }
#zmw-view .zm-log-msg-ok { color: #4ade80; }
#zmw-view .zm-log-msg-error { color: #fb7185; }
#zmw-view .zm-log-msg-warn { color: #fdba74; }
#zmw-view .zm-log-code { color: #94a3b8; }

#zmw-view .zm-config-editor {
	background: var(--console); color: #e2e8f0;
	border: 1px solid var(--console-border); border-radius: 16px;
	padding: 16px 18px; font: 13px/1.65 var(--mono);
	outline: none;
	transition: border-color .15s, box-shadow .15s;
}
#zmw-view .zm-config-editor:focus { border-color: var(--a1); box-shadow: var(--ring); }

/* баннеры */
#zmw-view .zm-refresh-banner, .zm-refresh-banner {
	background: var(--warn-bg); border: 1px solid rgba(245,158,11,.35);
	color: var(--warn); border-radius: var(--radius); padding: 14px 18px;
	font-size: 14px; font-weight: 600; margin-top: 0;
}
#zmw-view .zm-current-banner {
	background: var(--grad-soft); border: 1px solid rgba(124,92,255,.28);
	border-radius: 14px; padding: 12px 16px; font-size: 13.5px; color: var(--text);
}
#zmw-view .zm-current-banner.zm-current-empty { background: var(--surface-2); border-color: var(--border); color: var(--muted); }
#zmw-view .zm-current-banner.zm-current-top { margin: 14px 0 0 !important; }
#zmw-view .zm-current-banner.zm-current-top + .zm-card { margin-top: 18px !important; }
#zmw-view .bt-current-cmd { background: var(--console); color: #86efac; border-radius: 12px; font-family: var(--mono); }

/* Telegram */
#zmw-view .zm-tg-link-card { background: var(--ok-bg); border: 1px solid rgba(16,185,129,.28); border-radius: 16px; }
#zmw-view .zm-tg-link-box { background: var(--console); color: #86efac; border-radius: 12px; font-family: var(--mono); font-size: 13.5px; }
#zmw-view .zm-tg-qr-box img { border-radius: 14px; box-shadow: var(--shadow); }

/* Автообход */
#zmw-view .zm-ab-panel { gap: 18px; }
#zmw-view .zm-ab-panel > .zm-card { margin: 0 !important; }
#zmw-view .zm-ab-hero { background: var(--surface); position: relative; overflow: hidden; }
#zmw-view .zm-ab-hero::after {
	content: ""; position: absolute; right: -80px; top: -80px; width: 240px; height: 240px; border-radius: 50%;
	background: radial-gradient(circle, rgba(26,163,255,.16), transparent 70%); pointer-events: none;
}
#zmw-view .zm-ab-hero h3::before, #zmw-view .zm-ab-title h3::before { display: none; }
#zmw-view .zm-ab-foot { border-top-color: var(--border); color: var(--muted); opacity: 1; }
#zmw-view .zm-ab-sum b { color: var(--text); }
#zmw-view .zm-ab-sum-ok b { color: var(--ok); }
#zmw-view .zm-ab-note-warn { background: var(--warn-bg); color: var(--warn); border-color: rgba(245,158,11,.35); }
#zmw-view .zm-ab-step { color: var(--muted); opacity: 1; }
#zmw-view .zm-ab-step::before { background: var(--border-2); }
#zmw-view .zm-ab-step-dot { background: var(--surface-2); border: 1px solid var(--border); }
#zmw-view .zm-ab-step.zm-ab-done { color: var(--text-2); }
#zmw-view .zm-ab-step.zm-ab-done .zm-ab-step-dot { background: var(--ok-dot); border-color: transparent; color: #fff; }
#zmw-view .zm-ab-step.zm-ab-done::before, #zmw-view .zm-ab-step.zm-ab-now::before { background: var(--grad); }
#zmw-view .zm-ab-step.zm-ab-now { color: var(--text); }
#zmw-view .zm-ab-step.zm-ab-now .zm-ab-step-dot { background: var(--grad); border-color: transparent; color: #fff; }
#zmw-view .zm-ab-svc-item, html.zm-theme-dark #zmw-view .zm-ab-svc-item { background: var(--surface-2); border-color: var(--border); border-radius: 13px; }
#zmw-view .zm-ab-svc-item.zm-ab-svc-bad { border-color: rgba(239,68,68,.35); }
#zmw-view .zm-awg-if, html.zm-theme-dark #zmw-view .zm-awg-if { background: var(--surface-2); border-color: var(--border); border-radius: 14px; }
#zmw-view .zm-ab-svc-name { color: var(--text); }
#zmw-view .zm-ab-player video { border-radius: 14px; box-shadow: var(--shadow); }
#zmw-view .zm-ab-logcard .zm-log { margin-top: 0; }

#zmw-view .zm-st-stat, html.zm-theme-dark #zmw-view .zm-st-stat { background: var(--surface-2); border-color: var(--border); border-radius: 14px; }
#zmw-view .zm-st-stat-label { color: var(--muted); opacity: 1; }
#zmw-view .zm-st-stat-value { color: var(--text); }
#zmw-view .zm-st-ok { color: var(--ok); } #zmw-view .zm-st-warn { color: var(--warn); } #zmw-view .zm-st-bad { color: var(--bad); } #zmw-view .zm-st-off { color: var(--muted); opacity: 1; }
#zmw-view .zm-st-promo > div { background: var(--grad-soft); border-color: rgba(124,92,255,.25); border-radius: 14px; }
#zmw-view .zm-st-promo b { color: var(--text); } #zmw-view .zm-st-promo span { color: var(--muted); opacity: 1; }
#zmw-view .zm-svc, html.zm-theme-dark #zmw-view .zm-svc { background: var(--surface-2); border-color: var(--border); border-radius: 14px; }
#zmw-view .zm-svc:hover { border-color: rgba(124,92,255,.55); box-shadow: 0 10px 20px -14px rgba(99,102,241,.7); }
#zmw-view .zm-svc.zm-svc-on, html.zm-theme-dark #zmw-view .zm-svc.zm-svc-on { background: var(--grad-soft); border-color: rgba(124,92,255,.6); }
#zmw-view .zm-svc-name { color: var(--text); } #zmw-view .zm-svc-sub { color: var(--muted); opacity: 1; }
#zmw-view .zm-switch { background: var(--border-2); }
#zmw-view .zm-switch.zm-switch-on { background: var(--grad); }
#zmw-view .zm-st-note-ok { background: var(--ok-bg); color: var(--ok); border-color: rgba(16,185,129,.3); }
#zmw-view .zm-st-note-bad { background: var(--bad-bg); color: var(--bad); border-color: rgba(239,68,68,.3); }
#zmw-view .zm-st-check { color: var(--text); } #zmw-view .zm-st-check-why { color: var(--muted); opacity: 1; }

/* авторы */
#zmw-view .zm-credits-grid { gap: 12px; }
#zmw-view .zm-credit-tile, html.zm-theme-dark #zmw-view .zm-credit-tile {
	background: var(--surface-2); border: 1px solid var(--border); border-radius: 14px; padding: 14px;
	transition: border-color .15s, transform .15s;
}
#zmw-view .zm-credit-tile:hover { border-color: var(--border-2); transform: translateY(-1px); }
#zmw-view .zm-credit-tile.zm-credit-self { background: var(--grad-soft); border-color: rgba(124,92,255,.35); }
#zmw-view .zm-credit-author { color: var(--muted); opacity: 1; }

/* ByeTube таблица */
#zmw-view .bt-table td { border-top-color: rgba(255,255,255,.08); }
#zmw-view .bt-chip { border-radius: 7px; }

/* MagiTrickle и прочие iframe */
#zmw-view iframe { border: 1px solid var(--border-2) !important; border-radius: 16px !important; background: #fff; box-shadow: var(--shadow); }

#zmw-view pre:not(.zm-log) { font-family: var(--mono); }
#zmw-view hr { border: 0; border-top: 1px solid var(--border); }

/* ───────────── Тосты ───────────── */

.zmw-body #zm-toast-container {
	top: auto; bottom: 28px; right: 28px; left: auto;
	gap: 12px; max-width: 520px; width: calc(100% - 56px);
	align-items: flex-end;
	z-index: 400;
	pointer-events: none;
}
/* Цвет тоста противоположен теме: в тёмной — светлый, в светлой — тёмный, чтобы его было сразу видно. */
.zmw-body .zm-toast {
	--toast-bg: #161b26; --toast-fg: #f4f6fb; --toast-border: rgba(255,255,255,.08);
	pointer-events: auto;
	align-items: center; gap: 16px;
	width: 100%;
	padding: 20px 24px 20px 20px;
	border-radius: 18px;
	border: 1px solid var(--toast-border); border-left: 6px solid var(--ok);
	background: var(--toast-bg);
	color: var(--toast-fg);
	box-shadow: 0 18px 50px rgba(0,0,0,.35), 0 2px 8px rgba(0,0,0,.2);
	font-size: 16.5px; font-weight: 600; line-height: 1.45;
	opacity: 0; transform: translateY(16px) scale(.98);
	transition: opacity .25s ease, transform .3s cubic-bezier(.2,.8,.2,1);
}
html.zm-theme-dark .zmw-body .zm-toast, html.zm-theme-dark.zmw-body .zm-toast {
	--toast-bg: #ffffff; --toast-fg: #141821; --toast-border: rgba(0,0,0,.06);
	box-shadow: 0 18px 50px rgba(0,0,0,.55), 0 0 0 1px rgba(255,255,255,.08);
}
.zmw-body .zm-toast-error { border-left-color: var(--bad); }
.zmw-body .zm-toast-warning { border-left-color: var(--warn); }
.zmw-body .zm-toast.zm-toast-show { opacity: 1; transform: none; }
.zmw-body .zm-toast-icon {
	width: 38px; height: 38px; border-radius: 12px;
	display: grid; place-items: center; flex-shrink: 0;
	font-size: 18px; font-weight: 800; line-height: 1;
}
html body.zmw-body .zm-toast .zm-toast-icon { color: #fff; }
html body.zmw-body .zm-toast { background: var(--toast-bg); color: var(--toast-fg); }
.zmw-body .zm-toast-info .zm-toast-icon { background: #1f9d55; }
.zmw-body .zm-toast-error .zm-toast-icon { background: #d93b3b; }
.zmw-body .zm-toast-warning .zm-toast-icon { background: #d08a00; }

/* ───────────── Адаптив ───────────── */

@media (max-width: 1360px) {
	.zmw-lbl-full { display: none; }
	.zmw-lbl-short { display: inline; }
}
@media (max-width: 1180px) {
	.zmw-logout span { display: none; }
}
@media (max-width: 1080px) and (min-width: 961px), (max-width: 760px) {
	.zmw-lbl-short { display: none; }
	.zmw-link-btn { padding: 0 10px; }
	.zmw-sub { display: none; }
}

@media (max-width: 960px) {
	:root { --side-w: min(86vw, 300px); }
	.zmw-side {
		position: fixed; left: 0; top: 0; bottom: 0; height: auto;
		transform: translateX(-104%);
		transition: transform .32s cubic-bezier(.2,.8,.2,1);
		box-shadow: var(--shadow-lg);
		background: var(--surface-solid);
	}
	body.zmw-drawer-open .zmw-side { transform: none; }
	.zmw-drawer-close { display: inline-flex; }
	.zmw-scrim {
		display: block; position: fixed; inset: 0; z-index: 35;
		background: rgba(5,7,12,.5); backdrop-filter: blur(3px);
		opacity: 0; pointer-events: none; transition: opacity .3s;
	}
	body.zmw-drawer-open .zmw-scrim { opacity: 1; pointer-events: auto; }
	body.zmw-drawer-open { overflow: hidden; }
	.zmw-burger { display: inline-flex; }
	.zmw-top { padding: 12px 16px; gap: 10px; }
	.zmw-view { padding: 4px 16px 20px; }
	.zmw-foot { padding: 4px 16px 20px; }
	.zmw-title { font-size: 20px; }
}

@media (max-width: 600px) {
	.zmw-sub { display: none; }
	.zmw-top-actions { gap: 5px; }
	.zmw-top-sep { display: none; }
	.zmw-icon-btn { height: 36px; min-width: 36px; padding: 0 8px; border-radius: 11px; }
	.zmw-link-btn { padding: 0 8px; }
	.zmw-top { gap: 8px; }
	.zmw-title { font-size: 18px; }
	#zmw-view .zm-card { padding: 18px 16px; border-radius: 16px; }
	#zmw-view .zm-cards { grid-template-columns: 1fr; }
	#zmw-view .zm-header { padding: 16px; }
	#zmw-view .zm-header-links { margin-left: 0; }
	#zmw-view .zm-actions .cbi-button { flex: 1 1 auto; }
	#zmw-view .zmw-tabs .cbi-button { flex: 0 0 auto; }
	#zmw-view .zm-actions.zmw-tabs { width: 100%; }
	#zmw-view .zm-refresh-banner, .zm-refresh-banner { flex-direction: column; align-items: stretch; text-align: left; }
	.zmw-brand-name { font-size: 15px; white-space: nowrap; }
	.zmw-nav-item { padding: 7px 12px; }
	.zmw-login-card { padding: 30px 20px 22px; border-radius: 22px; }
	.zmw-body #zm-toast-container { left: 12px; right: 12px; bottom: 12px; width: auto; max-width: none; }
	#zmw-view .zm-log { font-size: 12.5px; padding: 0 14px 14px; }
	#zmw-view .zm-log::before { margin: 0 -14px 6px; }
}

@media (prefers-reduced-motion: reduce) {
	*, *::before, *::after { animation-duration: .01ms !important; animation-iteration-count: 1 !important; transition-duration: .01ms !important; }
}
#zmw-view .zm-node { border-color: var(--border); background: var(--surface-2); border-radius: 14px; }
html.zm-theme-dark #zmw-view .zm-node:not(.zm-active) { background: var(--surface-2); border-color: var(--border); }
#zmw-view .zm-node:hover { border-color: rgba(124,92,255,.55); transform: translateY(-2px); box-shadow: 0 10px 20px -14px rgba(99,102,241,.7); }
#zmw-view .zm-node.zm-active { border-color: rgba(124,92,255,.6); background: var(--grad-soft); box-shadow: var(--ring); }
#zmw-view .zm-node.zm-active .zm-node-name::before { color: var(--a1); }
#zmw-view .zm-node-name { color: var(--text); }
#zmw-view .zm-node-foot > span:first-child { color: var(--muted); opacity: 1; }
#zmw-view .zm-lat-good { color: var(--ok); } #zmw-view .zm-lat-mid { color: var(--warn); } #zmw-view .zm-lat-bad { color: var(--bad); }
#zmw-view .zm-sub-meta { background: var(--grad-soft); border: 1px solid rgba(124,92,255,.22); border-radius: 14px; }
#zmw-view .zm-sub-fact > span { color: var(--muted); opacity: 1; }
#zmw-view .zm-quota { background: var(--surface-3); }
#zmw-view .zm-quota > i { background: var(--grad); }
#zmw-view .zm-quota.zm-quota-high > i { background: var(--bad-dot); }
#zmw-view .zm-seg { background: var(--surface-2); border-color: var(--border); border-radius: 12px; }
#zmw-view .zm-seg-item { border-radius: 9px; color: var(--text-2); }
#zmw-view .zm-seg-item.zm-active { background: var(--grad); color: #fff; box-shadow: 0 6px 16px -10px rgba(99,102,241,.9); }
@media (max-width: 600px) {
	#zmw-view .zm-nodes { grid-template-columns: 1fr 1fr; }
	#zmw-view .zm-sub-meta { flex-direction: column; align-items: flex-start; }
}
#zmw-view .zm-log-bar { top: 46px; }
#zmw-view .zm-log-min { top: -38px; right: -10px; border-radius: 8px; border-color: rgba(255,255,255,.12); background: rgba(255,255,255,.05); color: #cbd5e1; }
#zmw-view .zm-log-min:hover { background: rgba(124,92,255,.35); border-color: rgba(124,92,255,.6); color: #fff; }
#zmw-view .zm-log.zm-log-collapsed { padding-bottom: 12px; }
.zmw-logo, .zmw-logo-lg { background: none; box-shadow: none; border-radius: 0; }
.zmw-logo svg { filter: drop-shadow(0 2px 3px rgba(0,120,220,.25)); }
.zmw-logo-lg::after { opacity: .55; }
html[data-theme="dark"] .zmw-logo svg { filter: drop-shadow(0 0 1px rgba(255,255,255,.55)) drop-shadow(0 0 10px rgba(0,182,255,.45)); }

.zmw-theme-menu {
	position: fixed; z-index: 1000; min-width: 184px; padding: 6px;
	display: flex; flex-direction: column; gap: 2px;
	background: var(--surface-solid); border: 1px solid var(--border-2); border-radius: 14px;
	box-shadow: var(--shadow-lg); animation: zmw-menu-in .14s ease-out;
}
@keyframes zmw-menu-in { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: none; } }
.zmw-theme-opt {
	display: flex; align-items: center; gap: 10px; width: 100%; padding: 9px 10px;
	border: 0; border-radius: 10px; background: none; color: var(--text); font: inherit; font-size: 14px;
	cursor: pointer; text-align: left;
}
.zmw-theme-opt:hover { background: var(--surface-2); }
.zmw-theme-opt.zmw-on { background: var(--grad-soft); font-weight: 650; }
.zmw-theme-opt .zmw-i { width: 18px; height: 18px; flex-shrink: 0; }
.zmw-theme-opt > span:nth-of-type(1) { flex: 1; }
.zmw-theme-mark { color: var(--a1); font-weight: 800; width: 14px; text-align: center; }

html[data-theme="ink"] {
	--a1: #0a9cff; --a2: #0a9cff; --a3: #00c0ff;
	--grad: linear-gradient(180deg, #00c0ff, #0a9cff);
	--grad-soft: #d6f0ff;
	--ring: 0 0 0 3px rgba(10,156,255,.35);
	--radius: 6px; --radius-sm: 4px;
	--bg: #ffffff; --bg-glow-1: transparent; --bg-glow-2: transparent;
	--surface: #ffffff; --surface-solid: #ffffff; --surface-2: #e8f6ff; --surface-3: #d6f0ff;
	--side-bg: #e8f6ff;
	--border: #0a0a0a; --border-2: #0a0a0a;
	--text: #0a0a0a; --text-2: #1f2a36; --muted: #3d4a57;
	--shadow: 5px 5px 0 #0a0a0a; --shadow-lg: 8px 8px 0 #0a0a0a;
	--input-bg: #ffffff; --console: #0a0a0a; --console-border: #0a0a0a;
	--ok: #0a0a0a; --ok-bg: #19c45a; --ok-dot: #0a0a0a;
	--bad: #0a0a0a; --bad-bg: #ff4d3d; --bad-dot: #0a0a0a;
	--warn: #0a0a0a; --warn-bg: #ffc21a; --warn-dot: #0a0a0a;
	--off: #0a0a0a; --off-bg: #eeeeee;
	color-scheme: light;
}
html[data-theme="ink"] ::selection { background: #00c0ff; color: #0a0a0a; }
html[data-theme="ink"] body.zmw-body { background-image: none; }
html[data-theme="ink"] .zmw-orbs, html[data-theme="ink"] .zmw-grid-bg { display: none; }
html[data-theme="ink"] .zmw-top { background: linear-gradient(to bottom, rgba(255,255,255,.96) 35%, rgba(255,255,255,0)); }
html[data-theme="ink"] .zmw-side { background: #e8f6ff; border-right: 2.5px solid #0a0a0a; backdrop-filter: none; -webkit-backdrop-filter: none; box-shadow: none; }
html[data-theme="ink"] .zmw-nav-item { border: 2px solid transparent; border-radius: 6px; }
html[data-theme="ink"] .zmw-nav-item:hover { background: #d6f0ff; border-color: #0a0a0a; }
html[data-theme="ink"] .zmw-nav-item.zmw-active { background: #0a9cff; color: #0a0a0a; border-color: #0a0a0a; box-shadow: 3px 3px 0 #0a0a0a; font-weight: 700; }
html[data-theme="ink"] .zmw-nav-item.zmw-active::before { display: none; }
html[data-theme="ink"] .zmw-nav-item.zmw-active .zmw-nav-ico { color: #0a0a0a; }
html[data-theme="ink"] .zmw-mem-bar { height: 10px; border: 2px solid #0a0a0a; border-radius: 3px; background: #ffffff; }
html[data-theme="ink"] .zmw-mem-bar i { border-radius: 0; background: #0a9cff; }
html[data-theme="ink"] .zmw-mem-mid .zmw-mem-bar i { background: #ffc21a; }
html[data-theme="ink"] .zmw-mem-hi .zmw-mem-bar i { background: #ff4d3d; }
html[data-theme="ink"] .zmw-icon-btn, html[data-theme="ink"] .zmw-btn-primary {
	border: 2px solid #0a0a0a; border-radius: 6px; box-shadow: 3px 3px 0 #0a0a0a; background: #ffffff; color: #0a0a0a;
	transition: transform .08s, box-shadow .08s;
}
html[data-theme="ink"] .zmw-btn-primary { background: #0a9cff; }
html[data-theme="ink"] .zmw-icon-btn:active, html[data-theme="ink"] .zmw-btn-primary:active { transform: translate(2px, 2px); box-shadow: 1px 1px 0 #0a0a0a; }
html[data-theme="ink"] .zmw-login-card, html[data-theme="ink"] .zmw-modal, html[data-theme="ink"] .zmw-theme-menu {
	border: 2.5px solid #0a0a0a; border-radius: 8px; box-shadow: 6px 6px 0 #0a0a0a; background: #ffffff; backdrop-filter: none; -webkit-backdrop-filter: none;
}
html[data-theme="ink"] .zmw-theme-opt { border: 2px solid transparent; border-radius: 5px; }
html[data-theme="ink"] .zmw-theme-opt.zmw-on { background: #0a9cff; border-color: #0a0a0a; }
html[data-theme="ink"] .zmw-theme-mark { color: #0a0a0a; }
html[data-theme="ink"] .zmw-input { border: 2px solid #0a0a0a; border-radius: 6px; }
html[data-theme="ink"] .zmw-check-box { border: 2px solid #0a0a0a; border-radius: 3px; }

html[data-theme="ink"] #zmw-view .zm-card {
	background: #ffffff; border: 2.5px solid #0a0a0a; border-radius: 6px; box-shadow: 5px 5px 0 #0a0a0a;
	backdrop-filter: none; -webkit-backdrop-filter: none;
}
html[data-theme="ink"] #zmw-view .zm-card:hover { box-shadow: 5px 5px 0 #0a0a0a; border-color: #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-card h3::before { background: #0a9cff; border: 1.5px solid #0a0a0a; }
html[data-theme="ink"] #zmw-view .cbi-button {
	border: 2px solid #0a0a0a; border-radius: 6px; box-shadow: 3px 3px 0 #0a0a0a; background: #ffffff; color: #0a0a0a;
	transition: transform .08s, box-shadow .08s;
}
html[data-theme="ink"] #zmw-view .cbi-button:hover { background: #e8f6ff; transform: none; box-shadow: 3px 3px 0 #0a0a0a; }
html[data-theme="ink"] #zmw-view .cbi-button:active { transform: translate(2px, 2px); box-shadow: 1px 1px 0 #0a0a0a; }
html[data-theme="ink"] #zmw-view .cbi-button-positive, html[data-theme="ink"] #zmw-view .cbi-button-positive:hover { background: #0a9cff; color: #0a0a0a; border-color: #0a0a0a; }
html[data-theme="ink"] #zmw-view .cbi-button-remove, html[data-theme="ink"] #zmw-view .cbi-button-remove:hover { background: #ff4d3d; color: #0a0a0a; border-color: #0a0a0a; }
html[data-theme="ink"] #zmw-view .cbi-button-action, html[data-theme="ink"] #zmw-view .cbi-button-action:hover { background: #d6f0ff; color: #0a0a0a; }
html[data-theme="ink"] #zmw-view .cbi-button[disabled] { box-shadow: none; opacity: .5; }
html[data-theme="ink"] #zmw-view .zmw-tabs .cbi-button { box-shadow: none; }
html[data-theme="ink"] #zmw-view .zmw-tabs .cbi-button-positive { box-shadow: 3px 3px 0 #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-tile {
	background: #ffffff; border: 2px solid #0a0a0a; border-radius: 6px; box-shadow: 3px 3px 0 #0a0a0a; color: #0a0a0a;
}
html[data-theme="ink"] #zmw-view .zm-tile:hover { background: #e8f6ff; transform: none; }
html[data-theme="ink"] #zmw-view .zm-tile.zm-active { background: #0a9cff; color: #0a0a0a; border-color: #0a0a0a; box-shadow: 3px 3px 0 #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-tile.zm-active::before { color: #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-badge { border: 2px solid #0a0a0a; color: #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-badge .zm-dot { box-shadow: none; animation: none; }
html[data-theme="ink"] #zmw-view input[type="text"], html[data-theme="ink"] #zmw-view input[type="password"],
html[data-theme="ink"] #zmw-view input[type="number"], html[data-theme="ink"] #zmw-view select,
html[data-theme="ink"] #zmw-view textarea:not(.zm-config-editor) { border: 2px solid #0a0a0a; border-radius: 6px; background: #ffffff; }
html[data-theme="ink"] #zmw-view .zm-config-editor, html[data-theme="ink"] #zmw-view .zm-log { border: 2.5px solid #0a0a0a; border-radius: 6px; box-shadow: 5px 5px 0 #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-current-banner, html[data-theme="ink"] #zmw-view .zm-refresh-banner { border: 2px solid #0a0a0a; border-radius: 6px; background: #d6f0ff; box-shadow: 3px 3px 0 #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-node, html[data-theme="ink"] #zmw-view .zm-svc, html[data-theme="ink"] #zmw-view .zm-awg-if,
html[data-theme="ink"] #zmw-view .zm-st-stat, html[data-theme="ink"] #zmw-view .zm-credit-tile, html[data-theme="ink"] #zmw-view .zm-ab-svc-item {
	background: #ffffff; border: 2px solid #0a0a0a; border-radius: 6px; box-shadow: 3px 3px 0 #0a0a0a;
}
html[data-theme="ink"] #zmw-view .zm-node.zm-active, html[data-theme="ink"] #zmw-view .zm-svc.zm-svc-on { background: #0a9cff; border-color: #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-node:hover { transform: none; }
html[data-theme="ink"] #zmw-view .zm-seg { border: 2px solid #0a0a0a; border-radius: 6px; background: #ffffff; }
html[data-theme="ink"] #zmw-view .zm-seg-item { border-radius: 3px; color: #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-seg-item.zm-active { background: #0a9cff; color: #0a0a0a; box-shadow: none; outline: 2px solid #0a0a0a; }
html[data-theme="ink"] #zmw-view .zm-sub-meta { background: #e8f6ff; border: 2px solid #0a0a0a; border-radius: 6px; }
html[data-theme="ink"] #zmw-view .zm-quota { border: 2px solid #0a0a0a; height: 10px; background: #ffffff; }
html[data-theme="ink"] #zmw-view .zm-quota > i { background: #0a9cff; border-radius: 0; }
html[data-theme="ink"] #zmw-view .zm-switch { border: 2px solid #0a0a0a; background: #ffffff; }
html[data-theme="ink"] #zmw-view .zm-switch > span { border: 2px solid #0a0a0a; box-shadow: none; top: 1px; left: 1px; }
html[data-theme="ink"] #zmw-view .zm-switch.zm-switch-on { background: #0a9cff; }
html[data-theme="ink"] #zmw-view a:not(.cbi-button) { color: #0060c0; text-decoration: underline; text-underline-offset: 2px; }
html[data-theme="ink"] .zmw-logo svg { filter: none; }
html[data-theme="ink"] .zmw-logo-lg::after { display: none; }
html[data-theme="bento"] {
	--font: "Onest", system-ui, sans-serif;
	--a1: #1c1a17; --a2: #1c1a17; --a3: #5b554c;
	--grad: #1c1a17; --grad-soft: #e4ddd0; --ring: 0 0 0 3px rgba(28,26,23,.2);
	--radius: 28px; --radius-sm: 16px;
	--bg: #efebe4; --bg-glow-1: transparent; --bg-glow-2: transparent;
	--surface: #ffffff; --surface-solid: #ffffff; --surface-2: #f6f2ea; --surface-3: #eee8dd;
	--side-bg: #efebe4; --border: rgba(28,26,23,.06); --border-2: rgba(28,26,23,.12);
	--text: #1c1a17; --text-2: #3d3830; --muted: #6f685d;
	--shadow: none; --shadow-lg: 0 24px 60px -24px rgba(28,26,23,.35);
	--input-bg: #f6f2ea;
	--ok: #1f5a2c; --ok-bg: #d8f0dc; --ok-dot: #2f7d4f;
	--bad: #8a1c14; --bad-bg: #ffd9d4; --bad-dot: #d64532;
	--warn: #7a4a0f; --warn-bg: #ffe2b8; --warn-dot: #d98a1c;
	--off: #6f685d; --off-bg: #eee8dd;
	color-scheme: light;
}
html[data-theme="bento"] body.zmw-body { background-image: none; }
html[data-theme="bento"] .zmw-orbs, html[data-theme="bento"] .zmw-grid-bg { display: none; }
html[data-theme="bento"] .zmw-top { background: linear-gradient(to bottom, rgba(239,235,228,.96) 40%, rgba(239,235,228,0)); }
html[data-theme="bento"] .zmw-title { font-family: "Unbounded", sans-serif; font-weight: 800; letter-spacing: -.03em; }
html[data-theme="bento"] .zmw-side { background: transparent; border-right: 0; box-shadow: none; backdrop-filter: none; -webkit-backdrop-filter: none; }
html[data-theme="bento"] .zmw-nav-item { border-radius: 999px; }
html[data-theme="bento"] .zmw-nav-item:hover { background: #ffffff; }
html[data-theme="bento"] .zmw-nav-item.zmw-active { background: #1c1a17; color: #ffffff; }
html[data-theme="bento"] .zmw-nav-item.zmw-active::before { display: none; }
html[data-theme="bento"] .zmw-nav-item.zmw-active .zmw-nav-ico { color: #ffffff; }
html[data-theme="bento"] .zmw-mem-bar { height: 8px; background: #e4ddd0; }
html[data-theme="bento"] .zmw-mem-bar i { background: #1c1a17; }
html[data-theme="bento"] #zmw-view .zm-card { background: #ffffff; border: 0; border-radius: 30px; box-shadow: none; backdrop-filter: none; -webkit-backdrop-filter: none; padding: 26px 28px; }
html[data-theme="bento"] #zmw-view .zm-cards > .zm-card:nth-child(4n+2) { background: #dcecff; }
html[data-theme="bento"] #zmw-view .zm-cards > .zm-card:nth-child(4n+3) { background: #ffe6c4; }
html[data-theme="bento"] #zmw-view .zm-cards > .zm-card:nth-child(4n+4) { background: #dff2e2; }
html[data-theme="bento"] #zmw-view .zm-card h3::before { display: none; }
html[data-theme="bento"] #zmw-view .zm-card h3 { font-size: 15px; font-weight: 600; color: inherit; opacity: .8; }
html[data-theme="bento"] #zmw-view .cbi-button, html[data-theme="bento"] .zmw-icon-btn { border-radius: 14px; border: 0; background: #f6f2ea; color: #1c1a17; box-shadow: none; }
html[data-theme="bento"] #zmw-view .cbi-button:hover, html[data-theme="bento"] .zmw-icon-btn:hover { background: #e4ddd0; transform: none; }
html[data-theme="bento"] #zmw-view .cbi-button-positive, html[data-theme="bento"] #zmw-view .cbi-button-positive:hover, html[data-theme="bento"] .zmw-btn-primary { background: #1c1a17; color: #ffffff; border: 0; box-shadow: none; }
html[data-theme="bento"] #zmw-view .cbi-button-remove, html[data-theme="bento"] #zmw-view .cbi-button-remove:hover { background: #ffd9d4; color: #8a1c14; }
html[data-theme="bento"] #zmw-view .zm-tile { border-radius: 18px; border: 0; background: #f6f2ea; }
html[data-theme="bento"] #zmw-view .zm-tile.zm-active { background: #1c1a17; color: #ffffff; border: 0; }
html[data-theme="bento"] #zmw-view .zm-badge { border-radius: 999px; }
html[data-theme="bento"] #zmw-view .zm-log, html[data-theme="bento"] #zmw-view .zm-config-editor { border-radius: 24px; }
html[data-theme="bento"] .zmw-login-card, html[data-theme="bento"] .zmw-modal, html[data-theme="bento"] .zmw-theme-menu { border: 0; border-radius: 28px; background: #ffffff; backdrop-filter: none; }

html[data-theme="minimal"] {
	--font: "IBM Plex Sans", system-ui, sans-serif;
	--a1: #0078e8; --a2: #0078e8; --a3: #0078e8;
	--grad: #0078e8; --grad-soft: transparent; --ring: 0 0 0 2px rgba(0,120,232,.35);
	--radius: 0px; --radius-sm: 0px;
	--bg: #ffffff; --bg-glow-1: transparent; --bg-glow-2: transparent;
	--surface: #ffffff; --surface-solid: #ffffff; --surface-2: #fafafa; --surface-3: #f0f0f0;
	--side-bg: #ffffff; --border: #ececec; --border-2: #e0e0e0;
	--text: #111111; --text-2: #333333; --muted: #6b6b6b;
	--shadow: none; --shadow-lg: 0 20px 60px -30px rgba(0,0,0,.25);
	--input-bg: #ffffff;
	--ok: #111111; --ok-bg: transparent; --ok-dot: #0078e8;
	--bad: #b3261e; --bad-bg: transparent; --bad-dot: #b3261e;
	--warn: #111111; --warn-bg: transparent; --warn-dot: #c77700;
	--off: #6b6b6b; --off-bg: transparent;
	color-scheme: light;
}
html[data-theme="minimal"] body.zmw-body { background-image: none; font-weight: 300; }
html[data-theme="minimal"] .zmw-orbs, html[data-theme="minimal"] .zmw-grid-bg { display: none; }
html[data-theme="minimal"] .zmw-top { background: #ffffff; }
html[data-theme="minimal"] .zmw-title { font-weight: 300; font-size: 34px; letter-spacing: -.03em; }
html[data-theme="minimal"] .zmw-side { background: #ffffff; border-right: 1px solid #ececec; box-shadow: none; backdrop-filter: none; -webkit-backdrop-filter: none; }
html[data-theme="minimal"] .zmw-logo svg { filter: grayscale(1) brightness(.2); }
html[data-theme="minimal"] .zmw-nav-item { border-radius: 0; font-weight: 400; color: #6b6b6b; }
html[data-theme="minimal"] .zmw-nav-item:hover { background: none; color: #111111; }
html[data-theme="minimal"] .zmw-nav-item.zmw-active { background: none; color: #111111; font-weight: 500; }
html[data-theme="minimal"] .zmw-nav-item.zmw-active::before { background: #111111; width: 2px; border-radius: 0; }
html[data-theme="minimal"] .zmw-nav-ico { opacity: .5; }
html[data-theme="minimal"] .zmw-mem-bar { height: 2px; background: #ececec; border-radius: 0; }
html[data-theme="minimal"] .zmw-mem-bar i { background: #111111; border-radius: 0; }
html[data-theme="minimal"] #zmw-view .zm-card { border: 0; border-top: 1px solid #ececec; border-radius: 0; box-shadow: none; background: transparent; backdrop-filter: none; -webkit-backdrop-filter: none; padding: 28px 0; }
html[data-theme="minimal"] #zmw-view .zm-card:hover { box-shadow: none; }
html[data-theme="minimal"] #zmw-view .zm-card h3 { font-weight: 400; font-size: 13px; text-transform: uppercase; letter-spacing: .12em; color: #6b6b6b; }
html[data-theme="minimal"] #zmw-view .zm-card h3::before { display: none; }
html[data-theme="minimal"] #zmw-view .cbi-button, html[data-theme="minimal"] .zmw-icon-btn { border-radius: 0; border: 1px solid #111111; background: #ffffff; color: #111111; box-shadow: none; font-weight: 400; }
html[data-theme="minimal"] #zmw-view .cbi-button:hover, html[data-theme="minimal"] .zmw-icon-btn:hover { background: #111111; color: #ffffff; transform: none; }
html[data-theme="minimal"] #zmw-view .cbi-button-positive, html[data-theme="minimal"] #zmw-view .cbi-button-positive:hover, html[data-theme="minimal"] .zmw-btn-primary { background: #111111; color: #ffffff; border: 1px solid #111111; box-shadow: none; }
html[data-theme="minimal"] #zmw-view .cbi-button-remove { border-color: #b3261e; color: #b3261e; background: #ffffff; }
html[data-theme="minimal"] #zmw-view .cbi-button-remove:hover { background: #b3261e; color: #ffffff; }
html[data-theme="minimal"] #zmw-view .zm-tile { border-radius: 0; border: 1px solid #e0e0e0; background: #ffffff; font-weight: 400; }
html[data-theme="minimal"] #zmw-view .zm-tile.zm-active { border-color: #111111; background: #ffffff; color: #111111; box-shadow: inset 0 0 0 1px #111111; }
html[data-theme="minimal"] #zmw-view .zm-tile.zm-active::before { color: #0078e8; }
html[data-theme="minimal"] #zmw-view .zm-badge { padding-left: 0; font-weight: 400; }
html[data-theme="minimal"] #zmw-view .zm-badge .zm-dot { width: 6px; height: 6px; box-shadow: none; animation: none; }
html[data-theme="minimal"] #zmw-view .zm-log, html[data-theme="minimal"] #zmw-view .zm-config-editor { border-radius: 0; }
html[data-theme="minimal"] .zmw-login-card, html[data-theme="minimal"] .zmw-modal, html[data-theme="minimal"] .zmw-theme-menu { border-radius: 0; border: 1px solid #111111; box-shadow: none; background: #ffffff; backdrop-filter: none; }
html[data-theme="minimal"] .zmw-theme-opt { border-radius: 0; }

html[data-theme="retro"] {
	--font: Tahoma, Verdana, "Segoe UI", sans-serif;
	--a1: #000080; --a2: #000080; --a3: #1084d0;
	--grad: linear-gradient(90deg, #000080, #1084d0); --grad-soft: #dcdcdc; --ring: 0 0 0 1px #000000;
	--radius: 0px; --radius-sm: 0px;
	--bg: #008080; --bg-glow-1: transparent; --bg-glow-2: transparent;
	--surface: #c0c0c0; --surface-solid: #c0c0c0; --surface-2: #d4d0c8; --surface-3: #ffffff;
	--side-bg: #c0c0c0; --border: #808080; --border-2: #000000;
	--text: #000000; --text-2: #000000; --muted: #404040;
	--shadow: none; --shadow-lg: none;
	--input-bg: #ffffff; --console: #000000; --console-border: #808080;
	--ok: #006400; --ok-bg: transparent; --ok-dot: #008000;
	--bad: #a00000; --bad-bg: transparent; --bad-dot: #ff0000;
	--warn: #806000; --warn-bg: transparent; --warn-dot: #c0a000;
	--off: #404040; --off-bg: transparent;
	color-scheme: light;
}
html[data-theme="retro"] body.zmw-body { background-image: none; font-size: 13px; }
html[data-theme="retro"] .zmw-orbs, html[data-theme="retro"] .zmw-grid-bg { display: none; }
html[data-theme="retro"] .zmw-top { background: #008080; }
html[data-theme="retro"] .zmw-title, html[data-theme="retro"] .zmw-sub { color: #ffffff; }
html[data-theme="retro"] .zmw-title { font-size: 20px; font-weight: 700; letter-spacing: 0; }
html[data-theme="retro"] .zmw-side { background: #c0c0c0; border-right: 2px solid #000000; box-shadow: inset -1px 0 0 #808080, inset 1px 1px 0 #ffffff; backdrop-filter: none; -webkit-backdrop-filter: none; }
html[data-theme="retro"] .zmw-nav-item { border-radius: 0; }
html[data-theme="retro"] .zmw-nav-item:hover { background: #d4d0c8; }
html[data-theme="retro"] .zmw-nav-item.zmw-active { background: #000080; color: #ffffff; }
html[data-theme="retro"] .zmw-nav-item.zmw-active::before { display: none; }
html[data-theme="retro"] .zmw-nav-item.zmw-active .zmw-nav-ico { color: #ffffff; }
html[data-theme="retro"] .zmw-mem-bar { height: 16px; border-radius: 0; background: #ffffff; border-top: 1px solid #808080; border-left: 1px solid #808080; border-right: 1px solid #ffffff; border-bottom: 1px solid #ffffff; padding: 2px; box-sizing: border-box; }
html[data-theme="retro"] .zmw-mem-bar i { border-radius: 0; background: repeating-linear-gradient(90deg, #000080 0 8px, transparent 8px 10px); }
html[data-theme="retro"] .zmw-mem-mid .zmw-mem-bar i, html[data-theme="retro"] .zmw-mem-hi .zmw-mem-bar i { background: repeating-linear-gradient(90deg, #a00000 0 8px, transparent 8px 10px); }
html[data-theme="retro"] #zmw-view .zm-card {
	background: #c0c0c0; border-radius: 0; backdrop-filter: none; -webkit-backdrop-filter: none;
	border-top: 2px solid #ffffff; border-left: 2px solid #ffffff; border-right: 2px solid #000000; border-bottom: 2px solid #000000;
	box-shadow: inset -1px -1px 0 #808080, inset 1px 1px 0 #dfdfdf;
}
html[data-theme="retro"] #zmw-view .zm-card { padding: 0 14px 14px; }
html[data-theme="retro"] #zmw-view .zm-card h3 { margin: 3px -11px 14px; padding: 5px 8px; background: linear-gradient(90deg, #000080, #1084d0); color: #ffffff; font-size: 13px; font-weight: 700; }
html[data-theme="retro"] #zmw-view .zm-card h3::before { display: none; }
html[data-theme="retro"] #zmw-view .cbi-button, html[data-theme="retro"] .zmw-icon-btn, html[data-theme="retro"] .zmw-btn-primary {
	border-radius: 0; background: #c0c0c0; color: #000000; box-shadow: inset -1px -1px 0 #808080, inset 1px 1px 0 #dfdfdf;
	border-top: 2px solid #ffffff; border-left: 2px solid #ffffff; border-right: 2px solid #000000; border-bottom: 2px solid #000000; font-weight: 400;
}
html[data-theme="retro"] #zmw-view .cbi-button:hover, html[data-theme="retro"] .zmw-icon-btn:hover { background: #c0c0c0; transform: none; }
html[data-theme="retro"] #zmw-view .cbi-button:active, html[data-theme="retro"] .zmw-icon-btn:active { border-top-color: #000000; border-left-color: #000000; border-right-color: #ffffff; border-bottom-color: #ffffff; }
html[data-theme="retro"] #zmw-view .cbi-button-positive, html[data-theme="retro"] #zmw-view .cbi-button-positive:hover { background: #c0c0c0; color: #000000; font-weight: 700; outline: 1px dotted #000000; outline-offset: -5px; }
html[data-theme="retro"] #zmw-view .cbi-button-remove, html[data-theme="retro"] #zmw-view .cbi-button-remove:hover { background: #c0c0c0; color: #a00000; }
html[data-theme="retro"] #zmw-view .zm-tile { border-radius: 0; background: #ffffff; border-top: 2px solid #808080; border-left: 2px solid #808080; border-right: 2px solid #ffffff; border-bottom: 2px solid #ffffff; }
html[data-theme="retro"] #zmw-view .zm-tile.zm-active { background: #000080; color: #ffffff; }
html[data-theme="retro"] #zmw-view .zm-badge { border-radius: 0; padding-left: 0; }
html[data-theme="retro"] #zmw-view .zm-badge .zm-dot { box-shadow: none; animation: none; }
html[data-theme="retro"] #zmw-view input, html[data-theme="retro"] #zmw-view select, html[data-theme="retro"] #zmw-view textarea:not(.zm-config-editor), html[data-theme="retro"] .zmw-input {
	border-radius: 0; background: #ffffff; border-top: 2px solid #808080; border-left: 2px solid #808080; border-right: 2px solid #ffffff; border-bottom: 2px solid #ffffff;
}
html[data-theme="retro"] #zmw-view .zm-log, html[data-theme="retro"] #zmw-view .zm-config-editor { border-radius: 0; }
html[data-theme="retro"] .zmw-login-card, html[data-theme="retro"] .zmw-modal, html[data-theme="retro"] .zmw-theme-menu {
	border-radius: 0; background: #c0c0c0; backdrop-filter: none; box-shadow: inset -1px -1px 0 #808080, inset 1px 1px 0 #dfdfdf;
	border-top: 2px solid #ffffff; border-left: 2px solid #ffffff; border-right: 2px solid #000000; border-bottom: 2px solid #000000;
}
html[data-theme="retro"] .zmw-theme-opt { border-radius: 0; }
html[data-theme="retro"] .zmw-theme-opt:hover, html[data-theme="retro"] .zmw-theme-opt.zmw-on { background: #000080; color: #ffffff; }
html[data-theme="retro"] .zmw-foot { color: #ffffff; }

html[data-theme="depth"] {
	--font: "Onest", system-ui, sans-serif;
	--a1: #00b6ff; --a2: #0090ff; --a3: #7fdcff;
	--grad: linear-gradient(180deg, #33c6ff, #0090ff); --grad-soft: rgba(0,182,255,.14); --ring: 0 0 0 3px rgba(0,182,255,.4);
	--radius: 20px; --radius-sm: 14px;
	--bg: #0a0e18; --bg-glow-1: rgba(0,182,255,.18); --bg-glow-2: rgba(255,140,60,.10);
	--surface: #16203a; --surface-solid: #16203a; --surface-2: rgba(127,220,255,.06); --surface-3: rgba(127,220,255,.12);
	--side-bg: rgba(10,14,24,.85); --border: rgba(127,220,255,.16); --border-2: rgba(127,220,255,.3);
	--text: #e8eefc; --text-2: #c7d3ea; --muted: #9fb0cc;
	--shadow: 0 1px 0 rgba(255,255,255,.08) inset, 0 10px 0 -2px #0c1426, 0 28px 50px -12px rgba(0,0,0,.8);
	--shadow-lg: 0 40px 90px -30px rgba(0,0,0,.9);
	--input-bg: rgba(255,255,255,.05); --console: #060910; --console-border: rgba(127,220,255,.2);
	--ok: #5ef0a8; --ok-bg: rgba(94,240,168,.12); --ok-dot: #5ef0a8;
	--bad: #ff7b7b; --bad-bg: rgba(255,123,123,.12); --bad-dot: #ff7b7b;
	--warn: #ffc48a; --warn-bg: rgba(255,196,138,.12); --warn-dot: #ff9a4d;
	--off: #9fb0cc; --off-bg: rgba(159,176,204,.12);
	color-scheme: dark;
}
html[data-theme="depth"] .zmw-title { font-family: "Unbounded", sans-serif; font-weight: 800; }
html[data-theme="depth"] .zmw-top { background: linear-gradient(to bottom, rgba(10,14,24,.94) 40%, rgba(10,14,24,0)); }
html[data-theme="depth"] #zmw-view { perspective: 1600px; }
html[data-theme="depth"] #zmw-view .zm-card {
	background: linear-gradient(160deg, #1b2740, #121a2c); border: 1px solid rgba(127,220,255,.2);
	transform: translateZ(0); transition: transform .35s cubic-bezier(.2,.8,.2,1), box-shadow .35s;
}
html[data-theme="depth"] #zmw-view .zm-card:hover { transform: rotateX(4deg) translateY(-4px); box-shadow: 0 1px 0 rgba(255,255,255,.1) inset, 0 14px 0 -2px #0c1426, 0 40px 60px -14px rgba(0,0,0,.85), 0 0 40px -10px rgba(0,182,255,.35); border-color: rgba(127,220,255,.4); }
html[data-theme="depth"] #zmw-view .cbi-button, html[data-theme="depth"] .zmw-icon-btn {
	background: #1e2b48; border: 1px solid rgba(127,220,255,.25); color: #e8eefc;
	box-shadow: 0 4px 0 #0c1426, 0 8px 16px -6px rgba(0,0,0,.7); transition: transform .08s, box-shadow .08s;
}
html[data-theme="depth"] #zmw-view .cbi-button:hover, html[data-theme="depth"] .zmw-icon-btn:hover { background: #253559; transform: translateY(-1px); }
html[data-theme="depth"] #zmw-view .cbi-button:active, html[data-theme="depth"] .zmw-icon-btn:active { transform: translateY(4px); box-shadow: 0 0 0 #0c1426; }
html[data-theme="depth"] #zmw-view .cbi-button-positive, html[data-theme="depth"] #zmw-view .cbi-button-positive:hover, html[data-theme="depth"] .zmw-btn-primary { background: linear-gradient(180deg, #33c6ff, #0090ff); color: #04111f; border-color: #0090ff; box-shadow: 0 4px 0 #005a9e, 0 10px 24px -8px rgba(0,182,255,.8); }
html[data-theme="depth"] #zmw-view .cbi-button-remove, html[data-theme="depth"] #zmw-view .cbi-button-remove:hover { background: linear-gradient(180deg, #ff8a7a, #e84a3a); color: #1a0503; border-color: #e84a3a; box-shadow: 0 4px 0 #8f2419; }
html[data-theme="depth"] #zmw-view .zm-tile { background: #1e2b48; border: 1px solid rgba(127,220,255,.2); box-shadow: 0 4px 0 #0c1426; transition: transform .15s, box-shadow .15s; }
html[data-theme="depth"] #zmw-view .zm-tile:hover { transform: translateY(-2px); box-shadow: 0 6px 0 #0c1426, 0 14px 24px -10px rgba(0,182,255,.5); }
html[data-theme="depth"] #zmw-view .zm-tile.zm-active { background: linear-gradient(180deg, #33c6ff, #0090ff); color: #04111f; border-color: #0090ff; box-shadow: 0 4px 0 #005a9e; }
html[data-theme="depth"] .zmw-side { box-shadow: 10px 0 40px -20px rgba(0,0,0,.8); }
html[data-theme="depth"] .zmw-nav-item.zmw-active { background: linear-gradient(180deg, rgba(0,182,255,.25), rgba(0,144,255,.12)); box-shadow: 0 3px 0 #0c1426, inset 0 1px 0 rgba(255,255,255,.08); }
html[data-theme="depth"] .zmw-mem-bar { background: #0c1426; box-shadow: inset 0 2px 3px rgba(0,0,0,.6); }
html[data-theme="depth"] .zmw-mem-bar i { background: linear-gradient(180deg, #7fdcff, #0090ff); box-shadow: 0 0 10px rgba(0,182,255,.6); }
html[data-theme="depth"] .zmw-login-card, html[data-theme="depth"] .zmw-modal, html[data-theme="depth"] .zmw-theme-menu { background: linear-gradient(160deg, #1b2740, #121a2c); border: 1px solid rgba(127,220,255,.25); }

.zmw-theme-menu { max-height: calc(100vh - 90px); overflow-y: auto; }
html[data-theme="bento"] #zmw-view .zm-tile.zm-active::before { color: #9fe0b0; }
html[data-theme="bento"] .zmw-theme-opt.zmw-on { background: #1c1a17; color: #ffffff; }
html[data-theme="bento"] .zmw-theme-opt.zmw-on .zmw-theme-mark { color: #9fe0b0; }
html[data-theme="minimal"] .zmw-theme-opt.zmw-on { background: #f3f3f3; }
html[data-theme="retro"] #zmw-view .zm-tile.zm-active::before { color: #ffff00; }
html[data-theme="retro"] .zmw-theme-opt:hover .zmw-theme-mark, html[data-theme="retro"] .zmw-theme-opt.zmw-on .zmw-theme-mark { color: #ffff00; }
html[data-theme="retro"] .zmw-nav-item { padding-left: 12px; }
html[data-theme="retro"] .zmw-link-btn, html[data-theme="retro"] .zmw-link-btn:hover { color: #000000; }
html[data-theme="depth"] #zmw-view .zm-tile.zm-active::before { color: #04111f; }
html[data-theme="depth"] .zmw-theme-mark { color: #7fdcff; }
html[data-theme="ink"] #zmw-view .zm-node.zm-active .zm-node-name::before, html[data-theme="ink"] #zmw-view .zm-node.zm-active .zm-lat { color: #0a0a0a; }
html[data-theme="bento"] #zmw-view .zm-seg-item.zm-active, html[data-theme="retro"] #zmw-view .zm-seg-item.zm-active { color: #ffffff; }
#zmw-view .zm-credit-tile.zm-credit-all { grid-column: 1 / -1; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; }
.zmw-theme-menu { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 2px 4px; width: 340px; max-width: calc(100vw - 16px); }
.zmw-theme-group { grid-column: 1 / -1; padding: 8px 10px 4px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .1em; color: var(--muted); }
.zmw-theme-group:first-child { padding-top: 4px; }
.zmw-theme-opt { min-width: 0; }
.zmw-theme-opt > span:nth-of-type(1) { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

html[data-theme="micro"] {
	--font: "Onest", system-ui, sans-serif;
	--a1: #2d5bff; --a2: #2d5bff; --a3: #2d5bff;
	--grad: #2d5bff; --grad-soft: #e6ecff; --ring: 0 0 0 3px #2d5bff55;
	--radius: 20px; --radius-sm: 20px;
	--bg: #f4f5f8; --bg-glow-1: transparent; --bg-glow-2: transparent;
	--surface: #ffffff; --surface-solid: #ffffff; --surface-2: #f7f8fb; --surface-3: #eceff5;
	--side-bg: #ffffff; --border: #e3e6ee; --border-2: #e3e6ee;
	--text: #151a26; --text-2: #151a26; --muted: #5a6377;
	--shadow: 0 1px 2px rgba(0,0,0,.04); --shadow-lg: 0 30px 70px -30px rgba(0,0,0,.45);
	--input-bg: #f7f8fb;
	--ok: #11643e; --ok-bg: #dcf5e9; --ok-dot: #11643e;
	--warn: #7a4d00; --warn-bg: #fff1d6; --warn-dot: #7a4d00;
	--bad: #9a1f1f; --bad-bg: #ffe1e1; --bad-dot: #9a1f1f;
	--off: #4a5266; --off-bg: #eceff5;
	color-scheme: light;
}
html[data-theme="micro"] body.zmw-body { background: #f4f5f8; }
html[data-theme="micro"] .zmw-orbs, html[data-theme="micro"] .zmw-grid-bg { display: none; }
html[data-theme="micro"] .zmw-top { background: linear-gradient(to bottom, #f4f5f8 55%, transparent); }
html[data-theme="micro"] .zmw-title { font-family: "Onest", sans-serif; color: #151a26; }
html[data-theme="micro"] .zmw-sub, html[data-theme="micro"] .zmw-foot { color: #5a6377; }
html[data-theme="micro"] .zmw-side { background: #ffffff; border-right: 1px solid #e3e6ee; box-shadow: none; backdrop-filter: none; -webkit-backdrop-filter: none; color: #151a26; }
html[data-theme="micro"] .zmw-brand-name, html[data-theme="micro"] .zmw-mem-row { color: #151a26; }
html[data-theme="micro"] .zmw-nav-group, html[data-theme="micro"] .zmw-brand-sub, html[data-theme="micro"] .zmw-mem-label, html[data-theme="micro"] .zmw-side-links a { color: #5d6679; }
html[data-theme="micro"] .zmw-nav-item { color: #151a26; border-radius: 12px; }
html[data-theme="micro"] .zmw-nav-item:hover { background: #f0f3fa; color: #151a26; }
html[data-theme="micro"] .zmw-nav-item.zmw-active { background: #2d5bff; color: #ffffff; box-shadow: none; }
html[data-theme="micro"] .zmw-nav-item.zmw-active::before { display: none; }
html[data-theme="micro"] .zmw-nav-item.zmw-active .zmw-nav-ico { color: #ffffff; }
html[data-theme="micro"] .zmw-mem-bar { background: #e3e6ee; border-radius: 6px; }
html[data-theme="micro"] .zmw-mem-bar i { background: #2d5bff; border-radius: inherit; }
html[data-theme="micro"] #zmw-view .zm-card { background: #ffffff; border: 1px solid #e3e6ee; border-radius: 20px; box-shadow: 0 1px 2px rgba(0,0,0,.04); backdrop-filter: none; -webkit-backdrop-filter: none; color: #151a26; }
html[data-theme="micro"] #zmw-view .zm-card:hover { border-color: #e3e6ee; }
html[data-theme="micro"] #zmw-view .zm-card h3 { color: #151a26; } html[data-theme="micro"] #zmw-view .zm-card h3::before { background: #2d5bff; }
html[data-theme="micro"] #zmw-view .zm-hint, html[data-theme="micro"] #zmw-view p.zm-hint, html[data-theme="micro"] #zmw-view .zm-label { color: #5a6377; opacity: 1; }
html[data-theme="micro"] #zmw-view a:not(.cbi-button) { color: #2d5bff; }
html[data-theme="micro"] #zmw-view .cbi-button, html[data-theme="micro"] .zmw-icon-btn { background: #f7f8fb; color: #151a26; border: 1px solid #e3e6ee; border-radius: 14px; box-shadow: 0 1px 2px rgba(0,0,0,.06); }
html[data-theme="micro"] #zmw-view .cbi-button:hover, html[data-theme="micro"] .zmw-icon-btn:hover { background: #eceff5; color: #151a26; }
html[data-theme="micro"] #zmw-view .cbi-button-positive, html[data-theme="micro"] #zmw-view .cbi-button-positive:hover, html[data-theme="micro"] .zmw-btn-primary { background: #2d5bff; color: #ffffff; border-color: #2d5bff; }
html[data-theme="micro"] #zmw-view .cbi-button-remove, html[data-theme="micro"] #zmw-view .cbi-button-remove:hover { background: #ffe1e1; color: #9a1f1f; border-color: #ffe1e1; }
html[data-theme="micro"] #zmw-view .cbi-button-action, html[data-theme="micro"] #zmw-view .cbi-button-action:hover { background: #e6ecff; color: #151a26; }
html[data-theme="micro"] #zmw-view .zm-tile:not(.zm-active):not(.zm-tile-off), html[data-theme="micro"] #zmw-view .zm-tile { background: #f7f8fb; color: #151a26; border: 1px solid #e3e6ee; border-radius: 14px; }
html[data-theme="micro"] #zmw-view .zm-tile.zm-active { background: #2d5bff; color: #ffffff; border-color: #2d5bff; }
html[data-theme="micro"] #zmw-view .zm-tile.zm-active::before { color: #ffffff; }
html[data-theme="micro"] #zmw-view .zm-seg-item { color: #151a26; } html[data-theme="micro"] #zmw-view .zm-seg-item.zm-active { background: #2d5bff; color: #ffffff; }
html[data-theme="micro"] #zmw-view .zm-node.zm-active { background: #e6ecff; border-color: #2d5bff; } html[data-theme="micro"] #zmw-view .zm-node.zm-active .zm-node-name, html[data-theme="micro"] #zmw-view .zm-node.zm-active .zm-node-name::before { color: #151a26; }
html[data-theme="micro"] #zmw-view .zm-badge { border-radius: 999px; }
html[data-theme="micro"] #zmw-view input, html[data-theme="micro"] #zmw-view select, html[data-theme="micro"] #zmw-view textarea:not(.zm-config-editor), html[data-theme="micro"] .zmw-input { background: #f7f8fb; color: #151a26; border: 1px solid #e3e6ee; border-radius: 14px; }
html[data-theme="micro"] #zmw-view .zm-current-banner, html[data-theme="micro"] #zmw-view .zm-refresh-banner { background: #e6ecff; color: #151a26; border-color: #2d5bff; }
html[data-theme="micro"] #zmw-view .zm-credit-tile, html.zm-theme-dark[data-theme="micro"] #zmw-view .zm-credit-tile { background: #f7f8fb; border-color: #e3e6ee; color: #151a26; }
html[data-theme="micro"] #zmw-view .zm-credit-tile.zm-credit-self { background: #e6ecff; }
html[data-theme="micro"] #zmw-view .zm-switch.zm-switch-on { background: #2d5bff; }
html[data-theme="micro"] .zmw-check input:checked + .zmw-check-box { background: #2d5bff; } html[data-theme="micro"] .zmw-check input:checked + .zmw-check-box::after { border-color: #ffffff; }
html[data-theme="micro"] .zmw-login-card, html[data-theme="micro"] .zmw-modal, html[data-theme="micro"] .zmw-theme-menu { background: #ffffff; color: #151a26; border: 1px solid #e3e6ee; backdrop-filter: none; -webkit-backdrop-filter: none; }
html[data-theme="micro"] .zmw-theme-opt { color: #151a26; } html[data-theme="micro"] .zmw-theme-opt:hover { background: #f7f8fb; }
html[data-theme="micro"] .zmw-theme-opt.zmw-on { background: #2d5bff; color: #ffffff; } html[data-theme="micro"] .zmw-theme-opt.zmw-on .zmw-theme-mark, html[data-theme="micro"] .zmw-theme-opt.zmw-on .zmw-i { color: #ffffff; }
html[data-theme="micro"] .zmw-theme-group { color: #5a6377; }
html[data-theme="micro"] #zmw-view .cbi-button, html[data-theme="micro"] .zmw-icon-btn, html[data-theme="micro"] .zmw-btn-primary { transition: transform .12s, box-shadow .12s, background .2s, border-radius .25s; }
html[data-theme="micro"] #zmw-view .cbi-button:hover, html[data-theme="micro"] .zmw-icon-btn:hover { transform: scale(1.03); }
html[data-theme="micro"] #zmw-view .cbi-button:active, html[data-theme="micro"] .zmw-icon-btn:active, html[data-theme="micro"] .zmw-btn-primary:active { transform: scale(.95); box-shadow: none; }
html[data-theme="micro"] #zmw-view .cbi-button-positive:hover, html[data-theme="micro"] .zmw-btn-primary:hover { border-radius: 22px; box-shadow: 0 12px 24px -10px rgba(45,91,255,.7); }
html[data-theme="micro"] #zmw-view .zm-tile { transition: transform .2s cubic-bezier(.2,.8,.2,1), box-shadow .2s; }
html[data-theme="micro"] #zmw-view .zm-tile:hover { transform: translateY(-2px); box-shadow: 0 10px 18px -12px rgba(45,91,255,.6); }
html[data-theme="micro"] #zmw-view .zm-badge .zm-dot { animation: zmw-micro-ring 2s infinite; }
@keyframes zmw-micro-ring { 0% { box-shadow: 0 0 0 0 rgba(30,180,110,.45); } 70% { box-shadow: 0 0 0 7px rgba(30,180,110,0); } 100% { box-shadow: 0 0 0 0 rgba(30,180,110,0); } }
html[data-theme="micro"] .zmw-nav-item { transition: background .2s, transform .15s; }
html[data-theme="micro"] .zmw-nav-item:active { transform: scale(.97); }
html[data-theme="ink"] #zmw-view .zm-actions.zmw-tabs { background: #ffffff; border: 2.5px solid #0a0a0a; border-radius: 6px; box-shadow: 4px 4px 0 #0a0a0a; backdrop-filter: none; }
html[data-theme="ink"] #zmw-view .zmw-tabs .cbi-button { background: transparent; border: 2px solid transparent; border-radius: 4px; box-shadow: none; color: #0a0a0a; transform: none; }
html[data-theme="ink"] #zmw-view .zmw-tabs .cbi-button:hover { background: #e8f6ff; border-color: transparent; box-shadow: none; }
html[data-theme="ink"] #zmw-view .zmw-tabs .cbi-button-positive, html[data-theme="ink"] #zmw-view .zmw-tabs .cbi-button-positive:hover { background: #0a9cff; border-color: #0a0a0a; color: #0a0a0a; box-shadow: none; }
html[data-theme="bento"] #zmw-view .zm-actions.zmw-tabs { background: #ffffff; border: 0; border-radius: 999px; box-shadow: none; backdrop-filter: none; }
html[data-theme="bento"] #zmw-view .zmw-tabs .cbi-button { background: transparent; border: 0; border-radius: 999px; color: #6f685d; box-shadow: none; }
html[data-theme="bento"] #zmw-view .zmw-tabs .cbi-button:hover { background: #f6f2ea; color: #1c1a17; }
html[data-theme="bento"] #zmw-view .zmw-tabs .cbi-button-positive, html[data-theme="bento"] #zmw-view .zmw-tabs .cbi-button-positive:hover { background: #1c1a17; color: #ffffff; }
html[data-theme="minimal"] #zmw-view .zm-actions.zmw-tabs { background: transparent; border: 0; border-bottom: 1px solid #e0e0e0; border-radius: 0; box-shadow: none; padding: 0; gap: 24px; backdrop-filter: none; }
html[data-theme="minimal"] #zmw-view .zmw-tabs .cbi-button { background: transparent; border: 0; border-bottom: 2px solid transparent; border-radius: 0; color: #6b6b6b; padding: 10px 0; box-shadow: none; font-weight: 400; }
html[data-theme="minimal"] #zmw-view .zmw-tabs .cbi-button:hover { background: transparent; color: #111111; }
html[data-theme="minimal"] #zmw-view .zmw-tabs .cbi-button-positive, html[data-theme="minimal"] #zmw-view .zmw-tabs .cbi-button-positive:hover { background: transparent; color: #111111; border-bottom-color: #111111; font-weight: 500; }
html[data-theme="retro"] #zmw-view .zm-actions.zmw-tabs { background: transparent; border: 0; border-bottom: 2px solid #ffffff; border-radius: 0; box-shadow: none; padding: 0 0 0 4px; gap: 2px; align-items: flex-end; backdrop-filter: none; }
html[data-theme="retro"] #zmw-view .zmw-tabs .cbi-button { background: #c0c0c0; color: #000000; border-radius: 0; border-top: 2px solid #ffffff; border-left: 2px solid #ffffff; border-right: 2px solid #000000; border-bottom: 0; box-shadow: inset -1px 0 0 #808080; min-height: 30px; padding: 5px 16px; margin: 0; outline: none; font-weight: 400; }
html[data-theme="retro"] #zmw-view .zmw-tabs .cbi-button:hover { background: #c0c0c0; color: #000000; }
html[data-theme="retro"] #zmw-view .zmw-tabs .cbi-button-positive, html[data-theme="retro"] #zmw-view .zmw-tabs .cbi-button-positive:hover { background: #c0c0c0; color: #000000; font-weight: 700; min-height: 34px; outline: none; margin-bottom: -2px; padding-bottom: 7px; }
html[data-theme="depth"] #zmw-view .zm-actions.zmw-tabs { background: #16203a; border: 1px solid rgba(127,220,255,.2); box-shadow: 0 6px 0 -2px #0c1426; }
html[data-theme="depth"] #zmw-view .zmw-tabs .cbi-button { background: transparent; border: 0; box-shadow: none; color: #9fb0cc; }
html[data-theme="depth"] #zmw-view .zmw-tabs .cbi-button:hover { background: rgba(127,220,255,.08); color: #e8eefc; transform: none; }
html[data-theme="depth"] #zmw-view .zmw-tabs .cbi-button-positive, html[data-theme="depth"] #zmw-view .zmw-tabs .cbi-button-positive:hover { background: linear-gradient(180deg, #33c6ff, #0090ff); color: #04111f; box-shadow: 0 3px 0 #005a9e; }
html[data-theme="micro"] #zmw-view .zm-actions.zmw-tabs { background: #ffffff; border: 1px solid #e3e6ee; border-radius: 16px; box-shadow: 0 1px 2px rgba(0,0,0,.04); backdrop-filter: none; }
html[data-theme="micro"] #zmw-view .zmw-tabs .cbi-button { background: transparent; border: 0; border-radius: 11px; color: #5a6377; box-shadow: none; transform: none; }
html[data-theme="micro"] #zmw-view .zmw-tabs .cbi-button:hover { background: #f0f3fa; color: #151a26; transform: none; }
html[data-theme="micro"] #zmw-view .zmw-tabs .cbi-button-positive, html[data-theme="micro"] #zmw-view .zmw-tabs .cbi-button-positive:hover { background: #2d5bff; color: #ffffff; box-shadow: 0 6px 14px -8px rgba(45,91,255,.9); border-radius: 11px; }
html[data-theme="micro"] #zmw-view .zmw-tabs .cbi-button:active { transform: scale(.96); }
html[data-theme="retro"] #zmw-view .zm-current-banner { background: #ffffe1; border: 1px solid #000000; border-radius: 0; color: #000000; }
html[data-theme="micro"] .zmw-icon-btn.zmw-link-kvn, html[data-theme="micro"] .zmw-icon-btn.zmw-link-kvn:hover { background: linear-gradient(135deg, #2d5bff, #5b7cff); color: #ffffff; border-color: #2d5bff; box-shadow: 0 8px 18px -10px rgba(45,91,255,.9); }
html[data-theme="micro"] .zmw-icon-btn.zmw-link-tg, html[data-theme="micro"] .zmw-icon-btn.zmw-link-tg:hover { background: #e8f4fc; color: #1b6fa8; border-color: #bfdff3; }
html[data-theme="ink"] .zmw-icon-btn.zmw-link-kvn, html[data-theme="ink"] .zmw-icon-btn.zmw-link-kvn:hover { background: #0a9cff; color: #0a0a0a; }
html[data-theme="ink"] .zmw-icon-btn.zmw-link-tg, html[data-theme="ink"] .zmw-icon-btn.zmw-link-tg:hover { background: #d6f0ff; color: #0a0a0a; }
html[data-theme="bento"] .zmw-icon-btn.zmw-link-kvn, html[data-theme="bento"] .zmw-icon-btn.zmw-link-kvn:hover { background: #1c1a17; color: #ffffff; }
html[data-theme="bento"] .zmw-icon-btn.zmw-link-tg, html[data-theme="bento"] .zmw-icon-btn.zmw-link-tg:hover { background: #dcecff; color: #1f4f82; }
html[data-theme="minimal"] .zmw-icon-btn.zmw-link-kvn, html[data-theme="minimal"] .zmw-icon-btn.zmw-link-kvn:hover { background: #111111; color: #ffffff; border-color: #111111; }
html[data-theme="minimal"] .zmw-icon-btn.zmw-link-tg, html[data-theme="minimal"] .zmw-icon-btn.zmw-link-tg:hover { background: #ffffff; color: #0060bb; border-color: #0060bb; }
html[data-theme="retro"] .zmw-icon-btn.zmw-link-kvn, html[data-theme="retro"] .zmw-icon-btn.zmw-link-kvn:hover { color: #000080; font-weight: 700; }
html[data-theme="retro"] .zmw-icon-btn.zmw-link-tg, html[data-theme="retro"] .zmw-icon-btn.zmw-link-tg:hover { color: #000080; }
html[data-theme="depth"] .zmw-icon-btn.zmw-link-kvn, html[data-theme="depth"] .zmw-icon-btn.zmw-link-kvn:hover { background: linear-gradient(180deg, #33c6ff, #0090ff); color: #04111f; border-color: #0090ff; }
html[data-theme="depth"] .zmw-icon-btn.zmw-link-tg, html[data-theme="depth"] .zmw-icon-btn.zmw-link-tg:hover { background: rgba(127,220,255,.12); color: #7fdcff; }
ZM_INSTALLER_EOF
cat > '/www/zm-webui.html' << 'ZM_INSTALLER_EOF'
<!doctype html>
<html lang="ru" data-theme="micro">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#f3f5fa">
<meta name="robots" content="noindex, nofollow">
<title>Zapret Manager</title>
<link rel="icon" href="data:image/svg+xml,%3Csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%201250%201250%27%3E%3Cdefs%3E%3ClinearGradient%20id=%27z%27%20x1=%270%27%20y1=%270%27%20x2=%270%27%20y2=%271%27%3E%3Cstop%20offset=%270%27%20stop-color=%27%2300b6ff%27/%3E%3Cstop%20offset=%271%27%20stop-color=%27%230090ff%27/%3E%3C/linearGradient%3E%3C/defs%3E%3Cg%20fill=%27url%28%23z%29%27%20stroke=%27%230a0a0a%27%20stroke-width=%2722%27%20stroke-linejoin=%27miter%27%3E%3Cpolygon%20points=%27455,170%201072,118%201215,25%20688,615%2025,1235%20735,338%20262,383%27/%3E%3Cpolygon%20points=%271025,462%20722,860%201215,800%201005,1022%20315,1095%27/%3E%3C/g%3E%3C/svg%3E">
<link rel="apple-touch-icon" href="data:image/svg+xml,%3Csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%201250%201250%27%3E%3Cdefs%3E%3ClinearGradient%20id=%27z%27%20x1=%270%27%20y1=%270%27%20x2=%270%27%20y2=%271%27%3E%3Cstop%20offset=%270%27%20stop-color=%27%2300b6ff%27/%3E%3Cstop%20offset=%271%27%20stop-color=%27%230090ff%27/%3E%3C/linearGradient%3E%3C/defs%3E%3Cg%20fill=%27url%28%23z%29%27%20stroke=%27%230a0a0a%27%20stroke-width=%2722%27%20stroke-linejoin=%27miter%27%3E%3Cpolygon%20points=%27455,170%201072,118%201215,25%20688,615%2025,1235%20735,338%20262,383%27/%3E%3Cpolygon%20points=%271025,462%20722,860%201215,800%201005,1022%20315,1095%27/%3E%3C/g%3E%3C/svg%3E">
<link rel="stylesheet" href="/zm/app.css?v=__ZMW_BUILD__">
<script>
(function(){try{var t=localStorage.getItem('zmw.theme')||sessionStorage.getItem('zmw.theme');if(!/^(micro|light|dark|ink|bento|minimal|retro|depth)$/.test(t||''))t='micro';document.documentElement.setAttribute('data-theme',t);if(/^(dark|depth)$/.test(t))document.documentElement.classList.add('zm-theme-dark');}catch(e){}})();
</script>
</head>
<body class="zmw-body">
<div id="zmw-root"></div>
<noscript><p style="padding:24px;font-family:sans-serif">Для работы панели Zapret Manager нужен JavaScript.</p></noscript>
<script src="/zm/app.js?v=__ZMW_BUILD__"></script>
</body>
</html>
ZM_INSTALLER_EOF
ZMW_BUILD="$(date +%s)"
sed -i "s/__ZMW_BUILD__/$ZMW_BUILD/g" /www/zm/app.js /www/zm/app.css /www/zm-webui.html
chmod 0644 /www/zm/app.js /www/zm/app.css /www/zm-webui.html

/opt/zapret-manager-luci/backend.sh redbtn_panel_gone >/dev/null 2>&1 || true

ZMW_RESTART=0
if [ ! -e /usr/lib/uhttpd_ubus.so ]; then
	echo -e "${CYAN}Устанавливаем ${NC}uhttpd-mod-ubus${CYAN} для Web UI${NC}"
	$INSTALL uhttpd-mod-ubus >&2 || { $PM update >&2; $INSTALL uhttpd-mod-ubus >&2; } || true
	ZMW_RESTART=1
fi

if ! uci -q get uhttpd.zmweb >/dev/null; then
	uci set uhttpd.zmweb=uhttpd
	uci add_list uhttpd.zmweb.listen_http='0.0.0.0:7788'
	uci add_list uhttpd.zmweb.listen_http='[::]:7788'
	uci set uhttpd.zmweb.home='/www'
	uci set uhttpd.zmweb.index_page='zm-webui.html'
	uci set uhttpd.zmweb.ubus_prefix='/ubus'
	uci set uhttpd.zmweb.no_dirlists='1'
	uci set uhttpd.zmweb.rfc1918_filter='1'
	uci set uhttpd.zmweb.max_requests='12'
	uci set uhttpd.zmweb.max_connections='100'
	uci set uhttpd.zmweb.script_timeout='120'
	uci set uhttpd.zmweb.network_timeout='30'
	uci set uhttpd.zmweb.http_keepalive='20'
	uci set uhttpd.zmweb.tcp_keepalive='1'
	uci commit uhttpd
	ZMW_RESTART=1
fi
[ "$ZMW_RESTART" = "1" ] && { /etc/init.d/uhttpd restart >/dev/null 2>&1 || true; }

ZMW_PORT="$(uci -q get uhttpd.zmweb.listen_http | tr ' ' '\n' | head -n1 | sed 's/.*://')"
ZMW_IP="$(/opt/zapret-manager-luci/backend.sh lan_ip 2>/dev/null || true)"
[ -n "$ZMW_IP" ] || ZMW_IP="192.168.1.1"

echo -e "Zapret Manager ${GREEN}для ${NC}LuCI ${GREEN}установлен!${NC}"
echo -e "\n${CYAN}Web UI: ${NC}http://${ZMW_IP}:${ZMW_PORT:-7788}${NC}\n"
