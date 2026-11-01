# Global Agent Instructions

Follow repo-local conventions over these personal defaults.

## Working Style

- When I ask a question, answer it without making changes unless requested.
- Keep changes focused and follow existing repo patterns. Avoid unrelated refactors.
- Proceed on reasonable, low-risk assumptions and state them. Ask when ambiguity
  could cause data loss, security issues, production impact, or substantial wasted work.
- Keep communication concise and concrete. Explain meaningful tradeoffs.

## Ownership and Safety

- Treat existing uncommitted changes as user-owned. Preserve them unless explicitly
  authorized to change or remove them.
- Ask before destructive Git operations.
- Commit only changes belonging to the task. Use concise, descriptive commit messages.
- Preserve authentication, authorization, tenant isolation, TLS, audit logging,
  and other security controls unless changes are explicitly approved.
- Keep secrets and sensitive customer data out of logs, commits, and messages.
- Surface production-impacting assumptions and validation plans before making changes.

## Branches and Worktrees

- Prefix personal branches with `mshelley.`.
- For repository code changes, default to a new worktree under
  `~/programming/worktrees/[repo-name]/`. Reuse the current worktree when I explicitly
  ask to continue existing work; related stacked PRs may share a worktree.
- Link PR references in chat and PR descriptions.

## Validation and Resources

- Run relevant, focused checks before declaring work complete. Report checks
  not run and why.
- Test behavior and contracts rather than incidental implementation details.
- For PR follow-ups, validate the delta against the current remote base and CI.
  Restart broader review workflows only when requested or justified by new evidence.
- Before heavy local checks, inspect competing jobs. Run heavy checks sequentially
  with at most two workers per job, including nested parallelism.
- Explain substantial increases in scope, runtime, or cost before proceeding.

## Dependencies and Completion

- Use existing package managers and command wrappers. Justify new dependencies;
  avoid unrelated formatting, lint, build, or test configuration changes.
- Finish with a brief summary of changes, validation, and remaining risks or blockers.
