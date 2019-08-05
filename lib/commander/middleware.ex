defmodule Commander.Middleware do
  @type pipeline :: %Commander.Pipeline{}

  @callback before_dispatch(pipeline) :: pipeline
  @callback after_dispatch(pipeline) :: pipeline
  @callback after_failure(pipeline) :: pipeline
end
