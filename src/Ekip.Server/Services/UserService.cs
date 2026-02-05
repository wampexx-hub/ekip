using Ekip.Server.Data;
using Ekip.Server.Data.Entities;
using Ekip.Shared.DTOs;
using Ekip.Shared.Enums;
using Microsoft.EntityFrameworkCore;

namespace Ekip.Server.Services;

public class UserService : IUserService
{
    private readonly EkipDbContext _context;
    private readonly ILogger<UserService> _logger;

    public UserService(EkipDbContext context, ILogger<UserService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<UserDto?> GetUserAsync(Guid userId)
    {
        var user = await _context.Users.FindAsync(userId);
        return user != null ? MapToDto(user) : null;
    }

    public async Task<UserDto?> GetUserByUsernameAsync(string username)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Username.ToLower() == username.ToLower());
        return user != null ? MapToDto(user) : null;
    }

    public async Task<List<UserDto>> GetUsersAsync()
    {
        return await _context.Users
            .Where(u => u.IsEnabled)
            .OrderBy(u => u.DisplayName)
            .Select(u => MapToDto(u))
            .ToListAsync();
    }

    public async Task<List<UserDto>> SearchUsersAsync(string query)
    {
        var lowerQuery = query.ToLower();
        return await _context.Users
            .Where(u => u.IsEnabled &&
                       (u.DisplayName.ToLower().Contains(lowerQuery) ||
                        u.Username.ToLower().Contains(lowerQuery) ||
                        (u.Email != null && u.Email.ToLower().Contains(lowerQuery)) ||
                        (u.Department != null && u.Department.ToLower().Contains(lowerQuery))))
            .OrderBy(u => u.DisplayName)
            .Take(50)
            .Select(u => MapToDto(u))
            .ToListAsync();
    }

    public async Task<List<DepartmentDto>> GetDepartmentsAsync()
    {
        return await _context.Users
            .Where(u => u.IsEnabled && u.Department != null)
            .GroupBy(u => u.Department!)
            .Select(g => new DepartmentDto
            {
                Name = g.Key,
                UserCount = g.Count(),
                Users = g.Select(u => new ContactDto
                {
                    UserId = u.Id,
                    DisplayName = u.DisplayName,
                    Email = u.Email,
                    Department = u.Department,
                    Title = u.Title,
                    AvatarUrl = u.AvatarUrl,
                    Status = u.Status
                }).ToList()
            })
            .OrderBy(d => d.Name)
            .ToListAsync();
    }

    public async Task<UserDto?> CreateOrUpdateFromAdAsync(string username, string? domain)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Username.ToLower() == username.ToLower());

        if (user == null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                Username = username,
                DisplayName = username,
                Email = $"{username}@{domain ?? "local"}",
                Status = UserStatus.Available,
                CreatedAt = DateTime.UtcNow
            };
            _context.Users.Add(user);
        }

        user.LastLoginAt = DateTime.UtcNow;
        user.Status = UserStatus.Available;

        await _context.SaveChangesAsync();
        return MapToDto(user);
    }

    public async Task<bool> UpdateStatusAsync(Guid userId, UserStatus status)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return false;

        user.Status = status;
        user.LastSeen = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetUserOnlineAsync(Guid userId, bool isOnline)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return false;

        if (!isOnline)
        {
            user.Status = UserStatus.Offline;
        }
        user.LastSeen = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UpdateProfileAsync(Guid userId, UpdateUserProfileDto dto)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return false;

        if (dto.DisplayName != null) user.DisplayName = dto.DisplayName;
        if (dto.AvatarUrl != null) user.AvatarUrl = dto.AvatarUrl;
        if (dto.Status.HasValue) user.Status = dto.Status.Value;

        await _context.SaveChangesAsync();
        return true;
    }

    private static UserDto MapToDto(User user)
    {
        return new UserDto
        {
            Id = user.Id,
            Username = user.Username,
            DisplayName = user.DisplayName,
            Email = user.Email,
            Department = user.Department,
            Title = user.Title,
            AvatarUrl = user.AvatarUrl,
            Status = user.Status,
            Role = user.Role,
            LastSeen = user.LastSeen,
            IsOnline = user.Status != UserStatus.Offline
        };
    }
}
