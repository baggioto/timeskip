# 0004: Keep API secrets out of git

- Status: Accepted
- Date: 2026-11-17

## Context
A token committed to a repository is effectively public, even if the repo is private today and the commit is later removed: history, forks and caches keep it.

## Decision
- The TMDB token lives in a local `Secrets.xcconfig`, listed in `.gitignore`.
- The repo ships a `Secrets.example.xcconfig` with a placeholder.
- Unit tests never hit the real API, so CI needs no token. If integration tests are added later, CI gets the token from a GitHub Actions secret.

## Consequences
- New contributors copy the example file and add their own token.
- Note: a token bundled in an app binary can still be extracted. For a real product the calls would go through a backend proxy; for a portfolio app, keeping it out of git is the realistic bar.
