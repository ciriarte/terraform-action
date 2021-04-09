#! /usr/bin/env bash

echo "Hello $1"
time=$(date)
echo "::set-output name=time::$time"

/opt/resource/out