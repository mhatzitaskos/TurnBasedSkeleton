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

public class MatchDataEncoding {
    
    class func decode(matchData: NSData) -> (initiator: String, turnsData: [TurnDataObject], currentRound: Int, score1: Int, score2: Int, playerGroup: Int, lastTurnTime: String, readChatMessages1: Int, readChatMessages2: Int) {

        if matchData.length > 0 {
            
            let majorSeparator = "<|>"
            
            let dataString = NSString(data: matchData, encoding: NSUTF8StringEncoding)
            let dataMessage: String = dataString as! String
            let messageArray: [String] = dataMessage.componentsSeparatedByString(majorSeparator)
            
            let initiator = String(messageArray[0])
            let turnsData = retrieveTurnsData(String(messageArray[1]))
            let currentRound = Int(messageArray[2])
            let score1 = Int(messageArray[3])
            let score2 = Int(messageArray[4])
            let playerGroup = Int(messageArray[5])
            let lastTurnTime = String(messageArray[6])
            let readChatMessages1 = Int(messageArray[7])
            let readChatMessages2 = Int(messageArray[8])
            
            return (initiator, turnsData, currentRound!, score1!, score2!, playerGroup!, lastTurnTime, readChatMessages1!, readChatMessages2!)
        
        } else {
            
            return (GKLocalPlayer.localPlayer().playerID!, [TurnDataObject](), 1, 0, 0, 0, "", 0, 0)
        }
    }
    
    class func encode(matchData: NSData, newTurn: TurnDataObject) -> NSData {
        
        let dateFormater = NSDateFormatter()
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
            
            if i < matchDataTurnDataObjects.count {
                
                turnsStr += externalSeparator
                i++
            }
            
        }
        
        str += turnsStr
        str += majorSeparator
        str += String(matchDataTuple.currentRound)
        str += majorSeparator
        str += String(matchDataTuple.score1)
        str += majorSeparator
        str += String(matchDataTuple.score2)
        str += majorSeparator
        str += String(matchDataTuple.playerGroup)
        str += majorSeparator
        str += dateFormater.stringFromDate(NSDate())
        str += majorSeparator
        str += String(matchDataTuple.readChatMessages1)
        str += majorSeparator
        str += String(matchDataTuple.readChatMessages2)
        
        return str.dataUsingEncoding(NSUTF8StringEncoding)!
    }

    class func retrieveTurnsData(turns: String) -> [TurnDataObject] {
        
        let externalSeparator = "[]"
        let internalSeparator = "(:)"
        
        var turnsObjects = [TurnDataObject]()
        var turnsArray = [String]()
        
        if  NSString(string: turns).containsString(externalSeparator) {
            
            turnsArray = turns.componentsSeparatedByString(externalSeparator)
            
        } else {
            
            turnsArray.append(turns)
        }
        
        for turn in turnsArray {
            
            let turnData = turn.componentsSeparatedByString(internalSeparator)
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