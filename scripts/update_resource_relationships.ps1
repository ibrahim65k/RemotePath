$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$utf8 = [System.Text.UTF8Encoding]::new($false)
function Read-JsonArray([string]$path){
  $parsed=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json
  while($true){
    if($parsed -is [array]){if($parsed.Count -eq 1 -and $parsed[0].PSObject.Properties['value'] -and $parsed[0].value -is [array]){$parsed=$parsed[0].value;continue};return ,$parsed}
    if($parsed.PSObject.Properties['value'] -and $parsed.value -is [array]){$parsed=$parsed.value;continue}
    return ,@($parsed)
  }
}
$mapping=@{
  'podcast-editor'=@('upwork','fiverr','freelancer-com')
  'podcast-producer'=@('upwork','fiverr','freelancer-com')
  'audio-editor'=@('upwork','fiverr','freelancer-com')
  'sound-designer'=@('upwork','fiverr','freelancer-com')
  'video-subtitle-editor'=@('upwork','fiverr','khamsat')
  'motion-graphics-designer'=@('upwork','fiverr','freelancer-com')
  '2d-animator'=@('upwork','fiverr','freelancer-com')
  '3d-animator'=@('upwork','fiverr','freelancer-com')
  'video-colorist'=@('upwork','fiverr','freelancer-com')
  'video-repurposing-specialist'=@('upwork','fiverr','khamsat')
  'ai-video-producer'=@('upwork','fiverr','freelancer-com')
  'voice-over-artist'=@('upwork','fiverr','freelancer-com')
  'excel-assistant'=@('linkedin-jobs','wuzzuf')
  'spreadsheet-specialist'=@('linkedin-jobs','wuzzuf')
  'crm-data-entry-specialist'=@('linkedin-jobs','wuzzuf')
  'email-management-assistant'=@('linkedin-jobs','wuzzuf')
  'calendar-management-assistant'=@('linkedin-jobs','wuzzuf')
  'lead-generation-assistant'=@('linkedin-jobs','wuzzuf')
  'e-commerce-data-assistant'=@('linkedin-jobs','wuzzuf')
  'document-formatting-specialist'=@('linkedin-jobs','wuzzuf')
  'presentation-assistant'=@('linkedin-jobs','wuzzuf')
  'project-coordinator'=@('linkedin-jobs','wuzzuf')
  'executive-assistant'=@('linkedin-jobs','wuzzuf')
  'appointment-setter'=@('linkedin-jobs','wuzzuf')
  'sales-development-representative'=@('linkedin-jobs','wuzzuf')
  'online-sales-assistant'=@('linkedin-jobs','wuzzuf')
  'community-moderator'=@('linkedin-jobs','wuzzuf')
  'discord-server-manager'=@('linkedin-jobs','wuzzuf')
  'game-community-manager'=@('linkedin-jobs','wuzzuf')
  'recruiting-assistant'=@('linkedin-jobs','wuzzuf')
  'sourcing-specialist'=@('linkedin-jobs','wuzzuf')
  'legal-research-assistant'=@('linkedin-jobs','wuzzuf')
  'virtual-legal-assistant'=@('linkedin-jobs','wuzzuf')
  'medical-transcriptionist'=@('linkedin-jobs','wuzzuf')
  'product-photographer'=@('upwork','fiverr')
  'engineering-design-specialist'=@('upwork','freelancer-com')
  'professional-research-consultant'=@('upwork','linkedin-jobs')
  'specialized-remote-consultant'=@('upwork','linkedin-jobs')
}
$platformPath=Join-Path $root 'data/platforms.json'
$platforms=Read-JsonArray $platformPath
if($platforms -isnot [array] -or $platforms.Count -ne 51){throw 'Platforms JSON did not load as the expected 51-record array; refusing to write.'}
$known=@{};foreach($p in $platforms){$known[$p.id]=$p}
$added=0;$missingPlatformIds=@()
foreach($roleId in $mapping.Keys){
  foreach($platformId in $mapping[$roleId]){
    if(!$known.ContainsKey($platformId)){$missingPlatformIds+=$platformId;continue}
    if($known[$platformId].specializationIds -notcontains $roleId){
      $known[$platformId].specializationIds=@($known[$platformId].specializationIds)+$roleId
      $added++
    }
  }
}
$json=ConvertTo-Json -InputObject @($platforms) -Depth 40
[System.IO.File]::WriteAllText($platformPath,$json+[Environment]::NewLine,$utf8)
Write-Output "Added $added relevant role-to-platform links. Missing platform IDs: $(@($missingPlatformIds|Select-Object -Unique).Count)."

# Tighten examples that the review identified as overly broad.
$toolPath=Join-Path $root 'data/tools.json'
$specPath=Join-Path $root 'data/specializations.json'
$tools=Read-JsonArray $toolPath
$specs=Read-JsonArray $specPath
if($tools -isnot [array] -or $tools.Count -ne 68){throw 'Tools JSON did not load as the expected 68-record array; refusing to write.'}
$specById=@{};foreach($s in $specs){$specById[$s.id]=$s}
$toolRoleMap=@{
  'burp-suite'=@('bug-bounty-hunter','web-application-pentester','api-security-tester')
  'davinci-resolve'=@('video-editor','short-form-video-editor','youtube-video-editor','podcast-editor','audio-editor','sound-designer','video-subtitle-editor','motion-graphics-designer','2d-animator','3d-animator','video-colorist','video-repurposing-specialist','ai-video-producer','voice-over-artist','ai-video-creator','stock-video-creator')
  'hugging-face'=@('ai-chatbot-developer','ai-agent-developer','llm-application-developer','rag-developer','prompt-engineer','ai-integration-specialist','ai-model-fine-tuning-specialist','ai-data-pipeline-developer','ai-response-evaluator','llm-evaluator','prompt-response-rater','ai-content-reviewer','ai-safety-evaluator','ai-coding-evaluator','domain-expert-evaluator','annotation-quality-reviewer','ai-red-team-contributor','data-annotator','image-annotator','video-annotator','audio-annotator','text-annotator','ai-security-tester','ai-red-team-specialist','ai-product-tester')
}
$pruned=@()
foreach($tool in $tools){
  if($toolRoleMap.ContainsKey($tool.id)){
    $before=@($tool.specializationIds).Count
    $tool.specializationIds=@($toolRoleMap[$tool.id] | Where-Object {$specById.ContainsKey($_)})
    $pruned+=($before-@($tool.specializationIds).Count)
    $linkedCategories=@($tool.specializationIds | ForEach-Object {$specById[$_].categoryId} | Select-Object -Unique)
    $tool.categoryIds=@(@($tool.categoryIds)+$linkedCategories|Select-Object -Unique)
  }
  $allLinkedCategories=@($tool.specializationIds|ForEach-Object{$specById[$_].categoryId}|Where-Object{$_}|Select-Object -Unique)
  $tool.categoryIds=@(@($tool.categoryIds)+$allLinkedCategories|Select-Object -Unique)
}
$toolJson=ConvertTo-Json -InputObject @($tools) -Depth 40
[System.IO.File]::WriteAllText($toolPath,$toolJson+[Environment]::NewLine,$utf8)
Write-Output "Reviewed 68 tool records; refined three named relevance maps and removed $(@($pruned|Measure-Object -Sum).Sum) overbroad example links. Pricing and availability claims were not changed."
