//
//  CollectionViewCell.swift
//  Lupy
//
//  Created by Agree Ahmed on 4/28/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

class FilterViewCell: UICollectionViewCell {
    private var _filterSelected = false
    var filterSelected: Bool {
        get {
            return _filterSelected
        }
        set(newValue) {
            _filterSelected = newValue
            selectedBar.hidden = !(_filterSelected)
        }
    }
    
    private var _name = ""
    var name: String {
        get {
            return _name
        }
        set(newValue) {
            _name = newValue
            nameLabel!.text = newValue
        }
    }
    
    var _image: CIImage?
    var image: CIImage? {
        get {
            return _image
        }
        set(newValue) {
            _image = newValue
            preview.image = UIImage(CIImage: _image!)
        }
    }
    
    @IBOutlet weak var preview: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectedBar: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func loadCell(image: CIImage, name: String, selected: Bool){
        self.image = image
        self.name = name
        self.filterSelected = selected
        print("Loading collection cell")
    }
}
