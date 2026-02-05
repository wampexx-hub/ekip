using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Ekip.Desktop.Services;

namespace Ekip.Desktop.ViewModels;

public partial class LoginViewModel : ObservableObject
{
    private readonly IAuthenticationService _authService;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private string _statusMessage = "Windows kimlik bilgileri ile giriş yapılıyor...";

    public LoginViewModel(IAuthenticationService authService)
    {
        _authService = authService;
    }

    [RelayCommand]
    private async Task LoginAsync()
    {
        IsLoading = true;
        ErrorMessage = null;
        StatusMessage = "Giriş yapılıyor...";

        try
        {
            var result = await _authService.LoginWithWindowsAsync();

            if (result.Success)
            {
                StatusMessage = "Giriş başarılı!";
                // Navigate to main window
            }
            else
            {
                ErrorMessage = result.ErrorMessage ?? "Giriş başarısız";
                StatusMessage = "Tekrar deneyin";
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            StatusMessage = "Bağlantı hatası";
        }
        finally
        {
            IsLoading = false;
        }
    }
}
