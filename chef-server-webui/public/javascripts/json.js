/*
	Do NOT use this version as it was slightly modified to accomodate editing and returning of functions!
	use this version instead: http://www.JSON.org/json2.js
*/

if (!this.JSON) {
    JSON = function () {
        function f(n) {return n < 10 ? '0' + n : n;}
        Date.prototype.toJSON = function () {
            return this.getUTCFullYear()   + '-' +
                 f(this.getUTCMonth() + 1) + '-' +
                 f(this.getUTCDate())      + 'T' +
                 f(this.getUTCHours())     + ':' +
                 f(this.getUTCMinutes())   + ':' +
                 f(this.getUTCSeconds())   + 'Z';
        };
        var meta = {
                '\b': '\\b',
                '\t': '\\t',
                '\n': '\\n',
                '\f': '\\f',
                '\r': '\\r',
                '"' : '\\"',
                '\\': '\\\\'
            },
            escapeable = /["\\\x00-\x1f\x7f-\x9f]/g;

        function quote(string) {
            return escapeable.test(string) ?
                '"' + string.replace(escapeable, function (a) {
                    var c = meta[a];
                    if (typeof c === 'string') {
                        return c;
                    }
                    c = a.charCodeAt();
                    return '\\u00' + Math.floor(c / 16).toString(16) +
                                               (c % 16).toString(16);
                }) + '"' :
                '"' + string + '"';
        }

        function stringify(key, holder, replacer) {
            var i,
                k,
                v,
                length,
                partial,
                value = holder[key];
            if (value && typeof value === 'object' &&
                    typeof value.toJSON === 'function') {
                value = value.toJSON(key);
            }
            if (typeof replacer === 'function') {
                value = replacer.call(holder, key, value);
            }
            switch (typeof value) {
            case 'string':
                return quote(value);
				
			/* added for the BC Json Editor to enable editing of functions */
			case 'function':
				return value;
				
            case 'number':
                return isFinite(value) ? String(value) : 'null';
            case 'boolean':
            case 'null':
                return String(value);
            case 'object':
                if (!value) {
                    return 'null';
                }
                partial = [];
                if (typeof value.length === 'number' &&
                        !(value.propertyIsEnumerable('length'))) {
                    length = value.length;
                    for (i = 0; i < length; i += 1) {
                        partial[i] = stringify(i, value, replacer) || 'null';
                    }
                    return '[' + partial.join(',') + ']';
                }
                if (typeof replacer === 'object') {
                    length = replacer.length;
                    for (i = 0; i < length; i += 1) {
                        k = replacer[i];
                        if (typeof k === 'string') {
                            v = stringify(k, value, replacer);
                            if (v) {
                                partial.push(quote(k) + ':' + v);
                            }
                        }
                    }
                } else {
                    for (k in value) {
                        v = stringify(k, value, replacer);
                        if (v) {
                            partial.push(quote(k) + ':' + v);
                        }
                    }
                }
                return '{' + partial.join(',') + '}';
            }
        }
        return {
            stringify: function (value, replacer) {
                if (typeof replacer !== 'function') {
                    if (!replacer) {
                        replacer = function (key, value) {
                            if (!Object.hasOwnProperty.call(this, key)) {
                                return undefined;
                            }
                            return value;
                        };
                    } else if (typeof replacer !== 'object' ||
                            typeof replacer.length !== 'number') {
                        throw new Error('JSON.stringify');
                    }
                }
                return stringify('', {'': value}, replacer);
            },

            parse: function (text, reviver) {
                var j;
                function walk(holder, key) {
                    var k, v, value = holder[key];
                    if (value && typeof value === 'object') {
                        for (k in value) {
                            if (Object.hasOwnProperty.call(value, k)) {
                                v = walk(value, k);
                                if (v !== undefined) {
                                    value[k] = v;
                                } else {
                                    delete value[k];
                                }
                            }
                        }
                    }
                    return reviver.call(holder, key, value);
                }
                if (/^[\],:{}\s]*$/.test(text.replace(/\\["\\\/bfnrtu]/g, '@').
replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').
replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                    j = eval('(' + text + ')');
                    return typeof reviver === 'function' ?
                        walk({'': j}, '') : j;
                }
                throw new SyntaxError('JSON.parse');
            },
			info:{"version":"","www":"http://www.json.org/","date":"2008-03-22","description":"Open source code of a JSON parser and JSON stringifier. [Douglas Crockford]"},
            quote: quote
        };
    }();
}
