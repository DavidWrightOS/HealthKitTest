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
    
    static let cellIdentifier = "DataTypeCollectionViewCell"
    
    // MARK: - Properties
    
    let calendar = Calendar.current
    
    var mobilityContent: [String] = [
        HKQuantityTypeIdentifier.stepCount.rawValue,
        HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue
    ]
    
    var queries: [HKAnchoredObjectQuery] = []
    
    var data: [(dataTypeIdentifier: String, values: [Double])] = []
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.register(DataTypeCollectionViewCell.self, forCellWithReuseIdentifier: Self.cellIdentifier)
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    var isLandscape: Bool {
        UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isLandscape ?? false
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForhealthIntegrationIsEnabledChanges()
        setUpViews()
        
        data = mobilityContent.map { ($0, []) }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AppSettings.shared.healthIntegrationIsEnabled {
            setUpQueries()
        } else {
            print("Warning: Unable to configure query. The user has disabled Apple Health integration.")
            reloadData()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        collectionView.setCollectionViewLayout(makeLayout(), animated: true)
    }
    
    // MARK: - Data
    
    func setUpQueries() {
        guard queries.isEmpty else { return }
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypeIdentifiers: mobilityContent) { success in
            if success {
                self.setUpBackgroundObservers()
                self.loadData()
            }
        }
    }
    
    func stopQueries() {
        guard !queries.isEmpty else { return }
        
        print("Stopping HealthKit queries...")
        
        for query in queries {
            HealthData.healthStore.stop(query)
        }
        
        queries.removeAll()
    }
    
    func loadData() {
        performQuery {
            // Dispatch UI updates to the main thread.
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }
    
    func reloadData() {
        collectionView.reloadData()
    }
    
    func setUpBackgroundObservers() {
        data.compactMap { getSampleType(for: $0.dataTypeIdentifier) }.forEach { (sampleType) in
            createAnchoredObjectQuery(for: sampleType)
        }
    }
    
    // MARK: - Create Anchored Object Query
    
    func createAnchoredObjectQuery(for sampleType: HKSampleType) {
        // Customize query parameters
        let predicate = createLastWeekPredicate()
        let limit = HKObjectQueryNoLimit
        
        // Fetch anchor persisted in memory
        let anchor = HealthData.getAnchor(for: sampleType)
        
        // Create HKAnchoredObjecyQuery
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: predicate, anchor: anchor, limit: limit) {
            (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            // Handle error
            if let error = errorOrNil {
                print("HKAnchoredObjectQuery initialResultsHandler with identifier \(sampleType.identifier) error: \(error.localizedDescription)")
                
                return
            }
            
            print("HKAnchoredObjectQuery initialResultsHandler has returned for \(sampleType.identifier)!")
            
            // Update anchor for sample type
            HealthData.updateAnchor(newAnchor, from: query)
            
            Network.push(addedSamples: samplesOrNil, deletedSamples: deletedObjectsOrNil)
        }
        
        // Create update handler for long-running background query
        query.updateHandler = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            // Handle error
            if let error = errorOrNil {
                print("HKAnchoredObjectQuery initialResultsHandler with identifier \(sampleType.identifier) error: \(error.localizedDescription)")
                
                return
            }
            
            print("HKAnchoredObjectQuery initialResultsHandler has returned for \(sampleType.identifier)!")
            
            // Update anchor for sample type
            HealthData.updateAnchor(newAnchor, from: query)
            
            // The results come back on an anonymous background queue.
            Network.push(addedSamples: samplesOrNil, deletedSamples: deletedObjectsOrNil)
        }
        
        HealthData.healthStore.execute(query)
        queries.append(query)
    }
    
    // MARK: - Perform Query
    
    func performQuery(completion: @escaping () -> Void) {
        // Create a query for each data type.
        for (index, item) in data.enumerated() {
            // Set dates
            let now = Date()
            let startDate = getLastWeekStartDate()
            let endDate = now
            
            let predicate = createLastWeekPredicate()
            let dateInterval = DateComponents(day: 1)
            
            // Process data.
            let statisticsOptions = getStatisticsOptions(for: item.dataTypeIdentifier)
            let initialResultsHandler: (HKStatisticsCollection) -> Void = { (statisticsCollection) in
                var values: [Double] = []
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
                    let statisticsQuantity = getStatisticsQuantity(for: statistics, with: statisticsOptions)
                    if let unit = preferredUnit(for: item.dataTypeIdentifier),
                        let value = statisticsQuantity?.doubleValue(for: unit) {
                        values.append(value)
                    }
                }
                
                self.data[index].values = values
                
                completion()
            }
            
            // Fetch statistics.
            HealthData.fetchStatistics(with: HKQuantityTypeIdentifier(rawValue: item.dataTypeIdentifier),
                                       predicate: predicate,
                                       options: statisticsOptions,
                                       startDate: startDate,
                                       interval: dateInterval,
                                       completion: initialResultsHandler)
        }
    }
    
    // MARK: - View Helper Functions
    
    private func setUpViews() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = tabBarItem.title
        view.backgroundColor = .systemBackground
        
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    }
}


// MARK: - UICollectionViewLayout

extension MobilityChartDataViewController {

    private func makeLayout() -> UICollectionViewLayout {
        let verticalMargin: CGFloat = 8
        let horizontalMargin: CGFloat = 20
        let interGroupSpacing: CGFloat = horizontalMargin
        
        let cellHeight = calculateCellHeight(horizontalMargin: horizontalMargin, verticalMargin: verticalMargin)

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(cellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(cellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = interGroupSpacing
        section.contentInsets = .init(top: verticalMargin, leading: horizontalMargin, bottom: verticalMargin, trailing: horizontalMargin)

        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
    
    /// Return a collection view cell height that is equivalent to the smaller dimension of the view's bounds minus margins on each side.
    private func calculateCellHeight(horizontalMargin: CGFloat, verticalMargin: CGFloat) -> CGFloat {
        let widthInset = (horizontalMargin * 2) + view.safeAreaInsets.left + view.safeAreaInsets.right
        var heightInset = (verticalMargin * 2) // safeAreaInsets already accounted for in tabBar bounds.
        
        heightInset += navigationController?.navigationBar.bounds.height ?? 0
        heightInset += tabBarController?.tabBar.bounds.height ?? 0
        
        let cellHeight = isLandscape ? view.bounds.height - heightInset : view.bounds.width - widthInset
        
        return cellHeight
    }
}


// MARK: - UICollectionViewDataSource

extension MobilityChartDataViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let content = data[indexPath.row]
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellIdentifier, for: indexPath) as? DataTypeCollectionViewCell else {
            return DataTypeCollectionViewCell()
        }
        
        cell.updateChartView(with: content.dataTypeIdentifier, values: content.values)
        
        return cell
    }
}


// MARK: - SettingsTracking

extension MobilityChartDataViewController: SettingsTracking {
    func healthIntegrationIsEnabledChanged() {
        if AppSettings.shared.healthIntegrationIsEnabled {
            setUpQueries()
        } else {
            stopQueries()
            queries.removeAll()
            data = mobilityContent.map { ($0, []) }
            reloadData()
        }
    }
}
