return {
  "lervag/vimtex",
  lazy = false, -- TeXファイルを開いたら即有効
  init = function()
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_view_method = "skim" -- macOS
    vim.g.vimtex_quickfix_mode = 0
  end,
}
