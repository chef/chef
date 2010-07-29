/*
         "version": "1.1.1", "www": "http://braincast.nl", "date": "jul 2010", "description": "Braincast Json Tree object." },
*/
var BCJT = function() {
    return {
        info: { "version": "1.1.1", "www": "http://braincast.nl", "date": "jul 2010", "description": "Braincast Json Tree object." },
        util: function() {
            function addLoadEvent(func) { var oldonload = window.onload; if (typeof window.onload != 'function') { window.onload = func; } else { window.onload = function() { if (oldonload) { oldonload(); } func(); }; } }
            function addEvent(obj, type, fn) { if (obj.attachEvent) { obj['e' + type + fn] = fn; obj[type + fn] = function() { obj['e' + type + fn](window.event); }; obj.attachEvent('on' + type, obj[type + fn]); } else { obj.addEventListener(type, fn, false); } }
            function getElementById(strid) { return document.getElementById(strid); }
            return { addLoadEvent: addLoadEvent, addEvent: addEvent, $$: getElementById };
        } (),
        tree: function() {
            var treeIndex = 0;
            var li = 0;
            function TreeUtil() {
                var oldA;
                function makeUrl(jsonpath, text, li, index, clickable) { return (clickable) ? "<a id=\"a" + li + "\" onclick=\"BCJT.tree.forest[" + index + "].getNodeValue('" + escape(jsonpath) + "', this);return false\">" + text + "</a>" : text; }
                function isTypeOf(thing) { return (thing !== null) ? thing.constructor : thing; }
                function strIsTypeOf(con) { switch (con) { case Array: return 'array'; case Object: return 'object'; case Function: return 'function'; case String: return 'string'; case Number: return 'number'; case Boolean: return 'boolean'; case null: return 'null'; default: return 'undeterimable type'; } }
                function getParentLi(item) {
                    /* not used */
                    return (item.nodeName == "LI") ? item.id : getParentLi(item.parentNode);
                }
                return {
                    strIsTypeOf: strIsTypeOf,
                    isTypeOf: isTypeOf,
                    getNodeValue: function(jsonPath, aobj) {
                        if (aobj) {
                            if (isTypeOf(aobj) == String) {
                                aobj = document.getElementById(aobj);
                            }
                            if (oldA) { oldA.className = "au"; } aobj.className = "as"; oldA = aobj;
                        }
                        this.cp = "BCJT.tree.forest[" + this.index + "]." + unescape(jsonPath);
                        this.ca = aobj;
                        this.cli = document.getElementById("li" + aobj.id.substr(1));
                        var params = { "jsonPath": "", "jsonValue": "", "jsonType": null, "a": {}, li: {} };
                        try {
                            var jsval = eval("BCJT.tree.forest[" + this.index + "]." + BCJTEP.escapeslashes(unescape(jsonPath)));
                            var typ = isTypeOf(jsval);
                            var txt;
                            if (typ == Function) {
                                txt = (jsval.toSource) ? jsval.toSource() : txt = jsval;
                            } else if (typ == String) {
                                txt = JSON.stringify(jsval).replace(/(^")|("$)/g, "");
                            } else {
                                txt = JSON.stringify(jsval);
                            }
                            params.jsonPath = jsonPath;
                            params.jsonValue = txt;
                            params.jsonType = strIsTypeOf(typ);
                            params.a = this.ca;
                            params.li = this.cli;
			    $$("autodetect").checked = false;
                            this.nodeclick(params);
                        } catch (e) {
                            BCJT.tree.error = "Could not get value!<br />" + e;
			    $$("log").innerHTML = BCJT.tree.error;
			    $$("console").style.display = "block";
                        }
                    },
                    makeTree: function(content, dots, inside) {
                        var out = ""; var t;
                        if (content === null) {
                            if (!inside) { out += "<ul><li><s>null</s></li></ul>"; }
                        } else if (isTypeOf(content) == Array) {
                            out += "<ul>";
                            for (var i = 0; i < content.length; i++) {
                                dots += "[" + i + "]";
                                t = this.makeTree(content[i], dots, false);
                                dots = dots.substr(0, dots.length - ("" + i).length - 2);
                                li++;
                                out += "<li id=\"li" + li + "\">" + makeUrl(dots + "[" + i + "]", i + " (index)", li, this.index, this.clickable) + " " + t;
                            }
                            out += "</ul>";
                        } else if (isTypeOf(content) == Object) {
                            out += "<ul>";
                            for (var j in content) {
                                dots += "['" + j + "']";
                                t = this.makeTree(content[j], dots, true);
                                dots = dots.substr(0, dots.length - j.length - 4);
                                li++;
                                out += "<li id=\"li" + li + "\">" + makeUrl(dots + "['" + j + "']", j, li, this.index, this.clickable) + " " + t;
                            }
                            out += "</ul>";
                        } else if (isTypeOf(content) == String) {
                            out += "</li>";
                        } else { out += "</li>"; }
                        return out;
                    },
                    reloadTree: function() {
                        li = 0;
                        if (this.clickable) {
                            if (this.rootLink === "") { this.rootLink = "BCJT.tree.forest[" + this.index + "].getNodeValue('json', this);return false"; }
                            this.el.innerHTML = "<ul id=\"tree" + this.index + "\" class=\"mktree\"><li><a id=\"a0\" onclick=\"" + this.rootLink + "\">" + this.rootNode + "</a><ul>" + this.makeTree(this.json, "json", false).substr(4) + "</ul></li></ul>";
                        } else { this.el.innerHTML = "<ul id=\"tree" + this.index + "\" class=\"mktree\"><li>" + this.rootNode + "<ul>" + this.makeTree(this.json, "json", false).substr(4) + "</ul></li></ul>"; }
                        if (this.mktree) { BCJT.mktree.processList(document.getElementById("tree" + this.index)); }
                    }
                };
            }
            function Tree(json, div, params) {
                if (!params) { params = {}; }
                var options = { "json": json, "nodeclick": function() { }, "mktree": true, "clickable": true, "index": treeIndex, "el": document.getElementById(div), "cp": null, "ca": null, "cli": null, rootNode: "json", rootLink: "", "newtree": true };
                for (var key in options) { this[key] = (params[key] !== undefined) ? params[key] : options[key]; }
                if (this.newtree) {
                    if (this.clickable) {
                        if (this.rootLink === "") { this.rootLink = "BCJT.tree.forest[" + this.index + "].getNodeValue('json', this);return false"; }
                        this.el.innerHTML = "<ul id=\"tree" + treeIndex + "\" class=\"mktree\"><li><a id=\"a0\" onclick=\"" + this.rootLink + "\">" + this.rootNode + "</a><ul>" + this.makeTree(json, "json", false).substr(4) + "</ul></li></ul>";
                    } else { this.el.innerHTML = "<ul id=\"tree" + treeIndex + "\" class=\"mktree\"><li>" + this.rootNode + "<ul>" + this.makeTree(json, "json", false).substr(4) + "</ul></li></ul>"; }
                    BCJT.tree.forest.push(this);
                    treeIndex++;
                } else {
                    if (this.clickable) {
                        if (this.rootLink === "") { this.rootLink = "BCJT.tree.forest[" + this.index + "].getNodeValue('json', this);return false"; }
                        this.el.innerHTML = "<ul id=\"tree" + this.index + "\" class=\"mktree\"><li><a id=\"a0\" onclick=\"" + this.rootLink + "\">" + this.rootNode + "</a><ul>" + this.makeTree(json, "json", false).substr(4) + "</ul></li></ul>";
                    } else { this.el.innerHTML = "<ul id=\"tree" + this.index + "\" class=\"mktree\"><li>" + this.rootNode + "<ul>" + this.makeTree(json, "json", false).substr(4) + "</ul></li></ul>"; }
                    li = 0;
                    BCJT.tree.forest[this.index] = this;
                }
                if (this.mktree) { BCJT.mktree.processList(document.getElementById("tree" + this.index)); }
                return this;
            }
            Tree.prototype = new TreeUtil();
            return {
                forest: [],
                _tree: Tree, /* expose the internal Tree object for prototype purposes */
                init: function(json, div, params) {
                try {
                        var j = (json.constructor === Object) ? json : eval('(' +json+ ')');
                        new Tree(j, div, params);
                        return true;
                    } catch (e) {
                        BCJT.tree.error = "Build tree failed!<br />" + e;
                        return false;
                    }
                },
                error: ""
            };
        } (),
        mktree: function() {
            /* All below code was obtained from: http://www.javascripttoolbox.com/lib/mktree/ 
            the autor is: Matt Kruse (http://www.mattkruse.com/)
            (The code below was slightly modified!)
            */
            var nodeClosedClass = "liClosed", nodeOpenClass = "liOpen", nodeBulletClass = "liBullet", nodeLinkClass = "bullet";

            /* the two below functions will prevent memory leaks in IE */
            function treeNodeOnclick() { this.parentNode.className = (this.parentNode.className == nodeOpenClass) ? nodeClosedClass : nodeOpenClass; return false; }
            function retFalse() { return false; }
            function processList(ul) {
                if (!ul.childNodes || ul.childNodes.length === 0) { return; }
                var childNodesLength = ul.childNodes.length;
				var folders = [];
				var items = []
                for (var itemi = 0; itemi < childNodesLength; itemi++) {
                    var item = ul.childNodes[itemi];
                    if (item.nodeName == "LI") {
                        var subLists = false;
                        var itemChildNodesLength = item.childNodes.length;
                        for (var sitemi = 0; sitemi < itemChildNodesLength; sitemi++) {
                            var sitem = item.childNodes[sitemi];
                            if (sitem.nodeName == "UL") { subLists = true; processList(sitem); }
                        }
                        var s = document.createElement("SPAN");
                        var t = '\u00A0';
                        s.className = nodeLinkClass;
                        if (subLists) {
                            if (item.className === null || item.className === "") { item.className = nodeClosedClass; }
                            if (item.firstChild.nodeName == "#text") { t = t + item.firstChild.nodeValue; item.removeChild(item.firstChild); }
                            s.onclick = treeNodeOnclick;
							folders.push(item);
                        } else { 
							item.className = nodeBulletClass;
							s.onclick = retFalse; 
							items.push(item);
						}
                        s.appendChild(document.createTextNode(t));
                        item.insertBefore(s, item.firstChild);
                    }
                }
				// sort
				var sortNodes = function(a, b)
				{
					var ta = jQuery(a).text();
					var tb = jQuery(b).text();
					if (ta == tb) return 0;
					return (ta < tb) ? -1 : 1;
				};
				folders.sort(sortNodes);
				items.sort(sortNodes);
				for (var i = 0; i < items.length; i++)
				{
					folders.push(items[i]);
				}
				items = null;
				for (var i = 0; i < folders.length; i++)
				{
					ul.appendChild(folders[i]);
				}
            }
            // Performs 3 functions:
            // a) Expand all nodes
            // b) Collapse all nodes
            // c) Expand all nodes to reach a certain ID
            function expandCollapseList(ul, nodeOpenClass, itemId) {
                if (!ul.childNodes || ul.childNodes.length === 0) { return false; }
                for (var itemi = 0; itemi < ul.childNodes.length; itemi++) {
                    var item = ul.childNodes[itemi];
                    if (itemId !== null && item.id == itemId) { return itemId; }
                    if (item.nodeName == "LI") {
                        var subLists = false;
                        for (var sitemi = 0; sitemi < item.childNodes.length; sitemi++) {
                            var sitem = item.childNodes[sitemi];
                            if (sitem.nodeName == "UL") {
                                subLists = true;
                                var ret = expandCollapseList(sitem, nodeOpenClass, itemId);
                                if (itemId !== null && ret) { item.className = nodeOpenClass; return itemId; }
                            }
                        }
                        if (subLists && itemId === null) { item.className = nodeOpenClass; }
                    }
                }
            }
            // Full expands a tree with a given ID
            function expandTree(treeId) {
                var ul = document.getElementById(treeId);
                if (ul === null) { return false; }
                expandCollapseList(ul, nodeOpenClass);
            }

            // Fully collapses a tree with a given ID
            function collapseTree(treeId) {
                var ul = document.getElementById(treeId);
                if (ul === null) { return false; }
                expandCollapseList(ul, nodeClosedClass);
            }

            // Expands enough nodes to expose an LI with a given ID
            function expandToItem(treeId, itemId) {
                var ul = document.getElementById(treeId);
                if (ul === null) { return false; }
                var ret = expandCollapseList(ul, nodeOpenClass, itemId);
                if (ret) {
                    var o = document.getElementById(itemId);
                    if (o.scrollIntoView) {
                        o.scrollIntoView(false);
                    }
                }
            }
            return {
                processList: processList,
                expandCollapseList: expandCollapseList,
                expandTree: expandTree,
                collapseTree: collapseTree,
                expandToItem: expandToItem
            };
        } ()
    };
} ();
if ( typeof $$ == "undefined" ) var $$ = BCJT.util.$$;
var addE = BCJT.util.addEvent;

var BCJTE = function(){
	if (!BCJT){
		throw new Error("BCJTE needs the BCJT object!");
	}
	var tp = BCJT.tree._tree;
	tp.prototype.deleteNode = function(){
		if (this.cp !== null){
			var del = this.cp.substring(this.cp.lastIndexOf("[")+2,this.cp.lastIndexOf("]")-1);
			var pp = this.cp.substring(0, this.cp.lastIndexOf("["));
			var parent = eval(BCJTEP.escapeslashes(pp));
			var no = {};
			for(var i in parent){if (i !== del){no[i] = parent[i];}}
			eval(pp +"="+ JSON.stringify(no));
			var pn = this.cli.parentNode.parentNode.id;
			this.cli.parentNode.removeChild(this.cli);
			this.reloadTree();
			
			//clear boxes
			if (this.mktree){
				this.ca = null;
				this.cp = null;
				this.cli = null;
				
				//clear boxes
				$$("jsonname").value = "";
				$$("jsonvalue").value = "";
				$$("jsonpath").innerHTML = "";
				$$("jsontypes").selectedIndex= 0;
				$$("jsonnameinput").style.display = "none";
				$$("addbutton").style.display = "none";
				$$("savebutton").style.display = "inline";
				$$("savedstatus").style.display = "none";
				$$("deletedstatus").style.display = "block";
			}
			
			/* expanding fails because the tree is being reindexed during reload... the old id probably doens't exist anymore */
			BCJT.mktree.expandToItem("tree"+this.index, pn);
			//alert(this.index +"\n"+ pn);
			
		}
	};
	tp.prototype.addNode = function(nn, nv, t){
		if (this.cp !== null){
			var obj = eval(BCJTEP.escapeslashes(this.cp));
			var objJSON = JSON.stringify(obj);
			var objType = this.strIsTypeOf(this.isTypeOf(obj));
			var cid = this.cli ? this.cli.id : null;
			var nObj = null;
			try {
        		$$("jsonmode").innerHTML = "Mode: " + ($$("autodetect").checked ? "Automatic" : "Standard");
        		$$("jsonname").readonly=null;

			//what type are we creating?
			if (t === undefined){ t = this.strIsTypeOf(this.isTypeOf(nv));}
			switch(t){
				case 'string': nObj = nv; break;
				case 'object': case 'boolean': case 'function': case 'number': nObj = JSON.parse(nv); break;
				case 'array': nObj = JSON.parse(""+Array(nv)); break;
				default: nObj = null; break;
			}
			//what is the current type?
			switch (objType) {
				case 'object':
				    obj[nn] = nObj;
				    break;
				case 'array': 
				    obj.push(nObj);
				    break;
				default: throw "Unable to add a child to type: " + objType;
			}
		} catch (e) {
			$$("log").innerHTML = e;
			$$("console").style.display = "block";
		}
		this.reloadTree();
			if (this.mktree){
				var liid = BCJT.mktree.expandCollapseList(document.getElementById("tree"+this.index), this.cli.id);
				this.ca = null;
				this.cp = null;
				this.cli = null;
				
				//clear boxes
				$$("jsonname").value = "";
				$$("jsonvalue").value = "";
				$$("jsontypes").selectedIndex= 0;
				$$("jsonpath").innerHTML = "";
				$$("jsonmode").innerHTML = "";
				$$("jsonnameinput").style.display = "none";
				$$("addbutton").style.display = "none";
				$$("savebutton").style.display = "inline";
				$$("savedstatus").style.display = "block";
				$$("deletedstatus").style.display = "none";
			}

			/* expanding fails because the tree is being reindexed during reload... the old id probably doens't exist anymore */
			BCJT.mktree.expandToItem("tree"+this.index, cid);
			
		}
	};
	tp.prototype.save = function(nv,t){
		if (this.cp !== null){
			var obj = eval(BCJTEP.escapeslashes(this.cp));
			var pp = this.cp.substring(0, this.cp.lastIndexOf("["));
			var parent = eval(BCJTEP.escapeslashes(pp));
			var pt = this.strIsTypeOf(this.isTypeOf(parent));
			var nn = "";
			if (pt == 'array') {
				nn = this.cp.substring(this.cp.lastIndexOf("[")+1,this.cp.lastIndexOf("]"));
				
			} else {
				nn = this.cp.substring(this.cp.lastIndexOf("[")+2,this.cp.lastIndexOf("]")-1);
			}
			var nObj = null;
			if (t === undefined){ t = this.strIsTypeOf(this.isTypeOf(nv));}
			try{
				switch(t){
					case 'string':
						nObj = nv; 
						break;
					case 'object': case 'boolean': case 'function': case 'number':
						nObj = JSON.parse(nv);
						break;
					case 'array':
						nObj = JSON.parse(nv);
						break;
					case 'null': 
						nObj = null;
						break;
					default: return t;
				}
				parent[nn] = nObj;

				if (t == "object" || t == "array"){
					if (window.confirm("New value's have been saved.\nDo you want to rebuild the tree?")){
						this.reloadTree();
						if (this.mktree){
							var liid = BCJT.mktree.expandCollapseList(document.getElementById("tree"+this.index), this.cli.id);
							this.ca = null;
							this.cp = null;
							this.cli = null;
						}
						//clear boxes
						$$("jsonname").value = "";
						$$("jsonvalue").value = "";
						$$("jsontypes").selectedIndex= 0;
						$$("jsonpath").innerHTML = "";
						$$("jsonnameinput").style.display = "none";
						$$("addbutton").style.display = "none";
						$$("savebutton").style.display = "inline";
					}
				}						
				$$("savedstatus").style.display = "block";
			}catch(e){
				$$("log").innerHTML = "There's an error in your value!<br />" + e;
				$$("console").style.display = "block";
			}
		}
	};
	
	function searchJson(tree, keyword){
		var results = [];
		var li = 0;
		function searchKeyword(input,word){if (input===null){return -1;}return input.toString().search(new RegExp(word,"gi"));}		
		function searchTree(content,index,dots,inside,keyword){
			if (tree.isTypeOf(content) == Array){
				for (var i=0; i<content.length; i++){
					dots+="["+i+"]";
					searchTree(content[i], i, dots, false,keyword);
					li++;
					dots=dots.substr(0, dots.length - (""+i).length-2);
				}
			}else if(tree.isTypeOf(content) == Object){
				for(var i in content){
					dots+="['"+i+"']";
					searchTree(content[i], -1, dots,true,keyword);
					li++;
					if (searchKeyword(i,keyword) > -1 && tree.isTypeOf(i)!==Object){makeList(dots, i, li, "label");}
					if (searchKeyword(content[i],keyword) > -1 && tree.isTypeOf(content[i])!==Object){makeList(dots, i, li, "value");}					
					dots=dots.substr(0, dots.length - i.length - 4);	
				}
			}				
		}
		function makeList(dots, where, id, val){results.push({"a":"a"+id,"li":"li"+id,"path":escape(dots),"value":where,"where":val});}		
		return function(){
			li =0;
			results.length = 0;
			searchTree(tree.json, -1, "json", false, keyword);
			return results;
		}();
	}
	tp.prototype.search = function(keyword){
		return searchJson(this, keyword);
	};
	return{
		addOptions: function(object, oValue, oText){object.options[object.length] = new Option(oText, oValue, false, false);},
		objectTypes: ['array','object','function','string','number','boolean','null','undeterimable type'],
		info: {"version": "1.2", "www": "http://braincast.nl", "date": "april 2008", "description": "Editor extension object for the Braincast Json Tree object."}
	};
}();


var BCJTEP = function(){
	if (!BCJT && !BCJTE){
		throw new Error("BCJTEP needs the BCJT object and the BCJTE object!");
	}
	function selectType(object, type){
		var l = object.options.length;
		for (var i=0;i<l;i++){
			if (object.options[i].text == type){
				object.selectedIndex= i;
				break;
			}
		}
	}
	function escapeslashes(str){
	    str = str.replace(/\\\\/g, '\\\\\\\\');
		return str;
	}
	function stripslashes(str){
	    str = str.replace(/\\'/g, '\'');
		str = str.replace(/\\"/g, '"');
		str = str.replace(/\\\\/g, '\\');
		//str = str.replace(/\\0/g, '\0');
		str = str.replace(/\\0/g, '0');
		return str;
	}
	function determineUserType(a){
		try{var y = eval(a);
		}catch(e){
			try{y = eval('('+a+')');
			}catch(f){return 'string';}
		}
		var x = typeof y;
		if (x == 'object'){
			try{
				x = y.constructor;
				if (x === Array){return 'array';}
				else if (x === Object){return 'object';}
			}catch(g){return 'null';}
		}else if (x == 'undefined'){return 'object';}
		else{return x;}
	}
	return{
		save: function(jsonPath){
      if (jsonPath) {
        var jsval = eval("BCJT.tree.forest[0]." + BCJTEP.escapeslashes(jsonPath));
			  return JSON.stringify(jsval);	
      } else {
			  return JSON.stringify(BCJT.tree.forest[0].json);	
      }
		},
		build: function(){
			var jsonstr = $$("jsonstr").value;
			if (jsonstr == "") return false;
			var r = BCJT.tree.init(jsonstr, "div1", {"rootNode": "json", "index": 0,"newtree":false, "nodeclick": function(p){
			        //make sure the add dialogs are not shown
				$$("jsonname").value = "";
				$$("jsonvalue").value = "";
				$$("jsonpath").innerHTML = "";
				$$("jsonmode").innerHTML = "";
				$$("jsontypes").selectedIndex= 0;
				$$("jsonnameinput").style.display = "none";
				$$("addbutton").style.display = "none";
				$$("savebutton").style.display = "inline";
				$$("savedstatus").style.display = "none";
				$$("deletedstatus").style.display = "none";
				
				if ("json" == unescape(p.jsonPath)){
					tabber1.show(3);
					$$("jsonstr").value = p.jsonValue;
				}else{
					if ($$("tab2").style.display != "block"){tabber1.show(2);}
					/*
					alert("type: " + p.jsonType + "\n" +
					  "value: " + p.jsonValue + "\n" +
					  "path: " + p.jsonPath + "\n" +
					  "li: " + p.li
					  );*/
					  var jsonmode = "Standard";
					  if (p.jsonType == 'object' || p.jsonType == 'array') {
					     $$("jsonvalue").value = p.jsonValue;
					     jsonmode = "<b>NATIVE JSON</b>";
					  } else {
					     $$("jsonvalue").value = BCJTEP.stripslashes(p.jsonValue);
					  }
					  $$("jsonpath").innerHTML = "Path: " + unescape(p.jsonPath);
            $$("jsonmode").innerHTML = "Mode: " + jsonmode;
					  selectType($$("jsontypes"),p.jsonType); 
				}
			}});
			if (r){return r;
			}else{
				$$("log").innerHTML = BCJT.tree.error;
				$$("console").style.display = "block";
				return false;
			}
		},	
		escapeslashes: escapeslashes,
		stripslashes: stripslashes,
		uType: determineUserType,
		selectType: selectType,
		writeResults: function(){
			var results = BCJT.tree.forest[0].search($$("keyword").value);
			var res = $$("results");
			res.innerHTML = "";
			var strtable = "<table width=\"100%\"><tbody>";
			for (var i=0; i< results.length; i++){
				strtable += "<tr><td width=\"15\"><img src=\"/images/jsonedit/" + results[i].where + ".gif\" title=\"Result found in the "+results[i].where+"\" border=\"0\" /></td>";
				strtable += "<td><a href=\"#\" onclick=\"BCJT.mktree.expandToItem('tree0', '"+results[i].li+"');BCJT.tree.forest[0].getNodeValue('"+results[i].path+"', '"+results[i].a+"');tabber1.show(2);return false\">" + results[i].value + "</td>";
				strtable += "<td class=\"path\">" + unescape(results[i].path) + "</td></tr>";
			}
			strtable += "</tbody></table>";
			res.innerHTML = strtable;
		},
		info: {"version": "1.3", "www": "http://braincast.nl", "date": "april 2008", "description": "Braincast Json Tree Presentation object."}
	};
}();

BCJTEP.prototype = function(){
	BCJT.util.addLoadEvent(function(){
		tabber1 = new Yetii({id: 'tab-container-1'});
		tabber2 = new Yetii({id: 'tab-container-2',tabclass: 'tabn'});
		addE($$("buildbutton"), "click", function(){
			if (BCJTEP.build()){
				$$("results").innerHTML = "&nbsp;";
				$$("sourcetab").className = "show";
				$$("editortab").className = "show";
				$$("searchtab").className = "show";
			}
		})
		
		var jsontypes = $$("jsontypes");
		var j = BCJTE.objectTypes.length;
		for (var i = 0; i<j; i++){BCJTE.addOptions(jsontypes, i ,BCJTE.objectTypes[i]);}
		
		addE($$("savebutton"), "click", function(){
				if ($$("autodetect").checked){
					BCJTEP.selectType( $$("jsontypes"), BCJTEP.uType($$("jsonvalue").value) );
				}
				var obj = BCJT.tree.forest[0];				
				var listtype = $$("jsontypes").options[$$("jsontypes").selectedIndex].text;
				obj.save($$("jsonvalue").value,listtype);
			});
		
		addE($$("addbutton"), "click", function(){
				if ($$("autodetect").checked){
					BCJTEP.selectType( $$("jsontypes"), BCJTEP.uType($$("jsonvalue").value) );
				}

				var obj = BCJT.tree.forest[0];
				var listtype = $$("jsontypes").options[$$("jsontypes").selectedIndex].text;

				obj.addNode($$("jsonname").value,$$("jsonvalue").value,listtype);
			});
		/*
		addE($("jsonvalue"), "keydown", function(e){
			if (e.keyCode == 83 && e.ctrlKey){
				e.preventDefault();
				alert("Save");
			}
		});*/
		
		addE($$("refresh"), "mousedown", function(){
			$$("refresh").className = "button buttondown";
			$$("refresh").style.backgroundPosition = "right bottom";
			if (BCJT.tree.forest[0]) BCJT.tree.forest[0].getNodeValue('json', 'a0');
		});
		addE($$("refresh"), "mouseup", function(){
			$$("refresh").className = "button";
			$$("refresh").style.backgroundPosition = "center center";
		});

		
		addE($$("add"), "mousedown", function(){
			$$("add").className = "button buttondown";
			$$("add").style.backgroundPosition = "right bottom";
			$$("savebutton").style.display = "none";
			$$("addbutton").style.display = "inline";
			$$("jsonnameinput").style.display = "inline";
			$$("jsonvalue").value = "";
			$$("jsontypes").selectedIndex = 0;
			
			var objTree = BCJT.tree.forest[0];	
			var obj = eval(BCJTEP.escapeslashes(objTree.cp));
			var objType = objTree.strIsTypeOf(objTree.isTypeOf(obj));

			var jsonmode = "Automatic";
			$$("autodetect").checked = true;
			$$("jsonmode").innerHTML = "Mode: " + jsonmode;

			if (objType == "array") {
			  $$("jsonname").value = "Array Index";
			  $$("jsonname").disabled = true;
			} else {
			  $$("jsonname").value = "";
			  $$("jsonname").disabled = false;
			}

		});
		addE($$("add"), "mouseup", function(){
			$$("add").className = "button";
			$$("add").style.backgroundPosition = "center center";
		});	
		
    addE($$("jsontypes"), "change", function(){
				var listtype = $$("jsontypes").options[$$("jsontypes").selectedIndex].text;
				var jsonmode = $$("autodetect").checked ? "Automatic" : "Standard";
        if (listtype == "object" || listtype == "array") {
				  jsonmode = "<b>NATIVE JSON</b>";
        }
        $$("jsonmode").innerHTML = "Mode: " + jsonmode;

			});
		
		addE($$("delete"), "mousedown", function(){
			$$("delete").className = "button buttondown";
			$$("delete").style.backgroundPosition = "right bottom";
			if (confirm("Are you sure you want to delete this attribute?")) BCJT.tree.forest[0].deleteNode();
		});
		addE($$("delete"), "mouseup", function(){
			$$("delete").className = "button";
			$$("delete").style.backgroundPosition = "center center";
		});
		
		addE($$("search"), "click", function(){
			BCJTEP.writeResults();
		});
		addE($$("keyword"), "keydown", function(e){
			if (e.keyCode == 13){
				BCJTEP.writeResults();
			}
		});
		addE($$("consolebar"), "click", function(){
			$$("console").style.display = "none";
			return false;
		});
	});
}();
