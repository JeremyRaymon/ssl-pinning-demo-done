//
//  AlamofireAPIClientPublicKey.swift
//  ssl-pinning-demo
//
//  Created by Jeremy Raymond on 26/08/24.
//

import Foundation
import Alamofire

struct PublicKeys {
    
    static let publicKey: SecKey = {
        let certificate = Certificates.certificate
        return publicKey(from: certificate)
    }()
    
    private static func publicKey(from certificate: SecCertificate) -> SecKey {
        var publicKey: SecKey?
        var trust: SecTrust?
        
        // Create a trust object with the certificate
        let policy = SecPolicyCreateBasicX509()
        SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        // Extract the public key from the trust object
        if let trust = trust {
            publicKey = SecTrustCopyKey(trust)
        }
        
        return publicKey!
    }
}

struct Certificates {
    
    static let certificate: SecCertificate = {
        let filePath = Bundle.main.path(forResource: "run.mocky.io", ofType: "cer")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let certificate = SecCertificateCreateWithData(nil, data as CFData)!
        
        return certificate
    }()
}

class AlmofireAPIClientPublicKeys: APIClient {
    
    private var isSSLPinningEnabled = true
    private var session: Session = AF
    private let publicKeys: [String: SecKey] = [
        "run.mocky.io": PublicKeys.publicKey
    ]
    
    init(sslPinningEnabled: Bool) {
        self.isSSLPinningEnabled = sslPinningEnabled
        
        if isSSLPinningEnabled {
            let serverTrustPolicy = ServerTrustManager(
                allHostsMustBeEvaluated: true,
                evaluators: [
                    "run.mocky.io": PublicKeysTrustEvaluator(
                        keys: [PublicKeys.publicKey],
                        performDefaultValidation: true,
                        validateHost: true
                    )
                ]
            )
            
            self.session = Session(serverTrustManager: serverTrustPolicy)
        }
    }
    
    func dataRequest(_ url: URL, onCompletion: @escaping(_ result: Result<PostUserModel, Error>) -> Void) {
            
            self.session.request(url).response { response in
                DispatchQueue.main.async {
                    if let data = response.data {
                        if let decodedType = try? JSONDecoder().decode(PostUserModel.self, from: data) {
                            print(decodedType)
                            onCompletion(.success(decodedType))
                        } else {
                            print("Decoding Error")
                            onCompletion(.failure(AppError.decodingError))
                        }
                    } else {
                        if let err = response.error {
                            print("Server Error")
                            onCompletion(.failure(AppError.unknown(err.localizedDescription)))
                        } else if response.error?.isServerTrustEvaluationError ?? false {
                            print("Certificate Error")
                        } else {
                            print("Date Error")
                            onCompletion(.failure(AppError.noData))
                        }
                    }
                }
            }
        }
    }
