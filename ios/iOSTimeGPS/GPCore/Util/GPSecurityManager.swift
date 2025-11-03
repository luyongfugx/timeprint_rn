//
//  GPSecurityManager.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/11/30.
//

import Foundation

import UIKit
import CryptoSwift
import CommonCrypto

class GPSecurityManager {
    
    static let shared = GPSecurityManager()
    
    // MARK: - 加密字符串
    func encryptAES(str: String) -> String {
        
        var resultStr = ""
        //使用AES-128-CBC加密模式的Cipher
        if let aes = try? AES(key: GPApp.ForStringChange.getThisString(), iv: GPApp.ForStringChange.getThisString(),padding: .pkcs5)   {
            if let encryptedStr = try? str.encryptToBase64(cipher: aes) {
                resultStr = encryptedStr
            }
        }
      //  print("encryptAES resultStr \(resultStr)")
        return resultStr
    }
    
    // MARK: - 解密字符串
    func decryptAES(str: String) -> String {
        
        var resultStr = ""
        //使用AES-128-CBC加密模式的Cipher
        if let aes = try? AES(key: GPApp.ForStringChange.getThisString(), iv: GPApp.ForStringChange.getThisString(),padding: .pkcs5)   {
            if let decryptedStr = try? str.decryptBase64ToString(cipher: aes) {
                resultStr = decryptedStr
            }
        }
        return resultStr
    }

//    // V2.9.225  PDF二维码分享需要AES加密，但是key和上面的不同【安俊】
//    func encryptAESForPDF(str: String) -> String {
//
//        var resultStr = ""
//        //使用AES-128-CBC加密模式的Cipher
//        if let aes = try? AES(key: XHGlobalConstant.ForPDFQRCodeShare.getThisString(), iv: XHGlobalConstant.ForPDFQRCodeShare.getThisString(),padding: .pkcs5)   {
//            if let encryptedStr = try? str.encryptToBase64(cipher: aes) {
//                resultStr = encryptedStr
//            }
//        }
//        return resultStr
//    }
//
//    // MARK: - 解密字符串
//    func decryptAESForPDF(str: String) -> String {
//
//        var resultStr = ""
//        //使用AES-128-CBC加密模式的Cipher
//        if let aes = try? AES(key: XHGlobalConstant.ForPDFQRCodeShare.getThisString(), iv: XHGlobalConstant.ForPDFQRCodeShare.getThisString(),padding: .pkcs5)   {
//            if let decryptedStr = try? str.decryptBase64ToString(cipher: aes) {
//                resultStr = decryptedStr
//            }
//        }
//        return resultStr
//    }
}


/// @see http://www.splinter.com.au/2019/06/09/pure-swift-common-crypto-aes-encryption/
public extension Data {
    /// Encrypts for you with all the good options turned on: CBC, an IV, PKCS7
    /// padding (so your input data doesn't have to be any particular length).
    /// Key can be 128, 192, or 256 bits.
    /// Generates a fresh IV for you each time, and prefixes it to the
    /// returned ciphertext.
    func encryptAES256(key: Data, iv: Data, options: Int = kCCOptionPKCS7Padding) -> Data? {
        // No option is needed for CBC, it is on by default.
        return aesCrypt(operation: kCCEncrypt,
                        algorithm: kCCAlgorithmAES,
                        options: options,
                        key: key,
                        initializationVector: iv,
                        dataIn: self)
    }

    /// Decrypts self, where self is the IV then the ciphertext.
    /// Key can be 128/192/256 bits.
    func decryptAES256(key: Data, iv: Data, options: Int = kCCOptionPKCS7Padding) -> Data? {
        guard count > kCCBlockSizeAES128 else { return nil }
        return aesCrypt(operation: kCCDecrypt,
                        algorithm: kCCAlgorithmAES,
                        options: options,
                        key: key,
                        initializationVector: iv,
                        dataIn: self)
    }

    // swiftlint:disable:next function_parameter_count
    private func aesCrypt(operation: Int,
                          algorithm: Int,
                          options: Int,
                          key: Data,
                          initializationVector: Data,
                          dataIn: Data) -> Data? {
        return initializationVector.withUnsafeBytes { ivUnsafeRawBufferPointer in
            return key.withUnsafeBytes { keyUnsafeRawBufferPointer in
                return dataIn.withUnsafeBytes { dataInUnsafeRawBufferPointer in
                    // Give the data out some breathing room for PKCS7's padding.
                    let dataOutSize: Int = dataIn.count + kCCBlockSizeAES128 * 2
                    let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutSize, alignment: 1)
                    defer { dataOut.deallocate() }
                    var dataOutMoved: Int = 0
                    let status = CCCrypt(CCOperation(operation),
                                         CCAlgorithm(algorithm),
                                         CCOptions(options),
                                         keyUnsafeRawBufferPointer.baseAddress, key.count,
                                         ivUnsafeRawBufferPointer.baseAddress,
                                         dataInUnsafeRawBufferPointer.baseAddress, dataIn.count,
                                         dataOut, dataOutSize,
                                         &dataOutMoved)
                    guard status == kCCSuccess else { return nil }
                    return Data(bytes: dataOut, count: dataOutMoved)
                }
            }
        }
    }
}
