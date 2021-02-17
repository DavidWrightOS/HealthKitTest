//
//  WeeklyReportTableViewController.swift
//  HealthKitTest
//
//  Created by David Wright on 2/15/21.
//

import UIKit

class WeeklyReportTableViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let title = "Weekly Report"
        let subtitle = "No data recorded. Please add some health data."
        let image = UIImage(systemName: "doc.text.below.ecg.fill")
        
        addSplashScreen(title: title, subtitle: subtitle, image: image)
        
        self.title = title
    }
}
