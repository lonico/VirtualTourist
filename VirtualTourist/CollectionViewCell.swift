//
//  CollectionViewCell.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 9/29/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {

    @IBOutlet var image: UIImageView!
    @IBOutlet var title: UILabel!
    
    var photo: Photo! = nil
}
