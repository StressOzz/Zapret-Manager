#!/bin/sh
# ==========================================
# Zapret on remittor Manager by StressOzz
# Скрипт для установки, обновления и полного удаления Zapret на OpenWRT
# ==========================================

# Цвета для вывода
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
BLUE="\033[0;34m"
NC="\033[0m"
GRAY="\033[38;5;239m"
DGRAY="\033[38;5;236m"

# Рабочая директория для скачивания и распаковки
WORKDIR="/tmp/zapret-update"
# ==========================================
# Функция получения информации о версиях, архитектуре и статусе
# ==========================================
get_versions() {
    INSTALLED_VER=$(opkg list-installed | grep '^zapret ' | awk '{print $3}')
    [ -z "$INSTALLED_VER" ] && INSTALLED_VER="не найдена"

    LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)
    [ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v "noarch" | sort -k3 -n | tail -n1 | awk '{print $2}')

    command -v curl >/dev/null 2>&1 || {
        clear
        echo -e ""
        echo -e "${MAGENTA}ZAPRET on remittor Manager by StressOzz${NC}"
        echo -e ""
        echo -e "${GREEN}🔴 ${CYAN}Устанавливаем${NC} curl ${CYAN}для загрузки информации с ${NC}GitHub"
        opkg update >/dev/null 2>&1
        opkg install curl >/dev/null 2>&1
    }

    # ===== Проверка лимита GitHub API =====
    LIMIT_REACHED=0
    LIMIT_CHECK=$(curl -s "https://api.github.com/repos/remittor/zapret-openwrt/releases/latest")
    if echo "$LIMIT_CHECK" | grep -q 'API rate limit exceeded'; then
        LATEST_VER="${RED}Достигнут лимит GitHub API. Подождите 15 минут.${NC}"
        LIMIT_REACHED=1
    else
        LATEST_URL=$(echo "$LIMIT_CHECK" | grep browser_download_url | grep "$LOCAL_ARCH.zip" | cut -d '"' -f 4)
        if [ -n "$LATEST_URL" ] && echo "$LATEST_URL" | grep -q '\.zip$'; then
            LATEST_FILE=$(basename "$LATEST_URL")
            LATEST_VER=$(echo "$LATEST_FILE" | sed -E 's/.*zapret_v([0-9]+\.[0-9]+)_.*\.zip/\1/')
            USED_ARCH="$LOCAL_ARCH"
        else
            LATEST_VER="не найдена"
            USED_ARCH="нет пакета для вашей архитектуры"
        fi
    fi

    # Предыдущая версия
    PREV_URL=$(curl -s https://api.github.com/repos/remittor/zapret-openwrt/releases \
        | grep browser_download_url | grep "$LOCAL_ARCH.zip" | sed -n '2p' | cut -d '"' -f 4)
    if [ -n "$PREV_URL" ] && echo "$PREV_URL" | grep -q '\.zip$'; then
        PREV_FILE=$(basename "$PREV_URL")
        PREV_VER=$(echo "$PREV_FILE" | sed -E 's/.*zapret_v([0-9]+\.[0-9]+)_.*\.zip/\1/')
    else
        PREV_VER="не найдена"
    fi

    # Статус службы
    if [ -f /etc/init.d/zapret ]; then
        if /etc/init.d/zapret status 2>/dev/null | grep -qi "running"; then
            ZAPRET_STATUS="${GREEN}запущен${NC}"
        else
            ZAPRET_STATUS="${RED}остановлен${NC}"
        fi
    else
        ZAPRET_STATUS=""
    fi
}


# ==========================================
# Установка Zapret
# ==========================================
install_update() {
    local NO_PAUSE=$1
    [ "$NO_PAUSE" != "1" ] && clear
    [ "$NO_PAUSE" != "1" ] && echo -e ""

    echo -e "${MAGENTA}Устанавливаем ZAPRET${NC}"
    echo -e ""

    get_versions

    # Проверка лимита API
    if [ "$LIMIT_REACHED" -eq 1 ]; then
        echo -e "$LATEST_VER"  # Покажет предупреждение
        echo -e ""
        [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
        return
    fi

    # Всегда последняя версия
    TARGET_URL="$LATEST_URL"
    TARGET_FILE="$LATEST_FILE"
    TARGET_VER="$LATEST_VER"

    [ "$USED_ARCH" = "нет пакета для вашей архитектуры" ] && {
        echo -e "${RED}Нет доступного пакета для вашей архитектуры: ${NC}$LOCAL_ARCH"
        echo -e ""
        read -p "Нажмите Enter для выхода в главное меню..." dummy
        return
    }

    if [ "$INSTALLED_VER" = "$TARGET_VER" ]; then
        echo -e "${BLUE}🔴 ${GREEN}Последняя версия уже установлена !${NC}"
        echo -e ""
        [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
        return
    fi

    if [ -f /etc/init.d/zapret ]; then
        echo -e "${GREEN}🔴 ${CYAN}Останавливаем сервис ${NC}zapret"
        /etc/init.d/zapret stop >/dev/null 2>&1
        PIDS=$(pgrep -f /opt/zapret)
        if [ -n "$PIDS" ]; then
            echo -e "${GREEN}🔴 ${CYAN}Убиваем все процессы ${NC}zapret"
            for pid in $PIDS; do kill -9 "$pid" >/dev/null 2>&1; done
        fi
    fi

    mkdir -p "$WORKDIR"
    rm -f "$WORKDIR"/* 2>/dev/null
    cd "$WORKDIR" || return

    echo -e "${GREEN}🔴 ${CYAN}Скачиваем архив ${NC}$TARGET_FILE"
    wget -q "$TARGET_URL" -O "$TARGET_FILE" || {
        echo -e "${RED}Не удалось скачать ${NC}$TARGET_FILE"
        [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
        return
    }

    command -v unzip >/dev/null 2>&1 || { 
        echo -e "${GREEN}🔴 ${CYAN}Устанавливаем${NC} unzip ${CYAN}для распаковки архива${NC}"
        opkg update >/dev/null 2>&1
        opkg install unzip >/dev/null 2>&1
    }

    echo -e "${GREEN}🔴 ${CYAN}Распаковываем архив${NC}"
    unzip -o "$TARGET_FILE" >/dev/null

    PIDS=$(pgrep -f /opt/zapret)
    if [ -n "$PIDS" ]; then
        echo -e "${GREEN}🔴 ${CYAN}Убиваем все процессы ${NC}zapret"
        for pid in $PIDS; do kill -9 "$pid" >/dev/null 2>&1; done
    fi

    for PKG in zapret_*.ipk luci-app-zapret_*.ipk; do
        [ -f "$PKG" ] && {
            echo -e "${GREEN}🔴 ${CYAN}Устанавливаем пакет ${NC}$PKG"
            opkg install --force-reinstall "$PKG" >/dev/null 2>&1
        }
    done

    echo -e "${GREEN}🔴 ${CYAN}Удаляем временные файлы и пакеты${NC}"
    cd /
    rm -rf "$WORKDIR"
    rm -f /tmp/*.ipk /tmp/*.zip /tmp/*zapret* 2>/dev/null

    [ -f /etc/init.d/zapret ] && {
        echo -e "${GREEN}🔴 ${CYAN}Перезапуск службы ${NC}zapret"
        chmod +x /opt/zapret/sync_config.sh
        /opt/zapret/sync_config.sh
        /etc/init.d/zapret restart >/dev/null 2>&1
    }

    echo -e ""
    echo -e "${BLUE}🔴 ${GREEN}Zapret успешно установлен !${NC}"
    echo -e ""
    [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}

# ==========================================
# Чиним дефолтную стратегию
# ==========================================
fix_default() {
local NO_PAUSE=$1
    [ "$NO_PAUSE" != "1" ] && clear
    [ "$NO_PAUSE" != "1" ] && echo -e ""
    echo -e "${MAGENTA}Редактируем стратегию по умолчанию${NC}"
    echo -e ""

# Проверка, установлен ли Zapret
    if [ ! -f /etc/init.d/zapret ]; then
        echo -e "${RED}Zapret не установлен !${NC}"
        [ "$NO_PAUSE" != "1" ] && echo -e ""
        [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
        return
    fi

# Убираем все вхождения fake,
	sed -i 's/fake,//g' /etc/config/zapret

# Удаляем конкретный блок строк
	sed -i '/--filter-tcp=80 <HOSTLIST>/,/--new/d' /etc/config/zapret
	
# Все --dpi-desync-repeats=11 заменены на 6
	sed -i 's/--dpi-desync-repeats=11/--dpi-desync-repeats=6/g' /etc/config/zapret

	chmod +x /opt/zapret/sync_config.sh
	/opt/zapret/sync_config.sh
	/etc/init.d/zapret restart >/dev/null 2>&1

    echo -e "${BLUE}🔴 ${GREEN}Стратегия по умолчанию отредактирована !${NC}"
    [ "$NO_PAUSE" != "1" ] &&echo -e ""
	[ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}

# ==========================================
# Включение Discord и звонков в TG и WA
# ==========================================
enable_discord_calls() {
    local NO_PAUSE=$1
    [ "$NO_PAUSE" != "1" ] && clear
    [ "$NO_PAUSE" != "1" ] && echo -e ""
    [ "$NO_PAUSE" != "1" ] && echo -e "${MAGENTA}Меню настройки Discord и звонков в TG/WA${NC}"
    [ "$NO_PAUSE" != "1" ] && echo -e ""

    if [ ! -f /etc/init.d/zapret ]; then
        echo -e "${RED}Zapret не установлен !${NC}"
        echo -e ""
        [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
        return
    fi

    CUSTOM_DIR="/opt/zapret/init.d/openwrt/custom.d/"
    CURRENT_SCRIPT="не установлен"
    if [ -f "$CUSTOM_DIR/50-script.sh" ]; then
        FIRST_LINE=$(sed -n '1p' "$CUSTOM_DIR/50-script.sh")
        if echo "$FIRST_LINE" | grep -q "QUIC"; then
            CURRENT_SCRIPT="50-quic4all"
        elif echo "$FIRST_LINE" | grep -q "stun"; then
            CURRENT_SCRIPT="50-stun4all"
        else
            CURRENT_SCRIPT="неизвестный"
        fi
    fi

    [ "$NO_PAUSE" != "1" ] && echo -e "${YELLOW}Установленный скрипт:${NC} $CURRENT_SCRIPT"
    [ "$NO_PAUSE" != "1" ] && echo -e ""

    if [ "$NO_PAUSE" = "1" ]; then
        SELECTED="50-stun4all"
        URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all"
    else
        echo -e "${CYAN}1) ${GREEN}Установить скрипт ${NC}50-stun4all"
        echo -e "${CYAN}2) ${GREEN}Установить скрипт ${NC}50-quic4all"
        echo -e "${CYAN}3) ${GREEN}Удалить скрипт${NC}"
        echo -e "${CYAN}0) ${GREEN}Выход в главное меню (Enter)${NC}"
        echo -e ""
        echo -ne "${YELLOW}Выберите пункт:${NC} "
        read choice

        case "$choice" in
            1)
                SELECTED="50-stun4all"
                URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-stun4all"
                ;;
            2)
                SELECTED="50-quic4all"
                URL="https://raw.githubusercontent.com/bol-van/zapret/master/init.d/custom.d.examples.linux/50-quic4all"
                ;;
            3)
                echo -e ""
                echo -e "${BLUE}🔴 ${GREEN}Скрипт удалён !${NC}"
                rm -f "$CUSTOM_DIR/50-script.sh" 2>/dev/null
                chmod +x /opt/zapret/sync_config.sh
                /opt/zapret/sync_config.sh
                /etc/init.d/zapret restart >/dev/null 2>&1
				echo -e ""
				read -p "Нажмите Enter для выхода в главное меню..." dummy
                show_menu
                return
                ;;
            *)
                echo -e ""
                echo -e "${GREEN}Выходим в главное меню...${NC}"
                sleep 1
                show_menu
                return
                ;;
        esac
    fi

    if [ "$CURRENT_SCRIPT" = "$SELECTED" ]; then
        echo -e ""
        echo -e "${RED}Выбранный скрипт уже установлен !${NC}"
    else
        mkdir -p "$CUSTOM_DIR"
        if curl -fsSLo "$CUSTOM_DIR/50-script.sh" "$URL"; then
			[ "$NO_PAUSE" != "1" ] && echo -e ""
            echo -e "${GREEN}🔴 ${CYAN}Скрипт ${NC}$SELECTED${CYAN} успешно установлен !${NC}"
            chmod +x /opt/zapret/sync_config.sh
            /opt/zapret/sync_config.sh
            /etc/init.d/zapret restart >/dev/null 2>&1
			echo -e ""
            echo -e "${BLUE}🔴 ${GREEN}Звонки и Discord включены !${NC}"
        else
            echo -e "${RED}Ошибка при скачивании скрипта !${NC}"
			echo -e ""
            [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
            return
        fi
    fi

    if ! grep -q -- "--filter-udp=50000-50099" /etc/config/zapret; then
        sed -i "s/option NFQWS_PORTS_UDP '443'/option NFQWS_PORTS_UDP '443,50000-50099'/" /etc/config/zapret
        sed -i "/^'$/d" /etc/config/zapret
        printf -- '--new\n--filter-udp=50000-50099\n--filter-l7=discord,stun\n--dpi-desync=fake\n' >> /etc/config/zapret
        echo "'" >> /etc/config/zapret
    fi

	echo -e ""
		chmod +x /opt/zapret/sync_config.sh
		/opt/zapret/sync_config.sh
		/etc/init.d/zapret restart >/dev/null 2>&1
    [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}

# ==========================================
# Zapret под ключ
# ==========================================
zapret_key(){
	clear
	echo -e ""
    echo -e "${MAGENTA}Удаление, установка и настройка Zapret${NC}"
    get_versions

    if [ "$LIMIT_REACHED" -eq 1 ]; then
        echo -e ""
        echo -e "${RED}Достигнут лимит GitHub API. Подождите 15 минут.${NC}"
        echo -e ""
        read -p "Нажмите Enter для выхода в главное меню..." dummy
    else
        uninstall_zapret "1"
        install_update "1"
        fix_default "1"
        echo -e ""
        echo -e "${MAGENTA}Включаем Discord и звонки в TG и WA${NC}"
        echo -e ""
        enable_discord_calls "1"

        if [ -f /etc/init.d/zapret ]; then
            echo -e "${BLUE}🔴 ${GREEN}Zapret ${GREEN}установлен и настроен !${NC}"
        else
            echo -e "${RED}Zapret не установлен !${NC}"
        fi

        echo -e ""
        read -p "Нажмите Enter для выхода в главное меню..." dummy
    fi
}

# ==========================================
# Вернуть настройки по умолчанию
# ==========================================
comeback_def () {
            clear
            echo -e ""
            echo -e "${MAGENTA}Возвращаем настройки по умолчанию${NC}"
            echo -e ""
            # Проверка скрипта восстановления и его запуск
            if [ -f /opt/zapret/restore-def-cfg.sh ]; then
				rm -f /opt/zapret/init.d/openwrt/custom.d/50-script.sh
                [ -f /etc/init.d/zapret ] && /etc/init.d/zapret stop >/dev/null 2>&1
                chmod +x /opt/zapret/restore-def-cfg.sh
                /opt/zapret/restore-def-cfg.sh
                chmod +x /opt/zapret/sync_config.sh
                /opt/zapret/sync_config.sh
                [ -f /etc/init.d/zapret ] && /etc/init.d/zapret restart >/dev/null 2>&1
                echo -e "${BLUE}🔴 ${GREEN}Настройки возвращены, сервис перезапущен !${NC}"
            else
                echo -e "${RED}Zapret не установлен !${NC}"
            fi
            echo -e ""
            read -p "Нажмите Enter для выхода в главное меню..." dummy
            show_menu
}
# ==========================================
# Остановить Zapret
# ==========================================
stop_zapret() {
			clear
            echo -e ""
            echo -e "${MAGENTA}Останавливаем Zapret${NC}"
            echo -e ""
            # Остановка службы через init.d и убийство процессов
            if [ -f /etc/init.d/zapret ]; then
                echo -e "${GREEN}🔴 ${CYAN}Останавливаем сервис ${NC}Zapret"
                /etc/init.d/zapret stop >/dev/null 2>&1
                PIDS=$(pgrep -f /opt/zapret)
                if [ -n "$PIDS" ]; then
                    echo -e "${GREEN}🔴 ${CYAN}Убиваем все процессы ${NC}Zapret"
                    for pid in $PIDS; do kill -9 "$pid" >/dev/null 2>&1; done
                fi
                echo -e ""
                echo -e "${BLUE}🔴 ${GREEN}Zapret остановлен !${NC}"
            else
                echo -e "${RED}Zapret не установлен !${NC}"
            fi
            echo -e ""
            read -p "Нажмите Enter для выхода в главное меню..." dummy
}

# ==========================================
# Запустить Zapret
# ==========================================
start_zapret() {
			clear
            echo -e ""
            echo -e "${MAGENTA}Запускаем Zapret${NC}"
            echo -e ""
            # Запуск службы через init.d
            if [ -f /etc/init.d/zapret ]; then
                echo -e "${GREEN}🔴 ${CYAN}Запускаем сервис ${NC}Zapret"
                /etc/init.d/zapret start >/dev/null 2>&1
		chmod +x /opt/zapret/sync_config.sh
		/opt/zapret/sync_config.sh
		/etc/init.d/zapret restart >/dev/null 2>&1
                echo -e ""
                echo -e "${BLUE}🔴 ${GREEN}Zapret запущен !${NC}"
            else
                echo -e "${RED}Zapret не установлен !${NC}"
            fi
            echo -e ""
            read -p "Нажмите Enter для выхода в главное меню..." dummy
}

# ==========================================
# Полное удаление Zapret
# ==========================================
uninstall_zapret() {
local NO_PAUSE=$1
	[ "$NO_PAUSE" != "1" ] && clear
    echo -e ""
    echo -e "${MAGENTA}Удаляем ZAPRET${NC}"
    echo -e ""

    [ -f /etc/init.d/zapret ] && {
        echo -e "${GREEN}🔴 ${CYAN}Останавливаем сервис ${NC}zapret"
        /etc/init.d/zapret stop >/dev/null 2>&1
    }

    PIDS=$(pgrep -f /opt/zapret)
    if [ -n "$PIDS" ]; then
        echo -e "${GREEN}🔴 ${CYAN}Убиваем все процессы ${NC}zapret"
        for pid in $PIDS; do kill -9 "$pid" >/dev/null 2>&1; done
    fi

    echo -e "${GREEN}🔴 ${CYAN}Удаляем пакеты${NC} zapret ${CYAN}и ${NC}luci-app-zapret"
    opkg remove --force-removal-of-dependent-packages zapret luci-app-zapret >/dev/null 2>&1

    echo -e "${GREEN}🔴 ${CYAN}Удаляем конфигурации и рабочие папки${NC}"
    for path in /opt/zapret /etc/config/zapret /etc/firewall.zapret; do [ -e "$path" ] && rm -rf "$path"; done

    if crontab -l >/dev/null 2>&1; then
        crontab -l | grep -v -i "zapret" | crontab -
        echo -e "${GREEN}🔴 ${CYAN}Очищаем${NC} crontab ${CYAN}задания${NC}"
    fi

    echo -e "${GREEN}🔴 ${CYAN}Удаляем${NC} ipset"
    for set in $(ipset list -n 2>/dev/null | grep -i zapret); do ipset destroy "$set" >/dev/null 2>&1; done

    echo -e "${GREEN}🔴 ${CYAN}Удаляем временные файлы${NC}"
    rm -f /tmp/*zapret* /var/run/*zapret* 2>/dev/null

    echo -e "${GREEN}🔴 ${CYAN}Удаляем цепочки и таблицы${NC} nftables"
    for table in $(nft list tables 2>/dev/null | awk '{print $2}'); do
        chains=$(nft list table "$table" 2>/dev/null | grep zapret)
        [ -n "$chains" ] && nft delete table "$table" >/dev/null 2>&1
    done

    echo -e ""
    echo -e "${BLUE}🔴 ${GREEN}Zapret полностью удалён !${NC}"
    echo -e ""
    [ "$NO_PAUSE" != "1" ] && read -p "Нажмите Enter для выхода в главное меню..." dummy
}

# ==========================================
# Проверка Flow Offloading (программного и аппаратного)
# ==========================================
check_flow_offloading() {
    local FLOW_STATE=$(uci get firewall.@defaults[0].flow_offloading 2>/dev/null)
    local HW_FLOW_STATE=$(uci get firewall.@defaults[0].flow_offloading_hw 2>/dev/null)
    if [ "$FLOW_STATE" = "1" ] || [ "$HW_FLOW_STATE" = "1" ]; then
FLOW_WARNING="${RED}=======================================================\n\
ВНИМАНИЕ: включено ускорение пакетов (Flow Offloading)!\n\
Для корректной работы Zapret, рекомендуется отключить:\n\
LuCI → Network → Firewall → Flow offloading type → None\n\
=======================================================${NC}"
    else
        FLOW_WARNING=""
    fi
}

# ==========================================
# Главное меню
# ==========================================
show_menu() {
    clear
	echo -e ""
	echo -e "╔════════════════════════════════════╗"
	echo -e "║     ${BLUE}Zapret on remittor Manager${NC}     ║"
	echo -e "╚════════════════════════════════════╝"
	echo -e "                                  ${DGRAY}v3.0${NC}"

	get_versions
	check_flow_offloading
[ -n "$FLOW_WARNING" ] && echo -e "$FLOW_WARNING"

    # Определяем актуальная/устарела
if [ "$LIMIT_REACHED" -eq 1 ]; then
    INST_COLOR=$CYAN
    INSTALLED_DISPLAY="$INSTALLED_VER"
elif [ "$INSTALLED_VER" = "$LATEST_VER" ] && [ "$LATEST_VER" != "не найдена" ]; then
    INST_COLOR=$GREEN
    INSTALLED_DISPLAY="$INSTALLED_VER (актуальная)"
elif [ "$LATEST_VER" = "не найдена" ]; then
    INST_COLOR=$CYAN
    INSTALLED_DISPLAY="$INSTALLED_VER"
elif [ "$INSTALLED_VER" != "не найдена" ]; then
    INST_COLOR=$RED
    INSTALLED_DISPLAY="$INSTALLED_VER (устарела)"
else
    INST_COLOR=$RED
    INSTALLED_DISPLAY="$INSTALLED_VER"
fi

    # Вывод информации о версиях и архитектуре
    echo -e ""
    echo -e "${YELLOW}Установленная версия: ${INST_COLOR}$INSTALLED_DISPLAY${NC}"
    echo -e ""
    echo -e "${YELLOW}Последняя версия на GitHub: ${CYAN}$LATEST_VER${NC}"
    echo -e ""
	echo -e "${YELLOW}Архитектура устройства:${NC} $LOCAL_ARCH"
	
    # Выводим статус службы zapret, если он известен
    [ -n "$ZAPRET_STATUS" ] && echo -e "\n${YELLOW}Статус Zapret: ${NC}$ZAPRET_STATUS"

	# Проверяем, установлен ли кастомный скрипт
CUSTOM_DIR="/opt/zapret/init.d/openwrt/custom.d/"
CURRENT_SCRIPT=""
if [ -f "$CUSTOM_DIR/50-script.sh" ]; then
    FIRST_LINE=$(sed -n '1p' "$CUSTOM_DIR/50-script.sh")
    if echo "$FIRST_LINE" | grep -q "QUIC"; then
        CURRENT_SCRIPT="50-quic4all"
    elif echo "$FIRST_LINE" | grep -q "stun"; then
        CURRENT_SCRIPT="50-stun4all"
    fi
fi

# Если скрипт найден, выводим строку
[ -n "$CURRENT_SCRIPT" ] && echo -e "\n${YELLOW}Установлен скрипт: ${NC}$CURRENT_SCRIPT"

    echo -e ""

    # Вывод пунктов меню
    echo -e "${CYAN}1) ${GREEN}Установить последнюю версию${NC}"
    echo -e "${CYAN}2) ${GREEN}Оптимизировать стратегию по умолчанию${NC}"
    echo -e "${CYAN}3) ${GREEN}Вернуть настройки по умолчанию${NC}"
    echo -e "${CYAN}4) ${GREEN}Остановить ${NC}Zapret"
    echo -e "${CYAN}5) ${GREEN}Запустить ${NC}Zapret"
    echo -e "${CYAN}6) ${GREEN}Удалить ${NC}Zapret"
	echo -e "${CYAN}7) ${GREEN}Меню настройки ${NC}Discord${GREEN} и звонков в ${NC}TG${GREEN}/${NC}WA"
	echo -e "${CYAN}8) ${GREEN}Удалить / Установить / Настроить${NC} Zapret"
    echo -e "${CYAN}0) ${GREEN}Выход (Enter)${NC}"
    echo -e ""
    echo -ne "${YELLOW}Выберите пункт:${NC} "
    read choice
    case "$choice" in
        1) install_update ;;
        2) fix_default ;;
        3) comeback_def ;;
        4) stop_zapret ;;
        5) start_zapret ;;
        6) uninstall_zapret ;;
		7) enable_discord_calls ;;
		8) zapret_key ;;
        *) exit 0 ;;
    esac
}

# ==========================================
# Старт скрипта (цикл)
# ==========================================
while true; do
    show_menu
done
