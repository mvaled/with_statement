require 'helper'

class TestWithStatement < Test::Unit::TestCase
  context "A simple non-reentrant resource class" do
    class Resource
      attr_reader :locked

      def initialize
        @locked = false
      end

      def acquire
        raise Exception.new "Already acquired" if @locked
        @locked = true
        self
      end

      def release
        raise Exception.new "Not acquired" unless @locked
        @locked = false
      end

      def do_something
        :do_something
      end
    end

    setup do
      @resource = Resource.new
    end

    should "be locked within with statement, and release outside it" do
      with @resource do 
        assert @resource.locked
      end
      assert !@resource.locked
    end

    should "raise an exception when double locked" do
      with @resource do
        assert_raise Exception do 
          with @resource do; end
        end
      end
    end

    should "yield the resource to the block" do
      with @resource do |what|
        assert what == @resource
        assert what.do_something
      end
    end
  end
end
