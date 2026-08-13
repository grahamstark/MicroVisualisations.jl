#=

Constants and functions shared between all formats of table we support

=#

# FIXME these must ne standard defines somewhere?
struct MV_HTML end
struct MV_TYPST end
struct MV_MARKDOWN end
const AllFormats = Union{MV_MARKDOWN,MV_HTML,MV_TYPST}
to_ext( ::MV_HTML)="html"
to_ext( ::MV_TYPST)="typ"
to_ext( ::MV_MARKDOWN)="md"

const DEFAULT_FONT = "Urbanist"

# colo[u]rs for cell backgrounds, borrowed from standard Bootstrap 5.
BG_WHITE = "#ffffff"
BG_BLACK = "#000000"
BG_NEUTRAL = "#e2e3e5" # Boodstrap 5 secondary
BG_WORSEN = "#f8d7da" # danger
BG_IMPROVE = "#d1e7dd" # success

const GOOD_COLOUR = colorant"seagreen"
const BAD_COLOUR = colorant"firebrick"
const NEUTRAL_COLOUR = colorant"black"


const MR_UP_GOOD = [
    0, # "Less than zero"
    1, # "Zero"
    0, # "0.01-9.99"
    0, # "10-19.99"
    0, # "20-29.99"
    0, # "30-39.99"
    0, # "40-49.99"
    0, # "50-59.99"
    0, # "60-69.99"
    0, # "70-79.99"
    0, # "80-89.99"
    0, # "90-99.99"
    -1, # "100"
    -1, # "Above 100"
    -1, # mean
    -1] # median



# for prettytables
function crosstab_fm(v, r, c)
    return if c in [1,2] || r in [1,2]
        v
    elseif v == 0
        "-"
    else
        Format.format(v, precision=0, commas=true)
    end
end

"""
html version - wrap crosstab_fm output in a span that allows retrieval of row/col - so e.g. we
can pop up examples of changed hhlds in cells
FIXME doesn't work - html tags escaped
"""
function html_id_crosstab_fm(v, r, c)
    s = crosstab_fm(v, r, c)
    return if c in [1,2] || r in [1,2] || s == "-"
        s
    else
        "<span data-row='$r' data-col='$c'>$s</span>"
    end
end

const COST_UP_GOOD = [1,1,1,1,1,-1,-1,-1,-1,-1,-1,-1,1]

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

"""
last 4 cols in a gain-lose table, retaining the rest
"""
function gl_rename_cols( colnames )
    n = length( colnames )
    newnames = fill("",n)
    for c in 2:n
        newnames[c] = get( GL_RENAMES, colnames[c], colnames[c])
    end
    return newnames
end

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

function rgb2typ( r :: RGB )::String
    fpc(x)=format(x*100,precision=0)*"%"
    return "rgb( $(fpc(r.r)), $(fpc(r.g)), $(fpc(r.b)) )"
end

"""
This adds columns for 'before' on the left and 'after' and a row at the top for 'after' to make it a wee bit easier to format using PrettyTables.
"""
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
FIXME not used anymore since we now produce the crosstab in ScotBen the right way around.
Switch one of our crosstab dataframes from good->bad to bad->good, preserving the totals row/col and the 1st row/col.
returns a copy, rather than changing in-place.
"""
function reverse_crosstab( df :: AbstractDataFrame )::DataFrame
    nrows,ncols = size(df)
    @assert nrows == ncols-1
    #nr1 = nrows - 1 # so we can skip totals row
    # so reverse each row skipping 1st 2 (labels) and reverse all but cols 1,2,last
    return reverse(df,1,nrows-1)[!,[1,ncols-1:-1:2...,ncols]]
end

"""
Green->Red pallette In Julia Color.jl RGBs
"""
good_to_bad_pallette( num_grades :: Integer )::Vector = range( GOOD_COLOUR, stop=BAD_COLOUR, length=num_grades )

"""
Red->Green pallette In Julia Color.jl RGBs
"""
bad_to_good_pallette( num_grades :: Integer )::Vector = range( BAD_COLOUR, stop=GOOD_COLOUR, length=num_grades )

