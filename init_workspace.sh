#!/bin/bash
# This script is run once from a clean workspace to pull Zephyr source.
# Source init_venv.sh to activate the venv or recreate it.
source init_venv.sh
if [ ! $? -eq 0 ]; then
    echo "Exiting after error."
    exit 1
fi

echo "Running west init"
west init --local manifest-repo
echo "Running west update"
west update
echo "Running west zephyr-export"
west zephyr-export

echo "Installing zephyr python req's."
pip install -r deps/zephyr/scripts/requirements.txt
