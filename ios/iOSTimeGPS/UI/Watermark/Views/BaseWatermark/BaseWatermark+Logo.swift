//
//  BaseWatermark+Logo.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/6.
//

import Foundation

extension BaseWatermark {
    
    func updateLogo() {
        
        guard let logoModel = watermarkModel?.items?.first(where: { $0.idType == .logo }), logoModel.isOpen == true, !isCover else {
            logoHeight = 0
            logoWidth = 0
            logoImageView.image = nil
            outLogoView.isHidden = true
            outLogoView.imgView.image = nil
            return
        }
        
        if let logoImg = logoModel.getLogo() {
            setLogoWithImg(logoImg: logoImg)
        } else if let logoUrl = logoModel.extraLogo.logoUrl, !logoUrl.isEmpty {
            logoImageView.setImage_xh(with: logoUrl) { [weak self] img,url in
                if let img {
                    logoModel.addLogo(img)
                    setLogoWithImg(logoImg: img)
                    self?.setNeedsLayout()
                    self?.layoutIfNeeded()
                }
            }
        }
        
        func setLogoWithImg(logoImg: UIImage) {
            let margin = 24.0
            let slideValue = logoModel.extraLogo.scale ?? 0.23
            let alpha = logoModel.extraLogo.alpha ?? 1
            if logoImg.size.width > logoImg.size.height{
                logoWidth = (GPApp.screenWidth - margin) * CGFloat(slideValue)
                logoHeight = (GPApp.screenWidth - margin) * CGFloat(slideValue) * logoImg.size.height / logoImg.size.width
            }else{
                logoHeight = (GPApp.screenWidth - margin) * CGFloat(slideValue)
                logoWidth = (GPApp.screenWidth - margin) * logoImg.size.width / logoImg.size.height * CGFloat(slideValue)
            }
            
            switch logoModel.extraLogo.enumPosition {
            case .onWatermark:
                logoImageView.image = logoImg
                logoImageView.alpha = alpha
                outLogoView.isHidden = true
                outLogoView.imgView.image = nil
            case .leftTop, .rightTop, .center:
                logoImageView.image = nil
                outLogoView.isHidden = false
                outLogoView.imgView.image = logoImg
                outLogoView.imgView.alpha = alpha
            default:
                break
            }
            
            didUpdateLogo()
        }
    }
    
    func resetLogoFrame() {
        
        guard let logoModel = watermarkModel?.items?.first(where: { $0.idType == .logo }), logoModel.isOpen == true else { return }
                
        if logoImageView.image != nil {
            logoImageView.frame = CGRect(x: outLogoPadding, y: outLogoPadding, width: logoWidth, height: logoHeight)
        } else {
            logoImageView.frame = .zero
        }
        
        if outLogoView.imgView.image != nil {
            outLogoView.width = logoWidth
            outLogoView.height = logoHeight
            switch logoModel.extraLogo.enumPosition {
            case .leftTop:
//                outLogoView.x = outLogoPadding
//                outLogoView.y = outLogoPadding
                break
            case .rightTop:
//                if orientation == .portraitDirection || orientation == .downDirection {
//                    outLogoView.x = self.width - logoWidth - outLogoPadding
//                } else {
//                    outLogoView.x = self.height - logoWidth - outLogoPadding
//                }
//                outLogoView.y = outLogoPadding
                break
            case .center:
//                if orientation == .portraitDirection || orientation == .downDirection {
//                    outLogoView.center = CGPoint(x: self.width * 0.5, y: self.height * 0.5)
//                } else {
//                    outLogoView.center = CGPoint(x: self.height * 0.5, y: self.width * 0.5)
//                }
                break
            default:
                break
            }
        }
    }
    
}
