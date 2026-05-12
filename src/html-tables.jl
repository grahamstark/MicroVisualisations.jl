#=
Constants and functions needed for HTML Tables using PrettyTables as the backend.
=#

# FIXME as far as I can see PrettyTables actually does nothing with this.
const HTML_TABLE_FORMAT = HtmlTableFormat(css="border-collapse:collapse")

function html_table_style( pts :: AbstractString ) :: String
    return HtmlTableStyle( table=["text-font"=>"$(DEFAULT_FONT)", "text-stretch"=>"75%", "text-size"=>pts, "text-align"=>"horizon" ], column_label=["text-fill"=>"black", "fill" => "grey"] )
end


"""
Create an html cell highlighter function for prettyTables.

My 1st attempt at a closure.
- numcols
- sevcols - css colour strings for the data columns
"""
function html_make_highlighter( numcols :: Integer, sevcols::Vector )::Function

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
end # function /functor

"""
- df nxn crosstab with 2 label rows and cols inserted at the top & front.
- sevcols : colours of the text e.g. red for bad green good, etc.
return html formatted crosstab as html
"""
function format_crosstab(df :: DataFrame, sevcols :: Vector, ::MV_HTML )


    numcols = size( df )[1]
    # the highlighter is a closuer, so we can have sevcols and the size of dataframe
    body_hl = HtmlHighlighter( (data, r, c)-> true, html_make_highlighter(numcols,sevcols)) # (r>2)&&(c>2),  HLS[2] ) #
    io = IOBuffer()
    pretty_table(io, df;
        backend=:html,
        stand_alone = false,
        table_class = "table table-sm table-borderless", # FIXME this is Bootstrap-specific
        column_labels = fill( "", numcols ), # turn off labels
        table_format = HTML_TABLE_FORMAT,
        highlighters = [body_hl],
        formatters=[crosstab_fm] )
    return String(take!(io))
end

function format_gain_lose( title::String, gl :: DataFrame, ::MV_HTML; cell_prec=0 )::String

    nrows, ncols = size( gl )

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

    """
    grey totals & rhs cols, red/green change cols
    """
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
    hgainlose = HtmlHighlighter( (data, r, c)->true,  html_gainlose )

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

    gl[!,1] = Utils.pretty.(gl[!,1]) # labels on RHS
    io = IOBuffer()
    pretty_table(
        io, gl;
        backend = :html,
        formatters=[fm_gl],
        table_class = "table table-sm", # FIXME this is Bootstrap-specific
        # data_column_widths = [1=>"25%"],
        highlighters = [hgainlose],
        column_labels=gl_rename_cols( names(gl)),
        alignment=[:l,fill(:r,ncols-1)...],
        table_format=HTML_TABLE_FORMAT,
        # style=std_table_style( pts ),
        title = title )
    return String(take!(io))
end





