#!/usr/bin/env bash
# nb-daily-init — pre-create today's nb daily note from ~/.nb/.templates/daily-template.md.
# Exits silently if the file already exists (nb daily append will find it ready).
set -euo pipefail

NB_HOME="${HOME}/.nb/home"
TODAY="$(date +%Y%m%d)"
DATESTAMP="$(date +%Y-%m-%d)"
DAYNAME="$(date +'%A, %B %-d, %Y')"
TARGET="${NB_HOME}/${TODAY}.md"
TEMPLATE="${HOME}/.nb/.templates/daily-template.md"

[[ -e "${TARGET}" ]] && exit 0

WEATHER="$(curl -sf "https://wttr.in/?format=%c+%C,+%t+(feels+%f),+%h+humidity,+%w&m" \
  2>/dev/null || echo "(weather unavailable)")"

if [[ -f "${TEMPLATE}" ]]; then
    CONTENT="$(sed \
        -e "s|{{date}}|${DATESTAMP}|g" \
        -e "s|{{day}}|${DAYNAME}|g"    \
        -e "s|{{weather}}|${WEATHER}|g" \
        "${TEMPLATE}")"
else
    CONTENT="$(printf '# Daily %s\n\n> **%s**\n> %s\n\n---\n\n### Morning\n\n\n### Focus\n\n\n### Evening\n\n---\n' \
        "${DATESTAMP}" "${DAYNAME}" "${WEATHER}")"
fi

printf '%s\n' "${CONTENT}" > "${TARGET}"

# Update nb's index
grep -qxF "${TODAY}.md" "${NB_HOME}/.index" 2>/dev/null \
    || printf '%s\n' "${TODAY}.md" >> "${NB_HOME}/.index"

# Commit to nb's git backing store
git -C "${NB_HOME}" add "${TODAY}.md" 2>/dev/null \
    && git -C "${NB_HOME}" commit -m "Add daily ${DATESTAMP}" 2>/dev/null \
    || true
