---
status: proposed
date: 2025-11-12
decision-makers: Progress Chef Architecture, project owner
consulted: Product Management, Legal & Licensing, Release Engineering, project advisor
informed: Engineering, Support, Marketing, Partner Enablement, Community, contributors, reviewers, approver	Final approval and acceptance of contributions
---

# Establishing Distribution Classifications and Licensing Enforcement Boundaries

## Context and Problem Statement
Progress Chef is formalizing a consistent model for how software is **distributed**, **licensed**, and **enforced** across the Chef ecosystem. This model is essential for maintaining clear compliance boundaries, ensuring predictable user experiences, and aligning with Progress’s open-core strategy.

A **distribution** defines *how and from where* Chef software is packaged, signed, and made accessible. Examples include **official Progress-managed distributions** (e.g., Progress Artifactory, Progress Download APIs, Habitat Builder, or Chef 360 SaaS) and **unofficial sources** (e.g., RubyGems.org, community mirrors, or downstream forks). Each distribution carries distinct **delivery requirements/expectations**, **enforcement behaviors**, and may have distinct **end user license agreements**.

A **license**, in contrast, defines the *right to use* and the *scope of functionality* within that distribution—such as **commercial**, **trial**, **community**, or **free** usage. Importantly, this is not a *software source code license* (e.g., Apache 2.0 or GPL); it represents a **usage entitlement** that determines what features, durations, and integrations are available to the user. For example, a commercial distribution might allow execution without a license key but unlock additional features when one is provided, while a trial distribution may enforce license activation and duration limits at runtime.

Licenses may or may not be **enforced**, depending on the distribution type. Similarly, a distribution may be **eligible only for certain license types** and may **behave differently** based on which license is active. For instance:

* An **official commercial** distribution obtained via the Progress download API allows optional license entry for premium feature unlocks but does not require license validation during every client run.
* An **official trial** distribution requires a license to activate and enforces expiration during execution.
* An **unofficial RubyGems.org** distribution requires a valid Progress-issued license for activation or a license server connection unless it has been explicitly packaged as a sanctioned (e.g. trademarks removed, ...) downstream distribution.

At present, this distinction between **distribution origin** and **license enforcement** is inconsistently represented across Chef products. For example, *InSpec 6* enforces license validation on every execution, while tools such as *Chef Infra Client 18*, *Test Kitchen*, and *Knife* execute without requiring a license (or supporting the addition of one). Similarly, *Habitat* and *Artifactory* distributions may include internal access (download) enforcement mechanisms, whereas RubyGems.org packages do not. These inconsistencies create ambiguity for customers, internal compliance systems, and downstream partners—particularly in identifying which installations are **official**, which require **license enforcement**, and which can **operate freely**.

### Intent and Scope
The intent of this decision is **not to implement a Digital Rights Management (DRM) system** or introduce restrictive access controls. Rather, the objective is to **prevent accidental misuse, unintentional access to restricted software, and misalignment with applicable End User License Agreements (EULAs)**.

This model provides a transparent and auditable way to distinguish between official and unofficial distributions, ensuring that users, partners, and automation systems interact with Chef software in a manner consistent with its intended license terms. Enforcement mechanisms are designed to **guide and inform**, not to obstruct legitimate usage, open-source contribution, or integration within authorized environments.

To address this, Progress Chef will establish a unified mechanism that:

1. **Defines authoritative official distribution sources** (Progress Artifactory, Habitat Builder, and Chef 360 SaaS).
2. **Identifies distribution type** at build and runtime (e.g., official, community, unofficial, downstream).
3. **Defines license eligibility and enforcement behavior** per distribution type (e.g., optional, required at activation, enforced at runtime).
4. **Ensures consistent enforcement via the `chef-licensing` library** without hindering open client execution.
5. **Prevents misrepresentation or misuse** of unofficial or third-party distributions as official Progress releases.

This architecture must enable differentiated enforcement for commercial, trial, community, and free licenses—supporting flexible use cases while preserving compliance, auditability, and customer clarity.

## Decision Drivers

* Need for consistent licensing enforcement across multiple distribution channels.
* Requirement to differentiate official vs. unofficial package sources.
* Desire to keep client execution (e.g., Chef Infra Client, InSpec, Knife) license-optional.
* Support for community engagement without diluting commercial value.
* Alignment with Progress’s open-core and licensing strategy.
* **Customer-driven need to walk back the InSpec 6 runtime license enforcement model**, addressing concerns that strict runtime checks can prevent critical patching, compliance scans, or other essential executions in production environments.

## Considered Options

### **Group A: Distribution Classification and Access Controls**

* **Option A1 – Define Three Distribution Classes: Commercial, Official, and Unofficial**
  Establish a formal hierarchy of distribution classes to clarify access, authenticity, and compliance expectations:

  * **Commercial** distributions are a unique subset of **Official** distributions, representing paid or premium editions that may include additional features or service entitlements.
  * **Official** distributions include all Progress-managed public releases (e.g., Community or Free editions) distributed through trusted channels such as Progress Artifactory, Habitat Builder, or Chef 360 SaaS.
  * **Unofficial** distributions are externally sourced or community-provided builds (e.g., RubyGems.org or forks) that are not published by Progress and therefore must validate authenticity and enforce license requirements more strictly.

  This approach creates clear separation between how software is **accessed and trusted** versus how it is **licensed and entitled**. It supports multiple legitimate pathways—commercial, community, and open source—while ensuring transparency and auditability across all.

* **Option A2 – Treat All Distributions Uniformly**
  Eliminate distinctions between Commercial, Official, and Unofficial channels, allowing all products to be distributed identically and relying solely on license enforcement to determine entitlement.
  This simplifies packaging and delivery but erases clarity around authenticity, support, and EULA applicability.

* **Option A3 – Restrict Distribution to Progress-Managed Channels Only**
  Eliminate public or community distribution points (such as RubyGems.org) and centralize all access within Progress infrastructure.
  This provides strict control and compliance assurance but would significantly reduce community accessibility, break open-source adoption workflows, and conflict with the open-core model.

### **Group B: License Requirements and Enforcement Behavior**

* **Option B1 – Adaptive Enforcement Based on Distribution Class**
  Implement license enforcement policies that adjust dynamically by distribution type:

  * **Commercial** distributions may include **optional** license enforcement to unlock premium features or telemetry-based integrations.
  * **Official** (non-commercial) distributions may perform **lightweight** or **advisory** validation to confirm authenticity or collect usage telemetry.
  * **Unofficial** distributions require a valid Progress-issued license or connection to a license service for activation unless explicitly approved as a downstream.

  This provides the right balance between compliance, user flexibility, and operational reliability.

* **Option B2 – Global Runtime Enforcement**
  Require license validation at every execution across all distributions and product types (similar to InSpec 6).
  This ensures strict compliance but risks disrupting automation and customer trust.

* **Option B3 – No License Enforcement**
  Disable all runtime enforcement and rely only on download or EULA acceptance as implicit license acknowledgment.
  This reduces compliance complexity but removes Progress’s ability to differentiate entitlements or manage premium content access.

## Decision Outcome

Progress Chef will formalize **three distribution classes** — **Commercial**, **Official**, and **Unofficial** — with corresponding, context-aware license enforcement modes.

In this model:

* **Commercial** distributions are a *unique subset of Official distributions*, representing paid or premium editions that may include optional or required license enforcement for access to enhanced capabilities, integrations, or services.
* **Official** distributions represent all Progress-managed public releases (including Community or Free editions) that are signed, verifiable, and accessible through trusted channels such as Progress Artifactory, Habitat Builder, or Chef 360.
* **Unofficial** distributions represent externally sourced or repackaged builds (for example, RubyGems.org or community forks) that do not originate from Progress infrastructure and therefore require stronger validation or explicit licensing to ensure alignment with EULA terms.

This classification separates **access** (distribution) from **entitlement** (license enforcement), enabling a governance model that preserves operational freedom while preventing accidental misuse or EULA misalignment.

By adopting this framework, Progress addresses customer concerns stemming from the InSpec 6 runtime license checks that interfered with automation and emergency operations. License enforcement will now be determined by **distribution intent**, not as a universal runtime requirement.

### Consequences

* **Good**, because the new hierarchy (Commercial, Official, Unofficial) clearly defines authenticity and compliance boundaries, reducing customer confusion and accidental EULA misalignment.
* **Good**, because customers regain operational stability; runtime license enforcement no longer blocks automation, patching, or compliance scans, restoring trust lost during the InSpec 6 enforcement period.
* **Good**, because it reinforces Progress’s open-core strategy, maintaining a transparent separation between freely accessible tools and premium commercial entitlements.
* **Good**, because it provides a governance framework that can scale consistently across current and future Chef ecosystem products (e.g., Courier, DSM, Outpost).
* **Good**, because it improves auditability by providing a verifiable record of which distributions are official, commercial, or community, simplifying compliance reporting and legal oversight.
* **Good**, because it demonstrates responsiveness to customer feedback, strengthening long-term relationships and improving market perception of fairness and pragmatism.


* **Neutral**, because the policy introduces moderate administrative overhead—documentation, labeling, and metadata for every distribution class must be maintained and reviewed during release cycles.
* **Neutral**, because downstream community projects may require additional guidance or tooling to classify their distributions properly, but these effects are manageable through documentation.


* **Bad**, because publishing clear classification and enforcement rules may expose opportunities for misuse (e.g., repackaging or false claims of “official” status) if not backed by signing or verification mechanisms.
* **Bad**, because internal release and legal teams will need ongoing coordination to ensure that every distribution is correctly categorized and associated with its corresponding EULA.
* **Bad**, because customer enablement and partner training programs will need updates to explain the distinctions among Commercial, Official, and Unofficial distributions, as well as the related license behaviors.


## Architecture/Implementation Overview
The **`chef-official-distribution` gem** will serve as the foundational mechanism for identifying **distribution class** and configuring **license enforcement behavior** within Chef products.

In its initial release, the gem will act as a **non-intrusive signaling layer** that sets hidden configuration options inside the `chef-licensing` library. These options define whether licensing should be **optional**, **required**, or **enforced** for a given distribution. The gem will not modify product logic directly; instead, it will quietly instruct the licensing system how to behave based on the authenticated source and intended use of the distribution.

At launch, the behavior will follow a simple **on/off model**:

* **Official Commercial** distributions configure licensing as *optional*, enabling execution without a license key while allowing premium features when one is provided.
* **Official Trial** distributions configure licensing as *enforced*, requiring activation and validating expiration at runtime.
* **Unofficial** distributions default to *enforced*, requiring a valid Progress-issued license or connection to a licensing service for activation.

### Future Evolution

Over time, this gem may/will evolve from a basic toggle to a **dynamic configuration mechanism** capable of applying differentiated enforcement logic per distribution and license type. Planned enhancements include:

* **Unique logic paths for Free, Community, and Trial licenses**, allowing each to express distinct activation and entitlement behaviors.
* **Time-bound enforcement for trial distributions**, automatically transitioning to advisory or inactive states when trial periods expire, without blocking essential maintenance or patching tasks.
* **Lightweight anti-tampering safeguards**, such as checksum or signature validation of configuration values, to ensure that enforcement logic cannot be altered or disabled outside of authorized builds.
* **Context-aware configuration**, enabling the gem to interpret metadata like release channel, downstream declaration, or supported license types to drive more precise enforcement modes.

The enforcement model will not rely on the gem’s name or inclusion, but on **the configuration logic it executes within the `chef-licensing` library**. This ensures flexibility and avoids coupling enforcement to package identity or distribution tooling.

> To maintain openness and compliance with the **Apache 2.0 license**, the implementation must also support legitimate **downstream and community builds**. Distributors who repackage Chef under Apache 2.0 while removing Progress trademarks and branding per the existing trademark policy—must be able to rebuild without the `chef-official-distribution` gem and still operate legally and functionally. The gem’s design therefore cannot introduce hard dependencies or license validation requirements that would prevent lawful downstream redistribution.

The gem will remain **private and embedded only in official Progress builds** (e.g., Habitat packages, Artifactory distributions, or Chef 360 containers) to protect configuration integrity and prevent misuse of internal settings.

### Consequences of the Gem-Based Implementation
* **Good**, because the gem centralizes distribution and license logic through configuration rather than code changes, simplifying enforcement management across multiple Chef products.
* **Good**, because enforcement behavior becomes intentional and declarative—easily adjustable through configuration values without requiring rebuilds or code rewrites.
* **Good**, because this approach restores customer trust by enabling differentiated behavior for Free, Community, and Trial licenses while avoiding the disruptions caused by prior all-or-nothing runtime enforcement.
* **Good**, because the model preserves compliance with the Apache 2.0 license by allowing legitimate downstream distributions to continue operating without the gem, provided Progress trademarks are removed.
* **Good**, because keeping the gem private to official Progress builds protects internal enforcement logic from tampering while maintaining transparency through policy documentation.
* **Good**, because lightweight anti-tampering validation (e.g., checksum or configuration integrity checks) provides assurance that internal enforcement flags cannot be silently modified.

* **Neutral**, because evolving from a simple toggle to a dynamic configuration mechanism will increase maintenance complexity and require careful governance of versioning, documentation, and test coverage.
* **Neutral**, because downstream distributors and community maintainers will need clear guidance to ensure that removal of the gem still results in legally compliant and functional builds.

* **Bad**, because the presence of hidden configuration behavior could be misinterpreted as obfuscation if insufficiently documented for internal and partner teams.
* **Bad**, because managing private gem distribution and embedding across multiple packaging systems adds operational overhead and dependency management risk.
* **Bad**, because exposing even partial details of the gem’s configuration logic could enable unauthorized modifications or attempts to bypass license checks, requiring ongoing build and signing controls.

## Security and Supply Chain Safeguards

To prevent accidental or malicious misuse of the `chef-official-distribution` gem name and to ensure the integrity of official builds, Progress Chef will/has implemented several **supply chain protection measures**.

An **upstream placeholder (empty) gem** has been published to RubyGems.org under the same name (`chef-official-distribution`).
This placeholder serves no functional purpose other than to **reserve the gem namespace** and **prevent unauthorized uploads** that could impersonate an official Progress artifact or distribute misleading or harmful configuration logic.

The following safeguards accompany this approach:

* The **RubyGems account** controlling the `chef-official-distribution` namespace is secured and is restricted to a small set of vetted Progress release engineering maintainers.
* The **empty upstream gem** contains no configuration logic, no runtime effects, and no licensing behavior. Its presence alone cannot alter product functionality.
* The **actual enforcement logic** is delivered only through the private, internally packaged version of the gem included exclusively in official Progress distributions (e.g., Habitat packages, Artifactory releases, Chef 360 containers).
* Licensing behavior depends on **executed configuration logic**, not the gem’s name or installation.
  Installing the upstream placeholder gem **does not** enable, disable, or circumvent license requirements in any way.
* This approach eliminates the risk of community users or downstream redistributors **accidentally** introducing a gem that mimics or interferes with Progress licensing configuration.
* It also prevents malicious actors from publishing a counterfeit version of the gem under the same name, preserving the identity, authenticity, and trustworthiness of official Chef distributions.

While this mechanism is **not intended as DRM**, it provides essential **namespace protection** and **lightweight identity assurance**.

Together, these safeguards ensure customers cannot unintentionally violate license terms and that Progress maintains control and integrity over official distribution channels.



### Confirmation
Verification of this decision will occur through a combination of **automated validation**, **release governance**, and **policy alignment reviews**.
The goal is to ensure that the gem-based configuration behaves as intended, maintains downstream operability under Apache 2.0, and preserves compliance with Progress licensing and trademark requirements.

Validation activities will include:

* **Configuration Integrity Tests** – Automated tests will confirm that the `chef-official-distribution` gem correctly applies the intended configuration to the `chef-licensing` library for each distribution class (Commercial, Official, Unofficial) and license type (Free, Community, Trial, Commercial).
  These tests will verify that toggles such as *optional*, *required*, or *enforced* produce the expected runtime behavior.

* **Build and Packaging Verification** – The presence and configuration of the gem will be validated during official build pipelines (e.g., Habitat, Artifactory, Chef 360) to ensure it is included only in authorized distributions and omitted from downstream or community builds.

* **Downstream Operability Check** – Rebuilds performed without the `chef-official-distribution` gem will be verified to confirm they remain fully functional under the Apache 2.0 license and meet the Progress trademark removal requirements.
  This ensures that legitimate downstream distributions can continue to exist without technical or legal barriers.

* **Licensing Behavior Review** – Periodic internal audits will review that the license enforcement logic continues to align with stated policy: advisory for Community, optional for Commercial, enforced for Trials, and strict for Unofficial distributions.

* **Anti-Tampering Validation** – Future iterations will include checksum or configuration verification tests to detect unauthorized modifications to enforcement parameters in packaged distributions.

* **Governance and Legal Oversight** – Progress Legal, Product Management, and Engineering will jointly review any changes to enforcement logic or gem behavior to ensure continued compliance with open-source licensing, customer commitments, and commercial entitlements.

* **Operational Feedback Loop** – Customer support and field teams will monitor for unintended enforcement behavior (e.g., false enforcement triggers, license rejection) and provide feedback for continuous refinement of configuration logic.

The outcome of these confirmations should demonstrate that:

* License enforcement remains **predictable**, **transparent**, and **non-obstructive**.
* Downstream rebuilds remain **legally compliant and operational**.
* Configuration settings applied by the gem reflect **the declared distribution class and license mode**.
* Enforcement logic remains **secure, auditable, and reversible** as business or policy needs evolve.


## Pros and Cons of the Options
to be expanded on as required

## FAQ / Feedback
... to be added from PR feedback

## More Information

...
