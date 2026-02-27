# 2nd bit is opacity

const GOLDEN_RATIO = 1.618

function make_default_fig(; thumbnail = false, double_height=false, square=false )::Figure
    x,fontsize = if thumbnail
        200,
        10
    else
        2100,
        25
    end
    y = Int( floor( x/GOLDEN_RATIO))
    if double_height
        y *= 2
    elseif square
        y = x
    end
    return Figure(size=(x,y), fontsize = fontsize, fonts = (; regular = "Gill Sans"))
end

"""
List of colours for barcharts that change from col1->col2 and back
when the bars step over a decile. Approximate.
* `bins`: breaks e.g every £10
* `deciles` 10x4 matrix from PovertyInequality - we want :,3 - decile breaks
"""
function make_colourbins( input_colours, bins::Vector, deciles::Matrix )
@argcheck length( input_colours ) >= 2
    nbins = length(bins)-1
    colours = fill(input_colours[1],nbins)
    decile = 1
    colourno = 1
    for i in 1:nbins
        if bins[i] > deciles[decile,3] # next decile - swap colour.
            colourno = if colourno == 1
                2
            else 
                1
            end
            decile += 1
        end
        colours[i] = input_colours[colourno]        
    end
    colours
end

"""
kinda sorta copy of fig 5 from: https://www.gov.uk/government/statistics/households-below-average-income-for-financial-years-ending-1995-to-2024/households-below-average-income-an-analysis-of-the-uk-income-distribution-fye-1995-to-fye-2024

* `results` STBOutput main results dump (incomes individual)
* `summary` STBOutput results summary dump (means, medians)
"""
function draw_hbai_clone!( 
    f :: Figure, 
    results :: NamedTuple, 
    summary :: NamedTuple; 
    title :: AbstractString,
    subtitle :: AbstractString,
    bandwidth=10.0,
    sysno::Int, 
    measure::Symbol, 
    colours )
    edges = collect(0:bandwidth:2200)
    ih = summary.income_hists[sysno]
    ax = Axis( f[sysno,1], 
        title=title, 
        subtitle=subtitle,
        xlabel="£s pw, in £$(gf0(bandwidth)) bands; shaded bands represent deciles.", 
        ylabel="Counts",
        ytickformat = gft)
    deciles = summary.deciles[sysno]
    deccols = make_colourbins( colours, edges, deciles ) #ih.hist.edges[1], summary.deciles[1])
    incs = deepcopy(results.hh[sysno][!,measure])
    incs = max.( 0.0, incs )
    incs = min.(2200, incs )
    h = hist!( ax, 
        incs;
        weights=results.hh[sysno].weighted_people,
        bins=edges, 
        color = deccols )
    mheight=10_000*bandwidth # arbitrary height for mean/med lines
    povline = ih.median*0.6
    v1 = lines!( ax, [ih.mean,ih.mean], [0, mheight]; color=:chocolate4, label="Mean £$(gf2(ih.mean))", linestyle=:dash )
    v2 = lines!( ax, [ih.median,ih.median], [0, mheight]; color=:grey16, label="Median £$(gf2(ih.median))", linestyle=:dash )
    v3 = lines!( ax, [povline,povline], [0, mheight]; color=:olivedrab4, label="60% of median £$(gf2(povline))", linestyle=:dash )
    axislegend(ax)
    return ax
end

"""
* `results` STBOutput main results dump (incomes individual)
* `summary` STBOutput results summary dump (means, medians)
"""
function draw_hbai_thumbnail!(
    f :: Figure, 
    results :: NamedTuple, 
    summary :: NamedTuple;
    title :: AbstractString,
    col = 1,
    row = 2,
    bandwidth=20.0,
    sysno::Int, 
    measure::Symbol, 
    colours )
    edges = collect(0:bandwidth:2200)
    ih = summary.income_hists[sysno]
    ax = Axis( f[row,col], title=title, yticklabelsvisible=false)
    deciles = summary.deciles[sysno]
    deccols = make_colourbins( colours, edges, deciles ) #ih.hist.edges[1], summary.deciles[1])
    incs = deepcopy(results.hh[sysno][!,measure])
    incs = max.( 0.0, incs )
    incs = min.(2200, incs )
    h = hist!( ax, 
        incs;
        weights=results.hh[sysno].weighted_people,
        bins=edges, 
        color = deccols )
    mheight=10_000*bandwidth # arbitrary height for mean/med lines
    povline = ih.median*0.6
    v1 = lines!( ax, [ih.mean,ih.mean], [0, mheight]; color=:chocolate4, label="Mean £$(gf2(ih.mean))", linestyle=:dash )
    v2 = lines!( ax, [ih.median,ih.median], [0, mheight]; color=:grey16, label="Median £$(gf2(ih.median))", linestyle=:dash )
    v3 = lines!( ax, [povline,povline], [0, mheight]; color=:olivedrab4, label="60% of median £$(gf2(povline))", linestyle=:dash )
    return ax
end

"""

"""
function draw_hbai_thumbnail(
    results :: NamedTuple,
    summary :: NamedTuple;
    title :: AbstractString,
    col = 1,
    row = 1,
    bandwidth=20.0,
    sysno::Int,
    measure::Symbol,
    colours )
    f = make_default_fig(;thumbnail=true)
    draw_hbai_thumbnail!(
        f,
        results,
        summary;
        title,
        col,
        row,
        bandwidth,
        sysno,
        measure,
        colours )
    f
end


function draw_deciles_barplot!( f::Figure, summary::NamedTuple; row=1, col=1, percentages = false, thumbnail=false )
    ax = if thumbnail
        Axis(f[row,col] )
    else
        dch, ylabel = if percentages
            100.0 .* (summary.deciles[2][:, 4] .- summary.deciles[1][:, 4]) ./ summary.deciles[1][:, 4],
            "% Change"
        else
            summary.deciles[2][:, 4] .- summary.deciles[1][:, 4],
            "Change in £s per week"
        end
        Axis(f[row,col]; title="Income Changes By Decile",
            ylabel=ylabel, xlabel="Decile" )
    end
    maxy = max( 1.0, maximum(dch))
    miny = min( -1.0, minimum(dch))
    ylims!( ax, miny, maxy )
    barplot!( ax, dch)
    ax
end

function draw_deciles_barplot( summary::NamedTuple; row=1, col=1, percentages = false, thumbnail=false )
    f = make_default_fig(;thumbnail=thumbnail)
    draw_deciles_barplot!( f, summary; row=row, col=col, percentages = percentages )
    f
end

function draw_metrs_hist!( f::Figure, results :: NamedTuple; row=1, col=1, thumbnail=false )::Axis
    ax = if thumbnail
        Axis(f[row,col])
    else
        Axis(f[row,col]; title="METRs", xlabel="%", ylabel="")
    end
    for i in 1:2 # fixme multiple systems
        ind = results.indiv[i]
        m1=ind[.! ismissing.(ind.metr),:]
        m1.metr = Float64.( m1.metr ) # Coerce away from missing type.
        m1.metr = min.( 200.0, m1.metr )
        label, colour = if i == 1
            "Before", PRE_COLOUR
        else
            "After", POST_COLOUR
        end
        density!( ax, m1.metr; label, weights=m1.weight, color=colour)
    end
    return ax
end

function draw_metrs_hist( results :: NamedTuple; row=1, col=1, thumbnail=false )::Axis
    f = make_default_fig(;thumbnail=thumbnail)
    draw_metrs_hist!( f, results; row=row, col=col, thumbnail=thumbnail )
    f
end


"""
* `results` STBOutput main results dump (incomes individual)
* `summary` STBOutput results summary dump (means, medians)
"""
function draw_summary_graphs(
    settings::Settings,  
    results :: NamedTuple, 
    summary :: NamedTuple )::Figure
    f = make_default_fig(;)
    ax1 = draw_hbai_thumbnail!( f, results, summary;
        title="Income Distribution - Before",
        col = 1,
        row = 1,
        sysno = 1,
        bandwidth=20,
        measure=Symbol(string(settings.ineq_income_measure )),
        colours=PRE_COLOURS)
    ax2 = draw_hbai_thumbnail!( f, results, summary;
        title="Income Distribution - After",
        col = 1,
        row = 2,
        sysno = 2,
        bandwidth=20,
        measure=Symbol(string(settings.ineq_income_measure )),
        colours=POST_COLOURS)
    linkxaxes!( ax1, ax2 )
    linkyaxes!( ax1, ax2 )
    ax3 = draw_deciles_barplot!( f, summary; row=1, col=2, percentages = false )
    if settings.do_marginal_rates 
        ax4 = draw_metrs_hist!( f, results; row=2, col=2 )
    end
    f
end

"""
* `results` STBOutput main results dump (incomes individual)
* `summary` STBOutput results summary dump (means, medians)
"""
function draw_hbai_graphs(
    settings::Settings,
    results :: NamedTuple, 
    summary :: NamedTuple )
    f = make_default_fig(;double_height=true)
    ax1 = draw_hbai_clone!( f, results, summary;
        title="Incomes: Pre",
        subtitle=INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure ],
        sysno = 1,
        bandwidth=10, # £10 steps - £20 looks prettier but the deciles don't line up so well
        measure=Symbol(string(settings.ineq_income_measure )),
        colours=PRE_COLOURS)
    ax2 = draw_hbai_clone!( f, results, summary;
        title="Incomes: Post",
        subtitle=INEQ_INCOME_MEASURE_STRS[settings.ineq_income_measure ],
        sysno = 2,
        bandwidth=10,
        measure=Symbol(string(settings.ineq_income_measure )),
        colours=POST_COLOURS)
    linkxaxes!( ax1, ax2 )
    linkyaxes!( ax1, ax2 )
    f
end 

function make_rate_bins( 
    colourstr::String, 
    edges::AbstractVector,
	rates::AbstractVector,
    bands::AbstractVector )
    @assert all(rates .<= 1.0)
    lr = length(rates) 
    lb = length(bands)
    @assert (lr - lb) in 0:1
    cbands = deepcopy(bands)
    if lr > lb
        push!( cbands, typemax( eltype( bands )))
        lb = length(cbands)
    end
    nbins = length(edges)-1
    # map of colors based on the tax rate levels and some base colo[u]r
    # NO - rates are often too close together
    # see: https://juliagraphics.github.io/Colors.jl/stable/constructionandconversion/
    # basecolor = parse( Colorant, colourstr )
    # colmap = alphacolor.((basecolor,), rates)
    colmap = colormap(colourstr, lr+2)[2:end] # 1st one is usually too light
    colours = fill( colmap[1], nbins )
    rb = 1
	colno = 2
    for i in 1:nbins
        if (edges[i] >= cbands[rb]) # next shade
	        rb += 1
			colno += 1
        end
        colours[i] = colmap[colno]
    end
    return colours, colmap
end

function draw_incomes_vs_bands!( 
	f :: Figure;
	rates :: AbstractArray,
	bands :: AbstractArray,
	results :: NamedTuple, 
	title :: AbstractString,
	subtitle :: AbstractString,
	bandwidth=10.0,
	sysno::Int, 
	measure::Symbol, 
	colour :: String ) 
	edges = collect(0:bandwidth:3000)
	incs = deepcopy(results.income[sysno][!,measure])
	positive_incs = incs.>0.0
	incs = incs[ positive_incs ]
	weight = results.income[sysno].weight[positive_incs]
	ax = Axis( 
		f[sysno,1], 
		title=title, 
		subtitle=subtitle,
		xlabel="£s pw, in £$(gf0(bandwidth)) bands; shaded bands represent Scottish Income Tax bands.",
		ylabel="Counts",
		ytickformat = gft)
	ratecols, colourmap = make_rate_bins( colour, edges, rates, bands )
	incs = max.( 0.0, incs )
	incs = min.(3000, incs )
	h = hist!( ax, 
		incs;
		weights=weight,
		bins=edges, 
		color = ratecols )
	mheight=10_000*bandwidth # arbitrary height for mean/med lines
	mean = StatsBase.mean( incs, StatsBase.Weights( weight ))
	median = StatsBase.median( incs, StatsBase.Weights( weight ))
	v1 = lines!( ax, [mean,mean], [0, mheight]; color=:chocolate4, label="Mean £$(gf2(mean))", linestyle=:dash )
	v2 = lines!( ax, [median,median], [0, mheight]; color=:grey16, label="Median £$(gf2(median))", linestyle=:dash )
	axislegend(ax)
	# draw the pseudo key top right
	i = 2 # start at color 2 as in the graph since col1 is too light
    ytext = mheight-12_000 # draw downwards - 8000 turns out to be roughly right for height
    # 
	for r in rates 
		rs = r*100
		text!( 2800, ytext; 
			   text = "\u2588", 
			   color=colourmap[i], 
			   fontsize=40, 
			   font = "Gill Sans" ) 
		text!( 2900, ytext; 
			   text = "$(rs)%", 
			   color=:black, 
			   fontsize=30, 
			   font = "Gill Sans" ) 
                
		ytext -= 5000
		i += 1
	end
    ylims!(ax, 0, 100_000) 
    xlims!(ax, 0, edges[end])   
	return ax, edges[end]
end

function draw_tax_rates(
    f :: Figure;
    rates :: AbstractArray,
	bands :: AbstractArray,
    sysno :: Int,
    endx  :: Number,
    colour  )
    ax = Axis( f[sysno,1], 
        yaxisposition = :right, 
        xticksvisible=false, 
        xlabelvisible=false,
        xticklabelsvisible = false,
        ylabel="Marginal Rate (%)" )
    T = eltype(rates)
    b = T[] #copy(bands) 
    r = T[] # copy(rates) .* 100
    nr = length(rates)
    nb = length(bands)
    if nr == nb
        nb -= 1
    end # skip top band if set to a big number
    band = 0.0
    for i in 1:nr
        push!(b,band)
        if i <= nb
            band = bands[i]
            push!(b,band)
        else
            push!(b,endx)
        end
        push!(r,rates[i])
        push!(r,rates[i])
    end
    # @show r
    # @show b
    r .*= 100
    @assert length(b) == length(r)
    ylims!(ax, 0, 100)
    lines!(ax, b, r; color=colour, linewidth=3 )
    hidespines!(ax)
    return ax
end

function draw_taxable_graph(
    settings::Settings, 
	results :: NamedTuple, 
    summary :: NamedTuple, 
    systems :: Vector )
	f = make_default_fig(;double_height=true)
    ax1,endb1 = draw_incomes_vs_bands!(
		f;
		rates = systems[1].it.non_savings_rates,
		bands = systems[1].it.non_savings_thresholds,
		results=results, 
		title="Distribution of Scottish Non-Savings Taxable Income", 
		subtitle="Pre System", 
		sysno=1, 
		measure=:it_non_savings_taxable, 
		colour="Blues" )
	ax1a = draw_tax_rates(
        f;
        rates = systems[1].it.non_savings_rates,
		bands = systems[1].it.non_savings_thresholds,
        sysno = 1,
        endx  = endb1,
        colour = :darkblue )	
	ax2, endb2 = draw_incomes_vs_bands!(
		f;
		rates = systems[2].it.non_savings_rates,
		bands = systems[2].it.non_savings_thresholds,
		results=results, 
		title="", 
		subtitle="Post System", 
		sysno=2, 
		measure=:it_non_savings_taxable, 
		colour="Oranges" )
	ax2a = draw_tax_rates(
        f;
        rates = systems[2].it.non_savings_rates,
		bands = systems[2].it.non_savings_thresholds,
        sysno = 2,
        endx  = endb2,
        colour = :orange4 )	
	linkxaxes!( ax1, ax2 )
	linkxaxes!( ax1, ax1a )
	linkxaxes!( ax2, ax2a )
	linkyaxes!( ax1, ax2 )
    return f
end


# convoluted way of making pairs of (0,-10),(0,10) for label offsets
const OFFSETS = collect( Iterators.flatten(fill([(0,-10),(0,10)],50)))

function draw_bc( settings::Settings, title :: String, df1 :: DataFrame, df2 :: DataFrame; thumbnail=false )::Figure
    f = make_default_fig(;square=true, thumbnail=thumbnail )
    nrows1,ncols1 = size(df1)
    nrows2,ncols2 = size(df2)
    xmax = max( maximum(df1.gross), maximum(df2.gross))*1.1
    ymax = max( maximum(df1.net), maximum(df2.net))*1.1
    ymin = min( minimum(df1.net), minimum(df2.net))
    ax = if thumbnail
        Axis(f[1,1])
    else
        Axis(f[1,1]; xlabel="Earnings £s pw",
        ylabel=TARGET_BC_INCOMES_STRS[settings.target_bc_income]*" £s pw",
        title=title)
    end
    ylims!( ax, 0, ymax )
    xlims!( ax, -10, xmax )
    # diagonal gross=net
    lines!( ax, [0,xmax], [0, ymax]; color=:lightgrey)
    # bc 1 lines
    lines!( ax, df1.gross, df1.net, color=PRE_COLOUR, label="Pre"  )
    # b1 labels
    # b1 points
    scatter!( ax, df1.gross, df1.net, markersize=5, color=PRE_COLOUR )
    # bc 1 lines
    lines!( ax, df2.gross, df2.net; color=POST_COLOUR, label="Post" )
    # b1 labels
    if ! thumbnail
        scatter!( ax, df1.gross, df1.net; marker=df1.char_labels, marker_offset=OFFSETS[1:nrows1], markersize=15, color=PRE_COLOUR,  )
        scatter!( ax, df2.gross, df2.net; marker=df2.char_labels, marker_offset=OFFSETS[1:nrows2], markersize=15, color=POST_COLOUR )
    end
    # b1 points
    scatter!( ax, df2.gross, df2.net, markersize=5, color=POST_COLOUR )
    axislegend(;position = :rc)
    f
end



function draw_mr_hists( systems :: Vector, results :: NamedTuple; thumbnail=false )
    f = make_default_fig(;thumbnail=thumbnail)
    ax = Axis(f[1,1],
        title="Marginal Effective Tax Rates",
        xlabel=" METRs(%)",
        ylabel="Freq" )
    i = 0
    for ind in results.indiv
        i += 1
        m1=ind[.! ismissing.(ind.metr),:]
        m1.metr = Float64.( m1.metr ) # Coerce away from missing type.
        # (correct) v. high MRs at cliff edges.
        m1.metr = min.( 200.0, m1.metr )
        density!( ax, m1.metr; label=systems[i].name, weights=m1.weight)
    end
    axislegend()
    f
end

function draw_lorenz_curve!( f::Figure, popshare::Vector, incshare_pre::Vector, incshare_post::Vector; row=1, col=1, thumbnail=false )::Axis
    ax = if thumbnail
        Axis(f[row,col])
    else
        Axis(f[row,col]; title="Lorenz Curve", xlabel="Population Share", ylabel="Income Share")
    end
    ps = copy(popshare)
    ispre = copy(incshare_pre)
    ispost = copy(incshare_post)
    insert!(ps,1,0)
    insert!(ispre,1,0)
    insert!(ispost,1,0)
    lines!(ax, ps, ispre; label="Before", color=(:lightsteelblue, 1))
    lines!(ax,ps,ispost; label="After", color=(:gold2, 1))
    lines!(ax,[0,1],[0,1]; color=:grey)
    ax
end

function draw_lorenz_curve( popshare::Vector, incshare_pre::Vector, incshare_post::Vector; row=1, col=1, thumbnail=false )
    f = make_default_fig(;thumbnail=thumbnail)
    ax1 = draw_lorenz_curve!( f, popshare, incshare_pre, incshare_post )
    return f
end

function draw_summary_graphs_v2( settings::Settings, data::NamedTuple, summary :: NamedTuple )::Figure
    f = make_default_fig(;)
    ax1 = draw_lorenz_curve!( f,
        summary.quantiles[1][:,1], summary.quantiles[1][:,2], summary.quantiles[2][:,2] )
    ax2 = draw_deciles_barplot!( f, summary; row=1, col=2 )
    ax3 = Axis(f[2,1]; title="Income Distribution", xlabel="£s pw", ylabel="")
    density!( ax3, data.indiv[1].eq_bhc_net_income;
        weights=data.indiv[1].weight, label="Before", color=PRE_COLOUR )
    density!( ax3, data.indiv[2].eq_bhc_net_income;
        weights=data.indiv[2].weight, label="After", color=POST_COLOUR )
    if settings.do_marginal_rates
        ax4 = Axis(f[2,2]; title="METRs", xlabel="%", ylabel="")
        for i in 1:2
            ind = data.indiv[i]
            m1=ind[.! ismissing.(ind.metr),:]
            m1.metr = Float64.( m1.metr ) # Coerce away from missing type.
            m1.metr = min.( 200.0, m1.metr )
            label, colour = if i == 1
                "Before", PRE_COLOUR
            else
                "After", POST_COLOUR
            end
            density!( ax4, m1.metr; label, weights=m1.weight, color=colour)
        end
    end
    f
end

function fig_to_svg_string( f::Figure)::AbstractString
   buf = IOBuffer()
   show(buf, MIME"image/svg+xml"(), f)
   return String(take!(buf))
end
