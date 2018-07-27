//
//  ListOfGamesViewController.swift
//  TurnBasedTest
//
//  Created by Markos Hatzitaskos on 350/12/15.
//  Copyright © 2015 Markos Hatzitaskos. All rights reserved.
//

import UIKit
import GameKit

class ListOfGamesViewController: UITableViewController {
    
    var refreshTable = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self , selector: #selector(ListOfGamesViewController.reloadTable), name: NSNotification.Name(rawValue: "kReloadMatchTable"), object: nil)
        NotificationCenter.default.addObserver(self , selector: #selector(ListOfGamesViewController.reloadMatches), name: NSNotification.Name(rawValue: "kReloadMatches"), object: nil)

        refreshTable.addTarget(self, action: #selector(ListOfGamesViewController.reloadMatches), for: UIControlEvents.valueChanged)
        refreshTable.tintColor = UIColor.gray
        refreshTable.attributedTitle = NSAttributedString(string: "LOADING", attributes: [kCTForegroundColorAttributeName as NSAttributedStringKey : UIColor.gray])
        refreshTable.backgroundColor = UIColor.clear
        tableView.addSubview(refreshTable)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func reloadMatches() {
                
        GameCenterSingleton.sharedInstance.reloadMatches({
            (matches: [String:[GKTurnBasedMatch]]?) in
            
            if matches != nil {
                
                print("")
                print("Matches loaded")
                
            } else {
                
                print("")
                print("There were no matches to load or some error occured")
                
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
            self.refreshTable.endRefreshing()
        })
    }
    
    @objc func reloadTable() {
        print("")
        print("Reloading list of games table")
        
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //let cell = tableView.cellForRowAtIndexPath(indexPath) as! GameCell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {

        return 6
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            if let inSearchingModeMatches = GameCenterSingleton.sharedInstance.matchDictionary["inSearchingModeMatches"] {
                return inSearchingModeMatches.count
            } else {
                return 0
            }
        case 1:
            if let inInvitationModeMatches = GameCenterSingleton.sharedInstance.matchDictionary["inInvitationModeMatches"] {
                return inInvitationModeMatches.count
            } else {
                return 0
            }
        case 2:
            if let inWaitingForIntivationReplyModeMatches = GameCenterSingleton.sharedInstance.matchDictionary["inWaitingForIntivationReplyModeMatches"] {
                return inWaitingForIntivationReplyModeMatches.count
            } else {
                return 0
            }
        case 3:
            if let localPlayerTurnMatches = GameCenterSingleton.sharedInstance.matchDictionary["localPlayerTurnMatches"] {
                return localPlayerTurnMatches.count
            } else {
                return 0
            }
        case 4:
            if let opponentTurnMatches = GameCenterSingleton.sharedInstance.matchDictionary["opponentTurnMatches"] {
                return opponentTurnMatches.count
            } else {
                return 0
            }
        case 5:
            if let endedMatches = GameCenterSingleton.sharedInstance.matchDictionary["endedMatches"] {
                return endedMatches.count
            } else {
                return 0
            }
        default:
            return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath)
            as! GameCell
        
        switch indexPath.section {
        case 0:
            if let inSearchingModeMatches = GameCenterSingleton.sharedInstance.matchDictionary["inSearchingModeMatches"] {
                cell.match = inSearchingModeMatches[indexPath.row]
                cell.opponentLabel.text = "Random Opponent"
                cell.mode = MatchMode.inSearchingModeMatches
            }
        case 1:
            if let inInvitationModeMatches = GameCenterSingleton.sharedInstance.matchDictionary["inInvitationModeMatches"] {
                cell.match = inInvitationModeMatches[indexPath.row]
                let opponent = GameCenterSingleton.sharedInstance.findParticipantsForMatch(cell.match!)?.opponent
                cell.opponentLabel.text = opponent?.player?.alias
                cell.mode = MatchMode.inInvitationModeMatches
            }
        case 2:
            if let inWaitingForIntivationReplyModeMatches = GameCenterSingleton.sharedInstance.matchDictionary["inWaitingForIntivationReplyModeMatches"] {
                cell.match = inWaitingForIntivationReplyModeMatches[indexPath.row]
                let opponent = GameCenterSingleton.sharedInstance.findParticipantsForMatch(cell.match!)?.opponent
                cell.opponentLabel.text = opponent?.player?.alias
                cell.mode = MatchMode.inWaitingForIntivationReplyModeMatches
            }
        case 3:
            if let localPlayerTurnMatches = GameCenterSingleton.sharedInstance.matchDictionary["localPlayerTurnMatches"] {
                cell.match = localPlayerTurnMatches[indexPath.row]
                let opponent = GameCenterSingleton.sharedInstance.findParticipantsForMatch(cell.match!)?.opponent
                cell.opponentLabel.text = opponent?.player?.alias
                cell.mode = MatchMode.localPlayerTurnMatches
                
                print("match in cell \(indexPath.section) \(indexPath.row) \(cell.match)")
            }
        case 4:
            if let opponentTurnMatches = GameCenterSingleton.sharedInstance.matchDictionary["opponentTurnMatches"] {
                cell.match = opponentTurnMatches[indexPath.row]
                let opponent = GameCenterSingleton.sharedInstance.findParticipantsForMatch(cell.match!)?.opponent
                cell.opponentLabel.text = opponent?.player?.alias
                cell.mode = MatchMode.opponentTurnMatches
            }
        case 5:
            if let endedMatches = GameCenterSingleton.sharedInstance.matchDictionary["endedMatches"] {
                cell.match = endedMatches[indexPath.row]
                let opponent = GameCenterSingleton.sharedInstance.findParticipantsForMatch(cell.match!)?.opponent
                cell.opponentLabel.text = opponent?.player?.alias
                cell.mode = MatchMode.endedMatches
            }
        default:
            break
        }
        
        cell.updateButtons()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "GameHeaderCell") as! GameHeaderCell
        headerCell.backgroundColor = UIColor.lightGray
        
        switch (section) {
        case 0:
            headerCell.label.text = "Searching for opponent..."
        case 1:
            headerCell.label.text = "Invited by opponent"
        case 2:
            headerCell.label.text = "Invited opponent & waiting"
        case 3:
            headerCell.label.text = "My turn"
        case 4:
            headerCell.label.text = "Opponent's turn & waiting"
        case 5:
            headerCell.label.text = "Ended matches"
        default:
            headerCell.label.text = "Other"
        }
        
        return headerCell
    }
}
