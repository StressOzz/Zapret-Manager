<h1 align="center">Универсальный менеджер для обхода блокировок на OpenWrt</h1>

<div align="center">

![Platform](https://img.shields.io/badge/Platform-OpenWrt-orange)
![Architecture](https://img.shields.io/badge/Architecture-All%20(OpenWrt)-yellow)
![Script](https://img.shields.io/badge/Script-sh-informational)
![Status](https://img.shields.io/badge/Status-Active-success)
[![Views](https://views.whatilearened.today/views/github/StressOzz/Zapret-Manager.svg)](https://github.com/StressOzz/Zapret-Manager)

</div>

---

### **StressKVN** - умный VPN для стабильного доступа в любых условиях

- ✅ Работает даже при жёсткой фильтрации и в условиях белых списков
- 🌍 Умная маршрутизация: иностранные ресурсы через VPN, российский трафик напрямую
- ▶️ YouTube без рекламы
- ⚡ Высокая скорость и безлимитный трафик
- 📶 Можно использовать прямо на роутере
- 🎁 Бесплатный тест — 3 дня без оплаты

Подробнее: **https://github.com/StressOzz/StressKVN**

---

### Для Windows - используйте: **https://github.com/StressOzz/ZapretOzz**

---

> [!IMPORTANT]
> Если отсутствует доступ к **github.com**, выполните в **SSH** следующую команду:
> ```
> git="github.com"; grep -q "^140.82.114.3 $git" /etc/hosts || { printf "#$git\n140.82.114.3 $git\n185.199.110.154 github.githubassets.com\n185.199.110.133 camo.githubassets.com\n" >> /etc/hosts; /etc/init.d/dnsmasq restart 2>/dev/null; }; echo -e "\033[0;32mOK\033[0m"
> ```

Чтобы удалить эту настройку, в **SSH** выполните:
```
sed -i '/#github.com/,+3d' /etc/hosts; /etc/init.d/dnsmasq restart 2>/dev/null; echo -e "\033[0;32mOK\033[0m"
```

> [!IMPORTANT]
> При возникновении проблем с запуском скрипта или его функций, выполните в **SSH** следующую команду:
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
        <img width="280" height="130" alt="image" src="https://github.com/user-attachments/assets/519a126e-bd39-4f46-8a09-3f0d6e1dd8af">
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
- Установить [**NetShift**](https://github.com/yandexru45/netshift)
- Установить [**Mixomo**](https://github.com/Internet-Helper/mixomo-openwrt)
- Установить [**splify**](https://github.com/xyzmean/splify)
- Установить [**Zapret2 Routerich Edition**](https://github.com/routerich)
- Интегрировать [**VPN подпиcку**](https://github.com/StressOzz/StressKVN) в **NetShift** и **Mixomo**
- Сгенерировать **WARP** и интегрировать его в **Mixomo**
- Запустить автоподбор стратегий по расписанию

---

## 🔹 Подготовка системы

> [!IMPORTANT]
>для работы некоторых стратегий, в терминале Windows необходимо один раз выполнить:
>```
>netsh int tcp set global timestamps=enabled
>```
>
>для пользователей Linux:
>```
>sysctl -w net.ipv4.tcp_timestamps=1
>```

- Если у Вас установлен **ByeDPI** или **youtubeUnblock** скрипт выдаст сообщение.
- Если у Вас включён **Flow offloading** скрипт выдаст сообщение и в `Системном меню`, появится пункт **0** - **Применить FIX**.
- [**NetShift** берёт на себя роль DNS-резолвера](https://podkop.net/docs/dns/), поэтому с установленным `DNS over HTTPS` [**NetShift не установится!**](https://podkop.net/docs/install/#nesovmestimost)

---

## 🔹 Запуск менеджера

Подключитесь по **SSH** к роутеру и выполните команду:
> [!IMPORTANT]
> Если у Вас доступен **raw.githubusercontent.com**:
```
wget -qO - 'https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh' | sh
```
> [!IMPORTANT]
> Если у Вас **НЕ** доступен **raw.githubusercontent.com**:
```
wget -qO - 'https://gh-proxy.org/https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh' | sh
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

**Пункт f** - **Удалить → установить → настроить Zapret**

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

## 🔹 Expert mode

В `Системном меню` можно включить **expert mode**, что позволит Вам управлять сразу двумя версиями Zapret...

---

## 🔹 Тест стратегий из **/root/custom_test.txt**

Каждая стратегия должна начинаться со строки **#Название**

Пример содержимого `/root/custom_test.txt`:
```
#Strategy1
--filter-tcp=443
--dpi-desync=fake
. . .
#Strategy2
--filter-tcp=443
--dpi-desync=multidisorder
. . .
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
        <img width="280" height="130" alt="image" src="https://github.com/user-attachments/assets/519a126e-bd39-4f46-8a09-3f0d6e1dd8af">
      </a>
    </td>
  </tr>
</table>

---

# Благодарности:

- **Zapret** by [*bol-van*](https://github.com/bol-van)
- **Zapret-OpenWrt** by [*remittor*](https://github.com/remittor)
- **Zapret2 Routerich Edition** by [*Routerich*](https://github.com/routerich)
- **Стратегии Flowseal** by [*Flowseal*](https://github.com/Flowseal)
- **NetShift** by [*yandexru45*](https://github.com/yandexru45)
- **splify** - by [*xyzmean*](https://github.com/xyzmean/)
- **Mixomo** by [*Internet Helper*](https://github.com/Internet-Helper)
- **MagiTrickle** by [*Ponywka*](https://github.com/Ponywka)
- **HevSocks5Tunnel** by [*hev*](https://github.com/heiher)
- **AWG OpenWrt** by [*Slava-Shchipunov*](https://github.com/Slava-Shchipunov)
- **TG WS Proxy SOCKS5** by [*byd0mhate*](https://github.com/d0mhate)
- **TG WS Proxy Rust** by [*valnesfjord*](https://github.com/valnesfjord)
- **TG WS Proxy MTProto** by [*spatiumstas*](https://github.com/spatiumstas)
- **ByeDPI-OpenWrt** by [*DPITrickster*](https://github.com/DPITrickster)

---

*принадлежит компании Meta, признанной экстремистской и запрещённой на территории РФ
