local buffled = require('jirbuffled.buffled')

local M = {}

M.setup = function()
    -- Define custom highlight groups for the buffer list window
    vim.cmd('highlight BuffledWindow guibg=#282c34')
    vim.cmd('highlight BufferModified guifg=#FF0000 guibg=NONE ctermfg=red ctermbg=NONE')

    -- Setup autocommand group
    local augroup = vim.api.nvim_create_augroup("Buffled", { clear = true })
    vim.api.nvim_create_autocmd({"BufAdd", "BufEnter", "BufDelete", "BufWinEnter", "BufWinLeave", "InsertLeave", "TextChanged", "TextChangedI", "BufWritePost"}, {
        group = augroup,
        callback = vim.schedule_wrap(function()
            if buffled and buffled.update_buffer_list then
                buffled.update_buffer_list()
            else
                vim.api.nvim_err_writeln("Failed to update buffer list: buffled module or function not found")
            end
        end)
    })

    vim.schedule(function()
        if buffled and buffled.update_buffer_list then
            buffled.update_buffer_list()
        end
    end)
end

return M

