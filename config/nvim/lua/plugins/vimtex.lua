return {
  "lervag/vimtex",
  lazy = false, -- TeXファイルを開いたら即有効
  init = function()
    vim.g.vimtex_compiler_method = "latexmk"
    -- 既定の -pdf（pdflatex）にさせない。-shell-escape は latexmkrc の $lualatex に書いてある
    vim.g.vimtex_compiler_latexmk_engines = { _ = "-lualatex" }
    vim.g.vimtex_view_method = "skim" -- macOS
    vim.g.vimtex_quickfix_mode = 0
  end,
}
