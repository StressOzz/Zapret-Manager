#!/bin/sh

# Пути для Zapret-Manager
CONFIG_DIR="/opt/zapret"
STRATEGY_FILE="$CONFIG_DIR/nfq/desync.txt"
STRATEGIES_DIR="$CONFIG_DIR/strategies"
BACKUP_DIR="$CONFIG_DIR/backups"
LOG_FILE="/var/log/zapret.log"
MENU_TITLE="=== Zapret Manager - Управление стратегиями YouTube ==="

# Создаем директории
mkdir -p "$STRATEGIES_DIR" "$BACKUP_DIR" "$(dirname "$STRATEGY_FILE")"

# Цвета для меню
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции утилит
show_header() {
    clear
    echo -e "${BLUE}$MENU_TITLE${NC}"
    echo "================================================"
}

show_status() {
    echo -e "\n${YELLOW}Статус Zapret:${NC}"
    
    # Проверяем процессы nfqws
    if pgrep -f "nfqws" > /dev/null; then
        echo -e "${GREEN}✓ Zapret работает (процессы nfqws найдены)${NC}"
        echo "Количество процессов: $(pgrep -f "nfqws" | wc -l)"
    else
        echo -e "${RED}✗ Zapret не запущен${NC}"
    fi
    
    # Проверяем файл стратегии
    if [ -f "$STRATEGY_FILE" ]; then
        echo -e "\n${YELLOW}Текущая стратегия:${NC}"
        STRAT_NAME=$(basename $(readlink -f "$STRATEGY_FILE.link" 2>/dev/null) 2>/dev/null || echo "Неизвестно")
        echo "Имя: $STRAT_NAME"
        echo "Размер: $(wc -l < "$STRATEGY_FILE") строк"
        echo "Путь: $STRATEGY_FILE"
        
        # Показываем первые 3 строки текущей стратегии
        echo -e "\n${YELLOW}Первые строки стратегии:${NC}"
        head -5 "$STRATEGY_FILE"
    else
        echo -e "\n${RED}Файл стратегии не найден${NC}"
        echo "Примените стратегию из меню (опции 1-16)"
    fi
}

apply_strategy() {
    strategy_num=$1
    strategy_file="$STRATEGIES_DIR/strategy${strategy_num}.txt"
    
    if [ ! -f "$strategy_file" ]; then
        echo -e "${RED}Файл стратегии $strategy_num не найден!${NC}"
        echo "Создайте файлы стратегий командой: zapret-menu.sh --create"
        read -p "Нажмите Enter для продолжения..."
        return 1
    fi
    
    echo -e "${YELLOW}Применяем стратегию $strategy_num...${NC}"
    
    # Создаем бэкап текущей стратегии если она существует
    if [ -f "$STRATEGY_FILE" ]; then
        backup_name="backup_$(date +%Y%m%d_%H%M%S).txt"
        cp "$STRATEGY_FILE" "$BACKUP_DIR/$backup_name"
        echo -e "${GREEN}Создан бэкап: $backup_name${NC}"
    fi
    
    # Копируем новую стратегию
    if cp "$strategy_file" "$STRATEGY_FILE"; then
        # Создаем ссылку для отслеживания
        ln -sf "$strategy_file" "$STRATEGY_FILE.link" 2>/dev/null
        
        echo -e "${GREEN}✓ Стратегия $strategy_num успешно применена${NC}"
        echo -e "\n${YELLOW}Примененные параметры:${NC}"
        cat "$STRATEGY_FILE"
        
        echo -e "\n${BLUE}ВАЖНО:${NC}"
        echo "1. Перезапустите Zapret (опция r)"
        echo "2. Перезапустите браузер"
    else
        echo -e "${RED}✗ Ошибка при применении стратегии${NC}"
        echo "Проверьте права доступа к $STRATEGY_FILE"
    fi
}

restart_zapret() {
    echo -e "${YELLOW}Перезапуск Zapret...${NC}"
    
    # Проверяем есть ли файл стратегии
    if [ ! -f "$STRATEGY_FILE" ]; then
        echo -e "${RED}Файл стратегии не найден!${NC}"
        echo "Примените сначала стратегию (опции 1-16)"
        read -p "Нажмите Enter для продолжения..."
        return 1
    fi
    
    # Останавливаем Zapret
    echo "Останавливаем Zapret..."
    /etc/init.d/zapret stop 2>/dev/null
    sleep 2
    
    # Убиваем все оставшиеся процессы nfqws
    killall nfqws 2>/dev/null
    sleep 1
    
    # Запускаем Zapret
    echo "Запускаем Zapret..."
    /etc/init.d/zapret start
    sleep 3
    
    # Проверяем статус
    if pgrep -f "nfqws" > /dev/null; then
        echo -e "${GREEN}✓ Zapret успешно перезапущен${NC}"
        echo -e "${YELLOW}Запущенные процессы:${NC}"
        pgrep -f "nfqws" | xargs ps -o pid,args
    else
        echo -e "${RED}✗ Zapret не запустился${NC}"
        echo "Проверьте:"
        echo "1. Файл стратегии: $STRATEGY_FILE"
        echo "2. Логи: tail -f /var/log/zapret.log"
        echo "3. Конфигурацию: /opt/zapret/config/config"
    fi
}

create_strategies() {
    echo -e "${YELLOW}Создание файлов стратегий...${NC}"
    
    # Проверяем существование необходимых файлов
    if [ ! -f "/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" ]; then
        echo -e "${YELLOW}Внимание: файл tls_clienthello_www_google_com.bin не найден${NC}"
        echo "Он нужен для некоторых стратегий"
    fi
    
    if [ ! -f "/opt/zapret/files/fake/quic_initial_www_google_com.bin" ]; then
        echo -e "${YELLOW}Внимание: файл quic_initial_www_google_com.bin не найден${NC}"
        echo "Он нужен для стратегий с QUIC"
    fi
    
    # Стратегия 1
    cat > "$STRATEGIES_DIR/strategy1.txt" << 'EOFS1'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--ip-id=zero
--dpi-desync=multisplit
--dpi-desync-split-seqovl=681
--dpi-desync-split-pos=1
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
EOFS1
    echo "✓ Создана стратегия 1"
    
    # Стратегия 2
    cat > "$STRATEGIES_DIR/strategy2.txt" << 'EOFS2'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=multisplit
--dpi-desync-split-pos=1,sniext+1
--dpi-desync-split-seqovl=1
EOFS2
    echo "✓ Создана стратегия 2"
    
    # Стратегия 3
    cat > "$STRATEGIES_DIR/strategy3.txt" << 'EOFS3'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=multisplit
--dpi-desync-split-pos=1,sniext+1
--dpi-desync-split-seqovl=1
EOFS3
    echo "✓ Создана стратегия 3"
    
    # Стратегия 4
    cat > "$STRATEGIES_DIR/strategy4.txt" << 'EOFS4'
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=2
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
EOFS4
    echo "✓ Создана стратегия 4"
    
    # Стратегия 5
    cat > "$STRATEGIES_DIR/strategy5.txt" << 'EOFS5'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=split2
--dpi-desync-split-seqovl=681
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
EOFS5
    echo "✓ Создана стратегия 5"
    
    # Стратегия 6
    cat > "$STRATEGIES_DIR/strategy6.txt" << 'EOFS6'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,fakeddisorder
--dpi-desync-split-pos=10,midsld
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls-mod=none
--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin
--dpi-desync-split-seqovl=336
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin
--dpi-desync-fooling=badseq,badsum
--dpi-desync-badseq-increment=0
EOFS6
    echo "✓ Создана стратегия 6"
    
    # Стратегия 7
    cat > "$STRATEGIES_DIR/strategy7.txt" << 'EOFS7'
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=4
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
EOFS7
    echo "✓ Создана стратегия 7"
    
    # Стратегия 8
    cat > "$STRATEGIES_DIR/strategy8.txt" << 'EOFS8'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=multidisorder
--dpi-desync-split-pos=7,sld+1
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com
--dpi-desync-fooling=badseq
--dpi-desync-autottl 2:2-12
EOFS8
    echo "✓ Создана стратегия 8"
    
    # Стратегия 9
    cat > "$STRATEGIES_DIR/strategy9.txt" << 'EOFS9'
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=8
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
EOFS9
    echo "✓ Создана стратегия 9"
    
    # Стратегия 10
    cat > "$STRATEGIES_DIR/strategy10.txt" << 'EOFS10'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=multidisorder
--dpi-desync-split-pos=1,midsld,endhost-1
--dpi-desync-repeats=2
--dpi-desync-fooling=md5sig
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com
EOFS10
    echo "✓ Создана стратегия 10"
    
    # Стратегия 11
    cat > "$STRATEGIES_DIR/strategy11.txt" << 'EOFS11'
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=1
--dpi-desync-cutoff=d3
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
EOFS11
    echo "✓ Создана стратегия 11"
    
    # Стратегия 12
    cat > "$STRATEGIES_DIR/strategy12.txt" << 'EOFS12'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-fake-tls=0x00000000
--dpi-desync-fake-tls=!
--dpi-desync-split-pos=1,midsld
--dpi-desync-repeats=2
--dpi-desync-fooling=badseq
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com
EOFS12
    echo "✓ Создана стратегия 12"
    
    # Стратегия 13
    cat > "$STRATEGIES_DIR/strategy13.txt" << 'EOFS13'
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake
--dpi-desync-repeats=11
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
EOFS13
    echo "✓ Создана стратегия 13"
    
    # Стратегия 14
    cat > "$STRATEGIES_DIR/strategy14.txt" << 'EOFS14'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync-repeats=6
--dpi-desync-fooling=badseq
--dpi-desync-badseq-increment=2
--dpi-desync=multidisorder
--dpi-desync-split-pos=1,midsld
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
EOFS14
    echo "✓ Создана стратегия 14"
    
    # Стратегия 15
    cat > "$STRATEGIES_DIR/strategy15.txt" << 'EOFS15'
--new
--filter-udp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=split2
--dpi-desync-repeats=8
--dpi-desync-fooling=datanoack
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
EOFS15
    echo "✓ Создана стратегия 15"
    
    # Стратегия 16
    cat > "$STRATEGIES_DIR/strategy16.txt" << 'EOFS16'
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=multisplit
--dpi-desync-split-pos=1,2
--dpi-desync-split-seqovl=4
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com
EOFS16
    echo "✓ Создана стратегия 16"
    
    echo -e "\n${GREEN}✓ Все 16 файлов стратегий созданы в $STRATEGIES_DIR${NC}"
    echo "Теперь можно применять стратегии из меню (опции 1-16)"
}

view_strategy() {
    strategy_num=$1
    strategy_file="$STRATEGIES_DIR/strategy${strategy_num}.txt"
    
    if [ ! -f "$strategy_file" ]; then
        echo -e "${RED}Файл стратегии не найден!${NC}"
        echo "Создайте файлы стратегий командой: zapret-menu.sh --create"
        return 1
    fi
    
    echo -e "${YELLOW}Содержимое стратегии $strategy_num:${NC}"
    echo "================================================"
    cat "$strategy_file"
    echo "================================================"
    echo "Строк: $(wc -l < "$strategy_file")"
}

list_backups() {
    echo -e "${YELLOW}Доступные бэкапы:${NC}"
    if [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo "Нет бэкапов"
    else
        echo "Список бэкапов в $BACKUP_DIR:"
        ls -lh "$BACKUP_DIR/"*.txt 2>/dev/null | awk '{print NR". "$6" "$7" "$8" "$9" ("$5")"}' || echo "Бэкапы не найдены"
    fi
}

show_logs() {
    echo -e "${YELLOW}Последние 30 строк лога:${NC}"
    echo "================================================"
    if [ -f "$LOG_FILE" ]; then
        tail -30 "$LOG_FILE"
    else
        echo "Лог файл не найден: $LOG_FILE"
        echo "Попробуйте: tail -f /var/log/messages | grep zapret"
    fi
    echo "================================================"
}

check_zapret_install() {
    echo -e "${YELLOW}Проверка установки Zapret:${NC}"
    
    if [ -f "/opt/zapret/nfq/nfqws" ]; then
        echo -e "${GREEN}✓ Основной бинарный файл найден: /opt/zapret/nfq/nfqws${NC}"
        /opt/zapret/nfq/nfqws --version 2>/dev/null || echo "Не удалось получить версию"
    else
        echo -e "${RED}✗ Основной бинарный файл не найден${NC}"
    fi
    
    if [ -f "/etc/init.d/zapret" ]; then
        echo -e "${GREEN}✓ Init скрипт найден: /etc/init.d/zapret${NC}"
    else
        echo -e "${RED}✗ Init скрипт не найден${NC}"
    fi
    
    # Проверяем конфигурацию
    echo -e "\n${YELLOW}Конфигурация:${NC}"
    if [ -f "/opt/zapret/config/config" ]; then
        echo "Основной конфиг найден"
        grep -E "^(DAEMON|DESYNC|HOSTLIST)" /opt/zapret/config/config 2>/dev/null | head -10
    fi
    
    # Проверяем файлы стратегий
    echo -e "\n${YELLOW}Файлы стратегий:${NC}"
    if [ -f "$STRATEGY_FILE" ]; then
        echo "Текущий файл стратегий: $STRATEGY_FILE"
        echo "Размер: $(wc -l < "$STRATEGY_FILE") строк"
    else
        echo "Файл стратегий не найден"
    fi
    
    # Проверяем необходимые файлы
    echo -e "\n${YELLOW}Необходимые файлы:${NC}"
    for file in "/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" \
                "/opt/zapret/files/fake/quic_initial_www_google_com.bin"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓ Найден: $file${NC}"
        else
            echo -e "${YELLOW}⚠ Отсутствует: $file${NC}"
        fi
    done
}

show_menu() {
    show_header
    show_status
    
    echo -e "\n${GREEN}=== ОСНОВНОЕ МЕНЮ ===${NC}"
    echo "1.  Стратегия 1 (multisplit + zero IP ID)"
    echo "2.  Стратегия 2 (multisplit + SNI ext)"
    echo "3.  Стратегия 3 (multisplit + SNI ext повтор)"
    echo "4.  Стратегия 4 (fake QUIC x2)"
    echo "5.  Стратегия 5 (split2 + pattern)"
    echo "6.  Стратегия 6 (fake + fakeddisorder)"
    echo "7.  Стратегия 7 (fake QUIC x4)"
    echo "8.  Стратегия 8 (multidisorder + badseq)"
    echo "9.  Стратегия 9 (fake QUIC x8)"
    echo "10. Стратегия 10 (multidisorder + md5sig)"
    echo "11. Стратегия 11 (fake QUIC x1 + cutoff)"
    echo "12. Стратегия 12 (fake,multisplit + badseq)"
    echo "13. Стратегия 13 (fake QUIC x11)"
    echo "14. Стратегия 14 (multidisorder + badseq inc2)"
    echo "15. Стратегия 15 (split2 + datanoack)"
    echo "16. Стратегия 16 (multisplit pos1,2)"
    
    echo -e "\n${YELLOW}=== УТИЛИТЫ ===${NC}"
    echo "v.  Просмотреть стратегию"
    echo "c.  Создать все файлы стратегий"
    echo "r.  Перезапустить Zapret"
    echo "b.  Список бэкапов"
    echo "l.  Показать логи"
    echo "i.  Проверить установку Zapret"
    echo "s.  Статус системы"
    echo "q.  Выход"
    
    echo -e "\n${BLUE}=== ВАЖНО ===${NC}"
    echo "После смены стратегии ОБЯЗАТЕЛЬНО:"
    echo "1. Перезапустите Zapret (опция r)"
    echo "2. Перезапустите браузер"
    echo ""
}

# Проверяем аргументы командной строки
case "$1" in
    "--create"|"-c")
        create_strategies
        exit 0
        ;;
    "--restart"|"-r")
        restart_zapret
        exit 0
        ;;
    "--status"|"-s")
        show_status
        exit 0
        ;;
    "--check"|"-i")
        check_zapret_install
        exit 0
        ;;
    "--help"|"-h")
        echo "Использование:"
        echo "  zapret-menu              - запустить меню"
        echo "  zapret-menu --create     - создать файлы стратегий"
        echo "  zapret-menu --restart    - перезапустить Zapret"
        echo "  zapret-menu --status     - показать статус"
        echo "  zapret-menu --check      - проверить установку"
        exit 0
        ;;
esac

# Основной цикл меню
while true; do
    show_menu
    echo -n "Выберите опцию: "
    read choice
    
    case $choice in
        # Применение стратегий
        1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16)
            apply_strategy $choice
            read -p "Нажмите Enter для продолжения..."
            ;;
        
        # Просмотр стратегии
        v|V)
            echo -n "Введите номер стратегии для просмотра (1-16): "
            read num
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le 16 ]; then
                view_strategy $num
            else
                echo -e "${RED}Неверный номер стратегии${NC}"
            fi
            read -p "Нажмите Enter для продолжения..."
            ;;
        
        # Создание файлов стратегий
        c|C)
            create_strategies
            read -p "Нажмите Enter для продолжения..."
            ;;
        
        # Перезапуск Zapret
        r|R)
            restart_zapret
            read -p "Нажмите Enter для продолжения..."
            ;;
        
        # Список бэкапов
        b|B)
            list_backups
            read -p "Нажмите Enter для продолжения..."
            ;;
        
        # Показать логи
        l|L)
            show_logs
            read -p "Нажмите Enter для продолжения..."
            ;;
        
        # Проверить установку
        i|I)
            check_zapret_install
            read -p "Нажмите Enter для продолжения..."
            ;;
        
        # Статус системы
        s|S)
            show_status
            echo -e "\n${YELLOW}Системная информация:${NC}"
            echo "Память:"
            free -h | head -2
            echo -e "\nЗагрузка CPU:"
            uptime
            echo -e "\nСетевые интерфейсы:"
            ifconfig | grep -A1 "eth\|wlan\|br-lan" | grep -v "^--"
            read -p "Нажмите Enter для продолжения..."
            ;;
        
        # Выход
        q|Q)
            echo "Выход из меню..."
            exit 0
            ;;
        
        *)
            echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
            sleep 1
            ;;
    esac
done
