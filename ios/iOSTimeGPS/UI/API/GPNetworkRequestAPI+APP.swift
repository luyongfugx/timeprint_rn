//
//  GPNetworkRequestAPI+APP.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/16.
//

import Foundation
import Alamofire

extension GPNetworkRequestAPI {
    
//    static let apoloUrl = "https://conf.aiboot.cloud/configs/timeprint/default/watermarjson.json"
    
    static let apoloConfigUrl = "https://conf.aiboot.cloud/configs/timeprint/default/application"

    // 启动配置接口
    func appConfig(finishedHandle: @escaping ((_ error:Error?, _ message: GPConfigModel?)->())){
        
        func generateHeaders() -> [String: String] {//
            var authorization: String = "";
            var timestamp: String = "";

            do {
                let result = try ApolloHeaderUtils.buildHttpHeaders2(url: GPNetworkRequestAPI.apoloConfigUrl, appId: "timeprint", secret: "446eb21060c343689e30724da2214631")
                authorization = result.0
                timestamp = result.1
            } catch {
                LogDebug("Error: \(error.localizedDescription)")
            }
            
            return [
                "Timestamp": timestamp,
                "Authorization": authorization
            ]
        }

        func fetchGETData(from url: URL, headers: [String: String], completion: @escaping (Result<String, Error>) -> Void) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // 设置HTTP头部字段
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // 检查是否有错误发生
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // 确保我们得到了有效的数据
                guard let data = data else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                // 尝试将数据转换为字符串
                let string = String(data: data, encoding: .utf8)
                completion(.success(string ?? ""))
            }
            task.resume()
        }

        // 使用示例
        if let url = URL(string: GPNetworkRequestAPI.apoloConfigUrl) {
            let headers = generateHeaders()
            fetchGETData(from: url, headers: headers) { result in
                switch result {
                case .success(let data):
                    if let configDic = GPJson.stringToDictionary(data)?["configurations"] as? [String : Any], let configModel = try? SpeedyModel.dictionaryToModel(GPConfigModel.self, param: configDic) {
                        finishedHandle(nil, configModel)
                    } else {
                        finishedHandle(NSError(domain: "解析model失败", code: -1), nil)
                    }
                    LogDebug("Data received: \(data)")
                case .failure(let error):
                    LogDebug("Error: \(error.localizedDescription)")
                    finishedHandle(NSError(domain: "接口失败", code: -2), nil)
                }
            }
        }

    }
    
}
