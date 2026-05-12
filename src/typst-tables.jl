

const TYPST_NO_BORDERS = TypstTableBorders(
        top_line="0pt",
        header_line = "0pt",
        merged_header_cell_line = "0pt",
        middle_line = "0pt",
        bottom_line = "0pt",
        left_line = "0pt",
        center_line = "0pt",
        right_line = "0pt" )

const TYPST_TABLE_FORMAT = TypstTableFormat(borders=TYPST_NO_BORDERS, vertical_lines_at_data_columns= :none)

function typst_std_table_style( pts )
    return TypstTableStyle( table=["text-font"=>"Urbanist", "text-stretch"=>"75%", "text-size"=>pts, "text-align"=>"horizon" ], column_label=["text-fill"=>"black", "fill" => "grey"] )
end

"""
My 1st attempt at a closure: see:
"""
function make_highlighter( numcols::Integer, sevcols::Vector )::Function

    """
    - h - a highlighter - don't know! see pretty-tables docs ??
    - data - the whole dataset
    - row, col row and column (from 1)

    """
    function f_tablebody( h, data, row, col )::Vector{Pair{String,String}}
        d = Pair{String,String}[]
        bgcolour = if (col <= 2) || (row <= 2 ) # label cols
            rgbstr( BG_WHITE )
        elseif (col == numcols) || (row == numcols) || (col == row) # diags and rows
            rgbstr( BG_NEUTRAL )
        elseif row > col
            rgbstr( BG_WORSEN )
        elseif col > row
            rgbstr( BG_IMPROVE )
        end
        @assert ! isnothing( bgcolour) "bgcolour is nothing for r=$r c=$c"
        push!(d, "fill" => bgcolour)
        datacol = col - 2
        datarow = row - 2
        colour = if(row == numcols) && (col == numcols) # overal total LHS
            rgbstr( BG_BLACK )
        elseif(row == 1) || (col==1) # before/after
            rgbstr( BG_BLACK )
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


function format_crosstab(df :: DataFrame, sevcols :: Vector, ::MV_TYPST )
    nrows, ncols = size(df)
    pts, labwidth = if nrows < 7
        "9pt",
        "20%"
    elseif nrows < 12
        "7pt",
        "15%"
    else
        "5pt",
        "12%"
    end
    TABLE_STYLE = TypstTableStyle( table=["text-font"=>"$(DEFAULT_FONT)", "text-stretch"=>"75%", "text-size"=>pts, "text-align"=>"horizon" ], column_label=["text-fill"=>"black"] )
    BODY_HL = TypstHighlighter( (data, r, c)->true, make_highlighter( nrows, sevcols ) ) #
    io = IOBuffer()
    pretty_table(io, df;
        backend=:typst,
        merge_column_label_cells = :auto,
        column_labels=fill("",nrows), # turn off labels
        data_column_widths=[2=>labwidth],
        table_format=TYPST_TABLE_FORMAT,
        highlighters = [BODY_HL],
        style=typst_std_table_style( pts ),
        formatters=[crosstab_fm] )
    return String(take!(io))
end


function format_gain_lose( title::String, gl :: DataFrame, ::MV_TYPST; cell_prec=0 )::String

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
    hgainlose = TypstHighlighter( (data, r, c)->true,  typst_gainlose )

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
        backend = :typst,
        formatters=[fm_gl],
        data_column_widths = [1=>"25%"],
        highlighters = [hgainlose],
        column_labels=gl_rename_cols( names(gl)),
        alignment=[:l,fill(:r,ncols-1)...],
        table_format=TYPST_TABLE_FORMAT,
        style=typst_std_table_style( pts ),
        title = title )
    return String(take!(io))
end


"""
Our standard costs tables have 4 rows: label, pre values, post values, change.
up_is_good - vector of 1=good 0=don't care -1=bad
"""
function format_std_short_costs(
    df :: DataFrame, ::MV_TYPST;
    up_is_good :: Union{Vector,Nothing} = nothing,
    prec = 2,
    caption = "",
    totals_col :: Int = 9999999 )::String

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
            push!(d, "fill" => rgbstr( BG_NEUTRAL))
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
        if(c == 4) && (v > 0) # plus xx in totals column
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
        table_format=   TYPST_TABLE_FORMAT,
        style=typst_std_table_style( "10pt" ),
        caption = caption )
    return String(take!(io))
end


"""
Catch all with labels in col1, numbers in the rest
"""
function labelled_frame_to_table( df :: DataFrame,  ::MV_TYPST; prec=2 )::String

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
        table_format=  TYPST_TABLE_FORMAT,
        column_labels = ["",pretty.( names(df )[2:end])...],
        style=typst_std_table_style("8pt"),
        data_column_widths = [1=>"20%"],
        alignment=[:l,fill(:r,ncols-1)...],
        highlighters = [hl] )
    return String( take!( io ))
end


