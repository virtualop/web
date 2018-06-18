#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

bundle exec rails runner LogHelper.message_pump

cd -
