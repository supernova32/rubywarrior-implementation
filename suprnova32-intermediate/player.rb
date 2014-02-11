class Player
  @previous_direction = :forward
  @freed = false
  def play_turn(warrior)
    @rescued = 0
    should_attack, where = enemies_around(warrior)
    caps, @locations = number_of_captives(warrior)
    unless @sensed
      @captives = caps
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



    number, directions = number_of_enemies(warrior)


    if number > 2
      warrior.bind! directions.first
      return
    elsif number == 0 and caps > 0
      warrior.walk! warrior.direction_of @locations.last
      return
    end

    unless @rescued == @captives
      @should_free, @here = captives_around(warrior)
      if @should_free
        warrior.rescue! @here
        @rescued += 1
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

  def enemies_around(warrior)
    [:forward, :left, :right, :backward].each do |direction|
      if warrior.feel(direction).enemy?
        return true, direction
      end
    end
    false
  end

  def number_of_enemies(warrior)
    number = 0
    directions = []
    [:forward, :left, :right, :backward].each do |direction|
      if warrior.feel(direction).enemy?
        number += 1
        directions << direction
      end
    end
    return number, directions
  end

  def captives_around(warrior)
    [:forward, :left, :right, :backward].each do |direction|
      if warrior.feel(direction).captive?
        return true, direction
      end
    end
    false
  end

  def number_of_captives(warrior)
    number = 0
    units = warrior.listen
    captives = []
    units.each do |unit|
      if unit.captive?
        number += 1
        captives << unit
      end
    end
    return number, captives
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

end
