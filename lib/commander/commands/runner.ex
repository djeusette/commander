defmodule Commander.Commands.Runner do
  alias Commander.ExecutionContext

  @type context :: %ExecutionContext{}
  @type changes :: Map.t()
  @type error :: term()
  @type failed_operation :: term()
  @type failed_value :: any
  @type changes_so_far :: Map.t()

  @spec execute(context) :: {:ok, changes} |
  {:ok, pid} |
  {:error, error} |
  {:error, :task_exited, error} |
  {:error, :execution_timeout} |
  {:error,  failed_operation, failed_value, changes_so_far}
  def execute(%ExecutionContext{} = context) do
    execute_task(context)
  end

  defp execute_task(%ExecutionContext{async: true} = context) do
    task = start_task(context)
    kill_task_after(task, context)
    {:ok, task}
  end

  defp execute_task(%ExecutionContext{timeout: timeout, async: false} = context) do
    task = start_task(context)

    (Task.yield(task, timeout) || Task.shutdown(task))
    |> case do
      {:ok, reply} -> reply
      {:exit, error} -> {:error, :task_exited, error}
      nil -> {:error, :execution_timeout}
    end
  end

  defp kill_task_after(%Task{}, %ExecutionContext{timeout: :infinity}), do: nil

  defp kill_task_after(%Task{pid: pid}, %ExecutionContext{timeout: timeout}) when is_integer(timeout) do
    :timer.kill_after(timeout, pid)
  end

  defp start_task(%ExecutionContext{repo: repo, multi: multi, timeout: timeout}) do
    Task.Supervisor.async_nolink(
      Commander.Commands.TaskRunner,
      fn ->
        attempt_transaction(repo, multi, timeout)
      end)
  end

  defp attempt_transaction(repo, multi, timeout) do
    try do
      repo.transaction(multi, timeout: timeout, pool_timeout: timeout)
    rescue
      e -> {:error, e}
    end
  end
end
