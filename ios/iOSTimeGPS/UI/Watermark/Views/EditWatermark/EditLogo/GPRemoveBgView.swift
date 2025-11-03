//
//  GPRemoveBgView.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/6/18.
//

import Foundation
import UIKit
import Vision
/**
 删除logo背景
 */
class GPRemoveBgView: GPView {
    
    
    lazy var removeBtn: GPButton = {
        let button = GPButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 4
        
        button.setTitle("k_remove_bg".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        button.addTarget(self, action: #selector(didClickRemoveBg), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        return button
    }()
    var logoItem: WatermarkLogoItem?
    
    var removeBg: ((_ image: UIImage?) -> Void)?
    
    override func buildUI() {
        addSubview(removeBtn)
        
        removeBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(40)
        }
    }
    
    func initLogoImageView(logo: WatermarkLogoItem){
        logoItem = logo
        if((logoItem?.isRemoveBg) == true){
            removeBtn.setTitle("k_recover_bg".localized(), for: .normal)
        }
        else {
            removeBtn.setTitle("k_remove_bg".localized(), for: .normal)
        }
    }
    

        @objc func didClickRemoveBg() {
            if((logoItem?.isRemoveBg) == true){
                guard let image = GPDataCacheManager.shared.getCachLogo(fileName:logoItem?.originLogoPath ?? "")
                else {
                    return
                }
                
                logoItem?.selectLogoPath =  logoItem?.originLogoPath
                logoItem?.isRemoveBg = false
                removeBtn.setTitle("k_remove_bg".localized(), for: .normal)
                removeBg?(image)
                //
                GPFirebaseManager.recover_logo_bg()
            }
            else {
                guard let image = GPDataCacheManager.shared.getCachLogo(fileName:logoItem?.selectLogoPath ?? "")
                else {
                    return
                }
                logoItem?.originLogoPath  =  logoItem?.selectLogoPath
                removeBtn.isEnabled = false
                removeBtn.setTitle("......", for: .normal)
                DispatchQueue.global(qos: .userInitiated).async {
                    self.removeBackground(from: image) { [weak self] result in
                        DispatchQueue.main.async {
                            self?.removeBtn.isEnabled = true
                            self?.removeBtn.setTitle("k_remove_bg".localized(), for: .normal)
                            
                            switch result {
                            case .success(let newImage):
                                //self?.logoImageView.image = newImage
                                self?.removeBtn.setTitle("k_recover_bg".localized(), for: .normal)
                                
                                self?.removeBg?(newImage)
                                self?.logoItem?.isRemoveBg = true
                                //
                                GPFirebaseManager.remove_logo_bg()
                            case .failure(let error):
                                self?.removeBtn.setTitle("k_remove_bg".localized(), for: .normal)
                                print("Background removal failed: \(error.localizedDescription)")
                                // Show error to user if needed
                            }
                        }
                    }
                }
            }

        }
        
        private func removeBackground(from image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void) {
            guard let cgImage = image.cgImage else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])))
                return
            }
            
            if #available(iOS 17.0, *) {
                let request = VNGenerateForegroundInstanceMaskRequest()
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try requestHandler.perform([request])
                    
                    if let result = request.results?.first {
                        let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: requestHandler)
                        guard let mask = self.createCGImage(from: maskPixelBuffer) else {
                            throw NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to create mask image"])
                        }
                        let newImage = self.applyMask(mask, to: cgImage)
                        completion(.success(newImage))
                    } else {
                        completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No results from Vision request"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
                // Fallback implementation for iOS <17
                completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "Background removal requires iOS 17 or later"])))
            }
        }
        
        private func createCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext(options: nil)
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        
        private func applyMask(_ mask: CGImage, to image: CGImage) -> UIImage {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            guard let context = CGContext(data: nil,
                                        width: image.width,
                                        height: image.height,
                                        bitsPerComponent: 8,
                                        bytesPerRow: 0,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo.rawValue) else {
                return UIImage(cgImage: image)
            }
            
            context.clip(to: CGRect(x: 0, y: 0, width: image.width, height: image.height), mask: mask)
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            
            if let newImage = context.makeImage() {
                return UIImage(cgImage: newImage)
            }
            
            return UIImage(cgImage: image)
        }
}
