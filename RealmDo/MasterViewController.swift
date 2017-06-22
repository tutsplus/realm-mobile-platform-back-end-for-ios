//
//  MasterViewController.swift
//  RealmDo
//
//  Created by Doron Katz on 6/8/17.
//  Copyright © 2017 Doron Katz. All rights reserved.
//

import UIKit
import RealmSwift

class MasterViewController: UITableViewController {
    
    var realm : Realm!
    var notificationToken: NotificationToken!
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var remindersList = List<Reminder>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        // You should make the username and password user-input supported
        SyncUser.logIn(with: .usernamePassword(username: "doron@doronkatz.com", password: "test123", register: false), server: URL(string: "http://127.0.0.1:9080")!) { user, error in
            guard let user = user else {
                fatalError(String(describing: error))
            }
            
            DispatchQueue.main.async(execute: {
                // Open Realm
                let configuration = Realm.Configuration(
                    syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://127.0.0.1:9080/~/realmDoApp")!)
                )
                self.realm = try! Realm(configuration: configuration)
                // Set realm notification block
                
                
                self.notificationToken = self.realm.addNotificationBlock{ _ in
                    self.updateRemindersList()
                }
                self.updateRemindersList()
            })
        }
        

    }
    
    
    func updateRemindersList(){
        if self.remindersList.realm == nil{
            self.remindersList = self.realm.objects(Reminder.self).reduce(List<Reminder>()) { (list, element) -> List<Reminder> in
                list.append(element)
                return list
            }

        }
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    deinit {
        notificationToken.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return remindersList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let item = remindersList[indexPath.row]
        
        cell.textLabel!.text = item.name
        cell.textLabel!.textColor = item.done == false ? UIColor.black : UIColor.lightGray
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        let item = remindersList[indexPath.row]
        try! self.realm.write({
            item.done = !item.done
        })
        
        //refresh rows
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
    }
    // [1]
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // [2]
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete){
            let item = remindersList[indexPath.row]
            try! self.realm.write({
                self.realm.delete(item)
            })
            
        }
        
    }
    
}

extension MasterViewController{
    @IBAction func addReminder(_ sender: Any) {
        
        let alertVC : UIAlertController = UIAlertController(title: "New Reminder", message: "What do you want to remember?", preferredStyle: .alert)
        
        alertVC.addTextField { (UITextField) in
            
        }
        
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .destructive, handler: nil)
        
        alertVC.addAction(cancelAction)
        
        //Alert action closure
        let addAction = UIAlertAction.init(title: "Add", style: .default) { (UIAlertAction) -> Void in
            
            let textFieldReminder = (alertVC.textFields?.first)! as UITextField
            
            let reminderItem = Reminder()
            reminderItem.name = textFieldReminder.text!
            reminderItem.done = false
            
            // We are adding the reminder to our database
            try! self.realm?.write {
                self.realm.add(reminderItem)
            }
        }
        
        alertVC.addAction(addAction)
        
        present(alertVC, animated: true, completion: nil)
        
    }
}
