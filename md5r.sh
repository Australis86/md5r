#!/usr/bin/env bash
#
# Dependencies:
#   bash 4+ (arrays and mapfile)
#   md5sum
#   find
#
# Copyright 2026 Joshua White
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

usage="$(basename "$0") [checksum file]

Generate or update an MD5 checksum file.

If no checksum file is provided, the script will default to 
checksums.md5 in the current working directory.

If the checksum file exists, it will check if any of the files 
referenced within have a modification time newer than the checksum file
and update the stored hashes for those files only.

If the file does not exist, it will create it and walk the directory 
tree, starting from the path of the checksum file."


# SETTINGS

set -eo pipefail


# GLOBALS


# TEMPORARY WORKSPACE


# FUNCTIONS

function gen_chk_file() {
    chkpath="$1"
    echo "Generating new checksum file:"
    echo "$chkpath"
    echo
    startpath="$PWD"
    
    # Extract the directory path and filename
    # Cannot use PWD here since we may have been provided a custom path
    basedir=`dirname "$chkpath"`
    chkfile=`basename "$chkpath"`
    
    # Change directory to the starting path, find all files recursively, 
    # hash them and sort the output file (so that it is in path order)
    # This keeps the paths in the checksum file relative; an 
    # alternative approach would be to pass the starting path to 
    # find and then remove it from the checksum file afterwards
    cd "$basedir"
    find -type f \( -not -name "$chkfile" \) -exec md5sum -b '{}' \; | sort -k2 > "$chkfile"
    ec=$?
    cd "$startpath"
    
    return $ec
}


function upd_chk_file() {
    chkpath="$1"
    echo "Updating checksum file:"
    echo "$chkpath"
    echo
    startpath="$PWD"
    
    # Temporary file to store updated file paths
    changed_files="$(mktemp)"
    temp_hashes="$(mktemp)"

    # Extract the directory path and filename
    # Cannot use PWD here since we may have been provided a custom path
    basedir=`dirname "$chkpath"`
    chkfile=`basename "$chkpath"`

    # Logic based on ridgy's answer provided at 
    # https://askubuntu.com/questions/990495/update-md5-checksum-when-files-are-modified

    # Identify files that have been modified after the checksum file
    cd "$basedir"    
    find -type f -newer "$chkpath" -print > "$changed_files"
    ec=$?
    
    if [ $ec -ne 0 ]; then return $ec; fi
    
    # Loop through the list of changed files
    cat "$changed_files" | while read filepath; do
        # Append new hash to temporary checksum file
        md5sum -b "$filepath" >> "$temp_hashes"
    done

    # Loop through original checksum file and delete rows 
    # corresponding to removed or updated files
    cat "$chkfile" | while read hash filepath; do
        # Strip the leading asterisk (if present) from filepath
        # provided from checksum file
        cleaned_path=`echo "$filepath" | sed 's/^\*//'`
        
        # Check if file still exists
        if [ -f "$cleaned_path" ]; then
            # Check if modified
            if grep -q -e "$filepath" "$temp_hashes"; then
                # File updated
                echo "$cleaned_path" updated
            else
                # Use original hash
                echo "$hash $filepath" >> "$temp_hashes"
            fi
        else
            echo "$cleaned_path was removed"
        fi
    done

    # Replace the original checksum file
    cat "$temp_hashes" | sort -k2 > "$chkfile"

    # Return to original working directory
    cd "$startpath"
}


# CLI

# Set the checksum file path variable
if [ -z "$1" ]; then
    chkpath="$PWD/checksums.md5"
else
    chkpath="$1"
fi


# MAIN

if [ ! -f "$chkpath" ]; then
    # Checksum file doesn't exist, so generate it
    gen_chk_file "$chkpath"
else
    # Checksum file exists, so update it
    upd_chk_file "$chkpath"
fi
