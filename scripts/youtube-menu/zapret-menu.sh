#!/bin/sh

# YouTube Strategies Enhanced Menu for Zapret-Manager
# Автоматическое тестирование 16 стратегий для YouTube

CONFIG_DIR="/opt/zapret"
STRATEGY_FILE="$CONFIG_DIR/nfq/desync.txt"
STRATEGIES_DIR="$CONFIG_DIR/strategies"
BACKUP_DIR="$CONFIG_DIR/backups"
LOG_FILE="/var/log/zapret.log"
TEST_RESULTS="$CONFIG_DIR/youtube-test-results.txt"
MENU_TITLE="=== Zapret Manager - YouTube Strategies Auto-Tester ==="

# Создаем директории
mkdir -p "$STRATEGIES_DIR" "$BACKUP_DIR" "$(dirname "$STRATEGY_FILE")"

# Цвета для меню
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Функция показа заголовка
show_header() {
    clear
    echo -e "${PURPLE}$MENU_TITLE${NC}"
    echo "================================================"
    echo "Автоматический поиск работающей стратегии для YouTube"
    echo "================================================"
}

# Функция показа статуса
show_status() {
    echo -e "\n${YELLOW}📊 СТАТУС СИСТЕМЫ:${NC}"
    
    # Проверяем Zapret
    if pgrep -f "nfqws" > /dev/null; then
        echo -e "${GREEN}✅ Zapret работает${NC}"
        echo "   Процессов: $(pgrep -f "nfqws" | wc -l)"
    else
        echo -e "${RED}❌ Zapret не запущен${NC}"
    fi
    
    # Проверяем файл стратегии
    if [ -f "$STRATEGY_FILE" ]; then
        current_strat=$(grep -o "strategy[0-9]*" "$STRATEGY_FILE.link" 2>/dev/null | head -1 || echo "неизвестна")
        echo "   Текущая стратегия: $current_strat"
    fi
    
    # Показываем результаты тестов если есть
    if [ -f "$TEST_RESULTS" ]; then
        working_count=$(grep -c "✅ РАБОТАЕТ" "$TEST_RESULTS" 2>/dev/null || echo 0)
        if [ "$working_count" -gt 0 ]; then
            echo -e "${GREEN}   Найдено работающих стратегий: $working_count${NC}"
        fi
    fi
}

# Функция создания стратегий (нужна из старого скрипта)
create_strategies() {
    echo -e "${YELLOW}🛠️  СОЗДАНИЕ ФАЙЛОВ СТРАТЕГИЙ...${NC}"
    
    # Проверяем необходимые файлы
    if [ ! -f "/opt/zapret/files/fake/tls_clienthello_www_google_com.bin" ]; then
        echo -e "${YELLOW}⚠  Внимание: файл tls_clienthello_www_google_com.bin не найден${NC}"
    fi
    
    if [ ! -f "/opt/zapret/files/fake/quic_initial_www_google_com.bin" ]; then
        echo -e "${YELLOW}⚠  Внимание: файл quic_initial_www_google_com.bin не найден${NC}"
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
    
    echo -e "\n${GREEN}✅ Все 16 файлов стратегий созданы в $STRATEGIES_DIR${NC}"
}

# Функция тестирования одной стратегии
test_single_strategy() {
    local strat_num=$1
    local strat_file="$STRATEGIES_DIR/strategy${strat_num}.txt"
    
    echo -e "\n${CYAN}🔍 ТЕСТ СТРАТЕГИИ $strat_num${NC}"
    echo "────────────────────────"
    
    # Проверяем существует ли файл стратегии
    if [ ! -f "$strat_file" ]; then
        echo -e "${RED}❌ Файл стратегии не найден${NC}"
        return 1
    fi
    
    # Создаем бэкап текущей стратегии
    if [ -f "$STRATEGY_FILE" ]; then
        cp "$STRATEGY_FILE" "$BACKUP_DIR/backup_before_test_$(date +%s).txt" 2>/dev/null
    fi
    
    # Применяем стратегию
    echo "📝 Применяем стратегию $strat_num..."
    if ! cp "$strat_file" "$STRATEGY_FILE"; then
        echo -e "${RED}❌ Ошибка применения стратегии${NC}"
        return 1
    fi
    
    # Перезапускаем Zapret
    echo "🔄 Перезапускаем Zapret..."
    /etc/init.d/zapret restart > /dev/null 2>&1
    sleep 5
    
    # Проверяем запустился ли Zapret
    if ! pgrep -f "nfqws" > /dev/null; then
        echo -e "${RED}❌ ОШИБКА: Zapret не запустился после применения стратегии $strat_num${NC}"
        echo "⚠  Возможно стратегия содержит ошибки"
        return 1
    fi
    
    echo -e "${GREEN}✅ Zapret успешно перезапущен${NC}"
    
    # Выводим инструкции для тестирования
    echo -e "\n${YELLOW}📱 ИНСТРУКЦИЯ ДЛЯ ТЕСТИРОВАНИЯ:${NC}"
    echo "────────────────────────"
    echo "1. 📴 Закройте ВЕСЬ браузер полностью"
    echo "2. 🔄 Откройте браузер заново"
    echo "3. 🌐 Перейдите на youtube.com"
    echo "4. ▶️  Попробуйте открыть любое видео"
    echo ""
    echo -e "${CYAN}❓ YouTube работает нормально?${NC}"
    echo ""
    echo -e "${GREEN}[Y] ДА${NC} - видео загружается, нет ошибок"
    echo -e "${RED}[N] НЕТ${NC} - видео не грузится, есть ошибки"
    echo -e "${YELLOW}[S] ПРОПУСТИТЬ${NC} - не тестировал"
    echo ""
    echo -n "Ваш выбор (Y/N/S): "
    
    read -r user_answer
    echo ""
    
    case "$user_answer" in
        [YyДд]|"")
            # YouTube работает
            echo -e "${GREEN}🎉 УСПЕХ! Стратегия $strat_num РАБОТАЕТ!${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | Стратегия $strat_num | ✅ РАБОТАЕТ" >> "$TEST_RESULTS"
            
            # Предлагаем сохранить как основную
            echo -e "\n${YELLOW}💾 СОХРАНИТЬ эту стратегию как основную?${NC}"
            echo -n "Сохранить и завершить тестирование? (Y/N): "
            read -r save_answer
            
            if [[ "$save_answer" =~ [YyДд] ]]; then
                echo -e "${GREEN}✅ Стратегия $strat_num сохранена как основная${NC}"
                echo "🏁 Тестирование завершено успешно!"
                return 2  # Код 2 = стратегия работает и сохранена
            else
                echo "➡️  Продолжаем тестирование других стратегий..."
                return 0  # Код 0 = стратегия работает, но продолжаем
            fi
            ;;
        [NnНн])
            # YouTube не работает
            echo -e "${RED}❌ Стратегия $strat_num НЕ РАБОТАЕТ${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | Стратегия $strat_num | ❌ НЕ РАБОТАЕТ" >> "$TEST_RESULTS"
            return 1  # Код 1 = стратегия не работает
            ;;
        [SsСс])
            # Пропустить
            echo -e "${YELLOW}⏭️  Стратегия $strat_num пропущена${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | Стратегия $strat_num | ⏭️  ПРОПУЩЕНА" >> "$TEST_RESULTS"
            return 3  # Код 3 = пропущена
            ;;
        *)
            echo -e "${RED}⚠️  Неверный ввод. Стратегия помечена как не тестированная${NC}"
            return 3
            ;;
    esac
}

# Автоматическое тестирование всех стратегий
auto_test_all_strategies() {
    echo -e "${PURPLE}🚀 АВТОМАТИЧЕСКОЕ ТЕСТИРОВАНИЕ ВСЕХ СТРАТЕГИЙ${NC}"
    echo "================================================"
    echo "Будет протестировано 16 стратегий по очереди."
    echo "Нажмите Ctrl+C в любой момент для остановки."
    echo ""
    
    # Создаем файл результатов если его нет
    > "$TEST_RESULTS"
    echo "# Результаты тестирования YouTube стратегий" >> "$TEST_RESULTS"
    echo "# Дата начала: $(date)" >> "$TEST_RESULTS"
    echo "==========================================" >> "$TEST_RESULTS"
    
    local tested=0
    local working=0
    local not_working=0
    local skipped=0
    
    for i in $(seq 1 16); do
        # Проверяем существует ли файл стратегии
        if [ ! -f "$STRATEGIES_DIR/strategy$i.txt" ]; then
            echo -e "${YELLOW}⚠️  Стратегия $i не найдена, пропускаем...${NC}"
            continue
        fi
        
        echo -e "\n${BLUE}════════════════════════════════════════${NC}"
        echo -e "${CYAN}          ТЕСТ $i ИЗ 16          ${NC}"
        echo -e "${BLUE}════════════════════════════════════════${NC}"
        
        # Тестируем стратегию
        test_single_strategy $i
        result_code=$?
        
        # Обрабатываем результаты
        case $result_code in
            0)  # Работает, но продолжаем
                ((working++))
                ((tested++))
                echo -e "${GREEN}✅ Стратегия работает (продолжаем тестирование)${NC}"
                ;;
            1)  # Не работает
                ((not_working++))
                ((tested++))
                echo -e "${RED}❌ Стратегия не работает${NC}"
                ;;
            2)  # Работает и сохранена - завершаем
                ((working++))
                ((tested++))
                echo -e "${GREEN}🎯 Стратегия работает и сохранена как основная!${NC}"
                echo -e "${CYAN}🏆 Найдена рабочая стратегия!${NC}"
                show_test_results
                return 0
                ;;
            3)  # Пропущена
                ((skipped++))
                echo -e "${YELLOW}⏭️  Стратегия пропущена${NC}"
                ;;
        esac
        
        # Если не последняя стратегия, делаем паузу
        if [ $i -lt 16 ] && [ $result_code -ne 2 ]; then
            echo -e "\n${YELLOW}⏳ Переход к следующей стратегии через 5 секунд...${NC}"
            echo "   Нажмите Ctrl+C для остановки"
            for sec in {5..1}; do
                echo -ne "   $sec...\r"
                sleep 1
            done
            echo -ne "                    \r"
        fi
    done
    
    # Показываем итоги
    echo -e "\n${PURPLE}════════════════════════════════════════${NC}"
    echo -e "${CYAN}          ТЕСТИРОВАНИЕ ЗАВЕРШЕНО          ${NC}"
    echo -e "${PURPLE}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📊 ИТОГИ:${NC}"
    echo "────────────────────────"
    echo -e "${GREEN}✅ Работающих: $working${NC}"
    echo -e "${RED}❌ Не работающих: $not_working${NC}"
    echo -e "${YELLOW}⏭️  Пропущенных: $skipped${NC}"
    echo -e "${BLUE}📋 Всего протестировано: $tested${NC}"
    echo ""
    
    if [ $working -gt 0 ]; then
        echo -e "${GREEN}🎉 Найдено $working работающих стратегий!${NC}"
        echo "Рекомендуется использовать первую рабочую стратегию."
    else
        echo -e "${RED}😔 Работающих стратегий не найдено${NC}"
        echo "Попробуйте:"
        echo "1. Проверить интернет соединение"
        echo "2. Перезагрузить роутер"
        echo "3. Проверить логи Zapret"
    fi
    
    show_test_results
}

# Показать результаты тестов
show_test_results() {
    if [ -f "$TEST_RESULTS" ] && [ -s "$TEST_RESULTS" ]; then
        echo -e "\n${YELLOW}📜 РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ:${NC}"
        echo "=========================================="
        
        # Читаем и форматируем результаты
        local results=$(grep -v "^#" "$TEST_RESULTS" | grep -v "==========================================")
        
        if [ -n "$results" ]; then
            echo "$results" | while read line; do
                if echo "$line" | grep -q "✅ РАБОТАЕТ"; then
                    echo -e "${GREEN}$line${NC}"
                elif echo "$line" | grep -q "❌ НЕ РАБОТАЕТ"; then
                    echo -e "${RED}$line${NC}"
                elif echo "$line" | grep -q "⏭️  ПРОПУЩЕНА"; then
                    echo -e "${YELLOW}$line${NC}"
                else
                    echo "$line"
                fi
            done
        else
            echo "Результаты тестирования отсутствуют."
        fi
        
        echo "=========================================="
        
        # Показываем рекомендации
        local last_working=$(grep "✅ РАБОТАЕТ" "$TEST_RESULTS" | tail -1)
        if [ -n "$last_working" ]; then
            echo -e "\n${GREEN}💡 РЕКОМЕНДАЦИЯ:${NC}"
            echo "Используйте последнюю работающую стратегию:"
            echo "$last_working"
        fi
    else
        echo -e "\n${YELLOW}📜 Результаты тестирования отсутствуют${NC}"
        echo "Запустите тестирование чтобы получить результаты."
    fi
}

# Ручной режим тестирования
manual_test_mode() {
    while true; do
        show_header
        show_status
        
        echo -e "\n${CYAN}🔧 РУЧНОЙ РЕЖИМ ТЕСТИРОВАНИЯ${NC}"
        echo "────────────────────────"
        echo "1-16  - Тестировать конкретную стратегию"
        echo "t     - Показать результаты тестов"
        echo "r     - Перезапустить Zapret"
        echo "l     - Показать логи"
        echo "s     - Создать файлы стратегий"
        echo "q     - Вернуться в главное меню"
        echo ""
        
        echo -n "📝 Ваш выбор: "
        read -r choice
        
        case "$choice" in
            [1-9]|1[0-6])
                test_single_strategy "$choice"
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
                ;;
            t|T)
                show_test_results
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
                ;;
            r|R)
                echo "🔄 Перезапуск Zapret..."
                /etc/init.d/zapret restart
                sleep 3
                if pgrep -f "nfqws" > /dev/null; then
                    echo -e "${GREEN}✅ Zapret перезапущен${NC}"
                else
                    echo -e "${RED}❌ Ошибка перезапуска${NC}"
                fi
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
                ;;
            l|L)
                echo -e "\n${YELLOW}📋 ПОСЛЕДНИЕ ЛОГИ ZAPRET:${NC}"
                echo "────────────────────────"
                tail -15 "$LOG_FILE" 2>/dev/null || echo "Файл логов не найден"
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
                ;;
            s|S)
                create_strategies
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
                ;;
            q|Q)
                return 0
                ;;
            *)
                echo -e "${RED}⚠️  Неверный выбор${NC}"
                sleep 1
                ;;
        esac
    done
}

# Показать системную информацию
show_system_info() {
    echo -e "\n${YELLOW}💻 СИСТЕМНАЯ ИНФОРМАЦИЯ:${NC}"
    echo "────────────────────────"
    echo "📅 Дата: $(date)"
    echo "⏱️  Аптайм: $(uptime -p)"
    echo ""
    echo "🧮 Память:"
    free -h | grep -E "^Mem|^Пам" || free -h | head -2
    echo ""
    echo "🌐 Сеть:"
    ifconfig | grep -A1 "eth\|wlan\|br-lan" | grep -v "^--" | head -6
}

# Главное меню
main_menu() {
    while true; do
        show_header
        show_status
        
        echo -e "\n${GREEN}📱 ГЛАВНОЕ МЕНЮ${NC}"
        echo "────────────────────────"
        echo "A - 🚀 Автотест ВСЕХ стратегий (рекомендуется)"
        echo "M - 🔧 Ручное тестирование"
        echo "T - 📜 Результаты тестов"
        echo "I - 💻 Информация о системе"
        echo "C - 🛠️  Создать файлы стратегий"
        echo "Q - 🚪 Выход"
        echo ""
        
        echo -e "${BLUE}💡 СОВЕТ:${NC} Используйте автотест (A) для"
        echo "автоматического поиска работающей стратегии."
        echo ""
        
        echo -n "🎯 Ваш выбор: "
        read -r choice
        
        case "$choice" in
            a|A)
                auto_test_all_strategies
                echo ""
                echo -n "Нажмите Enter для возврата в меню..."
                read -r
                ;;
            m|M)
                manual_test_mode
                ;;
            t|T)
                show_test_results
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
                ;;
            i|I)
                show_system_info
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
                ;;
            c|C)
                create_strategies
                echo ""
                echo -n "Нажмите Enter для продолжения..."
                read -r
                ;;
            q|Q)
                echo -e "\n${CYAN}👋 До свидания!${NC}"
                echo "Не забудьте перезапустить браузер после смены стратегии."
                exit 0
                ;;
            *)
                echo -e "${RED}⚠️  Неверный выбор${NC}"
                sleep 1
                ;;
        esac
    done
}

# Обработка аргументов командной строки
case "$1" in
    "--auto"|"-a")
        auto_test_all_strategies
        ;;
    "--test"|"-t")
        if [ -n "$2" ]; then
            test_single_strategy "$2"
        else
            echo "Использование: $0 --test <номер_стратегии>"
            exit 1
        fi
        ;;
    "--create"|"-c")
        create_strategies
        ;;
    "--results"|"-r")
        show_test_results
        ;;
    "--help"|"-h")
        echo "YouTube Strategies Auto-Tester для Zapret-Manager"
        echo ""
        echo "Использование:"
        echo "  $0              - Запустить интерактивное меню"
        echo "  $0 --auto       - Автоматическое тестирование всех стратегий"
        echo "  $0 --test N     - Тестировать конкретную стратегию N (1-16)"
        echo "  $0 --create     - Создать файлы стратегий"
        echo "  $0 --results    - Показать результаты тестов"
        echo "  $0 --help       - Показать эту справку"
        echo ""
        echo "Пример:"
        echo "  $0 --auto       # Найти работающую стратегию"
        echo "  $0 --test 5     # Протестировать стратегию 5"
        exit 0
        ;;
    *)
        main_menu
        ;;
esac
