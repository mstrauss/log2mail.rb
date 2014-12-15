unless Kernel.respond_to?(:Hash)
  module Kernel
    def Hash(arg)
      if arg.respond_to?(:to_hash)
        return arg.to_hash
      elsif arg.nil?
        return {}
      else
        fail TypeError, "TypeError: can't convert #{arg.class} into Hash"
      end
    end
  end
end
