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
    
    var currentMatch: GKTurnBasedMatch?
    var totalNumberOfRounds: Int = 5
    
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
        
        self.presentingViewController?.hud = MBProgressHUD.showAdded(to: self.presentingViewController?.view, animated: true)
        self.presentingViewController?.hud?.labelText = "LOADING MATCHES"
        
        NotificationCenter.default.addObserver(self , selector: #selector(GameCenterSingleton.authenticationChanged), name: NSNotification.Name(rawValue: GKPlayerAuthenticationDidChangeNotificationName), object: nil)
        
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
                    
                    self.presentingViewController?.present(viewController!, animated: true, completion: {
                        finished in
                        
                        print("")
                        print("PLAYER IS NOT AUTHENTICATED: presenting login screen")
                        
                    })
                    
                } else {
                    
                    print("")
                    print("PLAYER \(GKLocalPlayer.localPlayer().alias) IS ALREADY AUTHENTICATED: \(GKLocalPlayer.localPlayer().isAuthenticated)")
                    
                }
            }
        } as! (UIViewController?, Error?) -> Void
    }
    
    func authenticationChanged() {
        
        print("")
        print("AUTHENTICATION CHANGED")
        
        self.presentingViewController?.hud?.hide(true)
        
        if GKLocalPlayer.localPlayer().isAuthenticated {
            
            print("")
            print("Player is authenticated")
            GKLocalPlayer.localPlayer().unregisterAllListeners()
            GKLocalPlayer.localPlayer().register(self)
            
            self.retrieveFriends()
            self.reloadMatches({
                (matches: [String:[GKTurnBasedMatch]]?) in
                
                if matches != nil {
                    
                    print("")
                    print("Matches loaded")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                    
                } else {
                    
                    print("")
                    print("There were no matches to load or some error occured")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
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
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        
        print("")
        print("Received turn event for match. Did become active \(didBecomeActive)")
        
        refreshMatchData(match, completion: {
            _ in
            
            if self.matchDictionary["allMatches"] == nil {
                self.matchDictionary["allMatches"] = [match]
            } else {
                
                var newMatch = true
                
                let allMatches = self.matchDictionary["allMatches"]!
                
                for i in 0 ..< allMatches.count {
                    if allMatches[i].matchID == match.matchID {
                        
                        print("")
                        print("Updating an existing match")
                        
                        self.matchDictionary["allMatches"]!.remove(at: i)
                        self.matchDictionary["allMatches"]!.append(match)
                        newMatch = false
                    }
                }
                
                if newMatch {
                    
                    print("")
                    print("Retrieved a new match")
                    
                    self.matchDictionary["allMatches"]!.append(match)
                }
            }
            
            self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                _ in
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
            })
            
        })
    }
    
    //Called when the match has ended.
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        
        print("")
        print("Received match ended notification")
        
        refreshMatchData(match, completion: {
            _ in
            
            
            if let allMatches = self.matchDictionary["allMatches"] {
                
                for i in 0 ..< allMatches.count {
                    if allMatches[i].matchID == match.matchID {
                        
                        print("")
                        print("Ending/Updating an existing match")
                        
                        self.matchDictionary["allMatches"]!.remove(at: i)
                        self.matchDictionary["allMatches"]!.append(match)
                    }
                }
                
                self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                    _ in
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                })
            }
        })
    }
    
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        print("")
        print("wantsToQuitMatch")
    }
    
    /* //this is for real-time matches only (but the docs don't say that)
    func player(player: GKPlayer, didAcceptInvite invite: GKInvite) {
    print("")
    print("Received notification that opponent has accepted invite")
    }
    */
    
    
    //For match launched via game center
    func player(_ player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) {
        print("")
        print("didRequestMatchWithOtherPlayers")
    }
    
    /*
    //For match launched via game center
    //DEPRECATED: This is fired when the user asks to play with a friend from the game center.app
    func player(player: GKPlayer, didRequestMatchWithPlayers playerIDsToInvite: [String]) {
    print("")
    print("didRequestMatchWithPlayers")
    }
    */
    
    //For match launched via game center
    func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer]) {
        print("")
        print("didRequestMatchWithRecipients")
    }
    
    func player(_ player: GKPlayer, wantsToPlay challenge: GKChallenge) {
        print("")
        print("wantsToPlayChallenge")
    }
    
    func player(_ player: GKPlayer, didComplete challenge: GKChallenge, issuedByFriend friendPlayer: GKPlayer) {
        print("")
        print("didCompleteChallenge")
    }
    
    func player(_ player: GKPlayer, didModifySavedGame savedGame: GKSavedGame) {
        print("")
        print("didModifySavedGame")
    }
    
    func player(_ player: GKPlayer, didReceive challenge: GKChallenge) {
        print("")
        print("didReceiveChallenge")
    }
    
    func player(_ player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame]) {
        print("")
        print("hasConflictingSavedGames")
    }
    
    func player(_ player: GKPlayer, issuedChallengeWasCompleted challenge: GKChallenge, byFriend friendPlayer: GKPlayer) {
        print("")
        print("issuedChallengeWasCompleted")
    }
    
    func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        print("")
        print("receivedExchangeCancellation")
    }
    
    func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        print("")
        print("receivedExchangeReplies")
    }
    
    func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        print("")
        print("receivedExchangeRequest")
    }
    
    //MARK: Loading Friends
    func retrieveFriends() {
        let localPlayer = GKLocalPlayer.localPlayer()
        
        if localPlayer.isAuthenticated {
            localPlayer.loadFriendPlayers(completionHandler: {
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
                            
                            self.loadPlayerData(playerIds as NSArray)
                            
                        } else {
                            
                            print("")
                            print("Local player has no friends")
                        }
                        
                    }
                }
            })
        }
    }
    
    func loadPlayerData(_ identifiers: NSArray) {
        GKPlayer.loadPlayers(forIdentifiers: identifiers as! [String], withCompletionHandler: {
            players, error in
            if error != nil {
                
                print("")
                print("ERROR: retrieving friend's data")
                
            } else {
                if (players != nil) {
                    self.friends = players as [GKPlayer]!
                    
                    print("")
                    print("Friend's data received")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kFriendsDataReceived"), object: nil)
                }
            }
        })
    }
    
    //MARK: Finding participants
    func findParticipantsForMatch(_ match: GKTurnBasedMatch) -> (localPlayer: GKTurnBasedParticipant, opponent: GKTurnBasedParticipant)? {
        
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
    func reloadMatches(_ completion: @escaping ([String:[GKTurnBasedMatch]]?) -> Void) {
        
        if !GKLocalPlayer.localPlayer().isAuthenticated {
            print("")
            print("Local player is NOT authenticated: NOT RELOADING GAMES")
            completion(nil)
            
        } else {
            
            GKTurnBasedMatch.loadMatches { (matches, error) in
                
                if error != nil {
                    
                    print("")
                    print("ERROR: loading matches")
                    completion(nil)
                    
                } else {
                    
                    if let loadedMatches = matches {
                        
                        print("")
                        print("Loaded \(loadedMatches.count) matches")
                        
                        self.refreshMatchesData(loadedMatches, completion: {
                            _ in
                            
                            self.updateMatchDictionary(loadedMatches, completion: {
                                _ in
                                
                                completion(self.matchDictionary)
                            })
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
    
    func refreshMatchData(_ match:GKTurnBasedMatch, completion: @escaping () -> Void) {
        
        match.loadMatchData(completionHandler: {
            data, error in
            
            if error != nil {
                print("")
                print("ERROR: Cannot reload match data for specific match")
                
            } else {
                
                print("")
                print("Reloaded match data for specific match")
                
            }
            
            completion()
        })
    }
    
    func refreshMatchesData(_ matches:[GKTurnBasedMatch], completion: @escaping () -> Void) {
        
        var matchesLoaded = 0
        
        for i in 0 ..< matches.count {
            refreshMatchData(matches[i], completion: {
                finished in
                
                matchesLoaded += 1
                
                if matchesLoaded == matches.count {

                    completion()
                }
            })
        }
    }
    
    
    func updateMatchDictionary(_ matches: [GKTurnBasedMatch], completion: ([String:[GKTurnBasedMatch]]?) -> Void) {
        
        print("")
        print("Update match dictionary")
        
        
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
            
            if match.status == GKTurnBasedMatchStatus.open {
                
                if let participants = self.findParticipantsForMatch(match) {
                    
                    if participants.opponent.status == GKTurnBasedParticipantStatus.matching {
                        
                        if match.matchData?.count == 0 {
                            
                            quitMatch(match, localPlayerOutcome: GKTurnBasedMatchOutcome.tied, completion: {
                                _ in
                                self.removeMatch(match, completion: {})
                            })
                            
                        } else {
                            inSearchingModeMatches.append(match)
                        }
                        
                    } else if participants.opponent.status == GKTurnBasedParticipantStatus.invited {
                        inWaitingForIntivationReplyModeMatches.append(match)
                        
                    } else if match.currentParticipant?.status == GKTurnBasedParticipantStatus.invited {
                        inInvitationModeMatches.append(match)
                        
                    } else if participants.opponent.status == GKTurnBasedParticipantStatus.active &&
                        participants.opponent.matchOutcome == GKTurnBasedMatchOutcome.none &&
                        participants.localPlayer.status == GKTurnBasedParticipantStatus.active &&
                        participants.localPlayer.matchOutcome == GKTurnBasedMatchOutcome.none {
                            
                            if match.currentParticipant?.player?.playerID == GKLocalPlayer.localPlayer().playerID {
                                localPlayerTurnMatches.append(match)
                                
                            } else {
                                
                                opponentTurnMatches.append(match)
                            }
                            
                            //Opponent has quit out of turn. End the match.
                    } else if participants.opponent.matchOutcome == GKTurnBasedMatchOutcome.lost {
                        self.quitMatch(match, localPlayerOutcome: GKTurnBasedMatchOutcome.won, completion: {})
                        
                    } else if participants.localPlayer.matchOutcome == GKTurnBasedMatchOutcome.lost {
                        //Message sent to other player and waiting for the current participant
                        //to end the match. While the local player waits he/she will not be able
                        //to see the match.
                    }
                    
                }
                
            } else if match.status == GKTurnBasedMatchStatus.ended {
                
                //Declined matches are immediately removed from the user who declined them.
                /*
                if let participants = self.findParticipantsForMatch(match) {
                
                if participants.localPlayer.status == GKTurnBasedParticipantStatus.Declined  ||
                    participants.opponent.status == GKTurnBasedParticipantStatus.Declined ||
                    match.currentParticipant == nil {
                
                removeMatch(match, completion: {})
                
                } else {
                endedMatches.append(match)
                }
                }
                */
                
                //Declined matches are shown as "Ended Matches"
                print("Add in endedMatches array")
                endedMatches.append(match)
                
            } else if match.status == GKTurnBasedMatchStatus.matching {
                
                inSearchingModeMatches.append(match)
                
            } else if match.status == GKTurnBasedMatchStatus.unknown {
                
                print("")
                print("ERROR: Match with unknown status")
            }
        }
        
        var playersTurnMatches = [GKTurnBasedMatch]()
        playersTurnMatches.append(contentsOf: inInvitationModeMatches)
        playersTurnMatches.append(contentsOf: localPlayerTurnMatches)
        
        var opponentsTurnMatches = [GKTurnBasedMatch]()
        opponentsTurnMatches.append(contentsOf: inSearchingModeMatches)
        opponentsTurnMatches.append(contentsOf: inWaitingForIntivationReplyModeMatches)
        opponentsTurnMatches.append(contentsOf: opponentTurnMatches)
        
        self.matchDictionary = ["allMatches":matches, "localPlayerTurnMatches":localPlayerTurnMatches, "opponentTurnMatches":opponentTurnMatches, "endedMatches":endedMatches, "inInvitationModeMatches":inInvitationModeMatches, "inWaitingForIntivationReplyModeMatches":inWaitingForIntivationReplyModeMatches, "inSearchingModeMatches":inSearchingModeMatches,  "playersTurnMatches":playersTurnMatches, "opponentsTurnMatches":opponentsTurnMatches]
        
        completion(self.matchDictionary)
    }
    
    //MARK: Starting Matches
    func initRandomMatch(_ completion: @escaping (_ match: GKTurnBasedMatch?) -> Void) {
        
        if !GKLocalPlayer.localPlayer().isAuthenticated {
            print("")
            print("Local player is NOT authenticated: NOT STARTING RANDOM MATCH")
            
            completion(nil)
            
        } else {
            
            let request = GKMatchRequest()
            request.minPlayers = 2
            request.maxPlayers = 2
            request.inviteMessage = "Invited to play game!"
            request.recipientResponseHandler = {
                player, response in
                
                print("")
                print("Received response to player \(player.alias) invitation")
                
                if response == GKInviteeResponse.inviteRecipientResponseDeclined ||
                    response == GKInviteRecipientResponse.inviteeResponseDeclined {
                        
                        print("")
                        print("\(player.alias) declined invitation")
                        
                } else if response == GKInviteeResponse.inviteeResponseAccepted ||
                    response == GKInviteRecipientResponse.inviteeResponseAccepted {
                    
                        print("")
                        print("\(player.alias) accepted invitation")
                        
                }
                
            }
            
            initMatchRequest(request) {
                match in
                
                completion(match)
            }
        }
    }
    
    func initMatch(_ opponent: GKPlayer, completion: @escaping (_ match: GKTurnBasedMatch?) -> Void) {
        
        print("")
        print("Initialize match with opponent \(opponent.alias)")
        
        if !GKLocalPlayer.localPlayer().isAuthenticated {
            print("")
            print("Local player is NOT authenticated: NOT STARTING SPECIFIC MATCH")
            
            completion(nil)
            
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
                
                if response == GKInviteeResponse.inviteRecipientResponseDeclined ||
                    response == GKInviteRecipientResponse.inviteeResponseDeclined {
                        
                        print("")
                        print("\(player.alias) declined invitation")
                        
                } else if response == GKInviteeResponse.inviteeResponseAccepted ||
                    response == GKInviteRecipientResponse.inviteeResponseAccepted {
                        
                        print("")
                        print("\(player.alias) accepted invitation")
                        
                }
                
            }
            
            initMatchRequest(request) {
                match in
                
                completion(match)
            }
        }
        
    }
    
    func initMatchRequest(_ request: GKMatchRequest, completion: @escaping (_ match: GKTurnBasedMatch?) -> Void) {
        GKTurnBasedMatch.find(for: request, withCompletionHandler: { (match:GKTurnBasedMatch?, error:NSError?) -> Void in
            
            if error != nil {
                
                print("")
                print("ERROR: starting match")
                completion(nil)
                
            } else {
                
                print("")
                print("Match was initialized")
                
                if self.matchDictionary["allMatches"] == nil &&
                    match != nil {
                        self.matchDictionary["allMatches"] = [match!]
                } else if match != nil {
                    
                    print("")
                    print("Retrieved a new match")
                    
                    self.matchDictionary["allMatches"]!.append(match!)
                }
                
                completion(match)
            }
        } as! (GKTurnBasedMatch?, Error?) -> Void)
    }
    
    func rematch(_ match: GKTurnBasedMatch?, completion: @escaping (_ match: GKTurnBasedMatch?) -> Void) {
        
        if !GKLocalPlayer.localPlayer().isAuthenticated {
            print("")
            print("Local player is NOT authenticated: NOT REMATCHING")
            
            completion(nil)
            
        } else {
            
            match?.rematch(completionHandler: {
                
                newMatch, error in
                
                if (error != nil) {
                    
                    print("")
                    print("ERROR: Could not initialize rematch")
                    completion(nil)
                    
                } else {
                    
                    print("")
                    print("Rematch initialized")
                    
                    self.removeMatch(match, completion: {
                        finished in
                        
                        print("")
                        print("Previous match removed")
                        
                        completion(newMatch)
                    })
                }
            })
        }
    }
    
    //MARK: Playing Turn
    func endTurn(_ match: GKTurnBasedMatch, newTurn: TurnDataObject, completion: @escaping () -> Void) {
        
        if let opponent = self.findParticipantsForMatch(match)?.opponent {
            
            let data = MatchDataEncoding.encode(match.matchData!, newTurn: newTurn)
            
            //If the totalNumberOfRounds (i.e. the maximum number of rounds to be played) has been reached
            //and the local player is not the initiation (i.e. he is the second player)
            //then the game has reached its conclusion and finishes.
            if MatchDataEncoding.decode(data).currentRound == totalNumberOfRounds && GKLocalPlayer.localPlayer().playerID != MatchDataEncoding.decode(data).initiator {
                
                let dataElements = MatchDataEncoding.decode(data)
                
                print("")
                print("Match Score: \(dataElements.score1) - \(dataElements.score2)")
                
                if match.currentParticipant?.player?.playerID == GKLocalPlayer.localPlayer().playerID {
                    
                    let matchParticipants = findParticipantsForMatch(match)
                    
                    //Score1 is for initiator of match, not local player.
                    //Since this example has only two players that take turns, the game will end
                    //when the local player is NOT the initiator.
                    if dataElements.score1 < dataElements.score2 {
                        
                        print("")
                        print("Match Result: Local player won")
                        
                        matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.won
                        matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.lost
                        
                    } else if dataElements.score2 < dataElements.score1 {
                        
                        print("")
                        print("Match Result: Opponent won")
                        
                        matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.lost
                        matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.won
                        
                    } else {
                        
                        print("")
                        print("Match Result: Tie")
                        
                        matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.tied
                        matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.tied
                    }
                }
                
                match.endMatchInTurn(withMatch: data, completionHandler: { (error) -> Void in
                    if error != nil {
                        
                        print("")
                        print("ERROR: Could not send end match")
                        completion()
                        
                    } else {
                        
                        print("")
                        print("End match was sent")
                        
                        self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                            _ in
                            
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                            
                            JSSAlertView().show(
                                self.presentingViewController!, // the parent view controller of the alert
                                title: "End match was sent" // the alert's title
                            )
                            
                            completion()
                        })
                    }
                })
                
            } else {
                
                match.endTurn(withNextParticipants: [opponent], turnTimeout: 36000, match: data, completionHandler: {
                    error in
                    if (error != nil) {
                        
                        print("")
                        print("ERROR: Could not send end turn")
                        completion()
                        
                    } else {
                        print("")
                        print("End turn was sent")
                        
                        let dataElements = MatchDataEncoding.decode(data)
                        
                        print("")
                        print("Match Score: \(dataElements.score1) - \(dataElements.score2)")
                        
                        self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                            _ in
                            
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                            
                            JSSAlertView().show(
                                self.presentingViewController!, // the parent view controller of the alert
                                title: "Turn was sent" // the alert's title
                            )
                            
                            completion()
                        })
                    }
                })
                
            }
            
        } else {
            print("")
            print("ERROR: Could not find match opponent")
            completion()
        }
    }
    
    //MARK: Send reminder
    //This should be called whenever a new game is initialized so that the opponent receives the invitation.
    func sendReminder(_ match:GKTurnBasedMatch, completion: @escaping () -> Void) {
        
        let opponent = findParticipantsForMatch(match)!.opponent
        
        match.sendReminder(to: [opponent], localizableMessageKey: "Reminder received!", arguments: [], completionHandler: {
            error in
            
            if error != nil {
                print("")
                print("ERROR: sending reminder")
                completion()
            } else {
                print("")
                print("Reminder sent")
                
                completion()
            }
        })
    }
    
    //MARK: Quiting Match
    func quitMatch(_ match: GKTurnBasedMatch!, localPlayerOutcome: GKTurnBasedMatchOutcome?, completion: @escaping () -> Void) {
        
        print("")
        print("Quit match")
        
        //If local player is the current participant then he/she can end the match
        if GKLocalPlayer.localPlayer().playerID == match.currentParticipant?.player?.playerID {
            
            let matchParticipants = findParticipantsForMatch(match)
            
            if localPlayerOutcome == GKTurnBasedMatchOutcome.won {
                
                matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.won
                matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.lost
                
            } else if localPlayerOutcome == GKTurnBasedMatchOutcome.lost {
                
                matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.lost
                matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.won
                
            } else {
                
                matchParticipants!.localPlayer.matchOutcome = GKTurnBasedMatchOutcome.tied
                matchParticipants!.opponent.matchOutcome = GKTurnBasedMatchOutcome.tied
            }
            
            match.endMatchInTurn(withMatch: match.matchData!, completionHandler: {
                error in
                
                if error != nil {
                    print("")
                    print("ERROR: Ending Match \(error)")
                } else {
                    print("")
                    print("Match Ended")
                    
                    self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                        _ in
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                        
                        JSSAlertView().show(
                            self.presentingViewController!, // the parent view controller of the alert
                            title: "Match Ended" // the alert's title
                        )
                    })
                }
                
                completion()
            })
            
            //If local player is not the current participant then he/she has to quit out of turn
        } else {
            
            match.participantQuitOutOfTurn(with: GKTurnBasedMatchOutcome.lost, withCompletionHandler: {
                error in
                
                if error != nil {
                    
                    print("")
                    print("ERROR: Quiting Match out of turn \(error)")
                    
                } else {
                    
                    print("")
                    print("Local player quit match out of turn")
                    
                    self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                        _ in
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                        
                        JSSAlertView().show(
                            self.presentingViewController!, // the parent view controller of the alert
                            title: "Local player quit match out of turn" // the alert's title
                        )
                        
                        completion()
                    })
                }
            })
        }
    }
    
    //MARK: Removing match
    func removeMatch(_ match: GKTurnBasedMatch!, completion: @escaping () -> Void) {
        
        print("Remove game with ID: \(match.matchID)")
        
        match.remove(completionHandler: {
            error in
            if error != nil {
                
                print("")
                print("ERROR: did not remove game: \(error)")
                
                self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                    _ in
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                })
                
            } else {
                
                print("")
                print("Removed match")
                
                let allMatches = self.matchDictionary["allMatches"]!
                
                for i in 0 ..< allMatches.count {
                    if allMatches[i].matchID == match.matchID {
                        
                        print("")
                        print("Removing match from array")
                        
                        self.matchDictionary["allMatches"]!.remove(at: i)
                    }
                }
                
                self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                    _ in
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                    
                    JSSAlertView().show(
                        self.presentingViewController!, // the parent view controller of the alert
                        title: "Removed match" // the alert's title
                    )
                })
            }
            
            completion()
        })
    }
    
    //MARK: Accepting/Rejecting invitations
    func acceptInvitation(_ match:GKTurnBasedMatch?) {
        match?.acceptInvite(completionHandler: {
            match, error in
            
            if error != nil {
                print("")
                print("ERROR: accepting invitation \(error)")
                
                //Error: No such session
                //if error!.userInfo["GKServerStatusCode"]!.int32Value == 5003 {
                    
                    print("")
                    print("Opponent quit game, cannot accept")
                    
                    //reload games
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatches"), object: nil)
                //}
                
            } else {
                print("Accepted invitation")
                
                self.sendReminder(match!, completion: {
                    _ in
                })
                
                self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                    _ in
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                    
                    JSSAlertView().show(
                        self.presentingViewController!, // the parent view controller of the alert
                        title: "Accepted invitation" // the alert's title
                    )
                })
            }
        })
    }
    
    func declineInvitation(_ match:GKTurnBasedMatch?) {
        match?.declineInvite(completionHandler: {
            error in
            
            if error != nil {
                print("")
                print("ERROR: declining invitation \(error)")
                
                //Error: No such session
                //if error?.code == 5003 {
                    
                    print("")
                    print("Opponent quit game, cannot decline")
                    self.removeMatch(match, completion: {})
                //}
                
            } else {
                print("Declined invitation")
                
                self.sendReminder(match!, completion: {
                    _ in
                })
                
                self.updateMatchDictionary(self.matchDictionary["allMatches"]!, completion: {
                    _ in
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "kReloadMatchTable"), object: nil)
                    
                    JSSAlertView().show(
                        self.presentingViewController!, // the parent view controller of the alert
                        title: "Declined invitation" // the alert's title
                    )
                })
            }
        })
    }
}
