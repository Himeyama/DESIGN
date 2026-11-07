# 公式 WinUI Blank App の生成と調整

## テンプレートを固定する

以下は Microsoft の `Microsoft.WindowsAppSDK.WinUI.CSharp.Templates` **0.0.4-alpha** の `winui` を対象に検証した手順。テンプレート自体はプレリリース版で、Windows App SDK のバージョンとは別。`0.0.7-alpha` など別版を使う場合は生成内容を確認し、この版との差分を適用してビルド・起動を検証する。新しい版への更新提案を自動で適用しない。既存プロジェクトのテンプレートを入れ替えない。

次の例では一時的な CLI ホームに [0.0.4-alpha](https://www.nuget.org/packages/Microsoft.WindowsAppSDK.WinUI.CSharp.Templates/0.0.4-alpha) をインストールするため、既存のテンプレート登録を変更しない。`MyApp`、出力先、対象 .NET は依頼に合わせて変更する。テンプレートの取得や依存パッケージの復元には NuGet 接続が必要。

```powershell
$previousCliHome = $env:DOTNET_CLI_HOME
$taskCliHome = Join-Path $env:TEMP ("WinUiTemplate-" + [Guid]::NewGuid().ToString('N'))
try {
    $env:DOTNET_CLI_HOME = $taskCliHome
    dotnet new install 'Microsoft.WindowsAppSDK.WinUI.CSharp.Templates@0.0.4-alpha'
    if ($LASTEXITCODE -ne 0) { throw 'Template installation failed.' }
    dotnet new winui -n MyApp -o .\MyApp --dotnet-version net8.0 --no-update-check
    if ($LASTEXITCODE -ne 0) { throw 'Project creation failed.' }
}
finally {
    if ($null -eq $previousCliHome) {
        Remove-Item Env:DOTNET_CLI_HOME -ErrorAction SilentlyContinue
    }
    else {
        $env:DOTNET_CLI_HOME = $previousCliHome
    }
}
```

`--no-update-check` はテンプレート自体の更新確認を止める。0.0.4-alpha には生成後に SDK の NuGet パッケージ更新・復元を試みる処理があるため、生成後の `.csproj` と処理結果も確認する。作成コマンドが成功しても作成後の操作だけ失敗する場合がある。必要な SDK のバージョンを明示し、取得や復元に失敗した場合は修正してからビルドする。テンプレート版の固定だけで依存パッケージまで固定されたとは扱わない。

WinUI のビルドでは `obj` 以下に長いパスが生成される。存在するはずの DLL に `MSB3030` が出る場合はパス長も確認し、必要なら短い場所の検証用コピーで再試行する。既存プロジェクトを無断で移動しない。

## 画面構成を選ぶ

0.0.4-alpha のテンプレートは、`MainWindow.xaml` の `RootFrame` に `MainPage.xaml` を表示し、`MainWindow.xaml.cs` で `RootFrame.Navigate(typeof(MainPage))` を呼ぶ。`MainPage` を放置したままウィンドウだけ置き換えない。以下のどちらかを選ぶ。

### 単一画面の新規アプリ

1. 生成直後の `MainPage.xaml` と `MainPage.xaml.cs` が未使用のひな形であり、他の画面やプロジェクトから参照されていないことを確認する。
2. スキル本文の `MainWindow.xaml` と `MainWindow.xaml.cs` を使い、`MyApp` を実際の名前空間に置き換える。`AppContent` に機能を実装する。テンプレートにあった `RootFrame.Navigate(typeof(MainPage))` と不要な `RootFrame` 参照は残さない。
3. 未使用になった生成直後の `MainPage.xaml` と `MainPage.xaml.cs` を削除する。`.csproj` にそのページの明示的な項目がある場合は、該当項目も整理する。既存アプリのユーザーが作ったページや使用中の画面は削除しない。
4. ビルド前に対象構成の古いビルド出力を `dotnet clean` で整理し、発行時は別の空フォルダーを使う。`MainPage` を削除した構成では、発行物に古い `MainPage.xbf` が残っていないことを確認する。

### `MainPage` や画面遷移を使うアプリ

テンプレートの `RootFrame`、`MainPage.xaml` / `.cs`、`RootFrame.Navigate(typeof(MainPage))` を維持し、依頼された UI と処理を `MainPage` に実装する。スキル本文のウィンドウ例では `AppContent` の代わりに次を使い、`MainWindow.xaml.cs` のコンストラクターには既存の `Navigate` を残す。

```xml
<Frame x:Name="RootFrame" Grid.Row="1" Margin="24,16,24,24" />
```

ページからステータスを更新する場合は、`MainWindow.xaml.cs` の `SetStatus` を `public void SetStatus(string message) => StatusText.Text = message;` とし、コンストラクターのナビゲーションを `RootFrame.Navigate(typeof(MainPage), this);` にする。`MainPage.xaml.cs` に `using Microsoft.UI.Xaml.Navigation;` を追加し、`MainPage` クラスに次を追加する。操作に応じて `SetPageStatus("メッセージ")` を呼ぶ。

```csharp
MainWindow? _window;

protected override void OnNavigatedTo(NavigationEventArgs e)
{
    base.OnNavigatedTo(e);
    _window = e.Parameter is MainWindow window ? window : null;
}

void SetPageStatus(string message) => _window?.SetStatus(message);
```

既存アプリでは現在の構成と機能を維持し、必要なタイトルバー・サイズ・ステータスバーの変更だけを統合する。

## テンプレートとの差分

- `MainWindow.xaml` の `<TitleBar ... Title="...">` から `Title` 属性と `<TitleBar.IconSource>...</TitleBar.IconSource>` を取り除き、`<TitleBar x:Name="AppTitleBar" />` とする。`Window` の `Title` はタスクバーや Alt+Tab の名前として残せる。
- `MainWindow.xaml.cs` の `AppWindow.SetIcon("Assets/AppIcon.ico")` は、スキル本文の `SetAppIcon()` に置き換える。アプリの配置先を基準に ICO の絶対パスを作り、存在確認後に設定する。作成不要の指定ではテンプレートの ICO を使える。
- テンプレートの `.csproj` にはすでに `<Content Include="Assets\AppIcon.ico" />` がある。非パッケージアプリでこれを使う場合は、同じ `Include` を追加せず、既存の `Content` より後に次を追加する。`ApplicationIcon` は既存設定と重複させない。

  ```xml
  <PropertyGroup>
    <ApplicationIcon>Assets\AppIcon.ico</ApplicationIcon>
  </PropertyGroup>
  <ItemGroup>
    <Content Update="Assets\AppIcon.ico"
             CopyToOutputDirectory="PreserveNewest"
             CopyToPublishDirectory="PreserveNewest" />
  </ItemGroup>
  ```

- `AGENTS.md` と `.github/instructions/` は作業指示を含むため、適用範囲を読んでから作業する。`Package.appxmanifest` と `Properties/PublishProfiles/` はパッケージ化や発行に使われる。不要と決めつけて削除せず、既存の指示や配布方式を維持する。ユーザーの指示が優先される。配布方式を変更した場合は、プロジェクト内の説明が実態と矛盾しないよう必要な箇所を調整する。
- 新規テンプレートには通常 `WindowsPackageType` がない。HSIS 向けの非パッケージ発行を依頼された場合は、[HSIS の手順](hsis-installer.md) に従い `None` を追加する。既存の MSIX アプリは依頼なく非パッケージに変更しない。
