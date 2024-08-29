//
//  ViewController.swift
//  ssl-pinning-demo
//
//  Created by Abhishek Ravi on 29/12/22.
//

import UIKit

class ViewController: UIViewController {

    private let GET_API = URL(string: "https://run.mocky.io/v3/51686d79-6336-413d-86bb-1826960ceba1")!
    
    //TODO: Change as per your convience
    private lazy var apiClient: APIClient = {
//        return AlmofireAPIClient(sslPinningEnabled: false)
        return URLSessionAPIClient()
        
    }()
    
    private lazy var apiClientAlamo: APIClient = {
        return AlmofireAPIClient(sslPinningEnabled: false)
    }()
    
    private lazy var apiClientURLPublicKey: APIClient = {
        return URLSessionAPIClientPublicKey()
    }()
    
    private lazy var apiClientAlamoPublicKey: APIClient = {
        return AlmofireAPIClientPublicKeys(sslPinningEnabled: true)
    }()
    
    private lazy var apiClientHardcode: APIClient = {
        return AlamofirePublickKeyHardcodeAPIClient(sslPinningEnabled: true)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeRequestHardcodeAlamo()
        makeRequestAlamoPublicKey()
//        makeRequestURLPublicKey()
//        makeRequestAlamo()
        makeRequest()
    }
    
    func  makeRequestHardcodeAlamo() {
        apiClientAlamoPublicKey.dataRequest(GET_API) { result in
            switch result {
            case .success(let data):
                print("Alamo Hardcode Public Success: \(data)")
            case .failure(let error):
                print("Alamo Hardcode Public Failure: \(error)")
            }
        }
    }
    
    func  makeRequestAlamoPublicKey() {
        apiClientAlamoPublicKey.dataRequest(GET_API) { result in
            switch result {
            case .success(let data):
                print("Alamo Public Success: \(data)")
            case .failure(let error):
                print("Alamo Public Failure: \(error)")
            }
        }
    }
    
    func makeRequestURLPublicKey() {
        apiClientURLPublicKey.dataRequest(GET_API) { result in
            switch result {
            case .success(let data):
                print("Public Success: \(data)")
            case .failure(let error):
                print("Public Failure: \(error)")
            }
        }
    }
    
    func makeRequestAlamo() {
        apiClientAlamo.dataRequest(GET_API) { result in
            switch result {
            case .success(let data):
                print("Alamo Success: \(data)")
            case .failure(let error):
                print("Alamo Failure: \(error)")
            }
        }
    }

    func makeRequest() {
        apiClient.dataRequest(GET_API) { result in
            switch result {
            case .success(let data):
                print("Success: \(data)")
            case .failure(let error):
                print("Failure: \(error)")
            }
        }
    }

}

