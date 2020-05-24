#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIR2="$( dirname "$( readlink -f "$0" )" )"
echo "$DIR"
echo "$DIR2"