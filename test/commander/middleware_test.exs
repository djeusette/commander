defmodule Commander.MiddlewareTest do
  use ExUnit.Case

  alias Commander.Middleware.Pipeline
  alias Commander.Helpers.CommandAuditMiddleware
  alias Commander.Pipeline

  alias Commander.Middleware.Commands.{
    IncrementCount,
    Fail,
    RaiseError,
    Timeout,
    CommandHandler,
  }

  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end

  defmodule FirstMiddleware do
    @behaviour Commander.Middleware

    def before_dispatch(pipeline), do: pipeline
    def after_dispatch(pipeline), do: pipeline
    def after_failure(pipeline), do: pipeline
  end

  defmodule ModifyMetadataMiddleware do
    @behaviour Commander.Middleware

    def before_dispatch(pipeline) do
      Pipeline.assign_metadata(pipeline, "updated_by", "ModifyMetadataMiddleware")
    end

    def after_dispatch(pipeline), do: pipeline
    def after_failure(pipeline), do: pipeline
  end

  defmodule LastMiddleware do
    @behaviour Commander.Middleware

    def before_dispatch(pipeline), do: pipeline
    def after_dispatch(pipeline), do: pipeline
    def after_failure(pipeline), do: pipeline
  end

  defmodule Router do
    use Commander.Router

    middleware FirstMiddleware
    middleware ModifyMetadataMiddleware
    middleware CommandAuditMiddleware
    middleware LastMiddleware

    dispatch [
               IncrementCount,
               Fail,
               RaiseError,
               Timeout
             ],
             to: CommandHandler
  end

  setup do
    CommandAuditMiddleware.start_link()
    CommandAuditMiddleware.reset()
  end

  test "should call middleware for each command dispatch" do
    aggregate_uuid = UUID.uuid4()

    {:ok, 1} = Router.dispatch(%IncrementCount{uuid: aggregate_uuid, by: 1})
    {:ok, 2} = Router.dispatch(%IncrementCount{uuid: aggregate_uuid, by: 2})
    {:ok, 3} = Router.dispatch(%IncrementCount{uuid: aggregate_uuid, by: 3})

    {dispatched, succeeded, failed} = CommandAuditMiddleware.count_commands()

    assert dispatched == 3
    assert succeeded == 3
    assert failed == 0

    dispatched_commands = CommandAuditMiddleware.dispatched_commands()
    succeeded_commands = CommandAuditMiddleware.succeeded_commands()

    assert pluck(dispatched_commands, :by) == [1, 2, 3]
    assert pluck(succeeded_commands, :by) == [1, 2, 3]
  end

  test "should execute middleware failure callback when aggregate process returns an error tagged tuple" do
    # force command handling to return an error
    {:error, :failed} = Router.dispatch(%Fail{uuid: UUID.uuid4()})

    {dispatched, succeeded, failed} = CommandAuditMiddleware.count_commands()

    assert dispatched == 1
    assert succeeded == 0
    assert failed == 1
  end

  test "should execute middleware failure callback when aggregate process errors" do
    # force command handling to error
    {:error, :execution_failed, {%RuntimeError{message: "failed"}, _}} =
      Router.dispatch(%RaiseError{uuid: UUID.uuid4()})

    {dispatched, succeeded, failed} = CommandAuditMiddleware.count_commands()

    assert dispatched == 1
    assert succeeded == 0
    assert failed == 1
  end

  test "should execute middleware failure callback when aggregate process dies" do
    # force command handling to timeout so the aggregate process is terminated
    :ok =
      case Router.dispatch(%Timeout{uuid: UUID.uuid4()}, 50) do
        {:error, :execution_timeout} -> :ok
        {:error, :execution_failed} -> :ok
      end

    {dispatched, succeeded, failed} = CommandAuditMiddleware.count_commands()

    assert dispatched == 1
    assert succeeded == 0
    assert failed == 1
  end

  test "should let a middleware update the metadata" do
    {:ok, %Pipeline{metadata: metadata}} =
      Router.dispatch(
        %IncrementCount{uuid: UUID.uuid4(), by: 1},
        include_pipeline: true,
        metadata: %{"first_metadata" => "first_metadata"}
      )

    assert metadata == %{
             "first_metadata" => "first_metadata",
             "updated_by" => "ModifyMetadataMiddleware"
           }
  end
end
