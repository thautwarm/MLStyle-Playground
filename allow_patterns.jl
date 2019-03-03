using MLStyle


function allow_patterns(node)
    @match node begin
        :(case($(targets...)) do
            $(cases...)
        end) => let target = length(targets) === 1 ? targets[1] : Expr(:tuple, targets...),
                   cases = map(allow_patterns, cases)
                   quote
                     $MLStyle.@match $target begin
                         $(cases...)
                     end
                   end
               end
        Expr(hd, tl...) => Expr(hd, map(allow_patterns, tl)...)
        a => a
    end
end

macro allow_patterns(node)
    allow_patterns(node) |> esc
end

# @allow_patterns module SyntaxExtended
#      case(1) do
#          2        => error(1)
#          5:10     => error(2)
#          1:4 && a =>
#          case(a + 1) do
#              a => 5a
#          end
#      end |> println
# end
