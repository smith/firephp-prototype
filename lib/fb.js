/**
 * Sends the given data to FirePHP Firefox Extension.
 * The data can be displayed in the Firebug Console or in the
 * "Server" request tab.
 * 
 * This script will only work in the Jaxer server environment.
 * See: http://www.aptana.com/jaxer/.
 * 
 * Usage:
 * 
 * <script runat="both" src="lib/prototype.js"></script>
 * <script runat="server" src="lib/fb.js"></script>
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
 *   fb(Jaxer.request, 'Jaxer.request', fb.LOG);
 *
 *   try {
 *     throw new Error('Test Exception');
 *   } catch(e) {
 *     fb(e);
 *   }
 *
 *   // Will show only in "Server" tab for the request
 *   fb(Jaxer.session, 'Jaxer.session', fb.DUMP);
 *</script>
 *                                   
 * This is a version using the Prototype.js framework, based on the JQuery
 * version by Christoph Dorn <christoph@christophdorn.com>
 *
 * @author      Nathan L Smith <smith@nlsmith.com>
 * @license     http://www.opensource.org/licenses/bsd-license.php
 */

if (typeof fb === "undefined") {
    if (typeof Prototype === "undefined") {
        throw new Error("fb.js requires prototype.js");
    }

    var fb = function () {
        // Check for the server environment
        var hasJaxer = typeof Jaxer === "object" && Jaxer.isOnServer
        var isOnServer = hasJaxer

        if (!isOnServer) {
            throw new Error('fb.js requires the Jaxer server environment');
        }

        // Set up environment
        var req = Jaxer.request;
        var resp = Jaxer.response;
        var headers = resp.headers;
        var agent = req.headers['User-Agent'] || '';

        // Is FirePHP installed? Skip the version check, just see if it's in 
        // the user agent. Don't run if it's not there
        var hasFirePHP = agent.include("FirePHP");
        if (!hasFirePHP || !fb.enabled) { return; }

        var argc = arguments.length;
        var item = {
            obj : arguments[0] || {},
            facility : fb.LOG,
            label : null
        };
        var startHeaders = {
   	    'X-FirePHP-Data-100000000001' : '{',
   	    'X-FirePHP-Data-999999999999' : '"__SKIP__":"__SKIP__"}'
        };
 
        /**
         * Format the data headers and send them to the response
         */
        function send() {
            var message = '';
            var messageParts = [];
            var dataHeader = 'X-FirePHP-Data-'
            var maxLength = 5000;

            Object.extend(headers, startHeaders);
            
            if (item.facility === fb.DUMP) { // Handle DUMP
                Object.extend(headers, {
                    'X-FirePHP-Data-200000000001' : '"FirePHP.Dump":{',
                    'X-FirePHP-Data-299999999999' : '"__SKIP__":"__SKIP__"},'
                });
                dataHeader += '2';
                if (item.label) {
                    message = '"#{label}" : #{obj}, '; 
                } else {
                    message = '"" : #{obj}, ';
                }
            } else {                        // Handle LOG, et. al
                Object.extend(headers, {
                    'X-FirePHP-Data-300000000001' : '"FirePHP.Firebug.Console":[',
                    'X-FirePHP-Data-399999999999' : '["__SKIP__"]],'
                });    
                dataHeader += '3';
                if (item.label) {
                    message = '["#{facility}", ["#{label}", #{obj}]], ';
                } else {
                    message = '["#{facility}", #{obj}], ';
                }
            }
            message = message.interpolate(item);

            // Long messages should be split up in individual requests of
            // maxLength
            //
            // This has only been tested with maxLength 5000
            // and request sizes less than 5000
            messageParts = $A(message).eachSlice(maxLength);
            messageParts.each(function (part) {
                // Create the unique header for this item in the format 
                // SSMMMIIIIII
                part = part.join(''); // Turn the part back into a string
                var date = new Date();
                var s = date.getSeconds();
                var ms = date.getMilliseconds(); // milliseconds
                var pad = { s : 2, ms : 3, index : 6 };

                fb.index += 1; // Increment the global index

                // Create header with padded numbers
                dataHeader += s.toPaddedString(pad.s) + 
                    ms.toPaddedString(pad.ms) + 
                    fb.index.toPaddedString(pad.index);
                headers[dataHeader] = part;
            });
        }

        // Create the item object and send it
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
        item.obj = Object.toJSON(item.obj); // JSONify item
        send(item);
    }

    Object.extend(fb, {
        index : 0,
        enabled : true,
        LOG : 'log',
        INFO: 'info',
        WARN: 'warn',
        ERROR: 'error',
        DUMP: 'dump'
    });
}
