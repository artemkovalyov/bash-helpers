#!/bin/bash
# My first script

cat << _EOF_
This script switches XrandR configs on my laptop
_EOF_

XRNDR="xrandr"
# select all the active outputs from xrandr log
CONNECTED_OUTPUTS=$($XRNDR | grep " connected" | grep -o "\w*-[0-9]\b")

if [ $(id -u) = "0" ]; then
    echo "superuser"
fi

if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script" >&2
    #exit 1
fi

debug() {
  echo "Debug INFO: $1, $2"
}

# 1 pararm - layout config, 2 param - array of active ouputs
set_layout() {
  echo "${@:3}"
  case $1 in
    clone)
      $XRNDR --output $3 --mode 1920x1080
    ;;
    above)
      $XRNDR --output $3 --mode 1920x1080 --above $2
    ;;
    left)
      $XRNDR --output $3 --mode 1920x1080 --left-of $2
    ;;
    right)
      $XRNDR --output $3 --mode 1920x1080 --right-of $2
    ;;
    below)
      $XRNDR --output $3 --mode 1920x1080 --below $2
    ;;
    off)
      #switch off all the displays except the primary one (shift to the third param and loop through the outputs)
      for i in ${@:3}; do
        $XRNDR --output $i --off
      done
    ;;


  esac
}

debug $CONNECTED_OUTPUTS

set_layout $1 $CONNECTED_OUTPUTS
