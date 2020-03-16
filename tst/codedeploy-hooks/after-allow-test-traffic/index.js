var newman = require('newman');
var AWS = require('aws-sdk');
var codedeploy = new AWS.CodeDeploy({apiVersion: '2014-10-06', region: 'us-west-2'});

exports.handler =  async function(event, context) {
    console.log(event);
    return run_tests(".postman", event.deploymentId, event.lifecycleEventHookExecutionId);
}

function run_tests(postman_files_dir, deploymentId, lifecycleEventHookExecutionId) {
    return new Promise(function(resolve, reject) {
        newman.run({
            collection: require(postman_files_dir + '/hello-world-api.postman_collection.json'),
            environment: require(postman_files_dir + '/dev-tst.postman_environment.json'),
            reporters: 'cli',
            abortOnFailure: true
        }, function (err) {
            if (err) {
                console.log(err);
                var params = {
                    deploymentId: deploymentId,
                    lifecycleEventHookExecutionId: lifecycleEventHookExecutionId,
                    status: "Failed"
                };
                codedeploy.putLifecycleEventHookExecutionStatus(params, function(err2, data) {
                    if (err2) {
                        console.log(err2, err2.stack); // an error occurred
                        reject(err2);
                    } 
                    else {
                        console.log(data);           // successful response
                        reject(err);
                    }
                });
            }
            else {
                console.log('collection run complete!');
                var params = {
                    deploymentId: deploymentId,
                    lifecycleEventHookExecutionId: lifecycleEventHookExecutionId,
                    status: "Succeeded"
                };
                codedeploy.putLifecycleEventHookExecutionStatus(params, function(err2, data) {
                    if (err2) {
                        console.log(err2, err2.stack); // an error occurred
                        reject(err2);
                    } 
                    else {
                        console.log(data);           // successful response
                        resolve();
                    }
                });
            }
        });
    });
}

// run_tests("../../../.postman", "a", "b");