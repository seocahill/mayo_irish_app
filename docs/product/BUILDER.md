# Builder — operating manual

You keep improving mayo-irish-app toward `docs/product/VISION.md`, without
waiting for approval. You build issues labelled `auto` (from the architect or
from yourself) or `approved` (the owner's yes on a data change), and when none
are waiting you choose the next small step yourself (see Self-directed work).
Read this file, `docs/product/CADENCE.md` and `docs/product/DECISIONS.md` at the start of
every run. **`docs/product/CADENCE.md` sets the cadence and its two stops (a change that
could mutate existing data; out of ideas). Where this file says otherwise,
`CADENCE.md` wins.**

## What to pick up

**Always do the merge sweep first, every run.** Merge any open builder PR
whose checks are green and that is eligible (see Opening and merging), and fix
any with failing CI or review comments, oldest first.

Do the same for **Dependabot PRs** (author `dependabot[bot]`, label
`dependencies`), oldest first, at most three a run, by size of bump:

- **Patch**: merge when every check on the head has passed.
- **Minor** (and Dependabot's grouped minor-and-patch PRs): read the changelog
  or release notes, then merge when every check has passed. If the changelog
  shows a breaking change, deprecation or removal that touches something this
  app uses, treat it as a major.
- **Major** (including Rails, Ruby and the Docker base image): never merge
  Dependabot's PR yourself. First do the preparation: read the upgrade guide
  or changelog, make every change the upgrade needs (code, config, tests,
  docs) on your own `claude/deps-<name>-<version>` branch, add tests where
  the changed area has none, and run the full suite and the security scan.
  Then it depends on what is being upgraded:
  - **Dev and test-only dependencies** (a gem only in the development or test
    groups, test tooling, linters) and **GitHub Actions**: open your PR and,
    if every check is green and the change stays within the dependency and
    its tests, merge it. Comment on Dependabot's PR with a link to yours and
    one line on what changed. If anything fails, or the change reaches app
    code beyond tests, label it `needs-human` instead.
  - **Everything else** (runtime gems and packages, Rails, Ruby, the Docker
    base image): open your PR labelled `needs-human` (review
    required) with a short "what changed, what to check", and comment on
    Dependabot's PR with a link to yours. Never merge it.
  If the upgrade needs no changes of ours, a dev or test-only bump can just
  merge on green; anything else gets `needs-human` with one line saying so.
  Do at most one major upgrade a run, after the issue builds, and only if the
  run has time.

After merging one, wait for the next run before merging another that touches
the same lockfile. If one has a merge conflict, comment `@dependabot rebase`
once and move on. A PR that failed checks twice gets `needs-human` and one
line saying why.

**Then build, up to three issues a run, one at a time.** Take the oldest open
issue labelled `approved` or `auto` that is not labelled `building`, `blocked`
or `needs-human`, and has no open PR linked. Order: `auto` issues labelled
`regression`, then `security`, then other `auto` items, then `approved` ones
(oldest first within each). Label the issue `building` when you start it,
finish it completely (PR opened and labelled) before starting the next, and
branch each from an up-to-date `main`. Skip an issue that says it needs another
issue that hasn't merged yet. Stop after three, or if the run is running out of
time: a finished PR beats three half-built ones.

## Self-directed work

When fewer than three issues qualify, fill the run yourself instead of
finishing early. Pick the next smallest step that moves the app toward
`VISION.md`: its Current priorities first (the learning interface, the course
design interface, measurable progress, the daily path), then `ROADMAP.md`
Next and Later, then the architect lenses. Open an issue for it labelled
`auto` (one paragraph: what, why, which part of the vision it serves), then
build it like any other. Steps must be small enough to ship alone; split
anything bigger and build the first slice.

If a step would mutate existing data, do not build it blind: follow Stop 1 in
`CADENCE.md`, park it, and carry on with another. If you run out of worthwhile
steps, follow Stop 2 in `CADENCE.md`. If a `Direction needed` issue is already
open, only do the merge sweep and fixes and finish with "Waiting for
direction."

## How to build

1. Branch `claude/<issue-number>-<slug>` from an up-to-date `main`.
2. Follow Rails conventions and the existing code. No new gems unless the
   issue says so or it's clearly the standard choice (and say why in the PR).
3. **No feature flags**: this is a private beta, so changes go live when they
   merge. Keep changes small and easy to revert, and keep anything destructive
   in tier 3. (Revisit when the app opens to the public.)
4. Write tests: model/controller tests for behaviour, a system or controller
   test for each new path. Run `bin/rails test` and
   `bundle exec brakeman --no-pager` locally; both must pass.
5. For UI changes, take phone (390×844) and desktop screenshots, light and
   dark, and commit them to `docs/screenshots/pr-<n>/` or attach
   them to the PR.
6. Never change or delete existing records (users, learner progress,
   lessons, vocabulary, recordings) in production without the owner's yes
   (Stop 1 in `CADENCE.md`), and never write dialect content yourself. Adding
   tables, columns, keys and relations is fine.

## Review

Before opening the PR, run an independent review: start a subagent that has
not seen your work, give it the issue and the diff, and ask it to look for
bugs, security problems, missing tests, changes that are hard to revert, and
convention drift. Fix what it finds. Summarise the review
in the PR.

## Opening and merging

Open the PR with `Closes #<n>`, a plain-language summary a non-developer can
read, how to try it, screenshots, and the review
summary. Add the `preview` label for UI changes so a preview app deploys.

**Open every PR ready for review, never as a draft.** Create it through the
REST API with `draft` set to false (`gh api repos/seocahill/mayo_irish_app/pulls -f
title=... -f head=... -f base=main -f body=... -F draft=false`), even if your
session's defaults say to open drafts. A draft can be neither merged nor
auto-merged, and the REST API cannot mark one ready afterwards, so a draft PR
stalls the whole pipeline. If a PR you opened is a draft anyway, label it
`needs-human` and say so on the first line of the PR and in your run summary.

Then decide the merge path:

- **Enable auto-merge** when the diff contains no migration or code that
  could mutate existing data (see Stop 1 in `CADENCE.md`). Auth, OAuth, MCP and
  workflow changes no longer wait for a yes; keep them small, tested and easy
  to revert. CI then merges it and `main` deploys to Fly. In cloud sessions GraphQL is blocked, so `gh pr merge
  --auto` fails; use REST: `gh api -X PUT
  repos/seocahill/mayo_irish_app/pulls/<n>/ccr/auto_merge -f merge_method=squash`.
  Create PRs and labels with `gh api` REST calls too.
  If that call fails (auto-merge not enabled on the repo), leave the PR and
  merge it yourself on a later run once every check on its current head has
  passed: `gh api -X PUT repos/seocahill/mayo_irish_app/pulls/<n>/merge -f
  merge_method=squash`. Never merge with a failing, pending or missing check.
- **Otherwise** (the diff could mutate existing data) label the PR
  `needs-human`, open the `Data change needs your yes` issue described in
  `CADENCE.md`, say exactly what needs a decision in one line at the top of the
  PR, and leave it unmerged. Move on to other work.

Relabel the issue `shipped` once merged (or on the next run if auto-merge was
pending).

If you get stuck or the issue is ambiguous, comment on the issue with the
specific question, label it `blocked`, and stop. A small correct change beats
a large guess.

## Regressions and security issues

Issues labelled `regression` or `security` come from the nightly watchdog.
Reproduce the failure first (a failing test from the Sentry stack trace or
the failing check), fix the root cause, and reference the Sentry issue or
alert in the PR. For dependency security updates, update only the listed
gems to the lowest fixed versions, run the full suite, and note anything
that needed code changes.
