-- lua/config/luasnip.lua
local ls = require("luasnip")

-- Tabでスニペット展開 or 次へ
vim.keymap.set({ "i", "s" }, "<Tab>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, true, true), "n", false)
  end
end, { silent = true })

-- Shift-Tabで前へ
vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true })

-- 自作 snippets を読み込む
require("luasnip.loaders.from_lua").load({
  paths = vim.fn.stdpath("config") .. "/lua/snippets",
})
