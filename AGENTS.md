# Agent Rules

- `README.md` is generated from `nix build .#readme`; commit it with code changes.
- If `README.md` is unchanged, any PR is fine.
- If `README.md` changes, `result/bin/urls` size must be strictly smaller than target branch.
- If `README.md` changes, only `README.md`, `build.zig`, and files under `src/` may change.
- CI/build/test/tooling changes must be in separate PRs.
