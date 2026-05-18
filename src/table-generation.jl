


function format_costs_table( incs1 :: DataFrame, incs2 :: DataFrame )
    df = costs_dataframe( incs1, incs2 )
    nrows, ncols = size(df)
    # HACK - extra Wealth col at the end which may or may not appear, so...
    up_is_good=COST_UP_GOOD[1:nrows]
    return frame_to_table( df, prec=0, up_is_good=up_is_good,
        caption="Tax Liabilities and Benefit Entitlements, £m pa, 2025/26" )
end



"""
A Named Tuple with all the formatted outputs (except the budget constraints).

"""
function construct_tables( settings::Settings, results::NamedTuple, summary::NamedTuple, format::Union{MV_MARKDOWN,MV_HTML_MV_TYPST} )::NamedTuple
    return (;
        overall_cost_table = format_overall_cost(
            summary.income_summary[1],
            summary.income_summary[2],
            format ),
        costs_table = format_costs_table(
            summary.income_summary[1],
            summary.income_summary[2],
            format ),
        hhtype_gl = format_gainlose("By Household Size",summary.gain_lose[2].hhtype_gl, format ),
        ten_gl = format_gainlose("By Tenure Type",summary.gain_lose[2].ten_gl, format ),
        dec_gl = format_gainlose("By Decile",summary.gain_lose[2].dec_gl, format ),
        children_gl = format_gainlose("By Numbers of Children",summary.gain_lose[2].children_gl, format ),
        reg_gl = format_gainlose("By Region",summary.gain_lose[2].reg_gl, format ),
        sfc = format_sfc("SFC Behavioral Corrections", results.behavioural_results[2], format),
        gain_lose_summary = format_gain_lose_table_v2( summary.gain_lose[2], format ),
        # println( io, "<h2>Format HH Summary</h2>\n", format_hh_summary( hh ))
        inequality_summary = format_ineq_table(
            summary.inequality[1],
            summary.inequality[2],
            format),
        metrs_table = format_mr_table( summary.metrs[1], summary.metrs[2], format ),
        poverty_summary = format_pov_table( summary.poverty[1],
            summary.poverty[2],
            summary.child_poverty[1],
            summary.child_poverty[2],
            format),
        poverty_transitions = format_pov_transitions( summary.povtrans_matrix[2], format),
        run_settings_summary = format_run_settings_summary( settings ),
        detailed_costs = costs_frame_to_table(detailed_cost_dataframe(
                summary.income_summary[1],
                summary.income_summary[2],
                format))
        )
end
