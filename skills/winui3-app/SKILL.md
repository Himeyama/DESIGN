---
name: winui3-app
description: Build or modify C# WinUI 3 Windows desktop apps using a title-free custom title bar, a status bar, DPI-aware sizing, the user's C# style, and HSIS installers when requested.
---

# WinUI 3 アプリ作成

C# と WinUI 3 で Windows デスクトップアプリを作る。ユーザーの今回の指示は、以下の既定ルールより優先する。

## 作業手順

1. 依頼された機能、入力、操作、結果を確認する。既存プロジェクトがある場合は、まず構成と対象バージョンを確認し、既存の機能や配布方式を維持する。
2. 新規なら [公式 WinUI Blank App の生成と調整](references/winui-blank-template.md) を読み、検証済みテンプレート版と生成ファイルを確認する。Windows App SDK 1.7 以降、.NET 8 以降、C# 12 以降を使う。次の項目をプロジェクトの `PropertyGroup` に設定する。既存プロジェクトでは互換性を確認し、必要な場合だけ変更する。

   ```xml
   <Nullable>enable</Nullable>
   ```

3. 新規の単一画面アプリでは、下の `MainWindow.xaml` と `MainWindow.xaml.cs` を基にウィンドウを作り、テンプレートの未使用 `MainPage` と参照を参照先の手順どおり整理する。両ファイルの `MyApp` をプロジェクトの名前空間に置き換える。既存アプリや `Frame` を使うアプリでは丸ごと上書きせず、画面を残したまま必要な行を統合する。
4. 単一画面なら `AppContent`、`Frame` を使う場合は `MainPage.xaml` 内に、依頼された機能の UI と処理を実装する。ひな形だけで完了としない。状態を知らせる必要があるときはステータスバーに表示する。
5. 新規アプリでは「アプリのアイコン」の手順でアイコンを作成し、実行ファイルと実行中のウィンドウに設定する。既存アプリは既存のアイコンを維持し、未設定の場合は作成・設定する。ユーザーがアイコン作成を不要とした場合は既定アイコンを使用し、「作成を省略する場合」に従う。
6. 「バージョン管理」に従い、新規アプリの初回バージョンを設定する。コミットまたはリリースに向けて変更する場合も、ビルド前にバージョンを揃える。
7. 依存関係の復元と対象アーキテクチャのビルドを行い、起動して末尾の確認項目を試す。実行可能な環境がなければ、未実施であることと理由を報告する。
8. インストーラーの作成を依頼された場合は [HSIS 0.11.2 によるインストーラー作成](references/hsis-installer.md) に従う。既存の配布方式やユーザーデータを確認し、生成した成果物と未確認事項を伝える。
9. Git 管理しているアプリでコミットを作る場合は、「バージョン管理」に従い、そのコミットにバージョンタグを付け、ブランチとタグを push する。

## バージョン管理

- バージョンは `メジャー.マイナー.パッチ` の 3 つの数値で表す。新規アプリの初回バージョンは `0.1.0`、対応する Git タグは `v0.1.0` とする。
- メジャーバージョンは開発者自身が明示的に引き上げる。AI は引き上げない。メジャーの変更が必要な場合は開発者に依頼し、開発者が設定したバージョンを確認してから、他の設定やタグにも同じ番号を反映する。
- 機能追加などアプリの仕様に変更がある場合は、AI がマイナーバージョンを 1 つ上げ、パッチを `0` にする。例: `0.1.2` → `0.2.0`。
- バグ修正、セキュリティ向上、リファクタリングなど、大きな機能変更がない場合は、AI がパッチバージョンを 1 つ上げる。例: `0.1.2` → `0.1.3`。機能追加と修正を同じコミットに含める場合は、マイナーを上げる。
- 1 コミットに 1 バージョンを割り当てる。新規アプリの最初のコミットには `v0.1.0` を使い、それ以降はドキュメントやビルド設定だけのコミットもパッチを上げる。すでに開発者がメジャーを引き上げたコミットには、その番号を使う。
- 新規の .NET プロジェクトでは `.csproj` の `PropertyGroup` に `<Version>0.1.0</Version>` を設定する。既存アプリでは現在のバージョンや管理場所を確認し、初回バージョンに戻さない。バージョンの設定元が不明な場合は開発者に確認する。
- `.csproj`、バージョン表示、インストーラーと Git タグは同じ番号に揃える。設定値の `0.1.0` とタグの `v0.1.0` は同じバージョンで、`v` はタグに付ける。

### Git 管理しているアプリをコミットする場合

1. 変更内容、現在のバージョン、対象のブランチと push 先を確認する。既存のローカル・リモートタグも確認し、同じバージョンのタグが別のコミットに存在する場合は上書きしない。
2. 上のルールに従ってバージョンを決め、アプリの変更とバージョン変更を同じコミットに含める。ユーザーの無関係な変更は含めない。
3. コミットに `v` とバージョンを組み合わせたタグを作る。対象ブランチを push してから、そのタグを同じリモートへ push する。他のタグをまとめて push しない。
4. 各操作の結果を確認する。リモートや対象ブランチが不明な場合は確認する。push が失敗した場合は成功したと報告せず、失敗した操作と残ったローカルのコミット・タグを伝える。既存タグの付け替えや強制 push はしない。

例えば、対象がリモート `origin` の `main` ブランチで、作成したコミットが `0.1.1` の場合:

```powershell
git tag v0.1.1
git push origin HEAD:refs/heads/main
git push origin refs/tags/v0.1.1
```

各コマンドが成功したことを確認してから次へ進む。リモート、ブランチ、タグは実際の対象に置き換える。Git で管理しないよう指定されたアプリは、Git の初期化・コミット・タグ付け・push を行わない。その場合もアプリのバージョンは上のルールで管理する。

## ウィンドウの既定仕様

- タイトルバーにはタイトル文字列とアイコンを表示しない。ドラッグ領域と Windows 標準の最小化・最大化・閉じるボタンを残す。`Window.Title` はタスクバーや Alt+Tab のウィンドウ名であり、タイトルバーにテキストを置くこととは別。
- アプリ下端にテキスト 1 行分のステータスバーを置く。主コンテンツと別の行にし、必要な状態や操作結果だけを表示する。長文は省略表示する。
- 初期サイズは **960 × 640 有効ピクセル**を目安にする。下のコードはウィンドウの DPI から物理ピクセルに変換し、モニターの作業領域に収める。処理するのは初期化時だけとし、ユーザーのリサイズを妨げない。保存済みのサイズや起動状態がある場合はそれを優先する。
- `app.manifest` の `<assembly>` 内に、既存の同じ設定がなければ次を追加し、Per-Monitor V2 を有効にする。既存の `<application>` や `<windowsSettings>` がある場合は中へ統合し、重複させない。

```xml
<application xmlns="urn:schemas-microsoft-com:asm.v3">
  <windowsSettings>
    <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
  </windowsSettings>
</application>
```

### MainWindow.xaml

単一画面の新規アプリでは以下を基にする。テンプレートの `Frame` と `MainPage` を残す場合は、[テンプレートの調整手順](references/winui-blank-template.md) に従う。`AppContent` 内にアプリのコントロールを配置する。

```xml
<Window
    x:Class="MyApp.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="アプリ">
    <Window.SystemBackdrop>
        <MicaBackdrop />
    </Window.SystemBackdrop>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <TitleBar x:Name="AppTitleBar" />

        <Grid x:Name="AppContent" Grid.Row="1" Margin="24,16,24,24">
            <!-- ここにアプリの操作画面を作る。 -->
        </Grid>

        <Border Grid.Row="2" MinHeight="32" Padding="24,6"
                BorderThickness="0,1,0,0"
                BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}">
            <TextBlock x:Name="StatusText"
                       Style="{ThemeResource CaptionTextBlockStyle}"
                       VerticalAlignment="Center" TextTrimming="CharacterEllipsis"
                       AutomationProperties.LiveSetting="Polite" />
        </Border>
    </Grid>
</Window>
```

### MainWindow.xaml.cs

`InitializeComponent()` 後にタイトルバーを設定し、初期サイズを 1 回だけ設定する。テンプレートの `App.xaml` と `App.xaml.cs` は維持する。

```csharp
using System;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Windows.Graphics;
using WinRT.Interop;

namespace MyApp;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        if (AppWindowTitleBar.IsCustomizationSupported())
        {
            ExtendsContentIntoTitleBar = true;
            SetTitleBar(AppTitleBar);
        }
        else
        {
            AppTitleBar.Visibility = Visibility.Collapsed;
        }

        SetAppIcon();
        SetInitialWindowSize();
    }

    void SetAppIcon()
    {
        string iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "AppIcon.ico");
        if (File.Exists(iconPath))
        {
            AppWindow.SetIcon(iconPath);
        }
    }

    void SetStatus(string message) => StatusText.Text = message;

    void SetInitialWindowSize()
    {
        const int baseDpi = 96;
        const int defaultWidth = 960;
        const int defaultHeight = 640;

        IntPtr handle = WindowNative.GetWindowHandle(this);
        uint dpi = GetDpiForWindow(handle);
        double scale = dpi > 0 ? (double)dpi / baseDpi : 1;
        int width = (int)Math.Round(defaultWidth * scale);
        int height = (int)Math.Round(defaultHeight * scale);
        DisplayArea? display = DisplayArea.GetFromWindowId(AppWindow.Id, DisplayAreaFallback.Nearest);

        if (display is null)
        {
            AppWindow.Resize(new SizeInt32(width, height));
            return;
        }

        RectInt32 workArea = display.WorkArea;
        width = Math.Min(width, workArea.Width);
        height = Math.Min(height, workArea.Height);
        int x = workArea.X + (workArea.Width - width) / 2;
        int y = workArea.Y + (workArea.Height - height) / 2;
        AppWindow.MoveAndResize(new RectInt32(x, y, width, height));
    }

    [DllImport("user32.dll")]
    static extern uint GetDpiForWindow(IntPtr handle);
}
```

このコードは Windows App SDK 1.7 以降の `TitleBar` を使う。対象環境でタイトルバーのカスタマイズが利用できない場合は、通常のタイトルバーへフォールバックし、タイトルとアイコンの非表示を保証できないことを報告する。対話コントロールをタイトルバーに追加する場合は、標準ボタンと重ねず、ドラッグ領域と入力領域を分ける。

## UI の作り方

- 操作と状態が見て分かるコントロールを使う。画面タイトル、重複する見出し、説明しなくても分かる操作説明は置かない。必要なラベル、空状態、アクセシビリティ情報は残す。
- 画面の内容は左から自然に並べ、利用できる幅を使う。根拠のない `MaxWidth` や中央寄せで大きな左余白を作らない。
- 一覧などが残りの高さを使う場合は、親に `Grid` の `*` 行を用意する。画面全体を `ScrollViewer` で包み、その中にスクロールする一覧を重ねない。
- 内容が収まるときはスクロールバーを出さない。あふれる場合は該当する領域だけスクロール可能にする。バーを隠して内容に到達できなくしない。
- Windows の標準コントロールとテーマリソースを使い、キーボードとスクリーンリーダーでも操作できるようにする。

## アイコンの選択と作成

[Fluent 2 Iconography](https://fluent2.microsoft.design/iconography) を参考に、意味が伝わる太めの形と、控えめな色・グラデーションを使う。アプリの識別用と画面内の操作用は区別し、タイトルバーにはどちらも表示しない。以下はユーザーの希望に合わせた表現で、公式 Fluent アイコンそのものではない。

### 新しいアイコンを作る手順

1. アイコンの用途、表したい操作やモチーフ、使用サイズを決める。アプリの識別用アイコンは、機能や対象から着想し、抽象化した図柄全体のシルエットで表す。例えばカウンターなら、数の積み重なりを太い形の重なりとして表す。画面内の操作用アイコンは既存のアイコンと意味・見た目を揃える。
2. 画像生成が利用可能なら、最初にデザイン案を生成する。アプリアイコンは用途から着想した抽象的な形を描き、太く丸みのあるシルエット、透明な背景、淡いグラデーション、控えめな立体感を指示する。現実の機械や物をそのまま細かく描くことは避ける。汎用の角丸四角や丸いタイルの上に記号を置くだけの構図は既定にしない。文字、細かい模様や複雑な影は避ける。生成画像はデザインの参考画像であり、そのまま SVG ではない。
3. 案の輪郭と色を参考に、パスや基本図形と `linearGradient` などで編集可能な SVG を作る。ビットマップを SVG に埋め込むだけで済ませない。必要なら手で輪郭を描き直し、形を簡略化する。画像生成を使えない場合は同じ条件で直接 SVG を作り、その旨を伝える。
4. 生成案と SVG を見比べ、形や色を調整する。透明背景、意図した描画範囲、20・24 ピクセルなど実際の大きさ、明暗テーマを確認する。細く消える部分やつぶれる隙間があれば太さと余白を調整する。ハイコントラストではシステム色を使う代替表示を用意し、色だけで状態を伝えない。
5. 利用先に合わせて WinUI の図形や画像として組み込み、対象サイズで実際の表示と操作を確認する。参照した第三者の素材をコピー・配布する場合はライセンスを確認する。

画像生成への指示例: 「Windows アプリの［用途］から着想した［抽象的な形］全体のシルエットで表すアイコン。実物の細密な描写ではなく、形の重なりで意味を暗示する。太く丸みのある形、［色］の控えめなグラデーションと柔らかな立体感、透明背景。四角いタイルやバッジを背景に置かない。文字と細かい装飾なし。小さいサイズでも識別できる形」

### 操作用アイコン

- 20 × 20 または 24 × 24 の正方形の SVG を基準にする。透明背景、太く単純な形、抑えた色を使い、線の太さ・丸み・余白をアプリ内で揃える。実際の大きさで視認性を優先する。
- 単純な塗りのパスは `PathIcon` に使える。SVG の線や変形をそのまま `PathIcon.Data` に貼らず、塗りつぶしたパスにする。グラデーションは `PathIcon.Foreground` にブラシを設定する。SVG の複雑な表現は `SvgImageSource` を検討し、対応する SVG 要素とテーマごとの表示を確認する。
- アイコンだけのボタンには `AutomationProperties.Name` とツールチップを付ける。意味が分かりにくい場合は短いテキストも使う。アイコンの見た目とクリック・タッチ領域の大きさを別に考える。
- 必要に応じて [Fluent System Icons](https://github.com/microsoft/fluentui-system-icons) や Windows 標準アイコンを利用できる。既存のアイコン群や配色との一貫性を保つ。

次は太めの「追加」アイコンの例。SVG の色は固定で、WinUI 側は明暗用のグラデーションとハイコントラスト用のシステム色を使う。実際の操作に合わせて `Click` ハンドラーを追加する。

`add.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <defs>
    <linearGradient id="ink" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#245CB0" />
      <stop offset="1" stop-color="#6247B8" />
    </linearGradient>
  </defs>
  <path fill="url(#ink)" d="M 10 2.75 a 1.25 1.25 0 0 1 1.25 1.25 v 4.75 H 16 a 1.25 1.25 0 0 1 0 2.5 h -4.75 V 16 a 1.25 1.25 0 0 1 -2.5 0 v -4.75 H 4 a 1.25 1.25 0 0 1 0 -2.5 h 4.75 V 4 a 1.25 1.25 0 0 1 1.25 -1.25 Z" />
</svg>
```

```xml
<Button Width="40" Height="40" Padding="0"
        AutomationProperties.Name="追加" ToolTipService.ToolTip="追加">
    <Button.Resources>
        <ResourceDictionary>
            <ResourceDictionary.ThemeDictionaries>
                <ResourceDictionary x:Key="Light">
                    <LinearGradientBrush x:Key="AddIconBrush" StartPoint="0,0" EndPoint="1,1">
                        <GradientStop Color="#245CB0" Offset="0" />
                        <GradientStop Color="#6247B8" Offset="1" />
                    </LinearGradientBrush>
                </ResourceDictionary>
                <ResourceDictionary x:Key="Default">
                    <LinearGradientBrush x:Key="AddIconBrush" StartPoint="0,0" EndPoint="1,1">
                        <GradientStop Color="#9CC8FF" Offset="0" />
                        <GradientStop Color="#D3BBFF" Offset="1" />
                    </LinearGradientBrush>
                </ResourceDictionary>
                <ResourceDictionary x:Key="HighContrast">
                    <SolidColorBrush x:Key="AddIconBrush" Color="{ThemeResource SystemColorButtonTextColor}" />
                </ResourceDictionary>
            </ResourceDictionary.ThemeDictionaries>
        </ResourceDictionary>
    </Button.Resources>
    <PathIcon Width="20" Height="20" Foreground="{ThemeResource AddIconBrush}"
              Data="M 10 2.75 a 1.25 1.25 0 0 1 1.25 1.25 v 4.75 H 16 a 1.25 1.25 0 0 1 0 2.5 h -4.75 V 16 a 1.25 1.25 0 0 1 -2.5 0 v -4.75 H 4 a 1.25 1.25 0 0 1 0 -2.5 h 4.75 V 4 a 1.25 1.25 0 0 1 1.25 -1.25 Z" />
</Button>
```

### アプリのアイコン

- アプリの用途から着想した抽象的なモチーフを選び、その全体のシルエットや形の重なりでアプリを表す。角丸四角の背景に記号を載せた汎用タイルを既定にせず、モチーフ自体に太さ・淡いグラデーション・柔らかな立体感を持たせる。Microsoft の製品アイコンやロゴを流用しない。
- 編集可能な SVG を元データにする。SVG から透明背景の **16・32・48・256 ピクセルの PNG** をそれぞれ書き出し、各サイズの見え方を確認する。特に小さいサイズでつぶれる細部は SVG 側で調整する。
- 4 枚の PNG を 1 個の ICO にまとめ、各サイズと透明度を確認する。以下の手順と [scripts/pngs_to_ico.py](scripts/pngs_to_ico.py) を使用できる。画像生成した参考画像を ICO に直接使わず、SVG から書き出す。
- 非パッケージアプリは、作成した ICO を `Assets/AppIcon.ico` に置き、次を `.csproj` に設定する。実行ファイルに埋め込み、実行時にも ICO を出力フォルダへコピーする。既存の `Content` 定義と重複する場合は、既存項目を更新する。

  ```xml
  <PropertyGroup>
    <ApplicationIcon>Assets\AppIcon.ico</ApplicationIcon>
  </PropertyGroup>
  <ItemGroup>
    <Content Include="Assets\AppIcon.ico"
             CopyToOutputDirectory="PreserveNewest"
             CopyToPublishDirectory="PreserveNewest" />
  </ItemGroup>
  ```

- `MainWindow` のひな形の `SetAppIcon()` は、コピーされた ICO のフルパスを `AppWindow.SetIcon` に渡して実行中のウィンドウにも設定する。アイコンが見つからずアプリを起動できない事態を避けるため存在を確認するが、欠落したまま完了としない。出力先の ICO の存在と、エクスプローラー・タスクバーの表示を確認する。カスタムタイトルバー内にアイコン要素は追加しない。
- MSIX では `Package.appxmanifest` が参照する画像と必要なスケール・ターゲットサイズを用意する。既存の配布方式を変えずに適用を確認する。詳細は [Windows アプリのアイコン](https://learn.microsoft.com/windows/apps/design/iconography/app-icon-construction) を参照する。

#### 作成を省略する場合

ユーザーが新規アイコンの作成を不要とした場合は、テンプレートまたは既存アプリのアイコンをそのまま使う。SVG・PNG・ICO の新規作成や ICO 内のサイズ・透明度の検査は不要。アイコンを設定する場合は参照先の存在、出力先へのコピー、実行ファイルやタスクバーでの表示を確認する。アイコン自体も不要と指定された場合は作成・設定・表示確認を省き、タイトルバーにアイコンを表示しないことは確認する。

#### SVG から ICO を作る例

Inkscape が利用可能な場合、アプリのルートで次を実行する。`Assets/AppIcon.svg` は自作 SVG とし、書き出し先はあらかじめ作成する。4 枚とも 8 ビット RGBA の透明 PNG にする。

```powershell
New-Item -ItemType Directory -Force Assets | Out-Null
foreach ($size in @(16, 32, 48, 256)) {
    & inkscape Assets/AppIcon.svg --export-area-page --export-filename="Assets/AppIcon-$size.png" --export-width=$size --export-height=$size
    if ($LASTEXITCODE -ne 0) { throw "SVG の書き出しに失敗しました: $size" }
}
```

Inkscape がない場合は、利用可能な SVG レンダラーで同名・同サイズの RGBA PNG を作る。次に Python 3.10 以降で、スキルに付属する `pngs_to_ico.py` を実行する。実際のスキルフォルダのパスに置き換える。追加の Python ライブラリは不要。

```powershell
python "<スキルフォルダ>/scripts/pngs_to_ico.py" Assets
```

`Assets/AppIcon.ico` が作られる。入力が欠けている、サイズが異なる、または RGBA でない場合はエラーになるので、PNG を修正して再実行する。配布方式に合わせてアプリアイコンを設定し、必要なら各サイズのデザインを個別に調整する。

## C# の書き方

- `var` を使わず型を明示する。生成は原則 `型 変数 = new();`。宣言型と生成型が異なる場合などは具体型を明示する。
- 破棄するオブジェクトは原則 `using` 宣言を使う。適切な破棄のタイミングのために必要ならスコープを設ける。名前空間の `using` ディレクティブは通常どおり使う。
- 配列やリストの初期化にはコレクション式 `[]`、`[要素, ...]` を使う。省略可能な `private` は書かない。
- nullable を有効にし、値がない可能性を `?` と null 判定で扱う。警告を消すためだけに `!` を乱用しない。
- 値の分岐は読みやすい範囲で switch 式にする。単純な関数やプロパティは `=>` で書く。型の判定と取り出しは `is` などのパターンマッチングを使う。

```csharp
List<string> names = ["Alice", "Bob"];
List<string> results = new();
using FileStream stream = File.OpenRead(path);

if (sender is Button { Tag: string action })
{
    string label = action switch
    {
        "save" => "保存",
        "close" => "閉じる",
        _ => "その他"
    };
}

static bool HasItems(int count) => count > 0;
```

## WinUI 3 で迷いやすい点

- アプリの名前空間と .NET の型名は衝突しうる。例えば `Stopwatch` 名前空間で時間計測型を使う場合は `global::System.Diagnostics.Stopwatch stopwatch = new();` のように型を明示する。
- UI 用の `DispatcherTimer` は `Microsoft.UI.Xaml.DispatcherTimer` を使う。WPF や UWP の API を WinUI 3 に移すときは、対象の Windows App SDK の API と名前空間を確認する。
- WinUI 3 の `TextBlock` に `FontVariant` はない。数字を等幅に揃える場合は、対応フォントで `Typography.NumeralAlignment="Tabular"` を使い、実際の表示を確認する。

## 完了前の確認

- ビルドが成功する。生成した実行ファイルを実際に起動し、ウィンドウが表示され、起動直後に終了せず、依頼された主要操作が動く。出力フォルダを別にした場合は、その実行ファイルを確認する。
- タイトルバーにタイトル・アイコンがなく、ドラッグ、最小化、最大化／復元、閉じるができる。
- 内容が左から表示され、不要な説明や大きな左余白がない。収まる内容にスクロールバーが出ず、あふれた内容には到達できる。
- ステータスバーはリサイズ後も下端にあり、文字が収まる。
- 作成したアイコンは実際の表示サイズで判別でき、明暗・ハイコントラストでも見える。新規作成したアプリアイコンの PNG と ICO は 16・32・48・256 ピクセルと透明度を確認する。既定アイコンを流用した場合は「作成を省略する場合」の確認範囲を使う。アイコンだけのボタンには操作名があり、必要な素材ライセンスを満たしている。
- 可能なら表示倍率 100% と 150% 以上、異なる DPI の画面間移動、明暗テーマでも確認する。倍率は Windows の「設定」→「システム」→「ディスプレイ」で、アプリを表示しているモニターを選び「拡大縮小」を確認する。Per-Monitor 対応ウィンドウの `GetDpiForWindow` の値でも確認でき、96 DPI は 100%、144 DPI は 150%。DPI 非対応ウィンドウでは 96 が返るため、設定画面で確認する。設定を変更できない場合は現在の倍率と未確認の倍率を報告する。
