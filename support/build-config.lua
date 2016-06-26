-- Builds layer manifests and configs.
-- Usage: lua build-config.lua <repo> <architecture>

local json = require('json')

-- Parse arguments.
if #arg ~= 2 then
    os.exit(1)
end
local repo, arch = unpack(arg)

-- Build the base config.
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

-- Format history `created` date.
local creation_date = os.date("!%Y-%m-%dT%T.000000000Z")

-- Iterate layers.
local num = 0
for line in io.open('_image/_meta.jsonl'):lines() do
    local layer = json.decode(line)
    num = num + 1

    -- Add layer to config.
    manifest[1].RepoTags[1] = string.format('%s:%s-%s', repo, arch, layer.tag)
    manifest[1].Layers[num] = string.format('L%d/layer.tar', num)
    config.rootfs.diff_ids[num] = string.format('sha256:%s', layer.sha256)
    config.history[num] = {
        created=creation_date,
        created_by=string.format('/bin/sh -c #(nop) %s', layer.comment)
    }

    -- Write layer manifest.
    local manifestf = io.open(string.format('_image/manifest-L%d.json', num), 'w')
    manifestf:write(json.encode(manifest))
    manifestf:close()

    -- Write layer config.
    local configf = io.open(string.format('_image/config-L%d.json', num), 'w')
    configf:write(json.encode(config))
    configf:close()
end
