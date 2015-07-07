exports.launchInstance = (ec2, request, instanceName) ->
   ec2.runInstances(request).promise().then (resp) ->
    instanceId = resp.Instances[0].InstanceId
    echo "#{instanceName} id is #{instanceId}. Waiting instance to run"
    ec2.waitFor("instanceRunning", InstanceIds: [instanceId]).promise().then ->
      ec2.describeInstances(InstanceIds: [instanceId]).promise().then (resp) ->
        instanceUrl = resp.Reservations[0].Instances[0].PublicDnsName
        echo "#{instanceName} is running at #{instanceUrl}"
        ec2.createTags(Resources: [instanceId], Tags: [{Key: 'Name', Value: instanceName}]).promise().then ->
          instanceUrl

`var q = require('q');

exports.injectPromise = function(aws){
    aws.Request.prototype.promise = function() {
        var d = q.defer();

        this.on('complete', function(response) {
            if (response.error) {
                d.reject(response.error);
            } else {
                d.resolve(response.data);
            }
        });
        this.send();

        return d.promise;
    };
};`




