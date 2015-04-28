## Questions ##

Q: "Is there a player I can down load and use now?"

A: Yes http://code.google.com/p/project-thunder-snow/downloads/detail?name=thundersnow-binary.zip&can=2&q=


Q: "Will it work as is?"

A: No, the radio stations in the playlist will not allow your website to access them this way. BUT, a flash developer CAN use the playlist as-is in the flash/flex IDE without restrictions, because we rock, and there is leeway in the IDE that you wont get in the wild.

Q: "Will it work on my web site with my radio station?"

A: Yes, with the following Recommendations



### Recommendations ###

I recommend getting a flash developer involved.

Q: "Why?"

A:

1) Because the library is not a trivial one in usage, and even seasoned developers trip on the demo-player code.

2) Because the included player, while skinned well, and despite that it will navigate the playlist, it is 'As-Is'.

3) Because the parsers for the various sources mostly work, but any issue normally fixed with simple additional code line in the parser cannot be done.

4) Because the technical aspect of choosing tcp or raw socket stream, the deployment issues as to where it is served from, and many other details require some knowledge.

5) Because knowing the difference between a crossdomain file and a crossdomain policy file server will make or break your deployment.



## More Questions ##

Q: "Cant I just set up an AACP player without the back-end crap to support features that I dont want or wont use ?"

A: Yes, but what fun is that? A flash developer who understands the operation of the core lib could write a url-stream object to pump tcp payloads into the transcoder. But now that I have thought about it, you can find just that in the downloads section. Check out the NBaac player.


Q: "WTF!! You think by now there would be some kind of consensus reached and aacp media should be as easy as mp3! When do we get somewhere like THAT!?!?"

A: Shoutcast server V2 will have a built in socket policy server to solve many problems.


Q: "Great, What about NOW!?!?"

A: If you serve the player from an ice cast web directory, you know, enable the icecast server to provide a web-server, you can ommit the need to use crossdomain files where the parser uses a TCP stream. woohoo...