
#!/bin/sh
# ==========================================
# ByeDPI & Podkop Manager by StressOzz
# ==========================================

# Цвета
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
NC="\033[0m"
WHITE="\033[1;37m"
BLUE="\033[0;34m"
GRAY='\033[38;5;239m'
DGRAY='\033[38;5;236m'

WORKDIR="/tmp/byedpi"

# ==========================================
# Функция проверки и установки curl
# ==========================================
curl_install() {
    command -v curl >/dev/null 2>&1 || {
		clear 
		echo -e ""
        echo -e "${CYAN}Устанавливаем${NC} ${WHITE}curl ${CYAN}для загрузки информации с ${WHITE}GitHub${NC}"
		echo -e ""
        opkg update >/dev/null 2>&1
        opkg install curl >/dev/null 2>&1
    }
}

# ==========================================
# Определение версий
# ==========================================
get_versions() {
    # --- ByeDPI ---
    BYEDPI_VER=$(opkg list-installed | grep '^byedpi ' | awk '{print $3}' | sed 's/-r[0-9]\+$//')
    [ -z "$BYEDPI_VER" ] && BYEDPI_VER="не найдена"

    LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)
    [ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v "noarch" | tail -n1 | awk '{print $2}')

	curl_install

    # --- Получаем последнюю версию ByeDPI ---
    BYEDPI_API_URL="https://api.github.com/repos/DPITrickster/ByeDPI-OpenWrt/releases"
    RELEASE_DATA=$(curl -s "$BYEDPI_API_URL")
    BYEDPI_URL=$(echo "$RELEASE_DATA" | grep browser_download_url | grep "$LOCAL_ARCH.ipk" | head -n1 | cut -d'"' -f4)
    if [ -n "$BYEDPI_URL" ]; then
        BYEDPI_FILE=$(basename "$BYEDPI_URL")
        BYEDPI_LATEST_VER=$(echo "$BYEDPI_FILE" | sed -E 's/^byedpi_([0-9]+\.[0-9]+\.[0-9]+)(-r[0-9]+)?_.*/\1/')
        LATEST_VER="$BYEDPI_LATEST_VER"      # добавляем для install_update
        LATEST_URL="$BYEDPI_URL"            # добавляем для install_update
        LATEST_FILE="$BYEDPI_FILE"          # добавляем для install_update
    else
        BYEDPI_LATEST_VER="не найдена"
        LATEST_VER=""
        LATEST_URL=""
        LATEST_FILE=""
    fi

    # --- Podkop ---
    if command -v podkop >/dev/null 2>&1; then
        PODKOP_VER=$(podkop show_version 2>/dev/null | sed 's/-r[0-9]\+$//')
        [ -z "$PODKOP_VER" ] && PODKOP_VER="не найдена"
    else
        PODKOP_VER="не установлен"
    fi

    PODKOP_API_URL="https://api.github.com/repos/itdoginfo/podkop/releases/latest"
    PODKOP_LATEST_VER=$(curl -s "$PODKOP_API_URL" | grep '"tag_name"' | head -n1 | cut -d'"' -f4 | sed 's/-r[0-9]\+$//')
    [ -z "$PODKOP_LATEST_VER" ] && PODKOP_LATEST_VER="не найдена"

    # --- Нормализация версий ---
    PODKOP_VER=$(echo "$PODKOP_VER" | sed 's/^v//')
    PODKOP_LATEST_VER=$(echo "$PODKOP_LATEST_VER" | sed 's/^v//')
    BYEDPI_VER=$(echo "$BYEDPI_VER" | sed 's/^v//')
    BYEDPI_LATEST_VER=$(echo "$BYEDPI_LATEST_VER" | sed 's/^v//')
}

# ==========================================
# Проверка версии Podkop с подсветкой
# ==========================================
check_podkop_status() {
    if [ "$PODKOP_VER" = "не найдена" ] || [ "$PODKOP_VER" = "не установлен" ]; then
        PODKOP_STATUS="${RED}$PODKOP_VER${NC}"
    elif [ "$PODKOP_LATEST_VER" != "не найдена" ] && [ "$PODKOP_VER" != "$PODKOP_LATEST_VER" ]; then
        PODKOP_STATUS="${RED}$PODKOP_VER${NC}"
    else
        PODKOP_STATUS="${GREEN}$PODKOP_VER${NC}"
    fi
}

# ==========================================
# Проверка версии ByeDPI с подсветкой
# ==========================================
check_byedpi_status() {
    if [ "$BYEDPI_VER" = "не найдена" ] || [ "$BYEDPI_VER" = "не установлен" ]; then
        BYEDPI_STATUS="${RED}$BYEDPI_VER${NC}"
    elif [ "$BYEDPI_LATEST_VER" != "не найдена" ] && [ "$BYEDPI_VER" != "$BYEDPI_LATEST_VER" ]; then
        BYEDPI_STATUS="${RED}$BYEDPI_VER${NC}"
    else
        BYEDPI_STATUS="${GREEN}$BYEDPI_VER${NC}"
    fi
}



# ==========================================
# Установка / обновление ByeDPI
# ==========================================
install_update() {
    clear
	echo -e ""
    echo -e "${MAGENTA}Установка / обновление ByeDPI${NC}"
    get_versions

    [ -z "$LATEST_URL" ] && {
        echo -e ""
		echo -e "${RED}Последняя версия ByeDPI не найдена. Установка пропущена.${NC}"
        echo -e ""
		read -p "Нажмите Enter..." dummy
        return
    }

    echo -e ""
	echo -e "${GREEN}Скачиваем ${NC}${WHITE}$LATEST_FILE${NC}"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR" || return
    curl -L -s -o "$LATEST_FILE" "$LATEST_URL" || {
        echo -e "${RED}Ошибка загрузки ${NC}$LATEST_FILE"
        read -p "Нажмите Enter..." dummy
        return
    }

	echo -e "${GREEN}Устанавливаем${NC} ${WHITE}$LATEST_FILE${NC}"
    opkg install --force-reinstall "$LATEST_FILE" >/dev/null 2>&1
    rm -rf "$WORKDIR"
	echo -e ""
	/etc/init.d/byedpi enable >/dev/null 2>&1
    /etc/init.d/byedpi start >/dev/null 2>&1
    echo -e "ByeDPI ${GREEN}успешно установлен!${NC}"
	echo -e ""
    read -p "Нажмите Enter..." dummy
}

# ==========================================
# Удаление ByeDPI
# ==========================================
uninstall_byedpi() {
    clear
	echo -e ""
    echo -e "${MAGENTA}Удаление ByeDPI${NC}"
    [ -f /etc/init.d/byedpi ] && {
        /etc/init.d/byedpi stop >/dev/null 2>&1
        /etc/init.d/byedpi disable >/dev/null 2>&1
    }
    opkg remove --force-removal-of-dependent-packages byedpi >/dev/null 2>&1
    rm -rf /etc/init.d/byedpi /opt/byedpi /etc/config/byedpi
	echo -e ""
    echo -e "${GREEN}ByeDPI удалён полностью.${NC}"
	echo -e ""
    read -p "Нажмите Enter..." dummy
}

# ==========================================
# Установка / обновление Podkop
# ==========================================
install_podkop() {
    clear
    echo -e ""
    echo -e "${MAGENTA}Установка / обновление Podkop${NC}"
    echo -e ""

    REPO="https://api.github.com/repos/itdoginfo/podkop/releases/latest"
    DOWNLOAD_DIR="/tmp/podkop"

    PKG_IS_APK=0
    command -v apk >/dev/null 2>&1 && PKG_IS_APK=1

    rm -rf "$DOWNLOAD_DIR"
    mkdir -p "$DOWNLOAD_DIR"

    msg() {
        if [ -n "$2" ]; then
            printf "\033[32;1m%s \033[37;1m%s\033[0m\n" "$1" "$2"
        else
            printf "\033[32;1m%s\033[0m\n" "$1"
        fi
    }

    pkg_is_installed () {
        local pkg_name="$1"
        if [ "$PKG_IS_APK" -eq 1 ]; then
            apk list --installed | grep -q "$pkg_name"
        else
            opkg list-installed | grep -q "$pkg_name"
        fi
    }

    pkg_remove() {
        local pkg_name="$1"
        msg "Удаляем" "$pkg_name..."
        if [ "$PKG_IS_APK" -eq 1 ]; then
            apk del "$pkg_name" >/dev/null 2>&1
        else
            opkg remove --force-depends "$pkg_name" >/dev/null 2>&1
        fi
    }

    pkg_list_update() {
        msg "Обновляем список пакетов..."
        if [ "$PKG_IS_APK" -eq 1 ]; then
            apk update >/dev/null 2>&1
        else
            opkg update >/dev/null 2>&1
        fi
    }

    pkg_install() {
        local pkg_file="$1"
        msg "Устанавливаем" "$(basename "$pkg_file")"
        if [ "$PKG_IS_APK" -eq 1 ]; then
            apk add --allow-untrusted "$pkg_file" >/dev/null 2>&1
        else
            opkg install "$pkg_file" >/dev/null 2>&1
        fi
    }

    # Проверка системы
    MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "не определено")
    AVAILABLE_SPACE=$(df /overlay | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=26000
	
[ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ] && { 
    msg "Недостаточно свободного места"
    echo ""
    read -p "Нажмите Enter..." dummy
    return
}

nslookup google.com >/dev/null 2>&1 || { 
    msg "DNS не работает"
    echo ""
    read -p "Нажмите Enter..." dummy
    return
}


    if pkg_is_installed https-dns-proxy; then
        msg "Обнаружен конфликтный пакет" "https-dns-proxy. Удаляем..."
        pkg_remove luci-app-https-dns-proxy
        pkg_remove https-dns-proxy
        pkg_remove luci-i18n-https-dns-proxy*
    fi

    # Проверка sing-box
    if pkg_is_installed "^sing-box"; then
        sing_box_version=$(sing-box version | head -n 1 | awk '{print $3}')
        required_version="1.12.4"
        if [ "$(echo -e "$sing_box_version\n$required_version" | sort -V | head -n 1)" != "$required_version" ]; then
            msg "sing-box устарел. Удаляем..."
            service podkop stop >/dev/null 2>&1
            pkg_remove sing-box
        fi
    fi

    /usr/sbin/ntpd -q -p 194.190.168.1 -p 216.239.35.0 -p 216.239.35.4 -p 162.159.200.1 -p 162.159.200.123 >/dev/null 2>&1

pkg_list_update || { 
    msg "Не удалось обновить список пакетов"
    echo ""
    read -p "Нажмите Enter..." dummy
    return
}

    # Проверка GitHub API
    if command -v curl >/dev/null 2>&1; then
        check_response=$(curl -s "$REPO")
        if echo "$check_response" | grep -q 'API rate limit '; then
			echo ""
            echo -e "${RED}Превышен лимит запросов GitHub. Повторите позже.${NC}"
			echo ""
            read -p "Нажмите Enter..." dummy
            return
        fi
    fi

    # Шаблон скачивания
    if [ "$PKG_IS_APK" -eq 1 ]; then
        grep_url_pattern='https://[^"[:space:]]*\.apk'
    else
        grep_url_pattern='https://[^"[:space:]]*\.ipk'
    fi

    download_success=0
    urls=$(wget -qO- "$REPO" 2>/dev/null | grep -o "$grep_url_pattern")
    for url in $urls; do
        filename=$(basename "$url")
        filepath="$DOWNLOAD_DIR/$filename"
        msg "Скачиваем" "$filename"
        if wget -q -O "$filepath" "$url" >/dev/null 2>&1 && [ -s "$filepath" ]; then
            download_success=1
        else
            msg "Ошибка скачивания" "$filename"
        fi
    done

[ $download_success -eq 0 ] && { 
    msg "Нет успешно скачанных пакетов"
    echo ""
    read -p "Нажмите Enter..." dummy
    return
}

    # Установка пакетов
    for pkg in podkop luci-app-podkop; do
        file=$(ls "$DOWNLOAD_DIR" | grep "^$pkg" | head -n 1)
        [ -n "$file" ] && pkg_install "$DOWNLOAD_DIR/$file"
    done

    # Русский интерфейс
    ru=$(ls "$DOWNLOAD_DIR" | grep "luci-i18n-podkop-ru" | head -n 1)
    if [ -n "$ru" ]; then
        if pkg_is_installed luci-i18n-podkop-ru; then
            msg "Обновляем русский язык..." "$ru"
            pkg_remove luci-i18n-podkop* >/dev/null 2>&1
            pkg_install "$DOWNLOAD_DIR/$ru"
        else
            msg "Установить русский интерфейс? y/N"
            read -r RUS
            case "$RUS" in
                y|Y) pkg_install "$DOWNLOAD_DIR/$ru" ;;
                *) ;;
            esac
        fi
    fi

    # Очистка
    rm -rf "$DOWNLOAD_DIR"

    echo -e "Podkop ${GREEN}успешно установлен / обновлён!${NC}"
    echo -e ""
    read -p "Нажмите Enter..." dummy
}


# ==========================================
# Интеграция ByeDPI в Podkop
# ==========================================
integration_byedpi_podkop() {
    clear
	echo -e ""
    echo -e "${MAGENTA}Интеграция ByeDPI в Podkop${NC}"
	echo -e ""

	# Проверяем установлен ли ByeDPI
    if ! command -v byedpi >/dev/null 2>&1 && [ ! -f /etc/init.d/byedpi ]; then
		echo -e "${YELLOW}ByeDPI не установлен.${NC}"
		echo -e ""
        read -p "Нажмите Enter..." dummy
        return
    fi
	echo -e "${GREEN}Отключаем локальный ${NC}DNS${GREEN}...${NC}"
	uci set dhcp.@dnsmasq[0].localuse='0'
    uci commit dhcp
	echo -e "${GREEN}Перезапускаем ${NC}dnsmasq${GREEN}...${NC}"
	/etc/init.d/dnsmasq restart >/dev/null 2>&1

    # Меняем стратегию ByeDPI на интеграционную
	echo -e "${GREEN}Меняем стратегию ${NC}ByeDPI${GREEN} на рабочую...${NC}"
    if [ -f /etc/config/byedpi ]; then
        sed -i "s|option cmd_opts .*| option cmd_opts '-o2 --auto=t,r,a,s -d2'|" /etc/config/byedpi
    fi

    # Создаём / меняем /etc/config/podkop
    cat <<EOF >/etc/config/podkop
config main 'main'
	option mode 'proxy'
	option proxy_config_type 'outbound'
	option community_lists_enabled '1'
	option user_domain_list_type 'disabled'
	option local_domain_lists_enabled '0'
	option remote_domain_lists_enabled '0'
	option user_subnet_list_type 'disabled'
	option local_subnet_lists_enabled '0'
	option remote_subnet_lists_enabled '0'
	option all_traffic_from_ip_enabled '0'
	option exclude_from_ip_enabled '0'
	option yacd '0'
	option socks5 '0'
	option exclude_ntp '0'
	option quic_disable '0'
	option dont_touch_dhcp '0'
	option update_interval '1d'
	option dns_type 'udp'
	option dns_server '8.8.8.8'
	option dns_rewrite_ttl '60'
	option config_path '/etc/sing-box/config.json'
	option cache_path '/tmp/sing-box/cache.db'
	list iface 'br-lan'
	option mon_restart_ifaces '0'
	option ss_uot '0'
	option detour '0'
	option shutdown_correctly '0'
	option outbound_json '{
  "type": "socks",
  "server": "127.0.0.1",
  "server_port": 1080
}'
	option bootstrap_dns_server '77.88.8.8'
	list community_lists 'russia_inside'
	list community_lists 'hodca'
EOF

    echo -e "${GREEN}Запуск ${NC}ByeDPI${GREEN}...${NC}"
    /etc/init.d/byedpi enable >/dev/null 2>&1
    /etc/init.d/byedpi start >/dev/null 2>&1
	echo -e "${GREEN}Запуск ${NC}Podkop${GREEN}...${NC}"
    podkop enable >/dev/null 2>&1
    echo -e "${GREEN}Применяем конфигурацию...${NC}"
    podkop reload >/dev/null 2>&1
    echo -e "${GREEN}Перезапускаем сервис...${NC}"
    podkop restart >/dev/null 2>&1
    echo -e "${GREEN}Обновляем списки...${NC}"
    podkop list_update >/dev/null 2>&1
	echo -e ""
    echo -e "Podkop ${GREEN}готов к работе.${NC}"
	echo -e ""
    echo -e "ByeDPI ${GREEN}интегрирован в ${NC}Podkop${GREEN}.${NC}"
	echo -e ""
    echo -ne "Нужно ${RED}обязательно${NC} перезагрузить роутер. Перезагрузить сейчас? [y/N]: "
	echo -e ""
    read REBOOT_CHOICE
    case "$REBOOT_CHOICE" in
	y|Y)
		echo -e ""
        echo -e "${GREEN}Перезагрузка роутера...${NC}"
        sleep 1
        reboot
        ;;
    *) 
        echo -e "${YELLOW}Перезагрузка отложена.${NC}" 
        ;;
esac
echo -e ""
read -p "Нажмите Enter..." dummy
}

# ==========================================
# Изменение стратегии ByeDPI
# ==========================================
fix_strategy() {
    clear
    echo -e ""
    echo -e "${MAGENTA}Изменение стратегии ByeDPI${NC}"

    if [ -f /etc/config/byedpi ]; then
        # Получаем текущую стратегию
        CURRENT_STRATEGY=$(grep "option cmd_opts" /etc/config/byedpi | sed -E "s/.*'(.+)'/\1/")
        [ -z "$CURRENT_STRATEGY" ] && CURRENT_STRATEGY="(не задана)"
        echo -e ""
        echo -e "${GREEN}Текущая стратегия:${NC} ${WHITE}$CURRENT_STRATEGY${NC}"
        echo -e ""
        echo -ne "${YELLOW}Введите новую стратегию (Enter — оставить текущую):${NC} "
		read NEW_STRATEGY
        echo -e ""
        if [ -z "$NEW_STRATEGY" ]; then
            echo -e "${GREEN}Стратегия не изменена.${NC}"
        else
            sed -i "s|option cmd_opts .*| option cmd_opts '$NEW_STRATEGY'|" /etc/config/byedpi
			/etc/init.d/byedpi enable >/dev/null 2>&1
			/etc/init.d/byedpi start >/dev/null 2>&1
            echo -e "${GREEN}Стратегия изменена на:${NC} ${WHITE}$NEW_STRATEGY${NC}"
        fi
    else
		echo -e ""
        echo -e "${YELLOW}ByeDPI не установлен.${NC}"
    fi
    echo -e ""
    read -p "Нажмите Enter..." dummy
}

# ==========================================
# Удаление Podkop
# ==========================================
uninstall_podkop() {
    clear
    echo -e ""
    echo -e "${MAGENTA}Удаление Podkop${NC}"
    
    # Удаляем пакеты
    opkg remove luci-i18n-podkop-ru luci-app-podkop podkop --autoremove >/dev/null 2>&1 || true

    # Удаляем конфиги и временные папки
    rm -rf /etc/config/podkop /tmp/podkop_installer

    # Удаляем все файлы в /etc/config с именем содержащим podkop
    rm -f /etc/config/*podkop* >/dev/null 2>&1

    echo -e ""
    echo -e "${GREEN}Podkop удалён полностью.${NC}"
    echo -e ""
    read -p "Нажмите Enter..." dummy
}


# ==========================================
# Полная установка и интеграция
# ==========================================
full_install_integration() {
    install_update
    install_podkop
    integration_byedpi_podkop
}

# ==========================================
# Меню
# ==========================================
show_menu() {
    get_versions

# ==========================================	
# Получаем текущую стратегию ByeDPI
# ==========================================
if [ -f /etc/config/byedpi ]; then
    CURRENT_STRATEGY=$(grep "option cmd_opts" /etc/config/byedpi | sed -E "s/.*'(.+)'/\1/")
    [ -z "$CURRENT_STRATEGY" ] && CURRENT_STRATEGY="(не задана)"
else
    CURRENT_STRATEGY="не найдена"
fi
	clear
	echo -e ""
	echo -e "╔═══════════════════════════════╗"
	echo -e "║     ${BLUE}Podkop+ByeDPI Manager${NC}     ║"
	echo -e "╚═══════════════════════════════╝"
	echo -e "                             ${DGRAY}v2.1${NC}"

	check_podkop_status
	check_byedpi_status

	echo -e "${MAGENTA}--- ByeDPI ---${NC}"
	echo -e "${YELLOW}Установленная версия:${NC} $BYEDPI_STATUS"
	echo -e "${YELLOW}Последняя версия:${NC} ${CYAN}$BYEDPI_LATEST_VER${NC}"
	echo -e "${YELLOW}Текущая стратегия:${NC} ${WHITE}$CURRENT_STRATEGY${NC}"
	echo -e ""
	echo -e "${MAGENTA}--- Podkop ---${NC}"
	echo -e "${YELLOW}Установленная версия:${NC} $PODKOP_STATUS"
	echo -e "${YELLOW}Последняя версия:${NC} ${CYAN}$PODKOP_LATEST_VER${NC}"
	echo -e ""
	echo -e "${YELLOW}Архитектура устройства:${NC} $LOCAL_ARCH"
	echo -e ""
    echo -e "${CYAN}1) ${GREEN}Установить / обновить ${NC}ByeDPI"
    echo -e "${CYAN}2) ${GREEN}Удалить ${NC}ByeDPI"
    echo -e "${CYAN}3) ${GREEN}Интегрировать ${NC}ByeDPI ${GREEN}в ${NC}Podkop"
    echo -e "${CYAN}4) ${GREEN}Изменить текущую стратегию ${NC}ByeDPI"
    echo -e "${CYAN}5) ${GREEN}Установить / обновить ${NC}Podkop"
	echo -e "${CYAN}6) ${GREEN}Удалить ${NC}Podkop"
	echo -e "${CYAN}7) ${GREEN}Установить ${NC}ByeDPI ${GREEN}+ ${NC}Podkop ${GREEN}+ ${NC}Интеграция"
	echo -e "${CYAN}8) ${GREEN}Перезагрузить устройство${NC}"
	echo -e "${CYAN}9) ${GREEN}Выход (Enter)${NC}"
	echo -e ""
    echo -ne "${YELLOW}Выберите пункт:${NC} "
    read choice

    case "$choice" in
        1) install_update ;;
        2) uninstall_byedpi ;;
        3) integration_byedpi_podkop ;;
        4) fix_strategy ;;
        5) install_podkop ;;
		6) uninstall_podkop ;;
		7) full_install_integration ;;
		8) 
		echo -e ""
		echo -e "${RED}Перезагрузка${NC}"
		echo -e ""
        sleep 1
        reboot
		;;
        *) exit 0 ;;
    esac
}

# ==========================================
# Запуск
# ==========================================
while true; do
    show_menu
done
