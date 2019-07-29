defmodule Commander.Command do
  @type command :: struct()

  @callback validate(Ecto.Changeset.t(), command) :: Ecto.Changeset.t()
  @callback schema :: Map.t()
  @callback required_keys :: Map.t()

  defmacro __using__(_) do
    quote do
      import Ecto.Changeset
      @behaviour Commander.Command

      alias Commander.Support.Module
      alias Commander.Command.Builder

      def new(params \\ %{}) do
        Module.to_struct(__MODULE__, params)
        |> Builder.build()
      end

      @spec changeset(command) :: Ecto.Changeset.t()
      def changeset(%__MODULE__{} = cmd) do
        {%__MODULE__{}, schema()}
        |> cast(Map.from_struct(cmd), Map.keys(schema()))
        |> validate_required(required_keys())
        |> validate(cmd)
      end

      @spec valid?(command) :: :ok | {:error, keyword()}
      def valid?(%__MODULE__{} = cmd) do
        changeset = changeset(cmd)

        case changeset.valid? do
          false -> {:error, changeset.errors}
          true -> :ok
        end
      end
    end
  end

  defprotocol Builder do
    @fallback_to_any true
    @doc "Allows to apply additional operations on the command built from the params"
    def build(command)
  end

  defimpl Builder, for: Any do
    def build(command), do: command
  end
end
