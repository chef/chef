---
status: proposed              #{proposed | rejected | accepted | deprecated | … | superseded by [ADR-0005](0005-example.md)}
date: 2025-10-23              #{YYYY-MM-DD when the decision was last updated}
deciders: decider, decider    #{list everyone involved in the decision}
consulted: Consulted          #{list everyone whose opinions are sought (typically subject-matter experts); and with whom there is a two-way communication}
informed: Informed            #{list everyone who is kept up-to-date on progress; and with whom there is a one-way communication}
---
# ADR001: Adopt Markdown Architectural Decision Records (MADRs)

## Context and Problem Statement
Our engineering teams constantly make significant architectural decisions, including technology choices (e.g., databases, languages), patterns (e.g., REST vs. GraphQL), service boundaries, and infrastructure choices.

This critical "why" information is currently scattered and frequently lost. It lives in ephemeral Slack conversations, meeting notes, slide decks, wikis, or only in the memory of the original architects. This leads to several problems:

1. **"Decision Amnesia"**: Teams forget the original rationale for a decision, leading to wasted time re-litigating it or making changes that break hidden assumptions.
2. **Onboarding Friction**: New team members have no way to ramp up on the project's architectural history and must ask "why" repeatedly.
3. **Inconsistency**: Without a visible record, architectural patterns diverge across the organization, increasing complexity and maintenance costs.
4. **Low Visibility**: Decisions are not accessible to other teams, preventing knowledge sharing and cross-team alignment.

We need a lightweight, durable, and developer-friendly process to capture and share these critical decisions.

## Decision Drivers

- **Need for Durability**: Architectural rationale is lost in transient communication channels (Slack, Teams meetings).
- **Need for Discoverability**: Onboarding new engineers is slow and requires direct access to original architects.
- **Need for Consistency**: Lack of a formal record leads to pattern divergence and "decision amnesia."
- **Need for Integration**: Decisions should be co-located with the code they affect ("Docs-like-Code").
- **Need for Lightweight Process**: Any solution must have a low barrier to adoption to ensure developers use it.

## Considered Options
1. **Markdown ADRs (MADRs) in Git**
   - **Description**: Store lightweight Markdown files directly in the repository alongside the code.
   - **Pros**: "Docs-like-Code" (versioned, reviewable in PRs), highly discoverable by Backstage, low-friction (no special tools).
   - **Cons**: Requires developer discipline, can become stale if not maintained.

2. **Centralized Wiki (e.g., Confluence)**
   - **Description**: Create a central, dedicated space in a tool like Confluence for all ADRs.
   - **Pros**: Good search capabilities, non-technical users can access it easily.
   - **Cons**: High friction. Developers must leave their code editor. Becomes disconnected from the code's version history and is easily forgotten, leading to stale content.

3. **Status Quo (No Formal Process)**
   - **Description**: Continue capturing decisions informally in meeting notes, Slack, and wikis.
   - **Pros**: Zero friction or new process overhead.
   - **Cons**: Fails to solve any of the problems identified in the Context. This is the root of "decision amnesia" and onboarding friction.

## Decision Outcome
We will adopt the Markdown Architectural Decision Record (MADR) format as the standard for documenting all significant architectural decisions.

1. **Chosen Option**: Option 1, **Markdown ADRs (MADRs) in Git**, is the chosen solution.
2. **Storage**: ADRs will be stored as Markdown files (`.md`) in a dedicated directory within each repository, located at `/.i360/adrs/`.
3. **Format**: We will use the standard MADR template, which includes sections for Context, Decision (or the more detailed format used in this ADR), and Consequences.
4. **Scope**: An ADR must be created for any "significant" architectural decision. A decision is "significant" if it affects the system's non-functional requirements (e.g., security, performance, maintainability), dependencies, or key patterns, and is not easily reversed.
5. **Integration**: The Backstage developer portal will be configured to automatically discover, parse, and display the ADRs for each component, making them a visible and searchable part of our central documentation.

## Risks (or Consequences)
- **Cultural Change & Discipline**: The primary risk is adoption. Developers must build the habit of writing ADRs. This may be perceived as "extra work" or bureaucracy initially.
- **Maintenance Overhead**: If a decision is later reversed or superseded, a new ADR must be written to reflect that change to prevent the records from becoming stale and misleading.
  - Click-to-run tooling (like a template generator) may be needed to ensure consistent file naming (e.g., 001-short-title.md) and formatting.

## More Information

* [MADR](https://adr.github.io/madr/) 3.0.0 – The Markdown Any Decision Records
* [The Markdown ADR (MADR) Template Explained and Distilled](https://medium.com/olzzio/the-markdown-adr-madr-template-explained-and-distilled-b67603ec95bb)

