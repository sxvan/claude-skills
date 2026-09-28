param([string]$ProjectDir, [string]$Distro)


[Console]::InputEncoding = [Text.Encoding]::UTF8
$data = [Console]::In.ReadToEnd() | ConvertFrom-Json
$msg  = $data.last_assistant_message
$cwd  = $data.cwd
$session_id = $data.session_id
$transcript_path = $data.transcript_path

$project = Split-Path -Leaf $ProjectDir

$transcript = "\\wsl.localhost\$Distro" + ($transcript_path -replace '/', '\')

$title = $null
if (Test-Path $transcript) {
  $lines = Select-String -Path $transcript -Pattern '"type":"(custom-title|ai-title)"' | ForEach-Object { $_.Line | ConvertFrom-Json }
  $custom = $lines | Where-Object type -eq 'custom-title' | Select-Object -Last 1
  $ai     = $lines | Where-Object type -eq 'ai-title'     | Select-Object -Last 1
  $title  = if ($custom) { $custom.customTitle } elseif ($ai) { $ai.aiTitle }
}

if (-not $title) { $title = 'Claude Code' }

$logo = New-BTImage -Source (Join-Path $PSScriptRoot '..\assets\claude-ai-logo.png') -AppLogoOverride -Crop Circle

$text1 = New-BTText -Content "$project - $title"
$text2 = New-BTText -Content $msg

$binding = New-BTBinding -Children $text1, $text2 -AppLogoOverride $logo
$visual = New-BTVisual -BindingGeneric $binding

$launch = 'vsclaude://open?session={0}&folder={1}&distro={2}' -f ($session_id, $ProjectDir, $Distro | ForEach-Object { [Uri]::EscapeDataString($_) })

$content = New-BTContent -Visual $visual -ActivationType Protocol -Launch $launch

Submit-BTNotification -Content $content -UniqueIdentifier $session_id