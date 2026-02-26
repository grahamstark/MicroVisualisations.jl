
export DEFAULT_SYS, 
    do_higher_rates_run,
    do_higher_rates_run2,
    draw_bc,
    fes_run, 
    format_bc_df, 
    format_gainlose, 
    format_sfc,
    getbc,
    get_change_target_hhs, 
    get_examples

const DEFAULT_SYS = get_default_system_for_fin_year(2026; scotland=true, autoweekly=false )
    


function zip_dump( settings :: Settings )
    rname = basiccensor( settings.run_name )
    dirname = joinpath( settings.output_dir, rname ) 
    io = ZipFile.Writer("$(dirname).zip")
    for f in readdir(dirname)
        ZipFile.addfile( io, f )
    end
    ZipFile.close(io)
    return dirname
end


h1 = HtmlHighlighter( ( data, r, c ) -> (c == 1), ["font_weight"=>"bold", "color"=>"slategrey"])
# HtmlDecoration( font_weight="bold", color="slategrey"))

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

function format_sfc( title::String, sf :: DataFrame )
    sf[!,1] = pretty.(sf[!,1]) # labels on RHS
    io = IOBuffer()
    pretty_table( 
        io, 
        sf[!,1:end]; 
        backend = :html,
        formatters=[fm3], 
        alignment=[:l,fill(:r,11)...],
        highlighters = [ht],
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

"""

"""
function format_gainlose(title::String, gl::DataFrame)
    gl[!,1] = pretty.(gl[!,1]) # labels on RHS
    io = IOBuffer()
    pretty_table( 
        io, 
        gl[!,1:end-1]; 
        backend = :html,
        formatters=[fm], 
        alignment=[:l,fill(:r,7)...],
        highlighters = [h1,h7],
        title = title,
        column_labels=["",
            "Lose £10.01+",
            "Lose £1.01-£10",
            "No Change",
            "Gain £1.01-£10",
            "Gain £10.01+",
            "Av. Change",
            "Pct. Change"])
    return String(take!(io))
end

function get_examples( 
    settings :: Settings, 
    examples :: AbstractDataFrame;
    systems  :: Vector{TaxBenefitSystem{T}}, 
    rowval::AbstractString, 
    colval::AbstractString) where T <: AbstractFloat
    out = []
    ex = examples[(examples.rowval.==rowval).&(examples.colval.==colval),:]
    for e in eachrow(ex)
        hh = FRSHouseholdGetter.get_household( e.hid, e.data_year )
        results = []
        for sys in systems
            # r1 = to_md_table(do_one_calc( hh, sys, settings ))
            # push!(results, md"$(r1)")
            push!(results, do_one_calc( hh, sys, settings ))
        end
        # push!(out, (; hh=md"$(to_md_table(hh))", results ))
        push!(out, (; hh, results ))
    end
    return out
end

function fmbc(v, r,c) 
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
