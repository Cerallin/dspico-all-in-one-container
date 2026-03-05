#!/usr/bin/env bash

DATA_DIR="encryptor-data"

NTR_BLOWFISH="ntrBlowfish.bin"
NTR_BLOWFISH_SHA1="84e467f2485078e401a17a5f231e3fe6e9686648"

NTR_BIOS="biosnds7.rom"
NTR_BIOS_SHA1="24f67bdea115a2c847c8813a262502ee1607b7df"

TWL_BLOWFISH="twlBlowfish.bin"
TWL_BLOWFISH_SHA1="2dea11191f28c6cc1956dadb8941affd4b2b5102"

TWL_BIOS="BIOSDSI7.ROM"
TWL_BIOS_INCOMPLETE_SHA1="a3aa751eb6bdaaf8a827ba9e03576a6f1ab0f547"
TWL_BIOS_COMPLETE_SHA1="c7c7570bfe51c3c7c5da3b01331b94e7e7cb4f53"

TWL_DEV_BLOWFISH="twlDevBlowfish.bin"
TWL_DEV_BLOWFISH_SHA1="cff62f24444f5494001f019d505f9c51d40fc8b3"

# check if a file exists and matches the expected sha1 checksum
checksum() {
	local file="$DATA_DIR/$1"
	local expected_sha1="$2"

	if [ ! -f "$file" ]; then
		return 1
	fi

	local actual_sha1=$(sha1sum "$file" | awk '{print $1}')
	if [ "$actual_sha1" != "$expected_sha1" ]; then
		echo "Error: Checksum mismatch for $file. Expected $expected_sha1 but got $actual_sha1." >&2
		return 1
	fi
}

# Check prerequisites for DsRomEncryptor
check_encryptor_prerequisites() {
	# Check for ntr blowfish
	if checksum "$NTR_BLOWFISH" "$NTR_BLOWFISH_SHA1"; then
		echo "Using ntr blowfish from ntrBlowfish.bin"
	elif checksum "$NTR_BIOS" "$NTR_BIOS_SHA1"; then
		echo "Using ntr blowfish from biosnds7.rom"
	else
		echo "Error: No ntr blowfish table found. Please provide either ntrBlowfish.bin or biosnds7.rom."
		return 1
	fi

	# Check twl blowfish with checksum
	if checksum "$TWL_BLOWFISH" "$TWL_BLOWFISH_SHA1"; then
		echo "Using twl blowfish from $TWL_BLOWFISH"
	elif [ -f "$DATA_DIR/$TWL_BIOS" ]; then
		echo "Found $TWL_BIOS, checking if it's complete..."
		if checksum "$TWL_BIOS" "$TWL_BIOS_COMPLETE_SHA1" 2>/dev/null; then
			echo "Using twl blowfish from $TWL_BIOS"
		elif checksum "$TWL_BIOS" "$TWL_BIOS_INCOMPLETE_SHA1" 2>/dev/null; then
            echo "Using incomplete twl blowfish from $TWL_BIOS"
		else
			echo "Error: $TWL_BIOS found but checksum does not match either complete or incomplete versions. Please provide a valid $TWL_BIOS."
			return 1
		fi
	else
		echo "Error: No twl blowfish table found. Please provide either $TWL_BLOWFISH or $TWL_BIOS."
		return 1
	fi

	# # Check twl dev blowfish with checksum
	# if checksum "$TWL_DEV_BLOWFISH" "$TWL_DEV_BLOWFISH_SHA1"; then
	# 	echo "Using twl dev blowfish from $TWL_DEV_BLOWFISH"
	# else
	# 	echo "Error: No twl dev blowfish table found. Please provide $TWL_DEV_BLOWFISH in the DSRomEncryptor directory."
	# 	return 1
	# fi

}

check_encryptor_prerequisites || exit 1

./init_submodules.sh

docker build -t dspico-all-in-one:latest .
docker run --rm -it \
	-v "$(pwd)/$DATA_DIR":/data \
	-v "$(pwd)/output":/output \
	dspico-all-in-one:latest \
	bash
