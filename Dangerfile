# Enforce our Gemfile update policy
if git.modified_files.include?('Gemfile.lock')
  if git.modified_files.include?('Gemfile')
    message "PR updates Gemfile.lock, but it also updates Gemfile, so that" +
      " is probably OK - but the reviewer should check updates are soley" +
      " from the Gemfile update"
  elsif !github.pr_body.include?('--conservative')
    if github.pr_body.include?("#gemlock_major_upgrade")
      message "PR updates Gemfile.lock, but output doesn't appear to be in" +
          " the PR Description. However #gemlock_major_upgrade does, so allowing"
    else
      failure "Gem/Bundle changes were not documented in the Description. If" +
        " this is a major update, add #gemlock_major_upgrade to the PR"
        " Description."
    end
  end
end
