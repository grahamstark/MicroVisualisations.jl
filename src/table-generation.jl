


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
    dfm = cleanup_mr_crosstab( df ) # bad -> good for MRs
    dfm = fixup_transitions_matrix( dfm )
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
    push!( df, ["ScotBen version", "$(string(pkgversion(ScottishTaxBenefitModel)))"] )
    push!( df, ["Incomes uprated to", "$(settings.to_y) q$(settings.to_q)"] )
    push!( df, ["Income Type Used for Poverty/Inequality/Decile Graphs", "$(INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure])"] )
    push!( df, ["Income Type used for Gain-Lose tables", "$(INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure])"])
    push!( df, ["Populations weighed to", "$(settings.weighting_target_year)"] )
    push!( df, ["Poverty Line", "$(POVERTY_LINE_SOURCE_STRS[settings.poverty_line_source])** $(pov_line_str)"])
    push!( df, ["Means-Tested Benefits Phase in assumption", "$(MT_ROUTING_STRS[settings.means_tested_routing])"] )
    push!( df, ["Disability Benefits Phase in assumption", "Scottish System 100% phased in."])
    push!( df, ["Dodgy Means-Tested Benefits takeup corrections applied", "$(settings.do_dodgy_takeup_corrections)"] );
    return df
end

function format_run_settings_summary( settings :: Settings, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    return labelled_frame_to_table(run_settings_to_df( settings ), format )
end

function format_detailed_costs( incs1::DataFrame, incs2::DataFrame, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::String
    df = detailed_cost_dataframe( incs1, incs2 )
    return labelled_frame_to_table( df, format; prec=0 )
end

"""
A Named Tuple with all the formatted outputs (except the budget constraints).

"""
function construct_tables( settings::Settings, results::NamedTuple, summary::NamedTuple, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST} )::NamedTuple
    return (;
        overall_cost_table = OneEntry(
            format_overall_cost( # x
                summary.income_summary[1],
                summary.income_summary[2],
                format ),
            "One Line entry showing the net costs of your reform",
            ["pdf", "tpst", "html"] ),
        costs_table = OneEntry(
            format_costs_table( # x
                summary.income_summary[1],
                summary.income_summary[2],
                format ),
            "Short Table with headline costs of your reform",
            ["pdf", "tpst", "html"] ),
        hhtype_gl = OneEntry(
            format_gain_lose("By Household Size",summary.gain_lose[2].hhtype_gl, format ), # x
            "Gain Lose Table By Household Size (counts of individuals)",
            ["pdf", "tpst", "html"] ),
        ten_gl = OneEntry(
            format_gain_lose("By Tenure Type",summary.gain_lose[2].ten_gl, format ),
            "Gain Lose Table By Tenure(counts of individuals)",
            ["pdf", "tpst", "html"] ),
        dec_gl = OneEntry(
            format_gain_lose("By Decile",summary.gain_lose[2].dec_gl, format ),
            "Gain Lose Table By Income Decile(counts of individuals)",
            ["pdf", "tpst", "html"] ),
        children_gl = OneEntry(
            format_gain_lose("By Numbers of Children",summary.gain_lose[2].children_gl, format ),
            "Gain Lose Table By Number of Children in the Household (counts of individuals)",
            ["pdf", "tpst", "html"]),
        reg_gl = OneEntry(
            format_gain_lose("By Region",summary.gain_lose[2].reg_gl, format ),
            "Gain Lose Table By Region (counts of individuals)",
            ["pdf", "tpst", "html"]),
        sfc = OneEntry(
            format_sfc("SFC Behavioral Corrections", results.behavioural_results[2], format), # x
            "Table describing our SFC correction",
            ["pdf", "tpst", "html"]),

        gain_lose_summary = OneEntry(
            format_gain_lose_table_v2( summary.gain_lose[2], format ), # x
            "Short text summary of numbers of gainers and losers",
            ["pdf", "tpst", "html"]),
        # println( io, "<h2>Format HH Summary</h2>\n", format_hh_summary( hh ))
        inequality_summary = OneEntry(
            format_ineq_table( # x
                summary.inequality[1],
                summary.inequality[2],
                format),
            "Short textual summmary of our standard inequality measures.",
            ["pdf", "tpst", "html"]),
        metrs_table = OneEntry(
            format_mr_table( summary.metrs[1], summary.metrs[2], format ),
            "Summary table of our Marginal Rate estimates (if available).",
            ["pdf", "tpst", "html"]),

        metrs_transitions = OneEntry(
            format_mr_transitions( summary.metrs[2].transmat_df, format ), # x
            "Transitions table from our Marginal Rate estimates (if available).",
            ["pdf", "tpst", "html"]),
        poverty_summary = OneEntry(
            format_pov_table( summary.poverty[1], # x
                summary.poverty[2],
                summary.child_poverty[1],
                summary.child_poverty[2],
                format),
            "Short Table with headline poverty measures",
            ["pdf", "tpst", "html"]),
        poverty_transitions = OneEntry(
            format_pov_transitions( summary.povtrans_matrix_df[2], format), # x
            "Summary table of our Poverty estimates (if available).",
            ["pdf", "tpst", "html"]),
        run_settings_summary = OneEntry(
            format_run_settings_summary( settings, format ), # x
            "Highlights from the run settings",
            ["pdf", "tpst", "html"]),
        detailed_costs = OneEntry(
            format_detailed_costs( # x
                summary.income_summary[1],
                summary.income_summary[2],
                format),
            "Huge dump of all incomes and case counts from the run.",
            ["pdf", "tpst", "html"])
        )
end

function dump_tables( dir::String, tabs :: NamedTuple, format::Union{MV_MARKDOWN,MV_HTML,MV_TYPST})
    ext = to_ext( format )
    for (k,v) in pairs( tabs )
        println( "on $k")
        open(joinpath( dir, "$(k).$(ext)"), "w") do io
            println( io, v.data )
        end
    end
end
