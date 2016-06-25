#!/bin/bash
# Create images for a specific archicture.
# Usage: build.sh <repo> <architecture>
set -xe
cd "$(dirname "$0")"

# Parse arguments.
[ $# -eq 2 ]
repo=$1
arch=$2

# Get the bootstrap image settings.
source bootstrap/vars
bootstrap_image="archlinux-bootstrap:${bootstrap_version}"

# Create the bootstrap image if it does not exist.
if [ -z "$(docker images -q ${bootstrap_image})" ]; then
    # Build the bootstrap rootfs.
    docker pull ${bootstrap_build_image}
    docker run --rm -v "${PWD}"/bootstrap:/bootstrap-dir \
        -i ${bootstrap_build_image} /bin/bash \
        < support/build-bootstrap.sh

    # Remove old bootstrap images.
    ./support/clean-repo.sh archlinux-bootstrap

    # Create the new bootstrap image.
    docker build -t ${bootstrap_image} bootstrap

    # Cleanup the bootstrap rootfs tarball.
    rm bootstrap/_rootfs.tar.gz
fi

# Create a scratch volume used to build in.
# We need this in order to create our own aufs mountpoint.
scratch="$(docker volume create)"
trap "docker volume rm ${scratch}" exit

# Build the image layers.
# We need to be privileged in order to create our own aufs mountpoint.
docker run --rm --privileged \
    -v ${scratch}:/build \
    -v "${PWD}"/target-${arch}:/target-dir \
    -i ${bootstrap_image} /bin/bash \
    < support/bootstrap.sh

# Move to image directory
pushd target-${arch}/_image

# Build the layer configs and manifests.
docker run --rm \
    -v "${PWD}":/image-dir -w /image-dir \
    -i ${bootstrap_image} /usr/bin/lua << EOF

local json = require('json')

local creation_date = os.date("!%Y-%m-%dT%TZ")
local manifest = {
    {
        Config='config.json',
        RepoTags={},
        Layers={}
    }
}
local config = {
    architecture='amd64',
    os='linux',
    config={
        User='root',
        Env={ 'PATH=/usr/local/sbin:/usr/local/bin:/usr/bin' },
        WorkingDir='/',
        Cmd='/bin/bash'
    },
    rootfs={
        type='layers',
        diff_ids={}
    },
    history={}
}

local num = 0
for line in io.open('_meta.jsonl'):lines() do
    local layer = json.decode(line)
    num = num + 1

    manifest[1].RepoTags[1] = string.format('%s:%s-%s', '${repo}', '${arch}', layer.tag)
    manifest[1].Layers[num] = string.format('L%d/layer.tar', num)
    config.rootfs.diff_ids[num] = string.format('sha256:%s', layer.sha256)
    config.history[num] = {
        created=creation_date,
        created_by=string.format('/bin/sh -c #(nop) %s', layer.comment)
    }

    local manifestf = io.open(string.format('manifest-L%d.json', num), 'w')
    manifestf:write(json.encode(manifest))
    manifestf:close()

    local configf = io.open(string.format('config-L%d.json', num), 'w')
    configf:write(json.encode(config))
    configf:close()
end

EOF

# Load the layers.
total=$(wc -l < _meta.jsonl)
num=0
while (( ++num <= total )); do
    mv manifest-L${num}.json manifest.json
    mv config-L${num}.json config.json
    tar -c manifest.json config.json L${num} | docker load
done

# Cleanup layer files.
popd
rm -r target-${arch}/_image

# Create the makepkg tag.
pushd makepkg
dockerfile="$(mktemp .Dockerfile-XXXXXX)"
sed -e "s|%parent_layer%|${repo}:${arch}-devel|g" \
    < Dockerfile.in > ${dockerfile}
docker build -t ${repo}:${arch}-makepkg -f ${dockerfile} .
rm ${dockerfile}
popd
