//
//  DataTypeTableViewCell.swift
//  HealthKitTest
//
//  Created by David Wright on 2/16/21.
//

import UIKit

/// A table view cell with a title and detail value label.
class DataTypeTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
