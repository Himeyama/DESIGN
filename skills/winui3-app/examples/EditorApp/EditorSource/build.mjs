import { copyFile } from 'node:fs/promises';
import { build } from 'esbuild';

const monaco = 'node_modules/monaco-editor/esm/vs';
await build({
    entryPoints: [
        'editor.js',
        `${monaco}/editor/editor.worker.js`,
        `${monaco}/language/json/json.worker.js`
    ],
    bundle: true,
    format: 'esm',
    outdir: '../Web',
    outbase: '.',
    entryNames: '[name]',
    loader: { '.ttf': 'file' },
    minify: true,
    legalComments: 'linked'
});

for (const file of ['LICENSE', 'ThirdPartyNotices.txt']) {
    await copyFile(`node_modules/monaco-editor/${file}`, `../Web/Monaco-${file}`);
}
