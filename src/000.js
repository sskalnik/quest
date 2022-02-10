const express = require('express');
const app = express();
const port = 3000;

app.get('/', function(req, res) {
  const {exec} = require('child_process');
  exec('bin/001', (error, stdout, stderr) => {
    if (error) {
      console.error(`Running exec against bin/001 resulted in an error: ${error}`);
      return res.send(`${stderr}`);
    }
    return res.send(`${stdout}`);
  });
});

app.get('/aws', function(req, res) {
  const {exec} = require('child_process');
  exec('bin/002', (error, stdout, stderr) => {
    if (error) {
      console.error(`Running exec against bin/002 resulted in an error: ${error}`);
      return res.send(`${stderr}`);
    }
    return res.send(`${stdout}`);
  });
});

app.get('/docker', function(req, res) {
  const {exec} = require('child_process');
  exec('bin/003', (error, stdout, stderr) => {
    if (error) {
      console.error(`Running exec against bin/003 resulted in an error: ${error}`);
      return res.send(`${stderr}`);
    }
    return res.send(`${stdout}`);
  });
});

app.get('/loadbalanced', function(req, res) {
  const {exec} = require('child_process');
  exec('bin/004 ' + JSON.stringify(req.headers), (error, stdout, stderr) => {
    if (error) {
      console.error(`Running exec against bin/004 resulted in an error: ${error}`);
      return res.send(`${stderr}`);
    }
    return res.send(`${stdout}`);
  });
});

app.get('/tls', function(req, res) {
  const {exec} = require('child_process');
  exec('bin/005 ' + JSON.stringify(req.headers), (error, stdout, stderr) => {
    if (error) {
      console.error(`Running exec against bin/005 resulted in an error: ${error}`);
      return res.send(`${stderr}`);
    }
    return res.send(`${stdout}`);
  });
});

app.get('/secret_word', function(req, res) {
  const {exec} = require('child_process');
  exec('bin/006 ' + JSON.stringify(req.headers), (error, stdout, stderr) => {
    if (error) {
      console.error(`Running exec against bin/006 resulted in an error: ${error}`);
      return res.send(`${stderr}`);
    }
    return res.send(`${stdout}`);
  });
});

app.listen(port, () => console.log(`Rearc quest listening on port ${port}!`));
