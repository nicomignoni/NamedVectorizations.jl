using Test, NamedVectorizations

const TENSOR_SIZE = (2, 5, 4)
const MATRIX_SIZE = (4, 7)

x = NV(
    a=rand(TENSOR_SIZE...),
    b=rand(MATRIX_SIZE...),
    c=5
)

@testset "Matrix product" begin
    # Checks if multiplying and NV for a square matrix of the 
    # same size still returns an NV.
    M = rand(length(x), length(x))
    @test (M * x) isa NV

    # Otherwise, it must return a Vector whose dimension is 
    # the number of the matrix rows.
    M = rand(length(x) + 5, length(x))
    @test (M * x) isa Vector
end

@testset "vcat" begin
    y = rand(5)
    @test vcat(x, y) isa Vector

    # vcat with overlapping layouts
    y = NV(
        a=rand(5),
        d=rand(2, 3),
        e=2
    )
    @test vcat(x, y) isa Vector

    # vcat with disjoined layouts
    y = NV(
        d=4,
        e=rand(3),
        f=rand(2, 3, 4)
    )
    @test vcat(x, y) isa NV
end     

@testset "Broadcasting" begin
    y = rand(length(x))

    @test x .+ y isa NV
    @test x .+ 1 isa NV
    @test 2x isa NV
end

