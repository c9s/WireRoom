#!/bin/bash
cp -v scripts/post-receive.xdroom /home/git/hooks/
cd /home/git && bash maintenance/install-hooks.sh
