local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- reload config automatically
config.automatically_reload_config = true

-- 1. フォント
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 14.0

-- 2. カラーテーマ
config.color_scheme = "Tokyo Night"

-- 3. 画面の透過とすりガラス効果
config.window_background_opacity = 0.75
config.macos_window_background_blur = 20

-- 4. タイトルバーを消す
config.window_decorations = "RESIZE"

-- タブ
-- タブの管理は herdr に任せるので、WezTerm 側のタブは常に1枚
-- （WezTerm のタブを増やしても同じ herdr セッションが二重に映るだけになる）
-- ただしタブバーは時計と LEADER 表示の置き場所として残し、タブの見た目だけ消す
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.window_background_gradient = {
	colors = { "#000000" },
}

-- タブ名は表示しない（タブバーは実質ステータスバーとして使う）
wezterm.on("format-tab-title", function()
	return ""
end)

-- 5. 少しだけ余白を作る
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}

wezterm.on("update-right-status", function(window, _)
	local cells = {}

	-- herdr の prefix モードに入っているか
	if window:active_key_table() == "herdr_prefix" then
		table.insert(cells, "PREFIX ")
	end

	-- Leaderキーが押されているか
	if window:leader_is_active() then
		table.insert(cells, "LEADER ")
	end

	-- 日付も出す
	local date = wezterm.strftime("%Y-%m-%d %H:%M:%S")
	table.insert(cells, date)

	-- 表示スタイル
	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#7aa2f7" } },
		{ Text = table.concat(cells, " | ") .. " " },
	}))
end)

-- 起動時に herdr にアタッチする（サーバーは herdr 自身が自動起動する）
config.default_prog = { "/opt/homebrew/bin/herdr" }

-- Leader Key
-- Ctrl+Space は herdr の prefix に譲ったので、こちらは Ctrl+a
-- 以下のキーバインドは herdr が使えないときの退避用
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

-- Cmd キーはターミナルの中のプログラムには届かないので、
-- WezTerm 側で受けて herdr のキー操作（prefix = Ctrl+Space）に翻訳する
local function to_herdr(key)
	return wezterm.action.Multiple({
		wezterm.action.SendKey({ key = "Space", mods = "CTRL" }),
		wezterm.action.SendKey(key),
	})
end

-- herdr の prefix モードを表示するための空のキーテーブル
-- WezTerm からは herdr の状態を読めないので、prefix キーを押したことを WezTerm 側でも
-- 記録して印にする。中身が空なので次のキーはそのまま herdr に流れ、one_shot で解除される
config.key_tables = {
	herdr_prefix = {},
}

config.keys = {
	-- herdr の prefix。herdr に送りつつ、ステータス表示用の印をつける
	{
		key = "Space",
		mods = "CTRL",
		action = wezterm.action.Multiple({
			wezterm.action.SendKey({ key = "Space", mods = "CTRL" }),
			wezterm.action.ActivateKeyTable({ name = "herdr_prefix", one_shot = true }),
		}),
	},

	-- 0. Cmd系のタブ操作を herdr に転送する
	{ key = "t", mods = "SUPER", action = to_herdr({ key = "c" }) },
	{ key = "w", mods = "SUPER", action = to_herdr({ key = "X", mods = "SHIFT" }) },
	{ key = "[", mods = "SUPER|SHIFT", action = to_herdr({ key = "p" }) },
	{ key = "]", mods = "SUPER|SHIFT", action = to_herdr({ key = "n" }) },
	-- 新しいウィンドウも herdr の二重表示になるだけなので無効化
	{ key = "n", mods = "SUPER", action = wezterm.action.DisableDefaultAssignment },

	-- 1. 画面分割（ペイン）
	-- Leader + \ で縦に割る（左右）
	{ key = "\\", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- Leader + - で横に割る（上下）
	{ key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- 2. ペインの移動（HJKL）
	{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },

	-- 3. ペインを閉じる
	{ key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },

	-- サイズ調整 (Shiftを足す)
	{ key = "H", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
	{ key = "L", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },
	{ key = "K", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
	{ key = "J", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },

	-- 管理系
	{ key = "w", mods = "LEADER", action = wezterm.action.ShowLauncherArgs({ flags = "WORKSPACES" }) },
	{ key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },

	-- herdr を経由しない素のシェルを別ウィンドウで開く（herdr の停止・更新・復旧用）
	-- タブ名を表示していないのでタブで開くと見分けがつかない。ウィンドウで開く
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action.SpawnCommandInNewWindow({ args = { "/bin/zsh", "-l" } }),
	},
}

-- Cmd+1〜9 で herdr のタブを切り替える
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "SUPER",
		action = to_herdr({ key = tostring(i) }),
	})
end

return config
