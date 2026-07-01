#!/bin/sh
set -eu

OUT="/root/AllowDomainsList.mtrickle"
WORK="/tmp/mihomo_groups.$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

REPO_TGZ="$WORK/repo.tgz"
REPO_DIR="$WORK/repo"

RED="$(printf '\033[31m')"
GRN="$(printf '\033[32m')"
YEL="$(printf '\033[33m')"
CYN="$(printf '\033[36m')"
MAG="$(printf '\033[35m')"
RST="$(printf '\033[0m')"

say() { color="$1"; shift; echo -e "${color}$*${RST}"; }

fetch() {
  u="$1"; d="$2"
  if command -v uclient-fetch >/dev/null 2>&1; then
    uclient-fetch -q -O "$d" "$u"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$d" "$u"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$d" "$u"
  else
    say "$RED" "ОШИБКА: нет uclient-fetch/wget/curl"
    exit 1
  fi
}

count_lines_human() {
  f="$1"
  bytes="$(wc -c < "$f" 2>/dev/null || echo 0)"
  nl="$(wc -l < "$f" 2>/dev/null || echo 0)"
  if [ "$bytes" -gt 0 ] && [ "$nl" -eq 0 ]; then echo 1; else echo "$nl"; fi
}

merge_lst_dir() {
  src="$1"
  [ -d "$src" ] || return 0
  find "$src" -maxdepth 1 -type f -name '*.lst' -print | while IFS= read -r f; do
    base="$(basename "$f")"
    out="$WORK/$base"
    awk '{ sub(/\r$/,""); print }' "$f" >> "$out"
  done
}

clear
say "$MAG" "Создаём список ItDog Allow Domains для MagiTrickle"

fetch "https://api.github.com/repos/itdoginfo/allow-domains/tarball/main" "$REPO_TGZ"

mkdir -p "$REPO_DIR"
tar -xzf "$REPO_TGZ" -C "$REPO_DIR"

ROOTDIR="$(find "$REPO_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[ -n "${ROOTDIR:-}" ] || { say "$RED" "ОШИБКА: не нашёл корневую папку в архиве"; exit 1; }

say "$YEL" "Вытаскивем списки Categories / Services / Subnets/IPv4/IPv6"
merge_lst_dir "$ROOTDIR/Categories"
merge_lst_dir "$ROOTDIR/Services"
merge_lst_dir "$ROOTDIR/Subnets/IPv4"
merge_lst_dir "$ROOTDIR/Subnets/IPv6"

LIST_COUNT="$(find "$WORK" -maxdepth 1 -name '*.lst' | wc -l | tr -d ' ')"
say "$MAG" "Всего файлов в работе: $YEL$LIST_COUNT"

awk '
function trim(s){ sub(/^[ \t\r\n]+/,"",s); sub(/[ \t\r\n]+$/,"",s); return s }
function tolower_ascii(s,   i,c,r,up,lo){
  up="ABCDEFGHIJKLMNOPQRSTUVWXYZ"; lo="abcdefghijklmnopqrstuvwxyz"; r=""
  for(i=1;i<=length(s);i++){ c=substr(s,i,1); p=index(up,c); if(p) c=substr(lo,p,1); r=r c }
  return r
}
function titlecase(s){ return (s==""?s:toupper(substr(s,1,1)) substr(s,2)) }
FNR==1{
  fn=FILENAME
  sub(/^.*\//,"",fn); sub(/\.lst$/,"",fn)
  grp=titlecase(tolower_ascii(fn))
}
{
  line=$0
  sub(/\r$/,"",line)
  sub(/#.*/,"",line); sub(/;.*/,"",line)
  line=trim(line)
  if(line=="") next

  if (line ~ /^[a-zA-Z]+:\/\//) {
    gsub(/^([a-zA-Z]+:\/\/)/,"",line)
    sub(/\/.*$/,"",line)
  }

  if(line ~ /^\*\./) line=substr(line,2)
  if(line ~ /^\./) line=substr(line,2)

  line=trim(line)
  if(line=="") next

  print grp "\t" line
}
' "$WORK"/*.lst > "$WORK/tagged.tsv"

TAGGED_TOTAL="$(wc -l < "$WORK/tagged.tsv" 2>/dev/null || echo 0)"
say "$MAG" "Всего строк: $YEL$TAGGED_TOTAL"
say "$CYN" "Создаём общий список. Ждите..."

awk -F '\t' '
function is_ipv4(s){ return (s ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/) }
function is_ipv4_cidr(s){ return (s ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$/) }
function is_ipv6(s){ return (s ~ /^[0-9a-fA-F:]+$/) }
function is_ipv6_cidr(s){ return (s ~ /^[0-9a-fA-F:]+\/[0-9]{1,3}$/) }
function is_domainish(s){ return (s ~ /^[A-Za-z0-9][A-Za-z0-9.-]*\.[A-Za-z0-9.-]+$/) }
function dotcount(s,  i,c,n){ n=0; for(i=1;i<=length(s);i++){ c=substr(s,i,1); if(c==".") n++ } return n }

function json_escape(s,  i,c,o){
  o=""
  for(i=1;i<=length(s);i++){
    c=substr(s,i,1)
    if(c=="\\") o=o "\\\\"
    else if(c=="\"") o=o "\\\""
    else if(c=="\r" || c=="\n") o=o ""
    else o=o c
  }
  return o
}

function rid(    x){
  "hexdump -n 4 -e \x27/1 \"%02x\"\x27 /dev/urandom 2>/dev/null" | getline x
  close("hexdump -n 4 -e \x27/1 \"%02x\"\x27 /dev/urandom 2>/dev/null")
  if(x=="") x="00000000"
  return x
}

function hsv_to_hex(h, s, v,   c,x,m,r,g,b,hh){
  c=v*s
  hh=h/60
  x=c*(1-((hh%2)-1<0?-(hh%2-1):(hh%2-1)))

  if(hh<1){r=c;g=x;b=0}
  else if(hh<2){r=x;g=c;b=0}
  else if(hh<3){r=0;g=c;b=x}
  else if(hh<4){r=0;g=x;b=c}
  else if(hh<5){r=x;g=0;b=c}
  else {r=c;g=0;b=x}

  m=v-c
  r=int((r+m)*255)
  g=int((g+m)*255)
  b=int((b+m)*255)

  return sprintf("#%02x%02x%02x",r,g,b)
}

BEGIN{
  OFS=""
  print "{\"groups\":["
  first_group=1
}

{
  g=$1; v=$2
  key=g SUBSEP v
  if(seen[key]++) next
  groups[g]=1
  vals[g, ++cnt[g]] = v
}

END{
  golden=137.508

  n=0
  for(g in groups){ glist[++n]=g }

  for(i=1;i<=n;i++) for(j=i+1;j<=n;j++) if(glist[i] > glist[j]){ t=glist[i]; glist[i]=glist[j]; glist[j]=t }

  for(gi=1; gi<=n; gi++){
    g=glist[gi]

    if(!first_group) printf(",\n")
    first_group=0

    gid=rid()

    hue=(gi*golden)%360
    color=hsv_to_hex(hue,0.65,0.95)

    print "{\"id\":\"",gid,"\",\"name\":\"",json_escape(g),"\",\"color\":\"",color,"\",\"interface\":\"Mihomo\",\"enable\":true,\"rules\":["
    first_rule=1

    m=cnt[g]
    for(i=1;i<=m;i++) vlist[i]=vals[g,i]
    for(i=1;i<=m;i++) for(j=i+1;j<=m;j++) if(vlist[i] > vlist[j]){ t=vlist[i]; vlist[i]=vlist[j]; vlist[j]=t }

    for(i=1;i<=m;i++){
      v=vlist[i]
      if(v=="") continue

      if(is_ipv6_cidr(v) || is_ipv6(v)) typ="subnet6"
      else if(is_ipv4_cidr(v) || is_ipv4(v)) typ="subnet"
      else if(is_domainish(v)){
        if(dotcount(v)>=2) typ="domain"; else typ="namespace"
      } else typ="namespace"

      if(!first_rule) printf(",\n")
      first_rule=0

      printf("{\"enable\":true,\"id\":\"%s\",\"name\":\"\",\"rule\":\"%s\",\"type\":\"%s\"}",rid(),json_escape(v),typ)
    }

    print "]}"
    delete vlist
  }

  print "]}"
}
' "$WORK/tagged.tsv" > "$OUT"

say "$GRN" "Готово!"
say "$YEL" "Файл сохранён:" "$RST""$OUT"
