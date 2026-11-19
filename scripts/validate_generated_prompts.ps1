param([int]$Port = 8876)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$preview = Join-Path $PSScriptRoot 'serve_preview.ps1'
$tempDir = [IO.Path]::GetTempPath()
$dump = Join-Path $tempDir ('remotepath-prompt-audit-' + [guid]::NewGuid().ToString('N') + '.html')
$server = $null
$browser = $null
try {
  $shell = (Get-Process -Id $PID).Path
  $server = Start-Process -FilePath $shell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$preview,'-Port',[string]$Port) -PassThru -WindowStyle Hidden
  $base = "http://127.0.0.1:$Port/"
  $ready = $false
  for($i=0;$i -lt 40;$i++){
    try { $null=Invoke-WebRequest -Uri $base -UseBasicParsing -TimeoutSec 2; $ready=$true; break } catch { Start-Sleep -Milliseconds 250 }
  }
  if(!$ready){throw 'The local preview server did not become ready.'}

  $edge = @('C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe','C:\Program Files\Microsoft\Edge\Application\msedge.exe') | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if(!$edge){throw 'Microsoft Edge was not found for the browser-based prompt audit.'}
  $url = $base + 'scripts/validate_generated_prompts.html'
  $browser = Start-Process -FilePath $edge -ArgumentList @('--headless','--disable-gpu','--disable-cache','--virtual-time-budget=20000','--dump-dom',$url) -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput $dump
  $dom = Get-Content -LiteralPath $dump -Raw
  $result = [regex]::Match($dom,'<title>PROMPT_AUDIT_(PASS|FAIL)_(\d+)_(\d+)</title>')
  if(!$result.Success){
    $details = [regex]::Match($dom,'<pre id="audit">([\s\S]*?)</pre>')
    throw "Browser prompt audit did not complete. $($details.Groups[1].Value)"
  }
  $status=$result.Groups[1].Value
  $generated=[int]$result.Groups[2].Value
  $failed=[int]$result.Groups[3].Value
  if($status -ne 'PASS' -or $generated -ne 229 -or $failed -ne 0){
    $details = [regex]::Match($dom,'<pre id="audit">([\s\S]*?)</pre>')
    throw "Prompt audit failed: generated=$generated failed=$failed. $($details.Groups[1].Value)"
  }
  Write-Output "Prompt builder browser audit passed: $generated generated prompts; $failed failed checks."

  # Verify that the real specialization page loads and renders the matching guide and caution field.
  $roleUrl=$base+'specialization.html?slug=bug-bounty-hunter'
  $browser=Start-Process -FilePath $edge -ArgumentList @('--headless','--disable-gpu','--disable-cache','--virtual-time-budget=12000','--dump-dom',$roleUrl) -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput $dump
  $page=Get-Content -LiteralPath $dump -Raw
  $hasPreview=$page -match 'data-prompt-preview'
  $hasCaution=$page -match 'explicit written authorization and scope'
  $hasDistinctive=$page -match 'Distinctive professional considerations:'
  $hasCautionLabel=$page -match 'Profession-specific professional cautions and boundaries:'
  if(!$hasPreview -or !$hasCaution -or !$hasDistinctive -or !$hasCautionLabel){throw 'The specialization page did not render the prompt preview with distinctiveness and professional cautions.'}
  Write-Output 'Frontend prompt-preview integration passed for Bug Bounty Hunter, including its caution and separate distinctive-considerations sections.'
} finally {
  if($server -and !$server.HasExited){Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue}
  if(Test-Path -LiteralPath $dump){Remove-Item -LiteralPath $dump -Force}
}
