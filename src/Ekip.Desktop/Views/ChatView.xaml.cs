using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Ekip.Shared.Enums;
using Microsoft.Win32;

namespace Ekip.Desktop.Views;

public partial class ChatView : Page
{
    public ObservableCollection<ChatMessageViewModel> Messages { get; } = new();

    public ChatView()
    {
        InitializeComponent();
        MessagesList.ItemsSource = Messages;

        // Load sample messages
        LoadSampleMessages();
    }

    private void LoadSampleMessages()
    {
        Messages.Add(new ChatMessageViewModel
        {
            Content = "Merhaba, toplantı saat kaçta başlıyor?",
            Time = "14:32",
            IsOutgoing = false,
            Status = MessageStatus.Read
        });

        Messages.Add(new ChatMessageViewModel
        {
            Content = "Saat 15:00'te konferans odasında olacağız.",
            Time = "14:35",
            IsOutgoing = true,
            Status = MessageStatus.Read
        });

        Messages.Add(new ChatMessageViewModel
        {
            Content = "Tamam, orada olacağım.",
            Time = "14:36",
            IsOutgoing = false,
            Status = MessageStatus.Read
        });

        Messages.Add(new ChatMessageViewModel
        {
            Content = "Sunumu hazırladın mı?",
            Time = "14:40",
            IsOutgoing = true,
            Status = MessageStatus.Delivered
        });
    }

    private void SendMessage_Click(object sender, RoutedEventArgs e)
    {
        SendMessage();
    }

    private void MessageInput_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter && !Keyboard.Modifiers.HasFlag(ModifierKeys.Shift))
        {
            e.Handled = true;
            SendMessage();
        }
    }

    private void MessageInput_TextChanged(object sender, TextChangedEventArgs e)
    {
        // TODO: Send typing indicator via SignalR
    }

    private void SendMessage()
    {
        var messageText = MessageInput.Text.Trim();
        if (string.IsNullOrEmpty(messageText)) return;

        Messages.Add(new ChatMessageViewModel
        {
            Content = messageText,
            Time = DateTime.Now.ToString("HH:mm"),
            IsOutgoing = true,
            Status = MessageStatus.Sent
        });

        MessageInput.Clear();

        // Scroll to bottom
        if (MessagesScrollViewer.ScrollableHeight > 0)
        {
            MessagesScrollViewer.ScrollToBottom();
        }

        // TODO: Send message via SignalR
    }

    private void AttachFile_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFileDialog
        {
            Title = "Dosya Seç",
            Filter = "Tüm Dosyalar (*.*)|*.*|Resimler (*.jpg;*.png;*.gif)|*.jpg;*.png;*.gif|Belgeler (*.pdf;*.docx;*.xlsx)|*.pdf;*.docx;*.xlsx",
            Multiselect = true
        };

        if (dialog.ShowDialog() == true)
        {
            foreach (var fileName in dialog.FileNames)
            {
                // TODO: Upload file and send as attachment
                Messages.Add(new ChatMessageViewModel
                {
                    Content = $"[Dosya: {System.IO.Path.GetFileName(fileName)}]",
                    Time = DateTime.Now.ToString("HH:mm"),
                    IsOutgoing = true,
                    Status = MessageStatus.Sent
                });
            }
        }
    }

    private async void Screenshot_Click(object sender, RoutedEventArgs e)
    {
        // Minimize window temporarily
        var mainWindow = Application.Current.MainWindow;
        var previousState = mainWindow.WindowState;
        mainWindow.WindowState = WindowState.Minimized;

        await Task.Delay(300); // Wait for window to minimize

        // TODO: Open screenshot capture tool
        // For now, just show a message
        mainWindow.WindowState = previousState;

        MessageBox.Show(
            "Ekran görüntüsü aracı açılacak. Sol tıklayarak seçim yapın.",
            "Ekran Görüntüsü",
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }
}

public class ChatMessageViewModel
{
    public string Content { get; set; } = string.Empty;
    public string Time { get; set; } = string.Empty;
    public bool IsOutgoing { get; set; }
    public MessageStatus Status { get; set; }

    public Visibility IsIncomingVisibility => IsOutgoing ? Visibility.Collapsed : Visibility.Visible;
    public Visibility IsOutgoingVisibility => IsOutgoing ? Visibility.Visible : Visibility.Collapsed;

    public string StatusIcon => Status switch
    {
        MessageStatus.Sent => "\uE73E",      // Checkmark
        MessageStatus.Delivered => "\uE73E", // Checkmark
        MessageStatus.Read => "\uE73E",      // Double checkmark (using same for simplicity)
        _ => ""
    };
}
