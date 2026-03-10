const MR_UP_GOOD = [
    0, # "Less than zero"
    1, # "Zero"
    0, # "0.01-9.99"
    0, # "10-19.99"
    0, # "20-29.99"
    0, # "30-39.99"
    0, # "40-49.99"
    0, # "50-59.99"
    0, # "60-69.99"
    0, # "70-79.99"
    0, # "80-89.99"
    0, # "90-99.99"
    -1, # "100"
    -1, # "Above 100"
    -1, # mean
    -1] # median

const COST_UP_GOOD = [1,1,1,1,1,-1,-1,-1,-1,-1,-1,-1,1]

const PRE_COLOURS = [(:lightsteelblue3, 0.5) (:lightslategray,0.5)]
const POST_COLOURS = [(:peachpuff, 0.5) (:peachpuff3,0.5)]

const PRE_COLOUR = (:lightsteelblue, 0.5)
const POST_COLOUR = (:gold2, 0.5)

const PRE_COLOUR_BOLD = (:darkblue, 1)
const POST_COLOUR_BOLD = (:darkorange, 1)

const CURRENCY = "£"

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
