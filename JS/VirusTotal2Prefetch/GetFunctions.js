
// http://stackoverflow.com/questions/11279441/return-all-of-the-functions-that-are-defined-in-a-javascript-file

for(var i in this) {
    if( this[i] && "function"==(typeof this[i]).toString() ) {
        document.write('<li>'+ (this[i]).toString() +"</li>");
    }
}
