


function format_costs_table(
    incs1 :: DataFrame,
    incs2 :: DataFrame,
    format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    df = costs_dataframe( incs1, incs2 )
    nrows, ncols = size(df)
    # HACK - extra Wealth col at the end which may or may not appear, so...
    up_is_good=COST_UP_GOOD[1:nrows]
    return format_std_short_costs( df, format; up_is_good=up_is_good, prec=0)
    # return format_std_short_costs( df, prec=0, up_is_good=up_is_good,
    #    caption="Tax Liabilities and Benefit Entitlements, £m pa, 2025/26" )
end

function format_ineq_table(
    ineq1 :: InequalityMeasures,
    ineq2 :: InequalityMeasures,
    format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    df = ineq_dataframe( ineq1, ineq2 )
    up_is_good = fill( -1, 6 )
    return format_std_short_costs(
        df,
        format,
        prec=2,
        up_is_good=up_is_good )
end

function format_pov_transitions( df :: DataFrame, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    dfm = fixup_transitions_matrix( df )
    return format_crosstab(dfm, format )
end

function format_mr_transitions( df :: DataFrame, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    dfm = reverse_crosstab( df ) # bad -> good for MRs
    dfm = fixup_transitions_matrix( df )
    return format_crosstab(dfm, format )
end

function format_pov_table(
    pov1 :: PovertyMeasures,
    pov2 :: PovertyMeasures,
    ch1  :: GroupPoverty,
    ch2  :: GroupPoverty,
    format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    df = pov_dataframe( pov1, pov2, ch1, ch2 )
    up_is_good = fill( -1, 7 )
    return format_std_short_costs( df, format; up_is_good=up_is_good, prec=2)
end

function format_gain_lose_table_v2( gl :: NamedTuple, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    lose = Format.format(gl.losers, commas=true, precision=0)
    gain = Format.format(gl.gainers, commas=true, precision=0)
    nc = Format.format(gl.nc, commas=true, precision=0)
    losepct = md_format(100*gl.losers/gl.popn)
    gainpct = md_format(100*gl.gainers/gl.popn)
    ncpct = md_format(100*gl.nc/gl.popn)
    df = DataFrame(
        labels = ["Gainers", "Losers", "Unchanged"],
        counts = [gain, lose, nc ],
        pct = [gainpct, losepct, ncpct]
        )
    # caption = "Individuals living in households where net income has risen, fallen, or stayed the same respectively."
    return labelled_frame_to_table( df, format; labels = ["","",""] )
end

function format_mr_table( mr1, mr2, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    df = mr_dataframe( mr1.hist, mr2.hist, mr1.mean, mr2.mean, mr1.median, mr2.median )
    n = size(df)[1]
    return labelled_frame_to_table(
        df,
        format;
        prec=0 )
end

function run_settings_to_df( settings::Settings)::DataFrame
    df = DataFrame( name=fill("",0), value=fill( "",0 ))
    pov_line_str = if settings.ineq_income_measure ==  pl_from_settings
        "Poverty Line Set to : $(fm( settings.poverty_line))"
    else
        ""
    end
    push!( df, ["ScotBen version", "(string(pkgversion(ScottishTaxBenefitModel)))"] )
    push!( df, ["Incomes uprated to", "$(settings.to_y) q$(settings.to_q)"] )
    push!( df, ["Income Type Used for Poverty/Inequality/Decile Graphs", "$(INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure])"] )
    push!( df, ["Income Type used for Gain-Lose tables", "$(INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure])"])
    push!( df, ["Populations weighed to", "$(settings.weighting_target_year)"] )
    push!( df, ["Poverty Line", "$(POVERTY_LINE_SOURCE_STRS[settings.poverty_line_source])** $(pov_line_str)"])
    push!( df, ["Means-Tested Benefits Phase in assumption", "(MT_ROUTING_STRS[settings.means_tested_routing])"] )
    push!( df, ["Disability Benefits Phase in assumption", "Scottish System 100% phased in."])
    push!( df, ["Dodgy Means-Tested Benefits takeup corrections applied", "$(settings.do_dodgy_takeup_corrections)"] );
    return df
end

function format_run_settings_summary( settings :: Settings, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    return labelled_frame_to_table(run_settings_to_df( settings ), format )
end

function format_detailed_costs( incs1::DataFrame, incs2::DataFrame, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    return labelled_frame_to_table( detailed_cost_dataframe( incs1, incs2 ), format )
end

const AVAILABLE_TABLES = OrderedDict([
    :overall_cost_table => "format_overall_cost(summary.income_summary[1],summary.income_summary[2])",
    :costs_table => "",
    :hhtype_gl => "format_gainlose(By Household Size,summary.gain_lose[2].hhtype_gl )",
    :ten_gl => "format_gainlose(By Tenure Type,summary.gain_lose[2].ten_gl )",
    :dec_gl => "format_gainlose(By Tenure Type,summary.gain_lose[2].dec_gl )",
    :children_gl => "format_gainlose(By Numbers of Children,summary.gain_lose[2].children_gl )",
    :reg_gl => "format_gainlose(By Region,summary.gain_lose[2].reg_gl )",
    :sfc => "format_sfc(SFC Behavioral Corrections, results.behavioural_results[2])",
    :gain_lose_summary => "format_gain_lose_table_v2( summary.gain_lose[2] )",
    :inequality_summary => "format_ineq_table(summary.inequality[1],summary.inequality[2])",
    :metrs_table => "format_mr_table( summary.metrs[1], summary.metrs[2] )",
    :poverty_summary => "format_pov_table( summary.poverty[1],summary.poverty[2],summary.child_poverty[1],summary.child_poverty[2])",
    :poverty_transitions => "format_pov_transitions( summary.povtrans_matrix[2])",
    :run_settings_summary => "format_run_settings_summary( settings )",
    :detailed_costs =>"detailed_cost_dataframe(summary.income_summary[1],summary.income_summary[2])"])

"""
A Named Tuple with all the formatted outputs (except the budget constraints).

"""
function construct_tables( settings::Settings, results::NamedTuple, summary::NamedTuple, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::NamedTuple
    return (;
        overall_cost_table = format_overall_cost( # x
            summary.income_summary[1],
            summary.income_summary[2],
            format ),
        costs_table = format_costs_table( # x
            summary.income_summary[1],
            summary.income_summary[2],
            format ),
        hhtype_gl = format_gain_lose("By Household Size",summary.gain_lose[2].hhtype_gl, format ), # x
        ten_gl = format_gain_lose("By Tenure Type",summary.gain_lose[2].ten_gl, format ),
        dec_gl = format_gain_lose("By Decile",summary.gain_lose[2].dec_gl, format ),
        children_gl = format_gain_lose("By Numbers of Children",summary.gain_lose[2].children_gl, format ),
        reg_gl = format_gain_lose("By Region",summary.gain_lose[2].reg_gl, format ),
        sfc = format_sfc("SFC Behavioral Corrections", results.behavioural_results[2], format), # x
        gain_lose_summary = format_gain_lose_table_v2( summary.gain_lose[2], format ), # x
        # println( io, "<h2>Format HH Summary</h2>\n", format_hh_summary( hh ))
        inequality_summary = format_ineq_table( # x
            summary.inequality[1],
            summary.inequality[2],
            format),
        metrs_table = format_mr_table( summary.metrs[1], summary.metrs[2], format ),
        metrs_transitions = format_mr_transitions( summary.metrs[2].transmat_df, format ), # x
        poverty_summary = format_pov_table( summary.poverty[1], # x
            summary.poverty[2],
            summary.child_poverty[1],
            summary.child_poverty[2],
            format),
        poverty_transitions = format_pov_transitions( summary.povtrans_matrix_df[2], format), # x

        run_settings_summary = format_run_settings_summary( settings, format ), # x
        detailed_costs = format_detailed_costs( # x
                summary.income_summary[1],
                summary.income_summary[2],
                format)
        )
end

function dump_tables( dir::String, tabs :: NamedTuple, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST})
    ext = to_ext( format )
    for (k,v) in pairs( tabs )
        open(joinpath( dir, "$(k).$(ext)"), "w") do io
            println( io, v )
        end
    end
end
