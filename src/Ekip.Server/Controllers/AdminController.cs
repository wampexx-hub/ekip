using Ekip.Server.Data;
using Ekip.Server.Services;
using Ekip.Shared.DTOs;
using Ekip.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Ekip.Server.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly EkipDbContext _context;
    private readonly IUserService _userService;
    private readonly ISurveillanceService _surveillanceService;
    private readonly ILogger<AdminController> _logger;

    public AdminController(
        EkipDbContext context,
        IUserService userService,
        ISurveillanceService surveillanceService,
        ILogger<AdminController> logger)
    {
        _context = context;
        _userService = userService;
        _surveillanceService = surveillanceService;
        _logger = logger;
    }

    /// <summary>
    /// Dashboard istatistiklerini getir
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<DashboardStatsDto>>> GetDashboardStats()
    {
        var today = DateTime.UtcNow.Date;

        var stats = new DashboardStatsDto
        {
            TotalUsers = await _context.Users.CountAsync(u => u.IsEnabled),
            ActiveUsers = await _context.Users.CountAsync(u => u.IsEnabled && u.LastLoginAt >= today.AddDays(-7)),
            OnlineUsers = await _context.Users.CountAsync(u => u.Status != UserStatus.Offline),
            TodayMessageCount = await _context.Messages.CountAsync(m => m.SentAt >= today),
            TotalMessageCount = await _context.Messages.CountAsync(),
            TodayFileTransferBytes = await _context.FileAttachments
                .Where(f => f.UploadedAt >= today)
                .SumAsync(f => f.FileSize),
            ActiveSessions = await _context.Sessions.CountAsync(s => s.IsActive),
            LastUpdated = DateTime.UtcNow
        };

        return Ok(ApiResponse<DashboardStatsDto>.Ok(stats));
    }

    /// <summary>
    /// Kullanıcı listesini getir (admin view)
    /// </summary>
    [HttpGet("users")]
    public async Task<ActionResult<ApiResponse<List<AdminUserDto>>>> GetUsers()
    {
        var users = await _context.Users
            .Include(u => u.Sessions)
            .OrderBy(u => u.DisplayName)
            .Select(u => new AdminUserDto
            {
                Id = u.Id,
                Username = u.Username,
                DisplayName = u.DisplayName,
                Email = u.Email,
                Department = u.Department,
                Title = u.Title,
                Role = u.Role,
                Status = u.Status,
                IsEnabled = u.IsEnabled,
                CreatedAt = u.CreatedAt,
                LastLoginAt = u.LastLoginAt,
                ActiveSessionCount = u.Sessions.Count(s => s.IsActive)
            })
            .ToListAsync();

        return Ok(ApiResponse<List<AdminUserDto>>.Ok(users));
    }

    /// <summary>
    /// Kullanıcı rolünü güncelle
    /// </summary>
    [HttpPut("users/{userId}/role")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateUserRole(Guid userId, [FromBody] UpdateUserRoleDto dto)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound(ApiResponse<bool>.Fail("Kullanıcı bulunamadı"));
        }

        user.Role = dto.Role;
        await _context.SaveChangesAsync();

        // Audit log
        await LogAction("UpdateUserRole", "User", userId, $"Role changed to {dto.Role}");

        return Ok(ApiResponse<bool>.Ok(true, "Kullanıcı rolü güncellendi"));
    }

    /// <summary>
    /// Kullanıcıyı aktif/pasif yap
    /// </summary>
    [HttpPut("users/{userId}/status")]
    public async Task<ActionResult<ApiResponse<bool>>> SetUserEnabled(Guid userId, [FromBody] bool isEnabled)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound(ApiResponse<bool>.Fail("Kullanıcı bulunamadı"));
        }

        user.IsEnabled = isEnabled;
        await _context.SaveChangesAsync();

        // Audit log
        await LogAction("SetUserEnabled", "User", userId, $"Enabled: {isEnabled}");

        return Ok(ApiResponse<bool>.Ok(true, isEnabled ? "Kullanıcı aktifleştirildi" : "Kullanıcı devre dışı bırakıldı"));
    }

    /// <summary>
    /// Aktif oturumları getir
    /// </summary>
    [HttpGet("sessions")]
    public async Task<ActionResult<ApiResponse<List<ActiveSessionDto>>>> GetActiveSessions()
    {
        var sessions = await _context.Sessions
            .Include(s => s.User)
            .Where(s => s.IsActive)
            .OrderByDescending(s => s.LastActivityAt)
            .Select(s => new ActiveSessionDto
            {
                SessionId = s.Id,
                UserId = s.UserId,
                Username = s.User.Username,
                DisplayName = s.User.DisplayName,
                DeviceName = s.DeviceName,
                IpAddress = s.IpAddress,
                StartedAt = s.CreatedAt,
                LastActivityAt = s.LastActivityAt
            })
            .ToListAsync();

        return Ok(ApiResponse<List<ActiveSessionDto>>.Ok(sessions));
    }

    /// <summary>
    /// Oturumu sonlandır
    /// </summary>
    [HttpDelete("sessions/{sessionId}")]
    public async Task<ActionResult<ApiResponse<bool>>> TerminateSession(Guid sessionId)
    {
        var session = await _context.Sessions.FindAsync(sessionId);
        if (session == null)
        {
            return NotFound(ApiResponse<bool>.Fail("Oturum bulunamadı"));
        }

        session.IsActive = false;
        await _context.SaveChangesAsync();

        // Audit log
        await LogAction("TerminateSession", "Session", sessionId, $"Session terminated for user {session.UserId}");

        return Ok(ApiResponse<bool>.Ok(true, "Oturum sonlandırıldı"));
    }

    /// <summary>
    /// Surveillance yapılandırmalarını getir
    /// </summary>
    [HttpGet("surveillance")]
    public async Task<ActionResult<ApiResponse<List<SurveillanceConfigDto>>>> GetSurveillanceConfigs()
    {
        var configs = await _surveillanceService.GetConfigsAsync();
        return Ok(ApiResponse<List<SurveillanceConfigDto>>.Ok(configs));
    }

    /// <summary>
    /// Surveillance yapılandırması kaydet
    /// </summary>
    [HttpPost("surveillance")]
    public async Task<ActionResult<ApiResponse<SurveillanceConfigDto>>> SaveSurveillanceConfig(
        [FromBody] SaveSurveillanceConfigDto dto)
    {
        var config = await _surveillanceService.SaveConfigAsync(dto);
        if (config == null)
        {
            return BadRequest(ApiResponse<SurveillanceConfigDto>.Fail("Yapılandırma kaydedilemedi"));
        }

        // Audit log
        await LogAction("SaveSurveillanceConfig", "SurveillanceConfig", config.Id, $"Config saved: {dto.Name}");

        return Ok(ApiResponse<SurveillanceConfigDto>.Ok(config, "Yapılandırma kaydedildi"));
    }

    /// <summary>
    /// Surveillance webhook'unu test et
    /// </summary>
    [HttpPost("surveillance/{configId}/test")]
    public async Task<ActionResult<ApiResponse<bool>>> TestSurveillanceWebhook(Guid configId)
    {
        var result = await _surveillanceService.TestWebhookAsync(configId);
        if (!result)
        {
            return BadRequest(ApiResponse<bool>.Fail("Webhook testi başarısız"));
        }
        return Ok(ApiResponse<bool>.Ok(true, "Webhook testi başarılı"));
    }

    /// <summary>
    /// Audit logları getir
    /// </summary>
    [HttpGet("audit-logs")]
    public async Task<ActionResult<ApiResponse<PagedResponse<AuditLogDto>>>> GetAuditLogs(
        [FromQuery] PaginationParams pagination)
    {
        var query = _context.AuditLogs
            .OrderByDescending(a => a.Timestamp);

        var totalCount = await query.CountAsync();
        var items = await query
            .Skip((pagination.PageNumber - 1) * pagination.PageSize)
            .Take(pagination.PageSize)
            .Select(a => new AuditLogDto
            {
                Id = a.Id,
                Timestamp = a.Timestamp,
                UserId = a.UserId,
                Username = a.Username,
                Action = a.Action,
                EntityType = a.EntityType,
                EntityId = a.EntityId,
                Details = a.NewValues,
                IpAddress = a.IpAddress
            })
            .ToListAsync();

        var response = new PagedResponse<AuditLogDto>
        {
            Items = items,
            TotalCount = totalCount,
            PageNumber = pagination.PageNumber,
            PageSize = pagination.PageSize
        };

        return Ok(ApiResponse<PagedResponse<AuditLogDto>>.Ok(response));
    }

    private async Task LogAction(string action, string entityType, Guid? entityId, string? details)
    {
        var userIdClaim = User.FindFirst("sub")?.Value;
        Guid.TryParse(userIdClaim, out var userId);

        var log = new Data.Entities.AuditLog
        {
            Id = Guid.NewGuid(),
            Timestamp = DateTime.UtcNow,
            UserId = userId != Guid.Empty ? userId : null,
            Username = User.Identity?.Name,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            NewValues = details,
            IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString()
        };

        _context.AuditLogs.Add(log);
        await _context.SaveChangesAsync();
    }
}
