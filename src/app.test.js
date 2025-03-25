import request from 'supertest'
import { describe, test } from 'node:test'
import assert from 'node:assert'

import app from './app.js'

describe('GET /health', () => {
  test('should return 200', async () => {
    const response = await request(app).get('/health')
    assert.equal(response.statusCode, 200)
  })
})
