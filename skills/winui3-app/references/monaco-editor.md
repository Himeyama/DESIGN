# WinUI 3 に Monaco Editor を組み込む

通常の WinUI 3 画面では WebView2 に同梱した HTML を表示する。既存の Blazor Hybrid 画面では Razor の初回描画後に `IJSRuntime` で初期化する。以下は通常の WinUI 3 向けの単一文書の例。

## Web アセットをビルドする

既存のバンドラーがあれば利用する。以下は Monaco Editor 0.55.1 と esbuild 0.28.2 で JSON 編集を組み込む例。WinUI プロジェクト内にソース用の `EditorSource` と配布用の `Web` を分け、`EditorSource` に後述の `editor.js`、`Web` に `index.html` を置く。npm はアセットのビルド時に使う。

```powershell
# EditorSource ディレクトリで実行
npm.cmd init -y
npm.cmd install --save-exact monaco-editor@0.55.1
npm.cmd install --save-dev --save-exact esbuild@0.28.2
$monaco = 'node_modules/monaco-editor/esm/vs'
npx.cmd --no-install esbuild editor.js "$monaco/editor/editor.worker.js" "$monaco/language/json/json.worker.js" --bundle --format=esm --outdir=../Web --outbase=. '--entry-names=[name]' '--loader:.ttf=file'
```

`Web` には HTML に加え、生成した `editor.js`、`editor.css`、ワーカーと CSS が参照するフォントが入る。再現可能なビルドには `package-lock.json` を保存して `npm ci` を使う。アプリの配布物には Monaco のライセンス表示を含める。ビルド済みの `Web` を配布するため、実行時の npm や CDN 接続は不要。

```xml
<ItemGroup>
  <Content Include="Web\**\*"
           CopyToOutputDirectory="PreserveNewest"
           CopyToPublishDirectory="PreserveNewest" />
</ItemGroup>
```

既に `Content` に含まれるファイルには `Update` で属性を設定する。MSIX ではパッケージ内にも `Web` が含まれることを確認する。

`Web/index.html`

```html
<!doctype html>
<html lang="ja">
<head>
    <meta charset="utf-8">
    <title>Monaco Editor</title>
    <link rel="stylesheet" href="./editor.css">
    <style>
        html, body, #editor { width: 100%; height: 100%; margin: 0; overflow: hidden; }
    </style>
</head>
<body>
    <div id="editor"></div>
    <script type="module" src="./editor.js"></script>
</body>
</html>
```

`EditorSource/editor.js`

```javascript
import * as monaco from 'monaco-editor';

globalThis.MonacoEnvironment = {
    getWorker(_moduleId, label) {
        const file = label === 'json' ? './json.worker.js' : './editor.worker.js';
        return new Worker(new URL(file, import.meta.url), { type: 'module', name: label });
    }
};

const bridge = window.chrome.webview;
const model = monaco.editor.createModel('', 'json');
const editor = monaco.editor.create(document.getElementById('editor'), {
    model,
    automaticLayout: true
});
let applyingHostText = false;

function onHostMessage({ data }) {
    if (data?.type !== 'setText' || typeof data.text !== 'string') return;

    applyingHostText = true;
    try {
        if (model.getValue() !== data.text) model.setValue(data.text);
        editor.updateOptions({ readOnly: data.readOnly === true });
    } finally {
        applyingHostText = false;
    }
}

bridge.addEventListener('message', onHostMessage);
const contentChanged = model.onDidChangeContent(() => {
    if (!applyingHostText) {
        bridge.postMessage({ type: 'textChanged', text: model.getValue() });
    }
});
window.addEventListener('pagehide', () => {
    bridge.removeEventListener('message', onHostMessage);
    contentChanged.dispose();
    editor.dispose();
    model.dispose();
}, { once: true });

bridge.postMessage({ type: 'ready' });
```

対応言語を増やすときは、その言語のワーカーをビルド入力と `getWorker` の両方に追加する。例えば JavaScript と TypeScript は `ts.worker.js` を共有する。言語の色分けと構文診断・補完は別々に確認する。既存の AMD 構成を扱う場合はバージョンを確認する。新規の組み込みには ESM を使う。[Monaco の ESM 組み込み例](https://github.com/microsoft/monaco-editor/blob/main/docs/integrate-esm.md) · [AMD の非推奨化](https://github.com/microsoft/monaco-editor/blob/main/CHANGELOG.md#0530)

## WinUI の画面に接続する

`Grid` の残り高さを使う行に `<WebView2 x:Name="EditorView" Loaded="OnEditorLoaded" />` を置く。コード例を `MainWindow` に追加し、コンストラクターの `InitializeComponent()` の後に `Closed += OnEditorClosed;` を追加する。XAML の `Source` は指定せず、次の順に初期化する。[WebView2 の依存関係と初期化](webview2.md)

1. UI スレッドで `EnsureCoreWebView2Async()` を待つ。画面を閉じた後に待機が完了する場合を考慮する。
2. 同梱した `Web` だけを仮想 HTTPS ホストに割り当て、`NavigationStarting` と `WebMessageReceived` を購読してから `Navigate` する。ページ、モジュール、ワーカーを同じオリジンに置く。`file:` URL では ESM の読み込みがブロックされ、HTML だけが開いて `ready` が届かないことがある。[WebView2 の仮想ホスト割り当て](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/winrt/microsoft_web_webview2_core/corewebview2#setvirtualhostnametofoldermapping)
3. ページから `ready` が届いてから C# が保持する最新のテキストと設定を送る。`ready` は `NavigationCompleted` より先に届くこともあるため、ナビゲーション完了イベントの順序には依存しない。リロード時は初期化をやり直し、同じ文書を表示する間は C# 側の値を保持する。

仮想ホストへの割り当てとイベント登録の例。シングルウィンドウでは同じ初期化を繰り返さないよう、`Loaded` の購読を初回に解除する。

```csharp
// using System;
// using System.IO;
// using System.Text.Json;
// using Microsoft.UI.Xaml;
// using Microsoft.Web.WebView2.Core;
const string EditorUrl = "https://editor.example/index.html";
CoreWebView2? _core;
bool _ready;
bool _closed;
bool _readOnly = false;
string _text = "{}";

async void OnEditorLoaded(object sender, RoutedEventArgs args)
{
    EditorView.Loaded -= OnEditorLoaded;
    try
    {
        await EditorView.EnsureCoreWebView2Async();
        if (_closed) return;

        _core = EditorView.CoreWebView2
            ?? throw new InvalidOperationException("CoreWebView2 を取得できませんでした。");
        _core.SetVirtualHostNameToFolderMapping(
            "editor.example",
            Path.Combine(AppContext.BaseDirectory, "Web"),
            CoreWebView2HostResourceAccessKind.Deny);
        _core.NavigationStarting += OnNavigationStarting;
        _core.WebMessageReceived += OnEditorMessage;
        _core.Navigate(EditorUrl);
    }
    catch (Exception ex)
    {
        if (!_closed) SetStatus($"エディタの初期化に失敗しました。{ex.Message}");
    }
}

void OnNavigationStarting(CoreWebView2 sender, CoreWebView2NavigationStartingEventArgs args)
{
    if (args.Uri == EditorUrl)
    {
        _ready = false;
    }
    else
    {
        args.Cancel = true;
    }
}

void OnEditorMessage(CoreWebView2 sender, CoreWebView2WebMessageReceivedEventArgs args)
{
    if (args.Source != EditorUrl) return;

    using JsonDocument document = JsonDocument.Parse(args.WebMessageAsJson);
    JsonElement root = document.RootElement;
    if (root.ValueKind != JsonValueKind.Object ||
        !root.TryGetProperty("type", out JsonElement type) ||
        type.ValueKind != JsonValueKind.String) return;

    switch (type.GetString())
    {
        case "ready" when !_ready:
            _ready = true;
            SendEditorText();
            break;
        case "textChanged" when _ready &&
            root.TryGetProperty("text", out JsonElement text) &&
            text.ValueKind == JsonValueKind.String:
            _text = text.GetString() ?? string.Empty;
            break;
    }
}

void SendEditorText()
{
    if (_ready && _core is not null)
    {
        _core.PostWebMessageAsJson(JsonSerializer.Serialize(new
        {
            type = "setText",
            text = _text,
            readOnly = _readOnly
        }));
    }
}

void OnEditorClosed(object sender, WindowEventArgs args)
{
    _closed = true;
    _ready = false;
    if (_core is not null)
    {
        _core.NavigationStarting -= OnNavigationStarting;
        _core.WebMessageReceived -= OnEditorMessage;
        _core = null;
    }

    EditorView.Close();
}
```

外部からテキストや読み取り専用設定を更新するときは、先に保持値を更新してから `SendEditorText()` を呼ぶ。画面を再生成する構成では WebView2 も再生成する。

JavaScript はオブジェクトをそのまま `postMessage` する。先に `JSON.stringify` すると C# の `WebMessageAsJson` で得られるルートは文字列になる。`PostWebMessageAsJson` へは C# 側で一度シリアライズした文字列を渡し、JS 側は `event.data` をオブジェクトとして読む。[WebView2 の JavaScript メッセージ API](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/javascript/webview)

行番号と折り返しは `lineNumbers` と `wordWrap` で設定する。複数の文書では文書ごとにモデルを所有し、通知にも文書 ID を含める。C# から差分を適用して元に戻す履歴を保つ場合は `executeEdits()` と必要に応じて `pushUndoStop()` を使う。

## 配布ビルドで確認する

- アプリ自体が XAML の読み込みで終了する場合は、発行先にアプリの `.xbf` と `.pri` が揃っているかを確認する。Windows App SDK 1.7.251107005 の非パッケージ構成では、ビルド出力に存在するファイルが発行先から欠けるケースを確認した。
- 発行先から起動し、HTML のナビゲーション結果と `ready` の受信を確認する。ページが空白または `ready` が届かない場合は、DevTools の Console と Network でモジュール、CSS、フォント、ワーカーを確認する。
- 初期テキスト、入力・貼り付けの反映、C# からの差し替えで変更通知が往復しないこと、読み取り専用、リサイズ、リロードと画面の開き直しを確認する。
- この例では `{"value": }` を読み込ませて JSON の構文エラーが出ることを確認する。ワーカーの読み込みエラーがある場合は、色分けやマーカーの表示だけで動作を判断せず、DevTools でワーカーのロードとフォールバックの有無を確認する。

検証環境は x64 の非パッケージ WinUI 3 アプリ、.NET 8、Windows App SDK 1.7.251107005、WebView2 Runtime 158.0.4370.33。同じアセットを `file:` URL で開くとナビゲーションは成功しても `ready` が届かなかった。仮想 HTTPS では `ready` を受信し、JSON の構文診断と C# とのテキスト同期まで動作した。
