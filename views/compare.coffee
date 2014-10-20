###
  Обьединенный график совмещающий разные таймлайны метрик графита на одной шкале
###
class UnitedGraphiteChart
  constructor: (@container, @template, @graphite) ->
    @container.attr 'title', @template.name

  _createTimeSeries: () ->
    ({
      name: item.target
      data: ([point[1] * 1000, point[0]] for point in item.datapoints)
    } for item in chart_data)
  _normalizeSeries: (series) ->
    now = +new Date
    for s in series
      start=s.data[0][0]
      s.data.forEach (p) -> p[0]=now+(p[0]-start)
      s
  _cropTimeSeries: (series) ->
    for s in series
      s.data = s.data.filter (p) => p[0] >= @params.startTime and p[0] <= @params.endTime
      s
  _hashToQueryString: (hash) ->
    ("#{key}=#{value}" for key, value of hash).join('&')
  _makeTarget: (target) ->
    metric = target.metric.replace('%p', @graphite.prefix)
    if target.function?
      metric = target.function.replace('%m', metric)
    return metric

  _getTargetData: (target) ->
    params =
      format: 'json'
      tz: 'Europe/Moscow'
      target: @_makeTarget target
      maxDataPoints: 500
      from: graphiteDateFormat(target.startTime)
      until: graphiteDateFormat(+endDate)
    qs = @_hashToQueryString params
    $.getJSON "http://#{@graphite.host}:#{@graphite.webPort}/render?#{qs}"

  _getGraphiteData: (callback) ->
    targetsCollected = 0
    totalTargets = @template.targets.length
    sumData=[]
    for target in @template.targets
      @_getTargetData target
        .done (data) ->
          sumData.push data[0]
          targetsCollected++
          if targetsCollected is totalTargets then callback sumData

  _update: ->
    @_getGraphiteData (data) =>
      @chart = new Highcharts.Chart
        title:
          text: @template.name
          x: -20
        xAxis:
          title:
            text: "Time"
          type: "datetime"
        yAxis:
          title:
            text: "Value"

          plotLines: [
            value: 0
            width: 1
            color: "#808080"
          ]

        tooltip:
          crosshairs: true

        chart:
          type: @template.chartType or 'spline'
          zoomType: 'xy'
          renderTo: $(@container)[0]

        plotOptions: @template.plotOptions or defaultPlotOptions
        colors: @template.colors or defaultColors

        legend:
          layout: "vertical"
          align: "center"
          verticalAlign: "bottom"
          borderWidth: 0

        series: @_normalizeSeries @_cropTimeSeries @_createTimeSeries(data)
      @chart.legendHide()

$(document).ready -> 
  $chartsContainer = $('.graphite-charts')
  graphiteOptions = $chartsContainer.data "graphite"
  templates = [
    name: 'RPS by marker',
    targets: [
      metric: "%p.overall.RPS"
    ]
  ]

  populateTargets = (target, reports) ->
    for r in reports
      _.extend _.clone(target), _.pick(r, ['startTime', 'endTime'])

    if err then callback err
    else
      for template in templates
        for target in template.targets
          target

  for template in templates
    $chart = $("<div/>").appendTo 
    template.chart = new GraphiteChart($chart, template, graphiteOptions)
    template.chart._update()