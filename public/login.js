onload = function(){
	login();
}

function login(){
	console.log('in login');
	var login = document.loginForm;
	var username = document.loginForm.username;
	var password = document.loginForm.password;
	var submit = document.loginForm.submit;

	submit.addEventListener('click', function(e){
		e.preventDefault();
		var url = '/login?username='+ username.value + "&password=" + password.value;
		getData(url);


	});
}

function getData(url, callback){
	console.log('in get login data');
	var xhr = new XMLHttpRequest();

	xhr.open('GET', url);

	xhr.onreadystatechange = function(){
		if(xhr.readyState == 4 && xhr.status < 400){
			if(callback){
				callback(JSON.parse(xhr.responseText));
			}
		}
	}
		
	xhr.send(null);
	
}