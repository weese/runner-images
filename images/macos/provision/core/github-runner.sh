#!/bin/bash -e
################################################################################
##  File:  runner-package.sh
##  Desc:  Downloads and Installs runner package
################################################################################

get_github_package_download_url() {
    local REPO_ORG=$1
    local FILTER=$2
    local VERSION=$3
    local SEARCH_IN_COUNT="100"

    json=$(curl -fsSL "https://api.github.com/repos/${REPO_ORG}/releases?per_page=${SEARCH_IN_COUNT}")

    if [ -n "$VERSION" ]; then
        tagName=$(echo $json | jq -r '.[] | select(.prerelease==false).tag_name' | sort --unique --version-sort | egrep -v ".*-[a-z]|beta" | egrep "\w*${VERSION}" | tail -1)
    else
        tagName=$(echo $json | jq -r '.[] | select((.prerelease==false) and (.assets | length > 0)).tag_name' | sort --unique --version-sort | egrep -v ".*-[a-z]|beta" | tail -1)
    fi

    downloadUrl=$(echo $json | jq -r ".[] | select(.tag_name==\"${tagName}\").assets[].browser_download_url | select(${FILTER})" | head -n 1)
    if [ -z "$downloadUrl" ]; then
        echo "Failed to parse a download url for the '${tagName}' tag using '${FILTER}' filter"
        exit 1
    fi
    echo $downloadUrl
}

# Download runner package
DOWNLOAD_URL=$(get_github_package_download_url "actions/runner" 'test("actions-runner-osx-arm64-[0-9]+\\.[0-9]{3}\\.[0-9]+\\.tar\\.gz")')
FILE_NAME="${DOWNLOAD_URL##*/}"

curl -o /tmp/${FILE_NAME} -L ${DOWNLOAD_URL}

# Install GiHub runner agent
mkdir -p actions-runner
cd actions-runner
tar xzf /tmp/${FILE_NAME}
./config.sh --unattended --url $GITHUB_URL$GITHUB_ORG --token $RUNNER_TOKEN --name "$RUNNER_NAME" --replace --labels "$RUNNER_LABELS"

# Register service
./svc.sh install runner
./svc.sh start
