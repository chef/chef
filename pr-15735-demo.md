# Demo: Fix Target Mode Node Identity When Using Chef Server
### PR #15735 — `chef/chef`

---

## The Problem

When running `chef-client` with the `-t` / `--target` flag against a real **Chef Server** (without `-z` / local mode), the client **silently converged the wrong node** — it converged the local workstation instead of the specified remote target.

This was caused by **four layered bugs** that together broke authentication and node selection.

---

## Bug Walkthrough

### Bug 1 — `application/client.rb`: The `unless` guard that swallowed the target

```ruby
# BEFORE — the guard prevented overriding a pre-set node_name
Chef::Config.node_name = target unless Chef::Config.node_name
```

**What went wrong:**  
On a Chef Server workstation, `/etc/chef/client.rb` pre-sets `node_name` to the admin user's identity (e.g. `"jmccrae"`). The `unless` guard saw that `node_name` was already set and silently skipped the override. Chef then loaded and converged **the admin user's local node** instead of the remote target.

---

### Bug 2 — `chef-config/config.rb`: The disappearing `client_key` path

The `client_key` config has a **lazy default** that changes once `target_mode.enabled = true`:

```
/etc/chef/client.pem          ← before target_mode enabled
/etc/chef/<target>/client.pem ← after target_mode enabled
```

The operator's real signing key had to be captured **before** flipping `target_mode.enabled`, otherwise it would resolve to the target's (non-existent) key path.

---

### Bug 3 — `node.rb`: Bare `ServerAPI` using the wrong identity

```ruby
# BEFORE — no credentials passed; falls back to Chef::Config[:node_name]
def self.load(name)
  from_hash(Chef::ServerAPI.new(Chef::Config[:chef_server_url]).get("nodes/#{name}"))
end
```

**What went wrong:**  
After `node_name` was (correctly) changed to the target, every `Node.load` call signed its HTTP request as `"target.example.com"` — a name the Chef Server had never heard of — producing **401 Unauthorized** errors.

---

### Bug 4 — `policy_builder/policyfile.rb` & `expand_node_object.rb`: Same bare `ServerAPI` issue

```ruby
# BEFORE — also constructed without explicit credentials
def api_service
  @api_service ||= Chef::ServerAPI.new(config[:chef_server_url],
    version_class: Chef::CookbookManifestVersions)
end
```

Cookbook resolution and policy loading both failed for the same reason as Bug 3.

---

## The Fix (PR #15735)

### Step 1 — Register new config keys (`chef-config/config.rb`)

```ruby
# NEW — two dedicated config keys to hold the operator's identity
default :api_client_name, nil
default :api_client_key,  nil
```

These persist across the full client lifecycle and are never overwritten by target-mode path resolution.

---

### Step 2 — Capture operator credentials before enabling target mode (`application/client.rb`)

```ruby
# AFTER — capture FIRST, then unconditionally set node_name
Chef::Config[:api_client_name] ||= Chef::Config[:node_name]   # save "jmccrae"
Chef::Config[:api_client_key]  ||= Chef::Config[:client_key]  # save "/etc/chef/client.pem"
Chef::Config.target_mode.enabled = true
Chef::Config.node_name = Chef::Config.target_mode.host         # now "target.example.com"
```

Key changes:
- **`||=`** ensures we don't overwrite an explicitly set value, but always have a fallback.
- The `unless` guard is **gone** — `node_name` is always set to the target.
- Credentials are captured **before** `target_mode.enabled = true` so `client_key`'s lazy path resolves correctly.

---

### Step 3 — Helper methods for consistent credential resolution (`client.rb`)

```ruby
# NEW — helper methods added to Chef::Client
def api_client_name
  Chef::Config[:api_client_name] || node_name
end

def api_client_key
  Chef::Config[:api_client_key] || Chef::Config[:client_key]
end

# AFTER — rest and rest_clean now use helpers
def rest
  @rest ||= Chef::ServerAPI.new(Chef::Config[:chef_server_url],
    client_name: api_client_name,
    signing_key_filename: api_client_key)
end

def rest_clean
  @rest_clean ||= Chef::ServerAPI.new(Chef::Config[:chef_server_url],
    client_name: api_client_name,
    signing_key_filename: api_client_key,
    validate_utf8: false)
end
```

---

### Step 4 — Explicit credentials in `Node.load` (`node.rb`)

```ruby
# AFTER — operator credentials passed explicitly
def self.load(name)
  from_hash(Chef::ServerAPI.new(Chef::Config[:chef_server_url],
    client_name: api_client_name,
    signing_key_filename: api_client_key).get("nodes/#{name}"))
end

def self.api_client_name
  Chef::Config[:api_client_name] || Chef::Config[:node_name]
end
private_class_method :api_client_name

def self.api_client_key
  Chef::Config[:api_client_key] || Chef::Config[:client_key]
end
private_class_method :api_client_key
```

The HTTP request is now signed as `"jmccrae"` (the admin) while loading the node object for `"target.example.com"`.

---

### Step 5 — Same fix in both policy builders (`policyfile.rb`, `expand_node_object.rb`)

```ruby
# AFTER — both builders pass operator credentials explicitly
def api_service
  @api_service ||= Chef::ServerAPI.new(config[:chef_server_url],
    client_name: api_client_name,
    signing_key_filename: api_client_key,
    version_class: Chef::CookbookManifestVersions)
end

def api_client_name
  config[:api_client_name] || config[:node_name]
end

def api_client_key
  config[:api_client_key] || config[:client_key]
end
```

---

## Before vs After: Side-by-Side Summary

| Component | Before | After |
|---|---|---|
| `application/client.rb` | `node_name = target unless node_name` — silently skipped if pre-set | Captures operator identity, then **unconditionally** sets `node_name` to target |
| `chef-config/config.rb` | No persistent store for operator identity | `api_client_name` / `api_client_key` config keys registered |
| `client.rb` `rest` / `rest_clean` | Signed as `node_name` (the target) | Signed as `api_client_name` (the operator) |
| `node.rb` `Node.load` | Bare `ServerAPI.new` — fell back to wrong identity | Explicit credentials passed → signs as operator |
| `policyfile.rb` / `expand_node_object.rb` | Same bare `ServerAPI.new` | Same explicit credential fix |

---

## Test Coverage Added

```
spec/unit/application/client_spec.rb     — 12 new tests (target mode reconfigure scenarios)
spec/unit/client_spec.rb                 —  6 new tests (rest/rest_clean credential usage)
spec/unit/node_spec.rb                   —  2 new contexts (Node.load credential handling)
spec/unit/policy_builder/policyfile_spec.rb         — 2 new tests (api_service credentials)
spec/unit/policy_builder/expand_node_object_spec.rb — 2 new tests (api_service credentials)
```

**All 442 examples pass.**

---

## Key Takeaway

The root issue was an **identity collision**: a single `Chef::Config[:node_name]` was expected to serve two incompatible roles simultaneously — the *operator's auth identity* on the Chef Server, and the *target node's name* being managed. The fix separates these concerns cleanly:

- `node_name` → **what node to manage** (the remote target)
- `api_client_name` / `api_client_key` → **who is doing the managing** (the operator)
