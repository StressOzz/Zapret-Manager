#!/bin/sh
# Zapret Manager by StressOzz for LuCI installer
# Version: 1.34
set -e

GREEN="\033[1;32m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"; MAGENTA="\033[1;35m"; BLUE="\033[0;34m"; NC="\033[0m"; DGRAY="\033[38;5;244m"

echo -e "\n${MAGENTA}Устанавливаем Zapret Manager для LuCI${NC}"

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
	/www/luci-static/resources/view/zapret-manager/youtube.js \
	/www/luci-static/resources/view/zapret-manager/game.js \
	/www/luci-static/resources/view/zapret-manager/discord.js \
	/www/luci-static/resources/view/zapret-manager/exclusions.js \
	/usr/share/luci/menu.d/luci-app-ytbypass.json \
	/usr/share/rpcd/acl.d/luci-app-ytbypass.json \
	/www/luci-static/resources/view/ytbypass/main.js 2>/dev/null

# Миграция с версий, где ByeTube был внутренне назван "ytbypass" — переносим на "bytetube"
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
	# Настройки и свои списки пользователя переносим, а не удаляем
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

CONF="/etc/config/zapret"
ZM_VERSION="1.34"
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
mkdir -p "$JOBS_DIR"

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
	$UPDATE >/dev/null 2>&1
	updated=1
	$INSTALL $need >/dev/null 2>&1
}


job_start() {
	local name="$1"; shift
	local log="$JOBS_DIR/$name.log"
	local pid="$JOBS_DIR/$name.pid"
	if [ -f "$pid" ] && kill -0 "$(cat "$pid" 2>/dev/null)" 2>/dev/null; then
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
	if [ -f "$pid" ] && kill -0 "$(cat "$pid" 2>/dev/null)" 2>/dev/null; then running="true"; fi
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
	[ -x /opt/zapret/sync_config.sh ] && /opt/zapret/sync_config.sh >/dev/null 2>&1
	/etc/init.d/zapret restart >/dev/null 2>&1
}


system_info() {
	local model arch owrt df_out tmp_used tmp_free root_used root_free
	model=$(cat /tmp/sysinfo/model 2>/dev/null)
	arch=$(grep DISTRIB_ARCH /etc/openwrt_release 2>/dev/null | cut -d"'" -f2)
	owrt=$(grep '^DISTRIB_RELEASE=' /etc/openwrt_release 2>/dev/null | cut -d"'" -f2)
	df_out=$(df -h /tmp / 2>/dev/null)
	tmp_used=$(echo "$df_out" | awk 'NR==2{print $3}')
	tmp_free=$(echo "$df_out" | awk 'NR==2{print $4}')
	root_used=$(echo "$df_out" | awk 'NR==3{print $3}')
	root_free=$(echo "$df_out" | awk 'NR==3{print $4}')
	printf '{"model":"%s","arch":"%s","openwrt":"%s","tmp_used":"%s","tmp_free":"%s","root_used":"%s","root_free":"%s"}\n' \
		"$(esc "$model")" "$(esc "$arch")" "$(esc "$owrt")" \
		"$(esc "$tmp_used")" "$(esc "$tmp_free")" "$(esc "$root_used")" "$(esc "$root_free")"
}

status() {
	local zr="not_installed" zr_running="false" zr_ver=""
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
		strat=$(sed -n "/^[[:space:]]*option NFQWS_OPT '\$/,/^[[:space:]]*'\$/p" "$CONF" | grep '^#' | sed 's/^#//' | tr '\n' ' ' | sed 's/ $//')
		fs_marker=$(grep -m1 '^# ZMFS:' "$CONF" | sed 's/^# ZMFS://')
	fi

	printf '{"pkg":"%s","zapret":"%s","zapret_running":%s,"zapret_version":"%s","zapret2":"%s","zapret2_running":%s,"strategy":"%s","flowseal":"%s"}\n' \
		"$PKG" "$zr" "$zr_running" "$(esc "$zr_ver")" "$zr2" "$zr2_running" "$(esc "$strat")" "$(esc "$fs_marker")"
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
		wget -q --timeout=20 -U "Mozilla/5.0" -O zapret.zip "$url" >/dev/null 2>&1
		command -v unzip >/dev/null 2>&1 || { echo "==> Устанавливаем unzip"; $INSTALL unzip >/dev/null 2>&1; }
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
			echo "  - $(basename "$p")"; $INSTALL "$p" >/dev/null 2>&1 || { echo "ОШИБКА: $p"; return 1; }
		done
		for p in apk/luci*; do
			[ -f "$p" ] || continue
			echo "  - $(basename "$p")"; $INSTALL "$p" >/dev/null 2>&1
		done
	else
		for p in zapret_*.ipk; do
			[ -f "$p" ] || continue
			echo "  - $(basename "$p")"; $INSTALL "$p" >/dev/null 2>&1 || { echo "ОШИБКА: $p"; return 1; }
		done
		for p in luci-app-zapret_*.ipk; do
			[ -f "$p" ] || continue
			echo "  - $(basename "$p")"; $INSTALL "$p" >/dev/null 2>&1
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
	local b
	for b in ai instagram ntc librusec telegram twitch scell spotify rutor; do
		local content line
		content="$(_hosts_block "$b")"
		while IFS= read -r line; do
			[ -z "$line" ] && continue
			grep -Fxq "$line" "$HOSTS_FILE" || echo "$line" >> "$HOSTS_FILE"
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
	$DELETE luci-app-zapret >/dev/null 2>&1
	$DELETE zapret >/dev/null 2>&1
	echo "==> Удаляем файлы"
	rm -rf /opt/zapret "$CONF" /etc/init.d/zapret /etc/firewall.zapret
	crontab -l 2>/dev/null | grep -v -i zapret | crontab - 2>/dev/null
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
	$DELETE luci-app-zapret2 >/dev/null 2>&1
	$DELETE zapret2 >/dev/null 2>&1
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

_add_yv_default() {
	if ! grep -q "^#Yv" "$CONF" && ! grep -q "^#general" "$CONF"; then
		sed -i "/^[[:space:]]*option NFQWS_OPT '/a\\#Yv08\\n--filter-tcp=443\\n--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt\\n--dpi-desync=hostfakesplit\\n--dpi-desync-hostfakesplit-mod=host=google.com\\n--dpi-desync-fooling=ts\\n--new" "$CONF"
	fi
}

_discord_str_add() {
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
	local version="$1"
	echo "$version" | grep -qE '^v([1-9]|10)$' || { echo '{"error":"некорректная версия"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	sed -i '/^# ZMFS:/d' "$CONF"
	sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" "$CONF"
	{ echo "  option NFQWS_OPT '"; strategy_"$version"; echo "'"; } >> "$CONF"
	_add_gp_domains
	_refresh_exclude_file
	_add_yv_default
	_discord_str_add
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
	command -v unzip >/dev/null 2>&1 || $INSTALL unzip >/dev/null 2>&1

	while [ "$attempt" -le "$max_attempts" ]; do
		rm -f "$zip"
		wget -q --timeout=20 -U "Mozilla/5.0" -O "$zip" "$FLOWSEAL_ZIP" >/dev/null 2>&1
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
	if [ ! -s "$f" ]; then
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
	local name="$1" f block
	f="$(_flowseal_file)"
	[ -s "$f" ] || { echo '{"error":"список не загружен — сначала обновите"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	block=$(awk -v n="#$name" '$0==n{flag=1; print; next} /^#/ && flag{exit} flag{print}' "$f")
	[ -z "$block" ] && { echo '{"error":"стратегия не найдена"}'; return 1; }
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
	if [ ! -s "$f" ]; then
		job_start youtube_download do_yv_download
		return
	fi
	printf '{"items":[%s]}\n' "$(
		grep -oE '^#Yv[0-9]+' "$f" | sed 's/^#//' | awk '{
			printf "%s{\"id\":\"%s\"}", (NR>1?",":""), $0
		}'
	)"
}

strategy_set_youtube() {
	local name="$1" f selected
	f="$(_yv_file)"
	[ -s "$f" ] || { echo '{"error":"список не загружен — сначала обновите"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	selected="#$name"
	grep -qxF "$selected" "$f" || { echo '{"error":"стратегия не найдена"}'; return 1; }

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

discord_status() {
	local dv="" fake=""
	if [ -f "$CONF" ]; then
		dv=$(grep -oE '#Dv[0-9]+' "$CONF" | head -n1 | sed 's/#//')
		fake=$(grep -m1 -- '--dpi-desync-fake-discord=' "$CONF" | sed 's|.*fake/||')
	fi
	printf '{"current":"%s","current_fake":"%s","available":["Dv1","Dv2","Dv3","Dv4","Dv5","Dv6","Dv7","Dv8","Dv9","Dv10","Dv11","Dv12","Dv13","Dv14","Dv15","Dv16","Dv17"]}\n' "$(esc "$dv")" "$(esc "$fake")"
}

discord_set_dv() {
	local num="$1" strat
	echo "$num" | grep -qE '^(1[0-7]|[1-9])$' || { echo '{"error":"некорректный номер Dv"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	strat="$(Dv"$num")"
	grep -q -E '^[[:space:]]*--filter-tcp=2053,2083,2087,2096,8443' "$CONF" || {
		echo '{"error":"блок discord.media отсутствует — сначала установите базовую стратегию с поддержкой Discord"}'; return 1; }
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
	grep -q -- "--filter-l7=discord,stun" "$CONF" || { echo '{"error":"блок discord,stun не найден"}'; return 1; }
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
		roblox) printf '%s\n' \
			"#tr.rbxcdn.com" \
			"108.156.22.8 tr.rbxcdn.com" \
			"108.157.32.114 tr.rbxcdn.com" \
			"18.65.147.108 tr.rbxcdn.com" \
			"18.65.147.112 tr.rbxcdn.com" \
			"13.224.181.18 tr.rbxcdn.com" \
			"13.224.181.74 tr.rbxcdn.com" \
			"54.230.253.22 tr.rbxcdn.com" \
			"54.230.253.81 tr.rbxcdn.com" \
			"54.230.253.48 tr.rbxcdn.com" \
			"54.230.253.59 tr.rbxcdn.com" \
			"143.204.214.34 tr.rbxcdn.com" \
			"143.204.214.67 tr.rbxcdn.com" \
			"143.204.214.92 tr.rbxcdn.com" \
			"99.84.181.25 tr.rbxcdn.com" \
			"99.84.181.63 tr.rbxcdn.com" \
			"65.8.158.45 tr.rbxcdn.com" \
			"65.8.158.112 tr.rbxcdn.com" ;;
		*) return 1 ;;
	esac
}

_hosts_block_status() {
	local block="$1" content line
	content="$(_hosts_block "$block")" || return 1
	while IFS= read -r line; do
		[ -z "$line" ] && continue
		grep -Fxq "$line" "$HOSTS_FILE" || { echo "false"; return; }
	done <<-EOF
	$content
	EOF
	echo "true"
}

hosts_status() {
	local blocks="nalog ntc instagram librusec ai twitch telegram spotify rutor scell githubraw github tapeop roblox" b first=1
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
		while IFS= read -r line; do [ -z "$line" ] && continue; sed -i "\\|^$line\$|d" "$HOSTS_FILE"; done <<-EOF
		$content
		EOF
	else
		while IFS= read -r line; do [ -z "$line" ] && continue; grep -Fxq "$line" "$HOSTS_FILE" || echo "$line" >> "$HOSTS_FILE"; done <<-EOF
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


_remove_ports_if_present() {
	local option="$1" ports="$2" p
	for p in $(echo "$ports" | tr ',' ' '); do
		sed -i "\\#option $option '#s#,$p##g" "$CONF"
	done
	sed -i "\\#option $option '#s#,,#,#g; s#,\$##" "$CONF"
}

_add_ports_if_missing() {
	local option="$1" ports="$2" p
	for p in $(echo "$ports" | tr ',' ' '); do
		grep -q "option $option '.*\b$p\b" "$CONF" || sed -i "\\#option $option '#s#'\$#,$p'#" "$CONF"
	done
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

game_status() {
	local current="" xtreme="false" fake=""
	if [ -f "$CONF" ]; then
		local i
		for i in 1 2 3 4; do grep -q "^#Gv$i\$" "$CONF" && current="Gv$i"; done
		grep -q "^#Gv[0-9]\+Xtreme\$" "$CONF" && xtreme="true"
		fake=$(grep -m1 -- '--dpi-desync-fake-unknown-udp=' "$CONF" | sed 's|.*fake/||')
	fi
	printf '{"current":"%s","xtreme":%s,"fake":"%s"}\n' "$(esc "$current")" "$xtreme" "$(esc "$fake")"
}

game_set() {
	local choice="$1" current="" i
	echo "$choice" | grep -qE '^[1-4]$' || { echo '{"error":"некорректный номер Gv"}'; return 1; }
	[ -f "$CONF" ] || { echo '{"error":"Zapret не установлен"}'; return 1; }
	for i in 1 2 3 4; do grep -q "^#Gv$i\$" "$CONF" && current="Gv$i"; done

	local last_quote gv_line
	last_quote=$(grep -n "^'\$" "$CONF" | tail -n1 | cut -d: -f1)
	if grep -q "^#Gv" "$CONF"; then
		gv_line=$(grep -n "^#Gv" "$CONF" | tail -n1 | cut -d: -f1)
		sed -i "${gv_line},${last_quote}d" "$CONF"
	elif [ -n "$last_quote" ]; then
		sed -i "${last_quote},\$d" "$CONF"
	fi

	if [ "$current" = "Gv$choice" ]; then
		_remove_ports_if_present NFQWS_PORTS_UDP "$PORTS_UDP"
		_remove_ports_if_present NFQWS_PORTS_TCP "$PORTS_TCP"
		echo "'" >> "$CONF"
		zapret_restart
		printf '{"ok":true,"game":"none"}\n'
		return
	fi

	local strat
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
	uci add firewall rule >/dev/null 2>&1
	uci set firewall.@rule[-1].name='Block_UDP_80' >/dev/null 2>&1
	uci add_list firewall.@rule[-1].proto='udp' >/dev/null 2>&1
	uci set firewall.@rule[-1].src='lan' >/dev/null 2>&1
	uci set firewall.@rule[-1].dest='wan' >/dev/null 2>&1
	uci set firewall.@rule[-1].dest_port='80' >/dev/null 2>&1
	uci set firewall.@rule[-1].target='REJECT' >/dev/null 2>&1
	uci add firewall rule >/dev/null 2>&1
	uci set firewall.@rule[-1].name='Block_UDP_443' >/dev/null 2>&1
	uci add_list firewall.@rule[-1].proto='udp' >/dev/null 2>&1
	uci set firewall.@rule[-1].src='lan' >/dev/null 2>&1
	uci set firewall.@rule[-1].dest='wan' >/dev/null 2>&1
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
rm -rf /opt/zapret-manager-luci /usr/libexec/rpcd/zapret-manager \
	/usr/share/luci/menu.d/luci-app-zapret-manager.json \
	/usr/share/rpcd/acl.d/luci-app-zapret-manager.json \
	/www/luci-static/resources/view/zapret-manager \
	/www/luci-static/resources/zapret-manager \
	/www/luci-static/resources/bytetube \
	/www/luci-static/resources/view/bytetube \
	/tmp/zapret-manager-luci /tmp/luci-indexcache* /tmp/luci-modulecache/* \
	/www/zm /www/zm-webui.html 2>/dev/null
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
	if ! $UPDATE >/dev/null 2>&1; then
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

_excl_write() {
	local ips="$1" f
	f="$(_excl_file)"
	mkdir -p "$(_excl_dir)"
	if [ -n "$ips" ]; then
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
	lan_dev=$(uci -q get network.lan.device)
	[ -z "$lan_dev" ] && lan_dev="br-lan"
	arp_tmp="$JOBS_DIR/excl_arp_tmp"
	rm -f "$arp_tmp"
	if [ -f /proc/net/arp ]; then
		tail -n +2 /proc/net/arp | while read -r aip ahw aflags amac amask adev; do
			[ -z "$aip" ] && continue
			[ "$adev" = "$lan_dev" ] || continue
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
	chmod +x /opt/zapret/sync_config.sh
	/opt/zapret/sync_config.sh
	/etc/init.d/zapret restart >/dev/null 2>&1
	sleep 1
	printf '{"ok":true}\n'
}


TG_MTPROTO_VER="0.10"
TGWS_VERSION="0.2.5"
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
		mipsel*) echo "tg-ws-proxy-mipsel-unknown-linux-musl" ;;
		mips*) echo "tg-ws-proxy-mips-unknown-linux-musl" ;;
		*) return 1 ;;
	esac
}

_tg_arch_go() {
	case "$TG_ARCH" in
		aarch64*) echo "tg-ws-proxy-openwrt-aarch64" ;;
		arm*) echo "tg-ws-proxy-openwrt-armv7" ;;
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
	lan_ip=$(uci -q get network.lan.ipaddr 2>/dev/null | cut -d/ -f1)

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
	$UPDATE >/dev/null 2>&1
	echo "==> Скачиваем $(basename "$url")"
	wget -q --timeout=20 -O "$tmp" "$url" || { echo "ОШИБКА скачивания $url"; return 1; }
	$INSTALL "$tmp" >/dev/null 2>&1 || { echo "ОШИБКА установки"; rm -f "$tmp"; return 1; }
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
	$DELETE tg-ws-proxy >/dev/null 2>&1
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
	latest=$(curl -fsSL --connect-timeout 4 --max-time 6 "$TGWS_VERSION_URL" 2>/dev/null | tr -d '[:space:]')
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
		wget -q --timeout=20 -O "$tmp" "$TGWS_BASE_URL/$file" >/dev/null 2>&1
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
	$UPDATE >/dev/null 2>&1
	if [ "$PKG" = "apk" ]; then
		if apk info -e kmod-nft-queue >/dev/null 2>&1; then
			apk add kmod-nft-queue >/dev/null 2>&1
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
	$DELETE tgws >/dev/null 2>&1
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
TEST_BACKUP="$TEST_DIR/backup.conf"
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

zm_update_status() {
	local latest_line latest=""
	latest_line=$(curl -fsSL --connect-timeout 5 --max-time 8 -r 0-400 "$ZM_SCRIPT_URL" 2>/dev/null | grep -m1 '^# Version:')
	if [ -z "$latest_line" ]; then
		latest_line=$(curl -fsSL --connect-timeout 5 --max-time 10 "$ZM_SCRIPT_URL" 2>/dev/null | grep -m1 '^# Version:')
	fi
	latest=$(echo "$latest_line" | sed 's/^# Version:[[:space:]]*//')
	printf '{"current":"%s","latest":"%s"}\n' "$(esc "$ZM_VERSION")" "$(esc "$latest")"
}

do_zm_update() {
	echo "==> Скачиваем установщик"
	local tmp="/tmp/zm_update_install.sh"
	rm -f "$tmp"
	wget -q --timeout=20 -U "Mozilla/5.0" -O "$tmp" "$ZM_SCRIPT_URL" || { echo "ОШИБКА: не удалось скачать установщик"; rm -f "$tmp"; return 1; }
	[ -s "$tmp" ] || { echo "ОШИБКА: скачался пустой файл"; rm -f "$tmp"; return 1; }
	head -c 200 "$tmp" | grep -q '^#!/bin/sh' || { echo "ОШИБКА: скачанный файл не похож на установщик"; rm -f "$tmp"; return 1; }
	chmod +x "$tmp"
	echo "==> Установка запущена в фоне — она перезапускает rpcd/uhttpd, поэтому не может отслеживаться этой же задачей. Панель перезагрузится сама через несколько секунд"
	( sh "$tmp" >/tmp/zm_update_install.log 2>&1; rm -f "$tmp" ) &
}

zm_update_action() {
	job_start zm_update do_zm_update
}

_mixomo_lan_ip() { uci -q get network.lan.ipaddr 2>/dev/null | cut -d/ -f1; }

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
		mihomo_latest=$(curl -Ls --connect-timeout 4 --max-time 6 -o /dev/null -w '%{url_effective}' "https://github.com/MetaCubeX/mihomo/releases/latest" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
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
		mt_latest=$(curl -fsSL --connect-timeout 4 --max-time 6 -o /dev/null -w '%{url_effective}' "https://github.com/MagiTrickle/MagiTrickle/releases/latest" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
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

do_mixomo_install() {
	_ensure_deps
	echo "==> Устанавливаем Mixomo (Mihomo + hev-socks5-tunnel + MagiTrickle)"

	echo "==> Устанавливаем зависимости (unzip, ca-certificates, модули ядра TUN/nftables)"
	$UPDATE >/dev/null 2>&1
	if [ "$PKG" = "apk" ]; then
		$INSTALL unzip ca-certificates kmod-tun kmod-nft-tproxy kmod-nft-nat curl >/dev/null 2>&1
	else
		$INSTALL unzip ca-certificates kmod-tun kmod-nft-tproxy kmod-nft-nat curl libcurl4 ca-bundle >/dev/null 2>&1
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
	curl -Lf --connect-timeout 5 --max-time 90 --retry 3 --retry-delay 2 "$url" -o "$tmp" >/dev/null 2>&1 || { echo "ОШИБКА: не удалось скачать $file"; return 1; }
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
	$UPDATE >/dev/null 2>&1
	$INSTALL hev-socks5-tunnel >/dev/null 2>&1
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
	uci set "firewall.${fw_fwd}.src=lan"
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
			if curl -Lf --connect-timeout 5 --max-time 90 --retry 3 --retry-delay 2 -o "$tmp" "$url_mt" >/dev/null 2>&1; then
				$INSTALL "$tmp" >/dev/null 2>&1 || echo "!! Не удалось установить MagiTrickle"
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
		$DELETE hev-socks5-tunnel >/dev/null 2>&1
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
	$DELETE magitrickle >/dev/null 2>&1
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
				curl -fL --connect-timeout 3 --max-time 7 -o "$tmp" "${GH_MAIN}/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip" >/dev/null 2>&1 && { ok=1; break; }
				sleep 1
			done
			[ "$ok" = "1" ] || { echo "ОШИБКА: не удалось скачать Zashboard"; return 1; }
			command -v unzip >/dev/null 2>&1 || $INSTALL unzip >/dev/null 2>&1
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
				curl -fL --connect-timeout 3 --max-time 7 -o "$tmp" "${GH_MAIN}/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz" >/dev/null 2>&1 && { ok=1; break; }
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
	local prefixes="188.114.96. 188.114.97. 188.114.98. 188.114.99. 162.159.192. 162.159.193. 162.159.195. 8.34.146. 8.39.214. 8.39.204. 8.6.112. 8.35.211. 8.39.125. 8.47.69."
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
		command -v jq >/dev/null 2>&1 || $INSTALL jq >/dev/null 2>&1
		command -v wg >/dev/null 2>&1 || command -v awg >/dev/null 2>&1 || $INSTALL wireguard-tools >/dev/null 2>&1
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


# ================================================================ ByeTube
BYEDPI_REPO="DPITrickster/ByeDPI-OpenWrt"

_bytetube_fetch() { # URL OUT
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 15 --max-time 90 -o "$2" "$1"
	else
		wget -q -T 20 -O "$2" "$1"
	fi
}

health() {
	# Быстрая сводка без сетевых запросов: 0 — не установлено, 1 — работает, 2 — установлено, но не работает
	local zr=0 zr2=0 bt=0 tg=0 mx=0 doh=0 hs=0 inst=0 bad=0 out=""
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
	printf '{"zapret":%s,"zapret2":%s,"bytetube":%s,"tg":%s,"mixomo":%s,"doh":%s,"hosts":%s}\n' \
		"$zr" "$zr2" "$bt" "$tg" "$mx" "$doh" "$hs"
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
	_pkg_is_installed dnsmasq && $DELETE dnsmasq >/dev/null 2>&1
	_pkg_is_installed dnsmasq-dhcpv6 && $DELETE dnsmasq-dhcpv6 >/dev/null 2>&1
	rm -f /tmp/resolv.conf
	if grep -qs '^nameserver' /tmp/resolv.conf.d/resolv.conf.auto 2>/dev/null; then
		cp /tmp/resolv.conf.d/resolv.conf.auto /tmp/resolv.conf
	else
		printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /tmp/resolv.conf
	fi
	if ! $INSTALL dnsmasq-full >/dev/null 2>&1; then
		echo "!! не удалось поставить dnsmasq-full, возвращаю обычный dnsmasq"
		rm -f /tmp/resolv.conf
		if grep -qs '^nameserver' /tmp/resolv.conf.d/resolv.conf.auto 2>/dev/null; then
			cp /tmp/resolv.conf.d/resolv.conf.auto /tmp/resolv.conf
		else
			printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /tmp/resolv.conf
		fi
		$INSTALL dnsmasq >/dev/null 2>&1
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
	# локальный порт SOCKS5 у ByeDPI (отдельный экземпляр, штатный byedpi не трогаем)
	option byedpi_port '1088'
	# стратегия обхода DPI, подбирается под провайдера (вкладка «Тест стратегий»)
	option byedpi_opts '-d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -S -a1'
	# заворачивать IPv6-адреса YouTube (0 — только IPv4)
	option ipv6 '1'
	# QUIC (UDP/443): block — отбрасывать, чтобы клиент откатился на TCP; proxy — гнать через ByeDPI
	option quic 'block'
	# использовать встроенный список доменов YouTube
	option default_domains '1'
	# дополнительные домены:
	# list domain 'example.com'
YTB_FILE_END_7f3a9c
	chmod 644 /etc/config/bytetube
	mkdir -p /etc/hotplug.d/firewall
	cat > /etc/hotplug.d/firewall/90-bytetube <<'YTB_FILE_END_7f3a9c'
#!/bin/sh
# Если после reload firewall наша таблица пропала — восстановить.
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
# YouTube Bypass: ByeDPI + hev-socks5-tunnel, маршрутизация только доменов YouTube

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

# итоговый список доменов: встроенный + свои, только валидные имена
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
				# proper-суффиксы справа налево: если родительский домен уже в списке — запись избыточна
				for (j = n; j >= 2; j--) {
					suf = (suf == "") ? p[j] : p[j] "." suf
					if (suf in have) { redundant = 1; break }
				}
				if (!redundant) print name[i]
			}
		}'
}

dns_remove() {
	local conf
	conf="$(dnsmasq_confdir)/bytetube.conf"
	[ -f "$conf" ] || return 0
	rm -f "$conf"
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
}

# Записать nftset-правила для dnsmasq; dnsmasq перезапускается только при изменении.
# Строка конфига dnsmasq не может быть длиннее ~1 КБ (иначе dnsmasq вообще не запустится),
# поэтому домены разбиваются на несколько строк nftset= по <= 800 байт.
dns_apply() {
	local ipv6="$1" conf domains suffix new old
	conf="$(dnsmasq_confdir)/bytetube.conf"
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
	old=$(cat "$conf" 2>/dev/null)
	if [ "$old" != "$new" ]; then
		mkdir -p "$(dirname "$conf")"
		printf '%s\n' "$new" > "$conf"
		/etc/init.d/dnsmasq restart >/dev/null 2>&1
	fi
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

# правило forward в fw4 (иначе policy drop не пропустит LAN -> tun)
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

	# --- ByeDPI: локальный SOCKS5 с десинхронизацией ---
	procd_open_instance byedpi
	procd_set_param command "$byedpi" -i 127.0.0.1 -p "$byedpi_port"
	set -f
	# shellcheck disable=SC2086
	[ -n "$byedpi_opts" ] && procd_append_param command $byedpi_opts
	set +f
	procd_set_param respawn 3600 5 0
	procd_set_param stderr 1
	procd_close_instance

	# --- hev-socks5-tunnel: TUN -> SOCKS5 ByeDPI ---
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
# Вспомогательная утилита YouTube Bypass (используется LuCI и для отладки)
#   bytetube status   — состояние в JSON
#   bytetube flush    — очистить наборы IP (клиентам нужно заново резолвить домены)
#   bytetube list     — показать IP в наборах
#   bytetube diag [IP|MAC|имя] [сек] — диагностика клиента: куда идёт его DNS и :443-трафик (без аргумента — список клиентов)
#   bytetube test …   — тест стратегий ByeDPI (start|stop|status|log|results|clear|list)
#   bytetube test list get|set|reset strategies|domains [текст] — свои списки для теста
#   bytetube set-strategy "<параметры ciadpi>" — записать стратегию и перезапустить службу

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
	lan_ip=$(uci -q get network.lan.ipaddr | sed 's#/.*##')
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

	# имя/MAC -> IP через аренды DHCP
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

	# все адреса устройства: IPv4 + его глобальные IPv6 (по MAC)
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

	# каждый поток считаем один раз; «в туннеле», если у него хоть раз была метка
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
# Общие константы и функции YouTube Bypass

TUN=ytb0            # имя TUN-интерфейса hev-socks5-tunnel
MARK=0x10000        # fwmark (один выделенный бит)
MASK=0x10000
TABLE=89            # таблица маршрутизации
PREF=8900           # приоритет ip rule
NFT_TABLE=bytetube

# каталог conf-dir, который читает dnsmasq
dnsmasq_confdir() {
	local d
	d=$(sed -n 's/^conf-dir=\([^,]*\).*/\1/p' /var/etc/dnsmasq.conf.* 2>/dev/null | head -n 1)
	[ -n "$d" ] || d=/tmp/dnsmasq.d
	echo "$d"
}

# dnsmasq собран с nftset (dnsmasq-full)?
dnsmasq_has_nftset() {
	dnsmasq --version 2>/dev/null | grep -Eq '(^| )nftset( |$)'
}

# путь к бинарнику ByeDPI
find_byedpi() {
	local b
	for b in /usr/bin/ciadpi /usr/bin/byedpi; do
		[ -x "$b" ] && { echo "$b"; return 0; }
	done
	command -v ciadpi
}

# Параметры ByeDPI приходят из UCI как строка, а раскрываются без eval (по пробелам).
# Кавычки вроде -n "google.com" при этом остались бы в аргументе буквально,
# поэтому их убираем: у аргументов ciadpi пробелов внутри не бывает.
byedpi_opts_clean() {
	printf '%s' "$1" | tr -d "\"'" | tr '\n\r\t' '   ' | sed 's/^ *//; s/ *$//; s/  */ /g'
}
YTB_FILE_END_7f3a9c
	chmod 755 /usr/libexec/bytetube/common.sh
	cat > /usr/libexec/bytetube/net.sh <<'YTB_FILE_END_7f3a9c'
#!/bin/sh
# Настройка nftables и policy routing.
# Использование: net.sh up | down | purge
#   up    — создать таблицу inet bytetube и ip rule
#   down  — убрать правила маркировки и ip rule (наборы IP остаются, чтобы dnsmasq не сыпал ошибками)
#   purge — удалить всё, включая таблицу

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
	# если туннель уже поднят — сразу добавить маршрут (иначе это сделает post-up hev)
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
# Вызывается hev-socks5-tunnel после подъёма TUN (и из net.sh up).
# Если туннель упадёт, маршрут исчезнет вместе с интерфейсом, и помеченный
# трафик уйдёт по основной таблице напрямую (fail-open).

. /lib/functions.sh
. /usr/libexec/bytetube/common.sh

config_load bytetube
config_get IPV6 main ipv6 1
[ -f /proc/net/if_inet6 ] || IPV6=0

ip link set "$TUN" up 2>/dev/null
ip route replace default dev "$TUN" table "$TABLE"
[ "$IPV6" = "1" ] && ip -6 route replace default dev "$TUN" table "$TABLE"

# ответы приходят с адресов YouTube на TUN — нужен нестрогий rp_filter (2 = loose)
echo 2 > "/proc/sys/net/ipv4/conf/$TUN/rp_filter" 2>/dev/null
exit 0
YTB_FILE_END_7f3a9c
	chmod 755 /usr/libexec/bytetube/route-up.sh
	cat > /usr/libexec/bytetube/test.sh <<'YTB_FILE_END_7f3a9c'
#!/bin/sh
# Тест стратегий ByeDPI.
#   bytetube test start | stop | status | log | results | clear
#
# Списки стратегий и доменов: свои (/etc/bytetube/, переживают обновление) или встроенные.
#   bytetube test list get|set|reset strategies|domains [текст]
#
# Каждая стратегия запускается во ВРЕМЕННОМ экземпляре ciadpi на отдельном порту,
# домены проверяются через него по curl --socks5. Боевой сервис и трафик клиентов
# не затрагиваются, конфигурация не меняется. Сначала контрольный замер без обхода.

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

# ---------------------------------------------------------------- списки
# имя файла у пользователя
list_name() {
	case "$1" in
		strategies) echo strategies.txt ;;
		domains)    echo test-domains.txt ;;
	esac
}

# путь действующего списка: свой (если есть и не пуст), иначе встроенный
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

# домены: по одному в строке; допускаем ссылки, *.домен, запятые/пробелы; комментарии (#) сохраняем.
# Первая некорректная запись пишется в файл $1.
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

# стратегии: по одной в строке, пробелы схлопываются, дубли убираются, комментарии (#) сохраняем
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

# ---------------------------------------------------------------- управление
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
	# полностью отвязываем от stdin/stdout, иначе rpcd будет ждать завершения
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

# ---------------------------------------------------------------- движок
# check_url ЗАПИСЬ OKFILE LOGFILE [socks host:port]
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

# check_all ФАЙЛ_URL LOGFILE [socks] -> "ok total"
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
	# текущая стратегия идёт первой, затем список; дубликаты (без учёта кавычек) отбрасываем
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
		# ключ сортировки: (999999-ok) и номер — при обычном лексикографическом sort получается
		# «больше ok выше, при равенстве раньше в списке». sort -k/-n в busybox OpenWrt может не работать.
		printf '%06d\t%06d\t%s\t%s\t%s\n' "$((999999 - ok))" "$idx" "$ok" "$tot" "$line" >> "$RAW"
	done < "$cand"

	if [ -f "$STOP" ]; then
		echo "==> Тест остановлен пользователем, показываю то, что успели проверить"
		rm -f "$STOP"
	else
		echo "==> Тест завершён"
	fi
	[ "$skipped" -gt 0 ] && echo "==> Пропущено стратегий (не запустились): $skipped"

	# итог: по убыванию числа доступных доменов, при равенстве — в порядке списка
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
# Домены YouTube и связанных сервисов Google (поддомены подхватываются автоматически).
# Список объединяется с «Дополнительными доменами» из настроек. Вложенные записи
# (например, i.ytimg.com при наличии ytimg.com) сервис сам отбрасывает как избыточные.
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
# Google and Youtube
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

# Googlevideo
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
	$UPDATE >/dev/null 2>&1

	if ! _pkg_is_installed kmod-tun; then
		echo "==> Ставлю kmod-tun"
		$INSTALL kmod-tun >/dev/null 2>&1 || { echo "ОШИБКА: kmod-tun не установлен"; return 1; }
	fi
	_bytetube_ensure_dnsmasq_full || return 1

	if ! _pkg_is_installed hev-socks5-tunnel; then
		echo "==> Ставлю hev-socks5-tunnel"
		$INSTALL hev-socks5-tunnel >/dev/null 2>&1 || { echo "ОШИБКА: hev-socks5-tunnel не найден в репозитории (есть в feeds OpenWrt 24.10+)"; return 1; }
		NEW_HEV=1
	fi
	_bytetube_install_byedpi || return 1

	for p in ca-bundle curl; do
		_pkg_is_installed "$p" || $INSTALL "$p" >/dev/null 2>&1 || echo "!! не удалось поставить $p — тест стратегий работать не будет (остальное — да)"
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
		rm -f "$(dnsmasq_confdir)/bytetube.conf"
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
	$DELETE byedpi >/dev/null 2>&1
	if [ -x "$MIHOMO_BIN" ] && [ -x /etc/init.d/magitrickle ]; then
		echo "==> hev-socks5-tunnel используется Mixomo — оставляю пакет"
	else
		echo "==> Удаляю пакет hev-socks5-tunnel"
		$DELETE hev-socks5-tunnel >/dev/null 2>&1
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

do_doh_install() {
	local installed
	installed=$(doh_status | grep -o '"installed":[a-z]*' | cut -d: -f2)
	if [ "$installed" = "true" ]; then
		echo "==> DNS over HTTPS уже установлен"
		return 0
	fi
	_ensure_deps
	echo "==> Обновляем список пакетов"
	$UPDATE >/dev/null 2>&1
	echo "==> Устанавливаем https-dns-proxy и luci-app-https-dns-proxy"
	$INSTALL https-dns-proxy luci-app-https-dns-proxy >/dev/null 2>&1 || { echo "ОШИБКА установки"; return 1; }
	echo "==> Готово, DNS over HTTPS установлен — выберите провайдера ниже"
}

do_doh_remove() {
	echo "==> Удаляем DNS over HTTPS"
	echo "==> Удаляем пакеты"
	$DELETE https-dns-proxy luci-app-https-dns-proxy >/dev/null 2>&1
	echo "==> Удаляем файлы конфигурации"
	rm -f /etc/config/https-dns-proxy /etc/init.d/https-dns-proxy
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	echo "==> Готово, DNS over HTTPS удалён"
}

doh_remove() {
	job_start doh_remove do_doh_remove
}

doh_install() {
	job_start doh_install do_doh_install
}

doh_status() {
	local installed="false" current=""
	if [ "$PKG" = "apk" ]; then apk info -e https-dns-proxy >/dev/null 2>&1 && installed="true"
	else opkg list-installed 2>/dev/null | grep -q '^https-dns-proxy ' && installed="true"; fi
	if [ -f "$_doh_file" ]; then
		if grep -q "eu.geohide.ru" "$_doh_file"; then current="geohide_eu"
		elif grep -q "us.geohide.ru" "$_doh_file"; then current="geohide_us"
		elif grep -q "geohide.ru" "$_doh_file"; then current="geohide_ru"
		elif grep -q "xbox-dns.ru" "$_doh_file"; then current="xbox"
		elif grep -q "cloudflare-dns.com" "$_doh_file"; then current="cloudflare"
		elif grep -q "dns.google" "$_doh_file"; then current="google"
		elif grep -q "dns.quad9.net" "$_doh_file"; then current="quad9"; fi
	fi
	printf '{"installed":%s,"current":"%s"}\n' "$installed" "$(esc "$current")"
}

doh_set() {
	local provider="$1" url bootstrap=""
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
	{
		echo "config main 'config'"
		echo "	option canary_domains_icloud '1'"
		echo "	option canary_domains_mozilla '1'"
		echo "	option dnsmasq_config_update '*'"
		echo "	option force_dns '1'"
		echo "	option notrack_dns '1'"
		echo "	list force_dns_port '53'"
		echo "	list force_dns_port '853'"
		echo "	list force_dns_src_interface 'lan'"
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
	} > "$_doh_file"
	/etc/init.d/https-dns-proxy reload >/dev/null 2>&1
	/etc/init.d/https-dns-proxy restart >/dev/null 2>&1
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	printf '{"ok":true,"provider":"%s"}\n' "$provider"
}



cmd="$1"; shift
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
	strategy_list_flowseal)       strategy_list_flowseal ;;
	strategy_set_flowseal)         strategy_set_flowseal "$1" ;;
	strategy_list_youtube)          strategy_list_youtube ;;
	strategy_set_youtube)            strategy_set_youtube "$1" ;;
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
	bytetube_action)                      bytetube_action "$1" ;;
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
	json_add_object "strategy_list_flowseal"; json_close_object
	json_add_object "strategy_set_flowseal";  json_add_string "name" "string"; json_close_object
	json_add_object "strategy_list_youtube";  json_close_object
	json_add_object "strategy_set_youtube";   json_add_string "name" "string"; json_close_object
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
		strategy_list_flowseal)  "$BACKEND" strategy_list_flowseal ;;
		strategy_set_flowseal)   json_get_var name name;       "$BACKEND" strategy_set_flowseal "$name" ;;
		strategy_list_youtube)   "$BACKEND" strategy_list_youtube ;;
		strategy_set_youtube)    json_get_var name name;       "$BACKEND" strategy_set_youtube "$name" ;;
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
		exclusions_file_set)           json_get_var content content; "$BACKEND" exclusions_file_set "$content" ;;
		exclusions_file_restore)       "$BACKEND" exclusions_file_restore ;;
		nfqws_opt_get)                 "$BACKEND" nfqws_opt_get ;;
		nfqws_opt_set)                 json_get_var content content; "$BACKEND" nfqws_opt_set "$content" ;;
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
		hosts_file_set)          json_get_var content content; "$BACKEND" hosts_file_set "$content" ;;
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
		mixomo_config_set)       json_get_var content content; "$BACKEND" mixomo_config_set "$content" ;;
		mixomo_subscription_set) json_get_var url url; "$BACKEND" mixomo_subscription_set "$url" ;;
		mixomo_magitrickle_list_set) json_get_var id id; "$BACKEND" mixomo_magitrickle_list_set "$id" ;;
		mixomo_autorestart_set)  json_get_var mode mode; json_get_var value value; "$BACKEND" mixomo_autorestart_set "$mode" "$value" ;;
		mixomo_ui_action)        json_get_var which which; "$BACKEND" mixomo_ui_action "$which" ;;
		mixomo_warp_status)      "$BACKEND" mixomo_warp_status ;;
		mixomo_warp_action)      json_get_var endpoint_mode endpoint_mode; "$BACKEND" mixomo_warp_action "$endpoint_mode" ;;
		mixomo_warp_integrate_action) "$BACKEND" mixomo_warp_integrate_action ;;
		mixomo_warp_config_set) json_get_var content content; "$BACKEND" mixomo_warp_config_set "$content" ;;
		bytetube_installed)      "$BACKEND" bytetube_installed ;;
		health)                  "$BACKEND" health ;;
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
					"zapret_latest_version", "bytetube_installed", "health"
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
					"strategy_set_v", "strategy_set_flowseal", "strategy_set_youtube",
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
					"bytetube_action"
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
var callSystemInfo = rpc.declare({ object: 'zapret-manager', method: 'system_info', expect: {} });
var callJobStatus = rpc.declare({ object: 'zapret-manager', method: 'job_status', params: ['job'], expect: {} });
var callLogTail = rpc.declare({ object: 'zapret-manager', method: 'log_tail', params: ['job'], expect: {} });
var callZapretAction = rpc.declare({ object: 'zapret-manager', method: 'zapret_action', params: ['action'], expect: {} });
var callZapretLatestVersion = rpc.declare({ object: 'zapret-manager', method: 'zapret_latest_version', expect: {} });
var callZapret2Action = rpc.declare({ object: 'zapret-manager', method: 'zapret2_action', params: ['action'], expect: {} });
var callStrategyListV = rpc.declare({ object: 'zapret-manager', method: 'strategy_list_v', expect: {} });
var callStrategySetV = rpc.declare({ object: 'zapret-manager', method: 'strategy_set_v', params: ['version'], expect: {} });
var callStrategyListFlowseal = rpc.declare({ object: 'zapret-manager', method: 'strategy_list_flowseal', expect: {} });
var callStrategySetFlowseal = rpc.declare({ object: 'zapret-manager', method: 'strategy_set_flowseal', params: ['name'], expect: {} });
var callStrategyListYoutube = rpc.declare({ object: 'zapret-manager', method: 'strategy_list_youtube', expect: {} });
var callStrategySetYoutube = rpc.declare({ object: 'zapret-manager', method: 'strategy_set_youtube', params: ['name'], expect: {} });
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

function renderLog(logEl, text) {
	logEl.innerHTML = '';
	var lines = (text || '').split('\n');
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
	boardInfo: callBoardInfo,
	parseSize: parseSize,
	fmtSize: fmtSize,
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
				dohNode, E('span', {}, DOH_LABELS[doh.current] || doh.current || 'провайдер не определён')
			]);

			var items = [];
			items.push(row('Zapret', zm.stateBadge(zrSt)));
			if (zrSt !== 0 && d.zapret_version) items.push(row('Версия Zapret', E('span', {}, d.zapret_version)));
			if (zrSt !== 0 && d.strategy) items.push(row('Стратегия', E('span', {}, d.strategy)));
			items.push(row('Zapret2', zm.stateBadge(zr2St)));
			items.push(row('ByeTube', zm.stateBadge(st(h, 'bytetube', 0))));
			items.push(row('TG WS Proxy', zm.stateBadge(st(h, 'tg', 0))));
			items.push(row('Mixomo', zm.stateBadge(st(h, 'mixomo', 0))));
			items.push(row('DNS over HTTPS', dohNode));
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
				row('OpenWrt', E('span', {}, sysInfo.openwrt || '—'))
			];
			var memRows = [];
			if (mem.total) memRows.push(row('ОЗУ', E('span', {}, zm.usageText(mem.total - ramAvail, mem.total))));
			memRows.push(row('Флеш', E('span', {}, zm.usageText(ru, ru + rf))));
			memRows.push(row('/tmp', E('span', {}, zm.usageText(tu, tu + tf))));

			cards.appendChild(E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Система'),
				E('div', { 'class': 'bt-cols' }, [
					E('div', { 'class': 'bt-col' }, rows),
					E('div', { 'class': 'bt-col' }, memRows)
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

		this.refreshOverview = refreshOverview;

		var zmUpdateBusy = false;
		function waitForServerAndReload() {
			setTimeout(function() { location.href = L.url('admin/logout'); }, 4000);
		}
		function renderZmUpdate() {
			updateEl.innerHTML = '';
			if (!zmUpdate.latest || zmUpdate.latest === zmUpdate.current) return;
			updateEl.appendChild(E('div', { 'class': 'zm-refresh-banner zm-show' }, [
				E('span', {}, 'Доступна новая версия панели Zapret Manager: ' + zmUpdate.latest + ' (у вас установлена ' + zmUpdate.current + ').'),
				E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() {
						if (zmUpdateBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						zmUpdateBusy = true;
						zm.toast('Обновление запущено — через 4 секунды вы будете автоматически выведены из LuCI. Просто зайдите заново', 'warning', 6000);
						zm.zmUpdateAction().then(function(res) {
							zmUpdateBusy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
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

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.dohStatus();
	},

	render: function(data) {
		var wrap = E('div', { 'class': 'zm-wrap' });
		var logEl = E('pre', { 'class': 'zm-log' });
		var bannerEl = E('div', {});
		var busy = false;

		var grid = E('div', { 'class': 'zm-grid' });
		function renderGrid() {
			grid.innerHTML = '';
			PROVIDERS.forEach(function(p) {
				grid.appendChild(E('div', {
					'class': 'zm-tile' + (data.current === p.id ? ' zm-active' : ''),
					'click': function() {
						if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						busy = true;
						zm.toast('Меняем DNS на ' + p.label, 'warning');
						zm.dohSet(p.id).then(function(res) {
							busy = false;
							if (res.error) { zm.toast(res.error, 'error'); return; }
							zm.toast(p.label + ' применён', 'info');
							zm.dohStatus().then(function(res2) { data = res2; renderGrid(); });
						}).catch(function() { busy = false; });
					}
				}, p.label));
			});
		}
		renderGrid();

		var installBtn = E('button', {
			'class': 'cbi-button cbi-button-positive',
			'click': function() {
				if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
				zm.toast('Устанавливаем DNS over HTTPS', 'warning');
				busy = true;
				zm.dohInstall().then(function(res) {
					if (res.error) { busy = false; zm.toast(res.error, 'error'); return; }
					if (res.started) {
						zm.pollJob('doh_install', logEl, function(ok) {
							busy = false;
							zm.toast(ok ? 'DNS over HTTPS установлен' : 'Ошибка установки', ok ? 'info' : 'error');
							if (ok) {
								bannerEl.innerHTML = '';
								bannerEl.appendChild(zm.refreshBanner('Пункт меню DNS over HTTPS в LuCI мог измениться — выйдите и зайдите заново.'));
							}
						});
					} else {
						busy = false;
					}
				}).catch(function() { busy = false; });
			}
		}, 'Установить DNS over HTTPS');

		var removeBtn = E('button', {
			'class': 'cbi-button cbi-button-remove',
			'click': function() {
				if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
				zm.toast('Удаляем DNS over HTTPS', 'warning');
				busy = true;
				zm.dohRemove().then(function(res) {
					if (res.error) { busy = false; zm.toast(res.error, 'error'); return; }
					if (res.started) {
						zm.pollJob('doh_remove', logEl, function(ok) {
							busy = false;
							zm.toast(ok ? 'DNS over HTTPS удалён' : 'Ошибка удаления', ok ? 'info' : 'error');
							if (ok) {
								bannerEl.innerHTML = '';
								bannerEl.appendChild(zm.refreshBanner('Пункт меню DNS over HTTPS в LuCI мог измениться — выйдите и зайдите заново.'));
							}
						});
					} else {
						busy = false;
					}
				}).catch(function() { busy = false; });
			}
		}, 'Удалить');

		var card = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'DNS over HTTPS'),
			E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'Пакет'),
				zm.badge(data.installed === true, 'установлен', 'не установлен')
			]),
			E('div', { 'class': 'zm-actions' }, data.installed ? [ removeBtn ] : [ installBtn ]),
			grid,
			logEl
		]);

		wrap.appendChild(card);
		wrap.appendChild(bannerEl);
		return wrap;
	}
});
ZM_INSTALLER_EOF
chmod 0644 '/www/luci-static/resources/view/zapret-manager/doh.js'

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
	tapeop: 'tapeop.dev',
	roblox: 'Roblox'
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

		function renderStatus(d) {
			statusCard.innerHTML = '';
			var installed = d.mihomo === 'installed';
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
							zm.status().then(function(d) { status = d; renderZCard(d); renderBanner(); renderV(); });
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

			var currentBanner = E('div', { 'class': 'zm-current-banner' });
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
							zm.strategyListFlowseal().then(function(res) {
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
				currentBanner.className = 'zm-current-banner' + (status.strategy ? '' : ' zm-current-empty');
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
								refreshState();
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
								refreshState();
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

			renderBanner();
			renderV();

			panels.strategy.appendChild(vCard);
			panels.strategy.appendChild(fCard);
			panels.strategy.appendChild(logEl);

			zm.strategyListFlowseal().then(function(res) {
				if (!res.started) renderFlowseal(res);
				else fGrid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список ещё не загружен — нажмите «Обновить список».'));
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
					nfqwsCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Прямое редактирование параметров NFQWS_OPT в /etc/config/zapret — для опытных пользователей.'));
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
				nfqwsCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Содержимое в /etc/config/zapret. Сохранение применяет изменения и перезапускает Zapret.'));
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
								refreshState();
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
				mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Тест идёт в фоне — переключение вкладок или закрытие LuCI его не прервёт. По окончании конфигурация всегда возвращается к тому, что было до начала теста — стратегии только тестируются, лучшую нужно применить вручную на странице «Стратегии».'));
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
				ytCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Всегда тестируется отдельно от v/Flowseal.'));
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
				curCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Проверяет уже применённую сейчас стратегию (конфигурация не переключается) по доменам DPI и отдельно по доменам YouTube.'));
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
				(res.items || []).forEach(function(it) {
					grid.appendChild(E('div', {
						'class': 'zm-tile' + (current === it.id ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Применяем стратегию ' + it.id + '', 'warning');
							zm.strategySetYoutube(it.id).then(function(r2) {
								busy = false;
								if (!zm.notifyStrategyResult(r2, it.id)) return;
								refreshState();
							}).catch(function() { busy = false; });
						}
					}, it.id));
				});
				if (!res.items || !res.items.length)
					grid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список пуст — нажмите «Обновить список».'));
			}

			function refreshState() {
				zm.status().then(function(s) {
					current = currentYv(s);
					if (lastList) renderGrid(lastList);
				});
			}

			current = currentYv(status);

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
							zm.strategyListYoutube().then(function(res) {
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
				E('p', { 'class': 'zm-hint' }, 'Применяется поверх текущей стратегии — заменяет только YouTube-часть.')
			]);

			panels.youtube.appendChild(card);
			panels.youtube.appendChild(logEl);

			if (!initial.started) {
				renderGrid(initial);
			} else {
				grid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список ещё не загружен — нажмите «Обновить список».'));
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
				[1, 2, 3, 4].forEach(function(n) {
					gvGrid.appendChild(E('div', {
						'class': 'zm-tile' + (data.current === ('Gv' + n) ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Применяем игровую стратегию Gv' + n + '', 'warning');
							zm.gameSet(String(n)).then(function(res) {
								busy = false;
								if (res.error) { zm.toast(res.error, 'error'); return; }
								zm.toast(res.game === 'none' ? 'Игровая стратегия снята' : res.game + ' применена', 'info');
								refreshState();
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
				xtremeRow.appendChild(E('p', { 'class': 'zm-hint' }, 'Внимание: может повлиять на работу приложений и соединений — используйте только для проверки игр.'));
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
								refreshState();
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
								refreshState();
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

			renderGv();
			renderXtreme();
			renderFake();

			var gvCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Игровая стратегия'),
				gvGrid,
				E('p', { 'class': 'zm-hint' }, 'Повторный клик по уже выбранной — снимает игровую стратегию.')
			]);

			var xtremeCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Xtreme режим'),
				xtremeRow
			]);

			var fakeCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Fake-файл для игровой стратегии'),
				fakeGrid,
				E('p', { 'class': 'zm-hint' }, 'Доступно только если игровая стратегия уже выбрана.')
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
				(data.available || []).forEach(function(dv) {
					dvGrid.appendChild(E('div', {
						'class': 'zm-tile' + (data.current === dv ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Применяем стратегию ' + dv + '', 'warning');
							zm.discordSetDv(dv.replace('Dv', '')).then(function(res) {
								busy = false;
								if (!zm.notifyStrategyResult(res, dv)) return;
								refreshState();
							}).catch(function() { busy = false; });
						}
					}, dv));
				});
			}

			function renderFake() {
				fakeGrid.innerHTML = '';
				GAME_FAKES.forEach(function(f) {
					fakeGrid.appendChild(E('div', {
						'class': 'zm-tile' + (data.current_fake === f ? ' zm-active' : ''),
						'click': function() {
							if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
							busy = true;
							zm.toast('Меняем fake-файл на ' + f + '', 'warning');
							zm.discordSetFake(f).then(function(res) {
								busy = false;
								if (!zm.notifyStrategyResult(res, f)) return;
								refreshState();
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

			renderDv();
			renderFake();

			var dvCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Стратегия для discord.media'),
				dvGrid,
				E('p', { 'class': 'zm-hint' }, 'Нужна базовая стратегия с блоком discord.media.')
			]);

			var fakeCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Fake-файл для discord,stun'),
				fakeGrid
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
			editorCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Редактирование /opt/zapret/ipset/zapret-hosts-user-exclude.txt — домены, для которых Zapret не применяется. Сохранение перезапускает Zapret.'));
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
					grid.appendChild(E('p', { 'class': 'zm-hint' }, 'Устройства не найдены (нет записей в /tmp/dhcp.leases).'));
			}

			renderGrid(data.devices);

			var manualInput = E('input', { 'type': 'text', 'placeholder': '192.168.1.100', 'class': 'cbi-input-text' });

			var card = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Исключение устройств из Zapret'),
				grid,
				E('p', { 'class': 'zm-hint' }, 'Клик по устройству — включить/выключить исключение (трафик этого IP не будет проходить через Zapret).'),
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
.zm-log:empty::before { content: "Ожидание вывода..."; opacity: .4; }

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
	padding: 22px 26px; border-radius: 14px;
	box-shadow: 0 10px 40px rgba(0,0,0,.4);
	font-size: 17px; line-height: 1.5; font-weight: 500; cursor: pointer;
	opacity: 0; transform: translateX(24px);
	transition: opacity .22s ease, transform .22s ease;
	border-left: 6px solid #1a7f37;
}
.zm-toast-show { opacity: 1; transform: translateX(0); }
.zm-toast-error { border-left-color: #cf222e; }
.zm-toast-warning { border-left-color: #9a6700; }
.zm-toast-icon { flex-shrink: 0; font-weight: 700; font-size: 22px; line-height: 1.3; }
.zm-toast-info .zm-toast-icon { color: #3fb950; }
.zm-toast-error .zm-toast-icon { color: #ff7b72; }
.zm-toast-warning .zm-toast-icon { color: #e3b341; }
.zm-toast-text { overflow-wrap: anywhere; }

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
			{ product: 'Zapret Manager LuCI и ByeTube', author: 'StressOzz', url: 'https://github.com/StressOzz', self: true },
			{ product: 'zapret-openwrt', author: 'remittor', url: 'https://github.com/remittor/zapret-openwrt' },
			{ product: 'стратегии Flowseal', author: 'Flowseal', url: 'https://github.com/Flowseal/zapret-discord-youtube' },
			{ product: 'ByeDPI-OpenWrt', author: 'DPITrickster', url: 'https://github.com/DPITrickster/ByeDPI-OpenWrt' },
			{ product: 'mihomo', author: 'MetaCubeX', url: 'https://github.com/MetaCubeX/mihomo' },
			{ product: 'MagiTrickle', author: 'MagiTrickle', url: 'https://github.com/MagiTrickle/MagiTrickle' },
			{ product: 'sTGWS', author: 'xyzmean', url: 'https://gitlab.com/xyzmean/brb' },
			{ product: 'tg-ws-proxy-go (MTProto)', author: 'spatiumstas', url: 'https://github.com/spatiumstas/tg-ws-proxy-go' },
			{ product: 'tg-ws-proxy-go (SOCKS5)', author: 'd0mhate', url: 'https://github.com/d0mhate/-tg-ws-proxy-Manager-go' },
			{ product: 'tg-ws-proxy-rs (Rust)', author: 'valnesfjord', url: 'https://github.com/valnesfjord/tg-ws-proxy-rs' },
			{ product: 'GeoHideDNS', author: 'Internet-Helper', url: 'https://github.com/Internet-Helper/GeoHideDNS' },
			{ product: 'dpi-checkers', author: 'hyperion-cs', url: 'https://github.com/hyperion-cs/dpi-checkers' }
		];
		var creditsGrid = E('div', { 'class': 'zm-credits-grid' });
		CREDITS.forEach(function(c) {
			creditsGrid.appendChild(E('div', { 'class': 'zm-credit-tile' + (c.self ? ' zm-credit-self' : '') }, [
				E('div', { 'class': 'zm-credit-product' }, c.product),
				E('div', { 'class': 'zm-credit-author' }, c.author),
				E('a', { 'href': c.url, 'target': '_blank', 'rel': 'noreferrer' }, c.url.replace(/^https?:\/\//, ''))
			]));
		});
		var creditsCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Спасибо'),
			E('p', { 'class': 'zm-hint' }, 'Zapret Manager LuCI объединяет и упаковывает в один интерфейс наработки этих проектов и их авторов.'),
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
.zm-log:empty::before { content: "Ожидание вывода..."; opacity: .4; }

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
	padding: 22px 26px; border-radius: 14px;
	box-shadow: 0 10px 40px rgba(0,0,0,.4);
	font-size: 17px; line-height: 1.5; font-weight: 500; cursor: pointer;
	opacity: 0; transform: translateX(24px);
	transition: opacity .22s ease, transform .22s ease;
	border-left: 6px solid #1a7f37;
}
.zm-toast-show { opacity: 1; transform: translateX(0); }
.zm-toast-error { border-left-color: #cf222e; }
.zm-toast-warning { border-left-color: #9a6700; }
.zm-toast-icon { flex-shrink: 0; font-weight: 700; font-size: 22px; line-height: 1.3; }
.zm-toast-info .zm-toast-icon { color: #3fb950; }
.zm-toast-error .zm-toast-icon { color: #ff7b72; }
.zm-toast-warning .zm-toast-icon { color: #e3b341; }
.zm-toast-text { overflow-wrap: anywhere; }

.zm-current-banner {
	display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
	background: rgba(26,127,55,.07); border: 1px solid rgba(26,127,55,.22);
	border-radius: 10px; padding: 10px 16px; font-size: 13px; margin-bottom: 4px;
}
.zm-current-banner b { font-weight: 700; }
.zm-current-banner.zm-current-empty {
	background: rgba(110,118,129,.08); border-color: rgba(110,118,129,.2);
}

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

if command -v apk >/dev/null 2>&1; then PM="apk"; INSTALL="apk add"
else PM="opkg"; INSTALL="opkg install"; fi
command -v curl >/dev/null 2>&1 || $INSTALL curl >/dev/null 2>&1 || true
command -v unzip >/dev/null 2>&1 || $INSTALL unzip >/dev/null 2>&1 || true


# ─────────────── Web UI (отдельный веб-интерфейс на порту 7788) ───────────────
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
var K_SID = 'zmw.sid', K_THEME = 'zmw.theme', K_USER = 'zmw.user';

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
	return fetch('/ubus', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		cache: 'no-store',
		credentials: 'omit',
		body: JSON.stringify({
			jsonrpc: '2.0', id: ++rpcSeq, method: 'call',
			params: [ useSid || sid || NULL_SID, object, method, params || {} ]
		})
	}).then(function (r) {
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
		return msg.result;
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
	rocket: '<path d="M14.5 4.2c2.6-1.1 5-1.2 5.3-.9.3.3.2 2.7-.9 5.3-1 2.4-3.1 4.9-6.2 6.9l-3.2-3.2c2-3.1 4.5-5.2 6.9-6.2z"/><circle cx="15.2" cy="8.8" r="1.6"/><path d="M9.5 12.3l-3.6-.4 2.4-3.2 3.3-.2M11.7 14.5l.4 3.6 3.2-2.4.2-3.3"/><path d="M6.8 16.2c-1.3.4-2.1 2.2-2.3 3.3 1.1-.2 2.9-1 3.3-2.3"/>',
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
		E('<svg viewBox="0 0 1254 1254" aria-hidden="true">' +
			'<defs><linearGradient id="' + id + '" x1="0" y1="0" x2="0.35" y2="1">' +
			'<stop offset="0" stop-color="#5fd8ff"/><stop offset=".5" stop-color="#1aa3ff"/><stop offset="1" stop-color="#0a7cff"/>' +
			'</linearGradient></defs>' +
			'<g fill="url(#' + id + ')" stroke="#04101f" stroke-width="22" stroke-linejoin="miter">' +
			'<path d="M455 170L1072 118L1240 18L685 615L30 1240L742 335L258 385Z"/>' +
			'<path d="M1030 458L722 862L1222 797L1008 1022L310 1100Z"/>' +
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
function themePref() { var t = sget(K_THEME); return t === 'light' || t === 'dark' ? t : 'auto'; }
function themeEffective() { var p = themePref(); return p === 'auto' ? ((mqDark && !mqDark.matches) ? 'light' : 'dark') : p; }
function applyTheme() {
	var t = themeEffective();
	var h = document.documentElement;
	h.setAttribute('data-theme', t);
	h.classList.toggle('zm-theme-dark', t === 'dark');
	h.setAttribute('data-zm-theme-checked', '1');
	var mc = document.querySelector('meta[name="theme-color"]');
	if (mc) mc.setAttribute('content', t === 'dark' ? '#0a0c12' : '#f3f5fa');
	Array.prototype.forEach.call(document.querySelectorAll('.zmw-theme-toggle'), function (b) {
		b.innerHTML = '';
		b.appendChild(icon(t === 'dark' ? 'sun' : 'moon'));
		b.title = t === 'dark' ? 'Светлая тема' : 'Тёмная тема';
	});
}
if (mqDark && mqDark.addEventListener) mqDark.addEventListener('change', function () { if (themePref() === 'auto') applyTheme(); });
function toggleTheme() {
	sset(K_THEME, themeEffective() === 'dark' ? 'light' : 'dark', true);
	document.documentElement.classList.add('zmw-theme-anim');
	applyTheme();
	setTimeout(function () { document.documentElement.classList.remove('zmw-theme-anim'); }, 400);
}

/* ───────────────────────── Маршруты ───────────────────────── */

var ROUTES = [
	{ id: 'dashboard', title: 'Дашборд', sub: 'Состояние всех компонентов', icon: 'dashboard', group: 'Обзор' },
	{ id: 'strategy', title: 'Zapret', sub: 'Стратегии, тесты, YouTube, игры, Discord и исключения', icon: 'shield', group: 'Обход блокировок', dot: 'zapret' },
	{ id: 'zapret2', title: 'Zapret2', sub: 'Установка и управление Zapret2', icon: 'bolt', group: 'Обход блокировок', dot: 'zapret2' },
	{ id: 'bytetube', title: 'ByeTube', sub: 'YouTube через ByeDPI', icon: 'play', group: 'Обход блокировок', dot: 'bytetube' },
	{ id: 'tgproxy', title: 'TG WS Proxy', sub: 'Прокси для Telegram', icon: 'send', group: 'Обход блокировок', dot: 'tg' },
	{ id: 'mixomo', title: 'Mixomo', sub: 'Mihomo, MagiTrickle и WARP', icon: 'layers', group: 'Обход блокировок', dot: 'mixomo' },
	{ id: 'hosts', title: 'Hosts', sub: 'Домены в hosts и списки GeoHide', icon: 'list', group: 'Сеть', dot: 'hosts' },
	{ id: 'doh', title: 'DNS over HTTPS', sub: 'Шифрованный DNS для всей сети', icon: 'globe', group: 'Сеть', dot: 'doh' },
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

	deviceEl = E('div', { 'class': 'zmw-device' }, [ E('div', { 'class': 'zmw-device-model' }, [ 'Роутер' ]), E('div', { 'class': 'zmw-device-sub' }, [ location.hostname ]) ]);
	verEl = E('div', { 'class': 'zmw-brand-sub' }, [ 'Web UI' ]);
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
			]),
			E('div', { 'class': 'zmw-credit' }, [ 'by StressOzz' ])
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
		E('div', { 'class': 'zmw-main' }, [ top, viewEl, E('footer', { 'class': 'zmw-foot' }, [ 'Zapret Manager Web UI · тот же бэкенд, что и в LuCI' ]) ]),
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
		r.order = key === 'ram' ? 0 : key === 'flash' ? 1 : 2;
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
	}).catch(function () {});
}

var statusBusy = false;
var DOT_TEXT = { 1: 'работает', 2: 'не работает' };
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
		Object.keys(navDots).forEach(function (k) { setDot(navDots[k], h[k]); });
	}).catch(function () {}).then(function () { statusBusy = false; });
}
function setDot(el, st) {
	if (!el) return;
	el.className = 'zmw-nav-dot' + (st === 1 ? ' zmw-on' : st === 2 ? ' zmw-stop' : '');
	el.title = DOT_TEXT[st] || '';
}

function loadShellInfo() {
	callSysInfo().then(function (i) {
		if (!i || i.error) return;
		deviceEl.firstChild.textContent = String(i.model || 'Роутер').replace(/\s*\(.*\)\s*$/, '') || i.model;
		deviceEl.title = [ i.model, i.openwrt ? 'OpenWrt ' + i.openwrt : '', i.arch ].filter(Boolean).join('\n');
		deviceEl.lastChild.textContent = [ i.openwrt ? 'OpenWrt ' + i.openwrt : '', i.arch || '' ].filter(Boolean).join(' · ') || location.hostname;
	}).catch(function () {});
	callUpd().then(function (u) {
		if (!u || u.error) return;
		if (u.current) verEl.textContent = 'Web UI · v' + u.current;
		if (u.latest && u.current && u.latest !== u.current) {
			updateEl.hidden = false;
			updateEl.textContent = 'Доступна версия ' + u.latest;
		}
	}).catch(function () {});
}

var shellTimer = null;
function startShellPolling() {
	if (shellTimer) return;
	shellTimer = setInterval(function () { if (!document.hidden) { refreshShellStatus(); refreshMemory(); } }, 15000);
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
	showLogin('Сессия истекла — войдите снова', 'warning');
}

function logout() {
	var s = sid;
	sid = null;
	sset(K_SID, null);
	var done = function () {
		poll._reset();
		if (viewEl) viewEl.innerHTML = '';
		showLogin('Вы вышли из панели.', 'info');
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

	if (/[?&]logout=1/.test(location.search)) {
		var s = sid;
		sid = null;
		sset(K_SID, null);
		try { history.replaceState(null, '', '/' + location.hash); } catch (e) {}
		if (s) ubus('session', 'destroy', {}, s).catch(function () {});
		showLogin('Вы вышли из панели. Войдите снова.', 'info');
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

* { scrollbar-width: thin; scrollbar-color: var(--border-2) transparent; }
::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-thumb { background: var(--border-2); border-radius: 10px; border: 2px solid transparent; background-clip: content-box; }
::-webkit-scrollbar-track { background: transparent; }

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
	padding: 6px 12px; border-radius: 12px;
	text-decoration: none; color: var(--text-2);
	font-weight: 550; font-size: 14px;
	transition: background .15s, color .15s;
}
.zmw-nav-item:hover { background: var(--surface-2); color: var(--text); }
.zmw-nav-ico {
	width: 30px; height: 30px; border-radius: 10px;
	display: grid; place-items: center; flex-shrink: 0;
	background: var(--surface-2); border: 1px solid var(--border);
	color: var(--muted);
	transition: background .2s, color .2s, border-color .2s, box-shadow .2s;
}
.zmw-nav-ico .zmw-i { width: 18px; height: 18px; }
.zmw-nav-label { flex: 1; min-width: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.zmw-nav-item.zmw-active { background: var(--grad-soft); color: var(--text); }
.zmw-nav-item.zmw-active::before {
	content: ""; position: absolute; left: -14px; top: 10px; bottom: 10px; width: 4px;
	border-radius: 0 4px 4px 0; background: var(--grad);
}
.zmw-nav-item.zmw-active .zmw-nav-ico {
	background: var(--grad); color: #fff; border-color: transparent;
	box-shadow: 0 6px 16px -6px rgba(99,102,241,.8);
}
.zmw-nav-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; display: none; }
.zmw-nav-dot.zmw-on, .zmw-nav-dot.zmw-stop { display: block; }
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
.zmw-device { padding: 2px 6px; }
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
	box-shadow: 0 8px 20px -10px rgba(99,102,241,.9), inset 0 1px 0 rgba(255,255,255,.22);
	transition: background-position .35s, transform .1s, box-shadow .2s;
}
.zmw-link-kvn:hover { color: #fff; border-color: transparent; background: var(--grad); background-size: 160% 100%; background-position: 100% 0; box-shadow: 0 10px 24px -10px rgba(99,102,241,1), inset 0 1px 0 rgba(255,255,255,.22); }
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
	padding: 44px 20px 18px;
	font: 13px/1.75 var(--mono);
	box-shadow: inset 0 1px 0 rgba(255,255,255,.04), var(--shadow);
	position: relative;
	background-image:
		radial-gradient(circle at 20px 20px, #ff5f57 5px, transparent 5.5px),
		radial-gradient(circle at 38px 20px, #febc2e 5px, transparent 5.5px),
		radial-gradient(circle at 56px 20px, #28c840 5px, transparent 5.5px),
		linear-gradient(to bottom, rgba(255,255,255,.035) 0, rgba(255,255,255,.035) 40px, transparent 40px);
	background-repeat: no-repeat;
}
#zmw-view .zm-log.bt-panel { padding-top: 16px; background-image: none; }
#zmw-view .zm-log:empty::before { color: #8b949e; }
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
#zmw-view .bt-current-cmd { background: var(--console); color: #86efac; border-radius: 12px; font-family: var(--mono); }

/* Telegram */
#zmw-view .zm-tg-link-card { background: var(--ok-bg); border: 1px solid rgba(16,185,129,.28); border-radius: 16px; }
#zmw-view .zm-tg-link-box { background: var(--console); color: #86efac; border-radius: 12px; font-family: var(--mono); font-size: 13.5px; }
#zmw-view .zm-tg-qr-box img { border-radius: 14px; box-shadow: var(--shadow); }

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
	top: auto; bottom: 24px; right: 24px; left: auto;
	gap: 10px; max-width: 420px; width: calc(100% - 48px);
	align-items: flex-end;
	z-index: 400;
	pointer-events: none;
}
.zmw-body .zm-toast {
	pointer-events: auto;
	align-items: center; gap: 12px;
	width: 100%;
	padding: 14px 16px 14px 14px;
	border-radius: 16px;
	border: 1px solid var(--border-2); border-left: 1px solid var(--border-2);
	background: var(--surface-solid);
	color: var(--text);
	box-shadow: var(--shadow-lg);
	font-size: 14px; font-weight: 550; line-height: 1.45;
	opacity: 0; transform: translateY(16px) scale(.98);
	transition: opacity .25s ease, transform .3s cubic-bezier(.2,.8,.2,1);
}
.zmw-body .zm-toast.zm-toast-show { opacity: 1; transform: none; }
.zmw-body .zm-toast-icon {
	width: 30px; height: 30px; border-radius: 10px;
	display: grid; place-items: center; flex-shrink: 0;
	font-size: 14px; font-weight: 800; line-height: 1;
}
.zmw-body .zm-toast-info .zm-toast-icon { background: var(--ok-bg); color: var(--ok); }
.zmw-body .zm-toast-error .zm-toast-icon { background: var(--bad-bg); color: var(--bad); }
.zmw-body .zm-toast-warning .zm-toast-icon { background: var(--warn-bg); color: var(--warn); }

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
	#zmw-view .zm-log { font-size: 12.5px; padding: 40px 14px 14px; }
}

@media (prefers-reduced-motion: reduce) {
	*, *::before, *::after { animation-duration: .01ms !important; animation-iteration-count: 1 !important; transition-duration: .01ms !important; }
}
ZM_INSTALLER_EOF
cat > '/www/zm-webui.html' << 'ZM_INSTALLER_EOF'
<!doctype html>
<html lang="ru" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#0a0c12">
<meta name="robots" content="noindex, nofollow">
<title>Zapret Manager</title>
<link rel="icon" href="data:image/svg+xml,%3Csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%201254%201254%27%3E%3Cdefs%3E%3ClinearGradient%20id=%27b%27%20x1=%270%27%20y1=%270%27%20x2=%270%27%20y2=%271%27%3E%3Cstop%20offset=%270%27%20stop-color=%27%2315264a%27/%3E%3Cstop%20offset=%271%27%20stop-color=%27%23060c18%27/%3E%3C/linearGradient%3E%3ClinearGradient%20id=%27z%27%20x1=%270%27%20y1=%270%27%20x2=%27.35%27%20y2=%271%27%3E%3Cstop%20offset=%270%27%20stop-color=%27%235fd8ff%27/%3E%3Cstop%20offset=%27.5%27%20stop-color=%27%231aa3ff%27/%3E%3Cstop%20offset=%271%27%20stop-color=%27%230a7cff%27/%3E%3C/linearGradient%3E%3C/defs%3E%3Crect%20width=%271254%27%20height=%271254%27%20rx=%27280%27%20fill=%27url%28%23b%29%27/%3E%3Cg%20transform=%27translate%2890%2090%29%20scale%28.856%29%27%20fill=%27url%28%23z%29%27%20stroke=%27%2304101f%27%20stroke-width=%2726%27%20stroke-linejoin=%27miter%27%3E%3Cpath%20d=%27M455%20170L1072%20118L1240%2018L685%20615L30%201240L742%20335L258%20385Z%27/%3E%3Cpath%20d=%27M1030%20458L722%20862L1222%20797L1008%201022L310%201100Z%27/%3E%3C/g%3E%3C/svg%3E">
<link rel="apple-touch-icon" href="data:image/svg+xml,%3Csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%201254%201254%27%3E%3Cdefs%3E%3ClinearGradient%20id=%27b%27%20x1=%270%27%20y1=%270%27%20x2=%270%27%20y2=%271%27%3E%3Cstop%20offset=%270%27%20stop-color=%27%2315264a%27/%3E%3Cstop%20offset=%271%27%20stop-color=%27%23060c18%27/%3E%3C/linearGradient%3E%3ClinearGradient%20id=%27z%27%20x1=%270%27%20y1=%270%27%20x2=%27.35%27%20y2=%271%27%3E%3Cstop%20offset=%270%27%20stop-color=%27%235fd8ff%27/%3E%3Cstop%20offset=%27.5%27%20stop-color=%27%231aa3ff%27/%3E%3Cstop%20offset=%271%27%20stop-color=%27%230a7cff%27/%3E%3C/linearGradient%3E%3C/defs%3E%3Crect%20width=%271254%27%20height=%271254%27%20rx=%27280%27%20fill=%27url%28%23b%29%27/%3E%3Cg%20transform=%27translate%2890%2090%29%20scale%28.856%29%27%20fill=%27url%28%23z%29%27%20stroke=%27%2304101f%27%20stroke-width=%2726%27%20stroke-linejoin=%27miter%27%3E%3Cpath%20d=%27M455%20170L1072%20118L1240%2018L685%20615L30%201240L742%20335L258%20385Z%27/%3E%3Cpath%20d=%27M1030%20458L722%20862L1222%20797L1008%201022L310%201100Z%27/%3E%3C/g%3E%3C/svg%3E">
<link rel="stylesheet" href="/zm/app.css?v=__ZMW_BUILD__">
<script>
(function(){try{var t=localStorage.getItem('zmw.theme')||sessionStorage.getItem('zmw.theme');if(t!=='light'&&t!=='dark')t=(window.matchMedia&&!matchMedia('(prefers-color-scheme: dark)').matches)?'light':'dark';document.documentElement.setAttribute('data-theme',t);if(t==='dark')document.documentElement.classList.add('zm-theme-dark');}catch(e){}})();
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

ZMW_RESTART=0
# JSON-RPC /ubus для uhttpd — обычно уже стоит вместе с LuCI
if [ ! -e /usr/lib/uhttpd_ubus.so ]; then
	echo -e "${CYAN}Устанавливаем ${NC}uhttpd-mod-ubus${CYAN} для Web UI${NC}"
	$INSTALL uhttpd-mod-ubus >/dev/null 2>&1 || { $PM update >/dev/null 2>&1; $INSTALL uhttpd-mod-ubus >/dev/null 2>&1; } || true
	ZMW_RESTART=1
fi

# Отдельный экземпляр uhttpd. Если секция уже есть — не трогаем (порт мог быть изменён вручную)
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
ZMW_IP="$(uci -q get network.lan.ipaddr | cut -d/ -f1)"
[ -n "$ZMW_IP" ] || ZMW_IP="192.168.1.1"

echo -e "Zapret Manager ${GREEN}для ${NC}LuCI ${GREEN}установлен!${NC}"
echo -e "\n${CYAN}Web UI: ${NC}http://${ZMW_IP}:${ZMW_PORT:-7788}/${NC}\n"

