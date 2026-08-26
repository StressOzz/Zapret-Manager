# this custom script runs desync to all discord media packets
# NOTE: @ih requires nft 1.0.1+ and updated kernel version. it's confirmed to work on 5.15 (openwrt 23) and not work on 5.10 (openwrt 22)

# can override in config :
NFQWS_OPT_DESYNC_DISCORD_MEDIA="${NFQWS_OPT_DESYNC_DISCORD_MEDIA:---payload discord_ip_discovery --blob=dbank:@/opt/zapret2/files/fake/quic_initial_dbankcloud_ru.bin --lua-desync=fake:blob=dbank:repeats=6}"
DISCORD_MEDIA_PORT_RANGE="${DISCORD_MEDIA_PORT_RANGE:-19294-19344,50000-50099}"

alloc_dnum DNUM_DISCORD_MEDIA
alloc_qnum QNUM_DISCORD_MEDIA

zapret_custom_daemons()
{
  # $1 - 1 - add, 0 - stop

  local opt="--qnum=$QNUM_DISCORD_MEDIA $NFQWS_OPT_DESYNC_DISCORD_MEDIA"
  do_nfqws $1 $DNUM_DISCORD_MEDIA "$opt"
}

zapret_custom_firewall()
{
    # $1 - 1 - run, 0 - stop

    local DISABLE_IPV6=1

    # Разбиваем диапазоны на два правила, чтобы multiport не ломался
    local range1="19294:19344"
    local range2="50000:50099"

    # QUIC Initial match (u32)
    local u32test="0>>22&0x3C@4>>16=0x52&&0>>22&0x3C@8=0x00010046&&0>>22&0x3C@16=0&&0>>22&0x3C@76=0"

    fw_nfqws_post $1 "-p udp -m multiport --dports $range1 -m u32 --u32 $u32test" '' $QNUM_DISCORD_MEDIA
    fw_nfqws_post $1 "-p udp -m multiport --dports $range2 -m u32 --u32 $u32test" '' $QNUM_DISCORD_MEDIA
}

zapret_custom_firewall_nft()
{
    local DISABLE_IPV6=1

    # QUIC Initial match
    local match_quic='udp length == 82
        @ih,0,32 0x00010046
        @ih,64,128 0x00000000000000000000000000000000
        @ih,192,128 0x00000000000000000000000000000000
        @ih,320,128 0x00000000000000000000000000000000
        @ih,448,128 0x00000000000000000000000000000000'

    # диапазон 1
    nft_fw_nfqws_post "udp dport 19294-19344 $match_quic" '' $QNUM_DISCORD_MEDIA

    # диапазон 2
    nft_fw_nfqws_post "udp dport 50000-50099 $match_quic" '' $QNUM_DISCORD_MEDIA
}
