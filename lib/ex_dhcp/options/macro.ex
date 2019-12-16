
defmodule ExDhcp.Options.Macro do

  @moduledoc """
  This module provides methods that facilitate custom encoding and decoding
  strategies for DHCP packet options.  `ExDhcp.Options.Basic` provides
  basic parameter encoding; the full DHCP specification provides for
  additional, proprietary, and custom options encoding.

  For example, [PXE](https://en.wikipedia.org/wiki/Preboot_Execution_Environment)
  (_**P**reboot e**X**ecution **E**nvironment_)
  uses an additional set of options to transmit booting information to the
  client.  These are implemented in `ExDhcp.Options.Pxe` for demonstration.

  If you need to implement additional options parsing use this module,
  include it as an option in the `use ExDhcp` directive along with `ExDhcp.Options.Basic`
  (unless you want to override it):

  ```elixir
  use ExDhcp, dhcp_options: [MyParser, ExDhcp.Options.Basic]
  ```

  ### Standard and Custom Parsing
  Pass the `options/1` macro a keyword list of parameter names and
  datatypes.  The options parser will then search for a module parameter
  corresponding to the keyword, and assign that integer as the
  options parameter.  The type will indicate either a standard type
  codec or an atom for a custom codec.

  The following standard types are implemented:

  | Name       | Erlang Term Type        | Binary Representation    |
  | ---------- | ----------------------- | ------------------------ |
  | `:ip`      | `{a, b, c, d}`          | 4 octets                 |
  | `:iplist`  | `list({a, b, c, d})`    | *N*x4 octets             |
  | `:string`  | `binary`                | variable octets          |
  | `:integer` | `integer`               | 4 octet (32 bit) integer |
  | `:short`   | `integer`               | 2 octet (16 bit) integer |
  | `:byte`    | `integer`               | 1 octet (8 bit) integer  |
  | `:boolean` | `boolean`               | one octet, either 1 or 0 |

  In the case of a custom codec, you must implement two functions:
  - `encode_<atom_value>/1`: &nbsp; The encoder should take a raw binary and convert
  it to an appropriate erlang term representing the atom.

  - `decode_<atom_value>/1`: &nbsp; The decoder should take an erlang term and convert
  it to an appropriate binary to be packed into the DHCP packet.

  `options/1` will append a relevant table of encoders/decoders into your module
  documentation as a feature.

  Here is an example implementation of a parser:

  ```elixir

  defmodule MyParser do

    import ExDhcp.Options.Macro

    @behaviour ExDhcp.Options.Api

    @option_1  123
    @option_2  124
    @option_3  125

    options option_1: :integer
            option_2: :string
            option_3: :option_3

    def decode_option_3(binary) do
      # code_to_decode_option_3
      result_erlang_term
    end

    def encode_option_3(source_erlang_term) do
      # code_to_encode_option_3
      result_binary
    end

  end

  ```

  Refer to `ExDhcp.Options.Basic` and `ExDhcp.Options.Pxe` source codes as an
  additional reference.

  _Learn more about PXE here: [Wikipedia](https://en.wikipedia.org/wiki/Preboot_Execution_Environment)_
  """

  @options_encodable [:ip, :iplist, :string, :integer, :short, :byte, :boolean]

  defp encode_fn(at_form, style, _) when style in @options_encodable do
    quote do Options.unquote(:"encode_#{style}")(unquote(at_form), value) end
  end
  defp encode_fn(at_form, style, context) do
    quote do
      Options.encode_string(
        unquote(at_form),
        unquote(context).unquote(:"encode_#{style}")(value))
    end
  end

  defp decode_fn(style, _context) when style in @options_encodable do
    quote do Options.unquote(:"decode_#{style}")(value) end
  end
  defp decode_fn(style, context) do
    quote do unquote(context).unquote(:"decode_#{style}")(value) end
  end

  @spec at_form(atom) :: Macro.t
  defp at_form(name) do
    {:@, [context: Elixir, import: Kernel], [{name, [context: Elixir], Elixir}]}
  end

  @doc false
  @spec encode_atom({atom, atom}, module) :: Macro.t
  def encode_atom({name, style}, context) do
    at_form = at_form(name)
    quote do
      def encode({unquote(name), value}), do: unquote(encode_fn(at_form, style, context))
    end
  end

  @doc false
  @spec encode_atval({atom, atom}, module) :: Macro.t
  def encode_atval({name, style}, context) do
    at_form = at_form(name)
    quote do
      def encode({unquote(at_form), binary}) when is_binary(binary) do
        <<unquote(at_form), :erlang.size(binary)>> <> binary
      end
      def encode({unquote(at_form), value}), do: unquote(encode_fn(at_form, style, context))
    end
  end

  @doc false
  @spec decode({atom, atom}, module) :: Macro.t
  def decode({name, style}, context) do
    at_form = at_form(name)
    quote do
      def decode({unquote(at_form), value}), do: {unquote(name), unquote(decode_fn(style, context))}
    end
  end

  @doc """
  Generates code for codecs based on a list of atom / type keys.

  See `ExDhcp.Options.Macro` for details and strategies for using
  this macro.
  """
  defmacro options(options_list) do
    context = __CALLER__.module
    atom_encoder = Enum.map(options_list, &encode_atom(&1, context))
    atval_encoder = Enum.map(options_list, &encode_atval(&1, context))
    decoder = Enum.map(options_list, &decode(&1, context))
    quote do

      @before_compile ExDhcp.Options.Macro
      @options_list unquote(options_list)

      alias ExDhcp.Options

      @doc false
      @spec encode({atom, term})               :: {atom, term} | binary
      @spec encode({Options.typecode, binary}) :: {Options.typecode, binary}
      unquote_splicing(atom_encoder)
      unquote_splicing(atval_encoder)
      def encode(any), do: any

      @doc false
      @spec decode({Options.typecode, binary}) :: {atom, term} | {Options.typecode, binary}
      @spec decode({atom, term})               :: {atom, term}
      unquote_splicing(decoder)
      def decode(any), do: any
    end
  end

  defp doc_table({_, false}, options, module), do: doc_table({nil, ""}, options, module)
  defp doc_table({_, predoc}, options_list, context_module) do

    # appends a a table of options encodings to the existing documentation
    # for the module.
    #
    # in order to properly read the options values from the module's attributes
    # it is necessary to run this function in the __before_compile__ context;
    # this module is passed in the "context_module" variable.

    encodings = options_list
    |> Enum.map(fn
      # builtin types have a simpler table scheme, where we just write
      # down the type.
      {option_name, type} when type in @options_encodable ->
        option_value = Module.get_attribute(context_module, option_name)
        "| `:#{option_name}` | #{option_value} | #{type} |"

      # for custom types, we report the names of the functions which will
      # be used to perform the encoding.  If they are documented by the user,
      # ExDoc will provide a hyperlink to that function.
      {option_name, custom_type} ->
        option_value = Module.get_attribute(context_module, option_name)
        encoder = "`encode_#{custom_type}/1`"
        decoder = "`decode_#{custom_type}/1`"
        "| `:#{option_name}` | #{option_value} | #{encoder} <br/> #{decoder} |"
    end)
    |> Enum.join("\n")

    # append the documentation table to the end of the previously generated
    # documentation by the user.
    """
    #{predoc}

    This module implements the following DHCP options encodings:

    | option atom | DHCP option code | type / codec |
    | ----------- | ---------------- | ------------ |
    #{encodings}
    """
  end

  @doc false
  defmacro __before_compile__(%{module: module}) do
    # extract moduledoc information (if it exists), or just pass a
    # tuple with empty string to the documentation generator.

    predoc = Module.get_attribute(module, :moduledoc) || {nil, ""}

    # grab the options_list table.
    options_list = Module.get_attribute(module, :options_list)
    documentation = doc_table(predoc, options_list, module)

    # reissue the moduledoc parameter, with the new injected table.
    quote do
      @moduledoc unquote(documentation)
    end
  end
end
