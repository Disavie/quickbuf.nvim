--/home/davis/nvim-plugins/quickbuf.nvim/lua/quickbuf/init.lua
local M = {}
-- name : id pairs
M.active_buffers = {}
M.state = {
    buf = -1,
    win = -1
}
M.parent_win = -1
_G.statusline_input = ""

local function is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "directory"
end

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

    M.state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("modifiable",true, { buf = M.state.buf} )
end

local check_new_buffers = function()
    for _, bid in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[bid].buflisted then
            --truncate name
            local name =vim.api.nvim_buf_get_name(bid)

            if is_dir(name) ~= nil then
                name = vim.fn.fnamemodify(name, ":~:.")
                if M.active_buffers[name] == nil then
                    M.active_buffers[name] = bid
                end
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

            local name =vim.api.nvim_buf_get_name(bid)

            if is_dir(name) ~= nil then
                print(is_dir(name))
                name = vim.fn.fnamemodify(name, ":~:.")
                if name ~= "" and name ~= "~"  then
                    if M.active_buffers[name] == bid then
                        new_active[name] = bid
                    end
                end
            end
        end
    end
    M.active_buffers = new_active
end

local prompt = function()
    local input = vim.fn.input( { prompt = "This buffer is not saved are you sure you want to delete it? [y/n] "} )
    if input == "y" then
        return true
    end
    return false
end

local close_deleted_buffers = function()

    local current = vim.api.nvim_list_bufs()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local current_set = {}
    for _, bname in ipairs(lines) do
        current_set[bname] = true
    end

    for name, b in pairs(M.active_buffers) do
        if not current_set[name] then

            if M.active_buffers[name] == vim.api.nvim_win_get_buf(M.parent_win) then
                local new_buf = vim.api.nvim_create_buf(true, false)
                local placeholder = "~"
                M.active_buffers[placeholder] = new_buf
                vim.api.nvim_win_set_buf(M.parent_win,M.active_buffers[placeholder])
            end

            local ismodified = vim.api.nvim_get_option_value("modified", { buf = b} )
            if ismodified then
                local v = prompt()
                if v then
                    print("here we go!")
                    M.active_buffers[name] = nil
                    vim.cmd("bd!"..b)
                else
                    populate_win()
                end
            else
                M.active_buffers[name] = nil
                vim.cmd("bd"..b)
            end
        end
    end
end

local create_win = function()
    M.parent_win = vim.api.nvim_get_current_win()

     local ui = vim.api.nvim_list_uis()[1]
     local width = math.floor(ui.width * 0.3)
     local height = math.floor(ui.height * 0.3)
     local row = math.floor((ui.height - height) / 2)
     local col = math.floor((ui.width - width) / 2)

     local buf = nil


    M.state.win = vim.api.nvim_open_win(M.state.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        --style = "minimal",
        border = "rounded",
    })

    remove_closed_buffers()
    check_new_buffers()
    populate_win()
end

local close = function()
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_hide(M.state.win)
    end
end

M.setup = function()
    init()

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

    vim.keymap.set("n", "<CR>", function()
            local lineno = vim.api.nvim_win_get_cursor(M.state.win)[1]
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local word = lines[lineno]

            if M.active_buffers[word] == nil then

                local new_buf = vim.api.nvim_create_buf(true, false)
                vim.api.nvim_buf_set_name(new_buf,word)
                vim.api.nvim_buf_call(new_buf, function()
                    vim.cmd("edit")
                end)

                M.active_buffers[word] = new_buf
            end
            if not vim.api.nvim_win_is_valid(M.parent_win) then
                vim.cmd.split()
            end
            vim.api.nvim_win_set_buf(M.parent_win,M.active_buffers[word])

            if vim.api.nvim_win_is_valid(M.state.win) then
                vim.api.nvim_win_hide(M.state.win)
            end
        end, {buffer = M.state.buf, nowait = true})


    local group = vim.api.nvim_create_augroup("FloatingBuffers", { clear = true })
    vim.api.nvim_create_autocmd({'InsertLeave','TextChanged'}, {
        group = group,
        buffer = M.state.buf,
        callback = function()
            close_deleted_buffers()
        end,
    })
    vim.api.nvim_create_user_command("QuickBufLs", function()
        print(vim.inspect(M.active_buffers))


    end, {})

    vim.api.nvim_create_user_command("QuickBufDebug", function()
        vim.ui.input( { prompt = "This buffer is not saved are you sure you want to delete it? [y/n]"}, function(input)
            if input == "y" then
                print("ok")
            else
                print("dang")
            end
        end)
    end, {})
end


return M
