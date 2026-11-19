$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'data/specializations.json'
$items = @(Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)

$categoryTags = @{
  'programming-software-development' = @('Software Development','Web & App Development')
  'artificial-intelligence-ai-services' = @('Applied AI','AI Systems')
  'ai-training-data-annotation' = @('AI Data','Data Quality')
  'writing-translation-localization' = @('Writing & Editing','Language Services')
  'graphic-design-visual-content' = @('Visual Design','Digital Content')
  'video-audio-media-production' = @('Media Production','Digital Content')
  'marketing-social-media-ecommerce' = @('Digital Marketing','Audience Growth')
  'virtual-assistance-administrative-services' = @('Remote Operations','Business Support')
  'online-teaching-training' = @('Online Education','Instructional Design')
  'software-testing-product-testing' = @('Quality Assurance','Product Testing')
  'cybersecurity-bug-bounty' = @('Cybersecurity','Security Testing')
  'research-surveys-online-studies' = @('Online Research','Data Collection')
  'digital-products-online-selling' = @('Digital Products','Online Business')
  'customer-support-sales-community-management' = @('Customer Experience','Remote Sales')
  'specialized-professional-remote-services' = @('Professional Services','Remote Consulting')
}
$rules = @(
  @{ Pattern='frontend|javascript|react|vue|angular|web developer'; Tags=@('Frontend','JavaScript','Web Applications') },
  @{ Pattern='backend|api|full.stack|integration'; Tags=@('Backend','APIs','Application Development') },
  @{ Pattern='wordpress|shopify|webflow'; Tags=@('Website Building','CMS & E-commerce') },
  @{ Pattern='mobile|android|ios|flutter|react native'; Tags=@('Mobile Apps','App Development') },
  @{ Pattern='data analyst|business analyst|financial analyst'; Tags=@('Data Analysis','Reporting','Decision Support') },
  @{ Pattern='ai|llm|rag|prompt|machine learning|chatbot|agent'; Tags=@('Artificial Intelligence','Automation','AI Applications') },
  @{ Pattern='annotat|transcri|speech|data collector'; Tags=@('Data Labeling','AI Training Data','Quality Review') },
  @{ Pattern='writer|copywriter|editor|blog|script|technical writer'; Tags=@('Writing','Editing','Content Development') },
  @{ Pattern='translat|localiz|proofread'; Tags=@('Translation','Localization','Language Quality') },
  @{ Pattern='designer|design|visual|illustrat|canva'; Tags=@('Visual Design','Creative Production','Digital Content') },
  @{ Pattern='video|youtube|podcast|audio|sound|voice|subtitle'; Tags=@('Media Production','Editing','Digital Content') },
  @{ Pattern='seo|sem|ppc|media buyer|affiliate|email marketing|marketing'; Tags=@('Digital Marketing','Campaigns','Audience Growth') },
  @{ Pattern='social media|content planner|community manager'; Tags=@('Social Media','Content Planning','Audience Engagement') },
  @{ Pattern='virtual assistant|administrative|appointment|data entry|crm|spreadsheet|excel assistant'; Tags=@('Administrative Support','Remote Operations','Organization') },
  @{ Pattern='tutor|instructor|teacher|teaching|course creator'; Tags=@('Online Teaching','Learning Design','Student Support') },
  @{ Pattern='tester|qa|quality assurance|beta tester|usability'; Tags=@('Quality Assurance','Test Execution','Defect Reporting') },
  @{ Pattern='security|pentest|bug bounty|vulnerability|red team'; Tags=@('Cybersecurity','Security Testing','Risk Analysis') },
  @{ Pattern='survey|study participant|focus group|feedback contributor'; Tags=@('Research Participation','Surveys','User Feedback') },
  @{ Pattern='research assistant|online researcher|researcher'; Tags=@('Online Research','Source Evaluation','Information Synthesis') },
  @{ Pattern='template|ebook|e-book|publisher|digital planner|online course seller'; Tags=@('Digital Products','Product Creation','Online Selling') },
  @{ Pattern='support|customer success|sales|appointment setter'; Tags=@('Customer Communication','Remote Support','Service Operations') },
  @{ Pattern='bookkeep|accountant|accounting|legal|law|cad|3d|architect|consultant'; Tags=@('Professional Services','Specialist Delivery','Client Communication') }
)
$generic = @('Technical','Skill-Based','Client-Based','Entry-Level','Creative','Digital','Research','Communication','Administrative')
$changed = 0
foreach ($item in $items) {
  $matches = @($rules | Where-Object { $item.title -match $_.Pattern } | Select-Object -First 1)
  if ($matches.Count -gt 0) { $tags = @($matches[0].Tags) }
  else { $tags = @($categoryTags[$item.categoryId]) }
  if (-not $tags -or $tags.Count -eq 0) { throw "No substantive tag rule for $($item.id)" }
  $item.tags = @($tags | Select-Object -Unique | Where-Object { $_ -notin $generic } | Select-Object -First 3)
  if ($item.shortDescription -match ' Typical deliverables include .+$') {
    $item.shortDescription = $item.shortDescription -replace ' Typical deliverables include .+$','.'
  }
  $changed++
}
$json = ConvertTo-Json -InputObject @($items) -Depth 40
[System.IO.File]::WriteAllText($path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Write-Output "Updated role-specific catalog tags and removed repeated deliverable boilerplate for $changed specializations."
