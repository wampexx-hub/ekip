using Ekip.Shared.DTOs;
using System.Security.Principal;

namespace Ekip.Desktop.Services;

public interface IAuthenticationService
{
    UserDto? CurrentUser { get; }
    string? Token { get; }
    bool IsAuthenticated { get; }

    Task<AuthResultDto> LoginWithWindowsAsync();
    Task<bool> RefreshTokenAsync();
    Task LogoutAsync();
}

public class AuthenticationService : IAuthenticationService
{
    private readonly IApiClient _apiClient;
    private string? _refreshToken;

    public UserDto? CurrentUser { get; private set; }
    public string? Token { get; private set; }
    public bool IsAuthenticated => !string.IsNullOrEmpty(Token) && CurrentUser != null;

    public AuthenticationService(IApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task<AuthResultDto> LoginWithWindowsAsync()
    {
        try
        {
            // Get Windows identity
            var identity = WindowsIdentity.GetCurrent();
            var username = identity.Name;

            var parts = username.Split('\\');
            var domain = parts.Length > 1 ? parts[0] : null;
            var user = parts.Length > 1 ? parts[1] : parts[0];

            var loginDto = new WindowsLoginDto
            {
                Username = user,
                Domain = domain
            };

            var response = await _apiClient.PostAsync<ApiResponse<AuthResultDto>>("api/auth/login", loginDto);

            if (response?.Success == true && response.Data?.Success == true)
            {
                Token = response.Data.Token;
                _refreshToken = response.Data.RefreshToken;
                CurrentUser = response.Data.User;

                _apiClient.SetAuthToken(Token!);

                return response.Data;
            }

            return new AuthResultDto
            {
                Success = false,
                ErrorMessage = response?.Data?.ErrorMessage ?? "Giriş başarısız"
            };
        }
        catch (Exception ex)
        {
            return new AuthResultDto
            {
                Success = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public async Task<bool> RefreshTokenAsync()
    {
        if (string.IsNullOrEmpty(_refreshToken)) return false;

        try
        {
            var dto = new RefreshTokenDto { RefreshToken = _refreshToken };
            var response = await _apiClient.PostAsync<ApiResponse<AuthResultDto>>("api/auth/refresh", dto);

            if (response?.Success == true && response.Data?.Success == true)
            {
                Token = response.Data.Token;
                _refreshToken = response.Data.RefreshToken;
                CurrentUser = response.Data.User;

                _apiClient.SetAuthToken(Token!);
                return true;
            }

            return false;
        }
        catch
        {
            return false;
        }
    }

    public async Task LogoutAsync()
    {
        try
        {
            await _apiClient.PostAsync<ApiResponse<bool>>("api/auth/logout", null);
        }
        finally
        {
            Token = null;
            _refreshToken = null;
            CurrentUser = null;
            _apiClient.SetAuthToken(null!);
        }
    }
}
