require "shelljs/global"
launchInstance = require("../lib/aws-helpers").launchInstance

module.exports = (AWS, instanceType) -> 
  params =
    ImageId: "ami-f0b11187" # required
    MaxCount: 1 # required
    MinCount: 1 # required
    InstanceInitiatedShutdownBehavior: "terminate"
    InstanceType: instanceType
    KeyName: "tools"
    Monitoring:
      Enabled: false # required
    UserData: new Buffer(cat "./launchers/scripts/tank-init-ec2.sh").toString('base64')

  ec2 = new AWS.EC2

  launchInstance ec2, params, "tank"