using Ekip.Desktop.Services;
using Ekip.Desktop.ViewModels;
using Microsoft.Extensions.DependencyInjection;
using System.Windows;

namespace Ekip.Desktop;

public partial class App : Application
{
    public static IServiceProvider Services { get; private set; } = null!;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        var services = new ServiceCollection();
        ConfigureServices(services);
        Services = services.BuildServiceProvider();

        // Sistem temasını algıla ve uygula
        ThemeService.Instance.ApplySystemTheme();
    }

    private void ConfigureServices(IServiceCollection services)
    {
        // HTTP Client
        services.AddHttpClient<IApiClient, ApiClient>(client =>
        {
            client.BaseAddress = new Uri("https://localhost:5001");
        });

        // Services
        services.AddSingleton<IThemeService, ThemeService>();
        services.AddSingleton<ISignalRService, SignalRService>();
        services.AddSingleton<IAuthenticationService, AuthenticationService>();
        services.AddSingleton<IScreenshotService, ScreenshotService>();

        // ViewModels
        services.AddTransient<MainViewModel>();
        services.AddTransient<LoginViewModel>();
        services.AddTransient<ChatViewModel>();
        services.AddTransient<ContactsViewModel>();
        services.AddTransient<SettingsViewModel>();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        // Cleanup
        if (Services is IDisposable disposable)
        {
            disposable.Dispose();
        }
        base.OnExit(e);
    }
}
