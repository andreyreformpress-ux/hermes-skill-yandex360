# Яндекс Календарь 360 MCP — полные схемы инструментов

Сервер: `yandex360_calendar` (`https://mcp.360.yandex.net/v1/calendar/mcp`), авторизация `Authorization: OAuth <YANDEX360_CALENDAR_API_KEY>`. В сессии имена с префиксом `mcp_yandex360_calendar_`, точки → подчёркивания. Снимок tools/list 2026-11-20 (предварительная версия API — может меняться). Ключ календаря отдельный от почты (YANDEX360_MAIL_API_KEY) — токен почты даёт 403/пусто.

Общее: пагинация — первый вызов с параметрами (+ `limit`), следующие — только `cursor` (значение `next_cursor`), без остальных параметров. `recurrence_id` = `YYYY-MM-DDTHH:mm:ss` без таймзоны — время начала конкретного повтора.

---

## calendar.list_calendars
| Параметр | Тип | Описание |
|---|---|---|
| relation_type | string | Фильтр по типу отношений с пользователем |
| type | string | Фильтр по типу календаря |
| visibility | string | Фильтр по видимости |
| limit | int | Размер страницы; только в первом вызове |
| cursor | string | next_cursor прошлого ответа; передаётся ОДИН |

Свои календари, shared-доступ и внешние подписки. Календари коллег «только занятость» НЕ входят.

## calendar.list_events
| Параметр | Тип | Описание |
|---|---|---|
| from | string (date-time) | Начало диапазона, вкл. (`2026-06-01T00:00:00Z`) |
| to | string (date-time) | Конец диапазона, НЕ вкл. |
| time_zone | string | Часовой пояс ответа (по умолчанию — пояс пользователя) |
| event_ids | string | Только эти события, id через запятую |
| calendar_ids | string | Только эти календари, id через запятую |
| calendar_visibility | string | Фильтр по видимости календарей |
| opacity | string | Фильтр по занятости |
| include_declined_events | bool | Включить события, от которых отказались |
| limit | int | Размер страницы |
| cursor | string | next_cursor прошлого ответа; передаётся ОДИН |

Повторяющиеся события — по записи на каждый повтор. Ссылка на веб-интерфейс: `{{calendar_url}}/event/<event_id>`, для повтора — `?recurrenceId=<recurrence_id>`.

## calendar.get_event
| Параметр | Тип |
|---|---|---|
| event_id* | string |
| recurrence_id | string (YYYY-MM-DDTHH:mm:ss) |

## calendar.create_event
| Параметр | Тип | Описание |
|---|---|---|
| start* | object | Момент начала (вкл.); для серии — первого повтора |
| end* | object | Момент окончания (не вкл.) |
| summary* | string | Название |
| calendar_id | string | Календарь (по умолчанию — основной) |
| description | string | Описание |
| location | string | Место |
| participants | array | Участники |
| conference | object | Данные конференции |
| rules | object | Права/видимость; если передан — все поля обязательны |
| repetition | object | Правила повтора → серия; без поля — одиночное событие |
| personal_settings | object | Персональные настройки (напоминания и т.п.) |

## calendar.update_event
Обязателен `event_id`; `recurrence_id` — ограничить действие одним повтором. Частичное обновление — передавай только меняемые поля:
start, end, summary, description, location, repetition, rules (все поля необязательны), conference (отсутствует — не менять; `null` — удалить; объект — новая).

## calendar.delete_event
| Параметр | Тип |
|---|---|---|
| event_id* | string |
| recurrence_id | string |

Без recurrence_id — вся серия/одиночное событие; с ним — только этот повтор, остальные сохраняются. Только после подтверждения пользователя.

## calendar.move_event
| Параметр | Тип |
|---|---|---|
| event_id* | string |
| source_calendar_id* | string |
| target_calendar_id* | string |

Переносит событие/всю серию между календарями. Нужны права удаления в исходном и создания в целевом; календари должны различаться.

## calendar.get_user_availability
| Параметр | Тип | Описание |
|---|---|---|
| user_email | string | Почта пользователя занятости |
| from | string (date-time) | Начало диапазона, вкл. |
| to | string (date-time) | Конец, не вкл. |
| limit | int | Размер страницы |
| cursor | string | next_cursor; передаётся ОДИН |

Повторы — отдельными записями с recurrence_id. Нет почты → 404; нет прав → ошибка прав.

## calendar.get_room_availability
Те же from/to/limit/cursor, но `room_id` — публичный идентификатор переговорки (см. list_rooms).

## calendar.add_event_participants
| Параметр | Тип |
|---|---|---|
| event_id* | string |
| items* | array | Добавляемые участники (внутренние и внешние) |
| recurrence_id | string | Ограничить одним повтором серии |

## calendar.list_event_participants
| Параметр | Тип |
|---|---|---|
| event_id | string |
| decisions | string | Фильтр по решению (значения через запятую) |
| recurrence_id | string |
| limit | int |
| cursor | string |

Упорядочены по participation_id.

## calendar.remove_event_participants
| Параметр | Тип |
|---|---|---|
| event_id* | string |
| participant_ids* | string | Через запятую |
| recurrence_id | string |

Несуществующих участников игнорирует (204).

## calendar.respond_to_event
| Параметр | Тип |
|---|---|---|
| event_id* | string |
| decision* | string | `ACCEPTED` / `DECLINED` / `TENTATIVE` |
| recurrence_id | string |

Организатор не может изменить свой ответ (ошибка).

## calendar.list_offices
Только `limit`/`cursor`. Офисы организации, где есть переговорки, доступные пользователю для бронирования.

## calendar.list_rooms
| Параметр | Тип |
|---|---|---|
| office_id | string | Фильтр по офису (без него — все офисы) |
| limit | int |
| cursor | string |

Только переговорки, которые пользователь может забронировать.
