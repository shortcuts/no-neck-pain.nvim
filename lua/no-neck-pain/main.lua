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

    local augroupName = A.getAugroupName(S.activeTab)
    vim.api.nvim_create_augroup(augroupName, { clear = true })

    S.setSideID(S, vim.api.nvim_get_current_win(), "curr")
    S.computeSplits(S, S.getSideID(S, "curr"))

    N.init(scope, true)

    S.setEnabled(S)

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

    vim.api.nvim_create_autocmd({ "TabLeave" }, {
        callback = function(p)
            vim.schedule(function()
                if
                    S.isActiveTabRegistered(S) and not vim.api.nvim_tabpage_is_valid(S.activeTab)
                then
                    S.refreshTabs(S, S.activeTab)
                    D.log(p.event, "tab %d is now inactive", S.activeTab)
                else
                    D.log(p.event, "tab %d left", S.activeTab)
                end
            end)
        end,
        group = augroupName,
        desc = "Removes potentially inactive tabs from the state",
    })

    vim.api.nvim_create_autocmd({ "TabEnter" }, {
        callback = function(p)
            vim.schedule(function()
                S.setActiveTab(S, A.getCurrentTab())

                D.log(p.event, "tab %d entered", S.activeTab)
            end)
        end,
        group = augroupName,
        desc = "Keeps track of the currently active tab",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                p.event = string.format("%s:split", p.event)
                if not S.hasTabs(S) or E.skip(S.getTab(S)) then
                    return D.log(p.event, "skip")
                end

                if S.checkSides(S, "and", false) then
                    return D.log(p.event, "no side buffer")
                end

                if S.isSideTheActiveWin(S, "curr") then
                    return D.log(p.event, "current win")
                end

                -- an integration isn't considered as a split
                local isSupportedIntegration = S.isSupportedIntegration(S, p.event, nil)
                if isSupportedIntegration then
                    return D.log(p.event, "on an integration")
                end

                local wins = S.getUnregisteredWins(S)

                if #wins ~= 1 then
                    return D.log(p.event, "no new or too many unregistered windows")
                end

                local focusedWin = wins[1]

                local isVSplit = S.computeSplits(S, focusedWin)
                S.setSplit(S, { id = focusedWin, vertical = isVSplit })

                if isVSplit then
                    N.init(p.event)
                end
            end)
        end,
        group = augroupName,
        desc = "WinEnter covers the split/vsplit management",
    })

    vim.api.nvim_create_autocmd({ "QuitPre", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                local s = string.format("%s:quit", p.event)
                if E.skip(nil) or not S.isActiveTabRegistered(S) then
                    return
                end

                if S.hasSplits(S) then
                    return D.log(s, "splits still active")
                end

                if
                    (
                        (S.isSideRegistered(S, "left") and not S.isSideWinValid(S, "left"))
                        or (S.isSideRegistered(S, "right") and not S.isSideWinValid(S, "right"))
                    )
                    or (
                        not _G.NoNeckPain.config.fallbackOnBufferDelete
                        and not S.isSideWinValid(S, "curr")
                    )
                then
                    D.log(s, "one of the NNP side has been closed")

                    return N.disable(p.event)
                end

                if S.isSideWinValid(S, "curr") then
                    D.log(s, "curr is still valid, skipping")

                    return
                end

                -- if we still have a side valid but curr has been deleted (mostly because of a :bd),
                -- we will fallback to the first valid side
                if p.event == "QuitPre" then
                    D.log(s, "curr has been closed")

                    return N.disable(p.event)
                end

                D.log(s, "`curr` has been deleted, resetting state")

                vim.cmd("new")

                N.disable(string.format("%s:reset", s))
                N.enable(string.format("%s:reset", s))
            end)
        end,
        group = augroupName,
        desc = "Handles the closure of main NNP windows",
    })

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(nil) or not S.hasSplits(S) or W.stateWinsActive(true) then
                    return
                end

                S.tabs[S.activeTab].wins.splits = vim.tbl_filter(function(split)
                    if vim.api.nvim_win_is_valid(split.id) then
                        return true
                    end

                    S.decreaseLayers(S, split.vertical)

                    return false
                end, S.tabs[S.activeTab].wins.splits)

                if #S.tabs[S.activeTab].wins.splits == 0 then
                    S.initSplits(S)
                end

                -- we keep track if curr have been closed because if it's the case,
                -- the focus will be on a side buffer which is wrong
                local haveCloseCurr = false

                -- if curr is not valid anymore, we focus the first valid split and remove it from the state
                if not vim.api.nvim_win_is_valid(S.getSideID(S, "curr")) then
                    -- if neither curr and splits are remaining valids, we just disable
                    if not S.hasSplits(S) then
                        return N.disable(p.event)
                    end

                    haveCloseCurr = true

                    local split = S.tabs[S.activeTab].wins.splits[1]

                    S.decreaseLayers(S, split.vertical)
                    S.setSideID(S, split.id, "curr")
                    S.removeSplit(S, split.id)
                end

                -- we only restore focus on curr if there's no split left
                N.init(p.event, haveCloseCurr or not S.hasSplits(S))
            end)
        end,
        group = augroupName,
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                local s = string.format("%s:integration", p.event)
                if not S.hasTabs(S) or not S.isActiveTabRegistered(S) or E.skip(S.getTab(S)) then
                    return D.log(s, "skip")
                end

                if S.wantsSides(S) and S.checkSides(S, "and", false) then
                    return D.log(s, "no side buffer")
                end

                if p.event == "WinClosed" and not S.hasIntegrations(S) then
                    return D.log(s, "no registered integration")
                end

                local unregistered = S.getUnregisteredWins(S)
                if p.event == "WinEnter" and #unregistered == 0 then
                    return D.log(s, "no new windows")
                end

                if
                    p.event == "WinEnter"
                    and #unregistered == 1
                    and not S.isSupportedIntegration(S, s, unregistered[1])
                then
                    return D.log(s, "encountered a new window, not an integration")
                end

                N.init(s, false, true)
            end)
        end,
        group = augroupName,
        desc = "Resize to apply on WinEnter/Closed of an integration",
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

    if S.refreshTabs(S) == 0 then
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        D.log(scope, "no more active tabs left, reinitializing state")

        S.init(S)
    end

    S.save(S)

    for side, id in pairs(sides) do
        if vim.api.nvim_win_is_valid(id) then
            if #vim.api.nvim_tabpage_list_wins(S.activeTab) == 1 then
                return vim.cmd("quit")
            end

            S.removeNamespace(S, vim.api.nvim_win_get_buf(id), side)
            W.close(scope, id, side)
        end
    end

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if
        currID ~= nil
        and vim.api.nvim_win_is_valid(currID)
        and not vim.api.nvim_get_current_win() == currID
    then
        vim.fn.win_gotoid(currID)

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end
end

return N
