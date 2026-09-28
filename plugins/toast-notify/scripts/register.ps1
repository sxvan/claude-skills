$key     = 'HKCU:\Software\Classes\vsclaude'
$handler = Join-Path $PSScriptRoot 'open-session.ps1'

New-Item -Path "$key\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path $key -Name '(Default)'    -Value 'URL:vsclaude'
Set-ItemProperty -Path $key -Name 'URL Protocol' -Value ''
Set-ItemProperty -Path "$key\shell\open\command" -Name '(Default)' `
  -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$handler`" `"%1`""
