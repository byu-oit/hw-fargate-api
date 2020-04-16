const express = require('express')
const app = express()
const AWS = require('aws-sdk')
const dynamodb = new AWS.DynamoDB({ region: 'us-west-2' })

app.use((req, res, next) => {
  console.log(`${req.method} called on ${req.path} on ${new Date().toISOString()}`)
  next()
})

app.get('/health', (req, res) => {
  res.send('healthy')
})

app.get('/', async (req, res) => {
  const params = { TableName: process.env.DYNAMO_TABLE_NAME }
  try {
    const data = await dynamodb.scan(params).promise()
    res.send({
      secret: process.env.SOME_SECRET,
      table: process.env.DYNAMO_TABLE_NAME,
      numItems: data.Count
    })
  } catch (err) {
    console.log(err, err.stack)
    res.status(500).send('Error reading table')
  }
})

app.listen(8080, () => {
  console.log('listening on port 8080')
})
