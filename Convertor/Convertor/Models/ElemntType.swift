//
//  ElemntType.swift
//  Convertor
//
//  Created by Александр Арсенюк on 27.12.2020.
//

import Foundation

enum ElementType: String, CaseIterable {
    case tableView
    case tableViewCell
    case imageView
    case label
    case button
    case view
    case segmentedControl
    case switchControl = "switch"
    case textField
    case textView
    case activityIndicatorView
    case pageControl
    case collectionView
    case collectionViewCell
    case stackView
    case viewController
}
