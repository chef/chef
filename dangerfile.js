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

function normalizeBody(text) {
    // Strip whitespace differences and checkbox state so we catch
    // templates where someone only ticked boxes but wrote nothing.
    return text.replace(/\r\n/g, '\n').replace(/- \[x\]/gi, '- [ ]').trim()
}

// Check if PR description has been properly filled out by comparing
// against the PR template (from this repo, falling back to chef/.github).
async function checkPRDescription() {
    const body = danger.github.pr.body || ""

    if (danger.github.pr.user.type === "Bot") {
        return
    }

    const api = danger.github.api
    const owner = danger.github.thisPR.owner
    const repo = danger.github.thisPR.repo

    let template = null
    // Check this repo first, then the org-level .github repo
    for (const [o, r, path] of [[owner, repo, ".github/PULL_REQUEST_TEMPLATE.md"], [owner, ".github", ".github/PULL_REQUEST_TEMPLATE.md"]]) {
        try {
            const { data } = await api.repos.getContent({ owner: o, repo: r, path })
            template = Buffer.from(data.content, 'base64').toString('utf-8')
            break
        } catch (e) {
            // not found, try next
        }
    }

    if (!template) {
        return
    }

    if (normalizeBody(body) === normalizeBody(template)) {
        fail("❌ PR description is the unedited template. Please fill in a description of your changes.")
    }
}

async function stickyWorkflowChangeReminder() {
    if (danger.github.pr.user.type === "Bot") {
        return
    }

    const workflowChanges = danger.git.modified_files.filter(file =>
        file.startsWith(".github/workflows/")
    )

    if (workflowChanges.length === 0) {
        return
    }

    const filesList = workflowChanges.map(f => `- \`${f}\``).join("\n")

    const body = `
### ⚠️ Workflow changes detected

This PR modifies GitHub Actions workflow files:

${filesList}

**Reviewer reminder – please double-check for:**
- [ ] Changes to **secrets usage** or new secret references
- [ ] Workflow **permissions** increases (especially \`contents\`, \`actions\`, or \`id-token\`)
- [ ] Any way secrets could be **exfiltrated** (logs, artifacts, uploads)

These workflow changes are gated for manual approval — please review carefully before approving.
`

    const api = danger.github.api
    const issue = danger.github.pr.number
    const repo = danger.github.thisPR.repo
    const owner = danger.github.thisPR.owner

    const { data: comments } = await api.issues.listComments({
        owner,
        repo,
        issue_number: issue,
        per_page: 100,
    })

    const existing = comments.find(c =>
        c.user?.login === "github-actions[bot]" &&
        c.body?.includes("⚠️ Workflow changes detected")
    )

    if (existing) {
        await api.issues.updateComment({
            owner,
            repo,
            comment_id: existing.id,
            body,
        })
    } else {
        await api.issues.createComment({
            owner,
            repo,
            issue_number: issue,
            body,
        })
    }
}

// Recursively collect all ${{ secrets.X }} names from a parsed YAML value tree
function collectSecretNames(obj, found = new Set()) {
    if (typeof obj === 'string') {
        for (const m of obj.matchAll(/\$\{\{\s*secrets\.(\w+)\s*\}\}/g)) {
            found.add(m[1])
        }
    } else if (Array.isArray(obj)) {
        for (const item of obj) collectSecretNames(item, found)
    } else if (obj !== null && typeof obj === 'object') {
        for (const val of Object.values(obj)) collectSecretNames(val, found)
    }
    return found
}

// Return true if the parsed `on:` value includes a bare `pull_request` trigger
function triggersPullRequest(on) {
    if (!on) return false
    if (typeof on === 'string') return on === 'pull_request'
    if (Array.isArray(on)) return on.includes('pull_request')
    if (typeof on === 'object') return 'pull_request' in on
    return false
}

// Check for secrets used in pull_request-triggered workflows
async function checkWorkflowSecretsOnPullRequest() {
    if (danger.github.pr.user.type === "Bot") {
        return
    }

    const workflowFiles = [
        ...danger.git.created_files,
        ...danger.git.modified_files,
    ].filter(f => f.startsWith(".github/workflows/") && f.endsWith(".yml"))

    if (workflowFiles.length === 0) {
        return
    }

    const yaml = require('js-yaml')
    const api = danger.github.api
    const owner = danger.github.thisPR.owner
    const repo = danger.github.thisPR.repo
    const ref = danger.github.pr.head.sha

    for (const file of workflowFiles) {
        let content
        try {
            const { data } = await api.repos.getContent({ owner, repo, path: file, ref })
            content = Buffer.from(data.content, 'base64').toString('utf-8')
        } catch (e) {
            continue
        }

        let workflow
        try {
            workflow = yaml.load(content)
        } catch (e) {
            continue
        }

        if (!workflow || typeof workflow !== 'object') {
            continue
        }

        // js-yaml 4.x (YAML 1.2): `on` key is a string → workflow['on']
        // js-yaml 3.x (YAML 1.1): `on` is a boolean true → key coerces to workflow['true']
        const triggers = workflow['on'] ?? workflow['true']
        if (!triggersPullRequest(triggers)) {
            continue
        }

        const allSecrets = collectSecretNames(workflow)
        const badSecrets = [...allSecrets].filter(s => s !== 'GITHUB_TOKEN')

        if (badSecrets.length > 0) {
            const secretList = badSecrets.map(s => `\`${s}\``).join(', ')
            fail(
                `❌ \`${file}\` references secrets (${secretList}) in a \`pull_request\`-triggered workflow. ` +
                `Secrets are not available to workflows triggered by \`pull_request\` events from forks, ` +
                `so this will silently break CI for external contributors. ` +
                `Use \`pull_request_target\` instead (carefully, following GitHub's security guidance), ` +
                `or restructure the workflow to avoid requiring secrets on the \`pull_request\` trigger.`
            )
        }
    }
}

// Check for chef gem version changes
schedule(checkChefGemVersions())

// Check PR description
schedule(checkPRDescription())

// Remind reviewers about workflow changes
schedule(stickyWorkflowChangeReminder)

// Check for secrets in pull_request-triggered workflows
schedule(checkWorkflowSecretsOnPullRequest())
