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
using DataStructures
using Dates
using Format
using CairoMakie
using Images: load
using Markdown
using Observables
using StatsBase
using PrettyTables
using Preferences
using Typstry


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
    construct_tables,
    run_settings_to_df,
    construct_images,
    AVAILABLE_GRAPHS,
    AVAILABLE_TABLES

include( "misc-constants.jl")
include( "tables-common.jl")
include( "standard-formats.jl")
include( "gen-functions.jl")

include( "summary-dataframe-conversions.jl")
include( "html-tables.jl")
include( "typst-tables.jl")

include( "table-generation.jl")
include( "graphics-generation.jl")
include( "other-formats-generation.jl")

function __init__()
    CairoMakie.activate!(type = "svg")
end 

# TODO
# include( "examples.jl")

end
