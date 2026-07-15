<h1 align="center">Универсальный менеджер для обхода блокировок на OpenWrt</h1>

<div align="center">

![Platform](https://img.shields.io/badge/Platform-OpenWrt-orange)
![Architecture](https://img.shields.io/badge/Architecture-All%20(OpenWrt)-yellow)
![Script](https://img.shields.io/badge/Script-sh-informational)
![Status](https://img.shields.io/badge/Status-Active-success)
![Community](https://img.shields.io/badge/Community-Enabled-green)
[![Views](https://views.whatilearened.today/views/github/StressOzz/Zapret-Manager.svg)](https://github.com/StressOzz/Zapret-Manager)
![GitHub last commit](https://img.shields.io/github/last-commit/StressOzz/Zapret-Manager)

</div>

---

### Для Windows - используйте: **https://github.com/StressOzz/ZapretOzz**

---

> [!IMPORTANT]
> Для доступа к **github.com**, выполните в **SSH** следующую команду:
> ```
> git="github.com"; grep -q "^140.82.114.3 $git" /etc/hosts || { printf "#$git\n140.82.114.3 $git\n185.199.110.154 github.githubassets.com\n185.199.110.133 camo.githubassets.com\n" >> /etc/hosts; /etc/init.d/dnsmasq restart 2>/dev/null; }; echo -e "\033[0;32mOK\033[0m"
> ```

Чтобы удалить эту настройку, в **SSH** выполните:
```
sed -i '/#github.com/,+3d' /etc/hosts; /etc/init.d/dnsmasq restart 2>/dev/null; echo -e "\033[0;32mOK\033[0m"
```

> [!IMPORTANT]
> При возникновении проблем с запуском скрипта или его функций выполните в **SSH** следующую команду:
> ```
> git="githubusercontent.com"; grep -q "raw.$git" /etc/hosts || { printf "#$git\n185.199.109.133 raw.$git release-assets.$git\n185.199.108.133 private-user-images.$git gist.$git avatars.$git\n" >> /etc/hosts; /etc/init.d/dnsmasq restart 2>/dev/null; }; echo -e "\033[0;32mOK\033[0m"
> ```

Чтобы удалить эту настройку, в **SSH** выполните:
```
sed -i '/#githubusercontent.com/,+2d' /etc/hosts; /etc/init.d/dnsmasq restart 2>/dev/null; echo -e "\033[0;32mOK\033[0m"
```

---

<table>
  <tr>
    <td>
      <a href="https://github.com/StressOzz#-поддержать-проект">
        <img width="280" height="130" src="https://github.com/user-attachments/assets/2999757b-fbf3-4149-bf6c-48bf3e241529">
      </a>
    </td>
    <td>
      <a href="https://github.com/StressOzz/StressKVN">
        <img width="270" height="80" src="https://github.com/user-attachments/assets/7dbb964b-bb79-461a-9f47-9ca73323ebac">
      </a>
    </td>
  </tr>
</table>

---

# Оглавление
- [Возможности](#-возможности)
- [Подготовка системы](#-подготовка-системы)
- [Запуск менеджера](#-запуск-менеджера)
- [Быстрый старт](#-быстрый-старт)
- [Настройка Telegram](#-telegram)
- [Cтратегии](#-стратегии)
- [Mixomo](#-mixomo)
- [Дерево меню Zapret Manager](#-дерево-меню-zapret-manager)
- [Благодарности](#благодарности)
- [Поддержать проект](https://github.com/StressOzz)

---

## 🔹 Возможности

### Zapret Manager позволяет:

- Установить **Zapret** последней версии
- Выбрать стратегию для установки **v1-v9**
- Выбрать и установить стратегию от **Flowseal**
- Протестировать стратегии **v1-v9** и **Flowseal**
- Подобрать стратегию для **YouTube**
- Сделать резервную копию настроек **Zapret** 
- Включить стратегию для игр **Battlefield 6**, **Apex Legend**, **Roblox** и других...
- Установить скрипт для **Discord**
- Включить обход Финских **IP** для **Discord**
- Выбрать стратегию для **discord.media**
- Установить **DoH** (**DNS over HTTPS**) и выбрать **DNS**-сервер
- Получить доступ к **Zapret Manager** из браузера
- Включить блокировку **QUIC** (порты 80,443)
- Включить или выключить **IP** в **hosts**
- Открыть доступ к **AI** сервисам без **VPN**
- Разблокировать **Telegram WEB**, **rutor.info**, **ntc.party**, **lib.rus.ec**, **Instagram***
- Разблокировать разрешение на **Twitch**
- Сменить источник (выбрать зеркало) для пакетов **OpenWRT**
- Установить различные **TG WS Proxy** для **Telegram**
- Установить **NetShift** - **https://github.com/yandexru45/netshift**
- Установить **Mixomo** - **https://github.com/Internet-Helper/mixomo-openwrt**
- Интегрировать [**VPN подпиcку**](https://github.com/StressOzz/StressKVN) в **NetShift** и **Mixomo**
- Сгенерировать **WARP** и интегрировать его в **Mixomo**

---

## 🔹 Подготовка системы

> [!IMPORTANT]
>для работы некотрых стратегий, в терминале Windows необходимо один раз выполнить:
>```
>netsh int tcp set global timestamps=enabled
>```

- Если у Вас установлен **ByeDPI** или **youtubeUnblock** скрипт выдаст сообщение.
- Если у Вас включён **Flow offloading** скрипт выдаст сообщение и в `Системном меню`, появится пункт **0** - **Применить FIX**.
- [**NetShift** берёт на себя роль DNS-резолвера](https://podkop.net/docs/dns/), поэтому с установленным `DNS over HTTPS` [**NetShift не установится!**](https://podkop.net/docs/install/#nesovmestimost)

---

## 🔹 Запуск менеджера

Подключитесь по **SSH** к роутеру и выполните команду:

```
sh <(wget -O - https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh)
```
или
```
wget -O /tmp/Zapret-Manager.sh https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh && sh /tmp/Zapret-Manager.sh
```

После запуска скрипта по команде выше, скрипт можно запускать в **SSH** командой:
```
zms
```

Для запуска скрипта в браузере или в LuСI:
- запустите скрипт → Системное меню → Активировать доступ к скрипту из браузера

После установки, скрипт будет доступен:
- в браузере по адресу **http://192.168.1.1:7681**
- в LuCI вкладка **Services** → **Terminal**

---

## 🔹 Быстрый старт

**Пункт 9** - **Удалить → установить → настроить Zapret**

Установка **Zapret** под ключ:
- Удаляет Zapret
- Устанавливает последнюю версию Zapret
- Устанавливает стратегию **v7**
- Устанавливает скрипт **50-stun4all**
- Добавляет в стратегию настройки для игр
- Добавляет домены **Telegram WEB**, **AI**, **rutor.info**, **ntc.party**, **lib.rus.ec**, **Twitch**, **Instagram***  в `hosts`

>⚠️ Использовать только для полной переустановки и настройки Zapret.

## 🔹 Стратегии

Если у Вас не запускается **Youtube** на каком-либо устройстве, то попробуйте подобрать стратегию только для **YouTube**.

В скрипте, в пункте 2, затем 0 - Тестировать стратегии для `YouTube` и Тестировать `v` и `Flowseal` стратегии

- [Cтратегии для Youtube](https://github.com/StressOzz/Zapret-Manager/blob/main/Strategies_For_Youtube.md)
- [Cтратегии используемые в скрипте](https://github.com/StressOzz/Zapret-Manager/blob/main/Strategies.md)

## 🔹 Telegram

**Пункт 5** -  установка или удаление **TG WS Proxy**

В **Telegram Desktop**:
- Настройки **→** Продвинутые настройки **→** Тип соеденения **→** Добавить прокси
- Выберите **SOCKS5** / **MTPROTO**
- В поле **Хост** укажите **IP**, в **Порт** укажите **порт**
- Для **MTPROTO** в **Ключ** укажите **ключ**
- Нажмите Сохранить

В **приложении Telegram**:
- Настройки **→** Данные и память **→** Настройки прокси **→** Добавить прокси
- Выберите **SOCKS5** / **MTPROTO**
- В поле **Сервер** укажите **IP**, в **Порт** укажите **порт**
- Для **MTPROTO** в **Ключ** укажите **ключ**
- Нажмите на галочку в верхнем правом углу

---

## 🔹 Mixomo

- Интегрировать **VPN** подписку в **Mihomo**

   Вставьте ссылку на свою подписку.
   Можете воспользоваться [**StressKVN**](https://github.com/StressOzz/StressKVN)

   Зайдите на http://192.168.1.1:9090/ui 
   в поле **Хост** введите **192.168.1.1**
   во вкладке **Прокси** выберите **Сервер для YouTube** и **Сервер для остального трафика** который поёдйт через списки **MagiTrickle**
   
- Сгенерируйте **WARP** 
 
   Для генерации **WARP** через скрипт понадобится установить **[Zapret](https://github.com/StressOzz/Zapret-Manager)**
   
- Интегрируйте **WARP**

   Для интеграции своего **WARP** файла - скиньте его в `/root/WARP.conf`
   
- Зайдите на http://192.168.1.1:8080/ выберите списки, которые Вам нужны, нажмите **Сохранить изменения**

- Можете выбрать и установить панель для управления **Mihomo** - пункт **7**

- Можете включить автоперезапуск **Mihomo** - может помочь при использовании сгенерированных warp

---

## 🔹 Дерево меню Zapret Manager


<details>
<summary>Нажмите, чтобы развернуть</summary>

```text
─ 1 Установить / Удалить / Обновить Zapret

─ 2 Меню стратегий
  ├─ 0 Меню тестирование стратегий
  │  ├─ 1 Тестировать стратегии v
  │  ├─ 2 Тестировать стратегии Flowseal
  │  ├─ 3 Тестировать v и Flowseal стратегии
  │  ├─ 4 Тестировать текущую стратегию
  │  ├─ 5 Тестировать стратегии по домену
  │  ├─ 6 Тестировать стратегии для YouTube
  │  ├─ 9 Результаты тестирования стратегий
  │  ├─ 0 Удалить результаты тестования
  │  └─ Enter Выход в главное меню
  │ 
  ├─ 1 Выбрать и установить стратегию v1–v9
  ├─ 2 Выбрать и установить стратегию от Flowseal
  ├─ 3 Выбрать и установить стратегию для YouTube
  ├─ 4 Меню управления стратегиями для игр
  │  ├─ 1 Установить / Удалить Gv1
  │  ├─ 2 Установить / Удалить Gv2
  │  ├─ 3 Установить / Удалить Gv3
  │  ├─ 4 Установить / Удалить Gv4
  │  ├─ 5 Сменить fake на stun.bin / quic_initial_dbankcloud_ru.bin
  │  └─ Enter Выход в меню стратегий
  │
  ├─ 5 Включить / Выключить обход по спискам РКН
  ├─ 6 Обновить список исключений
  ├─ 7 Добавить в стратегию блок с --wssize 1:6
  ├─ 8 Добавить в стратегию блок с --methodeol
  ├─ 9 Добавить в стратегию блок с --filter-udp=443
  └─ Enter Выход в главное меню

─ 3 Меню Mixomo
  ├─ 1 Установить Mixomo
  ├─ 2 Удалить Mixomo
  ├─ 3 Сменить список MagiTrickle
  ├─ 4 Интегрировать / сменить VPN подписку в Mihomo
  ├─ 5 Сгенерировать WARP в /root/WARP.conf
  ├─ 6 Интегрировать /root/WARP.conf в Mihomo
  ├─ 7 Выбрать и установить панель для Mihomo
  ├─ 8 Включить / Выключить автоперезапуск Mihomo
  └─ Enter Выход в главное меню

─ 4 Меню NetShift
  ├─ 1 Установить / Удалить / Обновить NetShift
  ├─ 2 Установить / Удалить AWG и интерфейс AWG
  ├─ 3 Интегрировать VPN подписку в NetShift / Сменить VPN подписку в NetShift
  ├─ 4 Интегрировать AWG в NetShift
  └─ Enter Выход в главное меню
  
─ 5 Меню TG WS Proxy 
  ├─ 1 Установить / Удалить TG WS Proxy Go SOCKS5
  ├─ 2 Установить / Удалить TG WS Proxy Rust
  ├─ 3 Установить / Удалить TG WS Proxy Go MTProto
  ├─ 4 Удалить все TG WS Proxy
  └─ Enter Выход в главное меню

─ 6 Меню DNS over HTTPS
  ├─ 1 Установить / Удалить DNS over HTTPS
  ├─ 2 Настроить Comss DNS
  ├─ 3 Настроить Xbox DNS
  ├─ 4 Настроить dns.malw.link
  ├─ 5 Настроить dns.malw.link через Cloudflare
  ├─ 6 Настроить dns.mafioznik.xyz
  ├─ 7 Настроить dns.astracat.ru
  ├─ 8 Настроить dns.nullsproxy.com (Supercell)
  ├─ 0 Вернуть настройки DNS по умолчанию
  └─ Enter Выход в главное меню

─ 7 Меню настройки Discord
  ├─ 1 Установить скрипт 50-stun4all
  ├─ 2 Установить скрипт 50-quic4all
  ├─ 3 Установить скрипт 50-discord-media
  ├─ 4 Установить скрипт 50-discord
  ├─ 5 Удалить скрипт Discord
  ├─ 6 Добавить Финские IP-адреса в hosts
  ├─ 7 Выбрать и установить стратегию для discord.media
  ├─ 8 Меню выбора fake для discord,stun
  │  ├─ 1 Сменить на stun.bin
  │  ├─ 2 Сменить на quic_initial_www_google_com.bin
  │  ├─ 3 Сменить на quic_initial_dbankcloud_ru.bin
  │  └─ Enter Выход в меню настройки Discord
  │  
  └─ Enter Выход в главное меню

─ 8 Меню управления доменами в hosts
  ├─  0 Добавить / Удалить nalog.ru
  ├─  1 Добавить / Удалить rutor.info
  ├─  2 Добавить / Удалить ntc.party
  ├─  3 Добавить / Удалить Instagram* & Facebook*
  ├─  4 Добавить / Удалить lib.rus.ec
  ├─  5 Добавить / Удалить AI сервисы
  ├─  6 Добавить / Удалить Twitch
  ├─  7 Добавить / Удалить Telegram Web
  ├─  8 Добавить / Удалить Spotify
  ├─  9 Добавить / Удалить Supercell
  ├─ 10 Добавить / Удалить githubusercontent.com
  ├─ 11 Удалить все домены
  ├─ 12 Заменить hosts на GeoHide hosts
  ├─ 13 Заменить hosts на Mafioznik hosts
  ├─ 14 Заменить hosts на Malw.link hosts
  ├─ 15 Восстановить hosts
  └─Enter Выход в главное меню

─ 9 Удалить → установить → настроить Zapret

─ 0 Системное меню
  ├─ 1 Показать системную информацию
  ├─ 2 Активировать доступ к скрипту из браузера
  ├─ 3 Включить блокировку QUIC (порты 80 и 443)
  ├─ 4 Меню выбора зеркала OpenWrt
  │  ├─ 1 China
  │  ├─ 2 Germany
  │  ├─ 3 Belgium
  │  ├─ 4 Kazakhstan
  │  ├─ 5 Netherlands
  │  ├─ 6 default / OpenWrt
  │  └─Enter Выход в системное меню
  │
  ├─ 5 Запустить проверку blockcheck
  ├─ 6 Удалить Zapret
  ├─ 7 Сделать / Удалить резервную копию настроек Zapret
  ├─ 8 Восстановить настройки Zapret из резервной копии
  ├─ 9 Включить / Выключить IPv6 в Zapret
  ├─ 0 Применить FIX для Flow Offloading
  └─ Enter Выход в главное меню

─ s/S Запустить / Остановить Zapret
```

</details>

---

[![Star History Chart](https://api.star-history.com/svg?repos=StressOzz/Zapret-Manager&type=date&legend=top-left)](https://www.star-history.com/#StressOzz/Zapret-Manager&type=date&legend=top-left)

---

<table>
  <tr>
    <td>
      <a href="https://github.com/StressOzz#-поддержать-проект">
        <img width="280" height="130" src="https://github.com/user-attachments/assets/2999757b-fbf3-4149-bf6c-48bf3e241529">
      </a>
    </td>
    <td>
      <a href="https://github.com/StressOzz/StressKVN">
        <img width="270" height="80" src="https://github.com/user-attachments/assets/7dbb964b-bb79-461a-9f47-9ca73323ebac">
      </a>
    </td>
  </tr>
</table>

---

# Благодарности:

- **Zapret-OpenWrt** by [*remittor*](https://github.com/remittor)
- **Стратегии от Flowseal** by [*Flowseal*](https://github.com/Flowseal)
- **NetShift** by [*yandexru45*](https://github.com/yandexru45)
- **Mixomo** by [*Internet Helper*](https://github.com/Internet-Helper)
- **AWG OpenWrt** by [*Slava-Shchipunov*](https://github.com/Slava-Shchipunov)
- **TG WS Proxy SOCKS5** by [*byd0mhate*](https://github.com/d0mhate)
- **TG WS Proxy Rust** by [*valnesfjord*](https://github.com/valnesfjord)
- **TG WS Proxy MTProto** by [*spatiumstas*](https://github.com/spatiumstas)

---

*принадлежит компании Meta, признанной экстремистской и запрещённой на территории РФ
