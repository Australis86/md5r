# md5r
Generate or update an MD5 checksum file.

## Background

MD5 hashes are still suitable for file integrity checks in most 
situations. A typical use case is a checksum file storing the hashes of
multiple files or a directory tree for later verification.

The purpose of this script was to address the situation where one or 
more files may be revised/updated (e.g. on a monthly basis) and 
automate the update of the MD5 hash in the checksum file (rather than 
manually replacing the hash for the affected files).

## Dependencies

- bash 4+
- md5sum (should be present on most *nix systems)

## Usage

The script will default to using `checksums.md5` in the current working 
directory, but can also accept a custom checksum file path as an 
optional argument.

If the checksum file exists, it will use the file modification time as a 
reference to add any new files and update the hashes for modified files.
If **strict mode** is specified, *only* pre-existing hashes will be 
updated (new files will not be added).

If the file does not exist, it will create it and walk the directory 
tree, starting from the path of the checksum file.

| parameter | example | description |
| --- | --- | --- |
| -s | | Strict mode; only update existing checksums in file, don't add new files |
| -v | | Boolean flag to enable verbose output |


# Copyright and Licence

Unless otherwise stated, these scripts are Copyright © Joshua White and 
licensed under the GNU GPL v3.0.
