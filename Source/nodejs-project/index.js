const express = require('express');
const path = require('path');

const app = express();
var cors = require('cors');
const bodyParser = require('body-parser')

app.use(bodyParser.urlencoded({
  extended: true
}))

app.use(bodyParser.json())


// Then use it before your routes are set up:
app.use(cors());
let auth = '';
let username = '';
// Serve the static files from the React app
app.use(express.static(path.join(__dirname, 'client/build')));

app.post('/logincheck', (req, res) => {
         
    var request = require('request'),
    username = req.body.username,
    password = req.body.password,
    url = 'https://api.lamp.digital/participant/me';
    auth = "Basic "+ new Buffer(username + ":" + password).toString("base64");

    request(
    {
        url : url,
        headers : {
            "Authorization" : auth
        }
    },
    function (error, response, body) {
        if(typeof response != 'undefined') {
            if(response.statusCode == 200) {
                res.status(response.statusCode).send({'token' : auth, 'userID' : username});
            } else {
                res.status(response.statusCode).send({'status': response.statusCode});
            }
        } else {
            res.status(503).send({'status': 503});
        }
    });
  
});

// Handles any requests that don't match the ones above
app.get('*', (req,res) =>{
    res.sendFile(path.join(__dirname+'/client/build/index.html'));
});

const port = process.env.PORT || 5000;
app.listen(port);

console.log('App is listening on port ' + port);
