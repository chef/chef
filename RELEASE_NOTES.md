_This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team. Please see <https://docs.chef.io/release_notes.html> for the official Chef release notes._

# Chef Client Release Notes 12.19:

## Highlighted enhancements for this release:

- Systemd Unit files are now verified before being installed

## Highlighted bug fixes for this release:

- Ensure that the Windows Administrator group can access the chef-solo nodes directory
- When loading a cookbook in Chef Solo, use `metadata.json` in preference to `metadata.rb`

# Ohai Release Notes 8.23:

## Cumulus Linux Platform

Cumulus Linux will now be detected as platform `cumulus` instead of `debian` and the `platform_version` will be properly set to the Cumulus Linux release.

## Virtualization Detection

Windows / Linux / BSD guests running on the Veertu hypervisors will now be detected

Windows guests running on Xen and Hyper-V hypervisors will now be detected

## New Sysconf Plugin

A new plugin parses the output of the sysconf command to provide information on the underlying system.

## AWS Account ID

The EC2 plugin now fetches the AWS Account ID in addition to previous instance metadata

## GCC Detection

GCC detection has been improved to collect additional information, and to not prompt for the installation of Xcode on macOS systems
