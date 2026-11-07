# HSIS 0.11.2 でインストーラーを作成

## 対象と準備

- インストーラーの作成を依頼されたときに使う。HSIS は [Himeyama/hsis](https://github.com/Himeyama/hsis) の **0.11.2** を指定し、別のバージョンで代用しない。
- この例は Windows 11 x64 で、非パッケージの WinUI 3 アプリをユーザー単位にインストールする。既存の MSIX や別の配布方法を無断で置き換えない。対象 OS・CPU が異なる場合は互換性を先に確認する。
- ビルドにはアプリの対象 .NET SDK、.NET 9 SDK、HSIS CLI とその隣の `Template` フォルダー、7z/LZMA2 対応の Windows 標準 `tar.exe` が必要。標準の tar が対応しない場合は HSIS の説明に従い `HSIS_7ZIP_PATH` に 7-Zip を指定する。初回のパッケージ復元には NuGet 接続が必要な場合がある。
- HSIS 0.11.2 のインストーラーは上記リポジトリの Releases から入手できる。既に導入されている場合は実際の CLI とテンプレートのバージョンを確認する。以下は既定のインストール先にある `hsis.exe` を使う例。
- `MyApp` は例。アプリの実行ファイル名、表示名、他のアプリと衝突しない固定の識別子・登録キーに置き換える。更新時は既存の識別子と保存先を維持する。アプリが使用するユーザーデータの保存場所を確認してから削除定義を書く。

## 1. インストーラー定義

アプリのプロジェクトルートに `installer/MyApp.nsi` を UTF-8 で作る。次の例は `artifacts` に発行したアプリ全体を `app` サブフォルダーに配置し、スタートメニューと Windows のアプリ一覧に登録する。`APP_VERSION` は `0.1.0` のような 3 要素の数値、`SOURCE_DIR` は発行先とし、後の CLI コマンドで渡す。`VIProductVersion` は Windows の 4 要素の番号が必要なので、例では末尾に `.0` を付ける。

```nsi
Unicode true
!include "MUI2.nsh"

Name "MyApp"
OutFile "MyApp-${APP_VERSION}-win-x64-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\MyApp"
RequestExecutionLevel user
VIProductVersion "${APP_VERSION}.0"
VIAddVersionKey /LANG=1041 "ProductName" "MyApp"
VIAddVersionKey /LANG=1041 "FileDescription" "MyApp Setup"
VIAddVersionKey /LANG=1041 "FileVersion" "${APP_VERSION}"

!define MUI_FINISHPAGE_RUN "$INSTDIR\app\MyApp.exe"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "Japanese"

Section "MyApp"
  SetOutPath "$INSTDIR\app"
  File /r "${SOURCE_DIR}\*"
  CreateShortcut "$SMPROGRAMS\MyApp.lnk" "$INSTDIR\app\MyApp.exe"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp" "DisplayName" "MyApp"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp" "DisplayIcon" "$INSTDIR\app\MyApp.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp" "QuietUninstallString" '$\"$INSTDIR\Uninstall.exe$\" /S'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$SMPROGRAMS\MyApp.lnk"
  RMDir /r "$INSTDIR\app"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MyApp"
SectionEnd
```

`RMDir /r "$INSTDIR\app"` はそのフォルダー内を再帰的に削除する。そこには配布ファイルだけを置き、設定や文書などのユーザーデータを置かない。既存アプリのインストール先や登録キーを確認し、他のアプリや既存データと衝突する設定を使わない。ライセンス画面が必要な場合だけ、実際の利用規約ファイルを追加する。

## 2. 画面リソースの発行設定

非パッケージの WinUI 3 アプリでは、`dotnet publish` がアプリ固有の `.pri` と画面の `.xbf` を発行先にコピーせず、ビルドは成功してもアプリが起動しない場合がある。この節は単一ファイル化しない通常の発行に使う。既存アプリが単一ファイル化や Native AOT に依存している場合は、その配布方式に合う方法を別途確認する。

HSIS で非パッケージとして配布する新規プロジェクトでは、`.csproj` の `PropertyGroup` に `<WindowsPackageType>None</WindowsPackageType>` を追加する。公式テンプレート 0.0.4-alpha にはこの設定がない。既にある場合は重複させず、既存の MSIX アプリは依頼なく変更しない。`WindowsAppSDKSelfContained` は後の発行コマンドで指定する。

```xml
<PropertyGroup>
  <WindowsPackageType>None</WindowsPackageType>
</PropertyGroup>
```

次を `</Project>` の直前に追加する。同じ処理が既にある場合は重複して追加しない。ターゲットは `WindowsPackageType` が `None` のときだけ動くので、設定漏れに注意する。アプリ固有のリソースインデックスと、ビルド出力内の `.xbf` を、サブフォルダー構造を保って発行先にコピーする。ファイルが見つからない場合は発行を失敗させる。

```xml
<Target Name="CopyUnpackagedWinUIResourcesToPublish" AfterTargets="Publish"
        Condition="'$(WindowsPackageType)' == 'None' and '$(PublishSingleFile)' != 'true'">
  <Error Condition="'$(ProjectPriFullPath)' == '' or !Exists('$(ProjectPriFullPath)')"
         Text="The WinUI resource index was not found in the build output." />
  <ItemGroup>
    <_WinUIXbf Include="$(TargetDir)**\*.xbf"
               Exclude="$(PublishDir)**\*;$(TargetDir)publish\**\*" />
  </ItemGroup>
  <Error Condition="'@(_WinUIXbf)' == ''"
         Text="The compiled XAML files were not found in the build output." />
  <Copy SourceFiles="$(ProjectPriFullPath)"
        DestinationFiles="$(PublishDir)$(ProjectPriFileName)"
        SkipUnchangedFiles="true" />
  <Copy SourceFiles="@(_WinUIXbf)"
        DestinationFiles="@(_WinUIXbf->'$(PublishDir)%(RecursiveDir)%(Filename)%(Extension)')"
        SkipUnchangedFiles="true" />
</Target>
```

発行先はビルド出力とは別の空フォルダーにする。Windows App SDK などを更新した場合は、この対処がまだ必要か確認する。関連情報: [WindowsAppSDK の発行時の PRI 欠落](https://github.com/microsoft/WindowsAppSDK/issues/6720)。

公式テンプレート 0.0.4-alpha は Release 時に `PublishTrimmed=True` を設定する。トリミングは使われないと判断したコードやメタデータを削除するが、WinUI の XAML や WinRT の参照が実行時に必要になる場合があり、発行後の起動や画面表示に失敗することがある。この手順では再現性を優先し、次のコマンドで `-p:PublishTrimmed=false` を明示する。Visual Studio の発行プロファイルを使う場合は、そのプロファイルでも `PublishTrimmed` が `false` になるよう設定する。トリミングを有効にする場合は対応する SDK とアプリの構成を確認し、発行物を実際に検証する。[Microsoft の説明](https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/applifecycle/applifecycle-single-instance) も参照。

## 3. 発行と生成

次の PowerShell はプロジェクトルートで実行する。`MyApp.csproj`・`MyApp.nsi` を実際の名前に変更する。アプリが ICO を使わない場合は `$usesAppIcon` を `$false` にする。テンプレートの既定 ICO を使う場合は `$true` のままにする。アプリのバージョンはプロジェクトの設定から読み取り、発行とインストーラーに同じ値を使う。実行前にバージョンの設定元と公開済みの番号を確認する。設定がない場合の MSBuild の既定値を、開発者が決めたバージョンとみなしてはならない。空の発行先を使い、以前のファイルを混ぜない。発行には .NET ランタイムと Windows App SDK の両方を含める。アプリが自前の ICO を出力に含める設定も維持する。

```powershell
$appName = 'MyApp'
$usesAppIcon = $true
$versionOutput = & dotnet msbuild .\MyApp.csproj -nologo -getProperty:Version -p:Configuration=Release -p:Platform=x64 -p:RuntimeIdentifier=win-x64 -p:SelfContained=true -p:WindowsAppSDKSelfContained=true -p:PublishSingleFile=false -p:PublishTrimmed=false
if ($LASTEXITCODE -ne 0) { throw 'Could not read the application version.' }
$appVersion = "$versionOutput".Trim()
if ($appVersion -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') {
    throw 'Application version must contain three numeric components.'
}
foreach ($component in $appVersion.Split('.')) {
    if ([uint64]$component -gt 65535) { throw 'A version component exceeds 65535.' }
}
$hsisDir = Join-Path $env:LOCALAPPDATA 'Programs\HSIS'
$hsisExe = Join-Path $hsisDir 'hsis.exe'
$hsisDeps = Join-Path $hsisDir 'hsis.deps.json'
if (!(Test-Path -LiteralPath $hsisExe) -or !(Test-Path -LiteralPath $hsisDeps)) {
    throw 'HSIS 0.11.2 CLI was not found.'
}
$deps = Get-Content -LiteralPath $hsisDeps -Raw | ConvertFrom-Json
if ($deps.libraries.PSObject.Properties.Name -notcontains 'hsis/0.11.2') {
    throw 'HSIS CLI version must be 0.11.2.'
}
$templateProps = Join-Path $hsisDir 'Template\Directory.Build.props'
if (!(Test-Path -LiteralPath $templateProps)) {
    throw 'HSIS Template folder was not found.'
}
[xml]$templateXml = Get-Content -LiteralPath $templateProps -Raw
if ($templateXml.Project.PropertyGroup.Version -ne '0.11.2') {
    throw 'HSIS Template version must be 0.11.2.'
}

$publishDir = Join-Path (Get-Location).Path "artifacts\publish-$appVersion"
if (Test-Path -LiteralPath $publishDir) {
    throw 'Publish directory already exists; choose an empty directory.'
}
dotnet publish .\MyApp.csproj -c Release -r win-x64 --self-contained true -p:Platform=x64 -p:WindowsAppSDKSelfContained=true -p:PublishSingleFile=false -p:PublishTrimmed=false "-p:Version=$appVersion" -o $publishDir
if ($LASTEXITCODE -ne 0) { throw 'Application publish failed.' }
$requiredFiles = @("$appName.exe", "$appName.pri", 'App.xbf', 'MainWindow.xbf')
if ($usesAppIcon) { $requiredFiles += 'Assets\AppIcon.ico' }
foreach ($file in $requiredFiles) {
    if (!(Test-Path -LiteralPath (Join-Path $publishDir $file))) {
        throw "Required published file was not found: $file"
    }
}
```

ユーザーが発行版の実行を制限していなければ、ここで発行先の EXE を起動し、ウィンドウと主要な操作を確認する。確認できたら、同じ PowerShell セッションでインストーラーを生成する。

```powershell
& $hsisExe build .\installer\MyApp.nsi --output .\artifacts\installer "-DAPP_VERSION=$appVersion" "-DSOURCE_DIR=$publishDir"
if ($LASTEXITCODE -ne 0) { throw 'Installer build failed.' }
```

`.nsi` 内の `VIProductVersion` に 4 要素の Windows バージョンを渡すため、`$appVersion` は `0.1.0` のような 3 要素の数値（各 0～65535）とする。対応する Git タグを付ける場合は `v0.1.0` のように `v` を付ける。Windows App SDK の自己完結設定と .NET の `--self-contained true` は別々に必要。検査する `.pri`、`.xbf`、ICO の名前や配置が異なる場合は、そのアプリの実際の名前に合わせる。`Microsoft.UI.pri` など SDK 側の PRI だけでは不十分。

成功すると HSIS が `SETUP=...` に生成された EXE のパスを表示する。`Setup-日時-識別子` 配下の成果物を確認し、付随ファイルがある場合はフォルダーごと扱う。EXE 名は変更せず、変更が必要なら `OutFile` を変えて再生成する。

## 4. 同梱内容と動作の確認

- 指定した 0.11.2 の CLI で生成できたこと、生成 EXE の存在、配置元にアプリ EXE、アプリ固有の `.pri`、各画面の `.xbf`、必要な ICO を含むことを確認する。ページを削除した場合は、対応する古い `.xbf` が残っていないことも確認する。
- 発行先のアプリ EXE を起動し、ウィンドウが表示されてすぐに終了せず、主要な操作が動くことを確認する。ビルドやインストーラー生成の成功だけを起動確認の代わりにしない。
- ユーザーがインストールの動作確認を担当すると指定した場合は、インストーラーを実行せずに渡す。発行フォルダーの確認は同梱の実証ではないので、インストーラーの同梱内容とインストール後の動作は未確認と報告する。
- インストールして確認できる場合は、既存のインストール先、スタートメニューやアプリ一覧の登録と衝突しない、適切なテスト環境を使う。セットアップ、インストール先からの起動、スタートメニュー、アプリ一覧、アンインストールを確認する。別フォルダーを選んでも同じ登録キーやショートカットを使うため、隔離されるとは限らない。

### 7-Zip がない場合の同梱確認

HSIS 0.11.2 の生成 EXE は `.nsi` を読み込む独自形式で、NSIS の EXE と同一ではない。`tar.exe -tf Setup.exe` や `7z l Setup.exe` でアプリのファイル一覧を直接取得できるとは限らない。NSIS プラグインや未対応の圧縮形式の指定を前提にしない。

テスト環境にインストールできる場合は、インストール完了後のファイルと発行元を比較する。次の `$installDir` は実際に選んだインストール先、`$publishDir` は発行先とする。ファイル名はアプリに合わせて変更する。アプリで ICO を使わない場合だけ `$usesAppIcon` を `$false` にする。

```powershell
$publishDir = 'C:\path\to\publish'
$installDir = 'C:\path\to\test-install'
$usesAppIcon = $true
$requiredFiles = @('MyApp.exe', 'MyApp.pri', 'App.xbf', 'MainWindow.xbf')
if ($usesAppIcon) { $requiredFiles += 'Assets\AppIcon.ico' }
foreach ($file in $requiredFiles) {
    $source = Join-Path $publishDir $file
    $installed = Join-Path (Join-Path $installDir 'app') $file
    if (!(Test-Path -LiteralPath $source) -or !(Test-Path -LiteralPath $installed)) {
        throw "Required file was not found: $file"
    }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash) {
        throw "Installed file differs from published file: $file"
    }
}
```

この例は列挙したファイルの一致を検証する。追加の画面や依存ファイルも必要に応じて比較し、未検証の内容を区別して報告する。インストールや検証可能な展開を行えない場合は、同梱内容を確認済みとしない。

### インストールの待機と中断

- HSIS のセットアップは大きなアプリでは数分かかることがある。短いツールの制限時間に合わせて `Start-Process -Wait` を使い続けず、起動したプロセスの ID と開始時刻を記録し、別々の短い待機で状態を確認する。`Uninstall.exe` の出現だけでは完了と判定しない。プロセスの終了結果と必要な配置・登録の両方を確認する。
- 同じ PowerShell セッションで、起動時に `-PassThru` で取得した `$setupProcess` を保持できる場合は、次を 1 回ずつ繰り返す。終了コードを取得できない場合は成功を断定しない。

  ```powershell
  Start-Sleep -Seconds 5
  $setupProcess.Refresh()
  if ($setupProcess.HasExited) {
      "Exit code: $($setupProcess.ExitCode)"
  }
  else {
      "Still running: $($setupProcess.Id)"
  }
  ```

- `MUI_FINISHPAGE_RUN` がある場合、完了画面を閉じる際にアプリが起動することがある。無人実行が使える実装でも自動起動の有無を事前に確認し、テストで起動したプロセスだけを終了する。確認した HSIS 0.11.2 の実装では `/S` はアンインストール用に処理される。セットアップ側に NSIS の無人実行や `/D` の動作を仮定せず、使用する版で確認する。
- HSIS のアンインストーラーは一時コピーを別プロセスで実行する場合がある。最初のプロセスの終了だけで削除完了とせず、子プロセスと登録・配置の状態も確認する。
- 中断・強制終了時の自動ロールバックは保証されない。インストール先や登録が部分的に残りうるため、完了扱いせず状態を確認する。既存データや他のアプリの登録を自動削除しない。

## 5. 報告

- セットアップの出力パス、既定のインストール先、動作確認の実施・未実施を報告する。
