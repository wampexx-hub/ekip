using Ekip.AdminDashboard.Services;
using Ekip.Server.Data;
using Microsoft.AspNetCore.Authentication.Negotiate;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();

// Database
builder.Services.AddDbContext<EkipDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("PostgreSQL")
        ?? "Host=localhost;Database=ekip;Username=postgres;Password=postgres";
    options.UseNpgsql(connectionString);
});

// Authentication
builder.Services.AddAuthentication(NegotiateDefaults.AuthenticationScheme)
    .AddNegotiate();

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin", "Administrators", "Domain Admins"));
    options.FallbackPolicy = options.DefaultPolicy;
});

// Services
builder.Services.AddScoped<DashboardService>();
builder.Services.AddScoped<UserManagementService>();
builder.Services.AddScoped<StatisticsService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();
