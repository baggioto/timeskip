# 0002: TMDB as the data source

- Status: Accepted
- Date: 2026-11-17

## Context
The app needs real movie and TV data: trending lists, details, search, images and seasons/episodes. It should be free for a non-commercial project.

## Decision
Use the TMDB API (v3) with a read access token.

## Consequences
- Rich, real data with pagination, which is exactly what the feed and image cache need to be tested against.
- TMDB terms require attribution (their logo + notice in the app) and rate-limit-friendly usage, so caching matters.
- The token is a secret and must never be committed (see [0004](0004-secrets-out-of-git.md)).
