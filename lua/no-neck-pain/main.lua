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
    local currentState = S.tabs[S.activeTab].scratchPadEnabled

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

    S.scanLayout(S, scope)

    N.init(scope)
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
--- @param scope string: internal identifier for logging purposes.
--- @param goToCurr boolean?: whether we should re-focus the `curr` window.
--- @param skipIntegrations boolean?: whether we should skip the integrations logic.
---@private
function N.init(scope, goToCurr, skipIntegrations)
    if not S.isActiveTabRegistered(S) then
        error("called the internal `init` method on a `nil` tab.")
    end

    D.log(scope, "init called on tab %d for current window %d", S.activeTab, S.getSideID(S, "curr"))

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local hadSideBuffers = true
    if S.checkSides(S, "and", false) then
        hadSideBuffers = false
    end

    W.createSideBuffers(skipIntegrations)

    if
        goToCurr
        or (not hadSideBuffers and S.checkSides(S, "or", true))
        or (S.isSideTheActiveWin(S, "left") or S.isSideTheActiveWin(S, "right"))
    then
        D.log(scope, "re-routing focus to curr")

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

    S.setEnabled(S)
    S.setTab(S, A.getCurrentTab())

    local augroupName = A.getAugroupName(S.activeTab)
    vim.api.nvim_create_augroup(augroupName, { clear = true })

    S.setSideID(S, vim.api.nvim_get_current_win(), "curr")
    S.scanLayout(S, scope)
    N.init(scope, true)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                    return
                end

                local tab = S.getTab(S)

                if tab ~= nil then
                    if A.getCurrentTab() ~= tab.id then
                        return
                    end
                end

                N.init(p.event)
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
                    D.log(p.event, "tab %d left", S.activeTab)

                    return
                end

                S.setActiveTab(S, A.getCurrentTab())

                D.log(p.event, "tab %d entered", S.activeTab)
            end)
        end,
        group = augroupName,
        desc = "Keeps track of the currently active tab and the tab state",
    })

    vim.api.nvim_create_autocmd({ "QuitPre", "BufDelete", "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                if not S.isActiveTabRegistered(S) or E.skip(S.getTab(S)) then
                    return
                end

                local refresh = S.scanLayout(S, p.event)

                if not vim.api.nvim_win_is_valid(S.getSideID(S, "curr")) then
                    if p.event == "BufDelete" and _G.NoNeckPain.config.fallbackOnBufferDelete then
                        D.log(p.event, "`curr` has been deleted, resetting state")

                        vim.cmd("new")

                        N.disable(string.format("%s:reset", p.event))
                        N.enable(string.format("%s:reset", p.event))

                        return
                    end

                    local vsplits, nbVSplits = S.getVSplits(S, true)
                    if nbVSplits == 0 then
                        D.log(p.event, "no active windows found")

                        return N.disable(p.event)
                    end

                    S.setSideID(S, vsplits[1], "curr")

                    D.log(p.event, "re-routing to %d", S.getSideID(S, "curr"))

                    return N.init(p.event, true)
                end

                if
                    (S.isSideEnabled(S, "left") and not S.isSideWinValid(S, "left"))
                    or (S.isSideEnabled(S, "right") and not S.isSideWinValid(S, "right"))
                then
                    D.log(p.event, "one of the NNP side has been closed")

                    return N.disable(p.event)
                end

                if refresh then
                    return N.init(p.event)
                end
            end)
        end,
        group = augroupName,
        desc = "keeps track of the state after closing windows and deleting buffers",
    })

    if _G.NoNeckPain.config.autocmds.skipEnteringNoNeckPainBuffer then
        vim.api.nvim_create_autocmd({ "WinLeave" }, {
            callback = function(p)
                vim.schedule(function()
                    p.event = string.format("%s:skipEnteringNoNeckPainBuffer", p.event)
                    if
                        not S.isActiveTabRegistered(S)
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
    local activeTab = S.activeTab

    D.log(scope, "calling disable for tab %d", activeTab)

    local wins = vim.tbl_filter(function(win)
        return win ~= S.getSideID(S, "left")
            and win ~= S.getSideID(S, "right")
            and not A.isRelativeWindow(win)
    end, vim.api.nvim_tabpage_list_wins(activeTab))

    if #vim.api.nvim_list_tabpages() == 1 and #wins == 0 then
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

        pcall(vim.api.nvim_del_augroup_by_name, A.getAugroupName(activeTab))
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        return vim.cmd("quitall!")
    end

    pcall(vim.api.nvim_del_augroup_by_name, A.getAugroupName(activeTab))

    local sides = { left = S.getSideID(S, "left"), right = S.getSideID(S, "right") }
    local currID = S.getSideID(S, "curr")

    if S.refreshTabs(S, activeTab) == 0 then
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

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end

    S.save(S)
end

return N
