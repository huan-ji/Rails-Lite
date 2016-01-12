class StaticAssets
  attr_reader :app
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.path.match(/^\/publi/)
      file_name = req.path
      file = File.read("./public#{file_name}")
      res = Rack::Response.new
      res['Content-type'] = "image/jpeg"
      res.write(file)
      res.finish
    else
      app.call(env)
    end
  end
end
