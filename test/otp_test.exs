defmodule ExDhcpTest.OtpTest do
  # module for making sure that we are otp-compliant.
  use ExUnit.Case, async: true

  test "a supervised trivial has a dynamic_supervisor" do
    children = [
      {ExDhcp, {TrivialStub, "foo", port: 0, name: :sup_test, trivial_name: Foo}}]

    Supervisor.start_link(
      children, strategy: :one_for_one)
  end

end
