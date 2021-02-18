//
//  ChartView.swift
//  HealthKitTest
//
//  Created by David Wright on 2/18/21.
//

import UIKit
import CareKitUI

class ChartView: UIView {
    
    // MARK: - Properties
    
    var title: String?
    var subtitle: String?
    var unitDisplayName: String?
    var horizontalAxisMarkers: [String]?
    
    var statisticalValues: [Double] = []
    
    var chartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUpView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setUpView() {
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
    
    func updateChartView(with values: [Double]) {
        self.statisticalValues = values
        
        // Update headerView
        chartView.headerView.titleLabel.text = title
        chartView.headerView.detailLabel.text = subtitle
        
        // Update graphView
        chartView.applyDefaultConfiguration()
        chartView.graphView.horizontalAxisMarkers = horizontalAxisMarkers ?? Array(repeating: "", count: values.count)
        
        // Update graphView dataSeries
        let dataPoints: [CGFloat] = statisticalValues.map { CGFloat($0) }
        let unitTitle = unitDisplayName ?? ""
        
        chartView.graphView.dataSeries = [
            OCKDataSeries(values: dataPoints, title: unitTitle)
        ]
    }
}


// MARK: - Chart View Style

extension ChartView {
    /// Apply standard graph configuration to set axes and style in a default configuration.
    func applyDefaultConfiguration() {
        chartView.headerView.detailLabel.textColor = .secondaryLabel
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        
        chartView.graphView.numberFormatter = numberFormatter
        chartView.graphView.yMinimum = 0
    }
    
    func applyHeaderStyle() {
        chartView.headerView.detailLabel.textColor = .secondaryLabel
        chartView.customStyle = ChartHeaderStyle()
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
}
