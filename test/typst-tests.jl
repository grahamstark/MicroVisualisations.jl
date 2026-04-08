using PrettyTables
using DataFrames
using Format

const labels = ["V.Deep (<=30%)",
              "Deep (<=40%)",
              "In Poverty (<=60%)",
              "Near Poverty (<=80%)",
              "Not in Poverty",
             "Total"]
const BEFORE = [""*3]


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

const RGB_SEVCOLS = rgbstr.(sevcols)

const TEST_MAT = rand(1:1000,6,6)

function makedf()
    m = rand(1:100_000,6,6)
    d = DataFrame(m,labels)
    insertcols!(d,1,:l1=>midstring("After",6))
    insertcols!(d,2,:pre=>labels)
    pushfirst!(d, ["", "", labels...]; promote=true)
end

const test_df = makedf()

BG_WHITE = rgbstr( "#ffffff")
BG_NEUTRAL = rgbstr( "#dddddd")
BG_WORSEN = rgbstr( "#ffccbb")
BG_IMPROVE = rgbstr( "#bbffdd")

const TYP_NO_BORDERS = TypstTableBorders(

        top_line="0pt",
        header_line = "0pt",
        merged_header_cell_line = "0pt",
        middle_line = "0pt",
        bottom_line = "0pt",
        left_line = "0pt",
        center_line = "0pt",
        right_line = "0pt" )
const TYP_TABLE_FMT= TypstTableFormat(borders=TYP_NO_BORDERS, vertical_lines_at_data_columns= :none)
const COL_FILLS = ["text-fill"=>"black"] #, "text-fill"=>"black", ("text-fill"=>x for x in RGB_SEVCOLS)...]

const TYP_TABLE_STYLE = TypstTableStyle( column_label=COL_FILLS )
    # io = IOBuffer()


function f_tablebody( h, data, r, c )::Vector{Pair{String,String}}
    d = Pair{String,String}[]
    datacol = c - 2
    bgcolour = if c <= 2
        BG_WHITE
    elseif datacol == 6 || r == 6 || datacol == r
        BG_NEUTRAL
    elseif r > datacol
        BG_WORSEN
    elseif c > r
        BG_IMPROVE
    end
    push!(d, "fill" => bgcolour)
    # if r == 0 # size( sf )[1]
    if r == 6 && datacol > 0
        push!(d, "text-fill" => RGB_SEVCOLS[datacol])
    else
        push!(d, "text-fill" => RGB_SEVCOLS[r])
    end
    # end

    if(c in [1,2,8]) || (r in [6])
        push!(d, "text-weight" => "bold")
    end
    # push!(d, "stretch"=>"75%")
    return d
end

const BODY_HL = TypstHighlighter( (data, r, c)->true,  f_tablebody ) #

    """
    format cols at end green for good, red for bad.
    """

# for prettytables
function fm(v, r, c)
    return if c in [1,2]
        v
    elseif v == 0
        "-"
    else
        Format.format(v, precision=0, commas=true)
    end
end

function pt()
    io = IOBuffer()
    pretty_table(io,
                test_df;
                backend=:typst,
                merge_column_label_cells = :auto,
                column_labels=COL_LABELS,
                table_format=TYP_TABLE_FMT,
                highlighters = [BODY_HL],
                style=TYP_TABLE_STYLE,
                formatters=[fm] )
    return String(take!(io))
end

function save_and_print( filename = "table1")
    io = open( "tmp/$(filename).typ", "w")
    println( io, pt())
    close(io)
    typst_command = `typst compile tmp/$(filename).typ`
    run( typst_command )
end
