//
//  ChartView.swift
//  HealthKitTest
//
//  Created by David Wright on 2/18/21.
//

import UIKit
import CareKitUI

protocol ChartViewDataSource: class {
    var chartValues: [CGFloat] { get }
}

//extension ChartViewDataSource {
//    var values: [CGFloat] {
//        get { values }
//        set { [CGFloat]() }
//    }
//}

class ChartView: UIView {
    
    // MARK: - Properties
    
    var title: String?
    var subtitle: String?
    var unitDisplayName: String?
    var horizontalAxisMarkers: [String]?
    
    var dataSource: ChartViewDataSource?
    
    private var chartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        addSubview(chartView)
        
        let leading = chartView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let top = chartView.topAnchor.constraint(equalTo: topAnchor)
        let trailing = chartView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let bottom = chartView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        trailing.priority -= 1
        bottom.priority -= 1
        
        NSLayoutConstraint.activate([leading, top, trailing, bottom])
    }
    
    // MARK: - Update UI
    
    func updateChartView() {
        let values = dataSource?.chartValues ?? []
        
        // Update headerView
        chartView.headerView.titleLabel.text = title
        chartView.headerView.detailLabel.text = subtitle
        
        // Update graphView
        let horizontalAxisMarkers = self.horizontalAxisMarkers ?? Array(repeating: "", count: values.count)
        chartView.graphView.horizontalAxisMarkers = horizontalAxisMarkers
        applyDefaultConfiguration()
        
        // Update graphView dataSeries
        let unitTitle = unitDisplayName ?? ""
        let ockDataSeries = OCKDataSeries(values: values, title: unitTitle)
        chartView.graphView.dataSeries = [ockDataSeries]
    }
    
    /// Apply standard graph configuration to set axes and style in a default configuration.
    private func applyDefaultConfiguration() {
        chartView.headerView.detailLabel.textColor = .secondaryLabel
        chartView.graphView.numberFormatter = numberFormatter
        chartView.graphView.yMinimum = 0
    }
    
    // MARK: - Formatters
    
    private let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        return numberFormatter
    }()
}
