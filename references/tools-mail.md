# Yandex 360 Mail MCP — полные схемы инструментов

Сервер: `yandex360_mail` (`https://mcp.360.yandex.net/v1/mail/mcp`). В сессии имена с префиксом `mcp_yandex360_mail_` и с `_` вместо точек. Снимок получен tools/list 2026-11-20.

Во всех list/search-инструментах конверт письма содержит: `message_id`, `folder_id`, `thread_id`, `received_at`, `sent_at`, `subject`, `firstline`, `from`/`to`/`cc`/`bcc`/`sender`/`reply_to` (массивы `{local, domain, display_name}`), `in_reply_to`, `references`, `rfc_message_id`, `is_read`, `labels[]`, `tab_type`, `size`, `thread_count`, `thread_unread_messages_count`, `attachments_count`, `attachments_full_size`, `attachments[]` (`hid, file_name, content_type, size`), `revision`.

---

## mail.list_folders
Папки ящика. Без параметров.
Возвращает: `folder_id`, `parent_id` (`0` — верхний уровень), `name`, `type` (`user|system`), `symbol` (`inbox`, `sent`, `trash`, `spam`, `draft`…), `is_threadable`, `messages_count`, `unread_messages_count`, `recent_messages_count`, `revision`.

## mail.list_messages_in_folder
| Параметр | Тип | Описание |
|---|---|---|
| folder_id | string | Идентификатор папки |
| min_received_at | date-time | Нижняя граница получения (вкл.) |
| max_received_at | date-time | Верхняя граница (не вкл.) |
| limit | int 1–100 (10) | Размер страницы; только в первом вызове |
| cursor | string | next_cursor прошлого ответа; передаётся ОДИН, без других параметров |

## mail.search_messages
Хотя бы один из `body_query`/`subject_query`/`from_query`/`recipients_query` обязателен — фильтры сами по себе не запрос.
| Параметр | Тип | Описание |
|---|---|---|
| body_query | string | Поиск в теле письма |
| subject_query | string | Поиск в теме |
| from_query | string | Поиск в заголовке From |
| recipients_query | string | Поиск в To/Cc/Bcc |
| folder_id | string | Искать только в папке |
| min_received_at | date-time | Нижняя граница получения (вкл.) |
| max_received_at | date-time | Верхняя граница (не вкл.) |
| search_only_with_attachments | bool | Только письма с вложениями |
| limit | int 1–100 (10) | Размер страницы; только в первом вызове |
| cursor | string | next_cursor прошлого ответа; передаётся ОДИН |

## mail.list_labels
Все метки: словарь label_id → `{label_id, name, color, type (user|system|social|status|imap), is_user, is_system, messages_count, unread_messages_count}`. Без параметров.

## mail.list_messages_by_label
| Параметр | Тип | Описание |
|---|---|---|
| label_id | string | Идентификатор метки |
| limit | int 1–100 (10) | Размер страницы; только в первом вызове |
| cursor | string | next_cursor прошлого ответа; передаётся ОДИН |

## mail.get_message
| Параметр | Тип | Описание |
|---|---|---|
| message_id* | string | Идентификатор письма |

Возвращает конверт + вложения с временными ссылками для скачивания. Тело НЕ возвращает.

## mail.read_message
| Параметр | Тип | Описание |
|---|---|---|
| message_id* | string | Идентификатор письма |
| is_markdown | bool | true → текст в Markdown; по умолчанию HTML |

Возвращает `items[].body` — текстовые части письма. Не помечает прочитанным.

## mail.create_draft
| Параметр | Тип | Описание |
|---|---|---|
| to | string[] | Основные получатели |
| cc | string[] | Копия |
| bcc | string[] | Скрытая копия |
| subject | string | Тема |
| text | string | Тело — **HTML** |
| attachment_stids | string[] | STID ранее загруженных вложений (см. загрузку ниже) |
| existing_attachments | {mid, hid}[] | Вложения из существующих писем/черновиков |

Отправитель подставляется из почтового профиля пользователя. Возвращает `mid` черновика + метаданные вложений. **НЕ отправляет письмо.**

## mail.update_draft
Обязателен `draft_mid`. Остальные параметры те же, что у create_draft. **Полная замена**: пропущенные поля очищаются, неуказанные вложения удаляются. Текущее состояние: `mail.get_message` (адресаты/тема/вложения) + `mail.read_message` (тело), где message_id = draft_mid. **НЕ отправляет письмо.**

## mail.delete_message
| Параметр | Тип | Описание |
|---|---|---|
| message_ids | string[] | Идентификаторы писем |
| thread_ids | string[] | Идентификаторы цепочек |

Хотя бы один массив. Перемещает в «Удаленные» (уже удалённые повторно не трогает). Перед вызовом — подтверждение пользователя.

## mail.add_message_labels / mail.remove_message_labels
| Параметр | Тип | Описание |
|---|---|---|
| label_ids* | string[] | Идентификаторы меток |
| message_ids | string[] | Идентификаторы писем |
| thread_ids | string[] | Идентификаторы цепочек |

Хотя бы один из message_ids/thread_ids.

## mail.move_messages
| Параметр | Тип | Описание |
|---|---|---|
| destination_folder_id* | string | Папка назначения |
| message_ids | string[] | Идентификаторы писем |
| thread_ids | string[] | Идентификаторы цепочек |
| destination_tab_type | string | `relevant` / `news` / `social` — категория письма |

---

## Загрузка нового вложения для черновика
```
POST https://cloud-api.yandex.net/v1/mail/drafts/attachments/upload?filename=<URL-кодированное имя>
Authorization: Bearer <тот же OAuth-токен, YANDEX360_MAIL_API_KEY из .env>
Content-Type: application/octet-stream
Content-Length: <размер в байтах>

<тело — сам файл, БЕЗ multipart/form-data, до 24 МиБ>
```
Ответ → `stid`, передать в `attachment_stids` create/update_draft. Токен читать из `.env` внутри скрипта, не выводить в чат/лог.
