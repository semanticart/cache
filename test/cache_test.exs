defmodule CacheTest do
  use ExUnit.Case
  doctest Cache

  setup do
    Cache.start

    :ok
  end

  describe ".write" do
    test "stores a value in the cache" do
      assert Cache.write("name", "Jeffrey") == :ok

      assert Cache.dump == %{"name" => "Jeffrey"}
    end
  end

  describe ".read" do
    test "returns the value for a key that exists" do
      assert Cache.write("name", "Jeffrey") == :ok

      assert Cache.read("name") == "Jeffrey"
    end

    test "returns nil if no key exists" do
      assert Cache.read("name") == nil
    end
  end

  describe ".fetch" do
    test "a miss evaluates and caches the function" do
      fun = fn -> "Developer" end

      assert Cache.fetch("title", fun) == "Developer"
      assert Cache.read("title") == "Developer"
    end

    test "a hit returns the cached value and does not evaluate the function" do
      Cache.write("title", "Developer")

      fun = fn -> flunk("This should not be called") end

      assert Cache.fetch("title", fun) == "Developer"
    end
  end

  describe ".delete" do
    test "returns nil if the key is not cached" do
      assert Cache.delete("pancakes") == nil
    end

    test "returns a value if the key is cached and removes it from the cache" do
      Cache.write("pancakes", "delicious")

      assert Cache.delete("pancakes") == "delicious"
      assert Cache.read("pancakes") == nil
    end
  end
end
