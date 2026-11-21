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

Клонируйте репозиторий и запустите интерактивный установщик — он спросит три OAuth-токена скрытым вводом, сохранит их в файл секретов профиля (права 600), зарегистрирует все три MCP-сервера, скопирует скилл и проверит подключение:

```bash
git clone https://github.com/andreyreformpress-ux/hermes-skill-yandex360.git
cd hermes-skill-yandex360 && ./install.sh
```

Токены можно в любой момент поменять: в приложении **Capabilities → Connectors → сервер → изменить ключ**, либо отредактировав переменные в файле секретов профиля. Если вы используете 1Password/Bitwarden — токены можно хранить в менеджере секретов (`hermes secrets onepassword` / `hermes secrets bitwarden`) вместо файла.

После установки перезапустите шлюз (`hermes gateway restart` или Restart gateway в статус-меню приложения) — инструменты появятся в новых сессиях.

## Настройка (вручную, без установщика)

1. Получите три OAuth-токена по ссылкам «получить OAuth-токен» (у каждого сервиса свой токен, скоупы не взаимозаменяемы):
   - Почта: https://yandex.ru/dev/yandex-360/mcp/ru/mail
   - Календарь: https://yandex.ru/dev/yandex-360/mcp/ru/calendar
   - Телемост: https://yandex.ru/dev/yandex-360/mcp/ru/telemost
2. Положите их в `~/.hermes/.env` (для профиля — `~/.hermes/profiles/<имя>/.env`):
   ```bash
   YANDEX360_MAIL_API_KEY=<токен почты>
   YANDEX360_CALENDAR_API_KEY=<токен календаря>
   YANDEX360_TELEMOST_API_KEY=<токен Телемоста>
   chmod 600 ~/.hermes/.env
   ```
3. Зарегистрируйте серверы (в config.yaml — только ссылки `${VAR}`, токены туда не попадают):
   ```bash
   hermes config set mcp_servers.yandex360_mail.url "https://mcp.360.yandex.net/v1/mail/mcp" --force
   hermes config set mcp_servers.yandex360_mail.headers.Authorization "Bearer ${YANDEX360_MAIL_API_KEY}" --force
   hermes config set mcp_servers.yandex360_calendar.url "https://mcp.360.yandex.net/v1/calendar/mcp" --force
   hermes config set mcp_servers.yandex360_calendar.headers.Authorization "OAuth ${YANDEX360_CALENDAR_API_KEY}" --force
   hermes config set mcp_servers.yandex360_telemost.url "https://mcp.360.yandex.net/v1/telemost/mcp" --force
   hermes config set mcp_servers.yandex360_telemost.headers.Authorization "OAuth ${YANDEX360_TELEMOST_API_KEY}" --force
   ```
4. Скилл (если ставите без git clone): `hermes skills install https://raw.githubusercontent.com/andreyreformpress-ux/hermes-skill-yandex360/main/skills/yandex360/SKILL.md`
5. Проверка и включение: `hermes mcp test yandex360_mail` (13), `... yandex360_calendar` (15), `... yandex360_telemost` (18) → перезапуск шлюза.

⚠️ **Важно:** токен почты **не** даёт доступа к календарю и Телемосту — подключение пройдёт, но обращения к данным вернут 403/пустые списки. Схемы авторизации тоже разные: почта — `Bearer`, календарь и Телемост — `OAuth` (эмпирически `Bearer` принимают все три, но конфигурируйте по документации).

## Структура

```
install.sh                    — интерактивный установщик (токены + серверы + скилл)
skills/yandex360/SKILL.md     — когда применять, настройка, карты всех 46 инструментов, сценарии
skills/yandex360/references/  — полные схемы параметров: tools-mail (13), tools-calendar (15), tools-telemost (18)
```

## Правила безопасности, зашитые в скилл

- Токены — только в файле секретов профиля; в config.yaml — ссылки `${VAR}`; агент не принимает ключи в чате.
- Все изменяющие операции (создание/изменение/удаление событий, соорганизаторы, удаление писем) — только после явного подтверждения пользователя.
- Удаление — всегда с перечислением того, что будет удалено.
- `mail.update_draft` затирает пропущенные поля — скилл требует сначала прочитать текущее состояние.
- Учтены неочевидные особенности API: курсорная пагинация (следующая страница — только `cursor`), `recurrence_id` для отдельных повторов серий, повторное использование вложений, загрузка новых файлов на `cloud-api.yandex.net`.

## Совместимость

Скилл написан для формата навыков Hermes Agent (прогрессивная загрузка: SKILL.md + references), но `references/*.md` — это самодостаточные справочники схем инструментов, полезные с любым MCP-клиентом (Claude, Codex и т.п.).

Требования: подписка Яндекс 360 (Почта/Календарь для организации), Hermes Agent с MCP-клиентом.

## Лицензия

MIT — см. [LICENSE](LICENSE). MCP-серверы Яндекс 360 — предварительная версия API, обратная совместимость не гарантирована: перед критичными сценариями сверяйте схемы с [документацией](https://yandex.ru/dev/yandex-360/mcp/ru/).
