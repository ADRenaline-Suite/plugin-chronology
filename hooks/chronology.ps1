# Session-log hooks. The paragraph is written by the agent. This script only
# passes the window id, remembers that the window edited a file, asks once
# when that note is missing, and stamps the close line.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("sessionStart", "SessionStart", "afterFileEdit", "afterAgentThought", "preToolUse", "stop", "sessionEnd")]
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

function Write-Utf8Text([string]$Path, [string]$Text) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

function Write-Utf8Lines([string]$Path, [string[]]$Lines) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($Path, $Lines, $utf8)
}

function Get-ThoughtBlock([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $found = [regex]::Matches($Text, '(?s)<<<chronology\s*\r?\n(.*?)chronology>>>')
    if ($found.Count -eq 0) { return $null }
    $body = $found[$found.Count - 1].Groups[1].Value
    $title = ""
    $outcome = ""
    if ($body -match '(?m)^title:\s*(.+?)\s*$') { $title = $Matches[1].Trim() }
    if ($body -match '(?m)^outcome:\s*(worked|failed|partial)\s*$') { $outcome = $Matches[1] }
    $split = [regex]::Split($body, "(?m)^outcome:\s*(?:worked|failed|partial)\s*\r?\n", 2)
    $paragraph = ""
    if ($split.Count -eq 2) { $paragraph = $split[1].Trim() }
    $title = ($title -replace '[\r\n#|]', '').Trim()
    if ($title.Length -gt 80) { $title = $title.Substring(0, 80).Trim() }
    if (-not $title -or -not $outcome -or -not $paragraph) { return $null }
    return @{ title = $title; outcome = $outcome; paragraph = $paragraph }
}

function Get-NoteSections([string]$Text) {
    $list = New-Object System.Collections.Generic.List[object]
    $rx = [regex]'(?m)^## (\d{4}-\d{2}-\d{2})T\d{2}:\d{2}:\d{2}Z\s+Outcome: (worked|failed|partial)\b'
    foreach ($match in $rx.Matches($Text)) {
        $list.Add(@{ date = $match.Groups[1].Value; outcome = $match.Groups[2].Value })
    }
    return ,$list
}

function Test-ShouldAppend($Sections, [string]$Outcome, [string]$Today) {
    if ($Sections.Count -eq 0) { return $true }
    $todayCount = @($Sections | Where-Object { $_.date -eq $Today }).Count
    if ($todayCount -ge 2) { return $false }
    $last = $Sections[$Sections.Count - 1]
    if ($last.date -lt $Today) { return $true }
    if ($last.outcome -ne $Outcome) { return $true }
    return $false
}

function Get-NextNumber([string]$PersonDir) {
    $max = 0
    if (Test-Path -LiteralPath $PersonDir) {
        Get-ChildItem -LiteralPath $PersonDir -Filter "*-chronology-*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -match '^(\d+)-chronology-') {
                $n = [int]$Matches[1]
                if ($n -gt $max) { $max = $n }
            }
        }
    }
    return $max + 1
}

function Ensure-Origin([string]$OutputFull) {
    $path = Join-Path $OutputFull "ORIGIN.json"
    $expected = [ordered]@{
        suite = "ADRenaline-Suite"
        plugin = "plugin-chronology"
        repository = "https://github.com/ADRenaline-Suite/plugin-chronology"
        convention = "adr-001"
    }
    $write = -not (Test-Path -LiteralPath $path)
    if (-not $write) {
        try {
            $current = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
            foreach ($key in $expected.Keys) {
                if ([string]$current.$key -ne [string]$expected[$key]) { $write = $true }
            }
        } catch { $write = $true }
    }
    if ($write) {
        Write-Utf8Text $path (($expected | ConvertTo-Json -Compress) + "`n")
    }
}

function Set-StatusRow([string]$StatusPath, [string]$N, [string]$Archivo, [string]$WindowId, [string]$Outcome, [string]$Utc) {
    $notas = "window:${WindowId}; outcome:${Outcome}; at:${Utc}"
    $row = "| $N | $Archivo | accepted | | $notas |"
    if (-not (Test-Path -LiteralPath $StatusPath)) {
        Write-Utf8Lines $StatusPath @(
            "| N | archivo | estado | sustituye | notas |",
            "| --- | --- | --- | --- | --- |",
            $row
        )
        return
    }
    $lines = [System.Collections.Generic.List[string]]@(Get-Content -LiteralPath $StatusPath)
    $marker = "window:$WindowId"
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notlike "*$marker*") { continue }
        $closed = ""
        if ($lines[$i] -match 'closed:([^|]*)') {
            $stamp = $Matches[1].Trim()
            if ($stamp) { $closed = "; closed:$stamp" }
        }
        $lines[$i] = "| $N | $Archivo | accepted | | $notas$closed |"
        $found = $true
        break
    }
    if (-not $found) { $lines.Add($row) }
    Write-Utf8Lines $StatusPath $lines.ToArray()
}

function Save-ThoughtNote([string]$Root, [string]$WindowId, [string]$GenerationId, $Block) {
    $slug = Get-PersonSlug (Get-GitName $Root)
    if (-not $slug) { return }
    $relative = Get-OutputDir $Root
    $outputFull = Join-Path $Root $relative
    $ledger = Get-LedgerPath $Root $WindowId
    $seenDir = Split-Path -Parent $ledger
    $seenKey = $GenerationId
    if ([string]::IsNullOrWhiteSpace($seenKey)) {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Block.title + $Block.outcome + $Block.paragraph))
        $seenKey = [System.BitConverter]::ToString($bytes).Replace("-", "").Substring(0, 16).ToLowerInvariant()
    }
    $seenKey = [regex]::Replace($seenKey, '[^A-Za-z0-9-]', '')
    $seenPath = Join-Path $seenDir "seen-$seenKey"
    if (Test-Path -LiteralPath $seenPath) { return }

    $utc = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $today = $utc.Substring(0, 10)
    $personDir = Join-Path $outputFull $slug
    $existing = Find-Note $outputFull $WindowId
    $section = @"
## $utc

Outcome: $($Block.outcome)

$($Block.paragraph)
"@.TrimEnd()

    if ($existing) {
        $current = [System.IO.File]::ReadAllText($existing)
        $sections = Get-NoteSections $current
        if (-not (Test-ShouldAppend $sections $Block.outcome $today)) {
            Write-Utf8Text $seenPath "skipped"
            return
        }
        $text = $current.TrimEnd() + "`r`n`r`n" + $section + "`r`n"
        Write-Utf8Text $existing $text
        $fileName = Split-Path -Leaf $existing
        if ($fileName -match '^(\d+)-') { $n = "{0:D3}" -f [int]$Matches[1] } else { $n = "000" }
        Set-StatusRow (Join-Path $outputFull "STATUS.md") $n "$slug/$fileName" $WindowId $Block.outcome $utc
    } else {
        if (-not (Test-Path -LiteralPath $personDir)) {
            New-Item -ItemType Directory -Path $personDir -Force | Out-Null
        }
        $topic = Get-PersonSlug $Block.title
        if (-not $topic) { $topic = "note" }
        if ($topic.Length -gt 40) { $topic = $topic.Substring(0, 40).Trim('-') }
        $n = Get-NextNumber $personDir
        $path = $null
        $fileName = $null
        while ($true) {
            $fileName = "{0:D3}-chronology-{1}.md" -f $n, $topic
            $path = Join-Path $personDir $fileName
            if (-not (Test-Path -LiteralPath $path)) { break }
            $held = [System.IO.File]::ReadAllText($path)
            if ($held.Contains("<!-- window:$WindowId -->")) { break }
            $n++
        }
        $body = @"
# $($Block.title)

<!-- window:$WindowId -->

$section

"@
        Write-Utf8Text $path $body
        Set-StatusRow (Join-Path $outputFull "STATUS.md") ("{0:D3}" -f $n) "$slug/$fileName" $WindowId $Block.outcome $utc
    }
    Ensure-Origin $outputFull
    Write-Utf8Text $seenPath "written"
}

function Test-ChronologyEdit($Payload, [string]$Root) {
    $tool = [string]$Payload.tool_name
    $writers = @("Write", "StrReplace", "Delete", "EditNotebook", "ApplyPatch")
    if ($writers -notcontains $tool) { return $false }
    if (-not $Payload.tool_input) { return $false }
    $relative = Get-OutputDir $Root
    $outputFull = Join-Path $Root $relative
    foreach ($prop in $Payload.tool_input.PSObject.Properties) {
        $value = [string]$prop.Value
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        if (Test-UnderOutput $value $outputFull) { return $true }
    }
    return $false
}

$payload = Get-Payload
if (-not $payload) {
    if ($Event -eq "stop") { Write-Json @{} }
    elseif ($Event -eq "preToolUse") { Write-Json @{ permission = "allow" } }
    exit 0
}

$windowId = Get-WindowId $payload
$root = Get-ProjectRoot $payload

try {
    if ($Event -eq "sessionStart" -or $Event -eq "SessionStart") {
        $slug = ""
        if ($root) { $slug = Get-PersonSlug (Get-GitName $root) }
        $instruction = "Follow skill record-chronology and references/note.md. When this turn changes the project or reaches a result, put one chronology block in thinking and nowhere else. Do not create or edit files in the chronology folder. Do not mention the note, the path, or a status line in the reply. The reply is only what was asked. Omit the block when the turn does not qualify. Do not write a transcript or a secret. The block is <<<chronology then a line title: <topic> then a line outcome: worked or failed or partial then a blank line then one paragraph then chronology>>>."
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

    if ($Event -eq "preToolUse") {
        if ($root -and (Test-ChronologyEdit $payload $root)) {
            Write-Json @{
                permission = "deny"
                agent_message = "Do not edit the chronology folder. Put the chronology block only in thinking. The hook writes the file. Leave it out of the reply."
            }
        } else {
            Write-Json @{ permission = "allow" }
        }
        exit 0
    }

    if (-not $root -or -not $windowId) {
        if ($Event -eq "stop") { Write-Json @{} }
        exit 0
    }

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

    if ($Event -eq "afterAgentThought") {
        $block = Get-ThoughtBlock ([string]$payload.text)
        if ($block) {
            $generation = [string]$payload.generation_id
            Save-ThoughtNote $root $windowId $generation $block
        }
        exit 0
    }

    if ($Event -eq "stop") {
        Write-Json @{}
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
    elseif ($Event -eq "preToolUse") { Write-Json @{ permission = "allow" } }
    exit 0
}
