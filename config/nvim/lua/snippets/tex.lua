local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

ls.add_snippets("tex", {
  s("main", {
    -- いつもの設定は ytex にまとめてある（~/bin/assets/tx/ytex、使い方は ~/bin/docs/tx.md）
    t({
      "%!TEX program = lualatex",
      "\\documentclass[a4paper]{ltjarticle}",
      "\\usepackage[tree,proof]{ytex}",
      "",
      "\\title{",
    }),
    i(1),
    t({ "}", "\\author{" }),
    -- 著者名は環境変数 TEX_AUTHOR から入れる（~/.config/shell/local.sh で export する）
    f(function()
      return os.getenv("TEX_AUTHOR") or ""
    end),
    t({
      "}",
      "\\date{}",
      "",
      "\\begin{document}",
      "\\maketitle",
      "",
      "",
      "",
      "\\end{document}",
      "",
    }),
  }),
})
