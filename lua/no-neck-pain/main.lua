local A = require("no-neck-pain.util.api")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local T = require("no-neck-pain.trees")
local W = require("no-neck-pain.wins")

local N = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
---@private
function N.toggle(scope)
    if State.hasTabs(State) and State.isActiveTabRegistered(State) then
        return N.disable(scope)
    end

    return N.enable(scope)
end

--- Toggles the scratchPad feature of the plugin.
---@private
function N.toggleScratchPad()
    if not State.isActiveTabRegistered(State) then
        return
    end

    -- store the current win to later restore focus
    local currWin = vim.api.nvim_get_current_win()

    -- map over both sides and let the init method either setup or cleanup the side buffers
    for _, side in pairs(Co.SIDES) do
        vim.fn.win_gotoid(State.getSideID(State, side))
        W.initScratchPad(side)
    end

    -- restore focus
    vim.fn.win_gotoid(currWin)

    -- save new state of the scratchpad and update tabs
    State.setScratchPad(not State.tabs[State.activeTab].scratchPadEnabled)

    return State
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
---@private
function N.init(scope, goToCurr, skipTrees)
    if not State.isActiveTabRegistered(State) then
        error("called the internal `init` method on a `nil` tab.")
    end

    D.log(scope,"init called on tab %d for current window %d",State.activeTab,State.getSideID(State, 'curr'))

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local hadSideBuffers = true
    if not State.isSideRegistered(State, 'left') or not State.isSideRegistered(State, 'right') then
        hadSideBuffers = false
    end

    W.createSideBuffers(skipTrees)

    if
        goToCurr
        or (not hadSideBuffers and (State.isSideRegistered(State, 'left') or State.isSideRegistered(State, 'right')))
        or (State.isSideTheActiveWin(State, 'left') or State.isSideTheActiveWin(State, 'right'))
    then
        vim.fn.win_gotoid(State.getSideID(State, 'curr'))
    end

    return State
end

--- Initializes the plugin, sets event listeners and internal state.
---@private
function N.enable(scope)
    if E.skipEnable() then
        return nil
    end

    D.log(scope, "calling enable for tab %d", State.activeTab)

    -- register the new tab.
    State.setTab(State, State.activeTab)

    local augroupName = A.getAugroupName()
    vim.api.nvim_create_augroup(augroupName, { clear = true })

    State.setSideID(State, vim.api.nvim_get_current_win(), 'curr')
    State.computeSplits(State, State.getSideID(State, 'curr'))

    N.init(scope, true)

    State.setEnabled(State)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(State.getTab(State)) then
                    return
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
                if not State.isActiveTabValid(State) then
                    State.refreshTabs(State, State.activeTab)
                end

                State.setActiveTab(State, vim.api.nvim_get_current_tabpage())

                D.log(p.event, "new tab page registered %d", State.activeTab)
            end)
        end,
        group = augroupName,
        desc = "Refreshes the active tab state",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                if not State.hasTabs(State) or E.skip(State.tabs[State.activeTab]) then
                    return
                end

                -- there's nothing to manage when there's no side buffer, fallback to vim's default behavior
                if
                    not State.isSideRegistered(State, 'left')
                    and not State.isSideRegistered(State, 'right')
                then
                    return D.log(p.event, "skip split logic: no side buffer")
                end

                -- a side tree isn't considered as a split
                local isSideTree, _ = T.isSideTree(p.event, nil)
                if isSideTree then
                    return D.log(p.event, "skip split logic: side tree")
                end

                local wins = State.getUnregisteredWins(State, false)

                if #wins ~= 1 then
                    return D.log(
                        p.event,
                        "skip split logic: no new or too many unregistered windows"
                    )
                end

                local focusedWin = wins[1]

                local isVSplit = State.computeSplits(State, focusedWin)
                State.setSplit(State, { id = focusedWin, vertical = isVSplit })

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
                if E.skip(nil) then
                    return
                end

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                if
                    State.tabs[State.activeTab] == nil
                    or State.tabs[State.activeTab].wins == nil
                    or State.tabs[State.activeTab].wins.splits == nil
                        and not W.stateWinsActive(State.getTab(State), false)
                then
                    D.log(p.event, "one of the NNP main buffers have been closed, disabling...")

                    return N.disable(p.event)
                end

                if _G.NoNeckPain.config.disableOnLastBuffer then
                    local rwins = State.getUnregisteredWins(State, false)

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
                if
                    E.skip(nil)
                    or State.tabs == nil
                    or State.tabs[State.activeTab] == nil
                    or State.tabs[State.activeTab].wins.splits == nil
                    or W.stateWinsActive(State.getTab(State), true)
                then
                    return
                end

                State.tabs[State.activeTab].wins.splits = vim.tbl_filter(function(split)
                    if vim.api.nvim_win_is_valid(split.id) then
                        return true
                    end

                    State.decreaseLayers(State, split.vertical)

                    return false
                end, State.tabs[State.activeTab].wins.splits)

                if #State.tabs[State.activeTab].wins.splits == 0 then
                    State.tabs[State.activeTab].wins.splits = nil
                end

                -- we keep track if curr have been closed because if it's the case,
                -- the focus will be on a side buffer which is wrong
                local haveCloseCurr = false

                -- if curr is not valid anymore, we focus the first valid split and remove it from the state
                if not vim.api.nvim_win_is_valid(State.getSideID(State, 'curr')) then
                    -- if neither curr and splits are remaining valids, we just disable
                    if State.tabs[State.activeTab].wins.splits == nil then
                        return N.disable(p.event)
                    end

                    haveCloseCurr = true


                    local split = State.tabs[State.activeTab].wins.splits[1]

                    State.decreaseLayers(State, split.vertical)
                    State.setSideID(State, split.id, 'curr')
                    State.removeSplit(State, split.id)
                end

                -- we only restore focus on curr if there's no split left
                N.init(p.event, haveCloseCurr or State.tabs[State.activeTab].wins.splits == nil)
            end)
        end,
        group = augroupName,
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                if not State.hasTabs(State) or State.tabs[State.activeTab] == nil or E.skip(State.getTab(State)) then
                    return
                end

                -- We can skip enter hooks that are not on a side tree
                local isSideTree, _ = T.isSideTree(p.event, nil)
                if p.event == "WinEnter" and not isSideTree then
                    return
                end

                -- we copy the state so we can compare with the refreshed trees what changed
                -- if something changed, we will run init in order to resize buffers correctly
                local stateTrees = vim.deepcopy(State.tabs[State.activeTab].wins.external.trees)
                local shouldInit = false

                State.tabs[State.activeTab].wins.external.trees = T.refresh()

                for name, tree in pairs(State.tabs[State.activeTab].wins.external.trees) do
                    if
                        -- if we had an id but it's not valid anymore or it changed
                        (
                            stateTrees[name] ~= nil
                            and stateTrees[name].id ~= nil
                            and (tree.id == nil or tree.id ~= tree.id)
                        )
                        -- if we registered a new side tree
                        or (
                            tree.id ~= nil
                            and (stateTrees[name] == nil or stateTrees[name].id ~= tree.id)
                        )
                    then
                        D.log(p.event, "%s has changed, resizing", name)

                        shouldInit = true
                    end
                end

                if shouldInit then
                    N.init(p.event, false, true)
                end
            end)
        end,
        group = augroupName,
        desc = "Resize to apply on WinEnter/Closed of external windows",
    })

    return State
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@private
function N.disable(scope)
    D.log(scope, "calling disable for tab %d", State.activeTab)

    pcall(vim.api.nvim_del_augroup_by_name, A.getAugroupName())

    local currID = State.getSideID(State, 'curr')

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if
        currID ~= nil
        and vim.api.nvim_win_is_valid(currID)
        and not State.isSideTheActiveWin(State, 'curr')
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
                State.activeTab,
                side
            )
        )
        vim.cmd(
            string.format(
                "highlight! clear NoNeckPain_text_tab_%s_side_%s NONE",
                State.activeTab,
                side
            )
        )

        if State.isSideRegistered(State, side) then
            local activeWins = vim.api.nvim_tabpage_list_wins(State.activeTab)
            local haveOtherWins = false

            local sideID = State.getSideID(State, side)

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

    State.refreshTabs(State)

    if not State.hasTabs(State) then
        D.log(scope, "no more active tabs left, reinitializing state")

        State.init(State)
    end

    return State
end

return N
