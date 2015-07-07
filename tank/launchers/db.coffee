require "shelljs/global"
q = require 'q'
launchInstance = require("../lib/aws-helpers").launchInstance

healthCheckDb = (url) ->
  q.Promise (resolve) ->
    console.log "waiting 2m for db scripts"
    setTimeout (-> console.log "db is ready"; resolve url), 120000

module.exports = (AWS, instanceType) -> 
  params =
    ImageId: "ami-66228711" #Microsoft Windows Server 2012 R2 with SQL Server Web - ami-66228711
    MaxCount: 1
    MinCount: 1
    InstanceInitiatedShutdownBehavior: "terminate"
    InstanceType: instanceType
    SecurityGroups: ['site-sql']
    KeyName: "tools"
    IamInstanceProfile:
      Arn: "arn:aws:iam::223840855670:instance-profile/sql-serv"
    Monitoring:
      Enabled: false # required
    UserData: new Buffer(cat("./launchers/scripts/db-init-ec2.ps1")).toString('base64')

  ec2 = new AWS.EC2
  launchInstance ec2, params, 'test-db'
    .then healthCheckDb