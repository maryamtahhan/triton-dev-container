#!/bin/bash
#
# Copyright (C) 2024-2025 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

USER=${USERNAME:-triton}
USER_ID=${USER_UID:-1000}
GROUP_ID=${USER_GID:-1000}

navigate() {
    if [ -n "$TRITON_CPU_BACKEND" ] && [ "$TRITON_CPU_BACKEND" -eq 1 ]; then
        if [ -d "/opt/triton-cpu" ]; then
            cd /opt/triton-cpu || exit 1
        fi
    else
        if [ -d "/opt/triton" ]; then
            cd /opt/triton || exit 1
        fi
    fi
}
# Function to clone repo and install dependencies
install_dependencies() {
    if [ -n "$TRITON_CPU_BACKEND" ] && [ "$TRITON_CPU_BACKEND" -eq 1 ]; then
        if [ ! -d "/opt/triton-cpu" ]; then
            echo "/opt/triton-cpu not found. Cloning repository..."
            git clone https://github.com/triton-lang/triton-cpu.git /opt/triton-cpu
        fi
    else
        if [ ! -d "/opt/triton" ]; then
            echo "/opt/triton not found. Cloning repository..."
            git clone https://github.com/triton-lang/triton.git /opt/triton
        fi
    fi

    navigate

    git submodule init
    git submodule update

    echo "Installing Python dependencies..."
    pip install --upgrade pip

    if [ -n "$INSTALL_CUDNN" ] && [ "$INSTALL_CUDNN" = "true" ]; then
        echo "Installing CUDA dependencies..."
        python3 -m pip install nvidia-cudnn-cu12;
    fi

    echo "Installing pre-commit dependencies..."
    pip install pre-commit

    echo "Installing Triton dependencies..."
    pip install torch numpy matplotlib pandas tabulate scipy ninja cmake wheel pybind11

    pre-commit install
}

# Check if the USER environment variable is set and not empty
if [ -n "$USER" ] && [ "$USER" != "root" ]; then
    # Create user if it doesn't exist
    if ! id -u "$USER" >/dev/null 2>&1; then
        echo "Creating user $USER with UID $USER_ID and GID $GROUP_ID"
        ./user.sh -u "$USER" -g "$USER_ID"
    fi

   export_vars=(
        "USERNAME=$USER"
        "USER_UID=$USER_ID"
        "USER_GID=$GROUP_ID"
        "TRITON_CPU_BACKEND=$TRITON_CPU_BACKEND"
        "INSTALL_CUDNN=$INSTALL_CUDNN"
    )

    export_cmd=""
    for var in "${export_vars[@]}"; do
        export_cmd+="export $var; "
    done

    echo "Switching to user: $USER to install dependencies."
    runuser -u "$USER" -- bash -c "$export_cmd $(declare -f install_dependencies navigate); navigate && install_dependencies"

    navigate  # Ensure we end in the correct directory
    exec gosu "$USER" "$@"
else
    install_dependencies
    navigate  # Ensure we end in the correct directory
    exec "$@"
fi
