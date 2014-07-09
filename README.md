Protest
=======

Protest organizing application created originally for a hackathon at UC Santa Cruz. Allows protestors to communicate and coordinate with each other anonymously, without having to fight to be heard. It works peer to peer so even if police (or an oppressive regime) were to shut down cell phone towers (as they did here: wapo.st/1jdfMUY) protestors would still be able to send and recieve messages.

![alt tag](http://i.imgur.com/CpFGhuh.png)

Security Model
--------------

![alt tag](http://i.imgur.com/x9irP5W.png)

Based on this paper: (http://ecee.colorado.edu/~ekeller/classes/fall2013_advsec/papers/tarzan_ccs02.pdf) 

The protocol is designed to preserve the anonymity of all peers in the network. Messages are sent along a random path (n=3) through the network with layered encryption. The final peer in the chain decrypts the plaintext and broadcasts it to all peers in the network. Networks can be set up with or without a password. Passwords disseminate through word of mouth in a crowd. Ideally, no one in the crowd would give the password to the police or security forces.



