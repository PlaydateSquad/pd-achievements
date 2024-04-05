#!/usr/bin/env bash

# TODO: build equivalent in powershell (and/or cmd-term, sigh) for windows (current setup works fo linux and _should_ work for macs)

echo -n "using Playdate-SDK: "
$PLAYDATE_SDK_PATH/bin/pdc --version || { echo "Playdate-SDK not found! Set the PLAYDATE_SDK_PATH environment variable first!"; exit 1; }

echo "building test-game"
$PLAYDATE_SDK_PATH/bin/pdc ./test_game ./test_game.pdx

echo "copying test-game"
rm -r $PLAYDATE_SDK_PATH/Disk/Games/test_game.pdx || echo "WARNING: Could not remove old .PDX directory. OK if the first build or removed."
cp -R ./test_game.pdx $PLAYDATE_SDK_PATH/Disk/Games/test_game.pdx || echo "ERROR: Could not copy .PDX directory to PlayData SDK game-folder."
