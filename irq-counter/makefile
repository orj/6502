# VASM is used to compile
VASM_BINARY=../tools/vasm/vasm6502_oldstyle

# MiniPro will be used to upload the ROM
MINIPRO_BINARY=minipro
EEPROM_MODEL=AT28C256

# Hexdump is used for "testing" the ROM
HEXDUMP_BINARY=hexdump
HEXDUMP_FLAGS=-C

# Standard utilities (rm/mkdir)
RM_BINARY=rm
MKDIR_BINARY=mkdir

# Build folder
BUILD_FOLDER=build

# Source files to be compiled
SOURCES = main.s

# Resulting binary file (ROM to be uploaded)
FIRMWARE_BINARY=$(BUILD_FOLDER)/firmware.bin

$(VASM_BINARY):
	cd ../tools/vasm && make CPU=6502 SYNTAX=oldstyle

# Build the folder if doesn't exist
$(BUILD_FOLDER):
	$(MKDIR_BINARY) $(BUILD_FOLDER)

# Assemble sources
$(FIRMWARE_BINARY): $(SOURCES) $(BUILD_FOLDER) $(VASM_BINARY)
	$(VASM_BINARY) -wdc02 -dotdir -Fbin -o $@ -L $(@:.o=.lst) $<

# Standard build
all: $(FIRMWARE_BINARY)

# Display ROM contents
test: $(FIRMWARE_BINARY)
	$(HEXDUMP_BINARY) $(HEXDUMP_FLAGS) $<

# Burn ROM to EEPROM
install: $(FIRMWARE_BINARY)
	$(MINIPRO_BINARY) -p $(EEPROM_MODEL) -w $<

# Clean generated files
clean:
	$(RM_BINARY) -f $(BUILD_FOLDER)/firmware.*.bin $(BUILD_FOLDER)/*.o $(BUILD_FOLDER)/*.lst
