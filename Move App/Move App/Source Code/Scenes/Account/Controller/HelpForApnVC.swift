//
//  HelpForApnVC.swift
//  Move App
//
//  Created by Wuju Zheng on 2017/4/24.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit



class HelpForApnVC: UIViewController {
    
    
    @IBOutlet weak var tipLab: UILabel!
    
    
    
    @IBOutlet weak var step1TextLab: UILabel!
    @IBOutlet weak var step2TextLab: UILabel!
    @IBOutlet weak var step3TextLab: UILabel!

    
    private func initializeI18N() {
        self.title = R.string.localizable.id_help_for_apn()
        
        step1TextLab.text = R.string.localizable.id_info_apn_not_paired_1()
        step2TextLab.text = R.string.localizable.id_info_apn_not_paired_2()
        step3TextLab.text = R.string.localizable.id_info_apn_not_paired_3()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeI18N()
        
        tipLab.text = "If your watch has not be paired"
        
        
    }
    
    
    
    
    
    
}
