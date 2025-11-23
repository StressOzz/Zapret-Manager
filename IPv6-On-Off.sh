#!/bin/sh
# ==========================================
#  IPv6 TOGGLE MENU SCRIPT for OpenWRT 24+
# ==========================================

# Цвета
RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
BLUE="\033[0;34m"
RESET="\033[0m"

clear

# --- Меню ---
echo -e "${MAGENTA}  -==Управление IPv6 (OpenWRT)==-${RESET}"
echo -e "${GREEN}1) Включить IPv6${RESET}"
echo -e "${RED}2) Выключить IPv6 (жёстко)${RESET}"
echo -e "${CYAN}3) Выключить IPv6 (мягко)${RESET}"
echo -e "${YELLOW}Enter) Выход${RESET}"

echo -e ""
if ip -6 addr show | grep -q "inet6"; then
    IPV6_STATE="enabled"
    echo -e "${GREEN}🔴${RESET} IPv6 ${GREEN}включён.${RESET}"
else
    IPV6_STATE="disabled"
    echo -e "${RED}🔴${RESET} IPv6 ${RED}отключён.${RESET}"
fi
echo -e ""
echo -n -e "${YELLOW}Выберите опцию: ${RESET}"
read -r CHOICE

case "$CHOICE" in
    1)
        if [ "$IPV6_STATE" = "enabled" ]; then
            echo -e "${RED}🔴${RESET} IPv6 уже включён."
        else
            echo -e "${BLUE}🔴${RESET} Включаем IPv6..."

            uci set network.lan.ipv6='1'
            uci set network.wan.ipv6='1'
            uci set network.lan.delegate='1'

            uci set dhcp.lan.dhcpv6='server'
            uci set dhcp.lan.ra='server'

            uci delete dhcp.@dnsmasq[0].filter_aaaa 2>/dev/null

            uci commit network >/dev/null 2>&1
            uci commit dhcp >/dev/null 2>&1

            /etc/init.d/odhcpd enable
            /etc/init.d/odhcpd start

            sed -i '/^net.ipv6.conf.all.disable_ipv6=/d' /etc/sysctl.conf
            sed -i '/^net.ipv6.conf.default.disable_ipv6=/d' /etc/sysctl.conf
            sed -i '/^net.ipv6.conf.lo.disable_ipv6=/d' /etc/sysctl.conf
            sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1
            sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null 2>&1
            sysctl -w net.ipv6.conf.lo.disable_ipv6=0 >/dev/null 2>&1

            /etc/init.d/dnsmasq restart >/dev/null 2>&1
        fi
        ;;
    2)
        if [ "$IPV6_STATE" = "disabled" ]; then
            echo -e "${RED}🔴${RESET} IPv6 уже отключён."
        else
            echo -e "${BLUE}🔴${RESET} Отключаем IPv6 (жёстко)..."

            uci set network.lan.ipv6='0'
            uci set network.wan.ipv6='0'
            uci set network.lan.delegate='0'
            uci -q delete network.globals.ula_prefix

            uci set dhcp.lan.dhcpv6='disabled'
            uci set dhcp.lan.ra='disabled'
            uci -q delete dhcp.lan.dhcpv6
            uci -q delete dhcp.lan.ra

            uci set dhcp.@dnsmasq[0].filter_aaaa='1'

            uci commit network >/dev/null 2>&1
            uci commit dhcp >/dev/null 2>&1

            /etc/init.d/odhcpd stop >/dev/null 2>&1
            /etc/init.d/odhcpd disable >/dev/null 2>&1

            sed -i '/^net.ipv6.conf.all.disable_ipv6=/d' /etc/sysctl.conf
            sed -i '/^net.ipv6.conf.default.disable_ipv6=/d' /etc/sysctl.conf
            sed -i '/^net.ipv6.conf.lo.disable_ipv6=/d' /etc/sysctl.conf
            cat >> /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
            sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
            sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
            sysctl -w net.ipv6.conf.lo.disable_ipv6=1 >/dev/null 2>&1

            /etc/init.d/dnsmasq restart >/dev/null 2>&1
        fi
        ;;
    3)
        echo -e "${CYAN}🔵${RESET} Мягко отключаем IPv6..."

        uci set network.lan.ipv6='0'
        uci set network.wan.ipv6='0'
        uci set network.lan.delegate='0'
        uci -q delete network.globals.ula_prefix

        uci set dhcp.lan.dhcpv6='disabled'
        uci set dhcp.lan.ra='disabled'
        uci -q delete dhcp.lan.dhcpv6
        uci -q delete dhcp.lan.ra

        uci commit network >/dev/null 2>&1
        uci commit dhcp >/dev/null 2>&1

        /etc/init.d/odhcpd stop >/dev/null 2>&1
        /etc/init.d/odhcpd disable >/dev/null 2>&1

        echo -e "${GREEN}🔴${RESET} Интерфейсы IPv6 отключены, DNS и ядро оставлены нетронутыми."
        ;;
    *)  exit 0
        ;;
esac

# --- Проверка ---
echo -e "${BLUE}🔴${RESET} Проверяем IPv6 на интерфейсах роутера:"
if ip -6 addr show | grep -q "inet6"; then
    echo -e "${GREEN}🔴${RESET} IPv6 ${GREEN}включён.${RESET}"
else
    echo -e "${RED}🔴${RESET} IPv6 ${RED}отключён.${RESET}"
fi

echo -e "${BLUE}🔴${RESET} Скрипт завершён. Рекомендуется перезагрузка роутера."
