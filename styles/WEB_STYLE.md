# ウェブサイトのデザイン

## レイアウト
- 日本語ページとする
    ```html
    <html lang="ja">
    ```

- レスポンシブデザインとし、パソコン・スマホともに見やすい構成とする

    ```html
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    ```

- 適切な余白を付け、ゆとりを持たせる
- 余白は 8 の倍数とする
- 角丸はやや小さくする
- 角丸は 4 の倍数とする
- 影は使用しない


## フォント
- 本文は明朝体とし、太字 (強調・見出し) はゴシック体とする
- 英数字は本文・太字ともにセリフ体とする
- 英数字フォントを優先する

- 以下のフォントを使用する
    - 英字: Georgia, Times New Roman
    - 日本語本文: Noto Serif JP
    - 日本語太字: Noto Sans JP

```css
body, p {
    font-family: Georgia, Times New Roman, Noto Serif JP;
}

strong, thead, h1, h2, h3, h4, h5, h6 {
    font-family: Georgia, Times New Roman, Noto Sans JP;
}
```

## 絵文字
絵文字を使用しない

## 色
- 背景色を白 (透明) とする
- 文字色は黒とする