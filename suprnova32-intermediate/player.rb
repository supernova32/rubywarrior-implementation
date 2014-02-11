class Player
  @previous_direction = :forward
  @freed = false
  def play_turn(warrior)
    @units_bound = []
    @rescued = 0
    should_attack, where = enemies_around(warrior)
    @caps, @locations, @ticking, @tick_locations = number_of_captives(warrior)
    unless @sensed
      @captives = @caps
      @sensed = true
    end

    if warrior.health < 4
      if should_attack
        warrior.walk! walk_to_free_space(warrior)
        return
      else
        warrior.rest!
        return
      end
    end


    directions = location_of_enemies(warrior)
    number = immediate_enemies(warrior)

    if bomb_squad(warrior)
      return
    end

    if number > 1
      @units_bound << directions.first
      warrior.bind! warrior.direction_of(directions.first)
      return
    elsif @ticking > 0
      rescue_ticking_first(warrior, warrior.direction_of(@tick_locations.first))
      return
    elsif number == 0 and @caps > 0
      rescue_ticking_first(warrior, warrior.direction_of(@locations.first))
      return
    end

    location = warrior.listen
    unless location.empty?
      if @units_bound.include? warrior.feel(warrior.direction_of(location.first))
        warrior.attack! warrior.direction_of(warrior.listen.first)
        return
      end
    end


    if should_attack
      warrior.attack! where
    else
      fight_all_sludges(warrior)
    end
  end

  def walk_to_free_space(warrior)
    [:forward, :left, :right, :backward].each do |direction|
      if warrior.feel(direction).empty?
        return direction
      end
    end
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
    if warrior.feel(direction).wall? or warrior.feel(direction).stairs?
      rescue_ticking_first(warrior, counter_clockwise(direction))
    elsif warrior.feel(direction).empty?
      warrior.walk! direction
    elsif warrior.feel(direction).enemy?
      warrior.attack! direction
    else
      rescue_c(warrior)
    end
  end

  def rescue_c(warrior)
    unit_locations = @units_bound.map { |u| warrior.direction_of(u) }
    unless @rescued == @captives
      @should_free, @here = captives_around(warrior)
      if @should_free and !unit_locations.include?(@here)
        warrior.rescue! @here
        @rescued += 1
        return
      end
    end
  end

  def enemies_around(warrior)
    [:forward, :left, :right, :backward].each do |direction|
      if warrior.feel(direction).enemy?
        return true, direction
      end
    end
    false
  end

  def immediate_enemies(warrior)
    number = 0
    [:forward, :left, :right, :backward].each do |direction|
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
      if unit.enemy?
        directions << unit
      end
    end
    directions
  end

  def captives_around(warrior)
    [:forward, :left, :right, :backward].each do |direction|
      if warrior.feel(direction).captive?
        return true, direction
      end
    end
    false
  end

  def bomb_squad(warrior)
    enemies = 0
    warrior.look.each do |unit|
      if unit.enemy?
        enemies += 1
      end
    end
    #puts "Enemies: #{enemies}"
    if warrior.feel.empty?
      warrior.walk!
    elsif enemies > 1 and warrior.health > 4
      warrior.detonate!
      true
    end
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

end
