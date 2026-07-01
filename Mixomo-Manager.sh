#!/bin/sh

GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
BLUE="\033[0;34m"
NC="\033[0m"
DGRAY="\033[38;5;244m"

LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null | cut -d/ -f1)

PAUSE() { echo -ne "\nНажмите Enter..."; read dummy; }

if command -v opkg >/dev/null 2>&1; then UPDATE="opkg update"; INSTALL="opkg install"; else UPDATE="apk update"; INSTALL="apk add"; fi

if ! command -v curl >/dev/null 2>&1; then clear; echo -e "${CYAN}Устанавливаем ${NC}curl"
$UPDATE >/dev/null 2>&1 && $INSTALL curl >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить curl${NC}"; PAUSE; return 1; }; fi

if ! command -v unzip >/dev/null 2>&1; then clear; echo -e "${CYAN}Устанавливаем ${NC}unzip"
$UPDATE >/dev/null 2>&1 && $INSTALL unzip >/dev/null 2>&1 || { echo -e "\n${RED}Не удалось установить unzip!${NC}"; PAUSE; return 1; }; fi

CONFIGPATH="/etc/magitrickle/state/config.yaml"
URL_DEFAULT="https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/refs/heads/main/files/MagiTrickle/config.yaml"
URL_ITDOG="https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/refs/heads/main/files/MagiTrickle/configAD.yaml"

echo 'sh <(wget -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/Mixomo-Manager.sh)' > /usr/bin/mom; chmod +x /usr/bin/mom

magitrickle_config() {
echo -e "\n${MAGENTA}Выбор списка для MagiTrickle${NC}"
echo -e "${CYAN}1) ${GREEN}Список от${NC} ITDog"
echo -e "${CYAN}2) ${GREEN}Список от${NC} Internet Helper"
echo -e "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n"

while true; do
  echo -en "${YELLOW}Выберите пункт: ${NC}"
  read -r choice

  case "$choice" in
    1) MAGITRICKLE_CONFIG_URL="$URL_ITDOG"; break ;;
    2) MAGITRICKLE_CONFIG_URL="$URL_DEFAULT"; break ;;
    *) return ;;
  esac
done

if [ -n "$MAGITRICKLE_CONFIG_URL" ]; then
  echo -e "\n${CYAN}Скачиванем и устанавливаем список${NC}"
  wget -q -O "$CONFIGPATH" "$MAGITRICKLE_CONFIG_URL" || {
    echo -e "\n${RED}Ошибка: не удалось скачать список!${NC}"
    echo "URL: $MAGITRICKLE_CONFIG_URL"
    PAUSE
    return 1
  }

  if [ ! -s "$CONFIGPATH" ]; then
    echo -e "\n${RED}Ошибка: файл пустой или не создан:${NC} $CONFIGPATH"
    PAUSE
    return 1
  fi

  /etc/init.d/magitrickle enable >/dev/null 2>&1
  /etc/init.d/magitrickle reload >/dev/null 2>&1
  /etc/init.d/magitrickle start >/dev/null 2>&1
  /etc/init.d/magitrickle restart >/dev/null 2>&1
  echo -e "${GREEN}Список успешно изменён!${NC}"
  PAUSE
fi
}

check_status() {
  MIHOMO_STATUS="${RED}не установлен${NC}"
  HEV_STATUS="${RED}не установлен${NC}"
  MAGITRICKLE_STATUS="${RED}не установлен${NC}"

  if [ -x /etc/init.d/mihomo ]; then
    STATUS=$(/etc/init.d/mihomo status 2>/dev/null)
    case "$STATUS" in
      running|active) MIHOMO_STATUS="${GREEN}запущен${NC}" ;;
      *)              MIHOMO_STATUS="${RED}остановлен${NC}" ;;
    esac
  fi

  if [ -x /etc/init.d/hev-socks5-tunnel ]; then
    STATUS=$(/etc/init.d/hev-socks5-tunnel status 2>/dev/null)
    case "$STATUS" in
      running|active) HEV_STATUS="${GREEN}запущен${NC}" ;;
      *)              HEV_STATUS="${RED}остановлен${NC}" ;;
    esac
  fi

  if [ -x /etc/init.d/magitrickle ]; then
    STATUS=$(/etc/init.d/magitrickle status 2>/dev/null)
    case "$STATUS" in
      running|active) MAGITRICKLE_STATUS="${GREEN}запущен${NC}" ;;
      *)              MAGITRICKLE_STATUS="${RED}остановлен${NC}" ;;
    esac
  fi

  echo -e "${YELLOW}Mihomo:${NC}              $MIHOMO_STATUS"
  echo -e "${YELLOW}MagiTrickle:${NC}         $MAGITRICKLE_STATUS"
  echo -e "${YELLOW}HevSocks5Tunnel:${NC}     $HEV_STATUS"
}

PODPISKA() {
  echo -ne "\n${YELLOW}Введите ссылку на подписку (${CYAN}https://...${YELLOW}): ${NC}"
  read -r SUB_URL

  [ -z "$SUB_URL" ] && echo -e "\n${RED}Ошибка! Ссылка пустая!${NC}" && PAUSE && return

  cat > /etc/mihomo/config.yaml <<EOF
mode: rule
ipv6: false
mixed-port: 7890
log-level: error
allow-lan: false
unified-delay: true
tcp-concurrent: false
find-process-mode: off
external-controller: 0.0.0.0:9090
external-ui: ./ui
external-ui-url: https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip
routing-mark: 2
profile:
  store-selected: true
  store-fake-ip: true
  tracing: true
sniffer:
  enable: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    HTTP:
      ports: [80]
      override-destination: true
    TLS:
      ports: [443, 8443]
    QUIC:
      ports: [443, 8443]
  skip-domain:
    - Mijia Cloud
    - +.lan
    - +.local
    - +.msftconnecttest.com
    - +.msftncsi.com
    - +.3gppnetwork.org
    - +.openwrt.org
    - +.vsean.net
    - cudy.net

hosts:
  ntc.party: 130.255.77.28

proxies:

  - name: "Домашний интернет"
    type: direct

proxy-providers:

  Подписка:
    type: http
    url: "$SUB_URL"
    exclude-filter: "(?i)LTE"
    path: ./proxy-providers/sub.yaml
    interval: 86400
    health-check:
      enable: true
      url: http://www.gstatic.com/generate_204
      interval: 300
      timeout: 5000
      lazy: true

proxy-groups:

  - name: "Сервер для YouTube"
    type: select
    icon: https://www.clashverge.dev/assets/icons/youtube.svg
    proxies:
      - "Домашний интернет"
    use:
      - "Подписка"

  - name: "Сервер для остального трафика"
    type: select
    icon: https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.3/assets/svg/1f310.svg
    use:
      - "Подписка"

rule-providers:

  youtube:
    type: http
    format: yaml
    behavior: classical
    url: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/YouTube/YouTube.yaml"
    path: ./rule-providers/youtube-list.yaml
    interval: 86400

rules:
  - RULE-SET,youtube,Сервер для YouTube
  - MATCH,Сервер для остального трафика
EOF

### СКАЧИВАЕМ WEB UI
TMP1="/tmp/zashboard.zip"
DIR1="/etc/mihomo/ui"
URL1="https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"
for i in 1 2 3 4 5 6 7; do
    curl -fL --connect-timeout 5 --max-time 15 -o "$TMP1" "$URL1" >/dev/null 2>&1 && break
    sleep 2
done
[ -f "$TMP1" ] || { echo -e "\n${RED}Ошибка скачивания WEB UI!${NC}"; PAUSE; }
mkdir -p "$DIR1"
rm -rf "$DIR1"/*
unzip -o "$TMP1" -d /tmp/zashboard >/dev/null 2>&1
cp -r /tmp/zashboard/dist/* "$DIR1"/
rm -rf "$TMP1" /tmp/zashboard
###

/etc/init.d/mihomo reload >/dev/null 2>&1
/etc/init.d/mihomo restart >/dev/null 2>&1

echo -e "\n${GREEN}Подписка успешно применена!${NC}"
}

UI_INSTALL() {
while true; do
	echo -e "\n${CYAN}1) ${GREEN}Zashboard${NC}"
	echo -e "${CYAN}2) ${GREEN}MetaCubeXD${NC}"
	echo -e "${CYAN}Enter) ${GREEN}Выход в главное меню${NC}\n"
	echo -en "${YELLOW}Выберите панель для уставновки:${NC} "
	read -r choice

	case "$choice" in
	1)
		echo -e "\n${MAGENTA}Устанавливаем Zashboard${NC}"

		rm -rf /etc/mihomo/ui

		curl -fL -o /tmp/zashboard.zip \
		https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip || {
			echo -e "\n${RED}Ошибка загрузки Zashboard${NC}"
			return
		}

		mkdir -p /etc/mihomo/ui
		rm -rf /etc/mihomo/ui/*
		rm -rf /tmp/zashboard

		unzip -oq /tmp/zashboard.zip -d /tmp/zashboard || {
			echo -e "\n${RED}Ошибка распаковки архива${NC}"
			rm -rf /tmp/zashboard.zip /tmp/zashboard
			return
		}

		cp -r /tmp/zashboard/dist/* /etc/mihomo/ui/

		rm -rf /tmp/zashboard.zip /tmp/zashboard

		echo -e "\n${GREEN}Zashboard успешно установлен${NC}"
		break
		;;

	2)
		echo -e "\n${MAGENTA}Устанавливаем MetaCubeXD${NC}"

		rm -rf /etc/mihomo/ui

		curl -fL -o /tmp/metacubexd.tgz \
		https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz || {
			echo -e "\n${RED}Ошибка загрузки MetaCubeXD${NC}"
			return
		}

		mkdir -p /etc/mihomo/ui
		rm -rf /etc/mihomo/ui/*
		rm -rf /tmp/metacubexd
		mkdir -p /tmp/metacubexd

		tar -xzf /tmp/metacubexd.tgz -C /tmp/metacubexd || {
			echo -e "\n${RED}Ошибка распаковки архива${NC}"
			rm -rf /tmp/metacubexd.tgz /tmp/metacubexd
			return
		}

		cp -r /tmp/metacubexd/* /etc/mihomo/ui/

		rm -rf /tmp/metacubexd.tgz /tmp/metacubexd

		echo -e "\n${GREEN}MetaCubeXD успешно установлен${NC}"
		break
		;;

	*)
		return
		;;
	esac
done
}



show_menu() {
clear
echo -e "╔═══════════════════════════════════╗"
echo -e "║    ${BLUE}Mixomo Manager by StressOzz${NC}    ║"
echo -e "╚═══════════════════════════════════╝\n"

check_status

[ -f /etc/mihomo/config.yaml ] && while IFS='|' read -r c a; do h=${a%%:*}
grep -qF "$h" /etc/mihomo/config.yaml && echo -e "${YELLOW}WARP endpoint:       ${CYAN}$c${NC}" && break
done <<EOF
Россия|engage.cloudflareclient.com:4500
Россия #2|engage.cloudflareclient.com:2408
Россия #3|engage.cloudflareclient.com:500
EOF

if [ -f "$CONFIGPATH" ]; then
    grep -Fq 'name: Google_ai' "$CONFIGPATH" && echo -e "${YELLOW}Используется список: ${NC}ITDog"
    grep -Fq 'name: Meta (WA+FB+Instagram)' "$CONFIGPATH" && echo -e "${YELLOW}Используется список: ${NC}Internet Helper"
fi

[ -f "$CONFIGPATH" ] && echo -e "${YELLOW}Web-интерфейс MagiTrickle:${NC}  ${CYAN}$LAN_IP:8080${NC}"
[ -f /etc/mihomo/config.yaml ] && echo -e "${YELLOW}Web-интерфейс Mihomo:${NC}       ${CYAN}$LAN_IP:9090/ui${NC}"

echo -e "\n${CYAN}1) ${GREEN}Установить ${NC}Mixomo"
echo -e "${CYAN}2) ${GREEN}Удалить ${NC}Mixomo"
echo -e "${CYAN}3) ${GREEN}Сменить список ${NC}MagiTrickle"
if [ -f /etc/mihomo/config.yaml ] && grep -q 'url: "' /etc/mihomo/config.yaml; then
  echo -e "${CYAN}4) ${GREEN}Сменить ${NC}VPN${GREEN} подписку${NC}"
else
  echo -e "${CYAN}4) ${GREEN}Интегрировать ${NC}VPN${GREEN} подписку в ${NC}Mihomo${NC}"
fi
echo -e "${CYAN}5) ${GREEN}Сгенерировать ${NC}WARP ${GREEN}в ${NC}/root/WARP.conf"
echo -e "${CYAN}6) ${GREEN}Интегрировать ${NC}/root/WARP.conf${GREEN} в ${NC}Mihomo"
[ -f /etc/mihomo/config.yaml ] && echo -e "${CYAN}7) ${GREEN}Выбрать и установить панель для ${NC}Mihomo"
# echo -e "${CYAN}888) ${GREEN}Удалить ${NC}→ ${GREEN}установить ${NC}→ ${GREEN}настроить ${NC}mihomo-openwrt"
echo -e "${CYAN}Enter) ${GREEN}Выход\n"
echo -ne "${YELLOW}Выберите пункт: ${NC}"
read choiceM

case "$choiceM" in
1)
  sh <(wget -q -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/mixomo_openwrt_install.sh)
  PAUSE
  ;;

2)
  sh <(wget -q -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/mixomo_openwrt_delete.sh)
  echo -e "\n${YELLOW}Рекомендую сделать перезагрузку роутера!${NC}"
  PAUSE
  ;;

3)
  magitrickle_config
  ;;

4) 
  PODPISKA
  PAUSE
  ;;

5)
  sh <(wget -q -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/gen_WARP.sh)
  PAUSE
  ;;
6)
  sh <(wget -q -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/WARP_to_conf.sh)
  PAUSE
  ;;

7)
  UI_INSTALL
  PAUSE
  ;;
  
888)
  sh <(wget -q -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/mixomo_openwrt_delete.sh)
  sh <(wget -q -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/mixomo_openwrt_install.sh)
  sh <(wget -q -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/gen_WARP.sh)
  sh <(wget -q -O - https://raw.githubusercontent.com/StressOzz/Mixomo-Manager/main/WARP_to_conf.sh)
  PAUSE
  ;;
*)
  echo
  exit 0
  ;;
esac
}

while true; do
  show_menu
done
