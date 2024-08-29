//
//  AlamoAPIClientKeyHardcode.swift
//  ssl-pinning-demo
//
//  Created by Jeremy Raymond on 26/08/24.
//

import Foundation
import Alamofire

class AlamofirePublickKeyHardcodeAPIClient: APIClient {
    struct PublicKeys {
        
        // Base64-encoded public key (extracted from the certificate)
        static let publicKeyBase64 = """
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwZYslxJ3GcLg2T05Y0v6
        gteuzRlWY9fnC54SGs8iOffD8iiJOHIphh9Fvd05m1HZVTO6vz+7UQyROX7+YZFm
        7LuBJowTXPeiqfSNBNjOievMdrqRm0KVuLqQXDs78KUNFG8A4C+FB/Qwk5j8WiaE
        +u9DK85H1CJiNvFcE+fq01a83xLFHA5/TmZpxDjUh5kBPIBmU+l43lpAIhu1T4Vr
        0C/mN+at7l1HQ1sqOGUzAVO8NqT5DYDLMtYqjcFdHSCnW1pAjgAQLcDDHGbiZnfk
        I3nLBSWkihXE/+/9+MMIEwTCwUIjYPoVVUi0O3sJR8B+sfEug5FpMEHu6vRrCDS9
        1wIDAQAB
        """ // Replace with your actual public key in Base64 format
        
        static let publicKey: SecKey = {
            guard let data = Data(base64Encoded: publicKeyBase64) else {
                fatalError("Invalid Base64 string")
            }
            
            let keyDict: [NSString: Any] = [
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrKeySizeInBits: 2048,
                kSecReturnPersistentRef: true
            ]
            
            var error: Unmanaged<CFError>?
            guard let secKey = SecKeyCreateWithData(data as CFData, keyDict as CFDictionary, &error) else {
                fatalError("Failed to create public key: \(error!.takeRetainedValue() as Error)")
            }
            
            return secKey
        }()
    }
    
    private var isSSLPinningEnabled = true
    private var session: Session = AF
    
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

