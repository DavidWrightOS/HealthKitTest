//
//  MainTabViewController.swift
//  HealthKitTest
//
//  Created by David Wright on 2/15/21.
//

import UIKit
import HealthKit

class MainTabViewController: UITabBarController {
    
    // MARK: - Initializers
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .systemBackground
        setUpTabViewController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    func setUpTabViewController() {
        let viewControllers = [
            createWelcomeViewController(),
            createWeeklyQuantitySampleTableViewController(),
            createChartViewController(),
//            createWeeklyReportViewController(),
            createWeeklyWaterIntakeTableViewController(),
            createWaterIntakeChartViewController(),
        ]
        
        self.viewControllers = viewControllers.map {
            UINavigationController(rootViewController: $0)
        }
        
        delegate = self
        selectedIndex = getLastViewedViewControllerIndex()
    }
    
    private func createWelcomeViewController() -> UIViewController {
        let viewController = WelcomeViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Welcome",
                                                 image: UIImage(systemName: "house"),
                                                 selectedImage: UIImage(systemName: "house.fill"))
        return viewController
    }
    
    private func createWeeklyQuantitySampleTableViewController() -> UIViewController {
        let dataTypeIdentifier = HKQuantityTypeIdentifier.stepCount.rawValue
        let viewController = WeeklyQuantitySampleTableViewController(dataTypeIdentifier: dataTypeIdentifier)
        
        viewController.tabBarItem = UITabBarItem(title: "Health Data",
                                                 image: UIImage(systemName: "heart.text.square"),
                                                 selectedImage: UIImage(systemName: "heart.text.square.fill"))
        return viewController
    }
    
    private func createChartViewController() -> UIViewController {
        let viewController = MobilityChartDataViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Charts",
                                                 image: UIImage(systemName: "chart.bar"),
                                                 selectedImage: UIImage(systemName: "chart.bar.fill"))
        return viewController
    }
    
    private func createWeeklyReportViewController() -> UIViewController {
        let viewController = WeeklyReportTableViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Weekly Report",
                                                 image: UIImage(systemName: "doc.text.below.ecg"),
                                                 selectedImage: UIImage(systemName: "doc.text.below.ecg.fill"))
        return viewController
    }
    
    private func createWeeklyWaterIntakeTableViewController() -> UIViewController {
        let viewController = WeeklyWaterIntakeTableViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Water Data",
                                                 image: UIImage(systemName: "drop"),
                                                 selectedImage: UIImage(systemName: "drop.fill"))
        return viewController
    }
    
    private func createWaterIntakeChartViewController() -> UIViewController {
        let viewController = WaterIntakeChartViewController()
        
        viewController.tabBarItem = UITabBarItem(title: "Charts",
                                                 image: UIImage(systemName: "chart.bar"),
                                                 selectedImage: UIImage(systemName: "chart.bar.fill"))
        return viewController
    }
    
    // MARK: - View Persistence
    
    private static let lastViewControllerViewed = "LastViewControllerViewed"
    private var userDefaults = UserDefaults.standard
    
    private func getLastViewedViewControllerIndex() -> Int {
        if let index = userDefaults.object(forKey: Self.lastViewControllerViewed) as? Int {
            return index
        }
        
        return 0 // Default to first view controller.
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabViewController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.firstIndex(of: item) else { return }
        
        setLastViewedViewControllerIndex(index)
    }
    
    private func setLastViewedViewControllerIndex(_ index: Int) {
        userDefaults.set(index, forKey: Self.lastViewControllerViewed)
    }
}
