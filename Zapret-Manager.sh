#!/bin/sh
# ==========================================
# Zapret on remittor Manager by StressOzz
# Скрипт для установки, обновления и полного удаления Zapret на OpenWRT
# ==========================================

# Цвета для вывода
GREEN="\033[1;32m"       # Зеленый для успешных действий и статусов
RED="\033[1;31m"         # Красный для ошибок или остановленных процессов
CYAN="\033[1;36m"        # Голубой для информационных сообщений
YELLOW="\033[1;33m"      # Желтый для подчеркивания важных данных
MAGENTA="\033[1;35m"     # Фиолетовый для заголовков и названия скрипта
BLUE="\033[0;34m"        # Синий для завершения действий
NC="\033[0m"             # Сброс цвета
GRAY='\033[38;5;239m'    # Темно-серый для ссылок
DGRAY='\033[38;5;236m'   # Очень темный серый для версии

# Рабочая директория для скачивания и распаковки
WORKDIR="/tmp/zapret-update"  # Временная папка для загрузки архивов

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

    LATEST_URL=$(curl -s https://api.github.com/repos/remittor/zapret-openwrt/releases/latest \
        | grep browser_download_url | grep "$LOCAL_ARCH.zip" | cut -d '"' -f 4)
    PREV_URL=$(curl -s https://api.github.com/repos/remittor/zapret-openwrt/releases \
        | grep browser_download_url | grep "$LOCAL_ARCH.zip" | sed -n '2p' | cut -d '"' -f 4)

    if [ -n "$LATEST_URL" ] && echo "$LATEST_URL" | grep -q '\.zip$'; then
        LATEST_FILE=$(basename "$LATEST_URL")
        LATEST_VER=$(echo "$LATEST_FILE" | sed -E 's/.*zapret_v([0-9]+\.[0-9]+)_.*\.zip/\1/')
        USED_ARCH="$LOCAL_ARCH"
    else
        LATEST_VER="не найдена"
        USED_ARCH="нет пакета для вашей архитектуры"
    fi

    if [ -n "$PREV_URL" ] && echo "$PREV_URL" | grep -q '\.zip$'; then
        PREV_FILE=$(basename "$PREV_URL")
        PREV_VER=$(echo "$PREV_FILE" | sed -E 's/.*zapret_v([0-9]+\.[0-9]+)_.*\.zip/\1/')
    else
        PREV_VER="не найдена"
    fi

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
# Установка или обновление Zapret (обычная)
# ==========================================
install_update() {
    clear
    echo -e ""
    if [ "$INSTALLED_VER" != "не найдена" ]; then
        echo -e "${MAGENTA}Начинаем установку ZAPRET${NC}"
        ACTION="update"
    else
        echo -e "${MAGENTA}Начинаем установку ZAPRET${NC}"
        ACTION="install"
    fi
    echo -e ""
    get_versions

    TARGET="$1"
    if [ "$TARGET" = "prev" ]; then
        TARGET_URL="$PREV_URL"
        TARGET_FILE="$PREV_FILE"
        TARGET_VER="$PREV_VER"
    else
        TARGET_URL="$LATEST_URL"
        TARGET_FILE="$LATEST_FILE"
        TARGET_VER="$LATEST_VER"
    fi

    [ "$USED_ARCH" = "нет пакета для вашей архитектуры" ] && {
        echo -e "${RED}Нет доступного пакета для вашей архитектуры: ${NC}$LOCAL_ARCH"
        echo -e ""
        read -p "Нажмите Enter для продолжения..." dummy
        return
    }

    if [ "$INSTALLED_VER" = "$TARGET_VER" ]; then
        echo -e "${BLUE}🔴 ${GREEN}Эта версия уже установлена !${NC}"
        echo -e ""
        read -p "Нажмите Enter для продолжения..." dummy
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

    mkdir -p "$WORKDIR" && cd "$WORKDIR" || return
    echo -e "${GREEN}🔴 ${CYAN}Скачиваем архив ${NC}$TARGET_FILE"
    wget -q "$TARGET_URL" -O "$TARGET_FILE" || { echo -e "${RED}Не удалось скачать ${NC}$TARGET_FILE"; read -p "Нажмите Enter для продолжения..." dummy; return; }

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
    if [ "$ACTION" = "update" ]; then
        echo -e "${BLUE}🔴 ${GREEN}Zapret успешно обновлён !${NC}"
    else
        echo -e "${BLUE}🔴 ${GREEN}Zapret успешно установлен !${NC}"
    fi
    echo -e ""
    read -p "Нажмите Enter для продолжения..." dummy
}

# ==========================================
# Установка конкретной версии Zapret
# ==========================================
install_update_specific() {
    SPEC_URL="$1"
    SPEC_FILE="$2"
    SPEC_VER="$3"

    clear
    echo -e ""
    if [ "$INSTALLED_VER" != "не найдена" ]; then
        echo -e "${MAGENTA}Начинаем установку ZAPRET${NC}"
        ACTION="update"
    else
        echo -e "${MAGENTA}Начинаем установку ZAPRET${NC}"
        ACTION="install"
    fi
    echo -e ""
    get_versions

    TARGET_URL="$SPEC_URL"
    TARGET_FILE="$SPEC_FILE"
    TARGET_VER="$SPEC_VER"

    [ "$USED_ARCH" = "нет пакета для вашей архитектуры" ] && {
        echo -e "${RED}Нет доступного пакета для вашей архитектуры: ${NC}$LOCAL_ARCH"
        echo -e ""
        read -p "Нажмите Enter для продолжения..." dummy
        return
    }

    if [ "$INSTALLED_VER" = "$TARGET_VER" ]; then
        echo -e "${BLUE}🔴 ${GREEN}Эта версия уже установлена !${NC}"
        echo -e ""
        read -p "Нажмите Enter для продолжения..." dummy
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

    mkdir -p "$WORKDIR" && cd "$WORKDIR" || return
    echo -e "${GREEN}🔴 ${CYAN}Скачиваем архив ${NC}$TARGET_FILE"
    wget -q "$TARGET_URL" -O "$TARGET_FILE" || { echo -e "${RED}Не удалось скачать ${NC}$TARGET_FILE"; read -p "Нажмите Enter для продолжения..." dummy; return; }

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
    echo -e "${BLUE}🔴 ${GREEN}Zapret успешно установлен версия $TARGET_VER!${NC}"
    echo -e ""
    read -p "Нажмите Enter для продолжения..." dummy
}

# ==========================================
# Выбор и установка конкретной версии
# ==========================================
choose_version() {
    clear
    echo -e ""
    echo -e "${MAGENTA}Последние 10 версий Zapret${NC}"
    echo -e ""

    LOCAL_ARCH=$(awk -F\' '/DISTRIB_ARCH/ {print $2}' /etc/openwrt_release)
    [ -z "$LOCAL_ARCH" ] && LOCAL_ARCH=$(opkg print-architecture | grep -v "noarch" | sort -k3 -n | tail -n1 | awk '{print $2}')

    RELEASES=$(curl -s https://api.github.com/repos/remittor/zapret-openwrt/releases \
        | grep '"tag_name"' | grep -Eo '[0-9]+\.[0-9]+[0-9]*' | head -n 10)

    if [ -z "$RELEASES" ]; then
        echo -e "${RED}Не удалось получить список версий${NC}"
        echo -e ""
        read -p "Нажмите Enter для продолжения..." dummy
        return
    fi

i=1
echo "$RELEASES" | while read ver; do
    LABEL=""
    COLOR="$NC"

# Проверяем последнюю версию
if [ "$ver" = "$LATEST_VER" ]; then
    LABEL="${LABEL}последняя"
    COLOR="$GREEN"
fi

# Проверяем установленную версию
if [ "$ver" = "$INSTALLED_VER" ]; then
    [ -n "$LABEL" ] && LABEL="${LABEL} / "
    LABEL="${LABEL}установленная"

    # Если версия и последняя, и установленная — оставляем зелёный
    if [ "$ver" = "$LATEST_VER" ]; then
        COLOR="$GREEN"
    else
        COLOR="$CYAN"
    fi
fi
    echo -e "${GREEN}$i) ${COLOR}$ver $LABEL${NC}"
    i=$((i+1))
done

    echo -e ""
    echo -n "Введите номер пункта для установки (или Enter для выхода в меню): "
    read num
    [ -z "$num" ] && return

    SELECTED=$(echo "$RELEASES" | sed -n "${num}p")
    [ -z "$SELECTED" ] && { echo -e "${RED}Неверный номер${NC}"; sleep 2; return; }

    TARGET_URL=$(curl -s https://api.github.com/repos/remittor/zapret-openwrt/releases \
        | grep browser_download_url | grep "$SELECTED" | grep "$LOCAL_ARCH.zip" | cut -d'"' -f4)
    [ -z "$TARGET_URL" ] && { echo -e "${RED}Не найден пакет для вашей архитектуры${NC}"; read -p "Enter..." dummy; return; }
    TARGET_FILE=$(basename "$TARGET_URL")
    TARGET_VER="$SELECTED"

    install_update_specific "$TARGET_URL" "$TARGET_FILE" "$TARGET_VER"
}

# ==========================================
# Включение Discord и звонков в TG и WA
# ==========================================
enable_discord_calls() {
    clear
    echo -e ""
    echo -e "${MAGENTA}Включаем Discord, звонки TG и WA${NC}"
    echo -e ""

    CONFIG_FILE="/opt/zapret/config"

    # Проверка, установлен ли Zapret
    if [ ! -f /etc/init.d/zapret ]; then
        echo -e "${RED}Zapret не установлен! Нечего включать.${NC}"
        echo -e ""
        read -p "Нажмите Enter для продолжения..." dummy
        return
    fi

CONFIG_FILE="/etc/config/zapret"

# Проверка и добавление UDP-портов
grep -q "50000-50099" "$CONFIG_FILE"
if [ $? -ne 0 ]; then
    # Меняем строку с портами, добавляем 50000-50099
    sed -i "s|^\s*option NFQWS_PORTS_UDP\s*'.*'|option NFQWS_PORTS_UDP '443,50000-50099'|" "$CONFIG_FILE"
fi

# Проверка и добавление параметров в конце
grep -q -- '--filter-l7=discord,stun' "$CONFIG_FILE"
if [ $? -ne 0 ]; then
    # Удаляем последнюю кавычку один раз (если есть)
    sed -i '$s/\'$'\''$//' "$CONFIG_FILE"
    
    # Добавляем новые строки перед последней кавычкой
    printf -- "--new\n--filter-udp=50000-50099\n--filter-l7=discord,stun\n--dpi-desync=fake\n'\n" >> "$CONFIG_FILE"
fi

    # Перезапуск Zapret
    chmod +x /opt/zapret/sync_config.sh
    /opt/zapret/sync_config.sh
    /etc/init.d/zapret restart >/dev/null 2>&1

    echo -e "${BLUE}🔴 ${GREEN}Звонки и Discord включены!${NC}"
    echo -e ""
    read -p "Нажмите Enter для продолжения..." dummy
}


# ==========================================
# Полное удаление Zapret
# ==========================================
uninstall_zapret() {
    clear
    echo -e ""
    echo -e "${MAGENTA}Начинаем удаление ZAPRET${NC}"
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
    echo -e "${BLUE}🔴 ${GREEN}Zapret полностью удалён!${NC}"
    echo -e ""
    read -p "Нажмите Enter для продолжения..." dummy
}

# ==========================================
# Главное меню
# ==========================================
show_menu() {
    get_versions  # Получаем версии, архитектуру и статус службы

	clear
	echo -e ""
	echo -e "${YELLOW}Модель и архитектура роутера:${NC} $MODEL / $LOCAL_ARCH"
    
    clear
	echo -e ""
	echo -e "╔════════════════════════════════════╗"
	echo -e "║     ${BLUE}Zapret on remittor Manager${NC}     ║"
	echo -e "╚════════════════════════════════════╝"
	echo -e "                                  ${DGRAY}v3.0${NC}"

    # Определяем цвет для отображения версии (актуальная/устарела)
    [ "$INSTALLED_VER" = "$LATEST_VER" ] && INST_COLOR=$GREEN || INST_COLOR=$RED

    # Настройка текста для меню в зависимости от версии
    if [ "$INSTALLED_VER" = "$LATEST_VER" ]; then
        INSTALLED_DISPLAY="$INSTALLED_VER (актуальная)"
    elif [ "$INSTALLED_VER" != "не найдена" ]; then
        INSTALLED_DISPLAY="$INSTALLED_VER (устарела)"
    else
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

    echo -e ""

    # Вывод пунктов меню
    echo -e "${CYAN}1) ${GREEN}Установить последнюю версию${NC}"
    echo -e "${CYAN}2) ${GREEN}Меню выбора версии для установки${NC}"
    echo -e "${CYAN}3) ${GREEN}Вернуть настройки по умолчанию${NC}"
    echo -e "${CYAN}4) ${GREEN}Остановить ${NC}Zapret"
    echo -e "${CYAN}5) ${GREEN}Запустить ${NC}Zapret"
    echo -e "${CYAN}6) ${GREEN}Удалить ${NC}Zapret"
	echo -e "${CYAN}7) ${GREEN}Включить ${NC}Discord${GREEN} и звонки в ${NC}TG${GREEN} и ${NC}WA ${RED}(test)${NC}"
    echo -e "${CYAN}8) ${GREEN}Выход (Enter)${NC}"
    echo -e ""
    echo -ne "${YELLOW}Выберите пункт:${NC} "
    read choice
    case "$choice" in
        1) install_update "latest" ;;  # Установка/обновление до последней версии
        2) choose_version ;;
        3)
            clear
            echo -e ""
            echo -e "${MAGENTA}Возврат к настройкам по умолчанию${NC}"
            echo -e ""
            # Проверка скрипта восстановления и его запуск
            if [ -f /opt/zapret/restore-def-cfg.sh ]; then
			 	rm -f /opt/zapret/init.d/openwrt/custom.d/50-script.sh 2>/dev/null
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
            read -p "Нажмите Enter для продолжения..." dummy
            show_menu
            ;;          
        4)
            clear
            echo -e ""
            echo -e "${MAGENTA}Остановка Zapret${NC}"
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
            read -p "Нажмите Enter для продолжения..." dummy
            ;;
        5)
            clear
            echo -e ""
            echo -e "${MAGENTA}Запуск Zapret${NC}"
            echo -e ""
            # Запуск службы через init.d
            if [ -f /etc/init.d/zapret ]; then
                echo -e "${GREEN}🔴 ${CYAN}Запускаем сервис ${NC}Zapret"
                /etc/init.d/zapret start >/dev/null 2>&1
                echo -e ""
                echo -e "${BLUE}🔴 ${GREEN}Zapret запущен !${NC}"
            else
                echo -e "${RED}Zapret не установлен !${NC}"
            fi
            echo -e ""
            read -p "Нажмите Enter для продолжения..." dummy
            ;;
        6) uninstall_zapret ;;  # Полное удаление Zapret
		7) enable_discord_calls ;;
        *) exit 0 ;;  # Выход по Enter или любой другой невалидной опции
    esac
}

# ==========================================
# Старт скрипта (цикл)
# ==========================================
while true; do
    show_menu  # Показываем главное меню бесконечно
done
