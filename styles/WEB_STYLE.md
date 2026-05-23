# Website Design Style

## Layout
- Language: Japanese. Set `<html lang="ja">`.
- Responsive: must be readable on both desktop and mobile. Include `<meta name="viewport" content="width=device-width, initial-scale=1.0">`.
- Use generous whitespace. Spacing values must be multiples of 8px.
- Border radius: small. Values must be multiples of 4px.
- No shadows.

## Fonts
- Body text: serif (Mincho). Bold text (emphasis, headings): sans-serif (Gothic).
- Latin letters and digits: always serif, for both body and bold.
- Prefer the Latin font (list it first in `font-family`).
- Font stacks:
    - Latin: Georgia, Times New Roman
    - Japanese body: Noto Serif JP
    - Japanese bold: Noto Sans JP

```css
body, p {
    font-family: Georgia, Times New Roman, Noto Serif JP;
}
strong, thead, h1, h2, h3, h4, h5, h6 {
    font-family: Georgia, Times New Roman, Noto Sans JP;
}
```

## Emoji
- Do not use emoji.

## Colors
- Background: white (transparent).
- Text: black.
