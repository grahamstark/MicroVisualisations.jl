
const MR_UP_GOOD = [1,0,0,0,0,0,0,-1,-1]
const COST_UP_GOOD = [1,1,1,1,1,-1,-1,-1,-1,-1,-1,-1,1]

const PRE_COLOURS = [(:lightsteelblue3, 0.5) (:lightslategray,0.5)]
const POST_COLOURS = [(:peachpuff, 0.5) (:peachpuff3,0.5)]

const PRE_COLOUR = (:lightsteelblue, 0.5)
const POST_COLOUR = (:gold2, 0.5)

function format_and_class( change :: Real ) :: Tuple
    gnum = format( abs(change), commas=true, precision=2 )
    glclass = "";
    glstr = ""
    if change > 20.0
        glstr = "positive_strong"
        glclass = "text-success"
    elseif change > 10.0
        glstr = "positive_med"
        glclass = "text-success"
    elseif change > 0.01
        glstr = "positive_weak"
        glclass = "text-success"
    elseif change < -20.0
        glstr = "negative_strong"
        glclass = "text-danger"
    elseif change < -10
        glstr = "negative_med"
        glclass = "text-danger"
    elseif change < -0.01
        glstr = "negative_weak"
        glclass = "text-danger"
    else
        glstr = "nonsig"
        glclass = "text-body"
        gnum = "";
    end
    ( gnum, glclass, glstr )
end


const ARROWS_3 = Dict([
    "nonsig"          => "&#x25CF;",
    "positive_strong" => "&#x21c8;",
    "positive_med"    => "&#x2191;",
    "positive_weak"   => "&#x21e1;",
    "negative_strong" => "&#x21ca;",
    "negative_med"    => "&#x2193;",
    "negative_weak"   => "&#x21e3;" ])

const ARROWS_1 = Dict([
    "nonsig"          => "",
    "positive_strong" => "<i class='bi bi-arrow-up-circle-fill'></i>",
    "positive_med"    => "<i class='bi bi-arrow-up-circle'></i>",
    "positive_weak"   => "<i class='bi bi-arrow-up'></i>",
    "negative_strong" => "<i class='bi bi-arrow-down-circle-fill'></i>",
    "negative_med"    => "<i class='bi bi-arrow-down-circle'></i>",
    "negative_weak"   => "<i class='bi bi-arrow-down'></i>" ])
