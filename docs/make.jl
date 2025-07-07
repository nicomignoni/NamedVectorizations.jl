push!(LOAD_PATH, "../src/")

using Documenter, NamedVectorizations

makedocs(
    sitename="NamedVectorizations.jl",
    pages = [
        "Home" => "index.md",
        "API" => "api.md"
    ],
    repo=Remotes.GitHub("nicomignoni", "NamedVectorizations.jl"),
)
