// parse javascript datetime into BigFix time string
function fnDateBigFixFromTime(objDateTime) {
	if (objDateTime === undefined) {
		strDateBigFix = moment().format('DD MMM YYYY HH:mm:SS ZZ');
	} else {
		strDateBigFix = moment(objDateTime).format('DD MMM YYYY HH:mm:SS ZZ');
	}
	return strDateBigFix
}

// check if moment is defined
if (typeof moment == "undefined") {
  console.log( "moment undefined!" );
  // TODO: load moment?
}

// if this file is run directly, do the following:
if (typeof require == "undefined" || require.main === module) {
  // do the following only if file run directly with node or if it is run in the browser.
	console.log( fnDateBigFixFromTime() );
}
