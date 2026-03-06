# Build all DSpico components and collect outputs.
# This Makefile is intended to run inside the Docker container
# after all source repos have been COPY'd to $(WORKDIR).
#
# Based on the official guide:
# https://github.com/LNH-team/dspico/blob/a02bacae774487c40c13dca4cfad7d59619c668a/GUIDE.md

NPROC		:= $(shell nproc)
WORKDIR		:= /build
OUTPUT_DIR	?= /output
OUTPUT_SD_DIR	?= $(OUTPUT_DIR)/sdcard
DLDITOOL	?= /opt/wonderful/thirdparty/blocksds/core/tools/dlditool/dlditool
WRFU_TESTER_V060 ?= /data/WRFUTester_v0.60_20080821.srl

# Source directories (COPY'd by Dockerfile)
DLDI_DIR	:= $(WORKDIR)/dspico-dldi
BOOT_DIR	:= $(WORKDIR)/dspico-bootloader
WRFUXXED_DIR	:= $(WORKDIR)/dspico-wrfuxxed
ENCRYPTOR_DIR	:= $(WORKDIR)/DSRomEncryptor-C
FIRMWARE_DIR	:= $(WORKDIR)/dspico-firmware
LOADER_DIR	:= $(WORKDIR)/pico-loader
LAUNCHER_DIR	:= $(WORKDIR)/pico-launcher

# Build artifacts (intermediates)
DLDI		:= $(DLDI_DIR)/DSpico.dldi
BOOTLOADER	:= $(BOOT_DIR)/BOOTLOADER.nds
WRFUXXED	:= $(WRFUXXED_DIR)/uartBufv060.bin
ENCRYPTOR	:= $(ENCRYPTOR_DIR)/build/DSRomEncryptor
DEFAULT_NDS	:= $(ENCRYPTOR_DIR)/default.nds
FIRMWARE_UF2	:= $(FIRMWARE_DIR)/build/DSpico.uf2
LOADER7		:= $(LOADER_DIR)/picoLoader7.bin
LOADER9		:= $(LOADER_DIR)/picoLoader9.bin
APLIST		:= $(LOADER_DIR)/aplist.bin
SAVELIST	:= $(LOADER_DIR)/savelist.bin
PATCHLIST	:= $(LOADER_DIR)/patchlist.bin
LAUNCHER	:= $(LAUNCHER_DIR)/LAUNCHER.nds

# Final output targets
OUT_UF2		:= $(OUTPUT_DIR)/DSpico.uf2
OUT_PICOBOOT	:= $(OUTPUT_SD_DIR)/_picoboot.nds
OUT_LOADER7	:= $(OUTPUT_SD_DIR)/_pico/picoLoader7.bin
OUT_LOADER9	:= $(OUTPUT_SD_DIR)/_pico/picoLoader9.bin
OUT_APLIST	:= $(OUTPUT_SD_DIR)/_pico/aplist.bin
OUT_SAVELIST	:= $(OUTPUT_SD_DIR)/_pico/savelist.bin
OUT_PATCHLIST	:= $(OUTPUT_SD_DIR)/_pico/patchlist.bin

.PHONY: all clean firmware sdcard theme

all: firmware sdcard theme
	@echo "[>] Build complete!"
	@echo "    Firmware: $(OUT_UF2)"
	@echo "    SD card:  $(OUTPUT_SD_DIR)/"

firmware: $(OUT_UF2)

sdcard: $(OUT_PICOBOOT) $(OUT_LOADER7) $(OUT_LOADER9) $(OUT_APLIST) $(OUT_SAVELIST) $(OUT_PATCHLIST)

theme:
	@echo "[>] Building theme..."
	cp -r $(LAUNCHER_DIR)/_pico/themes $(OUTPUT_SD_DIR)/_pico/
	@echo "    Theme files copied to $(OUTPUT_SD_DIR)/_pico/"

# ──────────────────────────────────────
# DSpico DLDI
# ──────────────────────────────────────
$(DLDI):
	@echo "[>] Building DSpico DLDI..."
	$(MAKE) -C $(DLDI_DIR) -j$(NPROC)

# ──────────────────────────────────────
# DSpico Bootloader + DLDI patch + encrypt
# ──────────────────────────────────────
$(BOOTLOADER):
	@echo "[>] Building DSpico Bootloader..."
	$(MAKE) -C $(BOOT_DIR) -j$(NPROC)

$(BOOTLOADER).patched: $(BOOTLOADER) $(DLDI)
	@echo "[>] DLDI patching bootloader..."
	$(DLDITOOL) $(DLDI) $(BOOTLOADER)
	@cp $(BOOTLOADER) $@

$(ENCRYPTOR):
	@echo "[>] Building DSRomEncryptor..."
	mkdir -p $(ENCRYPTOR_DIR)/build
	find /data -maxdepth 1 -type f -exec cp {} $(ENCRYPTOR_DIR)/build/ \;
	cd $(ENCRYPTOR_DIR)/build && cmake .. && $(MAKE) -j$(NPROC)

$(DEFAULT_NDS): $(BOOTLOADER).patched $(ENCRYPTOR)
	@echo "[>] Encrypting bootloader -> default.nds..."
	cd $(ENCRYPTOR_DIR) && $(ENCRYPTOR) $(BOOTLOADER).patched default.nds

# ──────────────────────────────────────
# DSpico WRFUxxed
# ──────────────────────────────────────
$(WRFUXXED): $(DLDI)
	@echo "[>] Building DSpico WRFUxxed..."
	$(MAKE) -C $(WRFUXXED_DIR) -j$(NPROC)
	$(DLDITOOL) $(DLDI) $(WRFUXXED)

# ──────────────────────────────────────
# DSpico Firmware
# ──────────────────────────────────────
$(FIRMWARE_UF2): $(DEFAULT_NDS) $(WRFUXXED)
	@echo "[>] Building DSpico Firmware..."
	cp $(DEFAULT_NDS) $(FIRMWARE_DIR)/roms/
	cp $(WRFU_TESTER_V060) $(FIRMWARE_DIR)/roms/dsimode.nds
	cp $(WRFUXXED) $(FIRMWARE_DIR)/data/
	sed -i 's/#DSPICO_ENABLE_WRFUXXED/DSPICO_ENABLE_WRFUXXED/' $(FIRMWARE_DIR)/CMakeLists.txt
	cd $(FIRMWARE_DIR) && chmod +x compile.sh && ./compile.sh

# ──────────────────────────────────────
# Pico Launcher
# ──────────────────────────────────────
$(LAUNCHER):
	@echo "[>] Building Pico Launcher..."
	$(MAKE) -C $(LAUNCHER_DIR) -j$(NPROC)

# ──────────────────────────────────────
# Collect outputs
# ──────────────────────────────────────
$(OUT_UF2): $(FIRMWARE_UF2) | $(OUTPUT_DIR)
	cp $< $@

$(OUT_PICOBOOT): $(LAUNCHER) | $(OUTPUT_SD_DIR)
	cp $< $@

$(OUT_LOADER7): $(LOADER7) | $(OUTPUT_SD_DIR)/_pico
	cp $< $@

$(OUT_LOADER9): $(LOADER9) | $(OUTPUT_SD_DIR)/_pico
	cp $< $@

$(OUT_APLIST): $(APLIST) | $(OUTPUT_SD_DIR)/_pico
	cp $< $@

$(OUT_SAVELIST): $(SAVELIST) | $(OUTPUT_SD_DIR)/_pico
	cp $< $@

$(OUT_PATCHLIST): $(PATCHLIST) | $(OUTPUT_SD_DIR)/_pico
	cp $< $@

# Directory creation (order-only prerequisites)
$(OUTPUT_DIR) $(OUTPUT_SD_DIR) $(OUTPUT_SD_DIR)/_pico:
	mkdir -p $@

clean:
	-$(MAKE) -C $(DLDI_DIR) clean
	-$(MAKE) -C $(BOOT_DIR) clean
	-rm -rf $(ENCRYPTOR_DIR)/build $(DEFAULT_NDS)
	-rm -rf $(FIRMWARE_DIR)/build
	-$(MAKE) -C $(LOADER_DIR) clean
	-$(MAKE) -C $(LAUNCHER_DIR) clean
	-rm -rf $(OUTPUT_DIR)
