//
//  GameCell.swift
//  TurnBasedTest
//
//  Created by Markos Hatzitaskos on 350/12/15.
//  Copyright © 2015 Markos Hatzitaskos. All rights reserved.
//

import UIKit
import GameKit

class GameCell: UITableViewCell {
    
    var match: GKTurnBasedMatch?
    var mode: MatchMode?
    @IBOutlet weak var opponentLabel: UILabel!
    @IBOutlet weak var acceptPlayButton: UIButton!
    @IBOutlet weak var declineQuitButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateButtons() {
        switch mode! {
            
        case MatchMode.inSearchingModeMatches:
            acceptPlayButton.isHidden = true
            acceptPlayButton.setTitle("", for: UIControlState())
            declineQuitButton.isHidden = false
            declineQuitButton.setTitle("Quit", for: UIControlState())
        case MatchMode.inInvitationModeMatches:
            acceptPlayButton.isHidden = false
            acceptPlayButton.setTitle("Accept", for: UIControlState())
            declineQuitButton.isHidden = false
            declineQuitButton.setTitle("Decline", for: UIControlState())
        case MatchMode.inWaitingForIntivationReplyModeMatches:
            acceptPlayButton.isHidden = true
            acceptPlayButton.setTitle("", for: UIControlState())
            declineQuitButton.isHidden = false
            declineQuitButton.setTitle("Quit", for: UIControlState())
        case MatchMode.localPlayerTurnMatches:
            acceptPlayButton.isHidden = false
            acceptPlayButton.setTitle("Play", for: UIControlState())
            declineQuitButton.isHidden = false
            declineQuitButton.setTitle("Quit", for: UIControlState())
        case MatchMode.opponentTurnMatches:
            acceptPlayButton.isHidden = true
            acceptPlayButton.setTitle("", for: UIControlState())
            declineQuitButton.isHidden = false
            declineQuitButton.setTitle("Quit", for: UIControlState())
        case MatchMode.endedMatches:
            acceptPlayButton.isHidden = true
            acceptPlayButton.setTitle("", for: UIControlState())
            declineQuitButton.isHidden = false
            declineQuitButton.setTitle("Remove", for: UIControlState())
        }
        
        if let matchData = match?.matchData {
            
            let currentRound = MatchDataEncoding.decode(matchData).currentRound
            
            if let labelText = opponentLabel.text {
                opponentLabel.text = "\(labelText) - Round: \(currentRound)"
            } else {
                opponentLabel.text = "Random Opponent - Round: \(currentRound)"
            }
            
        }
    }
    
    @IBAction func acceptPlayButtonPressed(_ sender: AnyObject) {
        print("")
        print("acceptPlayButton Pressed")
        
        switch mode! {
            
        case MatchMode.inInvitationModeMatches:
            GameCenterSingleton.sharedInstance.acceptInvitation(match)
            
        case MatchMode.localPlayerTurnMatches:
            playTurn(match!)
            
        default:
            break
        }
    }
    
    @IBAction func declineQuitButtonPressed(_ sender: AnyObject) {
        print("")
        print("declineQuitButton Pressed")
        
        switch mode! {
            
        case MatchMode.inInvitationModeMatches:
            GameCenterSingleton.sharedInstance.declineInvitation(match)
        
        case MatchMode.endedMatches:
            GameCenterSingleton.sharedInstance.removeMatch(match, completion: {})
        
        default:
            
            if match?.currentParticipant?.player?.playerID == GKLocalPlayer.localPlayer().playerID {
                
                //Local player that has pressed the quit button will lose, independent of score
                let outcome = GKTurnBasedMatchOutcome.lost
                
                GameCenterSingleton.sharedInstance.quitMatch(match, localPlayerOutcome: outcome, completion: {})
            } else {
                GameCenterSingleton.sharedInstance.quitMatch(match, localPlayerOutcome: nil, completion: {})
            }
        }
    }
    
    //This function acts as a dummy function that simulates a turn in the turn based game.
    //In a real game, the turn would first be played by the user, a TurnDataObject would be
    //created with the correct information and then the endTurn function would be called.
    func playTurn(_ match: GKTurnBasedMatch) {
        let newTurn = TurnDataObject(playerID: GKLocalPlayer.localPlayer().playerID!, word: "Word", substring: "o", substringStart: 1, subStringLength: 1, pointsEarned: 4, turn: 1)
        
        GameCenterSingleton.sharedInstance.endTurn(match, newTurn: newTurn) {}
    }
}
