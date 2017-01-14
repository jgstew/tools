// NOTE: this isn't working for me... intended to prevent loading of `wizard.js`

// http://stackoverflow.com/questions/4755546/remove-div-tag-using-javascript-or-jquery
//  - http://stackoverflow.com/questions/4726362/use-javascript-to-prevent-a-later-script-tag-from-being-evaluated

// http://www.w3schools.com/jsref/met_document_getelementsbytagname.asp
var scripts = document.getElementsByTagName('script');

// http://www.w3schools.com/js/js_loop_for.asp
for(i = 0; i < scripts.length; i++) {
    if (scripts[i].hasAttribute('src') && scripts[i].getAttribute('src') == 'C:\Program Files (x86)\BigFix Enterprise\BES Console\reference\wizards.js') {
         scripts[i].parentNode.removeChild(scripts[i]);
    }
}
