module Opal
  class Parser
    class Node
      def initialize(sexp, level, parser)
        @sexp = sexp
        @level = level
        @parser = parser
      end

      def type
        @sexp.type
      end

      def children
        @sexp[1..-1]
      end

      def compile_to_fragments
        return @fragments if @fragments

        @fragments = []
        self.compile
        @fragments
      end

      def compile
        raise "Not Implemented"
      end

      def push(str)
        str = fragment(str) if str.is_a?(String)
        @fragments << str
      end

      def unshift(str)
        str = fragment(str) if str.is_a?(String)
        @fragments.unshift str
      end

      def wrap(pre, post)
        unshift pre
        push post
      end

      def fragment(str)
        Opal::Parser::Fragment.new str, @sexp
      end

      def scope
        @parser.scope
      end

      def s(*args)
        @parser.s(*args)
      end

      def expr(sexp)
        @parser.process sexp, :expr
      end

      def recv(sexp)
        @parser.process sexp, :recv
      end

      def stmt(sexp)
        @parser.process sexp, :stmt
      end

      def expr_or_nil(sexp)
        sexp ? expr(sexp) : "nil"
      end

      def reserved?(name)
        Opal::Parser::RESERVED.include? name
      end

      def property(name)
        reserved?(name) ? "['#{name}']" : ".#{name}"
      end

      def variable(name)
        reserved?(name) ? "#{name}$" : name
      end

      def add_local(name)
        scope.add_local name.to_sym
      end

      def add_ivar(name)
        scope.add_ivar name
      end

      def add_temp(temp)
        scope.add_temp temp
      end

      def helper(name)
        @parser.instance_variable_get(:@helpers)[name] = true
      end

      def with_temp(&block)
        @parser.with_temp(&block)
      end

      def in_while?
        @parser.in_while?
      end
    end
  end
end