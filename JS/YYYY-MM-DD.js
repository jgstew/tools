
// http://stackoverflow.com/a/16714931/861745
function fnYYYY_MM_DD(objDate) {
	if (objDate === undefined) {
		objDate = new Date();
	}
	return objDate.toISOString().slice(0,10);
}

// if this file is run directly, do the following:
if (typeof require == "undefined" || require.main === module) {
	// do the following only if file run directly with node or if it is run in the browser. 
	console.log( fnYYYY_MM_DD() );
}
