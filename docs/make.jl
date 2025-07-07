push!(LOAD_PATH, "../src/")

using Documenter, NamedVectorizations

makedocs(
    sitename="NamedVectorizations.jl",
    pages = [
        "Home" => "index.md",
        "API" => "api.md"
    ],
    format = Documenter.HTML(
        edit_link="master"
    ),
    repo=Remotes.GitHub("nicomignoni", "NamedVectorizations.jl"),
)

deploydocs(
    repo = "github.com/nicomignoni/NamedVectorizations.jl.git",
)
