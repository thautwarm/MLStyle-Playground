function matchast(target, actions)
    (@match actions begin
       Expr(:quote,
            quote
                $(stmts...)
            end
       ) => stmts
    end) |> stmts ->
    map(stmts) do stmt
        @match stmt begin
            ::LineNumberNode => stmt
            :($a => $b) => :($(Expr(:quote, a)) => $b)
        end
    end |> actions ->
    quote
        $MLStyle.@match $target begin
            $(actions...)
        end
    end
end

macro matchast(template, actions)
    matchast(template, actions) |> esc
end
