"prefetch filename.ext sha1:" + 
$('div#file-details.extra-info').children('div').children('div:has(> span:contains("SHA1") )').contents().filter(function() { return this.nodeType == 3; }).text().trim() +
" size:" +
$('div#file-details.extra-info').children('div').children('div:has(> span:contains("File size") )').contents().filter(function() { return this.nodeType == 3; }).text().split(' ( ')[1].split(' bytes ')[0] +
" http://URL sha256:" +
$('div#file-details.extra-info').children('div').children('div:has(> span:contains("SHA256") )').contents().filter(function() { return this.nodeType == 3; }).text().trim();