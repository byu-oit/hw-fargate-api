const core = require('@actions/core');
const fs = require('fs');
const client = require('aws-sdk/clients/codedeploy');

async function run () {
  try {
    const appName = core.getInput('application-name');
    const groupName = core.getInput('deployment-group-name');
    const appspecFile = core.getInput('appspec-file');
    console.log(`Hello world! ${appName}, ${groupName}, ${appspecFile}`);

    const appspecJson = fs.readFileSync(appspecFile, 'utf8');

    console.log("1 ", appspecJson);
    //
    // const cliInputJson = {
    //   "applicationName": appName,
    //   "deploymentGroupName": groupName,
    //   "revision": {
    //     "revisionType": "AppSpecContent",
    //     "appSpecContent": {
    //       "content": JSON.stringify(appspecJson)
    //     }
    //   }
    // }
    //
    // console.log("2 ", JSON.stringify(appspecJson));

    const codeDeploy = new client();
    const deployment = await codeDeploy.createDeployment({
      applicationName: appName,
      deploymentGroupName: groupName,
      revision: {
        revisionType: "AppSpecContent",
        appSpecContent: {
          content: appspecJson
        }
      }
    }).promise();
    console.log('deployment', deployment);
    await codeDeploy.waitFor('deploymentSuccessful', {deploymentId: deployment.deploymentId}).promise();

    // const time = (new Date()).toTimeString();
    // core.setOutput("time", time);
    // // Get the JSON webhook payload for the event that triggered the workflow
    // const payload = JSON.stringify(github.context.payload, undefined, 2)
    // console.log(`The event payload: ${payload}`);
    process.exit(0);
  } catch (error) {
    console.error(error);
    core.setFailed(error.message);
    process.exit(1);
  }
}

run();
