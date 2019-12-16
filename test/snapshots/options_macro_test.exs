defmodule DhcpTest.Options.MacroTest do

  #
  #  snapshot testing against ExDhcp.Options.OptionsMacro to make sure
  #  that it gives you the expected code.
  #

  alias ExDhcp.Options.Macro, as: OptionsMacro
  use ExUnit.Case

  @moduletag :OptionsMacro_snapshot

  def reformat(code) do
    code
    |> Code.format_string!(locals_without_parens: [def: 2])
    |> :erlang.iolist_to_binary
  end

  defmacrop assert_code(code, term) do
    quote do
      assert reformat(unquote(code)) == reformat(Macro.to_string(unquote(term)))
    end
  end

  describe "when passed options codegen parameters" do
    test "encode_atom generates the correct function" do
      assert_code """
      def(encode({:subnet_mask, value})) do
        Options.encode_ip(@subnet_mask, value)
      end
      """, OptionsMacro.encode_atom({:subnet_mask, :ip}, __MODULE__)
    end

    test "encode_atval generates the correct function" do
      assert_code """
      def(encode({@subnet_mask, binary}) when is_binary(binary)) do
        <<@subnet_mask, :erlang.size(binary)>> <> binary
      end
      def(encode({@subnet_mask, value})) do
        Options.encode_ip(@subnet_mask, value)
      end
      """, OptionsMacro.encode_atval({:subnet_mask, :ip}, __MODULE__)
    end

    test "decode generates the correct function" do
      assert_code """
      def(decode({@subnet_mask, value})) do
        {:subnet_mask, Options.decode_ip(value)}
      end
      """, OptionsMacro.decode({:subnet_mask, :ip}, __MODULE__)
    end
  end

  describe "when passed locally implemented codecs" do
    test "encode_atom generates the correct function" do
      assert_code """
      def(encode({:local, value})) do
        Options.encode_string(@local, DhcpTest.Options.MacroTest.encode_local(value))
      end
      """, OptionsMacro.encode_atom({:local, :local}, __MODULE__)
    end

    test "encode_atval generates the correct function" do
      assert_code """
      def(encode({@local, binary}) when is_binary(binary)) do
        <<@local, :erlang.size(binary)>> <> binary
      end
      def(encode({@local, value})) do
        Options.encode_string(@local, DhcpTest.Options.MacroTest.encode_local(value))
      end
      """, OptionsMacro.encode_atval({:local, :local}, __MODULE__)
    end

    test "decode generates the correct function" do
      assert_code """
      def(decode({@local, value})) do
        {:local, DhcpTest.Options.MacroTest.decode_local(value)}
      end
      """, OptionsMacro.decode({:local, :local}, __MODULE__)
    end
  end

end
