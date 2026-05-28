#set text(font:"Palatino Linotype")
#set heading(numbering:"1.")
#set page(numbering: "1 of 1")
#let fixed(term, color: rgb(20,90,90)) = {
  set text(color, font: "JuliaMono", size:9pt)
  [#term]
}
#show heading: set text(rgb(50,50,100), font:"Gill Sans" )
#show link: underline
#show link: set text(blue)

#let table_fonts = ("BellCentennial LT Address","Arial")
#show figure.caption: set text( size:6pt, fill:rgb("#444466"))
#show table. cell: set text( size:6pt, font:table_fonts )

= Main Results<sec:main-results>

#include("overall_cost_table.typ")

#figure(
  image( "summary_graphs.svg" ))

#figure( image("metrs-hist.svg"), caption:"Disposable Incomes")

== Costs

#figure( caption: "estimated costs in £m p.a 2026/7")[ #include("costs_table.typ")]

== Gainers and Losers<sec:gainlose>

#figure( image("deciles-barplot.svg"), caption:"Deciles")

#figure( caption: "Gainers & Losers: Summary (counts of people)")[#include("gain_lose_summary.typ")]

#figure( caption: "Gainers & Losers by Household Tenure (counts of people)")[#include("ten_gl.typ")]

#figure( caption: "Gainers & Losers by Number of People in the Household (counts of people)")[#include("hhtype_gl.typ")]

#figure( caption: "Gainers & Losers by Income Decile (counts of people)")[#include("dec_gl.typ")]

#figure( caption: "Gainers & Losers by Number of Children in the Household (counts of all people in the household)")[#include("dec_gl.typ")]

== Work Incentives<sec:work-incentives>

#figure(image( "metg.svg"),caption:"MRs")

#figure( caption: "METRS")[
   #include("metrs_table.typ")
]

#figure( caption: "METRS Transitions")[
   #include("metrs_transitions.typ")
]

== Poverty<sec:poverty>

#figure(
    image("hbai.svg"),
    caption: "Disposable Incomes")

#figure( caption: "Poverty summary")[
   #include("poverty_summary.typ")
]

#figure( caption: "Poverty Transitions, using Equivalised BHC Incomes")[
   #include("poverty_transitions.typ")
]

== Inequality<sec:inequality>

#figure(image( "lorenz-curve.svg"), caption:"Lorenz Curves")

#figure( caption: "Inequality Summary")[#include( "inequality_summary.typ")]


== Income Tax<sec:income-tax>

#figure(
    image("taxable_graph.svg"),
    caption: "Taxable Incomes")


#figure( caption: "SFC Behavioural Correction")[
   #include("sfc.typ")
]

== Budget Constraints<sec:budget-constraints>

#figure(
    image("bcp.svg"),
    caption: [This is a Budget Constraint.])

== Run Settings<sec:run-settings>

#figure( caption: "Key Run Assumptions ")[#include( "run_settings_summary.typ")]

