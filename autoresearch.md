# Autoresearch: pi-mono vs OMP ecosystem comparison

## Objective
Produce a better-supported recommendation about whether to keep using Oh My Pi (OMP) with local compatibility patches or to switch to pi-mono as the base and port desired OMP features on top.

The work focuses on current upstream reality, not brand preference:
- recent maintenance activity
- plugin ecosystem compatibility
- evidence of fixes landing upstream
- signs of namespace drift or ecosystem fragmentation
- practical cost of carrying downstream patches

## Metrics
- Primary: `primary_sources` (count, higher is better)
- Secondary: `fresh_sources_90d`, `official_sources`, `plugin_signals`, `omp_patch_surface`

The metric is a bookkeeping aid only. Final conclusions must be driven by source quality and substance, not by maximizing counts.

## How to Run
`./autoresearch.sh` — validates the current source inventory and prints `METRIC primary_sources=<n>`.

## Files in Scope
- `autoresearch.md` — research objective, constraints, findings backlog
- `autoresearch.sh` — lightweight validation/count script for the evidence inventory
- `autoresearch.sources.txt` — one source URL per line, comments allowed with `#`
- `autoresearch.ideas.md` — deferred research leads or follow-up questions

## Off Limits
- Do not modify OMP runtime code or plugin code as part of this research
- Do not manufacture evidence from secondary summaries when primary sources exist
- Do not let the metric replace judgment

## Constraints
- Prefer primary sources: official GitHub repos, changelogs, releases, maintainers' issues/PRs, package metadata
- Search public web sources for broader signals, including X/Twitter only if surfaced via search and corroborated elsewhere
- Use current evidence, especially activity from the last 30-90 days when available
- Treat plugin compatibility as more important than cosmetic feature differences
- Be explicit about uncertainty where evidence is incomplete

## What's Been Tried
- Initialized session and defined a research-oriented metric based on validated primary-source inventory.

- Collected 30 current primary sources covering pi-mono, OMP, and key plugins (pi-multi-pass, pi-design-deck, pi-autoresearch).
- Verified that pi-mono is actively shipping extension/plugin-facing changes in recent releases (0.57.x through 0.62.0), including breaking changes and fast follow-up fixes.
- Verified that OMP is also actively developed, with 13.14.x released on 2026-03-21 and 13.15.0 changes already in changelog/commits on 2026-03-23.
- Verified ecosystem alignment risk: third-party plugins and plugin examples still target `@mariozechner/*` packages or pi-mono semantics, while local OMP usage requires compatibility patch scripts and runtime rewrites.
- Verified that public X/Twitter search produced little durable signal; GitHub and package metadata are the authoritative evidence base for this comparison.
- Verified package publication split: pi-mono currently publishes `@mariozechner/pi-coding-agent@0.62.0`, while OMP publishes `@oh-my-pi/pi-coding-agent@13.14.2`; third-party plugin sources examined still import the former namespace or assume pi-mono extension semantics.
- Verified GSD-2 is not a drop-in OMP plugin: it is a standalone CLI built on the Pi SDK with its own `@gsd/*` package namespace, Node >=22 runtime, bundled resource sync, `.gsd/` state machine, and internal extension package under `src/resources/extensions/gsd/`.