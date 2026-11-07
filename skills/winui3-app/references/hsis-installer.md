# HSIS 0.11.2 でインストーラーを作成

## 対象と準備

- インストーラーの作成を依頼されたときに使う。HSIS は [Himeyama/hsis](https://github.com/Himeyama/hsis) の **0.11.2** を指定し、別のバージョンで代用しない。
- この例は Windows 11 x64 で、非パッケージの WinUI 3 アプリをユーザー単位にインストールする。既存の MSIX や別の配布方法を無断で置き換えない。対象 OS・CPU が異なる場合は互換性を先に確認する。
- ビルドにはアプリの対象 .NET SDK、.NET 9 SDK、HSIS CLI とその隣の `Template` フォルダー、7z/LZMA2 対応の Windows 標準 `tar.exe` が必要。標準の tar が対応しない場合は HSIS の説明に従い `HSIS_7ZIP_PATH` に 7-Zip を指定する。初回のパッケージ復元には NuGet 接続が必要な場合がある。
- HSIS 0.11.2 のインストーラーは上記リポジトリの Releases から入手できる。既に導入されている場合は実際の CLI とテンプレートのバージョンを確認する。以下は既定のインストール先にある `hsis.exe` を使う例。
- `MyApp` は例。アプリの実行ファイル名、表示名、他のアプリと衝突しない固定の識別子・登録キーに置き換える。更新時は既存の識別子と保存先を維持する。アプリが使用するユーザーデータの保存場所を確認してから削除定義を書く。

## 1. インストーラー定義

アプリのプロジェクトルートに `installer/MyApp.nsi` を UTF-8 で作る。次の例は `artifacts` に発行したアプリ全体を `app` サブフォルダーに配置し、スタートメニューと Windows のアプリ一覧に登録する。`APP_VERSION` と `SOURCE_DIR` は後の CLI コマンドで渡す。

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

`.csproj` が `<WindowsPackageType>None</WindowsPackageType>` であることを確認し、次を `</Project>` の直前に追加する。同じ処理が既にある場合は重複して追加しない。アプリ固有のリソースインデックスと、ビルド出力内の `.xbf` を、サブフォルダー構造を保って発行先にコピーする。ファイルが見つからない場合は発行を失敗させる。

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

## 3. 発行と生成

次の PowerShell はプロジェクトルートで実行する。`MyApp.csproj`・`MyApp.nsi` を実際の名前に変更する。アプリのバージョンはプロジェクトの設定から読み取り、発行とインストーラーに同じ値を使う。実行前にバージョンの設定元と公開済みの番号を確認する。設定がない場合の MSBuild の既定値を、開発者が決めたバージョンとみなしてはならない。空の発行先を使い、以前のファイルを混ぜない。発行には .NET ランタイムと Windows App SDK の両方を含める。アプリが自前の ICO を出力に含める設定も維持する。

```powershell
$appName = 'MyApp'
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
foreach ($file in @("$appName.exe", "$appName.pri", 'App.xbf', 'MainWindow.xbf', 'Assets\AppIcon.ico')) {
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

## 4. 確認と報告

- 指定した 0.11.2 の CLI で生成できたこと、生成 EXE の存在、配置元にアプリ EXE、アプリ固有の `.pri`、各画面の `.xbf`、ICO を含む必要なファイルがあることを確認する。インストーラーに実際に同梱されていることも確認する。
- 発行先のアプリ EXE を起動し、ウィンドウが表示されてすぐに終了せず、主要な操作が動くことを確認する。ビルドやインストーラー生成の成功だけを起動確認の代わりにしない。
- ユーザーがインストールの動作確認を担当すると指定した場合は、インストーラーを実行せずに渡す。それ以外は適切なテスト環境で、セットアップ画面、インストール、インストール先からの起動、スタートメニュー、アプリ一覧、アンインストールを確認する。既存のインストールやユーザーデータを上書き・削除しない場所を選ぶ。
- セットアップの出力パス、既定のインストール先、動作確認の実施・未実施を報告する。
