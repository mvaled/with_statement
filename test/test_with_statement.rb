require 'helper'

class TestWithStatement < Test::Unit::TestCase
  context "A simple non-reentrant resource class" do
    class ResourceException < Exception; end

    class Resource
      attr_reader :locked

      def initialize
        @locked = false
      end

      def acquire
        raise ResourceException.new "Already acquired" if @locked
        @locked = true
        self
      end

      def release
        raise ResourceException.new "Not acquired" unless @locked
        @locked = false
      end

      def do_something
        :do_something
      end
    end

    class LockedResource < Resource
      def initialize
        super
        @locked = true
      end
    end

    class WeirdException < Exception; end

    setup do
      @resource = Resource.new
      @inner = Resource.new
      @locked = LockedResource.new
    end

    should "be locked within with statement, and release outside it" do
      with @resource do
        assert @resource.locked
      end
      assert !@resource.locked
    end

    should 'raise an exception on a locked resource' do
      assert_raise ResourceException do
        with @locked do; end
      end
    end

    should "raise an exception when double locked" do
      with @resource do
        assert_raise ResourceException do
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

    should "allow nested withs" do
      with @resource do |a|
        with @inner do |b|
          assert @resource.locked
          assert @inner.locked
        end
        assert @resource.locked
        assert !@inner.locked
      end
    end

    should "allow multiple context managers" do
      with @resource, @inner do |a, b, *others|
        assert a == @resource
        assert b == @inner
        assert others == [], 'no more resources'
        assert @resource.locked
        assert @inner.locked
      end
      assert !@resource.locked
      assert !@inner.locked
    end

    should 'release the first resource if the second fails to enter' do
      assert_raise ResourceException do
        with @resource, @locked do
          raise StandardError, 'This exception should not be raised; because this code should never be called'
        end
      end
      assert !@resource.locked
    end

    should 'raise a SyntaxError when no context managers are given' do
      assert_raise SyntaxError do
        with {}
      end
    end

    should 'raise an exception if no block is given' do
      assert_raise LocalJumpError do
        with @resource
      end
    end

    should "allow to be used with non-resource objects" do
      with 21 + 10 + 78 do |result|
        assert result == 21 + 10 + 78
      end
    end

    should "allow the intermixed resource and non-resource objects" do
      with @resource, true, @inner do |which, aboolean, what|
        assert @resource == which
        assert aboolean
        assert @inner == what
      end
    end
  end
end
