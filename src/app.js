'use strict'
const express = require('express')
const { DynamoDBClient, ScanCommand } = require('@aws-sdk/client-dynamodb')
const { S3Client, ListObjectsV2Command } = require('@aws-sdk/client-s3')
const app = express()
const dynamodb = new DynamoDBClient({ region: 'us-west-2' })
const s3 = new S3Client({})

app.use((req, res, next) => {
  console.log(`${req.method} called on ${req.path} on ${new Date().toISOString()}`)
  next()
})

app.get('/health', (req, res) => {
  res.send('healthy')
})

app.get('/', async (req, res) => {
  const scanCommand = new ScanCommand({ TableName: process.env.DYNAMO_TABLE_NAME })
  const listObjectsV2Command = new ListObjectsV2Command({ Bucket: process.env.BUCKET_NAME })
  try {
    const [dynamoData, s3Data] = await Promise.all([
      dynamodb.send(scanCommand),
      s3.send(listObjectsV2Command)
    ])
    res.send({
      secret: process.env.SOME_SECRET,
      table: process.env.DYNAMO_TABLE_NAME,
      numItemsInDynamo: dynamoData.Count,
      bucket: process.env.BUCKET_NAME,
      numObjectsInS3: s3Data.KeyCount
    })
  } catch (err) {
    console.log(err, err.stack)
    res.status(500).send('Error reading table or S3')
  }
})
function mySlowFunction(baseNumber) {
  console.time('mySlowFunction');
  let result = 0;
  for (let i = Math.pow(baseNumber, 7); i >= 0; i--) {
    result += Math.atan(i) * Math.tan(i);
  }
  console.timeEnd('mySlowFunction');
}
app.get('/cpu/:complexity', async (req, res) => {
  try {
    mySlowFunction(Number(req.params.complexity))
    res.send({
      ping: 'pong'
    })
  } catch (err) {
    console.log(err, err.stack)
    res.status(500).send('Error')
  }
})

module.exports = app
