const express = require('express')
const app = express()
const AWS = require('aws-sdk')
const dynamodb = new AWS.DynamoDB({ region: 'us-west-2' })
const s3 = new AWS.S3()

app.use((req, res, next) => {
  console.log(`${req.method} called on ${req.path} on ${new Date().toISOString()}`)
  next()
})

app.get('/health', (req, res) => {
  res.send('healthy')
})

app.get('/', async (req, res) => {
  const dynamoParams = { TableName: process.env.DYNAMO_TABLE_NAME }
  const bucketParams = { Bucket : process.env.BUCKET_NAME }
  try {
    const [dynamoData, s3Data] = await Promise.all([
      dynamodb.scan(dynamoParams).promise(),
      s3.listObjectsV2(bucketParams).promise()
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

app.listen(8080, () => {
  console.log('listening on port 8080')
})
