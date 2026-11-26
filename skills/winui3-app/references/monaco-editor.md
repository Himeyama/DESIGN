# WinUI 3 に Monaco Editor を組み込む

## WebView2 でホストする

1. WinUI 3 の画面でコード編集が必要なら、`WebView2` にエディタ用の HTML を読み込ませる。WebView2 の初期化とアセット配置は [WebView2 の手引き](webview2.md) に従う。既存の Blazor Hybrid 画面では、その Razor コンポーネントの初回描画後に `IJSRuntime` 経由で初期化する。
2. オフライン対応が必要なら、Monaco 本体、CSS、使用する言語ワーカーをアプリに同梱する。バンドル後のファイル構成を保ち、仮想 HTTPS ホストなど WebView 内でワーカーの URL を解決できる方法で読み込む。
3. C# は初回ナビゲーション前に `WebMessageReceived` を購読する。JavaScript はモデルとエディタを作成して受信用の `message` リスナーを登録した後、`window.chrome.webview.postMessage({ type: 'ready' })` で準備完了を知らせる。C# は送信元とメッセージを検証し、準備完了を受けてから最新の初期テキストと設定を `PostWebMessageAsJson` で渡す。再読み込みがある場合は、ページ遷移時に準備状態をリセットする。

## 文書モデルを同期する

- `monaco.editor.createModel(text, languageId)` で文書モデルを作り、`monaco.editor.create(container, { model })` に渡す。別々の文書を表示するペインには別のモデルを使う。`readOnly`、`lineNumbers`、`wordWrap` は画面の要件に合わせる。
- `onDidChangeModelContent` で編集を検知し、`getValue()` で取得したテキストを C# 側の状態に反映する。複数の文書を扱う場合は、通知に文書 ID を含める。大きな文書で全量転送が負荷になる場合は、保存直前に最新のテキストを確定できるようにしたうえで、通知頻度の調整や差分転送を検討する。
- C# から文書全体を読み直す場合は `setValue()` を使える。C# から適用した変更の通知を抑え、同じ値の書き戻しを避けて往復更新を防ぐ。外部からの部分編集を元に戻せるようにする場合は、`executeEdits()` と必要に応じて `pushUndoStop()` を使う。

[Monaco Editor API](https://microsoft.github.io/monaco-editor/typedoc/interfaces/editor_editor_api.editor.IStandaloneCodeEditor.html) · [文書モデルの API](https://microsoft.github.io/monaco-editor/typedoc/interfaces/editor_editor_api.editor.ITextModel.html)

## 表示と破棄を確認する

- エディタのコンテナーに幅と高さを与え、`automaticLayout` または表示・リサイズ後の `layout()` でサイズを追従させる。非表示のペインを再表示した場合も確認する。
- 画面を閉じるときは、C# のイベント購読と JavaScript のメッセージリスナー、Monaco のイベント購読を解除し、エディタと画面が所有する文書モデルを破棄する。
- 配布ビルドを実際に起動し、初期表示、入力と貼り付け、C# からの文書更新、読み取り専用の切り替え、リサイズ、画面の開き直しを確認する。言語ワーカーを使う場合は、そのワーカーが提供する構文診断や補完も試す。
