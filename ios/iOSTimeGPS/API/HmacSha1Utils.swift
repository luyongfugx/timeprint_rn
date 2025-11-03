//
//  HmacSha1Utils.swift
//  beautycamera
//
//  Created by waynelu on 2024/11/16.
//

import Foundation
import CommonCrypto
public class HmacSha1Utils {
    
    private static let ALGORITHM_NAME = kCCHmacAlgSHA1
    private static let ENCODING = String.Encoding.utf8
    
    public static func signString(_ stringToSign: String, accessKeySecret: String) throws -> String {
        guard let keyData = accessKeySecret.data(using: ENCODING),
              let messageData = stringToSign.data(using: ENCODING) else {
            throw NSError(domain: "HmacSha1Utils", code: -1, userInfo: [NSLocalizedDescriptionKey: "编码失败"])
        }
        
        let keyLength = keyData.count
        let messageLength = messageData.count
        
        var result = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        
        keyData.withUnsafeBytes { keyPtr in
            messageData.withUnsafeBytes { messagePtr in
                CCHmac(CCHmacAlgorithm(ALGORITHM_NAME),
                       keyPtr.baseAddress!, keyLength,
                       messagePtr.baseAddress!, messageLength,
                       &result)
            }
        }
        
        let hmacData = Data(result)
        return hmacData.base64EncodedString()
    }
}