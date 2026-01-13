import { danger, fail, markdown, message, peril, schedule, warn } from 'danger'

// Enforce our Gemfile update policy
if (danger.git.modified_files.includes("Gemfile.lock") &&
    danger.github.pr.user.type !== "Bot") {
    /*
     * our default template now includes --conservative, so we have to
     * strip that out. Oops.
     */
    body = danger.github.pr.body
    body = body.replace("I have used `--conservative` to do it", "")

    if (danger.git.modified_files.includes("Gemfile")) {
        message("PR updates Gemfile.lock, but it also updates Gemfile, so that" +
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
