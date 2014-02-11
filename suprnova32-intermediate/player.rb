class Player

  def initialize
    @units_bound = []
    @rescued = 0
    @previous_direction = :forward
    @orientations = [:forward, :left, :right, :backward]
  end

  def add_bound_unit (unit)
    @units_bound << unit
  end

  def play_turn(warrior)
    should_attack, where = enemies_around(warrior)
    caps, locations, ticking, tick_locations = number_of_captives(warrior)
    p "There are #{ticking} captives"
    unless @sensed
      @captives = caps
      @sensed = true
    end

    if warrior.health < 4
      if should_attack
        p "I'm weak!"
        warrior.walk! walk_to_free_space(warrior)
        return
      else
        warrior.rest!
        return
      end
    end


    directions = location_of_enemies(warrior)
    number = immediate_enemies(warrior)



    if number > 1
      directions.reverse_each do |d|
        unless warrior.feel(warrior.direction_of(d)).captive?
          p warrior.direction_of(d) == :forward
          unless warrior.direction_of(d) == :forward and ticking > 0
            p "We are about to bind to #{warrior.direction_of(d)}"
            add_bound_unit d
            p 'Warrior bind!'
            warrior.bind! warrior.direction_of(d)
            return
          end
        end
      end
      return
    elsif bomb_squad(warrior)
      p 'Bomb squad to the rescue'
      return
    elsif should_attack and path_blocked(warrior)
      p 'Warrior attack!'
      warrior.attack! where
      return
    elsif ticking > 0
      p 'There is a ticking captive!'
      rescue_ticking_first(warrior, warrior.direction_of(tick_locations.first))
      return
    elsif number == 0 and caps > 0
      p 'There is a captive!'
      rescue_ticking_first(warrior, warrior.direction_of(locations.first))
      return
    elsif should_attack
      p 'Warrior attack!'
      warrior.attack! where
      return
    else
      p 'Continue the fight!'
      fight_all_sludges(warrior)
    end

    location = warrior.listen
    unless location.empty?
      p 'Listen!'
      if @units_bound.include? warrior.feel(warrior.direction_of(location.first))
        warrior.attack! warrior.direction_of(warrior.listen.first)
      end
    end

  end

  def walk_to_free_space(warrior)
    @orientations.each do |direction|
      if warrior.feel(direction).empty? and !warrior.feel(direction).stairs?
        return direction
      end
    end
  end

  def path_blocked(warrior)
    @orientations.each do |direction|
      if warrior.feel(direction).empty?
        return false
      end
    end
    true
  end

  def path_to_bomb(warrior, direction)
    if warrior.feel(direction).empty?
      return false
    end
    true
  end

  def fight_all_sludges(warrior)
    if warrior.listen.empty?
      @previous_direction = warrior.direction_of_stairs
      warrior.walk! @previous_direction
    else
      warrior.walk!(warrior.direction_of(warrior.listen.first))
    end
  end

  def rescue_ticking_first(warrior, direction)
    if rescue_c(warrior)
      return
    end
    p "We should be going #{direction}"
    if warrior.feel(direction).wall? or warrior.feel(direction).stairs? or (!warrior.feel(direction).empty? and warrior.feel(direction).enemy?)
      rescue_ticking_first(warrior, counter_clockwise(direction))
    elsif warrior.feel(direction).enemy?
      warrior.attack! direction
    elsif warrior.feel(direction).empty?
      p 'Walking to the rescue'
      warrior.walk! direction
    elsif warrior.feel(clockwise(direction)).enemy?
      warrior.attack! clockwise(direction)
    else
      warrior.walk!
    end
  end

  def avoid_walls_and_stairs(warrior, direction)
    if warrior.feel(direction).wall? or warrior.feel(direction).stairs?
      avoid_walls_and_stairs(warrior, counter_clockwise(direction))
    elsif warrior.feel(direction).empty?
      warrior.walk! direction
    else
      rescue_c(warrior)
    end
  end

  def rescue_c(warrior)
    p "There are #{@captives} captives and #{@rescued} rescued"
    @should_free, @here = captives_around(warrior)
    unless @here.nil?
      @here.each do |loc|
        if @rescued != @captives
          p "The one we are about to rescue is a #{warrior.feel(loc).to_s}"
          if @should_free and warrior.feel(loc).to_s != 'Sludge'
            p 'Calling rescue!'
            warrior.rescue! loc
            @rescued += 1
            return true
          end
        else
          p 'Freeing Sludge so we can kill it!'
          warrior.rescue! loc
          return true
        end
      end
    end
    false
  end

  def enemies_around(warrior)
    @orientations.each do |direction|
      if warrior.feel(direction).enemy?
        return true, direction
      end
    end
    false
  end

  def immediate_enemies(warrior)
    number = 0
    @orientations.each do |direction|
      if warrior.feel(direction).enemy?
        number += 1
      end
    end
    number
  end

  def location_of_enemies(warrior)
    directions = []
    units = warrior.listen
    units.each do |unit|
      if unit.enemy? and !unit.captive?
        directions << unit
      end
    end
    directions
  end

  def captives_around(warrior)
    locations = []
    @orientations.each do |direction|
      if warrior.feel(direction).captive?
        locations << direction
      end
    end
    unless locations.empty?
      return true, locations
    end
    false
  end

  def bomb_squad(warrior)
    @orientations.each do |direction|
      enemies = 0
      thick_sludges = 0
      warrior.look(direction).each do |unit|
        if unit.enemy?
          enemies += 1
        end
        if unit.to_s == 'Thick Sludge'
          thick_sludges += 1
        end
      end
      #if warrior.feel(direction).empty?
      #  p 'Walking to place a bomb!'
      #  warrior.walk! direction
      #  return true
      if enemies > 1
        if thick_sludges > 0
          if warrior.health > 4
            if warrior.feel(direction).empty?
              warrior.walk! direction
              return true
            else
              warrior.detonate! direction
              return true
            end
          end
        else
          if warrior.health > 12
            if warrior.feel(direction).empty?
              warrior.walk! direction
              return true
            else
              warrior.detonate! direction
              return true
            end
          end
        end
      end

    end
    false
  end

  def number_of_captives(warrior)
    number = 0
    units = warrior.listen
    captives = []
    ticking_locations = []
    ticking = 0
    units.each do |unit|
      if unit.captive?
        number += 1
        captives << unit
      end
      if unit.ticking?
        ticking += 1
        ticking_locations << unit
      end
    end
    return number, captives, ticking, ticking_locations
  end

  def opposite_direction(where)
    case where
      when :forward
        return :backward
      when :left
        return :right
      when :right
        return :left
      when :backward
        return :forward
      else
        return :forward
    end
  end

  def counter_clockwise(where)
    case where
      when :forward
        return :left
      when :left
        return :backward
      when :right
        return :forward
      when :backward
        return :right
      else
        return :forward
    end
  end

  def clockwise(where)
    case where
      when :forward
        return :right
      when :left
        return :forward
      when :right
        return :backward
      when :backward
        return :left
      else
        return :forward
    end

  end

end
