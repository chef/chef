> [!IMPORTANT]
> This repo has not been onboarded to backstage yet; the directory and README have only been created to create the ADR in the proper place and add context for the developers/contributors

# Backstage - i360 - metadata & documentation

## Overview
This directory contains the files and directories used to send information to the i360 developer portal, including:
- `catalog-info.yaml` - i360 Developer Portal metadata file used for the service catalog.
- `./adrs` directory - hosts your Architectural Decision records.
- `./docs` directory - hosts your techdocs.
- `mkdocs.yml` - defines your techdocs config.
- `Makefile` - build and run your techdocs locally.

The purpose of each file and directory is described below.

## `catalog-info.yaml`
`catalog-info.yaml` is a simple text file placed in the `.i360` directory that formally introduces your code to Backstage (the i360 Developer Portal). It's the single source of truth that Backstage reads to answer the most critical questions about your service, such as:

- What is this? (A service, a library, a website?)
- Who owns this? (Which team is responsible for it?)
- How does it fit in? (What business domain does it belong to?)
- What does it depend on? (What databases, queues, or other resources does it need? What APIs does it consume?)
- What does it provide? (What APIs does it expose for others to use?)

The Backstage system is configured to continuously scan our GitHub organization for files named `catalog-info.yaml`. When it finds one, it ingests the YAML content, parses all the "entities" you've defined (like Components, APIs, or Resources), and then links them to the rest of the organization's components. This process is what builds the live, searchable graph of our entire software ecosystem in the developer portal.

The accuracy of this file is critical, as it directly impacts everything from incident response (who gets contacted) to architectural planning.

For specific formatting and examples, refer to the [i360 Developer Portal](https://backstage.infra360.org/catalog/default/component/backstage/docs) documentation.


## `./adrs`
The `.i360/adrs` directory is the designated place in your repository to store Architectural Decision Records (ADRs). An ADR is a short text file that captures a single, important architectural decision, along with its context and consequences. ADRs are your engineering logbook.

The `adrs` directory is the source of truth for answering questions for future developers (including your future self), such as:

- Why did we choose PostgreSQL over MySQL for this service?
- Why did we decide to use a REST API instead of GraphQL?
- Why did we select this specific caching strategy and not another?
- What other options did we consider, and why did we reject them?

Backstage is configured to automatically find, parse, and display these ADRs directly on your component's page in the developer portal. This makes your team's critical decisions and their trade-offs first-class citizens, visible to everyone in the organization.

The accuracy and consistency of these records are critical. They provide invaluable context for onboarding new engineers, prevent teams from re-litigating old decisions, and protect long-term architectural integrity.

Backstage accesses your ADRs through your `catalog-info` file, which contains a reference to the `adr-location` directory (which, in our case, is `adrs`):

```yaml
metadata:
  annotations:
    backstage.io/adr-location: adrs
```

See the `0001-use-adrs.md` section below for more information about the starter ADR in this directory.

## ./docs

The `.i360/docs` directory is the home for your service's TechDocs: the technical documentation that explains how to use, operate, and understand your component.

While the `adrs` directory explains the Why (architectural decisions), the `docs` directory explains the How. This is where you store your service's "how-to" manual. Content commonly includes:

- Getting Started Guides: How a new developer can run your service locally.
- Operational Runbooks: How to troubleshoot the service if it fails. What do the common alerts mean?
- API Tutorials: Practical examples of how to consume your service's API.
- In-depth Guides: Explanations of more complex features or internal logic.

This directory is the heart of the **Docs-like-Code** philosophy. Instead of writing documentation in separate, hard-to-find Wiki pages that quickly becomes stale, you write it in simple Markdown files that live in the same repository as your code.

This approach means your documentation is versioned in Git and can be updated as part of your normal development workflow. When a developer changes an API, they can update the corresponding documentation in the same Pull Request.

Backstage automatically finds, builds, and renders the contents of this docs directory into a searchable documentation site, which it displays directly on your component's page in the developer portal. By embracing this, we eliminate the need for separate Wiki pages and ensure our documentation stays as fresh and reliable as our code.

Backstage accesses your techdocs through your `catalog-info` file, which contains a reference to the `techdocs-ref` directory (which, in our case, is `dir:.`):

```yaml
metadata:
  annotations:
    backstage.io/techdocs-ref: dir:.
```

This syntax allows Backstage to read the `mkdocs.yml` file, which automatically searches `./docs` and compiles them into techdocs.

## mkdocs.yml
No changes are required to this file unless you want to have a custom docs navigation.

By default, the docs appear in the Table of Contents (TOC) navigation list in alphabetical order (although `index.md` appears first). If you want custom documentation ordering or nested topics, uncomment the following lines:

```yml
#nav:
#  - Getting Started: index.md
```

Then you can manually order every topic and also include nested topics, for example:

```yml
nav:
  - Getting Started: index.md
  - User Guide:
    - Writing your docs: writing-your-docs.md
    - Styling your docs: styling-your-docs.md
  - About:
    - License: license.md
    - Release Notes: release-notes.md

```

However, if you add documentation into `./docs`, the topic will not appear in the TOC until you reference it in `mkdocs.yml`.

Without the `nav` config defined, every topic added to `./docs` appears in the TOC automatically.

For more information, see the [mkdocs](https://www.mkdocs.org/user-guide/writing-your-docs/) documentation.


## Makefile
To build and run the documentation locally, ensure you have at least Python 3.5.

From the current directory, run the following in your command line:

```shell
# Install python dependencies
make install

# Run mkdocs with hot reload
make run
```

Limitations:

1. Do not add plugins (the docs will be rendered from inside the backstage portal, and may not have the plugin you added).
2. Do not change the theme (the docs will adopt the them of the backstage portal).

## `0001-use-adrs.md`
This file has been added to your `adrs` directory and serves as a template for future ADRs. It marks the decision to contribute data to the i360 Developer Portal.

ADRs can contain many sections to capture standardized data.  However, they are flexible enough to support just a small number of sections.

The ADRs "light" version recommends you include the following sections in every ADR:
- Metadata
- Title
- Context and Problem Statement
- Considered Options
- Decision Outcome
- Consequences
- More Information

Here's an template, which you can paste into your next ADR:

```markdown
---
status: Accepted        #{proposed | rejected | accepted | deprecated | superseded by }
date: 2025-10-28        #{YYYY-MM-DD} when the decision was last updated
deciders: name, name    #{list everyone involved in the decision}
consulted: Consulted    #{list subject-matter experts and those involved with two-way communication}
informed: Informed      #{list observers and those involved with one-way communication}

# ADR000: Title of ADR that conveys the problem solved and solution chosen

## Context and Problem Statement

Describes the context and problem statement in a few sentences. One may want to articulate the problem in form of a question or provide an illustrative story that invites to a conversation. Links to collaboration boards or issue management systems can go here too.

## Decision Drivers

Desired qualities, forces, faced concerns are identified here:

* {decision driver a}
* {decision driver a}

## Considered Options

This section lists the alternatives (or choices) investigated:

- {title/name of option x}
- {title/name of option y}
- {title/name of option z}

The template recommends listing the chosen option first (as a project-wide convention). One needs to make sure to list options that can solve the given problem in the given context (as documented in Section “Context and Problem Statement”).

## Decision Outcome

Here, the chosen option is referred to by its title. A justification should be given as well: {name of option 1} because {justification}. Some examples of justifications are: it is the only option that meets a certain k.o. criterion/decision driver; it resolves a particular force; it comes out best when comparing options. See this post for more valid arguments.

### Risks (or Consequences)

This section discusses how problem and solution space look like after the decision is made (and enforced).

Positive and negative consequences are listed as “Good, because …” and “Bad, because …”, respectively. An example for a positive consequence is an improvement of a desired quality. A negative consequence might be extra effort or risk during implementation.

## More Information

Here, one might want to provide additional evidence for the decision outcome (possibly including assumptions made) and/or document the team agreement on the decision (including the confidence level) and/or define how this decision should be realized and when it should be re-visited (the optional “Validation” section may also cover this aspect). Links to other decisions and resources might appear in this section as well.

More information about M-ADRs:
* [MADR](https://adr.github.io/madr/) 3.0.0 – The Markdown Any Decision Records
* [The Markdown ADR (MADR) Template Explained and Distilled](https://medium.com/olzzio/the-markdown-adr-madr-template-explained-and-distilled-b67603ec95bb) - another example (under "Example of Filled Out Template").
```


## FYI: How Your Documentation (TechDocs) Gets Published

This section explains how the techdocs content is automatically published to our S3 storage bucket and made visible in Backstage.

The key takeaway is that this process is fully automated via GitHub Actions. You don't need to build, compile, or upload anything. Your only job is to write your docs, make sure they are listed in the mkdocs.yml file (if using custom topic ordering), and merge them to the main branch.

**What You Do (The Simple Version)**
1. **Write Docs**: Make changes to your Markdown files inside the `.i360/docs/` directory.
2. **Update Navigation** (if you want to control how topics are ordered): When you add a new page, add it to the nav: section of your `.i360/mkdocs.yml` file.
3. **Merge to main**: When your pull request is merged, the automated workflow takes over.

That's it. Within a few minutes, your updated documentation will be live in Backstage.

**What's Happening in the Background (For Context)**

Your repository has a GitHub Action workflow (triggered by changes to `.i360/docs/` or `.i360/mkdocs.yml`) that automatically runs when you merge to main.

This workflow's job is to call our central, reusable publisher workflow (`techdocs-reusable.yml`) and provide it with two things:

1. Your Repo's Identity: It passes your repository's name as the entity-name.
2. AWS Secrets: It securely provides the AWS credentials needed to upload the built site. This are GitHub org-level secrets.

The central workflow then performs the build and publish steps:

1. Installs Tooling: It installs techdocs-cli and mkdocs.
2. Generates Site: It runs techdocs-cli generate to build a static HTML site from your Markdown files.
3. Publishes to S3: It runs techdocs-cli publish to upload the static site to the correct "folder" in our central `TECHDOCS_S3_BUCKET_NAME`. The exact path is determined by the entity name, resulting in a path like: `default/component/your-repo-name/`.

**What This Means For You as a Repo Owner**

- **No Wiki Pages**: You never have to visit a separate wiki site to update documentation. Your docs live with your code and are published automatically.
- **PRs for Docs**: You can (and should!) have your team review documentation changes in a Pull Request just like you review code.
- **No Publishing Delay**: Merging doc changes to a feature branch will not publish them. Only merging to main makes them live, so your production docs always match your production code.
- **Critical Naming Convention**: The system links your docs using your repository's name. For Backstage to find your docs, your GitHub repository name must match the `metadata.name` field in your `.i360/catalog-info.yaml` file.

The techdocs should just build and populate with your catalog entry. If your docs aren't appearing, contact the [i360tg](https://backstage.infra360.org/catalog/default/group/i360tg).
