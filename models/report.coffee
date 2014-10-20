mongoose = require "mongoose"

ReportSchema = new mongoose.Schema
  name: String
  category: String
  startTimestamp: Number
  endTimestamp: Number # javascript Date timestamp
  appVersion: String
  date: String # 11-10-1989

ReportSchema.methods.findAllVersions = (callback) ->
  @model("Report").find name: @name, callback


ReportModel = mongoose.model "Report", ReportSchema

module.exports = ReportModel


