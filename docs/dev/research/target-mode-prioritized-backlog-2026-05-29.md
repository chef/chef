# Target Mode Prioritized Backlog (2026-05-29)

## Scope
Target subsystem: target mode transport and credential resolution in chef-client and chef-config.

Primary code anchors:
- [lib/chef/application/client.rb](lib/chef/application/client.rb#L122)
- [chef-config/lib/chef-config/mixin/train_transport.rb](chef-config/lib/chef-config/mixin/train_transport.rb#L37)
- [spec/unit/application/client_spec.rb](spec/unit/application/client_spec.rb#L320)
- [spec/unit/train_transport_spec.rb](spec/unit/train_transport_spec.rb#L24)
- [tasks/target_mode.rb](tasks/target_mode.rb#L34)

## Prioritized Improvement Opportunities

### P1 - Guard invalid target URI input and fail with actionable message
Why this matters:
- Current target parsing path uses URI.parse directly in reconfigure flow and can raise before producing a clear user-facing action.

Code paths:
- [lib/chef/application/client.rb](lib/chef/application/client.rb#L126)
- [spec/unit/application/client_spec.rb](spec/unit/application/client_spec.rb#L374)

Acceptance criteria:
- Given a malformed value passed to --target, reconfigure fails via Chef::Application.fatal! with a message containing the invalid target string and expected formats (hostname or train URI).
- Existing valid host targets continue to work.
- Existing valid train URI targets continue to work.
- New unit tests are added for malformed URI handling and pass with existing target-mode tests.

Good first task:
- Yes.
- Reason: isolated change in one code path with focused unit test updates.

---

### P2 - Make credentials_file_path errors include full lookup order and failing source
Why this matters:
- Current errors can tell users that a file does not exist but do not consistently expose which candidate paths were evaluated.

Code paths:
- [chef-config/lib/chef-config/mixin/train_transport.rb](chef-config/lib/chef-config/mixin/train_transport.rb#L86)
- [spec/unit/train_transport_spec.rb](spec/unit/train_transport_spec.rb#L52)

Acceptance criteria:
- Error path includes the evaluated lookup order: CHEF_CREDENTIALS_FILE, target_mode.credentials_file, host-specific credentials file, and user target_credentials.
- If a configured path is provided but missing, the message includes that exact configured path.
- Unit tests assert message content and lookup order.

Good first task:
- Yes.
- Reason: no functional protocol changes; mostly diagnostics and tests.

---

### P3 - Add build_transport unit coverage for precedence, protocol selection, and plugin failure path
Why this matters:
- Core merge behavior (config plus credentials) and invalid protocol handling currently have little direct unit coverage in this spec file.

Code paths:
- [chef-config/lib/chef-config/mixin/train_transport.rb](chef-config/lib/chef-config/mixin/train_transport.rb#L111)
- [spec/unit/train_transport_spec.rb](spec/unit/train_transport_spec.rb#L24)

Acceptance criteria:
- Tests cover protocol selection precedence: credentials transport_protocol over target_mode.protocol.
- Tests cover allowed-option filtering against Train.options(protocol).
- Tests cover Train::PluginLoadError handling and asserted logger.error call.
- Tests cover SocketError message rewrite branch.

Good first task:
- Yes.
- Reason: tests-only backlog item with low regression risk.

---

### P4 - Harden contains_split_fqdn? against nil and non-String profile values
Why this matters:
- contains_split_fqdn? assumes fqdn responds to include? and split; nil or unexpected profile types can throw before useful diagnostics.

Code paths:
- [chef-config/lib/chef-config/mixin/train_transport.rb](chef-config/lib/chef-config/mixin/train_transport.rb#L63)
- [spec/unit/train_transport_spec.rb](spec/unit/train_transport_spec.rb#L24)

Acceptance criteria:
- contains_split_fqdn? returns false for nil or non-String profile values.
- Existing split-hostname warning behavior remains unchanged for malformed TOML host sections.
- Unit tests added for nil and symbol profile inputs.

Good first task:
- Yes.
- Reason: tiny defensive change with narrow blast radius.

---

### P5 - Expand target mode static analysis rule to flag TargetIO bypasses beyond File.read-like calls
Why this matters:
- Current static-analysis rule is limited to a subset of File methods and may miss local I/O bypasses through related patterns.

Code paths:
- [tasks/target_mode.rb](tasks/target_mode.rb#L38)
- [tasks/target_mode.rb](tasks/target_mode.rb#L51)

Acceptance criteria:
- Static analysis flags local I/O bypasses for at least: File.exist?, File.file?, FileUtils operations when executed in target-mode providers.
- Rule avoids false positives on comments and obvious safe TargetIO calls.
- Add unit-style validation fixture or deterministic test task input demonstrating one positive and one negative detection.

Good first task:
- No.
- Reason: requires balancing coverage and false-positive rate.

## Priority Recommendation
Execution order:
1. P1 (user-facing reliability fix)
2. P3 (test coverage to reduce regression risk)
3. P2 (diagnostic quality)
4. P4 (defensive hardening)
5. P5 (tooling enhancement)

Recommended delegation-ready first tasks:
- P1, P2, P3, P4

## Simulated Delegation Patch Plan (for P1)

Delegated issue title:
- Target mode: validate malformed --target URI with clear fatal error

Delegate brief:
- Add a safe parse path around URI.parse in target-mode reconfigure logic.
- Keep behavior unchanged for valid hostname and valid train URI.
- Add unit tests in target mode section for malformed URI.

Implementation plan:
1. Update reconfigure target parse block in [lib/chef/application/client.rb](lib/chef/application/client.rb#L122):
	- Wrap URI.parse with rescue URI::InvalidURIError.
	- Route invalid values to Chef::Application.fatal! with explicit expected input formats.
2. Add unit tests in [spec/unit/application/client_spec.rb](spec/unit/application/client_spec.rb#L320):
	- malformed target string triggers fatal! and does not call Train.unpack_target_from_uri.
	- existing URI and hostname tests remain green.
3. Run focused tests:
	- bundle exec rspec spec/unit/application/client_spec.rb

Validation evidence expected from delegate:
- Before: malformed --target causes unhandled parse exception or non-actionable error.
- After: malformed --target produces deterministic fatal! message with guidance.
- Test evidence: new spec examples pass in target mode describe block.

Rollout risk:
- Low. Behavior change only in malformed input path.

Rollback plan:
- Revert isolated changes in [lib/chef/application/client.rb](lib/chef/application/client.rb#L122) and [spec/unit/application/client_spec.rb](spec/unit/application/client_spec.rb#L320).

## Suggested Issue Text Snippets

Use these as tracker issue bodies if tracker access is available:

1) P1 body summary:
- Problem: malformed --target input is not consistently surfaced with actionable guidance.
- AC: use P1 acceptance criteria above.
- Links: [lib/chef/application/client.rb](lib/chef/application/client.rb#L122), [spec/unit/application/client_spec.rb](spec/unit/application/client_spec.rb#L320)

2) P2 body summary:
- Problem: credential-path failures are not explicit about lookup order.
- AC: use P2 acceptance criteria above.
- Links: [chef-config/lib/chef-config/mixin/train_transport.rb](chef-config/lib/chef-config/mixin/train_transport.rb#L86), [spec/unit/train_transport_spec.rb](spec/unit/train_transport_spec.rb#L52)

3) P3 body summary:
- Problem: missing direct tests for transport config merge and protocol failure handling.
- AC: use P3 acceptance criteria above.
- Links: [chef-config/lib/chef-config/mixin/train_transport.rb](chef-config/lib/chef-config/mixin/train_transport.rb#L111), [spec/unit/train_transport_spec.rb](spec/unit/train_transport_spec.rb#L24)

4) P4 body summary:
- Problem: split-fqdn helper assumes profile is String.
- AC: use P4 acceptance criteria above.
- Links: [chef-config/lib/chef-config/mixin/train_transport.rb](chef-config/lib/chef-config/mixin/train_transport.rb#L63), [spec/unit/train_transport_spec.rb](spec/unit/train_transport_spec.rb#L24)

5) P5 body summary:
- Problem: static analysis does not detect a broader set of local IO bypasses in target-mode providers.
- AC: use P5 acceptance criteria above.
- Links: [tasks/target_mode.rb](tasks/target_mode.rb#L38), [tasks/target_mode.rb](tasks/target_mode.rb#L51)
