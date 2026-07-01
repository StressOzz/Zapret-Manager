#!/bin/sh
set -eu

GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m"

IN="/root/WARP.conf"
OUT="/etc/mihomo/config.yaml"
TMP="$(mktemp)"

PAUSE() { echo -ne "\nНажмите Enter..."; read dummy; }

[ -r "$IN" ] || { echo -e "\n${RED}Файл ${NC}$IN ${RED}отсутвтвует!${NC}"; PAUSE; exit 1; }
command -v awk >/dev/null 2>&1 || { echo -e "\n${RED}Отсутвтвует ${NC}awk"; PAUSE; exit 1; }

awk -v OUT="$TMP" '
function trim(s){ gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s); return s }
function lc(s){ return tolower(s) }
function yaml_quote(s){
  gsub(/\\/,"\\\\",s)
  gsub(/"/,"\\\"",s)
  gsub(/\r/,"",s)
  return "\"" s "\""
}
function split_endpoint(s,    a,n){
  s=trim(s)
  n=split(s,a,":")
  if(n<2){ host=s; port="" } else {
    port=a[n]
    host=a[1]
    for(i=2;i<n;i++) host=host ":" a[i]
  }
}
BEGIN{
  sec=""
  addr4=""; addr6=""; dns=""; mtu=""
  priv=""; pub=""; psk=""; allowed=""; endpoint=""; keep=""
  s1=""; s2=""; s3=""; s4=""; jc=""; jmin=""; jmax=""; h1=""; h2=""; h3=""; h4=""
  i1=""; i2=""; i3=""; i4=""; i5=""
}
{
  raw=$0
  line=$0
  sub(/[;#].*$/, "", line)
  line=trim(line)
  if(line=="") next

  if(line ~ /^\[.*\]$/){
    sec=lc(trim(substr(line,2,length(line)-2)))
    next
  }

  if(index(line,"=")==0) next
  key=trim(substr(line,1,index(line,"=")-1))
  val=trim(substr(line,index(line,"=")+1))
  k=lc(key)

  if(sec=="interface"){
    if(k=="address"){
      gsub(/,/, " ", val)
      n=split(val, a, /[ \t]+/)
      for(i=1;i<=n;i++){
        if(a[i] ~ /:/) addr6=a[i]; else addr4=a[i]
      }
    } else if(k=="privatekey") priv=val
    else if(k=="dns") dns=val
    else if(k=="mtu") mtu=val
    else if(k=="s1") s1=val
    else if(k=="s2") s2=val
    else if(k=="s3") s3=val
    else if(k=="s4") s4=val
    else if(k=="jc") jc=val
    else if(k=="jmin") jmin=val
    else if(k=="jmax") jmax=val
    else if(k=="h1") h1=val
    else if(k=="h2") h2=val
    else if(k=="h3") h3=val
    else if(k=="h4") h4=val
    else if(k=="i1") i1=val
    else if(k=="i2") i2=val
    else if(k=="i3") i3=val
    else if(k=="i4") i4=val
    else if(k=="i5") i5=val
  } else if(sec=="peer"){
    if(k=="publickey") pub=val
    else if(k=="presharedkey") psk=val
    else if(k=="allowedips") { gsub(/[ \t]+/, "", val); allowed=val }
    else if(k=="endpoint") endpoint=val
    else if(k=="persistentkeepalive") keep=val
  }
}
END{
  if(priv=="" || pub=="" || endpoint==""){
    echo -e "\n${RED}В ${NC}WARP.conf${RED} отсутствуют обязательные поля!${NC}"
    PAUSE
    exit 2
  }
  split_endpoint(endpoint)

  ip=addr4; sub(/\/32$/, "", ip)
  ipv6=addr6; sub(/\/128$/, "", ipv6)

  if(allowed=="") allowed="0.0.0.0/0,::/0"
  n=split(allowed, aip, ",")
  
  allowed_block=""
  for(i=1;i<=n;i++){
    if(aip[i]=="") continue
    allowed_block = allowed_block "      - " yaml_quote(aip[i]) "\n"
  }

  print "mixed-port: 7890" > OUT
  print "allow-lan: false" >> OUT
  print "tcp-concurrent: true" >> OUT
  print "mode: rule" >> OUT
  print "log-level: error" >> OUT
  print "ipv6: false" >> OUT
  print "external-controller: 0.0.0.0:9090" >> OUT
  print "external-ui: ./UI" >> OUT
  print "external-ui-url: https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip" >> OUT
  print "secret:" >> OUT
  print "unified-delay: true" >> OUT
  print "profile:" >> OUT
  print "  store-selected: true" >> OUT
  print "  store-fake-ip: true" >> OUT
  print "" >> OUT

  print "proxy-groups:" >> OUT
  print "  - name: GLOBAL" >> OUT
  print "    type: select" >> OUT
  print "    proxies:" >> OUT
  print "      - WARP" >> OUT
  print "      - REJECT" >> OUT
  print "" >> OUT

  print "rules:" >> OUT
  print "  - \"MATCH,GLOBAL\"" >> OUT
  print "" >> OUT

  print "proxies:" >> OUT
  print "  - name: WARP" >> OUT
  print "    type: wireguard" >> OUT
  print "    server: " host >> OUT
  if(port!="") print "    port: " port >> OUT
  print "    private-key: " yaml_quote(priv) >> OUT
  print "    udp: true" >> OUT
  if(ip!="") print "    ip: " ip >> OUT
  if(ipv6!="") print "    ipv6: " ipv6 >> OUT
  print "    public-key: " yaml_quote(pub) >> OUT
  if(psk!="") print "    pre-shared-key: " yaml_quote(psk) >> OUT
  print "    allowed-ips:" >> OUT
  printf "%s", allowed_block >> OUT
  if(mtu!="") print "    mtu: " mtu >> OUT
  if(keep!="") print "    persistent-keepalive: " keep >> OUT

  if(s1!="" || s2!="" || s3!="" || s4!="" || jc!="" || jmin!="" || jmax!="" || h1!="" || h2!="" || h3!="" || h4!="" || i1!="" || i2!="" || i3!="" || i4!="" || i5!=""){
    print "    amnezia-wg-option:" >> OUT
    if(s1!="")  print "      s1: " s1 >> OUT
    if(s2!="")  print "      s2: " s2 >> OUT
    if(s3!="")  print "      s3: " s3 >> OUT
    if(s4!="")  print "      s4: " s4 >> OUT
    if(jc!="")  print "      jc: " jc >> OUT
    if(jmin!="")print "      jmin: " jmin >> OUT
    if(jmax!="")print "      jmax: " jmax >> OUT
    if(h1!="")  print "      h1: " h1 >> OUT
    if(h2!="")  print "      h2: " h2 >> OUT
    if(h3!="")  print "      h3: " h3 >> OUT
    if(h4!="")  print "      h4: " h4 >> OUT
    if(i1!="")  print "      i1: " yaml_quote(i1) >> OUT
    if(i2!="")  print "      i2: " yaml_quote(i2) >> OUT
    if(i3!="")  print "      i3: " yaml_quote(i3) >> OUT
    if(i4!="")  print "      i4: " yaml_quote(i4) >> OUT
    if(i5!="")  print "      i5: " yaml_quote(i5) >> OUT
  }
}
' "$IN"

chmod 600 "$TMP"
mkdir -p "$(dirname "$OUT")"
mv -f "$TMP" "$OUT"

/etc/init.d/mihomo reload
/etc/init.d/mihomo restart
echo -e "\n${NC}WARP${GREEN} интегрирован в ${NC}Mihomo${GREEN}!${NC}"
