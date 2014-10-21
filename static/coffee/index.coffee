class ReportViewModel
  constructor: (report, @list) ->
    @[k]=v for k, v of report

  remove: ->
    $.ajax
      url: '/report/'+@_id
      type: 'DELETE'
      success: () => @list.reports.remove @

class ReportsListViewModel
  constructor: (reports) ->
    @reports = ko.observableArray reports.map (r) => new ReportViewModel r, @

$(document).ready ->
  vm = new ReportsListViewModel $('body').data('model')
  ko.applyBindings vm