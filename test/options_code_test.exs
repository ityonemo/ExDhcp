defmodule DhcpTest.OptionsCodeTest do

  use ExUnit.Case

  @moduletag :basic_options

  alias ExDhcp.Options.Basic

  @subnet_mask              1
  @routers                  3
  @host_name                12
  @lease_time               51
  @message_type             53
  @parameter_request_list   55
  @client_ndi               94
  @forcerenew_nonce_capable 145

  describe "encoding to binaries works" do
    test "for subnet_mask (ip example)" do
      assert <<@subnet_mask, 4, 10, 1, 10, 255>> ==
        Basic.encode({:subnet_mask, {10, 1, 10, 255}})
      assert <<@subnet_mask, 4, 10, 1, 10, 255>> ==
        Basic.encode({@subnet_mask, {10, 1, 10, 255}})
    end

    test "for routers (iplist example)" do
      assert <<@routers, 8, 10, 1, 10, 1, 10, 1, 11, 1>> ==
        Basic.encode({:routers, [{10, 1, 10, 1}, {10, 1, 11, 1}]})
      assert <<@routers, 8, 10, 1, 10, 1, 10, 1, 11, 1>> ==
        Basic.encode({@routers, [{10, 1, 10, 1}, {10, 1, 11, 1}]})
    end

    test "for host_name (string example)" do
      assert <<@host_name, 3, "foo">> == Basic.encode({:host_name, "foo"})
      assert <<@host_name, 3, "foo">> == Basic.encode({@host_name, "foo"})
    end

    test "for lease_time (integer example)" do
      assert <<@lease_time, 4, 100::32>> == Basic.encode({:lease_time, 100})
      assert <<@lease_time, 4, 100::32>> == Basic.encode({@lease_time, 100})
    end

    test "for message_type (message type example)" do
      assert <<@message_type, 1, 1>> == Basic.encode({:message_type, :discover})
      assert <<@message_type, 1, 1>> == Basic.encode({@message_type, <<1>>})
    end

    test "for parameter_request_list (parameter type example)" do
      assert <<@parameter_request_list, 4, 1, 2, 3, 4>> ==
        Basic.encode({:parameter_request_list, [1, 2, 3, 4]})
      assert <<@parameter_request_list, 4, 1, 2, 3, 4>> ==
        Basic.encode({@parameter_request_list, [1, 2, 3, 4]})
    end

    test "for client_ndi (client ndi type example)" do
      assert <<@client_ndi, 3, 1, 2, 3>> == Basic.encode({:client_ndi, {1, 2, 3}})
      assert <<@client_ndi, 3, 1, 2, 3>> == Basic.encode({@client_ndi, <<1, 2, 3>>})
    end

    test "for forcerenew_nonce_capable (boolean type example)" do
      assert <<@forcerenew_nonce_capable, 1, 1>> ==
        Basic.encode({:forcerenew_nonce_capable, true})
      assert <<@forcerenew_nonce_capable, 1, 1>> ==
        Basic.encode({@forcerenew_nonce_capable, 1})
    end

    test "spurious tags are passed on" do
      pair = {:nonsense_atom, {:my, "funny", [:term]}}
      assert pair == Basic.encode(pair)

      numpair = {254, "this is binary"}
      assert numpair == Basic.encode(numpair)
    end
  end

  describe "decoding from binaries works" do
    test "for subnet_mask (ip example)" do
      assert {:subnet_mask, {10, 1, 10, 255}} ==
        Basic.decode({@subnet_mask, <<10, 1, 10, 255>>})
    end

    test "for routers (iplist example)" do
      assert {:routers, [{10, 1, 10, 1}, {10, 1, 11, 1}]} ==
        Basic.decode({@routers, <<10, 1, 10, 1, 10, 1, 11, 1>>})
    end

    test "for host_name (string example)" do
      assert {:host_name, "foo"} == Basic.decode({@host_name, "foo"})
    end

    test "for lease_time (integer example)" do
      assert {:lease_time, 100} == Basic.decode({@lease_time, <<100::32>>})
    end

    test "for message_type (message type example)" do
      assert {:message_type, :discover} == Basic.decode({@message_type, <<1>>})
    end

    test "for parameter_request_list (parameter type example)" do
      assert {:parameter_request_list, [1, 2, 3, 4]} ==
        Basic.decode({@parameter_request_list, <<1, 2, 3, 4>>})
    end

    test "for client_ndi (client ndi type example)" do
      assert {:client_ndi, {1, 2, 3}} == Basic.decode({@client_ndi, <<1, 2, 3>>})
    end

    test "for forcerenew_nonce_capable (boolean type example)" do
      assert {:forcerenew_nonce_capable, true} ==
        Basic.decode({@forcerenew_nonce_capable, <<1>>})
    end

    test "undecipherable tags are not deciphered" do
      numpair = {254, "this is binary"}
      assert numpair == Basic.decode(numpair)
    end
  end
end
