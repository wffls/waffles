#!/bin/bash
export WAFFLES_CONFIG_FILE=/root/.waffles/waffles.conf
export SITE_DIR=/root/.waffles/kitchen/site
export DEBUG=1
cd /root/.waffles
bash waffles.sh -r ubuntu1204
