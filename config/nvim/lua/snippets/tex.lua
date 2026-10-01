local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

ls.add_snippets("tex", {
  s("main", {
    t({
      "%!TEX program = lualatex",
      "\\documentclass{article}",
      "",
      "\\usepackage{luatexja}",
      "\\usepackage{luatexja-fontspec}",
      "\\usepackage{listings}",
      "\\usepackage{amssymb}",
      "\\usepackage{forest}",
      "",
      "\\lstset{",
      "  basicstyle=\\ttfamily\\small,",
      "  frame=single,",
      "  breaklines=true,",
      "  breakatwhitespace=true,",
      "  columns=fullflexible",
      "}",
      "",
      "\\usepackage[",
      "  a4paper,",
      "  top=25mm,",
      "  bottom=25mm,",
      "  left=25mm,",
      "  right=25mm",
      "]{geometry}",
      "",
      "\\forestset{",
      "  heap/.style={",
      "    for tree={",
      "      circle, draw, minimum size=2.5em, inner sep=1pt,",
      "      l=1.2cm, s sep=0.8cm, font=\\small,",
      "      edge={thick}",
      "    }",
      "  }",
      "}",
      "",
      "\\usepackage{microtype}",
      "\\usepackage{bussproofs}",
      "\\EnableBpAbbreviations",
      "",
      "\\setmainjfont{Hiragino Mincho ProN}",
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
