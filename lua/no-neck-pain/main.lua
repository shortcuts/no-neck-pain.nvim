local A = require("no-neck-pain.util.api")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local Sp = require("no-neck-pain.splits")
local T = require("no-neck-pain.trees")
local Ta = require("no-neck-pain.tabs")
local W = require("no-neck-pain.wins")

local N = {}
local S = Ta.initState()

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
---@private
function N.toggle(scope)
    if S.tabs ~= nil and S.tabs[S.activeTab] ~= nil then
        return N.disable(scope)
    end

    return N.enable(scope)
end

--- Toggles the scratchPad feature of the plugin.
---@private
function N.toggleScratchPad()
    if S.tabs[S.activeTab] == nil then
        return
    end

    -- store the current win to later restore focus
    local currWin = vim.api.nvim_get_current_win()

    -- map over both sides and let the init method either setup or cleanup the side buffers
    for _, side in pairs(Co.SIDES) do
        vim.fn.win_gotoid(S.tabs[S.activeTab].wins.main[side])
        W.initScratchPad(side, S.tabs[S.activeTab].scratchPadEnabled)
    end

    -- restore focus
    vim.fn.win_gotoid(currWin)

    -- save new state of the scratchpad and update tabs
    S.tabs[S.activeTab].scratchPadEnabled = not S.tabs[S.activeTab].scratchPadEnabled
    S.tabs = Ta.update(S.tabs, S.tabs[S.activeTab].id, S.tabs[S.activeTab])

    return S
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
---@private
function N.init(scope, goToCurr, skipTrees)
    if S.tabs[S.activeTab] == nil then
        error("called the internal `init` method on a `nil` tab.")
    end

    D.log(
        scope,
        "init called on tab %d for current window %d",
        S.tabs[S.activeTab].id,
        S.tabs[S.activeTab].wins.main.curr
    )

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local hadSideBuffers = true
    if
        not A.sideExist(S.tabs[S.activeTab], "left")
        or not A.sideExist(S.tabs[S.activeTab], "right")
    then
        hadSideBuffers = false
    end

    S.tabs[S.activeTab] = W.createSideBuffers(S.tabs[S.activeTab], skipTrees)

    if
        goToCurr
        or (not hadSideBuffers and (A.sideExist(S.tabs[S.activeTab], "left") or A.sideExist(
            S.tabs[S.activeTab],
            "right"
        )))
        or (
            A.isCurrentWin(S.tabs[S.activeTab].wins.main.left)
            or A.isCurrentWin(S.tabs[S.activeTab].wins.main.right)
        )
    then
        vim.fn.win_gotoid(S.tabs[S.activeTab].wins.main.curr)
    end

    S.tabs = Ta.update(S.tabs, S.tabs[S.activeTab].id, S.tabs[S.activeTab])

    return S
end

--- Initializes the plugin, sets event listeners and internal state.
---@private
function N.enable(scope)
    if E.skipEnable(nil) then
        return nil
    end

    D.log(scope, "calling enable for tab %d", S.activeTab)

    -- register the new tab.
    S.tabs = Ta.insert(S.tabs, S.activeTab)

    local augroupName = Ta.getAugroupName(S.activeTab)
    vim.api.nvim_create_augroup(augroupName, { clear = true })

    S.tabs[S.activeTab].wins.main.curr = vim.api.nvim_get_current_win()
    S.tabs[S.activeTab], _ = Sp.compute(S.tabs[S.activeTab], S.tabs[S.activeTab].wins.main.curr)

    S = N.init(scope, true)

    S.enabled = true

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(S.tabs[S.activeTab]) then
                    return
                end

                S = N.init(p.event)
            end)
        end,
        group = augroupName,
        desc = "Resizes side windows after terminal has been resized, closes them if not enough space left.",
    })

    vim.api.nvim_create_autocmd({ "TabLeave" }, {
        callback = function(p)
            vim.schedule(function()
                -- if the left tab is not valid anymore, we can remove it from the state
                if not vim.api.nvim_tabpage_is_valid(S.activeTab) then
                    S.tabs = Ta.refresh(S.tabs, S.activeTab)
                end

                S.activeTab = vim.api.nvim_get_current_tabpage()

                D.log(p.event, "new tab page registered %d", S.activeTab)
            end)
        end,
        group = augroupName,
        desc = "Refreshes the active tab state",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                if S.tabs == nil or E.skip(S.tabs[S.activeTab]) then
                    return
                end

                -- there's nothing to manage when there's no side buffer, fallback to vim's default behavior
                if
                    not A.sideExist(S.tabs[S.activeTab], "right")
                    and not A.sideExist(S.tabs[S.activeTab], "left")
                then
                    return D.log(p.event, "skip split logic: no side buffer")
                end

                -- a side tree isn't considered as a split
                local isSideTree, _ = T.isSideTree(p.event, S.tabs[S.activeTab], nil)
                if isSideTree then
                    return D.log(p.event, "skip split logic: side tree")
                end

                local wins = A.winsExceptState(S.tabs[S.activeTab], false)

                if #wins ~= 1 then
                    return D.log(
                        p.event,
                        "skip split logic: no new or too many unregistered windows"
                    )
                end

                local focusedWin = wins[1]
                local isVSplit = true

                S.tabs[S.activeTab], isVSplit = Sp.compute(S.tabs[S.activeTab], focusedWin)
                S.tabs[S.activeTab].wins.splits = S.tabs[S.activeTab].wins.splits or {}
                table.insert(
                    S.tabs[S.activeTab].wins.splits,
                    { id = focusedWin, vertical = isVSplit }
                )

                if isVSplit then
                    S = N.init(p.event)
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
                    S.tabs[S.activeTab] == nil
                    or S.tabs[S.activeTab].wins == nil
                    or S.tabs[S.activeTab].wins.splits == nil
                        and not W.stateWinsActive(S.tabs[S.activeTab], false)
                then
                    D.log(p.event, "one of the NNP main buffers have been closed, disabling...")

                    return N.disable(p.event)
                end

                if _G.NoNeckPain.config.disableOnLastBuffer then
                    local rwins = A.winsExceptState(S.tabs[S.activeTab], true)

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
                    or S.tabs == nil
                    or S.tabs[S.activeTab] == nil
                    or S.tabs[S.activeTab].wins.splits == nil
                    or W.stateWinsActive(S.tabs[S.activeTab], true)
                then
                    return
                end

                S.tabs[S.activeTab].wins.splits = vim.tbl_filter(function(split)
                    if vim.api.nvim_win_is_valid(split.id) then
                        return true
                    end

                    S.tabs[S.activeTab].layers =
                        Sp.decreaseLayers(S.tabs[S.activeTab].layers, split.vertical)

                    return false
                end, S.tabs[S.activeTab].wins.splits)

                if #S.tabs[S.activeTab].wins.splits == 0 then
                    S.tabs[S.activeTab].wins.splits = nil
                end

                -- we keep track if curr have been closed because if it's the case,
                -- the focus will be on a side buffer which is wrong
                local haveCloseCurr = false

                -- if curr is not valid anymore, we focus the first valid split and remove it from the state
                if not vim.api.nvim_win_is_valid(S.tabs[S.activeTab].wins.main.curr) then
                    -- if neither curr and splits are remaining valids, we just disable
                    if S.tabs[S.activeTab].wins.splits == nil then
                        return N.disable(p.event)
                    end

                    haveCloseCurr = true

                    S.tabs[S.activeTab].layers = Sp.decreaseLayers(
                        S.tabs[S.activeTab].layers,
                        S.tabs[S.activeTab].wins.splits[1].vertical
                    )

                    S.tabs[S.activeTab].wins.main.curr = S.tabs[S.activeTab].wins.splits[1].id
                    S.tabs[S.activeTab].wins.splits = Sp.remove(
                        S.tabs[S.activeTab].wins.splits,
                        S.tabs[S.activeTab].wins.splits[1].id
                    )
                end

                -- we only restore focus on curr if there's no split left
                S = N.init(p.event, haveCloseCurr or S.tabs[S.activeTab].wins.splits == nil)
            end)
        end,
        group = augroupName,
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                if S.tabs == nil or S.tabs[S.activeTab] == nil or E.skip(S.tabs[S.activeTab]) then
                    return
                end

                -- We can skip enter hooks that are not on a side tree
                local isSideTree, _ = T.isSideTree(p.event, S.tabs[S.activeTab], nil)
                if p.event == "WinEnter" and not isSideTree then
                    return
                end

                -- we copy the state so we can compare with the refreshed trees what changed
                -- if something changed, we will run init in order to resize buffers correctly
                local stateTrees = vim.deepcopy(S.tabs[S.activeTab].wins.external.trees)
                local shouldInit = false

                S.tabs[S.activeTab].wins.external.trees = T.refresh(S.tabs[S.activeTab])

                for name, tree in pairs(S.tabs[S.activeTab].wins.external.trees) do
                    if
                        -- if we had an id but it's not valid anymore or it changed
                        (stateTrees[name].id ~= nil and (tree.id == nil or tree.id ~= tree.id))
                        -- if we registered a new side tree
                        or (tree.id ~= nil and stateTrees[name].id ~= tree.id)
                    then
                        D.log(p.event, "%s has changed, resizing", name)

                        shouldInit = true
                    end
                end

                if shouldInit then
                    S = N.init(p.event, false, true)
                end
            end)
        end,
        group = augroupName,
        desc = "Resize to apply on WinEnter/Closed of external windows",
    })

    return S
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@private
function N.disable(scope)
    -- if S.tabs[S.activeTab] == nil then
    --     return S
    -- end

    D.log(scope, "calling disable for tab %d", S.tabs[S.activeTab].id)

    pcall(vim.api.nvim_del_augroup_by_name, Ta.getAugroupName(S.activeTab))

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if
        S.tabs[S.activeTab].wins.main.curr ~= nil
        and vim.api.nvim_win_is_valid(S.tabs[S.activeTab].wins.main.curr)
        and not A.isCurrentWin(S.tabs[S.activeTab].wins.main.curr)
    then
        vim.fn.win_gotoid(S.tabs[S.activeTab].wins.main.curr)

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end

    -- determine if we should quit vim or just close the window
    for _, side in pairs(Co.SIDES) do
        vim.cmd(
            string.format(
                "highlight! clear NoNeckPain_background_tab_%s_side_%s NONE",
                S.tabs[S.activeTab].id,
                side
            )
        )
        vim.cmd(
            string.format(
                "highlight! clear NoNeckPain_text_tab_%s_side_%s NONE",
                S.tabs[S.activeTab].id,
                side
            )
        )

        if A.sideExist(S.tabs[S.activeTab], side) then
            local activeWins = vim.api.nvim_tabpage_list_wins(S.tabs[S.activeTab].id)
            local haveOtherWins = false

            -- if we have other wins active and usable, we won't quit vim
            for _, activeWin in pairs(activeWins) do
                if
                    S.tabs[S.activeTab].wins.main[side] ~= activeWin
                    and not A.isRelativeWindow(activeWin)
                then
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
            W.close(scope, S.tabs[S.activeTab].wins.main[side], side)
        end
    end

    S.tabs = Ta.refresh(S.tabs)

    if S.tabs == nil then
        D.log(scope, "no more active tabs left, reinitializing state")

        S = Ta.initState()
    end

    return S
end

return N
