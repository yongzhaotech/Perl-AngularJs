var JSONOBJECT = {
	path:"111",
	name:"Hierarchy"
};

var documents = (function() {
	var addElements = function(obj, dom) {
		var div = document.createElement("div");
		var span = document.createElement("span");
		var txt = document.createTextNode(obj.name);
		span.appendChild(txt);
		div.appendChild(span);
		div.id = obj.path;
		span.className = "js-files";
		div.className = "js-folders";
		dom.appendChild(div);
		span.addEventListener("click", addElement);	
		for(var k in obj.children) {
			addElements(obj.children[k], div);
		}	
	};
	var addElement = function() {
		var parentPath = this.parentElement.id;
		var parentElement = this.parentElement;

		var div = document.createElement("div");
		var input = document.createElement("input");
		var plus = document.createElement("span");
		input.placeholder = "Enter here";
		plus.appendChild(document.createTextNode("+"));
		input.className = "js-input";
		plus.className = "js-files";
		plus.addEventListener("click", function() {
			input.value = input.value.replace(/\s+$/, '');
			input.value = input.value.replace(/^\s+/, '');
			if(!input.value.length) {
				alert("Can not be blank!");
				return;
			}
			span.innerHTML = input.value;
			jsonObj.element.children.push({
				path:div.id,
				name:input.value,
				children:[]
			});
			div.removeChild(input);
			div.removeChild(plus);
		});
		div.appendChild(input);
		div.appendChild(plus);

		var span = document.createElement("span");
		var children = parentElement.getElementsByTagName("div");
		if(children.length) {
			var paths = [];
			for(var e of children) {
				if(e.id.length === parentPath.length + 3) {
					paths.push(e.id);
				}
			}
			var path = paths.sort((a, b) => { return a - b; }).pop();
			div.id = +path + 1;
		}else {
			div.id = parentPath + '111';
		}
		
		div.appendChild(span)
		span.className = "js-files";
		div.className = "js-folders";
		parentElement.appendChild(div);
		span.addEventListener("click", addElement);
		input.focus();

		var jsonObj = {};
		findParent.call(jsonObj, JSONOBJECT, parentPath);
		if(!jsonObj.element.children) { jsonObj.element.children = []; }
	};
	var findParent = function(json, path) {
		if(json.path === path) {
			this.element = json;
		}else {
			for(var k in json) {
				if(typeof json[k] === 'object') {
					findParent.call(this, json[k], path);
				}
			}
		}
	};
	return {
		addElements: addElements,
	};
})();