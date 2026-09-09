---
name: form-text-history
description: Extract the user-visible text history of a published FyllUt form across a date range, including Bokmål source text, translations in its published languages, exact change dates, and a shareable HTML report. Use when someone asks what wording a form had, when wording changed, or whether a specific question changed.
---

# Trace user-visible form text

Build an evidence-based history of the text users could see in a published
FyllUt form. Treat the published form repository as the source of truth and use
the FyllUt renderer to decide which fields are visible.

## Inputs

Identify:

- the form number or path, such as `nav190105`
- the requested date range
- the requested languages, limited to languages the form was actually published for
- any wording or component the user wants investigated closely
- the requested report location and language

If the workspace contains several repositories, locate
`skjemautfylling-formio` and `skjemabygging-formio` rather than assuming paths.

## Establish the published timeline

In `skjemautfylling-formio`:

1. Find the form and translation files under `forms/` and `translations/`.
2. Read repository guidance before inspecting history.
3. List every commit in the requested interval that touches either file.
4. Include the last state before the interval as the baseline.
5. Pair form and translation commits that belong to the same publication. Use
   timestamps, commit messages, and their shared monorepo reference.
6. Find every publication of the global translation resources for languages
   the form was published for during the interval. Keep the ones that change a
   source string active in the form at that time, even when the form itself was
   not republished.
7. Record commit hashes, publication timestamps, and upstream monorepo
   references.

Use commit timestamps as the change dates unless repository data proves that
deployment or publication happened at another time. State which timestamp the
report uses.

## Decide what users could see

Inspect the FyllUt rendering and translation code in
`skjemabygging-formio`. Do not guess from property names alone.

At minimum, check how the renderer handles:

- form and page titles
- component labels and option labels
- descriptions, additional descriptions, tooltips, and placeholders
- content and alert components
- fieldset legends
- repeating-group controls such as `addAnother`
- attachment titles and upload instructions
- validation messages
- hidden labels, internal component labels, and builder-only metadata
- conditional components
- missing translations and language fallback

Record conditional text as user-visible with a condition. Exclude component
IDs, keys, scripts, conditional expressions, timestamps, author metadata, and
other implementation details unless the renderer displays them.

Walk the complete ancestor chain when classifying conditional text. A child is
conditional when it or any parent is hidden by a standard `conditional`,
`customConditional`, or `hidden` setting.

## Extract language versions

Treat the form definition as the Bokmål source. The top-level
`publishedLanguages` field in the form definition defines which languages are
published at each snapshot. Do not use `properties.publishedLanguages` or the
keys in the translation file for this decision. Resolve only published
languages through the exact translation keys used by FyllUt. Do not show an
unpublished language merely because a global translation resource has a value
for it.

For each form publication and relevant global-translation state:

1. Extract every user-visible Bokmål text by stable component key and field.
2. Resolve values for every language published in that snapshot.
3. Record missing translations and the renderer's actual fallback behavior for
   published languages only.
4. Keep HTML semantics that affect what the user reads, but normalize markup
   when comparing wording so formatting-only changes do not look like text
   changes.
5. Keep links when their URL or link text changed.

Track a text item by component identity and field, not by the Bokmål string
itself. A changed source string normally becomes a new translation key.
Resolve effective translations in the same precedence order as FyllUt. Local
form translations override global translations, and an unresolved key falls
back to the Bokmål source.

## Classify changes

For each consecutive publication state, classify differences as:

- wording added, removed, or replaced
- translation-only change
- link or formatting change that affects the rendered result
- technical change with no visible text effect
- unused translation entry added or removed

Do not count removal of an orphaned translation as a user-visible change.
Confirm that its source string was active in the form at that time.

Investigate any wording named by the user separately. Show its value in every
publication state and every language published in that state. Also follow conditional
components that reference the focused component, and show the complete history
of warnings, descriptions, or other text triggered by each answer. If Git
history contradicts the premise that the focus text or a dependent text
changed, say so directly and cite the relevant commits.

## Use the bundled generator

The skill includes
`scripts/generate-form-text-history.mjs`. Use it to create the report instead
of rebuilding the extraction logic for each form.

Run it with Node.js:

```sh
node <skill-directory>/scripts/generate-form-text-history.mjs \
  --form nav190105 \
  --from 2024-01-01 \
  --to 2024-12-31 \
  --repository /path/to/skjemautfylling-formio \
  --output /path/to/nav190105-teksthistorikk-2024.html \
  --focus "Vil du søke AFP fra privat sektor?"
```

Required options:

- `--form`: form path without the `.json` suffix
- `--from`: first date in the report, formatted as `YYYY-MM-DD`
- `--to`: last date in the report, formatted as `YYYY-MM-DD`

Optional options:

- `--repository`: path to `skjemautfylling-formio`; defaults to
  `./skjemautfylling-formio`
- `--output`: HTML destination; defaults to the current directory
- `--focus`: a Bokmål source text to feature at the top of the report
- `--ref`: Git ref to inspect; defaults to `HEAD`
- `--timezone`: IANA timezone used for commit times; defaults to `Europe/Oslo`

The generator discovers paired form and translation commits through their
shared monorepo reference. It also checks global Nynorsk and English resource
commits and keeps only changes that affected an active form text. Its report
text is Norwegian. Inspect the generated report and supplement the method
section if a repository version uses rendering rules the script does not yet
cover.

## Create the HTML report

Create one standalone HTML file that opens without a server or external assets.
Write it in the language requested by the user.

Include:

- scope, method, source repositories, and timestamp interpretation
- metrics at the top, followed by a concise summary of the actual content
  changes, such as wording replaced, text added or removed, and
  translation-only changes; do not make this a summary of publication or event
  counts
- a published-languages section after the content summary, listing the
  languages the form was published for at the start of the period and after
  every language-status change; state plainly whether the published language
  set changed
- a prominent answer about the specifically requested wording
- a chronological publication and change timeline
- global translation changes that affected the form without a form publication
- before-and-after text in every language actually published in each snapshot
- a searchable full inventory of all user-visible text during the interval
- filters for language, changed versus unchanged text, and form section
- visible markers for changed, unchanged, conditional, and missing translation
  states
- an explicit explanation when a translation key disappears and FyllUt shows
  the Bokmål source as fallback; never imply that the foreign-language
  translation itself contains Bokmål
- an explicit explanation when removing a form-specific translation reveals
  an already existing global translation; make clear that the displayed
  after-value was not added by the form translation commit
- commit links and abbreviated hashes; open repository links in a new tab with
  `rel="noopener noreferrer"`
- a short section for technical publications with no text change

Use semantic HTML, keyboard-accessible controls, sufficient contrast, printable
styles, and no network dependencies. Escape repository content before placing
it in HTML.

## Verify the result

Before finishing:

1. Re-run the commit queries and confirm every in-range form publication and
   relevant global-translation publication appears.
2. Compare every consecutive snapshot, including the baseline.
3. Confirm all active source strings have a documented value or fallback in
   every language published for that snapshot, and that no unpublished
   language appears in the report.
4. Search the report for the wording named by the user.
5. Parse or open the generated HTML and confirm navigation and filters work.
6. Report the file path and the main factual conclusion.
