# WinUI 3 で WebView2 を使う

## 依存関係とビルドエラー

- WinUI 3 の `WebView2` コントロールでは、通常は Windows App SDK が取り込む WebView2 SDK を使う。追加の API が必要な場合は、まず対応する Windows App SDK の版と互換性を確認する。
- `CoreWebView2` 周辺で `CS0012` や `CS0246` が出たら、`dotnet list <プロジェクト> package --include-transitive` と `obj/project.assets.json` で実際に解決された依存関係を確認する。`.csproj` や `Directory.Packages.props` の直接参照・バージョン指定、`WebView2EnableCsWinRTProjection` の上書きも調べ、WinUI コントロールが期待する WinRT プロジェクションとコンパイル時の参照を揃える。不要な上書きを整理してから、対象構成をクリーン、復元、再ビルドする。
- WebView2 SDK はビルド時の依存関係で、実行先には WebView2 Runtime が必要。配布方式に応じて Evergreen Runtime の利用・導入か Fixed Version の同梱を確認する。Windows App SDK を自己完結で配布する場合も同様に確認する。

[WinUI 3 の WebView2](https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/webview2) · [WebView2 Runtime の配布](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution)

## 初期化とメッセージ

- 初回の読み込み前に設定やイベント登録が必要なら、UI スレッドで `await view.EnsureCoreWebView2Async()` を呼び、成功後に `CoreWebView2` を取得する。初回ナビゲーションより先に必要なイベントを登録し、その後に `Navigate` または `Source` で読み込む。この順序が必要なときは XAML で `Source` を先に指定しない。画面の再表示などでイベントを重複登録しないようにする。
- JavaScript オブジェクトは `window.chrome.webview.postMessage({ ... })` で送り、C# の `WebMessageReceived` で `WebMessageAsJson` を読む。文字列を送る設計では `TryGetWebMessageAsString()` を使う。受信時に `args.Source` とメッセージの型・必要な項目を検証してから処理する。

[WinUI 3 で WebView2 を使い始める](https://learn.microsoft.com/en-us/microsoft-edge/webview2/get-started/winui) · [WebView2 のセキュリティ](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/security)

## ローカルの Web アセット

- HTML と参照先の JS・CSS などはディレクトリ構造を保って配布する。ファイルとして配置する場合は、プロジェクトの項目定義に合わせて `Content` に `CopyToOutputDirectory` と `CopyToPublishDirectory` を設定し、実行時は `AppContext.BaseDirectory` を基準にパスを組み立てる。既に含まれている項目には `Update` を使う。MSIX では実際のパッケージに必要なファイルが入っていることも確認する。
- 安定したオリジンや HTTPS のセキュアコンテキストが必要なら、`SetVirtualHostNameToFolderMapping` で同梱アセットのフォルダーを仮想 HTTPS ホストに割り当てる。
- 画面が空白の場合は、初期化エラー、`NavigationCompleted` の `IsSuccess` / `WebErrorStatus`、DevTools のコンソールやネットワークの順に確認する。実際に配布する成果物から起動し、入口の HTML と依存ファイルの読み込み、利用する場合は C# と JavaScript の通信まで試す。

[WebView2 でローカルコンテンツを読み込む](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/working-with-local-content)
