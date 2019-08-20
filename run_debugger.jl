include("simple_debugger.jl")
@inject function f(x)
    @watch! x
    z = x + 2
    @watch! z
    @watch! z+1
    nested(u) = begin
        @watch! u
        u + x
    end
end
@nodebug!
nested = f(1)
nested(1)