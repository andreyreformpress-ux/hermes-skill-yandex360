# Yandex 360 MCP Skill для Hermes Agent

Единый скилл [Hermes Agent](https://hermes-agent.nousresearch.com) для работы с **Яндекс 360** через официальные MCP-серверы Яндекса:

| Сервис | MCP-сервер | Инструментов | Авторизация |
|---|---|---|---|
| 📧 Почта | `yandex360_mail` | 13 | `Bearer` |
| 📅 Календарь | `yandex360_calendar` | 15 | `OAuth` |
| 🎥 Телемост | `yandex360_telemost` | 18 | `OAuth` |

**46 инструментов** с полными схемами параметров, снятыми `tools/list` с живых серверов (не пересказ документации) — плюс выверенные сценарии использования и правила безопасности.

## Что умеет

**Почта** — поиск и чтение писем (в т.ч. конспекты встреч Телемоста), папки, метки, черновики с HTML-телом и вложениями (до 24 МиБ), перемещение и удаление писем. Отправки нет — черновик остаётся черновиком, пользователь отправляет сам.

**Календарь** — план на день, поиск событий, создание/перенос/удаление встреч (включая повторяющиеся серии через `recurrence_id`), управление участниками, ответы на приглашения (ACCEPTED / DECLINED / TENTATIVE), занятость пользователей и переговорных, подбор свободных слотов, офисы и переговорные.

**Телемост** — создание видеовстреч (комната ожидания, трансляция, соорганизаторы, автоконспектирование, автооблачная запись), ссылки подключения, поиск людей, чаты/каналы/треды и поиск сообщений (только чтение).

## Установка

```bash
git clone https://github.com/andreyreformpress-ux/hermes-skill-yandex360.git \
  ~/.hermes/skills/productivity/yandex360
```

Для профиля — `~/.hermes/profiles/<имя>/skills/productivity/yandex360`.

## Настройка

Ключи **никогда не хранятся в config.yaml и не передаются в чат** — только в `~/.hermes/.env`, а конфиг ссылается на них как `${VAR}` (Hermes подставляет значения при старте агента):

```bash
# 1. Получите три OAuth-токена (у каждого сервиса свой, скоупы не взаимозаменяемы):
#    почта:     https://yandex.ru/dev/yandex-360/mcp/ru/mail
#    календарь: https://oauth.yandex.ru/authorize?client_id=d5fff53202474631801939f538932a5c&response_type=token
#    телемост:  https://oauth.yandex.ru/authorize?client_id=80d9d53eb9c34b11baa4d76778fe5282&response_type=token

# 2. Положите их в ~/.hermes/.env:
YANDEX360_MAIL_API_KEY=<токен почты>
YANDEX360_CALENDAR_API_KEY=<токен календаря>
YANDEX360_TELEMOST_API_KEY=<токен Телемоста>
chmod 600 ~/.hermes/.env

# 3. Зарегистрируйте MCP-серверы:
hermes config set mcp_servers.yandex360_mail.url "https://mcp.360.yandex.net/v1/mail/mcp" --force
hermes config set mcp_servers.yandex360_mail.headers.Authorization "Bearer ${YANDEX360_MAIL_API_KEY}" --force
hermes config set mcp_servers.yandex360_calendar.url "https://mcp.360.yandex.net/v1/calendar/mcp" --force
hermes config set mcp_servers.yandex360_calendar.headers.Authorization "OAuth ${YANDEX360_CALENDAR_API_KEY}" --force
hermes config set mcp_servers.yandex360_telemost.url "https://mcp.360.yandex.net/v1/telemost/mcp" --force
hermes config set mcp_servers.yandex360_telemost.headers.Authorization "OAuth ${YANDEX360_TELEMOST_API_KEY}" --force

# 4. Проверьте и перезапустите шлюз:
hermes mcp test yandex360_mail      # → 13 инструментов
hermes mcp test yandex360_calendar  # → 15
hermes mcp test yandex360_telemost  # → 18
hermes gateway restart
```

⚠️ **Важно:** токен почты **не** даёт доступа к календарю и Телемосту — подключение пройдёт, но обращения к данным вернут 403/пустые списки. Схемы авторизации тоже разные: почта — `Bearer`, календарь и Телемост — `OAuth`.

## Структура

```
SKILL.md                      — когда применять, настройка, карты всех 46 инструментов, сценарии
references/tools-mail.md      — полные схемы параметров почты (13)
references/tools-calendar.md  — полные схемы параметров календаря (15)
references/tools-telemost.md  — полные схемы параметров Телемоста (18)
```

## Правила безопасности, зашитые в скилл

- Токены — только в `.env`; в config.yaml — ссылки `${VAR}`; агент не принимает ключи в чате.
- Все изменяющие операции (создание/изменение/удаление событий, соорганизаторы, удаление писем) — только после явного подтверждения пользователя.
- Удаление — всегда с перечислением того, что будет удалено.
- `mail.update_draft` затирает пропущенные поля — скилл требует сначала прочитать текущее состояние.
- Учтены неочевидные особенности API: курсорная пагинация (следующая страница — только `cursor`), `recurrence_id` для отдельных повторов серий, повторное использование вложений, загрузка новых файлов на `cloud-api.yandex.net`.

## Совместимость

Скилл написан для формата навыков Hermes Agent (прогрессивная загрузка: SKILL.md + references), но `references/*.md` — это самодостаточные справочники схем инструментов, полезные с любым MCP-клиентом (Claude, Codex и т.п.).

Требования: подписка Яндекс 360 (Почта/Календарь для организации), Hermes Agent с MCP-клиентом.

## Лицензия

MIT — см. [LICENSE](LICENSE). MCP-серверы Яндекс 360 — предварительная версия API, обратная совместимость не гарантирована: перед критичными сценариями сверяйте схемы с [документацией](https://yandex.ru/dev/yandex-360/mcp/ru/).
