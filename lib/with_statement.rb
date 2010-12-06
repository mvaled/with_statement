module Kernel

  # Similar to Python's with statement. This statement enters the
  # context of an object +resource+, executes the block, and exits the
  # context.
  def with(resource)
    what = resource.acquire
    begin
      yield(what)
    ensure
      resource.release
    end
  end
end

