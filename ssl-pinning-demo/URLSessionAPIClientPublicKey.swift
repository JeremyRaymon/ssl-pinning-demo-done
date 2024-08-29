//
//  URLSessionAPIClientPublicKey.swift
//  ssl-pinning-demo
//
//  Created by Jeremy Raymond on 26/08/24.
//

import Foundation

class URLSessionAPIClientPublicKey: NSObject, APIClient {
    
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    // Public key data stored as `SecKey`
    private let publicKey: SecKey = {
        let url = Bundle.main.url(forResource: "run.mocky.io.publickey", withExtension: "der")!
        let data = try! Data(contentsOf: url) as CFData
        
        let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                      kSecAttrKeyClass as String: kSecAttrKeyClassPublic]
        
        let key = SecKeyCreateWithData(data, options as CFDictionary, nil)!
        return key
    }()
    
    func dataRequest(_ url: URL, onCompletion: @escaping (_ result: Result<PostUserModel, Error>) -> Void) {
        
        guard let request = try? URLRequest(url: url, method: .get) else {
            onCompletion(.failure(AppError.noData))
            return
        }
        
        self.session.dataTask(with: request) { data, response, error in
            if let err = error {
                onCompletion(.failure(AppError.unknown(err.localizedDescription)))
                return
            }
            
            DispatchQueue.main.async {
                if let decodedData = try? JSONDecoder().decode(PostUserModel.self, from: data!) {
                    onCompletion(.success(decodedData))
                } else {
                    onCompletion(.failure(AppError.decodingError))
                }
            }
        }.resume()
    }
    
}

extension URLSessionAPIClientPublicKey: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        SecTrustEvaluateAsyncWithError(serverTrust, DispatchQueue.main) { trust, isTrusted, error in
            guard isTrusted, let serverCertificate = SecTrustGetCertificateAtIndex(trust, 0) else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            
            // Extract the public key from the server's certificate
            guard let serverPublicKey = SecCertificateCopyKey(serverCertificate) else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            
            // Compare the server's public key with your stored public key
            if self.publicKey == serverPublicKey {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                // Public key does not match, cancel the connection
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
}

