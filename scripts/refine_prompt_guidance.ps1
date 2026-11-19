# Initial Phase 03 guidance generator. For the final profession-specific skill/domain profiles,
# the last step below reapplies the focused refinement without changing directory records.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$specPath = Join-Path $root 'data/specializations.json'
$guidePath = Join-Path $root 'data/prompt-guidance.json'
$toolPath = Join-Path $root 'data/tools.json'
$platformPath = Join-Path $root 'data/platforms.json'
$utf8 = [System.Text.UTF8Encoding]::new($false)
function Read-JsonArray([string]$path) {
  $parsed = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  while($true){
    if($parsed -is [array]){
      if($parsed.Count -eq 1 -and $parsed[0].PSObject.Properties['value'] -and $parsed[0].value -is [array]){$parsed=$parsed[0].value;continue}
      return ,$parsed
    }
    if($parsed.PSObject.Properties['value'] -and $parsed.value -is [array]){$parsed=$parsed.value;continue}
    return ,@($parsed)
  }
}

$special = @{
  'frontend-developer' = @{ domain='HTML, CSS, JavaScript, browser rendering, responsive layout, DOM behavior, accessibility, and API-backed interfaces'; tasks=@('Translate a supplied Figma or design specification into semantic, responsive HTML and CSS, including mobile and keyboard states.','Implement interactive JavaScript behavior and connect the interface to an API, handling loading, empty, and error states.','Reproduce a browser defect, isolate the layout or DOM cause, and verify the fix at multiple viewport widths.') ; outputs=@('Responsive page or component with source files and a design-to-implementation note.','Keyboard and viewport test results with any accessibility or browser compatibility issues recorded.','A deployable interface change with before-and-after evidence and tested edge states.') ; skills=@('Semantic HTML','CSS layout and responsive design','JavaScript and DOM','Accessibility and keyboard interaction','Browser debugging and performance') }
  'backend-developer' = @{ domain='server-side application logic, HTTP APIs, authentication, validation, data persistence, logging, and automated tests'; tasks=@('Implement or modify an API endpoint with request validation, authorization checks, and documented response behavior.','Trace a server error through application logs and reproduce the failing input before changing business logic.','Add tests for success, invalid input, permission failures, and a relevant boundary case.') ; outputs=@('Tested API or service change with request/response examples and setup notes.','Schema or migration change with rollback and data-integrity checks where applicable.','A reproducible defect report or performance finding with measured evidence.') ; skills=@('HTTP and API design','Server-side programming','Data modeling and SQL','Authentication and authorization','Automated testing and logging') }
  'full-stack-developer' = @{ domain='browser UI, server endpoints, persistence, API contracts, authentication, end-to-end behavior, and deployment'; tasks=@('Deliver a vertical feature from an interface state through its API and stored data, checking validation and error paths.','Trace a user-visible defect across browser, network request, and server logs to find its actual source.','Run integration tests and review configuration or deployment effects before handoff.') ; outputs=@('A working end-to-end feature with UI, API, data changes, and verification steps.','A cross-layer bug fix with regression coverage and a short technical handoff.','An implementation note identifying configuration, security, and deployment assumptions.') ; skills=@('Frontend and server-side programming','API contracts','Database design','End-to-end testing','Deployment and debugging') }
  'ai-response-evaluator' = @{ domain='LLM output evaluation, instruction following, factual accuracy, relevance, hallucination detection, rubric use, response ranking, and qualification tests'; tasks=@('Score an AI response against the exact rubric, separating instruction compliance, factual support, relevance, and style.','Compare two candidate responses and identify the specific evidence that makes one safer or more useful.','Flag unsupported claims, fabricated citations, policy failures, or ambiguous rubric cases without rewriting the task as software engineering.') ; outputs=@('Completed evaluation records with rubric-based ratings and concise evidence.','Pairwise response comparisons that explain the decisive quality differences.','An uncertainty or escalation note for cases the supplied rubric cannot resolve.') ; skills=@('Rubric interpretation','Factuality and source checking','Comparative judgment','Hallucination and policy detection','Consistent written rationale') }
  'video-editor' = @{ domain='timeline editing, shot selection, sequencing, pacing, transitions, dialogue cleanup, audio synchronization, subtitles, color correction, export settings, and client review'; tasks=@('Organize supplied footage, select usable takes, and assemble a story-focused sequence to the brief and target duration.','Synchronize dialogue and music, clean audio, add requested captions or graphics, and apply consistent basic color correction.','Export platform-specific versions, inspect playback and audio peaks, and deliver the project file with named media assets.') ; outputs=@('An edited video master plus requested aspect-ratio or short-form versions.','An editable timeline project with relinkable media and an organized asset folder.','A delivery checklist recording codec, dimensions, captions, audio, and review notes.') ; skills=@('Timeline editing and pacing','Audio synchronization and cleanup','Captions and graphics','Color correction','Codec and export quality control') }
  'virtual-assistant' = @{ domain='email and calendar operations, scheduling, document organization, spreadsheet upkeep, research, CRM updates, client communication, and task coordination'; tasks=@('Triage an agreed inbox using labels and escalation rules, draft routine replies, and flag messages needing client decisions.','Coordinate calendar appointments across time zones, confirm details, and resolve conflicts without changing commitments outside authorization.','Update task, contact, or spreadsheet records from approved sources and run a completeness check before handoff.') ; outputs=@('An accurately updated inbox, calendar, CRM, or operations tracker with exception notes.','A concise handoff summary separating completed actions from decisions required.','Reusable checklists or templates for recurring administrative workflows.') ; skills=@('Email and calendar management','Spreadsheet accuracy','CRM and task tracking','Research and source logging','Confidentiality and escalation judgment') }
  'bug-bounty-hunter' = @{ domain='authorized reconnaissance, program scope, attack-surface discovery, web vulnerability research, safe validation, severity assessment, reproducible evidence, and responsible disclosure'; tasks=@('Read the program scope and safe-harbor rules before testing; map only explicitly authorized assets and excluded areas.','Validate a suspected web vulnerability with the minimum safe proof needed, avoiding data access, persistence, or service disruption.','Prepare a reproducible report with affected endpoint, impact, evidence, severity rationale, and practical remediation guidance.') ; outputs=@('A scope-compliant vulnerability report with redacted proof and clear reproduction steps.','A triage note distinguishing a confirmed issue, duplicate, informational finding, or unverified lead.','A remediation-focused retest result after the owner approves validation.') ; skills=@('Web security fundamentals','Scope and authorization discipline','Safe vulnerability validation','Evidence and severity assessment','Responsible disclosure') }
  'online-survey-participant' = @{ domain='study eligibility, screening questions, informed consent, participant instructions, honest responses, study completion, privacy choices, and payment eligibility'; tasks=@('Check the study location, age, language, device, and other stated eligibility rules before beginning a screener.','Read consent and task instructions, complete the assigned survey or activity honestly, and avoid duplicate or fabricated responses.','Record completion evidence and distinguish study compensation terms from guaranteed income or payment access.') ; outputs=@('A valid, complete study submission that follows researcher instructions and consent terms.','A truthful screener response set and completion confirmation where the study provides one.','Participant feedback only where requested, without disclosing protected study materials.') ; skills=@('Careful instruction reading','Eligibility and consent awareness','Honest, consistent responses','Privacy and data handling','Study completion discipline') }
  'podcast-editor' = @{ domain='multitrack audio editing, dialogue cleanup, loudness consistency, pacing, intro/outro placement, music licensing, metadata, and podcast export formats'; tasks=@('Assemble host and guest tracks, remove distracting pauses or noise without damaging speech, and preserve natural conversation flow.','Balance speech, music, and effects; check loudness and mono compatibility against the publisher delivery specification.','Export the requested episode and teaser clips, verify metadata, and provide an editable session with licensed assets identified.') ; outputs=@('A mastered podcast episode in the requested audio format plus optional teaser cuts.','An editable multitrack session and organized source-media handoff.','A QC sheet noting loudness, clipping, metadata, and music-rights assumptions.') ; skills=@('Multitrack editing','Dialogue restoration','Loudness and export standards','Pacing and continuity','Audio licensing awareness') }
  'podcast-producer' = @{ domain='episode planning, guest coordination, recording logistics, editorial structure, production schedules, release assets, and publishing handoff'; tasks=@('Turn an episode brief into a run-of-show with segments, timing, guest needs, and recording contingencies.','Coordinate preproduction details and track approvals, releases, files, and deadlines across participants.','Review the assembled episode package for title, description, show notes, artwork, links, and publishing readiness.') ; outputs=@('Episode run-of-show, production calendar, and guest preparation notes.','A release-ready episode package with metadata and approved promotional assets.','A production handoff that lists missing approvals, source files, or publishing decisions.') ; skills=@('Editorial planning','Guest and schedule coordination','Audio production workflow','Metadata and show notes','Rights and release tracking') }
  'voice-over-artist' = @{ domain='script interpretation, vocal performance, diction, microphone technique, room noise, retakes, audio editing, pronunciation review, and usage-rights terms'; tasks=@('Mark a script for intent, pacing, pronunciation, and emphasis, then record clean takes to the agreed style and file specification.','Review recordings for plosives, clipping, room noise, consistency, and correct pronunciation before submitting selects.','Clarify usage, territory, duration, exclusivity, and synthetic-voice restrictions before licensing a recording.') ; outputs=@('Edited, labeled voice tracks with alternate takes where requested.','A pronunciation or pickup list with synchronized retake notes.','A delivery package documenting format and agreed usage rights.') ; skills=@('Vocal performance and diction','Microphone and room technique','Audio editing and QC','Script interpretation','Usage-rights awareness') }
  'ai-red-team-contributor' = @{ domain='authorized AI safety testing, adversarial inputs, misuse cases, policy boundaries, reproducibility, risk classification, and careful reporting'; tasks=@('Use only the assigned test environment and approved red-team protocol to probe a defined model behavior.','Record the exact prompt, output, expected policy behavior, and repeatability while minimizing harmful content exposure.','Classify findings by potential impact and provide safe reproduction guidance for the authorized review team.') ; outputs=@('A reproducible test case within the approved scope.','A policy or safety finding with evidence, impact rationale, and minimal necessary excerpts.','A retest record showing whether an approved mitigation changed the behavior.') ; skills=@('Adversarial test design','Policy and rubric interpretation','Reproducibility','Risk assessment','Safe evidence handling') }
  'medical-transcriptionist' = @{ domain='clinical speech transcription, medical terminology, speaker and medication accuracy, timestamps, formatting conventions, privacy, and quality review'; tasks=@('Transcribe the assigned recording using the client approved format and flag genuinely inaudible segments rather than guessing.','Verify names, dosages, abbreviations, and clinical terms against permitted reference material and supplied style rules.','Perform a final audio-to-text pass and handle recordings only through authorized secure systems.') ; outputs=@('A formatted clinical transcript with uncertainty markers handled per client rules.','A correction log for ambiguous terminology or unintelligible passages.','A privacy-conscious delivery with no unnecessary local copies of protected recordings.') ; skills=@('Medical terminology','Accurate listening and typing','Clinical formatting','Confidentiality and data security','Proofreading under uncertainty') }
  'legal-research-assistant' = @{ domain='jurisdiction-aware legal research, primary authority, citation validation, issue tracking, source currency, attorney supervision, and the boundary against independent legal advice'; tasks=@('Research a lawyer-defined question within the specified jurisdiction and date range, prioritizing statutes, regulations, and court opinions.','Verify citations, procedural status, and quoted language against the primary source before summarizing authority.','Separate binding authority, persuasive material, and secondary commentary in a concise research log.') ; outputs=@('A jurisdiction- and date-labeled research memorandum with checked citations.','A source table recording authority, holding or relevance, and verification status.','A handoff that highlights unresolved legal questions for supervising counsel.') ; skills=@('Primary-source legal research','Citation checking','Jurisdiction and date awareness','Concise legal writing','Confidentiality and supervision') }
  'web-application-pentester' = @{ domain='written authorization, defined web application scope, threat modeling, safe vulnerability testing, evidence minimization, severity, and remediation'; tasks=@('Confirm written scope, test accounts, rate limits, and prohibited actions before assessing the application.','Test only approved endpoints for common web risks and validate findings without extracting unnecessary personal or production data.','Document a reproducible finding, impact, evidence, and remediation; retest only with authorization.') ; outputs=@('A scope-bound web application assessment report with prioritized findings.','Minimal reproducible evidence with sensitive data redacted.','A remediation and authorized retest record.') ; skills=@('Web application security','HTTP and browser testing','Authorization and scope control','Severity and impact assessment','Responsible reporting') }
  'huggingface' = @{ domain='model and dataset discovery, model cards, licenses, inference endpoints, transformers, evaluation, and reproducible ML workflows'; tasks=@('Check a model or dataset card, license, intended use, and limitations before incorporating it into a project.','Run a small reproducible inference or evaluation experiment and record model version, inputs, and metrics.','Package a relevant artifact or demonstration while protecting credentials and documenting dependencies.') ; outputs=@('A versioned model or dataset evaluation note with license and limitation checks.','A reproducible demo or pipeline configuration with no embedded secrets.','An evidence-backed recommendation for a specific AI workflow.') ; skills=@('Model and dataset evaluation','License and model-card review','Python/ML workflow literacy','Reproducible experiments','Privacy and credential safety') }
}

$genericTags = @('Technical','Skill-Based','Client-Based','Task-Based','Language-Based','Specialized','Creative','Product-Based','Administrative')
function Set-Field($target, [string]$name, $value) {
  if($target.PSObject.Properties[$name]){$target.$name=$value}
  else{Add-Member -InputObject $target -MemberType NoteProperty -Name $name -Value $value}
}
$guides = Read-JsonArray $guidePath
$specs = Read-JsonArray $specPath
$tools = Read-JsonArray $toolPath
$platforms = Read-JsonArray $platformPath
$specById = @{}; foreach($s in $specs){$specById[$s.id]=$s}
$categoryNames = @{}; foreach($c in (Read-JsonArray (Join-Path $root 'data/categories.json'))){$categoryNames[$c.id]=$c.name}
$changed = 0

foreach($g in $guides){
  $id = [string]$g.specializationId
  if(!$id){continue}
  $s = $specById[$id]
  if(!$s){continue}
  $title = $s.title
  $category = [string]$s.categoryId
  $roleSpecific = $special[$id]
  $relatedTools = @($tools | Where-Object { $_.specializationIds -contains $id } | Select-Object -ExpandProperty name -Unique | Select-Object -First 6)
  $relatedPlatforms = @($platforms | Where-Object { $_.specializationIds -contains $id } | Select-Object -ExpandProperty name -Unique | Select-Object -First 6)

  switch($category){
    'programming-software-development' {
      $domain = 'software implementation, debugging, version control, testing, deployment, and documented technical handoff'
      $tasks = @("Implement a scoped $title change against an existing technical brief, preserving the surrounding application contracts and edge cases.","Reproduce a role-relevant defect or requirement in a small test environment, then verify the change with an appropriate automated or manual check.","Prepare a maintainable handoff that identifies the changed component, setup assumptions, tests run, and any deployment or compatibility limits.")
      $outputs = @("A $title implementation artifact such as a feature, integration, script, or focused code change with relevant tests.",'A reproducible test or defect note with expected behavior, actual behavior, and supporting evidence.','A maintainer-ready handoff with setup, configuration, security, and deployment assumptions.')
      $skills = @('Programming in the role-relevant language or runtime','Reading technical specifications and existing code','Testing and debugging','Version control and code review','Secure handling of data and credentials')
      $knowledge = @('Programming language or platform named by the specialization','Data flow and error handling','Testing strategy and deployment context')
    }
    'artificial-intelligence-ai-services' {
      $domain = 'AI system design, model selection, data boundaries, evaluation, integration, human review, and failure handling'
      $tasks = @("Translate a $title use case into inputs, outputs, constraints, and a measurable success criterion before choosing a model or automation pattern.",'Build a small, testable workflow using representative examples; inspect incorrect, unsafe, and ambiguous outputs rather than relying on a happy-path demo.','Document model/provider assumptions, data retention, fallback behavior, evaluation results, and the limits that require human review.')
      $outputs = @("A scoped $title workflow, prompt, model feature, or integration with sample inputs and evaluated outputs.",'A test set or evaluation note covering quality, failure cases, latency, and safety boundaries.','A deployment handoff that identifies data handling, provider terms, fallback, monitoring, and human-review needs.')
      $skills = @('Model and tool selection','Prompt or workflow design','Evaluation and error analysis','API integration and data handling','Privacy, safety, and human oversight')
      $knowledge = @('Model capabilities and limitations','Evaluation examples and acceptance criteria','Data protection and failure recovery')
    }
    'ai-training-data-annotation' {
      $domain = 'task-specific annotation or evaluation, rubric interpretation, consistent labels, quality review, ambiguity handling, and secure dataset work'
      $tasks = @("Complete a $title assignment by applying the project taxonomy to each item and recording only labels supported by the supplied evidence.",'Check borderline cases against the rubric, preserve timestamps or spans where required, and escalate ambiguous examples rather than guessing.','Review a batch for schema validity, omissions, inconsistent labels, and privacy or safety handling before submission.')
      $outputs = @("A schema-valid $title annotation or evaluation batch with required labels, spans, timestamps, or ratings.",'A concise ambiguity log that points to the conflicting instruction and requests a rubric clarification.','A quality-control correction set with the reason for each change and consistency checks.')
      $skills = @('Rubric and taxonomy interpretation','Modality-specific attention to detail','Consistent labeling and schema accuracy','Uncertainty escalation','Privacy and data handling')
      $knowledge = @('Label definitions and edge cases','Quality sampling and disagreement resolution','Secure handling of supplied examples')
    }
    'writing-translation-localization' {
      $domain = 'audience, source research, editorial brief, terminology, tone, language quality, revision, and delivery format'
      $tasks = @("Produce a $title assignment from a defined audience and brief, separating verified source facts from interpretation or promotional claims.",'Build an outline or terminology/style sheet before drafting, translating, or editing so the work stays consistent across sections.','Run a final accuracy, language, formatting, originality, and rights check against the client specification.')
      $outputs = @("A brief-aligned $title text deliverable in the requested language, tone, structure, and format.",'A source, terminology, or style note that makes factual and editorial decisions traceable.','A revised final file with tracked changes or clean copy and a concise handoff of unresolved questions.')
      $skills = @('Audience-aware writing or language transfer','Research and source verification','Terminology and style consistency','Editing and proofreading','Copyright and attribution awareness')
      $knowledge = @('Genre conventions relevant to the specialization','Source quality and factual verification','Language, tone, and terminology choices')
    }
    'graphic-design-visual-content' {
      $domain = 'visual hierarchy, audience, brand constraints, layout, typography, color, accessibility, source files, and production export'
      $tasks = @("Convert a $title design brief into a clear visual hierarchy and create alternatives that answer the stated audience and use case.",'Refine spacing, typography, color, contrast, crop, or component behavior against the actual display size and brand constraints.','Export correctly sized production files and check editable source organization, licensing, and handoff notes.')
      $outputs = @("A production-ready $title asset set in requested formats and dimensions, plus organized editable source files.",'A concise visual rationale tying layout and hierarchy to the brief, not personal preference.','An export and usage handoff covering variants, fonts, stock assets, and licensing assumptions.')
      $skills = @('Visual hierarchy and composition','Typography, color, and contrast','Specialization-specific design software','File preparation and export quality','Client feedback and rights management')
      $knowledge = @('Audience and channel specifications','Design-system or brand constraints','Accessibility, licensing, and production formats')
    }
    'video-audio-media-production' {
      $domain = 'media planning, timeline or layer workflow, pacing, audio and visual quality, captions, export specifications, source organization, and rights'
      $tasks = @("Complete a $title production brief by organizing source media and building the requested sequence, mix, animation, or voice performance to specification.",'Review continuity, timing, synchronization, levels, color or rendering artifacts, captions, and target-platform dimensions before final export.','Package the approved master, requested variants, editable project assets, and a rights-aware handoff.')
      $outputs = @("A $title media deliverable in the requested duration, aspect ratio, resolution, codec, or audio format.",'An organized editable project or session with relinkable source assets and named versions.','A technical quality-control checklist covering playback, audio, captions, exports, and usage rights.')
      $skills = @('Media-specific editing or production workflow','Pacing, timing, and continuity','Audio, color, and export quality control','File organization and versioning','Copyright, music, and usage rights')
      $knowledge = @('Target channel and delivery specification','Source-media organization and non-destructive workflow','Licensing and export quality checks')
    }
    'marketing-social-media-ecommerce' {
      $domain = 'audience intent, channel strategy, campaign or catalog operations, truthful claims, measurement, consent, and optimization'
      $tasks = @("Plan a $title work item around a named audience, channel, and business objective, defining a measurable baseline before execution.",'Create or update the relevant campaign, content calendar, product record, or outreach workflow with approved copy, targeting, and tracking.','Review performance or data quality, identify a testable next change, and report results without claiming causation from weak evidence.')
      $outputs = @("A $title campaign, content, listing, research, or outreach artifact tied to the stated objective.",'A channel-specific measurement plan with tracking fields, assumptions, and privacy/consent checks.','A concise optimization report separating observed data from recommendations.')
      $skills = @('Audience and channel research','Campaign or catalog execution','Analytics and measurement','Clear, truthful marketing communication','Privacy, consent, and platform-policy awareness')
      $knowledge = @('Channel-specific formats and constraints','Measurement definitions and attribution limits','Brand, consent, and advertising requirements')
    }
    'virtual-assistance-administrative-services' {
      $domain = 'business operations, records accuracy, scheduling, information organization, process documentation, permissions, and client handoff'
      $tasks = @("Complete a $title operations request from approved instructions, updating only the specified record, schedule, document, or workflow.",'Validate names, dates, formulas, links, time zones, and required fields against the approved source before marking the task complete.','Maintain an exception list and handoff that distinguishes finished actions from missing information or decisions requiring approval.')
      $outputs = @("An accurate $title operational record, calendar, spreadsheet, contact list, document, or coordination plan.",'A reusable checklist or template for the recurring workflow, with ownership and approval steps clear.','A short exception and handoff log that protects confidential client information.')
      $skills = @('Role-specific office software and records handling','Accuracy and verification','Scheduling and process coordination','Clear written handoffs','Confidentiality and authorization boundaries')
      $knowledge = @('The system of record for the task','Approval and escalation rules','Time zones, data quality, and access control')
    }
    'online-teaching-training' {
      $domain = 'learner level, measurable objectives, lesson sequencing, explanation, practice, feedback, accessibility, and assessment'
      $tasks = @("Plan a $title session around a measurable learner objective and a short diagnostic of learner level.",'Teach one concept with a worked example, guided practice, and an independent check that exposes likely misconceptions.','Adapt pacing and materials from learner evidence, then record the next step without promising an exam result or guaranteed progress.')
      $outputs = @("A $title lesson plan or learning resource with objectives, examples, practice, and an answer or feedback rubric.",'A short assessment or learner progress note tied to observable evidence.','Accessible teaching materials and a follow-up plan appropriate to the learner and subject.')
      $skills = @('Subject-matter accuracy','Instructional explanation and sequencing','Questioning and feedback','Assessment design','Online classroom and accessibility practice')
      $knowledge = @('Prerequisites and learner level','Common misconceptions in the subject','Assessment and accessibility constraints')
    }
    'software-testing-product-testing' {
      $domain = 'test design, environment setup, expected versus actual behavior, reproducibility, severity, regression checks, and user impact'
      $tasks = @("Design a $title test around an observable user or system risk, stating the setup, inputs, expected result, and pass/fail criteria.",'Run the test on the specified device, browser, build, or API; capture the smallest evidence that reproduces a failure.','Retest a fix and check nearby regression paths, recording environment and limitations so another tester can reproduce it.')
      $outputs = @("A $title test plan or executed test record with environment, steps, expected result, and observed result.",'A reproducible issue report with evidence, impact, severity rationale, and scope.','A regression or compatibility summary after a change, including untested combinations.')
      $skills = @('Test-case design and boundary coverage','Reproducible evidence collection','Device/browser/API-specific testing','Severity and user-impact judgment','Regression and clear bug reporting')
      $knowledge = @('Target platform and test environment','Acceptance criteria and risk-based coverage','Privacy-safe screenshots, logs, and test data')
    }
    'cybersecurity-bug-bounty' {
      $domain = 'written authorization, defined scope, threat modeling, safe security testing, vulnerability evidence, risk assessment, and responsible disclosure'
      $tasks = @("Confirm authorization, scope, excluded targets, and rules of engagement before any $title assessment activity.",'Use safe, non-destructive checks to validate a specific security hypothesis and retain only the evidence needed to prove impact.','Write a reproducible finding with affected asset, risk rationale, remediation direction, and disclosure or retest boundaries.')
      $outputs = @("A scope-limited $title assessment or report with reproducible and minimally sensitive evidence.",'A risk-ranked finding log that distinguishes verified vulnerabilities from observations and hypotheses.','A remediation and retest handoff conducted only with explicit authorization.')
      $skills = @('Security fundamentals for the target surface','Authorization and scope management','Safe evidence handling','Severity and impact analysis','Responsible disclosure and remediation writing')
      $knowledge = @('Rules of engagement and prohibited tests','Target-specific attack surface','Privacy, reporting, and legal boundaries')
    }
    'research-surveys-online-studies' {
      $domain = 'research question, sampling or eligibility, consent, method, source quality, participant privacy, evidence synthesis, and limitations'
      $tasks = @("For a $title assignment, follow the stated eligibility, consent, protocol, or research question before collecting or submitting information.",'Record observations or sources in the requested structure, distinguishing direct evidence, participant statements, and interpretation.','Check completeness, privacy, and method limitations; report uncertainty instead of filling gaps with invented data.')
      $outputs = @("A protocol-compliant $title submission, research log, or evidence summary in the requested format.",'A source or observation table with dates, selection criteria, and traceable evidence.','A limitation and privacy note identifying what the collected material cannot establish.')
      $skills = @('Research-method literacy','Eligibility, consent, and privacy awareness','Source evaluation and evidence logging','Structured data collection','Uncertainty and limitation reporting')
      $knowledge = @('Study or research protocol','Sampling and selection limitations','Consent, privacy, and data-retention requirements')
    }
    'digital-products-online-selling' {
      $domain = 'customer problem, product scope, source-file quality, compatibility, licensing, listing accuracy, delivery, support, and sales-channel terms'
      $tasks = @("Define the buyer and use case for a $title product, then build and test the deliverable in the formats the listing promises.",'Package editable/source and customer-ready files with clear setup instructions, version labels, and license terms.','Publish an accurate listing, test the purchase-to-delivery path, and handle feedback or defects without promising sales volume.')
      $outputs = @("A usable $title digital product with source files, customer-ready exports, and setup instructions.",'A product page that accurately states compatibility, included files, limitations, and license.','A delivery and support checklist covering version updates, refunds, and customer questions.')
      $skills = @('Product design and quality assurance','File packaging and compatibility testing','Customer-focused instructions','Marketplace listing and rights management','Basic product analytics without income guarantees')
      $knowledge = @('Buyer workflow and supported formats','Marketplace terms, licenses, and delivery','Product support and revision boundaries')
    }
    'customer-support-sales-community-management' {
      $domain = 'customer or community context, approved policies, clear communication, case records, escalation, consent, and outcome tracking'
      $tasks = @("Handle a $title case or interaction using approved policies, asking only for necessary information and recording the outcome accurately.",'Triage requests by urgency and ownership, resolve in-scope issues, and escalate exceptions without making unauthorized promises.','Review interaction records for follow-up, customer safety, policy compliance, and useful trend signals.')
      $outputs = @("A resolved or correctly escalated $title ticket, prospect record, moderation action, or recruiting handoff.",'A clear interaction note with next owner, due time, consent status, and unresolved question.','A recurring-issue summary that separates observed cases from broader claims.')
      $skills = @('Channel-appropriate writing and listening','Policy and process application','Accurate CRM or community records','De-escalation and prioritization','Privacy, consent, and escalation judgment')
      $knowledge = @('Approved service or community policy','Case ownership and escalation paths','Data minimization and respectful communication')
    }
    'specialized-professional-remote-services' {
      $domain = 'discipline-specific standards, scope, source or calculation accuracy, confidentiality, professional boundaries, and reviewable deliverables'
      $tasks = @("Clarify the $title engagement scope, jurisdiction or technical standard, source materials, review owner, and deliverable format before substantive work.",'Produce a traceable work product using the applicable professional method, checking calculations, citations, dimensions, or terminology as relevant.','Perform an independent quality pass and flag assumptions, missing records, jurisdiction limits, or decisions reserved for a licensed professional.')
      $outputs = @("A reviewable $title professional work product with cited inputs, assumptions, and version history.",'A source, calculation, drawing, or decision log that supports independent review.','A confidentiality-conscious handoff that flags qualifications, jurisdictional, or technical limitations.')
      $skills = @('Discipline-specific methods and terminology','Evidence, calculation, or technical-drawing accuracy','Quality review and traceability','Confidential handling of client data','Scope, licensure, and jurisdiction awareness')
      $knowledge = @('Applicable standards and jurisdiction','Primary sources or technical specifications','Professional review and confidentiality boundaries')
    }
  }

  if($roleSpecific){
    $domain = $roleSpecific.domain
    $tasks = $roleSpecific.tasks
    $outputs = $roleSpecific.outputs
    $skills = $roleSpecific.skills
  }
  $roleDeliverable = switch($category){
    'programming-software-development' { "A $title implementation package with runnable code, edge-case tests, setup instructions, and a deployment or rollback note." }
    'artificial-intelligence-ai-services' { "A $title workflow demo with evaluation examples, measured results, a failure log, and clear human-review boundaries." }
    'ai-training-data-annotation' { "A $title annotation or evaluation batch with rubric evidence, quality checks, and an ambiguity escalation record." }
    'writing-translation-localization' { "A $title language deliverable with a terminology or style note, source trail where relevant, and a revision-ready handoff." }
    'graphic-design-visual-content' { "A $title design package with editable source, export specifications, visual rationale, and asset-license notes." }
    'video-audio-media-production' { "A $title production package with a review-ready master, editable project assets, output specifications, and technical QC notes." }
    'marketing-social-media-ecommerce' { "A $title channel package with audience definition, approved assets, tracking setup, and a measured performance handoff." }
    'virtual-assistance-administrative-services' { "A $title operations handoff with approved records updated, an exception log, and a repeatable process checklist." }
    'online-teaching-training' { "A $title lesson pack with a measurable objective, worked example, learner practice, feedback rubric, and follow-up step." }
    'software-testing-product-testing' { "A $title test evidence pack with build and environment details, reproducible steps, expected versus actual behavior, and regression findings." }
    'cybersecurity-bug-bounty' { "A $title scoped security report with safe proof, impact and severity rationale, remediation, and an authorized retest plan." }
    'research-surveys-online-studies' { "A $title research record with method or eligibility notes, traceable observations, consent and privacy handling, and limitations." }
    'digital-products-online-selling' { "A $title listing and delivery package with tested files, compatibility and license notes, and customer setup instructions." }
    'customer-support-sales-community-management' { "A $title case handoff with consent-aware notes, next owner and action, resolution or escalation rationale, and follow-up status." }
    'specialized-professional-remote-services' { "A $title reviewed work product with assumptions, cited inputs, jurisdiction or technical boundaries, and a confidential handoff." }
    default { "A $title deliverable with documented quality checks, assumptions, and a recipient-ready handoff." }
  }
  $outputs = @($outputs + $roleDeliverable)
  # Avoid ungrammatical articles before role names such as AI, Arabic, and Online.
  $tasks = @($tasks | ForEach-Object { $_.Replace("a $title", "the $title") })
  $outputs = @($outputs | ForEach-Object { $_.Replace("a $title", "the $title").Replace("A $title", "A role-specific $title") })
  $related = @($s.relatedSpecializations | ForEach-Object { $specById[$_] } | Where-Object { $_ } | Select-Object -ExpandProperty title)
  $toolsAndPlatforms = @()
  if($relatedTools.Count){$toolsAndPlatforms += 'Tools currently linked in this directory: ' + ($relatedTools -join ', ') + '.'}
  else{$toolsAndPlatforms += 'No profession-specific tool mapping is currently recorded; identify tools from official documentation and state uncertainty.'}
  if($relatedPlatforms.Count){$toolsAndPlatforms += 'Platforms currently linked in this directory: ' + ($relatedPlatforms -join ', ') + '. Verify current eligibility, work availability, and payment for Egypt separately.'}
  else{$toolsAndPlatforms += 'No mapped platform is available in the current directory; do not invent an association or imply current work.'}
  $cautions = @('Confirm the actual brief, qualification, work model, and acceptance criteria; do not assume that a job title proves eligibility or demand.')
  if($category -eq 'cybersecurity-bug-bounty' -or $id -match 'pentest|bug-bounty|red-team|security-tester|vulnerability'){$cautions += 'Test only systems covered by explicit written authorization and scope; avoid destructive access, data exfiltration, persistence, and out-of-scope testing.'}
  if($category -eq 'research-surveys-online-studies' -or $id -match 'participant|survey|study'){$cautions += 'Follow consent and study rules, answer screeners honestly, protect participant privacy, and distinguish study compensation from guaranteed income.'}
  if($id -match 'legal|accountant|medical|financial|bookkeeper'){$cautions += 'Respect jurisdiction, licensing, confidentiality, and review requirements; do not present assistant work as independent regulated advice.'}
  if($id -match '^ai-|evaluator|annotation|llm|prompt'){$cautions += 'Check model limits, privacy, copyright, safety, and project rubric; never present generated output as verified fact without evidence.'}
  $cleanExistingSkills = @($g.keySkills | Where-Object { $_ -and ($_ -notin $genericTags) -and ($_ -notmatch '^(Requirements analysis|Quality control|Professional communication)$') })
  $allSkills = @($skills + $cleanExistingSkills | Select-Object -Unique | Select-Object -First 9)
  $g.professionContext = [string]$s.shortDescription
  Set-Field $g 'domainKnowledge' (@($domain) + @($knowledge))
  $g.typicalTasks = @($tasks)
  $g.commonDeliverables = @($outputs)
  $g.keySkills = @($allSkills)
  Set-Field $g 'relatedToolAndPlatformGuidance' @($toolsAndPlatforms)
  $g.distinctiveConsiderations = @("For $title, make the guide demonstrate the specific workflow and evidence expected in this role; distinguish it from nearby titles rather than treating it as generic remote work.")
  if($related.Count){$g.relatedRoleComparisons = @($related | Select-Object -First 5)}
  $g.learningPriorities = @("Learn the foundations in this order: $($knowledge -join '; ').", "Practice the $title workflow on a small, realistic brief and check the result against explicit acceptance criteria.", "Build evidence suited to the applicable work model; confirm related tools, platform rules, and Egypt eligibility before spending money or time.")
  $g.workModelNotes = "Verify each of these current classifications for $title against real listings or official work descriptions: $($s.workModels -join ', '). Explain which are common, occasional, or inappropriate; identify if the role is a task, study, employment, product, or regulated service rather than forcing a freelance-services model."
  $g.professionalCautions = @($cautions)
  $changed++
}

$json = ConvertTo-Json -InputObject $guides -Depth 40
[System.IO.File]::WriteAllText($guidePath, $json + [Environment]::NewLine, $utf8)
Write-Output "Updated role-specific guidance for $changed specialization records."
& (Join-Path $PSScriptRoot 'refine_profession_specific_guidance.ps1')
