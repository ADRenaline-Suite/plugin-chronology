# Session-log hooks. The paragraph is written by the agent. This script only
# passes the window id, remembers that the window edited a file, asks once
# when that note is missing, and stamps the close line.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("sessionStart", "SessionStart", "afterFileEdit", "stop", "sessionEnd")]
    [string]$Event
)

$ErrorActionPreference = "Stop"

function Write-Json([object]$Value) {
    $json = $Value | ConvertTo-Json -Compress -Depth 6
    [Console]::Out.WriteLine($json)
}

function Get-Payload {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    try { return $raw | ConvertFrom-Json } catch { return $null }
}

function Get-WindowId($Payload) {
    $raw = ""
    if ($Payload.session_id) { $raw = [string]$Payload.session_id }
    elseif ($Payload.conversation_id) { $raw = [string]$Payload.conversation_id }
    $safe = [regex]::Replace($raw, '[^A-Za-z0-9-]', '')
    if ([string]::IsNullOrWhiteSpace($safe)) { return "" }
    return $safe
}

function Get-ProjectRoot($Payload) {
    if ($Payload.workspace_roots) {
        foreach ($root in @($Payload.workspace_roots)) {
            if ($root -and (Test-Path -LiteralPath $root)) { return [string]$root }
        }
    }
    foreach ($name in @("CURSOR_PROJECT_DIR", "CLAUDE_PROJECT_DIR")) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if ($value -and (Test-Path -LiteralPath $value)) { return $value }
    }
    return (Get-Location).Path
}

function Get-OutputDir([string]$Root) {
    $nested = "adrenaline\chronology"
    $legacy = "chronology"
    $config = Join-Path $Root ".cursor\adrenaline.json"
    if (Test-Path -LiteralPath $config) {
        try {
            $json = Get-Content -Raw -LiteralPath $config | ConvertFrom-Json
            $path = [string]$json.outputDirs."plugin-chronology"
            if (-not [string]::IsNullOrWhiteSpace($path)) {
                $path = $path.Replace("/", "\").Trim("\")
                if ($path -notmatch '(^\.\.)|(\\\.\.\\)|(\.\.$)|(^[A-Za-z]:\\)|(^\\)') { return $path }
            }
        } catch { }
    }
    $legacyMarker = Join-Path $Root "$legacy\ORIGIN.json"
    $legacyStatus = Join-Path $Root "$legacy\STATUS.md"
    $nestedMarker = Join-Path $Root "$nested\ORIGIN.json"
    $nestedStatus = Join-Path $Root "$nested\STATUS.md"
    $legacyExists = (Test-Path -LiteralPath $legacyMarker) -or (Test-Path -LiteralPath $legacyStatus)
    $nestedExists = (Test-Path -LiteralPath $nestedMarker) -or (Test-Path -LiteralPath $nestedStatus)
    if ($legacyExists -and -not $nestedExists) { return $legacy }
    return $nested
}

function Get-PersonSlug([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return "" }
    $map = @{
        'á'='a'; 'à'='a'; 'ä'='a'; 'â'='a'; 'ã'='a'
        'é'='e'; 'è'='e'; 'ë'='e'; 'ê'='e'
        'í'='i'; 'ì'='i'; 'ï'='i'; 'î'='i'
        'ó'='o'; 'ò'='o'; 'ö'='o'; 'ô'='o'; 'õ'='o'
        'ú'='u'; 'ù'='u'; 'ü'='u'; 'û'='u'
        'ñ'='n'; 'ç'='c'
    }
    $slug = $Name.Trim().ToLowerInvariant()
    foreach ($key in $map.Keys) { $slug = $slug.Replace($key, $map[$key]) }
    $slug = [regex]::Replace($slug, '\s+', '-')
    $slug = [regex]::Replace($slug, '[^a-z0-9-]', '')
    $slug = [regex]::Replace($slug, '-{2,}', '-').Trim('-')
    return $slug
}

function Get-GitName([string]$Root) {
    try {
        $name = & git -C $Root config --get user.name 2>$null
        if ($LASTEXITCODE -ne 0) { return "" }
        return [string]$name
    } catch { return "" }
}

function Get-LedgerPath([string]$Root, [string]$WindowId) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Root.ToLowerInvariant()))
    $hash = [System.BitConverter]::ToString($bytes).Replace("-", "").Substring(0, 16).ToLowerInvariant()
    $base = Join-Path $env:LOCALAPPDATA "ADRenaline\chronology\$hash"
    return (Join-Path $base $WindowId)
}

function Test-UnderOutput([string]$FilePath, [string]$OutputFull) {
    if ([string]::IsNullOrWhiteSpace($FilePath)) { return $false }
    try {
        $full = [System.IO.Path]::GetFullPath($FilePath)
        $root = [System.IO.Path]::GetFullPath($OutputFull)
        if (-not $root.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
            $root = $root + [System.IO.Path]::DirectorySeparatorChar
        }
        return $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)
    } catch { return $false }
}

function Find-Note([string]$OutputFull, [string]$WindowId) {
    if (-not (Test-Path -LiteralPath $OutputFull)) { return $null }
    $marker = "<!-- window:$WindowId -->"
    $files = Get-ChildItem -LiteralPath $OutputFull -Recurse -Filter *.md -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "STATUS.md" }
    foreach ($file in $files) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        if ($text.Contains($marker)) { return $file.FullName }
    }
    return $null
}

function Add-ClosedLine([string]$Path, [string]$Reason) {
    $allowed = @("completed", "aborted", "error", "window_close", "user_close")
    if ($allowed -notcontains $Reason) { $Reason = "unknown" }
    $text = [System.IO.File]::ReadAllText($Path)
    if ($text -match '(?m)^Closed: ') { return }
    $utc = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $line = "Closed: $utc $Reason"
    if (-not $text.EndsWith("`n")) { $text += "`r`n" }
    $text += "`r`n$line`r`n"
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $text, $utf8)
}

function Add-ClosedNote([string]$StatusPath, [string]$WindowId, [string]$Reason) {
    if (-not (Test-Path -LiteralPath $StatusPath)) { return }
    $allowed = @("completed", "aborted", "error", "window_close", "user_close")
    if ($allowed -notcontains $Reason) { $Reason = "unknown" }
    $utc = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $stamp = "closed:$utc $Reason"
    $marker = "window:$WindowId"
    $lines = [System.Collections.Generic.List[string]]@(Get-Content -LiteralPath $StatusPath)
    $changed = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -notmatch '^\|') { continue }
        if ($line -notlike "*$marker*") { continue }
        if ($line -like "*closed:*") { continue }
        $trimmed = $line.TrimEnd()
        if ($trimmed.EndsWith("|")) {
            $trimmed = $trimmed.Substring(0, $trimmed.Length - 1).TrimEnd()
            $lines[$i] = "$trimmed; $stamp |"
            $changed = $true
        }
    }
    if ($changed) {
        $utf8 = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($StatusPath, $lines.ToArray(), $utf8)
    }
}

$payload = Get-Payload
if (-not $payload) {
    if ($Event -eq "stop") { Write-Json @{} }
    exit 0
}

$windowId = Get-WindowId $payload
$root = Get-ProjectRoot $payload

try {
    if ($Event -eq "sessionStart" -or $Event -eq "SessionStart") {
        $slug = ""
        if ($root) { $slug = Get-PersonSlug (Get-GitName $root) }
        $instruction = "Follow skill record-chronology and references/note.md before the reply when this turn changes the project or reaches a result. Do not wait to be asked. Do not write a transcript or a secret."
        if ($slug) {
            $text = "ADRenaline chronology. Window id: $windowId. Person folder: $slug. $instruction"
        } else {
            $text = "ADRenaline chronology. Window id: $windowId. git user.name was not observed. Do not invent a person folder. Skip the note."
        }
        if ($Event -ceq "SessionStart") {
            Write-Json @{
                hookSpecificOutput = @{
                    hookEventName = "SessionStart"
                    additionalContext = $text
                }
            }
        } else {
            Write-Json @{ additional_context = $text }
        }
        exit 0
    }

    if (-not $root -or -not $windowId) { if ($Event -eq "stop") { Write-Json @{} }; exit 0 }

    $relative = Get-OutputDir $root
    $outputFull = Join-Path $root $relative
    $ledger = Get-LedgerPath $root $windowId

    if ($Event -eq "afterFileEdit") {
        $filePath = [string]$payload.file_path
        if (-not (Test-UnderOutput $filePath $outputFull)) {
            $dir = Split-Path -Parent $ledger
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $utf8 = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($ledger, "edited", $utf8)
        }
        exit 0
    }

    if ($Event -eq "stop") {
        $status = [string]$payload.status
        $loops = 0
        if ($payload.loop_count) { $loops = [int]$payload.loop_count }
        $note = Find-Note $outputFull $windowId
        if ($status -eq "completed" -and $loops -eq 0 -and (Test-Path -LiteralPath $ledger) -and -not $note) {
            $slug = Get-PersonSlug (Get-GitName $root)
            $who = "git user.name was not observed. Do not invent a person folder. If it is still missing, write no file."
            if ($slug) { $who = "Person folder: $slug." }
            Write-Json @{
                followup_message = "Write the chronology note for this window. Follow skill record-chronology and references/note.md. Window id: $windowId. $who One paragraph of what was tried and whether it worked. If this window did not change the project and did not reach a result, write no file."
            }
        } else {
            Write-Json @{}
        }
        exit 0
    }

    if ($Event -eq "sessionEnd") {
        $note = Find-Note $outputFull $windowId
        if ($note) {
            $reason = [string]$payload.reason
            Add-ClosedLine $note $reason
            Add-ClosedNote (Join-Path $outputFull "STATUS.md") $windowId $reason
        }
        exit 0
    }
} catch {
    if ($Event -eq "stop") { Write-Json @{} }
    exit 0
}
