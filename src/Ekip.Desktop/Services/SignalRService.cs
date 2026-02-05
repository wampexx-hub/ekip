using Ekip.Shared.DTOs;
using Ekip.Shared.Enums;
using Ekip.Shared.Models;
using Microsoft.AspNetCore.SignalR.Client;

namespace Ekip.Desktop.Services;

public interface ISignalRService
{
    bool IsConnected { get; }
    event Action<MessageDto>? MessageReceived;
    event Action<Guid, MessageStatus, DateTime?>? MessageStatusUpdated;
    event Action<Guid, UserStatus>? UserStatusChanged;
    event Action<TypingIndicatorDto>? UserTyping;
    event Action<ConversationDto>? ConversationCreated;
    event Action<Guid>? UserOnline;
    event Action<Guid>? UserOffline;

    Task ConnectAsync(string token);
    Task DisconnectAsync();
    Task SendMessageAsync(SendMessageDto message);
    Task MarkAsReadAsync(Guid conversationId, Guid messageId);
    Task SetTypingAsync(Guid conversationId, bool isTyping);
    Task UpdateStatusAsync(UserStatus status);
    Task JoinConversationAsync(Guid conversationId);
    Task LeaveConversationAsync(Guid conversationId);
}

public class SignalRService : ISignalRService, IAsyncDisposable
{
    private HubConnection? _connection;
    private readonly string _hubUrl;

    public bool IsConnected => _connection?.State == HubConnectionState.Connected;

    public event Action<MessageDto>? MessageReceived;
    public event Action<Guid, MessageStatus, DateTime?>? MessageStatusUpdated;
    public event Action<Guid, UserStatus>? UserStatusChanged;
    public event Action<TypingIndicatorDto>? UserTyping;
    public event Action<ConversationDto>? ConversationCreated;
    public event Action<Guid>? UserOnline;
    public event Action<Guid>? UserOffline;

    public SignalRService(IConfiguration? configuration = null)
    {
        _hubUrl = configuration?["Api:BaseUrl"] ?? "https://localhost:5001";
    }

    public async Task ConnectAsync(string token)
    {
        if (_connection != null)
        {
            await DisconnectAsync();
        }

        _connection = new HubConnectionBuilder()
            .WithUrl($"{_hubUrl}{SignalRConstants.HubPath}", options =>
            {
                options.AccessTokenProvider = () => Task.FromResult<string?>(token);
            })
            .WithAutomaticReconnect()
            .Build();

        RegisterHandlers();

        await _connection.StartAsync();
    }

    public async Task DisconnectAsync()
    {
        if (_connection != null)
        {
            await _connection.StopAsync();
            await _connection.DisposeAsync();
            _connection = null;
        }
    }

    private void RegisterHandlers()
    {
        if (_connection == null) return;

        _connection.On<MessageDto>(SignalRConstants.Methods.ReceiveMessage, message =>
        {
            MessageReceived?.Invoke(message);
        });

        _connection.On<Guid, MessageStatus, DateTime?>(SignalRConstants.Methods.MessageStatusUpdated,
            (messageId, status, timestamp) =>
            {
                MessageStatusUpdated?.Invoke(messageId, status, timestamp);
            });

        _connection.On<Guid, UserStatus>(SignalRConstants.Methods.UserStatusChanged, (userId, status) =>
        {
            UserStatusChanged?.Invoke(userId, status);
        });

        _connection.On<TypingIndicatorDto>(SignalRConstants.Methods.UserTyping, indicator =>
        {
            UserTyping?.Invoke(indicator);
        });

        _connection.On<ConversationDto>(SignalRConstants.Methods.ConversationCreated, conversation =>
        {
            ConversationCreated?.Invoke(conversation);
        });

        _connection.On<Guid>(SignalRConstants.Methods.UserOnline, userId =>
        {
            UserOnline?.Invoke(userId);
        });

        _connection.On<Guid>(SignalRConstants.Methods.UserOffline, userId =>
        {
            UserOffline?.Invoke(userId);
        });
    }

    public async Task SendMessageAsync(SendMessageDto message)
    {
        if (_connection == null || !IsConnected) return;
        await _connection.InvokeAsync(SignalRConstants.Methods.SendMessage, message);
    }

    public async Task MarkAsReadAsync(Guid conversationId, Guid messageId)
    {
        if (_connection == null || !IsConnected) return;
        await _connection.InvokeAsync(SignalRConstants.Methods.MarkAsRead, conversationId, messageId);
    }

    public async Task SetTypingAsync(Guid conversationId, bool isTyping)
    {
        if (_connection == null || !IsConnected) return;
        await _connection.InvokeAsync(SignalRConstants.Methods.SetTyping, conversationId, isTyping);
    }

    public async Task UpdateStatusAsync(UserStatus status)
    {
        if (_connection == null || !IsConnected) return;
        await _connection.InvokeAsync(SignalRConstants.Methods.UpdateStatus, status);
    }

    public async Task JoinConversationAsync(Guid conversationId)
    {
        if (_connection == null || !IsConnected) return;
        await _connection.InvokeAsync(SignalRConstants.Methods.JoinConversation, conversationId);
    }

    public async Task LeaveConversationAsync(Guid conversationId)
    {
        if (_connection == null || !IsConnected) return;
        await _connection.InvokeAsync(SignalRConstants.Methods.LeaveConversation, conversationId);
    }

    public async ValueTask DisposeAsync()
    {
        await DisconnectAsync();
    }
}
