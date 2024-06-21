
// http://stackoverflow.com/questions/11279441/return-all-of-the-functions-that-are-defined-in-a-javascript-file
// http://www.w3schools.com/js/js_function_definition.asp

// `this` contains all objects/functions/etc...
// if( this[i] ) checks for existence
// if( "function"==(typeof this[i]).toString() ) checks that it is a function
// this[i].toString() returns the function declaration
// ~this[i].toString().indexOf("[native code]") this returns 0 (false) if `[native code]` is not within the declaration
// if( !~this[i].toString().indexOf("[native code]") ) checks that `[native code]` is not within the declaration

// self-invoking function expression:
(function () {
    document.write('<h2>Javascript Functions:</h2><ul>');
    for(var i in this) {
        if( this[i] && "function"==(typeof this[i]).toString() && !~this[i].toString().indexOf("[native code]") ) {
            document.write('<li>'+ this[i].toString() +"</li>");
        }
    }
    document.write('</ul>');
})();
