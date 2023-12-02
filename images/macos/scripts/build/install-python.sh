#!/bin/bash -e -o pipefail
################################################################################
##  File:  install-python.sh
##  Desc:  Install Python
################################################################################

source ~/utils/utils.sh
arch=$(get_arch)

echo "Installing Python Tooling"

if is_Monterey || is_BigSur; then
    echo "Install latest Python 2"
    python2_pkg=$(download_with_retry "https://www.python.org/ftp/python/2.7.18/python-2.7.18-macosx10.9.pkg")

    choice_changes_xml=$(mktemp /tmp/python2_choice_changes.xml.XXXXXX)
    sudo installer -showChoiceChangesXML -pkg "$python2_pkg" -target / | tee "$choice_changes_xml" > /dev/null

    # To avoid symlink conflicts, remove tools installation in /usr/local/bin using installer choices
    xmllint --shell "$choice_changes_xml" <<EOF
    cd //array/dict[string[text()='org.python.Python.PythonUnixTools-2.7']]/integer
    set 0
    save
EOF

    sudo installer -applyChoiceChangesXML "$choice_changes_xml" -pkg "$python2_pkg" -target /

    pip install --upgrade pip

    echo "Install Python2 certificates"
    bash -c "/Applications/Python\ 2.7/Install\ Certificates.command"
fi

# Close Finder window
if is_Veertu; then
    close_finder_window
fi

echo "Brew Installing Python 3"
brew_smart_install "python@3.11"

echo "Installing pipx"
if [ $arch == "arm64" ]; then
    export PIPX_BIN_DIR=/opt/homebrew/opt/pipx/bin
    export PIPX_HOME=/opt/homebrew/opt/pipx
else
    export PIPX_BIN_DIR=/usr/local/opt/pipx_bin
    export PIPX_HOME=/usr/local/opt/pipx
fi

brew_smart_install "pipx"

echo "export PIPX_BIN_DIR=${PIPX_BIN_DIR}" >> "${HOME}/.bashrc"
echo "export PIPX_HOME=${PIPX_HOME}" >> "${HOME}/.bashrc"
echo 'export PATH="$PIPX_BIN_DIR:$PATH"' >> "${HOME}/.bashrc"

#invoke_tests "Python"
