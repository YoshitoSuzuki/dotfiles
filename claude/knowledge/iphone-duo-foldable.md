# iPhone Duo（折りたたみ iPhone）にアプリを合わせる

- 更新日: 2026-09-12

2026-09-09 発表、2026-10-23 発売。**1台で画面の広さが2通りある**のが設計上の要点。

| | 大きさ | size class | 縦横比 |
|---|---|---|---|
| 外側（閉じた状態） | 466 × 678 pt | compact 幅 | 1.45 |
| 内側（開いた状態） | **669 × 951 pt** | **regular 幅・regular 高** | **1.42** |

実機の仕様は 内側 7.6インチ 1878×2670px / 430ppi、外側 5.4インチ 1398×2034px / 460ppi。
内側の 1.42 はほぼ √2（A判の比）。**16:9 の動画には向かない**（1/5 が letterbox になる）が、
**2ペインの画面には向く**。ポーズは7通り（閉じ / 開き / 各向き / 途中まで折った状態）。

## 守るべきこと

- **size class だけで分岐する。** 端末の種類（`userInterfaceIdiom`）と画面の向きは見ない。
  **内側画面はアプリが指定した対応向き（`UISupportedInterfaceOrientations`）を尊重しない**
- **`UIScreen.main` を使わない**（画面が2つあるので曖昧。非推奨）。
  `window?.windowScene?.screen`、倍率は `traitCollection.displayScale`
- **セーフエリアが左右で非対称**。各辺を独立に扱う。操作するものはセーフエリアの内側、
  背景だけ `ignoresSafeArea()` で外へ
- **入力途中の状態を View の `@State` に置かない。** たたむ / 開くで size class が
  入れ替わって View が作り直され、**入力中のデータが消える**。
  `@Observable` なモデル側に置く
- 下部の帯は `VStack` に積まず **`safeAreaInset(edge: .bottom)`** で差し込む
  （積んで `.background` を付けると下のセーフエリアに背景が届かない）
- `NavigationSplitView` / `TabView` は元から適応するのでそのまま使える
- 生体認証の文言は **Touch ID**（Face ID ではない）

## バージョンと道具（2026-09 時点）

- **iPhone Duo のシミュレータは Xcode 27.1 から**。`xcrun simctl list devicetypes` に
  出なければ入っていない。Xcode 27.1 の DeviceHub で開く / 閉じる / 回す / 折るを操作できる
- **`ArrangementView`（primary + secondary を size class と縦横比で配置）と
  `ReservedRegion` / `UIViewReservedRegion` は iOS 27.1 の API。** 27.0 SDK では使えない
- `ConcentricRectangle` / `UICornerConfiguration`（画面の角に沿わせる）は iOS 26 から
- 27.1 SDK で再ビルドすると edge-to-edge と縦のバーが有効になる

### シミュレータが無いうちの確認

内側画面（669×951pt）にいちばん近いのは **iPad mini の縦（744×1133pt）**。
`regular/regular` で幅も近いので、2ペインが成立するかはここで見られる。
外側画面は普通の iPhone シミュレータでよい。

## 設計の型

広さの判断を1か所に閉じ込めておくと、あとで `ArrangementView` に載せ替えやすい。

```swift
enum PaneWidth {
    case narrow, wide
    init(_ sizeClass: UserInterfaceSizeClass?) {
        self = sizeClass == .regular ? .wide : .narrow
    }
}
```

画面側は `wide` / `narrow` しか見ない。内側画面は正方形に近いので、
**wide では「一覧 + 作業用の列」の2ペイン**にすると空きが出ない
（列幅は 300pt 程度にすると 669pt でも一覧側に2列残る）。
