#!/bin/bash
# This script is run once from a clean workspace to pull Zephyr source.
# Source init_venv.sh to activate the venv or recreate it.

help() {
  cat << EOF
usage: $0 [OPTIONS]
    Initialize the workspace after a clean checkout or --reset.

    Options:
    -h, --help           Show this message
    --init               Run init steps.
    --venv               Update the python virtualenv.
    -m, --main           Switch applications/ to main branch.
    -r, --reset          Reset the workspace.
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

function install_zephyr_python_deps {
    # VirtualEnv should be activated prior to calling.
    echo "Installing zephyr python req's."
    pip install -r deps/zephyr/scripts/requirements.txt
}

function west_steps {
    echo "Running west init"
    west init --local manifest-repo
    echo "Running west update"
    west update
    echo "Running west zephyr-export"
    west zephyr-export
    echo "Fetching esp32 blobs."
    west blobs fetch hal_espressif
}

function reset {
    echo "Resetting workspace."
    rm -rf .venv/ .west/ deps/ applications/
    rm cscope.* tags *.log
}

do_init=0
do_reset=0
reset_wks=0
do_main=0
do_update_venv=0

# Handle script arguments and options.
leftoverargs=()
for arg in "$@"; do
    case $arg in
        --init)
            do_init=1
            ;;
        --venv)
            do_update_venv=1
            ;;
        -r|--reset)
            reset_wks=1
            ;;
        -m|--main)
            do_main=1
            ;;
        -h|--help)
            help
            exit 0
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

if [[ $do_init == 1 ]]; then
    ask "Do you really want to init the workspace?"
    if [[ $? == 1 ]]; then
        init_venv && install_zephyr_python_deps && west_steps
    fi
fi

if [[ $do_update_venv == 1 ]]; then
    echo "Updating python virtual env."
    rm -rf .venv/
    init_venv && install_zephyr_python_deps
fi

if [[ $do_main == 1 ]]; then
    git -C applications fetch
    git -C common fetch
    git -C applications checkout main
    git -C common checkout main
fi
