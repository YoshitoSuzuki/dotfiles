# install.sh brew で入るもの（brew bundle --file=Brewfile でも同じ）

# Homebrew を使わずに入れたアプリが既にあれば cask を飛ばす（同じ場所にあると cask の導入が失敗するため）
def app?(name)
  ["/Applications", File.expand_path("~/Applications")].any? { |dir| File.exist?("#{dir}/#{name}.app") }
end

# ターミナル
cask "ghostty" unless app?("Ghostty")     # 普段使いのターミナル。起動すると herdr に入る
brew "herdr"                              # AI エージェント向けのターミナルマルチプレクサ
cask "wezterm" unless app?("WezTerm")     # 予備のターミナル（herdr が固まったときの復旧用）
cask "font-jetbrains-mono-nerd-font"      # Ghostty / WezTerm / Neovim のアイコン表示に必要

# Neovim（LazyVim）
brew "neovim"
brew "node"                               # LSP・prettier・eslint を Mason が入れるのに使う
brew "ripgrep"                            # 全文検索（<leader>/）
brew "fd"                                 # ファイル検索（<leader><space>）
brew "lazygit"                            # git の画面（<leader>gg）

# エディタ
cask "zed" unless app?("Zed")             # GUI のエディタ。Markdown を書くときに使う

# シェル
brew "rmtrash"                            # rm をゴミ箱送りにする
