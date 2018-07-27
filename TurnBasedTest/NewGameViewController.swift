//
//  NewGameViewController.swift
//  TurnBasedTest
//
//  Created by Markos Hatzitaskos on 350/12/15.
//  Copyright © 2015 Markos Hatzitaskos. All rights reserved.
//

import UIKit
import GameKit

class NewGameViewController: UITableViewController {

    var hud:MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewGameViewController.reloadTable), name: NSNotification.Name(rawValue: "kFriendsDataReceived"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func reloadTable() {
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return GameCenterSingleton.sharedInstance.friends.count + 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewGameCell", for: indexPath)

        // Configure the cell...
        if indexPath.row == 0 {
            
            if let nameLabel = cell.viewWithTag(101) as? UILabel {
                nameLabel.text = "RANDOM OPPONENT"
            }
            if let imageView = cell.viewWithTag(100) as? UIImageView {
                imageView.backgroundColor = UIColor.gray
            }
            
        } else {
            
            let friends = GameCenterSingleton.sharedInstance.friends
            let player = friends[indexPath.row-1] as GKPlayer
            
            if let nameLabel = cell.viewWithTag(101) as? UILabel {
                nameLabel.text = player.alias
            }
            if let imageView = cell.viewWithTag(100) as? UIImageView {
                ProfilePhoto.loadPhoto(player, view: imageView, smallSize: true)
            }
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.hud?.labelText = "INITIALIZING MATCH"
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.row == 0 {
            
            GameCenterSingleton.sharedInstance.initRandomMatch() {
                match in
                
                if let newMatch = match {
                    
                    //This is a dummy call. In a real game this should be called
                    //at the end of the first turn.
                    self.playFirstTurn(newMatch)
                }
            }
            
        } else {
            
            let friends = GameCenterSingleton.sharedInstance.friends
            GameCenterSingleton.sharedInstance.initMatch(friends[indexPath.row-1]) {
                match in
                
                if let newMatch = match {
                    
                    //This is a dummy call. In a real game this should be called
                    //at the end of the first turn.
                    self.playFirstTurn(newMatch)
                }
            }
            
        }
    }
    
    //This function acts as a dummy function that simulates a turn in the turn based game.
    //In a real game, the turn would first be played by the user, a TurnDataObject would be
    //created with the correct information and then the endTurn function would be called.
    func playFirstTurn(_ match: GKTurnBasedMatch) {
        let newTurn = TurnDataObject(playerID: GKLocalPlayer.localPlayer().playerID!, word: "Word", substring: "o", substringStart: 1, subStringLength: 1, pointsEarned: 4, turn: 1)
        
        //May pass any message that is necessary for the receiver (ex. playerGroup)
        match.message = ""
        
        GameCenterSingleton.sharedInstance.endTurn(match, newTurn: newTurn) {
//            _ in
            
            self.hud?.hide(true)
        }
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
