---
name: yandex360
description: "Яндекс 360: почта, календарь и Телемост через MCP."
version: 1.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [email, calendar, yandex, telemost, mcp, meetings, productivity]
    related_skills: [calendar-slot-finder, email-inbox-triage]
---

# Яндекс 360 через MCP (почта + календарь + Телемост)

Единый скилл для трёх MCP-серверов Яндекс 360: **почта** (`yandex360_mail`), **календарь** (`yandex360_calendar`), **Телемост** (`yandex360_telemost`).

## When to Use

- Почта Яндекс 360: найти/прочитать письмо, черновик (НЕ отправка!), метки, папки, перемещение, удаление писем.
- Календарь Яндекс 360: встречи на день, поиск события, создание/перенос/удаление, участники, ответы на приглашения, занятость, переговорные, свободные слоты.
- Телемост: создать видеовстречу, ссылка подключения, соорганизаторы, чаты/каналы/треды (только чтение), поиск сообщений.
- Настройка/починка любого из этих MCP (Unauthorized, пустые списки, 403).
- НЕ для личной почты @yandex.ru вне Яндекс 360 и НЕ для Google/Exchange — см. related_skills.

## Три сервера и три ключа

| Сервис | Сервер | URL | Ключ .env | Схема |
|---|---|---|---|---|
| Почта | `yandex360_mail` | `https://mcp.360.yandex.net/v1/mail/mcp` | `YANDEX360_MAIL_API_KEY` | **Bearer** |
| Календарь | `yandex360_calendar` | `https://mcp.360.yandex.net/v1/calendar/mcp` | `YANDEX360_CALENDAR_API_KEY` | **OAuth** |
| Телемост | `yandex360_telemost` | `https://mcp.360.yandex.net/v1/telemost/mcp` | `YANDEX360_TELEMOST_API_KEY` | **OAuth** |

**Важно:** у каждого сервиса СВОЙ OAuth-токен со своими скоупами — токен почты НЕ даёт доступа к календарю/Телемосту (initialize проходит, но данные → 403/пусто). Схема авторизации тоже разная: почта — `Bearer`, остальные — `OAuth`.

Получение токенов (пользователь сам, в браузере):
- Почта: https://yandex.ru/dev/yandex-360/mcp/ru/mail (ссылка «получить OAuth-токен»)
- Календарь: https://oauth.yandex.ru/authorize?client_id=d5fff53202474631801939f538932a5c&response_type=token
- Телемост: https://oauth.yandex.ru/authorize?client_id=80d9d53eb9c34b11baa4d76778fe5282&response_type=token

## Настройка (ключи только в .env)

1. Пользователь сам кладёт три ключа в `~/.hermes/.env` (профиль — `~/.hermes/profiles/<имя>/.env`):
   ```bash
   YANDEX360_MAIL_API_KEY=<токен почты>
   YANDEX360_CALENDAR_API_KEY=<токен календаря>
   YANDEX360_TELEMOST_API_KEY=<токен Телемоста>
   chmod 600 ~/.hermes/.env
   ```
2. Регистрация серверов (в config.yaml — только ссылки `${VAR}`, токены туда не попадают):
   ```bash
   hermes config set mcp_servers.yandex360_mail.url "https://mcp.360.yandex.net/v1/mail/mcp" --force
   hermes config set mcp_servers.yandex360_mail.headers.Authorization "Bearer ${YANDEX360_MAIL_API_KEY}" --force
   hermes config set mcp_servers.yandex360_calendar.url "https://mcp.360.yandex.net/v1/calendar/mcp" --force
   hermes config set mcp_servers.yandex360_calendar.headers.Authorization "OAuth ${YANDEX360_CALENDAR_API_KEY}" --force
   hermes config set mcp_servers.yandex360_telemost.url "https://mcp.360.yandex.net/v1/telemost/mcp" --force
   hermes config set mcp_servers.yandex360_telemost.headers.Authorization "OAuth ${YANDEX360_TELEMOST_API_KEY}" --force
   ```
3. Проверка: `hermes mcp test yandex360_mail` (13), `... yandex360_calendar` (15), `... yandex360_telemost` (18) → `hermes gateway restart`.

Если пользователь предлагает вставить токен в чат — откажись и дай шаг 1. `Unauthorized`/`403 Forbidden` на данных = токен неверен, истёк или выдан на другой сервис. Пустые списки без ошибок — проверь, тем ли аккаунтом выдан токен. Отзыв доступа: Яндекс ID → «Доступы к данным» → «Внешний ИИ-агент для …».

**Горячая перезагрузка MCP (диагностика):** шлюз подхватывает изменения `mcp_servers` без рестарта, но reconcile сравнивает только СОСТАВ серверов (имена). Если у уже добавленного сервера поменять `headers`/токен — живое подключение НЕ пересоздаётся и продолжит ходить со старым токеном (403 на данных), при этом `hermes mcp test` (свежий процесс, читает текущий конфиг) будет проходить. Лечение: `hermes config unset mcp_servers.<имя>` → дождаться в `~/.hermes/logs/gateway.log` строки `removed=['<имя>']` (~20–60 c) → вернуть конфиг и дождаться `added=['<имя>']` + регистрации инструментов в `agent.log`. Быстрый unset+set подряд не срабатывает — вочер не видит промежуточного состояния. И помни: `tools/list` при дискавери НЕ проверяет скоупы токена — сервер может «зарегистрировать все инструменты» с чужим токеном, а данные при этом будут 403. Перезапустить шлюз изнутри сессии агента НЕЛЬЗЯ (агент — дочерний процесс шлюза, рестарт убьёт команду и сессию; CLI это блокирует) — рестарт делает пользователь: статус-меню приложения → Restart gateway, или `hermes gateway restart` в своём терминале; пока идут активные чаты, шлюз откладывает рестарт («Restart needed»).

Документация: https://yandex.ru/dev/yandex-360/mcp/ru/ (предварительная версия API, обратная совместимость не гарантирована).

## Имена инструментов

В сессии — префикс сервера, точки → подчёркивания: `mail.search_messages` → `mcp_yandex360_mail_mail_search_messages`, `calendar.list_events` → `mcp_yandex360_calendar_calendar_list_events`, `telemost.create_meeting` → `mcp_yandex360_telemost_telemost_create_meeting`.

## Общие правила

- **Пагинация (все три сервера):** первый вызов — параметры (+ `limit`); следующая страница — ТОЛЬКО `cursor` = `next_cursor` прошлого ответа, без остальных параметров. `null` — конец. Курсор не менять.
- **Мутации — с подтверждением:** в календаре и Телемосте изменяющие действия (создать/изменить/удалить/участники/соорганизаторы/respond) делай только после показа пользователю что изменится; в почте — как минимум для `delete_message`.
- **Рабочие часы по умолчанию:** если пользователь просит «свободный слот» без уточнения — считай 10:00–19:00 в его таймзоне (обычно MSK); оговорись в ответе.
- **Правильный ключ к сервису:** скрипты-пробы читают токен из `.env` внутри кода и не выводят его в чат/логи.

## Почта (13 инструментов) — краткая карта

| Инструмент | Назначение |
|---|---|
| `mail.list_folders` | Папки с счётчиками; `symbol` = inbox/sent/trash/spam/draft |
| `mail.list_messages_in_folder` | Конверты папки (folder_id, min/max_received_at, limit, cursor) — НЕ тела |
| `mail.search_messages` | Поиск: ≥1 из body/subject/from/recipients_query + фильтры (папка, даты, вложения) |
| `mail.list_labels` / `mail.list_messages_by_label` | Метки и письма с меткой |
| `mail.get_message` | Конверт: адреса, вложения + временные ссылки скачивания |
| `mail.read_message` | Тело письма (message_id, is_markdown=true → Markdown) |
| `mail.create_draft` / `mail.update_draft` | Черновики; тело — HTML; update затирает пропущенное. **Отправки НЕТ** — пользователь отправляет сам |
| `mail.delete_message` | В «Удаленные» (message_ids и/или thread_ids) — только с подтверждением |
| `mail.add/remove_message_labels` | Метки (label_ids + message_ids/thread_ids) |
| `mail.move_messages` | destination_folder_id (+ destination_tab_type: relevant/news/social) |

Типовой поиск письма: `search_messages` → `read_message`. Вложения в черновик: `existing_attachments` [{mid,hid}] или загрузка файла ≤ 24 МиБ на `cloud-api.yandex.net` → `attachment_stids`. Полные схемы: `references/tools-mail.md`.

## Календарь (15 инструментов) — краткая карта

| Инструмент | Назначение |
|---|---|
| `calendar.list_calendars` | Календари пользователя (фильтры type/relation_type/visibility) |
| `calendar.list_events` | События за from/to (повторы — по записи на каждый); фильтры event_ids/calendar_ids/opacity/include_declined_events; time_zone |
| `calendar.get_event` | Событие: участники, описание, место, ссылка, конференция |
| `calendar.create_event` | start/end/summary (обяз.) + description, location, participants, conference, rules, repetition (серия), personal_settings |
| `calendar.update_event` | Частичное обновление переданных полей |
| `calendar.delete_event` | Удаление — только с подтверждением |
| `calendar.move_event` | Между календарями (source/target_calendar_id) |
| `calendar.add/list/remove_event_participants` | Участники; фильтр decisions |
| `calendar.respond_to_event` | decision = ACCEPTED / DECLINED / TENTATIVE (организатору нельзя) |
| `calendar.get_user_availability` | Занятость пользователя (user_email, from, to) |
| `calendar.get_room_availability` | Занятость переговорной (room_id) |
| `calendar.list_offices` / `calendar.list_rooms` | Офисы с переговорками; переговорки (фильтр office_id) |

**recurrence_id** = `YYYY-MM-DDTHH:mm:ss` без таймзоны (начало повтора): без него — вся серия/одиночное событие, с ним — один повтор. Подбор общего свободного времени НЕТ — вычисляй сам из availability участников (+ переговорной). Полные схемы: `references/tools-calendar.md`.

Нюансы API (проверено 2026-11-20):
- `create_event` → `participants`: массив объектов `{"email": ..., "participation_type": "ATTENDEE"|"OPTIONAL"}`; поля MEMBER/RESOURCE — невалидны.
- Переговорка бронируется добавлением её email (из `list_rooms`, формат `<номер/имя>@<домен организации>`) в `participants` как ATTENDEE + `location` = имя переговорки. В списке участников события переговорка НЕ отображается — проверяй бронь через `get_room_availability`.
- Снять броню переговорки через API НЕЛЬЗЯ точечно: `remove_event_participants` требует UUID participation_id (email → «is not UUID», а переговорка не видна в списке участников), `update_event` с `location:""`/`null` и заменой `participants` бронь не снимает. Единственный рабочий путь — `delete_event` + `create_event` заново без переговорки (участникам уходит отмена и новое приглашение).
- Если у сервера календаря не видно токена-инструментов в сессии, но `hermes mcp test yandex360_calendar` проходит — ходи напрямую streamable-HTTP MCP: initialize → `notifications/initialized` → `tools/call`; имя инструмента на сервере с ТОЧКОЙ (`calendar.list_events`), подчёркивания — только в сессии Hermes.

## Телемост (18 инструментов) — краткая карта

| Инструмент | Назначение |
|---|---|
| `telemost.get_current_user` | Текущий пользователь + организации (org_id для поиска) |
| `telemost.search_users` | Поиск людей (query, org_id) — email/user_id для cohosts |
| `telemost.create_meeting` | Видеовстреча: waiting_room_level, live_stream, cohosts, автоконспект, автооблзапись → id + join_url |
| `telemost.update_meeting` | Изменить настройки встречи (id = короткий id или ссылка); соорганизаторы — отдельно |
| `telemost.get_meeting_join_details` | id, join_url, waiting_room_level (не SIP/токены/участники) |
| `telemost.list/add/update/remove_meeting_cohosts` | Соорганизаторы; update — полная замена (пустой список = удалить всех) |
| `telemost.list_chats` / `search_chats` / `get_chat` | Чаты и каналы пользователя |
| `telemost.list_chat_members` | Участники и роли чата |
| `telemost.list_chat_messages` / `get_chat_message` | История чата (от новых к старым; unread_only) и отдельное сообщение |
| `telemost.list_thread_messages` / `get_thread_message` | Треды (thread_id = id корневого сообщения) |
| `telemost.search_messages` | Поиск по всем чатам / одному чату / треду (thread_id только с chat_id) |

**Чаты — только чтение:** писать/удалять/менять состав нельзя. Каналы = чаты (отдельных инструментов нет). message_id/thread_id — Unix-время в микросекундах. Полные схемы: `references/tools-telemost.md`.

## Прямой вызов MCP по HTTP (фолбэк)

Если инструментов MCP нет в текущей сессии (сессия началась до подключения/фикса сервера, шлюз не перезапущен), вызывай эндпоинты напрямую (streamable HTTP, работает для всех трёх серверов):
1. Прочитай токен из `.env` внутри скрипта (никогда не выводи и не передавай в чат).
2. `POST <url>` с заголовками `Content-Type: application/json`, `Accept: application/json, text/event-stream`, `Authorization: <Bearer|OAuth> <токен>` (схема — из таблицы выше).
3. `initialize` (protocolVersion `2025-03-26`) → `notifications/initialized` (ответ 202 с пустым телом — это норма) → `tools/call`.
4. Сервер НЕ возвращает `Mcp-Session-Id` — stateless-вызовы работают без него; ответы приходят как SSE — парсь строки `data: {...}`.
5. Имя инструмента на сервере — С ТОЧКОЙ (`calendar.list_events`); подчёркивания — только в именах Hermes-сессии.

## Комбинированные сценарии

- **Встреча с видеоссылкой:** календарь `create_event` (участники, переговорная) + Телемост `create_meeting` → join_url в описание/конференцию события.
- **Подготовка к встрече:** календарь `list_events`/`get_event` + Телемост `search_messages` по теме + почта `search_messages` (конспекты от keeper@telemost.yandex.ru — «Конспект встречи …», полный транскрипт во вложении txt).
- **Конспект встречи по почте** — эффективнее искать в почте: `search_messages {from_query: "keeper@telemost"}` или по теме.

### Общие слоты нескольких участников (проверено 2026-11-20)
1. **Имена → почты:** `telemost.get_current_user` → org_id; `telemost.search_users {query: "<имя>", org_id}` — ответ `items[].user.login` = email (вложенный объект `user`! не путай с `items[].login`). Матчи проверяй по фамилии в `display_name`.
2. **Занятость каждого:** `calendar.get_user_availability {user_email, from, to, limit: 100}` — ОБЯЗАТЕЛЬНО цикл по `cursor` до `next_cursor: null` (повторы серий разворачиваются в отдельные интервалы, их много). Работает и для собственной почты. В ответе `summary: null` — названия встреч бери из своего `list_events`.
3. **Вычисление окон:** склей пересекающиеся интервалы каждого (встречи часто идут внахлёст) → объедини занятость ВСЕХ участников → вычти из рабочих часов (по умолчанию 10:00–19:00 MSK) → оставь окна ≥ нужной длительности. Указывай день, границы окна в МСК и длительность.
