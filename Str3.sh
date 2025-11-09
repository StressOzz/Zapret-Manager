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
# v6.5
clear
echo -e "${MAGENTA}Оптимизируем стратегию${NC}\n"
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
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-pos=2,sld
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com
--dpi-desync-split-seqovl=2108
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin
--dpi-desync-fooling=badsum,badseq
--new
--filter-tcp=443
--dpi-desync=fake,fakeddisorder
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--dpi-desync-split-pos=10,midsld
--dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_t2_ru.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=m.ok.ru
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls-mod=none
--dpi-desync-fakedsplit-pattern=/opt/zapret/files/fake/tls_clienthello_vk_com.bin
--dpi-desync-split-seqovl=336
--dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_gosuslugi_ru.bin
--dpi-desync-fooling=badsum,badseq
--dpi-desync-badseq-increment=0
--new
--filter-udp=443
--dpi-desync=fake
--dpi-desync-repeats=4
--dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin
'
EOF
# Редактируем /etc/hosts
echo -e "${GREEN}🔴 ${CYAN}Добавляем домены для ${NC}Youtube${CYAN} и редактируем ${NC}/etc/hosts"
file="/etc/hosts"
cat <<'EOF' | grep -Fxv -f "$file" 2>/dev/null >> "$file"
130.255.77.28 ntc.party
57.144.222.34 instagram.com www.instagram.com
173.245.58.219 rutor.info d.rutor.info
193.46.255.29 rutor.info
157.240.9.174 instagram.com www.instagram.com
EOF
/etc/init.d/dnsmasq restart >/dev/null 2>&1
# добавление исключения
file="/opt/zapret/ipset/zapret-hosts-user-exclude.txt"
rm -f "$file"
cat <<'EOF' > "$file"
gstatic.com
EOF
# Проверка и добавление YouTube hostlist
file="/opt/zapret/ipset/zapret-hosts-google.txt"
cat <<'EOF' | grep -Fxv -f "$file" 2>/dev/null >> "$file"
cdn.youtube.com
fonts.googleapis.com
fonts.gstatic.com
ggpht.com
googleapis.com
googleusercontent.com
i.ytimg.com
i9.ytimg.com
kids.youtube.com
m.youtube.com
manifest.googlevideo.com
music.youtube.com
nhacmp3youtube.com
returnyoutubedislikeapi.com
s.ytimg.com
signaler-pa.youtube.com
studio.youtube.com
tv.youtube.com
yt3.googleusercontent.com
yting.com
EOF
# дкопируем tls_clienthello_t2_ru.bin
echo -e "${GREEN}🔴 ${CYAN}Копируем ${NC}tls_clienthello_t2_ru.bin${CYAN} на устройство${NC}"
curl -sLo /opt/zapret/files/fake/tls_clienthello_t2_ru.bin https://github.com/StressOzz/Zapret-Manager/raw/refs/heads/main/tls_clienthello_t2_ru.bin
# Применяем конфиг
echo -e "${GREEN}🔴 ${CYAN}Применяем новую стратегию и настройки${NC}\n"
{ chmod +x /opt/zapret/sync_config.sh && /opt/zapret/sync_config.sh && /etc/init.d/zapret restart >/dev/null 2>&1; }
echo -e "${BLUE}🔴 ${GREEN}Стратегия отредактирована!${NC}"
echo -e ""
read -p "Нажмите Enter для выхода в главное меню..." dummy
