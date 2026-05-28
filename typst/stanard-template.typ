#import "@preview/grape-suite:4.0.0": seminar-paper

#show: seminar-paper.project.with(
    title: "MS THING",
    author: "GS",
    email: "gs@vw" )


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
    #figure(
        image("bcp.svg"),
        caption: [This is a Budget Constraint Sidenote version.]
        )]
#grid(
    columns: (50%, 50%),
    grid.cell()[$(bcc1)],
    grid.cell()[$(bcc2)])

    #figure(caption:"A caption")[
    $(bcc1)]
]

#figure(
  image( "summary_graphs.svg" ))

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

    #figure(caption: "A table of MRs")[
        $(mv.format_mr_transitions( summary.metrs[2].transmat_df, typst ))
    ]


== Costs

overall_cost_table
costs_table

== Gainers and Losers

#figure( caption: "Gainers & Losers: Summary (counts of people)")[#include("gain_lose_summary.typ")]

#figure( caption: "Gainers & Losers by Household Tenure (counts of people)")[#include("ten_gl.typ")]

#figure( caption: "Gainers & Losers by Number of People in the Household (counts of people)")[#include("hhtype_gl.typ")]

#figure( caption: "Gainers & Losers by Income Decile (counts of people)")[#include("dec_gl.typ")]

#figure( caption: "Gainers & Losers by Number of Children in the Household (counts of all people in the household)")[#include("dec_gl.typ")]

== SFC Behavour Correction

#figure( caption: "SFC Thing")[#include("sfc.typ")]

metrs_table
metrs_transitions

=== Poverty

poverty_summary
poverty_transitions
run_settings_summary

== Inequality Summary

#figure( caption: "Inequality Summary")[#include( "inequality_summary.typ")]

