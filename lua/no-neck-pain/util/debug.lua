local D = {}

-- prints only if debug is true.
function D.print(...)
    if _G.NoNeckPain.config ~= nil and not _G.NoNeckPain.config.debug then
        return
    end

    local info = debug.getinfo(2, "Sl")
    local line = ""

    if info then
        line = " L" .. info.currentline
    end

    print("[no-neck-pain:" .. os.date("%H:%M:%S") .. line .. "] --> ", ...)
end

-- prints table only if debug is true.
function D.tprint(table, indent)
    if _G.NoNeckPain.config ~= nil and not _G.NoNeckPain.config.debug then
        return
    end

    if not indent then
        indent = 0
    end

    for k, v in pairs(table) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            D.tprint(v, indent + 1)
        elseif type(v) == "boolean" then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

return D
