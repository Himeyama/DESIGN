# WinUI 3 サンプルテンプレート

各フォルダが単独でビルドできる WinUI 3 プロジェクトです。

| フォルダ | 内容 |
| --- | --- |
| [BlankApp](BlankApp/) | 空のコンテンツ領域を持つ最小構成。画面を追加する入口は `MainWindow.xaml` の `AppContent`。 |
| [WebViewApp](WebViewApp/) | 起動時に [example.com](https://example.com/) を開く WebView2。再読み込みとナビゲーション結果の表示。 |
| [EditorApp](EditorApp/) | Monaco による JSON の色分けと構文診断。サンプル文書の復元、読み取り専用切り替え、ホスト側での文字数表示。 |

共通仕様は .NET 8、Windows App SDK 1.7、x64、バージョン 0.1.0 です。タイトル文字とアイコンを省いたタイトルバー、下端のステータスバー、DPI に合わせた初期サイズを備えています。

## 起動

Windows x64 と .NET 8 以降の SDK が必要です。非パッケージ構成で、Windows App SDK はビルド出力に同梱します。WebViewApp と EditorApp は Microsoft Edge WebView2 Runtime を使用します。WebViewApp がページを表示するにはインターネット接続が必要です。

このフォルダで以下のうち起動したいプロジェクトのコマンドを実行してください。

```powershell
dotnet run --project .\BlankApp\BlankApp.csproj -p:Platform=x64
dotnet run --project .\WebViewApp\WebViewApp.csproj -p:Platform=x64
dotnet run --project .\EditorApp\EditorApp.csproj -p:Platform=x64
```

## テンプレートとして使う

使いたいアプリのフォルダをコピーし、プロジェクトファイル名と `RootNamespace`、C# の名前空間、XAML の `x:Class` と `xmlns:local`、`app.manifest` の `assemblyIdentity` 名を揃えて変更します。ウィンドウ名は `MainWindow.xaml` の `Title` で設定します。`Assets/AppIcon.svg` がアプリアイコンの編集用データです。

EditorApp は `Web/` のビルド済みアセットを読み込みます。アプリのビルドと実行には Node.js が不要です。Monaco の設定や JavaScript を変更したときは、Node.js 18 以降でアセットを再生成してください。Monaco のライセンスと第三者通知は `Web/` に同梱しています。

```powershell
Set-Location .\EditorApp\EditorSource
npm ci
npm run build
```
