require 'gosu'
require 'pry'
require 'imagetext'

class Maze
  attr_reader :width, :height
  attr_reader :cells
  attr_reader :contents
  attr_accessor :playerX, :playerY
  attr_accessor :player

  def initialize(w, h)
    @width = w
    @height = h
    @cells = Array.new(w * h, true)
    @contents = Array.new(w * h) {[]}
    # Note: both horizontal and vertical walls are addressed in the order
    @horizontals = Array.new((w + 1) * (h + 1), true)
    @verticals = Array.new((w + 1) * (h + 1), true)
  end
  
  def getNeighbours(x, y)
    nb = []
    #binding.pry
    nb << [x - 1, y] if getCell(x - 1, y)
    nb << [x + 1, y] if getCell(x + 1, y)
    nb << [x, y - 1] if getCell(x, y - 1)
    nb << [x, y + 1] if getCell(x, y + 1)
    
    return nb
  end
  
  def getCell(x, y)
    if x >= 0 && y >= 0 && x < @width && y < @height
      return @cells[y * @width + x]
    else
      return false
    end
  end
  
  def getContents(x, y)
    return @contents[y * @width + x] || []
  end
  
  
  def getWallBetween(x1, y1, x2, y2)
    xavg = ((x1 + x2) / 2.0 + 0.5).to_i
    yavg = ((y1 + y2) / 2.0 + 0.5).to_i
    
    #binding.pry if yavg == 5
    
    if x1 == x2
      return @horizontals[(@width + 1) * yavg + xavg]
    elsif y1 == y2
      return @verticals[(@width + 1) * yavg + xavg]
    else
      raise "Bad cell address: x1 = #{x1}, y1 = #{y1}, x2 = #{x2}, y2 = #{y2}"
    end
  end
  
  def movePlayer(dx, dy)
    nx, ny = @playerX + dx, @playerY + dy
    wall = getWallBetween(@playerX, @playerY, nx, ny)
    
    if nx >= 0 && nx < @width && !wall
      @playerX = nx
    end
    
    if ny >= 0 && ny < @height && !wall
      @playerY = ny
    end
  end
  
  def setCell(x, y, value = false)
    @cells[y * @width + x] = value
  end
  
  def setContents(x, y, conts)
    @contents[y * @width + x] = conts
  end
  
  def setWallBetween(x1, y1, x2, y2, value = false)
    xavg = ((x1 + x2) / 2.0 + 0.5).to_i
    yavg = ((y1 + y2) / 2.0 + 0.5).to_i
    
    if x1 == x2
      @horizontals[(@width + 1) * yavg + xavg] = value
    elsif y1 == y2
      @verticals[(@width + 1) * yavg + xavg] = value
    else
      raise "Bad cell address: x1 = #{x1}, y1 = #{y1}, x2 = #{x2}, y2 = #{y2}"
    end
  end
  
  def Maze.generate(w, h)
    maze = self.new(w, h)
    
    x, y = 0, 0
    path = []
    
    while maze.cells.any?
      nb = maze.getNeighbours(x, y)
      if nb.length > 0
        n = nb[rand(nb.length)];
        maze.setWallBetween(x, y, n[0], n[1], false)
        maze.setCell(n[0], n[1], false)
        path.push [x, y]
        x, y = n
      else
        # Backtrack
        x, y = path.pop
        #binding.pry
      end
    end

    (1 + rand(4)).times do
      x, y = rand(maze.width - 1), rand(maze.height - 1)
      maze.getContents(x, y) << "maize"
      
    end
    
    (4 + rand(4)).times do
      x, y = rand(maze.width - 1), rand(maze.height - 1)
      maze.getContents(x, y) << "spikes"
    end
    
    return maze
  end
end

class Player
  attr_reader :image
  attr_reader :maxLives, :lives
  
  def initialize(maxLives)
    @image = Gosu::Image.new("player.png")
    @deadImage = Gosu::Image.new("grave.png")
    @maxLives = maxLives
    @lives = @maxLives
  end
  
  def damage(life = 1)
    if @lives - life >= 0
      @lives -= life
    end
  end
  
  def dead?
    if @lives <= 0
      @image = @deadImage
    end
    return @lives <= 0
  end
  
  def heal(life = 1)
    if @lives + life <= @maxLives
      @lives += life
    end
  end
  
  def draw(x, y, cellDim, wallWidth)
    @image.draw(x * (cellDim + wallWidth) + wallWidth, y * (cellDim + wallWidth) + wallWidth, 0)
  end
end

class MazeUI
  attr_writer :maxLives
  
  def initialize(anchorX, anchorY, maxWidth)
    @img_heartFull = Gosu::Image.new("heart_full.png")
    @img_heartEmpty = Gosu::Image.new("heart_empty.png")
    # Anchor is lower left corner.
    @ax = anchorX
    @ay = anchorY
    @maxLives = maxWidth
  end
  
  def draw(lives)
    @maxLives.times do |i|
      x = @ax + @img_heartFull.width * i
      y = @ay - @img_heartFull.height
      
      if i < lives
        @img_heartFull.draw(x, y, 0)
      else
        @img_heartEmpty.draw(x, y, 0)
      end
    end
  end
end

class MaizeWindow < Gosu::Window
  CELL_DIM = 16
  WALL_WIDTH = 8
  CELL_COLOR = Gosu::Color::GRAY
  WALL_COLOR = Gosu::Color.new(255, 80, 80, 80)
  
  IMG_MAIZE = Gosu::Image.new("maize.png")
  IMG_SPIKES = Gosu::Image.new("spikes.png")
  
  def initialize
    super 800, 600, false
    self.caption = "Maize Game"
    @tileset = Gosu::Image.load_tiles("Tile.png", 16, 16, retro: true)
    #binding.pry
    @maze = Maze.generate(10, 10)
    @maze.player = Player.new(5)
    @mazeUI = MazeUI.new(width - @maze.player.maxLives * 16, height, @maze.player.maxLives)
    
    @maze.playerX = 0
    @maze.playerY = 0
    
    @gameOver = false
    @bigFont = Gosu::Font.new(32, name: "./SDS_8x8.ttf")
  end
  
  def needs_cursor?
    return true
  end
  
  def button_down(id)
    #puts(id: id, KbRight: Gosu::KbRight)
    
    if not @gameOver
      case id
        when Gosu::KbUp
          @maze.movePlayer(0, -1)
        when Gosu::KbDown
          @maze.movePlayer(0, 1)
        when Gosu::KbLeft
          @maze.movePlayer(-1, 0)
        when Gosu::KbRight
          @maze.movePlayer(1, 0)
          #puts(x: @maze.playerX, y: @maze.playerY)
      end
    end
    
    updateOnMove
  end
  
  def updateOnMove
    @maze.getContents(@maze.playerX, @maze.playerY).each_with_index do |item, i|
      case item
        when "maize"
          @maze.player.heal
          @maze.getContents(@maze.playerX, @maze.playerY).delete(item)
        when "spikes"
          @maze.player.damage
      end
    end
    
    @gameOver = @maze.player.dead?
    if @gameOver
      @deadTime = Gosu.milliseconds
    end
  end
  
  def draw
    combdim = CELL_DIM + WALL_WIDTH
    

    for y in 0..(@maze.height)
      for x in 0..(@maze.width)
        sx = x * combdim
        sy = y * combdim
        
        # Vertical wall draw.
        if y == @maze.height 
        elsif @maze.getWallBetween(x - 1, y, x, y)
          Gosu.draw_rect(sx, sy + WALL_WIDTH, WALL_WIDTH, CELL_DIM, WALL_COLOR)
        end
        
        # Horizontal wall draw.
        if x == @maze.width
        elsif @maze.getWallBetween(x, y - 1, x, y)
          Gosu.draw_rect(sx + WALL_WIDTH, sy, CELL_DIM, WALL_WIDTH, WALL_COLOR)
        end
        
        if @maze.getCell(x, y)
          Gosu.draw_rect(sx + WALL_WIDTH, sy + WALL_WIDTH, CELL_DIM, CELL_DIM, CELL_COLOR)
        end
        
        # Fill in lacking spots.
        Gosu.draw_rect(sx, sy, CELL_DIM - WALL_WIDTH, CELL_DIM - WALL_WIDTH, WALL_COLOR)
        
        #puts "x = #{x}, y = #{y}"
        #puts(hc: hcount, vc: vcount, oc: ocount)
    
        #binding.pry
        #@maze.getContents(x, y).each do |item| puts item end
        @maze.getContents(x, y).each do |item|
          case item
            when "maize"
              img = IMG_MAIZE
            when "spikes"
              img = IMG_SPIKES
          end
      
          img.draw(sx + WALL_WIDTH, sy + WALL_WIDTH, 0)
        end
      end
    end
    

    @maze.player.draw(@maze.playerX, @maze.playerY, CELL_DIM, WALL_WIDTH)
    @mazeUI.draw(@maze.player.lives)
    
    if @gameOver
      text = "You died..."
      textWidth = @bigFont.text_width(text)
      @bigFont.draw(text, (width - textWidth) / 2, height / 2, 0, 1, 1, Gosu::Color::WHITE)
      
      if Gosu.milliseconds - @deadTime > 3000
        self.close
      end
    end
  end
end

MaizeWindow.new.show