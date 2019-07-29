defmodule Commander.CommandTest do
  use ExUnit.Case

  describe "valid? with no additional validation" do
    defmodule TestCommand1 do
      defstruct [:foo]

      use Commander.Command
      alias Commander.Command

      @impl Command
      def validate(changeset, _command) do
        changeset
      end

      @impl Command
      def schema do
        %{foo: :string}
      end

      @impl Command
      def required_keys do
        [:foo]
      end
    end

    test "it returns :ok if all args are present in the params" do
      command = TestCommand1.new(%{foo: "hello"})
      assert :ok = TestCommand1.valid?(command)
    end

    test "it returns an error tuple if args are missing" do
      command = TestCommand1.new(%{})
      assert {:error, _} = TestCommand1.valid?(command)
    end
  end

  describe "valid? with additional validation" do
    defmodule TestCommand2 do
      defstruct [:foo]

      use Commander.Command
      alias Commander.Command

      @impl Command
      def validate(changeset, _command) do
        changeset
        |> validate_format(:foo, ~r/[0-9]{1}.*/)
      end

      @impl Command
      def schema do
        %{foo: :string}
      end

      @impl Command
      def required_keys do
        [:foo]
      end
    end

    test "it returns ok if the additional validation is verified" do
      command = TestCommand2.new(%{foo: "1hello"})
      assert :ok = TestCommand2.valid?(command)
    end

    test "it returns an error tuple if any additional validation fails" do
      command = TestCommand2.new(%{foo: "hello"})
      assert {:error, _} = TestCommand2.valid?(command)
    end
  end
end
