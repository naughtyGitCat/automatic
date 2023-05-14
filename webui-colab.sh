#!/usr/bin/env bash
#################################################
# Please do not make any changes to this file,  #
# change the variables in webui-user.sh instead #
#################################################

# change to local directory
cd -- "$(dirname -- "$0")"

can_run_as_root=1
export ERROR_REPORTING=FALSE
export PIP_IGNORE_INSTALLED=0

# Read variables from webui-user.sh
if [[ -f webui-user.sh ]]
then
    source ./webui-user.sh
fi

# python3 executable
if [[ -z "${python_cmd}" ]]
then
    python_cmd="python3"
fi

# git executable
if [[ -z "${GIT}" ]]
then
    export GIT="git"
fi

if [[ -z "${venv_cmd}" ]]
then
    venv_cmd="virtualenv"
fi

if [[ -z "${venv_dir}" ]]
then
    venv_dir="venv"
fi


# read any command line flags to the webui.sh script
while getopts "f" flag > /dev/null 2>&1
do
    case ${flag} in
        f) can_run_as_root=1;;
        *) break;;
    esac
done

# Do not run as root
if [[ $(id -u) -eq 0 && can_run_as_root -eq 0 ]]
then
    echo "Cannot run as root"
    exit 1
fi

for preq in "${GIT}" "${python_cmd}"
do
    if ! hash "${preq}" &>/dev/null
    then
        printf "Error: %s is not installed, aborting...\n" "${preq}"
        exit 1
    fi
done

if ! "${venv_cmd}" -h &>/dev/null
then
    echo "Error: virtualenv is not installed"
    exit 1
fi

echo "Create and activate python venv"
if [[ ! -d "${venv_dir}" ]]
then
   "${venv_cmd}" "${venv_dir}"
    first_launch=1
fi

if [[ -f "${venv_dir}"/bin/activate ]]
then
    source "${venv_dir}"/bin/activate
else
    echo "Error: Cannot activate python venv"
    exit 1
fi

if [[ ! -d "/content/ImageReward/" ]]
then
  source "${venv_dir}"/bin/activate
  git clone https://github.com/THUDM/ImageReward.git
  %cd /content/ImageReward
  pip install image-reward
fi

if [[ ! -d "/content/automatic/models/Stable-diffusion" ]]
then
  mkdir -p /content/automatic/models/Stable-diffusion
fi

if [[ ! -f "/content/automatic/models/Stable-diffusion/majicmixRealistic_v4.safetensors" ]]
then
  wget https://civitai.com/api/download/models/55911 -O /content/automatic/models/Stable-diffusion/majicmixRealistic_v4.safetensors
fi



if [[ ! -z "${ACCELERATE}" ]] && [ ${ACCELERATE}="True" ] && [ -x "$(command -v accelerate)" ]
then
    echo "Accelerating launch.py..."
    exec accelerate launch --num_cpu_threads_per_process=6 launch.py "$@"
else
    echo "Launching launch.py..."
    exec "${python_cmd}" launch.py "$@"
fi
