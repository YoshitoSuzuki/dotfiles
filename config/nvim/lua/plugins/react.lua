return {
  -- TypeScript/React のサポートを追加
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- Tailwind CSS を使用している場合
  { import = "lazyvim.plugins.extras.lang.tailwind" },

  -- Prettier / ESLint
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.linting.eslint" },

  {
    "nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {}, -- または ts_ls
        tailwindcss = {},
        -- JSX/TSX で Emmet 展開（div.card>h1{Hi} → <Tab>）
        emmet_language_server = {
          filetypes = {
            "html",
            "css",
            "scss",
            "javascriptreact",
            "typescriptreact",
          },
        },
      },
    },
  },

  -- TypeScript のエラーメッセージを平易な英語に翻訳して表示
  {
    "dmmulroy/ts-error-translator.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {},
  },

  -- package.json に依存パッケージの最新バージョンを表示
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = { "BufReadPre package.json" },
    opts = { package_manager = "npm" },
    keys = {
      { "<leader>Ns", function() require("package-info").show() end, desc = "Show package versions" },
      { "<leader>Nu", function() require("package-info").update() end, desc = "Update package" },
      { "<leader>Nc", function() require("package-info").change_version() end, desc = "Change package version" },
    },
  },

  -- which-key に npm グループを追加（<leader>n は LazyVim が使用済み）
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>N", group = "npm" },
      },
    },
  },

  -- "..." の中で ${ を打つとバッククォートに自動変換
  {
    "axelvc/template-string.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = { remove_template_string = true },
  },
}
