# Global Agent Instructions

These instructions apply across repositories and agents. Repo-local instructions
such as `AGENTS.md`, `CLAUDE.md`, or project-specific docs should be followed in
addition to this file.

## Instruction Precedence

Follow instructions in this order:

1. System, developer, and tool policies.
2. Repo-local instructions.
3. These global personal instructions.
4. Agent defaults.

If instructions conflict, prefer the higher-precedence source. If a lower-level
instruction would cause data loss, security risk, or production impact, stop and
ask before proceeding.

## Operating Principles

- Prefer small, reviewable changes with a clear behavioral purpose.
- Follow the repository's existing patterns, frameworks, and naming conventions.
- Do not rewrite unrelated code or perform broad refactors unless directly
  needed for the task.
- Treat uncommitted changes as user-owned unless you made them in the current
  task.
- Do not revert, overwrite, or remove user changes without explicit approval.
- Run relevant tests or checks before claiming work is complete. If checks cannot
  be run, say what was not run and why.
- Explain meaningful tradeoffs when choosing between viable approaches.
- Keep communication direct and practical. Prefer concrete status, decisions,
  and next steps over general commentary.
- If I just ask a question, then asnwer it and wait for me to respond before making changes.
- Treat PR follow-ups as incremental work; do not restart project-tracker or
  independent-verification workflows unless I explicitly request it for that follow-up.
- Validate against the PR's current remote base. Run focused checks and inspect
  CI; repeat passing checks only for relevant changes or new evidence.
- Explain substantial scope expansion before starting another expensive review cycle.

## Git Safety

- Never run destructive git commands unless explicitly requested.
- Rebasing and force-pushing with `--force-with-lease` are authorized for
  agent-managed PR branches when maintaining stacks. Never overwrite unrelated
  user work or force-push shared base branches.
- Do not commit unrelated changes.
- Use clear commit messages that describe the change and its reason, but are not needlessly verbose.

## Branches, PRs, and Worktrees

- Prefix personal branches with `mshelley.`.
- For a single branch, use a descriptive name such as
  `mshelley.specific-branch`.
- For multiple related PRs, use the pattern
  `mshelley.[feature]/specific-branch`.
- For PRs that depend on each other, prefer stacked branches and stacked PRs.
- Open PRs stacked on another PR in a GitHub stack as drafts, and keep them
  draft while based on that PR. PRs based directly on `main` may be non-draft.
- Prefer `gh stack rebase` and `gh stack push` for GitHub stacks; use manual Git
  only when a concrete CLI limitation requires it.
- DO NOT merge branches into each other when using github stacks. Github stacks requires linear history.
- Keep stacked PRs narrow: each branch should have a coherent purpose and should
  be reviewable on its own relative to its parent.
- Default to working in a new worktree, unless I tell you otherwise. "Stacks" of PRs related to one feature can share the same worktree, but aren't required to.
- Put repository worktrees under `~/programming/worktrees/[repo-name]/`.
- Whenever creating a new worktree for the valthos repository, run the focused
  setup targets matching the work: `make install-python`, `make install-frontend`,
  and/or `make install-infrastructure`. Combine targets when work spans areas. If
  the required focused target is unavailable on that revision, run `make install`.
- Whenever printing a reference to a PR number, make it a link to the PR, e.g.
  `[#123](https://github.com/[org]/[repo]/pull/123)`. This applies to chat
  responses, summaries, commit messages, and PR descriptions.

## Code Quality

- Prefer boring, maintainable code over clever abstractions.
- Avoid duplication.
- Prefer typed, structured APIs and parsers over ad hoc string manipulation when
  the project or standard toolchain provides them.
- Keep comments sparse and useful. Add them for non-obvious behavior, not for
  code that is already self-explanatory. You should still add simple docstrings for public methods.
- Preserve API contracts and generated clients. When an OpenAPI or schema source
  changes, regenerate clients instead of hand-editing generated output.
- Write tests for core functionality. Do not write tests that don't change public behavior
  or important private behavior. For example, do not write tests to confirm that a logging
  line happens. Make tests concise where possible.
- Prefer clear classes to long, scattered methods in a large file.
- Split long methods into smaller, more focused methods. Strive for human readability.
- When working in the valthos repository, ensure you use the utils under python/valthos/utils when relevant.

## Dependencies and Tooling

- Keep the computer responsive. Before starting CPU- or memory-heavy local
  checks, inspect running jobs across agents and worktrees; defer heavy work if
  another job is already consuming substantial resources.
- Run heavy lint, test, and build commands sequentially. Default to at most two
  workers per job and account for nested parallelism: a hook runner can launch
  multiple linters, each of which launches its own workers. Bound concurrency at
  every layer using documented controls; if that is not possible, use small
  sequential file batches or CI.
- In particular, do not run repository-wide `prek run -a actionlint` with default
  parallelism. Concurrent actionlint instances can each spawn many ShellCheck
  processes. Prefer checks scoped to changed files, and explicitly limit both
  hook-runner and linter concurrency when a full check is required.
- If a check causes a process explosion, memory pressure, or sustained swapping,
  stop the job you launched and rerun with lower concurrency. Do not terminate
  another agent's or the user's processes without permission.
- Prefer the repository's existing package manager and command wrappers.
- Do not add new dependencies unless they materially improve correctness,
  maintainability, or delivery speed.
- When adding a dependency, explain why the existing stack is insufficient.
- Avoid changing formatting, lint, build, or test configuration unless the task
  specifically requires it.

## Production and Security

- Do not remove TLS, authentication, authorization, tenant isolation, audit
  logging, or safety checks without explicit approval.
- Do not expose secrets, tokens, private keys, credentials, or sensitive customer
  data in code, logs, commits, or messages.
- Treat migrations, infrastructure changes, and production-impacting behavior as
  high-risk. Surface assumptions and validation steps clearly.
- For long-running or expensive operations, state the likely cost or runtime
  before starting when it is not obvious.

## Communication

- If a task is ambiguous but a reasonable low-risk assumption exists, proceed and
  state the assumption.
- Ask before proceeding when ambiguity could cause data loss, security issues,
  production impact, or substantial wasted work.
- When work is complete, summarize what changed, what was checked, and any
  remaining risks or follow-up steps.
