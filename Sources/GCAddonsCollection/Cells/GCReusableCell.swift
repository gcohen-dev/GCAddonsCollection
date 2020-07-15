//
//  File.swift
//  
//
//  Created by Guy cohen on 13/07/2020.
//

import Foundation
import UIKit

protocol GCReuseableCell {
    static var reuseIdentifier: String { get }
}

extension GCReuseableCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionView {
    func registerReuseable(cell: GCReuseableCell.Type) {
        let cellNib = UINib(nibName: cell.reuseIdentifier, bundle: nil)
        self.register(cellNib, forCellWithReuseIdentifier: cell.reuseIdentifier)
    }
}
