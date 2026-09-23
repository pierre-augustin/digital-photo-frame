#!/bin/bash

sleep 15

xset s off
xset -dpms
xset s noblank

unclutter -idle 0.5 -root &

feh --fullscreen --auto-zoom --hide-pointer --slideshow-delay 8 \
    --randomize --recursive \
    --on-last-slide resize \
    /home/pat/images /mnt/nas-photos
