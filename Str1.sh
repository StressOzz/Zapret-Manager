#!/bin/sh
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
BLUE="\033[0;34m"
NC="\033[0m"
GRAY="\033[38;5;239m"
DGRAY="\033[38;5;236m"
WORKDIR="/tmp/zapret-update"
CONF="/etc/config/zapret"
# v5.5
clear
echo -e "${MAGENTA}Редактируем стратегию${NC}\n"
# Проверка, установлен ли Zapret
if [ ! -f /etc/init.d/zapret ]; then
echo -e "${RED}Zapret не установлен!${NC}"
echo -e ""
read -p "Нажмите Enter для выхода в главное меню..." dummy
return
fi
echo -e "${GREEN}🔴 ${CYAN}Меняем стратегию${NC}"
# Удаляем строку и всё, что идёт ниже строки с option NFQWS_OPT '
sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" /etc/config/zapret
# Вставляем новый блок сразу после строки option NFQWS_OPT '
cat <<'EOF' >> /etc/config/zapret
option NFQWS_OPT '
--filter-tcp=443
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--dpi-desync=fake,multidisorder
--dpi-desync-split-seqovl=681
--dpi-desync-split-pos=1
--dpi-desync-fooling=badseq
--dpi-desync-badseq-increment=10000000
--dpi-desync-repeats=2
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com
--new
--filter-udp=443
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--dpi-desync=fake
--dpi-desync-repeats=4
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
'
EOF
# Проверка и перезапись файла исключений пользователей
sed -i \
'/^play\.google\.com$/d; \
/^android\.com$/d; \
/^google-analytics\.com$/d; \
/^googleusercontent\.com$/d; \
/^gstatic\.com$/d; \
/^gvt1\.com$/d; \
/^ggpht\.com$/d; \
/^dl\.google\.com$/d; \
/^dl-ssl\.google\.com$/d; \
/^android\.clients\.google\.com$/d; \
/^gvt2\.com$/d; \
/^gvt3\.com$/d' /opt/zapret/ipset/zapret-hosts-user-exclude.txt
# Скачиваем список доменов и добавляем
echo -e "${GREEN}🔴 ${CYAN}Добавляем домены в ${NC}hostlist${CYAN} и редактируем ${NC}/etc/hosts\n"
exclude_file="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"
remote_url="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/exclude-list.txt"
tmpfile=$(mktemp)
if ! curl -fsSL "$remote_url" -o "$tmpfile"; then
echo -e "${RED}Не удалось загрузить список с GitHub!${NC}\n"
read -p "Нажмите Enter для выхода в главное меню..." dummy
else
while read -r domain; do
# пропускаем пустые строки и строки с #
[[ -z "$domain" || "$domain" == \#* ]] && continue
grep -Fxq "$domain" "$exclude_file" || echo "$domain" >> "$exclude_file"
done < "$tmpfile"
fi
rm -f "$tmpfile"
# Проверка и добавление hosts
file="/etc/hosts"
cat <<'EOF' | grep -Fxv -f "$file" 2>/dev/null >> "$file"
130.255.77.28 ntc.party
57.144.222.34 instagram.com www.instagram.com
173.245.58.219 rutor.info d.rutor.info
193.46.255.29 rutor.info
157.240.9.174 instagram.com www.instagram.com
EOF
/etc/init.d/dnsmasq restart >/dev/null 2>&1
# Применяем конфиг
{ chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1; }
echo -e "${BLUE}🔴 ${GREEN}Стратегия отредактирована!${NC}"
echo -e ""
read -p "Нажмите Enter для выхода в главное меню..." dummy
