#!/usr/bin/env bash

# TODO: build equivalent in powershell (and/or cmd-term, sigh) for windows (current setup works fo linux and _should_ work for macs)

echo -n "using Playdate-SDK: "
$PLAYDATE_SDK_PATH/bin/pdc --version || { echo "Playdate-SDK not found! Set the PLAYDATE_SDK_PATH environment variable first!"; exit 1; }

pushd .
cd ./examples

for dir in `ls --ignore "*.pdx" -1`
do
    echo "building example $dir"
    $PLAYDATE_SDK_PATH/bin/pdc ./$dir ./$dir.pdx
done

for dir in `ls -1d *.pdx`
do
    echo "copying example $dir"
    rm -r $PLAYDATE_SDK_PATH/Disk/Games/$dir || echo "WARNING: Could not remove old .PDX directory. OK if the first build or removed."
    cp -R $dir $PLAYDATE_SDK_PATH/Disk/Games/. || echo "ERROR: Could not copy .PDX directory to PlayData SDK game-folder."
done

popd
