var express = require('express');
var app = express();
var mysql = require('mysql');
var conn = mysql.createConnection({
	host: 'localhost',
	user: 'root',
	password: 'root',
	database: 'tododb'
});

app.use(express.static(__dirname + '/public'));

app.get('/', function(req, res){
	console.log("LOADED");
	res.render('index.html');
});

app.get('/hello', function(req, res){
	res.send('HELLO WORLD');
});

conn.connect();

app.get('/todo', function(req, res){
	console.log("in todo function");
	conn.query('SELECT * FROM todo', function(err, rows, fields){
		if(err){
			console.log("Something is wrong");
			console.log(err);
		}
		else{
			res.send(rows);
		}
	});
});


app.listen(3000, function(){
	console.log('Listening on 3000');
});

