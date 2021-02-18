//
//  DataTypeCollectionViewCell.swift
//  HealthKitTest
//
//  Created by David Wright on 2/18/21.
//

import UIKit
import CareKitUI

class DataTypeCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var dataTypeIdentifier: String!
    var statisticalValues: [Double] = []
    
    var chartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    // MARK: - Initializers
    
    init(dataTypeIdentifier: String) {
        self.dataTypeIdentifier = dataTypeIdentifier
        
        super.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setUpView() {
        contentView.addSubview(chartView)
        
        setUpConstraints()
    }
    
    private func setUpConstraints() {
        var constraints: [NSLayoutConstraint] = []
        
        constraints += createChartViewConstraints()
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func createChartViewConstraints() -> [NSLayoutConstraint] {
        let leading = chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let top = chartView.topAnchor.constraint(equalTo: contentView.topAnchor)
        let trailing = chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        let bottom = chartView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        
        trailing.priority -= 1
        bottom.priority -= 1
        
        return [leading, top, trailing, bottom]
    }
    
    // MARK: - Update UI
    
    func updateChartView(with dataTypeIdentifier: String, values: [Double]) {
        self.dataTypeIdentifier = dataTypeIdentifier
        self.statisticalValues = values
        
        // Update headerView
        chartView.headerView.titleLabel.text = getDataTypeName(for: dataTypeIdentifier) ?? "Data"
        chartView.headerView.detailLabel.text = createChartWeeklyDateRangeLabel()
        
        // Update graphView
        chartView.applyDefaultConfiguration()
        chartView.graphView.horizontalAxisMarkers = createHorizontalAxisMarkers()
        
        // Update graphView dataSeries
        let dataPoints: [CGFloat] = statisticalValues.map { CGFloat($0) }
        
        guard
            let unit = preferredUnit(for: dataTypeIdentifier),
            let unitTitle = getUnitDescription(for: unit)
        else {
            return
        }
        
        chartView.graphView.dataSeries = [
            OCKDataSeries(values: dataPoints, title: unitTitle)
        ]
    }
}


// MARK: - Chart View Style

extension OCKCartesianChartView {
    /// Apply standard graph configuration to set axes and style in a default configuration.
    func applyDefaultConfiguration() {
        headerView.detailLabel.textColor = .secondaryLabel
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        
        graphView.numberFormatter = numberFormatter
        graphView.yMinimum = 0
    }
    
    func applyHeaderStyle() {
        headerView.detailLabel.textColor = .secondaryLabel
        customStyle = ChartHeaderStyle()
    }
}

/// A styler for using the chart as a header with an `.insetGrouped` tableView.
struct ChartHeaderStyle: OCKStyler {
    var appearance: OCKAppearanceStyler {
        NoShadowAppearanceStyle()
    }
}

struct NoShadowAppearanceStyle: OCKAppearanceStyler {
    var shadowOpacity1: Float = 0
    var shadowRadius1: CGFloat = 0
    var shadowOffset1: CGSize = .zero
}
