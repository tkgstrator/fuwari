ARG BUN_VERSION

FROM oven/bun:${BUN_VERSION}
RUN apt_fragments="$(find /etc/apt/sources.list.d -mindepth 1 -print)" \
 && test -z "$apt_fragments" \
 && apt_sources="$(grep -Ev '^[[:space:]]*(#|$)' /etc/apt/sources.list)" \
 && test "$apt_sources" = "$(printf '%s\n' \
    'deb http://deb.debian.org/debian bullseye main' \
    'deb http://deb.debian.org/debian-security bullseye-security main' \
    'deb http://deb.debian.org/debian bullseye-updates main')" \
 && sed -i 's|^deb http://deb.debian.org/debian-security bullseye-security main$|deb http://archive.debian.org/debian-security bullseye-security main|' /etc/apt/sources.list \
 && grep -Fxq 'deb http://archive.debian.org/debian-security bullseye-security main' /etc/apt/sources.list \
 && rm -rf /var/lib/apt/lists/*

USER bun
WORKDIR /home/bun/app
CMD ["/bin/bash"]