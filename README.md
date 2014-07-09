Protest
=======

Protest organizing application created originally for a hackathon at UC Santa Cruz. Allows protestors to communicate and coordinate with each other anonymously, without having to fight to be heard. It works peer to peer so even if police (or an oppressive regime) were to shut down cell phone towers (as they did here: http://www.washingtonpost.com/blogs/worldviews/post/bart-san-francisco-cut-cell-services-to-avert-protest/2011/08/12/gIQAfLCgBJ_blog.html) protestors will still be able to send and recieve messages.

![alt tag](http://i.imgur.com/ja3PMsF.png)
![alt tag](http://i.imgur.com/Y1xpFsB.png)

Security Model: Based on this paper (http://ecee.colorado.edu/~ekeller/classes/fall2013_advsec/papers/tarzan_ccs02.pdf) Peers gossip public keys amongst themselves and layer encryption of messages as they send them along a random path of 3 peers. The third peer then broadcasts the message to all of the peers. This disguises the original sender.



