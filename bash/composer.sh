#!/bin/bash
TUNEDIR=./tunes/piano/
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
  echo "Playing ${tunes[$1]}"

  sox -q ${tunes[$1]} -d &
}


while true ; do
  ## get input and run sanity check
  #read digit
  read -n 1 digit
  if [[ "$digit" > "7" ]] || [[ "$digit" < "1" ]] ; then
    echo " Invalid input"
    continue;
  fi
  #echo "You selected $digit $(($digit-1))" 
  
  play_tune $(($digit-1))

done
