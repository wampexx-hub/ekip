using Ekip.Server.Data;
using Ekip.Server.Hubs;
using Ekip.Server.Services;
using Microsoft.AspNetCore.Authentication.Negotiate;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Ekip Messenger API",
        Version = "v1",
        Description = "Kurumsal mesajlaşma uygulaması API'si"
    });
});

// Database
builder.Services.AddDbContext<EkipDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("PostgreSQL")
        ?? "Host=localhost;Database=ekip;Username=postgres;Password=postgres";
    options.UseNpgsql(connectionString);
});

// Authentication - Windows Negotiate (Kerberos/NTLM)
builder.Services.AddAuthentication(NegotiateDefaults.AuthenticationScheme)
    .AddNegotiate();

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
});

// SignalR
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = builder.Environment.IsDevelopment();
    options.MaximumReceiveMessageSize = 1024 * 1024; // 1 MB
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("EkipCors", policy =>
    {
        policy.WithOrigins(
                builder.Configuration.GetSection("Cors:Origins").Get<string[]>()
                ?? new[] { "http://localhost:5000" })
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });
});

// HTTP Client Factory (for webhooks)
builder.Services.AddHttpClient();

// Application Services
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IMessageService, MessageService>();
builder.Services.AddScoped<IConversationService, ConversationService>();
builder.Services.AddScoped<IContactService, ContactService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IFileService, FileService>();
builder.Services.AddScoped<ISurveillanceService, SurveillanceService>();
builder.Services.AddSingleton<IConnectionManager, ConnectionManager>();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Ekip Messenger API v1");
    });
}

app.UseHttpsRedirection();
app.UseCors("EkipCors");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<MessageHub>("/hubs/message");

// Ensure database is created
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<EkipDbContext>();
    await context.Database.EnsureCreatedAsync();
}

app.Run();
