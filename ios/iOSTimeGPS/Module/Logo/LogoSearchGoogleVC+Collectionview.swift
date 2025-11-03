//
//  LogoSearchGoogleVC+Collectionview.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import UIKit

extension LogoSearchGoogleVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let lineSpce = (2-1)*10
        let buttonWidth: CGFloat = CGFloat((Int(GPApp.screenWidth) - 32 - lineSpce)/2)
        
        return .init(width: buttonWidth, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 0, left: 16, bottom: 10, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        10
    }
              
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
          10
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return logoModelList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPGoogleSearchLogoCell", for: indexPath) as! GPGoogleSearchLogoCell
        
        if let model = logoModelList[safe: indexPath.row] {
            
            switch model.logoType {
            case.image:
                cell.logoImageView?.image = model.image
            case .url: do {
                if let url = model.url, url.count > 0 {
                    cell.logoImageView?.setImage_xh(with: url, complete: { img, nsurl in
                        if let img {
                            model.image = img
                        }
                    })
                } else {
                    cell.logoImageView?.image = nil
                }
            }
            }
        } else {
            cell.logoImageView?.image = nil
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 点击
        if let selectCell = collectionView.cellForItem(at: indexPath) as? GPGoogleSearchLogoCell, let logoImg = selectCell.logoImageView?.image {
            self.dismiss(animated: true)
            self.completeBlock?(logoImg)
            
        }
    }
    
}
