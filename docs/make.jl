using MattTrack
using Documenter

DocMeta.setdocmeta!(MattTrack, :DocTestSetup, :(using MattTrack); recursive=true)

makedocs(;
    modules=[MattTrack],
    authors="mattsignorelli <mgs255@cornell.edu> and contributors",
    sitename="MattTrack.jl",
    format=Documenter.HTML(;
        canonical="https://mattsignorelli.github.io/MattTrack.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/mattsignorelli/MattTrack.jl",
    devbranch="main",
)
