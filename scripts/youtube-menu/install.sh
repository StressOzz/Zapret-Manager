#!/bin/sh
# Enhanced YouTube Strategies Menu Installer

echo "========================================="
echo "  🚀 YouTube Strategies Enhanced Menu"
echo "  Автоматический тестер стратегий"
echo "========================================="
echo ""

# Check Zapret
if [ ! -f "/opt/zapret/nfq/nfqws" ]; then
    echo "❌ Ошибка: Zapret-Manager не установлен!"
    echo "Установите Zapret-Manager сначала:"
    echo "https://github.com/StressOzz/Zapret-Manager"
    exit 1
fi

echo "✅ Zapret-Manager обнаружен"

# Download enhanced menu
echo "📥 Загружаем улучшенное меню..."
wget -q -O /usr/local/bin/zapret-menu-enhanced.sh \
    https://raw.githubusercontent.com/mataf0n/Zapret-Manager/main/scripts/youtube-menu/zapret-menu-enhanced.sh

if [ $? -ne 0 ]; then
    echo "❌ Ошибка загрузки"
    exit 1
fi

chmod +x /usr/local/bin/zapret-menu-enhanced.sh

# Create symlinks
echo "🔗 Создаем команды..."
ln -sf /usr/local/bin/zapret-menu-enhanced.sh /usr/bin/zapret-test 2>/dev/null
ln -sf /usr/local/bin/zapret-menu-enhanced.sh /usr/bin/youtube-tester 2>/dev/null

# Create strategy files
echo "📁 Создаем файлы стратегий..."
/usr/local/bin/zapret-menu-enhanced.sh --create > /dev/null 2>&1

echo ""
echo "========================================="
echo "  ✅ УСТАНОВКА ЗАВЕРШЕНА!"
echo "========================================="
echo ""
echo "📱 Доступные команды:"
echo "  zapret-test          - Запустить автотестер"
echo "  youtube-tester       - Альтернативная команда"
echo ""
echo "🚀 Быстрый старт:"
echo "  1. Запустите: zapret-test"
echo "  2. Нажмите 'A' для автоматического тестирования"
echo "  3. Следуйте инструкциям на экране"
echo ""
echo "💡 Функции:"
echo "  • Автотест 16 стратегий"
echo "  • Сохранение результатов"
echo "  • Рекомендации по стратегиям"
echo "  • Системная диагностика"
echo ""
echo "GitHub: https://github.com/mataf0n/Zapret-Manager"
echo "========================================="
