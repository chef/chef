# Bundle Hook for AIX Platform Support

This directory contains scripts and tasks to automatically generate both standard and AIX-specific lock files when running bundle operations.

## Problem

The Chef project needs to maintain two separate lock files:
- `Gemfile.lock` - Standard dependencies for all platforms
- `Gemfile.aix.lock` - AIX-specific dependencies with `inspec-core <= 5.22.80`

Previously, maintaining these files required manual intervention and was error-prone.

## Solution

The bundle hook system automatically:
1. Runs `bundle install/update` normally to generate `Gemfile.lock`
2. Backs up the standard lock file
3. Runs `bundle install/update` with `ENV["GENERATE_AIX"] = true` to generate AIX-specific dependencies
4. Moves the AIX lock file to `Gemfile.aix.lock`
5. Restores the original `Gemfile.lock`

## Usage

### Method 1: Using the Bundle Alias (Recommended)
```bash
# Instead of 'bundle install'
./bundle install

# Instead of 'bundle update'
./bundle update

# With additional arguments
./bundle install --without development test
./bundle update nokogiri
```

### Method 2: Using the Wrapper Script Directly
```bash
# Install dependencies
./scripts/bundle-with-aix.sh install

# Update dependencies  
./scripts/bundle-with-aix.sh update

# With additional arguments
./scripts/bundle-with-aix.sh install --without test
./scripts/bundle-with-aix.sh update nokogiri
```

### Method 3: Using Rake Tasks
```bash
# Install dependencies
rake bundle:install

# Update dependencies
rake bundle:update

# Update specific gem
rake bundle:update_gem[nokogiri]

# Clean and regenerate both lock files
rake bundle:clean_and_install

# Validate both lock files exist
rake bundle:validate
```

### Method 4: Using the Ruby Script Directly
```bash
# Install dependencies
ruby scripts/bundle-hook.rb install

# Update dependencies
ruby scripts/bundle-hook.rb update

# With additional arguments
ruby scripts/bundle-hook.rb install --without test
ruby scripts/bundle-hook.rb update nokogiri
```

## Files Generated

After running any of the above commands, you'll have:

- **`Gemfile.lock`** - Standard dependency resolution for all platforms
- **`Gemfile.aix.lock`** - AIX-specific dependency resolution with `inspec-core <= 5.22.80`

## How It Works

1. **Standard Run**: Executes `bundle install/update` normally, generating `Gemfile.lock`
2. **Backup**: Copies `Gemfile.lock` to `Gemfile.lock.base` for safekeeping
3. **AIX Run**: Sets `ENV["GENERATE_AIX"] = true` and runs `bundle install/update` again
   - This triggers the conditional logic in `chef.gemspec` that limits `inspec-core <= 5.22.80`
4. **Move AIX File**: Moves the new `Gemfile.lock` to `Gemfile.aix.lock`
5. **Restore**: Moves `Gemfile.lock.base` back to `Gemfile.lock`

## Error Handling

If any step fails:
- The script will attempt to restore the original `Gemfile.lock` from the backup
- Exit with error code 1
- Display clear error messages about what went wrong

## Integration with CI/CD

In your CI/CD pipelines, you can use:

```bash
# For standard platforms
bundle install

# For AIX builds specifically
GENERATE_AIX=true bundle install --gemfile=Gemfile.aix.lock
```

Or use the hook system to ensure both are always in sync:

```bash
./bundle install  # Generates both files
# Then commit both Gemfile.lock and Gemfile.aix.lock
```

## Maintenance

When adding new dependencies or changing versions:

1. Update `Gemfile` or `chef.gemspec` as needed
2. Run `./bundle install` or `rake bundle:install`
3. Commit both `Gemfile.lock` and `Gemfile.aix.lock`
4. The AIX-specific constraints will be automatically applied

## Troubleshooting

### Lock files out of sync
```bash
rake bundle:clean_and_install
```

### Validate lock files
```bash
rake bundle:validate
```

### Manual cleanup
```bash
rm -f Gemfile.lock Gemfile.aix.lock Gemfile.lock.base
./bundle install
```

[Product Documentation Copyright Notice & Trademarks | Progress](https://www.progress.com/legal/documentation-copyright)
