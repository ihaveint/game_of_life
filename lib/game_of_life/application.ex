defmodule GOL.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
     {GOL.Server, name: Server}
    ]

    opts = [strategy: :one_for_one, name: GOL.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
