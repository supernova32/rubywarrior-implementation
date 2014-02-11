class Player
  @previous_direction
  def play_turn(warrior)
    should_attack, where = enemies_around(warrior)

    if should_attack and warrior.health < 6
      warrior.walk! opposite_direction(@previous_direction)
    elsif !should_attack and warrior.health < 6
      warrior.rest!
    elsif should_attack
      warrior.attack! where
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
        return nil
    end
  end
end
