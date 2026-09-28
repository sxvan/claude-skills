param([string]$Url)

Add-Type -AssemblyName System.Web
$query = [System.Web.HttpUtility]::ParseQueryString(([Uri]$Url).Query)

$distro  = [Uri]::EscapeDataString($query['distro'])
$folder  = ($query['folder'] -split '/' | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'
$session = [Uri]::EscapeDataString($query['session'])

Start-Process "vscode://vscode-remote/wsl+$distro$folder"
Start-Sleep -Seconds 1
Start-Process "vscode://anthropic.claude-code/open?session=$session"
