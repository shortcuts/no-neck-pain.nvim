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

    print(
        string.format(
            "[no-neck-pain@%s in '%s'] > %s",
            os.date("%X"),
            scope,
            string.format(str, ...)
        )
    )
end

---analyzes the user provided `setup` parameters and sends a message if they use a deprecated option, then gives the new option to use.
---
---@param options table: the options provided by the user.
---@private
function D.warnDeprecation(options)
    local usesDeprecatedOption = false

    local notice = "is now deprecated, use `%s` instead."
    local rootDeprecated = {
        enableOnVimEnter = "autocmds.enableOnVimEnter",
        enableOnTabEnter = "autocmds.enableOnTabEnter",
        toggleMapping = "mappings.toggle",
        widthUpMapping = "mappings.widthUp",
        widthDownMapping = "mappings.widthDown",
    }
    local buffersDeprecated = {
        backgroundColor = "colors.background",
        textColor = "colors.text",
        blend = "colors.blend",
    }

    for name, warning in pairs(rootDeprecated) do
        if options[name] ~= nil then
            usesDeprecatedOption = true
            print(
                string.format("[no-neck-pain.nvim] `%s` %s", name, string.format(notice, warning))
            )
        end
    end

    for name, warning in pairs(buffersDeprecated) do
        if
            options.buffers[name] ~= nil
            or options.buffers.left[name] ~= nil
            or options.buffers.right[name] ~= nil
        then
            usesDeprecatedOption = true
            print(
                string.format(
                    "[no-neck-pain.nvim] `buffers.%s` %s",
                    name,
                    string.format(notice, warning)
                )
            )
        end
    end

    if usesDeprecatedOption then
        print("[no-neck-pain.nvim]     sorry to bother you with the breaking changes :(")
        print("[no-neck-pain.nvim]     use `:h NoNeckPain.options` to read more.")
    end
end

return D
