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
    if S.hasTabs(S) and S.isActiveTabRegistered(S) then
        return N.disable(scope)
    end

    N.enable(scope)
end

--- Toggles the scratchPad feature of the plugin.
---@private
function N.toggleScratchPad()
    if not S.isActiveTabRegistered(S) then
        return
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
--- @param scope string: internal identifier for logging purposes.
---@private
function N.init(scope)
    assert(S.isActiveTabRegistered(S) == true, "called the internal `init` method on a `nil` tab.")

    D.log(
        scope,
        "init called on tab %d for current window %d",
        S.getActiveTab(S),
        S.getSideID(S, "curr")
    )

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local hadSideBuffers = not S.checkSides(S, "and", false)

    W.createSideBuffers()

    if
        (not hadSideBuffers and S.checkSides(S, "or", true))
        or (S.isSideTheActiveWin(S, "left") or S.isSideTheActiveWin(S, "right"))
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

    D.log(scope, "calling enable for tab %d", A.getCurrentTab())

    S.setTab(S, A.getCurrentTab())

    local augroupName = A.getAugroupName(S.getActiveTab(S))
    vim.api.nvim_create_augroup(augroupName, { clear = true })

    S.setSideID(S, vim.api.nvim_get_current_win(), "curr")

    N.init(scope)

    S.setEnabled(S)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                    return
                end

                local tab = S.getTab(S)

                if tab ~= nil and A.getCurrentTab() ~= tab.id then
                    return
                end

                N.init(p.event)
            end)
        end,
        group = augroupName,
        desc = "Resizes side windows after terminal has been resized, closes them if not enough space left.",
    })

    vim.api.nvim_create_autocmd({ "TabLeave", "TabEnter" }, {
        callback = function(p)
            vim.schedule(function()
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

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                if not S.isActiveTabValid(S) or E.skip(S.getTab(S)) then
                    return D.log(p.event, "skipped on window %d", vim.api.nvim_get_current_win())
                end

                S.refreshIntegrations(S, p.event)
                S.refreshVSplits(S, p.event)

                -- TODO(next): find more skip condition to prevent unwanted UI refresh
                N.init(p.event)
            end)
        end,
        group = augroupName,
        desc = "Updates the state (vsplits, integrations, ui refresh) when entering a window",
    })

    vim.api.nvim_create_autocmd({ "WinClosed", "QuitPre", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                if not S.isActiveTabValid(S) then
                    return
                end

                S.refreshIntegrations(S, p.event)
                S.refreshVSplits(S, p.event)

                -- if `curr` has been closed, we will re-route focus to an other window
                -- if possible, otherwise we disable the plugin and/or quit nvim
                if not vim.api.nvim_win_is_valid(S.getSideID(S, "curr")) then
                    local wins = S.getUnregisteredWins(S)
                    if #wins == 0 then
                        if _G.NoNeckPain.config.autocmds.fallbackOnBufferDelete then
                            D.log(p.event, "`curr` has been deleted and user asked for a fallback")

                            vim.cmd("new")

                            N.disable(string.format("%s:reset", p.event))
                            N.enable(string.format("%s:reset", p.event))

                            return
                        end

                        D.log(
                            p.event,
                            "curr has been closed and no active windows found, disabling"
                        )

                        return N.disable(p.event)
                    end

                    S.setSideID(S, wins[1], "curr")

                    D.log(p.event, "curr has been closed, re-routing to %d", S.getSideID(S, "curr"))
                end

                -- if the user wants both side and one is closed, or if they only want one and none is opened
                if
                    (S.wantsSides(S) and not S.checkSides(S, "and", true))
                    or not S.checkSides(S, "or", true)
                then
                    D.log(p.event, "one of the side window has been closed, disabling")

                    return N.disable(p.event)
                end

                N.init(p.event)
            end)
        end,
        group = augroupName,
        desc = "Updates the state (vsplits, integrations, ui refresh) when leaving a window, also handles disabling the plugin and/or quitting nvim",
    })

    if _G.NoNeckPain.config.autocmds.skipEnteringNoNeckPainBuffer then
        vim.api.nvim_create_autocmd({ "WinLeave" }, {
            callback = function(p)
                vim.schedule(function()
                    p.event = string.format("%s:skipEnteringNoNeckPainBuffer", p.event)
                    if
                        not S.hasTabs(S)
                        or not S.isActiveTabRegistered(S)
                        or E.skip()
                        or S.getScratchPad(S)
                    then
                        return D.log(p.event, "skip")
                    end

                    local currentWin = vim.api.nvim_get_current_win()
                    local leftID = S.getSideID(S, "left")
                    local rightID = S.getSideID(S, "right")

                    if currentWin ~= leftID and currentWin ~= rightID then
                        return
                    end

                    local wins = vim.api.nvim_list_wins()

                    for i = 1, #wins do
                        local id = i == #wins and 1 or i + 1
                        if
                            wins[id] ~= currentWin
                            and wins[id] ~= leftID
                            and wins[id] ~= rightID
                        then
                            vim.fn.win_gotoid(wins[id])

                            return D.log(
                                p.event,
                                "rerouted focus of %d to %d",
                                currentWin,
                                wins[id]
                            )
                        end
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

    pcall(vim.api.nvim_del_augroup_by_name, A.getAugroupName(S.activeTab))

    local sides = { left = S.getSideID(S, "left"), right = S.getSideID(S, "right") }
    local currID = S.getSideID(S, "curr")
    local activeTab = S.activeTab

    if S.refreshTabs(S, S.getActiveTab(S)) == nil then
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        D.log(scope, "no more active tabs left, reinitializing state")

        S.init(S)
    end

    for side, id in pairs(sides) do
        if vim.api.nvim_win_is_valid(id) then
            local wins = vim.tbl_filter(function(win)
                return win ~= id and not A.isRelativeWindow(win)
            end, vim.api.nvim_tabpage_list_wins(activeTab))

            if #wins == 0 then
                -- return vim.cmd("quit")
            end

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
