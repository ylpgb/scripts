#!/bin/bash

while true ; do
  ## get input and run sanity check
  read digit
  if [[ "$digit" > "g" ]] || [[ "$digit" < "a" ]] ; then
    echo " Invalid input"
    continue;
  fi
  echo "You selected $digit ($idx)" 
  
  case $digit in
  'a')
    sox a.wav -d &
    ;;
  'b')
    sox b.wav -d &
    ;;
  'c')
    echo "this is c"
    sox c.wav -d &
    ;;
  'd')
    echo "this is d"
    sox d.wav -d &
    ;;
  'e')
    echo "this is e"
    sox e.wav -d &
    ;;
  'f')
    echo "this is f"
    sox f.wav -d &
    ;;
  'g')
    echo "this is g"
    sox g.wav -d &
    ;;
  *)
    echo "this is others"
    ;;
  esac
done
