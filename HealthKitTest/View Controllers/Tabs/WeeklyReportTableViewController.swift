//
//  WeeklyReportTableViewController.swift
//  HealthKitTest
//
//  Created by David Wright on 2/15/21.
//

import UIKit
import HealthKit
import CareKitUI

class WeeklyReportTableViewController: UITableViewController {
    
    static let cellIdentifier = "DataTypeTableViewCell"
    
    // MARK: - Properties
    
    var dataTypeIdentifier: String = HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue
    var dataValues: [HealthDataTypeValue] = []
    
    var queryPredicate: NSPredicate? = nil
    var queryAnchor: HKQueryAnchor? = nil
    var queryLimit: Int = HKObjectQueryNoLimit
    
    public var showGroupedTableViewTitle: Bool = false
    
    /// The date from the latest server response.
    private var dateLastUpdated: Date?
    
    // MARK: - UI Properties
    
    lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
        
    lazy var chartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.applyHeaderStyle()
        return chartView
    }()
    
    lazy var emptyDataView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let inset: CGFloat = 20
    let itemSpacing: CGFloat = 12
    let itemSpacingWithTitle: CGFloat = 0
    
    private var chartViewBottomConstraint: NSLayoutConstraint?
    
    // MARK: Initializers
    
    init() {
        super.init(style: .insetGrouped)
        
        // Set weekly predicate
        queryPredicate = createLastWeekPredicate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationController()
        setUpViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Authorization
        if !dataValues.isEmpty { return }
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypeIdentifiers: [dataTypeIdentifier]) { success in
            if success {
                // Perform the query and reload the data.
                self.loadData()
            }
        }
    }
    
    override func updateViewConstraints() {
        chartViewBottomConstraint?.constant = showGroupedTableViewTitle ? itemSpacingWithTitle : itemSpacing
        
        super.updateViewConstraints()
    }
    
    func setUpNavigationController() {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func setUpViewController() {
        title = tabBarItem.title
        setUpHeaderView()
        setUpTableView()
        setUpFetchButton()
        setUpRefreshControl()
    }
    
    func setUpTableView() {
        tableView.register(DataTypeTableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        showGroupedTableViewTitle = true
        
        tableView.addSubview(emptyDataView)
        
        // Add EmptyDataView Constraints
//        emptyDataView.leadingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.leadingAnchor, constant: inset).isActive = true
//        emptyDataView.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor, constant: -inset).isActive = true
//        emptyDataView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: itemSpacing).isActive = true
//        emptyDataView.bottomAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.bottomAnchor, constant: -inset).isActive = true
        
        emptyDataView.leadingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.leadingAnchor).isActive = true
        emptyDataView.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor).isActive = true
        emptyDataView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        emptyDataView.bottomAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    private func setUpHeaderView() {
        tableView.tableHeaderView = headerView
        headerView.addSubview(chartView)
        
        // Add HeaderView Constraints
        headerView.leadingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.leadingAnchor, constant: inset).isActive = true
        headerView.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor, constant: -inset).isActive = true
        headerView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: itemSpacing).isActive = true
        headerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        
        // Add ChartView Constraints
        chartView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        chartView.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
        
        let trailing = chartView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor)
        trailing.priority -= 1
        trailing.isActive = true
        
        let bottomConstant: CGFloat = showGroupedTableViewTitle ? itemSpacingWithTitle : itemSpacing
        let bottom = chartView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -bottomConstant)
        bottom.priority -= 1
        bottom.isActive = true
        chartViewBottomConstraint = bottom
    }
    
    private func setUpRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    private func setUpFetchButton() {
        let barButtonItem = UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(didTapFetchButton))
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    // MARK: - Selectors
    
    @objc func didTapFetchButton() {
        fetchNetworkData()
    }
    
    @objc private func refreshControlValueChanged() {
        loadData()
    }
    
    // MARK: - Data Life Cycle
    
    func reloadData() {
        reloadChartView()
        reloadTableView()
        
        // Change axis to use weekdays for six-minute walk sample
        DispatchQueue.main.async {
            self.chartView.graphView.horizontalAxisMarkers = createHorizontalAxisMarkers()
            
            if let dateLastUpdated = self.dateLastUpdated {
                self.chartView.headerView.detailLabel.text = createChartDateLastUpdatedLabel(dateLastUpdated)
            }
        }
    }
    
    private func reloadTableView() {
        self.dataValues.isEmpty ? self.setEmptyDataView() : self.removeEmptyDataView()
        self.dataValues.sort { $0.startDate > $1.startDate }
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    private func setEmptyDataView() {
        let title = "Weekly Report"
        let subtitle = "No data recorded. Please add some health data."
        let image = UIImage(systemName: "doc.text.below.ecg.fill")
        emptyDataView.addSplashScreen(title: title, subtitle: subtitle, image: image)
    }
    
    private func removeEmptyDataView() {
        emptyDataView.removeSplashScreen()
    }
    
    // MARK: - Date Formatters
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
}


// MARK: - Network

extension WeeklyReportTableViewController {
    
    func fetchNetworkData() {
//        Network.pull() { [weak self] (serverResponse) in
//            self?.handleServerResponse(serverResponse)
//        }
        Network.pull() { [weak self] (serverResponse) in
            self?.dateLastUpdated = serverResponse.date
            self?.queryPredicate = createLastWeekPredicate(from: serverResponse.date)
            self?.handleServerResponse(serverResponse)
        }
    }
    
    /// Handle a response fetched from a remote server. This function will also save any HealthKit samples and update the UI accordingly.
    func handleServerResponse(_ serverResponse: ServerResponse) {
//        loadData()
        let weeklyReport = serverResponse.weeklyReport
        let addedSamples = weeklyReport.samples.map { (serverHealthSample) -> HKQuantitySample in
                        
            // Set the sync identifier and version
            var metadata = [String: Any]()
            let sampleSyncIdentifier = String(format: "%@_%@", weeklyReport.identifier, serverHealthSample.syncIdentifier)
            
            metadata[HKMetadataKeySyncIdentifier] = sampleSyncIdentifier
            metadata[HKMetadataKeySyncVersion] = serverHealthSample.syncVersion
            
            // Create HKQuantitySample
            let quantity = HKQuantity(unit: .meter(), doubleValue: serverHealthSample.value)
            let sampleType = HKQuantityType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!
            let quantitySample = HKQuantitySample(type: sampleType,
                                                  quantity: quantity,
                                                  start: serverHealthSample.startDate,
                                                  end: serverHealthSample.endDate,
                                                  metadata: metadata)
            
            return quantitySample
        }
        
        HealthData.healthStore.save(addedSamples) { (success, error) in
            if success {
                self.loadData()
            }
        }
    }
}


// MARK: - UITableViewDataSource

extension WeeklyReportTableViewController {
        
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


// MARK: - HealthQueryDataSource

extension WeeklyReportTableViewController {
    
    /// Perform a query and reload the data upon completion.
    func loadData() {
        performQuery {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }
    
    func performQuery(completion: @escaping () -> Void) {
        guard let sampleType = getSampleType(for: dataTypeIdentifier) else { return }
        
        let anchoredObjectQuery = HKAnchoredObjectQuery(type: sampleType,
                                                        predicate: queryPredicate,
                                                        anchor: queryAnchor,
                                                        limit: queryLimit) {
            (query, samplesOrNil, deletedObjectsOrNil, anchor, errorOrNil) in
            
            guard let samples = samplesOrNil else { return }
            
            self.dataValues = samples.map { (sample) -> HealthDataTypeValue in
                var dataValue = HealthDataTypeValue(startDate: sample.startDate,
                                                    endDate: sample.endDate,
                                                    value: .zero)
                if let quantitySample = sample as? HKQuantitySample,
                   let unit = preferredUnit(for: quantitySample) {
                    dataValue.value = quantitySample.quantity.doubleValue(for: unit)
                }
                
                return dataValue
            }
            
            completion()
        }
        
        HealthData.healthStore.execute(anchoredObjectQuery)
    }
        
    /// Override `reloadData` to update `chartView` before reloading `tableView` data.
    private func reloadChartView() {
        DispatchQueue.main.async {
            self.chartView.applyDefaultConfiguration()
            
            let dateLastUpdated = Date()
            self.chartView.headerView.detailLabel.text = createChartDateLastUpdatedLabel(dateLastUpdated)
            self.chartView.headerView.titleLabel.text = getDataTypeName(for: self.dataTypeIdentifier)
            
            self.dataValues.sort { $0.startDate < $1.startDate }
            
            let sampleStartDates = self.dataValues.map { $0.startDate }
            
            self.chartView.graphView.horizontalAxisMarkers = createHorizontalAxisMarkers(for: sampleStartDates)
            
            let dataSeries = self.dataValues.compactMap { CGFloat($0.value) }
            guard
                let unit = preferredUnit(for: self.dataTypeIdentifier),
                let unitTitle = getUnitDescription(for: unit)
            else {
                return
            }
            
            self.chartView.graphView.dataSeries = [
                OCKDataSeries(values: dataSeries, title: unitTitle)
            ]
            
            self.view.layoutIfNeeded()
        }
    }
}
