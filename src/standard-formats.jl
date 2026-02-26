gf2(v) = Format.format(v, precision=2, commas=true)
gf0(v) = Format.format(v, precision=0, commas=true)


# some formatting
function fmz(v::Number)
    vm = fz(v/1_000_000)*"mn"
end

function fz( v::Number )
    return if v ≈ 0.0
        "No Change"
    else
        "£"*format( v, commas=true, precision=0 )
    end
end

fm(v::Number) = "£"*format( v/1_000_000, commas=true, precision=0 )*"mn"
fp(v::Number) = format( v*100, precision=1 )*"%"
fc(v::Number) = format( v, precision=0, commas=true )
fpw(v::Number) = "£"*format( v, precision=2, commas=true )
fpa(v::Number) = "£"*format( v, precision=0, commas=true )

function fb(v::Number)
    if v ≈ 0
        return "-"
    end
    format( v, precision=0, commas=true )
end

function fm(v, r,c)
    return if c == 1
        v
    elseif c < 7
        Format.format(v, precision=0, commas=true)
    else
        Format.format(v, precision=2, commas=true)
    end
    s
end

function fm3(v, r,c)
    return if c <= 3
        v
    elseif c == 4
        Format.format(v, precision=0, commas=true)
    elseif c <= 11
        Format.format(v/1_000_000, precision=0, commas=true)
    else
        Format.format(v, precision=2, commas=true)
    end
    s
end
