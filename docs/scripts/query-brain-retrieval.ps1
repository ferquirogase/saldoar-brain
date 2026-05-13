param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [int]$TopK = 5,
    [string]$BrainPath = '',
    [string]$CorpusPath = 'docs/retrieval/brain-retrieval-corpus.jsonl',
    [switch]$RebuildCorpus,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}

$resolvedBrainPath = if ([string]::IsNullOrWhiteSpace($BrainPath)) {
    Split-Path -Parent (Split-Path -Parent $scriptRoot)
} else {
    $BrainPath
}

$brainRoot = [System.IO.Path]::GetFullPath($resolvedBrainPath)
$resolvedCorpusPath = if ([System.IO.Path]::IsPathRooted($CorpusPath)) {
    $CorpusPath
} else {
    Join-Path $brainRoot $CorpusPath
}

$stopwords = @(
    'a', 'al', 'algo', 'como', 'con', 'cual', 'cuando', 'de', 'del', 'donde',
    'el', 'en', 'es', 'esta', 'este', 'esto', 'hay', 'la', 'las', 'lo', 'los',
    'mas', 'me', 'mi', 'mis', 'no', 'o', 'para', 'pero', 'por', 'porque', 'que',
    'se', 'si', 'sin', 'su', 'sus', 'te', 'tengo', 'tu', 'un', 'una', 'uno', 'y',
    'ya'
)

function Normalize-Text {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $normalized = $Text.Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder

    foreach ($char in $normalized.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)
        if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($char)
        }
    }

    return $builder.ToString().ToLowerInvariant()
}

function Get-Tokens {
    param([string]$Text)

    $normalized = Normalize-Text $Text
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    return @(
        $normalized -split '[^a-z0-9]+' |
            Where-Object { $_.Length -ge 2 -and $stopwords -notcontains $_ } |
            Select-Object -Unique
    )
}

function Get-OrderedQueryTokens {
    param([string]$Text)

    $normalized = Normalize-Text $Text
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    return @(
        $normalized -split '[^a-z0-9]+' |
            Where-Object { $_.Length -ge 2 -and $stopwords -notcontains $_ }
    )
}

function Get-NGrams {
    param(
        [string[]]$Tokens,
        [int]$Size
    )

    if ($Size -le 1 -or @($Tokens).Count -lt $Size) {
        return @()
    }

    $grams = @()
    for ($i = 0; $i -le (@($Tokens).Count - $Size); $i++) {
        $grams += (($Tokens[$i..($i + $Size - 1)]) -join ' ')
    }

    return @($grams | Select-Object -Unique)
}

function Get-RelativePathCompat {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseUri = New-Object System.Uri(([System.IO.Path]::GetFullPath($BasePath)).Replace('\', '/').TrimEnd('/') + '/')
    $targetUri = New-Object System.Uri(([System.IO.Path]::GetFullPath($TargetPath)).Replace('\', '/'))
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('\', '/')
}

function Import-Corpus {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return @()
    }

    $lines = Get-Content -LiteralPath $Path | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $records = @()
    foreach ($line in $lines) {
        $records += ($line | ConvertFrom-Json)
    }
    return $records
}

function Import-SynonymMap {
    param([string]$BrainRoot)

    $synonymsPath = Join-Path $BrainRoot '00_Index/synonyms.md'
    if (-not (Test-Path -LiteralPath $synonymsPath -PathType Leaf)) {
        return @()
    }

    $entries = @()
    $lines = Get-Content -LiteralPath $synonymsPath

    foreach ($line in $lines) {
        if ($line -notmatch '^\|') {
            continue
        }
        if ($line -match '^\|---') {
            continue
        }

        $columns = @(
            ($line.Trim('|') -split '\|') |
                ForEach-Object { $_.Trim() }
        )

        if ($columns.Count -lt 3) {
            continue
        }

        if ((Normalize-Text $columns[0]) -eq 'lo que dice el usuario / soporte') {
            continue
        }

        $flows = @(
            $columns[2] -split ',' |
                ForEach-Object {
                    $value = $_.Trim()
                    if ($value -like 'flow-*') {
                        $value.Substring(5)
                    } else {
                        $value
                    }
                } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )

        $entries += [pscustomobject]@{
            user_phrase = $columns[0]
            internal_term = $columns[1]
            flows = $flows
        }
    }

    return $entries
}

function Get-SynonymMatches {
    param(
        [string]$Query,
        [object[]]$Entries
    )

    $normalizedQuery = Normalize-Text $Query
    $matches = @()

    foreach ($entry in $Entries) {
        $userPhrase = Normalize-Text $entry.user_phrase
        $internalTerm = Normalize-Text $entry.internal_term
        $userTokens = Get-Tokens $entry.user_phrase
        $internalTokens = Get-Tokens $entry.internal_term
        $queryTokens = Get-Tokens $Query
        $userOverlap = (@($queryTokens | Where-Object { $userTokens -contains $_ })).Count
        $internalOverlap = (@($queryTokens | Where-Object { $internalTokens -contains $_ })).Count
        $userThreshold = switch ((@($userTokens)).Count) {
            0 { 99 }
            1 { 1 }
            2 { 2 }
            default { 2 }
        }
        $internalThreshold = switch ((@($internalTokens)).Count) {
            0 { 99 }
            1 { 1 }
            2 { 2 }
            default { 2 }
        }
        $tokenMatch = (
            $userOverlap -ge $userThreshold -or
            $internalOverlap -ge $internalThreshold
        )

        if (
            (-not [string]::IsNullOrWhiteSpace($userPhrase) -and $normalizedQuery.Contains($userPhrase)) -or
            (-not [string]::IsNullOrWhiteSpace($internalTerm) -and $normalizedQuery.Contains($internalTerm)) -or
            $tokenMatch
        ) {
            $matches += $entry
        }
    }

    return $matches
}

function Add-Reason {
    param(
        [System.Collections.Generic.List[string]]$Reasons,
        [string]$Reason
    )

    if (-not $Reasons.Contains($Reason)) {
        $Reasons.Add($Reason)
    }
}

function Get-KindBoost {
    param([string]$Kind)

    switch ($Kind) {
        'flow' { return 3.0 }
        'edge_case' { return 2.5 }
        'integration' { return 2.0 }
        'domain' { return 1.0 }
        'entity' { return 1.0 }
        default { return 0.0 }
    }
}

function Resolve-SecondaryContext {
    param(
        [object]$PrimaryRecord,
        [object[]]$CorpusRecords,
        [string[]]$ExpandedTokens
    )

    $linkedIds = @($PrimaryRecord.linked_ids | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if (@($linkedIds).Count -eq 0) {
        return @()
    }

    $related = @()
    foreach ($linkedId in $linkedIds) {
        $normalizedLinkedId = Normalize-Text ([string]$linkedId)
        if ([string]::IsNullOrWhiteSpace($normalizedLinkedId)) {
            continue
        }

        $match = $CorpusRecords | Where-Object { (Normalize-Text ([string]$_.doc_id)) -eq $normalizedLinkedId } | Select-Object -First 1
        if ($null -eq $match) {
            continue
        }

        $relatedTokens = Get-Tokens ([string]$match.retrieval_text)
        $tokenMatches = @($ExpandedTokens | Where-Object { $relatedTokens -contains $_ } | Select-Object -Unique)
        $score = ((@($tokenMatches)).Count * 3) + (Get-KindBoost -Kind ([string]$match.kind))

        $related += [pscustomobject]@{
            doc_id = [string]$match.doc_id
            kind = [string]$match.kind
            name = [string]$match.name
            score = [Math]::Round($score, 2)
            token_matches = $tokenMatches
            doc_paths = @($match.doc_paths)
        }
    }

    return @(
        $related |
            Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = 'doc_id'; Descending = $false } |
            Select-Object -First 2
    )
}

function Get-RerankBonus {
    param(
        [object]$Record,
        [string[]]$OrderedQueryTokens,
        [string[]]$ExpandedTokens,
        [object[]]$SynonymMatches
    )

    $bonus = 0.0
    $reasons = New-Object 'System.Collections.Generic.List[string]'
    $normalizedNarrative = Normalize-Text ([string]$Record.narrative_text)
    $normalizedStructured = Normalize-Text ([string]$Record.structured_text)
    $joinedText = (($normalizedStructured + "`n" + $normalizedNarrative).Trim())

    $bigrams = Get-NGrams -Tokens $OrderedQueryTokens -Size 2
    $trigrams = Get-NGrams -Tokens $OrderedQueryTokens -Size 3

    $matchedBigrams = @($bigrams | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $joinedText.Contains($_) } | Select-Object -Unique)
    if (@($matchedBigrams).Count -gt 0) {
        $bonus += (@($matchedBigrams).Count * 4)
        Add-Reason -Reasons $reasons -Reason ('rerank bigrams: ' + (@($matchedBigrams) -join ', '))
    }

    $matchedTrigrams = @($trigrams | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $joinedText.Contains($_) } | Select-Object -Unique)
    if (@($matchedTrigrams).Count -gt 0) {
        $bonus += (@($matchedTrigrams).Count * 7)
        Add-Reason -Reasons $reasons -Reason ('rerank trigrams: ' + (@($matchedTrigrams) -join ', '))
    }

    if ((Normalize-Text ([string]$Record.doc_id)) -eq 'flow-chat-state-chips-and-support-actions' -and $ExpandedTokens -contains 'tarea' -and $ExpandedTokens -contains 'mensaje') {
        $bonus += 6
        Add-Reason -Reasons $reasons -Reason 'rerank mensaje+tarea'
    }

    if ((Normalize-Text ([string]$Record.doc_id)) -eq 'flow-system-selection-and-quote-calculator' -and $ExpandedTokens -contains 'guardar' -and $ExpandedTokens -contains 'expira') {
        $bonus += 6
        Add-Reason -Reasons $reasons -Reason 'rerank expira+guardar'
    }

    $synonymItems = @($SynonymMatches | ForEach-Object { $_ })
    if (@($synonymItems).Length -gt 0) {
        $internalTerms = @(
            $synonymItems |
                ForEach-Object {
                    if ($null -eq $_ -or $_ -is [string]) {
                        return
                    }
                    $property = $_.PSObject.Properties['internal_term']
                    if ($null -ne $property) {
                        Normalize-Text ([string]$property.Value)
                    }
                } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )
        $matchedInternalTerms = @($internalTerms | Where-Object { $joinedText.Contains($_) } | Select-Object -Unique)
        if (@($matchedInternalTerms).Count -gt 0) {
            $bonus += (@($matchedInternalTerms).Count * 5)
            Add-Reason -Reasons $reasons -Reason ('rerank termino interno: ' + (@($matchedInternalTerms) -join ', '))
        }
    }

    return [pscustomobject]@{
        bonus = [Math]::Round($bonus, 2)
        reasons = @($reasons)
    }
}

if ($RebuildCorpus -or -not (Test-Path -LiteralPath $resolvedCorpusPath -PathType Leaf)) {
    $buildScript = Join-Path $brainRoot 'docs/scripts/build-retrieval-corpus.ps1'
    & powershell -ExecutionPolicy Bypass -File $buildScript -BrainPath $brainRoot -OutputPath (Get-RelativePathCompat -BasePath $brainRoot -TargetPath $resolvedCorpusPath) | Out-Null
}

$records = Import-Corpus -Path $resolvedCorpusPath
if (@($records).Count -eq 0) {
    throw 'No se encontraron records en el corpus de retrieval.'
}

$synonymEntries = Import-SynonymMap -BrainRoot $brainRoot
$synonymMatches = Get-SynonymMatches -Query $Query -Entries $synonymEntries

$queryTokens = Get-Tokens $Query
$orderedQueryTokens = Get-OrderedQueryTokens $Query
$expandedTokens = New-Object System.Collections.Generic.List[string]
foreach ($token in $queryTokens) {
    [void]$expandedTokens.Add($token)
}

$preferredFlowIds = New-Object System.Collections.Generic.List[string]
foreach ($match in $synonymMatches) {
    foreach ($token in (Get-Tokens $match.internal_term)) {
        if (-not $expandedTokens.Contains($token)) {
            [void]$expandedTokens.Add($token)
        }
    }
    foreach ($flowId in $match.flows) {
        if (-not $preferredFlowIds.Contains($flowId)) {
            [void]$preferredFlowIds.Add($flowId)
        }
    }
}

$normalizedQuery = Normalize-Text $Query
$scored = @()

foreach ($record in $records) {
    $score = 0.0
    $reasons = New-Object 'System.Collections.Generic.List[string]'

    $docId = [string]$record.doc_id
    $docName = [string]$record.name
    $kind = [string]$record.kind
    $retrievalText = [string]$record.retrieval_text
    $queryPatterns = @($record.query_patterns)

    $normalizedDocId = Normalize-Text $docId
    $normalizedDocName = Normalize-Text $docName
    $normalizedRetrievalText = Normalize-Text $retrievalText
    $docIdentityTokens = @((Get-Tokens $docId) + (Get-Tokens $docName) | Select-Object -Unique)

    if (-not [string]::IsNullOrWhiteSpace($normalizedDocId) -and $normalizedQuery.Contains($normalizedDocId)) {
        $score += 35
        Add-Reason -Reasons $reasons -Reason 'match directo con doc_id'
    }

    if (-not [string]::IsNullOrWhiteSpace($normalizedDocName) -and $normalizedQuery.Contains($normalizedDocName)) {
        $score += 25
        Add-Reason -Reasons $reasons -Reason 'match directo con nombre'
    }

    $identityMatches = @($expandedTokens | Where-Object { $docIdentityTokens -contains $_ } | Select-Object -Unique)
    if ((@($identityMatches)).Count -gt 0) {
        $score += ((@($identityMatches)).Count * 12)
        Add-Reason -Reasons $reasons -Reason ('tokens clave del documento: ' + ($identityMatches -join ', '))
    }

    foreach ($pattern in $queryPatterns) {
        $normalizedPattern = Normalize-Text ([string]$pattern)
        if ([string]::IsNullOrWhiteSpace($normalizedPattern)) {
            continue
        }

        if ($normalizedQuery.Contains($normalizedPattern) -or $normalizedPattern.Contains($normalizedQuery)) {
            $score += 18
            Add-Reason -Reasons $reasons -Reason ('query_pattern: ' + [string]$pattern)
        } else {
            $patternTokens = Get-Tokens ([string]$pattern)
            $patternOverlap = (@($expandedTokens | Where-Object { $patternTokens -contains $_ })).Count
            $patternTokenCount = (@($patternTokens)).Count
            $patternRatio = if ($patternTokenCount -gt 0) {
                $patternOverlap / $patternTokenCount
            } else {
                0
            }
            if ($patternOverlap -ge 2 -or $patternRatio -ge 0.5) {
                $score += [Math]::Round(($patternOverlap * 6) + ($patternRatio * 4), 2)
                Add-Reason -Reasons $reasons -Reason ('solapamiento con query_pattern: ' + [string]$pattern)
            }
        }
    }

    $recordTokens = Get-Tokens $retrievalText
    $tokenMatches = @($expandedTokens | Where-Object { $recordTokens -contains $_ } | Select-Object -Unique)
    if ((@($tokenMatches)).Count -gt 0) {
        $score += ((@($tokenMatches)).Count * 3)
        Add-Reason -Reasons $reasons -Reason ('tokens compartidos: ' + ($tokenMatches -join ', '))
    }

    if (-not [string]::IsNullOrWhiteSpace($normalizedRetrievalText) -and $normalizedRetrievalText.Contains($normalizedQuery)) {
        $score += 12
        Add-Reason -Reasons $reasons -Reason 'frase completa dentro del retrieval_text'
    }

    if ($preferredFlowIds.Contains($docId)) {
        $score += 20
        Add-Reason -Reasons $reasons -Reason 'boost por sinonimos y flow relevante'
    }

    if ((@($synonymMatches)).Count -gt 0) {
        $matchedTerms = @($synonymMatches | ForEach-Object { [string]$_.internal_term } | Select-Object -Unique)
        $docJoined = @($docId, $docName, $retrievalText) -join ' '
        $normalizedJoined = Normalize-Text $docJoined
        foreach ($term in $matchedTerms) {
            $normalizedTerm = Normalize-Text $term
            if (-not [string]::IsNullOrWhiteSpace($normalizedTerm) -and $normalizedJoined.Contains($normalizedTerm)) {
                $score += 8
                Add-Reason -Reasons $reasons -Reason ('termino interno expandido: ' + $term)
            }
        }
    }

    $score += (Get-KindBoost -Kind $kind)

    if ($score -le 0) {
        continue
    }

    $scored += [pscustomobject]@{
        doc_id = $docId
        kind = $kind
        name = $docName
        score = [Math]::Round($score, 2)
        reasons = @($reasons)
        doc_paths = @($record.doc_paths)
        source_paths = @($record.source_paths)
        linked_ids = @($record.linked_ids)
    }
}

$initialResults = @(
    $scored |
        Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = 'kind'; Descending = $false }, @{ Expression = 'doc_id'; Descending = $false } |
        Select-Object -First $TopK
)

$recordMap = @{}
foreach ($record in $records) {
    $recordMap[[string]$record.doc_id] = $record
}

$rerankedResults = @()
foreach ($result in $initialResults) {
    $primaryRecord = $recordMap[[string]$result.doc_id]
    $rerank = [pscustomobject]@{ bonus = 0.0; reasons = @() }
    if ($null -ne $primaryRecord) {
        $rerank = Get-RerankBonus -Record $primaryRecord -OrderedQueryTokens $orderedQueryTokens -ExpandedTokens @($expandedTokens) -SynonymMatches $synonymMatches
    }

    $rerankedResults += [pscustomobject]@{
        doc_id = $result.doc_id
        kind = $result.kind
        name = $result.name
        score = $result.score
        rerank_bonus = $rerank.bonus
        rerank_score = [Math]::Round(($result.score + $rerank.bonus), 2)
        reasons = @($result.reasons)
        rerank_reasons = @($rerank.reasons)
        doc_paths = @($result.doc_paths)
        source_paths = @($result.source_paths)
        linked_ids = @($result.linked_ids)
    }
}

$sortedResults = @(
    $rerankedResults |
        Sort-Object @{ Expression = 'rerank_score'; Descending = $true }, @{ Expression = 'score'; Descending = $true }, @{ Expression = 'kind'; Descending = $false }, @{ Expression = 'doc_id'; Descending = $false }
)

$results = @()
foreach ($result in $sortedResults) {
    $primaryRecord = $recordMap[[string]$result.doc_id]
    $secondaryContext = @()
    if ($null -ne $primaryRecord) {
        $secondaryContext = Resolve-SecondaryContext -PrimaryRecord $primaryRecord -CorpusRecords $records -ExpandedTokens @($expandedTokens)
    }

    $results += [pscustomobject]@{
        doc_id = $result.doc_id
        kind = $result.kind
        name = $result.name
        score = $result.score
        rerank_bonus = $result.rerank_bonus
        rerank_score = $result.rerank_score
        reasons = @($result.reasons)
        rerank_reasons = @($result.rerank_reasons)
        doc_paths = @($result.doc_paths)
        source_paths = @($result.source_paths)
        linked_ids = @($result.linked_ids)
        secondary_context = $secondaryContext
    }
}

if ($AsJson) {
    [pscustomobject]@{
        query = $Query
        expanded_tokens = @($expandedTokens)
        synonym_matches = @(
            $synonymMatches | ForEach-Object {
                [pscustomobject]@{
                    user_phrase = $_.user_phrase
                    internal_term = $_.internal_term
                    flows = $_.flows
                }
            }
        )
        results = $results
    } | ConvertTo-Json -Depth 8
    exit 0
}

$output = @()
$output += '# Retrieval Query'
$output += ''
$output += ('- query: {0}' -f $Query)
$output += ('- top_k: {0}' -f $TopK)
$output += ('- expanded_tokens: {0}' -f ((@($expandedTokens) -join ', ')))

if ((@($synonymMatches)).Count -gt 0) {
    $output += ('- synonym_matches: {0}' -f ((@($synonymMatches | ForEach-Object { $_.internal_term }) | Select-Object -Unique) -join ' | '))
}

$output += ''
$output += '## Results'

if ((@($results)).Count -eq 0) {
    $output += '- No hubo candidatos con score positivo.'
} else {
    $rank = 1
    foreach ($result in $results) {
        $output += ('{0}. [{1}] `{2}` - {3} (score {4}; rerank {5})' -f $rank, $result.kind, $result.doc_id, $result.name, $result.score, $result.rerank_score)
        if (@($result.reasons).Count -gt 0) {
            $output += ('   razones: ' + (@($result.reasons) -join ' | '))
        }
        if (@($result.rerank_reasons).Count -gt 0) {
            $output += ('   rerank: ' + (@($result.rerank_reasons) -join ' | '))
        }
        if (@($result.doc_paths).Count -gt 0) {
            $output += ('   docs: ' + (@($result.doc_paths) -join ' | '))
        }
        if (@($result.source_paths).Count -gt 0) {
            $output += ('   sources: ' + ((@($result.source_paths) | Select-Object -First 5) -join ' | '))
        }
        if (@($result.secondary_context).Count -gt 0) {
            $output += ('   contexto_secundario: ' + (
                @($result.secondary_context | ForEach-Object {
                    $label = '[{0}] {1}' -f $_.kind, $_.doc_id
                    if (@($_.token_matches).Count -gt 0) {
                        $label += ' (' + ((@($_.token_matches) -join ', ')) + ')'
                    }
                    $label
                }) -join ' | '
            ))
        }
        $rank++
    }
}

$output -join [Environment]::NewLine
