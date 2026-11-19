$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script:failures = [System.Collections.Generic.List[string]]::new()
$script:passes = [System.Collections.Generic.List[string]]::new()

function Check([bool]$condition, [string]$label) {
  if($condition){$script:passes.Add($label)}else{$script:failures.Add($label)}
}
function Read-JsonArray([string]$path) {
  $parsed=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json
  while($true){
    if($parsed -is [array]){
      if($parsed.Count -eq 1 -and $parsed[0].PSObject.Properties['value'] -and $parsed[0].value -is [array]){$parsed=$parsed[0].value;continue}
      return ,$parsed
    }
    if($parsed.PSObject.Properties['value'] -and $parsed.value -is [array]){$parsed=$parsed.value;continue}
    return ,@($parsed)
  }
}

$required=@('README.md','RELEASE_CHECKLIST.md','.gitignore','.editorconfig','.nojekyll','404.html','about.html','category.html','index.html','platforms.html','search.html','specialization.html','tools.html','robots.txt','sitemap.xml','.github/workflows/pages.yml','assets/css/main.css','assets/css/components.css','assets/css/responsive.css','assets/js/app.js','assets/js/config.js','assets/js/data-loader.js','assets/js/directory.js','assets/js/navigation.js','assets/js/prompt-builder.js','assets/js/search.js','assets/js/seo.js','assets/icons/mark.svg','docs/PROJECT_BLUEPRINT.md','docs/CONTENT_SCHEMA.md','docs/DEVELOPMENT_PHASES.md','docs/PHASE_HANDOFF_AR.md','docs/GITHUB_DEPLOYMENT_GUIDE_AR.md','docs/FINAL_REFINEMENT_REPORT_AR.md','docs/FINAL_QA_CHECKLIST.md','docs/FINAL_PROMPT_PATCH_REPORT_AR.md','scripts/refine_profession_specific_guidance.ps1','scripts/create_final_ready_archive.ps1','scripts/validate_generated_prompts.ps1','scripts/validate_generated_prompts.html')
foreach($file in $required){Check (Test-Path -LiteralPath (Join-Path $root $file) -PathType Leaf) "Required file: $file"}

$categories=Read-JsonArray (Join-Path $root 'data/categories.json')
$specs=Read-JsonArray (Join-Path $root 'data/specializations.json')
$guides=Read-JsonArray (Join-Path $root 'data/prompt-guidance.json')
$platforms=Read-JsonArray (Join-Path $root 'data/platforms.json')
$tools=Read-JsonArray (Join-Path $root 'data/tools.json')
$categoryIds=@{};foreach($c in $categories){$categoryIds[[string]$c.id]=$c}
$specById=@{};foreach($s in $specs){$specById[[string]$s.id]=$s}
$guideBySpec=@{};foreach($g in $guides){$guideBySpec[[string]$g.specializationId]=$g}

Check ($categories.Count -eq 15) "Category count = 15 (actual $($categories.Count))"
Check ($specs.Count -eq 229) "Specialization count = 229 (actual $($specs.Count))"
Check ($guides.Count -eq $specs.Count) "Prompt guidance coverage = specialization count ($($guides.Count))"
Check ($platforms.Count -eq 51) "Platform count = 51 (actual $($platforms.Count))"
Check ($tools.Count -eq 68) "Tool count = 68 (actual $($tools.Count))"
Check (($categories.id|Select-Object -Unique).Count -eq $categories.Count) 'Unique category IDs'
Check (($categories.slug|Select-Object -Unique).Count -eq $categories.Count) 'Unique category slugs'
Check (($specs.id|Select-Object -Unique).Count -eq $specs.Count) 'Unique specialization IDs'
Check (($specs.slug|Select-Object -Unique).Count -eq $specs.Count) 'Unique specialization slugs'
Check (($platforms.id|Select-Object -Unique).Count -eq $platforms.Count) 'Unique platform IDs'
Check (($tools.id|Select-Object -Unique).Count -eq $tools.Count) 'Unique tool IDs'

$badCategories=@($specs|Where-Object{!$categoryIds.ContainsKey([string]$_.categoryId)})
$missingGuides=@($specs|Where-Object{!$guideBySpec.ContainsKey([string]$_.id)})
$invalidGuideRefs=@($guides|Where-Object{!$specById.ContainsKey([string]$_.specializationId)})
$invalidPlatformRefs=@($platforms|ForEach-Object{$_.specializationIds}|Where-Object{!$specById.ContainsKey([string]$_)})
$invalidToolRefs=@($tools|ForEach-Object{$_.specializationIds}|Where-Object{!$specById.ContainsKey([string]$_)})
$invalidPlatformCats=@($platforms|ForEach-Object{$_.categoryIds}|Where-Object{!$categoryIds.ContainsKey([string]$_)})
$invalidToolCats=@($tools|ForEach-Object{$_.categoryIds}|Where-Object{!$categoryIds.ContainsKey([string]$_)})
$duplicateRelationships=0
foreach($record in @($platforms)+@($tools)){$ids=@($record.specializationIds);$duplicateRelationships+=($ids.Count-@($ids|Select-Object -Unique).Count)}
Check ($badCategories.Count -eq 0) 'Every specialization has a valid category'
Check ($missingGuides.Count -eq 0 -and $invalidGuideRefs.Count -eq 0) 'Prompt guidance maps one-to-one to existing specializations'
Check ($invalidPlatformRefs.Count -eq 0 -and $invalidPlatformCats.Count -eq 0) 'Platform relationship IDs resolve'
Check ($invalidToolRefs.Count -eq 0 -and $invalidToolCats.Count -eq 0) 'Tool relationship IDs resolve'
Check ($duplicateRelationships -eq 0) 'No duplicate platform/tool specialization relationships'
$platformMapped=@{};foreach($platform in $platforms){foreach($id in $platform.specializationIds){$platformMapped[[string]$id]=$true}}
$specsWithoutPlatform=@($specs|Where-Object{!$platformMapped.ContainsKey([string]$_.id)})
Check ($specsWithoutPlatform.Count -eq 0) "Every specialization has at least one mapped platform (missing: $($specsWithoutPlatform.Count))"

$genericTags=@('Technical','Skill-Based','Client-Based','Task-Based','Language-Based','Specialized','Creative','Product-Based','Administrative')
$specsWithGenericTags=@($specs|Where-Object{@($_.tags|Where-Object{$_ -in $genericTags}).Count -gt 0})
Check ($specsWithGenericTags.Count -eq 0) "No generic placeholder tags remain (records: $($specsWithGenericTags.Count))"
$weakGuides=@($guides|Where-Object{!$_.domainKnowledge -or $_.domainKnowledge.Count -lt 4 -or $_.typicalTasks.Count -lt 3 -or $_.commonDeliverables.Count -lt 3 -or $_.keySkills.Count -lt 5 -or $_.learningPriorities.Count -lt 3 -or !$_.distinctiveConsiderations -or !$_.professionalCautions -or $_.relatedToolAndPlatformGuidance.Count -lt 2 -or @($_.keySkills|Where-Object{$_ -in $genericTags}).Count -gt 0})
Check ($weakGuides.Count -eq 0) "All guidance records contain profession-specific skill/domain/learning/caution fields plus tasks and outputs (weak: $($weakGuides.Count))"
$genericDomainPhrases=@('Programming language or platform named by the specialization','Data flow and error handling','Testing strategy and deployment context','Applicable standards and jurisdiction','Primary sources or technical specifications')
$genericDomainRecords=@($guides|Where-Object{@($_.domainKnowledge|Where-Object{$_ -in $genericDomainPhrases}).Count -gt 0})
Check ($genericDomainRecords.Count -eq 0) "No universal placeholder domain anchors remain (records: $($genericDomainRecords.Count))"
$emptyPromptFields=@($guides|Where-Object{@($_.keySkills+$_.domainKnowledge+$_.learningPriorities+$_.typicalTasks+$_.commonDeliverables+$_.distinctiveConsiderations+$_.professionalCautions+$_.relatedToolAndPlatformGuidance|Where-Object{!$_ -or ($_ -isnot [string])}).Count -gt 0})
Check ($emptyPromptFields.Count -eq 0) "Prompt-facing guidance has no empty or non-text values (records: $($emptyPromptFields.Count))"

$cssFiles=@(Get-ChildItem (Join-Path $root 'assets/css') -Filter '*.css' -File)
$cssText=($cssFiles|ForEach-Object{Get-Content $_.FullName -Raw}) -join "`n"
$defined=@([regex]::Matches($cssText,'--([A-Za-z0-9_-]+)\s*:')|ForEach-Object{$_.Groups[1].Value}|Select-Object -Unique)
$used=@([regex]::Matches($cssText,'var\(\s*--([A-Za-z0-9_-]+)')|ForEach-Object{$_.Groups[1].Value}|Select-Object -Unique)
$undefined=@($used|Where-Object{$_ -notin $defined})
$cssUnbalanced=@()
foreach($file in $cssFiles){$text=Get-Content $file.FullName -Raw;$depth=0;foreach($ch in $text.ToCharArray()){if($ch -eq '{'){$depth++};if($ch -eq '}'){$depth--;if($depth -lt 0){break}}};if($depth -ne 0){$cssUnbalanced+=$file.Name}}
$mainCssLength=(Get-Item (Join-Path $root 'assets/css/main.css')).Length
Check ($mainCssLength -gt 5000) "Base design stylesheet restored (>5 KB; $mainCssLength bytes)"
Check ($undefined.Count -eq 0) "All used CSS custom properties are defined (undefined: $($undefined -join ', '))"
Check ($cssUnbalanced.Count -eq 0) "CSS braces balance in all stylesheets"
Check ($cssText -match ':focus-visible' -and $cssText -match 'prefers-reduced-motion') 'Focus-visible and reduced-motion styles exist'

$htmlFiles=@(Get-ChildItem $root -Filter '*.html' -File)
$broken=@()
foreach($html in $htmlFiles){
  $text=Get-Content $html.FullName -Raw
  foreach($match in [regex]::Matches($text,'(?:href|src)="([^"]+)"')){
    $url=$match.Groups[1].Value
    if($url -match '^(https?:|mailto:|tel:|#|data:|javascript:)'){continue}
    $local=($url -split '[?#]')[0]
    if(!$local){continue}
    $local=[uri]::UnescapeDataString($local)
    if(!(Test-Path -LiteralPath (Join-Path $root $local))){$broken+=($html.Name+': '+$url)}
  }
}
Check ($broken.Count -eq 0) "Static local href/src paths resolve (broken: $($broken.Count))"
$sitemapText=Get-Content (Join-Path $root 'sitemap.xml') -Raw
try{$xml=[xml]$sitemapText;$xmlOk=$true}catch{$xmlOk=$false}
Check $xmlOk 'Sitemap parses as XML'
Check (([regex]::Matches($sitemapText,'<loc>')).Count -eq 248) 'Sitemap contains 248 intended public routes'

$builder=Get-Content (Join-Path $root 'assets/js/prompt-builder.js') -Raw
Check ($builder.Contains('roleTitle') -and $builder.Contains('guide.domainKnowledge') -and $builder.Contains('relatedToolAndPlatformGuidance') -and $builder.Contains('guide.professionalCautions')) 'Prompt builder reads role-specific fields including professional cautions'
Check ($builder.Contains('Distinctive professional considerations:') -and $builder.Contains('Profession-specific professional cautions and boundaries:')) 'Prompt builder labels distinctive considerations separately from cautions'
Check ($builder.Contains('cleanText') -and $builder.Contains('cleanList') -and $builder.Contains('No profession-specific cautions were supplied')) 'Prompt builder handles absent or malformed optional values safely'
$workflow=Get-Content (Join-Path $root '.github/workflows/pages.yml') -Raw
Check ($workflow.Contains('actions/checkout@v7') -and $workflow.Contains('actions/configure-pages@v5') -and $workflow.Contains('actions/upload-pages-artifact@v5') -and $workflow.Contains('actions/deploy-pages@v5')) 'Pages workflow uses current official action major versions'
Check ($workflow.Contains('pages: write') -and $workflow.Contains('id-token: write') -and $workflow.Contains('contents: read') -and $workflow.Contains('include-hidden-files: true')) 'Pages workflow has required minimal permissions and includes .nojekyll'
Check ($workflow.Contains('path: _site') -and !$workflow.Contains('path: .')) 'Pages workflow uploads staged website artifact only'

Write-Output "Actual data: categories=$($categories.Count); specializations=$($specs.Count); prompt guidance=$($guides.Count); platforms=$($platforms.Count); tools=$($tools.Count)"
Write-Output "Checks passed: $($script:passes.Count); failed: $($script:failures.Count)"
foreach($pass in $script:passes){Write-Output "PASS | $pass"}
foreach($failure in $script:failures){Write-Output "FAIL | $failure"}
Write-Output "Broken local paths: $($broken -join ' | ')"
Write-Output "Weak guidance IDs: $(@($weakGuides|Select-Object -ExpandProperty specializationId) -join ', ')"
if($script:failures.Count -gt 0){exit 1}


