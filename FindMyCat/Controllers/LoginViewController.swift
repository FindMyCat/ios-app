import UIKit
import Foundation
import CocoaTextField

class LoginViewController: UIViewController {
    private var usernameTextField: CocoaTextField!
    private var passwordTextField: CocoaTextField!
    private var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view
        view.backgroundColor = .white

        // Create and configure the username text field
        usernameTextField = CocoaTextField()
        usernameTextField.placeholder = "Username"
        usernameTextField.inactiveHintColor = .systemGray3
        usernameTextField.activeHintColor = .black
        usernameTextField.autocapitalizationType = .none
        usernameTextField.focusedBackgroundColor = UIColor(red: 236/255, green: 239/255, blue: 239/255, alpha: 1)
        usernameTextField.defaultBackgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)
        usernameTextField.borderColor = .black
        usernameTextField.errorColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 0.7)
        usernameTextField.borderWidth = 1
        usernameTextField.cornerRadius = 11
        view.addSubview(usernameTextField)

        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.widthAnchor.constraint(equalToConstant: 300),
            usernameTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 80)

        ])

        // Create and configure the password text field
        passwordTextField = CocoaTextField()
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.inactiveHintColor = .systemGray3
        passwordTextField.activeHintColor = .black
        passwordTextField.autocapitalizationType = .none
        passwordTextField.focusedBackgroundColor = UIColor(red: 236/255, green: 239/255, blue: 239/255, alpha: 1)
        passwordTextField.defaultBackgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)
        passwordTextField.borderColor = .black
        passwordTextField.errorColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 0.7)
        passwordTextField.borderWidth = 1
        passwordTextField.cornerRadius = 11
        view.addSubview(passwordTextField)

        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalToConstant: 300),
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 30)

        ])

        // Create and configure the login button
        loginButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.tinted()
        configuration.cornerStyle = .large
        configuration.buttonSize = .large

        view.addSubview(loginButton)
        loginButton.configuration = configuration

        loginButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            loginButton.centerXAnchor.constraint(equalTo: passwordTextField.centerXAnchor)
        ])

        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)

    }

    @objc private func loginButtonTapped() {
        // Handle login button tap
        // You can add your authentication logic here to validate the username and password

        let username = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        TraccarAPIManager.shared.createSession(username: username, password: password) {
            result in
            switch result {
            case .success(let session):
                self.navigateToMainScreen()
            case .failure:
                self.displayErrorMessage()
            }
        }
    }

    private func navigateToMainScreen() {
        // Example code to navigate to the main screen
        let mainScreenViewController = HomeScreenController()
        mainScreenViewController.modalPresentationStyle = .fullScreen
        present(mainScreenViewController, animated: true)
    }

    private func displayErrorMessage() {
        // Example code to display an error message
        let alert = UIAlertController(title: "Login Failed", message: "Invalid username or password", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
