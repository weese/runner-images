#!/bin/bash -e -o pipefail

source ~/utils/utils.sh

# Close all finder windows because they can interfere with UI tests
close_finder_window

# Remove Parallels Desktop
# https://github.com/actions/runner-images/issues/6105
if is_Monterey; then
    brew uninstall parallels
fi

# Put documentation to $HOME root
#cp $HOME/image-generation/output/software-report/systeminfo.* $HOME/

# Put build vm assets scripts to proper directory
sudo mkdir -p /usr/local/opt/$USER/scripts
sudo chown -R $USER /usr/local/opt/$USER
mv $HOME/image-generation/assets/* /usr/local/opt/$USER/scripts

find /usr/local/opt/$USER/scripts -type f -name "*\.sh" -exec chmod +x {} \;

# Remove fastlane cached cookie
rm -rf ~/.fastlane

# Clean up npm cache which collected during image-generation
# we have to do that here because `npm install` is run in a few different places during image-generation
npm cache clean --force

# Clean yarn cache
yarn cache clean

# Clean up temporary directories
sudo rm -rf ~/utils /tmp/*

# Erase all indexes and wait until the rebuilding process ends,
# for now there is no way to get status of indexing process, it takes around 3 minutes to accomplish
# sudo mdutil -E /
# sudo log stream | grep -q -E 'mds.*Released.*BackgroundTask' || true
# echo "Indexing completed"

# delete symlink for tests running
sudo rm -f /usr/local/bin/invoke_tests

# In our base image there is no runner user, so let's link it to the admin user's home
sudo ln -s /Users/admin /Users/runner

# link toolcache /Users/admin/hostedtoolcache to /Users/admin/actions-runner/_work/_tool
mkdir -p /Users/admin/actions-runner/_work
ln -s /Users/admin/hostedtoolcache /Users/admin/actions-runner/_work/_tool
