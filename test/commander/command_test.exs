defmodule Commander.CommandTest do
  use ExUnit.Case

  describe "valid? with no additional validation" do
    alias Commander.Commands.CommandBasicTest

    test "it returns :ok if all args are present in the params" do
      command = CommandBasicTest.new(%{foo: "hello"})
      assert :ok = CommandBasicTest.valid?(command)
    end

    test "it returns an error tuple if args are missing" do
      command = CommandBasicTest.new(%{})
      assert {:error, _} = CommandBasicTest.valid?(command)
    end
  end

  describe "valid? with additional validation" do
    alias Commander.Commands.CommandFormatValidationTest

    test "it returns ok if the additional validation is verified" do
      command = CommandFormatValidationTest.new(%{foo: "1hello"})
      assert :ok = CommandFormatValidationTest.valid?(command)
    end

    test "it returns an error tuple if any additional validation fails" do
      command = CommandFormatValidationTest.new(%{foo: "hello"})
      assert {:error, _} = CommandFormatValidationTest.valid?(command)
    end
  end
end
