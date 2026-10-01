-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
-- -- R（radian）の場所をNeovimに教えてあげる設定
vim.g.iron_config = {
  config = {
    repl_definition = {
      r = {
        command = { "/opt/homebrew/bin/radian" }, -- 👈 ここをステップ1で調べたパスに書き換える
      },
    },
  },
}
