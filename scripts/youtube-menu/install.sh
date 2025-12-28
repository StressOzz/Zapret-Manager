#!/bin/ash
# Установщик меню стратегий YouTube для Zapret-Manager на OpenWrt
# Гарантированная совместимость с ash, проверка зависимостей
# Автоматический запуск меню после установки

set -e  # Выход при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Проверка интерактивности терминала
check_interactive() {
    if [ -t 0 ] && [ -t 1 ]; then
        return 0  # Интерактивный режим
    else
        return 1  # Неинтерактивный (pipe, cron и т.д.)
    fi
}

show_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║    🎯 YouTube Strategies Installer       ║"
    echo "║    для Zapret-Manager на OpenWrt         ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Версия установщика: 2024.01"
    echo "Автотест 16 стратегий для обхода блокировок"
    echo ""
}

# 1. ПРОВЕРКА СИСТЕМЫ
echo -e "${CYAN}🔍 ПРОВЕРКА СИСТЕМЫ...${NC}"
echo "────────────────────────"

# Проверка прав root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ ОШИБКА: Требуются права root${NC}"
    echo "   Запустите: sudo $0"
    exit 1
fi
echo -e "${GREEN}✅ Права root подтверждены${NC}"

# Проверка наличия wget
if ! command -v wget >/dev/null 2>&1; then
    echo -e "${RED}❌ ОШИБКА: wget не найден${NC}"
    echo "   Установите: opkg update && opkg install wget"
    exit 1
fi
echo -e "${GREEN}✅ wget доступен${NC}"

# Проверка установки Zapret-Manager
echo -e "${CYAN}📦 Проверяем Zapret-Manager...${NC}"
ZAPRET_NFQ="/opt/zapret/nfq/nfqws"
ZAPRET_INIT="/etc/init.d/zapret"

if [ ! -f "$ZAPRET_NFQ" ]; then
    echo -e "${RED}❌ ОШИБКА: Zapret-Manager не найден!${NC}"
    echo ""
    echo -e "${YELLOW}📋 РЕШЕНИЕ: Установите Zapret-Manager сначала${NC}"
    echo "   Выполните команды ниже:"
    echo -e "${BLUE}   cd /tmp${NC}"
    echo -e "${BLUE}   wget https://github.com/mataf0n/Zapret-Manager/raw/main/install.sh${NC}"
    echo -e "${BLUE}   chmod +x install.sh${NC}"
    echo -e "${BLUE}   ./install.sh${NC}"
    echo ""
    echo -e "🔗 Или посетите: https://github.com/mataf0n/Zapret-Manager"
    exit 1
fi
echo -e "${GREEN}✅ Zapret-Manager найден${NC}"

# Проверка запущен ли Zapret
if pgrep -f "nfqws" >/dev/null; then
    echo -e "${GREEN}✅ Zapret работает${NC}"
else
    echo -e "${YELLOW}⚠️  Внимание: Zapret не запущен${NC}"
    echo "   После установки запустите: /etc/init.d/zapret start"
fi

# 2. УСТАНОВКА
echo ""
echo -e "${CYAN}🚀 УСТАНОВКА...${NC}"
echo "────────────────────────"

# Создание директорий
echo -e "${CYAN}📁 Создаем директории...${NC}"
for dir in "/opt/zapret/strategies" "/opt/zapret/backups" "/usr/local/bin"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "   ${GREEN}✅ Создана:${NC} $dir"
    else
        echo -e "   ${BLUE}✓ Уже существует:${NC} $dir"
    fi
done

# 3. ЗАГРУЗКА И ИСПРАВЛЕНИЕ СКРИПТА
echo ""
echo -e "${CYAN}⬇️  Загружаем скрипт меню...${NC}"

MENU_URL="https://raw.githubusercontent.com/mataf0n/Zapret-Manager/mataf0n-patch-2/scripts/youtube-menu/zapret-menu.sh"
TEMP_FILE="/tmp/zapret-menu-$$.sh"
INSTALLED_FILE="/usr/local/bin/zapret-menu.sh"

if wget --no-check-certificate --timeout=30 -q "$MENU_URL" -O "$TEMP_FILE"; then
    echo -e "${GREEN}✅ Файл загружен${NC}"
    
    # Исправление для ash
    echo -e "${CYAN}🔧 Исправляем для совместимости с ash...${NC}"
    
    # Исправляем все известные проблемы с синтаксисом ash
    sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*\)++/\1=$((\1 + 1))/g' "$TEMP_FILE"
    sed -i 's/function //g' "$TEMP_FILE"
    
    # Шебанг (на всякий случай)
    if ! head -1 "$TEMP_FILE" | grep -q "^#!/bin/ash\|^#!/bin/sh"; then
        sed -i '1s|.*|#!/bin/ash|' "$TEMP_FILE"
    fi
    
    # Проверка синтаксиса
    echo -e "${CYAN}📝 Проверяем синтаксис...${NC}"
    if ash -n "$TEMP_FILE"; then
        echo -e "${GREEN}✅ Синтаксис правильный${NC}"
    else
        echo -e "${RED}❌ ОШИБКА СИНТАКСИСА! Пропускаем установку.${NC}"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    # Копирование на постоянное место
    cp "$TEMP_FILE" "$INSTALLED_FILE"
    chmod 755 "$INSTALLED_FILE"
    rm -f "$TEMP_FILE"
    
    echo -e "${GREEN}✅ Скрипт установлен:${NC} $INSTALLED_FILE"
else
    echo -e "${RED}❌ ОШИБКА ЗАГРУЗКИ!${NC}"
    echo "   Проверьте:"
    echo "   1. Подключение к интернету"
    echo "   2. Доступность GitHub"
    exit 1
fi

# 4. СОЗДАНИЕ КОМАНД
echo ""
echo -e "${CYAN}🔗 Создаем команды для удобства...${NC}"

# Основная команда youtube-tester
cat > /usr/local/bin/youtube-tester << 'EOF'
#!/bin/ash
# Обёртка для zapret-menu.sh
exec /usr/local/bin/zapret-menu.sh "$@"
EOF
chmod 755 /usr/local/bin/youtube-tester
echo -e "${GREEN}✅ Команда:${NC} youtube-tester"

# Создаем алиас yt-test
cat > /usr/local/bin/yt-test << 'EOF'
#!/bin/ash
# Ярлык для быстрого запуска
/usr/local/bin/zapret-menu.sh "$@"
EOF
chmod 755 /usr/local/bin/yt-test
echo -e "${GREEN}✅ Команда:${NC} yt-test"

# 5. СОЗДАНИЕ СТРАТЕГИЙ
echo ""
echo -e "${CYAN}⚙️  Создаем файлы стратегий...${NC}"
echo "Это может занять несколько секунд..."

STRAT_LOG="/tmp/zapret-strategies-$$.log"
if /usr/local/bin/zapret-menu.sh --create > "$STRAT_LOG" 2>&1; then
    STRAT_COUNT=$(ls -1 /opt/zapret/strategies/strategy*.txt 2>/dev/null | wc -l)
    echo -e "${GREEN}✅ Файлы стратегий созданы${NC}"
    echo "   Создано файлов: $STRAT_COUNT/16"
    rm -f "$STRAT_LOG"
else
    echo -e "${YELLOW}⚠️  Предупреждение: Не удалось создать все файлы стратегий${NC}"
    echo "   Вы можете создать их позже: zapret-menu.sh --create"
    echo "   Логи сохранены в: $STRAT_LOG"
fi

# 6. ФИНАЛЬНАЯ ПРОВЕРКА
echo ""
echo -e "${CYAN}🔍 ФИНАЛЬНАЯ ПРОВЕРКА...${NC}"

if [ -x "$INSTALLED_FILE" ]; then
    echo -e "${GREEN}✅ Исполняемый файл на месте:${NC} $INSTALLED_FILE"
    
    # Получаем версию скрипта
    SCRIPT_VERSION=$(grep -i "version\|версия" "$INSTALLED_FILE" | head -1 | sed 's/[^0-9.]//g' || echo "1.0")
    echo -e "${GREEN}✅ Версия скрипта:${NC} $SCRIPT_VERSION"
else
    echo -e "${RED}❌ Файл неисполняемый или отсутствует${NC}"
    exit 1
fi

# 7. ИТОГОВОЕ СООБЩЕНИЕ
show_banner
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}          🎉 УСТАНОВКА УСПЕШНА!          ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

echo -e "${CYAN}🚀 КОМАНДЫ ДЛЯ ЗАПУСКА:${NC}"
echo "   zapret-menu.sh        # Основная команда"
echo "   youtube-tester        # Короткий вариант"
echo "   yt-test              # Самый короткий"
echo ""

echo -e "${CYAN}📚 ОСНОВНЫЕ КОМАНДЫ:${NC}"
echo "   zapret-menu.sh --auto    # Автотест всех стратегий"
echo "   zapret-menu.sh --test 5  # Тест конкретной стратегии"
echo "   zapret-menu.sh --help    # Полная справка"
echo ""

# 8. АВТОМАТИЧЕСКИЙ ЗАПУСК МЕНЮ
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${CYAN}        🚀 ЗАПУСК МЕНЮ ЧЕРЕЗ 5 СЕК...     ${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Нажмите Ctrl+C чтобы отменить автозапуск"
echo ""

# Таймер обратного отсчета
for i in $(seq 5 -1 1); do
    echo -ne "   Меню запустится через: ${YELLOW}$i${NC} сек...\r"
    sleep 1
done

echo -ne "                                 \r"
echo ""

# Запуск меню
echo -e "${GREEN}▶️  Запускаем меню стратегий YouTube...${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"

sleep 1

# Запуск меню с передачей управления
if check_interactive; then
    # Интерактивный режим - запускаем меню
    exec /usr/local/bin/zapret-menu.sh
else
    # Неинтерактивный режим - показываем инструкции
    echo -e "${YELLOW}⚠️  Неинтерактивный режим${NC}"
    echo "Для запуска меню выполните:"
    echo "  /usr/local/bin/zapret-menu.sh"
    echo ""
    echo -e "${CYAN}📖 ДОКУМЕНТАЦИЯ:${NC}"
    echo "   https://github.com/mataf0n/Zapret-Manager"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
fi
