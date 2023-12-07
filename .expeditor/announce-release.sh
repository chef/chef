#!/bin/bash

set -exou pipefail

# Download the release-notes for our specific build
curl -o release-notes.md "https://packages.chef.io/release-notes/${EXPEDITOR_PRODUCT_KEY}/${EXPEDITOR_VERSION}.md"

topic_title="Chef Infra Client $EXPEDITOR_VERSION Released!"
topic_body=$(cat <<EOH
We are delighted to announce the availability of version $EXPEDITOR_VERSION of Chef Infra Client.

$(cat release-notes.md)

---
## Get the Build

As always, you can download binaries from [chef.io/downloads](https://www.chef.io/downloads/) or by using the \`mixlib-install\` command-line utility:

\`\`\`
$ mixlib-install download chef -v ${EXPEDITOR_VERSION}
\`\`\`

Alternatively, you can install Chef Infra Client using one of the following command options:

\`\`\`
# In Shell
$ curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef -v ${EXPEDITOR_VERSION}
# In Windows Powershell
. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -project chef -version ${EXPEDITOR_VERSION}
\`\`\`
If you want to give this version a spin in Test Kitchen, create or add the following to your `kitchen.yml` file:

\`\`\`
provisioner:
  product_name: chef
  product_version: ${EXPEDITOR_VERSION}
\`\`\`
EOH
)

# Use Expeditor's built in Bash helper to post our message: https://git.io/JvxPm
post_discourse_release_announcement "$topic_title" "$topic_body"

# Cleanup
rm release-notes.md
