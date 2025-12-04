# Releasing the Knife Gem

This document outlines the process for releasing the Knife gem to RubyGems.org.

## Prerequisites

- Push access to the [chef/chef](https://github.com/chef/chef) repository
- RubyGems.org account with permissions to push the `knife` gem
- Local checkout of the chef repository with the latest branch (main/chef-18)

## Release Process

### 1. Update Chef Version in Knife Gemfile.lock

The Knife gem depends on the latest released version of Chef. You must update the `Gemfile.lock` in the knife directory to match the latest Chef release on RubyGems.org.

### 2. Review and Commit Changes

Review the changes to ensure only the Chef version was updated:

```bash
git diff knife/Gemfile.lock
```

Commit these changes with a clear message:

```bash
git add knife/Gemfile.lock
git commit -m "Bump chef dependency in knife to latest release"
```
Create a PR for this change and have it merged.

### 3. Build the Knife Gem

Navigate to the knife directory and build the gem:

```bash
cd knife
gem build knife.gemspec
```

This creates a `knife-X.Y.Z.gem` file in the knife directory.

### 4. Push to RubyGems.org

Push the built gem to RubyGems.org:

```bash
gem push knife-X.Y.Z.gem
```

You will be prompted for your RubyGems.org credentials. Enter your username and API key/password.

### 5. Verify the Release

Verify the gem was successfully published by checking RubyGems.org:

```bash
gem search knife --exact
```

Or visit: https://rubygems.org/gems/knife

## Troubleshooting

### Authentication Issues

If you cannot authenticate to RubyGems.org:
- Verify your RubyGems.org account is active
- Check that you have been added to the `knife` gem owners list
- Regenerate your API key in your [RubyGems.org account settings](https://rubygems.org/profile/api_keys)
- Store the API key in `~/.gem/credentials` with proper permissions (600)

### Build Failures

If `gem build` fails:
- Ensure you're in the `knife/` directory
- Run `bundle install` to resolve any dependency issues
- Review the `knife.gemspec` for syntax errors

## Related Resources

- `knife/Gemfile.lock`
- `knife.gemspec`
- [RubyGems.org Publishing Guide](https://guides.rubygems.org/publishing/)