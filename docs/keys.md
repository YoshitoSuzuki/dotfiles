# 操作キー一覧

よく使うものだけを載せている。全部を見たいときの調べ方は各節の最後に書いた。

## macOS 全体

| キー | 動作 |
| --- | --- |
| `Option+Space` | Raycast（アプリの起動・検索） |
| `Cmd+Space` | Spotlight |

## Ghostty + herdr（普段のターミナル）

herdr の prefix は **`Ctrl+Space`**。表の「`Ctrl+Space` → `x`」は、`Ctrl+Space` を押して離してから `x` を押す。

### タブ（Cmd キーは Ghostty が herdr に転送している）

| キー | 動作 |
| --- | --- |
| `Cmd+T` / `Cmd+W` | タブを開く / 閉じる |
| `Cmd+Shift+[` / `Cmd+Shift+]` | 前 / 次のタブ |
| `Cmd+1`〜`9` | 番号のタブへ |
| `Ctrl+Space` → `Shift+T` | タブの名前を変える |

### ペイン

| キー | 動作 |
| --- | --- |
| `Ctrl+Space` → `\` / `-` | 左右 / 上下に分割 |
| `Ctrl+Space` → `h` `j` `k` `l` | 左 / 下 / 上 / 右のペインへ |
| `Ctrl+Space` → `Tab` | 次のペインへ |
| `Ctrl+Space` → `z` | ペインを最大化 / 元に戻す |
| `Ctrl+Space` → `r` | サイズ変更モード（`h` `j` `k` `l` で広げる、`Esc` で抜ける） |
| `Ctrl+Space` → `x` | ペインを閉じる |
| `Ctrl+Space` → `e` | スクロールバックをエディタで開く（過去の出力を検索・コピーする） |

### ワークスペース・その他

| キー | 動作 |
| --- | --- |
| `Ctrl+Space` → `w` | ワークスペースを選ぶ（`j` / `k` で移動、`Enter` で決定） |
| `Ctrl+Space` → `Shift+N` | 新しいワークスペース |
| `Ctrl+Space` → `Shift+W` | ワークスペースの名前を変える |
| `Ctrl+Space` → `b` | サイドバーの表示 / 非表示 |
| `Ctrl+Space` → `o` | 通知の出たペイン（手が空いたエージェント）へ |
| `Ctrl+Space` → `?` | herdr のキー一覧 |
| `Ctrl+Space` → `q` | herdr から抜ける（中のシェルやエージェントは動き続ける） |
| `Cmd+Shift+,` | Ghostty の設定を読み直す |

全部のキー: `herdr --default-config`（このリポジトリで変えたものは `config/herdr/config.toml`）

### herdr が使えないとき（Ghostty 単体・WezTerm）

`Ctrl+a` のあとに次のキー。

| キー | 動作 |
| --- | --- |
| `\` / `-` | 左右 / 上下に分割 |
| `h` `j` `k` `l` | ペインの移動（`Shift` を足すとサイズ変更） |
| `x` | ペインを閉じる |
| `n` | herdr を通さないシェルを別ウィンドウで開く（herdr の停止・更新用） |

## Neovim（LazyVim）

Leader は **`Space`**。`Space` を押して少し待つと、続けて押せるキーの一覧が出る。

### ファイル・検索

| キー | 動作 |
| --- | --- |
| `Space Space` | ファイルを探して開く |
| `Space /` | プロジェクト全体を文字列で検索 |
| `Space ,` | 開いているバッファの一覧 |
| `Space f r` | 最近開いたファイル |
| `Space e` | ファイルツリー |
| `Space s k` | キー割り当てを検索 |
| `Space s h` | ヘルプを検索 |

### 画面・バッファ

| キー | 動作 |
| --- | --- |
| `Shift+H` / `Shift+L` | 前 / 次のバッファ |
| `Space b d` | バッファを閉じる |
| `Space \|` / `Space -` | 左右 / 上下に分割 |
| `Ctrl+h` `j` `k` `l` | 分割した画面の移動 |
| `Space w d` | 分割した画面を閉じる |
| `Space q q` | 全部閉じて終了 |

### コード

| キー | 動作 |
| --- | --- |
| `g d` / `g r` | 定義へ / 参照の一覧 |
| `K` | カーソル位置の説明を表示 |
| `Space c a` | コードアクション（修正の候補） |
| `Space c r` | 名前を一括で変える |
| `Space c f` | 整形 |
| `] d` / `[ d` | 次 / 前のエラー・警告 |
| `Space x x` | エラー・警告の一覧 |
| `g c c` | 行をコメントにする / 戻す（ビジュアルモードでは `g c`） |
| `main` → `Tab` | 雛形を展開（C++ / Go / TeX / .gitignore） |

### Git・その他

| キー | 動作 |
| --- | --- |
| `Space g g` | lazygit を開く |
| `Space g b` | その行を最後に変えたコミット |
| `Space f t` | ターミナルを開く（`Ctrl+/` で隠す） |
| `Space c p` | Markdown をブラウザでプレビュー（入力に合わせて更新） |
| `Space N s` / `Space N u` | package.json のパッケージの版を表示 / 更新 |
| `Space l` | プラグインの管理画面（Lazy） |

全部のキー: `Space s k`、または https://www.lazyvim.org/keymaps

## Zed

vim モードを有効にしている。Neovim と同じ操作がそのまま使える。

| キー | 動作 |
| --- | --- |
| `Cmd+Shift+P` | コマンドパレット |
| `Cmd+P` | ファイルを探して開く |
| `Space m p` | Markdown のプレビューを右に開く（ノーマルモード、md のとき） |
| `Ctrl+Space` → `h` `j` `k` `l` | 左 / 下 / 上 / 右のペインへ（`Ctrl+w` → `h` なども使える） |
| `Ctrl+Space` → `w` | 次のペインへ |

ターミナルからは `zed .` で今のディレクトリを開く。全部のキー: コマンドパレットで `zed: open default keymap`

## シェル（zsh / bash 共通）

| コマンド | 動作 |
| --- | --- |
| `l` / `la` | `ls -l` / `ls -a` |
| `...` `....` | 2つ上 / 3つ上のディレクトリへ（`.` を足すとさらに上） |
| `mcd <名前>` | ディレクトリを作って入る |
| `op` / `od` | `open` / ダウンロードフォルダを開く |
| `gs` / `ga` / `gc "<msg>"` / `gp <branch>` | `git status` / `git add -A` / `git commit -m` / `git push -u origin` |
| `gch` / `gcb` / `gcm` | `git checkout` / `checkout -b` / `checkout main` |
| `gb` / `gbd` / `gbD` | ブランチの一覧 / 削除 / 強制削除 |
| `ai` | Claude Code |
| `vi` / `vim` | Neovim |

zsh だけ: `h`（直近100件の履歴）、`hg <語>`（履歴を検索）、`G` / `L`（`ls G foo` → `ls | grep foo`、`L` は行数）。
全部の定義は `shell/common.sh` と `.zshrc`。
