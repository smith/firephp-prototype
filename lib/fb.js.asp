/**
 * Sends the given data to FirePHP Firefox Extension.
 * The data can be displayed in the Firebug Console or in the
 * "Server" request tab.
 * 
 * This script will only work in the ASP JScript server environment.
 * 
 * Usage:
 * 
 * <script runat="both" src="../lib/prototype.js"></script>
 * <script runat="server" src="../lib/fb.js"></script>
 * <script runat="server">
 *   fb('Hello World');
 *   fb('Hello World 2');
 *
 *   fb('Log message', fb.LOG);
 *   fb('Info message', fb.INFO);
 *   fb('Warn message', fb.WARN);
 *   fb('Error message', fb.ERROR);
 *
 *   fb('Message with label','Label', fb.LOG);
 *
 *   fb({ a : 1, b : 2, c : 3 }, 'Some object', fb.LOG);
 *
 *   try {
 *     throw new Error('Test Exception');
 *   } catch(e) {
 *     fb(e);
 *   }
 *
 *   // Will show only in "Server" tab for the request
 *   fb({ a : 1, b : 2, c : 3 }, 'Some object', fb.DUMP);
 *</script>
 *                                   
 * This is a version using the Prototype.js framework, based on the JQuery
 * version by Christoph Dorn <christoph@christophdorn.com>
 *
 * @author      Nathan L Smith <smith@nlsmith.com>
 * @license     http://www.opensource.org/licenses/bsd-license.php
 */

if (typeof fb === "undefined") {
  function fb() {
    if (typeof Prototype === "undefined") {
        throw new Error("fb.js requires prototype.js");
    }

    // Set up the server environment for ASP
    var hasASP = typeof Request === "object" && typeof Response === "object";
    var isOnServer = hasASP

    if (!isOnServer) {
        throw new Error('fb.js requires A server environment (ASP)');
    }

    fb.index = fb.index || 0;
    fb.enabled = fb.enabled || true;
    fb.hasConsoleHeaders = fb.hasConsoleHeaders || false;
    fb.hasDumpHeaders = fb.hasDumpHeaders || false;
    fb.LOG = 'log';
    fb.INFO = 'info';
    fb.WARN = 'warn';
    fb.ERROR = 'error';
    fb.DUMP = 'dump';

    // ASP specific variables
    var req, resp, addHeader, agent;
    req = Request;
    resp = Response;
    addHeader = function (name, value) { resp.addHeader(name, value); }
    agent = String(Request.ServerVariables('HTTP_USER_AGENT'));

    var argc = arguments.length;
    var item = {
        obj : arguments[0] || {},
        facility : fb.LOG,
        label : null
    };
    var out = [];
    var headers = {};
    var startHeaders = {
    'X-FirePHP-Data-100000000001' : '{',
    'X-FirePHP-Data-999999999999' : '"__SKIP__":"__SKIP__"}'
    };

    // is FirePHP installed? Skip the version check, just see if it's in 
    // the user agent
    var hasFirePHP = agent.include("FirePHP");

    /**
     * Format the data headers and send them to the response
     */
    function send() {
        var message = '';
        var messageParts = [];
        var dataHeader = 'X-FirePHP-Data-'
        var maxLength = 5000;
        var dumpHeaders = {
            'X-FirePHP-Data-200000000001' : '"FirePHP.Dump":{',
            'X-FirePHP-Data-299999999999' : '"__SKIP__":"__SKIP__"},'
        };
        var consoleHeaders = {
            'X-FirePHP-Data-300000000001' : '"FirePHP.Firebug.Console":[',
            'X-FirePHP-Data-399999999999' : '["__SKIP__"]],'
        }
        
        // Check to see if a header has already been added
        function hasHeaders(newHeaders) {
          return Object.keys(headers).include(Object.keys(newHeaders)[0]);
        }
        if (fb.index < 1) {
            Object.extend(headers, startHeaders);
        }
        
        if (item.facility === fb.DUMP) {
            // Add headers for this facility if they haven't been added yet
            if (!fb.hasDumpHeaders) {
              Object.extend(headers, dumpHeaders);
              fb.hasDumpHeaders = true;
            }
            dataHeader += '2';
            if (item.label) {
                message = '"' + item.label + '" : ' + 
                    Object.toJSON(item.obj) + ', ';
            } else {
                message = '"" : ' + 
                    Object.toJSON(item.obj) + ', ';
            }
        } else {
            // Add headers for this facility if they haven't been added yet
            if (!fb.hasConsoleHeaders) {
              Object.extend(headers, consoleHeaders);
              fb.hasConsoleHeaders = true;
            }
            dataHeader += '3';
            if (item.label) {
                message = '["' + item.facility + '",["' +
                    item.label + '",' + Object.toJSON(item.obj) + ']], ';
            } else {
                message = '["' + item.facility + '",' +
                    Object.toJSON(item.obj) + '], ';
            }
        }

        // Long messages should be split up in individual requests of
        // maxLength
        //
        // This has only been tested with maxLength 5000
        // and request sizes less than 5000
        messageParts = $A(message).eachSlice(maxLength);
        messageParts.each(function (part, index) {
            // Create the unique header for this item in the format 
            // SSMMMIIIIII
            part = part.join(''); // Turn the part back into a string
            var date = new Date();
            var s = date.getSeconds();
            var ms = date.getMilliseconds(); // milliseconds
            var pad = { s : 2, ms : 3, index : 6 };

            fb.index += 1; // Increment the global index

            // Created header with padded numbers
            dataHeader += s.toPaddedString(pad.s) + 
                ms.toPaddedString(pad.ms) + 
                fb.index.toPaddedString(pad.index);
            headers[dataHeader] = part;
        });


        for (header in headers) {
             addHeader(header, headers[header], true);
        }
    }

    if (hasFirePHP && fb.enabled) {
        if (argc === 2) {
            item.facility = arguments[1] || item.facility;    
        } else if (argc === 3) {
            item.label = arguments[1] || item.label;
            item.facility = arguments[2] || item.facility;
        } else if (argc < 1 || argc > 3) {
            throw new Error('Wrong number of arguments to fb function');
        } 
        // If there's an error, it must be thrown with 'new Error(...)' 
        // to show up as an error
        if (item.obj instanceof Error) {
            item.facility = fb.ERROR;
        }
        send(item);
    }
  }
}
