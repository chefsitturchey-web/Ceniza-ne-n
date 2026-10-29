param([switch]$Validation)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$removed = 0
$bytes = 0L
function Assert-LocalTarget([string]$Path) {
    $absolute = [IO.Path]::GetFullPath($Path)
    if (-not $absolute.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Destino fuera del proyecto: $absolute"
    }
    $ancestor = $absolute
    while ($ancestor -and $ancestor -ne $projectRoot) {
        if (Test-Path -LiteralPath $ancestor) {
            if ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "No se limpiara un enlace o junction: $ancestor"
            }
        }
        $ancestor = Split-Path -Parent $ancestor
    }
    return $absolute
}
foreach ($file in Get-ChildItem -LiteralPath $projectRoot -File -Filter 'validation*.log') {
    $target = Assert-LocalTarget $file.FullName
    $bytes += $file.Length
    Remove-Item -LiteralPath $target -Force
    $removed++
}
$cacheFolders = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Directory -Filter '__pycache__' -Recurse -Force)
foreach ($folder in $cacheFolders) {
    $target = Assert-LocalTarget $folder.FullName
    $files = @(Get-ChildItem -LiteralPath $target -File -Recurse -Force)
    $removed += $files.Count
    $bytes += ($files | Measure-Object Length -Sum).Sum
    Remove-Item -LiteralPath $target -Recurse -Force
}
if ($Validation) {
    $target = Assert-LocalTarget (Join-Path $projectRoot 'build/validation')
    if (Test-Path -LiteralPath $target) {
        $files = @(Get-ChildItem -LiteralPath $target -File -Recurse -Force)
        $removed += $files.Count
        $bytes += ($files | Measure-Object Length -Sum).Sum
        Remove-Item -LiteralPath $target -Recurse -Force
    }
}
Write-Output ("Limpieza: {0} archivos generados eliminados ({1:N2} MB)." -f $removed, ($bytes / 1MB))
