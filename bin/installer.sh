#!/bin/bash

echo 'set GUID environment variable and made it persistent'
export GUID=$(hostname | cut -d '.' -f2)
cat <<-EOF >> $HOME/.bash_profile

# set GUID for LAB
export GUID=$GUID
EOF


