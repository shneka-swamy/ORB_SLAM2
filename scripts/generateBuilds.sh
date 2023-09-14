#!/bin/bash
#

set -e

# export VCPKG_INSTALLED_DIR=/home/shnekam/Software/vcpkg/installed

# cmake -B cmake-build-debug -S . -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake
#
# cmake -B cmake-build-release -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake

cmake -B cmake-build-debug -S . -DCMAKE_BUILD_TYPE=Debug -G Ninja

cmake -B cmake-build-release -S . -DCMAKE_BUILD_TYPE=Release -G Ninja
