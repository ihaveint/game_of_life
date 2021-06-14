defmodule Cell do
  defstruct(x: nil, y: nil, status: :dead)

  use GenServer

  @impl true
  def init([x, y, status]) when status in [:dead, :live] do
    {:ok,
     %{
       x: x,
       y: y,
       status: status,
       next_status: nil
     }}
  end

  @impl true
  def handle_call({:get_status}, _from, %{status: status} = state) do
    {:reply, status, state}
  end

  @impl true
  def handle_cast({:transit}, %{x: x, y: y, status: current_status} = state) do
    pid = self()

    spawn(fn ->
      neighbours_status =
        [-1, -1, -1, 0, 0, 1, 1, 1]
        |> Enum.zip([-1, 0, 1, -1, 1, -1, 0, 1])
        |> Enum.map(fn {dx, dy} ->
          neighbour_coordinates = {x + dx, y + dy}
          _neighbour_status = GenServer.call(Server, {:get_cell_status, neighbour_coordinates}) 
        end)

      live_counter = Enum.count(neighbours_status, fn status -> status == :live end)

      next_status =
        case current_status do
          :dead ->
            if live_counter == 3 do
              :live
            else
              :dead
            end

          :live ->
            if live_counter == 2 or live_counter == 3 do
              :live
            else
              :dead
            end
      end


      :timer.sleep(1000)

      GenServer.cast(pid, {:finished_work, next_status})
    end)

    {:noreply, state}
  end

  def handle_cast({:finished_work, status}, state) do
    {:noreply, %{state | status: status}}
  end
end
