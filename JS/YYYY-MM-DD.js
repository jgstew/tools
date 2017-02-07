
// http://stackoverflow.com/a/16714931/861745
function fnYYYY_MM_DD(objDate) {
	if (objDate === undefined) {
		objDate = new Date();
	}
	return objDate.toISOString().slice(0,10);
}

// if this file is run directly, do the following:
if (require.main === module) {
	console.log( fnYYYY_MM_DD() );
}
