const AVAILABLE_OTHER_ITEMS = OrderedDict([
    :headline_numbers => "A summary of headline numbers."])


function format_headline_numbers( headlines :: NamedTuple )::NamedTuple
    return (;
        gainers = gf0(headlines.gainers),
        losers = gf0(headlines.losers),
        no_change = gf0(headlines.no_change),
        median_metrs = format_and_class_full( pre=headlines.median_metr1, post=headlines.median_metr2, up_is_good=false, formatter=gf1 ),
        mean_metrs = format_and_class_full( pre=headlines.mean_metr1, post=headlines.mean_metr2, up_is_good=false, formatter=gf1 ),
        median_income = format_and_class_full( pre=headlines.median_income1, post=headlines.median_income2, up_is_good=true, formatter=fpw ),
        mean_income = format_and_class_full( pre=headlines.mean_income1, post=headlines.mean_income2, up_is_good=true, formatter=fpw ),
        benefits = format_and_class_full( pre=headlines.ben1, post=headlines.ben2, up_is_good=false, formatter=fm ),
        tax = format_and_class_full( pre=headlines.tax1, post=headlines.tax2, up_is_good=true, formatter=fm ),
        palma = format_and_class_full( pre=headlines.palma1*100, post=headlines.palma2*100, up_is_good=false, formatter=gf1 ),
        gini = format_and_class_full( pre=headlines.gini1*100, post=headlines.gini2*100, up_is_good=false, formatter=gf1 ),
        pov_headcount = format_and_class_full( pre=headlines.pov_headcount1*100, post=headlines.pov_headcount2*100, up_is_good=false, formatter=gf1 ),
        child_poverty = format_and_class_full( pre=headlines.child_poverty1*100, post=headlines.child_poverty2*100, up_is_good=false, formatter=gf1 ),
        net_cost = format_and_class_semi( headlines.net_cost; divisor=1_000_000, up_is_good=false, formatter=fm ),
        net_direct = format_and_class_semi( headlines.net_direct; divisor=1_000_000, up_is_good=false, formatter=fm))
end
