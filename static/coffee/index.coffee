class ReportViewModel
  constructor: (report, @list) ->
    @[k]=v for k, v of report

class ReportsListViewModel
  constructor: (reports) ->
    dates = _.groupBy reports, (r) -> moment(r.startTimestamp).format "DD MMM YYYY"
    @reportsByDate = (date: d, reports: r for d,r of dates)
    for date in @reportsByDate
      date.reports = ko.observableArray date.reports.map (r) => new ReportViewModel r, @
    @remove = (report) =>
      $.ajax
        url: '/report/'+report._id
        type: 'DELETE'
        success: () => _.find(@reportsByDate, (r)->r.date == moment(report.startTimestamp).format "DD MMM YYYY").reports.remove report


$(document).ready ->
  vm = new ReportsListViewModel $('body').data('model')
  ko.applyBindings vm