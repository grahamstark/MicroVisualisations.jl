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
