#!/usr/bin/env bash

set -e

install_path="~/.local/bin"
build_path="/Users/admin/Documents/Development/Bioinformatics/Projects/blast_parser/build/Products/Debug/blast_parser"

cd "$install_path"
ditto "$build_path" ./blast_parser