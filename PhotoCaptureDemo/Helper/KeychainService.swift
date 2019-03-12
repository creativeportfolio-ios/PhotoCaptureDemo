//
//  KeychainItemWrapper.swift
//  PhotoCaptureDemo
//
//  Copyright © 2019 A2B. All rights reserved.
//

import Security
import Foundation

let kSecClassValue = String(format: kSecClass as String)
let kSecAttrAccountValue = String(format: kSecAttrAccount as String)
let kSecValueDataValue = String(format: kSecValueData as String)
let kSecClassGenericPasswordValue = String(format: kSecClassGenericPassword as String)
let kSecAttrServiceValue = String(format: kSecAttrService as String)
let kSecMatchLimitValue = String(format: kSecMatchLimit as String)
let kSecReturnDataValue = String(format: kSecReturnData as String)
let kSecMatchLimitOneValue = String(format: kSecMatchLimitOne as String)

public class KeychainService: NSObject {
    
    class func saveData(service: String, account:String, data: Data?) {
        if let data = data {
            let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, data], forKeys: [kSecClassValue as NSCopying, kSecAttrServiceValue as NSCopying, kSecAttrAccountValue as NSCopying, kSecValueDataValue as NSCopying])
            
            let status = SecItemAdd(keychainQuery as CFDictionary, nil)
            
            if (status != errSecSuccess) {
                if let _ = SecCopyErrorMessageString(status, nil) {

                }
            }
        }
    }
    
    class func getData(service: String, account:String) -> Data? {
        let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, kCFBooleanTrue, kSecMatchLimitOneValue as NSCopying], forKeys: [kSecClassValue as NSCopying, kSecAttrServiceValue as NSCopying, kSecAttrAccountValue as NSCopying, kSecReturnDataValue as NSCopying, kSecMatchLimitValue as NSCopying])
        
        var dataTypeRef :AnyObject?
        
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        var contentsOfKeychain: Data?
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain =  retrievedData
            }
        } else {
            print("Nothing was retrieved from the keychain. Status code \(status)")
        }
        
        return contentsOfKeychain
    }
    
}
