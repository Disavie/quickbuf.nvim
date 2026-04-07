--/home/davis/nvim-plugins/quickbuf.nvim/lua/quickbuf/init.lua
local M = {}
-- name : id pairs
M.active_buffers = {}
M.state = {
    buf = -1,
    win = -1
}
M.parent_win = -1

local populate_win = function()
    local names = {}
    for name, id in pairs(M.active_buffers) do
        table.insert(names,name)
    end
    vim.api.nvim_buf_set_lines(M.state.buf,0,-1, false,names)
end

local init = function()
    for _, bid in ipairs(vim.api.nvim_list_bufs()) do
        --sort out to only listed buffers 
        if vim.bo[bid].buflisted then
            --truncate name
            local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bid), ":~:.")
            if name ~= "" and name ~= "~"  then
                M.active_buffers[name] = bid
            end
        end
    end
end

local check_new_buffers = function()
    for _, bid in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[bid].buflisted then
            --truncate name
            local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bid), ":~:.")
            if M.active_buffers[name] == nil then
                M.active_buffers[name] = bid
            end
        end
    end
end

local remove_closed_buffers = function()
    local new_active = {}
    local bids = vim.api.nvim_list_bufs()

    -- Mark all active buffers
    for _, bid in ipairs(bids) do
        if vim.bo[bid].buflisted then
            local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bid), ":~:.")
            if name ~= "" and name ~= "~"  then
                if M.active_buffers[name] == bid then
                    new_active[name] = bid
                end
            end
        end
    end
    M.active_buffers = new_active
end

local create_win = function()
    M.parent_win = vim.api.nvim_get_current_win()

     local ui = vim.api.nvim_list_uis()[1]
     local width = math.floor(ui.width * 0.3)
     local height = math.floor(ui.height * 0.3)
     local row = math.floor((ui.height - height) / 2)
     local col = math.floor((ui.width - width) / 2)

     local buf = nil

    if vim.api.nvim_buf_is_valid(M.state.buf) then
        --refresh list
    else
        M.state.buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable",true, { buf = M.state.buf} )
    end

    remove_closed_buffers()
    check_new_buffers()
    populate_win()

    M.state.win = vim.api.nvim_open_win(M.state.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        --style = "minimal",
        border = "rounded",
    })
end

local close = function()
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_hide(M.state.win)
    end
end

M.setup = function()
    init()


    print(vim.inspect(M.active_buffers))

    vim.api.nvim_create_user_command("QuickBufToggle", function()
        -- open and populate if closed
        if not vim.api.nvim_win_is_valid(M.state.win) then
            create_win()
        else
        -- hide
            vim.api.nvim_win_hide(M.state.win)
        end
    end, {} )
    vim.keymap.set("n",'<leader><leader>',function() vim.cmd("QuickBufToggle") end)

    vim.keymap.set("n", "<Esc>", function() close() end, { buffer = M.state.buf, nowait = true })
    vim.keymap.set("n", "<C-c>", function() close() end, { buffer = M.state.buf, nowait = true })










    vim.api.nvim_create_user_command("QuickBufDebug", function()
        print(vim.inspect(M.active_buffers))
    end, {})


end

return M

