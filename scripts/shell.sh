#!/bin/bash

export DISABLE_SPRING=1

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

bundle exec rails runner 'Vop::Shell.run($vop)' "$*"

cd -
