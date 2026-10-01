-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Markdown を読み書きするときの見た目。LazyVim の wrap_spell より後に走らせて
-- spell（日本語だと全部赤波線になる）を打ち消しつつ、折り返しを整える。
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown_prose", { clear = true }),
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.opt_local.spell = false
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true -- 単語の途中で折り返さない
    vim.opt_local.breakindent = true
    vim.opt_local.breakindentopt = ""
    vim.opt_local.showbreak = "  " -- 引用の縦線を折り返し行にも繋げるため
    vim.opt_local.textwidth = 0
  end,
})
