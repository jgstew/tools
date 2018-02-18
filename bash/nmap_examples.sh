
# https://security.stackexchange.com/questions/36198/how-to-find-live-hosts-on-my-network
# https://developer.bigfix.com/relevance/reference/network-adapter.html#cidr-string-of-network-adapter-string

nmap -sP -PS22,3389,52311 -PU161 {unique value of cidr strings of adapters of networks}
