using System.Windows.Controls;
using Ekip.Desktop.Services;

namespace Ekip.Desktop.Views;

public partial class SettingsView : Page
{
    public SettingsView()
    {
        InitializeComponent();
    }

    private void ThemeComboBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ThemeComboBox.SelectedItem is ComboBoxItem item)
        {
            var theme = item.Content.ToString() switch
            {
                "Açık" => ThemeMode.Light,
                "Koyu" => ThemeMode.Dark,
                _ => ThemeMode.System
            };

            ThemeService.Instance.SetTheme(theme);
        }
    }
}
