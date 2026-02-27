module MicroVisualisations
#=


=#
using Markdown
using UUIDs
using ZipFile

using ArgCheck
using Colors
using CSV
using DataFrames
using Dates
using Format
using CairoMakie
using Images: load
using Observables
using StatsBase
using PrettyTables
using Preferences
using Markdown

using BudgetConstraints
using PovertyAndInequalityMeasures

using ScottishTaxBenefitModel

using ScottishTaxBenefitModel.BCCalcs
using ScottishTaxBenefitModel.Definitions
using ScottishTaxBenefitModel.Definitions
using ScottishTaxBenefitModel.ExampleHelpers
using ScottishTaxBenefitModel.ExampleHouseholdGetter
using ScottishTaxBenefitModel.GeneralTaxComponents
using ScottishTaxBenefitModel.ModelHousehold
using ScottishTaxBenefitModel.HTMLLibs

using ScottishTaxBenefitModel.Monitor
using ScottishTaxBenefitModel.Results
using ScottishTaxBenefitModel.Runner
using ScottishTaxBenefitModel.RunSettings
using ScottishTaxBenefitModel.SimplePovertyCounts
using ScottishTaxBenefitModel.SingleHouseholdCalculations
using ScottishTaxBenefitModel.STBIncomes
using ScottishTaxBenefitModel.STBOutput
using ScottishTaxBenefitModel.STBParameters
using ScottishTaxBenefitModel.Utils
using ScottishTaxBenefitModel.Weighting

export
      PRE_COLOUR,
      POST_COLOUR,
      PRE_COLOURS,
      POST_COLOURS,
      costs_frame_to_table,
      detailed_cost_dataframe,
      draw_bc,
      draw_deciles_barplot,
      draw_hbai_thumbnail,
      draw_hbai_graphs,
      draw_incomes_vs_bands,
      draw_lorenz_curve,
      draw_summary_graphs,
      draw_summary_graphs_v2,
      draw_tax_rates,
      draw_taxable_graph,
      fig_to_svg_string,
      format_bc_df,
      format_bc_df,
      format_costs_table,
      format_gain_lose_table_v2,
      format_gainlose,
      format_hh_summary,
      format_ineq_table,
      format_mr_table,
      format_overall_cost,
      format_pers_inc_table,
      format_pov_table,
      format_pov_transitions,
      format_run_settings_summary,
      format_sfc,
      make_example_card,
      make_popups,
      make_short_summary

include( "examples.jl")
include( "display_constants.jl")
include( "standard-formats.jl")
include( "graphics.jl")
include( "gen-functions.jl")
include( "table_libs.jl")
include( "text_html_libs.jl")

function __init__()
    CairoMakie.activate!(type = "svg")
end 

end
