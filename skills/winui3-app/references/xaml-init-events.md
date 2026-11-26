# XAML 初期化中のイベント発火

## 起動時クラッシュの調べ方

- XAML の `ComboBox` に `SelectedIndex="0"` と `SelectionChanged="OnLanguageChanged"` があると、`InitializeComponent()` 中にハンドラーが呼ばれることがある。`OnLanguageChanged` → `ShowStatus()` → `StatusText.Text` のように、XAML で後から初期化される `x:Name` フィールドを参照すると `NullReferenceException` が発生する。
- `combase.dll` の障害や `0xC0000005`（アクセス違反）が Application ログに記録されていても、起動直後なら直前のマネージ例外を調べる。`0x80004003` は .NET の `COR_E_NULLREFERENCE` と COM の `E_POINTER` に共通する HRESULT。障害モジュール、オフセット、例外コードを手がかりに、実際に例外を投げた箇所をスタックで確認する。
- Visual Studio の「例外設定」で `System.NullReferenceException` をスロー時に中断させて起動し、`InitializeComponent()`、イベントハンドラー、未初期化のフィールドを確認する。イベントログを参照するときは、テスト実行時刻と実行ファイル名で対象を絞る。

[NullReferenceException](https://learn.microsoft.com/dotnet/api/system.nullreferenceexception) · [COM のエラーコード](https://learn.microsoft.com/windows/win32/com/com-error-codes-1) · [アクセス違反の調査](https://learn.microsoft.com/en-us/shows/inside/c0000005)

## 初期化とイベント購読の順序

- XAML の `ComboBox` から `SelectedIndex` と `SelectionChanged` の属性を外す。`InitializeComponent()` の後で項目と参照先の準備を済ませ、初期値を設定してからイベントを購読する。初期表示の更新は明示的に一度呼ぶ。バインディングで項目を後から読み込む場合は、項目が揃った時点で初期選択を設定する。
- 初期化中にも呼ばれうるハンドラーでは、参照先が `null` なら処理を保留し、準備完了後に現在の選択状態から表示を更新する。下の例では、選択の解除時にも表示を更新する。

```csharp
public MainWindow()
{
    InitializeComponent();

    LanguageBox.SelectedIndex = LanguageBox.Items.Count > 0 ? 0 : -1;
    LanguageBox.SelectionChanged += OnLanguageChanged;
    UpdateLanguageStatus();
}

void OnLanguageChanged(object sender, SelectionChangedEventArgs args) => UpdateLanguageStatus();

void UpdateLanguageStatus()
{
    if (LanguageBox is null || StatusText is null)
    {
        return;
    }

    StatusText.Text = LanguageBox.SelectedItem is ComboBoxItem { Content: string language }
        ? language
        : string.Empty;
}
```

`SelectionChangedEventArgs` と `ComboBoxItem` は `Microsoft.UI.Xaml.Controls` の型。既存のウィンドウ初期化処理は維持し、表示の更新内容はアプリに合わせる。

## 未処理例外の記録

WinUI 3 の `Microsoft.UI.Xaml.Application.UnhandledException` を `App` のコンストラクターで購読する。既存のログ基盤があれば利用する。次は既存の `App.xaml.cs` に統合できるファイルログの例。`OnLaunched` など既存の処理は維持し、`MyApp` をアプリの名前に置き換える。

```csharp
using System;
using System.Diagnostics;
using System.IO;
using Microsoft.UI.Xaml;

namespace MyApp;

public partial class App : Application
{
    public App()
    {
        UnhandledException += OnUnhandledException;
        InitializeComponent();
    }

    void OnUnhandledException(object sender, Microsoft.UI.Xaml.UnhandledExceptionEventArgs args)
    {
        string message = $"{DateTimeOffset.Now:O} {args.Message}{Environment.NewLine}{args.Exception}";
        try
        {
            string folder = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MyApp");
            Directory.CreateDirectory(folder);
            File.AppendAllText(Path.Combine(folder, "startup-errors.log"), message + Environment.NewLine);
        }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException)
        {
            Debug.WriteLine(message);
            Debug.WriteLine(error);
        }
    }
}
```

致命的な初期化失敗では `Handled` を既定値の `false` のままにする。このイベントで受け取る例外の型やスタックが元の例外と異なることがあり、イベント自体に届かない障害もある。ログが残らない場合は、デバッガーで元の例外を捕捉する。ログ経路を検証するときは開発用ビルドで既知の UI 例外を使い、検証用の変更を外してから通常の起動を再確認する。

[Application.UnhandledException](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.application.unhandledexception?view=windows-app-sdk-1.5)

## 起動テスト

非パッケージアプリには [test-launch.ps1](../scripts/test-launch.ps1) を使える。`-Project` と `-ExePath` は指定した構成・ランタイムの成果物を指すように揃え、`-ExpectedTitle` に実際の `Window.Title` を指定する。デスクトップセッションで、操作中のアプリとは別にテスト用のインスタンスを起動できる状態で実行する。

```powershell
& '<スキルフォルダ>/scripts/test-launch.ps1' `
    -Project './MyApp.csproj' `
    -ExePath './bin/Debug/net8.0-windows10.0.26100.0/win-x64/MyApp.exe' `
    -ExpectedTitle 'アプリ' -RuntimeIdentifier win-x64
```

ビルド後に実行ファイルを起動し、既定で 10 秒間生存したこと、メインウィンドウに期待したタイトルがあり応答していることを確認する。テストが起動したプロセスは終了する。MSIX ではインストール済みパッケージを通常の方法で起動し、同じ項目を確認する。初期選択の表示と手動での選択変更は別途アプリ上で試す。
