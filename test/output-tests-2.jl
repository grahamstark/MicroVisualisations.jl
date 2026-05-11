using CSV,DataFrames, Test
import MicroVisualisations as mv

const filename = "table1"

dfm = CSV.File( "sample_output/metrs-transition-matrix-df-2.csv")|>DataFrame
dfm = mv.reverse_crosstab( dfm ) # bad -> good for MRs
dfm = mv.fixup_transitions_matrix( dfm )
df = CSV.File( "sample_output/poverty-transition-matrix-2-vs-1.csv")|>DataFrame
df = mv.fixup_transitions_matrix( df )
gl = CSV.File( "sample_output/gain-lose-by-tenure-2-vs-1.csv")|>DataFrame
incs1 = CSV.File( "sample_output/income_summary_1.csv")|>DataFrame
incs2 = CSV.File( "sample_output/income_summary_2.csv")|>DataFrame
cf = mv.costs_dataframe( incs1, incs2 )

sevcols = mv.bad_to_good_pallette( size(df)[1])

open( "tmp/$(filename).html", "w") do io
    hsc = "#" .* mv.hex.(sevcols)
    println( io, mv.format_crosstab(df, hsc, mv.MV_HTML()))
end

open( "tmp/$(filename).typ", "w") do io
    hsc = mv.rgb2typ.( sevcols )
    println( io, mv.format_crosstab(df, hsc, mv.MV_TYPST()))
end

@testset "New Table out via PrettyTables" begin


end

#=
    open( "tmp/$(filename).typ", "w") do io
        sevcols = TransTables.bad_to_good_pallette( size(df)[1])
        hsc = TypstTabs.rgb2typ.( sevcols )
        println( io, TypstTabs.format_crosstab(df, hsc ))
        sevcols = TransTables.bad_to_good_pallette( size(dfm)[1])
        hsc = TypstTabs.rgb2typ.( sevcols )
        println( io, TypstTabs.format_crosstab( dfm, hsc ))
        println(io, TypstTabs.format_gl( "Gain-Lose by Tenure", gl ))
        println( io, TypstTabs.frame_to_table( cf; prec=0, up_is_good=MicroVisualisations.COST_UP_GOOD ))
        println( io, TypstTabs.labelled_frame_to_table( cf ))

    end
    typst_command = `typst compile tmp/$(filename).typ`
    run( typst_command )

    open( "tmp/$(filename).html", "w") do io
        println(io, HTMLTabs.HTML_PRE)
        sevcols = TransTables.bad_to_good_pallette( size(df)[1])
        hsc = "#" .* hex.(sevcols)
        println( io, HTMLTabs.format_crosstab(df, hsc ))
        sevcols = TransTables.bad_to_good_pallette( size(dfm)[1])
        hsc = "#" .* hex.(sevcols)
        println( io, HTMLTabs.format_crosstab( dfm, hsc ))
        println( io, HTMLTabs.format_gl( "Gain-Lose by Tenure", gl ))
        println( io, HTMLTabs.frame_to_table( cf; prec=0, up_is_good=MicroVisualisations.COST_UP_GOOD ))
        println( io, HTMLTabs.labelled_frame_to_table( cf ))
        println( io, "</body></html>")
    end
=#
