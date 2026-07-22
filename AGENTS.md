# AGENTS.md

The command framework behind Discourse's `disco` CLI: a registry that applications and plugins add their commands to, the bootstrap that builds the Samovar command tree and boots Rails only for commands that need it, a command base class and an exception handler that prints presentable errors without a backtrace.

## Commands

- `bin/rspec`: run the specs
- `bin/lint`: autocorrect with RuboCop and format with Syntax Tree
- `bin/rubocop`, `bin/stree check '**/*.rb'`: check without changing files

## Gotchas

- **Samovar reserves `name` on commands.** `Nested#parse` instantiates a sub-command with `name:` (its invocation name), which Samovar stores and exposes as `name`. So don't declare a positional `one :name` on a command — when the argument is omitted the accessor silently reads back the command's own name instead of `nil`. Name the positional something else (`one :table_name, …`).
- **Samovar positionals are never required.** Don't use `one :x, required: true` — it raises during parsing, before `call` runs, which breaks the `-h/--help` handling. Leave positionals optional and validate them at the top of `call` with `require_positional!`; it raises a presentable error, so the user gets a clean message instead of a backtrace.
- **Don't give command groups a `-h/--help` option.** The option hoisting in `Command#parse` moves recognized flags to the front, so a group-level help option steals `--help` from the subcommands. Leave groups without options; a bare `group --help` surfaces as an unparsable token, which the bootstrap turns into usage with exit 0.

## Conventions

- Comments explain why, not what. No comments that describe history or code that was removed.
- No `module_function`, no endless methods, no `send`/`public_send` (RuboCop enforces this).
- Prefer `> 0` / `< 0` over `.positive?` / `.negative?`.
- Commit messages use Discourse's prefixes (`DEV:`, `FIX:`, `FEATURE:`, `PERF:`, `UX:`). Don't reference PRs, issues or commits of other repositories in commit messages or PR descriptions.
