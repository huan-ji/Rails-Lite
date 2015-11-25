require 'json'

class Flash

  def initialize(req)
    flash = req.cookies["flash"]
    if flash
      @flash = JSON.parse(cookie)
    else
      @flash = {}
    end
  end

  def now

  end

  def [](key)
    @flash[key]
  end

  def []=(key, val)
    @flash[key] = val
  end
end
