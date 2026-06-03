

using CairoMakie
using DataFrames,CSV, Dates
using Observables
using Random
using Test
using BudgetConstraints

import MicroVisualisations as mv

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
include( "generation-functions.jl")
# save your tests here.

summary, results, settings, sys = do_dummy_run()

hh = FRSHouseholdGetter.get_household(100)
# hh = examples[3]
wage = 20.0
bc1, bc2 = getbc( settings, hh, sys[1], sys[2], wage )

@testset "test_complete" begin
    html_tabs = construct_tables( settings, results, summary, mv.MV_HTML())
    typst_tabs = construct_tables( settings, results, summary, mv.MV_TYPST())
    println( "tabs OK")
    graphs = construct_images( settings, results, summary, sys )
    println( "graphs OK")
    path, zippath = mv.phunpackify( settings, graphs, typst_tabs, html_tabs, summary )
end
