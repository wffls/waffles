#!/bin/bash
export WAFFLES_CONFIG_FILE=/root/.waffles/waffles.conf
export WAFFLES_SITE_DIR=/root/.waffles/kitchen/site
cd /root/.waffles
bash waffles.sh -d -r ubuntu1404_apache
