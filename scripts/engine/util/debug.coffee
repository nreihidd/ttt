window.debugInfo = {}
    
$( ->
    $spans = {};
    values = {};
    $container = $("#debug-info");
    refreshDebugInfo = ->
        for label of debugInfo
            str = debugInfo[label]
            if not (label of $spans)
                $block = $("<div><div class='label'>" + label + "</div><div class='value'></div></div>")
                $span = $block.find('.value')
                $spans[label] = $span
                $block.appendTo($container)
            if str isnt values[label]
                values[label] = str
                $spans[label].text(values[label])
    
    window.setInterval(refreshDebugInfo, 100)
)