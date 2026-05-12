using CSV,DataFrames, Test
import MicroVisualisations as mv

const filename = "table1"


const HTML_PRE = """
<!DOCTYPE html>
<html lang='en-GB'>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta charset="UTF-8">
<title>A Budget for Scotland/Microsim API V1 Demo</title>
    <link rel="icon" href="images/favicon.ico?v=2.0.0" type="image/x-icon">
    <link rel="stylesheet" href="css/stb-bootstrap.css">

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.9.1/font/bootstrap-icons.css">

    <script src="https://cdn.jsdelivr.net/npm/d3@7.9.0/dist/d3.min.js"></script>

    <script src='js/jquery.js'></script>
    <script src='js/jquery.periodicalupdater.js'></script>
    <script src='js/jquery.validate.js'></script>
    <script src='js/jquery.number.js'></script>
    <!-- bootstrap -->
    <script src="js/bootstrap.bundle.js"></script>
    <!-- vega graphics -->
    <script src="js/vega-lite.min.js"></script>
    <script src="js/vega.js"></script>
    <script src="js/vega-embed.min.js"></script>
    <!-- templates -->
    <script src="js/mustache.min.js"></script>
    <!-- FIXME add colours in bootstrap -->
    <style>
    .bg-purple {background:#cdf;}
    .bg-orange {background:#fec;}
    .hover-highlight:hover {background: #eee}
    </style>
</head>
<body class='text-primary p-2'>

"""

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
sevcolsm = mv.bad_to_good_pallette( size(dfm)[1])

open( "tmp/$(filename).html", "w") do io
    println( io, HTML_PRE)
    hsc = "#" .* mv.hex.(sevcols)
    println( io, mv.format_crosstab(df, hsc, mv.MV_HTML()))
    hscm = "#" .* mv.hex.(sevcolsm)
    println( io, mv.format_crosstab( dfm, hscm, mv.MV_HTML() ))
    println( io, mv.format_gain_lose("gain lose by tenure", gl, mv.MV_HTML()))
    println( io, mv.format_std_short_costs( cf, mv.MV_HTML(); up_is_good=mv.COST_UP_GOOD, prec=0))
    println( io, mv.labelled_frame_to_table( cf , mv.MV_HTML(); prec=0))
    println( io, "</body></html>")
end

open( "tmp/$(filename).typ", "w") do io
    hsc = mv.rgb2typ.( sevcols )
    println( io, mv.format_crosstab(df, hsc, mv.MV_TYPST()))
    hscm = mv.rgb2typ.(sevcolsm)
    println( io, mv.format_crosstab( dfm, hscm, mv.MV_TYPST()))
    println( io, mv.format_gain_lose("gain lose by tenure", gl, mv.MV_TYPST()))
    println( io, mv.format_std_short_costs( cf, mv.MV_TYPST(); up_is_good=mv.COST_UP_GOOD, prec=0))
    println( io, mv.labelled_frame_to_table( cf, mv.MV_TYPST(); prec=0))
end

typst_command = `typst compile tmp/$(filename).typ`
run( typst_command )

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
