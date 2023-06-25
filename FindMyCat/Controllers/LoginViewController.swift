import UIKit
import Foundation

class LoginViewController: UIViewController {
    private var usernameTextField: UITextField!
    private var passwordTextField: UITextField!
    private var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.backgroundColor = .white
        
        // Create and configure the username text field
        usernameTextField = UITextField(frame: CGRect(x: 50, y: 100, width: 200, height: 30))
        usernameTextField.placeholder = "Username"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.autocapitalizationType = .none
        view.addSubview(usernameTextField)
        
        // Create and configure the password text field
        passwordTextField = UITextField(frame: CGRect(x: 50, y: 150, width: 200, height: 30))
        passwordTextField.placeholder = "Password"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        view.addSubview(passwordTextField)
        
        // Create and configure the login button
        loginButton = UIButton(type: .system)
        loginButton.frame = CGRect(x: 50, y: 200, width: 200, height: 30)
        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        view.addSubview(loginButton)
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
                debugPrint(session)
                self.navigateToMainScreen()
            case .failure(_):
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
