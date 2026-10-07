local M = {}

-- Function to list buffers sorted by number
local function list_buffers_sorted_by_number()
    local buffers = vim.api.nvim_list_bufs()
    table.sort(buffers)

    local lines = {}
    local highlights = {}

    -- Add header
    table.insert(lines, "  LIST OF BUFFERS")
    table.insert(highlights, { 1, 0,  2, 'String' }) -- Highlight the header with the same color as the numbers
    table.insert(highlights, { 1, 2, -1, 'Function' }) -- Highlight the header with the same color as the numbers

    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == '' and vim.bo[buf].filetype ~= 'buffled' then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == '' then
                buf_name = '[No Name]'
            else
                buf_name = vim.fn.fnamemodify(buf_name, ':t') -- Get file name without path
            end
            local buf_num_str = string.format("#%d", buf)
            local modified = vim.api.nvim_buf_get_option(buf, 'modified')
            local modified_char = modified and '+' or ' '
            local line = string.format("   %s: %s%s", buf_num_str, buf_name, modified_char)
            table.insert(lines, line)

            local highlight_group = 'Normal'
            if buf == vim.api.nvim_get_current_buf() then
                highlight_group = 'Statement'
            elseif modified then 
                highlight_group = 'BufferModified'
            end

            table.insert(highlights, { #lines, 0, #buf_num_str + 3, 'Function' }) -- Highlight the # and number with Function color
            table.insert(highlights, { #lines, #buf_num_str + 3, -1, highlight_group }) -- Highlight the rest of the line based on buffer state
        end
    end

    return lines, highlights
end

-- Function to open buffer list window as a vertical split
local function open_buffer_list_window()
    -- Save the current window ID to return focus to it later
    local original_win = vim.api.nvim_get_current_win()

    -- Check if the buffer list window already exists
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_option(buf, 'filetype') == 'buffled' then
            return win, buf
        end
    end

    -- Create a new vertical split for buffer list
    vim.cmd('topleft vsplit')  -- 'botright vsplit' for right side
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    if not buf then
        vim.api.nvim_err_writeln("Failed to create buffer")
        return
    end
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'buffled')
    vim.api.nvim_win_set_width(win, 30)  -- Adjust the width as needed

    -- Apply the custom highlight group to the window
    vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:BuffledWindow')

    -- Make the window non-focusable
    vim.api.nvim_win_set_option(win, 'cursorline', false)
    vim.api.nvim_win_set_option(win, 'number', false) -- Disable line numbers
    vim.api.nvim_win_set_option(win, 'relativenumber', false) -- Disable relative line numbers

    -- Update the buffer list immediately
    M.update_buffer_list()

    -- Return focus to the original window
    vim.api.nvim_set_current_win(original_win)

    return win, buf
end

-- Function to toggle buffer list window
local function toggle_buffer_list_window()
    local augroup_name = "Buffled"

    -- Temporarily disable the autocommand group to prevent immediate reopening
    vim.api.nvim_del_augroup_by_name(augroup_name)

    local window_closed = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_option(buf, 'filetype') == 'buffled' then
            -- Close the window if found
            vim.api.nvim_win_close(win, true)
            window_closed = true
            break
        end
    end

    if not window_closed then
        -- If the window was not open, open it
        open_buffer_list_window()
    end

    -- Recreate the autocommand group
    vim.api.nvim_create_augroup(augroup_name, { clear = true })
    vim.api.nvim_create_autocmd({"BufAdd", "BufEnter", "BufDelete", "BufWinEnter", "BufWinLeave", "InsertLeave", "TextChanged", "TextChangedI", "BufWritePost"}, {
        group = augroup_name,
        callback = vim.schedule_wrap(function()
            if M.update_buffer_list then
                M.update_buffer_list()
            else
                vim.api.nvim_err_writeln("Failed to update buffer list: function not found")
            end
        end)
    })
end

-- Function to update buffer list
function M.update_buffer_list()
    local cur_win = vim.api.nvim_get_current_win()
    local win, buf = open_buffer_list_window()
    if not win or not buf then return end

    local lines, highlights = list_buffers_sorted_by_number()
    
    -- Ensure lines and highlights are not nil
    lines = lines or {}
    highlights = highlights or {}

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Apply highlights
    for _, hl in ipairs(highlights) do
         vim.api.nvim_buf_add_highlight(buf, -1, hl[4], hl[1] - 1, hl[2], hl[3])
    end

    -- Return focus to the original window
    vim.api.nvim_set_current_win(cur_win)
end

-- Expose the toggle function
M.toggle_buffer_list_window = toggle_buffer_list_window

return M
