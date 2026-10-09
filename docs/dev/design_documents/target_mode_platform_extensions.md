# Target Mode platform extension loading

Chef core no longer defines the AIX-specific resources and providers. In Target
Mode, Chef selects an `agentless_<platform>_extensions` plugin from the target
node's attributes and loads it lazily.

```mermaid
sequenceDiagram
    participant C as Chef::Client
    participant O as Ohai::System
    participant L as ChefPremiumExtensions::Loader
    participant X as agentless_PLATFORM_extensions

    C->>O: run_ohai, transport_connection set
    C->>O: target_platform_attributes
    O-->>C: platform, platform_family, os from Train
    C->>L: load_for target attributes, ohai
    alt loader gem not installed
        L-->>C: LoadError rescued, debug log, OSS continues
    else premium gates fail
        L-->>C: no plugins loaded
    else platform matches
        L->>X: require plugin
        X->>X: register resources, providers and shims
        L->>O: add_platform_plugin_path
    end
    C->>O: all_plugins
    C->>L: load_for ohai.data, ohai
    C->>L: setup_targetmode, load_for node, ohai
```

- Only the optional `require "chef_premium_extensions/loader"` is rescued.
  Failures inside a matching extension surface to the user.
- `load_for` is idempotent, so calling it again after Ohai only adds platforms
  that were not already loaded.
- AIX is supplied by `agentless-aix-extensions` (premium Target Mode) or, only
  when explicitly required, the community `chef-aix-resources` snapshot
  (local mode).
