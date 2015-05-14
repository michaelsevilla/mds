#!/bin/bash
overlay=0
data=$1

if [ "$#" -lt 1 ]; then
  echo "Feed me a filename. Nom nom."
  echo "USAGE: $0 <file>"
  exit
fi

args=""
for file in "$@"; do
  f=${file%.dat}
  args=" $args $file"
  if [ "$overlay" -eq 0 ]; then args=" $args -x 2 --field-format=2,date,HH:mm:ss --x-format=date,HH:mm:ss" ; fi
  if [ "$#" -ne 1 ]; then args=" $args -f $f-rename,$f-setattr,$f-create,$f-mkdir,$f-symlink,$f-getattr,$f-lookup,$f-readdir,$f-unlink,$f-open"
  else args=" $args -f rename,setattr,create,mkdir,symlink,getattr,lookup,readdir,unlink,open" ; fi
  args=" $args -s 3,4,5,6,7,8,9,10,11,12"
done
tailplot $args
