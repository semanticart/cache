defmodule Cache do
  use GenServer

  def start do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def write(key, value) do
    write(key, value, expires: nil)
  end
  def write(key, value, expires: expires) do
    GenServer.cast(__MODULE__, {:write, key, value, expires})
    :ok
  end

  def read(key) do
    GenServer.call(__MODULE__, {:read, key})
  end

  def fetch(key, fun) do
    fetch(key, fun, expires: nil)
  end
  def fetch(key, fun, expires: expires) do
    GenServer.call(__MODULE__, {:fetch, key, fun, expires})
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  def dump do
    GenServer.call(__MODULE__, {:dump})
  end

  # Internal API

  def handle_cast({:write, key, value, expires}, state) do
    {:noreply, Map.put(state, key, [value, expires])}
  end

  def handle_call({:dump}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:read, key}, _from, state) do
    {:reply, fresh_value(Map.get(state, key)), state}
  end
  def handle_call({:fetch, key, fun, expires}, _from, state) do
    if current_value = fresh_value(Map.get(state, key)) do
      {:reply, current_value, state}
    else
      value = fun.()
      {:reply, value, Map.put(state, key, [value, expires])}
    end
  end
  def handle_call({:delete, key}, _from, state) do
    {value, new_state} = Map.pop(state, key)
    {:reply, fresh_value(value), new_state}
  end

  defp fresh_value(nil), do: nil
  defp fresh_value([value, nil]), do: value
  defp fresh_value([value, expires]) do
    if expires >= :os.system_time(:millisecond) do
      value
    else
      nil
    end
  end
end
