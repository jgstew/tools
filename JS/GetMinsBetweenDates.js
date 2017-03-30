
// http://www.htmlgoodies.com/html5/javascript/calculating-the-difference-between-two-dates-in-javascript.html
Date.minsBetween = function( date1, date2 ) {
  //Get 1 min in milliseconds
  var one_min=1000*60;

  // Convert both dates to milliseconds
  var date1_ms = new Date(date1).getTime();
  var date2_ms = new Date(date2).getTime();

  // Calculate the difference in milliseconds
  var difference_ms = date2_ms - date1_ms;
    
  // Convert back to min and return
  return Math.round(difference_ms/one_min); 
}

// Used here: https://github.com/jgstew/bigfix-content/blob/master/clientui/information/_dashboard.html
