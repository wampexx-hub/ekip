using System.Windows;
using System.Windows.Controls;

namespace Ekip.Desktop.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        Loaded += MainWindow_Loaded;
    }

    private void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        // Default navigation - Chat view
        NavigateToChat();
    }

    private void NavItem_Checked(object sender, RoutedEventArgs e)
    {
        if (sender is RadioButton radioButton)
        {
            switch (radioButton.Name)
            {
                case "NavChat":
                    NavigateToChat();
                    break;
                case "NavContacts":
                    NavigateToContacts();
                    break;
                case "NavFiles":
                    NavigateToFiles();
                    break;
                case "NavSettings":
                    NavigateToSettings();
                    break;
            }
        }
    }

    private void NavigateToChat()
    {
        ListFrame.Navigate(new ConversationListView());
        ContentFrame.Navigate(new ChatView());
    }

    private void NavigateToContacts()
    {
        ListFrame.Navigate(new ContactListView());
        ContentFrame.Navigate(new ContactDetailView());
    }

    private void NavigateToFiles()
    {
        ListFrame.Navigate(new FileListView());
        ContentFrame.Navigate(new FileDetailView());
    }

    private void NavigateToSettings()
    {
        ListFrame.Content = null;
        ContentFrame.Navigate(new SettingsView());
    }

    private void SearchBox_TextChanged(object sender, TextChangedEventArgs e)
    {
        // TODO: Implement search functionality
    }

    private void ProfileButton_Click(object sender, RoutedEventArgs e)
    {
        // TODO: Show profile popup/dialog
        var profileWindow = new ProfileWindow();
        profileWindow.Owner = this;
        profileWindow.ShowDialog();
    }
}
