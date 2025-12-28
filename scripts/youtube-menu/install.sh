#!/bin/ash
# Установщик меню стратегий YouTube для Zapret-Manager на OpenWrt

echo "========================================="
echo "  Установщик меню стратегий YouTube"
echo "  для OpenWrt с Zapret-Manager"
echo "========================================="
echo ""

# Проверка прав root
if [ "$(id -u)" -ne 0 ]; then
    echo "ОШИБКА: Этот скрипт должен запускаться от root"
    echo "Используйте: sudo $0"
    exit 1
fi

# Проверка установки Zapret
echo "Проверяем установку Zapret..."
if [ ! -f "/opt/zapret/nfq/nfqws" ]; then
    echo "ОШИБКА: Zapret не найден в /opt/zapret/nfq/"
    echo ""
    echo "Установите сначала Zapret-Manager:"
    echo "1. Подключитесь к роутеру по SSH"
    echo "2. Выполните:"
    echo "   cd /tmp"
    echo "   wget https://github.com/mataf0n/Zapret-Manager/raw/main/install.sh"
    echo "   chmod +x install.sh"
    echo "   ./install.sh"
    exit 1
fi
echo "Zapret найден"

# Создание необходимых директорий
echo "Создаем директории..."
mkdir -p /opt/zapret/strategies /opt/zapret/backups /usr/local/bin 2>/dev/null
echo "Директории созданы"

# Загрузка скрипта меню
echo "Загружаем скрипт меню..."
MENU_URL="https://raw.githubusercontent.com/mataf0n/Zapret-Manager/mataf0n-patch-2/scripts/youtube-menu/zapret-menu.sh"

if wget --no-check-certificate -q "$MENU_URL" -O /tmp/zapret-menu.sh; then
    # Исправляем инкременты для ash
    echo "Исправляем синтаксис для ash..."
    sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*\)++/\1=$((\1 + 1))/g' /tmp/zapret-menu.sh
    
    # Копируем в правильное место
    cp /tmp/zapret-menu.sh /usr/local/bin/zapret-menu.sh
    chmod +x /usr/local/bin/zapret-menu.sh
    
    # Тестируем синтаксис
    if ash -n /usr/local/bin/zapret-menu.sh; then
        echo "Скрипт меню установлен и проверен"
    else
        echo "ВНИМАНИЕ: Есть синтаксические ошибки в скрипте"
    fi
else
    echo "ОШИБКА: Не удалось загрузить скрипт меню"
    echo "Проверьте подключение к интернету"
    exit 1
fi

# Создание простых команд
echo "Создаем команды для удобства..."
cat > /usr/local/bin/youtube-tester << 'EOF'
#!/bin/ash
/usr/local/bin/zapret-menu.sh "$@"
EOF
chmod +x /usr/local/bin/youtube-tester

echo "Команды созданы"

# Создание файлов стратегий
echo "Создаем файлы стратегий..."
echo "Это может занять несколько секунд..."
/usr/local/bin/zapret-menu.sh --create 2>/dev/null || echo "Пропускаем создание стратегий"

echo ""
echo "========================================="
echo "  УСТАНОВКА ЗАВЕРШЕНА!"
echo "========================================="
echo ""
echo "Команды для запуска:"
echo "  zapret-menu.sh          - Запустить меню"
echo "  youtube-tester          - Альтернативная команда"
echo ""
echo "Быстрый старт:"
echo "  1. Запустите: zapret-menu.sh"
echo "  2. Выберите 'A' для автотестирования"
echo "  3. Следуйте инструкциям на экране"
echo ""
echo "Если меню не запускается:"
echo "  /usr/local/bin/zapret-menu.sh"
echo ""
echo "Для помощи:"
echo "  zapret-menu.sh --help"
echo "========================================="
