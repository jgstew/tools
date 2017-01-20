
// from here:  https://github.com/jgstew/bigfix-content/blob/master/dashboards/BaselineStatusResults.ojo

// Helper function designed to take jquery array result as input from a table and put it in the format NVD3 expects
//  - example values:  $("#results > tr > td:nth-child(2)")
//  - example lables:  $("#results > tr > td:nth-child(4)")
//  - usage: getChartData( $("#results > tr > td:nth-child(2)") , $("#results > tr > td:nth-child(4)") );
function getChartData(values, labels) {
    var arrKeyValuePairs = [];
    for (i = 0; i < values.length; i++) { 
        arrKeyValuePairs[i] = {
            "label": labels[i].innerText,
            "value": Number( values[i].innerText )
        };
    }
    return arrKeyValuePairs;
}

// http://stackoverflow.com/questions/8375625/how-to-select-a-table-column-with-jquery
// http://stackoverflow.com/questions/1168807/how-can-i-add-a-key-value-pair-to-a-javascript-object
// http://www.w3schools.com/jsref/jsref_number.asp
