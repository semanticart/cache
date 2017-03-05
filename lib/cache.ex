defmodule Cache do
  use GenServer

  def start do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def write(key, value) do
    GenServer.cast(__MODULE__, {:write, key, value})
    :ok
  end

  def read(key) do
    GenServer.call(__MODULE__, {:read, key})
  end

  def fetch(key, fun) do
    GenServer.call(__MODULE__, {:fetch, key, fun})
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  def dump do
    GenServer.call(__MODULE__, {:dump})
  end

  # Internal API

  def handle_cast({:write, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end

  def handle_call({:dump}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:read, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end
  def handle_call({:fetch, key, fun}, from, state) do
    if !Map.has_key?(state, key) do
      value = fun.()
      {:reply, value, Map.put(state, key, value)}
    else
      handle_call({:read, key}, from, state)
    end
  end
  def handle_call({:delete, key}, _from, state) do
    {value, new_state} = Map.pop(state, key)
    {:reply, value, new_state}
  end
end
