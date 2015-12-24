# TurnBasedSkeleton

This project aims to create a skeleton for any turn based game using GameCenter.
As GameCenter seems to lack in documentation and tutorials, especially as far as turn based gaming is concerned, I decided to create this project to help others who might want to integrate GameCenter to their projects.

This project uses a custom UI to:
	•	present a list of all games
	•	display the local player's friends and allow him/her to pick one to invite
	  ⁃	For the opponent to receive the invitation a turn must also be sent. Thus, in order to invite a friend, a friend is selected, an invitation request is made, and then a turn is also taken.
	•	accept/decline an invitation
	•	end and remove an active game

This project:

	•	Allows the local user to login to GameCenter. If the local user is not already logged in through his/her device, the GameCenter login screen will appear.
  	⁃	If the local user does not login to GameCenter, an error message will appear.
  	⁃	If the local user logs in to GameCenter, the program continues.

	•	Allows the local user to get a list of all:
  	⁃	Games that are his/her turn
  	⁃	Games that are the opponent's turn
  	⁃	Games he/she is invited to
  	⁃	Games he/she has initiated and have not been accepted or declined yet
  	⁃	Games that have ended

	•	Allows the local user to remove a game that has ended from the games list

	•	Allows the local user to receive a new turn from an opponent, including data

	•	Allows the local user to send a new turn to an opponent, including data

Special thanks go to:<br>
	•	IJReachability (https://github.com/Isuru-Nanayakkara/Reach/tree/master)<br>
	•	MBProgressHUD (https://github.com/jdg/MBProgressHUD)<br>
	•	FontAwesome (https://github.com/thii/FontAwesome.swift)<br>
