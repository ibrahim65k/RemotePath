# Content Schema

All files under data/ are UTF-8 JSON arrays. IDs and slugs are globally unique within their collection, permanent after publication, and lowercase kebab-case. Use IDs for relationships instead of titles. Do not rely on display names as keys.

## Categories — categories.json
Fields: id and slug (stable URL identifier), name (English category title), description (concise scope), icon (coherent text/SVG glyph), specializationCount (derived total, checked against specializations.json).

Actual record example:

    {"id":"programming-software-development","slug":"programming-software-development","name":"Programming & Software Development","icon":"</>","description":"Build websites, apps, and software systems for a connected world.","specializationCount":21}

## Specializations — specializations.json
One record per canonical profession. Fields:
- id: globally unique permanent identifier; currently the normalized slug.
- slug: globally unique route segment used with specialization.html?slug=...
- title: clear English job title.
- categoryId: required primary category ID; each role belongs to exactly one category.
- shortDescription: specific 20–45 word English summary of the work and its output.
- tags: relevant labels selected from a consistent vocabulary, including Technical, Creative, Language-Based, Administrative, Specialized, Client-Based, Task-Based, Skill-Based, and Product-Based. Tags do not promise entry-level suitability.
- workModels: array of applicable identifiers: freelancing, microtasks, project-based, remote-contracts, part-time-remote, full-time-remote, commission-based, digital-products, online-teaching, consulting. Classifications describe possible work structures, not job availability.
- relatedSpecializations: array of canonical specialization IDs; use this for meaningful cross-references and do not duplicate records.
- prompt: retained as null for backward compatibility; Phase 03 generates the final standalone prompt from the canonical role ID and its prompt-guidance record. Do not store a duplicated master prompt here.

Actual record example (prompt is intentionally null because the prompt builder composes it at runtime):

    {"id":"frontend-developer","slug":"frontend-developer","title":"Frontend Developer","categoryId":"programming-software-development","shortDescription":"Builds the visual and interactive parts of websites and web applications, translating interface designs into responsive pages with browser-based technologies.","tags":["Technical","Skill-Based","Client-Based"],"workModels":["freelancing","remote-contracts","project-based","full-time-remote"],"relatedSpecializations":["full-stack-developer","ui-designer"],"prompt":null}

## Platforms — platforms.json
See the Phase 03 schema below. It contains 51 canonical platform records, with Egypt registration, project, and payment states tracked separately.

## Tools — tools.json
See the Phase 03 schema below. It contains 68 canonical tool records linked to their relevant categories and specializations.

## Work models — work-models.json
An empty array is retained for compatibility. Work model identifiers are currently stored on specialization records as documented above. A later phase may define a normalized lookup collection without changing specialization references.

## Relationships and routing
Each specialization has one primary category through categoryId. Related roles use relatedSpecializations IDs, including distinct AI red-team roles in Categories 03 and 11, and distinct search-evaluation roles in Categories 03 and 12. Category URLs use category.html?slug=...; role URLs use specialization.html?slug=.... Use URLSearchParams and encodeURIComponent for query values. Full job explainers remain outside the website.


## Phase 03 — Prompt guidance

`prompt-guidance.json` is an array with exactly one record per specialization. The prompt-facing fields are:

- `professionContext`, `categoryContext`: the canonical role description and its primary field.
- `typicalTasks`: concrete actions performed in the role, not general employability advice.
- `commonDeliverables`: actual client outputs, participation evidence, or task submissions. Do not force non-client work into a freelance deliverable model.
- `keySkills`: practical capabilities needed to perform this specific role. Foundational skills can overlap when the work genuinely overlaps.
- `domainKnowledge`: the technical or professional subject matter an instructor must explain accurately. Avoid universal placeholders such as “data flow and error handling” for unrelated roles.
- `distinctiveConsiderations`: what differentiates the role, its real workflow, common misconceptions, and what a teacher should emphasize.
- `professionalCautions`: actual legal, ethical, safety, privacy, confidentiality, licensing, authorization, copyright, or jurisdiction boundaries. Do not use this field as a replacement for role distinctions and do not invent cautions.
- `learningPriorities`: an ordered, practical learning route tied to the role’s knowledge, tasks, and evidence of progress.
- `workModelNotes`: role-specific work structures to verify against current listings or official descriptions; this is not proof of availability.
- `relatedRoleComparisons`: genuinely adjacent role names, when useful. An empty array is valid when no strong comparison exists.
- `relatedToolAndPlatformGuidance`: names already linked in the directories with instructions to verify relevance, current eligibility, project availability, and payment separately.
- `id`: stable `specializationId` plus `-learning-guide`; `specializationId` is the foreign key.

`assets/js/prompt-builder.js` combines every non-empty field into a complete standalone English prompt. It labels `distinctiveConsiderations` and `professionalCautions` in separate sections and repeats the supplied cautions in the shared professional-responsibility instructions. Optional or malformed values are replaced by clear role-specific research instructions; JSON syntax, `undefined`, `null`, and object representations must not leak into the prompt. The shared teaching requirements preserve Egyptian colloquial Arabic (Masri) explanations while keeping English technical terms intact. Run `scripts/validate_generated_prompts.ps1` to use Edge and the actual browser prompt builder against every current specialization; it also checks missing-field behavior and selected caution-heavy roles.

## Platforms — platforms.json

Required fields: `id`, `slug`, `name`, `description`, `platformTypes` (array), `workModels` (array), `categoryIds`, `specializationIds`, `officialWebsite`, `registrationUrl`, `egyptAvailability`, `feesAndWithdrawals`, and `verification`. `egyptAvailability` has independent `registrationEligibility`, `currentProjectAvailability`, and `paymentAccessibility` values, plus explanatory `notes`. Each value is one of `verified`, `conditional`, `unconfirmed`, or `not-available`. `verification.status` describes evidence quality; `lastVerified` may be null. `verification.sources[]` has `title`, `url`, `sourceType`, `accessedAt` (null when not actually checked), and `supports`. Website purpose evidence does not establish Egypt access or an active vacancy.

Sample: `{"id":"prolific","slug":"prolific","platformTypes":["research-studies"],"categoryIds":["research-surveys-online-studies"],"specializationIds":["online-survey-participant"],"egyptAvailability":{"registrationEligibility":"verified","currentProjectAvailability":"conditional","paymentAccessibility":"unconfirmed","notes":"Study matching and payout usability remain separate checks."}}`.

## Tools — tools.json

Required fields: `id`, `slug`, `name`, `description`, `toolCategory`, `categoryId`, `categoryIds`, `specializationIds`, `toolType`, `pricingModel`, `pricingNote`, `platformSupport`, `beginnerFriendly`, `alternatives`, `officialWebsite`, and `verification`. Pricing values include `free`, `freemium`, `paid`, `open-source`, `usage-based`, and `unconfirmed`. Use `unconfirmed` if current terms were not verified; do not infer that a trial is a free plan. Tool-to-role relationships use canonical specialization IDs, not duplicate tool records.

## Global search index (derived at runtime)

Search does not add duplicated catalog records. It builds index entries from categories.json, specializations.json, platforms.json, and tools.json. Each entry contains kind, canonical ID, title, description, destination URL, category IDs/names, searchable normalized fields, and aliases defined in assets/js/search.js. Search filters accept a kind and optional category ID. Keep aliases tied to canonical IDs and avoid putting unsupported eligibility claims into alias or descriptive text.
