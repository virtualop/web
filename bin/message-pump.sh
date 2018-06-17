#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

bundle exec rails runner "LogHelper.redis_to_action_cable"

cd -
