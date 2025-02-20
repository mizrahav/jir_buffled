local M = {}
 
-- Function to list buffers sorted by number
local function list_buffers_sorted_by_number()
    local buffers = vim.api.nvim_list_bufs()
    table.sort(buffers)

    -- Find the maximum buffer number length
    local max_buf_num_length = 0
    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'filetype') ~= 'buffled' then
            local buf_num_length = #tostring(buf)
            if buf_num_length > max_buf_num_length then
                max_buf_num_length = buf_num_length
            end
        end
    end

    local lines = {}
    local highlights = {}
    local current_buf = vim.api.nvim_get_current_buf()
    local windows = vim.api.nvim_list_wins()
    local open_buffers = {}

    -- Collect buffers that are open in any window
    for _, win in ipairs(windows) do
        local buf = vim.api.nvim_win_get_buf(win)
        open_buffers[buf] = true
    end

    -- Add header
    table.insert(lines, "  LIST OF BUFFERS")
    table.insert(highlights, { 1, 0,  2, 'String' }) -- Highlight the header with the same color as the numbers
    table.insert(highlights, { 1, 2, -1, 'Function' }) -- Highlight the header with the same color as the numbers

    local padding = ''
    local modified_char
    local modified
    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, 'filetype') ~= 'buffled' then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == '' then
                buf_name = '[No Name]'
            else
                buf_name = vim.fn.fnamemodify(buf_name, ':t') -- Get file name without path
            end
            local buf_num_str = string.format("#%d", buf)
            if buf < 10 then
                padding = " "
            end
            modified = vim.api.nvim_buf_get_option(buf, 'modified')
            if modified then
                modified_char = '+'
            else
                modified_char = ' '
            end
            local line = string.format("   %s%s: %s%s", buf_num_str, padding, buf_name, modified_char)
            table.insert(lines, line)

            local highlight_group = 'Normal'
            if buf == current_buf then
                highlight_group = 'Statement'
            elseif open_buffers[buf] then
                highlight_group = 'PreProc'
            elseif modified then 
                highlight_group = 'BufferModified'
            end

            table.insert(highlights, { #lines, 0, #buf_num_str + 3, 'Function' }) -- Highlight the # and number with Function color
            table.insert(highlights, { #lines, #buf_num_str + 3, -1, highlight_group }) -- Highlight the rest of the line based on buffer state
        end
    end

    -- Debug prints
    if not lines or #lines == 0 then
        print("list_buffers_sorted_by_number: No buffers found or empty lines")
    end

    return lines, highlights
end

-- Function to open buffer list window
local function open_buffer_list_window()
    -- Check if the buffer list window already exists
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_option(buf, 'filetype') == 'buffled' then
            return win, buf
        end
    end

    -- Create a new window for buffer list
    vim.cmd('noautocmd vsplit')
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    if not buf then
        vim.api.nvim_err_writeln("Failed to create buffer")
        return
    end
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'buffled')
    vim.api.nvim_win_set_width(win, 30)

    -- Apply the custom highlight group to the window
    vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:BuffledWindow')

    -- Make the window non-focusable
    vim.api.nvim_win_set_option(win, 'winfixwidth', true)
    vim.api.nvim_win_set_option(win, 'winfixheight', true)
    vim.api.nvim_win_set_option(win, 'cursorline', false)
    vim.api.nvim_win_set_option(win, 'number', false) -- Disable line numbers
    vim.api.nvim_win_set_option(win, 'relativenumber', false) -- Disable relative line numbers

    return win, buf
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

return M
