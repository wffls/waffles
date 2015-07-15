#!/bin/bash
export WAFFLES_CONFIG_FILE=/root/.waffles/waffles.conf
export WAFFLES_SITE_DIR=/root/.waffles/kitchen/site
export WAFFLES_DEBUG=1
cd /root/.waffles
bash waffles.sh -r ubuntu1204
