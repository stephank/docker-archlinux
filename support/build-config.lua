-- Builds layer manifests and configs
-- Usage: lua build-config.lua <repo> <architecture>

local repo = arg[1]
local arch = arg[2]

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
for line in io.open('_image/_meta.jsonl'):lines() do
    local layer = json.decode(line)
    num = num + 1

    manifest[1].RepoTags[1] = string.format('%s:%s-%s', repo, arch, layer.tag)
    manifest[1].Layers[num] = string.format('L%d/layer.tar', num)
    config.rootfs.diff_ids[num] = string.format('sha256:%s', layer.sha256)
    config.history[num] = {
        created=creation_date,
        created_by=string.format('/bin/sh -c #(nop) %s', layer.comment)
    }

    local manifestf = io.open(string.format('_image/manifest-L%d.json', num), 'w')
    manifestf:write(json.encode(manifest))
    manifestf:close()

    local configf = io.open(string.format('_image/config-L%d.json', num), 'w')
    configf:write(json.encode(config))
    configf:close()
end
