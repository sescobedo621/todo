onload = function(){
	getData('/todo', createTable);
	addForm();
}

function getData(url, callback){
	console.log("in getData");
	console.log(url);
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
	xhr.setRequestHeader('Content-Type', 'application/json');
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
	if(!table){
		table = document.createElement('table');
	}
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
		var updateButton = document.createElement('button');
		updateButton.setAttribute('u_id', data[i].id);	
		updateButton.value = "UPDATE";
		updateButton.innerHTML = "UPDATE";
		updateButton.addEventListener('click', function(e){
			var url = '/idtodo/' + e.target.getAttribute('u_id');
			console.log(url);
			getData(url, updateForm);
			//updateForm();
		});
		tr.appendChild(deleteButton);
		tr.appendChild(updateButton);
		table.appendChild(tr);
	}

		document.querySelector('body').appendChild(table);
}


function updateForm(data){
	console.log(data);
	var table = document.getElementById('todoTable');
	if(table){
		table.parentNode.removeChild(table);
	}
	var body = document.querySelector('body');
	var form = document.createElement('form');
	var listInput = document.createElement('input');
	listInput.type = "text";
	listInput.value = data[0].list;
	listInput.name = "list";
	form.appendChild(listInput);
	var notesInput = document.createElement('input');
	notesInput.type = "text";
	notesInput.value = data[0].notes;
	notesInput.name = "notes";
	form.appendChild(notesInput);

	var submit = document.createElement('input');
	submit.type = 'submit';
	submit.value = 'UPDATE';

	form.appendChild(submit);

	submit.addEventListener('click', function(e){
		e.preventDefault();
		var url = '/todo/' + data[0].id;
		console.log(url);
		var updated = {};
		updated.id = data[0].id;
		updated.list = listInput.value;
		updated.notes = notesInput.value;
		whateverData('PUT', url, null, updated);

	});
	body.appendChild(form);

}

function addForm(){
	console.log("in add form");
	var form = document.addForm;
	var list = document.addForm.list;
	var notes = document.addForm.notes;
	var submit = document.addForm.submit;

	submit.addEventListener('click', function(e){
		e.preventDefault();
		var todo = {};
		todo.list = list.value;
		todo.notes = notes.value;

		whateverData('POST', '/todo', null, todo);
	})
}












