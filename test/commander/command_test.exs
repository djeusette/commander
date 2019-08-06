defmodule Commander.CommandTest do
  use ExUnit.Case

  describe "a command with default functions" do
    defmodule DefaultCommand do
      defstruct [:foo, :bar]
      use Commander.Command
    end

    test "is valid" do
      command = DefaultCommand.new(%{})
      assert :ok = DefaultCommand.valid?(command)
    end
  end

  describe "a command with default functions but schema" do
    defmodule SchemaCommand do
      defstruct [:foo, :bar]
      use Commander.Command

      def schema do
        %{foo: :string, bar: :string}
      end
    end

    test "is valid if attributes are missing" do
      command = SchemaCommand.new(%{})
      assert :ok = SchemaCommand.valid?(command)
    end

    test "is valid with all attributes" do
      command = SchemaCommand.new(%{foo: "foo", bar: "bar"})
      assert :ok = SchemaCommand.valid?(command)
    end
  end

  describe "a command with schema and required_keys functions" do
    defmodule DefaultValidationCommand do
      defstruct [:foo, :bar]
      use Commander.Command

      def schema do
        %{foo: :string, bar: :string}
      end

      def required_keys do
        [:foo]
      end
    end

    test "is valid with all attributes" do
      command = DefaultValidationCommand.new(%{foo: "foo", bar: "bar"})
      assert :ok = DefaultValidationCommand.valid?(command)
    end

    test "is valid without optional attributes" do
      command = DefaultValidationCommand.new(%{foo: "foo"})
      assert :ok = DefaultValidationCommand.valid?(command)
    end

    test "is invalid without required attributes" do
      command = DefaultValidationCommand.new(%{bar: "bar"})
      assert {:error, [foo: {"can't be blank", [validation: :required]}]} = DefaultValidationCommand.valid?(command)
    end

    test "is invalid with no attributes" do
      command = DefaultValidationCommand.new(%{})
      assert {:error, [foo: {"can't be blank", [validation: :required]}]} = DefaultValidationCommand.valid?(command)
    end
  end

  describe "a command with extra validation" do
    defmodule ExtraValidationCommand do
      defstruct [:foo, :bar]
      use Commander.Command

      def schema do
        %{foo: :string, bar: :string}
      end

      def required_keys do
        [:foo]
      end

      def validate(%Ecto.Changeset{} = changeset, %ExtraValidationCommand{}) do
        changeset
        |> validate_format(:foo, ~r/@/)
      end
    end

    test "is invalid if the extra validation fails" do
      command = ExtraValidationCommand.new(%{foo: "bla"})
      assert {:error, [foo: {"has invalid format", [validation: :format]}]} = ExtraValidationCommand.valid?(command)
    end

    test "is valid when the extra validation passes" do
      command = ExtraValidationCommand.new(%{foo: "bl@"})
      assert :ok = ExtraValidationCommand.valid?(command)
    end
  end

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
