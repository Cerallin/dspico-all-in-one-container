# Based on the official guide:
# https://github.com/LNH-team/dspico/blob/a02bacae774487c40c13dca4cfad7d59619c668a/GUIDE.md

FROM skylyrac/blocksds:slim-latest

# Set an environment variable for dlditool:
ENV DLDITOOL=/opt/wonderful/thirdparty/blocksds/core/tools/dlditool/dlditool

ARG OUTPUT_DIR=/output
ENV OUTPUT_DIR=${OUTPUT_DIR}
ENV OUTPUT_SD_DIR=${OUTPUT_DIR}/sdcard

WORKDIR /build

### 0. Prerequisites

# We will skip installing c#, because I rewrote the DSRomEncryptor with C.
# We still need blowfish tables before building this docker image, please 
# see the DSRomEncryptor README.
RUN apt update && apt upgrade -y \
    && apt install --no-install-recommends -y wget unzip python3 git libnewlib-arm-none-eabi gcc-arm-none-eabi libstdc++-arm-none-eabi-newlib cmake build-essential \
    && apt clean && rm -rf /var/lib/apt/lists/*

### Copy all source repositories into the container
COPY dspico-dldi        /build/dspico-dldi
COPY dspico-bootloader  /build/dspico-bootloader
COPY DSRomEncryptor-C   /build/DSRomEncryptor-C
COPY dspico-firmware    /build/dspico-firmware
COPY pico-launcher      /build/pico-launcher

# Download pico-loader resources
RUN wget -O /build/pico-loader.zip https://github.com/LNH-team/pico-loader/releases/latest/download/Pico_Loader_DSPICO.zip
RUN unzip /build/pico-loader.zip -d /build/pico-loader

# Static assets: _pico directory (themes, etc.) for SD card
COPY pico-launcher/_pico ${OUTPUT_SD_DIR}/_pico/

### Build everything and collect outputs

COPY Makefile /build/Makefile

VOLUME ${OUTPUT_DIR}
