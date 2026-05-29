# Encrypted Data Bag Secret Loading Security

This note documents security controls for loading encrypted data bag secrets in Chef Infra.

## Remote Secret URL Controls

When `Chef::EncryptedDataBagItem.load_secret` is passed a URL, Chef now enforces:

- Allowed schemes: `http` and `https` only
- Required host in URL
- Embedded credentials (`user:pass@host`) are rejected
- Remote reads use explicit `open_timeout` and `read_timeout`

These checks reduce the risk of accidentally accepting unsafe URL formats or hanging indefinitely on remote reads.

## Local Verification Script

Use this script to validate the hardening is present:

```bash
scripts/security/check_encrypted_data_bag_secret_loading.sh
```

The script checks for:

- No `Kernel.open(path)` usage in secret loading
- Presence of `URI.open` with timeout options
- Presence of URL scheme and credential guards
