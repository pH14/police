module Police
  module DataFlow
    class SecureContext
      def infect(other, source)
        source.propagate_labels other
      end

      @@simple_methods =
      [# Rails, SafeBuffer
       "concat",
       "safe_concat",
       "initialize_copy",

       # Object
       "clone",
       "dup",
       "to_f",
       "to_a",
       "to_s",
       "to_str",

       # String
       "b", "byteslice", "capitalize", "center",
       "chomp", "chop", "crypt", "delete",
       "downcase", "dump", "element_set", "encode",
       "gsub", "insert", "ljust", "lstrip",
       "modulo", "multiply", "plus", "prepend",
       "reverse", "rjust", "rstrip", "squeeze",
       "strip", "sub", "succ", "next",
       "swapcase", "tr", "tr_s", "transform",
       "upcase",

       # RBX specific. TODO: Figure out if this is required
       "find_character",

       # Regexp
       "match",
       "match_start",
       "search_from",
       "last_match"]

      @@multiparam_methods = ["split"]

      @@operator_methods   = ["multiply", # *
                              "divide",   # /
                              "plus",     # +
                              "minus",    # -
                              "modulo",   # %
                              "not",      # !
                              "gt",       # >
                              "lt",       # <
                              "gte",      # >=
                              "lte",      # <=
                              "backtick", # `
                              "invert",   # ~
                              # "equals",   # ==
                              "not_equals", # !=
                              "similar",  # ===
                              "match",    # =~
                              "comparison", # <=>
                              "lshift",   # <<
                              "rshift",   # >>
                              "index",    # []
                              "element_assignment", # []=
                              "bitwise_and", # &
                              "bitwise_or",  # |
                              "bitwise_xor", # ^
                              "exponent",    # **
                              "uplus",       # +@
                              "uminus"]      # -@

      def initialize
        # This doesn't yet cover when slice returns several arguments, not just one
        define_singleton_method("after_slice") do |obj, arg, method_args|
          # puts "#{meth}: Post-hook running. Obj #{obj}, arg #{arg}, method args #{method_args}"
          case method_args[0]
          when String
            if method_args[0].labeled? and not arg.nil?
              obj.propagate_labels arg
            end
          else
            obj.propagate_labels arg
          end

          return arg
        end

        # Note to self: it's possible that trying to print a string with a label can recurse infinitely here.
        # What happens it that the interpolated string winds up calling methods that also have post-hooks, which
        # then try to print the same messag... etc. Gotta be careful with that, or create a dup without labels
        @@simple_methods.each do |meth|
          define_singleton_method("after_#{meth}") do |obj, arg, method_args|
            # puts "#{meth}: Post-hook running. Obj #{obj}, arg #{arg}, method args #{method_args}"
              # if meth == "dup"
              # else
              #   puts "#{meth}: Post-hook running. Obj #{obj.no_label_to_s}, arg #{arg.no_label_to_s}, method args #{method_args.no_label_to_s}"
              # end

            if obj.is_a? Array
              if obj.empty?
                return arg
              end
            end

            # Range should not pass on taint to its to_s, unless the
            # begin or ending strings of it are tainted. The Range object
            # itself shouldn't pass it on.
            if meth == "to_s"
              if obj.is_a? Range and not arg.labeled?
                return arg
              end

              if obj.is_a? Hash and obj.empty?
                return arg
              end
            end

            obj.propagate_labels arg
            arg
          end
        end

        @@multiparam_methods.each do |meth|
          define_singleton_method("after_#{meth}") do |obj, args, method_args|
            # puts "#{meth}: Post-hook running. Obj #{obj}, arg #{arg}, method args #{method_args}"
            unless obj.is_a? Enumerable
              if args.is_a? Enumerable
                args.each do |arg|
                  obj.propagate_labels arg
                end
              else
                obj.propagate_labels args
              end
            end

            return args
          end
        end

        @@operator_methods.each do |meth|
          define_singleton_method("after_op__#{meth}") do |obj, args, method_args|
            # puts "#{meth}: Post-hook running. Obj #{obj.no_label_to_s}, arg #{args.no_label_to_s}, method args #{method_args.no_label_to_s}"
            if not obj.is_a? Enumerable
              if args.is_a? Enumerable
                args.each do |arg|
                  obj.propagate_labels arg
                end
              else
                obj.propagate_labels args
              end
            end

            args
          end
        end
      end

    end # SecureContext
  end # End DataFlow
end # Police

# Monkeypatches to fix cases that require standard library changes

# module Rubinius
#   module Type
#     class << self
#       alias_method :old_infect, :infect

#       def infect(host, source)
#         if source.respond_to? :secure_context? and source.secure_context?
#           source.secure_context.send :hello, host, source
#         end

#         old_infect host, source
#       end
#     end
#   end
# end

class String
  alias_method :old_modulo, :%

  def %(*args)
    ret = old_modulo *args
    propagate_labels ret

    unless %w(%e %E %f %g %G).include? self
      if self.eql? '%p'
        args.each do |arg|
          Rubinius::Type.infect ret, arg.inspect
        end
      else
        args.each do |arg|
          Rubinius::Type.infect ret, arg
        end
      end
    end

    ret
  end
end

# class Array
#   alias_method :old_pack, :pack

#   def pack(directives)
#     ret = old_pack directives

#     self.each do |a|
#       Rubinius::Type.infect ret, a
#     end

#     Rubinius::Type.infect ret, directives

#     ret
#   end
# end
