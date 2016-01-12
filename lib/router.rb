class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern, @http_method, @controller_class, @action_name = pattern, http_method, controller_class, action_name
  end

  def matches?(req)
    req.path =~ @pattern && req.request_method == @http_method.to_s.upcase
  end

  def run(req, res)
    match_data = @pattern.match(req.path)
    route_params = {}
    csrf = false
    if @http_method == :post
      csrf = true
    end
    match_data.names.map { |key| route_params[key] = match_data[key] }
    controller = @controller_class.new(req, res, route_params)
    controller.invoke_action(@action_name, csrf)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  def draw(&proc)
    self.instance_eval(&proc)
  end

  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  def match(req)
    @routes.select do |route|
      route.matches?(req)
    end.first
  end

  def run(req, res)
    if match(req)
      match(req).run(req, res)
    else
      res.status = 404
    end
  end
end
