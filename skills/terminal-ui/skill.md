---
name: terminal-ui
description: JavaScript でターミナル UI を実装するガイド。OSC 8 リンク・プログレスバー・スピナーなど。
---

# ターミナル UI

## 1. クリッカブルリンク（OSC 8）

テキストをクリックでブラウザやエディタが開くリンクにする。

```js
const link = (text, url) => `\x1b]8;;${url}\x07${text}\x1b]8;;\x07`;

console.log(link("GitHub を開く", "https://github.com"));
console.log(link("src/index.ts を開く", `file:///path/to/src/index.ts`));
```

対応ターミナル: iTerm2 / Kitty / WezTerm / GNOME Terminal / Windows Terminal  
未対応環境ではテキストのみ表示（安全にフォールバック）。

## 2. 折りたたみUI（クリックで開閉）

### Ink は使えない

- Ink（React for CLI）は `onClick` / `{ mouse: true }` の API が**存在しない**
- 公式ドキュメントにマウスサポートの記載なし
- キーボード（`useInput`）のみ対応

### 生エスケープシーケンスで実装する

#### セットアップ

```js
process.stdin.setRawMode(true);
process.stdin.resume();
process.stdout.write("\x1b[?25l");   // カーソル非表示
process.stdout.write("\x1b[?1000h"); // マウスボタンイベント有効
process.stdout.write("\x1b[?1006h"); // SGR拡張モード（大きな座標でも安全）
```

#### クリーンアップ（終了時に必ず呼ぶ）

```js
process.stdout.write("\x1b[?1000l\x1b[?1006l"); // マウス無効
process.stdout.write("\x1b[?25h");               // カーソル再表示
```

#### マウスイベントの受信

クリック時に stdin へ届くバイト列（SGR形式）:

```
\x1b[<btn;col;rowM   # ボタン押下
\x1b[<btn;col;rowm   # ボタン離す
```

| btn | 意味 |
|-----|------|
| 0   | 左クリック |
| 1   | 中クリック |
| 2   | 右クリック |
| 64  | スクロールアップ |
| 65  | スクロールダウン |

```js
process.stdin.on("data", (buf) => {
  const s = buf.toString();

  if (s === "\x03") process.exit(0); // Ctrl+C

  const m = s.match(/\x1b\[<(\d+);(\d+);(\d+)([Mm])/);
  if (m) {
    const btn = parseInt(m[1]);
    const col = parseInt(m[2]);
    const row = parseInt(m[3]);
    const isPress = m[4] === "M";

    if (isPress && btn === 0) {
      // 左クリック押下時の処理
    }
  }
});
```

#### 画面描画

```js
process.stdout.write("\x1b[2J\x1b[H");       // 全消去＆カーソルをホームへ
process.stdout.write("\x1b[行;列H テキスト"); // 指定座標へ出力
```

#### 折りたたみの実装パターン

```js
let headerRows = []; // 各ヘッダーの行番号を記録

function draw() {
  process.stdout.write("\x1b[2J\x1b[H");
  let row = 1;
  headerRows = [];

  for (let i = 0; i < sections.length; i++) {
    headerRows.push(row);
    // ヘッダー描画
    process.stdout.write(`\x1b[${row};1H${open[i] ? "▼" : "▶"} ${sections[i].label}\n`);
    row++;

    if (open[i]) {
      for (const line of sections[i].lines) {
        process.stdout.write(`\x1b[${row};5H${line}\n`);
        row++;
      }
    }
    row++; // セクション間の空行
  }
}

// クリック時: headerRows と照合してトグル
const idx = headerRows.indexOf(clickRow);
if (idx !== -1) {
  open[idx] = !open[idx];
  draw();
}
```

## よく使う ANSI エスケープシーケンス

| コード | 効果 |
|--------|------|
| `\x1b[2J` | 画面クリア |
| `\x1b[H` | カーソルをホーム (1,1) へ |
| `\x1b[行;列H` | カーソルを指定座標へ |
| `\x1b[?25l` | カーソル非表示 |
| `\x1b[?25h` | カーソル表示 |
| `\x1b[1m` | 太字 |
| `\x1b[2m` | 薄字 |
| `\x1b[0m` | リセット |
| `\x1b[30m`〜`\x1b[37m` | 文字色（黒〜白） |
| `\x1b[31m` | 赤 |
| `\x1b[32m` | 緑 |
| `\x1b[33m` | 黄 |
| `\x1b[36m` | シアン |
