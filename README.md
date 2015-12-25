# TurnBasedSkeleton

This project aims to create a skeleton for any turn based game using GameCenter.
As GameCenter seems to lack in documentation and tutorials, especially as far as turn based gaming is concerned, I decided to create this project to help others who might want to integrate GameCenter to their projects.
This project (as-is) supports two player games. This could easily change with minimal alterations of the code.

This project uses a custom UI to:<br>

<ul>
  <li>present a list of all games</li>
  <li>display the local player's friends and allow him/her to pick one to invite
  	<ul>
  		<li>For the opponent to receive the invitation a turn must also be sent, as well as a reminder. Thus, in order to invite a friend, a friend is selected, an invitation request is made, a turn is taken and a reminder is sent.</li>
  	</ul>
  </li>
  <li>accept/decline an invitation</li>
  <li>end and remove an active game</li>
</ul>

This project:<br>
<ul>
	<li>Allows the local user to login to GameCenter. If the local user is not already logged in through his/her device, the GameCenter login screen will appear.
	<ul>
  	<li>If the local user does not login to GameCenter, an error message will appear.</li>
  	<li>If the local user logs in to GameCenter, the program continues.</li>
  	</ul>
	</li>
	<li>Allows the local user to get a list of all:
	<ul>
  	<li>Games that are his/her turn</li>
  	<li>Games that are the opponent's turn</li>
  	<li>Games he/she is invited to</li>
  	<li>Games he/she has initiated and have not been accepted or declined yet</li>
  	<li>Games that have ended</li>
  	</ul>
	</li>
	<li>Allows the local user to remove a game that has ended from the games list
	</li>
	<li>Allows the local user to receive a new turn from an opponent, including data
	</li>
	<li>Allows the local user to send a new turn to an opponent, including data
	</li>
	<li>Allows the local user to receive and be notified of a new invitation from an opponent
	</li>
</ul>
Special thanks go to:<br>
	•	IJReachability (https://github.com/Isuru-Nanayakkara/Reach/tree/master)<br>
	•	MBProgressHUD (https://github.com/jdg/MBProgressHUD)<br>
	•	FontAwesome (https://github.com/thii/FontAwesome.swift)<br>
