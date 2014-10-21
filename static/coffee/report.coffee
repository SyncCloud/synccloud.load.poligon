charts = require "./graphite-charts"

templates = [
    name: 'CPU Utilization'
    targets: [
      metric: "%p.backend.cpu"
    ]
  ,
    name: 'Quantiles'
    targets: [
      metric: "%p.overall.quantiles.100_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.overall.quantiles.99_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.overall.quantiles.95_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.overall.quantiles.90_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.overall.quantiles.75_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.overall.quantiles.50_0"
      function: "aliasByMetric(%m)"
    ]
    chartType: 'area'
    colors: ["green", "#38DD00", "#A6DD00", "#DDDC00", "#DD6e00", "#DD3800", "#DD0000"]
    plotOptions:
      area:
        lineWidth: 0
        stacking: 'normal'
        marker:
          enabled: false
  ,
    name: 'RPS by marker'
    targets: [
      metric: "%p.markers.*.RPS"
    ,
      metric: "%p.overall.RPS"
    ]
  ,
    name: 'Average response time by marker'
    targets: [
      metric: "%p.overall.avg_response_time"
      function: "aliasByNode(%m, 2)"
    ,
      metric: "%p.markers.*.avg_response_time"
      function: "aliasByNode(%m, 3)"
    ]
  ,
    name: 'HTTP codes'
    targets: [
      metric: "%p.overall.http_codes.*"
      function: "aliasByMetric(%m)"
    ]
    chartType: 'area'
    plotOptions:
      area:
        lineWidth: 0
        stacking: 'normal'
        marker:
          enabled: false
  ,
    name: 'NET codes'
    targets: [
      metric: "%p.overall.net_codes.*"
      function: "aliasByMetric(%m)"
    ]
    chartType: 'area'
    plotOptions:
      area:
        lineWidth: 0
        stacking: 'normal'
        marker:
          enabled: false
  ,
    name: 'Cumulative quantiles'
    targets: [
      metric: "%p.cumulative.quantiles.100_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.cumulative.quantiles.99_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.cumulative.quantiles.95_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.cumulative.quantiles.90_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.cumulative.quantiles.75_0"
      function: "aliasByMetric(%m)"
    ,
      metric: "%p.cumulative.quantiles.50_0"
      function: "aliasByMetric(%m)"
    ]
    chartType: 'area'
    colors: ["green", "#38DD00", "#A6DD00", "#DDDC00", "#DD6e00", "#DD3800", "#DD0000"]
    plotOptions:
      area:
        lineWidth: 0
        stacking: 'normal'
        marker:
          enabled: false
]

$(document).ready -> 
  $('.graphite-charts').each ->
    for template in templates
      template.chart = new charts.SingleIntervalChart(this, template)
      template.chart._update()