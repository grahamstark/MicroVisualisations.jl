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
function format_crosstab(df :: DataFrame, ::MV_HTML )

    numcols = size( df )[1]
    sevcols = "#".*hex.(bad_to_good_pallette( numcols ))
    # the highlighter is a closure, so we can have sevcols and the size of dataframe
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

"""
Our standard costs tables have 4 rows: label, pre values, post values, change.
up_is_good - vector of 1=good 0=don't care -1=bad
"""
function format_std_short_costs(
    df :: DataFrame, ::MV_HTML;
    up_is_good :: Union{Vector,Nothing} = nothing,
    prec = 2,
    caption = "",
    totals_col :: Int = 9999999 )

    nrows, ncols = size(df)
    @assert ncols == 4

    function html_costs( h, data, r, c )
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

    hdfcols = HtmlHighlighter((data, r, c)->true,  html_costs )
    io = IOBuffer()
    pretty_table(
        io, df;
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
function labelled_frame_to_table( df :: DataFrame, ::MV_HTML; prec=2, labels=nothing )::String

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
    if isnothing( labels )
       labels = ["",pretty.( names(df )[2:end])...]
    end
    pretty_table( io, df,
                    backend = :html,
                    formatters=[fm_df],
                    table_class = "table table-sm",
                    table_format=HTML_TABLE_FORMAT,
                    column_labels = labels,
                    alignment=[:l,fill(:r,ncols-1)...],
                    highlighters = [hl] )
    return String( take!( io ))
end


function format_sfc( title::String, sf :: DataFrame, ::MV_HTML )
    """
    fixme change this to set class text-success/text-warn
    """
    function f_gainlose( h, data, r, c )
        colour = "black"
        if c >= 7 # av, pct cols at end
            colour = if data[r,c] < -0.1
                "darkred"
                elseif data[r,c] > 0.1
                "darkgreen"
            else
                "black"
            end
        end
        return ["color" => colour ]
        # HtmlDecoration( color=colour )
    end

    """
    format cols at end green for good, red for bad.
    """
    h7 = HtmlHighlighter( (data, r, c)->(c >= 7), f_gainlose )
    ht = HtmlHighlighter( (data, r, c)->(r >= 7), ["font_weight"=>"bold", "color"=>"black", "background"=>"#ddddff"] )
    sf[!,1] = pretty.(sf[!,1]) # labels on RHS

    io = IOBuffer()
    pretty_table(
        io,
        sf[!,1:end];
        backend = :html,
        formatters=[fm3],
        alignment=[:l,fill(:r,11)...],
        highlighters = [ht],
        table_class="table table-sm table-striped table-responsive",
        title = title,
        column_labels=[[
            "Taxable Income",
            "Tie Rate",
            "AETR Rate",
            "Num People",
            "Static Baseline",
            "Static Reform",
            "Static Change",
            "Intensive Change",
            "Extensive Change",
            "Total Behavioural Change",
            "SFC Change",
            "Behavioural Offset"],
        ["£pa","","", "",MultiColumn(7,"£m pa"),"%"]] )
        return String(take!(io))
end

function format_overall_cost( incs1:: DataFrame, incs2:: DataFrame, ::MV_HTML ) :: String
    n1 = incs1[1,:net_cost]
    n2 = incs2[1,:net_cost]
    # add in employer's NI
    eni1 = incs1[1,:employers_ni]
    eni2 = incs2[1,:employers_ni]
    d = (n1-eni1) - (n2-eni2)
    d /= 1_000_000
    colour = "alert-info"
    extra = ""
    change_str = "In total, your changes cost less than £1m"
    change_val = ""
    if abs(d) > 1
        change_val = f0(abs(d))
        if d > 0
            colour = "alert-success"
            change_str = "In total, your changes raise £"
            extra = "m."
        else
            colour = "alert-danger"
            change_str = "In total, your changes cost £"
            extra = "m."
        end
    end
    costs = "<div class='alert $colour'>$change_str<strong>$change_val</strong>$extra</div>"
    return costs
end

function format_bc( title::String, bc::DataFrame, ::MV_HTML )::String

    function fm(v, r,c)
        return if c in [1,7]
            v
        elseif c == 4
            if abs(v) > 4000
                "Discontinuity"
            else
                Format.format(v, precision=3, commas=false)
            end
        else
            Format.format(v, precision=2, commas=true)
        end
        s
    end

    function add_hidden_to_label( lab :: String )::String
        i = rand(100000:100000000)
        id = "id-$i"
        return "<button class='btn btn-primary' type='button' data-bs-toggle='collapse' data-bs-target='#$(id)' aria-expanded='false' aria-controls='collapseExample'>More Detail</button><div class='collapse' id='$id'><div class='card card-body'>$(lab)</div></div>"
    end

    bc.char_labels = BCCalcs.get_char_labels(size(bc)[1])
    bc[!,:simplelabel_hide] = add_hidden_to_label.( bc.simplelabel )
    io = IOBuffer()
    pretty_table(
        io,
        bc[!,[:char_labels,:gross,:net,:mr,:cap,:reduction,:simplelabel_hide]];
        backend = :html,
        formatters=[fm],
        allow_html_in_cells=true,
        table_class="table table-sm table-striped table-responsive",
        column_labels = ["ID", "Earnings &pound;pw","Net Income AHC &pound;pw", "METR", "Benefit Cap", "Benefits Reduced By", "Breakdown"],
        alignment=[fill(:r,6)...,:l],
        title = title )
    return String(take!(io))
end




