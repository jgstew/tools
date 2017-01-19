// https://bigfix.me/relevance/details/3019241#comments
// http://nvd3.org/examples/pie.html
// https://codepen.io/MeredithU/pen/LVVoNE
    nv.addGraph(function() {
        var chart = nv.models.pieChart()
            .x(function(d) { return d.label })
            .y(function(d) { return d.value })
            .showLabels(true)
            .showLegend(false);

        d3.select("#chart svg")
            .datum( <?Relevance ("[ " & it & " ]") of concatenations ", " of (html it) of ("{ %22label%22: %22" & item 0 of it & "%22, %22value%22: " & item 1 of it as string & " }") of ( ( "Globally Hidden", number of bes fixlets whose(not globally visible flag of it) );( "Locally Hidden", number of bes fixlets whose(not locally visible flag of it) ) ) ?> )
            .transition().duration(300)
            .call(chart);

        return chart;
    });
