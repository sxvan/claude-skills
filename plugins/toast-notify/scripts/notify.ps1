param([string]$ProjectDir, [string]$Distro)


[Console]::InputEncoding = [Text.Encoding]::UTF8
$data = [Console]::In.ReadToEnd() | ConvertFrom-Json

if ($data.background_tasks){ 
  exit 
}

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

$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

# Windows can't load toast images from \\wsl.localhost paths
$logo = Join-Path $env:TEMP 'claude-ai-logo.png'
Copy-Item (Join-Path $PSScriptRoot '..\assets\claude-ai-logo.png') $logo -Force

# One app ID per session, so the notification center groups toasts by session instead of collapsing them all
$appId  = "VSClaude.$session_id"
$appKey = "HKCU:\Software\Classes\AppUserModelId\$appId"
New-Item -Path $appKey -Force | Out-Null
Set-ItemProperty -Path $appKey -Name 'DisplayName' -Value "$project - $title"
Set-ItemProperty -Path $appKey -Name 'IconUri'     -Value $logo

$launch = 'vsclaude://open?session={0}&folder={1}&distro={2}' -f ($session_id, $ProjectDir, $Distro | ForEach-Object { [Uri]::EscapeDataString($_) })

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml(@"
<toast activationType="protocol" launch="$([Security.SecurityElement]::Escape($launch))">
  <visual>
    <binding template="ToastGeneric">
      <image placement="appLogoOverride" hint-crop="circle" src="$([Security.SecurityElement]::Escape($logo))"/>
      <text>Claude responded</text>
      <text>$([Security.SecurityElement]::Escape($msg))</text>
      <text placement="attribution">via VSClaude</text>
    </binding>
  </visual>
</toast>
"@)

$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
$toast.Tag = $session_id

[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)