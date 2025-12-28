#!/bin/sh
# YouTube Strategies Menu Installer
# With auto-testing feature

echo "========================================="
echo "  🎯 YouTube Strategies Menu Installer"
echo "  With Auto-Testing Feature"
echo "========================================="
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: This script must be run as root"
    echo "Use: sudo $0"
    exit 1
fi

# Check Zapret installation
echo "🔍 Checking Zapret installation..."
if [ ! -f "/opt/zapret/nfq/nfqws" ]; then
    echo "❌ ERROR: Zapret-Manager not found!"
    echo "Please install Zapret-Manager first:"
    echo "https://github.com/StressOzz/Zapret-Manager"
    exit 1
fi
echo "✅ Zapret-Manager found"

# Create directories
echo "📁 Creating directories..."
mkdir -p /opt/zapret/strategies /opt/zapret/backups /usr/local/bin
echo "✅ Directories created"

# Download menu script
echo "⬇️  Downloading menu script..."
MENU_URL="https://raw.githubusercontent.com/mataf0n/Zapret-Manager/main/scripts/youtube-menu/zapret-menu.sh"

if wget -q "$MENU_URL" -O /usr/local/bin/zapret-menu.sh; then
    chmod +x /usr/local/bin/zapret-menu.sh
    echo "✅ Menu script downloaded"
else
    echo "❌ Error: Failed to download menu script"
    echo "Please check your internet connection"
    exit 1
fi

# Create symlinks
echo "🔗 Creating command aliases..."
ln -sf /usr/local/bin/zapret-menu.sh /usr/bin/zapret-menu 2>/dev/null || true
ln -sf /usr/local/bin/zapret-menu.sh /usr/bin/zapret-manager 2>/dev/null || true
ln -sf /usr/local/bin/zapret-menu.sh /usr/bin/youtube-tester 2>/dev/null || true
echo "✅ Command aliases created"

# Create strategy files
echo "📄 Creating strategy files..."
if /usr/local/bin/zapret-menu.sh --create > /tmp/zapret-install.log 2>&1; then
    echo "✅ Strategy files created"
else
    echo "⚠️  Warning: Some strategy files may not have been created"
    echo "You can create them later with: zapret-menu --create"
fi

echo ""
echo "========================================="
echo "  🎉 INSTALLATION COMPLETE!"
echo "========================================="
echo ""
echo "🚀 Quick Start:"
echo "  zapret-menu          - Start the menu"
echo "  youtube-tester       - Alternative command"
echo ""
echo "📱 Features:"
echo "  • Auto-testing of 16 YouTube strategies"
echo "  • Interactive interface with emojis"
echo "  • Results saving and recommendations"
echo "  • System diagnostics"
echo ""
echo "🔧 Usage:"
echo "  1. Run: zapret-menu"
echo "  2. Press 'A' for auto-testing"
echo "  3. Follow on-screen instructions"
echo "  4. Restart browser after finding working strategy"
echo ""
echo "❓ Need help? Check:"
echo "  https://github.com/mataf0n/Zapret-Manager"
echo "========================================="
