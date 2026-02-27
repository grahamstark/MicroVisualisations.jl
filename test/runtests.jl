
using Observables
using Test
using CairoMakie
using DataFrames,CSV, Dates

using BudgetConstraints
using MicroVisualisations

using ScottishTaxBenefitModel

using .BCCalcs
using .Definitions
using .ExampleHelpers
using .ExampleHouseholdGetter
using .FRSHouseholdGetter: initialise, get_household, get_num_households
using .ModelHousehold
using .Monitor
using .Results
using .RunSettings
using .Runner
using .STBOutput
using .STBParameters
using .Utils

include( "runner-functions.jl")

@testset "MicroVisualisations.jl" begin
    # save your tests here.
    tmpdir = tempdir()

    summary, results, settings, sys = do_dummy_run()
    io = open( joinpath( tmpdir, "main-output.html"), "w")
    println(io,
""""
    <html>
    <head>

        <link rel="icon" href="https://triplepc.northumbria.ac.uk/images/favicon.png">
        <link rel="stylesheet" href="https://triplepc.northumbria.ac.uk/css/bisite-bootstrap.css"/>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.9.1/font/bootstrap-icons.css"/>
        <script type='text/javascript' src='https://triplepc.northumbria.ac.uk/js/jquery.js'></script>
        <script type='text/javascript' src='https://triplepc.northumbria.ac.uk/js/jquery.periodicalupdater.js'></script>
        <script type='text/javascript' src='https://triplepc.northumbria.ac.uk/js/jquery.validate.js'></script>

    </head>
    <body>
""")
    hh = FRSHouseholdGetter.get_household(100)
    # hh = examples[3]
    wage = 20.0
    bc1, bc2 = getbc( settings, hh, sys[1], sys[2], wage )
    sg = draw_summary_graphs( settings, results, summary )
    save( joinpath( tmpdir, "summary_graphs.svg"), sg )
    println( io, "<img src='summary_graphs.svg'/>");

    sg2 = draw_summary_graphs_v2( settings, results, summary )
    save( joinpath( tmpdir, "summary_graphs-v2.svg"), sg2 )
    println( io, "<img src='summary_graphs-v2.svg'/>");

    tg = draw_taxable_graph( settings, results, summary, [sys[1],sys[2]] )
    save( joinpath( tmpdir, "taxable_graph.svg"), tg )
    println( io, "<img src='taxable_graph.svg'/>");

    hbt = draw_hbai_thumbnail( results, summary; title="HBAI Title", sysno=2, measure=Symbol(settings.ineq_income_measure), colours=POST_COLOURS)
    save( joinpath( tmpdir, "hbai-thumbnail.svg"), hbt )
    println( io, "<img src='hbai-thumbnail.svg'/>");

    hbc = draw_hbai_graphs( settings, results, summary )
    save( joinpath( tmpdir, "hbai.svg"), hbc )
    println( io, "<img src='hbai.svg'/>");


    for tn in [false,true]
        tns = tn ? "-thumbnail" : ""
        bcp = draw_bc( settings, "BC Test", bc1, bc2, thumbnail=tn )
        save( joinpath( tmpdir, "bcp$(tns).svg"), bcp )
        println( io, "<img src='bcp$(tns).svg'/>");

        lc = draw_lorenz_curve( summary.quantiles[1][:,1], summary.quantiles[1][:,2], summary.quantiles[2][:,2]; thumbnail=tn )
        save( joinpath( tmpdir, "lorenz-curve$(tns).svg"), lc )
        println( io, "<img src='lorenz-curve$(tns).svg'/>");

        dc = draw_deciles_barplot( summary; row=1, col=1, thumbnail=tn )
        save( joinpath( tmpdir, "deciles-barplot$(tns).svg"), dc )
        println( io, "<img src='deciles-barplot$(tns).svg'/>");

        mh = draw_metrs_hist( results; thumbnail=tn)
        save( joinpath( tmpdir, "metrs-hist$(tns).svg"), mh )
        println( io, "<img src='metrs-hist$(tns).svg'/>");
    end

    println( io, "<h2>Costs Headlines</h2>\n", format_overall_cost(
        summary.income_summary[1],
        summary.income_summary[2]))
    println( io, "<h2>Costs Summary</h2>\n", format_costs_table(
        summary.income_summary[1],
        summary.income_summary[2]))
    println( io, "<h2>Budget Constraint 1</h2>\n", format_bc_df( "BC 1", bc1 ))
    println( io, "<h2>Budget Constraint 2</h2>\n", format_bc_df( "BC 2", bc2 ))
    println( io, "<h2>Gainlose example</h2>\n", format_gainlose("By Household Size",summary.gain_lose[2].hhtype_gl ))
    println( io, "<h2>SFC Behavour Correction</h2>\n", format_sfc("SFC Behavioral Corrections", results.behavioural_results[2]))
    println( io, "<h2>Gain/Lose Summary</h2>\n", format_gain_lose_table_v2( summary.gain_lose[2] ))
    println( io, "<h2>Format HH Summary</h2>\n", format_hh_summary( hh ))
    println( io, "<h2>Inequality Summary</h2>\n", format_ineq_table(
        summary.inequality[1],
        summary.inequality[2]))
    println( io, "<h2>METRs Table</h2>\n", format_mr_table( summary.metrs[1], summary.metrs[2] ))
    # println( io, format_pers_inc_table( results ))
    println( io, "<h2>Poverty Table</h2>\n", format_pov_table( summary.poverty[1],
        summary.poverty[2],
        summary.child_poverty[1],
        summary.child_poverty[2]))
    println( io, "<h2>Budget Transitions</h2>\n", format_pov_transitions( summary.povtrans_matrix[2]))
    println( io, "<h2>Run Settings</h2>\n", format_run_settings_summary( settings ))
    println( io, "</body></html>")
    println( io, "<h2>Main Costs</h2>\n", costs_frame_to_table(
            detailed_cost_dataframe(
                summary.income_summary[1],
                summary.income_summary[2] )))

    close(io)

    images = construct_images( settings, results, summary, sys )
    htmls = construct_html( settings, results, summary )
    @show images
    @show htmls
end
