//
//  EditWeatherVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/5.
//

import Foundation
import UIKit

class EditWeatherVC: GPHalfBaseVC {
    
    private var viewHeight: CGFloat = 0
    
    override var preferredContentSize: CGSize {
        
        get { .init(width: view.bounds.width, height: editWatermarkHeightRate * GPApp.screenHeight) }
        set {}
    }
    
    let topLabel = UILabel()
    let sourcesStackView = UIStackView()
    let appleWeatherLabel = UILabel()
    let otherSourcesLabel = UITextView()
    let fontGetLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        vcTitle = "k_weather_attribute".localized()
        buildViews()
        layout()
    }
    
    func buildViews() {
        sourcesStackView.translatesAutoresizingMaskIntoConstraints = false
        sourcesStackView.axis = .vertical
        sourcesStackView.spacing = 20
        
        appleWeatherLabel.translatesAutoresizingMaskIntoConstraints = false
        appleWeatherLabel.text = " Weather (Apple Weather)"
        appleWeatherLabel.textColor = .black
        appleWeatherLabel.font = .preferredFont(forTextStyle: .title2)
        
//        otherSourcesLabel.translatesAutoresizingMaskIntoConstraints = false
        let dataSourceString = "k_weather_data_sourece".localized()
        let attributedString = NSMutableAttributedString(string: dataSourceString)
        attributedString.addAttribute(.link, value: "https://weatherkit.apple.com/legal-attribution.html", range: NSRange(location: 0, length: dataSourceString.count))
        otherSourcesLabel.attributedText = attributedString
        otherSourcesLabel.frame = CGRect(x: view.bounds.minX + 18, y: 180, width: view.bounds.width, height: 60)
        otherSourcesLabel.font = .preferredFont(forTextStyle: .title3)
        otherSourcesLabel.textAlignment = .left
        otherSourcesLabel.isEditable = false
        otherSourcesLabel.backgroundColor = .clear
        
        // fontGetLabel (SpaceX Font is from FontGet)
        fontGetLabel.translatesAutoresizingMaskIntoConstraints = false
        fontGetLabel.font = .preferredFont(forTextStyle: .title2)
    }
    
    func layout() {
        view.addSubview(topLabel)
        view.addSubview(sourcesStackView)
        view.addSubview(appleWeatherLabel)
        view.addSubview(otherSourcesLabel)
        view.addSubview(fontGetLabel)
        
        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            appleWeatherLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 80),
            appleWeatherLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            otherSourcesLabel.topAnchor.constraint(equalTo: appleWeatherLabel.bottomAnchor),
            otherSourcesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            otherSourcesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            fontGetLabel.topAnchor.constraint(equalTo: otherSourcesLabel.bottomAnchor),
            fontGetLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fontGetLabel.leadingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
    
}
