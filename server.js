const express = require('express');
const dotenv = require('dotenv');
const path = require('path');

const server = express();

server.set('view engine', 'ejs');

// Middleware
server.use(express.urlencoded({ extended: true }));
server.use(express.static(path.join(__dirname, 'public')));
server.use(express.json());

// Routes
server.use('/', require('./routes/starwowRoutes'));

const hostname = "localhost";
const port = 8000;

server.listen(port, () => {
console.log(`Server running at http://${hostname}:${port}/`);
});
