# jir-buffled

had to write something similar to minibufexp in vim

how to use:
return {
    'mizrahav/jir_buffled',
    name = 'jir_buffled',
    event = 'VeryLazy',
    config = function()
        vim.api.nvim_set_hl(0, 'BuffledWindow', { bg = '#000000' })
        vim.api.nvim_set_hl(0, 'BuffledCurrentBuffer', { bg = '#2e2a27' })
        vim.api.nvim_set_hl(0, 'BuffledBufferNumber', { bg = '#2e2a27' })
        vim.api.nvim_set_hl(0, 'BuffledBufferName', { bg = '#2e2a27' })
        vim.api.nvim_set_hl(0, 'BufferModified', { fg = '#FF0000' })
        require('jirbuffled').setup {}
    end,
}

next features:
- [ ] select color from config


