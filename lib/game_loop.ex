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
    IO.ANSI.clear()
    -10..10
    |> Enum.flat_map(fn x ->
      -10..10
      |> Enum.map(fn y ->
        coordinate = {x, y}

        live? = Enum.member?(live_coordinates, coordinate)

        if live? do
          "*"
        else
          "."
        end
      end)
    end)
    |> Enum.chunk_every(21)
    |> Enum.each(fn line ->
      Enum.join(line, "")
      |> IO.puts()
    end)

    #Enum.each(live_coordinates, fn live_coordinate ->
      #IO.inspect(live_coordinate)
    #end)
  end
end
