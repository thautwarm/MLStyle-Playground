using MLStyle

macro cond(cases)
    @match cases begin
        quote
        $(cases...)
        end =>
        let default = Expr(:call, throw, "None of the branches have satisfied conditions.")
            foldr(cases, init = default) do case, last
                last_lnode = @__LINE__
                @match case begin
                    ::LineNumberNode => begin
                        last_lnode = case
                        Expr(:block, case, last)
                    end
                    :(_ => $b) => b
                    :($a => $b) => Expr(:if, a, b, last)
                    _ => throw("Invalid syntax at $last_lnode.")
                end
            end
        end |> esc
    end
end

function check_more_than1(x :: Int)
    @cond begin
        x > 1 => true
        _ => false
    end
end

@assert check_more_than1(1) === false
@assert check_more_than1(0) === false
@assert check_more_than1(2) === true



