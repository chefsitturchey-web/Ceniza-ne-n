param(
    [string]$GodotPath = $env:GODOT_BIN,
    [ValidatePattern('^[a-zA-Z0-9_]+$')][string]$Suite = 'run_all',
    [switch]$ImportOnly,
    [switch]$Capture
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if (-not $GodotPath) {
    foreach ($name in @('godot', 'godot4', 'godot_console')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { $GodotPath = $command.Source; break }
    }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw 'Indica -GodotPath con el ejecutable de consola, o configura GODOT_BIN.'
}
$GodotPath = (Resolve-Path -LiteralPath $GodotPath).Path
$outputRoot = Join-Path $projectRoot 'build/validation/latest'
$profileRoot = Join-Path $projectRoot 'build/validation/user-data'
New-Item -ItemType Directory -Path $outputRoot, $profileRoot -Force | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $profileRoot
    $importOutput = Join-Path $outputRoot 'import-console.log'
    # Windows PowerShell treats native stderr as a terminating error under Stop.
    # Let Godot finish importing and record its complete diagnostics first.
    $ErrorActionPreference = 'Continue'
    & $GodotPath --headless --path $projectRoot --editor --import --quit --log-file (Join-Path $outputRoot 'import.log') *> $importOutput
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $importOutput -Pattern 'SCRIPT ERROR:|Parse Error:' -Quiet)) {
        throw "Fallo de importacion. Revisa $importOutput"
    }
    if ($ImportOnly) { Write-Output "Importacion completada: $outputRoot"; return }
    $script = "res://tests/$Suite.gd"
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot "tests/$Suite.gd"))) { throw "Suite inexistente: $Suite" }
    $consoleOutput = Join-Path $outputRoot "$Suite-console.log"
    $suiteArguments = @('--headless', '--path', $projectRoot, '--script', $script, '--log-file', (Join-Path $outputRoot "$Suite.log"))
    if ($Capture) {
        # A real renderer is needed for captures; keep the preview off the desktop.
        $suiteArguments = @('--path', $projectRoot, '--position', '20000,20000', '--script', $script, '--log-file', (Join-Path $outputRoot "$Suite.log"), '--', '--capture')
    }
    $ErrorActionPreference = 'Continue'
    & $GodotPath @suiteArguments *> $consoleOutput
    $ErrorActionPreference = 'Stop'
    Get-Content -LiteralPath $consoleOutput -Tail 5
    if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $consoleOutput -Pattern 'SCRIPT ERROR:|Parse Error:' -Quiet)) { throw "Validacion fallida. Revisa $consoleOutput" }
    Write-Output "Registros centralizados: $outputRoot"
} finally {
    $env:APPDATA = $previousAppData
}
