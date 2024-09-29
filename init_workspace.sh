#!/bin/bash
# This script is run once from a clean workspace to pull Zephyr source.
# Source init_venv.sh to activate the venv or recreate it.
#
help() {
  cat << EOF
usage: $0 [OPTIONS]
    Initialize the workspace after a clean checkout or --reset.

    Options:
    -h, --help           Show this message
    -r, --reset          Reset the workspace, then init.
EOF
}

ask() {
  while true; do
    read -p "$1 ([y]/n) " -r
    REPLY=${REPLY:-"y"}
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      return 1
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      return 0
    fi
  done
}

function init_venv {
    source init_venv.sh
    if [ ! $? -eq 0 ]; then
        echo "Exiting after error."
        return 1
    fi
}

function west_steps {
    echo "Running west init"
    west init --local manifest-repo
    echo "Running west update"
    west update
    echo "Running west zephyr-export"
    west zephyr-export
    echo "Installing zephyr python req's."
    pip install -r deps/zephyr/scripts/requirements.txt
}

function reset {
    echo "Resetting workspace."
    rm -rf .venv/ .west/ deps/ applications/
    rm cscope.* tags *.log
}

do_reset=0
reset_wks=0

# Handle script arguments and options.
leftoverargs=()
for arg in "$@"; do
    case $arg in
        -r|--reset)
            reset_wks=1
            ;;
        -h|--help)
            help
            return 0
            ;;
        *)
            leftoverargs+=("$arg")
            shift
            ;;
    esac
done

if [[ $reset_wks == 1 ]]; then
    echo "Make sure you do not have any existing changes in applications/."
    ask "Do you really want to reset the workspace?"
    do_reset=$?
fi

if [[ $do_reset == 1 ]]; then
    reset
fi

init_venv && west_steps
