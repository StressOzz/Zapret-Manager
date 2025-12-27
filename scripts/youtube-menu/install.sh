#!/bin/sh
# YouTube Strategies Menu Installer
# URL: https://github.com/mataf0n/Zapret-Manager

echo "========================================="
echo "  YouTube Strategies Menu Installer"
echo "========================================="
echo ""

# Check if Zapret is installed
if [ ! -f "/opt/zapret/nfq/nfqws" ]; then
    echo "ERROR: Zapret-Manager not found!"
    echo "Please install Zapret-Manager first:"
    echo "https://github.com/StressOzz/Zapret-Manager"
    exit 1
fi

echo "✓ Zapret-Manager detected"

# Download menu script
echo "Downloading menu..."
wget -q -O /tmp/zapret-menu.sh \
    https://raw.githubusercontent.com/mataf0n/Zapret-Manager/main/scripts/youtube-menu/zapret-menu.sh

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download menu script"
    exit 1
fi

# Install menu
echo "Installing menu..."
mv /tmp/zapret-menu.sh /usr/local/bin/zapret-menu.sh
chmod +x /usr/local/bin/zapret-menu.sh

# Create symlinks
echo "Creating commands..."
ln -sf /usr/local/bin/zapret-menu.sh /usr/bin/zapret-menu 2>/dev/null
ln -sf /usr/local/bin/zapret-menu.sh /usr/bin/zapret-manager 2>/dev/null

# Create strategy files
echo "Creating strategy files..."
zapret-menu.sh --create > /dev/null 2>&1

echo ""
echo "========================================="
echo "  INSTALLATION COMPLETE!"
echo "========================================="
echo ""
echo "Usage:"
echo "  zapret-menu     - Start the menu"
echo "  zapret-manager  - Alternative command"
echo ""
echo "First steps:"
echo "  1. Run: zapret-menu"
echo "  2. Select strategy (1-16)"
echo "  3. Press 'r' to restart Zapret"
echo "  4. Restart browser"
echo ""
echo "GitHub: https://github.com/mataf0n/Zapret-Manager"
echo "========================================="
