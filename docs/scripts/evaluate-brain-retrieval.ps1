param(
    [string]$BrainPath = '',
    [string]$EvaluationSetPath = 'docs/retrieval/evaluation/retrieval-eval-set.jsonl',
    [int]$TopK = 5,
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
$resolvedEvaluationSetPath = if ([System.IO.Path]::IsPathRooted($EvaluationSetPath)) {
    $EvaluationSetPath
} else {
    Join-Path $brainRoot $EvaluationSetPath
}

if (-not (Test-Path -LiteralPath $resolvedEvaluationSetPath -PathType Leaf)) {
    throw "No se encontro el evaluation set: $resolvedEvaluationSetPath"
}

$queryScript = Join-Path $brainRoot 'docs/scripts/query-brain-retrieval.ps1'
if (-not (Test-Path -LiteralPath $queryScript -PathType Leaf)) {
    throw "No se encontro el query script: $queryScript"
}

$cases = @(
    Get-Content -LiteralPath $resolvedEvaluationSetPath |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_ | ConvertFrom-Json }
)

if (@($cases).Count -eq 0) {
    throw 'El evaluation set esta vacio.'
}

$results = @()

foreach ($case in $cases) {
    $expectedDocIds = @($case.expected_doc_ids)
    $queryArgs = @(
        '-ExecutionPolicy', 'Bypass',
        '-File', $queryScript,
        '-Query', [string]$case.query,
        '-TopK', [string]$TopK,
        '-AsJson'
    )

    if ($RebuildCorpus) {
        $queryArgs += '-RebuildCorpus'
    }

    $queryOutput = & powershell @queryArgs
    $queryResult = $queryOutput | ConvertFrom-Json

    $topResults = @($queryResult.results)
    $topDocIds = @($topResults | ForEach-Object { [string]$_.doc_id })
    $top1DocId = if (@($topDocIds).Count -gt 0) { $topDocIds[0] } else { '' }
    $top3DocIds = @($topDocIds | Select-Object -First 3)
    $relevantInTop3 = @($top3DocIds | Where-Object { $expectedDocIds -contains $_ })
    $top1Correct = $expectedDocIds -contains $top1DocId
    $hitAt3 = (@($relevantInTop3).Count -gt 0)
    $precisionAt3 = [Math]::Round((@($relevantInTop3).Count / 3), 4)

    $results += [pscustomobject]@{
        case_id = [string]$case.case_id
        area = [string]$case.area
        query = [string]$case.query
        expected_doc_ids = $expectedDocIds
        top1_doc_id = $top1DocId
        top3_doc_ids = $top3DocIds
        top1_correct = $top1Correct
        hit_at_3 = $hitAt3
        precision_at_3 = $precisionAt3
    }
}

$totalCases = @($results).Count
$top1Accuracy = [Math]::Round(((@($results | Where-Object { $_.top1_correct })).Count / $totalCases), 4)
$hitAt3Rate = [Math]::Round(((@($results | Where-Object { $_.hit_at_3 })).Count / $totalCases), 4)
$meanPrecisionAt3 = [Math]::Round(((@($results | Measure-Object -Property precision_at_3 -Average).Average)), 4)

$areaSummary = @(
    $results |
        Group-Object area |
        ForEach-Object {
            $groupCases = @($_.Group)
            [pscustomobject]@{
                area = $_.Name
                cases = @($groupCases).Count
                top1_accuracy = [Math]::Round(((@($groupCases | Where-Object { $_.top1_correct })).Count / @($groupCases).Count), 4)
                hit_at_3 = [Math]::Round(((@($groupCases | Where-Object { $_.hit_at_3 })).Count / @($groupCases).Count), 4)
                mean_precision_at_3 = [Math]::Round(((@($groupCases | Measure-Object -Property precision_at_3 -Average).Average)), 4)
            }
        } |
        Sort-Object area
)

$payload = [pscustomobject]@{
    generated_at = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
    evaluation_set = $resolvedEvaluationSetPath
    cases = $totalCases
    top_k = $TopK
    metrics = [pscustomobject]@{
        top1_accuracy = $top1Accuracy
        hit_at_3 = $hitAt3Rate
        mean_precision_at_3 = $meanPrecisionAt3
    }
    by_area = $areaSummary
    results = $results
}

if ($AsJson) {
    $payload | ConvertTo-Json -Depth 8
    exit 0
}

$output = @()
$output += '# Retrieval Evaluation'
$output += ''
$output += ('- generated_at: {0}' -f $payload.generated_at)
$output += ('- evaluation_set: {0}' -f $payload.evaluation_set)
$output += ('- cases: {0}' -f $payload.cases)
$output += ('- top_k: {0}' -f $payload.top_k)
$output += ''
$output += '## Global Metrics'
$output += ('- top1_accuracy: {0}' -f $payload.metrics.top1_accuracy)
$output += ('- hit_at_3: {0}' -f $payload.metrics.hit_at_3)
$output += ('- mean_precision_at_3: {0}' -f $payload.metrics.mean_precision_at_3)
$output += ''
$output += '## By Area'

foreach ($area in $payload.by_area) {
    $output += ('- {0}: cases={1}, top1={2}, hit@3={3}, p@3={4}' -f $area.area, $area.cases, $area.top1_accuracy, $area.hit_at_3, $area.mean_precision_at_3)
}

$failures = @($payload.results | Where-Object { -not $_.top1_correct })
if (@($failures).Count -gt 0) {
    $output += ''
    $output += '## Top1 Failures'
    foreach ($failure in $failures) {
        $output += ('- [{0}] {1}' -f $failure.area, $failure.query)
        $output += ('  expected: {0}' -f (($failure.expected_doc_ids -join ', ')))
        $output += ('  got_top1: {0}' -f $failure.top1_doc_id)
        $output += ('  top3: {0}' -f (($failure.top3_doc_ids -join ', ')))
    }
}

$output -join [Environment]::NewLine
