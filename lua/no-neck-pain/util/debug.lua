local D = {}

---prints only if debug is true.
---
---@param scope string: the scope from where this function is called.
---@param str string: the formatted string.
---@param ... any: the arguments of the formatted string.
---@private
function D.log(scope, str, ...)
    if _G.NoNeckPain.config ~= nil and not _G.NoNeckPain.config.debug then
        return
    end

    local info = debug.getinfo(2, "Sl")
    local line = ""

    if info then
        line = "L" .. info.currentline
    end

    print(
        string.format(
            "[no-neck-pain:%s %s in %s] > %s",
            os.date("%H:%M:%S"),
            line,
            scope,
            string.format(str, ...)
        )
    )
end

---prints the table if debug is true.
---
---@param table table: the table to print.
---@param indent number?: the default indent value, starts at 0.
---@private
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
        elseif type(v) == "function" then
            print(formatting .. "FUNCTION")
        else
            print(formatting .. v)
        end
    end
end

return D
