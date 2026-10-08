# Neovim で TypeScript / React (TSX) を書く構成

- 更新日: 2026-09-19

`~/.config/nvim` は LazyVim。TSX/React 用に入れたもの・確認方法のメモ。

## すでに LazyVim 側で入っているので追加不要

- `nvim-ts-autotag` — JSX タグの自動閉じ・ペア改名
- `ts-comments.nvim` — JSX の中で `{/* */}` に切り替わるコメント
- `lang.typescript` extra（vtsls）、`lang.tailwind` extra

「JSXのタグ補完とコメントのプラグインを入れる」と提案する前に `lazy-lock.json` を見ること。

## 足したもの（lua/plugins/react.lua + lazyvim.json）

| 追加 | 何のため |
|---|---|
| `formatting.prettier` extra | conform に prettier を繋ぐ。**typescript extra だけでは prettier は入らない** |
| `linting.eslint` extra | eslint-lsp。プロジェクトに eslint 設定があるときだけ attach |
| `emmet_language_server` | `filetypes` に `javascriptreact` / `typescriptreact` を明示して JSX でも Emmet |
| `ts-error-translator.nvim` | TS のエラー文を平易な英語に置換（診断メッセージ自体が書き換わる） |
| `package-info.nvim` | package.json に最新バージョンを inline 表示 |
| `template-string.nvim` | `"..."` の中で `${` を打つとバッククォートに変換 |

## キーマップの空き

LazyVim は `<leader>` 直下の小文字をほぼ使い切っている（a b c d e f g h l m n o p q r s t u w x）。
`<leader>n` は Notification History。**新しいグループを作るなら大文字**（package-info は `<leader>N` = npm にした）。
衝突確認は `grep -oE '"<leader>[a-zA-Z]' ~/.local/share/nvim/lazy/LazyVim/lua -r | sort -u`。

## headless での検証手順

`nvim --headless "+Lazy! sync" +qa` は **mason のインストール途中で nvim が落ちる**
（`Neovim is exiting while packages are still installing`）。mason のツールは別途：

```sh
nvim --headless "+Lazy! load mason.nvim" "+MasonInstall prettier eslint-lsp emmet-language-server" +qa
```

`mason.nvim` は遅延ロードなので `+Lazy! load mason.nvim` を先に入れないと `E492: Not an editor command`。
終了時に `list.lua:176: attempt to index local 'value'` が出ても、
`~/.local/share/nvim/mason/packages` に入っていればインストール自体は成功している。

LSP の attach と整形の確認は、scratch に tsconfig.json + package.json + .tsx を作って：

```lua
vim.defer_fn(function()
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do print(c.name) end
  local conform = require("conform")
  for _, f in ipairs(conform.list_formatters(0)) do print(f.name, f.available) end
  conform.format({ bufnr = 0, timeout_ms = 5000 })
  print(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
  vim.cmd("qa!")
end, 6000)
```

を `nvim --headless src/App.tsx -c "luafile ..."` で流す。LSP の起動を待つので defer は 6〜9 秒必要。
tailwindcss LSP は tailwind の設定ファイルが無いプロジェクトでは attach しない（異常ではない）。
