var newman = require('newman');

exports.handler =  async function(event, context) {
    return run_tests(".");
}

function run_tests(postman_files_dir) {
    return new Promise(function(resolve, reject) {
        newman.run({
            collection: require(postman_files_dir + '/hello-world-api.postman_collection.json'),
            environment: require(postman_files_dir + '/dev.postman_environment.json'),
            reporters: 'cli',
            abortOnFailure: true
        }, function (err) {
            if (err) {
                console.log(err);
                reject(err);
            }
            else {
                console.log('collection run complete!');
                resolve();
            }
        });
    });
}

//run_tests("../../../.postman");