require "shelljs/global"
q = require 'q'
request = require 'request'
launchInstance = require('../lib/aws-helpers').launchInstance

healthCheckUrl = (url) ->
  d = q.defer()
  attempts = 1
  maxAttempts = 10
  interval = setInterval ( ->
    echo "requesting #{url} for #{attempts} times"
    request.get {url:url, timeout:20}, (err, resp) ->
      if err
        echo err, err.stack
        d.reject err
      else if resp.statusCode == 200
        clearInterval interval
        echo "response ok. url is ready for loading"
        d.resolve(url)
      else
        echo "response is #{resp.statusCode}, waiting..."
    attempts++
    if attempts > maxAttempts
      clearInterval interval
      d.reject new Error "address #{url} is unreachable"
  ), 21000
  return d.promise

module.exports = (AWS, version, hardware, dbConnString) -> 
  instanceInitScript=cat("./launchers/scripts/backend-init-ec2_from-custom-ami.ps1")
    .replace "$appVersion = '1.6.1'", "$appVersion = '#{version}'"
    .replace "$connString = 'abaab'", "$connString = '#{dbConnString}'"
  params =
    ImageId: "ami-00268877" #My custom Microsoft Windows Server 2012 Base with IIS and stuff installed
    MaxCount: hardware.count
    MinCount: hardware.count
    SecurityGroups: ['backend']
    InstanceInitiatedShutdownBehavior: "terminate"
    InstanceType: hardware.type
    KeyName: "sc-backend"
    IamInstanceProfile:
      Arn: "arn:aws:iam::223840855670:instance-profile/sc-backend"
    Monitoring:
      Enabled: false # required
    UserData: new Buffer(instanceInitScript).toString('base64')

  ec2 = new AWS.EC2
  launchInstance ec2, params, "test-backend-#{version}"
    .then (host) -> healthCheckUrl "http://#{host}"



