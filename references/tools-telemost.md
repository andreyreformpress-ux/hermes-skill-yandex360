# Телемост 360 MCP — полные схемы инструментов

Сервер: `yandex360_telemost` (`https://mcp.360.yandex.net/v1/telemost/mcp`), авторизация `Authorization: OAuth <YANDEX360_TELEMOST_API_KEY>`. В сессии имена с префиксом `mcp_yandex360_telemost_`, точки → подчёркивания. Снимок tools/list 2026-11-20 (предварительная версия API — может меняться). Ключ Телемоста отдельный от почты и календаря.

`id` встреч — короткий идентификатор или полная ссылка. `message_id`/`thread_id` — Unix-время в микросекундах. Чаты и сообщения — только чтение. Пагинация чатов: первый вызов с параметрами (+ limit), следующие — только cursor.

---

## telemost.get_current_user
Без параметров. Возвращает пользователя токена: `id`, `chat_id`, `display_name`, `login`, `is_bot`, `organizations[]` (`id`, `name`). `org_id` отсюда — для search_users/search_chats/search_messages.

## telemost.search_users
| Параметр | Тип | Описание |
|---|---|---|
| query* | string | Непустой поисковый запрос |
| org_id | int | Организация (из get_current_user); без него — без орг-контекста |
| limit | int (50) | Максимум результатов |

Одна страница, по релевантности. Логин — только для пользователей общей организации.

## telemost.create_meeting
| Параметр | Тип | Описание |
|---|---|---|
| waiting_room_level | string | `PUBLIC` — комната ожидания выключена; др. уровни — кто минует ожидание |
| live_stream | object | Настройки трансляции; без поля — не создаётся; возвращает `live_stream.watch_url` |
| cohosts | array | Соорганизаторы по email или user_id; пустой/не указан — без соорганизаторов |
| is_auto_summarization_enabled | bool | Автоконспектирование при старте встречи |
| is_auto_cloud_recording_enabled | bool | Автозапуск облачной записи при входе первого участника |

Возвращает `id`, `join_url` и доступные настройки. Только после подтверждения пользователя.

## telemost.update_meeting
| Параметр | Тип |
|---|---|---|
| id* | string |
| waiting_room_level | string/null |
| live_stream | object/null |
| is_auto_summarization_enabled | bool/null |
| is_auto_cloud_recording_enabled | bool/null |

Передавай только изменяемые поля. Соорганизаторы этим инструментом НЕ меняются. С подтверждением.

## telemost.get_meeting_join_details
| Параметр | Тип |
|---|---|---|
| id* | string |

Возвращает id, `join_url`, `waiting_room_level`. НЕ возвращает SIP-реквизиты, токены, участников, записи.

## telemost.list_meeting_cohosts
| Параметр | Тип |
|---|---|---|
| id* | string |
| offset | int |
| limit | int |

## telemost.update_meeting_cohosts
| Параметр | Тип |
|---|---|---|
| id* | string |
| cohosts* | array | Полный новый список (email/user_id); пустой — удалить всех |

Полная замена. Только после явного подтверждения.

## telemost.add_meeting_cohosts
| Параметр | Тип |
|---|---|---|
| id* | string |
| cohosts* | array | Добавляемые (email/user_id), существующие не трогаются |

## telemost.remove_meeting_cohosts
| Параметр | Тип |
|---|---|---|
| id* | string |
| cohost_emails* | string | Адреса через запятую |

С явным подтверждением.

## telemost.list_chats
| Параметр | Тип |
|---|---|---|
| limit | int |
| cursor | string |

Чаты текущего пользователя (без пустых). Каналы — тип чата, отдельных инструментов нет.

## telemost.search_chats
| Параметр | Тип |
|---|---|---|
| query* | string |
| org_id | int |
| limit | int (50) |

Только доступные текущему пользователю; одна страница по релевантности.

## telemost.get_chat
| Параметр | Тип |
|---|---|---|
| chat_id* | string |

## telemost.list_chat_members
| Параметр | Тип |
|---|---|---|
| chat_id | string |
| limit | int |
| cursor | string |

Состав ограничен правом `ListMembers` в этом чате.

## telemost.list_chat_messages
| Параметр | Тип |
|---|---|---|
| chat_id | string |
| unread_only | bool | Только непрочитанные |
| limit | int |
| cursor | string |

От новых к старым.

## telemost.get_chat_message
| Параметр | Тип |
|---|---|---|
| chat_id* | string |
| message_id* | int | Unix-время в микросекундах |

## telemost.list_thread_messages
| Параметр | Тип |
|---|---|---|
| chat_id | string |
| thread_id | int | Корневое сообщение треда |
| unread_only | bool |
| limit | int |
| cursor | string |

## telemost.get_thread_message
| Параметр | Тип |
|---|---|---|
| chat_id* | string |
| thread_id* | int |
| message_id* | int |

## telemost.search_messages
| Параметр | Тип |
|---|---|---|
| query* | string |
| org_id | int |
| chat_id | string | Без него — по всем доступным чатам |
| thread_id | int | Только вместе с chat_id |
| limit | int (50) |
