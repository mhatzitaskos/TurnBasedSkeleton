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

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateButtons() {
        switch mode! {
            
        case MatchMode.inSearchingModeMatches:
            acceptPlayButton.hidden = true
            acceptPlayButton.setTitle("", forState: UIControlState.Normal)
            declineQuitButton.hidden = false
            declineQuitButton.setTitle("Quit", forState: UIControlState.Normal)
        case MatchMode.inInvitationModeMatches:
            acceptPlayButton.hidden = false
            acceptPlayButton.setTitle("Accept", forState: UIControlState.Normal)
            declineQuitButton.hidden = false
            declineQuitButton.setTitle("Decline", forState: UIControlState.Normal)
        case MatchMode.inWaitingForIntivationReplyModeMatches:
            acceptPlayButton.hidden = true
            acceptPlayButton.setTitle("", forState: UIControlState.Normal)
            declineQuitButton.hidden = false
            declineQuitButton.setTitle("Quit", forState: UIControlState.Normal)
        case MatchMode.localPlayerTurnMatches:
            acceptPlayButton.hidden = false
            acceptPlayButton.setTitle("Play", forState: UIControlState.Normal)
            declineQuitButton.hidden = false
            declineQuitButton.setTitle("Quit", forState: UIControlState.Normal)
        case MatchMode.opponentTurnMatches:
            acceptPlayButton.hidden = true
            acceptPlayButton.setTitle("", forState: UIControlState.Normal)
            declineQuitButton.hidden = false
            declineQuitButton.setTitle("Quit", forState: UIControlState.Normal)
        case MatchMode.endedMatches:
            acceptPlayButton.hidden = true
            acceptPlayButton.setTitle("", forState: UIControlState.Normal)
            declineQuitButton.hidden = false
            declineQuitButton.setTitle("Remove", forState: UIControlState.Normal)
        }
        
        if let matchData = match?.matchData {
            
            let currentRound = MatchDataEncoding.decode(matchData).currentRound
            opponentLabel.text = "\(opponentLabel.text!) - Round: \(currentRound)"
        }
    }
    
    @IBAction func acceptPlayButtonPressed(sender: AnyObject) {
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
    
    @IBAction func declineQuitButtonPressed(sender: AnyObject) {
        print("")
        print("declineQuitButton Pressed")
        
        switch mode! {
            
        case MatchMode.inInvitationModeMatches:
            GameCenterSingleton.sharedInstance.declineInvitation(match)
        
        case MatchMode.endedMatches:
            GameCenterSingleton.sharedInstance.removeMatch(match, completion: {})
        
        default:
            
            if let matchData = match?.matchData {
                
                let data = MatchDataEncoding.decode(matchData)
                
                if match?.currentParticipant?.player?.playerID == GKLocalPlayer.localPlayer().playerID {
                    
                    let outcome: GKTurnBasedMatchOutcome!
                    
                    //Initiator, thus local player won
                    if data.score1 > data.score2 {
                        outcome = GKTurnBasedMatchOutcome.Won
                    
                    //Its a tie
                    } else if data.score1 == data.score2 {
                        outcome = GKTurnBasedMatchOutcome.Tied

                    //Opponent won
                    } else {
                        outcome = GKTurnBasedMatchOutcome.Lost
                    }
                
                    GameCenterSingleton.sharedInstance.quitMatch(match, localPlayerOutcome: outcome, completion: {})
                } else {
                    GameCenterSingleton.sharedInstance.quitMatch(match, localPlayerOutcome: nil, completion: {})
                }
            }
        }
    }
    
    //This function acts as a dummy function that simulates a turn in the turn based game.
    //In a real game, the turn would first be played by the user, a TurnDataObject would be
    //created with the correct information and then the endTurn function would be called.
    func playTurn(match: GKTurnBasedMatch) {
        let newTurn = TurnDataObject(playerID: GKLocalPlayer.localPlayer().playerID!, word: "Word", substring: "o", substringStart: 1, subStringLength: 1, pointsEarned: 4, turn: 1)
        
        GameCenterSingleton.sharedInstance.endTurn(match, newTurn: newTurn) {}
    }
}
