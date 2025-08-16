# GitInsight Commit Guidelines

To maintain a clean, readable, and useful commit history, all contributions to GitInsight should follow these guidelines. Adhering to these conventions helps in understanding changes, generating changelogs, and automating release processes.

## Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. This standard provides a lightweight convention on top of commit messages. It defines a set of rules for creating an explicit commit history, which makes it easier to write automated tools on top of it.

Each commit message consists of a **header**, a **body**, and a **footer**.

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Header

The header is mandatory and must conform to the following format:

`<type>[optional scope]: <description>`

#### Type

The `type` is a mandatory field and must be one of the following:

*   **feat**: A new feature
*   **fix**: A bug fix
*   **docs**: Documentation only changes
*   **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semicolons, etc.)
*   **refactor**: A code change that neither fixes a bug nor adds a feature
*   **perf**: A code change that improves performance
*   **test**: Adding missing tests or correcting existing tests
*   **build**: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
*   **ci**: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
*   **chore**: Other changes that don't modify src or test files
*   **revert**: Reverts a previous commit

#### Scope

The `scope` is an optional field that describes the part of the codebase affected by the commit. Examples include `frontend`, `backend`, `docs`, `auth`, `api`, `database`, `ci`, etc. If the change affects multiple parts, you can omit the scope.

#### Description

The `description` is a mandatory, concise summary of the change. It should:

*   Use the imperative, present tense: "change" not "changed" nor "changes".
*   Not capitalize the first letter.
*   Not end with a period.

### Body (Optional)

The body should provide additional contextual information about the code changes. It should:

*   Use the imperative, present tense: "fix" not "fixed".
*   Include the motivation for the change and contrast it with previous behavior.
*   Wrap at 72 characters.

### Footer (Optional)

The footer can contain information about breaking changes and reference issues that this commit closes.

#### Breaking Changes

A breaking change should be indicated by `BREAKING CHANGE:` at the beginning of the footer, followed by a space and a description of the change, justification, and migration instructions.

#### Referencing Issues

Closed issues should be listed in the footer with `Closes #<issue-number>` or `Fixes #<issue-number>`.

## Examples

```
feat(frontend): add user profile page

This commit introduces a new user profile page where users can view and edit their personal information.

Closes #123
```

```
fix(backend): correct database connection error

Previously, the database connection would occasionally drop due to an unhandled exception during high load. This fix implements a robust retry mechanism and proper error logging.

BREAKING CHANGE: Database connection string format has changed. Refer to updated `setup.md`.
```

```
docs: update contributing guidelines

Reflects new commit message conventions.
```

By following these guidelines, we ensure a consistent and understandable commit history for GitInsight.