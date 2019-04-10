# Updating Dependencies

If you want to change our constraints (change which packages and versions we accept in the chef), there are several places to do so:

* [Gemfile](Gemfile) and [Gemfile.lock](Gemfile.lock):  All gem version constraints (update with `bundle update`)
* [omnibus_overrides.rb](omnibus_overrides_rb):  Pinned versions of omnibus packages.
* [omnibus/Gemfile](omnibus/Gemfile) and [omnibus/Gemfile.lock](omnibus/Gemfile.lock):  Gems for the omnibus build system itself.

In addition, there are several places where versions are pinned for CI tasks:

* [kitchen-tests/Gemfile](kitchen-tests/Gemfile) and [kitchen-tests/Gemfile.lock](kitchen-tests/Gemfile.lock): Gems for test-kitchen tests (travis)

In order to update everything, run `rake dependencies`.  Note that the [Gemfile.lock](Gemfile.lock) pins windows platforms, and to fully regenerate the lockfile, you must use the following commands, or run `rake dependencies:update_gemfile_lock`:

```bash
bundle lock --update --add-platform ruby
bundle lock --update --add-platform x64-mingw32
bundle lock --update --add-platform x86-mingw32
```