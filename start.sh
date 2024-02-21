#!/bin/bash

FOLDER=$(echo $(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) | awk -F/ '{print $NF}')
source ~/scripts/$FOLDER/config/env

sudo systemctl restart $BINARY.service
sudo journalctl -u $BINARY.service -f --no-hostname -o cat
