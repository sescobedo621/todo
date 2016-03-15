var express = require('express');
var app = express();
var mysql = require('mysql');
var bodyParser = require('body-parser');
var conn = mysql.createConnection({
	host: 'localhost',
	user: 'root',
	password: 'root',
	database: 'tododb'
});

app.use(express.static(__dirname + '/public'));
app.use(bodyParser.json());

app.get('/', function(req, res){
	console.log("LOADED");
	res.render('index.html');
});

app.get('/hello', function(req, res){
	res.send('HELLO WORLD');
});

conn.connect();

app.get('/todo', function(req, res){
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

app.get('/idtodo/:id', function(req, res){

	var query = 'SELECT * FROM todo WHERE id=' + req.params.id;

	conn.query(query, function(err, rows, fields){
		if(err){
			console.log(err);
		}
		else{
			res.send(rows);
		}
	});
});

app.delete('/todo/:id', function(req, res){
	var query = "DELETE FROM todo WHERE id =" + req.params.id ;

	conn.query(query, function(err, rows, fields){
		if(err){
			console.log("Something is wrong");
			console.log(err);
		}
		else{
			res.send(rows);

		}	
	});
});
app.put('/todo/:id', function(req, res){
	var list = req.body.list;
	var notes = req.body.notes;

	var query = "UPDATE todo SET list='" + list +"', notes='" + notes + "' WHERE id=" + req.params.id;
	console.log(query);
	conn.query(query, function(err, rows, fields){
		if(err){
			console.log("SOMETHING HAPPENED");
			console.log(err);
		}
		else{
			res.send(rows);
		}
	});
});

app.post('/todo', function(req, res){
	console.log("in app.post");
	var query = "INSERT INTO todo (list, notes) VALUES ('" + req.body.list +"', '" + req.body.notes +"')";

	conn.query(query, function(err, rows, fields){
		if(err){
			console.log("SOMETHING HAPPENED");
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

