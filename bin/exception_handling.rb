require "coderay"

class ExceptionHandling
  attr_reader :app
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      app.call(env)
    rescue => errors
      @error = errors
      @error_inspect = errors.inspect
      @error_message = errors.message
      @error_backtrace = errors.backtrace.join("<br>")
      @source_file = source_code(errors)
      path = "views/exception_handling/error.html.erb"
      file = File.read(path)
      content = ERB.new(file).result(binding)
      res = Rack::Response.new
      res['Content-Type'] = "text/html"
      res.write(content)
      res.finish
    end
  end

  def source_code(error)
    source = error.backtrace.first.split(":in").first.split(":")
    source_path = source.first
    source_line = source.last.to_i
    source_file = CodeRay.scan(File.readlines(source_path)[(source_line - 8)..(source_line + 8)].join(""), :ruby).div(:line_numbers => :table)
  end
end
