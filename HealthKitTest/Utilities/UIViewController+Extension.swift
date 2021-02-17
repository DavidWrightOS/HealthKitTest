//
//  UIViewController+Extension.swift
//  HealthKitTest
//
//  Created by David Wright on 2/15/21.
//

import UIKit

fileprivate let splashScreenIdentifier = "ViewControllerSplashScreenIdentifier"

extension UIViewController {
    
    func addSplashScreen(title: String? = nil, subtitle: String? = nil, image: UIImage? = nil) {
        
        guard title != nil || subtitle != nil || image != nil else { return }
        
        // Remove the existing splash screen if one exists
        removeSplashScreen()
                
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .secondaryLabel
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = .label
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        let imageView = UIImageView()
        
        if let image = image {
            imageView.image = image.withTintColor(.tertiaryLabel, renderingMode: .alwaysOriginal)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let imageSize: CGFloat = 150
            
            imageView.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
            
//            let imageRatio = image.size.height / image.size.width
//
//            if imageRatio < 1 {
//                imageView.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
//                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: imageRatio).isActive = true
//            } else {
//                imageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
//                imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1/imageRatio).isActive = true
//            }
        }
        
        // Create splash screen stackView
        
        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel])
        stackView.accessibilityIdentifier = splashScreenIdentifier
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        
        view.addSubview(stackView)
                
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }
    
    func removeSplashScreen() {
        if let splashView = view.subviews.first(where: { $0.accessibilityIdentifier == splashScreenIdentifier }) {
            splashView.removeFromSuperview()
        }
    }
}
