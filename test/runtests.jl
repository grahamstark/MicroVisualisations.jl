
using Observables
using Test
using CairoMakie
using DataFrames,CSV, Dates

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
tmpdir = tempdir()
summary, results, settings, sys = do_dummy_run()
hh = FRSHouseholdGetter.get_household(100)
# hh = examples[3]
wage = 20.0
bc1, bc2 = getbc( settings, hh, sys[1], sys[2], wage )

@testset "generate all" begin
    generate_images( tmpdir, summary, results, settings, sys, bc1, bc2 )
    generate_html( tmpdir, summary, results, settings, sys, bc1, bc2 )
    generate_typst( tmpdir, summary, results, settings, sys, bc1, bc2 )
end

#=
    images = mv.construct_images( settings, results, summary, sys )
    htmls = mv.construct_tables( settings, results, summary, html )
    typsts = mv.construct_tables( settings, results, summary, mv.MV_TYPST() )
    @show images
    @show htmls
    @show typsts
    summary_strings = mv.format_headline_numbers( summary.headline_figures[2] )
    @show summary_strings

    open( joinpath( tmpdir, "main-output.typ"), "w") do io
    headlinesjs = mv.format_headline_numbers( summary.headline_figures[2] )
    println(io, headlinesjs )
    end

=#
