//
//  MobilityChartDataViewController.swift
//  HealthKitTest
//
//  Created by David Wright on 2/15/21.
//

import UIKit
import HealthKit

/// A representation of health data related to mobility.
class MobilityChartDataViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let title = "Charts"
        let subtitle = "No data recorded. Please add some health data."
        let image = UIImage(systemName: "chart.bar.xaxis")
        
        addSplashScreen(title: title, subtitle: subtitle, image: image)
        
        self.title = title
    }
}
