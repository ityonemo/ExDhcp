defmodule ExDhcp.Supervisor do

  @moduledoc "helper module for launching supervised DHCP servers"

  use Supervisor

  @doc false
  @spec start_link({module, term, keyword}) :: Supervisor.on_start
  @spec start_link({module, term}) :: Supervisor.on_start
  def start_link(s = {_module, _initial_value, opts}) do
    sup_opts = Keyword.take(opts, [:supervisor_name])
    Supervisor.start_link(__MODULE__, s, sup_opts)
  end
  def start_link({module, term}), do: start_link({module, term, []})

  @impl true
  def init({module, initial_value, opts}) do
    Supervisor.init([{module, {initial_value, opts}}], strategy: :one_for_one)
  end
end
