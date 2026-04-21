module TransTables

using Format,DataFrames,ScottishTaxBenefitModel,Colors,ArgCheck

export labels,midstring,COL_LABELS,rgbstr,sevcols,fm,makedf, BG_WHITE, BG_NEUTRAL, BG_WORSEN, BG_IMPROVE

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


function makedf()
    m = rand(1:100_000,6,6)
    d = DataFrame(m,labels)
    insertcols!(d,1,:l1=>midstring("Before",6))
    insertcols!(d,2,:pre=>labels)
    pushfirst!(d, ["", "", labels...]; promote=true)
    pushfirst!(d, midstring( "After", 8 ); promote=true)
end


BG_WHITE = "#ffffff"
BG_NEUTRAL = "#e2e3e5" # Boodstrap 5 secondary
BG_WORSEN = "#f8d7da" # danger
BG_IMPROVE = "#d1e7dd" # success

function good_to_bad_pallette( num_grades :: Integer )::Vector
    r = range( colorant"darkgreen", stop=colorant"darkred", length=num_grades )
    pushfirst!(r, colorant"black")
    pushfirst!(r, colorant"black")
    push!(r, colorant"black")
    return r
end

function bad_to_good_pallette( num_grades :: Integer )::Vector
    r = range( colorant"darkred", stop=colorant"darkgreen", length=num_grades )
    pushfirst!(r, colorant"black")
    pushfirst!(r, colorant"black")
    push!(r, colorant"black")
    return r
end

module HTMLTabs

using Main.TransTables
using PrettyTables
using DataFrames
using Format
using ArgCheck


const HTML_TABLE_FMT = HtmlTableFormat(css="border-collapse:collapse")

"""
My 1st attempt at a closure: see:
"""
function make_highlighters( df :: DataFrame, sevcols::Vector )::Tuple

    END_DATA_COL = size( df )[1]


    """
    Single cell format for html

    - h - a highlighter - don't know! see pretty-tables docs ??
    - data - the whole dataset
    - r,c row and column (from 1)

    """
    function f_tablebody( h, data, r, c )::Vector{Pair{String,String}}
        @argcheck r > 2 && c > 2 # && (isnothing(data)||data <: Number)
        d = Pair{String,String}[]
        datacol = c - 2
        datarow = r - 2
        bgcolour = if (datacol == END_DATA_COL) || (datarow == END_DATA_COL) || (datacol == datarow)
            BG_NEUTRAL
        elseif datarow > datacol
            BG_WORSEN
        elseif datacol > datarow
            BG_IMPROVE
        end
        @assert ! isnothing( bgcolour) "bgcolour is nothing for r=$r c=$c"
        push!(d, "background" => bgcolour)
        # if r == 0 # size( sf )[1]
        if datarow in [0,END_DATA_COL] && datacol > 0 # bottom col totals and top 2nd labels from col colour
            push!(d, "color" => sevcols[datacol])
        elseif datarow > 0
            push!(d, "color" => sevcols[datarow])
        end
        # end

        if(c in [1,2,END_DATA_COL]) || (r in [1,2,8]) # bold row & col headers
            push!(d, "font-weight" => "bold")
        end
        # push!(d, "stretch"=>"75%")
        return d
    end


    function f_labels( h, data, r, c )::Vector{Pair{String,String}}
        @argcheck r <= 2 || c <= 2 # && (data <: AbstractString)
        d = Pair{String,String}[]
        push!(d, "font-weight" => "bold")
        push!(d, "bakgrpund" => BG_WHITE )
        return d
    end

    return f_labels, f_tablebody
end

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

function dofall( h, data, r, c )
    println( "dofall called")
    @show h
    return ["color"=>"pink"]
end


"""
- df nxn crosstab with 2 label rows and cols inserted at the top & front.
- sevcols : colours of the text e.g. red for bad green good, etc.
return html formatted crosstab as html
"""
function pt(df :: DataFrame, sevcols :: Vector )

    END_DATA_COL = size( df )[1]

    HLS = make_highlighters(df,sevcols)
    LABEL_HL = HtmlHighlighter( (data, r, c)->(r<=2)||(c<=2),  HLS[1] )
    BODY_HL = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2),  HLS[2] ) #
    # won't work
    SC = get_sev_col_f( sevcols )
    label_hl = HtmlHighlighter( (data, r, c)->(r<=2)&&(c<=2), ["background" => BG_WHITE,  "font-weight" => "bold"] )
    below_diag = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2)&&(r>c), "background" => BG_WORSEN )
    above_diag = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2)&&(r<c), "background" => BG_IMPROVE )
    diags = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2)&&(r==c),  "background" => BG_NEUTRAL )
    sum_row_cols = HtmlHighlighter( (data, r, c)->((r>2)&&(c>2))&&((r==END_DATA_COL)||(c==END_DATA_COL)), ["background" => BG_NEUTRAL, "font-weight"=>"bold"] )
    sev_cols = HtmlHighlighter( (data, r, c)->(r>2)&&(c>2),  SC )

    io = IOBuffer()
    pretty_table(io,
                df;
                backend=:html,
                stand_alone = false,
                table_class = "table table-sm", # FIXME this is Bootstrap-specific
                # merge_column_label_cells = :auto,
                column_labels = fill("",8), # turn off labels
                table_format = HTML_TABLE_FMT,
                highlighters = [LABEL_HL, BODY_HL],
                # highlighters = [ sev_cols, label_hl, diags, below_diag, above_diag, sum_row_cols ],
                # style=TYP_TABLE_STYLE,
                formatters=[fm] )
    return String(take!(io))
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

"""
a Color RGB rec to typst colo[u]r string "rgb( 10%, 22%, 99% )"
"""
function rgb2typ( r :: RGB )::String
    fpc(x)=format(x*100,precision=0)*"%"
    return "rgb( $(fpc(r.r)), $(fpc(r.g)), $(fpc(r.b)) )"
end


const RGB_SEVCOLS = rgbstr.(sevcols)

BG_WHITE = rgbstr( TransTables.BG_WHITE )
BG_NEUTRAL = rgbstr( TransTables.BG_NEUTRAL )
BG_WORSEN = rgbstr( TransTables.BG_WORSEN )
BG_IMPROVE = rgbstr( TransTables.BG_IMPROVE )

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

const TABLE_STYLE = TypstTableStyle( column_label=["text-fill"=>"black"] )
    # io = IOBuffer()

function f_tablebody( h, data, r, c )::Vector{Pair{String,String}}
    d = Pair{String,String}[]
    datacol = c - 2
    datarow = r - 2
    bgcolour = if c <= 2 || r <= 2
        BG_WHITE
    elseif (datacol == 6) || (datarow == 6) || (datacol == datarow)
        BG_NEUTRAL
    elseif datarow > datacol
        BG_WORSEN
    elseif datacol > datarow
        BG_IMPROVE
    end
    @assert ! isnothing( bgcolour) "bgcolour is nothing for r=$r c=$c"
    push!(d, "fill" => bgcolour)
    # if r == 0 # size( sf )[1]
    if datarow in [0,6] && datacol > 0 # bottom col totals and top 2nd labels from col colour
        push!(d, "text-fill" => RGB_SEVCOLS[datacol])
    elseif datarow > 0
        push!(d, "text-fill" => RGB_SEVCOLS[datarow])
    end
    # end

    if(c in [1,2,8]) || (r in [1,2,8]) # bold row & col headers
        push!(d, "text-weight" => "bold")
    end
    # push!(d, "stretch"=>"75%")
    return d
end

const BODY_HL = TypstHighlighter( (data, r, c)->true,  f_tablebody ) #

function pt(df :: DataFrame )
    io = IOBuffer()
    pretty_table(io,
                df;
                backend=:typst,
                merge_column_label_cells = :auto,
                column_labels=fill("",8), # turn off labels
                table_format=TABLE_FMT,
                highlighters = [BODY_HL],
                style=TABLE_STYLE,
                formatters=[fm] )
    return String(take!(io))
end

end # Typst module

using .TransTables

function save_and_print( filename = "table1")
    df = TransTables.makedf()
    sevcols = TransTables.bad_to_good_pallette( size(df)[1])
    @show sevcols
    io = open( "tmp/$(filename).typ", "w")
    println( io, TypstTabs.pt(df))
    close(io)
    typst_command = `typst compile tmp/$(filename).typ`
    run( typst_command )
    io = open( "tmp/$(filename).html", "w")
    hsc = "#" .* hex.(sevcols)
    println( io, HTMLTabs.pt(df, hsc ))
    close(io)
end



end # moduke
