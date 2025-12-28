#!/bin/ash
# Установщик меню стратегий YouTube для Zapret-Manager на OpenWrt
# Гарантированная совместимость с ash, проверка зависимостей

set -e  # Выход при любой ошибке

echo "========================================="
echo "  УСТАНОВЩИК МЕНЮ СТРАТЕГИЙ YOUTUBE"
echo "  Для OpenWrt с Zapret-Manager"
echo "  Версия: $(date +%Y%m%d)"
echo "========================================="
echo ""

# 1. ПРОВЕРКА СИСТЕМЫ
echo "🔍 ПРОВЕРКА СИСТЕМЫ..."
echo "────────────────────────"

# Проверка прав root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ ОШИБКА: Требуются права root"
    echo "   Запустите: sudo $0"
    exit 1
fi
echo "✅ Права root подтверждены"

# Проверка наличия wget
if ! command -v wget >/dev/null 2>&1; then
    echo "❌ ОШИБКА: wget не найден"
    echo "   Установите: opkg update && opkg install wget"
    exit 1
fi
echo "✅ wget доступен"

# Проверка установки Zapret-Manager
echo "📦 Проверяем Zapret-Manager..."
ZAPRET_NFQ="/opt/zapret/nfq/nfqws"
ZAPRET_INIT="/etc/init.d/zapret"

if [ ! -f "$ZAPRET_NFQ" ]; then
    echo "❌ ОШИБКА: Zapret-Manager не найден!"
    echo ""
    echo "📋 РЕШЕНИЕ: Установите Zapret-Manager сначала:"
    echo "   1. cd /tmp"
    echo "   2. wget https://github.com/mataf0n/Zapret-Manager/raw/main/install.sh"
    echo "   3. chmod +x install.sh"
    echo "   4. ./install.sh"
    echo ""
    echo "🔗 Или: https://github.com/mataf0n/Zapret-Manager#установка"
    exit 1
fi
echo "✅ Zapret-Manager найден"

# Проверка запущен ли Zapret
if pgrep -f "nfqws" >/dev/null; then
    echo "✅ Zapret работает"
else
    echo "⚠️  Внимание: Zapret не запущен"
    echo "   После установки запустите: /etc/init.d/zapret start"
fi

# 2. УСТАНОВКА
echo ""
echo "🚀 УСТАНОВКА..."
echo "────────────────────────"

# Создание директорий
echo "📁 Создаем директории..."
for dir in "/opt/zapret/strategies" "/opt/zapret/backups" "/usr/local/bin"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "   ✅ Создана: $dir"
    else
        echo "   ✓ Уже существует: $dir"
    fi
done

# 3. ЗАГРУЗКА И ИСПРАВЛЕНИЕ СКРИПТА
echo ""
echo "⬇️  Загружаем скрипт меню..."

MENU_URL="https://raw.githubusercontent.com/mataf0n/Zapret-Manager/mataf0n-patch-2/scripts/youtube-menu/zapret-menu.sh"
TEMP_FILE="/tmp/zapret-menu-$$.sh"  # Уникальное имя временного файла
INSTALLED_FILE="/usr/local/bin/zapret-menu.sh"

if wget --no-check-certificate --timeout=30 -q "$MENU_URL" -O "$TEMP_FILE"; then
    echo "✅ Файл загружен"
    
    # Исправление для ash
    echo "🔧 Исправляем для совместимости с ash..."
    
    # 1. Инкременты
    sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*\)++/\1=$((\1 + 1))/g' "$TEMP_FILE"
    
    # 2. Шебанг (на всякий случай)
    sed -i '1s|#!/bin/bash|#!/bin/ash|' "$TEMP_FILE"
    sed -i '1s|#!/usr/bin/env bash|#!/bin/ash|' "$TEMP_FILE"
    
    # 3. Проверка синтаксиса
    echo "📝 Проверяем синтаксис..."
    if ash -n "$TEMP_FILE"; then
        echo "✅ Синтаксис правильный"
    else
        echo "❌ ОШИБКА СИНТАКСИСА! Пропускаем установку."
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    # 4. Копирование на постоянное место
    cp "$TEMP_FILE" "$INSTALLED_FILE"
    chmod 755 "$INSTALLED_FILE"
    rm -f "$TEMP_FILE"
    
    echo "✅ Скрипт установлен: $INSTALLED_FILE"
else
    echo "❌ ОШИБКА ЗАГРУЗКИ!"
    echo "   Проверьте:"
    echo "   1. Подключение к интернету"
    echo "   2. Доступность GitHub"
    exit 1
fi

# 4. СОЗДАНИЕ КОМАНД
echo ""
echo "🔗 Создаем команды для удобства..."

# Основная команда youtube-tester
cat > /usr/local/bin/youtube-tester << 'EOF'
#!/bin/ash
# Обёртка для zapret-menu.sh
exec /usr/local/bin/zapret-menu.sh "$@"
EOF
chmod 755 /usr/local/bin/youtube-tester
echo "✅ Команда: youtube-tester"

# Дополнительный алиас (опционально)
if [ -f /etc/profile ]; then
    if ! grep -q "alias yt-test=" /etc/profile; then
        echo "alias yt-test='/usr/local/bin/zapret-menu.sh'" >> /etc/profile
        echo "✅ Алиас добавлен в /etc/profile (перезайдите в shell)"
    fi
fi

# 5. СОЗДАНИЕ СТРАТЕГИЙ
echo ""
echo "⚙️  Создаем файлы стратегий..."
if /usr/local/bin/zapret-menu.sh --create >/tmp/zapret-strategies.log 2>&1; then
    echo "✅ Файлы стратегий созданы"
    STRAT_COUNT=$(ls -1 /opt/zapret/strategies/strategy*.txt 2>/dev/null | wc -l)
    echo "   Создано файлов: $STRAT_COUNT/16"
else
    echo "⚠️  Предупреждение: Не удалось создать все файлы стратегий"
    echo "   Вы можете создать их позже: zapret-menu.sh --create"
fi

# 6. ФИНАЛЬНАЯ ПРОВЕРКА
echo ""
echo "🔍 ФИНАЛЬНАЯ ПРОВЕРКА..."

if [ -x "$INSTALLED_FILE" ]; then
    echo "✅ Исполняемый файл на месте: $INSTALLED_FILE"
    echo "✅ Версия скрипта: $($INSTALLED_FILE --help | head -1)"
else
    echo "❌ Файл неисполняемый или отсутствует"
    exit 1
fi

# 7. ИТОГОВОЕ СООБЩЕНИЕ
echo ""
echo "========================================="
echo "🎉 УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА!"
echo "========================================="
echo ""
echo "🚀 КОМАНДЫ ДЛЯ ЗАПУСКА:"
echo "   zapret-menu.sh        # Основная команда"
echo "   youtube-tester        # Короткий вариант"
echo "   yt-test              # Алиас (после перезахода)"
echo ""
echo "📚 КРАТКАЯ ИНСТРУКЦИЯ:"
echo "   1. Запустите: zapret-menu.sh"
echo "   2. Нажмите 'A' для автотеста"
echo "   3. Следуйте инструкциям на экране"
echo "   4. После нахождения стратегии перезапустите браузер"
echo ""
echo "🔧 ДОПОЛНИТЕЛЬНЫЕ КОМАНДЫ:"
echo "   zapret-menu.sh --auto    # Прямой запуск автотеста"
echo "   zapret-menu.sh --test 5  # Тест конкретной стратегии"
echo "   zapret-menu.sh --help    # Вся справка"
echo ""
echo "🛠️  ЕСЛИ ВОЗНИКЛИ ПРОБЛЕМЫ:"
echo "   1. Проверьте что Zapret запущен: /etc/init.d/zapret status"
echo "   2. Посмотрите логи: tail -20 /var/log/zapret.log"
echo "   3. Проверьте процессы: ps | grep nfqws"
echo ""
echo "🌐 ДОКУМЕНТАЦИЯ:"
echo "   https://github.com/mataf0n/Zapret-Manager"
echo "========================================="
