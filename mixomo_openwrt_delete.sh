#!/bin/sh

SCRIPT_VERSION="v0.1.2-alpha"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()  { echo -e "${GREEN}=== $* ===${NC}"; }
log_done()  { echo -e "${GREEN}$*${NC}"; }

USE_APK=0
if command -v apk > /dev/null 2>&1; then
    USE_APK=1
fi

is_pkg_installed() {
    if [ "$USE_APK" -eq 1 ]; then
        apk info "$1" > /dev/null 2>&1
    else
        opkg list-installed 2>/dev/null | grep -q "^$1 "
    fi
}

remove_pkg() {
    if [ "$USE_APK" -eq 1 ]; then
        apk del "$1" > /dev/null 2>&1 || true
    else
        opkg remove "$1" > /dev/null 2>&1 || true
    fi
}

remove_mihomo() {
    log_info "Проверка наличия Mihomo..."
    local CLEANED=0

    if [ -f "/etc/init.d/mihomo" ]; then
        /etc/init.d/mihomo stop 2>/dev/null || true
        /etc/init.d/mihomo disable 2>/dev/null || true
        rm -f /etc/init.d/mihomo
        CLEANED=1
    fi

    if [ -f "/usr/bin/mihomo" ]; then
        rm -f /usr/bin/mihomo
        CLEANED=1
    fi

    if [ -d "/etc/mihomo" ] || [ -d "/www/luci-static/resources/view/mihomo" ]; then
        rm -rf /etc/mihomo
        rm -f /usr/share/luci/menu.d/luci-app-mihomo.json
        rm -f /usr/share/rpcd/acl.d/luci-app-mihomo.json
        rm -rf /www/luci-static/resources/view/mihomo
        CLEANED=1
    fi

    if [ "$CLEANED" -eq 1 ]; then
        log_done "Mihomo и его файлы успешно удалены."
    else
        log_done "Mihomo не найден (уже удалён)."
    fi
}

remove_hev_tunnel() {
    log_info "Проверка наличия Hev-Socks5-Tunnel..."
    local ACTION_TAKEN=0

    if [ -f "/etc/init.d/hev-socks5-tunnel" ]; then
        /etc/init.d/hev-socks5-tunnel stop 2>/dev/null || true
    fi

    if is_pkg_installed hev-socks5-tunnel; then
        remove_pkg hev-socks5-tunnel
        ACTION_TAKEN=1
    fi

    if [ -d "/etc/hev-socks5-tunnel" ] || [ -f "/etc/config/hev-socks5-tunnel" ]; then
        rm -rf /etc/hev-socks5-tunnel
        rm -f /etc/config/hev-socks5-tunnel
        ACTION_TAKEN=1
    fi

    echo "--> Очистка UCI..."
    uci delete network.Mihomo 2>/dev/null || true

    local fw_section
    for fw_section in $(uci show firewall 2>/dev/null \
            | grep -E "\.name='Mihomo'" \
            | sed "s/\.name.*//"); do
        uci delete "$fw_section" 2>/dev/null || true
    done

    for fw_section in $(uci show firewall 2>/dev/null \
            | grep -E "\.(src|dest)='Mihomo'" \
            | sed -E "s/\.(src|dest).*//"); do
        uci delete "$fw_section" 2>/dev/null || true
    done

    uci delete firewall.Mihomo 2>/dev/null || true
    uci delete firewall.lan_to_Mihomo 2>/dev/null || true

    uci commit network
    uci commit firewall

    /etc/init.d/network reload 2>/dev/null || true
    /etc/init.d/firewall restart 2>/dev/null || true

    if [ "$ACTION_TAKEN" -eq 1 ]; then
        log_done "Hev-Socks5-Tunnel и настройки удалены."
    else
        log_done "Hev-Socks5-Tunnel не найден (уже удалён)."
    fi
}

remove_magitrickle() {
    log_info "Проверка наличия MagiTrickle..."
    local PKG_REMOVED=0

    if [ -f "/etc/init.d/magitrickle" ]; then
        /etc/init.d/magitrickle stop 2>/dev/null || true
        /etc/init.d/magitrickle disable 2>/dev/null || true
    fi

    if is_pkg_installed magitrickle_mod; then
        log_info "Найден MagiTrickle Mod. Удаление..."
        remove_pkg magitrickle_mod
        PKG_REMOVED=1
    fi

    if is_pkg_installed magitrickle; then
        log_info "Найден MagiTrickle. Удаление..."
        remove_pkg magitrickle
        PKG_REMOVED=1
    fi

    local FILES_REMOVED=0
    if [ -d "/www/luci-static/resources/view/magitrickle" ] || \
       [ -f "/usr/share/luci/menu.d/luci-app-magitrickle.json" ]; then
        rm -rf /www/luci-static/resources/view/magitrickle
        rm -f /usr/share/luci/menu.d/luci-app-magitrickle.json
        FILES_REMOVED=1
    fi

    if [ -f "/etc/magitrickle/state/config.yaml" ]; then
        rm -f /etc/magitrickle/state/config.yaml
        rm -f /etc/magitrickle/state/config.yaml.backup
        FILES_REMOVED=1
    fi

    if [ "$PKG_REMOVED" -eq 1 ] || [ "$FILES_REMOVED" -eq 1 ]; then
        log_done "MagiTrickle и его файлы удалены."
    else
        log_done "MagiTrickle не найден (уже удалён)."
    fi
}

cleanup_system() {
    log_info "Очистка кэша и перезапуск служб..."
    rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/
    /etc/init.d/rpcd restart > /dev/null 2>&1 || true
    /etc/init.d/uhttpd restart > /dev/null 2>&1 || true
}

main() {
    clear
    log_done "Скрипт удаления Mixomo OpenWrt $SCRIPT_VERSION от Internet Helper"
    echo ""

    log_step "[1/4] Удаление Mihomo"
    remove_mihomo
    echo ""

    log_step "[2/4] Удаление Hev-Tunnel"
    remove_hev_tunnel
    echo ""

    log_step "[3/4] Удаление MagiTrickle"
    remove_magitrickle
    echo ""

    log_step "[4/4] Завершение"
    cleanup_system
    echo ""

    log_done "Удаление успешно завершено!"
}

main
