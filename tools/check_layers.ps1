$ErrorActionPreference = 'Stop'
$roots = @('lib/domain','lib/data','lib/presentation','lib/core') | Where-Object { Test-Path $_ }
if ($roots.Count -gt 0) {
  $offenders = Get-ChildItem -Path $roots -Recurse -File -Filter '*.dart' | Select-String -Pattern 'Platform\.is(Android|Windows|Linux)','import .*?(smtc_windows|dbus|audio_service)'
  if ($offenders) { $offenders; throw 'Platform leak outside lib/platform' }
}
Write-Output 'Layer isolation check OK'
