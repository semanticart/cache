defmodule Cache do
  @moduledoc """
    A simple in-memory key-value store with optional time-based expiration.

    Note that there is no ceiling on memory usage nor does it purge old items.
  """

  use GenServer

  @doc """
    Start the underlying `GenServer` with the initial state.
  """
  def start do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
    Write `value` to the cache under `key` with an optional expiration timestamp in ms

    When `expires` is nil, the item will remain fresh indefinitely.

    Otherwise, cached values are considered fresh until `expires` has passed. i.e.

        expires > :os.system_time(:millisecond)
  """
  @spec write(binary, any, number | nil) :: atom
  def write(key, value, expires \\ nil) do
    GenServer.cast(__MODULE__, {:write, key, value, expires})
    :ok
  end

  @doc """
    Read a value `key` from the cache.

    Returns nil if no value is cached under the provided key.

    Returns nil if the cached value has expired.
  """
  @spec read(binary) :: any
  def read(key) do
    GenServer.call(__MODULE__, {:read, key})
  end

  @doc """
    Read the value `key` from the cache and return it or cache & return the
    result of `fun`

    See `Cache.write/3` for more about `expires`
  """
  @spec fetch(binary, function, number | nil) :: any
  def fetch(key, fun, expires \\ nil) do
    GenServer.call(__MODULE__, {:fetch, key, fun, expires})
  end

  @doc """
    Delete a from the cache under `key`.

    Returns the deleted value or nil.

    Returns nil if the cached value has expired.
  """
  @spec delete(binary) :: any
  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  @doc """
    Returns the entire contents of the cache.
  """
  @spec dump() :: map
  def dump do
    GenServer.call(__MODULE__, {:dump})
  end

  # Internal API

  @spec handle_cast({:write, binary, any, number | nil}, map) :: {:noreply, map}
  def handle_cast({:write, key, value, expires}, state) do
    {:noreply, Map.put(state, key, {value, expires})}
  end

  @spec handle_call({:dump}, any, map) :: {:reply, map, map}
  def handle_call({:dump}, _from, state) do
    {:reply, state, state}
  end
  @spec handle_call({:read, binary}, any, map) :: {:reply, any, map}
  def handle_call({:read, key}, _from, state) do
    {:reply, fresh_value(Map.get(state, key)), state}
  end
  @spec handle_call({:fetch, binary, function, number | nil}, any, map) :: {:reply, any, map}
  def handle_call({:fetch, key, fun, expires}, _from, state) do
    if current_value = fresh_value(Map.get(state, key)) do
      {:reply, current_value, state}
    else
      value = fun.()
      {:reply, value, Map.put(state, key, {value, expires})}
    end
  end
  @spec handle_call({:delete, binary}, any, map) :: {:reply, any, nil}
  def handle_call({:delete, key}, _from, state) do
    {value, new_state} = Map.pop(state, key)
    {:reply, fresh_value(value), new_state}
  end

  defp fresh_value(nil), do: nil
  defp fresh_value({value, nil}), do: value
  defp fresh_value({value, expires}) do
    if expires >= :os.system_time(:millisecond) do
      value
    else
      nil
    end
  end
end
