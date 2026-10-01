local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("gitignore", {
  s("main", {
    t({
      ".DS_Store",
      "",
      ".idea/",
      "",
      "*.log",
      "",
      ".env",
      ".env.*",
      "",
      "tmp/",
      "temp/",
      "",
      ".build/",
      "",
      "*.p12",
      "*.pem",
      "*.key",
      "*.p8",
      "",
      "secrets.json",
      "",
      ".build/",
      "*.xcuserstate",
      "",
    }),
    i(1),
    t({}),
  }),
})
