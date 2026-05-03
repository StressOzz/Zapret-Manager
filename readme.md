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

### Для Windows - используйте это:
https://github.com/StressOzz/ZapretOzz

![Downloads](https://img.shields.io/github/downloads/StressOzz/Zapret-Manager/total)
![Latest Downloads](https://img.shields.io/github/downloads/StressOzz/Zapret-Manager/latest/total)

---

# Оглавление
- [Возможности](#-возможности)
- [Подготовка системы](#-подготовка-системы)
- [Запуск менеджера](#-запуск-менеджера)
- [Быстрый старт](#-быстрый-старт)
- [Настройка Telegram](#-настройка-telegram)
- [Cтратегии](#-стратегии)
- [Дерево меню Zapret Manager](#-дерево-меню-zapret-manager)
- [Благодарности](#благодарности)
- [Поддержать проект](https://github.com/StressOzz)

---

## 🔹 Возможности

### Zapret Manager позволяет:

- Установить **Zapret** последней версии
- Выбрать стратегию для установки **v1-v9**
- Выбрать и установить стратегию от **Flowseal**
- Протестировать стратегии
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
- Установить **TG WS Proxy** для **Telegram**
- Установить **Podkop Evolution**
- Интегрировать [**VPN подпиcку**](https://github.com/StressOzz/StressKVN) или **WARP** в **Podkop Evolution**

---

## 🔹 Подготовка системы

> [!IMPORTANT]
>для работы некотрых стратегий, в терминале Windows необходимо выполнить:
>```
>netsh int tcp set global timestamps=enabled
>```

- Если у Вас установлен **ByeDPI** или **youtubeUnblock** скрипт выдаст сообщение.
- Если у Вас включён **Flow offloading** скрипт выдаст сообщение и в `Системном меню`, появится пункт **0** - **Применить FIX**.
- [**Podkop** берёт на себя роль DNS-резолвера](https://podkop.net/docs/dns/), поэтому с установленным `DNS over HTTPS` [**Podkop не установится!**](https://podkop.net/docs/install/#nesovmestimost)

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

В скрипте, в 3 пункте - Тестировать стратегии для `YouTube` и Тестировать `v` и `Flowseal` стратегии

- [Cтратегии для Youtube](https://github.com/StressOzz/Zapret-Manager/blob/main/Strategies_For_Youtube.md)
- [Cтратегии используемые в скрипте](https://github.com/StressOzz/Zapret-Manager/blob/main/Strategies.md)

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

## 🔹 Настройка Telegram

**Пункт 4** -  установка или удаление **TG WS Proxy**

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

## 🔹 Дерево меню Zapret Manager


<details>
<summary>Нажмите, чтобы развернуть</summary>

```text
┌─ 1 Установить / Удалить / Обновить Zapret
│
├─ 2 Меню стратегий
│  ├─ 1 Выбрать и установить стратегию v1–v9
│  ├─ 2 Выбрать и установить стратегию от Flowseal
│  ├─ 3 Выбрать и установить стратегию для YouTube
│  ├─ 4 Выбрать и установить стратегию для игр
│  ├─ 5 Включить / Выключить обход по спискам РКН
│  ├─ 6 Обновить список исключений
│  └─ Enter Выход в главное меню
│
├─ 3 Меню тестирование стратегий
│  ├─1 Тестировать стратегии v
│  ├─2 Тестировать стратегии Flowseal
│  ├─3 Тестировать v и Flowseal стратегии
│  ├─4 Тестировать текущую стратегию
│  ├─5 Тестировать стратегии по домену
│  ├─6 Тестировать стратегии для YouTube
│  ├─9 Результаты тестирования стратегий
│  ├─0 Удалить результаты тестования
│  └─ Enter Выход в главное меню
│
├─ 4 Меню TG WS Proxy 
│  ├─1 Установить / Удалить TG WS Proxy Go
│  ├─2 Установить / Удалить TG WS Proxy Go
│  └─ Enter Выход в главное меню
│
├─ 5 Меню DNS over HTTPS
│  ├─ 1 Установить / Удалить DNS over HTTPS
│  ├─ 2 Настроить Comss DNS
│  ├─ 3 Настроить Xbox DNS
│  ├─ 4 Настроить dns.malw.link
│  ├─ 5 Настроить dns.malw.link через Cloudflare
│  ├─ 6 Настроить dns.mafioznik.xyz
│  ├─ 7 Настроить dns.astracat.ru
│  ├─ 0 Вернуть настройки DNS по умолчанию
│  └─ Enter Выход в главное меню
│
├─ 6 Меню Podkop Evolution
│  ├─ 1 Установить / Удалить / Обновить Podkop Evolution
│  ├─ 2 Установить / Удалить AWG и интерфейс AWG
│  ├─ 3 Интегрировать VPN подписку в Podkop Evolution / Сменить VPN подписку в Podkop Evolution
│  ├─ 4 Интегрировать AWG в Podkop
│  └─ Enter Выход в главное меню
│
├─ 7 Меню настройки Discord
│  ├─ 1 Установить скрипт 50-stun4all
│  ├─ 2 Установить скрипт 50-quic4all
│  ├─ 3 Установить скрипт 50-discord-media
│  ├─ 4 Установить скрипт 50-discord
│  ├─ 5 Удалить скрипт Discord
│  ├─ 6 Добавить Финские IP-адреса в hosts
│  ├─ 7 Выбрать и установить стратегию для discord.media
│  └─ Enter Выход в главное меню
│
├─ 8 Меню управления доменами в hosts
│  ├─ 0 Добавить / Удалить nalog.ru
│  ├─ 1 Добавить / Удалить rutor.info
│  ├─ 2 Добавить / Удалить ntc.party
│  ├─ 3 Добавить / Удалить Instagram* & Facebook*
│  ├─ 4 Добавить / Удалить lib.rus.ec
│  ├─ 5 Добавить / Удалить AI сервисы
│  ├─ 6 Добавить / Удалить Twitch
│  ├─ 7 Добавить / Удалить Telegram Web
│  ├─ 8 Добавить / Удалить Spotify
│  ├─ 9 Добавить / Удалить Supercell
│  ├─10 Добавить / Удалить все домены
│  ├─11 Восстановить hosts
│  └─Enter Выход в главное меню
│
├─ 9 Удалить → установить → настроить Zapret
│
├─ s/S Запустить / Остановить Zapret
│
└─ 0 Системное меню
   ├─ 1 Показать системную информацию
   ├─ 2 Активировать доступ к скрипту из браузера
   ├─ 3 Включить блокировку QUIC (порты 80 и 443)
   ├─ 4 Меню выбора зеркала OpenWrt
   │  ├─1 China
   │  ├─2 Germany
   │  ├─3 Belgium
   │  ├─4 Kazakhstan
   │  ├─5 Netherlands
   │  ├─6 default / OpenWrt
   │  └─Enter Выход в системное меню
   │
   ├─ 5 Запустить проверку blockcheck
   ├─ 6 Удалить Zapret
   ├─ 7 Сделать / Удалить резервную копию настроек Zapret
   ├─ 8 Восстановить настройки Zapret из резервной копии
   ├─ 9 Включить / Выключить IPv6 в Zapret
   ├─ 0 Применить FIX для Flow Offloading
   └─ Enter Выход в главное меню
```

</details>

---

[![Star History Chart](https://api.star-history.com/svg?repos=StressOzz/Zapret-Manager&type=date&legend=top-left)](https://www.star-history.com/#StressOzz/Zapret-Manager&type=date&legend=top-left)

---


# Благодарности:

- **Zapret-OpenWrt** by [*remittor*](https://github.com/remittor)
- **Стратегии от Flowseal** by [*Flowseal*](https://github.com/Flowseal)
- **TG WS Proxy Go** by [*byd0mhate*](https://github.com/d0mhate)
- **TG WS Proxy Rust** by [*valnesfjord*](https://github.com/valnesfjord)
- **Podkop Evolution** by [*yandexru45*](https://github.com/yandexru45)
- **AWG OpenWrt** by [*Slava-Shchipunov*](https://github.com/Slava-Shchipunov)
- **TG WS Proxy Go** by [*spatiumstas*](https://github.com/spatiumstas)

---

*принадлежит компании Meta, признанной экстремистской и запрещённой на территории РФ
