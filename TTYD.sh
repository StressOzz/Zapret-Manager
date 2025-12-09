#!/bin/sh
clear
echo -e 'sh <(wget -O - https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh)' > /usr/bin/zms
chmod +x /usr/bin/zms
echo -e "\033[1;32mУстановка \033[0mttyd"
opkg update >/dev/null 2>&1
opkg install ttyd >/dev/null 2>&1
sed -i "s#/bin/login#sh /usr/bin/zms#" /etc/config/ttyd
/etc/init.d/ttyd restart >/dev/null 2>&1
if pidof ttyd >/dev/null
then echo -e "\033[1;32mСлужба запущена!\nДоступ: \033[0mhttp://192.168.1.1:7681\n"
else echo -e "\033[1;31mСлужба не запущена!\033[0m"
fi
