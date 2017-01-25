
Trying to get virus total comments

- https://zapier.com/help/code/

Work in progress:

```
fetch('https://www.virustotal.com/en/user/jgstew/comments/')
  .then(function(res) {
    return res.json().html;
  })
  .then(function(resHTML) {
    var output = {id: 1234, rawHTML: resHTML};
    callback(null, output );
  })
  .catch(callback);
```

In chrome console: `JSON.parse( $('body > pre').innerText ).html`

