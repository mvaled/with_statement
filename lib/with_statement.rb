module Kernel

  # Similar to Python's with statement. This statement enters the
  # context of an object +resource+, executes the block, and exits the
  # context.
  def with(*resources, &block)
    raise SyntaxError, 'with statement called with no arguments' if resources.size == 0
    if resources.size == 1
      simple_with(resources.shift, &block)
    else
      simple_with(resources.shift) do |what|
        with(*resources) {|*rs|
          args = [what] + rs
          block.call(*args)
        }
      end
    end
  end

  private

  def simple_with(resource, &block)
    what = resource.respond_to?(:acquire) ? resource.acquire : resource
    begin
      yield(what)
    ensure
      resource.release if resource.respond_to? :release
    end
  end
end
