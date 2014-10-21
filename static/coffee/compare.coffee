charts = require "./graphite-charts.coffee"

templates = [
  name: 'RPS',
  metric: "one_sec.yandex_tank.overall.RPS"
]

$(document).ready -> 
  $chartsContainer = $('.graphite-charts')
  graphiteOptions = $chartsContainer.data "graphite"

  for template in templates
    template.chart = new charts.MultiIntervalChart($chartsContainer, template, graphiteOptions)
    template.chart._update()

