#!/usr/bin/env bash

# TODO: build equivalent in powershell (and/or cmd-term, sigh) for windows (current setup works fo linux and _should_ work for macs)

echo "NOTE: Running this script should only be necesary whenever the base default _fallback_ icons are updated by maintainers of the library."
echo "      Setting custom default icons for your game can be done by simply adding 'defaultIcon' and 'defaultIconLocked' fields in your initialization-data."

python  ./maintainer_resources/embed_images.py \
	--image-file  ./maintainer_resources/achievement-unlock.png    b64_default_icon    \
	--image-file  ./maintainer_resources/achievement-lock.png      b64_default_locked  \
	--image-file  ./maintainer_resources/achievement-secret.png    b64_default_secret  \
	--embed-into  ./toast_graphics.lua
