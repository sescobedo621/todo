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

var cookieParser = require('cookie-parser');
var credentials = require('./.credentials.js');
var session = require('express-session');
var handlebars = require('express-handlebars').create({defaultLayout: 'application'});

app.engine('handlebars', handlebars.engine);
app.set('view engine', 'handlebars');

app.use(express.static(__dirname + '/public'));
app.set('views', __dirname + '/public');
app.engine('html', require('ejs').renderFile);
app.set('view engine', 'html');
app.use(bodyParser.json());
app.use(cookieParser(credentials.cookieSecret));
app.use(session({
	resave: false,
	saveUnititialized: false,
	secret: credentials.cookieSecret
}));



app.get('/', function(req, res){
	console.log("LOADED");
	//res.send('hello');
	//res.redirect('login.html');
	res.render('login');
});

app.get('/hello', function(req, res){
	res.send('HELLO WORLD');
});

conn.connect();

app.get('/login', function(req, res){
	console.log('in login server');
	var query = "SELECT * from user WHERE username = '" +req.query.username +"' AND password = '" + req.query.password +"'";
	console.log(query);
	conn.query(query, function(err, rows, fields){
		console.log("in query function");
		if(err){
			console.log("ERRROR")
			console.log(err);
		}
		else{
			console.log("in else statement");
			console.log(rows);
			req.session.user = rows;
			
		}

	});
	res.sendFile('/public/inde.html');
});

app.get('/todo', function(req, res){
	var query = "SELECT list, notes FROM todo";
	if(req.session.user){
			query = "SELECT list, notes FROM todo JOIN mytodos ON todo.id = mytodos.todo_id"
				+"JOIN user ON mytodos.user_id = user.id WHERE user.id =" + req.session.user.id;
	}

	conn.query(query , function(err, rows, fields){
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

