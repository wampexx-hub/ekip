using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using Ekip.Shared.Enums;

namespace Ekip.Desktop.Views;

public partial class ConversationListView : Page
{
    public ObservableCollection<ConversationItemViewModel> Conversations { get; } = new();

    public ConversationListView()
    {
        InitializeComponent();
        DataContext = this;
        ConversationList.ItemsSource = Conversations;

        // Load sample data
        LoadSampleData();
    }

    private void LoadSampleData()
    {
        Conversations.Add(new ConversationItemViewModel
        {
            Id = Guid.NewGuid(),
            Name = "Proje Ekibi",
            LastMessage = "Toplantı yarın saat 10:00'da",
            LastMessageTime = "14:32",
            UnreadCount = 3,
            Status = UserStatus.Available,
            IsGroup = true
        });

        Conversations.Add(new ConversationItemViewModel
        {
            Id = Guid.NewGuid(),
            Name = "Ahmet Yılmaz",
            LastMessage = "Tamam, kontrol ediyorum",
            LastMessageTime = "13:45",
            UnreadCount = 0,
            Status = UserStatus.Available
        });

        Conversations.Add(new ConversationItemViewModel
        {
            Id = Guid.NewGuid(),
            Name = "Ayşe Kaya",
            LastMessage = "Dosyaları gönderdim",
            LastMessageTime = "11:20",
            UnreadCount = 1,
            Status = UserStatus.Busy
        });

        Conversations.Add(new ConversationItemViewModel
        {
            Id = Guid.NewGuid(),
            Name = "IT Destek",
            LastMessage = "Sorun çözüldü, teşekkürler",
            LastMessageTime = "Dün",
            UnreadCount = 0,
            Status = UserStatus.Away,
            IsGroup = true
        });
    }

    private void NewConversation_Click(object sender, RoutedEventArgs e)
    {
        // TODO: Open new conversation dialog
    }

    private void ConversationList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ConversationList.SelectedItem is ConversationItemViewModel conversation)
        {
            // TODO: Navigate to chat view with selected conversation
        }
    }
}

public class ConversationItemViewModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string LastMessage { get; set; } = string.Empty;
    public string LastMessageTime { get; set; } = string.Empty;
    public int UnreadCount { get; set; }
    public UserStatus Status { get; set; }
    public bool IsGroup { get; set; }

    public string Initials => IsGroup ? "#" : (Name.Length > 0 ? Name[0].ToString().ToUpper() : "?");
    public Visibility UnreadVisibility => UnreadCount > 0 ? Visibility.Visible : Visibility.Collapsed;
    public Visibility ShowStatus => IsGroup ? Visibility.Collapsed : Visibility.Visible;

    public System.Windows.Media.Brush StatusBrush => Status switch
    {
        UserStatus.Available => Application.Current.FindResource("StatusAvailableBrush") as System.Windows.Media.Brush,
        UserStatus.Busy => Application.Current.FindResource("StatusBusyBrush") as System.Windows.Media.Brush,
        UserStatus.Away => Application.Current.FindResource("StatusAwayBrush") as System.Windows.Media.Brush,
        _ => Application.Current.FindResource("StatusOfflineBrush") as System.Windows.Media.Brush
    } ?? System.Windows.Media.Brushes.Gray;
}
