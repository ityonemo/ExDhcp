defmodule Mix.Tasks.Snoop do
  use Mix.Task

  alias ExDhcp.Packet

  @moduledoc """
  A tool for sending a saved DHCP packet (usually saved from `mix snoop`) to a DHCP server

  ## Usage

  ```
  mix dhcp <filename> [options]
  ```

  ## Options

  - `--bind <device>` or `-b <device>` binds this mix task to a specific
    network device.
  - `--save <filename>` or `-s <filename>` saves the response packet (as erlang term binaries) to files
    with the given prefix
  - `!` fire and forget, don't wait for the response.
  """

  @shortdoc "send a saved DHCP packet"

  def run([filename, params]) do
    params = parse_params(params)

    response = filename
    |> File.read
    |> :erlang.binary_to_term
    |> Packet.send(params)

    unless params[:nowait] do
      savemsg = save(response, params)
      Logger.info(savemsg <> inspect response)
    end
    :ok
  end

  defp save(response, params) do
    path = params[:save]
    if path do
      File.write!(path, :erlang.term_to_binary(response))
      "(saved to #{path})"
    else
      ""
    end
  end

  @bind ~w(-b --bind)
  @save ~w(-s --save)
  @nowait "!"

  defp parse_params([switch, bind | rest]) when switch in @bind do
    [bind: bind] ++ parse_params(rest)
  end
  defp parse_params([switch, filename | rest]) when switch in @save do
    [save: filename] ++ parse_params(rest)
  end
  defp parse_params([@nowait | rest]) do
    [nowait: true] ++ parse_params(rest)
  end

end
