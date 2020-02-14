const express = require('express')
const app = express()

app.use((req, res, next) => {
  console.log(`${req.method} called on ${req.path} on ${new Date().toISOString()}`)
  next()
})

app.get('/health', (req, res) => {
  res.send('healthy')
})

app.get('/', (req, res) => {

  res.send(JSON.stringify({
    secret: process.env.SOME_SECRET,
    table: process.env.DYNAMO_TABLE_NAME
  }))
})

app.listen(8080, () => {
  console.log('listening on port 8080')
})