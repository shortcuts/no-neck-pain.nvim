local log = {}

local longest_scope = 15

--- prints only if debug is true.
---
---@param scope string: the scope from where this function is called.
---@param str string: the formatted string.
---@param ... any: the arguments of the formatted string.
---@private
function log.debug(scope, str, ...)
    return log.notify(scope, vim.log.levels.DEBUG, false, str, ...)
end

--- prints only if debug is true.
---
---@param scope string: the scope from where this function is called.
---@param level string: the log level of vim.notify.
---@param verbose boolean: when false, only prints when config.debug is true.
---@param str string: the formatted string.
---@param ... any: the arguments of the formatted string.
---@private
function log.notify(scope, level, verbose, str, ...)
    if not verbose and _G.NoNeckPain.config ~= nil and not _G.NoNeckPain.config.debug then
        return
    end

    if string.len(scope) > longest_scope then
        longest_scope = string.len(scope)
    end

    for i = longest_scope, string.len(scope), -1 do
        if i < string.len(scope) then
            scope = string.format("%s ", scope)
        else
            scope = string.format("%s", scope)
        end
    end

    vim.notify_once(
        string.format("[nnp@%s] %s", scope, string.format(str, ...)),
        level,
        { title = "no-neck-pain.nvim" }
    )
end

--- analyzes the user provided `setup` parameters and sends a message if they use a deprecated option, then gives the new option to use.
---
---@param options table: the options provided by the user.
---@private
function log.warn_deprecation(options)
    local uses_deprecated_option = false

    local notice = "is now deprecated, use `%s` instead."
    local root_deprecated = {
        enableOnVimEnter = "autocmds.enableOnVimEnter",
        enableOnTabEnter = "autocmds.enableOnTabEnter",
        toggleMapping = "mappings.toggle",
        widthUpMapping = "mappings.widthUp",
        widthDownMapping = "mappings.widthDown",
    }
    local buffers_deprecated = {
        backgroundColor = "colors.background",
        textColor = "colors.text",
        blend = "colors.blend",
    }

    for name, warning in pairs(root_deprecated) do
        if options[name] ~= nil then
            uses_deprecated_option = true
            log.notify(
                "deprecated_options",
                vim.log.levels.WARN,
                true,
                string.format("`%s` %s", name, string.format(notice, warning))
            )
        end
    end

    for name, warning in pairs(buffers_deprecated) do
        if
            options.buffers[name] ~= nil
            or options.buffers.left[name] ~= nil
            or options.buffers.right[name] ~= nil
        then
            uses_deprecated_option = true
            log.notify(
                "deprecated_options",
                vim.log.levels.WARN,
                true,
                string.format("`%s` %s", name, string.format(notice, warning))
            )
        end
    end

    if uses_deprecated_option then
        log.notify(
            "deprecated_options",
            vim.log.levels.WARN,
            true,
            "sorry to bother you with the breaking changes :("
        )
        log.notify(
            "deprecated_options",
            vim.log.levels.WARN,
            true,
            "use `:h NoNeckPain.options` to read more."
        )
    end
end

return log
