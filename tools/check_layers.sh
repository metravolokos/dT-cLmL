#!/usr/bin/env bash
set -euo pipefail
if grep -R -n -E 'Platform\.is(Android|Windows|Linux)|import .*(smtc_windows|dbus|audio_service)' lib/domain lib/data lib/presentation lib/core 2>/dev/null; then
  echo 'Platform leak outside lib/platform' >&2
  exit 1
fi
echo 'Layer isolation check OK'
