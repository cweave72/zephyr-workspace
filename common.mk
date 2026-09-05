THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

SHELL := /bin/bash

export BASEDIR ?= $(THIS_DIR)

# List of targets which cause parameter checks.
#skip_check_targets := west help boards clean flash mon appboards menuconfig

#ifneq ($(MAKECMDGOALS),)
#    ifeq ($(filter $(MAKECMDGOALS), $(skip_check_targets)), )
#        ifeq ($(BOARD),)
#            $(error "BOARD parameter must be provided")
#        endif
#    endif
#endif
    
# Default west build command.
WEST_BUILD_CMD := build -b $(BOARD)
ifeq ($(MAKECMDGOALS), build)
    ifeq ($(BOARD),)
	# If board not specified don't add -b option.
        WEST_BUILD_CMD := build
    endif
endif

EXT_CMD ?= espressif
WEST_CMD :=
WEST_OPTS :=

# Serial monitor. Espressif boards use west's built-in monitor command; other
# boards (e.g. w55rp20_evb_pico) have none, so setting PORT switches 'mon' to
# pyserial's miniterm, which is already in the venv. Exit miniterm with Ctrl+].
BAUD ?= 115200

ifdef PRISTINE
    WEST_OPTS += -p
endif

# Select a specific west runner for flash/debug (e.g. RUNNER=uf2 for rp2040
# boards, whose default runner is openocd).
ifdef RUNNER
    WEST_OPTS += -r $(RUNNER)
endif

# Zephyr snippets (see common/snippets). Space separated, build time only:
#   make BOARD=w55rp20_evb_pico SNIPPET="probe-console debug" build
# Snippets are applied at CMake configure time, so add PRISTINE=y when changing
# them on an existing build directory.
ifdef SNIPPET
    WEST_OPTS += $(foreach s,$(SNIPPET),-S $(s))
endif

# Separator introducing extra CMake arguments. Only emitted when there is
# something to pass: 'west build' ignores a trailing bare '--', but other
# subcommands reject it (e.g. "west boards: error: unexpected arguments: ['--']").
CMAKE_SEP :=
ifneq ($(strip $(CMAKE_OPTS)),)
    CMAKE_SEP := --
endif

export NANOPB_BASE = $(abspath $(BASEDIR)/deps/optional/nanopb)
export COMMON_BASE = $(abspath $(BASEDIR)/common)
export COMMON_PROTO_BASE = $(BASEDIR)/proto
export COMMON_MAKE_SCRIPTS = $(COMMON_BASE)/scripts/make

BOARDS := $(notdir $(wildcard boards/*.overlay))
BOARD_ROOT := $(abspath $(BASEDIR)/common)

# The board actually in play. BOARD is only given on 'build' -- flash, debug and
# attach take no -b -- so fall back to whatever the build dir was configured for.
# Strip any SoC/CPU qualifiers: 'esp32s3_matrix/esp32s3/procpu' -> 'esp32s3_matrix'.
BOARD_FROM_BUILD := $(shell sed -n 's/^CONFIG_BOARD="\(.*\)"/\1/p' $(CURDIR)/build/zephyr/.config 2>/dev/null)
EFF_BOARD := $(firstword $(subst /, ,$(or $(BOARD),$(BOARD_FROM_BUILD))))

# Extra options for the flash/debug family of subcommands. Boards add to this
# from their own board.mk (e.g. which OpenOCD to hand west); never applied to
# 'build'.
RUNNER_OPTS :=

# Per-board make settings, kept beside board.cmake in the board's own directory
# so a board stays self-contained. Optional -- most boards have none. The glob
# covers the vendor subdirectory, e.g.
#   common/boards/wiznet/w55rp20_evb_pico/board.mk
ifneq ($(EFF_BOARD),)
    -include $(wildcard $(BOARD_ROOT)/boards/*/$(EFF_BOARD)/board.mk)
endif

# Macro to invoke west within the virtual environment.
define invoke_west
   @(\
   source $(BASEDIR)/utils.sh; \
   source $(BASEDIR)/deps/zephyr/zephyr-env.sh; \
   source $(BASEDIR)/workspace-env.sh; \
   init_ws init_venv.sh; \
   echo "Running west"; \
   west $(WEST_CMD) $(WEST_OPTS) $(ARGS) $(CMAKE_SEP) $(CMAKE_OPTS); \
   )
endef

# Macro to invoke the virtual environment.
define invoke_venv
   @(\
   source $(BASEDIR)/utils.sh; \
   init_ws init_venv.sh; \
   $(VENV_CMD); \
   )
endef

.PHONY: help
help:
	@echo "Supported commands:"
	@echo "  build      : Runs a west build."
	@echo "  west       : Runs a west command."
	@echo "  flash      : Flashes a board."
	@echo "  debug      : Flashes, then starts gdb (needs a debug probe)."
	@echo "  attach     : Attaches gdb to a running target (no reflash)."
	@echo "  debugserver: Starts a gdb server on port 3333."
	@echo "  reset      : Restarts the image on the target (no reflash)."
	@echo "  run        : Runs when BOARD=qemu_*."
	@echo "  mon        : Runs serial monitor (west monitor for esp32; miniterm if PORT set)"
	@echo "  boards     : List supported boards for zephyr."
	@echo "  appboards  : List supported boards for application."
	@echo "  menuconfig : Runs menuconfig utility."
	@echo "  commonprotos : Builds python bindings for common proto files."
	@echo "  clean      : Cleans build directory."
	@echo ""
	@echo "Examples: Building, flashing, monitoring"
	@echo "  make BOARD=esp32s3_matrix [PRISTINE=y] build"
	@echo "  make BOARD=esp32s3_matrix [PRISTINE=y] build CMAKE_OPTS=\"-DCONFIG_SOMETHING=y\""
	@echo "  make flash"
	@echo "  make mon"
	@echo "  make flash mon"
	@echo ""
	@echo "Examples: non-Espressif boards"
	@echo "  make BOARD=w55rp20_evb_pico [PRISTINE=y] build"
	@echo "  make BOARD=w55rp20_evb_pico RUNNER=uf2 flash    (BOOTSEL; no probe needed)"
	@echo "  make PORT=/dev/ttyACM0 mon                     (console over USB-C; Ctrl+] to exit)"
	@echo ""
	@echo "Examples: w55rp20_evb_pico over SWD (Raspberry Pi Debug Probe)"
	@echo "  make BOARD=w55rp20_evb_pico PRISTINE=y SNIPPET=\"probe-console debug\" build"
	@echo "  make flash          (over SWD; no BOOTSEL, no mount)"
	@echo "  make debug          (gdb, breaks at main)"
	@echo "  make attach         (gdb, target left running)"
	@echo "  make debugserver    (gdb server on :3333)"
	@echo "  make reset          (restart the target, no reflash)"
	@echo ""
	@echo "Examples: west commands"
	@echo "  make west ARGS=\"--help\""
	@echo "  make west ARGS=\"boards\""
	@echo "  make west ARGS=\"help flash\""
	@echo ""

all:

.PHONY: west
west: 
	@$(invoke_west)

.PHONY: menuconfig
menuconfig:
	@$(eval WEST_CMD=build -t menuconfig)
	@$(invoke_west)


.PHONY: build
build: 
	@$(eval WEST_CMD=$(WEST_BUILD_CMD))
	@$(invoke_west)

.PHONY: run
run: 
	@$(eval WEST_CMD=build -t run)
	@$(invoke_west)

# West subcommands that drive a runner and so take RUNNER_OPTS (which the board's
# board.mk supplies, if it has one). All four are named after the west subcommand
# they invoke, so one rule covers them:
#   flash       program the board
#   debug       flash, then start gdb stopped at the reset vector
#   attach      attach gdb to a running target without reflashing
#   debugserver just the gdb server on port 3333, for VS Code or a separate gdb
# The last three need a debug-capable runner (a SWD probe on the rp2040 boards).
.PHONY: flash debug attach debugserver
flash debug attach debugserver:
	@$(eval WEST_CMD=$@ $(RUNNER_OPTS))
	@$(invoke_west)

# Restart the image already on the target, without reflashing it. Unlike the
# targets above this is not a west subcommand -- west has none -- so how to do it
# is board specific: a board supplies RESET_CMD from its own board.mk.
.PHONY: reset
reset:
ifeq ($(strip $(RESET_CMD)),)
	@echo "No reset command for board '$(EFF_BOARD)'."
	@echo "A board defines RESET_CMD in its board.mk; see"
	@echo "  common/boards/wiznet/w55rp20_evb_pico/board.mk"
	@false
else
	@echo "Resetting $(EFF_BOARD)."
	@$(RESET_CMD)
endif

.PHONY: flashmon mon

mon:
ifdef PORT
	@$(eval VENV_CMD=python -m serial.tools.miniterm --raw $(PORT) $(BAUD))
	@$(invoke_venv)
else
	@$(eval WEST_CMD=$(EXT_CMD) monitor)
	@$(invoke_west)
endif


test:
	@$(eval WEST_CMD = twister --no-clean --platform $(BOARD) -T .)
	@$(invoke_west)



.PHONY: appboards
appboards:
	@for bd in $(BOARDS); do \
	    echo $$bd; \
         done

.PHONY: boards
boards:
	@$(eval WEST_CMD=boards)
	@$(invoke_west)

.PHONY: clean
clean:
	@echo "Removing $(CURDIR)/build"
	@rm -rf $(CURDIR)/build
