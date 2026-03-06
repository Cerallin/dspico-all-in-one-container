## DSpico all in one container

This repo is to build all things following the [DSpico guide](https://github.com/LNH-team/dspico/blob/develop/GUIDE.md)

## Building

1. Ensure files containing the NTR and TWL blowfish tables are in `binaries`. Please see [DSRomEncryptor README](https://github.com/Gericom/DSRomEncryptor/blob/develop/README.md).
2. Ensure a WRFU Tester v0.60 in `binaries`. Please see [WRFUxxed README](https://github.com/LNH-team/dspico-wrfuxxed/blob/develop/README.md).
3. Run `./init_submodules.sh` to initialize the submodules.
4. Run `./build_all.sh` to build the container and run it.
5. Run `make` with the container.

Now the built files will be in the `output` directory, including a firmware, and a directory `sdcard` containing the files to be copied to the SD card.

## TODOs

- [ ] Add option for WRFUxxed.
- [ ] Add option for building the firmware with other executables.
