#! /bin/sh

# if [  $# -ne 1 ] ; then
#     echo "Usage: setup.sh targetdir"
#     exit 1
# fi

mkdir RCS
mkdir session
mkdir cache
mkdir attach
mkdir text

chmod 777 RCS session cache attach text
