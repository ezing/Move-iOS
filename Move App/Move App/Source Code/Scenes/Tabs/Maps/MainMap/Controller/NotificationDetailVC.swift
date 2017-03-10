//
//  NotificationDetailVC.swift
//  Move App
//
//  Created by lx on 17/2/20.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit

class NotificationDetailVC: UIViewController , UITableViewDataSource,UITableViewDelegate{

    @IBOutlet weak var tableview: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.tableFooterView = UIView.init(frame: CGRect.zero)

        let nib = UINib(nibName: "NoticeDetailCell", bundle: nil) //nibName指的是我们创建的Cell文件名
        tableview.register(nib, forCellReuseIdentifier: "NoticeDetailCell")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeDetailCell", for: indexPath) as! NoticeDetailCell
        cell.textstr = "dhijsahbjkbdjhbiuqhweijwbgeuhbvwiqdiewbdihbdibcdbicbdhibchsjbnadjiwbeihfbdehwbdhiewbdhiewbdihwebdhibewdhibewhdibewihbdwhebcdsjsadijwbegyfywebdiewjkdnjewbfdiuywdbhwedhbeihdfbewuhbdeiwjbdnjwebrhjbewuhfdbwedjewhdjbewiuydbeiwdeuwhbdehuwbdvuehwbdewdhbewudbeuwbdvuewduew"
        return cell
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}