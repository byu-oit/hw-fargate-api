const newman = require('newman')
const AWS = require('aws-sdk')
const codedeploy = new AWS.CodeDeploy({ apiVersion: '2014-10-06', region: 'us-west-2' })

exports.handler = async function (event, context) {
  console.log(event)

  let errorFromTests
  await runTests('.postman').catch(err => { errorFromTests = err })

  const params = {
    deploymentId: event.DeploymentId,
    lifecycleEventHookExecutionId: event.LifecycleEventHookExecutionId,
    status: errorFromTests ? 'Failed' : 'Succeeded'
  }
  try {
    const data = await codedeploy.putLifecycleEventHookExecutionStatus(params).promise()
    console.log(data)
  } catch (err) {
    console.log(err, err.stack)
    throw err
  }

  if (errorFromTests) throw errorFromTests // Cause the lambda to "fail"
}

function newmanRun (options) {
  return new Promise((resolve, reject) => {
    newman.run(options, err => { err ? reject(err) : resolve() })
  })
}

async function runTests (postmanFilesDir) {
  try {
    await newmanRun({
      collection: require(`${postmanFilesDir}/hello-world-api.postman_collection.json`),
      environment: require(`${postmanFilesDir}/${process.env.ENV}-tst.postman_environment.json`),
      reporters: 'cli',
      abortOnFailure: true
    })
    console.log('collection run complete!')
  } catch (err) {
    console.log(err)
    throw err
  }
}

// runTests('../../../.postman')
