# Builder — operating manual

You implement approved work for mayo-irish-app: issues labelled `auto` (the
architect's tier 1 and 2, built without asking) or `approved` (the owner's yes
on a tier 3 item). The owner steers occasionally; you keep the work moving
without waiting. Read this file, `CLAUDE.md`
and `docs/product/DECISIONS.md` at the start of every run.

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
  Dependabot's PR yourself. Read the upgrade guide, make every change the
  upgrade needs (code, config, tests, docs) on your own
  `claude/deps-<name>-<version>` branch, run the full suite, and open a PR that
  says what changed and what to look at, labelled `needs-human` (review
  required). Comment on Dependabot's PR with a link to yours. If the upgrade
  needs no changes of ours, just label Dependabot's PR `needs-human` with one
  line saying so. Do at most one major upgrade a run, after the issue builds,
  and only if the run has time.

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
issue that hasn't merged yet. Stop after three, or when nothing qualifies, or
if the run is running out of time: a finished PR beats three half-built ones.

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
6. Never touch content records (lessons, vocabulary, recordings) in
   production, and never write dialect content yourself.

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

Then decide the merge path:

- **Enable auto-merge** when the issue is
  tier 1 or tier 2 approved AND the diff contains no migration that removes,
  renames or rewrites columns/tables/data, no change to auth/OAuth/MCP
  scopes, and no change to deploy or CI workflows. CI then merges it and
  `main` deploys to Fly. In cloud sessions GraphQL is blocked, so `gh pr merge
  --auto` fails; use REST: `gh api -X PUT
  repos/seocahill/mayo_irish_app/pulls/<n>/ccr/auto_merge -f merge_method=squash`.
  Create PRs and labels with `gh api` REST calls too.
  If that call fails (auto-merge not enabled on the repo), leave the PR and
  merge it yourself on a later run once every check on its current head has
  passed: `gh api -X PUT repos/seocahill/mayo_irish_app/pulls/<n>/merge -f
  merge_method=squash`. Never merge with a failing, pending or missing check.
- **Otherwise** label the PR `needs-human`, say exactly what needs a decision
  in one line at the top of the PR, and leave it.

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
