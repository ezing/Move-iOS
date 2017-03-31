//
//  ChoseDeviceController.swift
//  Move App
//
//  Created by Jiang Duan on 17/1/20.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit

class ChoseDeviceController: UITableViewController {

    @IBOutlet weak var skipBarBtnItem: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!
    
    @IBOutlet weak var dev1Label: UILabel!
    @IBOutlet weak var dev2Label: UILabel!
    @IBOutlet weak var dev3Label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navItem.title = R.string.localizable.choose_device()
        skipBarBtnItem.title = R.string.localizable.skip()
        
        dev1Label.text = R.string.localizable.id_device_type_kids_watch2()
        dev2Label.text = R.string.localizable.id_device_type_mb12()
        dev3Label.text = R.string.localizable.id_device_type_mb22()
    }

    
}
