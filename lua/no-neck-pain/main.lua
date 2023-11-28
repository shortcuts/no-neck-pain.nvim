local A = require("no-neck-pain.util.api")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local S = require("no-neck-pain.state")
local W = require("no-neck-pain.wins")

local N = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
---@private
function N.toggle(scope)
    if S.hasTabs(S) and S.isActiveTabRegistered(S) then
        return N.disable(scope)
    end

    return N.enable(scope)
end

--- Toggles the scratchPad feature of the plugin.
---@private
function N.toggleScratchPad()
    if not S.isActiveTabRegistered(S) then
        return
    end

    -- store the current win to later restore focus
    local currWin = vim.api.nvim_get_current_win()

    -- map over both sides and let the init method either setup or cleanup the side buffers
    for _, side in pairs(Co.SIDES) do
        vim.fn.win_gotoid(S.getSideID(S, side))
        W.initScratchPad(side, S.getScratchpad(S))
    end

    -- restore focus
    vim.fn.win_gotoid(currWin)

    -- save new state of the scratchpad and update tabs
    S.setScratchpad(S, not S.tabs[S.activeTab].scratchPadEnabled)

    return S
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
--- @param scope string: internal identifier for logging purposes.
--- @param side "left" | "right": the side to toggle.
--- @return table: the state of the plugin.
---@private
function N.toggleSide(scope, side)
    if not S.isActiveTabRegistered(S) then
        D.log(scope, "skipped because the current tab is not registered")

        return S
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

    return N.init(scope)
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
--
--- @return table: the state of the plugin.
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

    return S
end

--- Initializes the plugin, sets event listeners and internal state.
---@private
function N.enable(scope)
    if E.skipEnable() then
        return nil
    end

    D.log(scope, "calling enable for tab %d", S.activeTab)

    -- register the new tab.
    S.setTab(S, S.activeTab)

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
                    if vim.api.nvim_get_current_tabpage() ~= tab.id then
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
                -- if the left tab is not valid anymore, we can remove it from the state
                if not S.isActiveTabValid(S) then
                    S.refreshTabs(S, S.activeTab)
                end

                S.setActiveTab(S, vim.api.nvim_get_current_tabpage())

                D.log(p.event, "new tab page registered %d", S.activeTab)
            end)
        end,
        group = augroupName,
        desc = "Refreshes the active tab state",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            p.event = string.format("%s:splits", p.event)
            A.debounce(p.event, function()
                if not S.hasTabs(S) or E.skip(S.getTab(S)) then
                    return D.log(p.event, "skip split logic")
                end

                if S.checkSides(S, "and", false) then
                    return D.log(p.event, "skip split logic: no side buffer")
                end

                if S.isSideTheActiveWin(S, "curr") then
                    return D.log(p.event, "skip split logic: current win")
                end

                -- an integration isn't considered as a split
                local isSupportedIntegration = S.isSupportedIntegration(S, p.event, nil)
                if isSupportedIntegration then
                    return D.log(p.event, "skip split logic: integration")
                end

                local wins = S.getUnregisteredWins(S)

                if #wins ~= 1 then
                    return D.log(
                        p.event,
                        "skip split logic: no new or too many unregistered windows"
                    )
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
                if E.skip(nil) or not S.isActiveTabRegistered(S) then
                    return
                end

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                if not S.hasSplits(S) and not W.stateWinsActive(false) then
                    D.log(p.event, "one of the NNP main buffers have been closed, disabling...")

                    return N.disable(p.event)
                end

                if _G.NoNeckPain.config.disableOnLastBuffer then
                    local rwins = S.getUnregisteredWins(S)

                    if
                        #rwins == 0
                        and vim.api.nvim_buf_get_option(0, "buftype") == ""
                        and vim.api.nvim_buf_get_option(0, "filetype") == ""
                        and vim.api.nvim_buf_get_option(0, "bufhidden") == "wipe"
                    then
                        D.log(p.event, "found last `wipe` buffer in list, disabling...")

                        return N.disable(p.event)
                    end
                end
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
            p.event = string.format("%s:integrations", p.event)
            A.debounce(p.event, function()
                if not S.hasTabs(S) or not S.isActiveTabRegistered(S) or E.skip(S.getTab(S)) then
                    return D.log(p.event, "skip integrations logic")
                end

                if S.checkSides(S, "and", false) then
                    return D.log(p.event, "skip integrations logic: no side buffer")
                end

                if vim.startswith(p.event, "WinClosed") and not S.hasIntegrations(S) then
                    return D.log(p.event, "skip integrations logic: no registered integration")
                end

                if vim.startswith(p.event, "WinEnter") and #S.getUnregisteredWins(S) == 0 then
                    return D.log(p.event, "skip integrations logic: no new windows")
                end

                N.init(p.event, false, true)
            end)
        end,
        group = augroupName,
        desc = "Resize to apply on WinEnter/Closed of an integration",
    })

    return S
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
--
--- @return table: the state of the plugin.
---@private
function N.disable(scope)
    D.log(scope, "calling disable for tab %d", S.activeTab)

    pcall(vim.api.nvim_del_augroup_by_name, A.getAugroupName(S.activeTab))

    local currID = S.getSideID(S, "curr")

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if
        currID ~= nil
        and vim.api.nvim_win_is_valid(currID)
        and not S.isSideTheActiveWin(S, "curr")
    then
        vim.fn.win_gotoid(currID)

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end

    -- determine if we should quit vim or just close the window
    for _, side in pairs(Co.SIDES) do
        vim.cmd(
            string.format(
                "highlight! clear NoNeckPain_background_tab_%s_side_%s NONE",
                S.activeTab,
                side
            )
        )
        vim.cmd(
            string.format("highlight! clear NoNeckPain_text_tab_%s_side_%s NONE", S.activeTab, side)
        )

        if S.isSideRegistered(S, side) then
            local activeWins = vim.api.nvim_tabpage_list_wins(S.activeTab)
            local haveOtherWins = false

            local sideID = S.getSideID(S, side)

            -- if we have other wins active and usable, we won't quit vim
            for _, activeWin in pairs(activeWins) do
                if sideID ~= activeWin and not A.isRelativeWindow(activeWin) then
                    haveOtherWins = true
                end
            end

            -- we don't have any window left if we close this one
            if not haveOtherWins then
                -- either triggered by a :wq or quit event, we can just quit
                if scope == "QuitPre" then
                    return vim.cmd("quit!")
                end

                -- mostly triggered by :bd or similar
                -- we will create a new window and close the other
                vim.cmd("new")
            end

            -- when we have more than 1 window left, we can just close it
            W.close(scope, sideID, side)
        end
    end

    if S.refreshTabs(S) == 0 then
        D.log(scope, "no more active tabs left, reinitializing state")

        S.init(S)
    end

    return S
end

return N
