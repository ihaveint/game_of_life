defmodule GOL.Server do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(_opts) do
    {:ok,
      %{
        cell_to_pid: %{
          {0, 0} => GenServer.start(Cell, [0, 0, :live]) |> elem(1),
          {1, 1} => GenServer.start(Cell, [1, 1, :live]) |> elem(1),
          {2, 1} => GenServer.start(Cell, [2, 1, :live]) |> elem(1),
          {2, 0} => GenServer.start(Cell, [2, 0, :live]) |> elem(1),
          {2, -1} => GenServer.start(Cell, [2, -1, :live]) |> elem(1)
        }
      }}
  end

  @impl true
  def handle_cast({:transit}, %{cell_to_pid: cell_to_pid} = state) do
    cell_to_pid
    |> Enum.each(fn {_coordinate, pid} ->
      GenServer.cast(pid, {:transit})
    end)

    {:noreply, state}
  end


  @impl true
  def handle_call({:get_live_coordinates}, _from, %{cell_to_pid: cell_to_pid} = state) do
    live_coordinates = Enum.filter(cell_to_pid, fn {_coordinate, pid} -> GenServer.call(pid, {:get_status}) == :live end) |> Map.new() |> Map.keys()
    {:reply, live_coordinates, state}
  end

  @impl true
  def handle_call({:get_cell_status, coordinates}, _from, %{cell_to_pid: cell_to_pid} = state) do
    {pid, new_mapping} =
      case Map.fetch(cell_to_pid, coordinates) do
        :error ->
          if has_at_least_on_live_neighbour(coordinates, cell_to_pid) do
            pid = GenServer.start(Cell, [elem(coordinates, 0), elem(coordinates, 1), :dead]) |> elem(1)
            GenServer.cast(pid, {:transit})
            {pid, Map.put(cell_to_pid, coordinates, pid)}
          else
            {:dead, cell_to_pid}
          end
        {:ok, pid} ->
          {pid, cell_to_pid}
      end


    response = case pid do
      :dead -> :dead
      pid ->  GenServer.call(pid, {:get_status})
    end

    {:reply, response, %{state | cell_to_pid: new_mapping}}
  end

  defp has_at_least_on_live_neighbour(coordinates, mapping) do

    [-1, -1, -1, 0, 0, 1, 1, 1]
    |> Enum.zip([-1, 0, 1, -1, 1, -1, 0, 1])
    |> Enum.any?(fn {dx, dy} ->
      neighbour_coordinates = {elem(coordinates, 0) + dx, elem(coordinates, 1) + dy}
      case Map.fetch(mapping, neighbour_coordinates) do
        :error -> false
        {:ok, pid} ->
          GenServer.call(pid, {:get_status}) == :live
      end
    end)
  end
end
