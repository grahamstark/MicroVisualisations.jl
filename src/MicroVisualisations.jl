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
using Random
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
    AVAILABLE_GRAPHS,
    AVAILABLE_OTHER_ITEMS,
    AVAILABLE_TABLES,
    MV_HTML,
    MV_MARKDOWN,
    MV_TYPST,
    construct_images,
    construct_tables,
    dump_images,
    dump_tables,
    format_headline_numbers,
    run_settings_to_df

const MICRO_DIR      = joinpath(dirname(pathof(MicroVisualisations)),".." )

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

#=
Write everything (except BCs.. ) into a working directory, generate PDFs of the typst bits create a zipfile of everything.
@return path to the zipfile and working directory
TODO: pdfs of individual tables are messed up; add directory of outputs, add BCs.
=#
function phunpackify(
    settings::Settings,
    graphics :: NamedTuple,
    typst_tables :: NamedTuple,
    html_tables :: NamedTuple,
    summary::NamedTuple )::Tuple
    path = joinpath(tempdir(), basiccensor( settings.run_name ), randstring(30))
    mkpath( path )
    # chdir( path )
    STBOutput.dump_summaries( path, settings, summary )
    dump_images( path, graphics )
    dump_tables( path, typst_tables, MV_TYPST())
    dump_tables( path, html_tables, MV_HTML())
    # each table to pdf via typst
    for (k,v) in pairs( typst_tables )
        tpath = joinpath( path, "$(k).typ" )
        cmd = TypstCommand( ["compile", tpath] )
        run(cmd)
    end
    # big standard output file
    mainout = joinpath( path, "main-output.typ")
    cp( joinpath( MICRO_DIR, "typst", "standard-template.typ"), mainout, force=true )
    cmd = TypstCommand(["compile", mainout] )
    run(cmd)
    zippath = joinpath( path, "alloutput.zip")
    z = ZipFile.Writer(zippath)
    for fp in readdir( path; join=true )
        f = open(fp, "r")
        content = read(f, String)
        close(f)
        zf = ZipFile.addfile(z, basename(fp));
        write(zf, content)
    end
    close(z)
    return path, zippath
end

function __init__()
    CairoMakie.activate!(type = "svg")
end 

# TODO
# include( "examples.jl")

end
