using System;
using System.IO;
using System.Text.Json;
using Microsoft.UI.Xaml;
using Microsoft.Web.WebView2.Core;

namespace EditorApp;

public sealed partial class MainWindow
{
    const string SampleJson = """
        {
          "name": "WinUI 3",
          "editor": "Monaco",
          "offline": true
        }
        """;

    const string EditorUrl = "https://editor.example/index.html";
    CoreWebView2? _core;
    bool _ready;
    bool _closed;
    bool _readOnly;
    string _text = SampleJson;

    async void OnEditorLoaded(object sender, RoutedEventArgs args)
    {
        EditorView.Loaded -= OnEditorLoaded;
        SetStatus("WebView2 を初期化しています…");
        try
        {
            await EditorView.EnsureCoreWebView2Async();
            if (_closed) return;

            _core = EditorView.CoreWebView2
                ?? throw new InvalidOperationException("CoreWebView2 を取得できませんでした。");
            _core.SetVirtualHostNameToFolderMapping(
                "editor.example",
                Path.Combine(AppContext.BaseDirectory, "Web"),
                CoreWebView2HostResourceAccessKind.Deny);
            _core.NavigationStarting += OnNavigationStarting;
            _core.WebMessageReceived += OnEditorMessage;
            _core.NavigationCompleted += OnEditorNavigationCompleted;
            _core.NewWindowRequested += OnEditorNewWindowRequested;
            _core.Navigate(EditorUrl);
        }
        catch (Exception ex)
        {
            if (!_closed) SetStatus($"エディタの初期化に失敗しました。{ex.Message}");
        }
    }

    void OnNavigationStarting(CoreWebView2 sender, CoreWebView2NavigationStartingEventArgs args)
    {
        if (args.Uri == EditorUrl)
        {
            _ready = false;
            ResetButton.IsEnabled = false;
            ReadOnlyButton.IsEnabled = false;
            SetStatus("エディタを読み込んでいます…");
        }
        else
        {
            args.Cancel = true;
        }
    }

    void OnEditorMessage(CoreWebView2 sender, CoreWebView2WebMessageReceivedEventArgs args)
    {
        if (args.Source != EditorUrl) return;

        using JsonDocument document = JsonDocument.Parse(args.WebMessageAsJson);
        JsonElement root = document.RootElement;
        if (root.ValueKind != JsonValueKind.Object ||
            !root.TryGetProperty("type", out JsonElement type) ||
            type.ValueKind != JsonValueKind.String) return;

        switch (type.GetString())
        {
            case "ready" when !_ready:
                _ready = true;
                UpdateEditor(_text);
                ResetButton.IsEnabled = !_readOnly;
                ReadOnlyButton.IsEnabled = true;
                ShowEditorStatus();
                break;
            case "textChanged" when _ready &&
                root.TryGetProperty("text", out JsonElement text) &&
                text.ValueKind == JsonValueKind.String:
                _text = text.GetString() ?? string.Empty;
                ShowEditorStatus();
                break;
        }
    }

    void UpdateEditor(string? text = null)
    {
        if (_ready && _core is not null)
        {
            _core.PostWebMessageAsJson(JsonSerializer.Serialize(new
            {
                type = "updateEditor",
                text,
                readOnly = _readOnly
            }));
        }
    }

    void OnEditorClosed(object sender, WindowEventArgs args)
    {
        _closed = true;
        _ready = false;
        if (_core is not null)
        {
            _core.NavigationStarting -= OnNavigationStarting;
            _core.WebMessageReceived -= OnEditorMessage;
            _core.NavigationCompleted -= OnEditorNavigationCompleted;
            _core.NewWindowRequested -= OnEditorNewWindowRequested;
            _core = null;
        }

        EditorView.Close();
    }

    void OnEditorNavigationCompleted(CoreWebView2 sender, CoreWebView2NavigationCompletedEventArgs args)
    {
        if (!args.IsSuccess && args.WebErrorStatus != CoreWebView2WebErrorStatus.OperationCanceled)
        {
            SetStatus($"エディタの読み込みに失敗しました。{args.WebErrorStatus}");
        }
    }

    void OnEditorNewWindowRequested(CoreWebView2 sender, CoreWebView2NewWindowRequestedEventArgs args)
        => args.Handled = true;

    void OnReset(object sender, RoutedEventArgs args)
    {
        _text = SampleJson;
        UpdateEditor(_text);
        ShowEditorStatus();
    }

    void OnReadOnlyChanged(object sender, RoutedEventArgs args)
    {
        _readOnly = ReadOnlyButton.IsChecked == true;
        ResetButton.IsEnabled = !_readOnly;
        UpdateEditor();
        ShowEditorStatus();
    }

    void ShowEditorStatus()
    {
        string mode = _readOnly ? "読み取り専用" : "編集中";
        SetStatus($"JSON  |  {mode}  |  {_text.Length:N0} 文字");
    }
}
