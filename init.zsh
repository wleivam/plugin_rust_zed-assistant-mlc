#!/usr/bin/env zsh

declare -r dir_plugin="mlc-ai"
declare -r dir_repository="zed"
declare -r tag_version=$(tail -n 1 "releases.tags") # Latest tag supported by the plugin
declare -r url_repository="https://github.com/zed-industries/zed"

# Clone/Pull Repository
if [ -d $dir_repository ]
then
    cd $dir_repository
    if [ $tag_version != $(git describe --exact-match --tags) ]
    then
        git reset --hard
        git checkout tags/$tag_version
    fi
    cd ..
else
    git clone --recursive $url_repository $dir_repository
    cd $dir_repository
    git checkout tags/$tag_version
    cd ..
fi

for file_action in $(find $dir_plugin | awk -F $dir_plugin'/' '{print $NF}' | grep --extended-regexp ".*\.(copy|link|patch)$")
do
    action=$(echo $file_action | awk -F '.' '{print $NF}')
    file_path_name=$(echo $file_action | awk -F '.'$action '{print $1}')
    file_name=$(echo $file_path_name | awk -F '/' '{print $NF}')
    file_dir=$(echo $file_path_name | awk -F '/'$file_name '{print $1}')
    case $action in
    "copy")
        # Copy new files
        if [ ! -d $dir_repository/$file_dir ]
        then
            mkdir -p $dir_repository/$file_dir
        fi
        cp -f "$dir_plugin/$file_action" "$dir_repository/$file_path_name"
        ;;
    "link")
        # Create symbolic links
        ln -sF "$(cat $dir_plugin/$file_action)" "$dir_repository/$file_path_name"
        ;;
    "patch")
        # Patch existent files
        patch --version-control=none "$dir_repository/$file_path_name" "$dir_plugin/$file_action"
        ;;
    esac
done
unset action
unset file
unset file_dir
unset file_name
unset file_path_name

cd $dir_repository
cargo build
./target/debug/zed
