/**
 * Partial implementation of the Firebug console API. 
 *
 * Right now it uses fb() and only supports the included methods. Objects are
 * only dumped; printf style formatting is not implemented
 */

if (typeof console === "undefined") {
    if (typeof fb !== "function") {
        throw 'The fb() function is required';
    }

    var console = {
        log : function (m) { return fb(m, fb.LOG); },
        info : function (m) { return fb(m, fb.INFO); },
        warn : function (m) { return fb(m, fb.WARN); },
        error : function (m) { return fb(m, fb.ERROR); }
    };
}
