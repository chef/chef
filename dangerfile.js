import { danger, fail, markdown, message, peril, schedule, warn } from 'danger'

// Check if chef gem versions have been modified in Gemfile.lock
async function checkChefGemVersions() {
    if (!danger.git.modified_files.includes("Gemfile.lock")) {
        return
    }

    const versionsComparison = await danger.git.diffForFile("Gemfile.lock")
    if (!versionsComparison) {
        return
    }

    const chefGems = ['chef (', 'chef-bin (', 'chef-config (', 'chef-utils (']
    const changedGems = []

    // Check if any of the chef gem version lines were modified
    versionsComparison.diff.split('\n').forEach(line => {
        // Look for lines that start with +/- and contain gem version info
        if ((line.startsWith('+') || line.startsWith('-')) && !line.startsWith('+++') && !line.startsWith('---')) {
            chefGems.forEach(gem => {
                if (line.includes(gem) && !changedGems.includes(gem.replace(' (', ''))) {
                    changedGems.push(gem.replace(' (', ''))
                }
            })
        }
    })

    if (changedGems.length > 0) {
        const gemList = changedGems.map(g => `\`${g}\``).join(', ')

        if (danger.github.pr.body && danger.github.pr.body.includes("manual-update")) {
            message(`✅ This PR modifies version(s) for: ${gemList} in Gemfile.lock. The PR includes 'manual-update' flag, so this is allowed.`)
        } else {
            fail(`❌ This PR modifies version(s) for: ${gemList} in Gemfile.lock. Core chef gem versions should not be changed unless this is an intentional version bump. If this is intentional, add 'manual-update' to the PR description to bypass this check.`)
        }
    }
}

// Enforce our Gemfile update policy
if (danger.git.modified_files.includes("Gemfile.lock") &&
    danger.github.pr.user.type !== "Bot") {
    /*
     * our default template now includes --conservative, so we have to
     * strip that out. Oops.
     */
    body = danger.github.pr.body
    body = body.replace("I have used `--conservative` to do it", "")

    if (danger.git.modified_files.includes("Gemfile") || danger.git.modified_files.includes("chef.gemspec") || danger.git.modified_files.includes("chef-universal-mingw-ucrt.gemspec")) {
        message("PR updates Gemfile.lock, but it also updates Gemfile/gemspec, so that" +
            " is probably OK - but the reviewer should check updates are solely" +
            " from the Gemfile update")
    } else if (!body.includes("--conservative")) {
        if (danger.github.pr.body.includes("#gemlock_major_upgrade")) {
            message("PR updates Gemfile.lock, but output doesn't appear to be in" +
                " the PR Description. However #gemlock_major_upgrade does, so allowing")
        } else {
            fail("Gem/Bundle changes were not documented in the Description. If" +
                " this is a major update, add #gemlock_major_upgrade to the PR" +
                " Description.")
        }
    }
}

// Check for chef gem version changes
schedule(checkChefGemVersions())
