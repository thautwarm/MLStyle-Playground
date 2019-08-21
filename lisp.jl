using MLStyle

flatten_row(expr) =
    @match expr begin
        Expr(:row, args...) => args
        a => [a]
    end

lisp(expr) =
    @match expr begin
        :[] => nothing

        :[f] => Expr(:call, lisp(f))


        Expr(:vcat, args...) =>
            lisp(Expr(:hcat, vcat(map(flatten_row, args)...)...))

        :[($(hd::QuoteNode)) ($(args...))] =>
            Expr(hd.value, map(lisp, args)...)

        :[($hd) ($(args...))] =>
            Expr(:call, hd, map(lisp, args)...)

        Expr(head, args...) =>
            Expr(head, map(lisp, args)...)

        a => a
    end

macro lisp(expr)
    lisp(expr) |> esc
end
