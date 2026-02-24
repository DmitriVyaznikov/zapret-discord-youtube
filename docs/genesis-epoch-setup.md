# Настройка Zapret для игрового сервера Genesis Epoch

## Сервер

- **IP:** `51.89.93.157`
- **Game Port:** 2302 (UDP)
- **Query Port:** 2303 (UDP)

---

## Шаг 1. Остановить Zapret

Если zapret запущен — закрой окно `winws.exe` или убей процесс в Диспетчере задач.

---

## Шаг 2. Добавить домены и IP в списки

Открой файл `lists\list-general.txt` и добавь в конец:

```
play.genesis-epoch.com
genesis-epoch.com
```

Открой файл `lists\ipset-all.txt` и убедись, что в нём есть:

```
51.89.93.157/32
198.251.84.43/32
```

---

## Шаг 3. Запустить service.bat от имени администратора

Правый клик на `service.bat` → **Запуск от имени администратора**.

Появится меню:

```
ZAPRET SERVICE MANAGER
----------------------------------------

:: SERVICE
   1. Install Service
   2. Remove Services
   3. Check Status

:: SETTINGS
   4. Game Filter         [disabled]
   5. IPSet Filter        [none]
   6. Auto-Update Check   [disabled]
```

---

## Шаг 4. Включить Game Filter

1. Введи **4** → Enter
2. Появится выбор режима:
   ```
   0. Disable
   1. TCP and UDP
   2. TCP only
   3. UDP only
   ```
3. Введи **3** (UDP only) → Enter — этого достаточно для игрового сервера (порты 2302-2303 = UDP)
4. Нажми любую клавишу

> Если нужен и веб-доступ к сайту сервера — выбери **1** (TCP and UDP).

---

## Шаг 5. Переключить IPSet Filter в режим [loaded]

1. Введи **5** → Enter
2. Режим переключается циклически: `none` → `any` → `loaded` → `none`
3. **Нажимай 5 до тех пор, пока статус не станет [loaded]**
4. Нажми любую клавишу

> В режиме **loaded** zapret применяет desync только к IP-адресам из `ipset-all.txt` (включая `51.89.93.157`).

---

## Шаг 6. Установить сервис

1. Введи **1** → Enter
2. Появится список стратегий:
   ```
   1. general (ALT).bat
   2. general (ALT10).bat
   ...
   ```
3. Введи **номер** стратегии `general (ALT).bat` → Enter
4. Нажми любую клавишу
5. Сервис zapret установлен и запущен

---

## Шаг 7. Проверить

1. Введи **3** → Enter — убедись что статус:
   - `zapret` service is **RUNNING**
   - Bypass (winws.exe) is **RUNNING**
2. Попробуй подключиться к серверу Genesis Epoch
3. **Выключи VPN**, если используешь

---

## Если не работает

Попробуй другие режимы IPSet (пункт 5 в меню):

- **[any]** — desync на весь трафик (без фильтрации по IP)
- **[loaded]** — только IP из списка
- **[none]** — только по доменам из hostlist

Также попробуй другую стратегию (например `general (FAKE TLS AUTO ALT).bat`) — повтори шаг 6 с другим выбором.
