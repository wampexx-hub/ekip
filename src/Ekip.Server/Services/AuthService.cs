using Ekip.Server.Data;
using Ekip.Server.Data.Entities;
using Ekip.Shared.DTOs;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace Ekip.Server.Services;

public class AuthService : IAuthService
{
    private readonly EkipDbContext _context;
    private readonly IUserService _userService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        EkipDbContext context,
        IUserService userService,
        IConfiguration configuration,
        ILogger<AuthService> logger)
    {
        _context = context;
        _userService = userService;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<AuthResultDto> AuthenticateWithWindowsAsync(string username, string? domain)
    {
        try
        {
            // Kullanıcıyı AD'den oluştur veya güncelle
            var user = await _userService.CreateOrUpdateFromAdAsync(username, domain);
            if (user == null)
            {
                return new AuthResultDto
                {
                    Success = false,
                    ErrorMessage = "Kullanıcı oluşturulamadı"
                };
            }

            // Token oluştur
            var token = GenerateToken();
            var refreshToken = GenerateToken();
            var expiresAt = DateTime.UtcNow.AddHours(24);

            // Oturum kaydet
            var session = new Session
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Token = token,
                RefreshToken = refreshToken,
                DeviceName = Environment.MachineName,
                IpAddress = "127.0.0.1",
                CreatedAt = DateTime.UtcNow,
                LastActivityAt = DateTime.UtcNow,
                ExpiresAt = expiresAt,
                IsActive = true
            };

            _context.Sessions.Add(session);
            await _context.SaveChangesAsync();

            return new AuthResultDto
            {
                Success = true,
                Token = token,
                RefreshToken = refreshToken,
                ExpiresAt = expiresAt,
                User = user
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Authentication failed for user {Username}", username);
            return new AuthResultDto
            {
                Success = false,
                ErrorMessage = "Kimlik doğrulama başarısız"
            };
        }
    }

    public async Task<AuthResultDto> RefreshTokenAsync(string refreshToken)
    {
        var session = await _context.Sessions
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.RefreshToken == refreshToken && s.IsActive);

        if (session == null || session.ExpiresAt < DateTime.UtcNow)
        {
            return new AuthResultDto
            {
                Success = false,
                ErrorMessage = "Geçersiz veya süresi dolmuş token"
            };
        }

        // Yeni token oluştur
        var newToken = GenerateToken();
        var newRefreshToken = GenerateToken();
        var newExpiresAt = DateTime.UtcNow.AddHours(24);

        session.Token = newToken;
        session.RefreshToken = newRefreshToken;
        session.ExpiresAt = newExpiresAt;
        session.LastActivityAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var userDto = new UserDto
        {
            Id = session.User.Id,
            Username = session.User.Username,
            DisplayName = session.User.DisplayName,
            Email = session.User.Email,
            Department = session.User.Department,
            Title = session.User.Title,
            AvatarUrl = session.User.AvatarUrl,
            Status = session.User.Status,
            Role = session.User.Role
        };

        return new AuthResultDto
        {
            Success = true,
            Token = newToken,
            RefreshToken = newRefreshToken,
            ExpiresAt = newExpiresAt,
            User = userDto
        };
    }

    public async Task<bool> RevokeSessionAsync(Guid sessionId)
    {
        var session = await _context.Sessions.FindAsync(sessionId);
        if (session == null) return false;

        session.IsActive = false;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<List<SessionDto>> GetUserSessionsAsync(Guid userId)
    {
        return await _context.Sessions
            .Where(s => s.UserId == userId && s.IsActive)
            .OrderByDescending(s => s.LastActivityAt)
            .Select(s => new SessionDto
            {
                Id = s.Id,
                UserId = s.UserId,
                DeviceName = s.DeviceName,
                IpAddress = s.IpAddress,
                CreatedAt = s.CreatedAt,
                LastActivityAt = s.LastActivityAt
            })
            .ToListAsync();
    }

    private static string GenerateToken()
    {
        var randomBytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }
}
