#=

trials rather than tests

=#
module TransTables

using Format,DataFrames,Colors,ArgCheck

using ScottishTaxBenefitModel
using .STBOutput, .Utils

export labels,midstring,COL_LABELS,rgbstr,sevcols,fm,makedf, BG_WHITE, BG_BLACK, BG_NEUTRAL, BG_WORSEN, BG_IMPROVE, fmt_gl, make_labels, rename_cols

struct HTML end
struct TYPST end
struct MARKDOWN end

const FONT = "BellCentennial LT Address"

const labels = ["V.Deep (<=30%)",
              "Deep (<=40%)",
              "In Poverty (<=60%)",
              "Near Poverty (<=80%)",
              "Not in Poverty",
             "Total"]

"""
midstring("hello",7) -> ["","","","hello","","",""] - for filling labels in crosstabs.
"""
function midstring(s,len)
    l1 = len÷2
    l2 = len - l1 - 1
    r = [fill("",l1)...,s,fill("",l2)...]
    @assert length(r) == len "length(r) $(length(r)) != len=$len "
    return r
end

const GL_RENAMES = Dict([
    "population"=>"Population, 000s",
    "avch" => "Avg. Change £pw",
    "pct_change"=> "% Change",
    "total_transfer" => "Total Transfer £m p.a"] )

function rename_cols( colnames )
    n = length( colnames )
    newnames = fill("",n)
    for c in 2:n
        newnames[c] = get( GL_RENAMES, colnames[c], colnames[c])
    end
    return newnames
end


"""
Make the row, col labels we actually need for a crosstab from a set of labels, e.g:

make_labels( "Hello", ["col1","col2"]) -> ( ["","","Hello",""], ["","","col1","col2"])
"""
function make_labels( title :: AbstractString, labels :: AbstractVector )::Tuple
    n = length( labels ) + 2
    return midstring( title, n ), ["","",labels...]
end

# two sets of labels
const COL_LABELS = make_labels( "Before", labels )

"""
Typst colo[u]r string from a css colo[u]r e.g.:

TransTables.rgbstr( "#cc0823") -> "rgb( 80%, 3%, 14%)"
"""
function rgbstr( hex :: String )::String

    function topct( x )
        format(100*(parse( Int, x; base=16) / 256),precision=0)
    end

    r = topct(hex[2:3])
    g = topct( hex[4:5])
    b = topct( hex[6:7])
    return "rgb( $(r)%, $(g)%, $(b)%)"
end

const sevcols = [
        "#ee0000",
        "#cc2222",
        "#990000",
        "#666666",
        "#333333",
        "#333333"]

# for prettytables
function fm(v, r, c)
    return if c in [1,2] || r in [1,2]
        v
    elseif v == 0
        "-"
    else
        Format.format(v, precision=0, commas=true)
    end
end


function makedf(labels::Vector)::DataFrame
    n = length( labels )
    m = rand(1:100_000,n,n)
    d = DataFrame(m,labels)
    insertcols!(d,1,:l1=>midstring("Before",n))
    insertcols!(d,2,:pre=>labels)
    pushfirst!(d, ["", "", labels...]; promote=true)
    pushfirst!(d, midstring( "After", n+2 ); promote=true)
end

function fixup_transitions_matrix( indf :: DataFrame )::DataFrame
    df = copy( indf )
    nrows, ncols = size( df )
    labels = names(df)
    insertcols!(df,1,:l1=>midstring("Before",nrows))
    pushfirst!(df, ["", "", labels[2:end]...]; promote=true)
    pushfirst!(df, midstring( "After", nrows+2 ); promote=true)
    return df
end


"""
Switch one of our crosstab dataframes from good->bad to bad->good, preserving the totals row/col and the 1st row/col.
returns a copy, rather than changing in-place.
"""
function reverse_crosstab( df :: DataFrame )
    nrows,ncols = size(df)
    @assert nrows == ncols-1
    #nr1 = nrows - 1 # so we can skip totals row
    # so reverse each row skipping 1st 2 (labels) and reverse all but cols 1,2,last
    return reverse(df,1,nrows-1)[!,[1,ncols-1:-1:2...,ncols]]
end

# colo[u]rs for cell backgrounds, borrowed from standard Bootstrap 5.
BG_WHITE = "#ffffff"
BG_BLACK = "#000000"
BG_NEUTRAL = "#e2e3e5" # Boodstrap 5 secondary
BG_WORSEN = "#f8d7da" # danger
BG_IMPROVE = "#d1e7dd" # success

"""
Green->Red pallette In Julia Color.jl RGBs
"""
good_to_bad_pallette( num_grades :: Integer )::Vector = range( colorant"seagreen", stop=colorant"firebrick", length=num_grades )

"""
Red->Green pallette In Julia Color.jl RGBs
"""
bad_to_good_pallette( num_grades :: Integer )::Vector = range( colorant"firebrick", stop=colorant"seagreen", length=num_grades )

module HTMLTabs

using Main.TransTables
using PrettyTables
using DataFrames
using Format
using ArgCheck
using MicroVisualisations
using ScottishTaxBenefitModel, .Utils


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

const HTML_TABLE_FORMAT = HtmlTableFormat(css="border-collapse:collapse")

"""
Create an html cell highlighter function for prettyTables.

My 1st attempt at a closure.
- numcols
- sevcols - css colour strings for the data columns
"""
function make_highlighter( numcols :: Integer, sevcols::Vector )::Function

    """
    Single cell format for html

    - h - a highlighter - don't know! see pretty-tables docs ??
    - data - the whole dataset
    - row,col row and column (from 1)

    """
    function f_tablebody( h, data, row, col )::Vector{Pair{String,String}}
        d = Pair{String,String}[]
        bgcolour = if (col <= 2) || (row <= 2 ) # label cols
            BG_WHITE
        elseif (col == numcols) || (row == numcols) || (col == row) # diags and rows
            BG_NEUTRAL
        elseif row > col
            BG_WORSEN
        elseif col > row
            BG_IMPROVE
        end
        @assert ! isnothing( bgcolour) "bgcolour is nothing for r=$r c=$c"
        push!(d, "background" => bgcolour)
        datacol = col - 2
        datarow = row - 2
        colour = if(row == numcols) && (col == numcols) # overal total LHS
            BG_BLACK
        elseif(row == 2 && col == numcols) || (col == 2 && row == numcols) # totals cells in black
            BG_BLACK
        elseif(row == 1) || (col==1)
            BG_BLACK
        elseif row in [2,numcols] # bottom col totals and top 2nd labels from col colour
            sevcols[col]
        else
            sevcols[row]
        end
        push!(d, "color" => colour )
        if(col == 1) || (row == 1)
            push!(d, "font-style"=> "italic")
        elseif (col in [2,numcols]) || (row in [2,numcols]) # bold row & col headers
            push!(d, "font-weight" => "bold")
        end
        return d
    end
    return f_tablebody
end

#= failed attempt at succesively applying styles - only 1st is used so abandoned
"""
closure is the only way I can see to do this...
"""
function get_sev_col_f( sevcols :: Vector )

    function get_sev_col( h, data, r, c )
        colour = if r < length(sevcols)-2
            sevcols[r]
        else
            sevcols[c]
        end
        println( "get_sev_col; on r=$r c=$c made colour $colour")
        return ["color"=>colour]
    end

    return get_sev_col
end

# won't work because only the 1st matched highlighter is applied - I've submitted a patcj
SC = get_sev_col_f( sevcols )
label_hl = HtmlHighlighter( (data, r, c)->(r<=2)&&(c<=2), ["background" => BG_WHITE,  "font-weight" => "bold"] )
below_diag = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2)&&(r>c), "background" => BG_WORSEN )
above_diag = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2)&&(r<c), "background" => BG_IMPROVE )
diags = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2)&&(r==c),  "background" => BG_NEUTRAL )
sum_row_cols = HtmlHighlighter( (data, r, c)->((r>2)&&(c>2))&&((r==numcols)||(c==numcols)), ["background" => BG_NEUTRAL, "font-weight"=>"bold"] )
sev_cols = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2),  SC )

...

highlighters = [ sev_cols, label_hl, diags, below_diag, above_diag, sum_row_cols ],

=#

"""
- df nxn crosstab with 2 label rows and cols inserted at the top & front.
- sevcols : colours of the text e.g. red for bad green good, etc.
return html formatted crosstab as html
"""
function format_crosstab(df :: DataFrame, sevcols :: Vector )

    numcols = size( df )[1]
    # the highlighter is a closuer, so we can have sevcols and the size of dataframe
    BODY_HL = HtmlHighlighter( (data, r, c)-> true, make_highlighter(numcols,sevcols)) # (r>2)&&(c>2),  HLS[2] ) #
    io = IOBuffer()
    pretty_table(io,
                df;
                backend=:html,
                stand_alone = false,
                table_class = "table table-sm table-borderless", # FIXME this is Bootstrap-specific
                # merge_column_label_cells = :auto,
                column_labels = fill( "", numcols ), # turn off labels
                table_format = HTML_TABLE_FORMAT,
                highlighters = [BODY_HL],
                # style=TYP_TABLE_STYLE,
                formatters=[fm] )
    return String(take!(io))
end


function std_table_style( pts )
    return HtmlTableStyle( table=["text-font"=>"Urbanist", "text-stretch"=>"75%", "text-size"=>pts, "text-align"=>"horizon" ], column_label=["text-fill"=>"black", "fill" => "grey"] )
end

function format_gl( title::String, sf :: DataFrame; backend=:html, cell_prec=0 )::String

    nrows, ncols = size( sf )

    function fm_gl(v, r, c)
        return if c == 1
            v
            elseif v == 0
            "-"
            elseif (c <= ncols - 3) || (c == ncols)
            Format.format(v, precision=cell_prec, commas=true)
        else
            Format.format(v, precision=2, commas=true)
        end
        s
    end

    function html_gainlose( h, data, r, c )
        d = Pair{String,String}[]
        colour = if c == 1
            "blue"
            elseif c >= ncols - 2
            if data[r,c] < -0.1
                "maroon"
                elseif data[r,c] > 0.1
                "olive"
            else
                "black"
            end
        else
            "black"
        end
        push!(d, "color" => colour)
        if r == nrows
            push!(d, "background" => BG_NEUTRAL)
        elseif c >= ncols - 3
            push!(d, "background" => "#eee")
        end
        if(c == 1) || (r== nrows)
            push!(d, "font-weight" => "bold")
        end
        return d
    end

    """
    format cols at end green for good, red for bad.
        """
        hgainlosecols = HtmlHighlighter( (data, r, c)->true,  html_gainlose )

        pts, labwidth = if ncols < 7
            "9pt",
            "20%"
            elseif ncols < 12
            "7pt",
            "15%"
        else
            "5pt",
            "12%"
        end

        sf[!,1] = Utils.pretty.(sf[!,1]) # labels on RHS

        io = IOBuffer()
        pretty_table(
            io,
            sf[!,1:end];
            backend = :html,
            formatters=[fm_gl],
            table_class = "table table-sm", # FIXME this is Bootstrap-specific
            # data_column_widths = [1=>"25%"],
            highlighters = [hgainlosecols],
            column_labels=rename_cols( names(sf)),
            alignment=[:l,fill(:r,ncols-1)...],
            table_format=HTML_TABLE_FORMAT,
            # style=std_table_style( pts ),
            title = title )
        return String(take!(io))
    end

    function frame_to_table(
        df :: DataFrame;
        up_is_good :: Union{Vector,Nothing} = nothing,
        prec = 2,
        caption = "",
        totals_col :: Int = 9999999 )

        nrows, ncols = size(df)
        @assert ncols == 4

        function html_df( h, data, r, c )
            d = Pair{String,String}[]
            colour = "black"
            if ! isnothing( up_is_good )
                if c == 4 # diff col
                    if data[r,c] > 0
                        if up_is_good[r] == -1
                            colour = "darkred"
                        elseif up_is_good[r] == 1
                            colour = "darkgreen"
                        end
                    elseif data[r,c] < 0
                        if up_is_good[r] == 1
                            colour = "darkred"
                        elseif up_is_good[r] == -1
                            colour = "darkgreen"
                        end
                    end
                end
            end
            push!(d, "color" => colour)
            if r >= totals_col
                push!(d, "background" => BG_NEUTRAL)
            end
            if(c == 1) || (r>= totals_col)
                push!(d, "font-weight" => "bold")
            end
            return d
        end

        function fm_df(v, r, c)
            s = if c == 1
                v
            elseif v ≈ 0
                "-"
            else
                Format.format(v, precision=prec, commas=true)
            end
            if(c == 4) && (v>0) # plus xx in totals column
               s = "+$(s)"
            end
            return s
        end

        hdfcols = HtmlHighlighter((data, r, c)->true,  html_df )
        io = IOBuffer()
        pretty_table(
            io,
            df;
            backend = :html,
            formatters=[fm_df],
            table_class = "table table-sm", # FIXME this is Bootstrap-specific
            # data_column_widths = [1=>"30%"],
            highlighters = [hdfcols],
            column_labels=["","Before","After","Change"],
            alignment=[:l,fill(:r,ncols-1)...],
            table_format=HTML_TABLE_FORMAT,
            # style=std_table_style( pts ),
            source_notes = caption )
        return String(take!(io))
    end

    """
    Catch all with labels in col1, numbers in the rest
    """
    function labelled_frame_to_table( df :: DataFrame; prec=2 )::String

        function fm_df(v, r, c)
            return if (c == 1) || (! (typeof(v) <: Number ))
                v
            else
                Format.format(v, precision=prec, commas=true)
            end
        end

        nrows, ncols = size(df)
        hl = HtmlHighlighter((data, r, c)->c==1,  ["font-weight"=>"bold"] )
        io = IOBuffer()
        pretty_table( io, df,
                     backend = :html,
                     formatters=[fm_df],
                     table_class = "table table-sm",
                     table_format=HTML_TABLE_FORMAT,
                     column_labels = ["",pretty.( names(df )[2:end])...],
                     # style=std_table_style("8pt"),
                     alignment=[:l,fill(:r,ncols-1)...],
                     highlighters = [hl] )
        return String( take!( io ))
    end


end # module

module TypstTabs

using Main.TransTables

using PrettyTables
using DataFrames
using Format
using Colors
using Typstry
using ArgCheck
using ScottishTaxBenefitModel
using .STBOutput, .Utils
"""
a Color RGB rec to typst colo[u]r string "rgb( 10%, 22%, 99% )"
"""
function rgb2typ( r :: RGB )::String
    fpc(x)=format(x*100,precision=0)*"%"
    return "rgb( $(fpc(r.r)), $(fpc(r.g)), $(fpc(r.b)) )"
end


const RGB_SEVCOLS = rgbstr.(sevcols)

BG_WHITE = rgbstr( TransTables.BG_WHITE )
BG_BLACK = rgbstr( TransTables.BG_BLACK )
BG_NEUTRAL = rgbstr( TransTables.BG_NEUTRAL )
BG_WORSEN = rgbstr( TransTables.BG_WORSEN )
BG_IMPROVE = rgbstr( TransTables.BG_IMPROVE )


function std_table_style( pts )
    return TypstTableStyle( table=["text-font"=>"Urbanist", "text-stretch"=>"75%", "text-size"=>pts, "text-align"=>"horizon" ], column_label=["text-fill"=>"black", "fill" => "grey"] )
end

const NO_BORDERS = TypstTableBorders(
        top_line="0pt",
        header_line = "0pt",
        merged_header_cell_line = "0pt",
        middle_line = "0pt",
        bottom_line = "0pt",
        left_line = "0pt",
        center_line = "0pt",
        right_line = "0pt" )

const TABLE_FMT= TypstTableFormat(borders=NO_BORDERS, vertical_lines_at_data_columns= :none)
    # io = IOBuffer()

"""
My 1st attempt at a closure: see:
"""
function make_highlighter( numcols::Integer, sevcols::Vector )::Function

    """
    Single cell format for html

    - h - a highlighter - don't know! see pretty-tables docs ??
    - data - the whole dataset
    - row, col row and column (from 1)

    """
    function f_tablebody( h, data, row, col )::Vector{Pair{String,String}}
        d = Pair{String,String}[]
        bgcolour = if (col <= 2) || (row <= 2 ) # label cols
            BG_WHITE
        elseif (col == numcols) || (row == numcols) || (col == row) # diags and rows
            BG_NEUTRAL
        elseif row > col
            BG_WORSEN
        elseif col > row
            BG_IMPROVE
        end
        @assert ! isnothing( bgcolour) "bgcolour is nothing for r=$r c=$c"
        push!(d, "fill" => bgcolour)
        datacol = col - 2
        datarow = row - 2
        colour = if(row == numcols) && (col == numcols) # overal total LHS
            BG_BLACK
        elseif(row == 2 && col == numcols) || (col == 2 && row == numcols) # totals cells in black
            BG_BLACK
        elseif(row == 1) || (col==1) # before/after
            BG_BLACK
        elseif row in [2,numcols] # bottom col totals and top 2nd labels from col colour
            sevcols[col]
        else
            sevcols[row]
        end
        push!(d, "text-fill" => colour )
        # before and after ..
        if(col == 1) || (row == 1)
            push!(d, "text-style"=> "italic")
            # bold row & col totals
        elseif (col in [numcols]) || (row in [numcols])
            #push!(d, "text-weight" => "bold")
            # push!(d, "text-size" => "90%")
        end
        return d
    end
    return f_tablebody
end

function format_crosstab(df :: DataFrame, sevcols :: Vector )
    n = size(df)[1]
    pts, labwidth = if n < 7
        "9pt",
        "20%"
    elseif n < 12
        "7pt",
        "15%"
    else
        "5pt",
        "12%"
    end

    TABLE_STYLE = TypstTableStyle( table=["text-font"=>"Urbanist", "text-stretch"=>"75%", "text-size"=>pts, "text-align"=>"horizon" ], column_label=["text-fill"=>"black"] )

    # "BellCentennial LT Address",

    BODY_HL = TypstHighlighter( (data, r, c)->true, make_highlighter( n, sevcols ) ) #

    io = IOBuffer()
    pretty_table(io,
                df;
                backend=:typst,
                merge_column_label_cells = :auto,
                column_labels=fill("",n), # turn off labels
                data_column_widths=[2=>labwidth],
                table_format=TABLE_FMT,
                highlighters = [BODY_HL],
                style=std_table_style( pts ),
                formatters=[fm] )
    return String(take!(io))
end

const STD_BORDERS = TypstTableBorders(
    top_line="0pt",
    header_line = "0pt",
    merged_header_cell_line = "0pt",
    middle_line = "0pt",
    bottom_line = "0pt",
    left_line = "0pt",
    center_line = "0pt",
    right_line = "0pt" )

const STD_FORMAT = TypstTableFormat(borders=STD_BORDERS, vertical_lines_at_data_columns= :none)


function format_gl( title::String, sf :: DataFrame; backend=:typst, cell_prec=0 )::String

    nrows, ncols = size( sf )

    function fm_gl(v, r, c)
        return if c == 1
            v
        elseif v == 0
            "-"
        elseif (c <= ncols - 3) || (c == ncols)
            Format.format(v, precision=cell_prec, commas=true)
        else
            Format.format(v, precision=2, commas=true)
        end
        s
    end

    function typst_gainlose( h, data, r, c )
        d = Pair{String,String}[]
        colour = if c == 1
            "blue"
        elseif c >= ncols - 2
            if data[r,c] < -0.1
                "maroon"
            elseif data[r,c] > 0.1
                "olive"
            else
                "black"
            end
        else
            "black"
        end
        push!(d, "text-fill" => colour)
        if r == nrows
            push!(d, "fill" => "gray")
        elseif c >= ncols - 3
            push!(d, "fill" => "silver")
        end
        if(c == 1) || (r== nrows)
            push!(d, "text-weight" => "bold")
        end
        return d
    end

    """
    format cols at end green for good, red for bad.
    """
    hgainlosecols = TypstHighlighter( (data, r, c)->true,  typst_gainlose )

    pts, labwidth = if ncols < 7
        "9pt",
        "20%"
    elseif ncols < 12
        "7pt",
        "15%"
    else
        "5pt",
        "12%"
    end

    sf[!,1] = Utils.pretty.(sf[!,1]) # labels on RHS

    # io = IOBuffer()
    io = IOBuffer()
    pretty_table(
        io,
        sf[!,1:end];
        backend = :typst,
        formatters=[fm_gl],
        data_column_widths = [1=>"25%"],
        highlighters = [hgainlosecols],
        column_labels=rename_cols( names(sf)),
        alignment=[:l,fill(:r,ncols-1)...],
        table_format=STD_FORMAT,
        style=std_table_style( pts ),
        title = title )
    return String(take!(io))
end

function frame_to_table(
    df :: DataFrame;
    up_is_good :: Union{Vector,Nothing} = nothing,
    prec = 2,
    caption = "",
    totals_col :: Int = 9999999 )

    nrows, ncols = size(df)
    @assert ncols == 4

    function typst_df( h, data, r, c )
        d = Pair{String,String}[]
        colour = "black"
        if ! isnothing( up_is_good )
            # typst named colo[u]rs: https://typst.app/docs/reference/visualize/color/
            if c == 4 # diff col
                if data[r,c] > 0
                    if up_is_good[r] == -1
                        colour = "maroon"
                        elseif up_is_good[r] == 1
                        colour = "olive"
                    end
                elseif data[r,c] < 0
                    if up_is_good[r] == 1
                        colour = "maroon"
                    elseif up_is_good[r] == -1
                        colour = "olive"
                    end
                end
            end
        end
        push!(d, "text-fill" => colour)
        if r >= totals_col
            push!(d, "fill" => BG_NEUTRAL)
        end
        if(c == 1) || (r>= totals_col)
            push!(d, "text-weight" => "bold")
        end
        return d
    end

    function fm_df(v, r, c)
        s = if c == 1
            v
            elseif v ≈ 0
            "-"
        else
            Format.format(v, precision=prec, commas=true)
        end
        if(c == 4) && (v>0) # plus xx in totals column
            s = "+$(s)"
        end
        return s
    end

    hdfcols = TypstHighlighter((data, r, c)->true,  typst_df )
    io = IOBuffer()
    pretty_table(
        io,
        df;
        backend = :typst,
        formatters=[fm_df],
        data_column_widths = [1=>"30%"],
        highlighters = [hdfcols],
        column_labels=["","Before","After","Change"],
        alignment=[:l,fill(:r,ncols-1)...],
        table_format=STD_FORMAT,
        style=std_table_style( "10pt" ),
        caption = caption )
    return String(take!(io))
end

"""
Catch all with labels in col1, numbers in the rest
"""
function labelled_frame_to_table( df :: DataFrame; prec=2 )::String

    function fm_df(v, r, c)
        return if (c == 1) || (! (typeof(v) <: Number ))
            v
        else
            Format.format(v, precision=prec, commas=true)
        end
    end

    nrows, ncols = size(df)
    hl = TypstHighlighter((data, r, c)->c==1,  ["text-weight"=>"bold"] )
    io = IOBuffer()
    pretty_table( io, df,
        backend = :typst,
        formatters=[fm_df],
        table_format=STD_FORMAT,
        column_labels = ["",pretty.( names(df )[2:end])...],
        style=std_table_style("8pt"),
        data_column_widths = [1=>"20%"],
        alignment=[:l,fill(:r,ncols-1)...],
        highlighters = [hl] )
    return String( take!( io ))
end

end # Typst module

using .TransTables
using ScottishTaxBenefitModel
using .STBOutput
using CSV,DataFrames
using MicroVisualisations

function save_and_print_trans( filename = "table1" )
    dfm = CSV.File( "sample_output/metrs-transition-matrix-df-2.csv")|>DataFrame
    dfm = TransTables.reverse_crosstab( dfm ) # bad -> good for MRs
    dfm = fixup_transitions_matrix( dfm )
    df = CSV.File( "sample_output/poverty-transition-matrix-2-vs-1.csv")|>DataFrame
    df = fixup_transitions_matrix( df )
    gl = CSV.File( "sample_output/gain-lose-by-tenure-2-vs-1.csv")|>DataFrame
    incs1 = CSV.File( "sample_output/income_summary_1.csv")|>DataFrame
    incs2 = CSV.File( "sample_output/income_summary_2.csv")|>DataFrame
    cf = costs_dataframe( incs1, incs2 )
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


end

end # moduke
