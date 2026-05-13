param(
    [string]$BrainPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$BackendRepoPath,
    [string]$FrontendRepoPath,
    [ValidateSet('working_tree', 'head_range')]
    [string]$Mode = 'working_tree',
    [string]$CommitRange = 'HEAD~1..HEAD',
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$brainRoot = [System.IO.Path]::GetFullPath($BrainPath)
$workspaceRoot = Split-Path -Parent $brainRoot

if ([string]::IsNullOrWhiteSpace($BackendRepoPath)) {
    $BackendRepoPath = Join-Path $workspaceRoot 'saldo'
}
if ([string]::IsNullOrWhiteSpace($FrontendRepoPath)) {
    $FrontendRepoPath = Join-Path $workspaceRoot 'solido'
}

$BackendRepoPath = [System.IO.Path]::GetFullPath($BackendRepoPath)
$FrontendRepoPath = [System.IO.Path]::GetFullPath($FrontendRepoPath)

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

function Workspace-AbsolutePath {
    param([string]$RelativePath)

    $normalizedRelative = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    return Normalize-PathString (Join-Path $workspaceRoot $normalizedRelative)
}

function Brain-AbsolutePath {
    param([string]$RelativePath)

    $normalizedRelative = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    return Normalize-PathString (Join-Path $brainRoot $normalizedRelative)
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

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line -match '^(?<key>[A-Za-z0-9_]+):\s*(?<value>.*)$') {
            $currentKey = $Matches.key
            $rawValue = $Matches.value.Trim()

            if ($rawValue -eq '' -or $rawValue -eq '|' -or $rawValue -eq '>') {
                if (-not $result.ContainsKey($currentKey)) {
                    $result[$currentKey] = @()
                }
                continue
            }

            $scalarValue = $rawValue.Trim("'`"")
            $result[$currentKey] = $scalarValue
            continue
        }

        if ($line -match '^\s*-\s*(?<item>.+)$' -and $null -ne $currentKey) {
            if (-not ($result[$currentKey] -is [System.Collections.IList])) {
                $result[$currentKey] = @()
            }
            $result[$currentKey] += $Matches.item.Trim().Trim("'`"")
        }
    }

    return [pscustomobject]$result
}

function Get-TrackedSourceRefs {
    param(
        [string]$YamlPath,
        [object]$YamlData,
        [string[]]$FieldNames
    )

    $refs = @()
    foreach ($fieldName in $FieldNames) {
        foreach ($rawValue in (To-Array (Get-PropertyValue -Object $YamlData -Name $fieldName))) {
            if ([string]::IsNullOrWhiteSpace([string]$rawValue)) {
                continue
            }

            $absolutePath = Workspace-AbsolutePath ([string]$rawValue)
            $pathType = 'missing'
            if (Test-Path -LiteralPath $absolutePath -PathType Container) {
                $pathType = 'directory'
            } elseif (Test-Path -LiteralPath $absolutePath -PathType Leaf) {
                $pathType = 'file'
            }

            $refs += [pscustomobject]@{
                field = $fieldName
                relative_path = [string]$rawValue
                absolute_path = $absolutePath
                path_type = $pathType
            }
        }
    }

    return $refs
}

function Get-DocRecordFromYaml {
    param([System.IO.FileInfo]$YamlFile)

    $yamlData = ConvertFrom-BrainYaml (Get-Content -LiteralPath $YamlFile.FullName -Raw)
    $docDir = Split-Path -Parent $YamlFile.FullName
    $docDirRelative = Get-RelativePathCompat -BasePath $brainRoot -TargetPath $docDir

    $kind = switch ($YamlFile.Name) {
        'flow.yaml' { 'flow' }
        'entity.yaml' { 'entity' }
        'domain.yaml' { 'domain' }
        'integration.yaml' { 'integration' }
        default { 'unknown' }
    }

    $idField = switch ($kind) {
        'flow' { 'flow_id' }
        'entity' { 'entity_id' }
        'domain' { 'domain_id' }
        'integration' { 'integration_id' }
        default { 'id' }
    }

    $sourceFields = switch ($kind) {
        'flow' { @('frontend_sources', 'backend_sources', 'references', 'source_of_truth') }
        'entity' { @('backend_model', 'frontend_surface', 'source_of_truth') }
        'domain' { @('backend_surface', 'frontend_surface', 'source_of_truth') }
        'integration' { @('backend_surface', 'frontend_surface', 'references', 'source_of_truth') }
        default { @('source_of_truth') }
    }

    $docFiles = @()
    foreach ($candidate in @('README.md', $YamlFile.Name)) {
            $candidatePath = Join-Path $docDir $candidate
            if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
            $docFiles += Get-RelativePathCompat -BasePath $brainRoot -TargetPath $candidatePath
            }
        }

    return [pscustomobject]@{
        doc_id = [string](Get-PropertyValue -Object $yamlData -Name $idField)
        name = [string](Get-PropertyValue -Object $yamlData -Name 'name')
        kind = $kind
        doc_dir = $docDirRelative
        docs = $docFiles
        source_refs = Get-TrackedSourceRefs -YamlPath $YamlFile.FullName -YamlData $yamlData -FieldNames $sourceFields
        review = Get-PropertyValue -Object $yamlData -Name 'review'
    }
}

function Get-ManualDocRecords {
    param([string]$ManualLinksPath)

    if (-not (Test-Path -LiteralPath $ManualLinksPath -PathType Leaf)) {
        return @()
    }

    $manualConfig = Get-Content -LiteralPath $ManualLinksPath -Raw | ConvertFrom-Json
    $records = @()

    foreach ($manualDoc in $manualConfig.manual_docs) {
        $docs = @()
        foreach ($docPath in $manualDoc.docs) {
            $docs += [string]$docPath
        }

        $sourceRefs = @()
        foreach ($sourcePath in $manualDoc.source_paths) {
            $absolutePath = Workspace-AbsolutePath ([string]$sourcePath)
            $pathType = 'missing'
            if (Test-Path -LiteralPath $absolutePath -PathType Container) {
                $pathType = 'directory'
            } elseif (Test-Path -LiteralPath $absolutePath -PathType Leaf) {
                $pathType = 'file'
            }

            $sourceRefs += [pscustomobject]@{
                field = 'manual'
                relative_path = [string]$sourcePath
                absolute_path = $absolutePath
                path_type = $pathType
            }
        }

        $records += [pscustomobject]@{
            doc_id = [string]$manualDoc.doc_id
            name = [string]$manualDoc.doc_id
            kind = [string]$manualDoc.kind
            doc_dir = ''
            docs = $docs
            source_refs = $sourceRefs
            review = $null
        }
    }

    return $records
}

function Get-ChangedFilesForRepo {
    param(
        [string]$RepoPath,
        [string]$RepoLabel
    )

    if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
        return @()
    }

    $lines = @()
    if ($Mode -eq 'working_tree') {
        $lines = @(git -c "safe.directory=$RepoPath" -C $RepoPath status --porcelain=v1 2>$null)
        $paths = foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }
            if ($line.Length -lt 4) {
                continue
            }
            $rawPath = $line.Substring(3)
            if ($rawPath -match ' -> ') {
                $rawPath = ($rawPath -split ' -> ')[-1]
            }
            $rawPath
        }
    } else {
        $lines = @(git -c "safe.directory=$RepoPath" -C $RepoPath diff --name-only $CommitRange 2>$null)
        $paths = $lines
    }

    $records = @()
    foreach ($relativeRepoPath in $paths | Sort-Object -Unique) {
        if ([string]::IsNullOrWhiteSpace($relativeRepoPath)) {
            continue
        }

        $relativeToWorkspace = ($RepoLabel + '/' + $relativeRepoPath.Replace('\', '/')).Replace('//', '/')
        $absolutePath = Normalize-PathString (Join-Path $workspaceRoot $relativeToWorkspace)

        $records += [pscustomobject]@{
            repo = $RepoLabel
            relative_path = $relativeToWorkspace
            absolute_path = $absolutePath
        }
    }

    return $records
}

function Get-ImpactForChangedFile {
    param(
        [pscustomobject]$ChangedFile,
        [object[]]$DocRecords
    )

    $impacts = @()
    foreach ($doc in $DocRecords) {
        $matchedRefs = @()
        foreach ($sourceRef in $doc.source_refs) {
            if ($sourceRef.path_type -eq 'file' -and $ChangedFile.absolute_path -eq $sourceRef.absolute_path) {
                $matchedRefs += [pscustomobject]@{
                    match_type = 'exact_file'
                    source_ref = $sourceRef
                }
            } elseif ($sourceRef.path_type -eq 'directory' -and $ChangedFile.absolute_path.StartsWith($sourceRef.absolute_path.TrimEnd('/') + '/')) {
                $matchedRefs += [pscustomobject]@{
                    match_type = 'within_directory'
                    source_ref = $sourceRef
                }
            }
        }

        if ($matchedRefs.Count -gt 0) {
            $impacts += [pscustomobject]@{
                doc = $doc
                matches = $matchedRefs
            }
        }
    }

    return $impacts
}

$yamlFiles = Get-ChildItem -Path @(
    (Join-Path $brainRoot '01_Domains'),
    (Join-Path $brainRoot '02_Flows'),
    (Join-Path $brainRoot '03_Entities'),
    (Join-Path $brainRoot '04_Integrations')
) -Recurse -File | Where-Object { $_.Name -in @('domain.yaml', 'flow.yaml', 'entity.yaml', 'integration.yaml') }

$docRecords = @()
foreach ($yamlFile in $yamlFiles) {
    $docRecords += Get-DocRecordFromYaml -YamlFile $yamlFile
}

$manualLinksPath = Join-Path $brainRoot 'docs/traceability/manual-links.json'
$docRecords += Get-ManualDocRecords -ManualLinksPath $manualLinksPath

$changedFiles = @()
$changedFiles += Get-ChangedFilesForRepo -RepoPath $BackendRepoPath -RepoLabel 'saldo'
$changedFiles += Get-ChangedFilesForRepo -RepoPath $FrontendRepoPath -RepoLabel 'solido'
$changedFiles = $changedFiles | Sort-Object relative_path -Unique

$impactRows = @()
foreach ($changedFile in $changedFiles) {
    $impactRows += [pscustomobject]@{
        changed_file = $changedFile
        impacted_docs = Get-ImpactForChangedFile -ChangedFile $changedFile -DocRecords $docRecords
    }
}

$allImpactedDocs = @()
foreach ($impactRow in $impactRows) {
    foreach ($impactDoc in $impactRow.impacted_docs) {
        $allImpactedDocs += $impactDoc.doc
    }
}
$allImpactedDocs = $allImpactedDocs | Sort-Object doc_id -Unique
$docsWithoutTraceability = @()
foreach ($docRecord in $docRecords) {
    $docRecordSourceRefs = To-Array (Get-PropertyValue -Object $docRecord -Name 'source_refs')
    if (@($docRecordSourceRefs).Count -eq 0) {
        $docsWithoutTraceability += $docRecord
    }
}
$docsWithoutTraceability = $docsWithoutTraceability | Sort-Object kind, doc_id

$reportLines = @()
$reportLines += '# Brain Impact Report'
$reportLines += ''
$reportLines += "- generated_at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
$reportLines += "- mode: $Mode"
if ($Mode -eq 'head_range') {
    $reportLines += "- commit_range: $CommitRange"
}
$reportLines += "- backend_repo: $BackendRepoPath"
$reportLines += "- frontend_repo: $FrontendRepoPath"
$reportLines += "- changed_files: $($changedFiles.Count)"
$reportLines += "- impacted_docs: $(@($allImpactedDocs).Count)"
$reportLines += ''

$reportLines += '## Changed Files'
if ($changedFiles.Count -eq 0) {
    $reportLines += ''
    $reportLines += 'No se detectaron cambios en `saldo` o `solido` para el modo elegido.'
} else {
    foreach ($row in $impactRows) {
        $reportLines += ''
        $reportLines += ('- `{0}`' -f $row.changed_file.relative_path)
        if ((@($row.impacted_docs)).Count -eq 0) {
            $reportLines += '  - impacto: sin docs vinculadas'
            continue
        }

        foreach ($impact in $row.impacted_docs) {
            $matchTypes = ($impact.matches.match_type | Sort-Object -Unique) -join ', '
            $docFiles = ($impact.doc.docs | ForEach-Object { '`' + $_ + '`' }) -join ', '
            $reportLines += ('  - doc: `{0}` ({1}) [{2}]' -f $impact.doc.doc_id, $docFiles, $matchTypes)
        }
    }
}

$reportLines += ''
$reportLines += '## Impacted Docs'
if ((@($allImpactedDocs)).Count -eq 0) {
    $reportLines += ''
    $reportLines += 'No hay documentos impactados con la trazabilidad actual.'
} else {
    foreach ($doc in $allImpactedDocs) {
        $docImpactRows = @()
        foreach ($impactRow in $impactRows) {
            $impactRowDocIds = @()
            foreach ($impactedDoc in (To-Array (Get-PropertyValue -Object $impactRow -Name 'impacted_docs'))) {
                $impactRowDocIds += $impactedDoc.doc.doc_id
            }
            if (($impactRowDocIds | Select-Object -Unique) -contains $doc.doc_id) {
                $docImpactRows += $impactRow
            }
        }
        $reportLines += ''
        $reportLines += ('- `{0}`' -f $doc.doc_id)
        $reportLines += ('  - kind: `{0}`' -f $doc.kind)
        $docDocs = To-Array (Get-PropertyValue -Object $doc -Name 'docs')
        if ($docDocs.Count -gt 0) {
            $docList = ($docDocs | ForEach-Object { '`' + $_ + '`' }) -join ', '
            $reportLines += ('  - docs: {0}' -f $docList)
        }
        $docSourceRefs = To-Array (Get-PropertyValue -Object $doc -Name 'source_refs')
        if ($docSourceRefs.Count -gt 0) {
            $sourceList = ($docSourceRefs.relative_path | ForEach-Object { '`' + $_ + '`' }) -join ', '
            $reportLines += ('  - tracked_sources: {0}' -f $sourceList)
        }
        $changedList = $docImpactRows.changed_file.relative_path | Sort-Object -Unique | ForEach-Object { '`' + $_ + '`' }
        $reportLines += ('  - changed_files: {0}' -f ($changedList -join ', '))
    }
}

$reportLines += ''
$reportLines += '## Docs Without Traceability'
if (@($docsWithoutTraceability).Count -eq 0) {
    $reportLines += ''
    $reportLines += 'Todas las docs detectadas tienen al menos una referencia tecnica.'
} else {
    foreach ($doc in $docsWithoutTraceability) {
        $reportLines += ('- `{0}` (`{1}`)' -f $doc.doc_id, $doc.kind)
    }
}

$report = $reportLines -join [Environment]::NewLine

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $resolvedOutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath
    } else {
        Join-Path $brainRoot $OutputPath
    }
    $outputDirectory = Split-Path -Parent $resolvedOutputPath
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }
    Set-Content -LiteralPath $resolvedOutputPath -Value $report
}

$report
