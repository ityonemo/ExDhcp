defmodule ExDhcp.Options do

  alias ExDhcp.Utils

  @moduledoc false

  @option_padding 0
  @option_finish 255

  @type typecode::byte

  @type decoded_options :: %{optional(atom) => any, optional(non_neg_integer) => any}

  @doc """
  Decode DHCP options
  """
  @spec decode(binary, [module]) :: decoded_options
  def decode(opts, modules) do
    opts
    |> decode_bin([])
    |> decode_mod(modules)
    |> Enum.into(%{})
  end

  defp decode_bin("", so_far), do: so_far
  defp decode_bin(<<@option_padding, rest::binary>>, so_far), do: decode(rest, so_far)
  defp decode_bin(<<@option_finish, _::binary>>, so_far), do: so_far
  defp decode_bin(<<code, len, value::binary-size(len), rest::binary>>, so_far) do
    decode_bin(rest, [{code, value} | so_far])
  end

  defp decode_mod(opts, []), do: opts
  defp decode_mod(opts, [module | rest]) do
    opts
    |> Enum.map(&module.decode/1)
    |> decode_mod(rest)
  end

  @doc """
  Encode the specified list of options to a binary for a DHCP packet.
  """
  @spec encode(keyword | map, [module]) :: iolist
  def encode(options, []), do: encode(options)
  def encode(options, [parser | rest]) do
    options
    |> Stream.reject(fn
      {_key, value} -> is_nil(value)
      _ -> false
    end)
    |> Stream.map(&parser.encode/1)
    |> encode(rest)
  end
  @spec encode(Enumerable.t) :: iolist
  def encode(options) do
    [options
     |> Enum.map(&encode_fragment/1)
     |> Enum.sort | <<@option_finish>>]
  end

  defp encode_fragment(binary) when is_binary(binary), do: binary
  defp encode_fragment({type, binary}) when is_integer(type) and is_binary(binary) do
    [<<type, :erlang.size(binary)>>, binary]
  end
  defp encode_fragment(_), do: ""

  #codec functions.

  # NB: sometimes DHCP clients will send a short instead of an integer.
  # For example, "max_message_size" is a commonly requested parameter.
  @spec decode_integer(binary) :: integer
  def decode_integer(<<a::32>>), do: a
  def decode_integer(<<a::16>>), do: a
  def decode_integer(<<a::8>>), do: a
  @spec encode_integer(typecode, integer) :: binary
  def encode_integer(type, a) when is_integer(a), do: <<type, 4, a::32>>

  @spec decode_short(binary) :: integer
  def decode_short(<<a::16>>), do: a
  @spec encode_short(typecode, integer) :: binary
  def encode_short(type, a) when is_integer(a), do: <<type, 2, a::16>>

  @spec decode_byte(binary) :: byte
  def decode_byte(<<a>>), do: a
  @spec encode_byte(typecode, byte) :: binary
  def encode_byte(type, a) when is_integer(a), do: <<type, 1, a>>

  @spec decode_ip(binary) :: Utils.ip4
  def decode_ip(<<a, b, c, d>>), do: {a, b, c, d}
  @spec encode_ip(typecode, Utils.ip4) :: binary
  def encode_ip(type, {a, b, c, d}), do: <<type, 4, a, b, c, d>>

  @spec decode_iplist(binary) :: [Utils.ip4]
  def decode_iplist(<<>>), do: []
  def decode_iplist(<<a, b, c, d>> <> rest) do
    [{a, b, c, d} | decode_iplist(rest)]
  end
  @spec encode_iplist(typecode, [Utils.ip4]) :: binary
  def encode_iplist(type, list) when is_list(list) do
    data = list
    |> Enum.map(fn {a, b, c, d} -> <<a, b, c, d>> end)
    |> IO.iodata_to_binary

    IO.iodata_to_binary([type, byte_size(data), data])
  end

  @spec decode_string(binary) :: binary
  def decode_string(bin), do: bin
  @spec encode_string(typecode, binary) :: binary
  def encode_string(type, value), do: <<type, byte_size(value), value::binary>>

  @spec decode_boolean(binary) :: boolean
  def decode_boolean(<<0>>), do: false
  def decode_boolean(_), do: true
  @spec encode_boolean(typecode, boolean | integer) :: binary
  def encode_boolean(type, true), do: <<type, 1, 1>>
  def encode_boolean(type, false), do: <<type, 1, 0>>
  def encode_boolean(type, value), do: <<type, 1, value>>

end
