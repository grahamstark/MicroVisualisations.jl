
function do_dummy_run()

    function make_some_changes!( sys )
        # flat tax -
        sys.it.non_savings_basic_rate = 1
        sys.it.non_savings_rates = [0.19]
        sys.it.non_savings_thresholds = []
        # UBI
        sys.ubi.abolished = false
        sys.ubi.child_amount = 20.0
        sys.ubi.adult_amount = 100.0
        sys.ubi.universal_pension = 190
        sys.ubi.mt_bens_treatment = ub_as_is
        make_ubi_pre_adjustments!( sys )
    end

    settings = Settings()
    settings.do_marginal_rates = true
    obs = Observable( Progress(settings.uuid,"",0,0,0,0))
    tot = 0

    of = on(obs) do p
        # global tot
        println(p)
        tot += p.step
        println(tot)
    end

    sys = [
        get_default_system_for_fin_year(2026; scotland=true),
        get_default_system_for_fin_year( 2026; scotland=true )]
    make_some_changes!( sys[2])
    # force reset of data to use UK dataset
    settings.num_households, settings.num_people, nhh2 =
        FRSHouseholdGetter.initialise( settings; reset=false )
    results = do_one_run( settings, sys, obs )
    h1 = results.hh[1]
    summary = summarise_frames!( results, settings )
    return (summary, results, settings, sys )
end

function getbc(
    settings :: Settings,
    hh  :: Household,
    sys1 :: TaxBenefitSystem,
    sys2 :: TaxBenefitSystem,
    wage :: Real )::Tuple
    bc1 = BCCalcs.makebc( hh, sys1, settings, wage; to_html=true )
    bc1 = recensor(bc1)
    bc1.mr .*= 100.0
    bc1.char_labels = BCCalcs.get_char_labels(size(bc1)[1])
    settings.means_tested_routing = uc_full
    bc2 = BCCalcs.makebc( hh, sys2, settings, wage; to_html=true )
    bc2 = recensor(bc2)
    bc2.mr .*= 100.0 # MR to percent
    bc2.char_labels = BCCalcs.get_char_labels(size(bc2)[1])
    (bc1,bc2)
end


