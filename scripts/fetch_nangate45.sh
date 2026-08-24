#!/usr/bin/env bash
set -euo pipefail
commit=b0353bd25da7d69562161e9f04b8b1353e40d9a3
destination=physical/lib/NangateOpenCellLibrary_typical.lib
mkdir -p physical/lib
if [[ ! -s "$destination" ]]; then
  curl -L --fail --retry 3 -o "$destination" \
    "https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/${commit}/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib"
fi
