#!/bin/sh
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
BLUE="\033[0;34m"
NC="\033[0m"
# Версия стратегии
version="v4"
echo -e "${MAGENTA}Устанавливаем стратегию ${version}${NC}"
echo -e "${CYAN}Меняем стратегию${NC}"
# Удаляем строку и всё, что идёт ниже строки с option NFQWS_OPT '
sed -i "/^[[:space:]]*option NFQWS_OPT '/,\$d" /etc/config/zapret
# Вставляем новый блок сразу после строки option NFQWS_OPT '
cat <<EOF >> /etc/config/zapret
  option NFQWS_OPT '
#${version} УДАЛИТЕ ЭТУ СТРОЧКУ, ЕСЛИ ВНОСИТЕ ИЗМЕННЕНИЯ В СТРАТЕГИЮ !!!

--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-pos=2,sld
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=google.com
--dpi-desync-split-seqovl=2108
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fooling=badseq
--new
--filter-tcp=443
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--dpi-desync-any-protocol=1
--dpi-desync-cutoff=n5
--dpi-desync=multisplit
--dpi-desync-split-seqovl=582
--dpi-desync-split-pos=1
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/4pda.bin
--new
--filter-udp=443
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--dpi-desync=fake
--dpi-desync-repeats=4
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
'
EOF
# Проверка и перезапись файла исключений пользователей
echo -e "${CYAN}Добавляем домены в исключения"
exclude_file="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"
remote_url="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/refs/heads/main/zapret-hosts-user-exclude.txt"
# Удаляем старый файл
rm -f "$exclude_file"
# Скачиваем новый файл на его место
if ! curl -fsSL "$remote_url" -o "$exclude_file"; then
echo -e "\n${RED}Не удалось загрузить список с GitHub!${NC}"
read -p "Нажмите Enter для выхода в главное меню..." dummy
fi
# копируем 4pda.bin
echo -e "${CYAN}Копируем ${NC}4pda.bin${CYAN} на устройство${NC}"
curl -sLo /opt/zapret/files/fake/4pda.bin https://github.com/StressOzz/Zapret-Manager/raw/refs/heads/main/4pda.bin
# Редактируем /etc/hosts
echo -e "${CYAN}Редактируем ${NC}/etc/hosts"
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
echo -e "${CYAN}Применяем новую стратегию и настройки${NC}"
chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1
echo -e "${GREEN}Стратегия ${NC}${version} ${GREEN}установлена!${NC}"
