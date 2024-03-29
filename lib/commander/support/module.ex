defmodule Commander.Support.Module do
  def to_struct(kind, attrs) do
    struct = struct(kind)

    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, k) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end)
  end
end
