Protest
=======

[![Build Status](https://travis-ci.org/jackflips/Protest.svg?branch=master)](https://travis-ci.org/jackflips/Protest)

Note: Please do not use yet. This is a work in progress and there are extant security issues.

Protest organizing application created originally for a hackathon at UC Santa Cruz. Allows protestors to communicate and coordinate with each other anonymously, without having to fight to be heard. It works peer to peer so even if police (or an oppressive regime) were to shut down cell phone towers (as they did here: http://wapo.st/1jdfMUY) protestors would still be able to send and recieve messages.

Protests can be set up with a password, which disseminates via word of mouth in the crowd, ideally not being shared with police or security forces. Organizers can designate lieutenants and make the protest read-only except to them, helping to mitigate noise when there are hundreds or thousands of protesters.

![alt tag](http://i.imgur.com/CpFGhuh.png)

Security Model
--------------
Based on this paper: (http://ecee.colorado.edu/~ekeller/classes/fall2013_advsec/papers/tarzan_ccs02.pdf) 

The protocol is designed to preserve the anonymity of all peers in the network. Messages are sent along a random path (n=3) through the network with layered encryption. The final peer in the chain decrypts the plaintext and broadcasts it to all peers in the network.

![alt tag](http://i.imgur.com/x9irP5W.png)



