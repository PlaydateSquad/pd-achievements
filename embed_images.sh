#!/usr/bin/env bash

# TODO: build equivalent in powershell (and/or cmd-term, sigh) for windows (current setup works fo linux and _should_ work for macs)

echo "NOTE: Running this script should only be necesary whenever the base default _fallback_ icons are updated by maintainers of the library."
echo "      Setting custom default icons for your game can be done by simply adding 'defaultIcon' and 'defaultIconLocked' fields in your initialization-data."

if [[ $# -ne 2 ]]; then
    echo "Please specify the filename of the image to be used as the default (unlocked) icon as the 1st argument, and similar for the (default) locked icon as the 2nd argument." >&2
    exit 2
fi

python ./maintainer_resources/embed_images.py --image-file $1 b64_default_icon --image-file $2 b64_default_locked --embed-into ./toast_graphics.lua
