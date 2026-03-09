gf2(v) = Format.format(float(v), precision=2, commas=true)
gf1(v) = Format.format(float(v), precision=1, commas=true)
gf0(v) = Format.format(float(v), precision=0, commas=true)


# some formatting
function fmz(v::Number)
    vm = fz(v/1_000_000)*"mn"
end

function fz( v::Number )
    return if v ≈ 0.0
        "No Change"
    else
        "$(CURRENCY)"*format( v, commas=true, precision=0 )
    end
end

function a_sign(v::Number)
    return if v < 0
        abs(float(v)),
        "-"
    else
        float(v),
        ""
    end
end

function fm(v::Number)
    av, sign = a_sign(v)
    "$(sign)$(CURRENCY)"*format( av/1_000_000, commas=true, precision=0 )*"mn"
end

fp(v::Number) = format( v*100.0, precision=1 )*"%"
fc(v::Number) = format( float(v), precision=0, commas=true )
function fpw(v::Number)
    av, sign = a_sign(v)
    "$(sign)$(CURRENCY)"*format( av, precision=2, commas=true )
end

function fpa(v::Number)
    av, sign = a_sign(v)
    "$(sign)$(CURRENCY)"*format( av, precision=0, commas=true )
end
gft(v::Vector) = Format.format.(v./1000; precision=0, commas=true).*"k"

function fb(v::Number)
    if v ≈ 0
        return "-"
    end
    format( float(v), precision=0, commas=true )
end

function fm(v, r,c)
    return if c == 1
        v
    elseif c < 7
        Format.format(float(v), precision=0, commas=true)
    else
        Format.format(float(v), precision=2, commas=true)
    end
    s
end

function fm3(v, r,c)
    return if c <= 3
        v
    elseif c == 4
        Format.format(float(v), precision=0, commas=true)
    elseif c <= 11
        Format.format(v/1_000_000, precision=0, commas=true)
    else
        Format.format(float(v), precision=2, commas=true)
    end
    s
end


function format_and_class_semi( change :: Real; divisor=1.0, up_is_good=true, formatter=fpw ) :: NamedTuple
    num_str = formatter( change )
    abs_num_str = formatter( abs(change ))
    change /= divisor
    dch = if up_is_good
        change
    else
        -change
    end
    arrow = if change > 20.0
        "positive_strong"
    elseif change > 10.0
        "positive_med"
    elseif change > 0.01
        "positive_weak"
    elseif change < -20.0
        "negative_strong"
    elseif change < -10
        "negative_med"
    elseif change < -0.01
        "negative_weak"
    else
        "nonsig"
    end
    glclass = if dch > 20.0
        "text-success"
    elseif dch > 10.0
        "text-success"
    elseif dch > 0.01
        "text-success"
    elseif change < -20.0
        "text-danger"
    elseif change < -10
        "text-danger"
    elseif change < -0.01
        "text-danger"
    else
        "text-body"
    end
    (; num_str, glclass, arrow, unsigned_num_str )
end

function format_and_class( change::Real )::Tuple
    f = format_and_class_semi( change; formatter=fp2 )
    return ( f.num_str, f.glclass )
end

function format_and_class_full(; pre::Number, post::Number, up_is_good :: Bool, formatter = gf2 )::NamedTuple
    delta = post - pre
    pct_change = if ! (pre  ≈  0)
        100*delta / pre
    elseif ! (post  ≈  0)
        100*delta / post
    else
        0.0
    end
    pre_str = formatter( pre )
    post_str = formatter( post )
    pct_change_str,
    unsigned_pct_change_str,
    change_str,
    unsigned_change_str  = if abs(pct_change) > 0.01
        format( pct_change, precision=1 )*"%",
        format( abs(pct_change), precision=1 )*"%",
        formatter( delta ),
        formatter( abs( delta ))
    else
        "-",
        "-",
        "-",
        "-"
    end
    arrow = if pct_change > 20.0
        "positive_strong"
    elseif pct_change  > 10.0
         "positive_med"
    elseif pct_change  > 0.01
        "positive_weak"
    elseif pct_change  < -20.0
        "negative_strong"
    elseif pct_change  < -10
        "negative_med"
    elseif pct_change  < -0.01
        "negative_weak"
    else
        "nonsig"

    end
    dpc = if up_is_good
        pct_change
    else
        -pct_change
    end
    glclass = if dpc > 20.0
        "text-success"
    elseif dpc > 10.0
        "text-success"
    elseif dpc > 0.01
        "text-success"
    elseif dpc < -20.0
        "text-danger"
    elseif dpc < -10
        "text-danger"
    elseif dpc < -0.01
        "text-danger"
    else
        "text-body"
    end
    return (;
                delta,
                pct_change,
                pre_str,
                post_str,
                pct_change_str,
                unsigned_pct_change_str,
                change_str,
                unsigned_change_str,
                glclass,
                arrow
           )

end
