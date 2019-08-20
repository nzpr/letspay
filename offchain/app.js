var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');

var app = express();
var sqlite3 = require('sqlite3').verbose()
var db = new sqlite3.Database('./offchain.db', sqlite3.OPEN_READWRITE, (err) => {
  if (err) {
    console.error(err.message);
  }
  console.log('Connected to the offchain database.');
});
process.on('SIGTERM', () => {
  db.close();
});

db.each('CREATE TABLE balances (address TEXT, balance INT)', function (err, row){})

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);
app.use('/users', usersRouter);

app.get('/wallet/setbalance/:address/:balance', function (req, res) {
  var address=req.params.address;
  var newBal=req.params.balance;
  db.run(`Update balances set balance=${newBal} where address='${address}'`, function (err, row) {
    console.log('updated')
    if (row==undefined) {
        db.run(`insert into balances (address,balance) values ('${address}',${newBal})`, function (err, row) {
      });
    }
  });
  res.send("OK")
})

app.get('/transfer/:from/:to/:amt', function (req, res) {
  var amt=req.params.amt;
 
  if (req.params.from==req.params.to) {
	res.send("self send")
  }

  db.each(`SELECT rowid AS id, balance FROM balances where address='${req.params.from}'`, function (err, row) {
    var q = `UPDATE balances set balance=${row.balance-parseFloat(amt)} where address='${req.params.from}'`;
    db.each(q, function (err, row) {
      console.log(q);
    })
  })

  db.each(`SELECT rowid AS id, balance FROM balances where address='${req.params.to}'`, function (err, row) {
    var q = `UPDATE balances set balance=${row.balance+parseFloat(amt)} where address='${req.params.to}'`
    db.each(q, function (err, row) {
       console.log(q);
    })
  })
  res.send()
})

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
