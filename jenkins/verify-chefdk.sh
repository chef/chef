#!/usr/bin/env bash

export PATH=/opt/chefdk/bin:$PATH
sudo chef verify --unit --integration
