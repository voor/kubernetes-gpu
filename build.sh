#!/usr/bin/env sh

export REPO_PATH=${PWD}

pushd ../image-builder/images/capi
packer build -on-error=ask \
    -var-file="${PWD}/packer/config/kubernetes.json" \
    -var-file="${PWD}/packer/config/cni.json" \
    -var-file="${PWD}/packer/config/containerd.json" \
    -var-file="${PWD}/packer/config/ansible-args.json" \
    -var-file="${PWD}/packer/ami/ami-default.json" \
    -var-file="${REPO_PATH}/nvidia-containerd.json" \
    -var-file="${REPO_PATH}/.secrets/secrets.json" \
    packer/ami/packer.json
popd