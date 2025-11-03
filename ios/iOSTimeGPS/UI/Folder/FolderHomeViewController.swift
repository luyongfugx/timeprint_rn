import UIKit

class FolderHomeViewController: UIViewController {
    

    // Use lazy var to create the tabBarController
    lazy var tBarController: UITabBarController = {
        let tabBController = UITabBarController()
        tabBController.tabBar.backgroundColor = .black
        tabBController.tabBar.barTintColor = .white // Set background color to black
       // tabBController.tabBar.isTranslucent = false // Make it opaque
        
        // First tab for FolderViewController
        let folderVC = FolderViewController() // Your existing FolderViewController
        folderVC.tabBarItem = UITabBarItem(title: "k_folder_name".localized(), image: UIImage(systemName: "folder"), tag: 0)
        
    
        // Second tab for CalendarViewController
        let calendarVC = CalendarViewController() // Create this class as shown earlier
        calendarVC.tabBarItem = UITabBarItem(title: "k_calendar_name".localized(), image: UIImage(systemName: "calendar"), tag: 1)
        
        tabBController.viewControllers = [folderVC, calendarVC]
        return tabBController
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }
    
    private func setupTabBar() {
        addChild(tBarController)
        view.addSubview(tBarController.view)
        tBarController.didMove(toParent: self)
        tBarController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    
}
