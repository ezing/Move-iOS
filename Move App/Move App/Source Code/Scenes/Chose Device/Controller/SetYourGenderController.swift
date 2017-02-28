//
//  SetYourGenderController.swift
//  Move App
//
//  Created by Vernon yellow on 17/2/16.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit

class SetYourGenderController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        girlBtn.isSelected = true
    }
    
    @IBOutlet weak var girlBtn: UIButton!
    @IBOutlet weak var boyBtn: UIButton!
    @IBAction func BackAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func girAction(_ sender: UIButton) {
        sender.isSelected = true
        boyBtn.isSelected = false
    }
    
    @IBAction func boyAction(_ sender: UIButton) {
        sender.isSelected = true
        girlBtn.isSelected = false
    }
    

    
}
