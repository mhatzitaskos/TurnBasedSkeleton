//
//  ProfilePhoto.swift
//  TurnBasedTest
//
//  Created by Markos Hatzitaskos on 350/12/15.
//  Copyright © 2015 Markos Hatzitaskos. All rights reserved.
//

import Foundation
import GameKit

class ProfilePhoto {
    
    class func loadPhoto(_ player: GKPlayer?, view: UIView, smallSize: Bool) {
        
        var fontSize: CGFloat = 0.0
        
        if currentDevice! == .iPad {
            
            if smallSize {
                
                //print("Small iPad Photo")
                fontSize = CGFloat(48)
                
            } else {
                
                //print("Large iPad Photo")
                fontSize = CGFloat(70.0)
                
            }
            
        } else {
            
            if smallSize {
                
                //print("Small iPhone Photo")
                fontSize = CGFloat(40.0)
                
            } else {
                
                //print("Large iPhone Photo")
                fontSize = CGFloat(55.0)
                
            }
        }
        
        let singleton = GameCenterSingleton.sharedInstance
        
        if let p = player {
            
            let size = smallSize ? GKPhotoSizeSmall : GKPhotoSizeNormal
            var photoAlreadyLoaded = false
            var profilePhoto: UIImage!
            
            if size == GKPhotoSizeNormal {
                
                if let photo = singleton.normalProfilePhotosDictionary[p.playerID!] {
                    photoAlreadyLoaded = true
                    profilePhoto = photo
                }
                
            } else {
                
                if let photo = singleton.smallProfilePhotosDictionary[p.playerID!] {
                    photoAlreadyLoaded = true
                    profilePhoto = photo
                } else if let photo = singleton.normalProfilePhotosDictionary[p.playerID!] {
                    photoAlreadyLoaded = true
                    profilePhoto = photo
                }
            }
            
            if photoAlreadyLoaded {
                
                print("Profile photo already loaded, reusing")
                let iconView = view
                let profileImageView = UIImageView(frame: iconView.frame)
                profileImageView.center = CGPoint(x: iconView.frame.width/2, y: iconView.frame.height/2)
                profileImageView.contentMode = UIViewContentMode.scaleAspectFit
                profileImageView.image = profilePhoto
                iconView.addSubview(profileImageView)
                
            } else {
                
                print("Profile photo loading...")
                
                let iconView = view
                
                if view.backgroundColor != nil {
                    iconView.backgroundColor = view.backgroundColor!
                } else {
                    iconView.backgroundColor = UIColor.purple
                }
                
                let initialsLabel = UILabel(frame: iconView.frame)
                
                //initialsLabel.text = p.alias!.substringToIndex(p.alias!.characters.index(p.alias!.startIndex, offsetBy: 2)).uppercased()
                initialsLabel.text = p.alias!.prefix(2).uppercased()

                initialsLabel.textAlignment = NSTextAlignment.center
                initialsLabel.textColor = UIColor.white
                initialsLabel.font = UIFont(name: "Impact", size: fontSize)
                initialsLabel.center = CGPoint(x: iconView.frame.width/2, y: iconView.frame.height/2)
                iconView.addSubview(initialsLabel)
                
                p.loadPhoto(for: size, withCompletionHandler: {
                    image, error in
                    
                    if (error != nil) {
                        
                        if let playerID = p.playerID {
                            
                            if size == GKPhotoSizeNormal {
                                
                                profilePhoto = iconView.pb_takeSnapshot()
                                singleton.normalProfilePhotosDictionary[playerID] = profilePhoto
                                
                            } else {
                                
                                profilePhoto = iconView.pb_takeSnapshot()
                                singleton.smallProfilePhotosDictionary[playerID] = profilePhoto
                                
                            }
                        }
                        
                    } else {
                        
                        let profilePhoto = image
                        let profileImageView = UIImageView(frame: iconView.frame)
                        profileImageView.center = CGPoint(x: iconView.frame.width/2, y: iconView.frame.height/2)
                        profileImageView.contentMode = UIViewContentMode.scaleAspectFit
                        profileImageView.image = profilePhoto
                        iconView.addSubview(profileImageView)
                        
                        if let playerID = p.playerID {
                            
                            if size == GKPhotoSizeNormal {
                                
                                singleton.normalProfilePhotosDictionary[playerID] = profilePhoto
                                
                            } else {
                                
                                singleton.smallProfilePhotosDictionary[playerID] = profilePhoto
                                
                            }
                        }
                    }
                    
                    
                })
                
            }
        } else {
            
            let iconView = view
            
            if view.backgroundColor != nil {
                iconView.backgroundColor = view.backgroundColor!
            } else {
                iconView.backgroundColor = UIColor.purple
            }
            
            let initials = String.fontAwesomeIconWithName(FontAwesome.User)
            
            let initialsLabel = UILabel(frame: iconView.frame)
            initialsLabel.text = initials
            initialsLabel.textAlignment = NSTextAlignment.center
            initialsLabel.textColor = UIColor.white
            initialsLabel.font = UIFont.fontAwesomeOfSize(fontSize)
            initialsLabel.center = CGPoint(x: iconView.frame.width/2, y: iconView.frame.height/2)
            iconView.addSubview(initialsLabel)
        }
    }
    
    class func loadPhotos(_ player1: GKPlayer?, view1: UIView, player2: GKPlayer?, view2: UIView, smallSize: Bool) {
        
        ProfilePhoto.loadPhoto(player1, view: view1, smallSize: smallSize)
        ProfilePhoto.loadPhoto(player2, view: view2, smallSize: smallSize)
    }
    
}

class SingleSmallProfilePhoto: UIView {
    
    init(player: GKPlayer?) {
        var width = CGFloat(60)
        if currentDevice! == .iPad {
            width = CGFloat(90)
        }
        
        let frame =  CGRect(x: 0, y: 0, width: width, height: width)
        super.init(frame: frame)
        
        self.layer.cornerRadius = self.frame.size.width/2
        self.clipsToBounds = true
        ProfilePhoto.loadPhoto(player, view: self, smallSize: true)
    }
    
    init(playerID: String) {
        var width = CGFloat(60)
        if currentDevice! == .iPad {
            width = CGFloat(90)
        }
        
        let frame =  CGRect(x: 0, y: 0, width: width, height: width)
        super.init(frame: frame)
        
        GKPlayer.loadPlayers(forIdentifiers: [playerID], withCompletionHandler: {
            players, error in
            
            if error != nil {
                
                print("")
                print("ERROR: Cannot load players")
                
            } else {
                
                let player = players!.first! as GKPlayer
                
                self.layer.cornerRadius = self.frame.size.width/2
                self.clipsToBounds = true
                ProfilePhoto.loadPhoto(player, view: self, smallSize: true)
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SingleLargeProfilePhoto: UIView {
    
    var playerIDNumber: String?
    var iconViewSize = currentDevice == Device.iPad ? CGFloat(160) : CGFloat(96)
    
    init(player: GKPlayer?) {
        
        let frame =  CGRect(x: 0, y: 0, width: iconViewSize, height: iconViewSize)
        super.init(frame: frame)
        
        if let p = player {
            playerIDNumber = p.playerID
        }
        
        self.layer.cornerRadius = self.frame.size.width/2
        self.clipsToBounds = true
        ProfilePhoto.loadPhoto(player, view: self, smallSize: false)
    }
    
    init(playerID: String) {
        
        let frame =  CGRect(x: 0, y: 0, width: iconViewSize, height: iconViewSize)
        super.init(frame: frame)
        
        GKPlayer.loadPlayers(forIdentifiers: [playerID], withCompletionHandler: {
            players, error in
            
            if error != nil {
                
                print("")
                print("ERROR: Cannot load players")
                
            } else {
                
                let player = players!.first! as GKPlayer
                
                self.playerIDNumber = player.playerID
                
                self.layer.cornerRadius = self.frame.size.width/2
                self.clipsToBounds = true
                ProfilePhoto.loadPhoto(player, view: self, smallSize: false)
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
