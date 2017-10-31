
If using BigFix and multiple processes in a container, then it seems like it makes sense to always run bigfix as the last layer in the chain of nested docker images, then use bigfix to spawn multiple processes if desired.

### References:

- https://engineeringblog.yelp.com/2016/01/dumb-init-an-init-for-docker.html
