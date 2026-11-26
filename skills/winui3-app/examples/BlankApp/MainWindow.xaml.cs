using System;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Windows.Graphics;
using WinRT.Interop;

namespace BlankApp;

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
        SetStatus("準備完了");
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
