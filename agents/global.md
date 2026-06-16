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

## Git Safety

- Never run destructive git commands unless explicitly requested.
- Do not amend, squash, rebase, reset, force-push, or delete branches without
  confirmation unless I've explicitly told you to.
- Do not commit unrelated changes.
- Before creating commits, inspect `git status` and make sure the commit only
  includes intended files.
- Use clear commit messages that describe the change and its reason, but are not needlessly verbose.

## Branches, PRs, and Worktrees

- Prefix personal branches with `mshelley.`.
- For a single branch, use a descriptive name such as
  `mshelley.specific-branch`.
- For multiple related PRs, use the pattern
  `mshelley.[feature]/specific-branch`.
- For PRs that depend on each other, prefer stacked branches and stacked PRs.
- Keep stacked PRs narrow: each branch should have a coherent purpose and should
  be reviewable on its own relative to its parent.
- Default to working in a new worktree, unless I tell you otherwise. "Stacks" of PRs related to one feature can share the same worktree.
- Put repository worktrees under `~/programming/worktrees/[repo-name]/`.
- Whenever creating a new worktree for the valthos repository, run `make install` 

## Code Quality

- Prefer boring, maintainable code over clever abstractions.
- Avoid duplication.
- Add abstractions only when they remove real duplication, simplify meaningful
  complexity, or match an established local pattern.
- Prefer typed, structured APIs and parsers over ad hoc string manipulation when
  the project or standard toolchain provides them.
- Keep comments sparse and useful. Add them for non-obvious behavior, not for
  code that is already self-explanatory.
- Preserve API contracts and generated clients. When an OpenAPI or schema source
  changes, regenerate clients instead of hand-editing generated output.
- Write tests for core functionality. Do not write tests that don't change public behavior
  or important private behavior. For example, do not write tests to confirm that a logging
  line happens. Make tests concise where possible.
- Prefer clear classes to long, scattered methods in a large file.
- When working in the valthos repository, ensure you use the utils under python/valthos/utils when relevant.

## Dependencies and Tooling

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
