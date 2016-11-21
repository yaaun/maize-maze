require 'gosu'

module ImageText
  class ImageText
    def initialize(path, twidth, theight, offset = 32, options = {})
      @chars = Gosu::Image.load_tiles(path, twidth, theight, options)
      @offset = offset
      
      @glyphWidth = twidth
      @glyphHeight = theight
    end
  end
  
  def draw(text, x, y, z, scale_x = 1.0, scale_y = 1.0, color = 0xff_ffffff, mode = :default)
    text.codepoints.each_with_index do |c, i|
      glyph = @chars.fetch(c - @offset)
      glyph.draw(x + i * @glyphWidth, y, z, scale_x, scale_y, color, mode)
    end
  end
end