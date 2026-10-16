-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.opt.clipboard = "unnamedplus"

-- フルカラーを扱えない端末（GNU screen 4.x など）では 256 色の配色にする。
-- LazyVim が読み込み中に termguicolors を有効にするので、読み込みのあとで上書きする
local colorterm = vim.env.COLORTERM or ""
if colorterm ~= "truecolor" and colorterm ~= "24bit" and (vim.env.TERM or ""):match("^screen") then
  vim.opt.termguicolors = false
end
