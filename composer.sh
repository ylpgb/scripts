#!/bin/bash
TUNEDIR=~/temp/music
tunes=(
  "$TUNEDIR/a.wav"
  "$TUNEDIR/b.wav"
  "$TUNEDIR/c.wav"
  "$TUNEDIR/d.wav"
  "$TUNEDIR/e.wav"
  "$TUNEDIR/f.wav"
  "$TUNEDIR/g.wav"
)

function play_tune
{
  echo "num is $1"

  sox ${tunes[$1]} -d &
}


while true ; do
  ## get input and run sanity check
  read digit
  if [[ "$digit" > "7" ]] || [[ "$digit" < "1" ]] ; then
    echo " Invalid input"
    continue;
  fi
  echo "You selected $digit $(($digit-1))" 
  
  play_tune $(($digit-1))

done
