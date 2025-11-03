//
//  ApolloHeaderUtils.swift
//  beautycamera
//
//  Created by waynelu on 2024/11/16.
//

import Foundation

public class ApolloHeaderUtils {
    
    // Authorization=Apollo {appId}:{sign}
    private static let AUTHORIZATION_FORMAT = "Apollo %@:%@"
    private static let DELIMITER = "\n"
    
    public static let HTTP_HEADER_AUTHORIZATION = "Authorization"
    public static let HTTP_HEADER_TIMESTAMP = "Timestamp"
    
    public static func signature(timestamp: String, pathWithQuery: String, secret: String) throws -> String {
        let stringToSign = timestamp + DELIMITER + pathWithQuery
        return try HmacSha1Utils.signString(stringToSign, accessKeySecret: secret)
    }
    
    public static func buildHttpHeaders(url: String, appId: String, secret: String) throws -> String {
        let currentTimeMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let timestamp = String(currentTimeMillis)
        
        let pathWithQuery = try url2PathWithQuery(urlString: url)
        let signature = try signature(timestamp: timestamp, pathWithQuery: pathWithQuery, secret: secret)
        
        var headers = [String: String]()
        headers[HTTP_HEADER_AUTHORIZATION] = String(format: AUTHORIZATION_FORMAT, appId, signature)
        print("HTTP_HEADER_AUTHORIZATION: \(HTTP_HEADER_AUTHORIZATION)")
        print("value: \(String(format: AUTHORIZATION_FORMAT, appId, signature))" )
        print("timestamp: \(timestamp)")
        headers[HTTP_HEADER_TIMESTAMP] = timestamp
        
        return "value: \(String(format: AUTHORIZATION_FORMAT, appId, signature)) |\(timestamp)";
    }
    
    public static func buildHttpHeaders2(url: String, appId: String, secret: String) throws -> (String, String) {
        // 获取真实事件戳
        let currentTimeMillis = Int64(TimeManager.shared.getRealTime().timeIntervalSince1970 * 1000)
        let timestamp = String(currentTimeMillis)
        
        let pathWithQuery = try url2PathWithQuery(urlString: url)
        let signature = try signature(timestamp: timestamp, pathWithQuery: pathWithQuery, secret: secret)
        let authorization = String(format: AUTHORIZATION_FORMAT, appId, signature)
        
        return (authorization, timestamp)
    }
    
    private static func url2PathWithQuery(urlString: String) throws -> String {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ApolloHeaderUtils", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid url pattern: \(urlString)"])
        }
        
        var pathWithQuery = url.path
        if let query = url.query {
            pathWithQuery += "?" + query
        }
        return pathWithQuery
    }
}
