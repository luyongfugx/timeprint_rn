//
//  CLCalendarDelegateFlowLayout.swift
//  Created by waynelu on 2024/12/16.
//

import UIKit

protocol CLCalendarDelegateFlowLayout: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, textColorForSectionAt section: Int) -> UIColor
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, textForSectionAt section: Int) -> String
}

extension CLCalendarDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, textColorForSectionAt section: Int) -> UIColor {
        .white
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, textForSectionAt section: Int) -> String {
        ""
    }
}
