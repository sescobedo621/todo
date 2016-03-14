onload = function(){
	getData('/todo', createTable);
}

function getData(url, callback){
	console.log("in getData");
	var xhr = new XMLHttpRequest();
	xhr.open('GET', url);

	xhr.onreadystatechange = function(){
		if(xhr.status < 400 && xhr.readyState == 4){
			callback(JSON.parse(xhr.responseText));
		}
	};

	xhr.send(null);
}

function whateverData(method, url, callback, obj){
	var xhr = new XMLHttpRequest();
	xhr.open(method, url);

	xhr.onreadystatechange = function(){
		if(xhr.status < 400 && xhr.readyState == 4){
			if(callback){
				callback(JSON.parse(xhr.responseText));
			}else{
				getData('/todo', createTable);
			}
		}
	};

	if(obj){
		xhr.send(JSON.stringify(obj));
	}
	else{
		xhr.send(null);
	}
}

function createTable(data){
	console.log('in createTable');
	var table = document.getElementById('todoTable');
	var thr = document.createElement('tr');
	for(var key in data[0]){
		var th = document.createElement('th');
		th.innerHTML = key;
		thr.appendChild(th);
	}
	table.appendChild(thr);

	for(var i = 0; i < data.length; i++){
		var tr = document.createElement('tr');
		for(var key in data[i]){
			var td = document.createElement('td');
			td.innerHTML = data[i][key];
			tr.appendChild(td);
		}
		var deleteButton = document.createElement('button');
		deleteButton.setAttribute('d_id', data[i].id);	
		deleteButton.value = "DELETE";
		deleteButton.innerHTML = "DELETE";
		deleteButton.addEventListener('click', function(e){
			var deleteElement = e.target.getAttribute('d_id');
			var url = "/todo/" + deleteElement;
			whateverData('DELETE', url);
		});
		tr.appendChild(deleteButton);
		table.appendChild(tr);
	}
}