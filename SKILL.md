---
name: yandex360
description: "Яндекс 360: почта, календарь и Телемост через MCP."
version: 1.0.0
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

Документация: https://yandex.ru/dev/yandex-360/mcp/ru/ (предварительная версия API, обратная совместимость не гарантирована).

## Имена инструментов

В сессии — префикс сервера, точки → подчёркивания: `mail.search_messages` → `mcp_yandex360_mail_mail_search_messages`, `calendar.list_events` → `mcp_yandex360_calendar_calendar_list_events`, `telemost.create_meeting` → `mcp_yandex360_telemost_telemost_create_meeting`.

## Общие правила

- **Пагинация (все три сервера):** первый вызов — параметры (+ `limit`); следующая страница — ТОЛЬКО `cursor` = `next_cursor` прошлого ответа, без остальных параметров. `null` — конец. Курсор не менять.
- **Мутации — с подтверждением:** в календаре и Телемосте изменяющие действия (создать/изменить/удалить/участники/соорганизаторы/respond) делай только после показа пользователю что изменится; в почте — как минимум для `delete_message`.
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

## Комбинированные сценарии

- **Встреча с видеоссылкой:** календарь `create_event` (участники, переговорная) + Телемост `create_meeting` → join_url в описание/конференцию события.
- **Подготовка к встрече:** календарь `list_events`/`get_event` + Телемост `search_messages` по теме + почта `search_messages` (конспекты от keeper@telemost.yandex.ru — «Конспект встречи …», полный транскрипт во вложении txt).
- **Конспект встречи по почте** — эффективнее искать в почте: `search_messages {from_query: "keeper@telemost"}` или по теме.
