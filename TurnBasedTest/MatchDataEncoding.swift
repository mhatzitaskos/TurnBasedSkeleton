//
//  MatchDataEncoding.swift
//  TurnBasedTest
//
//  Created by Markos Hatzitaskos on 353/12/15.
//  Copyright © 2015 Markos Hatzitaskos. All rights reserved.
//

import Foundation
import GameKit

enum MatchMode {
    case localPlayerTurnMatches, opponentTurnMatches, endedMatches, inInvitationModeMatches, inWaitingForIntivationReplyModeMatches, inSearchingModeMatches
}

class TurnDataObject: NSObject {
    var playerID:String!
    var word:String!
    var substring:String!
    var substringStart:Int!
    var subStringLength:Int!
    var pointsEarned:Int!
    var turn:Int!
    
    override init() {}
    
    init(playerID: String, word: String, substring: String, substringStart: Int, subStringLength: Int, pointsEarned: Int, turn: Int) {
        
        self.playerID = playerID
        self.word = word
        self.substring = substring
        self.substringStart = substringStart
        self.subStringLength = subStringLength
        self.pointsEarned = pointsEarned
        self.turn = turn
    }
}

open class MatchDataEncoding {
    
    class func decode(_ matchData: Data?) -> (initiator: String, turnsData: [TurnDataObject], currentRound: Int, score1: Int, score2: Int, playerGroup: Int, lastTurnTime: String, readChatMessages1: Int, readChatMessages2: Int) {
        
        if let data = matchData {
            if data.count > 0 {
                
                let majorSeparator = "<|>"
                
                let dataString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                let dataMessage: String = dataString as! String
                let messageArray: [String] = dataMessage.components(separatedBy: majorSeparator)
                
                let initiator = String(messageArray[0])
                let turnsData = retrieveTurnsData(String(messageArray[1]))
                let currentRound = Int(messageArray[2])
                let score1 = Int(messageArray[3])
                let score2 = Int(messageArray[4])
                let playerGroup = Int(messageArray[5])
                let lastTurnTime = String(messageArray[6])
                let readChatMessages1 = Int(messageArray[7])
                let readChatMessages2 = Int(messageArray[8])
                
                print("")
                print("Match Initiator: \(initiator)")
                print("Match Round: \(currentRound)")
                
                for turn in turnsData {
                    print("")
                    print("Match Turn: \(turn.playerID), \(turn.word), \(turn.substring), \(turn.substringStart), \(turn.subStringLength), \(turn.pointsEarned), \(turn.turn)")
                }
                
                return (initiator, turnsData, currentRound!, score1!, score2!, playerGroup!, lastTurnTime, readChatMessages1!, readChatMessages2!)
                
            } else {
                
                //Match data is not nil but is empty, return initializing values.
                return (GKLocalPlayer.localPlayer().playerID!, [TurnDataObject](), 1, 0, 0, 0, "", 0, 0)
            }
        } else {
            
            //Match data is nil, return initializing values.
            return (GKLocalPlayer.localPlayer().playerID!, [TurnDataObject](), 1, 0, 0, 0, "", 0, 0)
        }
    }
    
    class func encode(_ matchData: Data, newTurn: TurnDataObject) -> Data {
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "MM dd, yyyy HH:mm:ss"
        
        let majorSeparator = "<|>"
        let externalSeparator = "[]"
        let internalSeparator = "(:)"

        let matchDataTuple = decode(matchData)
        var matchDataTurnDataObjects = matchDataTuple.turnsData
        matchDataTurnDataObjects.append(newTurn)
        
        var str:String = ""
        
        str += matchDataTuple.initiator
        str += majorSeparator
        
        var turnsStr = ""
        
        var scoreInitiator = 0
        var scoreOpponent = 0
        
        var  i = 1
        for turn in matchDataTurnDataObjects {
            
            turnsStr += turn.playerID
            turnsStr += internalSeparator
            turnsStr += turn.word
            turnsStr += internalSeparator
            turnsStr += turn.substring
            turnsStr += internalSeparator
            turnsStr += String (turn.substringStart)
            turnsStr += internalSeparator
            turnsStr += String (turn.subStringLength)
            turnsStr += internalSeparator
            turnsStr += String (turn.pointsEarned)
            turnsStr += internalSeparator
            turnsStr += String (turn.turn)
            
            //The initiator will play even rounds, starting from 0.
            //The opponent will play odd rounds, starting from 1.
            //The initiator's and opponent's scores are calculated from their turns.
            if i%2 == 0 {
                scoreInitiator += turn.pointsEarned
            } else {
                scoreOpponent += turn.pointsEarned
            }
            
            if i < matchDataTurnDataObjects.count {
                
                turnsStr += externalSeparator
                i += 1
            }
        }
        
        str += turnsStr
        str += majorSeparator
        
        i -= 1
        str += String(Int(ceil((CGFloat(i)/2)+1)))
        str += majorSeparator
        str += String(scoreInitiator)
        str += majorSeparator
        str += String(scoreOpponent)
        str += majorSeparator
        str += String(matchDataTuple.playerGroup)
        str += majorSeparator
        str += dateFormater.string(from: Date())
        str += majorSeparator
        str += String(matchDataTuple.readChatMessages1)
        str += majorSeparator
        str += String(matchDataTuple.readChatMessages2)
        
        return str.data(using: String.Encoding.utf8)!
    }

    class func retrieveTurnsData(_ turns: String) -> [TurnDataObject] {
        
        let externalSeparator = "[]"
        let internalSeparator = "(:)"
        
        var turnsObjects = [TurnDataObject]()
        var turnsArray = [String]()
        
        if  NSString(string: turns).contains(externalSeparator) {
            
            turnsArray = turns.components(separatedBy: externalSeparator)
            
        } else {
            
            turnsArray.append(turns)
        }
        
        for turn in turnsArray {
            
            let turnData = turn.components(separatedBy: internalSeparator)
            let oneTurn:TurnDataObject = TurnDataObject()
            oneTurn.playerID = turnData[0]
            oneTurn.word = turnData[1]
            oneTurn.substring = turnData[2]
            oneTurn.substringStart = Int(turnData[3])
            oneTurn.subStringLength = Int(turnData[4])
            oneTurn.pointsEarned = Int(turnData[5])
            oneTurn.turn = Int(turnData[6])
            
            turnsObjects.append(oneTurn)
        }
        
        return turnsObjects
    }
}
