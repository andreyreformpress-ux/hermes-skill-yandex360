#!/usr/bin/env bash
# Установка MCP-серверов Яндекс 360 (Почта, Календарь, Телемост) для Hermes Agent.
# Токены вводятся скрытым вводом и сохраняются в файл секретов профиля (права 600).
# В config.yaml попадают только ссылки ${VAR} — сами токены туда не пишутся.
set -euo pipefail

HERMES_BIN="${HERMES_BIN:-hermes}"
ENV_FILE="${HERMES_HOME:-$HOME/.hermes}/.env"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DST="${HERMES_HOME:-$HOME/.hermes}/skills/productivity/yandex360"

say() { printf '\n%s\n' "$*"; }

command -v "$HERMES_BIN" >/dev/null 2>&1 || { echo "Ошибка: Hermes CLI ('$HERMES_BIN') не найден в PATH." >&2; exit 1; }

say "=== Установка Яндекс 360 (Почта + Календарь + Телемост) для Hermes ==="
say "Токены будут сохранены в: $ENV_FILE (права 600). В config.yaml — только ссылки \${VAR}."
say "Токен для каждого сервиса получается своей ссылкой «получить OAuth-токен»:"
say "  Почта:     https://yandex.ru/dev/yandex-360/mcp/ru/mail"
say "  Календарь: https://yandex.ru/dev/yandex-360/mcp/ru/calendar"
say "  Телемост:  https://yandex.ru/dev/yandex-360/mcp/ru/telemost"

read_token() {
  local prompt="$1" var
  while true; do
    printf '%s' "$prompt"
    if ! read -rs var </dev/tty 2>/dev/null; then read -rs var; fi
    printf '\n'
    if [ -n "$var" ]; then printf '%s' "$var"; return; fi
    echo "Пустое значение — попробуйте ещё раз (Ctrl+C для отмены)." >&2
  done
}

upsert_env() { # KEY VALUE
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  awk -v k="$key" -v v="$value" 'BEGIN{done=0}
    $0 ~ "^"k"=" { print k"="v; done=1; next }
    { print }
    END { if (!done) print k"="v }' "$ENV_FILE" >"$tmp" && mv "$tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
}

MAIL_TOKEN="$(read_token 'OAuth-токен Почты: ')"
CAL_TOKEN="$(read_token 'OAuth-токен Календаря: ')"
TM_TOKEN="$(read_token 'OAuth-токен Телемоста: ')"

upsert_env YANDEX360_MAIL_API_KEY "$MAIL_TOKEN"
upsert_env YANDEX360_CALENDAR_API_KEY "$CAL_TOKEN"
upsert_env YANDEX360_TELEMOST_API_KEY "$TM_TOKEN"
say "Токены сохранены в $ENV_FILE."

cfg() { "$HERMES_BIN" config set "$1" "$2" --force >/dev/null && echo "  ✓ $1"; }
say "Регистрация MCP-серверов в config.yaml…"
cfg mcp_servers.yandex360_mail.url "https://mcp.360.yandex.net/v1/mail/mcp"
cfg mcp_servers.yandex360_mail.headers.Authorization "Bearer \${YANDEX360_MAIL_API_KEY}"
cfg mcp_servers.yandex360_calendar.url "https://mcp.360.yandex.net/v1/calendar/mcp"
cfg mcp_servers.yandex360_calendar.headers.Authorization "OAuth \${YANDEX360_CALENDAR_API_KEY}"
cfg mcp_servers.yandex360_telemost.url "https://mcp.360.yandex.net/v1/telemost/mcp"
cfg mcp_servers.yandex360_telemost.headers.Authorization "OAuth \${YANDEX360_TELEMOST_API_KEY}"

if [ -d "$REPO_ROOT/skills/yandex360" ]; then
  say "Установка скилла yandex360…"
  mkdir -p "$(dirname "$SKILL_DST")"
  rm -rf "$SKILL_DST"
  cp -R "$REPO_ROOT/skills/yandex360" "$SKILL_DST"
  echo "  ✓ $SKILL_DST"
fi

say "Проверка подключений…"
ok=1
for s in yandex360_mail yandex360_calendar yandex360_telemost; do
  out="$("$HERMES_BIN" mcp test "$s" </dev/null 2>&1 || true)"
  if printf '%s' "$out" | grep -q "Tools discovered"; then
    echo "  ✓ $s — подключен"
  else
    echo "  ✗ $s — не подключился (проверьте токен: $HERMES_BIN mcp test $s)"; ok=0
  fi
done

say "Готово. Перезапустите шлюз, чтобы инструменты появились в сессиях:"
say "  $HERMES_BIN gateway restart   (или Restart gateway в статус-меню приложения)"
[ "$ok" = 1 ] || exit 2
