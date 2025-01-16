#!/usr/bin/env bash

set -ex

echo "***** Start: Testing Miniforge installer *****"

export CONDA_PATH="${HOME}/miniforge"

CONSTRUCT_ROOT="${CONSTRUCT_ROOT:-${PWD}}"

cd "${CONSTRUCT_ROOT}"

echo "***** Get the installer *****"
ls build/
if [[ "$(uname)" == MINGW* ]]; then
   EXT="exe";
else
   EXT="sh";
fi
INSTALLER_PATH=$(find build/ -name "*forge*.${EXT}" | head -n 1)
INSTALLER_NAME=$(basename "${INSTALLER_PATH}" | cut -d "-" -f 1)
INSTALLER_EXE=$(basename "${INSTALLER_PATH}")

echo "***** Run the installer *****"
chmod +x "${INSTALLER_PATH}"
if [[ "$(uname)" == MINGW* ]]; then
  echo "start /wait \"\" ${INSTALLER_PATH} /InstallationType=JustMe /RegisterPython=0 /S /D=$(cygpath -w "${CONDA_PATH}")" > install.bat
  cmd.exe //c install.bat

  echo "***** Setup conda *****"
  # Workaround a conda bug where it uses Unix style separators, but MinGW doesn't understand them
  export PATH=$CONDA_PATH/Library/bin:$PATH
  # shellcheck disable=SC1091
  source "${CONDA_PATH}/Scripts/activate"
  conda.exe config --set show_channel_urls true

  echo "***** Print conda info *****"
  conda.exe info
  conda.exe list

  echo "***** Check if we are bundling packages from msys2 or defaults *****"
  conda.exe list | grep defaults && exit 1
  conda.exe list | grep msys2 && exit 1

  echo "***** Check if we can install a package which requires msys2 *****"
  conda.exe install r-base --yes --quiet
  conda.exe list
else
  # Test one of our installers in batch mode
  if [[ "${INSTALLER_NAME}" == "Mambaforge" ]]; then
    sh "${INSTALLER_PATH}" -b -p "${CONDA_PATH}"
  # And the other in interactive mode
  else
    # Test interactive install. The install will ask the user to
    # - newline -- read the EULA
    # - yes -- then accept
    # - ${CONDA_PATH} -- Then specify the path
    # - no -- Then whether or not they want to initialize conda
    cat <<EOF | sh "${INSTALLER_PATH}"

yes
${CONDA_PATH}
no
EOF
  fi

  echo "***** Setup conda *****"
  # shellcheck disable=SC1091
  source "${CONDA_PATH}/bin/activate"

  echo "***** Print conda info *****"
  conda info
  conda list
fi

echo "***** Python path *****"
python -c "import sys; print(sys.executable)"
python -c "import sys; assert 'miniforge' in sys.executable"

echo "***** Print system informations from Python *****"
python -c "print('Hello Miniforge !')"
python -c "import platform; print(platform.architecture())"
python -c "import platform; print(platform.system())"
python -c "import platform; print(platform.machine())"
python -c "import platform; print(platform.release())"

echo "***** Done: Testing installer *****"
