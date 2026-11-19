$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$exportDir = Join-Path $root '_exports'
$archivePath = Join-Path $exportDir 'RemotePath_Final_Refined.zip'
if (Test-Path -LiteralPath $archivePath) {
  throw "Refusing to overwrite an existing archive: $archivePath"
}
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

$files = @(Get-ChildItem -LiteralPath $root -Force -Recurse -File | Where-Object {
  $relative = $_.FullName.Substring($root.Length).TrimStart('\')
  $segments = $relative -split '[\\/]'
  $segments[0] -notin @('.git','_exports')
})
$stream = [System.IO.File]::Open($archivePath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
try {
  $zip = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
  try {
    foreach ($file in $files) {
      $relative = $file.FullName.Substring($root.Length).TrimStart('\').Replace('\','/')
      $entry = $zip.CreateEntry($relative, [System.IO.Compression.CompressionLevel]::Optimal)
      $source = [System.IO.File]::OpenRead($file.FullName)
      try {
        $target = $entry.Open()
        try { $source.CopyTo($target) } finally { $target.Dispose() }
      } finally { $source.Dispose() }
    }
  } finally { $zip.Dispose() }
} finally { $stream.Dispose() }

$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
  $names = @($archive.Entries | ForEach-Object { $_.FullName })
  $required = @('.nojekyll','.gitignore','.editorconfig','.github/workflows/pages.yml','docs/FINAL_REFINEMENT_REPORT_AR.md','docs/FINAL_QA_CHECKLIST.md','scripts/validate_project.ps1')
  $missing = @($required | Where-Object { $_ -notin $names })
  $forbidden = @($names | Where-Object { $_ -match '(^|/)(\.git|_exports)(/|$)|CipherNeuron' })
  if ($missing.Count -gt 0 -or $forbidden.Count -gt 0) {
    throw "Archive verification failed. Missing: $($missing -join ', '); excluded paths found: $($forbidden -join ', ')"
  }
  foreach ($entry in $archive.Entries) {
    $entryStream = $entry.Open()
    try { $entryStream.CopyTo([System.IO.Stream]::Null) } finally { $entryStream.Dispose() }
  }
  Write-Output "Archive created and verified: $archivePath"
  Write-Output "Files: $($names.Count); bytes: $((Get-Item -LiteralPath $archivePath).Length); hidden project files included."
} finally { $archive.Dispose() }
