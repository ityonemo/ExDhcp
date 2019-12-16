defmodule ExDhcp.Utils do

  @moduledoc """
  Provides utilities containing typespecs for data types and binary/string
  conversions for _ip_ and _mac_ addresses. For ease-of-use both within this
  library and when using it.
  """

  @typedoc "Erlang-style _ip_ addresses."
  @type ip4 :: :inet.ip4_address
  @typedoc "_Mac_ addresses in the same style as the erlang _ip_ address."
  @type mac :: {byte, byte, byte, byte, byte, byte}

  @doc """
  Represents an erlang-style ip4 value as a string, without going through
  a list intermediate.
  """
  @spec ip2str(ip4) :: binary
  def ip2str(_ip_addr = {a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"

  @doc """
  Converts an erlang-style _ip_ address (4-tuple of bytes)
  to a binary stored _ip_ address (in the dhcp packet spec)
  """
  @spec ip2bin(ip4) :: <<_::32>>
  def ip2bin(_ip_addr = {a, b, c, d}), do: <<a, b, c, d>>

  @doc """
  Converts a binary stored _ip_ address (in the dhcp packet spec) to
  an erlang-style _ip_ address. (4-tuple of bytes)
  """
  @spec bin2ip(<<_::32>>) :: ip4
  def bin2ip(_mac_addr = <<a, b, c, d>>), do: {a, b, c, d}

  @doc """
  Converts a binary stored _mac_ address (in the dhcp packet spec) to
  an erlang-style _mac_ address. (6-tuple of bytes)
  """
  def bin2mac(_mac_addr = <<a, b, c, d, e, f>>), do: {a, b, c, d, e, f}

  @doc """
  Converts an erlang-style _mac_ address (6-tuple of bytes) to a
  binary stored _mac_ address (in the dhcp packet spec).
  """
  def mac2bin(_mac_addr = {a, b, c, d, e, f}), do: <<a, b, c, d, e, f>>

  @doc """
  Converts a _mac_ address 6-byte tuple to a string.

  ```elixir
  iex> ExDhcp.Utils.mac2str({1, 2, 3, 16, 255, 254})
  "01:02:03:10:FF:FE"
  ```
  """
  def mac2str(mac_addr = {_, _, _, _, _, _}) do
    mac_addr
    |> Tuple.to_list
    |> Enum.map(&padhex/1)
    |> Enum.join(":")
  end

  @doc """
  Converts a _mac_ address string into a raw binary value.

  ```elixir
  iex> ExDhcp.Utils.str2mac("01:02:03:10:FF:FE")
  {1, 2, 3, 16, 255, 254}
  ```
  """
  def str2mac(_mac_addr = <<a::16, ":", b::16, ":", c::16, ":", d::16, ":", e::16, ":", f::16>>) do
    [<<a::16>>, <<b::16>>, <<c::16>>, <<d::16>>, <<e::16>>, <<f::16>>]
    |> Enum.map(&String.to_integer(&1, 16))
    |> List.to_tuple
  end

  defp padhex(v) when v < 16, do: "0" <> Integer.to_string(v, 16)
  defp padhex(v), do: Integer.to_string(v, 16)

  @spec cidr2mask(cidr :: 0..32) :: ip4
  @doc """
  Creates a subnet mask from a _cidr_ value.

  ```elixir
  iex> ExDhcp.Utils.cidr2mask(24)
  {255, 255, 255, 0}
  ```
  """
  def cidr2mask(_cidr_val = n) do
    import Bitwise
    <<a, b, c, d>> = <<-1 <<< (32 - n)::32>>
    {a, b, c, d}
  end

end
