#!/usr/bin/env bash

currentDir=$(pwd)

echo "Creating Links"

for folder in `ls $currentDir/stow`; do
	stow $folder --dir=$currentDir/stow --target=$HOME
	echo "created link for $folder"
done

echo "Links Done"

