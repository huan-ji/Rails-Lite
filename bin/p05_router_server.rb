require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'
require_relative 'exception_handling'
require_relative 'statc_assets'

$cats = [
  { id: 1, name: "Curie" },
  { id: 2, name: "Markov" }
]

$statuses = [
  { id: 1, cat_id: 1, text: "Curie loves string!" },
  { id: 2, cat_id: 2, text: "Markov is mighty!" },
  { id: 3, cat_id: 1, text: "Curie is cool!" }
]

class StatusesController < ControllerBase
  def index
    statuses = $statuses.select do |s|
      s[:cat_id] == Integer(params['cat_id'])
    end

    render_content(statuses.to_s, "text/text")
  end
end

class Cats2Controller < ControllerBase
  def index

  end

  def new
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/cats$"), Cats2Controller, :index
  post Regexp.new("^/cats$"), Cats2Controller, :create
  get Regexp.new("^/cats/new$"), Cats2Controller, :new
  get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

middle_app = Rack::Builder.new do
  # use ExceptionHandling
  use StaticAssets
  run app
end.to_app

Rack::Server.start(
 app: middle_app,
 Port: 3000
)
