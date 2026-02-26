using MicroVisualisations
using Documenter

makedocs(;
    modules=[
        MicroVisualisations],
    authors="Graham Stark",
    # checkdocs=:exports,
    repo="https://github.com/grahamstark/MicroVisualisations.jl/blob/{commit}{path}#L{line}",
    sitename="MicroVisualisations.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://grahamstark.github.io/ScottishTaxBenefitModel.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md"
    ],
)

deploydocs(;
    repo="github.com/grahamstark/MicroVisualisations.jl",
)
