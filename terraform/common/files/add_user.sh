#!/bin/bash

set -evx

echo -e '\nBEGIN ADD USER + ORGANIZATION\n'

sudo chef-server-ctl user-create janedoe Jane Doe janed@example.com abc123 --filename /tmp/janedoe.pem
sudo chef-server-ctl org-create 4thcoffee 'Fourth Coffee, Inc.' --association_user janedoe --filename /tmp/4thcoffee-validator.pem

echo -e '\nEND ADD USER + ORGANIZATION\n'
