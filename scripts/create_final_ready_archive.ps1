$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exportDir = Join-Path $root '_exports'
$zipPath = Join-Path $exportDir 'RemotePath_Final_Ready.zip'
if (Test-Path -LiteralPath $zipPath) { throw "Refusing to overwrite existing archive: $zipPath" }
$required = @(
  '.github/workflows/pages.yml', '.nojekyll', '.gitignore', '.editorconfig',
  'docs/FINAL_PROMPT_PATCH_REPORT_AR.md', 'docs/FINAL_QA_CHECKLIST.md',
  'scripts/validate_generated_prompts.ps1', 'scripts/validate_generated_prompts.html'
)
foreach ($relative in $required) {
  if (!(Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { throw "Missing required archive file: $relative" }
}
$files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force | Where-Object {
  $relative = [IO.Path]::GetRelativePath($root, $_.FullName).Replace('\','/')
  $relative -notmatch '^(\.git|_exports)/' -and
  $relative -notmatch '(^|/)(node_modules|\.cache|\.tmp|temp|tmp)(/|$)' -and
  $relative -notmatch '\.(tmp|temp|log)$'
})
if (!$files.Count) { throw 'No project files found for archive.' }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [IO.File]::Open($zipPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
  $archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
  try {
    foreach ($file in $files) {
      $relative = [IO.Path]::GetRelativePath($root, $file.FullName).Replace('\','/')
      $entry = $archive.CreateEntry($relative, [IO.Compression.CompressionLevel]::Optimal)
      $input = [IO.File]::OpenRead($file.FullName)
      try { $output = $entry.Open(); try { $input.CopyTo($output) } finally { $output.Dispose() } } finally { $input.Dispose() }
    }
  } finally { $archive.Dispose() }
} finally { $stream.Dispose() }
$read = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
  $names = @($read.Entries | ForEach-Object FullName)
  if ($names | Where-Object { $_ -match '^(\.git|_exports)/' -or $_ -match '(^|/)CipherNeuron(/|$)' }) { throw 'Archive includes a forbidden path.' }
  foreach ($name in $names) {
    $entry = $read.GetEntry($name)
    if (!$entry) { throw "Missing ZIP entry: $name" }
    $entryStream = $entry.Open()
    try { $buffer = New-Object byte[] 81920; while ($entryStream.Read($buffer,0,$buffer.Length) -gt 0) {} } finally { $entryStream.Dispose() }
  }
  foreach ($relative in $required) {
    $entryName = $relative.Replace('\','/')
    if (!$read.GetEntry($entryName)) { throw "Required file not present in archive: $entryName" }
  }
  Write-Output "Archive created and read-verified: $zipPath"
  Write-Output "Files: $($read.Entries.Count); bytes: $((Get-Item -LiteralPath $zipPath).Length)"
  Write-Output "Hidden release files: .nojekyll=$([bool]$read.GetEntry('.nojekyll')); .gitignore=$([bool]$read.GetEntry('.gitignore')); .editorconfig=$([bool]$read.GetEntry('.editorconfig'))"
} finally { $read.Dispose() }
