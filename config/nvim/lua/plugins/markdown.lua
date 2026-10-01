-- Markdown を「書きながら完成形が見える」状態にする設定。
-- LazyVim の lang.markdown extra が render-markdown の装飾をかなり切っているので、
-- ここで Obsidian のライブプレビュー相当まで戻している。

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      -- 挿入モード中も描画を保つ（カーソル行だけ生の記法に戻る）。
      preset = "obsidian",

      heading = {
        sign = false,
        icons = { "󰬺 ", "󰬻 ", "󰬼 ", "󰬽 ", "󰬾 ", "󰬿 " },
        position = "inline",
        width = "block",
        right_pad = 4,
      },

      bullet = {
        icons = { "●", "○", "◆", "◇" },
        right_pad = 1,
      },

      checkbox = {
        enabled = true,
        right_pad = 1,
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 ", scope_highlight = "@markup.strikethrough" },
        -- stylua: ignore
        custom = {
          todo      = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
          important = { raw = "[!]", rendered = "󰀦 ", highlight = "DiagnosticWarn" },
          cancelled = { raw = "[~]", rendered = "󰜺 ", highlight = "Comment", scope_highlight = "@markup.strikethrough" },
        },
      },

      -- 引用・コールアウトの縦線を折り返し行にも伸ばす（下の autocmd の
      -- showbreak / breakindent とセットで正しく出る）。
      quote = { icon = "▋", repeat_linebreak = true },

      dash = { icon = "─" },

      code = {
        sign = false,
        width = "block",
        left_pad = 2,
        right_pad = 2,
        border = "thick",
        inline_pad = 1,
      },

      pipe_table = {
        preset = "round",
        alignment_indicator = "─",
      },

      link = {
        wiki = { icon = "󱗖 " },
      },

      -- $x^2$ などを Unicode に変換して表示する。
      -- 変換に latex2text (pip install pylatexenc) が要る。無ければ何も起きない。
      latex = { enabled = true },
    },
  },

  -- ターミナル内に画像をインライン表示する（Ghostty の kitty graphics を利用）。
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      -- 画像の実寸を決めるのに、pty が返すピクセル寸法（TIOCGWINSZ の xpixel/ypixel）が要る。
      -- herdr のペインの中ではこれが 0 で返るため、画像は描かれないのに 30 行ぶんの
      -- 空白だけが挿入されて逆に読みづらくなる。寸法が取れるときだけ有効にする。
      -- （＝ herdr を通さず素の Ghostty で nvim を開いたときは画像が出る）
      local ok, terminal = pcall(require, "snacks.image.terminal")
      local has_pixel_size = ok and terminal.size().cell_width > 0

      opts.image = {
        enabled = has_pixel_size,
        doc = {
          inline = true,
          float = true,
          max_width = 60,
          max_height = 30,
        },
        -- 数式は render-markdown 側の Unicode 変換に任せる（即時・外部ビルド不要）。
        -- 本物の組版で見たいなら true にする（pdflatex + ImageMagick が要る）。
        math = { enabled = false },
      }
      return opts
    end,
  },
}
