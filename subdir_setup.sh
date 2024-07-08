#!/bin/bash

echo "Executing subdirectories setup script"

directory=$1

echo "Argument: $directory"

# Find all directories at one level deep and exclude self
directories=$(find "$directory" -mindepth 1 -maxdepth 1 -type d | grep -v "^$directory$")

# Output each directory
for dir in $directories; do
    cd $dir
    echo "Directory to setup: $dir"
    echo "Running make setup"
    make setup
    echo "Setup complete"
    cd -
done