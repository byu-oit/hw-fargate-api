import { server } from './server.js'

async function run () {
  const app = await server()

  await app.listen({
    host: '0.0.0.0',
    port: 8080
  })
}

run()
  .then(r => {})
  .catch(err => console.log({ err }, 'Error starting app'))
