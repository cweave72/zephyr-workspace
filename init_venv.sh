if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "Error: Script must be sourced."
    exit
fi

# SCRIPTPATH will be set to the path of this script.
SCRIPTPATH=$(dirname $(realpath "${BASH_SOURCE[0]}"))

function activate_env {
    source $1/bin/activate 2>/dev/null
    if [ ! $? -eq 0 ]; then
        return 1
    fi
}

PY3=python3.10
PROMPT=venv
VENV_DIR=.venv

activate_env $VENV_DIR
if [ $? -eq 0 ]; then
    echo "Successfully activated venv."
    #echo "Sourcing zephyr-env.sh"
    #source deps/zephyr/zephyr-env.sh
    #echo $ZEPHYR_BASE
    return 0
fi

echo "Creating virtual environment in $VENV_DIR."
$PY3 -m venv --prompt=$PROMPT $VENV_DIR
if [ ! $? -eq 0 ]; then
    echo "Error creating virtual env."
    return 1
fi

activate_env $VENV_DIR
pip install -r requirements.txt --log pip.log

if [ -f zephyr/scripts/requirements.txt ]; then
    echo "Installing zephyr requirements."
    pip install -r zephyr/scripts/requirements.txt
fi

