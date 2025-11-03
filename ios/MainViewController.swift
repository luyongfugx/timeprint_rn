import React
import ReactAppDependencyProvider
import React_RCTAppDelegate
import UIKit

class MainViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private var reactNativeFactory: RCTReactNativeFactory?

    init(reactNativeFactory: RCTReactNativeFactory) {
        self.reactNativeFactory = reactNativeFactory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white  // 或者其他深色

        let button = UIButton(type: .system)
        button.setTitle("打开 TimePrint", for: .normal)
        button.addTarget(self, action: #selector(openReactNative), for: .touchUpInside)

        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc private func openReactNative() {
        let app = UIApplication.shared.delegate as! AppDelegate
        guard let factory = reactNativeFactory else { return }
        let window = UIApplication.shared.windows.first
        app.savedNativeVC = window?.rootViewController

         factory.startReactNative(
             withModuleName: "timeprint_rn",
             in: window,
             launchOptions: nil
         )
    }
}
