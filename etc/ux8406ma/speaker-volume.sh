#!/bin/bash

case $1 in
  up)
    amixer set 'Speaker' 5%+
    ;;
  down)
    amixer set 'Speaker' 5%-
    ;;
  mute)
    amixer set 'Speaker' toggle
    ;;
  *)
    echo "Uso: $0 {up|down|mute}"
    ;;
esac
