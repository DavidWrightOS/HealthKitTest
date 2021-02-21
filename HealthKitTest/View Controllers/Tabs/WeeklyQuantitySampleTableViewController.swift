//
//  WeeklyQuantitySampleTableViewController.swift
//  HealthKitTest
//
//  Created by David Wright on 2/15/21.
//

import UIKit
import HealthKit

/// A protocol for a class that manages a HealthKit query.
protocol HealthQueryDataSource: class {
    /// Create and execute a query on a health store. Note: The completion handler returns on a background thread.
    func performQuery(completion: @escaping () -> Void)
}

protocol HealthDataTableViewControllerDelegate: class {
    func didAddNewData(with value: Double)
}

/// A representation of health data related to mobility.
class WeeklyQuantitySampleTableViewController: UITableViewController {
    
    static let cellIdentifier = "DataTypeTableViewCell"
    
    // MARK: - Properties
    
    let calendar: Calendar = .current
    let healthStore = HealthData.healthStore
    
    var dataTypeIdentifier: String
    
    var dataValues: [HealthDataTypeValue] = [] // tableView data source
    
    var query: HKStatisticsCollectionQuery?
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
    
    public var showGroupedTableViewTitle: Bool = false
    
    // Computed Properties
    
    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        HKQuantityTypeIdentifier(rawValue: dataTypeIdentifier)
    }
    
    var quantityType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier)!
    }
    
    // MARK: Initializers

    init(dataTypeIdentifier: String) {
        self.dataTypeIdentifier = dataTypeIdentifier
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForhealthIntegrationIsEnabledChanges()
        setUpNavigationController()
        setUpViewController()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavigationItem()
        
        if AppSettings.shared.healthIntegrationIsEnabled {
            configureHKQuery()
        } else {
            print("Warning: Unable to configure query. The user has disabled Apple Health integration.")
            reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopHKQuery()
    }
    
    // MARK: - Lifecycle Helpers
    
    func setUpNavigationController() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "More", style: .plain, target: self, action: #selector(didTapLeftBarButtonItem))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Data", style: .plain, target: self, action: #selector(didTapRightBarButtonItem))
    }
    
    func setUpViewController() {
        title = tabBarItem.title
    }
    
    func setUpTableView() {
        tableView.register(DataTypeTableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
    }
    
    func updateNavigationItem() {
        navigationItem.title = getDataTypeName(for: dataTypeIdentifier)
    }
    
    func configureHKQuery() {
        
        print("Setting up HealthKit query...")
        
        guard query == nil else { print("Warning: query already exists... cancelling query setup"); return }
        
        let dataTypeValues = Set([quantityType])
        
        print("Requesting HealthKit authorization...")
        healthStore.requestAuthorization(toShare: dataTypeValues, read: dataTypeValues) { (success, error) in
            if let error = error {
                NSLog("Error requesting authorization to HealthStore: \(error.localizedDescription)")
            }
            
            guard success else {
                NSLog("Unable to query daily steps data: HealthStore authorization failed.")
                return
            }
            
            print("HealthKit authorization successful!")
            self.queryDailyQuantitySamplesForPastWeek()
        }
    }
    
    func stopHKQuery() {
        if let query = query {
            print("Stopping HealthKit query...")
            healthStore.stop(query)
        }
    }
    
    // MARK: - Read Steps Data
    
    /// Create and execute an HKQuery for daily steps totals over the last seven days
    func queryDailyQuantitySamplesForPastWeek() {
        performQuery {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }
    
    // MARK: - Data Life Cycle
    
    func reloadData() {
        self.dataValues.isEmpty ? self.setEmptyDataView() : self.removeEmptyDataView()
        self.dataValues.sort { $0.startDate > $1.startDate }
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    private func setEmptyDataView() {
        let title = tabBarItem.title
        let dataTypeName = getDataTypeName(for: dataTypeIdentifier)?.lowercased() ?? "data"
        let subtitle = "No data recorded. Please add some \(dataTypeName)."
        let image = tabBarItem.image
        
        tableView.addSplashScreen(title: title, subtitle: subtitle, image: image)
    }
    
    private func removeEmptyDataView() {
        tableView.removeSplashScreen()
    }
    
    // MARK: - Selectors
    
    @objc private func didTapRightBarButtonItem() {
        presentAddDataAlert()
    }
    
    @objc private func didTapLeftBarButtonItem() {
        presentDataTypeSelectionSheet()
    }
}


// MARK: - Add Data

extension WeeklyQuantitySampleTableViewController {
    
    private func presentAddDataAlert() {
        let title = getDataTypeName(for: self.dataTypeIdentifier)
        let message = "Enter a value to add as a sample to your health data."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = title
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let confirmAction = UIAlertAction(title: "Add", style: .default) { [weak self, weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            
            if let string = textField.text, let doubleValue = Double(string) {
                self?.didAddNewData(with: doubleValue)
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        
        present(alertController, animated: true)
    }
}


// MARK: - Other / Data Type Selection

extension WeeklyQuantitySampleTableViewController {
    
    private func presentDataTypeSelectionSheet() {
        let title = "Select Health Data Type"
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        for dataType in HealthData.readDataTypes {
            let actionTitle = getDataTypeName(for: dataType.identifier)
            
            let action = UIAlertAction(title: actionTitle, style: .default) { [weak self] action in
                self?.didSelectDataTypeIdentifier(dataType.identifier)
            }
            
            alertController.addAction(action)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancel)
        
        present(alertController, animated: true)
    }
    
    private func didSelectDataTypeIdentifier(_ dataTypeIdentifier: String) {
        self.dataTypeIdentifier = dataTypeIdentifier
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypeIdentifiers: [self.dataTypeIdentifier]) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.updateNavigationItem()
                }
                
                self?.performQuery() { [weak self] in
                    DispatchQueue.main.async {
                        self?.reloadData()
                    }
                }
            }
        }
    }
}

// MARK: - HealthQueryDataSource

extension WeeklyQuantitySampleTableViewController: HealthQueryDataSource {
    
    func performQuery(completion: @escaping () -> Void) {
        
        // Construct an HKStatisticsCollectionQuery; only calculate daily steps data from the past week
        let dateSevenDaysAgo = calendar.date(byAdding: DateComponents(day: -7), to: Date())!
        let lastSevenDaysPredicate = HKQuery.predicateForSamples(withStart: dateSevenDaysAgo, end: nil, options: .strictStartDate)
        let statisticsOptions = getStatisticsOptions(for: dataTypeIdentifier)
        let anchorDate = calendar.startOfDay(for: Date())
        let dailyInterval = DateComponents(day: 1)
        
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: lastSevenDaysPredicate,
                                                options: statisticsOptions,
                                                anchorDate: anchorDate,
                                                intervalComponents: dailyInterval)
        
        // The handler block for the HKStatisticsCollection results: updates the UI with the results
        let updateUIWithStatistics: (HKStatisticsCollection) -> Void = { statisticsCollection in
            self.dataValues = []
            
            let endDate = Date()
            let startDate = self.calendar.date(byAdding: .day, value: -6, to: endDate)!
            
            statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { [weak self] statistics, stop in
                var dataValue = HealthDataTypeValue(startDate: statistics.startDate, endDate: statistics.endDate, value: 0)
                
                if let quantity = getStatisticsQuantity(for: statistics, with: statisticsOptions),
                   let identifier = self?.dataTypeIdentifier,
                   let unit = preferredUnit(for: identifier) {
                    dataValue.value = quantity.doubleValue(for: unit)
                }
                
                self?.dataValues.append(dataValue)
            }
            
            completion()
        }
        
        // Handle initial query results
        query.initialResultsHandler = { query, statisticsCollection, error in
            if let statisticsCollection = statisticsCollection {
                updateUIWithStatistics(statisticsCollection)
            }
        }
        
        // Handle ongoing query results updates
        query.statisticsUpdateHandler = { query, statistics, statisticsCollection, error in
            if let statisticsCollection = statisticsCollection {
                updateUIWithStatistics(statisticsCollection)
            }
        }
        
        // Execute query on the HealthStore
        healthStore.execute(query)
        self.query = query
    }
}


// MARK: - UITableViewDataSource

extension WeeklyQuantitySampleTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataValues.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier) as? DataTypeTableViewCell else {
            return DataTypeTableViewCell()
        }
        
        let dataValue = dataValues[indexPath.row]
        
        cell.textLabel?.text = formattedValue(dataValue.value, typeIdentifier: dataTypeIdentifier)
        cell.detailTextLabel?.text = dateFormatter.string(from: dataValue.startDate)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let dataTypeTitle = getDataTypeName(for: dataTypeIdentifier),
              showGroupedTableViewTitle,
              !dataValues.isEmpty else {
            return nil
        }
        
        return String(format: "%@ %@", dataTypeTitle, "Samples")
    }
}


// MARK: - HealthDataTableViewControllerDelegate

extension WeeklyQuantitySampleTableViewController: HealthDataTableViewControllerDelegate {
    
    /// Handle a value corresponding to incoming HealthKit data.
    func didAddNewData(with value: Double) {
        guard let sample = processHealthSample(with: value) else { return }

        HealthData.saveHealthData([sample]) { [weak self] success, error in
            
            if let error = error {
                print("DataTypeTableViewController didAddNewData error:", error.localizedDescription)
            }
            
            if success {
                print("Successfully saved a new sample!", sample)
                DispatchQueue.main.async { [weak self] in
                    self?.reloadData()
                }
            } else {
                print("Error: Could not save new sample.", sample)
            }
        }
    }
    
    private func processHealthSample(with value: Double) -> HKObject? {
        let dataTypeIdentifier = self.dataTypeIdentifier
        
        guard let sampleType = getSampleType(for: dataTypeIdentifier),
              let unit = preferredUnit(for: dataTypeIdentifier) else { return nil }
        
        let now = Date()
        let start = now
        let end = now
        
        var optionalSample: HKObject?
        
        if let quantityType = sampleType as? HKQuantityType {
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: end)
            optionalSample = quantitySample
        }
        
        if let categoryType = sampleType as? HKCategoryType {
            let categorySample = HKCategorySample(type: categoryType, value: Int(value), start: start, end: end)
            optionalSample = categorySample
        }
        
        return optionalSample
    }
}


// MARK: - SettingsTracking

extension WeeklyQuantitySampleTableViewController: SettingsTracking {
    func healthIntegrationIsEnabledChanged() {
        if AppSettings.shared.healthIntegrationIsEnabled {
            configureHKQuery()
        } else {
            stopHKQuery()
            query = nil
            dataValues.removeAll()
            reloadData()
        }
    }
}
