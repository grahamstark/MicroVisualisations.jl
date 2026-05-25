function generate_images( tmpdir, summary, results, settings, sys, bc1, bc2 )
    sg = mv.draw_summary_graphs( settings, results, summary )
    save( joinpath( tmpdir, "summary_graphs.svg"), sg )
    sg2 = mv.draw_summary_graphs_v2( settings, results, summary )
    save( joinpath( tmpdir, "summary_graphs-v2.svg"), sg2 )
    hbt = mv.draw_hbai_thumbnail( results, summary; title="HBAI Title", sysno=2, measure=Symbol(settings.ineq_income_measure), colours=mv.POST_COLOURS)
    save( joinpath( tmpdir, "hbai-thumbnail.svg"), hbt )
    hbc = mv.draw_hbai_graphs( settings, results, summary )
    save( joinpath( tmpdir, "hbai.svg"), hbc )
    metg = mv.draw_metrs( settings, results )
    save( joinpath( tmpdir, "metg.svg"), metg )
    tg = mv.draw_taxable_graph( settings, results, summary, [sys[1],sys[2]] )
    save( joinpath( tmpdir, "taxable_graph.svg"), tg )
    metg2 = mv.draw_metrs2( settings, results )
    save( joinpath( tmpdir, "metg2.svg"), metg2 )
    for tn in [false,true]
        tns = tn ? "-thumbnail" : ""
        bcp = mv.draw_bc( settings, "BC Test", bc1, bc2, thumbnail=tn )
        save( joinpath( tmpdir, "bcp$(tns).svg"), bcp )
        lc = mv.draw_lorenz_curve( summary.quantiles[1][:,1], summary.quantiles[1][:,2], summary.quantiles[2][:,2]; thumbnail=tn )
        save( joinpath( tmpdir, "lorenz-curve$(tns).svg"), lc )
        dc = mv.draw_deciles_barplot( summary; row=1, col=1, thumbnail=tn )
        save( joinpath( tmpdir, "deciles-barplot$(tns).svg"), dc )
        mh = mv.draw_metrs_hist( results; thumbnail=tn)
        save( joinpath( tmpdir, "metrs-hist$(tns).svg"), mh )
    end
end

function generate_html( tmpdir, summary, results, settings, sys, bc1, bc2 )
    io = open( joinpath( tmpdir, "main-output.html"), "w")
    html = mv.MV_HTML()
    println(io,
""""
    <html>
    <head>
        <link rel="icon" href="https://conjoint.virtual-worlds.scot/images/favicon.png">
        <link rel="stylesheet" href="https://conjoint.virtual-worlds.scot/css/bisite-bootstrap.css"/>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.9.1/font/bootstrap-icons.css"/>
        <script type='text/javascript' src='https://conjoint.virtual-worlds.scot/js/jquery.js'></script>
        <script type='text/javascript' src='https://conjoint.virtual-worlds.scot/js/jquery.periodicalupdater.js'></script>
        <script type='text/javascript' src='https://conjoint.virtual-worlds.scot/js/jquery.validate.js'></script>
    </head>
    <body>
""")


    println( io, "<img src='summary_graphs.svg'/>");
    println( io, "<img src='summary_graphs-v2.svg'/>");
    println( io, "<img src='taxable_graph.svg'/>");
    println( io, "<img src='hbai-thumbnail.svg'/>");
    println( io, "<img src='hbai.svg'/>");
    println( io, "<img src='metg.svg'/>");
    println( io, "<img src='metg2.svg'/>");
    for tn in [false,true]
        tns = tn ? "-thumbnail" : ""
        println( io, "<img src='bcp$(tns).svg'/>");
        println( io, "<img src='lorenz-curve$(tns).svg'/>");
        println( io, "<img src='deciles-barplot$(tns).svg'/>");
        println( io, "<img src='metrs-hist$(tns).svg'/>");
    end
    println( io, "<h2>Costs Headlines</h2>\n", mv.format_overall_cost(
        summary.income_summary[1],
        summary.income_summary[2],
        html ) )
    println( io, "<h2>Costs Summary</h2>\n", mv.format_costs_table(
        summary.income_summary[1],
        summary.income_summary[2],
        html ))
    println( io, "<h2>Budget Constraint 1</h2>\n", mv.format_bc( "BC 1", bc1, html ))
    println( io, "<h2>Budget Constraint 2</h2>\n", mv.format_bc( "BC 2", bc2, html ))
    println( io, "<h2>Gainlose example</h2>\n", mv.format_gain_lose("By Household Size",summary.gain_lose[2].hhtype_gl, html ))
    println( io, "<h2>SFC Behavour Correction</h2>\n", mv.format_sfc("SFC Behavioral Corrections", results.behavioural_results[2], html))
    println( io, "<h2>Gain/Lose Summary</h2>\n", mv.format_gain_lose_table_v2( summary.gain_lose[2], html ))
    # TODO println( io, "<h2>Format HH Summary</h2>\n", format_hh_summary( hh ))
    println( io, "<h2>Inequality Summary</h2>\n", mv.format_ineq_table(
        summary.inequality[1],
        summary.inequality[2],
        html))
    println( io, "<h2>METRs Table</h2>\n", mv.format_mr_table( summary.metrs[1], summary.metrs[2], html ))
    # TODO println( io, format_pers_inc_table( results ))
    println( io, "<h2>Poverty Table</h2>\n", mv.format_pov_table(
        summary.poverty[1],
        summary.poverty[2],
        summary.child_poverty[1],
        summary.child_poverty[2],
        html ))
    println( io, "<h2>Poverty Transitions</h2>\n", mv.format_pov_transitions( summary.povtrans_matrix_df[2], html ))
    println( io, "<h2>MR Transitions</h2>\n", mv.format_mr_transitions( summary.metrs[2].transmat_df, html ))
    println( io, "<h2>Run Settings</h2>\n", mv.format_run_settings_summary( settings, html ))
    println( io, "</body></html>")
    println( io, "<h2>Main Costs</h2>\n", mv.format_detailed_costs(
            summary.income_summary[1],
            summary.income_summary[2],
            html ))
    close(io)

end

function generate_typst( tmpdir, summary, results, settings, sys, bc1, bc2 )
    typst = mv.MV_TYPST()
    dt = Dates.format(now(),"e d/u/Y, H:M")
    bcc1 = mv.format_bc( "BC 1", bc1, typst )
    bcc2 = mv.format_bc( "BC 2", bc2, typst )
    open( joinpath( tmpdir, "main-output.typ"), "w") do io
#import "@preview/toffee-tufte:0.1.1": *
    println(io, """

#import "@preview/toffee-tufte:0.1.1": *
#show: template.with(
  title: [Run Results Summary],
  authors: "Graham Stark",
  date: "$dt",
  // toc: true,
  // full: true,
  abstract: [Summary of ScotBen run of $(dt)  ],
  // bib: bibliography("main.bib"),
)

#let table_fonts = ("BellCentennial LT Address","Arial Narrow")
#show figure.caption: set text( size:6pt, fill:rgb("#444466"))
#show table.cell: set text( size:6pt, font:table_fonts )
#let grey = rgb("#dddddd") // bug in prettytables 2nd header

#sidenote(dy: 1.5em, numbered: false)[#outline(depth: 2)]

= Main Results <sec:main-results>
== Marginal Rates <sec:mrs>
== Budget Constraints")

#figure(
    image("bcp.svg"),
    caption: [This is a Budget Constraint Normal version.])

#pagebreak(weak:true)
#sidenote[
    #figure(
        image("bcp.svg"),
        caption: [This is a Budget Constraint Sidenote version.]
        )]
#grid(
    columns: (50%, 50%),
    grid.cell()[$(bcc1)],
    grid.cell()[$(bcc2)])

#wideblock[
    #figure(caption:"A caption")[
    $(bcc1)
    ]
]

#figure(
  image("summary_graphs.svg"))

#figure(
    image("taxable_graph.svg"),
    caption: "Taxable Incomes")

#figure(
    image("hbai.svg"),
    caption: "Disposable Incomes")

#figure(image( "metg.svg"),caption:"MRs")

#figure(image( "lorenz-curve.svg"), caption:"Lorenz Curves")

#figure( image("deciles-barplot.svg"), caption:"Deciles")

#figure( image("metrs-hist.svg"), caption:"Disposable Incomes")

#sidenote[
    $bcc2
]

#wideblock[
    #figure(caption: "A table of MRs")[
        $(mv.format_mr_transitions( summary.metrs[2].transmat_df, typst ))
    ]
]

== Gainers and Losers

#figure( caption: "Gainers & Losers by Household Tenure (counts of people)")[
    $(mv.format_gain_lose("By Tenure",summary.gain_lose[2].ten_gl, typst  ))]

#figure( caption: "Gainers & Losers by Number of People in the Household (counts of people)")[
    $(mv.format_gain_lose("By Household Size",summary.gain_lose[2].hhtype_gl, typst  ))]

#figure( caption: "Gainers & Losers by Income Decile (counts of people)")[
    $(mv.format_gain_lose("By Decile",summary.gain_lose[2].dec_gl, typst  ))]

#figure( caption: "Gainers & Losers by Number of Children in the Household (counts of all people in the household)")[
    $(mv.format_gain_lose("By Number of Children",summary.gain_lose[2].children_gl, typst  ))]

== SFC Behavour Correction

$(mv.format_sfc("SFC Behavioral Corrections", results.behavioural_results[2], typst ))

== Inequality Summary

$(mv.format_ineq_table(
    summary.inequality[1],
    summary.inequality[2],
    typst))

== Poverty
=== Summary
$(mv.format_pov_table(
    summary.poverty[1],
    summary.poverty[2],
    summary.child_poverty[1],
    summary.child_poverty[2],
    typst ))

=== Transitions

$(mv.format_pov_transitions( summary.povtrans_matrix_df[2], typst ))

""")
    #=
    # TODO println( io, "<h2>Format HH Summary</h2>\n", format_hh_summary( hh ))
    println( io, "
    println( io, "<h2>METRs Table</h2>\n", mv.format_mr_table( summary.metrs[1], summary.metrs[2], html ))
    # TODO println( io, format_pers_inc_table( results ))
    println( io,
    println( io, "<h2>Poverty Transitions</h2>\n", mv.format_pov_transitions( summary.povtrans_matrix_df[2], html ))
    println( io, "<h2>MR Transitions</h2>\n", mv.format_mr_transitions( summary.metrs[2].transmat_df, html ))
    println( io, "<h2>Run Settings</h2>\n", mv.format_run_settings_summary( settings, html ))
    println( io, "</body></html>")
    println( io, "<"<h2>Poverty Table</h2>\n", mv.format_pov_table(
    summary.poverty[1],
    summary.poverty[2],
    summary.child_poverty[1],
    summary.child_poverty[2],
    html ))h2>Main Costs</h2>\n", mv.format_detailed_costs(
    =#


    end # do block
end
