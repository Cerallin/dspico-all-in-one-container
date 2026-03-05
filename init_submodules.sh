#!/usr/bin/env bash

git submodule update --init

cd dspico-bootloader
git submodule update --init
cd ..

# Note that you shouldn't use --recursive because it draws in a lot of 
# unnecessary submodules inside the pico-sdk.
cd dspico-firmware
git submodule update --init
cd pico-sdk
git submodule update --init
cd ../..

cd pico-launcher
git submodule update --init
cd ..
