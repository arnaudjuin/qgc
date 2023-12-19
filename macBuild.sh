#!/bin/bash

# Change to the build directory
cd build/ || exit 1

# Run make with parallel jobs
make -j12
pwd
open ./release/CustomQGC.app