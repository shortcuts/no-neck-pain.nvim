local A = require("no-neck-pain.util.api")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local S = require("no-neck-pain.state")
local W = require("no-neck-pain.wins")

local N = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
--
--- @param scope string: internal identifier for logging purposes.
---@private
function N.toggle(scope)
    if S.isActiveTabRegistered(S) then
        return N.disable(scope)
    end

    N.enable(scope)
end

--- Toggles the scratchPad feature of the plugin.
--
--- @param scope string: internal identifier for logging purposes.
---@private
function N.toggleScratchPad(scope)
    if not S.isActiveTabRegistered(S) then
        D.log(scope, "skipped because the current tab is not registered")
    end

    -- store the current win to later restore focus
    local currWin = vim.api.nvim_get_current_win()
    local currentState = S.tabs[S.getActiveTab(S)].scratchPadEnabled

    -- save new state of the scratchPad and update tabs
    S.setScratchPad(S, not currentState)

    -- map over both sides and let the init method either setup or cleanup the side buffers
    for _, side in pairs(Co.SIDES) do
        local id = S.getSideID(S, side)
        if id ~= nil then
            vim.fn.win_gotoid(id)
            W.initScratchPad(side, id, currentState)
        end
    end

    -- restore focus
    vim.fn.win_gotoid(currWin)

    S.save(S)
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
--- @param scope string: internal identifier for logging purposes.
--- @param side "left" | "right": the side to toggle.
---@private
function N.toggleSide(scope, side)
    if not S.isActiveTabRegistered(S) then
        D.log(scope, "skipped because the current tab is not registered")

        return S.save(S)
    end

    _G.NoNeckPain.config = vim.tbl_deep_extend(
        "keep",
        { buffers = { [side] = { enabled = not _G.NoNeckPain.config.buffers[side].enabled } } },
        _G.NoNeckPain.config
    )

    if not _G.NoNeckPain.config.buffers[side].enabled then
        W.close(scope, S.getSideID(S, side), side)
        S.setSideID(S, nil, side)
    end

    if not S.checkSides(S, "or", true) then
        _G.NoNeckPain.config = vim.tbl_deep_extend(
            "keep",
            { buffers = { left = { enabled = true }, right = { enabled = true } } },
            _G.NoNeckPain.config
        )

        return N.disable(scope)
    end

    N.init(scope)
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
--
--- @param scope string: internal identifier for logging purposes.
--- @param force boolean?: forcing bypasses the refresh integration/vsplit checks
---@private
function N.init(scope, force)
    assert(S.isActiveTabRegistered(S) == true, "called the internal `init` method on a `nil` tab.")

    if not S.refreshIntegrations(S, scope) and not S.refreshVSplits(S, scope) and not force then
        return D.log(scope, "skipping init, nothing has changed")
    end

    D.log(
        scope,
        "init called on tab %d for current window %d",
        S.getActiveTab(S),
        S.getSideID(S, "curr")
    )

    local hadSideBuffers = S.checkSides(S, "and", true)

    W.createSideBuffers()

    if
        (not hadSideBuffers and S.checkSides(S, "or", true))
        or vim.api.nvim_get_current_win() == S.getSideID(S, "left")
        or vim.api.nvim_get_current_win() == S.getSideID(S, "right")
    then
        vim.fn.win_gotoid(S.getSideID(S, "curr"))
    end

    S.save(S)
end

--- Initializes the plugin, sets event listeners and internal state.
---
--- @param scope string: internal identifier for logging purposes.
---@private
function N.enable(scope)
    if E.skipEnable() then
        return
    end

    S.setTab(S, A.getCurrentTab())
    S.setEnabled(S)
    S.setSideID(S, vim.api.nvim_get_current_win(), "curr")

    D.log(
        scope,
        "calling enable for tab %d with curr %d",
        S.getActiveTab(S),
        S.getSideID(S, "curr")
    )

    local augroupName = A.getAugroupName(S.getActiveTab(S))
    vim.api.nvim_create_augroup(augroupName, { clear = true })

    N.init(scope)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            A.debounce(p.event, function()
                if E.skip() then
                    return
                end

                N.init(p.event, true)
            end)
        end,
        group = augroupName,
        desc = "Resizes side windows after terminal has been resized, closes them if not enough space left.",
    })

    vim.api.nvim_create_autocmd({ "TabLeave", "TabEnter" }, {
        callback = function(p)
            A.debounce(p.event, function()
                if p.event == "TabLeave" then
                    S.refreshTabs(S)
                    D.log(p.event, "tab %d left", S.getActiveTab(S))

                    return
                end

                S.setActiveTab(S, A.getCurrentTab())

                D.log(p.event, "tab %d entered", S.getActiveTab(S))
            end)
        end,
        group = augroupName,
        desc = "Keeps track of the currently active tab and the tab state",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "BufDelete", "QuitPre" }, {
        callback = function(p)
            A.debounce(p.event, function()
                if E.skip() then
                    return
                end

                local curr = vim.api.nvim_get_current_win()

                if
                    p.event == "WinEnter"
                    and (
                        S.getSideID(S, "left") == curr
                        or S.getSideID(S, "right") == curr
                        or S.getSideID(S, "curr") == curr
                    )
                then
                    return D.log(
                        p.event,
                        "skipped, %d is a main window",
                        vim.api.nvim_get_current_win()
                    )
                end

                if p.event ~= "WinEnter" then
                    if not S.isSideWinValid(S, "curr") then
                        S.setSideID(S, nil, "curr")
                        D.log(p.event, "`curr` has been closed")

                        if
                            p.event == "BufDelete"
                            and _G.NoNeckPain.config.autocmds.fallbackOnBufferDelete
                        then
                            D.log(p.event, "user asked for a fallback")

                            vim.cmd("new")

                            N.disable(string.format("%s:reset", p.event))
                            N.enable(string.format("%s:reset", p.event))

                            return
                        end

                        local wins = S.getUnregisteredWins(S)
                        if #wins == 0 then
                            D.log(p.event, "no active windows found")

                            return N.disable(p.event)
                        end

                        S.setSideID(S, wins[1], "curr")

                        D.log(p.event, "re-routing to %d", S.getSideID(S, "curr"))

                        return N.init(p.event)
                    end

                    for _, side in ipairs(Co.SIDES) do
                        local id = S.getSideID(S, side)
                        if
                            S.isSideEnabled(S, side)
                            and id ~= nil
                            and not vim.api.nvim_win_is_valid(id)
                        then
                            D.log(p.event, "%s was opened but has been closed", side)

                            return N.disable(p.event)
                        end
                    end
                end

                return N.init(p.event)
            end)
        end,
        group = augroupName,
        desc = "Updates the state (vsplits, integrations, ui refresh) when entering a window, deleting a buffer or attempting to quit nvim",
    })

    if _G.NoNeckPain.config.autocmds.skipEnteringNoNeckPainBuffer then
        vim.api.nvim_create_autocmd({ "WinEnter" }, {
            callback = function(p)
                p.event = string.format("%s:skipEnteringNoNeckPainBuffer", p.event)
                A.debounce(p.event, function()
                    if E.skip() or S.getScratchPad(S) then
                        return D.log(p.event, "skip")
                    end

                    if not S.isSideWinValid(S, "curr") then
                        return D.log(p.event, "skip no curr found")
                    end

                    local currentWin = vim.api.nvim_get_current_win()
                    local leftID = S.getSideID(S, "left")
                    local rightID = S.getSideID(S, "right")

                    if currentWin ~= leftID and currentWin ~= rightID then
                        return
                    end

                    -- always from left to right, we first try to find
                    -- the index of the window we just left in order to avoid jumping
                    -- in between windows
                    local wins = vim.api.nvim_tabpage_list_wins(S.getActiveTab(S))
                    -- actual idx of the current window
                    local idx = 1
                    -- the position to start from in the list
                    local pos = 1

                    for i = 1, #wins do
                        if wins[i] == currentWin then
                            idx = i
                            pos = i == #wins and 1 or i + 1
                            break
                        end
                    end

                    -- now we can pos from the window position, if we overflow #wins
                    -- we go to the beginning until pos is reached
                    -- this avoids re-ordering the wins table
                    while pos ~= idx do
                        if pos > #wins then
                            pos = 1
                        end

                        if
                            wins[pos] ~= currentWin
                            and wins[pos] ~= leftID
                            and wins[pos] ~= rightID
                        then
                            vim.fn.win_gotoid(wins[pos])

                            return D.log(
                                p.event,
                                "rerouted focus of %d to %d",
                                currentWin,
                                wins[pos]
                            )
                        end

                        pos = pos + 1
                    end
                end)
            end,
            group = augroupName,
            desc = "Entering a no-neck-pain side buffer skips to the next available buffer",
        })
    end

    S.save(S)
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@private
function N.disable(scope)
    D.log(scope, "calling disable for tab %d", S.activeTab)

    if #S.getUnregisteredWins(S, true) == 0 then
        for name, modified in pairs(A.getOpenedBuffers()) do
            if modified then
                local bufname = name
                if vim.startswith(name, "NoNamePain") then
                    bufname = string.sub(name, 11)
                end

                vim.schedule(function()
                    vim.notify(
                        "[no-neck-pain.nvim] unable to quit nvim because one or more buffer has modified files, please save or discard changes",
                        vim.log.levels.ERROR
                    )
                    vim.cmd("rightbelow vertical split")
                    vim.cmd("buffer " .. bufname)
                    N.init(scope)
                end)
                return
            end
        end

        pcall(vim.api.nvim_del_augroup_by_name, A.getAugroupName(S.activeTab))
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        return vim.cmd("quitall!")
    end

    pcall(vim.api.nvim_del_augroup_by_name, A.getAugroupName(S.activeTab))

    local sides = { left = S.getSideID(S, "left"), right = S.getSideID(S, "right") }
    local currID = S.getSideID(S, "curr")

    if S.refreshTabs(S, S.getActiveTab(S)) == nil then
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        D.log(scope, "no more active tabs left, reinitializing state")

        S.init(S)
    end

    for side, id in pairs(sides) do
        if vim.api.nvim_win_is_valid(id) then
            S.removeNamespace(S, vim.api.nvim_win_get_buf(id), side)
            W.close(scope, id, side)
        end
    end

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if currID ~= nil and vim.api.nvim_win_is_valid(currID) then
        vim.fn.win_gotoid(currID)

        if _G.NoNeckPain.config.autocmds.killAllWindowsOnDisable then
            vim.cmd("only")
        end
    end

    S.save(S)
end

return N
