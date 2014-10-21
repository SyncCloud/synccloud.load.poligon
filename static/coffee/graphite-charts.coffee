defaultColors = ["#E67117","#8F623F","#6D3103","#F9AA6D","#F9CFB0","#E69717","#8F713F","#6D4403","#F9C36D","#F9DDB0","#1A5197","#2E435E","#032148","#6FA3E5","#A8C2E5","#0E8D84","#275855","#02433E","#63E3D9","#A0E3DE"]
defaultPlotOptions = 
  spline:
    lineWidth: 2
    states:
      hover:
        lineWidth: 4
    marker:
      enabled: false

((Highcharts, UNDEFINED) ->
  return  unless Highcharts
  chartProto = Highcharts.Chart::
  legendProto = Highcharts.Legend::
  Highcharts.extend chartProto,
    legendSetVisibility: (display) ->
      chart = this
      legend = chart.legend
      legendAllItems = undefined
      legendAllItem = undefined
      legendAllItemLength = undefined
      legendOptions = chart.options.legend
      scroller = undefined
      extremes = undefined
      return  if legendOptions.enabled is display
      legendOptions.enabled = display
      unless display
        legendProto.destroy.call legend
        # fix for ex-rendered items - so they will be re-rendered if needed
        legendAllItems = legend.allItems
        if legendAllItems
          legendAllItem = 0
          legendAllItemLength = legendAllItems.length

          while legendAllItem < legendAllItemLength
            legendAllItems[legendAllItem].legendItem = UNDEFINED
            ++legendAllItem
        # fix for chart.endResize-eventListener and legend.positionCheckboxes()
        legend.group = {}
      chartProto.render.call chart
      unless legendOptions.floating
        scroller = chart.scroller
        if scroller and scroller.render
          # fix scrolller // @see renderScroller() in Highcharts
          extremes = chart.xAxis[0].getExtremes()
          scroller.render extremes.min, extremes.max
      return
    legendHide: ->
      @legendSetVisibility false
      return
    legendShow: ->
      @legendSetVisibility true
      return
    legendToggle: ->
      @legendSetVisibility @options.legend.enabled ^ true
      return

  return
) Highcharts

Number::twoDigit = () ->
  if @ <= 9 then '0'+@ else @+''

graphiteDateFormat = (timestamp) ->
  dt = new Date timestamp
  dt.setHours dt.getHours()-4
  "#{dt.getHours().twoDigit()}:#{dt.getMinutes().twoDigit()}_#{dt.getFullYear()}#{(dt.getMonth()+1).twoDigit()}#{dt.getDate().twoDigit()}"

###
  График для разных метрик совпадающих по временной шкале
###
class GraphiteChart
  constructor: (parentContainer, @template) ->
    @container = $('<div />',
      title: @template.name
    )
    chartGroup = $('<div />')
    @container.appendTo chartGroup
    chartGroup.appendTo parentContainer
    @params = $(parentContainer).data()
    endDate = new Date @params.endTime
    endDate.setMinutes endDate.getMinutes()+1
    @options = {
      format: 'json'
      tz: 'Europe/Moscow'
      maxDataPoints: 500
      from: graphiteDateFormat(@params.startTime)
      until: graphiteDateFormat(+endDate)
    }
  _makeOptions: ->
    ("#{key}=#{value}" for key, value of @options).join('&')
  _createTimeSeries: (chart_data) ->
    ({
      name: item.target
      data: ([point[1] * 1000, point[0]] for point in item.datapoints)
    } for item in chart_data)
  _cropTimeSeries: (series) ->
    for s in series
      s.data = s.data.filter (p) => p[0] >= @params.startTime and p[0] <= @params.endTime
      s
  _makeTarget: (target) ->
    metric = target.metric.replace('%p', @params.prefix)
    if target.function?
      metric = target.function.replace('%m', metric)
    return metric
  _query: ->
    ("target=#{@_makeTarget(target)}" for target in @template.targets).join('&') + '&' + @_makeOptions()
  _update: ->
    link = "http://#{@params.host}:#{@params.webPort}/render?#{@_query()}"
    $(@container).attr('src', link)
    $.ajax(link).done (data) =>
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

        series: @_cropTimeSeries @_createTimeSeries(data)
      @chart.legendHide()

###
  График по одной метрике с разными интервалами
###
class UnitedGraphiteChart
  constructor: ($parent, @template) ->
    @container = $('<div />').appendTo $parent
    @container.attr 'title', @template.name
    @graphite = $parent.data "graphite"
    @targets = $parent.data "targets"

  _createTimeSeries: (chart_data) ->
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
    # metric = target.metric.replace('%p', @graphite.prefix)
    if target.function?
      metric = target.function.replace('%m', metric)
    return metric

  _getTargetData: (target) ->
    endTime = new Date target.endTimestamp
    endTime.setMinutes endTime.getMinutes()+1
    params =
      format: 'json'
      tz: 'Europe/Moscow'
      target: "alias(#{@template.metric}, '#{target.name}')"
      maxDataPoints: 500
      from: graphiteDateFormat(target.startTimestamp)
      until: graphiteDateFormat(+endTime)
    qs = @_hashToQueryString params
    $.getJSON "http://#{@graphite.host}:#{@graphite.webPort}/render?#{qs}"

  _getGraphiteData: (callback) ->
    targetsCollected = 0
    totalTargets = @targets.length
    sumData=[]
    for target in @targets
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

        series: @_normalizeSeries @_createTimeSeries(data)
      @chart.legendHide()

module.exports =
  SingleIntervalChart: GraphiteChart
  MultiIntervalChart: UnitedGraphiteChart
