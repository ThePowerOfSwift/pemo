//
//  PemoLoginViewController.swift
//  PEMO
//
//  Created by Jaeseong on 2017. 10. 23..
//  Copyright © 2017년 Jaeseong. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Toaster
import LocalAuthentication

class PemoLoginViewController: UIViewController {
    
    var user: User = User()
    // MARK: - @IB
    //
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var loginFacebookButton: UIButton!
    
    @IBAction func login(_ sender: UIButton) {
        print("로그인")
        self.emailTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        
        if self.emailCheck(withEmail: self.emailTextField.text!) == false || self.emailTextField.text == "" {
            Toast(text: "Email을 확인해주세요").show()
        } else if (self.passwordTextField.text?.count)! < 8 || self.passwordTextField.text == "" {
            Toast(text: "password는 8자 이상입니다").show()
        }
        guard let email = self.emailTextField.text, let password = self.passwordTextField.text else { return }
        self.loginWihtAlamo(email: email, password: password, success:  {
            let sync = DataSync()
            DispatchQueue.main.async {
                print("다운로드")
                sync.memoDownload()
            }
            DispatchQueue.main.async {
                print("업로드")
                sync.memoUpload()
            }
        })
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
    }
    // MARK: - 이메일정규식
    //
    func emailCheck(withEmail: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: withEmail)
    }
    @IBAction func loginFacebook(_ sender: UIButton) {
        
    }
    @IBAction func createAnAccount(_ sender: UIButton) {
        guard let nextViewController = self.storyboard?.instantiateViewController(withIdentifier: "JOIN") as? PemoJoinViewController else { return }
        emailTextField.text = ""
        passwordTextField.text = ""
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.uiCustom()
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        //        navigationController?.navigationBar.isHidden = true
        let tokenValue = TokenAuth()
        print(" 뷰디드로드",tokenValue.load(serviceName, account: "accessToken"))
        print(" 뷰디드로드",tokenValue.load(serviceName, account: "id"))
        
    }
    override func viewWillAppear(_ animated: Bool) {
        self.emailTextField.becomeFirstResponder()
    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
}

// MARK: - UITextFieldDelegate
//
extension PemoLoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.isEqual(self.emailTextField)) {
            self.passwordTextField.becomeFirstResponder()
        } else if (textField.isEqual(self.passwordTextField)) {
            self.login(loginButton)
        }
        return true
    }
}
// MARK: - 서버통신 (Alamofire)
//
extension PemoLoginViewController {
    func loginWihtAlamo(email: String, password: String, success: (()->Void)? = nil) {
        print("로그인 알라모파이어")
        let url = mainDomain + "user/login/"
        let parameters: Parameters = ["username":email, "password":password]
        let call = Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil)
        call.validate().responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print(json)
                //                if !(json["detail"].stringValue.isEmpty) {
                //                    Toast(text: "이메일 혹은 비밀번호를 확인해 주세요").show()
                //                } else {
                self.user = DataManager.shared.userList(response: json["user"])
                let accessToken = json["token"].stringValue
                let id = json["user"]["id"].stringValue
                // KeyChain에 Token, id 저장
                let tokenValue = TokenAuth()
                tokenValue.save(serviceName, account: "accessToken", value: accessToken)
                tokenValue.save(serviceName, account: "id", value: id)
                //                print(tokenValue.load(serviceName, account: "accessToken"))
                //                print(tokenValue.load(serviceName, account: "id"))
                
//                success?()
                guard let nextViewController = self.storyboard?.instantiateViewController(withIdentifier: "NAVIMAIN") else { return }
                
                self.present(nextViewController, animated: true, completion: {
                  success?()
                })
                    
                //                }
                
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            case .failure(let error):
                print(error)
                Toast(text: "이메일 혹은 비밀번호를 확인해주세요").show()
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
}
// MARK: - UI
//
extension PemoLoginViewController {
    func uiCustom() {
        emailTextField.becomeFirstResponder()
        emailTextField.setBottomBorder()
        passwordTextField.setBottomBorder()
        loginButton.layer.cornerRadius = 10
        loginButton.layer.masksToBounds = true
        loginFacebookButton.layer.cornerRadius = 10
        loginFacebookButton.layer.masksToBounds = true
    }
}
