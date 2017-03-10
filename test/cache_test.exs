defmodule CacheTest do
  use ExUnit.Case
  doctest Cache

  setup do
    Cache.start

    :ok
  end

  defp now(), do: :os.system_time(:millisecond)
  defp future(), do: now() + 1000
  defp past(), do: now() - 1

  describe ".write" do
    test "stores a value in the cache" do
      assert Cache.write("name", "Jeffrey") == :ok

      assert Cache.dump == %{"name" => {"Jeffrey", nil}}
    end

    test "stores a value with an expiration" do
      assert Cache.write("name", "Jeffrey", 10) == :ok

      assert Cache.dump == %{"name" => {"Jeffrey", 10}}
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

    test "returns nil if the key has expired" do
      assert Cache.write("name", "Jeffrey", past()) == :ok

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
      Cache.write("title", "Developer", future())

      fun = fn -> flunk("This should not be called") end

      assert Cache.fetch("title", fun) == "Developer"
    end

    test "evaluates and caches the function if the previous value has already expired" do
      fun = fn -> "Developer" end
      Cache.write("title", "Stooge", past())

      assert Cache.fetch("title", fun) == "Developer"
    end
  end

  describe ".delete" do
    test "returns nil if the key is not cached" do
      assert Cache.delete("pancakes") == nil
    end

    # TODO: I think this makes sense
    test "returns nil if the value has expired" do
      Cache.write("pancakes", "delicious", past())

      assert Cache.delete("pancakes") == nil
    end

    test "returns a value if the key is cached and removes it from the cache" do
      Cache.write("pancakes", "delicious")

      assert Cache.delete("pancakes") == "delicious"
      assert Cache.read("pancakes") == nil
    end
  end
end
