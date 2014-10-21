express = require 'express'
ReportModel = require "./models/report"
config = require "./config"

router = new express.Router

router.get "/", (req, res) ->
  ReportModel.find {}, (err, reports) ->
    if err then next err
    else res.render "index.jade", reports: reports.map (r) -> r.toObject()

router.route "/report/:id"
  .get (req, res, next) ->
    ReportModel.findById req.params.id, (err, report) ->
      if err then next err
      else
        report.findAllVersions (err, reports) ->
          if err then next err
          else res.render "report.jade",
            graphite: config.graphite
            report: report
            versionsIds: reports.map (r) -> r._id
            versions: reports.map (r) -> r.toObject()

  .delete (req, res, next) ->
    ReportModel.remove _id: req.params.id, (err) ->
      if err then next err
      else res.send 200

router.route "/report"
  .post (req, res, next) ->
    report = new ReportModel req.body
    report.save (err) ->
      if err then next err
      else res.json report.toObject()

router.get "/compare/:ids", (req, res, next) ->
  ids = req.params.ids.split(',')
  ReportModel.find _id: {$in: ids}, (err, reports) ->
    if err then next err
    else res.render 'compare.jade',
      targets: reports.map (r) -> r.toObject()
      graphite: config.graphite

module.exports = router


