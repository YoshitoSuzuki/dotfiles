local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("go", {
  s("main", {
    t({
      "package main",
      'import "fmt"',
      "",
      "func main() {",
      "",
    }),
    i(1),
    t({
      "",
      "}",
    }),
  }),
})
