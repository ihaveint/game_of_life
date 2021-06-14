defmodule Game.Loop do
  def start() do
    loop()
  end

  defp loop() do
    spawn(fn ->
      draw_game(GenServer.call(Server, {:get_live_coordinates}))
    end)
    IO.puts("moving to the next transition")
    GenServer.cast(Server, {:transit})
    :timer.sleep(5000)
    loop()
  end

  defp draw_game(live_coordinates) do
    Enum.each(live_coordinates, fn live_coordinate ->
      IO.inspect(live_coordinate)
    end)
  end
end
