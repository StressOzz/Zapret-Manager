#!/bin/sh
# Zapret Manager by StressOzz for LuCI installer
# Version: 1.14
set -e

GREEN="\033[1;32m"; CYAN="\033[1;36m"; YELLOW="\033[1;33m"; MAGENTA="\033[1;35m"; BLUE="\033[0;34m"; NC="\033[0m"; DGRAY="\033[38;5;244m"

echo -e "\n${MAGENTA}Устанавливаем Zapret Manager для LuCI${NC}"

rm -rf \
	/usr/lib/zapret-manager* \
	/usr/libexec/rpcd/zapret-manager* \
	/usr/share/luci/menu.d/luci-app-zapret-manager.json \
	/usr/share/rpcd/acl.d/luci-app-zapret-manager.json \
	/www/luci-static/resources/view/zapret-manager* \
	/www/luci-static/resources/zapret-manager* \
	/etc/zapret_manager_expert_mode* \
	/tmp/zapret-manager* \
	/tmp/zm_uninstall_panel.sh \
	/tmp/luci-indexcache* \
	/tmp/luci-modulecache/* 2>/dev/null
/etc/init.d/rpcd restart >/dev/null 2>&1
/etc/init.d/uhttpd restart >/dev/null 2>&1

mkdir -p /usr/lib/zapret-manager
cat > '/usr/lib/zapret-manager/backend.sh' << 'ZM_INSTALLER_EOF'

CONF="/etc/config/zapret"
ZM_VERSION="1.14"
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
JOBS_DIR="/tmp/zapret-manager"
CRON_FILE="/etc/crontabs/root"
MIHOMO_DIR="/etc/mihomo"
MIHOMO_BIN="/usr/bin/mihomo"
MIHOMO_CONF="/etc/mihomo/config.yaml"
MAGITRICKLE_CONF="/etc/magitrickle/state/config.yaml"
MIXOMO_CRON_CMD="/etc/init.d/mihomo restart"
HOSTS_FILE="/etc/hosts"
EXPERT_MODE_FILE="/etc/zapret_manager_expert_mode"
PORTS_UDP="88,1024-2407,2409-4499,4502-19293,19345-49999,50101-65535"
PORTS_TCP="2802,2302,2502,3478-3480,3724,6000-8000,8085,8090,8100,8903,8904,25565,27015-27030,27036-27037,35500-35600,50001,60442"
mkdir -p "$JOBS_DIR"

if command -v opkg >/dev/null 2>&1; then
	PKG="opkg"; INSTALL="opkg install"; DELETE="opkg remove"; UPDATE="opkg update"
	TG_ARCH="$(opkg print-architecture 2>/dev/null | awk '{print $2}' | tail -n1)"
	RAZ="ipk"
else
	PKG="apk"; INSTALL="apk add --allow-untrusted"; DELETE="apk del"; UPDATE="apk update"
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
		wget -q -U "Mozilla/5.0" -O zapret.zip "$url" >/dev/null 2>&1
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
	wget -q -U "Mozilla/5.0" -O /opt/zapret/ipset/zapret-hosts-user-exclude.txt "$EXCLUDE_URL"

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
	for b in ai instagram ntc librusec telegram twitch scell spotify; do
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
	wget -q -U "Mozilla/5.0" -O /opt/zapret2/ipset/zapret_hosts_user_exclude.txt "$EXCLUDE_URL"

	echo "==> Настраиваем стратегии"
	mkdir -p /opt/zapret2/init.d/openwrt/custom.d
	wget -q -U "Mozilla/5.0" -O /opt/zapret2/init.d/openwrt/custom.d/50-discord_media.sh \
		"${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/Zapret2/50-discord_media.sh" \
		|| echo "!! Не удалось загрузить 50-discord_media.sh"
	wget -q -U "Mozilla/5.0" -O /etc/config/zapret2 \
		"${GH_RAW}/StressOzz/Zapret-Manager/refs/heads/main/files/Zapret2/zapret2" \
		|| echo "!! Не удалось загрузить zapret2"
	wget -q -U "Mozilla/5.0" -O /opt/zapret2/ipset/zapret_hosts_discord.txt \
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
	wget -q -U "Mozilla/5.0" -O /opt/zapret/ipset/zapret-hosts-user-exclude.txt "$EXCLUDE_URL"
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
			wget -q -U "Mozilla/5.0" -O "/opt/zapret/files/fake/$f" "${FLOWSEAL_FAKE_RAW}/$f" \
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
		wget -q -U "Mozilla/5.0" -O "$zip" "$FLOWSEAL_ZIP" >/dev/null 2>&1
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
		spotifyext) printf '%s\n' \
			"#SpotifyEXT" \
			"45.155.204.190 spotify.com www.spotify.com accounts.spotify.com login.spotify.com login5.spotify.com login.app.spotify.com auth.spotify.com account.spotify.com api.spotify.com api-partner.spotify.com spclient.wg.spotify.com gew1-spclient.spotify.com" \
			"45.155.204.190 guc3-spclient.spotify.com gae2-spclient.spotify.com gue1-spclient.spotify.com gnl-spclient.spotify.com spclient.spotify.com ap-gew1.spotify.com ap-gue1.spotify.com ap-gae2.spotify.com ap-gew4.spotify.com ap-sto3.spotify.com" \
			"45.155.204.190 ap-guc3.spotify.com ap.spotify.com apresolve.spotify.com aet.spotify.com gew1-dealer.g2.spotify.com guc3-dealer.g2.spotify.com gue1-dealer.g2.spotify.com dealer.spotify.com dealer-wg.spotify.com edge-web.dual-gslb.spotify.com" \
			"45.155.204.190 client.spotify.com web-partner.spotify.com connect.spotify.com gce.spotify.com clienttoken.spotify.com exp.wg.spotify.com pixel.spotify.com pixel-static.spotify.com image-upload.spotify.com content.spotify.com analytics.spotify.com" \
			"45.155.204.190 crashdump.spotify.com log.spotify.com logger.spotify.com metrics.spotify.com desktop.spotify.com audio-fa-tls13.spotifycdn.com heads-fa-tls13.spotifycdn.com heads4-fa-tls13.spotifycdn.com image-cdn-fa.spotifycdn.com" \
			"45.155.204.190 concerts.spotifycdn.com mrkt.spotifycdn.com pickasso.spotifycdn.com podz-content.spotifycdn.com seed-mix-image.spotifycdn.com thisis-images.spotifycdn.com wap.spotifycdn.com web-sdk-assets.spotifycdn.com spotifycdn.com spotifycdn.net" \
			"35.186.224.24 open.spotify.com" \
			"162.159.141.124 audio4-fa-tls13.spotifycdn.com audio-cf.spotifycdn.com open-exp.spotifycdn.com" \
			"23.36.163.34 audio-ak-spotify-com.akamaized.net" \
			"2.16.168.44 audio4-ak-spotify-com.akamaized.net" \
			"199.232.210.248 scdn.co i.scdn.co line-up.scdn.co mosaic.scdn.co daily-mix.scdn.co lineup-images.scdn.co encore.scdn.co image-cdn-fa.scdn.co accounts.scdn.co www.scdn.co www-growth.scdn.co av.scdn.co seafoam.scdn.co" \
			"23.48.23.145 heads-ak-spotify-com.akamaized.net" \
			"45.155.204.190 xpui.app.spotify.com" ;;
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
	local blocks="nalog ntc instagram librusec ai twitch telegram spotify spotifyext scell githubraw github tapeop roblox" b first=1
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
	wget -q -U "Mozilla/5.0" -O "$tmp" "$url" >/dev/null 2>&1
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
rm -rf /usr/lib/zapret-manager /usr/libexec/rpcd/zapret-manager \
	/usr/share/luci/menu.d/luci-app-zapret-manager.json \
	/usr/share/rpcd/acl.d/luci-app-zapret-manager.json \
	/www/luci-static/resources/view/zapret-manager \
	/www/luci-static/resources/zapret-manager \
	/tmp/zapret-manager /tmp/luci-indexcache* /tmp/luci-modulecache/* 2>/dev/null
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
	wget -q -O "$tmp" "$url" || { echo "ОШИБКА скачивания $url"; return 1; }
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
		wget -q -O "$tmp" "$TGWS_BASE_URL/$file" >/dev/null 2>&1
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
				v|flowseal|v_flowseal|youtube) ;;
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
				v|flowseal|v_flowseal|youtube) rm -f "$(_test_results_file "$mode")" ;;
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
	printf '{"running":%s,"mode":"%s","has_results_v":%s,"has_results_flowseal":%s,"has_results_v_flowseal":%s,"has_results_youtube":%s}\n' \
		"$running" "$(esc "$mode")" \
		"$([ -s "$(_test_results_file v)" ] && echo true || echo false)" \
		"$([ -s "$(_test_results_file flowseal)" ] && echo true || echo false)" \
		"$([ -s "$(_test_results_file v_flowseal)" ] && echo true || echo false)" \
		"$([ -s "$(_test_results_file youtube)" ] && echo true || echo false)"
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
	echo "==> Скачиваем и устанавливаем новую версию панели"
	local tmp="/tmp/zm_update_install.sh"
	rm -f "$tmp"
	wget -q -U "Mozilla/5.0" -O "$tmp" "$ZM_SCRIPT_URL" || { echo "ОШИБКА: не удалось скачать установщик"; rm -f "$tmp"; return 1; }
	[ -s "$tmp" ] || { echo "ОШИБКА: скачался пустой файл"; rm -f "$tmp"; return 1; }
	head -c 200 "$tmp" | grep -q '^#!/bin/sh' || { echo "ОШИБКА: скачанный файл не похож на установщик"; rm -f "$tmp"; return 1; }
	sh "$tmp"
	rm -f "$tmp"
	echo "==> Готово"
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
	tag=$(curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/MetaCubeX/mihomo/releases/latest" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
	[ -n "$tag" ] || { echo "ОШИБКА: не удалось определить версию Mihomo"; return 1; }
	echo "==> Версия: $tag"

	local file url tmp
	file="mihomo-linux-${arch}-${tag}.gz"
	url="${GH_MAIN}/MetaCubeX/mihomo/releases/download/${tag}/${file}"
	tmp="/tmp/mihomo.gz"
	echo "==> Скачиваем $file"
	curl -Lf --retry 3 --retry-delay 2 "$url" -o "$tmp" >/dev/null 2>&1 || { echo "ОШИБКА: не удалось скачать $file"; return 1; }
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
	local arch_mt mt_ver_latest file_mt url_mt suf
	arch_mt=$(grep '^OPENWRT_ARCH=' /etc/os-release 2>/dev/null | cut -d'"' -f2)
	suf=""
	[ "$PKG" = "apk" ] && suf="r"
	mt_ver_latest=$(curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/MagiTrickle/MagiTrickle/releases/latest" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
	if [ -n "$mt_ver_latest" ] && [ -n "$arch_mt" ]; then
		file_mt="magitrickle_${mt_ver_latest}-${suf}1_openwrt_${arch_mt}.${RAZ}"
		url_mt="${GH_MAIN}/MagiTrickle/MagiTrickle/releases/download/${mt_ver_latest}/${file_mt}"
		tmp="/tmp/$file_mt"
		echo "==> Скачиваем $file_mt"
		if curl -Lf --retry 3 --retry-delay 2 -o "$tmp" "$url_mt" >/dev/null 2>&1; then
			$INSTALL "$tmp" >/dev/null 2>&1 || echo "!! Не удалось установить MagiTrickle"
			rm -f "$tmp"
		else
			echo "!! Не удалось скачать MagiTrickle"
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
	$DELETE hev-socks5-tunnel >/dev/null 2>&1
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
		if awk -v url="$sub_url" 'BEGIN { updated = 0 } { if ($0 ~ /^[[:space:]]*type:[[:space:]]*http[[:space:]]*$/) { print; getline; if ($0 ~ /^[[:space:]]*url:[[:space:]]*"/) { sub(/url:[[:space:]]*".*"/, "url: \"" url "\""); updated = 1 } print; next } print } END { exit (updated ? 0 : 1) }' "$MIHOMO_CONF" > "$tmp"
		then
			mv "$tmp" "$MIHOMO_CONF"
			/etc/init.d/mihomo restart >/dev/null 2>&1
			printf '{"ok":true,"mode":"updated"}\n'
			return 0
		fi
		rm -f "$tmp"
	fi

	printf '%s\n' \
		'mode: rule' 'ipv6: false' 'mixed-port: 7890' 'log-level: error' 'allow-lan: false' \
		'unified-delay: true' 'tcp-concurrent: false' 'find-process-mode: off' \
		'external-controller: 0.0.0.0:9090' 'external-ui: ./ui' 'routing-mark: 2' \
		'profile:' '  store-selected: true' '  store-fake-ip: true' '  tracing: true' \
		'sniffer:' '  enable: true' '  force-dns-mapping: true' '  parse-pure-ip: true' \
		'  sniff:' '    HTTP:' '      ports: [80]' '      override-destination: true' \
		'    TLS:' '      ports: [443, 8443]' '    QUIC:' '      ports: [443, 8443]' \
		'  skip-domain:' '    - Mijia Cloud' '    - +.lan' '    - +.local' \
		'    - +.msftconnecttest.com' '    - +.msftncsi.com' '    - +.3gppnetwork.org' \
		'    - +.openwrt.org' '    - +.vsean.net' '    - cudy.net' '' \
		'hosts:' '  ntc.party: 130.255.77.28' '' \
		'proxies:' '' '  - name: "Домашний интернет"' '    type: direct' '' \
		'proxy-providers:' '' '  Подписка:' '    type: http' "    url: \"$sub_url\"" \
		'    path: ./proxy-providers/sub.yaml' '    interval: 86400' '    health-check:' \
		'      enable: true' '      url: http://www.gstatic.com/generate_204' \
		'      interval: 300' '      timeout: 5000' '      lazy: true' '' \
		'proxy-groups:' '' '  - name: "Сервер для YouTube"' '    type: select' \
		'    icon: https://www.clashverge.dev/assets/icons/youtube.svg' '    proxies:' \
		'      - "Домашний интернет"' '    use:' '      - "Подписка"' '' \
		'  - name: "Сервер для остального трафика"' '    type: select' \
		'    icon: https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.3/assets/svg/1f310.svg' \
		'    use:' '      - "Подписка"' '' \
		'rule-providers:' '' '  youtube:' '    type: http' '    format: yaml' \
		'    behavior: classical' \
		'    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"' \
		'    path: ./rule-providers/youtube-list.yaml' '    interval: 86400' '' \
		'rules:' '  - RULE-SET,youtube,Сервер для YouTube' '  - MATCH,Сервер для остального трафика' \
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
	wget -q -O "$MAGITRICKLE_CONF" "$url" || { echo '{"error":"не удалось скачать список"}'; return 1; }
	[ -s "$MAGITRICKLE_CONF" ] || { echo '{"error":"скачанный файл пуст"}'; return 1; }
	/etc/init.d/magitrickle enable >/dev/null 2>&1
	/etc/init.d/magitrickle restart >/dev/null 2>&1
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
		print "      - REJECT" >> OUT
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
	/etc/init.d/mihomo reload >/dev/null 2>&1
	/etc/init.d/mihomo restart >/dev/null 2>&1
	echo "==> Готово, WARP интегрирован в Mihomo"
}

mixomo_warp_integrate_action() {
	job_start mixomo_warp_integrate do_mixomo_warp_integrate
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
	tg_status)                                                   tg_status ;;
	tg_action)                                                    tg_action "$1" "$2" ;;
	tg_restart_all)                                                tg_restart_all ;;
	tgws_status)                                                    tgws_status ;;
	tgws_action)                                                     tgws_action "$1" ;;
	hosts_status)                      hosts_status ;;
	hosts_toggle)                       hosts_toggle "$1" ;;
	hosts_replace_geohide)              hosts_replace_geohide "$1" ;;
	hosts_reset)                        hosts_reset ;;
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
	*) echo '{"error":"неизвестная команда"}'; exit 1 ;;
esac
ZM_INSTALLER_EOF
chmod 0755 '/usr/lib/zapret-manager/backend.sh'

mkdir -p /usr/libexec/rpcd
cat > '/usr/libexec/rpcd/zapret-manager' << 'ZM_INSTALLER_EOF'
#!/bin/sh

. /usr/share/libubox/jshn.sh

BACKEND="/usr/lib/zapret-manager/backend.sh"

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
	json_add_object "tg_status";                   json_close_object
	json_add_object "tg_action";                   json_add_string "variant" "string"; json_add_string "action" "string"; json_close_object
	json_add_object "tg_restart_all";              json_close_object
	json_add_object "tgws_status";                 json_close_object
	json_add_object "tgws_action";                 json_add_string "action" "string"; json_close_object
	json_add_object "hosts_status";           json_close_object
	json_add_object "hosts_toggle";           json_add_string "block" "string"; json_close_object
	json_add_object "hosts_replace_geohide";  json_add_string "region" "string"; json_close_object
	json_add_object "hosts_reset";            json_close_object
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
		tg_status)                     "$BACKEND" tg_status ;;
		tg_action)                     json_get_var variant variant; json_get_var action action; "$BACKEND" tg_action "$variant" "$action" ;;
		tg_restart_all)                "$BACKEND" tg_restart_all ;;
		tgws_status)                   "$BACKEND" tgws_status ;;
		tgws_action)                   json_get_var action action;   "$BACKEND" tgws_action "$action" ;;
		hosts_status)            "$BACKEND" hosts_status ;;
		hosts_toggle)            json_get_var block block;     "$BACKEND" hosts_toggle "$block" ;;
		hosts_replace_geohide)   json_get_var region region;   "$BACKEND" hosts_replace_geohide "$region" ;;
		hosts_reset)             "$BACKEND" hosts_reset ;;
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
cat > '/usr/share/rpcd/acl.d/luci-app-zapret-manager.json' << 'ZM_INSTALLER_EOF'
{
	"luci-app-zapret-manager": {
		"description": "Grant access to the Zapret Manager backend",
		"read": {
			"ubus": {
				"zapret-manager": [
					"status", "job_status", "log_tail", "system_info",
					"strategy_list_v", "strategy_list_flowseal", "strategy_list_youtube",
					"discord_status", "hosts_status", "doh_status", "game_status",
					"system_status", "mirror_status", "exclusions_status", "tg_status", "tgws_status",
					"test_status", "test_results", "zm_update_status", "mixomo_status", "mixomo_config_get",
					"mixomo_warp_status",
					"zapret_latest_version"
				]
			}
		},
		"write": {
			"ubus": {
				"zapret-manager": [
					"zapret_action", "zapret2_action",
					"strategy_set_v", "strategy_set_flowseal", "strategy_set_youtube",
					"discord_set_dv", "discord_set_fake",
					"hosts_toggle", "doh_set", "hosts_replace_geohide", "hosts_reset", "doh_install", "doh_remove",
					"game_set", "game_set_fake", "game_toggle_xtreme",
					"system_check_connectivity", "system_toggle_quic", "system_toggle_ipv6",
					"system_toggle_flow_offloading_fix", "system_toggle_expert_mode", "system_uninstall_panel",
					"mirror_set", "exclusions_toggle", "exclusions_clear",
					"tg_action", "tg_restart_all", "tgws_action", "test_action", "zm_update_action",
					"mixomo_action", "mixomo_config_set", "mixomo_subscription_set",
					"mixomo_magitrickle_list_set", "mixomo_autorestart_set", "mixomo_ui_action",
					"mixomo_warp_action", "mixomo_warp_integrate_action"
				]
			}
		}
	}
}
ZM_INSTALLER_EOF

mkdir -p /usr/share/luci/menu.d
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
		"title": "Стратегии",
		"order": 20,
		"action": { "type": "view", "path": "zapret-manager/strategy" }
	},
	"admin/services/zapret-manager/test": {
		"title": "Тест стратегий",
		"order": 22,
		"action": { "type": "view", "path": "zapret-manager/test" }
	},
	"admin/services/zapret-manager/youtube": {
		"title": "YouTube",
		"order": 25,
		"action": { "type": "view", "path": "zapret-manager/youtube" }
	},
	"admin/services/zapret-manager/game": {
		"title": "Игры",
		"order": 27,
		"action": { "type": "view", "path": "zapret-manager/game" }
	},
	"admin/services/zapret-manager/discord": {
		"title": "Discord",
		"order": 30,
		"action": { "type": "view", "path": "zapret-manager/discord" }
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
	"admin/services/zapret-manager/system": {
		"title": "Система",
		"order": 60,
		"action": { "type": "view", "path": "zapret-manager/system" }
	},
	"admin/services/zapret-manager/exclusions": {
		"title": "Исключение устройств",
		"order": 70,
		"action": { "type": "view", "path": "zapret-manager/exclusions" }
	},
	"admin/services/zapret-manager/mixomo": {
		"title": "Mixomo",
		"order": 57,
		"action": { "type": "view", "path": "zapret-manager/mixomo" }
	}
}
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/zapret-manager
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
var callTgStatus = rpc.declare({ object: 'zapret-manager', method: 'tg_status', expect: {} });
var callTgAction = rpc.declare({ object: 'zapret-manager', method: 'tg_action', params: ['variant', 'action'], expect: {} });
var callTgRestartAll = rpc.declare({ object: 'zapret-manager', method: 'tg_restart_all', expect: {} });
var callTgwsStatus = rpc.declare({ object: 'zapret-manager', method: 'tgws_status', expect: {} });
var callTgwsAction = rpc.declare({ object: 'zapret-manager', method: 'tgws_action', params: ['action'], expect: {} });
var callHostsStatus = rpc.declare({ object: 'zapret-manager', method: 'hosts_status', expect: {} });
var callHostsToggle = rpc.declare({ object: 'zapret-manager', method: 'hosts_toggle', params: ['block'], expect: {} });
var callHostsReplaceGeohide = rpc.declare({ object: 'zapret-manager', method: 'hosts_replace_geohide', params: ['region'], expect: {} });
var callHostsReset = rpc.declare({ object: 'zapret-manager', method: 'hosts_reset', expect: {} });
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
	var cls = ok ? 'zm-ok' : 'zm-bad';
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
				toast('Роутер не отвечает — операция может ещё выполняться в фоне. Обновите страницу через полминуты, чтобы проверить результат.', 'warning', 25000);
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
	tgStatus: callTgStatus,
	tgAction: callTgAction,
	tgRestartAll: callTgRestartAll,
	tgwsStatus: callTgwsStatus,
	tgwsAction: callTgwsAction,
	hostsStatus: callHostsStatus,
	hostsToggle: callHostsToggle,
	hostsReplaceGeohide: callHostsReplaceGeohide,
	hostsReset: callHostsReset,
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
	mixomoWarpIntegrateAction: callMixomoWarpIntegrateAction
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
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
			zm.zapretLatestVersion().catch(function() { return {}; }),
			zm.systemInfo().catch(function() { return {}; }),
			zm.zmUpdateStatus().catch(function() { return {}; }),
			zm.mixomoStatus().catch(function() { return {}; })
		]);
	},

	render: function(all) {
		var view = this;
		var data = all[0], dohData = all[1], hostsData = all[2], sysData = all[3];
		var latestVersion = (all[4] && all[4].version) || '';
		var sysInfo = all[5] || {};
		var zmUpdate = all[6] || {};
		var mixomoData = all[7] || {};
		var wrap = E('div', { 'class': 'zm-wrap' });
		var overviewEl = E('div', {});
		var cards = E('div', { 'class': 'zm-cards' });
		var logEl = E('pre', { 'class': 'zm-log' });

		var DOH_LABELS = { cloudflare: 'Cloudflare', google: 'Google', quad9: 'Quad9', xbox: 'XBOX', geohide_ru: 'GeoHide RU', geohide_eu: 'GeoHide EU', geohide_us: 'GeoHide US' };

		function renderOverview(d, doh, hosts, sys, mixomo) {
			var hostsEnabled = (hosts.items || []).filter(function(it) { return it.enabled; }).length;
			var hostsTotal = (hosts.items || []).length;

			var sysFlags = [];
			if (sys.quic_blocked) sysFlags.push('QUIC заблокирован');
			if (sys.ipv6_enabled) sysFlags.push('IPv6 в Zapret включён');
			if (sys.flow_offloading_fix) sysFlags.push('Flow Offloading fix');

			var mixomoRunning = mixomo.mihomo_running === true && mixomo.hev_running === true && mixomo.magitrickle_running === true;

			return E('div', { 'class': 'zm-card', 'style': 'margin-bottom:4px' }, [
				E('h3', {}, 'Обзор'),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Zapret Manager LuCI'),
					E('span', {}, 'v' + (zmUpdate.current || '?'))
				]),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Zapret'),
					d.zapret === 'installed'
						? zm.badge(d.zapret_running === true, 'запущен', 'остановлен')
						: zm.badge(false, '', 'не установлен')
				]),
				d.zapret2 === 'installed' ? E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Zapret2'),
					zm.badge(d.zapret2_running === true, 'запущен', 'остановлен')
				]) : E([]),
				mixomo.mihomo === 'installed' ? E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Mixomo'),
					zm.badge(mixomoRunning, 'запущен', 'остановлен')
				]) : E([]),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'DNS over HTTPS'),
					doh.installed
						? zm.badge(true, DOH_LABELS[doh.current] || doh.current || 'установлен, провайдер не определён', '')
						: zm.badge(false, '', 'не установлен')
				]),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Домены в hosts'),
					hosts.geohide
						? zm.badge(true, 'GeoHide ' + hosts.geohide.toUpperCase(), '')
						: hostsTotal
							? zm.badge(hostsEnabled > 0, hostsEnabled + ' из ' + hostsTotal + ' включено', 'ничего не включено')
							: E('span', {}, '—')
				]),
				sysFlags.length ? E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Система'),
					E('span', { 'style': 'overflow-wrap:anywhere' }, sysFlags.join(', '))
				]) : E([])
			]);
		}

		function renderCards(d) {
			cards.innerHTML = '';

			var zActions = [];
			if (d.zapret === 'installed') {
				zActions.push(E('button', {
					'class': 'cbi-button cbi-button-remove',
					'click': ui.createHandlerFn(view, 'doAction', 'remove')
				}, 'Удалить'));
				if (/^[0-9]+\.[0-9]+$/.test(latestVersion) && d.zapret_version && latestVersion !== d.zapret_version) {
					zActions.push(E('button', {
						'class': 'cbi-button',
						'click': ui.createHandlerFn(view, 'doAction', 'update')
					}, 'Обновить до ' + latestVersion));
				}
				zActions.push(E('button', {
					'class': 'cbi-button',
					'click': ui.createHandlerFn(view, 'doAction', d.zapret_running ? 'stop' : 'start')
				}, d.zapret_running ? 'Остановить' : 'Запустить'));
			} else {
				zActions.push(E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': ui.createHandlerFn(view, 'doAction', 'install')
				}, 'Установить и настроить'));
			}

			var zCard = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Zapret'),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Статус'),
					d.zapret === 'installed'
						? zm.badge(d.zapret_running === true, 'запущен', 'остановлен')
						: zm.badge(false, '', 'не установлен')
				]),
				d.zapret_version ? E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Версия'), E('span', {}, d.zapret_version)
				]) : E([]),
				d.strategy ? E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Стратегия'), E('span', {}, d.strategy)
				]) : E([]),
				E('div', { 'class': 'zm-actions' }, zActions)
			]);

			var z2Actions = [];
			if (d.zapret2 === 'installed') {
				z2Actions.push(E('button', {
					'class': 'cbi-button cbi-button-remove',
					'click': ui.createHandlerFn(view, 'doAction2', 'remove')
				}, 'Удалить'));
				z2Actions.push(E('button', {
					'class': 'cbi-button',
					'click': ui.createHandlerFn(view, 'doAction2', d.zapret2_running ? 'stop' : 'start')
				}, d.zapret2_running ? 'Остановить' : 'Запустить'));
			} else {
				z2Actions.push(E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': ui.createHandlerFn(view, 'doAction2', 'install')
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

			var sysCard = E('div', { 'class': 'zm-card' }, [
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Модель:'), E('span', {}, sysInfo.model || '—')
				]),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Архитектура:'), E('span', {}, sysInfo.arch || '—')
				]),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'OpenWrt:'), E('span', {}, sysInfo.openwrt || '—')
				]),
				E('p', { 'class': 'zm-hint', 'style': 'margin-top:10px; margin-bottom:2px' }, 'Место на роутере:'),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, '/tmp'),
					E('span', {}, sysInfo.tmp_free ? ('занято ' + sysInfo.tmp_used + ' · свободно ' + sysInfo.tmp_free) : '—')
				]),
				E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, '/root'),
					E('span', {}, sysInfo.root_free ? ('занято ' + sysInfo.root_used + ' · свободно ' + sysInfo.root_free) : '—')
				])
			]);

			cards.appendChild(zCard);
			cards.appendChild(z2Card);
			cards.appendChild(sysCard);
		}

		function refreshOverview() {
			Promise.all([
				zm.status(),
				zm.dohStatus().catch(function() { return {}; }),
				zm.hostsStatus().catch(function() { return { items: [] }; }),
				zm.systemStatus().catch(function() { return {}; }),
				zm.mixomoStatus().catch(function() { return {}; })
			]).then(function(res) {
				overviewEl.innerHTML = '';
				overviewEl.appendChild(renderOverview(res[0], res[1], res[2], res[3], res[4]));
			});
		}

		overviewEl.appendChild(renderOverview(data, dohData, hostsData, sysData, mixomoData));
		renderCards(data);
		var updateEl = E('div', {});
		wrap.appendChild(updateEl);
		wrap.appendChild(E('div', { 'class': 'zm-header' }, [
			E('h2', {}, 'Zapret Manager'),
			E('span', { 'class': 'zm-header-by' }, 'by StressOzz'),
			E('div', { 'class': 'zm-header-links' }, [
				E('a', { 'href': 'http://stresskvn.lol/', 'target': '_blank', 'rel': 'noreferrer' }, 'StressKVN — обход белых списков!'),
				E('a', { 'href': 'https://t.me/stressozz_manager', 'target': '_blank', 'rel': 'noreferrer' }, 'Сообщество Telegram')
			])
		]));
		wrap.appendChild(overviewEl);
		wrap.appendChild(cards);
		wrap.appendChild(logEl);
		var bannerEl = E('div', {});
		wrap.appendChild(bannerEl);

		this.logEl = logEl;
		this.bannerEl = bannerEl;
		this.renderCards = renderCards;
		this.refreshOverview = refreshOverview;

		var zmUpdateBusy = false;
		function waitForServerAndReload() {
			var attempts = 0;
			var maxAttempts = 30;
			var target = L.resource('view/zapret-manager/dashboard.js') + '?_zmcheck=' + Date.now();
			var timer = setInterval(function() {
				attempts++;
				fetch(target, { credentials: 'same-origin', cache: 'no-store' }).then(function(resp) {
					if (resp.ok) {
						clearInterval(timer);
						location.reload();
					} else if (attempts >= maxAttempts) {
						clearInterval(timer);
						zm.toast('Панель обновлена, но страница пока не отвечает — обновите вручную (F5)', 'warning', 15000);
					}
				}).catch(function() {
					if (attempts >= maxAttempts) {
						clearInterval(timer);
						zm.toast('Панель обновлена, но страница пока не отвечает — обновите вручную (F5)', 'warning', 15000);
					}
				});
			}, 700);
		}
		function renderZmUpdate() {
			updateEl.innerHTML = '';
			if (!zmUpdate.latest || zmUpdate.latest === zmUpdate.current) return;
			var log = E('pre', { 'class': 'zm-log' });
			updateEl.appendChild(E('div', { 'class': 'zm-refresh-banner zm-show' }, [
				E('span', {}, 'Доступна новая версия панели Zapret Manager: ' + zmUpdate.latest + ' (у вас установлена ' + zmUpdate.current + ').'),
				E('button', {
					'class': 'cbi-button cbi-button-positive',
					'click': function() {
						if (zmUpdateBusy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						zmUpdateBusy = true;
						log.classList.add('zm-show');
						zm.toast('Скачиваем и запускаем обновление панели', 'warning');
						zm.zmUpdateAction().then(function(res) {
							if (res.error) { zmUpdateBusy = false; zm.toast(res.error, 'error'); return; }
							zm.pollJob('zm_update', log, function(ok) {
								zmUpdateBusy = false;
								if (ok) {
									zm.toast('Обновление скачано, ждём перезапуска панели...', 'info', 15000);
									waitForServerAndReload();
								} else {
									zm.toast('Не удалось скачать обновление', 'error');
								}
							});
						}).catch(function() { zmUpdateBusy = false; });
					}
				}, 'Обновить панель')
			]));
			updateEl.appendChild(log);
		}
		renderZmUpdate();

		return wrap;
	},

	doAction: function(action) {
		var view = this;
		if (view.busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
		var job = (action === 'install' || action === 'update') ? 'install_zapret'
			: (action === 'remove') ? 'remove_zapret' : null;
		var LABELS = { install: 'Устанавливаем и настраиваем Zapret', update: 'Обновляем Zapret', remove: 'Удаляем Zapret', start: 'Запускаем Zapret', stop: 'Останавливаем Zapret' };
		zm.toast(LABELS[action] || 'Выполняем', 'warning');
		if (job) view.busy = true;

		zm.zapretAction(action).then(function(res) {
			if (job && res && res.started) {
				zm.pollJob(job, view.logEl, function(ok) {
					view.busy = false;
					zm.toast(ok ? 'Готово' : 'Операция завершилась с ошибкой', ok ? 'info' : 'error');
					zm.status().then(function(d) { view.renderCards(d); });
					view.refreshOverview();
					if (ok && (action === 'install' || action === 'remove')) {
						view.bannerEl.innerHTML = '';
						view.bannerEl.appendChild(zm.refreshBanner('Пункт меню Zapret в LuCI мог измениться — выйдите и зайдите заново.'));
					}
				});
			} else if (res) {
				view.busy = false;
				view.renderCards(res);
				view.refreshOverview();
			}
		}).catch(function() { view.busy = false; });
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
					view.refreshOverview();
					if (ok && (action === 'install' || action === 'remove')) {
						view.bannerEl.innerHTML = '';
						view.bannerEl.appendChild(zm.refreshBanner('Пункт меню Zapret2 в LuCI мог измениться — выйдите и зайдите заново.'));
					}
				});
			} else if (res) {
				view.busy2 = false;
				view.renderCards(res);
				view.refreshOverview();
			}
		}).catch(function() { view.busy2 = false; });
	}
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/discord.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var FAKES = [
	'stun.bin', 'stun2.bin', 'quic_initial_4pda_to.bin',
	'quic_initial_tencent_com.bin', 'tls_clienthello_sochi_park.bin',
	'quic_initial_www_google_com.bin', 'quic_initial_steamcommunity_com.bin',
	'quic_initial_5ka_ru.bin', 'quic_initial_rutube_ru.bin'
];

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.discordStatus();
	},

	render: function(data) {
		var wrap = E('div', { 'class': 'zm-wrap' });
		var dvGrid = E('div', { 'class': 'zm-grid' });
		var fakeGrid = E('div', { 'class': 'zm-grid' });
		var busy = false;

		function renderDv() {
			dvGrid.innerHTML = '';
			(data.available || []).forEach(function(dv) {
				var num = dv.replace('Dv', '');
				dvGrid.appendChild(E('div', {
					'class': 'zm-tile' + (data.current === dv ? ' zm-active' : ''),
					'click': function() {
						if (busy) { zm.toast('Дождитесь завершения текущей операции', 'warning'); return; }
						busy = true;
						zm.toast('Применяем стратегию ' + dv + '', 'warning');
						zm.discordSetDv(num).then(function(res) {
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
			FAKES.forEach(function(f) {
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

		wrap.appendChild(dvCard);
		wrap.appendChild(fakeCard);
		return wrap;
	}
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
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

mkdir -p /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/exclusions.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.exclusionsStatus();
	},

	render: function(data) {
		var wrap = E('div', { 'class': 'zm-wrap' });

		if (data.error) {
			wrap.appendChild(E('div', { 'class': 'zm-card' }, [
				E('h3', {}, 'Исключение устройств'),
				E('p', { 'class': 'zm-hint' }, data.error)
			]));
			return wrap;
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

		wrap.appendChild(card);
		return wrap;
	}
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/game.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var FAKES = [
	'stun.bin', 'stun2.bin', 'quic_initial_4pda_to.bin',
	'quic_initial_tencent_com.bin', 'tls_clienthello_sochi_park.bin',
	'quic_initial_www_google_com.bin', 'quic_initial_steamcommunity_com.bin',
	'quic_initial_5ka_ru.bin', 'quic_initial_rutube_ru.bin'
];

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.gameStatus();
	},

	render: function(data) {
		var wrap = E('div', { 'class': 'zm-wrap' });
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
			FAKES.forEach(function(f) {
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

		wrap.appendChild(gvCard);
		wrap.appendChild(xtremeCard);
		wrap.appendChild(fakeCard);
		return wrap;
	}
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/hosts.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var LABELS = {
	nalog: 'Налог.ру',
	ntc: 'ntc.party',
	instagram: 'Instagram & Facebook',
	librusec: 'lib.rus.ec',
	ai: 'AI сервисы (ChatGPT, Claude, Gemini)',
	twitch: 'Twitch',
	telegram: 'Telegram Web',
	spotify: 'Spotify',
	spotifyext: 'Spotify (расширенный)',
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

		var resetBtn = E('button', { 'class': 'cbi-button cbi-button-remove', 'click': resetHosts }, 'Восстановить hosts');

		var geoCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Заменить hosts на GeoHide'),
			E('p', { 'class': 'zm-hint' }, 'Внимание: это ПОЛНОСТЬЮ заменит файл /etc/hosts на список от GeoHide DNS — все блоки выше и любые ваши собственные записи будут удалены.'),
			geoGrid,
			E('p', { 'class': 'zm-hint' }, 'Или восстановить hosts к чистому виду. Уберёт и блоки выше, и GeoHide.'),
			E('div', { 'class': 'zm-actions' }, [ resetBtn ]),
			geoLogEl
		]);
		wrap.appendChild(geoCard);

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
			geoLogEl.classList.add('zm-show');
			zm.renderLog(geoLogEl, '==> Восстанавливаем hosts');
			zm.hostsReset().then(function(res) {
				busy = false;
				if (res.error) { zm.renderLog(geoLogEl, '==> ОШИБКА: ' + res.error); zm.toast(res.error, 'error'); return; }
				zm.renderLog(geoLogEl, '==> Готово — hosts восстановлен.');
				zm.toast('hosts восстановлен', 'info');
				refreshAll();
			}).catch(function() { busy = false; });
		}

		return wrap;
	}
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
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
			statusCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Связка из трёх программ: Mihomo (прокси-ядро) + hev-socks5-tunnel (мост в туннель) + MagiTrickle (направляет в туннель только выбранные сайты). Устанавливаются, обновляются и удаляются вместе, одной кнопкой.'));
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
				E('span', { 'class': 'zm-label' }, 'Сейчас установлена'),
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
			autoCard.appendChild(E('div', { 'class': 'zm-row' }, [
				E('span', { 'class': 'zm-label' }, 'Сейчас'),
				E('span', {}, cur === '' ? 'выключен' : (cur.indexOf('every:') === 0 ? 'каждые ' + cur.split(':')[1] + ' ч.' : 'ежедневно в ' + cur.split(':')[1].padStart(2, '0') + ':00'))
			]));
			var hourInput = E('input', { 'type': 'number', 'min': '0', 'max': '23', 'placeholder': 'час (0-23)', 'class': 'cbi-input-text', 'style': 'max-width:120px' });
			autoCard.appendChild(E('div', { 'class': 'zm-actions' }, [
				E('button', { 'class': 'cbi-button', 'click': function() { doAuto('off', ''); } }, 'Выключить'),
				E('button', { 'class': 'cbi-button', 'click': function() { doAuto('every', '2'); } }, 'Каждые 2 часа'),
				E('button', { 'class': 'cbi-button', 'click': function() { doAuto('every', '6'); } }, 'Каждые 6 часов'),
				hourInput,
				E('button', {
					'class': 'cbi-button',
					'click': function() {
						var h = hourInput.value.trim();
						if (!/^\d+$/.test(h) || +h < 0 || +h > 23) { zm.toast('Введите час от 0 до 23', 'error'); return; }
						doAuto('daily', h);
					}
				}, 'Ежедневно в это время')
			]));
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
							zm.mixomoStatus().then(renderPresets);
							refreshMtEmbed();
						}).catch(function() { presetBusy = false; });
					}
				}, p.label);
			})));
		}

		var mtFrame = null;
		function refreshMtEmbed() {
			if (mtFrame) { mtFrame.src = mtFrame.src.split('?')[0] + '?_r=' + Date.now(); }
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

		function renderWarpConf(w) {
			warpConfCard.innerHTML = '';
			warpConfCard.appendChild(E('h3', {}, 'Содержимое WARP.conf'));
			var pre = E('pre', { 'class': 'zm-log zm-show' }, w.content || 'ещё не сгенерирован');
			warpConfCard.appendChild(pre);
		}

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

mkdir -p /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/strategy.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

return view.extend({
	load: function() {
		zm.injectCss();
		return Promise.all([ zm.status(), zm.strategyListV() ]);
	},

	render: function(data) {
		var status = data[0], vList = data[1];
		var lastFlowseal = null;
		var wrap = E('div', { 'class': 'zm-wrap' });
		var logEl = E('pre', { 'class': 'zm-log' });
		var busy = false;

		var currentBanner = E('div', { 'class': 'zm-current-banner' });
		wrap.appendChild(currentBanner);

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

		wrap.appendChild(vCard);
		wrap.appendChild(fCard);
		wrap.appendChild(logEl);

		zm.strategyListFlowseal().then(function(res) {
			if (!res.started) renderFlowseal(res);
			else fGrid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список ещё не загружен — нажмите «Обновить список».'));
		});

		return wrap;
	}
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
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
.zm-tg-link-row { display: flex; align-items: flex-start; gap: 10px; }
.zm-tg-link-row .zm-tg-link-box { flex: 1 1 auto; }

.zm-current-banner {
	display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
	background: rgba(26,127,55,.07); border: 1px solid rgba(26,127,55,.22);
	border-radius: 10px; padding: 10px 16px; font-size: 13px; margin-bottom: 4px;
}
.zm-current-banner b { font-weight: 700; }
.zm-current-banner.zm-current-empty {
	background: rgba(110,118,129,.08); border-color: rgba(110,118,129,.2);
}

.cbi-page-actions { display: none !important; }
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
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
								zm.badge(res.ipv4_ok === true, 'ok, ' + res.ipv4_ms + ' ms', 'недоступен')
							]));
							netEl.appendChild(E('div', { 'class': 'zm-row' }, [
								E('span', { 'class': 'zm-label' }, 'IPv6 (google.com)'),
								zm.badge(res.ipv6_ok === true, 'ok, ' + res.ipv6_ms + ' ms', 'недоступен')
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
				E('span', { 'class': 'zm-label' }, 'Текущее'), mirrorCurrentEl
			]),
			mirrorGrid,
			mirrorLog
		]);
		wrap.appendChild(mirrorCard);

		var uninstallLog = E('pre', { 'class': 'zm-log' });
		var uninstallCard = E('div', { 'class': 'zm-card' }, [
			E('h3', {}, 'Удалить Zapret Manager из LuCI'),
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
						if (!confirm('Удалить веб-интерфейс Zapret Manager из LuCI?\n\nСам Zapret и остальные установленные через панель компоненты не пострадают. Действие необратимо — панель придётся ставить заново.')) {
							return;
						}
						uninstallLog.classList.add('zm-show');
						zm.renderLog(uninstallLog, '==> Удаляем веб-интерфейс Zapret Manager');
						zm.toast('Удаляем Zapret Manager из LuCI', 'warning');
						zm.systemUninstallPanel().then(function(res) {
							if (res.error) { zm.renderLog(uninstallLog, '==> ОШИБКА: ' + res.error); zm.toast(res.error, 'error'); return; }
							zm.renderLog(uninstallLog, '==> Готово. Панель удалена, страница больше не будет отвечать. Выходим из LuCI');
							zm.toast('Zapret Manager удалён из LuCI', 'info');
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

		return wrap;
	}
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/test.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var MODES = [
	{ id: 'v', label: 'Тестировать v' },
	{ id: 'flowseal', label: 'Тестировать Flowseal' },
	{ id: 'v_flowseal', label: 'Тестировать v + Flowseal' }
];

var MODE_LABELS = {
	v: 'v', flowseal: 'Flowseal', v_flowseal: 'v + Flowseal', youtube: 'YouTube'
};

var RESULT_MODES = ['v', 'flowseal', 'v_flowseal', 'youtube'];

return view.extend({
	load: function() {
		zm.injectCss();
		return zm.testStatus();
	},

	render: function(data) {
		var view = this;
		var wrap = E('div', { 'class': 'zm-wrap' });
		var logEl = E('pre', { 'class': 'zm-log' });
		var resultsEl = E('pre', { 'class': 'zm-log' });
		var busy = data.running === true;
		var curMode = data.mode || '';
		var status = data;

		var mainCard = E('div', { 'class': 'zm-card' });
		var ytCard = E('div', { 'class': 'zm-card' });
		var resultsButtonsEl = E('div', {});

		function stopButton() {
			return E('button', { 'class': 'cbi-button cbi-button-remove', 'click': doStop }, 'Остановить тестирование стратегий');
		}

		function renderMain() {
			mainCard.innerHTML = '';
			mainCard.appendChild(E('h3', {}, 'Тест стратегий v / Flowseal'));
			mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Тест идёт в фоне — переключение вкладок или закрытие LuCI его не прервёт. По окончании конфигурация всегда возвращается к тому, что было до начала теста — стратегии только тестируются, лучшую нужно применить вручную на странице «Стратегии».'));
			if (busy && curMode !== 'youtube') {
				mainCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Статус'),
					zm.badge(true, 'тест выполняется (' + (MODE_LABELS[curMode] || curMode) + ')', '')
				]));
				mainCard.appendChild(E('div', { 'class': 'zm-actions' }, [ stopButton() ]));
			} else if (busy) {
				mainCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас выполняется тест YouTube — дождитесь его завершения.'));
			} else {
				mainCard.appendChild(E('div', { 'class': 'zm-actions' }, MODES.map(function(m) {
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
			ytCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Всегда тестируется отдельно от v/Flowseal — своим набором стратегий и доменов YouTube.'));
			if (busy && curMode === 'youtube') {
				ytCard.appendChild(E('div', { 'class': 'zm-row' }, [
					E('span', { 'class': 'zm-label' }, 'Статус'),
					zm.badge(true, 'тест выполняется', '')
				]));
				ytCard.appendChild(E('div', { 'class': 'zm-actions' }, [ stopButton() ]));
			} else if (busy) {
				ytCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Сейчас выполняется тест v/Flowseal — дождитесь его завершения.'));
			} else {
				ytCard.appendChild(E('div', { 'class': 'zm-actions' }, [
					E('button', {
						'class': 'cbi-button cbi-button-positive',
						'click': function() { doStart('youtube'); }
					}, 'Тестировать YouTube')
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
			zm.toast('Запускаем тест стратегий', 'warning');
			zm.testAction('start', mode).then(function(res) {
				if (res.error) { busy = false; curMode = ''; zm.toast(res.error, 'error'); renderMain(); renderYt(); return; }
				startPolling();
			}).catch(function() { busy = false; curMode = ''; renderMain(); renderYt(); });
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
			RESULT_MODES.forEach(function(m) {
				if (!status['has_results_' + m]) return;
				actions.push(E('button', {
					'class': 'cbi-button',
					'click': function() { showResultsFor(m); }
				}, 'Показать результаты: ' + MODE_LABELS[m]));
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
		renderResultsButtons();

		if (busy) { startPolling(); }

		wrap.appendChild(mainCard);
		wrap.appendChild(ytCard);
		wrap.appendChild(logEl);
		wrap.appendChild(resultsCard);
		return wrap;
	}
});
ZM_INSTALLER_EOF

mkdir -p /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/tgproxy.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

var VARIANTS = [
	{ id: 'mtproto', title: 'MTProto (пакет)', port: 1443, kind: 'proto' },
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

				linksWrap.appendChild(E('div', { 'class': 'zm-tg-link-card' }, [
					E('h4', {}, v.title),
					E('p', { 'class': 'zm-tg-link-hint' }, 'Откройте эту ссылку на телефоне/компьютере с Telegram — прокси подключится автоматически. Либо скопируйте и вставьте её в браузер/Telegram вручную.'),
					E('div', { 'class': 'zm-tg-link-row' }, [
						E('div', { 'class': 'zm-tg-link-box' }, link),
						E('button', {
							'class': 'cbi-button cbi-button-positive',
							'click': function() { copyToClipboard(link); }
						}, 'Скопировать')
					]),
					E('p', { 'class': 'zm-hint' }, extra)
				]));
			});
			if (!any) {
				linksWrap.appendChild(E('p', { 'class': 'zm-hint' }, 'Ссылки появятся здесь после установки и запуска хотя бы одного варианта прокси ниже.'));
			}
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
			tgwsCard.appendChild(E('p', { 'class': 'zm-hint' }, 'Бета-версия. В отдельных случаях может потребоваться сброс роутера до заводских настроек. Не устанавливайте, если не уверены, что сможете устранить возможные проблемы — рекомендуется использовать другие варианты TG WS Proxy выше.'));
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

mkdir -p /www/luci-static/resources/view/zapret-manager
cat > '/www/luci-static/resources/view/zapret-manager/youtube.js' << 'ZM_INSTALLER_EOF'
'use strict';
'require view';
'require zapret-manager.common as zm';

return view.extend({
	load: function() {
		zm.injectCss();
		return Promise.all([ zm.status(), zm.strategyListYoutube() ]);
	},

	render: function(data) {
		var status = data[0], initial = data[1];
		var wrap = E('div', { 'class': 'zm-wrap' });
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

		wrap.appendChild(card);
		wrap.appendChild(logEl);

		if (!initial.started) {
			renderGrid(initial);
		} else {
			grid.appendChild(E('p', { 'class': 'zm-hint' }, 'Список ещё не загружен — нажмите «Обновить список».'));
		}

		return wrap;
	}
});
ZM_INSTALLER_EOF

rm -f /tmp/luci-indexcache* /tmp/luci-modulecache/* 2>/dev/null || true
/etc/init.d/rpcd restart >/dev/null 2>&1
/etc/init.d/uhttpd restart >/dev/null 2>&1

if command -v apk >/dev/null 2>&1; then PM="apk"; INSTALL="apk add"
else PM="opkg"; INSTALL="opkg install"; fi
command -v curl >/dev/null 2>&1 || $INSTALL curl >/dev/null 2>&1 || true
command -v unzip >/dev/null 2>&1 || $INSTALL unzip >/dev/null 2>&1 || true

echo -e "Zapret Manager ${GREEN}для ${NC}LuCI ${GREEN}установлен!${NC}\n"

