# Product

## Register

brand

## Users

Developers arriving from GitHub, Hacker News, or a colleague's link. They are Claude Code power users who already feel the pain: juggling personal, work, and client accounts on one machine, logging in and out, clobbering credentials. Skeptical of marketing, allergic to fluff, fluent in the shell. They skim; they judge a tool by its README and its first command. Success: they copy the install command and run it.

## Product Purpose

ccenv runs multiple Claude Code accounts on one machine, concurrently. One account per terminal, switch in a keystroke, no clobbering. It stores zero secrets (tokens stay in the OS credential store, managed by Claude Code), inherits the user's existing plugins/skills/hooks, and requires no migration: the current login is already profile `default`. The site exists to convince this audience in under a minute and hand them the install command.

## Brand Personality

Sharp, terminal-honest, engineered. The voice of someone who lives in the shell and respects the reader's time. Dry wit allowed, never forced. Reference feel: Tailscale / WireGuard, engineering credibility and calm authority, claims stated plainly and backed by mechanism, not adjectives.

## Anti-references

- The SaaS landing template: gradient hero, three identical feature cards, testimonial wall, pricing table, "Get started free" buttons. None of that applies to a free MIT shell tool.
- Marketing superlatives ("blazingly fast", "supercharge your workflow").
- Fake urgency, newsletter popups, cookie-consent theater on a static page.

## Design Principles

1. **Show the tool, not adjectives.** Real terminal output is the hero. `ccenv list` with its status dots says more than any tagline.
2. **The install command is the CTA.** A copy-paste path to a working install appears in the first screen; everything else is supporting evidence.
3. **Mechanism earns trust.** Explain how it works (config dirs, credential store, symlink vs copy) the way the README does: plainly, specifically. This audience trusts explanations, not badges.
4. **Every claim is demonstrable.** Features are shown as actual commands and their output, never as icon + blurb.
5. **One minute to decision.** Structure for the skimmer: pitch, proof, install, mechanism, security. No section exists to fill space.

## Accessibility & Inclusion

WCAG 2.1 AA: contrast ratios met, full keyboard navigability, visible focus states, semantic landmarks. `prefers-reduced-motion` honored; any animation is decorative-only and disabled under it. Terminal snippets are real text (selectable, screen-reader legible), never images.
