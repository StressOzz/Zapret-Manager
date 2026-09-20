#!/bin/sh
# ByeTube for LuCI installer
# Version: 1.01

GREEN="\033[1;32m"; MAGENTA="\033[1;35m"; NC="\033[0m"

BYEDPI_REPO="DPITrickster/ByeDPI-OpenWrt"
R="${BT_ROOT:-}"
BT_DIR="/opt/ByeTube"
BT_TMP_DIR="/tmp/ByeTube"
NEW_BYEDPI=0
NEW_HEV=0
LEGACY=0
MODE=install
NOSTART=0

die()  { printf '\033[1;31mОшибка:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
	cat <<'USAGE'
ByeTube — установщик для OpenWrt

  sh ByeTube.sh               установить и запустить
  sh ByeTube.sh --no-start    установить, но не запускать
  sh ByeTube.sh --uninstall   удалить (пакеты byedpi и hev остаются)
  sh ByeTube.sh --purge       удалить вместе с пакетами byedpi и hev-socks5-tunnel

  BYEDPI_URL=<ссылка на .ipk/.apk>   поставить byedpi с конкретной ссылки
  FORCE_BYEDPI=1                     переустановить byedpi
USAGE
}

parse_args() {
	local a
	for a in "$@"; do
		case "$a" in
			--no-start)  NOSTART=1 ;;
			--uninstall) MODE=uninstall ;;
			--purge)     MODE=purge ;;
			-h|--help)   usage; exit 0 ;;
			*) die "неизвестный аргумент: $a" ;;
		esac
	done
}

pkg_has() {
	if [ "$PM" = apk ]; then apk info -e "$1" >/dev/null 2>&1
	else opkg list-installed 2>/dev/null | grep -q "^$1 - "; fi
}
pkg_add() { if [ "$PM" = apk ]; then apk add "$@"; else opkg install "$@"; fi >/dev/null 2>&1; }
pkg_del() { if [ "$PM" = apk ]; then apk del "$@"; else opkg remove "$@"; fi >/dev/null 2>&1; }

fetch() {
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 15 -o "$2" "$1"
	else
		wget -q -T 20 -O "$2" "$1"
	fi
}

run_uninstall() {
	sh -s -- "$@" <<'BT_FILE_END_7f3a9c'
#!/bin/sh
R="${BT_ROOT:-}"
MODE="$1"

CURRENT_PATHS="/opt/ByeTube /tmp/ByeTube /etc/init.d/byetube /etc/config/byetube /etc/hotplug.d/firewall/90-byetube /usr/share/nftables.d/chain-pre/forward/50-byetube.nft /usr/share/luci/menu.d/luci-app-byetube.json /usr/share/rpcd/acl.d/luci-app-byetube.json /www/luci-static/resources/view/byetube /www/luci-static/resources/byetube /lib/upgrade/keep.d/byetube"

LEGACY_PATHS="/etc/init.d/ytbypass /etc/config/ytbypass /etc/hotplug.d/firewall/90-ytbypass /usr/bin/ytbypass /usr/libexec/ytbypass /usr/share/ytbypass /usr/share/nftables.d/chain-pre/forward/50-ytbypass.nft /usr/share/luci/menu.d/luci-app-ytbypass.json /usr/share/rpcd/acl.d/luci-app-ytbypass.json /www/luci-static/resources/view/ytbypass /www/luci-static/resources/ytbypass /lib/upgrade/keep.d/ytbypass /etc/ytbypass /var/etc/ytbypass /var/run/ytbypass.started /tmp/ytbypass-test"

live() { [ -z "$R" ]; }

confdir() {
	local d
	d=$(sed -n 's/^conf-dir=\([^,]*\).*/\1/p' "$R"/var/etc/dnsmasq.conf.* 2>/dev/null | head -n 1)
	[ -n "$d" ] || d=/tmp/dnsmasq.d
	echo "$d"
}

drop_ip_rules() {
	live || return 0
	while ip rule del pref 8900 2>/dev/null; do :; done
	while ip -6 rule del pref 8900 2>/dev/null; do :; done
}

drop_dev() {
	live || return 0
	ip route del default dev "$1" table 89 2>/dev/null
	ip -6 route del default dev "$1" table 89 2>/dev/null
	nft delete table inet "$2" 2>/dev/null
}

stop_service() {
	live || return 0
	[ -x "/etc/init.d/$1" ] || return 0
	"/etc/init.d/$1" stop >/dev/null 2>&1
	"/etc/init.d/$1" disable >/dev/null 2>&1
}

remove_dnsmasq_conf() {
	local d f changed=0
	d="$R$(confdir)"
	for f in "$@"; do
		if [ -f "$d/$f" ]; then
			rm -f "$d/$f"
			changed=1
		fi
	done
	[ "$changed" = "1" ]
}

remove_paths() {
	local p
	for p in "$@"; do
		rm -rf "$R$p"
	done
}

dns_changed=0

if [ "$MODE" != "--legacy" ]; then
	stop_service byetube
	drop_ip_rules
	drop_dev byetube0 byetube
	remove_dnsmasq_conf byetube.conf && dns_changed=1
fi

stop_service ytbypass
if [ "$MODE" != "--legacy" ] || [ ! -f "$R/tmp/ByeTube/started" ]; then
	drop_ip_rules
fi
drop_dev ytb0 ytbypass
remove_dnsmasq_conf ytbypass.conf && dns_changed=1

if [ "$MODE" = "--legacy" ]; then
	remove_paths $LEGACY_PATHS
else
	remove_paths $CURRENT_PATHS $LEGACY_PATHS
fi

if live; then
	[ "$dns_changed" = "1" ] && /etc/init.d/dnsmasq restart >/dev/null 2>&1
	/etc/init.d/firewall reload >/dev/null 2>&1
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
	/etc/init.d/rpcd reload >/dev/null 2>&1
fi
exit 0
BT_FILE_END_7f3a9c
}

do_uninstall() {
	echo -e "\n${MAGENTA}Удаляем ByeTube${NC}"
	[ -x "$R$BT_DIR/bin/byetube" ] && "$R$BT_DIR/bin/byetube" test stop >/dev/null 2>&1
	run_uninstall >/dev/null 2>&1
	[ "$MODE" = purge ] && pkg_del byedpi hev-socks5-tunnel
	echo -e "ByeTube ${GREEN}удалён!${NC}\n"
	exit 0
}

fix_resolv() {
	rm -f /tmp/resolv.conf
	if grep -qs '^nameserver' /tmp/resolv.conf.d/resolv.conf.auto; then
		cp /tmp/resolv.conf.d/resolv.conf.auto /tmp/resolv.conf
	else
		printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /tmp/resolv.conf
	fi
}

ensure_dnsmasq_full() {
	local p
	dnsmasq --version 2>/dev/null | grep -Eq '(^| )nftset( |$)' && return 0
	mkdir -p "$BT_TMP_DIR"
	cp /etc/config/dhcp "$BT_TMP_DIR/dhcp.bak" 2>/dev/null
	for p in dnsmasq dnsmasq-dhcpv6; do
		pkg_has "$p" && pkg_del "$p"
	done
	fix_resolv
	if ! pkg_add dnsmasq-full; then
		fix_resolv
		pkg_add dnsmasq
		[ -f /etc/config/dhcp ] || cp "$BT_TMP_DIR/dhcp.bak" /etc/config/dhcp 2>/dev/null
		/etc/init.d/dnsmasq restart >/dev/null 2>&1
		die "dnsmasq-full не установлен"
	fi
	[ -f /etc/config/dhcp ] || cp "$BT_TMP_DIR/dhcp.bak" /etc/config/dhcp 2>/dev/null
	/etc/init.d/dnsmasq enable >/dev/null 2>&1
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
}

install_byedpi() {
	local url json cands f
	[ -x /usr/bin/ciadpi ] && [ "${FORCE_BYEDPI:-0}" != 1 ] && return 0
	url="${BYEDPI_URL:-}"
	if [ -z "$url" ]; then
		json=$(fetch "https://api.github.com/repos/$BYEDPI_REPO/releases?per_page=40" - 2>/dev/null)
		cands=$(printf '%s\n' "$json" \
			| grep -o '"browser_download_url": *"[^"]*"' \
			| sed 's/^[^:]*: *"//; s/"$//' \
			| grep -E "/byedpi_[^/]*_${ARCH}\.${EXT}\$")
		url=$(printf '%s\n' "$cands" | grep -F "$REL_MM" | head -n 1)
		[ -n "$url" ] || url=$(printf '%s\n' "$cands" | head -n 1)
	fi
	[ -n "$url" ] || die "не нашёл пакет byedpi для $ARCH (.$EXT). Скачайте вручную с https://github.com/$BYEDPI_REPO/releases и запустите: BYEDPI_URL=<ссылка> sh install.sh"
	mkdir -p "$BT_TMP_DIR/dl"
	f="$BT_TMP_DIR/dl/$(basename "$url")"
	fetch "$url" "$f" || die "не удалось скачать byedpi"
	{ if [ "$PM" = apk ]; then apk add --allow-untrusted "$f"; else opkg install "$f"; fi; } >/dev/null 2>&1 \
		|| die "не удалось установить byedpi"
	rm -rf "$BT_TMP_DIR/dl"
	NEW_BYEDPI=1
}

install_payload() {
	mkdir -p "$R/etc/config"
	[ -f "$R/etc/config/byetube" ] || cat > "$R/etc/config/byetube" <<'BT_FILE_END_7f3a9c'
config byetube 'main'
	option enabled '1'
	option byedpi_port '1088'
	option byedpi_opts '-d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -S -a1'
	option ipv6 '1'
	option quic 'block'
	option default_domains '1'
BT_FILE_END_7f3a9c
	chmod 644 "$R/etc/config/byetube"
	mkdir -p "$R/etc/hotplug.d/firewall"
	cat > "$R/etc/hotplug.d/firewall/90-byetube" <<'BT_FILE_END_7f3a9c'
#!/bin/sh
[ -f /tmp/ByeTube/started ] || exit 0
nft list table inet byetube >/dev/null 2>&1 && exit 0
logger -t byetube "таблица nft пропала после reload firewall — восстанавливаю"
/etc/init.d/byetube restart >/dev/null 2>&1
exit 0
BT_FILE_END_7f3a9c
	chmod 755 "$R/etc/hotplug.d/firewall/90-byetube"
	mkdir -p "$R/etc/init.d"
	cat > "$R/etc/init.d/byetube" <<'BT_FILE_END_7f3a9c'
#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

NAME=byetube

[ -r /opt/ByeTube/lib/common.sh ] || exit 0
. /opt/ByeTube/lib/common.sh
. /opt/ByeTube/lib/dns.sh

log() { logger -t "$NAME" "$*"; }

write_hev_conf() {
	local port="$1" ipv6="$2" f="$BT_TMP/hev.yml"
	{
		echo "tunnel:"
		echo "  name: $TUN"
		echo "  mtu: 1500"
		echo "  ipv4: 198.18.0.1"
		[ "$ipv6" = "1" ] && echo "  ipv6: 'fc00::1'"
		echo "  post-up-script: $BT_HOME/lib/route-up.sh"
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
	nft list chain inet fw4 forward 2>/dev/null | grep -q "byetube" && return 0
	[ -f /usr/share/nftables.d/chain-pre/forward/50-byetube.nft ] || return 0
	log "перезагружаю firewall, чтобы подхватить правило forward"
	/etc/init.d/firewall reload >/dev/null 2>&1
}

start_service() {
	local enabled byedpi_port byedpi_opts ipv6 byedpi hev

	config_load "$NAME"
	config_get enabled main enabled 0
	if [ "$enabled" != "1" ]; then
		"$BT_HOME/lib/net.sh" purge
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

	bt_prepare
	write_hev_conf "$byedpi_port" "$ipv6"

	"$BT_HOME/lib/net.sh" up || { log "не удалось настроить nftables/маршрутизацию"; return 1; }
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
	procd_set_param command "$hev" "$BT_TMP/hev.yml"
	procd_set_param respawn 3600 5 0
	procd_set_param stderr 1
	procd_close_instance

	touch "$STARTED_FLAG"
}

stop_service() {
	rm -f "$STARTED_FLAG"
	"$BT_HOME/lib/net.sh" down
}

service_triggers() {
	procd_add_reload_trigger "$NAME"
}
BT_FILE_END_7f3a9c
	chmod 755 "$R/etc/init.d/byetube"
	mkdir -p "$R/lib/upgrade/keep.d"
	cat > "$R/lib/upgrade/keep.d/byetube" <<'BT_FILE_END_7f3a9c'
/opt/ByeTube/custom/
BT_FILE_END_7f3a9c
	chmod 644 "$R/lib/upgrade/keep.d/byetube"
	mkdir -p "$R/opt/ByeTube/bin"
	cat > "$R/opt/ByeTube/bin/byetube" <<'BT_FILE_END_7f3a9c'
#!/bin/sh
. "${BT_FUNCTIONS:-/lib/functions.sh}"
. "${BT_HOME:-/opt/ByeTube}/lib/common.sh"
. "$BT_HOME/lib/lists.sh"

svc_running() {
	ubus call service list '{"name":"byetube"}' 2>/dev/null \
		| jsonfilter -e "@.byetube.instances.$1.running" 2>/dev/null | grep -q true
}

count_set() {
	nft list set inet "$NFT_TABLE" "$1" 2>/dev/null | grep -o 'expires' | wc -l
}

b() { if [ "$1" = "1" ]; then echo true; else echo false; fi; }

extra_count() {
	config_list_foreach main domain _extra_inc
	echo "$_extra_n"
}
_extra_n=0
_extra_inc() { _extra_n=$((_extra_n + 1)); }

cfg_valid() {
	local v
	case "$1" in
		enabled|ipv6|default_domains)
			case "$2" in 0|1) printf '%s' "$2" ;; *) return 1 ;; esac ;;
		quic)
			case "$2" in block|proxy) printf '%s' "$2" ;; *) return 1 ;; esac ;;
		byedpi_port)
			case "$2" in ''|*[!0-9]*) return 1 ;; esac
			[ "$2" -ge 1 ] && [ "$2" -le 65535 ] || return 1
			printf '%s' "$2" ;;
		byedpi_opts)
			v=$(printf '%s' "$2" | tr '\n\r\t' '   ' | sed 's/  */ /g; s/^ //; s/ $//')
			[ -n "$v" ] || return 1
			printf '%s' "$v" ;;
		*) return 1 ;;
	esac
}

cmd_config() {
	local action="$1" k v nv args="" err="" ipv6s=false
	shift
	case "$action" in
	get)
		config_load byetube
		config_get enabled main enabled 0
		config_get byedpi_opts main byedpi_opts ""
		config_get byedpi_port main byedpi_port 1088
		config_get quic main quic block
		config_get ipv6 main ipv6 1
		config_get default_domains main default_domains 1
		case "$byedpi_port" in ''|*[!0-9]*) byedpi_port=1088 ;; esac
		[ -f /proc/net/if_inet6 ] && ipv6s=true
		printf '{"enabled":%s,"byedpi_opts":"%s","byedpi_port":%s,"quic":"%s","ipv6":%s,"ipv6_supported":%s,"default_domains":%s}\n' \
			"$(b "$enabled")" "$(json_esc "$byedpi_opts")" "$byedpi_port" "$quic" "$(b "$ipv6")" "$ipv6s" "$(b "$default_domains")"
		;;
	set)
		while [ $# -ge 2 ]; do
			k="$1"; v="$2"; shift 2
			if ! nv=$(cfg_valid "$k" "$v"); then
				err="$k"
				break
			fi
			args="$args
$k=$nv"
		done
		if [ -n "$err" ]; then
			printf '{"error":"Неверное значение параметра: %s"}\n' "$(json_esc "$err")"
			return 0
		fi
		printf '%s\n' "$args" | while IFS='=' read -r k v; do
			[ -n "$k" ] && uci set "byetube.main.$k=$v"
		done
		uci commit byetube
		echo '{"ok":true}'
		;;
	*)
		echo '{"error":"неизвестное действие"}'
		;;
	esac
}

case "$1" in
status)
	config_load byetube
	config_get enabled main enabled 0
	config_get ipv6 main ipv6 1
	config_get quic main quic block
	config_get default_domains main default_domains 1

	v_byedpi=0; svc_running byedpi && v_byedpi=1
	v_hev=0;    svc_running hev && v_hev=1
	v_tun=0;    ip link show "$TUN" >/dev/null 2>&1 && v_tun=1
	v_nft=0;    nft list table inet "$NFT_TABLE" >/dev/null 2>&1 && v_nft=1
	v_rule=0;   ip rule show 2>/dev/null | grep -q "lookup $TABLE" && v_rule=1
	v_route=0;  ip route show table "$TABLE" 2>/dev/null | grep -q "$TUN" && v_route=1
	v_dns=0;    [ -s "$(dnsmasq_confdir)/byetube.conf" ] && v_dns=1
	v_nftset=0; dnsmasq_has_nftset && v_nftset=1
	v_fw=0;     nft list chain inet fw4 forward 2>/dev/null | grep -q byetube && v_fw=1
	v_bin=0;    { [ -x /usr/bin/ciadpi ] || [ -x /usr/bin/byedpi ]; } && [ -x /usr/bin/hev-socks5-tunnel ] && v_bin=1
	v_ycust=0;  list_is_custom youtube && v_ycust=1

	printf '{"version":"%s","enabled":%s,"byedpi":%s,"hev":%s,"tun":%s,"nft":%s,"rule":%s,"route":%s,"dns":%s,"dnsmasq_nftset":%s,"fw":%s,"binaries":%s,"ipv6":%s,"quic":"%s","default_domains":%s,"youtube_count":%s,"youtube_custom":%s,"extra_count":%s,"ips4":%s,"ips6":%s}\n' \
		"$BT_VERSION" "$(b "$enabled")" "$(b $v_byedpi)" "$(b $v_hev)" "$(b $v_tun)" "$(b $v_nft)" \
		"$(b $v_rule)" "$(b $v_route)" "$(b $v_dns)" "$(b $v_nftset)" "$(b $v_fw)" "$(b $v_bin)" \
		"$(b "$ipv6")" "$quic" "$(b "$default_domains")" "$(count_lines "$(list_file youtube)")" "$(b $v_ycust)" "$(extra_count)" \
		"$(count_set yt4)" "$(count_set yt6)"
	;;
config)
	shift
	cmd_config "$@"
	;;
service)
	case "$2" in
		start|stop|restart) /etc/init.d/byetube "$2" >/dev/null 2>&1; echo '{"ok":true}' ;;
		*) echo '{"error":"неизвестное действие"}' ;;
	esac
	;;
flush)
	nft flush set inet "$NFT_TABLE" yt4 2>/dev/null
	nft flush set inet "$NFT_TABLE" yt6 2>/dev/null
	echo '{"ok":true}'
	;;
ips)
	nft list set inet "$NFT_TABLE" yt4 2>/dev/null
	nft list set inet "$NFT_TABLE" yt6 2>/dev/null
	;;
list)
	shift
	cmd_list "$@"
	;;
diag)
	arg="$2"; secs="${3:-20}"
	LEASES="${BT_LEASES:-/tmp/dhcp.leases}"
	CT="${BT_CT:-/proc/net/nf_conntrack}"
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
		echo "Запустите: byetube diag <IP|MAC|имя телефона> [секунд, по умолчанию 20]"
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
	exec "$BT_HOME/lib/test.sh" "$@"
	;;
set-strategy)
	if nv=$(cfg_valid byedpi_opts "$2"); then
		uci set "byetube.main.byedpi_opts=$nv" && uci commit byetube
		/etc/init.d/byetube restart >/dev/null 2>&1
		echo '{"ok":true}'
	else
		echo '{"error":"пустая стратегия"}'
	fi
	;;
version)
	echo "$BT_VERSION"
	;;
*)
	echo "usage: byetube status|config|service|flush|ips|list|diag|test|set-strategy|version" >&2
	exit 1
	;;
esac
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/bin/byetube"
	mkdir -p "$R/opt/ByeTube/default"
	cat > "$R/opt/ByeTube/default/domains.list" <<'BT_FILE_END_7f3a9c'
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
BT_FILE_END_7f3a9c
	chmod 644 "$R/opt/ByeTube/default/domains.list"
	mkdir -p "$R/opt/ByeTube/default"
	cat > "$R/opt/ByeTube/default/strategies.txt" <<'BT_FILE_END_7f3a9c'
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
BT_FILE_END_7f3a9c
	chmod 644 "$R/opt/ByeTube/default/strategies.txt"
	mkdir -p "$R/opt/ByeTube/default"
	cat > "$R/opt/ByeTube/default/test-domains.txt" <<'BT_FILE_END_7f3a9c'
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
BT_FILE_END_7f3a9c
	chmod 644 "$R/opt/ByeTube/default/test-domains.txt"
	mkdir -p "$R/opt/ByeTube/lib"
	cat > "$R/opt/ByeTube/lib/common.sh" <<'BT_FILE_END_7f3a9c'
BT_HOME="${BT_HOME:-/opt/ByeTube}"
BT_TMP="${BT_TMP:-/tmp/ByeTube}"
BT_FUNCTIONS="${BT_FUNCTIONS:-/lib/functions.sh}"
BT_DEFAULT="$BT_HOME/default"
BT_CUSTOM="$BT_HOME/custom"
BT_VERSION="1.01"

TUN=byetube0
MARK=0x10000
MASK=0x10000
TABLE=89
PREF=8900
NFT_TABLE=byetube
STARTED_FLAG="$BT_TMP/started"
TEST_DIR="$BT_TMP/test"

bt_prepare() {
	mkdir -p "$BT_TMP"
}

dnsmasq_confdir() {
	local d
	d=$(sed -n 's/^conf-dir=\([^,]*\).*/\1/p' /var/etc/dnsmasq.conf.* 2>/dev/null | head -n 1)
	[ -n "$d" ] || d=/tmp/dnsmasq.d
	echo "$d"
}

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

json_esc() {
	printf '%s' "$1" | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g'
}

count_lines() {
	sed 's/#.*//' "$1" 2>/dev/null | tr -d '\r' | grep -c '[^[:space:]]'
}

list_name() {
	case "$1" in
		youtube)      echo domains.list ;;
		strategies)   echo strategies.txt ;;
		test-domains) echo test-domains.txt ;;
	esac
}

list_file() {
	local nm
	nm=$(list_name "$1")
	[ -n "$nm" ] || return 1
	if [ -s "$BT_CUSTOM/$nm" ]; then
		echo "$BT_CUSTOM/$nm"
	else
		echo "$BT_DEFAULT/$nm"
	fi
}

list_is_custom() {
	local nm
	nm=$(list_name "$1")
	[ -n "$nm" ] && [ -s "$BT_CUSTOM/$nm" ]
}

test_is_running() {
	[ -f "$TEST_DIR/job.pid" ] && kill -0 "$(cat "$TEST_DIR/job.pid" 2>/dev/null)" 2>/dev/null
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
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/lib/common.sh"
	mkdir -p "$R/opt/ByeTube/lib"
	cat > "$R/opt/ByeTube/lib/dns-apply.sh" <<'BT_FILE_END_7f3a9c'
#!/bin/sh
. "${BT_FUNCTIONS:-/lib/functions.sh}"
. "${BT_HOME:-/opt/ByeTube}/lib/common.sh"
. "$BT_HOME/lib/dns.sh"

config_load byetube
config_get enabled main enabled 0
[ "$enabled" = "1" ] || exit 0
config_get ipv6 main ipv6 1
[ -f /proc/net/if_inet6 ] || ipv6=0
dns_apply "$ipv6"
exit 0
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/lib/dns-apply.sh"
	mkdir -p "$R/opt/ByeTube/lib"
	cat > "$R/opt/ByeTube/lib/dns.sh" <<'BT_FILE_END_7f3a9c'
_echo() { echo "$1"; }

collect_domains() {
	local use_default
	config_get use_default main default_domains 1
	{
		[ "$use_default" = "1" ] && cat "$(list_file youtube)" 2>/dev/null
		config_list_foreach main domain _echo
	} | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
	  | tr '[:upper:]' '[:lower:]' \
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
	local conf
	conf="$(dnsmasq_confdir)/byetube.conf"
	[ -f "$conf" ] || return 0
	rm -f "$conf"
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
}

dns_apply() {
	local ipv6="$1" conf domains suffix new old
	conf="$(dnsmasq_confdir)/byetube.conf"
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
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/lib/dns.sh"
	mkdir -p "$R/opt/ByeTube/lib"
	cat > "$R/opt/ByeTube/lib/lists.sh" <<'BT_FILE_END_7f3a9c'
list_apply_dns() {
	local en
	"$BT_HOME/lib/dns-apply.sh" >/dev/null 2>&1
	en=$(uci -q get byetube.main.enabled)
	[ "$en" = "1" ]
}

list_extra_get() {
	uci -q get byetube.main.domain | tr ' ' '\n' | grep -v '^$'
}

list_extra_write() {
	local file="$1" d
	uci -q delete byetube.main.domain
	while IFS= read -r d; do
		[ -n "$d" ] && uci add_list "byetube.main.domain=$d"
	done < "$file"
	uci commit byetube
}

cmd_list() {
	local action="$1" kind="$2" text="$3" nm tmp bad n f applied=false custom=false

	case "$kind" in
		youtube|strategies|test-domains|extra) ;;
		*) echo '{"error":"неизвестный список"}'; return 0 ;;
	esac

	case "$action" in
	get)
		if [ "$kind" = "extra" ]; then
			list_extra_get
		else
			f=$(list_file "$kind")
			[ -f "$f" ] && cat "$f"
		fi
		return 0
		;;
	set|reset)
		;;
	*)
		echo '{"error":"неизвестное действие"}'
		return 0
		;;
	esac

	case "$kind" in
		strategies|test-domains)
			if test_is_running; then
				echo '{"error":"тест выполняется — остановите его перед изменением списка"}'
				return 0
			fi
			;;
	esac

	nm=$(list_name "$kind")
	mkdir -p "$BT_TMP"
	tmp="$BT_TMP/list.$$"
	bad="$BT_TMP/bad.$$"

	if [ "$action" = "reset" ]; then
		if [ "$kind" = "extra" ]; then
			: > "$tmp"
			list_extra_write "$tmp"
			rm -f "$tmp"
			n=0
		else
			rm -f "$BT_CUSTOM/$nm"
			n=$(count_lines "$(list_file "$kind")")
		fi
	else
		: > "$bad"
		case "$kind" in
			strategies) printf '%s\n' "$text" | norm_strategies > "$tmp" ;;
			extra)      printf '%s\n' "$text" | norm_domains "$bad" | grep -v '^#' > "$tmp" ;;
			*)          printf '%s\n' "$text" | norm_domains "$bad" > "$tmp" ;;
		esac
		if [ -s "$bad" ]; then
			printf '{"error":"Некорректный домен: %s"}\n' "$(json_esc "$(head -n 1 "$bad")")"
			rm -f "$tmp" "$bad"
			return 0
		fi
		rm -f "$bad"
		n=$(count_lines "$tmp")
		if [ "$kind" = "extra" ]; then
			list_extra_write "$tmp"
			rm -f "$tmp"
		else
			if [ "${n:-0}" -le 0 ]; then
				echo '{"error":"список пуст — чтобы вернуть встроенный, нажмите «Восстановить встроенный»"}'
				rm -f "$tmp"
				return 0
			fi
			mkdir -p "$BT_CUSTOM"
			mv "$tmp" "$BT_CUSTOM/$nm"
		fi
	fi

	case "$kind" in
		youtube|extra) list_apply_dns && applied=true ;;
	esac
	if [ "$kind" != "extra" ] && list_is_custom "$kind"; then
		custom=true
	fi
	[ "$kind" = "extra" ] && [ "${n:-0}" -gt 0 ] && custom=true
	printf '{"ok":true,"count":%s,"custom":%s,"applied":%s}\n' "${n:-0}" "$custom" "$applied"
	return 0
}
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/lib/lists.sh"
	mkdir -p "$R/opt/ByeTube/lib"
	cat > "$R/opt/ByeTube/lib/net.sh" <<'BT_FILE_END_7f3a9c'
#!/bin/sh
. "${BT_FUNCTIONS:-/lib/functions.sh}"
. "${BT_HOME:-/opt/ByeTube}/lib/common.sh"

config_load byetube
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
	ip link show "$TUN" >/dev/null 2>&1 && "$BT_HOME/lib/route-up.sh" "$TUN"
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
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/lib/net.sh"
	mkdir -p "$R/opt/ByeTube/lib"
	cat > "$R/opt/ByeTube/lib/route-up.sh" <<'BT_FILE_END_7f3a9c'
#!/bin/sh
. "${BT_FUNCTIONS:-/lib/functions.sh}"
. "${BT_HOME:-/opt/ByeTube}/lib/common.sh"

config_load byetube
config_get IPV6 main ipv6 1
[ -f /proc/net/if_inet6 ] || IPV6=0

ip link set "$TUN" up 2>/dev/null
ip route replace default dev "$TUN" table "$TABLE"
[ "$IPV6" = "1" ] && ip -6 route replace default dev "$TUN" table "$TABLE"

echo 2 > "/proc/sys/net/ipv4/conf/$TUN/rp_filter" 2>/dev/null
exit 0
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/lib/route-up.sh"
	mkdir -p "$R/opt/ByeTube/lib"
	cat > "$R/opt/ByeTube/lib/test.sh" <<'BT_FILE_END_7f3a9c'
#!/bin/sh
. "${BT_FUNCTIONS:-/lib/functions.sh}"
. "${BT_HOME:-/opt/ByeTube}/lib/common.sh"

PIDF="$TEST_DIR/job.pid"
LOGF="$TEST_DIR/job.log"
RES="$TEST_DIR/results.txt"
RAW="$TEST_DIR/results.raw"
STOP="$TEST_DIR/stop"
CPID="$TEST_DIR/ciadpi.pid"
PORT_BASE=22000
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) curl/8.0'
TAB=$(printf '\t')

cmd_start() {
	if test_is_running; then
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
	if ! test_is_running; then
		echo '{"error":"тест не запущен"}'
		return 0
	fi
	touch "$STOP"
	[ -f "$CPID" ] && kill "$(cat "$CPID" 2>/dev/null)" 2>/dev/null
	echo '{"ok":true}'
}

cmd_status() {
	local running=false has=false cu=false rc="" sc=false dc=false
	test_is_running && running=true
	[ -s "$RES" ] && has=true
	command -v curl >/dev/null 2>&1 && cu=true
	[ -f "$LOGF" ] && rc=$(grep '^__DONE__' "$LOGF" | tail -n 1 | awk '{print $2}')
	list_is_custom strategies && sc=true
	list_is_custom test-domains && dc=true
	printf '{"running":%s,"has_results":%s,"curl":%s,"strategies":%s,"test_domains":%s,"strategies_custom":%s,"test_domains_custom":%s,"rc":"%s"}\n' \
		"$running" "$has" "$cu" "$(count_lines "$(list_file strategies)")" "$(count_lines "$(list_file test-domains)")" "$sc" "$dc" "$rc"
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
	if test_is_running; then
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

	set -f
	trap cleanup EXIT
	trap 'exit 130' INT TERM

	config_load byetube
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
	tr -d '\r' < "$(list_file test-domains)" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
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

	echo "==> Результаты"
	cat "$RES"
	best=$(sed -n '2p' "$RES")
	[ -n "$best" ] && echo "==> Лучшая стратегия: $best"
	echo "==> Основной сервис и его настройки не менялись. Применить стратегию можно кнопкой «Применить» в результатах."
	return 0
}

case "$1" in
	start)   cmd_start ;;
	stop)    cmd_stop ;;
	status)  cmd_status ;;
	log)     cmd_log ;;
	results) cmd_results ;;
	clear)   cmd_clear ;;
	run)     cmd_run ;;
	*) echo "usage: byetube test start|stop|status|log|results|clear" >&2; exit 1 ;;
esac
exit 0
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/lib/test.sh"
	mkdir -p "$R/opt/ByeTube"
	cat > "$R/opt/ByeTube/uninstall.sh" <<'BT_FILE_END_7f3a9c'
#!/bin/sh
R="${BT_ROOT:-}"
MODE="$1"

CURRENT_PATHS="/opt/ByeTube /tmp/ByeTube /etc/init.d/byetube /etc/config/byetube /etc/hotplug.d/firewall/90-byetube /usr/share/nftables.d/chain-pre/forward/50-byetube.nft /usr/share/luci/menu.d/luci-app-byetube.json /usr/share/rpcd/acl.d/luci-app-byetube.json /www/luci-static/resources/view/byetube /www/luci-static/resources/byetube /lib/upgrade/keep.d/byetube"

LEGACY_PATHS="/etc/init.d/ytbypass /etc/config/ytbypass /etc/hotplug.d/firewall/90-ytbypass /usr/bin/ytbypass /usr/libexec/ytbypass /usr/share/ytbypass /usr/share/nftables.d/chain-pre/forward/50-ytbypass.nft /usr/share/luci/menu.d/luci-app-ytbypass.json /usr/share/rpcd/acl.d/luci-app-ytbypass.json /www/luci-static/resources/view/ytbypass /www/luci-static/resources/ytbypass /lib/upgrade/keep.d/ytbypass /etc/ytbypass /var/etc/ytbypass /var/run/ytbypass.started /tmp/ytbypass-test"

live() { [ -z "$R" ]; }

confdir() {
	local d
	d=$(sed -n 's/^conf-dir=\([^,]*\).*/\1/p' "$R"/var/etc/dnsmasq.conf.* 2>/dev/null | head -n 1)
	[ -n "$d" ] || d=/tmp/dnsmasq.d
	echo "$d"
}

drop_ip_rules() {
	live || return 0
	while ip rule del pref 8900 2>/dev/null; do :; done
	while ip -6 rule del pref 8900 2>/dev/null; do :; done
}

drop_dev() {
	live || return 0
	ip route del default dev "$1" table 89 2>/dev/null
	ip -6 route del default dev "$1" table 89 2>/dev/null
	nft delete table inet "$2" 2>/dev/null
}

stop_service() {
	live || return 0
	[ -x "/etc/init.d/$1" ] || return 0
	"/etc/init.d/$1" stop >/dev/null 2>&1
	"/etc/init.d/$1" disable >/dev/null 2>&1
}

remove_dnsmasq_conf() {
	local d f changed=0
	d="$R$(confdir)"
	for f in "$@"; do
		if [ -f "$d/$f" ]; then
			rm -f "$d/$f"
			changed=1
		fi
	done
	[ "$changed" = "1" ]
}

remove_paths() {
	local p
	for p in "$@"; do
		rm -rf "$R$p"
	done
}

dns_changed=0

if [ "$MODE" != "--legacy" ]; then
	stop_service byetube
	drop_ip_rules
	drop_dev byetube0 byetube
	remove_dnsmasq_conf byetube.conf && dns_changed=1
fi

stop_service ytbypass
if [ "$MODE" != "--legacy" ] || [ ! -f "$R/tmp/ByeTube/started" ]; then
	drop_ip_rules
fi
drop_dev ytb0 ytbypass
remove_dnsmasq_conf ytbypass.conf && dns_changed=1

if [ "$MODE" = "--legacy" ]; then
	remove_paths $LEGACY_PATHS
else
	remove_paths $CURRENT_PATHS $LEGACY_PATHS
fi

if live; then
	[ "$dns_changed" = "1" ] && /etc/init.d/dnsmasq restart >/dev/null 2>&1
	/etc/init.d/firewall reload >/dev/null 2>&1
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
	/etc/init.d/rpcd reload >/dev/null 2>&1
fi
exit 0
BT_FILE_END_7f3a9c
	chmod 755 "$R/opt/ByeTube/uninstall.sh"
	mkdir -p "$R/usr/share/luci/menu.d"
	cat > "$R/usr/share/luci/menu.d/luci-app-byetube.json" <<'BT_FILE_END_7f3a9c'
{
	"admin/services/byetube": {
		"title": "ByeTube",
		"order": 58,
		"action": {
			"type": "view",
			"path": "byetube/main"
		},
		"depends": {
			"acl": [ "luci-app-byetube" ],
			"uci": { "byetube": true }
		}
	}
}
BT_FILE_END_7f3a9c
	chmod 644 "$R/usr/share/luci/menu.d/luci-app-byetube.json"
	mkdir -p "$R/usr/share/nftables.d/chain-pre/forward"
	cat > "$R/usr/share/nftables.d/chain-pre/forward/50-byetube.nft" <<'BT_FILE_END_7f3a9c'
oifname "byetube0" accept comment "byetube"
BT_FILE_END_7f3a9c
	chmod 644 "$R/usr/share/nftables.d/chain-pre/forward/50-byetube.nft"
	mkdir -p "$R/usr/share/rpcd/acl.d"
	cat > "$R/usr/share/rpcd/acl.d/luci-app-byetube.json" <<'BT_FILE_END_7f3a9c'
{
	"luci-app-byetube": {
		"description": "ByeTube",
		"read": {
			"file": {
				"/opt/ByeTube/bin/byetube": [ "exec" ],
				"/etc/init.d/byetube": [ "exec" ]
			},
			"uci": [ "byetube" ]
		},
		"write": {
			"uci": [ "byetube" ]
		}
	}
}
BT_FILE_END_7f3a9c
	chmod 644 "$R/usr/share/rpcd/acl.d/luci-app-byetube.json"
	mkdir -p "$R/www/luci-static/resources/byetube"
	cat > "$R/www/luci-static/resources/byetube/common.js" <<'BT_FILE_END_7f3a9c'
'use strict';
'require baseclass';
'require fs';

var CLI = '/opt/ByeTube/bin/byetube';

function callJson(args) {
	return fs.exec(CLI, args).then(function(r) {
		var out = (r.stdout || '').trim();
		try { return JSON.parse(out); }
		catch (e) { return { error: out || r.stderr || 'нет ответа' }; }
	}).catch(function(e) { return { error: e.message }; });
}

function callText(args) {
	return fs.exec(CLI, args).then(function(r) { return r.stdout || ''; })
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
	l.href = L.resource('view/byetube/style.css');
	document.head.appendChild(l);
}

function badge(ok, textOk, textBad) {
	var cls = ok ? 'zm-ok' : 'zm-bad';
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
	config: function() { return callJson([ 'config', 'get' ]); },
	configSet: function(pairs) {
		var a = [ 'config', 'set' ];
		Object.keys(pairs).forEach(function(k) { a.push(k, String(pairs[k])); });
		return callJson(a);
	},
	service: function(action) { return callJson([ 'service', action ]); },
	flush: function() { return callJson([ 'flush' ]); },
	setStrategy: function(opts) { return callJson([ 'set-strategy', opts ]); },
	listGet: function(kind) { return callText([ 'list', 'get', kind ]); },
	listSet: function(kind, text) { return callJson([ 'list', 'set', kind, text ]); },
	listReset: function(kind) { return callJson([ 'list', 'reset', kind ]); },
	testStatus: function() { return callJson([ 'test', 'status' ]); },
	testStart: function() { return callJson([ 'test', 'start' ]); },
	testStop: function() { return callJson([ 'test', 'stop' ]); },
	testClear: function() { return callJson([ 'test', 'clear' ]); },
	testLog: function() { return callText([ 'test', 'log' ]); },
	testResults: function() { return callText([ 'test', 'results' ]); }
});
BT_FILE_END_7f3a9c
	chmod 644 "$R/www/luci-static/resources/byetube/common.js"
	mkdir -p "$R/www/luci-static/resources/byetube"
	cat > "$R/www/luci-static/resources/byetube/presets.js" <<'BT_FILE_END_7f3a9c'
'use strict';
'require baseclass';

var LIST = [
	{
		id: 'p1',
		label: 'Стратегия 1',
		name: 'Стратегия 1',
		opts: '-d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -S -a1'
	},
	{
		id: 'p2',
		label: 'Стратегия 2',
		name: 'Стратегия 2',
		opts: '-d1 -s1+s -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -a1'
	},
	{
		id: 'p3',
		label: 'Стратегия 3',
		name: 'Стратегия 3',
		opts: '-d1 -s1+s -d1+s -s3+s -d6+s -s12+s -d14+s -s20+s -d24+s -s30+s -a1'
	},
	{
		id: 'p4',
		label: 'Стратегия 4',
		name: 'Стратегия 4',
		opts: '-d1 -s1+s -s3+s -s6+s -s9+s -s12+s -s15+s -s20+s -s30+s -a1'
	},
	{
		id: 'p5',
		label: 'Стратегия 5',
		name: 'Стратегия 5',
		opts: '-d1 -s4 -d8 -s1+s -d5+s -s10+s -d20+s -a1'
	},
	{
		id: 'p6',
		label: 'Стратегия 6',
		name: 'Стратегия 6',
		opts: '-o1 -r-5+se -a1 -At,r,s -d1 -n "google.com" -Qr -f-1 -a1'
	},
	{
		id: 'p7',
		label: 'Стратегия 7',
		name: 'Стратегия 7',
		opts: '-f-1 -n "google.com" -Qr -s2+s -r3 -o20 -t4 -a1'
	},
	{
		id: 'p8',
		label: 'Стратегия 8',
		name: 'Стратегия 8',
		opts: '-f64+se -n "google.com" -t5 -a1'
	},
	{
		id: 'p9',
		label: 'Стратегия 9',
		name: 'Стратегия 9',
		opts: '-o1 -r-5+se -a1'
	},
	{
		id: 'p10',
		label: 'Стратегия 10',
		name: 'Стратегия 10',
		opts: '-o1 -a1 -r-5+se'
	}
];

function clean(s) {
	return String(s == null ? '' : s).replace(/["']/g, '').replace(/\s+/g, ' ').trim();
}

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
BT_FILE_END_7f3a9c
	chmod 644 "$R/www/luci-static/resources/byetube/presets.js"
	mkdir -p "$R/www/luci-static/resources/view/byetube"
	cat > "$R/www/luci-static/resources/view/byetube/main.js" <<'BT_FILE_END_7f3a9c'
'use strict';
'require view';
'require poll';
'require byetube.common as bt';
'require byetube.presets as presets';

var TABS = [
	{ id: 'main', label: 'ByeTube' },
	{ id: 'strategy', label: 'Стратегия' },
	{ id: 'test', label: 'Тест стратегий' },
	{ id: 'domains', label: 'Домены' }
];

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

return view.extend({
	load: function() {
		bt.injectCss();
		return Promise.all([
			bt.status(),
			bt.config(),
			bt.testStatus(),
			bt.listGet('youtube'),
			bt.listGet('extra'),
			bt.listGet('strategies'),
			bt.listGet('test-domains')
		]);
	},

	render: function(all) {
		var st = all[0] || {};
		var cfg = all[1] || {};
		var tst = all[2] || {};
		var texts = { 'youtube': all[3] || '', 'extra': all[4] || '', 'strategies': all[5] || '', 'test-domains': all[6] || '' };
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

		function refreshState() {
			return Promise.all([ bt.status(), bt.config() ]).then(function(r) {
				if (r[0] && !r[0].error) st = r[0];
				if (r[1] && !r[1].error) cfg = r[1];
				renderMain();
				renderStrategy();
				renderDomainsToggle();
				renderResults(resultsText);
				syncEditors();
			});
		}

		function applyConfig(pairs, okMsg) {
			if (guard()) return;
			busy = true;
			bt.toast('Применяем настройки', 'warning');
			bt.configSet(pairs).then(function(res) {
				if (res.error) {
					busy = false;
					bt.toast(res.error, 'error');
					return null;
				}
				return bt.service('restart').then(function() {
					busy = false;
					bt.toast(okMsg || 'Настройки применены', 'info');
					return refreshState();
				});
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
			items.push(row('Интерфейс byetube0', bt.badge(st.tun, 'поднят', 'нет')));
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
				st.enabled
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
				})
			]));
			fill(statusCard, kids);

			var quic = cfg.quic || 'block';
			if (!portDirty) portInput.value = String(cfg.byedpi_port || 1088);
			var ipv6Row;
			if (cfg.ipv6_supported === false)
				ipv6Row = row('IPv6', bt.badge(false, '', 'нет IPv6 на роутере'));
			else
				ipv6Row = row('IPv6', E('div', { 'class': 'zm-grid' }, [
					tile(cfg.ipv6 ? 'IPv6 включён' : 'IPv6 выключен', cfg.ipv6 ? 'zm-active' : 'zm-tile-off', function() {
						applyConfig({ ipv6: cfg.ipv6 ? 0 : 1 }, cfg.ipv6 ? 'IPv6 выключен' : 'IPv6 включён');
					})
				]));

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
				ipv6Row,
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
					return tile(p.label, cur && cur.id === p.id ? 'zm-active' : '', function() {
						setStrategy(p.opts, p.label);
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
			var resetBtn = o.resetLabel ? btn(o.resetLabel, '', onReset) : null;

			ed.node = E('div', { 'class': 'zm-card' }, [
				E('h3', {}, [ o.title ]),
				hint(o.hint),
				ta,
				meta,
				E('div', { 'class': 'zm-actions' }, resetBtn ? [ saveBtn, resetBtn ] : [ saveBtn ])
			]);

			ed.sync = function() {
				var info = o.info();
				fill(meta, [ o.meta(info) ]);
				ta.disabled = ed.locked;
				saveBtn.disabled = ed.locked;
				if (resetBtn) resetBtn.disabled = ed.locked || !info.custom;
			};

			function reload() {
				return bt.listGet(o.kind).then(function(t) {
					texts[o.kind] = t;
					ta.value = t;
				});
			}

			function tail(res) {
				if (!o.dns) return '';
				return res.applied ? '. DNS обновлён' : '. Применится при включении службы';
			}

			function onSave() {
				if (!ta.value.trim() && !o.allowEmpty) {
					bt.toast('Список пуст. Чтобы вернуть встроенный, нажмите «' + (o.resetLabel || 'Восстановить') + '».', 'error');
					return;
				}
				bt.listSet(o.kind, ta.value).then(function(res) {
					if (res.error) { bt.toast(res.error, 'error'); return; }
					o.apply(res);
					reload().then(function() {
						ed.sync();
						bt.toast('Список сохранён' + tail(res), 'info');
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
						bt.toast('Возвращён встроенный список' + tail(res), 'info');
					});
				});
			}

			return ed;
		}

		function syncEditors() {
			Object.keys(editors).forEach(function(k) { editors[k].sync(); });
		}

		function listMeta(unit) {
			return function(info) {
				return (info.custom ? 'Свой список' : 'Встроенный список') + ' · ' + info.count + ' ' + unit;
			};
		}

		editors['youtube'] = makeEditor({
			kind: 'youtube', title: 'Список доменов YouTube', height: 300, wrap: false, dns: true,
			hint: 'Для этих доменов трафик идёт через обход. Один домен в строке, поддомены подхватываются автоматически, можно вставлять ссылки. Вложенные записи (i.ytimg.com при наличии ytimg.com) отбрасываются сами.',
			resetLabel: 'Восстановить встроенный',
			info: function() { return { count: st.youtube_count || 0, custom: !!st.youtube_custom }; },
			meta: listMeta('доменов'),
			apply: function(res) { st.youtube_count = res.count; st.youtube_custom = res.custom; }
		});
		editors['extra'] = makeEditor({
			kind: 'extra', title: 'Дополнительные домены', height: 130, wrap: false, dns: true, allowEmpty: true,
			hint: 'Добавляются к списку выше. Один домен в строке; пустое поле — без дополнительных доменов.',
			info: function() { return { count: st.extra_count || 0, custom: (st.extra_count || 0) > 0 }; },
			meta: function(info) { return 'Дополнительных доменов: ' + info.count; },
			apply: function(res) { st.extra_count = res.count; }
		});
		editors['strategies'] = makeEditor({
			kind: 'strategies', title: 'Стратегии для теста', height: 260, wrap: true,
			hint: 'Одна стратегия (параметры ciadpi) в строке. Строки, начинающиеся с #, — комментарии.',
			resetLabel: 'Сбросить к встроенному',
			info: function() { return { count: tst.strategies || 0, custom: !!tst.strategies_custom }; },
			meta: listMeta('стратегий'),
			apply: function(res) { tst.strategies = res.count; tst.strategies_custom = res.custom; }
		});
		editors['test-domains'] = makeEditor({
			kind: 'test-domains', title: 'Домены для проверки', height: 220, wrap: false,
			hint: 'Один домен в строке; можно вставлять ссылки. Нужны только для проверки доступности при тесте и на маршрутизацию не влияют.',
			resetLabel: 'Сбросить к встроенному',
			info: function() { return { count: tst.test_domains || 0, custom: !!tst.test_domains_custom }; },
			meta: listMeta('доменов'),
			apply: function(res) { tst.test_domains = res.count; tst.test_domains_custom = res.custom; }
		});

		function renderDomainsToggle() {
			var on = cfg.default_domains !== false;
			fill(domainsToggleCard, [
				E('h3', {}, [ 'Домены YouTube' ]),
				row('Использовать список', E('div', { 'class': 'zm-grid' }, [
					tile(on ? 'Список используется' : 'Список выключен', on ? 'zm-active' : 'zm-tile-off', function() {
						applyConfig({ default_domains: on ? 0 : 1 }, on ? 'Список выключен' : 'Список включён');
					})
				])),
				hint('Сервисы Google часто делят IP-адреса, поэтому часть трафика Google (не только YouTube) тоже пойдёт через обход, а QUIC (UDP/443) к этим адресам будет блокироваться.')
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
			editors['test-domains'].locked = running;
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
							if (confirm(q)) setStrategy(r.opts, p ? p.label : 'Стратегия');
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
		panels['test'].appendChild(editors['test-domains'].node);

		panels['domains'].appendChild(domainsToggleCard);
		panels['domains'].appendChild(editors['youtube'].node);
		panels['domains'].appendChild(editors['extra'].node);

		wrap.appendChild(E('div', { 'class': 'zm-header' }, [
			E('h2', {}, [ 'ByeTube' ]),
			E('span', { 'class': 'zm-header-by' }, [ 'by StressOzz' ])
		]));
		wrap.appendChild(tabBar);
		TABS.forEach(function(t) { wrap.appendChild(panels[t.id]); });

		renderTabBar();
		renderMain();
		renderStrategy();
		renderDomainsToggle();
		renderTestActions();
		refreshLog();
		if (running) renderResults('');
		else refreshResults();

		poll.add(function() {
			return Promise.all([ refreshState(), tick() ]);
		}, 5);

		return wrap;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
BT_FILE_END_7f3a9c
	chmod 644 "$R/www/luci-static/resources/view/byetube/main.js"
	mkdir -p "$R/www/luci-static/resources/view/byetube"
	cat > "$R/www/luci-static/resources/view/byetube/style.css" <<'BT_FILE_END_7f3a9c'
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
	.bt-col .zm-row { justify-content: space-between; }
	.bt-col .zm-label { flex: 0 1 auto; }
	.bt-col .zm-row > :last-child { margin-left: auto; }
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
BT_FILE_END_7f3a9c
	chmod 644 "$R/www/luci-static/resources/view/byetube/style.css"
	mkdir -p "$R$BT_DIR/custom"
}

migrate_legacy() {
	local f
	if [ ! -e "$R/etc/config/ytbypass" ] && [ ! -e "$R/etc/init.d/ytbypass" ] \
		&& [ ! -d "$R/usr/libexec/ytbypass" ] && [ ! -e "$R/usr/bin/ytbypass" ]; then
		return 0
	fi
	LEGACY=1
	if [ -f "$R/etc/config/ytbypass" ] && [ ! -f "$R/etc/config/byetube" ]; then
		mkdir -p "$R/etc/config"
		sed 's/^config ytbypass\([[:space:]]\)/config byetube\1/' "$R/etc/config/ytbypass" > "$R/etc/config/byetube"
	fi
	for f in strategies.txt test-domains.txt; do
		if [ -s "$R/etc/ytbypass/$f" ] && [ ! -e "$R$BT_DIR/custom/$f" ]; then
			mkdir -p "$R$BT_DIR/custom"
			cp "$R/etc/ytbypass/$f" "$R$BT_DIR/custom/$f"
		fi
	done
	return 0
}

finish_legacy() {
	[ "$LEGACY" = 1 ] || return 0
	run_uninstall --legacy >/dev/null 2>&1
}

update_default_strategy() {
	local old new cur
	old='--split 1 --disorder 3+s --mod-http=h,d --auto=torst --tlsrec 1+s'
	new='-d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -S -a1'
	cur=$(uci -q get byetube.main.byedpi_opts)
	if [ "$cur" = "$old" ]; then
		uci set byetube.main.byedpi_opts="$new" && uci commit byetube
	fi
}

verify_running() {
	local ST
	ST=$("$BT_DIR/bin/byetube" status 2>/dev/null)
	case "$ST" in *'"enabled":true'*) ;; *) return 0 ;; esac
	case "$ST" in *'"byedpi":true'*'"hev":true'*'"tun":true'*) return 0 ;; esac
	return 1
}

main() {
	local p
	parse_args "$@"

	[ "$(id -u)" = "0" ] || die "нужны права root"
	[ -f /etc/openwrt_release ] || die "это не OpenWrt"
	. /etc/openwrt_release
	ARCH="$DISTRIB_ARCH"
	REL_MM=$(echo "$DISTRIB_RELEASE" | cut -d. -f1,2)

	if command -v apk >/dev/null 2>&1; then
		PM=apk;  EXT=apk
	elif command -v opkg >/dev/null 2>&1; then
		PM=opkg; EXT=ipk
	else
		die "не найден ни apk, ни opkg"
	fi

	[ "$MODE" = install ] || do_uninstall

	echo -e "\n${MAGENTA}Устанавливаем ByeTube${NC}"

	command -v fw4 >/dev/null 2>&1 || die "нужен firewall4 (OpenWrt 22.03+); hev-socks5-tunnel в пакетах — с 24.10"
	command -v nft >/dev/null 2>&1 || die "не найден nft"

	if ip rule add pref 8999 fwmark 0x10000/0x10000 lookup 89 2>/dev/null; then
		ip rule del pref 8999 2>/dev/null
	else
		die "ваш ip не поддерживает fwmark с маской. Установите ip-full: замените ip-tiny на ip-full и запустите установщик снова"
	fi

	if [ "$PM" = apk ]; then apk update >/dev/null 2>&1; else opkg update >/dev/null 2>&1; fi

	pkg_has kmod-tun || pkg_add kmod-tun || die "kmod-tun не установлен"
	ensure_dnsmasq_full

	if ! pkg_has hev-socks5-tunnel; then
		pkg_add hev-socks5-tunnel || die "hev-socks5-tunnel не найден в репозитории (есть в feeds OpenWrt 24.10+)"
		NEW_HEV=1
	fi
	install_byedpi

	for p in ca-bundle curl; do
		pkg_has "$p" || pkg_add "$p"
	done

	if [ "$NEW_BYEDPI" = 1 ] && [ -x /etc/init.d/byedpi ]; then
		/etc/init.d/byedpi stop >/dev/null 2>&1; /etc/init.d/byedpi disable >/dev/null 2>&1
	fi
	if [ "$NEW_HEV" = 1 ] && [ -x /etc/init.d/hev-socks5-tunnel ]; then
		/etc/init.d/hev-socks5-tunnel stop >/dev/null 2>&1; /etc/init.d/hev-socks5-tunnel disable >/dev/null 2>&1
	fi

	migrate_legacy
	install_payload
	finish_legacy
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
	/etc/init.d/rpcd reload >/dev/null 2>&1

	update_default_strategy
	/etc/init.d/byetube enable >/dev/null 2>&1

	if [ "$NOSTART" != 1 ]; then
		/etc/init.d/byetube restart >/dev/null 2>&1
		sleep 4
		verify_running || die "ByeTube установлен, но служба не запустилась. Смотрите: logread -e byetube"
	fi

	echo -e "ByeTube ${GREEN}установлен!${NC}\n"
}

[ -n "${BT_LIB_ONLY:-}" ] || main "$@"
