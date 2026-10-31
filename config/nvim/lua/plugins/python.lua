return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          init_options = {
            settings = {
              -- ruff 0.17 から既定で import の並び順（I001）なども指摘するようになったので、
              -- 以前の既定のルールに戻す。プロジェクトに ruff.toml / pyproject.toml があればそちらを使う
              configurationPreference = "filesystemFirst",
              lint = {
                select = { "E4", "E7", "E9", "F" },
              },
            },
          },
        },
      },
    },
  },
}
