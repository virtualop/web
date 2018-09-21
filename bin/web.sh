#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

CONFIG_FILE=/etc/vop/web.conf.sh

if [[ -f $CONFIG_FILE ]]; then
  . $CONFIG_FILE
fi

bundle exec rails s

cd -
