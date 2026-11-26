import * as monaco from 'monaco-editor';

globalThis.MonacoEnvironment = {
    getWorker(_moduleId, label) {
        const file = label === 'json' ? './json.worker.js' : './editor.worker.js';
        return new Worker(new URL(file, import.meta.url), { type: 'module', name: label });
    }
};

const bridge = window.chrome.webview;
const model = monaco.editor.createModel('', 'json');
const editor = monaco.editor.create(document.getElementById('editor'), {
    model,
    automaticLayout: true,
    scrollBeyondLastLine: false
});
let applyingHostText = false;

function onHostMessage({ data }) {
    if (data?.type !== 'updateEditor') return;

    applyingHostText = true;
    try {
        if (typeof data.text === 'string' && model.getValue() !== data.text) {
            model.setValue(data.text);
        }
        editor.updateOptions({ readOnly: data.readOnly === true });
    } finally {
        applyingHostText = false;
    }
}

bridge.addEventListener('message', onHostMessage);
const contentChanged = model.onDidChangeContent(() => {
    if (!applyingHostText) {
        bridge.postMessage({ type: 'textChanged', text: model.getValue() });
    }
});
window.addEventListener('pagehide', () => {
    bridge.removeEventListener('message', onHostMessage);
    contentChanged.dispose();
    editor.dispose();
    model.dispose();
}, { once: true });

bridge.postMessage({ type: 'ready' });

