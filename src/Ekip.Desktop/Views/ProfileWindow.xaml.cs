using System.Windows;

namespace Ekip.Desktop.Views;

public partial class ProfileWindow : Window
{
    public ProfileWindow()
    {
        InitializeComponent();
        LoadUserInfo();
    }

    private void LoadUserInfo()
    {
        // TODO: Load actual user info from service
        UserName.Text = Environment.UserName;
        UserTitle.Text = "Yazılım Geliştirici";
        UserDepartment.Text = "IT Departmanı";
    }

    private void Logout_Click(object sender, RoutedEventArgs e)
    {
        var result = MessageBox.Show(
            "Çıkış yapmak istediğinize emin misiniz?",
            "Çıkış",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (result == MessageBoxResult.Yes)
        {
            // TODO: Logout via auth service
            Application.Current.Shutdown();
        }
    }
}
