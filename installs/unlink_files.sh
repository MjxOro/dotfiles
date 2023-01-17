#!/usr/bin/env bash

currentDir=$(pwd)

echo "Removing Links"

for folder in `ls $currentDir/stow`; do
	stow -D $folder --dir=$currentDir/stow --target=$HOME
	echo "removed link for $folder"
done

echo "Removing Links Done"

