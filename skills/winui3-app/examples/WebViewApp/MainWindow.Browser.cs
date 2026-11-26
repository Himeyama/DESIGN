using System;
using Microsoft.UI.Xaml;
using Microsoft.Web.WebView2.Core;

namespace WebViewApp;

public sealed partial class MainWindow
{
    const string ExampleUrl = "https://example.com/";
    CoreWebView2? _browser;
    bool _closed;

    async void OnBrowserLoaded(object sender, RoutedEventArgs args)
    {
        Browser.Loaded -= OnBrowserLoaded;
        SetStatus("WebView2 を初期化しています…");
        try
        {
            await Browser.EnsureCoreWebView2Async();
            if (_closed) return;

            _browser = Browser.CoreWebView2
                ?? throw new InvalidOperationException("CoreWebView2 を取得できませんでした。");
            _browser.Settings.IsWebMessageEnabled = false;
            _browser.NavigationStarting += OnBrowserNavigationStarting;
            _browser.NavigationCompleted += OnBrowserNavigationCompleted;
            _browser.NewWindowRequested += OnBrowserNewWindowRequested;
            ReloadButton.IsEnabled = true;
            _browser.Navigate(ExampleUrl);
        }
        catch (Exception ex)
        {
            if (!_closed) SetStatus($"WebView2 の初期化に失敗しました。{ex.Message}");
        }
    }

    void OnReload(object sender, RoutedEventArgs args) => _browser?.Navigate(ExampleUrl);

    void OnBrowserNavigationStarting(CoreWebView2 sender, CoreWebView2NavigationStartingEventArgs args)
    {
        args.Cancel = !Uri.TryCreate(args.Uri, UriKind.Absolute, out Uri? uri) ||
                      uri.Scheme != Uri.UriSchemeHttps || uri.Host != "example.com";
        if (!args.Cancel) SetStatus("example.com を読み込んでいます…");
    }

    void OnBrowserNavigationCompleted(CoreWebView2 sender, CoreWebView2NavigationCompletedEventArgs args)
    {
        if (args.WebErrorStatus == CoreWebView2WebErrorStatus.OperationCanceled) return;
        SetStatus(args.IsSuccess ? "example.com を表示中" : $"読み込みに失敗しました。{args.WebErrorStatus}");
    }

    void OnBrowserNewWindowRequested(CoreWebView2 sender, CoreWebView2NewWindowRequestedEventArgs args)
        => args.Handled = true;

    void OnBrowserClosed(object sender, WindowEventArgs args)
    {
        _closed = true;
        if (_browser is not null)
        {
            _browser.NavigationStarting -= OnBrowserNavigationStarting;
            _browser.NavigationCompleted -= OnBrowserNavigationCompleted;
            _browser.NewWindowRequested -= OnBrowserNewWindowRequested;
            _browser = null;
        }

        Browser.Close();
    }
}
