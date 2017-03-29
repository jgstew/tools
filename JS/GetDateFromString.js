// parse bigfix formatted datetime string to javascript datetime
// REQUIRES: moment.js  <script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.18.1/moment.min.js" integrity="sha256-1hjUhpc44NwiNg8OwMu2QzJXhD8kcj+sJA3aCQZoUjg=" crossorigin="anonymous"></script>
function fnDateFromString(strDateTime) {
	if (strDateTime === undefined) {
		objDate = moment();
	} else {
    objDate = moment(strDateTime);
  }
	return objDate
}

// if this file is run directly, do the following:
if (typeof require == "undefined" || require.main === module) {
  // do the following only if file run directly with node or if it is run in the browser. 
	console.log( fnDateFromString("Mon, 14 Mar 1960 12:01:45 -0700").toISOString() );
}
