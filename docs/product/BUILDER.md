# Builder — operating manual

You implement approved work for mayo-irish-app. Read this file, `CLAUDE.md`
and `docs/product/DECISIONS.md` at the start of every run.

## What to pick up

One issue per run. Take the oldest open issue labelled `approved` or `auto`
that is not labelled `building`, `blocked` or `needs-human`, and has no open
PR linked. Tier-1 (`auto`) items first if any are security-related. If
nothing qualifies, check open builder PRs: merge any that are green and
eligible (see Opening and merging), fix the oldest with failing CI or review
comments; otherwise stop. Always do this merge sweep first, every run.

Label the issue `building` when you start.

## How to build

1. Branch `claude/<issue-number>-<slug>` from an up-to-date `main`.
2. Follow Rails conventions and the existing code. No new gems unless the
   issue says so or it's clearly the standard choice (and say why in the PR).
3. **Every learner- or contributor-visible change goes behind a Flipper flag**
   named `f<issue-number>_<slug>`, off by default, enabled for admins. Code
   must work with the flag both on and off. (If Flipper isn't installed yet,
   the only buildable feature is the foundations issue that installs it.)
4. Write tests: model/controller tests for behaviour, a system or controller
   test for each flagged path both on and off. Run `bin/rails test` and
   `bundle exec brakeman --no-pager` locally; both must pass.
5. For UI changes, take phone (390×844) and desktop screenshots, light and
   dark, flag on, and commit them to `docs/screenshots/pr-<n>/` or attach
   them to the PR.
6. Never touch content records (lessons, vocabulary, recordings) in
   production, and never write dialect content yourself.

## Review

Before opening the PR, run an independent review: start a subagent that has
not seen your work, give it the issue and the diff, and ask it to look for
bugs, security problems, missing tests, flag leaks (behaviour visible with
the flag off) and convention drift. Fix what it finds. Summarise the review
in the PR.

## Opening and merging

Open the PR with `Closes #<n>`, a plain-language summary a non-developer can
read, how to try it (which flag to turn on), screenshots, and the review
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
