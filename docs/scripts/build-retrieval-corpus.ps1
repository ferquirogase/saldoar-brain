param(
    [string]$BrainPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$OutputPath = 'docs/retrieval/brain-retrieval-corpus.jsonl'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$brainRoot = [System.IO.Path]::GetFullPath($BrainPath)

function Normalize-PathString {
    param([string]$PathString)

    return ([System.IO.Path]::GetFullPath($PathString)).Replace('\', '/')
}

function Get-RelativePathCompat {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseUri = New-Object System.Uri((Normalize-PathString $BasePath).TrimEnd('/') + '/')
    $targetUri = New-Object System.Uri((Normalize-PathString $TargetPath))
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('\', '/')
}

function To-Array {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        return @($Value)
    }
    return @($Value)
}

function Get-PropertyValue {
    param(
        [object]$Object,
        [string]$Name
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function ConvertFrom-BrainYaml {
    param([string]$YamlText)

    $result = @{}
    $lines = $YamlText -split "`r?`n"
    $currentKey = $null
    $inBlock = $false

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($inBlock -and $null -ne $currentKey) {
                $result[$currentKey] += "`n"
            }
            continue
        }

        if ($inBlock -and $null -ne $currentKey) {
            if ($line -match '^\s+(?<content>.+)$') {
                $content = $Matches.content
                $existing = [string](Get-PropertyValue -Object ([pscustomobject]$result) -Name $currentKey)
                $result[$currentKey] = ($existing + $content + "`n")
                continue
            }

            $result[$currentKey] = ([string]$result[$currentKey]).Trim()
            $inBlock = $false
            $currentKey = $null
            $i--
            continue
        }

        if ($line -match '^(?<key>[A-Za-z0-9_]+):\s*(?<value>.*)$') {
            $currentKey = $Matches.key
            $rawValue = $Matches.value.Trim()

            if ($rawValue -eq '|' -or $rawValue -eq '>') {
                $result[$currentKey] = ''
                $inBlock = $true
                continue
            }

            if ($rawValue -eq '') {
                if (-not $result.ContainsKey($currentKey)) {
                    $result[$currentKey] = @()
                }
                continue
            }

            $result[$currentKey] = $rawValue.Trim("'`"")
            continue
        }

        if ($line -match '^\s*-\s*(?<item>.+)$' -and $null -ne $currentKey) {
            if (-not ($result[$currentKey] -is [System.Collections.IList])) {
                $result[$currentKey] = @()
            }
            $result[$currentKey] += $Matches.item.Trim().Trim("'`"")
        }
    }

    if ($inBlock -and $null -ne $currentKey) {
        $result[$currentKey] = ([string]$result[$currentKey]).Trim()
    }

    return [pscustomobject]$result
}

function Join-NonEmpty {
    param([string[]]$Parts)

    return (($Parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n").Trim()
}

function Get-MarkdownHeading {
    param([string]$MarkdownText)

    $match = [regex]::Match($MarkdownText, '(?m)^\#\s+(?<title>.+)$')
    if ($match.Success) {
        return $match.Groups['title'].Value.Trim()
    }

    return ''
}

function Get-EdgeCaseYamlRecord {
    param([System.IO.FileInfo]$YamlFile)

    $yamlData = ConvertFrom-BrainYaml (Get-Content -LiteralPath $YamlFile.FullName -Raw)
    $markdownPath = [System.IO.Path]::ChangeExtension($YamlFile.FullName, '.md')
    $markdownRelative = $null
    $markdownText = ''

    if (Test-Path -LiteralPath $markdownPath -PathType Leaf) {
        $markdownRelative = Get-RelativePathCompat -BasePath $brainRoot -TargetPath $markdownPath
        $markdownText = (Get-Content -LiteralPath $markdownPath -Raw).Trim()
    }

    $queryPatterns = To-Array (Get-PropertyValue -Object $yamlData -Name 'query_patterns')
    $queryPatterns = $queryPatterns | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $sourcePaths = @()
    foreach ($field in @('source_of_truth', 'backend_sources', 'frontend_sources')) {
        $sourcePaths += To-Array (Get-PropertyValue -Object $yamlData -Name $field)
    }
    $sourcePaths = $sourcePaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique

    $linkedIds = @()
    foreach ($field in @('connected_flows', 'connected_entities', 'connected_integrations', 'connected_domains')) {
        $linkedIds += To-Array (Get-PropertyValue -Object $yamlData -Name $field)
    }
    $linkedIds = $linkedIds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique

    $summary = [string](Get-PropertyValue -Object $yamlData -Name 'summary')
    $abstract = [string](Get-PropertyValue -Object $yamlData -Name 'abstract')
    $primaryDescription = if (-not [string]::IsNullOrWhiteSpace($abstract)) {
        $abstract
    } elseif (-not [string]::IsNullOrWhiteSpace($summary)) {
        $summary
    } else {
        ''
    }

    $structuredText = Join-NonEmpty @(
        'kind: edge_case',
        ('id: ' + [string](Get-PropertyValue -Object $yamlData -Name 'edge_case_id')),
        ('name: ' + [string](Get-PropertyValue -Object $yamlData -Name 'name')),
        ('description: ' + $primaryDescription),
        ('query_patterns: ' + (($queryPatterns -join ' | '))),
        ('linked_ids: ' + (($linkedIds -join ' | '))),
        ('source_paths: ' + (($sourcePaths -join ' | ')))
    )

    $retrievalText = Join-NonEmpty @(
        $structuredText,
        $markdownText
    )

    return [pscustomobject]@{
        doc_id = [string](Get-PropertyValue -Object $yamlData -Name 'edge_case_id')
        kind = 'edge_case'
        name = [string](Get-PropertyValue -Object $yamlData -Name 'name')
        status = [string](Get-PropertyValue -Object $yamlData -Name 'status')
        priority = [string](Get-PropertyValue -Object $yamlData -Name 'severity')
        doc_paths = @(
            (Get-RelativePathCompat -BasePath $brainRoot -TargetPath $YamlFile.FullName),
            $markdownRelative
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        source_paths = $sourcePaths
        linked_ids = $linkedIds
        query_patterns = $queryPatterns
        structured_text = $structuredText
        narrative_text = $markdownText
        retrieval_text = $retrievalText
    }
}

function Get-EdgeCaseRecord {
    param([System.IO.FileInfo]$MarkdownFile)

    $markdownText = (Get-Content -LiteralPath $MarkdownFile.FullName -Raw).Trim()
    $title = Get-MarkdownHeading -MarkdownText $markdownText
    $docId = [System.IO.Path]::GetFileNameWithoutExtension($MarkdownFile.Name)
    $docRelative = Get-RelativePathCompat -BasePath $brainRoot -TargetPath $MarkdownFile.FullName

    $linkedIds = @(
        [regex]::Matches($markdownText, '`(?<id>[A-Za-z0-9_\-]+)`') |
            ForEach-Object { $_.Groups['id'].Value } |
            Where-Object { $_ -notmatch '^(flow_id|status|owner_area|evidence_level|WAITING_PAYMENT|TO_NEW_TICKET|HELD|MEDIATION|README|UX)$' } |
            Select-Object -Unique
    )

    $sourcePaths = @(
        [regex]::Matches($markdownText, '`(?<path>(saldo|solido)\/[^`]+)`') |
            ForEach-Object { $_.Groups['path'].Value } |
            Select-Object -Unique
    )

    $queryPatterns = @(
        [regex]::Matches($markdownText, '[\"“](?<question>[^\"”\?]+\?)[\"”]') |
            ForEach-Object { $_.Groups['question'].Value.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Unique
    )

    $summaryLines = @(
        $markdownText -split "`r?`n" |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Skip 1 -First 12
    )
    $summaryText = ($summaryLines -join ' ').Trim()

    $structuredText = Join-NonEmpty @(
        'kind: edge_case',
        ('id: ' + $docId),
        ('name: ' + $title),
        ('description: ' + $summaryText),
        ('query_patterns: ' + (($queryPatterns -join ' | '))),
        ('linked_ids: ' + (($linkedIds -join ' | '))),
        ('source_paths: ' + (($sourcePaths -join ' | ')))
    )

    $retrievalText = Join-NonEmpty @(
        $structuredText,
        $markdownText
    )

    return [pscustomobject]@{
        doc_id = $docId
        kind = 'edge_case'
        name = $title
        status = ''
        priority = ''
        doc_paths = @($docRelative)
        source_paths = $sourcePaths
        linked_ids = $linkedIds
        query_patterns = $queryPatterns
        structured_text = $structuredText
        narrative_text = $markdownText
        retrieval_text = $retrievalText
    }
}

function Get-DocumentRecord {
    param([System.IO.FileInfo]$YamlFile)

    $yamlData = ConvertFrom-BrainYaml (Get-Content -LiteralPath $YamlFile.FullName -Raw)
    $docDir = Split-Path -Parent $YamlFile.FullName
    $docDirRelative = Get-RelativePathCompat -BasePath $brainRoot -TargetPath $docDir
    $readmePath = Join-Path $docDir 'README.md'
    $readmeRelative = $null
    $readmeText = ''

    if (Test-Path -LiteralPath $readmePath -PathType Leaf) {
        $readmeRelative = Get-RelativePathCompat -BasePath $brainRoot -TargetPath $readmePath
        $readmeText = (Get-Content -LiteralPath $readmePath -Raw).Trim()
    }

    $kind = switch ($YamlFile.Name) {
        'flow.yaml' { 'flow' }
        'domain.yaml' { 'domain' }
        'entity.yaml' { 'entity' }
        'integration.yaml' { 'integration' }
        default { 'unknown' }
    }

    $idField = switch ($kind) {
        'flow' { 'flow_id' }
        'domain' { 'domain_id' }
        'entity' { 'entity_id' }
        'integration' { 'integration_id' }
        default { 'id' }
    }

    $sourceFields = switch ($kind) {
        'flow' { @('frontend_sources', 'backend_sources', 'references', 'source_of_truth') }
        'domain' { @('backend_surface', 'frontend_surface', 'source_of_truth') }
        'entity' { @('backend_model', 'frontend_surface', 'source_of_truth') }
        'integration' { @('backend_surface', 'frontend_surface', 'source_of_truth') }
        default { @('source_of_truth') }
    }

    $linkedFields = switch ($kind) {
        'flow' { @('entities', 'integrations') }
        'domain' { @('core_entities', 'connected_flows', 'connected_domains') }
        'entity' { @('connected_entities', 'connected_domains', 'connected_flows') }
        'integration' { @('connected_flows') }
        default { @() }
    }

    $sourcePaths = @()
    foreach ($field in $sourceFields) {
        $sourcePaths += To-Array (Get-PropertyValue -Object $yamlData -Name $field)
    }
    $sourcePaths = $sourcePaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique

    $linkedIds = @()
    foreach ($field in $linkedFields) {
        $linkedIds += To-Array (Get-PropertyValue -Object $yamlData -Name $field)
    }
    $linkedIds = $linkedIds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique

    $queryPatterns = To-Array (Get-PropertyValue -Object $yamlData -Name 'query_patterns')
    $queryPatterns = $queryPatterns | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $summary = [string](Get-PropertyValue -Object $yamlData -Name 'summary')
    $abstract = [string](Get-PropertyValue -Object $yamlData -Name 'abstract')
    $fallbackDescription = if (-not [string]::IsNullOrWhiteSpace($readmeText)) {
        (($readmeText -split "`r?`n" | Select-Object -Skip 1 -First 8) -join ' ').Trim()
    } else {
        ''
    }
    $primaryDescription = if (-not [string]::IsNullOrWhiteSpace($abstract)) {
        $abstract
    } elseif (-not [string]::IsNullOrWhiteSpace($summary)) {
        $summary
    } else {
        $fallbackDescription
    }

    $structuredText = Join-NonEmpty @(
        ('kind: ' + $kind),
        ('id: ' + [string](Get-PropertyValue -Object $yamlData -Name $idField)),
        ('name: ' + [string](Get-PropertyValue -Object $yamlData -Name 'name')),
        ('description: ' + $primaryDescription),
        ('query_patterns: ' + (($queryPatterns -join ' | '))),
        ('linked_ids: ' + (($linkedIds -join ' | '))),
        ('source_paths: ' + (($sourcePaths -join ' | ')))
    )

    $retrievalText = Join-NonEmpty @(
        $structuredText,
        $readmeText
    )

    return [pscustomobject]@{
        doc_id = [string](Get-PropertyValue -Object $yamlData -Name $idField)
        kind = $kind
        name = [string](Get-PropertyValue -Object $yamlData -Name 'name')
        status = [string](Get-PropertyValue -Object $yamlData -Name 'status')
        priority = [string](Get-PropertyValue -Object $yamlData -Name 'priority')
        doc_paths = @(
            (Get-RelativePathCompat -BasePath $brainRoot -TargetPath $YamlFile.FullName),
            $readmeRelative
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        source_paths = $sourcePaths
        linked_ids = $linkedIds
        query_patterns = $queryPatterns
        structured_text = $structuredText
        narrative_text = $readmeText
        retrieval_text = $retrievalText
    }
}

$yamlFiles = Get-ChildItem -Path @(
    (Join-Path $brainRoot '01_Domains'),
    (Join-Path $brainRoot '02_Flows'),
    (Join-Path $brainRoot '03_Entities'),
    (Join-Path $brainRoot '04_Integrations')
) -Recurse -File | Where-Object { $_.Name -in @('domain.yaml', 'flow.yaml', 'entity.yaml', 'integration.yaml') }

$records = @()
foreach ($yamlFile in $yamlFiles) {
    $records += Get-DocumentRecord -YamlFile $yamlFile
}

$edgeCaseYamlFiles = Get-ChildItem -Path (Join-Path $brainRoot '06_Edge_Cases') -File -Filter '*.yaml' |
    Where-Object { $_.Name -ne 'README.yaml' -and $_.BaseName -ne 'README' }
foreach ($edgeCaseYamlFile in $edgeCaseYamlFiles) {
    $records += Get-EdgeCaseYamlRecord -YamlFile $edgeCaseYamlFile
}

$edgeCaseYamlBaseNames = @($edgeCaseYamlFiles | ForEach-Object { $_.BaseName })
$edgeCaseFiles = Get-ChildItem -Path (Join-Path $brainRoot '06_Edge_Cases') -File -Filter '*.md' |
    Where-Object { $_.Name -ne 'README.md' -and ($edgeCaseYamlBaseNames -notcontains $_.BaseName) }
foreach ($edgeCaseFile in $edgeCaseFiles) {
    $records += Get-EdgeCaseRecord -MarkdownFile $edgeCaseFile
}

$records = $records | Sort-Object kind, doc_id

$resolvedOutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $brainRoot $OutputPath
}

$outputDirectory = Split-Path -Parent $resolvedOutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$jsonLines = foreach ($record in $records) {
    $record | ConvertTo-Json -Depth 6 -Compress
}
Set-Content -LiteralPath $resolvedOutputPath -Value $jsonLines

$summary = @()
$summary += '# Retrieval Corpus Build'
$summary += ''
$summary += ('- generated_at: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'))
$summary += ('- records: {0}' -f (@($records).Count))
$summary += ('- output: {0}' -f $resolvedOutputPath)
$summary += ''
$summary += '## Breakdown'
$summary += ('- flows: {0}' -f ((@($records | Where-Object { $_.kind -eq 'flow' })).Count))
$summary += ('- domains: {0}' -f ((@($records | Where-Object { $_.kind -eq 'domain' })).Count))
$summary += ('- entities: {0}' -f ((@($records | Where-Object { $_.kind -eq 'entity' })).Count))
$summary += ('- integrations: {0}' -f ((@($records | Where-Object { $_.kind -eq 'integration' })).Count))
$summary += ('- edge_cases: {0}' -f ((@($records | Where-Object { $_.kind -eq 'edge_case' })).Count))
$summary += ''
$summary += '## Sample IDs'
$summary += (($records | Select-Object -First 10 | ForEach-Object { '- `' + $_.doc_id + '`' }))

$summary -join [Environment]::NewLine
