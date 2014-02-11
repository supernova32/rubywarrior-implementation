class Player
  @previous_direction = :forward
  @sensed = false
  @freed = false
  def play_turn(warrior)
    should_attack, where = enemies_around(warrior)
    unless @sensed
      @should_free, @here = captives_around(warrior)
      @sensed = true
    end

    number, directions = number_of_enemies(warrior)

    if number > 1
      warrior.bind! directions.first
      return
    end

    unless @freed
      free(warrior)
      @freed = true
      return
    end


    if should_attack and warrior.health < 5
      warrior.walk! walk_to_free_space(warrior)
    elsif !should_attack and warrior.health < 5
      warrior.rest!
    elsif should_attack
      warrior.attack! where
    else
      fight_captive_sludge(warrior)
    end
  end

  def walk_to_free_space(warrior)
    [:forward, :left, :right, :backward].each do |direction|
      if warrior.feel(direction).empty?
        return direction
      end
    end
  end

  def fight_captive_sludge(warrior)
    if warrior.feel(warrior.direction_of_stairs).captive? and @freed
      warrior.attack! warrior.direction_of_stairs
    else
      @previous_direction = warrior.direction_of_stairs
      warrior.walk! @previous_direction
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

  def free(warrior)
    if @should_free
      warrior.rescue! @here
    end
  end
end
