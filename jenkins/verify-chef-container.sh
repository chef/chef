#!/usr/bin/env bash

export PATH=/opt/chef/bin:$PATH
sudo chef-init verify --unit --integration
