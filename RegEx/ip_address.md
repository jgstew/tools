
- https://www.regular-expressions.info/ip.html
- https://regexr.com/3upie

`\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b`

Relevance Example: (not ideal, gives partial matches)

    Q: unique values of matches (regex "\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b") of lines of files "sample_text_IPs.txt"
    A: 0.1.1.1
    A: 10.1.1.1
    A: 192.1.1.1
    A: 2.1.1.1
    A: 92.1.1.1
    T: 1.553 ms

Relevance turning it into a string set:

    Q: ("%22" & it & "%22") of concatenations "%22 ; %22" of unique values of matches (regex "\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b") of lines of files "sample_text_IPs.txt"
    A: "0.1.1.1" ; "10.1.1.1" ; "192.1.1.1" ; "2.1.1.1" ; "92.1.1.1"
    T: 1.620 ms
    
Session Relevance getting list of matching BES Computers:

    (name of item 0 of it | "<noname>", ip address of item 0 of it as string | "<noIP>", id of item 0 of it) of (it, ip addresses of it as string) whose( item 1 of it is contained by set of ("0.1.1.1" ; "10.1.1.1" ; "192.1.1.1" ; "2.1.1.1" ; "92.1.1.1") ) of bes computers


NOTE: using `first matches` in the relevance helps with the partial match issue above.
