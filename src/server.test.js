import { server } from './server.js'
import { test } from 'node:test'
import assert from 'node:assert/strict'

test('should return 200', async () => {
  const app = await server()
  const response = await app.inject('/health')
  assert(response.statusCode, 200)
})
