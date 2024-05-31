#!/bin/bash
#set -x

# for manage container
https_proxy=http://localhost:13128 jwt-agent "$@"
