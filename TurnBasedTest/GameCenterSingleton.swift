//
//  GameCenterSingleton.swift
//
//  Created by Markos Hatzitaskos on 1/14/15.
//  Copyright (c) 2015 beleApps. All rights reserved.
//

import Foundation
import GameKit

//RESOURCE: https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/GameKit_Guide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008304-CH1-SW1

class GameCenterSingleton:NSObject, GKLocalPlayerListener, UIAlertViewDelegate {
    
    var presentingViewController:TabBarViewController?
    
    var friends = [GKPlayer]()
    var smallProfilePhotosDictionary = [String:UIImage]()
    var normalProfilePhotosDictionary = [String:UIImage]()
    
    var matchDictionary = [String:[GKTurnBasedMatch]]()
    
    class var sharedInstance : GameCenterSingleton {
        /*
         The lazy initializer for a global variable (also for static members of structs and enums)
         is run the first time that global (also static or struct or enum) is accessed, and is launched as dispatch_once
         to make sure that the initialization is atomic.
         This enables a cool way to use dispatch_once in your code: just declare a global variable (or static or struct) with an initializer and mark it private.
        */

        struct Singleton {

            static let instance = GameCenterSingleton()
        }
  
        return Singleton.instance
    }

    //if user is not authenticated Game center's authentication viewController is presented
    func authenticateLocalPlayer() {
        
        self.presentingViewController?.hud = MBProgressHUD.showHUDAddedTo(self.presentingViewController?.view, animated: true)
        self.presentingViewController?.hud?.labelText = "LOADING MATCHES"
        
        NSNotificationCenter.defaultCenter().addObserver(self , selector: "authenticationChanged", name: GKPlayerAuthenticationDidChangeNotificationName, object: nil)
        
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {(viewController : UIViewController?, error : NSError?) -> Void in

            if error != nil {
                
                print("")
                print("GameCenter is unavailable with error: \(error)")
                
                JSSAlertView().show(
                    self.presentingViewController!, // the parent view controller of the alert
                    title: "GameCenter is unavailable" // the alert's title
                )
                
            } else {
                
                if ((viewController) != nil) {
                    
                    self.presentingViewController?.presentViewController(viewController!, animated: true, completion: {
                        finished in
                        
                        print("")
                        print("PLAYER IS NOT AUTHENTICATED: presenting login screen")
                        
                    })
                    
                } else {
                    
                    print("")
                    print("PLAYER \(GKLocalPlayer.localPlayer().alias) IS ALREADY AUTHENTICATED: \(GKLocalPlayer.localPlayer().authenticated)")
                    
                }
            }
        }
    }
    
    func authenticationChanged() {
        
        print("")
        print("AUTHENTICATION CHANGED")
        
        self.presentingViewController?.hud?.hide(true)
        
        if GKLocalPlayer.localPlayer().authenticated {
            
            print("")
            print("Player is authenticated")
            GKLocalPlayer.localPlayer().unregisterAllListeners()
            GKLocalPlayer.localPlayer().registerListener(self)
            
            self.retrieveFriends()
            self.reloadMatches({
                (matches: [String:[GKTurnBasedMatch]]?) in
                
                if matches != nil {
                
                    print("")
                    print("Matches loaded")
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("kMatchesLoaded", object: nil)

                } else {
                    
                    print("")
                    print("There were no matches to load or some error occured")
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("kMatchesLoaded", object: nil)
                }
            })
            
        } else {
            
            if !IJReachability.isConnectedToNetwork(){
                
                print("")
                print("ERROR: no Internet connection")
                
            } else {
                
                print("")
                print("ERROR: GameCenter is not authenticated")
                
            }
            
            
        }
        
    }
    
    //MARK: GKLocalPlayerListener
    
    // Called when it becomes this player's turn.
    // Because of this the app needs to be prepared to handle this even while the player is taking
    // a turn in an existing match. The boolean indicates whether this event launched or brought
    // to forground the app.
    func player(player: GKPlayer, receivedTurnEventForMatch match: GKTurnBasedMatch, didBecomeActive: Bool) {
        
        print("")
        print("Received turn event for match. Did become active \(didBecomeActive)")
        
        if matchDictionary["allMatches"] == nil {
            matchDictionary["allMatches"] = [match]
        } else {
            
            var newMatch = true
            
            let allMatches = matchDictionary["allMatches"]!
            
            for var i = 0; i < allMatches.count; i++ {
                if allMatches[i].matchID == match.matchID {
                    
                    print("")
                    print("Updating an existing match")
                    
                    matchDictionary["allMatches"]!.removeAtIndex(i)
                    matchDictionary["allMatches"]!.append(match)
                    newMatch = false
                }
            }
            
            if newMatch {
                
                print("")
                print("Retrieved a new match")
                
                matchDictionary["allMatches"]!.append(match)
            }
        }
        
        self.updateMatchDictionary(matchDictionary["allMatches"]!, completion: {
            _ in
            
            NSNotificationCenter.defaultCenter().postNotificationName("kReceivedTurnEvent", object: nil)
        })
    }
    
    //Called when the match has ended.
    func player(player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        
        print("")
        print("Received match ended notification")
    }
    
    func player(player: GKPlayer, didAcceptInvite invite: GKInvite) {
        print("")
        print("Received notification that opponent has accepted invite")
    }
    
    func player(player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) {
        print("")
        print("didRequestMatchWithOtherPlayers")
    }
    
    func player(player: GKPlayer, didRequestMatchWithPlayers playerIDsToInvite: [String]) {
        print("")
        print("didRequestMatchWithPlayers")
    }
    
    func player(player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer]) {
        print("")
        print("didRequestMatchWithRecipients")
    }
    
    func player(player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        print("")
        print("wantsToQuitMatch")
    }
    
    func player(player: GKPlayer, wantsToPlayChallenge challenge: GKChallenge) {
        print("")
        print("wantsToPlayChallenge")
    }
    
    func player(player: GKPlayer, didCompleteChallenge challenge: GKChallenge, issuedByFriend friendPlayer: GKPlayer) {
        print("")
        print("didCompleteChallenge")
    }
    
    func player(player: GKPlayer, didModifySavedGame savedGame: GKSavedGame) {
        print("")
        print("didModifySavedGame")
    }
    
    func player(player: GKPlayer, didReceiveChallenge challenge: GKChallenge) {
        print("")
        print("didReceiveChallenge")
    }
    
    func player(player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame]) {
        print("")
        print("hasConflictingSavedGames")
    }
    
    func player(player: GKPlayer, issuedChallengeWasCompleted challenge: GKChallenge, byFriend friendPlayer: GKPlayer) {
        print("")
        print("issuedChallengeWasCompleted")
    }
    
    func player(player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, forMatch match: GKTurnBasedMatch) {
        print("")
        print("receivedExchangeCancellation")
    }
    
    func player(player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, forMatch match: GKTurnBasedMatch) {
        print("")
        print("receivedExchangeReplies")
    }
    
    func player(player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, forMatch match: GKTurnBasedMatch) {
        print("")
        print("receivedExchangeRequest")
    }
    
    //MARK: Loading Friends
    func retrieveFriends() {
        let localPlayer = GKLocalPlayer.localPlayer()
        
        if localPlayer.authenticated {
            localPlayer.loadFriendPlayersWithCompletionHandler({
                friends, error in
                if error != nil {
                
                    print("")
                    print("ERROR: retrieving friends")
                    
                } else {
                    
                    if (friends != nil) {
                        
                        var playerIds:[String] = []
                        
                        for onePlayer in friends!  {
                            playerIds.append((onePlayer).playerID!)
                        }
                        
                        if playerIds.count > 0 {

                            self.loadPlayerData(playerIds)
                        
                        } else {
                        
                            print("")
                            print("Local player has no friends")
                        }
                        
                    }
                }
            })
        }
    }
    
    func loadPlayerData(identifiers: NSArray) {
        GKPlayer.loadPlayersForIdentifiers(identifiers as! [String], withCompletionHandler: {
            players, error in
            if error != nil {
                
                print("")
                print("ERROR: retrieving friend's data")
                
            } else {
                if (players != nil) {
                    self.friends = players as [GKPlayer]!
                    
                    print("")
                    print("Friend's data received")
                    NSNotificationCenter.defaultCenter().postNotificationName("kFriendsDataReceived", object: nil)
                }
            }
        })
    }

    //MARK: Finding participants
    func findParticipantsForMatch(match: GKTurnBasedMatch) -> (localPlayer: GKTurnBasedParticipant, opponent: GKTurnBasedParticipant)? {
        
        if let matchParticipants = match.participants {
            
            var localPlayerParticipant: GKTurnBasedParticipant?
            var opponentParticipant: GKTurnBasedParticipant?
            
            for participant in matchParticipants {
                
                if participant.player?.playerID != GKLocalPlayer.localPlayer().playerID {
                    opponentParticipant = participant
                } else {
                    localPlayerParticipant = participant
                }
            }
            
            return (localPlayerParticipant!, opponentParticipant!)
        }
        
        return nil
    }
    
    //MARK: Loading Matches
    func reloadMatches(completion: ([String:[GKTurnBasedMatch]]?) -> Void) {
        
        if !GKLocalPlayer.localPlayer().authenticated {
            print("")
            print("Local player is NOT authenticated: NOT RELOADING GAMES")
            completion(nil)
            
        } else {
            
            GKTurnBasedMatch.loadMatchesWithCompletionHandler { (matches:[GKTurnBasedMatch]?, error:NSError?) -> Void in
                
                if error != nil {
                    
                    print("")
                    print("ERROR: loading matches")
                    completion(nil)

                } else {
                    
                    if let loadedMatches = matches {
                    
                        print("")
                        print("Loaded \(loadedMatches.count) matches")
                        
                        self.updateMatchDictionary(loadedMatches, completion: {
                            _ in
                            
                            completion(self.matchDictionary)
                        })
                        
                    }  else {
                        
                        print("")
                        print("There were no matches to load")
                        
                        self.matchDictionary.removeAll()
                        completion(nil)
                    }

                }
            }
        
        }
    }
    
    func refreshMatchData(match:GKTurnBasedMatch, completion: () -> Void) {
        
        match.loadMatchDataWithCompletionHandler({
            data, error in
            
            if error != nil {
                print("")
                print("ERROR: Cannot reload match data for specific match")
                
            } else {
                
                print("")
                print("Reloaded match data for specific match")
                
                self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                    _ in
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("kMatchesLoaded", object: nil)
                })
            }
            
            completion()
        })
    }
    
    func updateMatchDictionary(matches: [GKTurnBasedMatch], completion: ([String:[GKTurnBasedMatch]]?) -> Void) {
        self.matchDictionary.removeAll()
        
        var localPlayerTurnMatches = [GKTurnBasedMatch]()
        var opponentTurnMatches = [GKTurnBasedMatch]()
        var endedMatches = [GKTurnBasedMatch]()
        
        //Array with matches to which the local player has been invited to,
        //but has not accepted or rejected them.
        var inInvitationModeMatches = [GKTurnBasedMatch]()
        
        //Array with matches that the local player has initialized with a specific opponent.
        var inWaitingForIntivationReplyModeMatches = [GKTurnBasedMatch]()
        
        //Array with matches that the local player has initialized with a random opponent.
        var inSearchingModeMatches = [GKTurnBasedMatch]()
        
        for match in matches {
            
            print("")
            print(match)
            
            if match.status == GKTurnBasedMatchStatus.Open {
                
                if let participants = self.findParticipantsForMatch(match) {
                    
                    if participants.opponent.status == GKTurnBasedParticipantStatus.Matching {
                        inSearchingModeMatches.append(match)
                    
                    } else if participants.opponent.status == GKTurnBasedParticipantStatus.Invited {
                        inWaitingForIntivationReplyModeMatches.append(match)
                    
                    } else if match.currentParticipant?.status == GKTurnBasedParticipantStatus.Invited {
                        inInvitationModeMatches.append(match)
                   
                    } else if participants.opponent.status == GKTurnBasedParticipantStatus.Active &&
                            participants.opponent.matchOutcome == GKTurnBasedMatchOutcome.None &&
                            participants.localPlayer.status == GKTurnBasedParticipantStatus.Active &&
                            participants.localPlayer.matchOutcome == GKTurnBasedMatchOutcome.None {
                            
                                if match.currentParticipant?.player?.playerID == GKLocalPlayer.localPlayer().playerID {
                                    localPlayerTurnMatches.append(match)
                                    
                                } else {
                                    
                                    opponentTurnMatches.append(match)
                                }
                    
                    //Opponent has quit out of turn. End the match.
                    } else if participants.opponent.matchOutcome == GKTurnBasedMatchOutcome.Lost {
                        quitMatch(match, localPlayerOutcome: GKTurnBasedMatchOutcome.Won, completion: {})
                    }
                    
                }
                
            } else if match.status == GKTurnBasedMatchStatus.Ended {
                
                endedMatches.append(match)
                
            } else if match.status == GKTurnBasedMatchStatus.Matching {
                
                
                
            } else if match.status == GKTurnBasedMatchStatus.Unknown {
                
                print("")
                print("ERROR: Match with unknown status")
            }
        }
        
        self.matchDictionary = ["allMatches":matches, "localPlayerTurnMatches":localPlayerTurnMatches, "opponentTurnMatches":opponentTurnMatches, "endedMatches":endedMatches, "inInvitationModeMatches":inInvitationModeMatches, "inWaitingForIntivationReplyModeMatches":inWaitingForIntivationReplyModeMatches, "inSearchingModeMatches":inSearchingModeMatches]
        
        completion(self.matchDictionary)
    }
    
    //MARK: Starting Matches
    func initRandomMatch(completion: (match: GKTurnBasedMatch?) -> Void) {
        
        if !GKLocalPlayer.localPlayer().authenticated {
            print("")
            print("Local player is NOT authenticated: NOT STARTING RANDOM MATCH")
            
            completion(match: nil)
            
        } else {
            
            let request = GKMatchRequest()
            request.minPlayers = 2
            request.maxPlayers = 2
            request.inviteMessage = "Invited to play game!"
            request.recipientResponseHandler = {
                player, response in
                
                print("")
                print("Received response to player \(player.alias) invitation")
                
                if response == GKInviteeResponse.InviteRecipientResponseDeclined ||
                    response == GKInviteRecipientResponse.InviteeResponseDeclined {
                    
                    print("")
                    print("\(player.alias) declined invitation")
                    
                } else if response == GKInviteeResponse.InviteeResponseAccepted ||
                    response == GKInviteRecipientResponse.InviteeResponseAccepted {
                    
                    print("")
                    print("\(player.alias) accepted invitation")
                    
                }
                
            }
            initMatchRequest(request) {
                match in
                
                completion(match: match)
            }
        }
    }

    func initMatch(opponent: GKPlayer, completion: (match: GKTurnBasedMatch?) -> Void) {
        
        print("")
        print("Initialize match with opponent \(opponent.alias)")
        
        if !GKLocalPlayer.localPlayer().authenticated {
            print("")
            print("Local player is NOT authenticated: NOT STARTING SPECIFIC MATCH")
            
            completion(match: nil)
            
        } else {
            
            let request = GKMatchRequest()
            request.maxPlayers = 2
            request.minPlayers = 2
            request.recipients = [opponent]
            request.inviteMessage = "Invited to play game!"
            request.recipientResponseHandler = {
                player, response in
                
                print("")
                print("Received response to player \(player.alias) invitation")
                
                if response == GKInviteeResponse.InviteRecipientResponseDeclined ||
                    response == GKInviteRecipientResponse.InviteeResponseDeclined {
                        
                        print("")
                        print("\(player.alias) declined invitation")
                        
                } else if response == GKInviteeResponse.InviteeResponseAccepted ||
                    response == GKInviteRecipientResponse.InviteeResponseAccepted {
                        
                        print("")
                        print("\(player.alias) accepted invitation")
                        
                }
                
            }
            
            initMatchRequest(request) {
                match in
                
                completion(match: match)
            }
        }
        
    }
    
    func initMatchRequest(request: GKMatchRequest, completion: (match: GKTurnBasedMatch?) -> Void) {
        GKTurnBasedMatch.findMatchForRequest(request, withCompletionHandler: { (match:GKTurnBasedMatch?, error:NSError?) -> Void in
            
            if error != nil {
                
                print("")
                print("ERROR: starting match")
                completion(match: nil)
                
            } else {
                
                print("")
                print("Match was initialized")
                
                if self.matchDictionary["allMatches"] == nil &&
                    match != nil {
                    self.matchDictionary["allMatches"] = [match!]
                }
                
                completion(match: match)
            }
        })
    }
    
    //MARK: Playing Turn
    func endTurn(match: GKTurnBasedMatch, newTurn: TurnDataObject, completion: () -> Void) {

        if let opponent = self.findParticipantsForMatch(match)?.opponent {

            let data = MatchDataEncoding.encode(match.matchData!, newTurn: newTurn)
            
            match.endTurnWithNextParticipants([opponent], turnTimeout: 36000, matchData: data, completionHandler: {
                error in
                if (error != nil) {
                    
                    print("")
                    print("ERROR: Could not send end turn")
                    completion()
                    
                } else {
                    print("")
                    print("End turn was sent")
                    
                    self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                        _ in
                        
                        NSNotificationCenter.defaultCenter().postNotificationName("kEndTurnEvent", object: nil)
                        
                        JSSAlertView().show(
                            self.presentingViewController!, // the parent view controller of the alert
                            title: "Turn was sent" // the alert's title
                        )
                        
                        completion()
                    })
                }
            })
        } else {
            print("")
            print("ERROR: Could not find match opponent")
            completion()
        }
    }
    
    //MARK: Quiting Match
    func quitMatch(match: GKTurnBasedMatch!, localPlayerOutcome: GKTurnBasedMatchOutcome?, completion: () -> Void) {
        
        print("")
        print("Quit game")
        
        //If local player is the current participant then he/she can end the match
        if GKLocalPlayer.localPlayer().playerID == match.currentParticipant?.player?.playerID {
            
            let matchParticipants = findParticipantsForMatch(match)
            
            if localPlayerOutcome == GKTurnBasedMatchOutcome.Won {
                
                matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.Won
                matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.Lost
                
            } else if localPlayerOutcome == GKTurnBasedMatchOutcome.Lost {
                
                matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.Lost
                matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.Won
                
            } else {
                
                matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.Tied
                matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.Tied
            }
            
            match.endMatchInTurnWithMatchData(match.matchData!, completionHandler: {
                error in
                
                if error != nil {
                    print("")
                    print("ERROR: Ending Match \(error)")
                } else {
                    print("")
                    print("Match Ended")
                    
                    JSSAlertView().show(
                        self.presentingViewController!, // the parent view controller of the alert
                        title: "Match Ended" // the alert's title
                    )
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("kEndTurnEvent", object: nil)
                }
                
                completion()
            })
        
        //If local player is not the current participant then he/she has to
        } else {
            
            match.participantQuitOutOfTurnWithOutcome(GKTurnBasedMatchOutcome.Lost, withCompletionHandler: {
                error in
                
                if error != nil {
                    
                    print("")
                    print("ERROR: Quiting Match out of turn \(error)")
                    
                } else {
                
                    print("")
                    print("Local player quit match out of turn")
                    
                    JSSAlertView().show(
                        self.presentingViewController!, // the parent view controller of the alert
                        title: "Local player quit match out of turn" // the alert's title
                    )
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("kEndTurnEvent", object: nil)
                }
            })
        }
    }
    
    //MARK: Removing match
    func removeMatch(match: GKTurnBasedMatch!, completion: () -> Void) {
        
        print("Remove game with ID: \(match.matchID)")
        
        match.removeWithCompletionHandler({
            error in
            if error != nil {
                
                print("")
                print("ERROR: did not remove game: \(error)")
                
            } else {
                
                print("")
                print("Removed match")
                
                let allMatches = self.matchDictionary["allMatches"]!
                
                for var i = 0; i < allMatches.count; i++ {
                    if allMatches[i].matchID == match.matchID {
                        
                        print("")
                        print("Removing match from array")
                        
                        self.matchDictionary["allMatches"]!.removeAtIndex(i)
                    }
                }
                
                JSSAlertView().show(
                    self.presentingViewController!, // the parent view controller of the alert
                    title: "Removed match" // the alert's title
                )
                
                NSNotificationCenter.defaultCenter().postNotificationName("kEndTurnEvent", object: nil)
            }
            
            completion()
        })
    }

    //MARK: Accepting/Rejecting invitations
    func acceptInvitation(match:GKTurnBasedMatch?) {
        match?.acceptInviteWithCompletionHandler({
            match, error in
            
            if error != nil {
                print("")
                print("ERROR: accepting invitation \(error)")
                
                //Error: No such session
                if error?.code == 5003 {
                    
                    print("")
                    print("Opponent quit game, cannot accept")
                    self.removeMatch(match, completion: {})
                }
                
            } else {
                print("Accepted invitation")
                
                JSSAlertView().show(
                    self.presentingViewController!, // the parent view controller of the alert
                    title: "Accepted invitation" // the alert's title
                )
                
                NSNotificationCenter.defaultCenter().postNotificationName("kEndTurnEvent", object: nil)
            }
        })
    }
    
    func declineInvitation(match:GKTurnBasedMatch?) {
        match?.declineInviteWithCompletionHandler({
            error in
            
            if error != nil {
                print("")
                print("ERROR: declining invitation \(error)")
                
                //Error: No such session
                if error?.code == 5003 {
                    
                    print("")
                    print("Opponent quit game, cannot decline")
                    self.removeMatch(match, completion: {})
                }
                
            } else {
                print("Declined invitation")
                
                JSSAlertView().show(
                    self.presentingViewController!, // the parent view controller of the alert
                    title: "Declined invitation" // the alert's title
                )
                
                NSNotificationCenter.defaultCenter().postNotificationName("kEndTurnEvent", object: nil)
            }
        })
    }
}
