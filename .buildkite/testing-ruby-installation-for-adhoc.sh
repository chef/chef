#!/bin/bash

rbenv install 3.1.6
rbenv global 3.1.6
rbenv rehash
ruby -v

whoami
ls -lah .
ls -lah /home/ec2-user/.rbenv
ls -lah /home/ec2-user/.rbenv/shims/ruby
