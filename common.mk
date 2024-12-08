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

ifdef PRISTINE
    WEST_OPTS += -p
endif

export NANOPB_BASE = $(abspath $(BASEDIR)/deps/optional/nanopb)
export COMMON_BASE = $(abspath $(BASEDIR)/common)
export COMMON_PROTO_BASE = $(COMMON_BASE)/proto
export COMMON_MAKE_SCRIPTS = $(COMMON_BASE)/scripts/make

BOARDS := $(notdir $(wildcard boards/*.overlay))
BOARD_ROOT := $(abspath $(BASEDIR)/common)

# Macro to invoke west within the virtual environment.
define invoke_west
   @(\
   source $(BASEDIR)/utils.sh; \
   source $(BASEDIR)/deps/zephyr/zephyr-env.sh; \
   source $(BASEDIR)/workspace-env.sh; \
   init_ws init_venv.sh; \
   echo "Running west $(ARGS)"; \
   west $(WEST_CMD) $(WEST_OPTS) $(ARGS); \
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
	@echo "  mon        : Runs monitor (esp32 support only)"
	@echo "  boards     : List supported boards for zephyr."
	@echo "  appboards  : List supported boards for application."
	@echo "  menuconfig : Runs menuconfig utility."
	@echo "  commonprotos : Builds python bindings for common proto files."
	@echo "  clean      : Cleans build directory."
	@echo ""
	@echo "Examples: Building, flashing, monitoring"
	@echo "  make BOARD=esp32s3_matrix [PRISTINE=y] build"
	@echo "  make flash"
	@echo "  make mon"
	@echo "  make flash mon"
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

.PHONY: flash flashmon mon
flash: 
	@$(eval WEST_CMD=flash)
	@$(invoke_west)

mon:
	@$(eval WEST_CMD=$(EXT_CMD) monitor)
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
