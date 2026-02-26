
const FAMDIR = "budget" # old budget images; alternative is 'keiko' for VE images

function thing_table(
    names::Vector{String}, 
    v1::Vector, 
    v2::Vector, 
    up_is_good::Vector{Int} )

    table = "<table class='table'>"
    table *= "<thead>
        <tr>
            <th></th><th>Before</th><th>After</th><th>Change</th>
        </tr>
        </thead>"

    diff = v2 - v1
    n = size(names)[1]
    rows = []
    for i in 1:n
        colour = "text-primary"
        if (up_is_good[i] !== 0) && (! (diff[i] ≈ 0))
            if diff[i] > 0
                colour = up_is_good[i] == 1 ? "text-success" : "text-danger"
             else
                colour = up_is_good[i] == 1 ? "text-danger" : "text-success"
            end # neg diff   
        end # non zero diff
        ds = diff[i] ≈ 0 ? "-" : fp(diff[i])
        row = "<tr><td>$(names[i])</td><td style='text-align:right'>$(f2(v1[i]))</td><td style='text-align:right'>$(f2(v2[i]))</td><td class='text-right $colour'>$ds</td></tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end

function costs_frame_to_table(
    df :: DataFrame )
    caption = "Values in £m pa; numbers of individuals paying or receiving."
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th colspan='2'>Before</th><th colspan='2'>After</th><th colspan=2>Change</th>            
        </tr>
        <tr>
            <th></th><th style='text-align:right'>Costs £m</th><th style='text-align:right'>(Counts)</th>
            <th style='text-align:right'>Costs £m</th><th style='text-align:right'>(Counts)</th>
            <th style='text-align:right'>Costs £m</th><th style='text-align:right'>(Counts)</th>
        </tr>
        </thead>"
    table *= "<caption>$caption</caption>"
    i = 0
    for r in eachrow( df )
        i += 1
        #=
        colour = ""
        if (up_is_good[i] !== 0) && (! (r.Change ≈ 0))
            if r.Change > 0
                colour = up_is_good[i] == 1 ? "text-success" : "text-danger"
             else
                colour = up_is_good[i] == 1 ? "text-danger" : "text-success"
            end # neg diff   
        end # non zero diff
        =#
        # fixme to a function
        dv = r.dval ≈ 0 ? "-" : format(r.dval, commas=true, precision=1 )
        if dv != "-" && r.dval > 0
            dv = "+$(dv)"
        end 
        dc = r.dcount ≈ 0 ? "-" : format(r.dcount, commas=true, precision=0 )
        if dc != "-" && r.dcount > 0
            dc = "+$(dc)"
        end 
        v1 = format(r.value1, commas=true, precision=1)
        c1 = format(r.count1, commas=true, precision=0)
        v2 = format(r.value2, commas=true, precision=1)
        c2 = format(r.count2, commas=true, precision=0)
        row = "<tr><th class='text-left'>$(r.Item)</th>
                  <td style='text-align:right'>$v1</td>
                  <td style='text-align:right'>($c1)</td>
                  <td style='text-align:right'>$v2</td>
                  <td style='text-align:right'>($c2)</td>
                  <td style='text-align:right'>$dv</td>
                  <td style='text-align:right'>($dc)</td>
                </tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end

"""
FIXME replace with PrettyTables version
"""
function frame_to_table(
    df :: DataFrame;
    up_is_good :: Vector{Int},
    prec :: Int = 2, 
    caption :: String = "",
    totals_col :: Int = -1 )
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th style='text-align:right'>Before</th><th style='text-align:right'>After</th><th style='text-align:right'>Change</th>            
        </tr>
        </thead>"
    table *= "<caption>$caption</caption>"
    i = 0
    for r in eachrow( df )
        i += 1
        colour = ""
        if (up_is_good[i] !== 0) && (! (r.Change ≈ 0))
            if r.Change > 0
                colour = up_is_good[i] == 1 ? "change-good" : "change-bad"
             else
                colour = up_is_good[i] == 1 ? "change-bad" : "change-good"
            end # neg diff   
        end # non zero diff
        ds = r.Change ≈ 0 ? "-" : format(r.Change, commas=true, precision=prec )
        if ds != "-" && r.Change > 0
            ds = "+$(ds)"
        end 
        row_style = i == totals_col ? "class='text-bold table-info' " : ""
        b = format(r.Before, commas=true, precision=prec)
        a = format(r.After, commas=true, precision=prec)
        row = "<tr $row_style><th class='text-left' align='left'>$(r.Item)</th>
                  <td style='text-align:right' align='right'>$b</td>
                  <td style='text-align:right' align='right'>$a</td>
                  <td style='text-align:right'  align='right' class='$colour'>$ds</td>
                </tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end

export costs_table, overall_cost, mr_table

function format_costs_table( incs1 :: DataFrame, incs2 :: DataFrame )
    df = costs_dataframe( incs1, incs2 )
    nrows, ncols = size(df)
    # HACK - extra Wealth col at the end which may or may not appear, so...
    up_is_good=COST_UP_GOOD[1:nrows]
    return frame_to_table( df, prec=0, up_is_good=up_is_good, 
        caption="Tax Liabilities and Benefit Entitlements, £m pa, 2025/26" )
end


function format_overall_cost( incs1:: DataFrame, incs2:: DataFrame ) :: String
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

function format_mr_table( mr1, mr2 )
    df = mr_dataframe( mr1.hist, mr2.hist, mr1.mean, mr2.mean )
    n = size(df)[1]
    table = frame_to_table( 
        df, 
        prec=0, 
        up_is_good=MR_UP_GOOD, 
        caption="",
        totals_col = n )   
    return table
end


function format_ineq_table( ineq1 :: InequalityMeasures, ineq2 :: InequalityMeasures )
    df = ineq_dataframe( ineq1, ineq2 )
    up_is_good = fill( -1, 6 )
    return frame_to_table( 
        df, 
        prec=2, 
        up_is_good=up_is_good )
end


function format_pov_table(
    pov1 :: PovertyMeasures, 
    pov2 :: PovertyMeasures,
    ch1  :: GroupPoverty, 
    ch2  :: GroupPoverty )
    df = pov_dataframe( pov1, pov2, ch1, ch2 )
    up_is_good = fill( -1, 7 )
    return frame_to_table( 
        df, 
        prec=2, 
        up_is_good=up_is_good )
end


function format_gain_lose_table_v2( gl :: NamedTuple )
    lose = format(gl.losers, commas=true, precision=0)
    gain = format(gl.gainers, commas=true, precision=0)
    nc = format(gl.nc, commas=true, precision=0)
    losepct = md_format(100*gl.losers/gl.popn)
    gainpct = md_format(100*gl.gainers/gl.popn)
    ncpct = md_format(100*gl.nc/gl.popn)
    caption = "Individuals living in households where net income has risen, fallen, or stayed the same respectively."
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th style='text-align:right'></th><th style='text-align:right'>%</th>
        </tr>";
    table *= "<caption>$caption</caption>"
    table *= "
        </thead>
        <tbody>"
        table *= "<tr><th>Gainers</th><td style='text-align:right'>$gain</td><td style='text-align:right'>$(gainpct)</td></tr>"
        table *= "<tr><th>Losers</th><td style='text-align:right'>$lose</td><td style='text-align:right'>$(losepct)</td></tr>"
    table *= "<tr><th>Unchanged</th><td style='text-align:right'>$nc</td><td style='text-align:right'>$(ncpct)</td></tr>"
    table *= "</tbody></table>"
    return table
end
#=
 choice of arrows/numbers for the tables - we use various uncode blocks;
 see: https://en.wikipedia.org/wiki/Arrow_(symbol)
 Of 'arrows', only 'arrows_3' displays correctly in Windows, I think,
 arrows_1 is prettiest
=#

    
function make_example_card( hh :: ExampleHH, res :: NamedTuple ) :: String
    change = res.pres.bhc_net_income - res.bres.bhc_net_income
    ( gnum, glclass, glstr ) = format_and_class( change )
    i2sp = inctostr(res.pres.income )
    i2sb = inctostr(res.bres.income )
    changestr = gnum != "" ? "&nbsp;"*ARROWS_1[glstr]*"&nbsp;&pound;"* gnum*"pw" : "No Change"
    card = "

    <div class='card' 
        style='width: 12rem;' 
        data-bs-toggle='modal' 
        data-bs-target='#$(hh.picture)' >
            <img src='images/families/$(FAMDIR)/$(hh.picture).png'  
                alt='Picture of Family'  width='100' height='140' />
            <div class='card-body'>
                <p class='$glclass'><strong>$changestr</strong></p>
                <h5 class='card-title'>$(hh.label)</h5>
                <p class='card-text'>$(hh.description)</p>
            </div>
        </div><!-- card -->
";
    @debug "card=$card"
    return card
end

function format_pers_inc_table( res :: NamedTuple ) :: String
    df = two_incs_to_frame( res.bres.income, res.pres.income )
    n = size(df)[1]
    up_is_good = zeros(Int, n )  
    df.Item = fill("",n)
    df.Change = df.After - df.Before
    df.Item = iname.(df.Inc)
    for i in 1:n
       up_is_good[i] = (df[i,:Inc] in DIRECT_TAXES_AND_DEDUCTIONS) ? -1 : 1
    end
    return frame_to_table( df, prec=2, up_is_good=up_is_good, 
        caption="Household incomes £pw" )    
end

function format_hh_summary( hh :: Household )
    caption = ""
    ten = pretty(hh.tenure)
    rm = "Rent"
    hc = format( hh.gross_rent, commas=true, precision=2)
    if is_owner_occupier( hh.tenure )
        hc = format(hh.mortgage_payment, commas=true, precision=2)
        rm = "Mortgage"
    end
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th style='text-align:right'></th>
        </tr>";
    table *= "<caption>$caption</caption>"
    table *= "
        </thead>
        <tbody>"
    table *= "<tr><th>Tenure</th><td style='text-align:right'>$ten</td></tr>"
    table *= "<tr><th>$rm</th><td style='text-align:right'>$hc</td></tr>"
    # ... and so on
    table *= "</tbody></table>"
    table
end

function make_popups( hh :: ExampleHH, res :: NamedTuple ) :: String

    pit = pers_inc_table( res )
    hhtab = hhsummary( hh.hh )
    modal = """
<!-- Modal -->
<div class='modal fade' id='$(hh.picture)' tabindex='-1' role='dialog' aria-labelledby='$(hh.picture)-label' aria-hidden='true'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      <div class='modal-header'>
      <h5 class='modal-title' id='$(hh.picture)-label'/>$(hh.label)</h5>
      <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
         
      </div> <!-- header -->
      <div class='modal-body'>
        <div class='row'>
            <div class='col'>
            <img src='images/families/$(FAMDIR)/$(hh.picture).png'  
                width='100' height='140'
                alt='Picture of Family'
              />
            </div>
            <div class='col'>
                $hhtab
            </div>
        </div>
        
        $pit
          
      </div> <!-- body -->
    </div> <!-- content -->
  </div> <!-- dialog -->
</div><!-- modal container -->
"""
    @debug modal
    return modal
end

function make_examples( example_results :: Vector )
    cards = "<div class='card-group'>"
    n = size( EXAMPLE_HHS )[1]
    for i in 1:n
        cards *= make_example_card( EXAMPLE_HHS[i], example_results[i])
    end
    cards *= "</div>"
    for i in 1:n
        cards *= make_popups( EXAMPLE_HHS[i], example_results[i])
    end
    return cards;
end

function make_short_summary( summary :: NamedTuple )::NamedTuple
    r1 = summary.income_summary[1][1,:]
    r2 = summary.income_summary[2][1,:]
    net1 = r1.net_inc_indirect
    net2 = r2.net_inc_indirect

    ben1 = r1.total_benefits
    ben2 = r2.total_benefits
    tax1 = r1.income_tax+r1.national_insurance+r1.employers_ni
    tax2 = r2.income_tax+r2.national_insurance+r2.employers_ni
    dtax = tax2 - tax1
    dben = ben2 - ben1
    netcost = net1 - net2 # note: other way around
    netdirect = dtax - dben
    palma1 = summary.inequality[1].palma
    palma2 = summary.inequality[2].palma
    dpalma = palma2 - palma1
    gini1 = summary.inequality[1].gini
    gini2 = summary.inequality[2].gini
    dgini = gini2 - gini1
    s1 = summary.poverty[1]
    s2 = summary.poverty[2]
    pr1 = s1.foster_greer_thorndyke[1]
    pr2 = s2.foster_greer_thorndyke[1]
    prch = s2.foster_greer_thorndyke[1]-s1.foster_greer_thorndyke[1]
    ncexcess = (netcost/1_000_000) - 4_000 # fixme parameterise
    ncpts = if ncexcess > 500 #res.netcost
        4 # "much too high"
    elseif ncexcess > 100
        3 # "slightly too high"
    elseif ncexcess < -100
        0 # "money to spend"
    else
        0 # "fine"
    end
    povexess = 0.03 + prch
    povpts = if povexess > 0.04
        4 # "too high"
    elseif povexess > 0.01
        2
    else
        0 # fine
    end
    score = povpts + ncpts
    response = if score == 0
        msg = "Well done: you've hit the poverty target and remained within budget."
        correct( md"$msg")
    elseif score < 3
        msg = "You're close to getting a successful policy, but not quite there. "
        if povpts > 0
            msg *= "Poverty, at $(fp(pr2)) represents a cut of less than 3%.Consider increasing the social security benefits, or targetting social security more on the poor. "
        end
        if ncpts > 0
            msg *= "At $(fm(netcost)), you are quite a bit over your £4bn net spend budget. Consider increasing taxes or cutting benefits. "
        end
        almost( msg )
    else
        msg = "You're quite far away. "
        if povpts > 0
            msg *= "Poverty, at $(fp(pr2)) represents a cut of less than 3%.Consider increasing the social security benefits, or targetting social security more on the poor. "
        end
        if ncpts > 0
            msg *= "At $(fm(netcost)), you are quite a bit over your £4bn net spend budget. Consider increasing taxes or cutting benefits. "
        end
        keep_working( msg )
    end

    (;
    response = response,
    netcost = fmz( netcost ),
    netdirect = fmz( netdirect ),
    povrate1 = fp(pr1),
    povrate2 = fp(pr2),
    dpovrate = fp( prch ),
    ben1 = fm( ben1 ),
    ben2 = fm( ben2 ),
    dben = fm(dben),
    gini1=fp(gini1),
    gini2=fp(gini2),
    palma1=fp(palma1),
    palma2=fp(palma2),
    dpalma=fp(dpalma),
    dgini=fp(dgini),
    tax1=fm( tax1 ),
    tax2=fm( tax2 ),
    dtax=fm( dtax ),
    gainers=fc( summary.gain_lose[2].gainers ),
    losers=fc( summary.gain_lose[2].losers ),
    nc = fc( summary.gain_lose[2].nc) )
end

const sevcols = [
        "#ee0000",
        "#cc2222",
        "#990000",
        "#666666",
        "#333333",
        "#333333"]


function one_row( label::String, v :: Vector, r::Int )::String
    s = "<tr><th style='color:$(sevcols[r])'>$label</th>"
    for i in 1:5
        bgcol = if r == 6
            "#dddddd"
        elseif i < r
            "#ffccbb"
        elseif i > r
            "#bbffdd"
        else
            "#dddddd"
        end
        cell = "<td style='text-align:right;background:$bgcol;color:$(sevcols[i])'>$(v[i])</td>"
        s *= cell
    end
    cell = "<td style='text-align:right;background:#cccccc;color:$(sevcols[r])'>$(v[6])</td>"
    s *= cell
    s *= "</tr>"
    s
end

function format_pov_transitions( trans::Matrix )::String
    labels = ["V.Deep (<=30%)",
              "Deep (<=40%)",
              "In Poverty (<=60%)",
              "Near Poverty (<=80%)",
              "Not in Poverty",
             "Total"]
    vs = fb.(trans)
    cells = ""
    for r in 1:6
        cells *= one_row( labels[r], vs[r,:], r )
    end

    return """
<table width='100%' style=''>
<thead></thead>
<tr><th colspan='7'>After</th>
<tr><th rowspan='9'>Before</th>
<tr>
    <th></th>
    <th style='color:$(sevcols[1])'>$(labels[1])</th>
    <th style='color:$(sevcols[2])'>$(labels[2])</th>
    <th style='color:$(sevcols[3])'>$(labels[3])</th>
    <th style='color:$(sevcols[4])'>$(labels[4])</th>
    <th style='color:$(sevcols[5])'>$(labels[5])</th>
    <th style='color:$(sevcols[6])'>$(labels[6])</th>
</tr>
$cells
</table>
"""
end # pov_summary


function format_run_settings_summary( settings :: Settings )::AbstractString

    pov_line_str = if settings.ineq_income_measure ==  pl_from_settings
            " - Poverty Line Set to : ** $(fm( settings.poverty_line))**"
    else
            ""
    end

    return Markdown.html(md"""

### Run Settings Summary

* ScotBen version: **$(string(pkgversion(ScottishTaxBenefitModel)))**
* Incomes uprated to: **$(settings.to_y)** q**$(settings.to_q)**;
* Income Type Used for Poverty/Inequality/Decile Graphs: **$(INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure])**;
* Income Type used for Gain-Lose tables: **$(INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure])**
* Populations weighed to: **$(settings.weighting_target_year)**;
* Poverty Line :**$(POVERTY_LINE_SOURCE_STRS[settings.poverty_line_source])** $(pov_line_str);
* Means-Tested Benefits Phase in assumption: **$(MT_ROUTING_STRS[settings.means_tested_routing])**;
* Disability Benefits Phase in assumption: **Scottish System 100% phased in**;
* Dodgy Means-Tested Benefits takeup corrections applied: **$(settings.do_dodgy_takeup_corrections)**;
""" )

end

function format_bc_df( title::String, bc::DataFrame)
    io = IOBuffer()
    nr,nc = size(bc)
    pretty_table(
        io,
        bc[!,[:char_labels,:gross,:net,:mr]], #,:cap,:reduction,:html_label]];
        backend = :html,
        formatters=[fmbc],
        allow_html_in_cells=true,
        title = title,
        table_class="table table-sm table-striped table-responsive",
        column_labels = ["ID", "Earnings &pound;pw","Net Income BHC &pound;pw", "METR"], #"Benefit Cap", "Benefits Reduced By","Breakdown"],
        alignment=[fill(:r,3)...,:l] )
    return String(take!(io))
end
