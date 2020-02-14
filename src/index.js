const express = require('express')
const app = express()
const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB({region: "us-west-2"});

app.use((req, res, next) => {
  console.log(`${req.method} called on ${req.path} on ${new Date().toISOString()}`)
  next()
})

app.get('/health', (req, res) => {
  res.send('healthy')
})

app.get('/', (req, res) => {

  var params = {
    TableName: process.env.DYNAMO_TABLE_NAME
  };
  dynamodb.describeTable(params, function(err, data) {
    if (err) {
      console.log(err, err.stack);
      res.status(500)
      res.send("Error reading table")
    }
    else {
      res.send(JSON.stringify({
        secret: process.env.SOME_SECRET,
        table: process.env.DYNAMO_TABLE_NAME,
        numItems: data.Table.ItemCount
      }))
    }
  });
})

app.listen(8080, () => {
  console.log('listening on port 8080')
})