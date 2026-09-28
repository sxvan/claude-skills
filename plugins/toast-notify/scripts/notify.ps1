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

$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

# PowerShell's own app ID, which Windows accepts without registering anything
$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

$logo   = Join-Path $PSScriptRoot '..\assets\claude-ai-logo.png'
$launch = 'vsclaude://open?session={0}&folder={1}&distro={2}' -f ($session_id, $ProjectDir, $Distro | ForEach-Object { [Uri]::EscapeDataString($_) })

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml(@"
<toast activationType="protocol" launch="$([Security.SecurityElement]::Escape($launch))">
  <visual>
    <binding template="ToastGeneric">
      <image placement="appLogoOverride" hint-crop="circle" src="$([Security.SecurityElement]::Escape($logo))"/>
      <text>$([Security.SecurityElement]::Escape("$project - $title"))</text>
      <text>$([Security.SecurityElement]::Escape($msg))</text>
    </binding>
  </visual>
</toast>
"@)

$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
# A later toast from the same session replaces this one
$toast.Tag = $session_id

[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)