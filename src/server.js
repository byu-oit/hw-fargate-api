import Fastify from 'fastify'
import { DynamoDBClient, ScanCommand } from '@aws-sdk/client-dynamodb'
import { S3Client, ListObjectsV2Command } from '@aws-sdk/client-s3'

const dynamodb = new DynamoDBClient({ region: 'us-west-2' })
const s3 = new S3Client({})

export async function server (options) {
  const fastify = await Fastify({
    logger: true
  })

  fastify.get('/health', (req, res) => {
    res.send('healthy')
  })

  fastify.get('/', async (req, res) => {
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

  return fastify
}
