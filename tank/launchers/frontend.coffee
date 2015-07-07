hashToEnvOptionSettings = (hash) ->
  _.pairs(hash).map (pair) ->
    Namespace: "aws:elasticbeanstalk:application:environment"
    OptionName: pair[0]
    Value: pair[1]

module.exports = (AWS) ->
  beanstalk = new AWS.ElasticBeanstalk

  createEnvRequest =
    ApplicationName: "SyncCloud.Frontend",
    EnvironmentName: "sc-front-load-#{frontendBranch}",
    CNAMEPrefix: "sc-front-load-#{frontendBranch}",
    Description: "Synccloud frontend version #{frontendBranch}",
    TemplateName: "synccloud-frontend-load",
    VersionLabel: frontendBranch,
    OptionSettings: hashToEnvOptionSettings(BACKEND_URL: "")

  beanstalk.createEnvironment(createEnvRequest).promise()