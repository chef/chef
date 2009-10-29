/*
jsonEditor 1.02
copyright 2007-2009 Thomas Frank

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/

JSONeditor={
	start:function(treeDivName,formDivName,json,showExamples){
		if(this.examples.length<6){
			var e=this.treeBuilder.JSONstring.make(this)
			eval("this.examples[5]={JSONeditor:"+e+"}")
		}
		this.treeDivName=treeDivName
		var t=this.treeBuilder, $=t.$
		treeBuilder=t
		var s=$(treeDivName).style
		var f=$(formDivName)
		var fs=f.style
		f.innerHTML=this.formHTML
		if(!showExamples){$('jExamples').style.display="none"}
		fs.fontSize=s.fontSize="11px"
		fs.fontFamily=s.fontFamily="Verdana,Arial,Helvetica,sans-serif"
		var e=f.getElementsByTagName("*")
		for(var i=0;i<e.length;i++){
			var s=e[i].style
			if(s){
				s.fontSize="11px"
				s.fontFamily="Verdana,Arial,Helvetica,sans-serif"
			}
		}
		json=json||{}
		t.JSONbuild(treeDivName,json)
	},
	loadExample:function(x){
		treeBuilder.hasRunJSONbuildOnce=false
		treeBuilder.JSONbuild(this.treeDivName,this.examples[x/1])
	},
	formHTML:"<form name=\"jsoninput\" onsubmit=\"return treeBuilder.jsonChange(this)\"><div id=\"jExamples\">Load an example:&nbsp;<select name=\"jloadExamples\" onchange=\"JSONeditor.loadExample(this.value)\"><option value=\"0\">None/empty</option><option value=\"1\">Employee data</option><option value=\"2\">Sample Konfabulator Widget</option><option value=\"3\">Member data</option><option value=\"4\">A menu system</option><option value=\"5\">The source code of this JSON editor</option></select><br><br></div>\nLabel:<br><input name=\"jlabel\" type=\"text\" value=\"\" size=\"60\" style=\"width:400px\"><br><br>\nValue: <br><textarea name=\"jvalue\" rows=\"10\" cols=\"50\" style=\"width:400px\"></textarea><br><br>\nData type: <select onchange=\"treeBuilder.changeJsonDataType(this.value,this.parentNode)\" name=\"jtype\">\n<option value=\"object\">object</option>\n<option value=\"array\">array</option>\n<option value=\"function\">function</option>\n<option value=\"string\">string</option>\n<option value=\"number\">number</option>\n<option value=\"boolean\">boolean</option>\n<option value=\"null\">null</option>\n<option value=\"undefined\">undefined</option>\n</select>&nbsp;&nbsp;&nbsp;&nbsp;\n<input name=\"orgjlabel\" type=\"hidden\" value=\"\" size=\"50\" style=\"width:300px\">\n<input onfocus=\"this.blur()\" type=\"submit\" value=\"Save\">&nbsp;\n<br><br>\n<input name=\"jAddChild\" onfocus=\"this.blur()\" type=\"button\" onclick=\"treeBuilder.jsonAddChild(this.parentNode)\" value=\"Add child\">\n<input name=\"jAddSibling\" onfocus=\"this.blur()\" type=\"button\" onclick=\"treeBuilder.jsonAddSibling(this.parentNode)\" value=\"Add sibling\">\n<br><br>\n<input name=\"jRemove\" onfocus=\"this.blur()\" type=\"button\" onclick=\"treeBuilder.jsonRemove(this.parentNode)\" value=\"Delete\">&nbsp;\n<input name=\"jRename\" onfocus=\"this.blur()\" type=\"button\" onclick=\"treeBuilder.jsonRename(this.parentNode)\" value=\"Rename\">&nbsp;\n<input name=\"jCut\" onfocus=\"this.blur()\" type=\"button\" onclick=\"treeBuilder.jsonCut(this.parentNode)\" value=\"Cut\">&nbsp;\n<input name=\"jCopy\" onfocus=\"this.blur()\" type=\"button\" onclick=\"treeBuilder.jsonCopy(this.parentNode)\" value=\"Copy\">&nbsp;\n<input name=\"jPaste\" onfocus=\"this.blur()\" type=\"button\" onclick=\"treeBuilder.jsonPaste(this.parentNode)\" value=\"Paste\">&nbsp;\n<br><br>\n<input type=\"checkbox\" name=\"jbefore\">Add children first/siblings before\n<br>\n<input type=\"checkbox\" name=\"jPasteAsChild\">Paste as child on objects & arrays\n<br><br><div id=\"jformMessage\"></div>\n</form>",
	examples:[{},
{employee:{gid:102, companyID:121, defaultActionID:444,names:{firstName:"Stive", middleInitial:"Jr",lastName:"Martin"},address:{city:"Albany",state:"NY",zipCode:"14410-585",addreess:"41 State Street"},job:{departmentID:102,jobTitleID:100,hireDate:"1/02/2000",terminationDate:"1/12/2007"},contact:{phoneHome:"12-123-2133", beeper:"5656",email1:"info@soft-amis.com",fax:"21-321-23223",phoneMobile:"32-434-3433",phoneOffice:"82-900-8993"},login:{employeeID:"eID102",password:"password",superUser:true,lastLoginDate:"1/12/2007",text:"text", regexp:/^mmm/, date: new Date() },comment:{PCDATA:"comment"},roles:[{role:102},{role:103}]}},
{"widget": {"debug": true,"window": {"title": "Sample Konfabulator Widget","name": "main_window","width": 500,"height": 500},"Pairs": [ {"src": "Images/Sun.png","name": "sun1"},{"hOffset": 250,"vOffset": 200},null,{"alignment": "center"}],"text": {"a very long item label here": "Click Here","size": 36,"style": "null","name": "text1","hOffset": 250,"vOffset": 100,"alignment": "center","onmouseover": function(){alert("Hello World");},"onMouseUp": "sun1.opacity = (sun1.opacity / 100) * 90;"}}},
{"members": [{"href": "1","entity": {"category": [{"term": "weblog", "label": "Weblog stuff"}],"updated": "2007-05-02T23:32:03Z","title": "This is the second post","author": {"uri": "http://dealmeida.net/","email": "roberto@dealmeida.net","name": "Rob de Almeida"},"summary": "Testing search","content": {"content": "This is my second post, to test the search.","type": "text"},"id": "1"}},{"href": "0","entity": {"category": [{"term": "weblog", "label": "Weblog stuff"},{"term": "json", "label": "JSON"}],"updated": "2007-05-02T23:25:59Z","title": "This is the second version of the first post","author": {"uri": "http://dealmeida.net/","email": "roberto@dealmeida.net","name": "Rob de Almeida"},"summary": "This is my first post here, after some modifications","content": {"content": "This is my first post, testing the jsonstore WSGI microapp PUT.","type": "html"},"id": "0"}}],"next": null},
{"menu": {"header": "SVG Viewer","items": [{"id": "Open"},{"id": "OpenNew", "label": "Open New", "thing": "thing"},{"id": "ZoomIn", "label": "Zoom In"},{"id": "ZoomOut", "label": "Zoom Out"},{"id": "OriginalView", "label": "Original View"},null,{"id": "Quality"},{"id": "Pause"},{"id": "Mute"},null,{"id": "Find", "label": "Find..."},{"id": "FindAgain", "label": "Find Again"},{"id": "Copy"},{"id": "CopyAgain", "label": "Copy Again"},{"id": "CopySVG", "label": "Copy SVG"},{"id": "ViewSVG", "label": "View SVG"}]}}
	]
}


/*
treeBuilder v 1.00 + a lot of json stuff added...
copyright 2007 Thomas Frank
*/
JSONeditor.treeBuilder={
	stateMem:{},
	images:{
		folderNode:'',
		folderNodeOpen:'',
		folderNodeLast:'',
		folderNodeOpenLast:'',
		docNode:'',
		docNodeLast:'',
		folder:'',
		folderOpen:'',
		doc:'',
		vertLine:'',
		folderNodeFirst:'',
		folderNodeOpenFirst:'',
		folderNodeLastFirst:'',
		folderNodeOpenLastFirst:'',
		path:'../../images/treeBuilderImages/',
		nodeWidth:16
	},
	$:function(x){return document.getElementById(x)},
	preParse:function(x){
		var x=x.innerHTML.split("\n");
		var d=[];
		for(var i=0;i<x.length;i++){
			if(x[i]){
				var y=x[i].split("\t");
				var l=0;while(!y[l]){l++};
				var la=y[l]?y[l]:'';l++;
				var t=y[l]?y[l]:'';
				d.push({level:l,label:la,todo:t});
			}
		};
		return d
	},
	isArray:function(x){
		return x.constructor==Array
	},
	jSyncTree:function(x){
		var d=this.$(this.baseDiv).getElementsByTagName('div')
		for(var i=0;i<d.length;i++){
			
			treeBuilder.maniClick="giveItBack"
			var p=d[i].onclick()
			if(p==x){
				var t=d[i]
				treeBuilder.maniClick="selectIt"
				t.onclick()
				t=t.parentNode
				while(t.id!=this.baseDiv){if(t.style){this.openAndClose(t.id,"open")};t=t.parentNode}
			}
		}
		treeBuilder.maniClick=false
	},
	jsonResponder:function(x){
		this.jTypeChanged=false
		treeBuilder.jSyncTree(x)
		var t=treeBuilder
		eval("var a=treeBuilder."+x)
		eval("var ap=treeBuilder."+treeBuilder.jsonParent(x))
		var b=JSON.stringify(a, null, '  ');
		var t=(a && treeBuilder.isArray(a))?"array":typeof a
		var tp=(ap && treeBuilder.isArray(ap))?"array":typeof ap
		if(a===null){t="null"}
		var f=document.forms.jsoninput
		if(t=="string"){eval("b="+b)}
		f.jlabel.value=x
		f.orgjlabel.value=x
		f.jvalue.value=b
		f.jtype.value=t
		f.jlabel.disabled=f.jlabel.value=="json"
		f.jtype.disabled=f.jlabel.disabled
		f.jRemove.disabled=f.jlabel.disabled
		f.jAddSibling.disabled=f.jlabel.disabled
		f.jRename.disabled=f.jlabel.disabled || tp=="array"
		f.jAddChild.disabled=t!="array" && t!="object"
		f.jPaste.disabled=!treeBuilder.jClipboard
		f.jCut.disabled=f.jlabel.disabled
	},
	jsonParent:function(x){          
		// inmproved thanks to \x000
		if(x=="json"){return "treeBuilder"} 
		if (x.charAt(x.length-1)==']') {return x.substring(0,x.lastIndexOf('['))}                  
		return x.substring(0,x.lastIndexOf('.'))     
	},	
	jsonChild:function(el1){
		var p=this.jsonParent(el1)
		el1=el1.split(p).join("")
		if(el1.charAt(0)=="."){el1=el1.substring(1)}
		if(el1.charAt(0)=="["){el1=el1.substring(2,el1.length-2)}
		return el1
	},
	jsonRemove:function(f){
		this.jsonChange(f,true)
	},
	jsonAlreadyExists:function(o,l){
		if(o[l]!==undefined){
			var co=2
			while(o[l+"_"+co]!==undefined){co++}
			var n=l+"_"+co
			var p='"'+l+'" already exists in this object.\nDo you want to rename? (otherwise the old "'+l+'" will be overwritten.)'
			p=prompt(p,n)
			if(p){l=p}
		}
		return l
	},
	jsonAddChild:function(f,label){
		var first=f.jbefore.checked
		var l=f.orgjlabel.value
		eval('var o=this.'+l)
		var t=(o && this.isArray(o))?"array":typeof o
		if(t=="object"){
			var nl=label||prompt("Label (without path):","")
			if(!nl){return}
			if(nl/1==nl){nl="$"+nl}
			nl=this.jsonAlreadyExists(o,nl)
			var n=nl.replace(/\w/g,'')===""?l+"."+nl:l+'["'+nl+'"]'
			eval('this.'+n+'={}')
			if(first){
				eval("var t=this."+l+";this."+l+"={};var s=this."+l)
				eval('this.'+n+'={}')
				for(var i in t){s[i]=t[i]}				
			}
		}
		if(t=="array"){
			o.push({})
			n=l+"["+(o.length-1)+"]"
			if(first){
				for(var i=o.length-1;i>0;i--){o[i]=o[i-1]}
				o[0]={}
				n=l+"[0]"
			}
		}
		this.JSONbuild(this.baseDiv,this.json)
		for(var i in this.stateMem){this.openAndClose(i,true)}
		this.jsonResponder(n)
	},
	jsonAddSibling:function(f,label){
		var before=f.jbefore.checked
		var l=f.orgjlabel.value
		var r=Math.random()
		eval('var temp=this.'+l)
		eval('this.'+l+"=r")
		var s=this.JSONstring.make(this.json)
		s=s.split(r+",")
		if(s.length<2){s=s[0].split(r)}
		var lp=this.jsonParent(l)
		eval('var o=this.'+lp)
		var t=(o && this.isArray(o))?"array":typeof o
		if(t=="object"){
			var nl=label||prompt("Label (without path):","")
			if(!nl){return}
			if(nl/1==nl){nl="$"+nl}
			nl=this.jsonAlreadyExists(o,nl)
			var n=nl.replace(/\w/g,'')===""?"."+nl:'["'+nl+'"]'
			s=s.join('null,"'+nl+'":{},')
			lp+=n
		}
		if(t=="array"){
			s=s.join('null,{},')
			var k=l.split("[")
			k[k.length-1]=(k[k.length-1].split("]").join("")/1+1)+"]"
			lp=k.join("[")
		}
		s=s.split("},}").join("}}") // replace with something better soon
		eval('this.json='+s)
		eval('this.'+l+'=temp')
		if(before){lp=this.jsonSwitchPlace(this.jsonParent(l),l,lp)}
		this.JSONbuild(this.baseDiv,this.json)
		for(var i in this.stateMem){this.openAndClose(i,true)}
		this.jsonResponder(lp)
	},
	jSaveFirst:function(f,a){
		var l=f.orgjlabel.value
		eval("var orgj=this."+l)
		orgj=this.JSONstring.make(orgj)
		var v=f.jvalue.value
		v=f.jtype.value=="string"?this.JSONstring.make(v):v
		v=v.split("\r").join("")
		if(orgj!=v || f.orgjlabel.value!=f.jlabel.value || this.jTypeChanged){
			var k=confirm("Save before "+a+"?")
			if(k){this.jsonChange(f)}
		}
	},
	jsonRename:function(f){
		this.jSaveFirst(f,"renaming")
		var orgl=l=f.orgjlabel.value
		l=this.jsonChild(l)
		var nl=prompt("Label (without path):",l)
		if(!nl){return}
		this.jsonResponder(orgl)
		var nl=nl.replace(/\w/g,'')===""?"."+nl:'["'+nl+'"]'
		f.jlabel.value=this.jsonParent(orgl)+nl
		this.jsonChange(f,false,true)
	},
	jsonSwitchPlace:function(p,el1,el2){
		var orgel1=el1, orgel2=el2
		eval("var o=this."+p)
		if(this.isArray(o)){
			eval("var t=this."+el1)
			eval("this."+el1+"=this."+el2)
			eval("this."+el2+"=t")
			return orgel1
		}
		el1=this.jsonChild(el1)
		el2=this.jsonChild(el2)
		var o2={}
		for(var i in o){
			if(i==el1){o2[el2]=o[el2];o2[el1]=o[el1];continue}
			if(i==el2){continue}
			o2[i]=o[i]
		}
		eval("this."+p+"=o2")
		return orgel2
	},
	jsonCut:function(f){
		this.jSaveFirst(f,"cutting")
		this.jsonCopy(f,true)
		this.jsonChange(f,true)
		this.setJsonMessage('Cut to clipboard!')
	},
	jsonCopy:function(f,r){
		if(!r){this.jSaveFirst(f,"copying")}
		var l=f.orgjlabel.value
		eval("var v=this."+l)
		v=this.JSONstring.make(v)
		var l=this.jsonChild(l)
		this.jClipboard={label:l,jvalue:v}
		this.jsonResponder(f.jlabel.value)
		if(!r){this.setJsonMessage('Copied to clipboard!')}
	},
	jsonPaste:function(f,r){
		var t=f.jtype.value
		var sibling=t!="object" && t!="array"
		if(!f.jPasteAsChild.checked){sibling=true}
		if(f.orgjlabel.value=="json"){sibling=false}
		if(sibling){this.jsonAddSibling(f,this.jClipboard.label)}
		else {this.jsonAddChild(f,this.jClipboard.label)}
		var l=f.orgjlabel.value
		eval("this."+l+"="+this.jClipboard.jvalue)
		this.jsonResponder(l)
		this.jsonChange(f)
		if(!r){this.setJsonMessage('Pasted!')}
	},
	setJsonMessage:function(x){
		this.$('jformMessage').innerHTML=x
		setTimeout("treeBuilder.$('jformMessage').innerHTML=''",1500)
	},
	changeJsonDataType:function(x,f){
		this.jTypeChanged=true
		var v=f.jvalue.value
		var orgv=v;
		v=x=='object'?'{"label":"'+v+'"}':v
		v=x=='array'?'["'+v+'"]':v
		if(!orgv){
			v=x=='object'?'{}':v
			v=x=='array'?'[]':v
		}
		v=x=='function'?'function(){'+v+'}':v
		v=x=='string'?v:v
		v=x=='number'?v/1:v
		v=x=='boolean'?!!v:v
		v=x=='null'?'null':v
		v=x=='undefined'?'undefined':v
		f.jvalue.value=v		
	},
	jsonChange:function(f,remove,rename){
		try {
			var l=f.jlabel.value
			var orgl=f.orgjlabel.value||"json.not1r2e3a4l"
			eval("var cur=this."+l)
			if(l!=orgl && cur!==undefined){
				var c=confirm(l+"\n\nalready contains other data. Overwrite?")
				if(!c){return false}
			}
			var v=f.jvalue.value.split("\r").join("")
			if(f.jtype.value=="string"){
				v=this.JSONstring.make(v)
			}
			if(l=="json"){
				eval("v="+v)
				this.JSONbuild(this.baseDiv,v)
				for(var i in this.stateMem){this.openAndClose(i,true)}
				this.setJsonMessage('Saved!')
				return false
			}
			eval("var json="+this.JSONstring.make(this.json))
			var randi=Math.random()
			eval(orgl+'='+randi)
			var paname=this.jsonParent(orgl)
			var samepa=this.jsonParent(orgl)==this.jsonParent(l)
			eval("var pa="+paname)
			if(this.isArray(pa)){	
				eval(paname+'=[];var newpa='+paname)
				for(var i=0;i<pa.length;i++){
					if(pa[i]!=randi){newpa[i]=pa[i]}
				}
				if(remove){
					var pos=l.substring(l.lastIndexOf("[")+1,l.lastIndexOf("]"))/1
					newpa=newpa.splice(pos,1)
				}
				if(!remove){eval(l+"="+v)}
			}		
			else {
				eval(paname+'={};var newpa='+paname)
				for(var i in pa){
					if(pa[i]!=randi){newpa[i]=pa[i]}
					else if(samepa && !remove){eval(l+"="+v)}
				}
				if(!samepa && !remove){eval(l+"="+v)}
			}
			this.json=json
			var selId=this.selectedElement?this.selectedElement.id:null
			this.JSONbuild(this.baseDiv,this.json)
			for(var i in this.stateMem){this.openAndClose(i,true)}
			this.selectedElement=this.$(selId)
			if(this.selectedElement && !remove && orgl!="json.not1r2e3a4l"){
				this.selectedElement.style.fontWeight="bold"
			}
			if(remove){l=""}
			this.setJsonMessage(remove?'Deleted!':rename?'Renamed!':'Saved!')
			if(!remove){this.jsonResponder(l)}
  		}
		catch(err){
			alert(err+"\n\n"+"Save error!")
		}
		return false
	},
	JSONbuild:function(divName,x,y,z){
		if(!z){
			this.partMem=[]
			this.JSONmem=[]
			this.json=x
			this.baseDiv=divName
		}
		var t=(x && this.isArray(x))?"array":typeof x
		y=y===undefined?"json":y
		z=z||0
		this.partMem[z]='["'+y+'"]'
		if(typeof y!="number" && y.replace(/\w/g,'')===""){this.partMem[z]="."+y}
		if(typeof y=="number"){this.partMem[z]="["+y+"]"}
		if(z===0){this.partMem[z]="json"}
		this.partMem=this.partMem.slice(0,z+1)
		var x2=x
		this.JSONmem.push({type:t,label:y,todo:this.partMem.join(""),level:z+1})
		if(t=="object"){
			var l = new Array();
			for(var i in x)
				l.push(i);
			l.sort();
			for(var i=0;i<l.length;i++){
				this.JSONbuild(false,x[l[i]],l[i],z+1)
			}
		}
		if(t=="array"){
			for(var i=0;i<x.length;i++){
				this.JSONbuild(false,x[i],i,z+1)
			}
		}
		if(divName){
			this.build(divName,this.jsonResponder,this.JSONmem)
			if(!this.hasRunJSONbuildOnce){this.jsonResponder('json')}
			this.hasRunJSONbuildOnce=true
		}
	},
	build:function(divName,todoFunc,data){
		//
		// divName is the id of the div we'll build the tree inside
		//
		// todoFunc - a function to call on label click with todo as parameter
		//
		// data should be an array of objects
		// each object should contain label,todo + level or id and pid (parentId)
		//
		var d=data, n=divName, $=this.$, lastlevel=0, levelmem=[], im=this.images;
		this.treeBaseDiv=divName
		if(!d){
			var c=$(divName).childNodes;
			for(var i=0;i<c.length;i++){
				if((c[i].tagName+"").toLowerCase()=='pre'){d=this.preParse(c[i])}
			};
			if(!d){return}
		};
		$(n).style.display="none";
		while ($(n).firstChild){$(n).removeChild($(n).firstChild)};
		for(var i=0;i<d.length;i++){
			if(d[i].level && !lastlevel){lastlevel=d[i].level};
			if(d[i].level && d[i].level>lastlevel){levelmem.push(n);n=d[i-1].id};
			if(d[i].level && d[i].level>lastlevel+1){return 'Trying to jump levels!'};
			if(d[i].level && d[i].level<lastlevel){
				for(var j=d[i].level;j<lastlevel;j++){n=levelmem.pop()}
			};
			if(!d[i].id){d[i].id=n+"_"+i};
			if(!d[i].pid){d[i].pid=n};
			lastlevel=d[i].level;
			var a=document.createElement('div');
			var t=document.createElement('span');
			t.style.verticalAlign='middle';
			a.style.whiteSpace='nowrap';
			var t2=document.createTextNode(d[i].label);
			t.appendChild(t2);
			a.style.paddingLeft=d[i].pid==divName?'0px':im.nodeWidth+'px';
			a.style.cursor='pointer';
			a.style.display=(d[i].pid==divName)?'':'none';
			a.id=d[i].id;
			a.t=t;
			var f=function(){
				var todo=d[i].todo;
				var func=todoFunc;
				a.onclick=function(e){
					if(treeBuilder.maniClick=="giveItBack"){return todo}
					if(treeBuilder.selectedElement){
						treeBuilder.selectedElement.style.fontWeight=""
					}
					this.style.fontWeight="bold"
					treeBuilder.selectedElement=this
					if(treeBuilder.maniClick=="selectIt"){return}
					func(todo);
					if (!e){e=window.event};
					e.cancelBubble = true;
					if(e.stopPropagation){e.stopPropagation()};
				};
				a.onmouseover=function(e){
					//this.style.color="#999"
					if (!e){e=window.event};
					e.cancelBubble = true;
					if(e.stopPropagation){e.stopPropagation()};
				};
				a.onmouseout=function(e){
					//this.style.color=""
					if (!e){e=window.event};
					e.cancelBubble = true;
					if(e.stopPropagation){e.stopPropagation()};
				};
			};
			f();
			$(d[i].pid).appendChild(a);
			if(d[i].pid==divName && !a.previousSibling){a.first=true};
		};
		// calculate necessary element looks before initial display
		for(var i=0;i<d.length;i++){var x=$(d[i].id);if(x && x.style.display!="none"){this.setElementLook(x)}};
		$(divName).style.display="";
	},
	setElementLook:function(m){
		var $=this.$, im=this.images
		if(!m.inited){
			var co=0
			for(var j in im){
				if(!Object.prototype[j]){
					if(j=="vertLine"){break};
					var img=document.createElement('img');
					var k=(m.first && j.indexOf('Node')>=0)?j+'First':j;
					img.src=im.path+(im[k]?im[k]:k+'.gif');
					img.style.display="none";
					img.style.verticalAlign="middle";
					img.id=m.id+"_"+j;
					if(j.indexOf('folderNode')==0){
						img.onclick=function(e){
							treeBuilder.openAndClose(this);
							if (!e){e=window.event};
							e.cancelBubble = true;
							if(e.stopPropagation){e.stopPropagation()};
						}
					};
					if(m.firstChild){m.insertBefore(img,m.childNodes[co]); co++}
					else {m.appendChild(img)};
				}
			};
			m.insertBefore(m.t,m.childNodes[co]);
			m.inited=true
		};
		var lastChild=m.childNodes[m.childNodes.length-1];
		var isParent=(lastChild.tagName+"").toLowerCase()=="div";
		var isLast=!m.nextSibling;
		var isOpen=isParent && lastChild.style.display!='none';
		$(m.id+"_folder").style.display=!isOpen && isParent?'':'none';
		$(m.id+"_folderOpen").style.display=isOpen && isParent?'':'none';
		$(m.id+"_doc").style.display=isParent?'none':'';
		$(m.id+"_docNode").style.display=isParent || isLast?'none':'';
		$(m.id+"_docNodeLast").style.display=isParent || !isLast?'none':'';
		$(m.id+"_folderNode").style.display=isOpen || !isParent || isLast?'none':'';
		$(m.id+"_folderNodeLast").style.display=isOpen || !isParent || !isLast?'none':'';
		$(m.id+"_folderNodeOpen").style.display=!isOpen || !isParent || isLast?'none':'';
		$(m.id+"_folderNodeOpenLast").style.display=!isOpen || !isParent || !isLast?'none':'';
		var p=m.parentNode.nextSibling;
		if(p && p.id){
			var sp=p;insideBase=false;
			while(sp){if(sp==$(this.treeBaseDiv)){insideBase=true};sp=sp.parentNode}
			if(!insideBase){return}
			var bg=im.path+(im.vertLine?im.vertLine:'vertLine.gif');
			m.style.backgroundImage='url('+bg+')';
			m.style.backgroundRepeat='repeat-y'
		};
	},
	openAndClose:function(x,remem){
		var o, div=remem?this.$(x):x.parentNode;
		if(!div){return}
		if(remem){o=this.stateMem[div.id]}
		else {o=x.id.indexOf('Open')<0}
		if(remem=="open"){o=true}
		this.stateMem[div.id]=o
		var c=div.childNodes;
		for(var i=0;i<c.length;i++){
			if(c[i].tagName.toLowerCase()!="div"){continue};
			c[i].style.display=o?'':'none';
			if(o && !c[i].inited){this.setElementLook(c[i])}
		};
		this.setElementLook(div)
	}
}



/*
JSONstring v 1.0
copyright 2006 Thomas Frank

Based on Steve Yen's implementation:
http://trimpath.com/project/wiki/JsonLibrary
*/

JSONeditor.treeBuilder.JSONstring={
	compactOutput:false, 		
	includeProtos:false, 	
	includeFunctions: true,
	detectCirculars:false,
	restoreCirculars:false,
	make:function(arg,restore) {
		this.restore=restore;
		this.mem=[];this.pathMem=[];
		return this.toJsonStringArray(arg).join('');
	},
	toObject:function(x){
		eval("this.myObj="+x);
		if(!this.restoreCirculars || !alert){return this.myObj};
		this.restoreCode=[];
		this.make(this.myObj,true);
		var r=this.restoreCode.join(";")+";";
		eval('r=r.replace(/\\W([0-9]{1,})(\\W)/g,"[$1]$2").replace(/\\.\\;/g,";")');
		eval(r);
		return this.myObj
	},
	toJsonStringArray:function(arg, out) {
		if(!out){this.path=[]};
		out = out || [];
		var u; // undefined
		switch (typeof arg) {
		case 'object':
			this.lastObj=arg;
			if(this.detectCirculars){
				var m=this.mem; var n=this.pathMem;
				for(var i=0;i<m.length;i++){
					if(arg===m[i]){
						out.push('"JSONcircRef:'+n[i]+'"');return out
					}
				};
				m.push(arg); n.push(this.path.join("."));
			};
			if (arg) {
				if (arg.constructor == Array) {
					out.push('[');
					for (var i = 0; i < arg.length; ++i) {
						this.path.push(i);
						if (i > 0)
							out.push(',\n');
						this.toJsonStringArray(arg[i], out);
						this.path.pop();
					}
					out.push(']');
					return out;
				} else if (typeof arg.toString != 'undefined') {
					out.push('{');
					var first = true;
					for (var i in arg) {
						if(!this.includeProtos && arg[i]===arg.constructor.prototype[i]){continue};
						this.path.push(i);
						var curr = out.length; 
						if (!first)
							out.push(this.compactOutput?',':',\n');
						this.toJsonStringArray(i, out);
						out.push(':');                    
						this.toJsonStringArray(arg[i], out);
						if (out[out.length - 1] == u)
							out.splice(curr, out.length - curr);
						else
							first = false;
						this.path.pop();
					}
					out.push('}');
					return out;
				}
				return out;
			}
			out.push('null');
			return out;
		case 'unknown':
		case 'undefined':
		case 'function':
			try {eval('var a='+arg)}
			catch(e){arg='function(){alert("Could not convert the real function to JSON, due to a browser bug only found in Safari. Let us hope it will get fixed in future versions of Safari!")}'}
			out.push(this.includeFunctions?arg:u);
			return out;
		case 'string':
			if(this.restore && arg.indexOf("JSONcircRef:")==0){
				this.restoreCode.push('this.myObj.'+this.path.join(".")+"="+arg.split("JSONcircRef:").join("this.myObj."));
			};
			out.push('"');
			var a=['\n','\\n','\r','\\r','"','\\"'];
			arg+=""; for(var i=0;i<6;i+=2){arg=arg.split(a[i]).join(a[i+1])};
			out.push(arg);
			out.push('"');
			return out;
		default:
			out.push(String(arg));
			return out;
		}
	}
}
/*
    http://www.JSON.org/json2.js
    2009-06-29

    Public Domain.

    NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.

    See http://www.JSON.org/js.html

    This file creates a global JSON object containing two methods: stringify
    and parse.

        JSON.stringify(value, replacer, space)
            value       any JavaScript value, usually an object or array.

            replacer    an optional parameter that determines how object
                        values are stringified for objects. It can be a
                        function or an array of strings.

            space       an optional parameter that specifies the indentation
                        of nested structures. If it is omitted, the text will
                        be packed without extra whitespace. If it is a number,
                        it will specify the number of spaces to indent at each
                        level. If it is a string (such as '\t' or '&nbsp;'),
                        it contains the characters used to indent at each level.

            This method produces a JSON text from a JavaScript value.

            When an object value is found, if the object contains a toJSON
            method, its toJSON method will be called and the result will be
            stringified. A toJSON method does not serialize: it returns the
            value represented by the name/value pair that should be serialized,
            or undefined if nothing should be serialized. The toJSON method
            will be passed the key associated with the value, and this will be
            bound to the object holding the key.

            For example, this would serialize Dates as ISO strings.

                Date.prototype.toJSON = function (key) {
                    function f(n) {
                        // Format integers to have at least two digits.
                        return n < 10 ? '0' + n : n;
                    }

                    return this.getUTCFullYear()   + '-' +
                         f(this.getUTCMonth() + 1) + '-' +
                         f(this.getUTCDate())      + 'T' +
                         f(this.getUTCHours())     + ':' +
                         f(this.getUTCMinutes())   + ':' +
                         f(this.getUTCSeconds())   + 'Z';
                };

            You can provide an optional replacer method. It will be passed the
            key and value of each member, with this bound to the containing
            object. The value that is returned from your method will be
            serialized. If your method returns undefined, then the member will
            be excluded from the serialization.

            If the replacer parameter is an array of strings, then it will be
            used to select the members to be serialized. It filters the results
            such that only members with keys listed in the replacer array are
            stringified.

            Values that do not have JSON representations, such as undefined or
            functions, will not be serialized. Such values in objects will be
            dropped; in arrays they will be replaced with null. You can use
            a replacer function to replace those with JSON values.
            JSON.stringify(undefined) returns undefined.

            The optional space parameter produces a stringification of the
            value that is filled with line breaks and indentation to make it
            easier to read.

            If the space parameter is a non-empty string, then that string will
            be used for indentation. If the space parameter is a number, then
            the indentation will be that many spaces.

            Example:

            text = JSON.stringify(['e', {pluribus: 'unum'}]);
            // text is '["e",{"pluribus":"unum"}]'


            text = JSON.stringify(['e', {pluribus: 'unum'}], null, '\t');
            // text is '[\n\t"e",\n\t{\n\t\t"pluribus": "unum"\n\t}\n]'

            text = JSON.stringify([new Date()], function (key, value) {
                return this[key] instanceof Date ?
                    'Date(' + this[key] + ')' : value;
            });
            // text is '["Date(---current time---)"]'


        JSON.parse(text, reviver)
            This method parses a JSON text to produce an object or array.
            It can throw a SyntaxError exception.

            The optional reviver parameter is a function that can filter and
            transform the results. It receives each of the keys and values,
            and its return value is used instead of the original value.
            If it returns what it received, then the structure is not modified.
            If it returns undefined then the member is deleted.

            Example:

            // Parse the text. Values that look like ISO date strings will
            // be converted to Date objects.

            myData = JSON.parse(text, function (key, value) {
                var a;
                if (typeof value === 'string') {
                    a =
/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)Z$/.exec(value);
                    if (a) {
                        return new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4],
                            +a[5], +a[6]));
                    }
                }
                return value;
            });

            myData = JSON.parse('["Date(09/09/2001)"]', function (key, value) {
                var d;
                if (typeof value === 'string' &&
                        value.slice(0, 5) === 'Date(' &&
                        value.slice(-1) === ')') {
                    d = new Date(value.slice(5, -1));
                    if (d) {
                        return d;
                    }
                }
                return value;
            });


    This is a reference implementation. You are free to copy, modify, or
    redistribute.

    This code should be minified before deployment.
    See http://javascript.crockford.com/jsmin.html

    USE YOUR OWN COPY. IT IS EXTREMELY UNWISE TO LOAD CODE FROM SERVERS YOU DO
    NOT CONTROL.
*/

/*jslint evil: true */

/*members "", "\b", "\t", "\n", "\f", "\r", "\"", JSON, "\\", apply,
    call, charCodeAt, getUTCDate, getUTCFullYear, getUTCHours,
    getUTCMinutes, getUTCMonth, getUTCSeconds, hasOwnProperty, join,
    lastIndex, length, parse, prototype, push, replace, slice, stringify,
    test, toJSON, toString, valueOf
*/

// Create a JSON object only if one does not already exist. We create the
// methods in a closure to avoid creating global variables.

var JSON = JSON || {};

(function () {

    function f(n) {
        // Format integers to have at least two digits.
        return n < 10 ? '0' + n : n;
    }

    if (typeof Date.prototype.toJSON !== 'function') {

        Date.prototype.toJSON = function (key) {

            return isFinite(this.valueOf()) ?
                   this.getUTCFullYear()   + '-' +
                 f(this.getUTCMonth() + 1) + '-' +
                 f(this.getUTCDate())      + 'T' +
                 f(this.getUTCHours())     + ':' +
                 f(this.getUTCMinutes())   + ':' +
                 f(this.getUTCSeconds())   + 'Z' : null;
        };

        String.prototype.toJSON =
        Number.prototype.toJSON =
        Boolean.prototype.toJSON = function (key) {
            return this.valueOf();
        };
    }

    var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        gap,
        indent,
        meta = {    // table of character substitutions
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"' : '\\"',
            '\\': '\\\\'
        },
        rep;


    function quote(string) {

// If the string contains no control characters, no quote characters, and no
// backslash characters, then we can safely slap some quotes around it.
// Otherwise we must also replace the offending characters with safe escape
// sequences.

        escapable.lastIndex = 0;
        return escapable.test(string) ?
            '"' + string.replace(escapable, function (a) {
                var c = meta[a];
                return typeof c === 'string' ? c :
                    '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
            }) + '"' :
            '"' + string + '"';
    }


    function str(key, holder) {

// Produce a string from holder[key].

        var i,          // The loop counter.
            k,          // The member key.
            v,          // The member value.
            length,
            mind = gap,
            partial,
            value = holder[key];

// If the value has a toJSON method, call it to obtain a replacement value.

        if (value && typeof value === 'object' &&
                typeof value.toJSON === 'function') {
            value = value.toJSON(key);
        }

// If we were called with a replacer function, then call the replacer to
// obtain a replacement value.

        if (typeof rep === 'function') {
            value = rep.call(holder, key, value);
        }

// What happens next depends on the value's type.

        switch (typeof value) {
        case 'string':
            return quote(value);

        case 'number':

// JSON numbers must be finite. Encode non-finite numbers as null.

            return isFinite(value) ? String(value) : 'null';

        case 'boolean':
        case 'null':

// If the value is a boolean or null, convert it to a string. Note:
// typeof null does not produce 'null'. The case is included here in
// the remote chance that this gets fixed someday.

            return String(value);

// If the type is 'object', we might be dealing with an object or an array or
// null.

        case 'object':

// Due to a specification blunder in ECMAScript, typeof null is 'object',
// so watch out for that case.

            if (!value) {
                return 'null';
            }

// Make an array to hold the partial results of stringifying this object value.

            gap += indent;
            partial = [];

// Is the value an array?

            if (Object.prototype.toString.apply(value) === '[object Array]') {

// The value is an array. Stringify every element. Use null as a placeholder
// for non-JSON values.

                length = value.length;
                for (i = 0; i < length; i += 1) {
                    partial[i] = str(i, value) || 'null';
                }

// Join all of the elements together, separated with commas, and wrap them in
// brackets.

                v = partial.length === 0 ? '[]' :
                    gap ? '[\n' + gap +
                            partial.join(',\n' + gap) + '\n' +
                                mind + ']' :
                          '[' + partial.join(',') + ']';
                gap = mind;
                return v;
            }

// If the replacer is an array, use it to select the members to be stringified.

            if (rep && typeof rep === 'object') {
                length = rep.length;
                for (i = 0; i < length; i += 1) {
                    k = rep[i];
                    if (typeof k === 'string') {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            } else {

// Otherwise, iterate through all of the keys in the object.

                var z = new Array();
                for (k in value)
                    z.push(k);

                z.sort();

                for (var l=0;l<z.length;l++) {
                    if (Object.hasOwnProperty.call(value, z[l])) {
                        v = str(z[l], value);
                        if (v) {
                            partial.push(quote(z[l]) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            }

// Join all of the member texts together, separated with commas,
// and wrap them in braces.

            v = partial.length === 0 ? '{}' :
                gap ? '{\n' + gap + partial.join(',\n' + gap) + '\n' +
                        mind + '}' : '{' + partial.join(',') + '}';
            gap = mind;
            return v;
        }
    }

// If the JSON object does not yet have a stringify method, give it one.

    if (typeof JSON.stringify !== 'function') {
        JSON.stringify = function (value, replacer, space) {

// The stringify method takes a value and an optional replacer, and an optional
// space parameter, and returns a JSON text. The replacer can be a function
// that can replace values, or an array of strings that will select the keys.
// A default replacer method can be provided. Use of the space parameter can
// produce text that is more easily readable.

            var i;
            gap = '';
            indent = '';

// If the space parameter is a number, make an indent string containing that
// many spaces.

            if (typeof space === 'number') {
                for (i = 0; i < space; i += 1) {
                    indent += ' ';
                }

// If the space parameter is a string, it will be used as the indent string.

            } else if (typeof space === 'string') {
                indent = space;
            }

// If there is a replacer, it must be a function or an array.
// Otherwise, throw an error.

            rep = replacer;
            if (replacer && typeof replacer !== 'function' &&
                    (typeof replacer !== 'object' ||
                     typeof replacer.length !== 'number')) {
                throw new Error('JSON.stringify');
            }

// Make a fake root object containing our value under the key of ''.
// Return the result of stringifying the value.

            return str('', {'': value});
        };
    }


// If the JSON object does not yet have a parse method, give it one.

    if (typeof JSON.parse !== 'function') {
        JSON.parse = function (text, reviver) {

// The parse method takes a text and an optional reviver function, and returns
// a JavaScript value if the text is a valid JSON text.

            var j;

            function walk(holder, key) {

// The walk method is used to recursively walk the resulting structure so
// that modifications can be made.

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


// Parsing happens in four stages. In the first stage, we replace certain
// Unicode characters with escape sequences. JavaScript handles many characters
// incorrectly, either silently deleting them, or treating them as line endings.

            cx.lastIndex = 0;
            if (cx.test(text)) {
                text = text.replace(cx, function (a) {
                    return '\\u' +
                        ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                });
            }

// In the second stage, we run the text against regular expressions that look
// for non-JSON patterns. We are especially concerned with '()' and 'new'
// because they can cause invocation, and '=' because it can cause mutation.
// But just to be safe, we want to reject all unexpected forms.

// We split the second stage into 4 regexp operations in order to work around
// crippling inefficiencies in IE's and Safari's regexp engines. First we
// replace the JSON backslash pairs with '@' (a non-JSON character). Second, we
// replace all simple value tokens with ']' characters. Third, we delete all
// open brackets that follow a colon or comma or that begin the text. Finally,
// we look to see that the remaining characters are only whitespace or ']' or
// ',' or ':' or '{' or '}'. If that is so, then the text is safe for eval.

            if (/^[\],:{}\s]*$/.
test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').
replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').
replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {

// In the third stage we use the eval function to compile the text into a
// JavaScript structure. The '{' operator is subject to a syntactic ambiguity
// in JavaScript: it can begin a block or an object literal. We wrap the text
// in parens to eliminate the ambiguity.

                j = eval('(' + text + ')');

// In the optional fourth stage, we recursively walk the new structure, passing
// each name/value pair to a reviver function for possible transformation.

                return typeof reviver === 'function' ?
                    walk({'': j}, '') : j;
            }

// If the text is not JSON parseable, then a SyntaxError is thrown.

            throw new SyntaxError('JSON.parse');
        };
    }
}());
