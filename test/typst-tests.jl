module TransTables

using Format,DataFrames,ScottishTaxBenefitModel

export labels,midstring,COL_LABELS,rgbstr,sevcols,fm,makedf, BG_WHITE, BG_NEUTRAL, BG_WORSEN, BG_IMPROVE

const labels = ["V.Deep (<=30%)",
              "Deep (<=40%)",
              "In Poverty (<=60%)",
              "Near Poverty (<=80%)",
              "Not in Poverty",
             "Total"]

"""
midstring("hello",7) -> ["","","","hello","","",""]
"""
function midstring(s,len)
    l1 = len÷2
    l2 = len - l1 - 1
    r = [fill("",l1)...,s,fill("",l2)...]
    @assert length(r) == len "length(r) $(length(r)) != len=$len "
    return r
end

const COL_LABELS = [
        # [MultiColumn(8, "Before")],
        midstring("Before",8),
        ["","", labels...]
     ]

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

module HTMLTabs

using Main.TransTables
using PrettyTables
using DataFrames
using Format

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
    push!(d, "background" => bgcolour)
    # if r == 0 # size( sf )[1]
    if datarow in [0,6] && datacol > 0 # bottom col totals and top 2nd labels from col colour
        push!(d, "color" => sevcols[datacol])
    elseif datarow > 0
        push!(d, "color" => sevcols[datarow])
    end
    # end

    if(c in [1,2,8]) || (r in [1,2,8]) # bold row & col headers
        push!(d, "font-weight" => "bold")
    end
    # push!(d, "stretch"=>"75%")
    return d
end

const TABLE_FMT = HtmlTableFormat(css="border-collapse:collapse")
const BODY_HL = HtmlHighlighter( (data, r, c)->true,  f_tablebody ) #

function pt(df :: DataFrame)
    io = IOBuffer()
    pretty_table(io,
                df;
                backend=:html,
                stand_alone = false,
                table_class = "table table-sm",
                # merge_column_label_cells = :auto,
                column_labels=fill("",8), # turn off labels
                table_format=TABLE_FMT,
                highlighters = [BODY_HL],
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
using Typstry

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
    io = open( "tmp/$(filename).typ", "w")
    println( io, TypstTabs.pt(df))
    close(io)
    typst_command = `typst compile tmp/$(filename).typ`
    run( typst_command )
    io = open( "tmp/$(filename).html", "w")
    println( io, HTMLTabs.pt(df))
    close(io)
end

end # moduke
